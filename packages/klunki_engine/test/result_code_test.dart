import 'dart:math';

import 'package:test/test.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_engine/debug.dart';

/// Every finished game carries a machine-readable [GameEndReason] next to the
/// English reason, so the app can localize the result (I18N-05).
void main() {
  group('GameEndReason', () {
    test('codes are unique, `<game>.<reason>`, and round-trip', () {
      final codes = GameEndReason.values.map((r) => r.code).toList();
      expect(codes.toSet(), hasLength(codes.length));
      for (final r in GameEndReason.values) {
        expect(r.code, matches(RegExp(r'^(common|connect4|muehle|quartett|schiffe|gostrategy|chess|wordtiles|maumau|maexchen)\.[a-z][A-Za-z0-9]*$')));
        expect(GameEndReason.fromCode(r.code), r);
      }
      expect(GameEndReason.fromCode('nope.nope'), isNull);
    });

    test('a running game has no code, no params and no reason', () {
      for (final spec in gameSpecs) {
        final r = spec.create(1).result;
        expect(r.code, isNull, reason: spec.id);
        expect(r.params, isEmpty, reason: spec.id);
        expect(r.reason, isEmpty, reason: spec.id);
      }
    });
  });

  group('every finished game yields a known code', () {
    String prefix(String gameId) => gameId.split('-').first;

    for (final id in DebugConsole.games.keys) {
      test(id, () {
        for (var seed = 0; seed < 25; seed++) {
          final c = DebugConsole(id, seed)..handle('auto');
          final r = c.current.game.result;
          expect(r.isOver, isTrue, reason: '$id seed $seed');
          expect(GameEndReason.values, contains(r.code), reason: '$id seed $seed');
          expect(r.code!.code, startsWith('${prefix(id)}.'));
          expect(r.reason, isNotEmpty);
        }
      });
    }

    test('random Quartett (sets) games end with a quartet code and the counts', () {
      final rnd = Random(7);
      for (var i = 0; i < 20; i++) {
        final g = QuartettGame(QuartettMode.sets, seed: i, handSize: 1 + rnd.nextInt(16));
        var moves = 0;
        while (!g.isOver && moves++ < 10000) {
          final legal = g.legalMoves;
          g.applyMove(legal[rnd.nextInt(legal.length)]);
        }
        expect(g.result.code, anyOf(GameEndReason.quartettMostQuartets, GameEndReason.quartettAllQuartetsEqual));
        expect(g.result.params, {'a': g.quartetsOf(Player.a).length, 'b': g.quartetsOf(Player.b).length});
        expect(g.result.draw, g.result.code == GameEndReason.quartettAllQuartetsEqual);
      }
    });
  });
}
