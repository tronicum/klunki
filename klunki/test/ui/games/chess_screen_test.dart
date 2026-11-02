// KLD-059 step 2: the hot-seat chess board. Everything here is driven by
// tapping squares in the widget tree (the controller only sets up longer
// openings), and the board is compared with the engine after the moves.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/games/chess/chess_board.dart';
import 'package:klunki/ui/games/chess/chess_pieces.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../shell/shell_test_utils.dart';

Finder _sq(String s) => find.byKey(Key('chess-sq-$s'));

ChessSquareView _view(WidgetTester tester, String s) => tester.widget<ChessSquareView>(_sq(s));

Future<void> _tap(WidgetTester tester, String s) async {
  await tester.tap(_sq(s));
  await tester.pump();
  await tester.pump(); // post-frame: hint, result dialog
}

/// Plays [from]→[to] by two taps.
Future<void> _move(WidgetTester tester, String from, String to) async {
  await _tap(tester, from);
  expect(_view(tester, from).selected, isTrue, reason: '$from selected');
  await _tap(tester, to);
}

/// Long-algebraic moves ("e2e4") through the controller (setup only).
Future<void> _setup(WidgetTester tester, GameController c, List<String> moves) async {
  for (final m in moves) {
    final r = await c.submit({'action': 'move', 'from': m.substring(0, 2), 'to': m.substring(2)});
    expect(r.isAccepted, isTrue, reason: m);
  }
  await tester.pump();
}

ChessGame _game(GameController c) => c.game as ChessGame;

String _status(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('shell-status'))).data!;

String _rank0(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('chess-rank-0'))).data!;

Set<String> _where(WidgetTester tester, bool Function(ChessSquareView v) test) => {
      for (var i = 0; i < 64; i++)
        if (test(_view(tester, ChessGame.squareName(i)))) ChessGame.squareName(i),
    };

/// Every square shows the engine's piece; the status, check badge and move
/// list match the engine.
void _expectMatchesEngine(WidgetTester tester, GameController c) {
  final g = _game(c);
  for (var i = 0; i < 64; i++) {
    final name = ChessGame.squareName(i);
    expect(_view(tester, name).piece, g.board[i], reason: name);
  }
  expect(find.byKey(const Key('chess-check')), g.isInCheck && !g.isOver ? findsOneWidget : findsNothing);
  final san = g.sanHistory;
  for (var i = 0; i < san.length; i++) {
    final text = tester.widget<Text>(find.byKey(Key('chess-move-$i'))).textSpan!.toPlainText();
    expect(text, endsWith(san[i]));
  }
  if (!g.isOver) expect(_status(tester), g.currentPlayer == Player.a ? 'Anna (Weiß) ist am Zug' : 'Ben (Schwarz) ist am Zug');
}

void main() {
  testWidgets('select a piece, see its legal targets, move it; the board turns to Black', (tester) async {
    final c = await pumpGame(tester, 'chess');
    expect(_status(tester), 'Anna (Weiß) ist am Zug');
    expect(_rank0(tester), '8', reason: 'White at the bottom');
    expect(_view(tester, 'e1').piece, const ChessPiece(ChessColor.white, ChessPieceType.king));

    await _tap(tester, 'g1');
    expect(_view(tester, 'g1').selected, isTrue);
    expect(_where(tester, (v) => v.target), {'f3', 'h3'});
    expect(_where(tester, (v) => v.captureTarget), isEmpty);
    expect(find.text('Tippe ein markiertes Feld an.'), findsOneWidget);

    // Another own piece switches the selection; an empty square deselects.
    await _tap(tester, 'e2');
    expect(_where(tester, (v) => v.target), {'e3', 'e4'});
    await _tap(tester, 'a5');
    expect(_where(tester, (v) => v.selected || v.target), isEmpty);
    // Black's pieces cannot be selected on White's turn.
    await _tap(tester, 'e7');
    expect(_view(tester, 'e7').selected, isFalse);

    await _move(tester, 'e2', 'e4');
    expect(_game(c).pieceAt('e4'), const ChessPiece(ChessColor.white, ChessPieceType.pawn));
    expect(_where(tester, (v) => v.lastMove), {'e2', 'e4'});
    expect(_status(tester), 'Ben (Schwarz) ist am Zug');
    expect(_rank0(tester), '1', reason: 'turned to Black');
    _expectMatchesEngine(tester, c);
  });

  testWidgets('capture: ring on the target, the piece goes to the captured row', (tester) async {
    final c = await pumpGame(tester, 'chess');
    await _setup(tester, c, ['e2e4', 'd7d5']);
    await _tap(tester, 'e4');
    expect(_where(tester, (v) => v.captureTarget), {'d5'});
    expect(_where(tester, (v) => v.target), {'e5'});
    await _tap(tester, 'd5');
    expect(_game(c).pieceAt('d5'), const ChessPiece(ChessColor.white, ChessPieceType.pawn));
    final captured = find.descendant(of: find.byKey(const Key('chess-captured-a')), matching: find.byType(ChessPieceIcon));
    expect(tester.widget<ChessPieceIcon>(captured).piece, const ChessPiece(ChessColor.black, ChessPieceType.pawn));
    _expectMatchesEngine(tester, c);
  });

  testWidgets('castling by the king\'s two-square step', (tester) async {
    final c = await pumpGame(tester, 'chess');
    await _setup(tester, c, ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5']);
    await _tap(tester, 'e1');
    expect(_where(tester, (v) => v.target), containsAll(['f1', 'g1', 'e2']));
    await _tap(tester, 'g1');
    expect(_game(c).pieceAt('g1'), const ChessPiece(ChessColor.white, ChessPieceType.king));
    expect(_game(c).pieceAt('f1'), const ChessPiece(ChessColor.white, ChessPieceType.rook));
    expect(_game(c).sanHistory.last, 'O-O');
    _expectMatchesEngine(tester, c);
  });

  testWidgets('en passant: a capture ring on the empty square', (tester) async {
    final c = await pumpGame(tester, 'chess');
    await _setup(tester, c, ['e2e4', 'a7a6', 'e4e5', 'd7d5']);
    await _tap(tester, 'e5');
    expect(_where(tester, (v) => v.captureTarget), {'d6'});
    await _tap(tester, 'd6');
    expect(_game(c).pieceAt('d5'), isNull);
    expect(_game(c).pieceAt('d6'), const ChessPiece(ChessColor.white, ChessPieceType.pawn));
    expect(_game(c).sanHistory.last, 'exd6');
    _expectMatchesEngine(tester, c);
  });

  testWidgets('promotion: the picker in the mover\'s colour; cancel keeps the pawn, then a knight', (tester) async {
    final c = await pumpGame(tester, 'chess');
    await _setup(tester, c, ['a2a4', 'b7b5', 'a4b5', 'a7a6', 'b5a6', 'c8b7', 'a6b7', 'b8c6']);
    await _move(tester, 'b7', 'a8');
    expect(find.byKey(const Key('chess-promotion')), findsOneWidget);
    for (final l in ['q', 'r', 'b', 'n']) {
      final icon = find.descendant(of: find.byKey(Key('chess-promote-$l')), matching: find.byType(ChessPieceIcon));
      expect(tester.widget<ChessPieceIcon>(icon).piece.color, ChessColor.white);
    }
    await tester.tap(find.byKey(const Key('chess-promote-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chess-promotion')), findsNothing);
    expect(_game(c).pieceAt('b7'), const ChessPiece(ChessColor.white, ChessPieceType.pawn));
    expect(c.moves, hasLength(8));
    expect(_status(tester), 'Anna (Weiß) ist am Zug');

    await _move(tester, 'b7', 'a8');
    await tester.tap(find.byKey(const Key('chess-promote-n')));
    await tester.pumpAndSettle();
    expect(_game(c).pieceAt('a8'), const ChessPiece(ChessColor.white, ChessPieceType.knight));
    expect(_game(c).sanHistory.last, 'bxa8=N');
    _expectMatchesEngine(tester, c);
  });

  testWidgets('check: badge and the king\'s square in red', (tester) async {
    final c = await pumpGame(tester, 'chess');
    await _setup(tester, c, ['e2e4', 'f7f5']);
    await _move(tester, 'd1', 'h5');
    expect(find.byKey(const Key('chess-check')), findsOneWidget);
    expect(find.text('Schach!'), findsOneWidget);
    expect(_where(tester, (v) => v.check), {'e8'});
    // Only the moves out of check are offered.
    await _tap(tester, 'g7');
    expect(_where(tester, (v) => v.target), {'g6'});
    await _tap(tester, 'g6');
    expect(find.byKey(const Key('chess-check')), findsNothing);
    expect(_where(tester, (v) => v.check), isEmpty);
    _expectMatchesEngine(tester, c);
  });

  testWidgets('Fool\'s mate by taps ends with "Schachmatt", Black wins', (tester) async {
    final c = await pumpGame(tester, 'chess');
    await _move(tester, 'f2', 'f3');
    await _move(tester, 'e7', 'e5');
    await _move(tester, 'g2', 'g4');
    await _move(tester, 'd8', 'h4');
    await tester.pumpAndSettle();
    expect(_game(c).result.code, GameEndReason.chessCheckmate);
    expect(find.descendant(of: find.byKey(resultDialog), matching: find.text('Ben (Schwarz) gewinnt!')), findsOneWidget);
    expect(find.descendant(of: find.byKey(resultDialog), matching: find.text('Schachmatt')), findsOneWidget);
    expect(_where(tester, (v) => v.check), {'e1'}, reason: 'the mated king stays marked');
  });

  testWidgets('stalemate ends in a draw with "Patt"', (tester) async {
    final c = await pumpGame(tester, 'chess');
    // Sam Loyd's ten-move stalemate; the last move by taps.
    await _setup(tester, c, [
      'e2e3', 'a7a5', 'd1h5', 'a8a6', 'h5a5', 'h7h5', 'h2h4', 'a6h6', 'a5c7', 'f7f6', //
      'c7d7', 'e8f7', 'd7b7', 'd8d3', 'b7b8', 'd3h7', 'b8c8', 'f7g6',
    ]);
    await _move(tester, 'c8', 'e6');
    await tester.pumpAndSettle();
    expect(_game(c).result.code, GameEndReason.chessStalemate);
    expect(find.descendant(of: find.byKey(resultDialog), matching: find.text('Unentschieden')), findsOneWidget);
    expect(find.descendant(of: find.byKey(resultDialog), matching: find.text('Patt')), findsOneWidget);
  });

  testWidgets('resign names the side ("Anna (Weiß) hat aufgegeben")', (tester) async {
    final c = await pumpGame(tester, 'chess');
    await tester.tap(find.byKey(const Key('shell-resign')));
    await tester.pumpAndSettle();
    expect(find.text('Anna (Weiß) gibt auf'), findsOneWidget);
    await tester.tap(find.byKey(const Key('resign-a')));
    await tester.pumpAndSettle();
    expect(c.game.isOver, isTrue);
    expect(find.descendant(of: find.byKey(resultDialog), matching: find.text('Anna (Weiß) hat aufgegeben')), findsOneWidget);
    expect(find.descendant(of: find.byKey(resultDialog), matching: find.text('Ben (Schwarz) gewinnt!')), findsOneWidget);
  });

  testWidgets('flip button and the auto-turn toggle', (tester) async {
    final c = await pumpGame(tester, 'chess');
    expect(_rank0(tester), '8');
    await tester.tap(find.byKey(const Key('chess-flip')));
    await tester.pump();
    expect(_rank0(tester), '1', reason: 'flipped by hand');
    await tester.tap(find.byKey(const Key('chess-flip')));
    await tester.pump();
    expect(_rank0(tester), '8');

    // Auto-turn off: the board stays with White at the bottom.
    await tester.tap(find.byKey(const Key('chess-auto-flip')));
    await tester.pump();
    await _move(tester, 'e2', 'e4');
    expect(_game(c).currentPlayer, Player.b);
    expect(_rank0(tester), '8');
    // Back on: turned to Black.
    await tester.tap(find.byKey(const Key('chess-auto-flip')));
    await tester.pump();
    expect(_rank0(tester), '1');
    // The files run h…a then.
    expect(tester.widget<Text>(find.byKey(const Key('chess-file-0'))).data, 'h');
  });

  testWidgets('drag and drop moves a piece', (tester) async {
    final c = await pumpGame(tester, 'chess');
    await tester.drag(_sq('g1'), tester.getCenter(_sq('f3')) - tester.getCenter(_sq('g1')));
    await tester.pumpAndSettle();
    expect(_game(c).pieceAt('f3'), const ChessPiece(ChessColor.white, ChessPieceType.knight));
    _expectMatchesEngine(tester, c);
  });

  testWidgets('undo puts the piece back', (tester) async {
    final c = await pumpGame(tester, 'chess');
    await _move(tester, 'e2', 'e4');
    await tester.tap(find.byKey(const Key('shell-undo')));
    await tester.pump();
    expect(c.moves, isEmpty);
    _expectMatchesEngine(tester, c);
    expect(_where(tester, (v) => v.lastMove), isEmpty);
  });

  // Real UI play: Scholar's mate, every move by tapping two squares; the
  // shown board, status and move list match the engine after each move.
  for (final size in [const Size(390, 844), const Size(1180, 820)]) {
    testWidgets('Scholar\'s mate played by taps at ${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = await pumpGame(tester, 'chess');
      for (final (from, to) in [
        ('e2', 'e4'), ('e7', 'e5'), ('f1', 'c4'), ('b8', 'c6'), ('d1', 'h5'), ('g8', 'f6'), ('h5', 'f7'), //
      ]) {
        final before = c.moves.length;
        await _move(tester, from, to);
        expect(c.moves.length, before + 1, reason: '$from-$to accepted');
        expect(tester.takeException(), isNull);
        _expectMatchesEngine(tester, c);
      }
      expect(_game(c).sanHistory, ['e4', 'e5', 'Bc4', 'Nc6', 'Qh5', 'Nf6', 'Qxf7#']);
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byKey(resultDialog), matching: find.text('Anna (Weiß) gewinnt!')), findsOneWidget);
      expect(find.descendant(of: find.byKey(resultDialog), matching: find.text('Schachmatt')), findsOneWidget);
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
    });
  }

  // KLD-059 step 3: the draw offer on one device. The player to move offers,
  // the dialog asks the other player at once.
  testWidgets('hot-seat draw offer: declined (hint, no second offer), then accepted', (tester) async {
    final c = await pumpGame(tester, 'chess');
    await _move(tester, 'e2', 'e4');
    // Black to move offers.
    await tester.tap(find.byKey(const Key('chess-offer-draw')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chess-offer-dialog')), findsOneWidget);
    expect(find.text('Remis anbieten?'), findsOneWidget);
    expect(find.text('Anna (Weiß) kann annehmen oder ablehnen. Bei Annahme endet das Spiel unentschieden.'),
        findsOneWidget);
    // Cancel sends nothing.
    await tester.tap(find.byKey(const Key('chess-offer-cancel')));
    await tester.pumpAndSettle();
    expect(c.moves, hasLength(1));
    await tester.tap(find.byKey(const Key('chess-offer-draw')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chess-offer-confirm')));
    await tester.pumpAndSettle();
    expect(c.moves.last.move, ChessGame.offerDrawMove(Player.b));
    expect(find.byKey(const Key('chess-draw-offer-dialog')), findsOneWidget);
    expect(find.text('Ben (Schwarz) bietet ein Remis an. Bei Annahme endet das Spiel unentschieden.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chess-draw-decline')));
    await tester.pumpAndSettle();
    expect(c.moves.last.move, ChessGame.declineDrawMove(Player.a));
    expect(find.byKey(const Key('chess-draw-offer-dialog')), findsNothing);
    expect(find.text('Anna (Weiß) lehnt das Remis ab.'), findsOneWidget);
    // Ben already offered in this position.
    expect(tester.widget<IconButton>(find.byKey(const Key('chess-offer-draw'))).onPressed, isNull);
    await _move(tester, 'e7', 'e5');
    expect(find.text('Anna (Weiß) lehnt das Remis ab.'), findsNothing);
    // White offers, Black accepts: a draw by agreement.
    await tester.tap(find.byKey(const Key('chess-offer-draw')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chess-offer-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chess-draw-accept')));
    await tester.pumpAndSettle();
    expect(_game(c).result.code, GameEndReason.chessDrawAgreed);
    expect(find.descendant(of: find.byKey(resultDialog), matching: find.text('Unentschieden')), findsOneWidget);
    expect(find.descendant(of: find.byKey(resultDialog), matching: find.text('Remis vereinbart')), findsOneWidget);
    expect(find.byKey(const Key('chess-offer-draw')), findsNothing);
  });

  testWidgets('hot-seat: undo takes back an open offer and closes its dialog; history names the offer', (tester) async {
    final c = await pumpGame(tester, 'chess');
    await _move(tester, 'd2', 'd4');
    await c.submit(ChessGame.offerDrawMove(Player.b));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chess-draw-offer-dialog')), findsOneWidget);
    expect(c.undo(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chess-draw-offer-dialog')), findsNothing);
    expect(_game(c).drawOfferBy, isNull);
    await c.submit(ChessGame.offerDrawMove(Player.b));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chess-draw-decline')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shell-history')));
    await tester.pumpAndSettle();
    expect(find.text('Anna (Weiß): d4'), findsOneWidget);
    expect(find.text('Ben (Schwarz): Remis angeboten'), findsOneWidget);
    expect(find.text('Anna (Weiß): Remis abgelehnt'), findsOneWidget);
  });
}
