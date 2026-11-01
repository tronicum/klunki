import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-059 step 1: the chess engine with the full FIDE rules.
void main() {
  Map<String, dynamic> mv(String from, String to, [String? promotion]) =>
      {'action': 'move', 'from': from, 'to': to, if (promotion != null) 'promotion': promotion};

  /// Plays [moves] (SAN or long algebraic, parsed by [ChessText]) and
  /// returns the game; every move must be legal.
  ChessGame play(List<String> moves, [ChessGame? game]) {
    final g = game ?? ChessGame();
    final t = ChessText(game: g);
    for (final s in moves) {
      final m = t.parse(s);
      expect(m, isNotNull, reason: 'parse $s');
      expect(g.applyMove(m!), isNotNull, reason: 'apply $s');
    }
    return g;
  }

  Set<String> targets(ChessGame g, String square) => {for (final m in g.legalMovesFrom(square)) m['to'] as String};

  group('perft (move generator against known node counts)', () {
    const positions = <String, (String, List<int>)>{
      'start position': (ChessGame.startFen, [20, 400, 8902, 197281, 4865609]),
      // Castling in all forms, pins, en passant, promotions.
      'Kiwipete': ('r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1', [48, 2039, 97862, 4085603]),
      // En passant with discovered rank checks, a lone rook endgame.
      'position 3': ('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1', [14, 191, 2812, 43238, 674624]),
      // Promotions with capture, castling rights lost by capture, checks.
      'position 4': ('r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1', [6, 264, 9467, 422333]),
      // Promotion on d8 with check, a knight fork on f2, short castling.
      'position 5': ('rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8', [44, 1486, 62379]),
    };
    positions.forEach((name, spec) {
      final (fen, counts) = spec;
      test('$name depth 1-${counts.length}', () {
        for (var d = 1; d <= counts.length; d++) {
          expect(ChessGame.fromFen(fen).perft(d), counts[d - 1], reason: '$name depth $d');
        }
      });
    });

    test('perft leaves the position unchanged', () {
      final g = ChessGame.fromFen(positions['Kiwipete']!.$1);
      final before = g.fen;
      g.perft(3);
      expect(g.fen, before);
      expect(g.legalMoves, hasLength(48));
    });
  });

  group('start position and API', () {
    test('White (A) to move, 20 legal moves, standard FEN', () {
      final g = ChessGame();
      expect(g.currentPlayer, Player.a);
      expect(g.fen, ChessGame.startFen);
      expect(g.legalMoves, hasLength(20));
      expect(g.isInCheck, isFalse);
      expect(g.isOver, isFalse);
      expect(g.history, isEmpty);
      expect(g.board, hasLength(64));
      expect(g.board[0], const ChessPiece(Player.a, ChessPieceType.rook));
      expect(g.board[4], const ChessPiece(Player.a, ChessPieceType.king));
      expect(g.board[59], const ChessPiece(Player.b, ChessPieceType.queen));
      expect(g.board[27], isNull);
      expect(g.pieceAt('e8')!.fen, 'k');
      expect(g.pieceAt('d1')!.fen, 'Q');
      expect(g.pieceAt('z9'), isNull);
    });

    test('square names and indices', () {
      expect(ChessGame.squareIndex('a1'), 0);
      expect(ChessGame.squareIndex('h1'), 7);
      expect(ChessGame.squareIndex('a8'), 56);
      expect(ChessGame.squareIndex('h8'), 63);
      for (final bad in ['i1', 'a9', 'a0', 'e', 'e44', '', null, 12]) {
        expect(ChessGame.squareIndex(bad), isNull, reason: '$bad');
      }
      for (var i = 0; i < 64; i++) {
        expect(ChessGame.squareIndex(ChessGame.squareName(i)), i);
      }
    });

    test('a move updates board, turn, history with SAN, and the payload', () {
      final g = ChessGame();
      final e = g.applyMove(mv('g1', 'f3'))!;
      expect(g.currentPlayer, Player.b);
      expect(g.pieceAt('f3')!.fen, 'N');
      expect(g.pieceAt('g1'), isNull);
      expect(g.history.single, {'action': 'move', 'from': 'g1', 'to': 'f3', 'san': 'Nf3'});
      expect(g.sanHistory, ['Nf3']);
      expect(e.winner, isNull);
      expect(e.draw, isFalse);
      expect(e.payload, {
        'from': 'g1',
        'to': 'f3',
        'piece': 'n',
        'san': 'Nf3',
        'capture': null,
        'captureSquare': null,
        'enPassant': false,
        'castle': null,
        'promotion': null,
        'check': false,
        'mate': false,
      });
    });

    test('the history replays to the same position', () {
      final g = play(['e4', 'c5', 'Nf3', 'd6', 'd4', 'cxd4', 'Nxd4', 'Nf6', 'Nc3', 'a6']);
      final r = replay(const GameConfig('chess'), g.history)!;
      expect((r as ChessGame).fen, g.fen);
    });
  });

  group('piece moves', () {
    // The h7 pawn keeps these from being drawn by insufficient material.
    String withPiece(String piece) => 'k7/7p/8/8/3${piece}4/8/8/7K w - - 0 1';

    test('rook, bishop, queen and knight from d4 on an empty board', () {
      expect(targets(ChessGame.fromFen(withPiece('R')), 'd4'), hasLength(14));
      expect(targets(ChessGame.fromFen(withPiece('B')), 'd4'), hasLength(13));
      expect(targets(ChessGame.fromFen(withPiece('Q')), 'd4'), hasLength(27));
      expect(targets(ChessGame.fromFen(withPiece('N')), 'd4'),
          {'b3', 'b5', 'c2', 'c6', 'e2', 'e6', 'f3', 'f5'});
    });

    test('a knight in the corner, a king in the middle', () {
      expect(targets(ChessGame.fromFen('k7/7p/8/8/8/8/8/N6K w - - 0 1'), 'a1'), {'b3', 'c2'});
      expect(targets(ChessGame.fromFen('k7/7p/8/8/4K3/8/8/8 w - - 0 1'), 'e4'),
          {'d3', 'd4', 'd5', 'e3', 'e5', 'f3', 'f4', 'f5'});
    });

    test('sliders stop before own pieces and on enemy pieces', () {
      final g = ChessGame.fromFen('k7/8/3P4/8/3R4/8/3p4/7K w - - 0 1');
      expect(targets(g, 'd4'), {'d5', 'd3', 'd2', 'a4', 'b4', 'c4', 'e4', 'f4', 'g4', 'h4'});
    });

    test('the king never steps into check', () {
      // The black rook on d8 covers the whole d-file.
      final g = ChessGame.fromFen('3rk3/8/8/8/8/8/8/4K3 w - - 0 1');
      expect(targets(g, 'e1'), {'e2', 'f1', 'f2'});
    });

    test('pawns: one or two squares from the start, one later, blocked, diagonal captures', () {
      final g = ChessGame();
      expect(targets(g, 'e2'), {'e3', 'e4'});
      play(['e4', 'e5'], g);
      expect(targets(g, 'e4'), isEmpty, reason: 'blocked');
      expect(targets(g, 'd2'), {'d3', 'd4'});
      final h = play(['e4', 'd5']);
      expect(targets(h, 'e4'), {'e5', 'd5'});
      final k = play(['e3', 'a6']);
      expect(targets(k, 'e3'), {'e4'}, reason: 'no double step after the first move');
      expect(targets(play(['e4']), 'e7'), {'e6', 'e5'}, reason: 'Black moves down the board');
    });

    test('a pinned piece cannot move', () {
      final g = ChessGame.fromFen('4k3/4r3/8/8/8/8/4B3/4K3 w - - 0 1');
      expect(g.legalMovesFrom('e2'), isEmpty);
    });
  });

  group('castling', () {
    const both = 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1';

    test('both sides, with the rook jumping over and the payload', () {
      final g = ChessGame.fromFen(both);
      expect(targets(g, 'e1'), containsAll(['g1', 'c1']));
      expect(g.sanOf(mv('e1', 'g1')), 'O-O');
      final e = g.applyMove(mv('e1', 'g1'))!;
      expect(g.pieceAt('g1')!.fen, 'K');
      expect(g.pieceAt('f1')!.fen, 'R');
      expect(g.pieceAt('h1'), isNull);
      expect(g.fen.split(' ')[2], 'kq');
      expect((e.payload as Map)['castle'], 'kingside');
      final e2 = g.applyMove(mv('e8', 'c8'))!;
      expect(g.pieceAt('c8')!.fen, 'k');
      expect(g.pieceAt('d8')!.fen, 'r');
      expect(g.pieceAt('a8'), isNull);
      expect(g.fen.split(' ')[2], '-');
      expect((e2.payload as Map)['castle'], 'queenside');
      expect(g.sanHistory, ['O-O', 'O-O-O']);
    });

    test('not out of check', () {
      final g = ChessGame.fromFen('4k3/8/8/4r3/8/8/8/R3K2R w KQ - 0 1');
      expect(g.isInCheck, isTrue);
      expect(targets(g, 'e1'), isNot(anyOf(contains('g1'), contains('c1'))));
    });

    test('not through check, not into check', () {
      final through = ChessGame.fromFen('4k3/8/8/5r2/8/8/8/R3K2R w KQ - 0 1');
      expect(targets(through, 'e1'), isNot(contains('g1')));
      expect(targets(through, 'e1'), contains('c1'));
      final into = ChessGame.fromFen('4k3/8/8/6r1/8/8/8/R3K2R w KQ - 0 1');
      expect(targets(into, 'e1'), isNot(contains('g1')));
      expect(targets(into, 'e1'), contains('c1'));
      final queenSide = ChessGame.fromFen('4k3/8/8/3r4/8/8/8/R3K2R w KQ - 0 1');
      expect(targets(queenSide, 'e1'), isNot(contains('c1')));
      expect(targets(queenSide, 'e1'), contains('g1'));
    });

    test('an attacked b1 does not stop the long castle; a piece on b1 does', () {
      final attacked = ChessGame.fromFen('4k3/8/8/1r6/8/8/8/R3K2R w KQ - 0 1');
      expect(targets(attacked, 'e1'), containsAll(['c1', 'g1']));
      final blocked = ChessGame.fromFen('4k3/8/8/8/8/8/8/RN2K2R w KQ - 0 1');
      expect(targets(blocked, 'e1'), isNot(contains('c1')));
      expect(targets(blocked, 'e1'), contains('g1'));
    });

    test('a king that moved has lost both rights', () {
      final g = play(['e1e2', 'e8d8', 'e2e1', 'd8e8'], ChessGame.fromFen('4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1'));
      expect(g.fen.split(' ')[2], '-');
      expect(targets(g, 'e1'), isNot(anyOf(contains('g1'), contains('c1'))));
    });

    test('a rook that moved has lost its side only', () {
      final g = play(['h1h2', 'e8d8', 'h2h1', 'd8e8'], ChessGame.fromFen('4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1'));
      expect(g.fen.split(' ')[2], 'Q');
      expect(targets(g, 'e1'), contains('c1'));
      expect(targets(g, 'e1'), isNot(contains('g1')));
    });

    test('a captured rook takes its right along', () {
      final g = ChessGame.fromFen(both)..applyMove(mv('a1', 'a8'));
      expect(g.fen.split(' ')[2], 'Kk');
    });
  });

  group('en passant', () {
    test('right after the double step, then never again', () {
      final g = play(['e4', 'a6', 'e5', 'd5']);
      expect(g.fen.split(' ')[3], 'd6');
      expect(targets(g, 'e5'), contains('d6'));
      expect(g.sanOf(mv('e5', 'd6')), 'exd6');
      final e = g.applyMove(mv('e5', 'd6'))!;
      expect(g.pieceAt('d5'), isNull, reason: 'the passed pawn is removed');
      expect(g.pieceAt('d6')!.fen, 'P');
      expect(e.payload, containsPair('enPassant', true));
      expect(e.payload, containsPair('capture', 'p'));
      expect(e.payload, containsPair('captureSquare', 'd5'));

      final late = play(['e4', 'a6', 'e5', 'd5', 'a3', 'h6']);
      expect(targets(late, 'e5'), {'e6'});
    });

    test('not when it would expose the own king along the rank', () {
      final g = ChessGame.fromFen('8/8/8/KPp4r/8/8/8/4k3 w - c6 0 1');
      expect(targets(g, 'b5'), {'b6'});
    });
  });

  group('promotion', () {
    test('the piece must be chosen; all four are offered', () {
      final g = ChessGame.fromFen('8/4P3/8/8/8/8/k7/4K3 w - - 0 1');
      expect(g.legalMovesFrom('e7').map((m) => m['promotion']).toSet(), {'q', 'r', 'b', 'n'});
      final before = g.fen;
      expect(g.applyMove(mv('e7', 'e8')), isNull, reason: 'no piece chosen');
      expect(g.applyMove(mv('e7', 'e8', 'k')), isNull);
      expect(g.applyMove(mv('e7', 'e8', 'Q')), isNull);
      expect(g.applyMove(mv('e7', 'e8', 'p')), isNull);
      expect(g.fen, before);
      final e = g.applyMove(mv('e7', 'e8', 'n'))!;
      expect(g.pieceAt('e8'), const ChessPiece(Player.a, ChessPieceType.knight));
      expect(e.payload, containsPair('promotion', 'n'));
      expect(e.payload, containsPair('piece', 'p'));
      expect(g.sanHistory, ['e8=N']);
      expect(g.history.single['promotion'], 'n');
    });

    test('with a capture and check', () {
      final g = ChessGame.fromFen('3r3k/4P3/8/8/8/8/8/K7 w - - 0 1');
      final e = g.applyMove(mv('e7', 'd8', 'q'))!;
      expect(g.sanHistory, ['exd8=Q+']);
      expect(e.payload, containsPair('capture', 'r'));
      expect(e.payload, containsPair('check', true));
      expect(g.isInCheck, isTrue);
    });

    test('Black promotes on the first rank; no promotion on other moves', () {
      final g = ChessGame.fromFen('K7/8/8/8/8/8/4p3/k7 b - - 0 1')..applyMove(mv('e2', 'e1', 'r'));
      expect(g.pieceAt('e1'), const ChessPiece(Player.b, ChessPieceType.rook));
      expect(ChessGame().applyMove(mv('e2', 'e4', 'q')), isNull);
    });
  });

  group('check and checkmate', () {
    test('a check must be answered', () {
      final g = play(['e4', 'f5', 'Qh5+']);
      expect(g.isInCheck, isTrue);
      expect(g.sanHistory.last, 'Qh5+');
      expect(g.legalMoves, [mv('g7', 'g6')]);
      expect(g.applyMove(mv('e8', 'f7')), isNull);
    });

    test("Fool's mate: Black wins", () {
      final g = ChessGame();
      final t = ChessText(game: g);
      GameEvent? last;
      for (final s in ['f3', 'e5', 'g4', 'Qh4#']) {
        last = g.applyMove(t.parse(s)!);
      }
      expect(last!.winner, Player.b);
      expect(last.payload, containsPair('mate', true));
      expect(last.payload, containsPair('check', true));
      expect(g.isOver, isTrue);
      expect(g.isInCheck, isTrue);
      expect(g.result.winner, Player.b);
      expect(g.result.code, GameEndReason.chessCheckmate);
      expect(g.result.reason, 'checkmate');
      expect(g.legalMoves, isEmpty);
      expect(g.sanHistory, ['f3', 'e5', 'g4', 'Qh4#']);
      expect(g.applyMove(mv('e2', 'e4')), isNull, reason: 'nothing after mate');
      expect(g.applyMove(Game.resignMove(Player.a)), isNull);
    });

    test("Scholar's mate: White wins", () {
      final g = play(['e4', 'e5', 'Bc4', 'Nc6', 'Qh5', 'Nf6', 'Qxf7#']);
      expect(g.result.winner, Player.a);
      expect(g.result.code, GameEndReason.chessCheckmate);
      expect(g.fen, 'r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4');
    });

    test('a checkmate position from FEN is over at once', () {
      final g = ChessGame.fromFen('rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3');
      expect(g.isOver, isTrue);
      expect(g.result.winner, Player.b);
    });
  });

  group('draws', () {
    test('stalemate', () {
      final g = ChessGame.fromFen('7k/8/6K1/8/8/8/5Q2/8 w - - 0 1');
      final e = g.applyMove(mv('f2', 'f7'))!;
      expect(e.draw, isTrue);
      expect(e.winner, isNull);
      expect(g.isInCheck, isFalse);
      expect(g.result.draw, isTrue);
      expect(g.result.code, GameEndReason.chessStalemate);
      expect(g.legalMoves, isEmpty);
    });

    group('insufficient material', () {
      test('a capture down to king against king', () {
        final g = ChessGame.fromFen('8/8/8/8/8/1k6/3r4/3K4 w - - 0 1');
        final e = g.applyMove(mv('d1', 'd2'))!;
        expect(e.draw, isTrue);
        expect(g.result.code, GameEndReason.chessInsufficientMaterial);
      });

      const drawn = {
        'K v K': '8/8/8/4k3/8/8/8/4K3 w - - 0 1',
        'K+B v K': '8/8/8/4k3/8/8/8/2B1K3 w - - 0 1',
        'K+N v K': '8/8/8/4k3/8/8/8/1N2K3 b - - 0 1',
        'K+B v K+B, same colour': '5b2/8/8/4k3/8/8/8/2B1K3 w - - 0 1',
        'K+B+B v K, same colour': '8/8/8/4k3/8/4B3/8/2B1K3 w - - 0 1',
      };
      const playable = {
        'K+B v K+B, opposite colours': '2b5/8/8/4k3/8/8/8/2B1K3 w - - 0 1',
        'K+N+N v K': '8/8/8/4k3/8/8/8/1N2K1N1 w - - 0 1',
        'K+N v K+N': '6n1/8/8/4k3/8/8/8/1N2K3 w - - 0 1',
        'K+B v K+N': '6n1/8/8/4k3/8/8/8/2B1K3 w - - 0 1',
        'K+P v K': '8/8/8/4k3/8/8/4P3/4K3 w - - 0 1',
        'K+R v K': '8/8/8/4k3/8/8/8/R3K3 w - - 0 1',
      };
      drawn.forEach((name, fen) {
        test('$name is a draw', () {
          final g = ChessGame.fromFen(fen);
          expect(g.isOver, isTrue, reason: name);
          expect(g.result.code, GameEndReason.chessInsufficientMaterial);
        });
      });
      playable.forEach((name, fen) {
        test('$name plays on', () => expect(ChessGame.fromFen(fen).isOver, isFalse, reason: name));
      });
    });

    group('75-move rule', () {
      test('the 150th half-move without capture or pawn move draws', () {
        final g = ChessGame.fromFen('8/8/8/4k3/8/8/8/R3K3 w - - 148 80');
        expect(g.applyMove(mv('a1', 'a2'))!.draw, isFalse);
        expect(g.halfmoveClock, 149);
        final e = g.applyMove(mv('e5', 'e6'))!;
        expect(e.draw, isTrue);
        expect(g.result.code, GameEndReason.chessSeventyFiveMoves);
        expect(g.result.params, {'moves': 75});
      });

      test('a capture or a pawn move resets the count', () {
        final capture = ChessGame.fromFen('8/8/8/4k3/8/8/p7/R3K3 w - - 149 80')..applyMove(mv('a1', 'a2'));
        expect(capture.isOver, isFalse);
        expect(capture.halfmoveClock, 0);
        final pawn = ChessGame.fromFen('8/8/8/4k3/8/8/4P3/R3K3 w - - 149 80')..applyMove(mv('e2', 'e3'));
        expect(pawn.isOver, isFalse);
        expect(pawn.halfmoveClock, 0);
      });

      test('a mate on the 150th half-move is a mate', () {
        final g = ChessGame.fromFen('k7/8/1K6/8/8/8/8/7R w - - 149 80');
        final e = g.applyMove(mv('h1', 'h8'))!;
        expect(e.winner, Player.a);
        expect(g.result.code, GameEndReason.chessCheckmate);
      });
    });

    group('threefold repetition', () {
      test('the third occurrence draws at once', () {
        final g = play(['Nf3', 'Nf6', 'Ng1', 'Ng8', 'Nf3', 'Nf6', 'Ng1']);
        expect(g.isOver, isFalse, reason: 'the start position occurred twice');
        final e = g.applyMove(mv('f6', 'g8'))!;
        expect(e.draw, isTrue);
        expect(g.result.code, GameEndReason.chessThreefoldRepetition);
        expect(g.result.params, {'times': 3});
        expect(g.legalMoves, isEmpty);
      });

      test('an en passant square without a legal capture does not count', () {
        // After 1.e4 the FEN names e3, but no black pawn can take: the
        // position is the same as after 3.Ng1.
        final g = play(['e4', 'Nf6', 'Nf3', 'Ng8', 'Ng1', 'Nf6', 'Nf3', 'Ng8']);
        expect(g.isOver, isFalse);
        g.applyMove(mv('f3', 'g1'));
        expect(g.result.code, GameEndReason.chessThreefoldRepetition);
      });

      test('lost castling rights make a different position', () {
        final g = ChessGame.fromFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
        const cycle = ['h1h2', 'h8h7', 'h2h1', 'h7h8'];
        play([...cycle, ...cycle], g);
        expect(g.isOver, isFalse, reason: 'same pieces as the start, but without the kingside rights');
        g.applyMove(mv('h1', 'h2'));
        expect(g.isOver, isFalse);
        g.applyMove(mv('h8', 'h7'));
        expect(g.result.code, GameEndReason.chessThreefoldRepetition);
      });
    });
  });

  group('FEN', () {
    test('round-trips', () {
      for (final fen in [
        ChessGame.startFen,
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
        '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
        'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
        'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8',
        '8/8/8/KPp4r/8/8/8/4k3 w - c6 0 1',
        'rnbqkbnr/pppp1ppp/8/8/3Pp3/8/PPP1PPPP/RNBQKBNR b Qk d3 0 3',
      ]) {
        expect(ChessGame.fromFen(fen).fen, fen);
      }
    });

    test('follows the moves: en passant square, clocks, move number', () {
      final g = play(['e4']);
      expect(g.fen, 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1');
      play(['c5', 'Nf3'], g);
      expect(g.fen, 'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2');
      expect(g.fullmoveNumber, 2);
      expect(ChessGame.fromFen(g.fen).fen, g.fen);
    });

    test('a FEN game continues with the side to move and restarts from its FEN', () {
      const fen = 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1';
      final g = ChessGame.fromFen(fen);
      expect(g.currentPlayer, Player.b);
      expect(g.startPosition, fen);
      expect(ChessText(game: g).restart().game.fen, fen);
    });

    test('drops castling rights without king or rook; clocks may be left out', () {
      expect(ChessGame.fromFen('4k3/8/8/8/8/8/8/4K3 w KQkq - 0 1').fen, '4k3/8/8/8/8/8/8/4K3 w - - 0 1');
      expect(ChessGame.fromFen('4k3/8/8/8/8/8/8/4K2R w KQ -').fen, '4k3/8/8/8/8/8/8/4K2R w K - 0 1');
    });

    test('rejects malformed or impossible positions', () {
      for (final bad in [
        '',
        'nonsense',
        'rnbqkbnr/pppppppp/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', // 7 ranks
        'rnbqkbnr/pppppppp/9/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', // bad digit
        'rnbqkbnr/pppppppp/7/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', // short rank
        'rnbqkbnr/ppppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', // long rank
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNX w KQkq - 0 1', // bad piece
        '4k3/8/8/8/8/8/8/3KK3 w - - 0 1', // two white kings
        '8/8/8/8/8/8/8/4K3 w - - 0 1', // no black king
        'P3k3/8/8/8/8/8/8/4K3 w - - 0 1', // pawn on rank 8
        '4k3/8/8/8/8/8/8/p3K3 b - - 0 1', // pawn on rank 1
        '4k3/8/8/8/8/8/8/4K3 x - - 0 1', // side to move
        '4k3/8/8/8/8/8/8/4K3 w KX - 0 1', // castling field
        '4k3/8/8/8/8/8/8/4K3 w QK - 0 1', // castling order
        '4k3/8/8/8/8/8/8/4K3 w - e9 0 1', // en passant square
        '4k3/8/8/8/8/8/8/4K3 w - e6 0 1', // en passant without the pawn
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e3 0 1', // e3 with White to move
        '4k3/8/8/8/8/8/8/4K3 w - - -1 1', // half-move clock
        '4k3/8/8/8/8/8/8/4K3 w - - 0 0', // full-move number
        '4k3/8/8/8/8/8/8/4K3 w - - 0', // five fields
        '4k3/8/8/8/8/8/8/4R1K1 w - - 0 1', // Black in check with White to move
      ]) {
        expect(() => ChessGame.fromFen(bad), throwsFormatException, reason: bad);
      }
    });
  });

  group('illegal moves', () {
    test('are rejected and change nothing', () {
      final g = play(['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'd6']); // the c6 knight is pinned
      final fen = g.fen;
      final history = g.history.length;
      for (final bad in <Map<String, dynamic>>[
        mv('c6', 'd4'), // not your piece, not your turn
        mv('e1', 'e3'), // a king step of two squares
        mv('b5', 'e8'), // a bishop through pieces
        mv('a2', 'a5'), // a pawn three squares
        mv('e4', 'e5'), // a pawn straight into a piece
        mv('f3', 'f5'), // a knight moving like a rook
        mv('e4', 'd5'), // a pawn capture onto an empty square
        mv('e2', 'e3'), // an empty square
        mv('e4', 'e5', 'q'), // promotion off the last rank
        mv('i1', 'e2'), // off the board
        {'action': 'move', 'from': 12, 'to': 28},
        {'action': 'move', 'from': 'g1'},
        {'action': 'place', 'from': 'b1', 'to': 'c3'},
        {'from': 'b1', 'to': 'c3'},
        {'action': 'move', 'from': 'b1', 'to': 'c3', 'promotion': 7},
      ]) {
        expect(g.applyMove(bad), isNull, reason: '$bad');
        expect(g.fen, fen, reason: '$bad');
        expect(g.history, hasLength(history));
        expect(g.currentPlayer, Player.a);
      }
      g.applyMove(mv('a2', 'a3'));
      expect(g.applyMove(mv('c6', 'e7')), isNull, reason: 'pinned knight');
    });

    test('a move that leaves the own king in check is refused', () {
      final g = ChessGame.fromFen('4k3/8/8/8/8/2N5/3PPP2/r3K3 w - - 0 1');
      expect(g.isInCheck, isTrue);
      expect(g.applyMove(mv('e2', 'e3')), isNull);
      expect(g.legalMoves, unorderedEquals([mv('c3', 'b1'), mv('c3', 'd1')]));
    });
  });

  group('resign', () {
    test('either player, any time, through the common move', () {
      final g = play(['e4']);
      expect(g.playerOf(Game.resignMove(Player.a)), Player.a);
      final e = g.applyMove(Game.resignMove(Player.a))!;
      expect(e.winner, Player.b);
      expect(g.result.code, GameEndReason.commonResigned);
      expect(g.legalMoves, isEmpty);
      expect(g.legalMovesFrom('e7'), isEmpty);
      expect(g.sanOf(mv('e7', 'e5')), isNull);
      expect(g.applyMove(mv('e7', 'e5')), isNull);
    });
  });

  group('SAN', () {
    test('file, rank and full-square disambiguation', () {
      final knights = ChessGame.fromFen('4k3/8/8/8/8/5N2/8/1N2K3 w - - 0 1');
      expect(knights.sanOf(mv('b1', 'd2')), 'Nbd2');
      expect(knights.sanOf(mv('f3', 'd2')), 'Nfd2');
      expect(knights.sanOf(mv('f3', 'e5')), 'Ne5');
      final rooks = ChessGame.fromFen('4k3/8/8/R7/8/8/8/R3K3 w - - 0 1');
      expect(rooks.sanOf(mv('a1', 'a3')), 'R1a3');
      expect(rooks.sanOf(mv('a5', 'a3')), 'R5a3');
      final queens = ChessGame.fromFen('4k3/8/8/8/8/Q7/8/Q1Q1K3 w - - 0 1');
      expect(queens.sanOf(mv('a1', 'b2')), 'Qa1b2');
      expect(queens.sanOf(mv('a3', 'b2')), 'Q3b2');
      expect(queens.sanOf(mv('c1', 'b2')), 'Qcb2');
    });

    test('a pinned rival needs no disambiguation', () {
      // Both knights reach d2, but the e4 knight is pinned by the e8 rook.
      final g = ChessGame.fromFen('4r2k/8/8/8/4N3/8/8/1N2K3 w - - 0 1');
      expect(g.sanOf(mv('b1', 'd2')), 'Nd2');
    });

    test('captures, castling with check, illegal moves', () {
      final g = play(['e4', 'd5']);
      expect(g.sanOf(mv('e4', 'd5')), 'exd5');
      expect(g.sanOf(mv('d1', 'h5')), 'Qh5');
      expect(g.sanOf(mv('e4', 'e6')), isNull);
      expect(ChessGame.fromFen('5k2/8/8/8/8/8/8/4K2R w K - 0 1').sanOf(mv('e1', 'g1')), 'O-O+');
    });
  });

  group('ChessText', () {
    test('parses long algebraic and SAN', () {
      final t = ChessText();
      expect(t.parse('e2e4'), mv('e2', 'e4'));
      expect(t.parse(' E2-E4 '), mv('e2', 'e4'));
      expect(t.parse('e7e8q'), mv('e7', 'e8', 'q'));
      expect(t.parse('Nf3'), mv('g1', 'f3'));
      expect(t.parse('e4'), mv('e2', 'e4'));
      expect(t.parse('Nf6'), isNull, reason: 'not legal for White');
      expect(t.parse('xyz'), isNull);
      expect(t.parse(''), isNull);
      final c = ChessText(game: ChessGame.fromFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'));
      expect(c.parse('O-O'), mv('e1', 'g1'));
      expect(c.parse('0-0-0'), mv('e1', 'c1'));
      final p = ChessText(game: ChessGame.fromFen('3r3k/4P3/8/8/8/8/8/K7 w - - 0 1'));
      expect(p.parse('exd8=Q+'), mv('e7', 'd8', 'q'));
      expect(p.parse('e8N'), mv('e7', 'e8', 'n'));
      expect(t.format(mv('e7', 'e8', 'q')), 'e7e8q');
    });

    test('renders the board with White at the bottom', () {
      final r = ChessText().render();
      expect(r.split('\n').first, '8  r n b q k b n r');
      expect(r, contains('1  R N B Q K B N R'));
      expect(r, endsWith('   a b c d e f g h'));
      expect(ChessText(game: play(['e4', 'f5', 'Qh5+'])).render(), endsWith('Ben (Black) is in check.'));
    });

    test('autoMove takes a mate in one, else the biggest capture', () {
      final mate = ChessText(game: play(['e4', 'e5', 'Bc4', 'Nc6', 'Qh5', 'Nf6']));
      for (var seed = 0; seed < 5; seed++) {
        expect(mate.autoMove(Random(seed)), mv('h5', 'f7'));
      }
      final capture = ChessText(game: play(['e4', 'd5']));
      expect(capture.autoMove(Random(1)), mv('e4', 'd5'));
    });

    test('narrates castling, en passant, promotion and the end', () {
      final c = DebugConsole('chess');
      expect(c.handle('e4'), startsWith('Anna (White) plays e4 (pawn e2-e4).'));
      c.handle('a6');
      c.handle('e5');
      c.handle('d5');
      expect(c.handle('exd6'), startsWith('Anna (White) plays exd6 (pawn e5-d6, takes the pawn en passant).'));
      expect(c.handle('resign'), startsWith('Ben (Black) resigns. Anna (White) wins.'));
      final p = DebugConsole('chess');
      expect(p.current.status(), 'Anna (White) to move');
    });

    test('the demo replays a famous short game to mate', () {
      final out = DebugConsole().demo('chess');
      expect(out, contains('Anna (White) plays O-O-O (castles queenside).'));
      expect(out, contains('Ben (Black) plays Nbd7'));
      expect(out, endsWith('Result: Anna (White) wins (checkmate) after 33 moves.'));
    });

    test('random games end with a known code', () {
      for (var seed = 0; seed < 10; seed++) {
        final c = DebugConsole('chess', seed)..handle('auto');
        final r = c.current.game.result;
        expect(r.isOver, isTrue, reason: 'seed $seed');
        expect(r.code!.code, startsWith('chess.'));
      }
    });
  });
}
