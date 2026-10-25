import 'package:test/test.dart';
import 'package:klunki_engine/klunki_engine.dart';

/// Plays [cols] in order and returns the game. Fails the test if any move
/// before the last is rejected.
Connect4Game play(List<int> cols) {
  final g = Connect4Game();
  for (var i = 0; i < cols.length; i++) {
    final e = g.applyMove({'col': cols[i]});
    expect(e, isNotNull, reason: 'move $i (col ${cols[i]}) was rejected');
  }
  return g;
}

void main() {
  group('Connect Four wins', () {
    test('horizontal win', () {
      final g = play([0, 0, 1, 1, 2, 2, 3]);
      expect(g.isOver, isTrue);
      expect(g.result.winner, Player.a);
      expect(g.result.draw, isFalse);
      expect(g.result.reason, 'four in a row');
    });

    test('vertical win', () {
      final g = play([3, 4, 3, 4, 3, 4, 3]);
      expect(g.isOver, isTrue);
      expect(g.result.winner, Player.a);
    });

    test('rising diagonal win', () {
      // A ends on (0,0) (1,1) (2,2) (3,3).
      final g = play([0, 1, 1, 2, 2, 3, 2, 3, 3, 6, 3]);
      expect(g.isOver, isTrue);
      expect(g.result.winner, Player.a);
      expect(g.board[3][3], Player.a);
    });

    test('falling diagonal win', () {
      // A ends on (6,0) (5,1) (4,2) (3,3).
      final g = play([6, 5, 5, 4, 4, 3, 4, 3, 3, 0, 3]);
      expect(g.isOver, isTrue);
      expect(g.result.winner, Player.a);
      expect(g.board[3][3], Player.a);
    });

    test('player B can win', () {
      final g = play([6, 0, 6, 1, 5, 2, 6, 3]);
      expect(g.isOver, isTrue);
      expect(g.result.winner, Player.b);
    });

    test('regression: dropping into the gap completes a line', () {
      // A holds cols 0,1,3 on row 0; the final drop in col 2 fills the gap.
      final g = Connect4Game();
      for (final c in [0, 0, 1, 1, 3, 3]) {
        g.applyMove({'col': c});
      }
      expect(g.isOver, isFalse);
      final e = g.applyMove({'col': 2});
      expect(e, isNotNull);
      expect(e!.winner, Player.a);
      expect(e.payload, {'col': 2, 'row': 0});
      expect(g.isOver, isTrue);
      expect(g.result.winner, Player.a);
    });

    test('three in a row is not a win', () {
      final g = play([0, 0, 1, 1, 2, 2]);
      expect(g.isOver, isFalse);
      expect(g.result.winner, isNull);
    });
  });

  group('Connect Four invalid moves', () {
    test('full column returns null', () {
      final g = play([0, 0, 0, 0, 0, 0]);
      expect(g.applyMove({'col': 0}), isNull);
      expect(g.history.length, 6);
      expect(g.currentPlayer, Player.a);
      expect(g.result.winner, isNull);
    });

    test('out-of-range columns return null', () {
      final g = Connect4Game();
      expect(g.applyMove({'col': -1}), isNull);
      expect(g.applyMove({'col': 7}), isNull);
      expect(g.history, isEmpty);
      expect(g.currentPlayer, Player.a);
      expect(g.result.winner, isNull);
    });

    test('move after game over returns null', () {
      final g = play([0, 0, 1, 1, 2, 2, 3]);
      expect(g.result.winner, Player.a);
      expect(g.applyMove({'col': 5}), isNull);
      expect(g.history.length, 7);
      expect(g.board[5][0], isNull);
      expect(g.result.winner, Player.a);
    });
  });

  group('Connect Four draw', () {
    // Fixed 42-move game that fills the board without any four-in-a-row.
    const drawGame = [
      6, 2, 3, 1, 2, 5, 0, 4, 0, 1, 5, 1, 1, 3, 6, 0, 6, 3, 2, 2, 4, //
      3, 3, 4, 2, 6, 0, 5, 1, 0, 4, 4, 4, 6, 1, 6, 0, 3, 5, 5, 5, 2,
    ];

    test('regression: a full bottom row is not a draw', () {
      final g = play([6, 2, 3, 1, 2, 5, 0, 4]); // fills row 0, no line
      expect(g.isOver, isFalse);
      expect(g.result.draw, isFalse);
      expect(g.result.winner, isNull);
    });

    test('full board without a line is a draw', () {
      final g = Connect4Game();
      for (var i = 0; i < drawGame.length; i++) {
        expect(g.isOver, isFalse, reason: 'game ended early at move $i');
        final e = g.applyMove({'col': drawGame[i]});
        expect(e, isNotNull);
        expect(e!.winner, isNull);
        if (i == drawGame.length - 1) expect(e.draw, isTrue);
      }
      expect(g.isOver, isTrue);
      expect(g.result.draw, isTrue);
      expect(g.result.winner, isNull);
      expect(g.result.reason, 'board full');
      expect(g.history.length, 42);
      expect(g.legalMoves, isEmpty);
    });
  });

  group('Connect Four state', () {
    test('currentPlayer alternates', () {
      final g = Connect4Game();
      expect(g.currentPlayer, Player.a);
      g.applyMove({'col': 0});
      expect(g.currentPlayer, Player.b);
      g.applyMove({'col': 1});
      expect(g.currentPlayer, Player.a);
      g.applyMove({'col': 0});
      expect(g.currentPlayer, Player.b);
      expect(g.result.winner, isNull);
    });

    test('history records col, row and player', () {
      final g = play([3, 3, 4]);
      expect(g.history, [
        {'col': 3, 'row': 0, 'player': Player.a},
        {'col': 3, 'row': 1, 'player': Player.b},
        {'col': 4, 'row': 0, 'player': Player.a},
      ]);
      expect(g.result.winner, isNull);
    });

    test('legalMoves shrinks when a column fills', () {
      final g = Connect4Game();
      expect(g.legalMoves, [0, 1, 2, 3, 4, 5, 6]);
      for (var i = 0; i < 5; i++) {
        g.applyMove({'col': 2});
      }
      expect(g.legalMoves, contains(2));
      g.applyMove({'col': 2});
      expect(g.legalMoves, [0, 1, 3, 4, 5, 6]);
      expect(g.result.winner, isNull);
    });

    test('legalMoves is empty after a win', () {
      final g = play([0, 0, 1, 1, 2, 2, 3]);
      expect(g.result.winner, Player.a);
      expect(g.legalMoves, isEmpty);
    });

    test('toRenderRows puts row 0 at the bottom', () {
      final g = play([0, 0]);
      final rows = g.toRenderRows();
      expect(rows.last[0], Player.a);
      expect(rows[rows.length - 2][0], Player.b);
      expect(rows.first[0], isNull);
      expect(g.result.winner, isNull);
    });
  });
}
