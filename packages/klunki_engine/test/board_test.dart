import 'package:test/test.dart';
import 'package:klunki_engine/klunki_engine.dart';

void main() {
  group('Four in a Row board rendering', () {
    test('render rows are 6 rows x 7 cols', () {
      final g = Connect4Game();
      final rows = g.toRenderRows();
      expect(rows.length, 6);
      for (final r in rows) {
        expect(r.length, 7);
      }
    });

    test('bottom row is index last (row 0 at top after render)', () {
      final g = Connect4Game();
      g.applyMove({'col': 0}); // A at bottom of col 0
      final rows = g.toRenderRows();
      // Bottom row is the last rendered row.
      expect(rows.last[0], Player.a);
      expect(rows.first[0], isNull); // top empty
    });
  });
}
