// Chess adapter for the live UI driver (KLD-059 step 3).
//
// Reads the move list a ChessBoard shows (`chess-move-<i>`, SAN): every
// board move is one turn, reported in order, one per observation, so a
// device that received two moves between observations still shows both.
// When a new move is reported on a device that is in sync with the host, the
// 64 squares on its screen are compared with its engine.
//
// Plays like a user: answers an open draw offer in its dialog (mostly
// "Ablehnen"), sometimes offers a draw on its turn (handshake button, then
// "Anbieten") and waits for the answer, else taps a piece and its target (a mate in one if there is
// one, often the best capture, else any legal move) and picks the piece in
// the promotion picker. Now and then it flips the board (a side action).
//
// The game-ending board move is never on screen long (the result dialog
// opens over it), so [engineTurns] leaves it out; the test checks the
// result dialog instead.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/games/chess/chess_board.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import 'live_ui_driver.dart';

class ChessAdapter extends LiveUiAdapter {
  /// Chance to offer a draw on the own turn (when allowed).
  final double offerRate;

  /// Chance to accept an offer (else decline).
  final double acceptRate;

  /// Offers declined before any is accepted.
  final int minDeclines;

  ChessAdapter({this.offerRate = 0.03, this.acceptRate = 0.2, this.minDeclines = 0});

  @override
  String get gameId => 'chess';

  /// How often each kind of action was tapped (the tests check the mix).
  final Map<String, int> tapped = {};

  /// Board positions compared with the engine.
  int boardChecks = 0;

  /// Turns reported per device (its controller: one per game) so far.
  final Map<GameController, int> _reported = {};

  /// Per device: the log index of the last draw offer it answered.
  final Map<GameController, int> _answered = {};

  void _count(String what) => tapped.update(what, (n) => n + 1, ifAbsent: () => 1);

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;

  TurnRecord _record(int i, String san, String source) => TurnRecord(
        index: i,
        actor: i.isEven ? Player.a : Player.b, // from the start position, White first
        action: 'move',
        outcome: san,
        detail: '#$i',
        nextActor: i.isEven ? Player.b : Player.a,
        source: source,
      );

  String? _moveText(WidgetTester tester, UiDevice d, int i) {
    final f = d.on(find.byKey(Key('chess-move-$i')));
    if (f.evaluate().isEmpty) return null;
    // "12. Nf3" or "Nf3": the SAN is the last word.
    return tester.widget<Text>(f).textSpan!.toPlainText().trim().split(RegExp(r'\s+')).last;
  }

  @override
  TurnRecord? observe(WidgetTester tester, UiDevice d, Game engine, {required bool inSync}) {
    final c = d.controller(tester);
    final cap = engineTurns(c).length;
    final k = _reported[c] ?? 0;
    if (k < cap) {
      final san = _moveText(tester, d, k);
      if (san != null) {
        _reported[c] = k + 1;
        expect(san, (c.game as ChessGame).sanHistory[k], reason: '${d.name}: move $k on screen');
        if (inSync && k + 1 == cap) _checkBoard(tester, d, c.game as ChessGame);
        return _record(k, san, d.name);
      }
    }
    if (k == 0) return null;
    return _record(k - 1, _moveText(tester, d, k - 1) ?? '?', d.name);
  }

  void _checkBoard(WidgetTester tester, UiDevice d, ChessGame g) {
    final board = g.board;
    for (var i = 0; i < 64; i++) {
      final name = ChessGame.squareName(i);
      expect(tester.widget<ChessSquareView>(d.on(find.byKey(Key('chess-sq-$name')))).piece, board[i],
          reason: '${d.name}: $name');
    }
    // The own side at the bottom on a network device (no flip in between).
    boardChecks++;
  }

  @override
  Future<bool> dismiss(WidgetTester tester, UiDevice device) async => false;

  @override
  Future<String?> fidget(WidgetTester tester, UiDevice d, Random rng) async {
    if (d.dialogOpen || !d.hasKey(const Key('chess-flip'))) return null;
    await d.tapKey(tester, const Key('chess-flip'));
    _count('flip');
    return 'flips the board';
  }

  /// Lets a dialog finish its entrance animation before a tap.
  Future<void> _dialogIn(WidgetTester tester) => tester.pump(const Duration(milliseconds: 300));

  @override
  Future<Map<String, dynamic>?> play(WidgetTester tester, UiDevice d, Random rng) async {
    final c = d.controller(tester);
    final g = c.game as ChessGame;
    if (g.isOver) return null;
    final offerBy = g.drawOfferBy;
    // The offer this device answered last: its dialog may still fade out
    // while the answer travels to the host.
    final offerIndex = c.moves.lastIndexWhere((m) => m.move['action'] == ChessGame.offerDraw);
    final answered = _answered[c] == offerIndex;
    if ((offerBy == null || answered) && d.hasKey(const Key('chess-draw-offer-dialog'))) await _dialogIn(tester);
    if (answered && offerBy != null) return null; // the answer is on its way
    if (d.hasKey(const Key('chess-draw-offer-dialog'))) {
      if (offerBy == null) return null;
      final me = _other(offerBy);
      await _dialogIn(tester);
      _answered[c] = offerIndex;
      if ((tapped['decline'] ?? 0) >= minDeclines && rng.nextDouble() < acceptRate) {
        _count('accept');
        await d.tapKey(tester, const Key('chess-draw-accept'));
        return ChessGame.acceptDrawMove(me);
      }
      _count('decline');
      await d.tapKey(tester, const Key('chess-draw-decline'));
      return ChessGame.declineDrawMove(me);
    }
    // The own offer waits for its answer: the pieces wait too.
    if (d.dialogOpen || !c.canAct || offerBy != null) return null;
    final me = g.currentPlayer;
    if (offerBy == null && g.canOfferDraw(me) && rng.nextDouble() < offerRate) {
      _count('offer');
      await d.tapKey(tester, const Key('chess-offer-draw'));
      await _dialogIn(tester);
      expect(d.hasKey(const Key('chess-offer-dialog')), isTrue, reason: '${d.name}: offer dialog');
      await d.tapKey(tester, const Key('chess-offer-confirm'));
      await _dialogIn(tester);
      return ChessGame.offerDrawMove(me);
    }
    final move = _choose(g, rng);
    await d.tapKey(tester, Key('chess-sq-${move['from']}'));
    await d.tapKey(tester, Key('chess-sq-${move['to']}'));
    final promo = move['promotion'];
    if (promo != null) {
      _count('promotion');
      await _dialogIn(tester);
      expect(d.hasKey(const Key('chess-promotion')), isTrue, reason: '${d.name}: promotion picker');
      await d.tapKey(tester, Key('chess-promote-$promo'));
      await _dialogIn(tester);
    }
    _count('move');
    return move;
  }

  static const _value = {ChessPieceType.pawn: 1, ChessPieceType.knight: 3, ChessPieceType.bishop: 3, ChessPieceType.rook: 5, ChessPieceType.queen: 9};

  /// A mate in one, else often the most valuable capture or a promotion,
  /// else any legal move (with a random promotion piece, mostly the queen).
  Map<String, dynamic> _choose(ChessGame g, Random rng) {
    final legal = g.legalMoves;
    final mates = [for (final m in legal) if (g.sanOf(m)!.endsWith('#')) m];
    if (mates.isNotEmpty) return mates[rng.nextInt(mates.length)];
    int gain(Map<String, dynamic> m) =>
        (_value[g.pieceAt(m['to'] as String)?.type] ?? 0) + (m['promotion'] == 'q' ? 8 : 0);
    final best = legal.map(gain).fold(0, max);
    if (best > 0 && rng.nextDouble() < 0.8) {
      final pick = [for (final m in legal) if (gain(m) == best) m];
      return pick[rng.nextInt(pick.length)];
    }
    final m = legal[rng.nextInt(legal.length)];
    if (m['promotion'] == null) return m;
    final piece = rng.nextDouble() < 0.7 ? 'q' : const ['r', 'b', 'n'][rng.nextInt(3)];
    return {...m, 'promotion': piece};
  }

  @override
  List<TurnRecord> engineTurns(GameController c) {
    final g = c.game as ChessGame;
    final san = g.sanHistory;
    // The game ended with a board move: the result dialog covers it.
    final endedOnBoard = g.isOver && c.moves.isNotEmpty && c.moves.last.move['action'] == 'move';
    final shown = endedOnBoard ? san.length - 1 : san.length;
    return [for (var i = 0; i < shown; i++) _record(i, san[i], 'engine')];
  }
}
