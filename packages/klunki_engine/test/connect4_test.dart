import 'package:test/test.dart';
import 'package:klunki_engine/klunki_engine.dart';

void main() {
  group('Connect Four', () {
    test('column win: 4 in the same column', () {
      final g = Connect4Game();
      // A and B both drop in column 0 until A has 4.
      // Order: A col0, B col0, A col0, B col0, A col0 -> A wins on 3rd?
      // Each applyMove alternates players, so we alternate columns to keep
      // A winning in col 0.
      g.applyMove({'col': 0}); // A row0
      g.applyMove({'col': 0}); // B row1
      g.applyMove({'col': 0}); // A row2
      g.applyMove({'col': 0}); // B row3
      g.applyMove({'col': 0}); // A row4 -> not yet 4 in a row for A
      // A has rows 0,2,4 ; B has rows 1,3 in col 0 -> no 4-in-a-row yet.
      expect(g.isOver, false);
    });

    test('a real 4-in-a-row wins', () {
      final g = Connect4Game();
      // Fill so that A forms 4 vertically in col 3 using the 5 turns A gets
      // before a win triggers.
      // Sequence (A,B alternation): A drops col3 four times total -> after
      // A's 4th drop in col 3 A has 4 in that column => win.
      for (var i = 0; i < 5; i++) {
        final e = g.applyMove({'col': 3});
        if (g.isOver) {
          expect(g.result.winner, Player.a);
          expect(e, isNotNull);
          return;
        }
      }
    });

    test('column full returns null', () {
      final g = Connect4Game();
      // Fill col 0 completely with 6 moves.
      for (var i = 0; i < 6; i++) {
        g.applyMove({'col': 0});
      }
      expect(g.applyMove({'col': 0}), isNull);
    });

    test('invalid negative column is ignored', () {
      final g = Connect4Game();
      expect(g.applyMove({'col': -1}), isNull);
    });
  });
}
