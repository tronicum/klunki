import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-094 step 10: "Restpunkte abziehen" can be turned off (rules version 5).
void main() {
  PlacedTile t(int row, int col, String tile) => PlacedTile(row, col, tile);
  const pass = {'action': 'pass'};

  WordTilesGame setup(List<List<String>> racks,
          {bool rest = true, List<String> bag = const [], WordCheck check = WordCheck.challenge, WordValidator? validator}) =>
      WordTilesGame(check: check, validator: validator, rackPenalty: rest)..debugSetup(racks: racks, bag: bag);

  group('Restpunkte abziehen', () {
    test('config: key `rest` only when off, round trip, public', () {
      const plain = GameConfig('wordtiles', seed: 3);
      expect(plain.rackPenalty, isTrue);
      expect(plain.toJson(), {'game': 'wordtiles', 'seed': 3});
      const off = GameConfig('wordtiles', seed: 3, rackPenalty: false);
      expect(off.toJson(), {'game': 'wordtiles', 'seed': 3, 'rest': false});
      expect(off.publicJson(), {'game': 'wordtiles', 'rest': false});
      expect(GameConfig.fromJson(off.toJson()), off);
      expect(GameConfig.fromJson(plain.toJson()), plain);
      expect(off.copyWith(seed: 4).rackPenalty, isFalse);
      expect(off == plain, isFalse);
      expect('$off', contains('rest: off'));
      expect((createGame(off) as WordTilesGame).rackPenalty, isFalse);
      expect((createGame(plain) as WordTilesGame).rackPenalty, isTrue);
    });

    test('rules version 5', () {
      expect(specById('wordtiles')!.rulesVersion, 5);
    });

    for (final rest in [true, false]) {
      test('scoreless end, rest ${rest ? 'on' : 'off'}', () {
        final g = setup([
          ['Q', 'A', 'A', 'A', 'A', 'A', 'A'], // 16
          ['X', 'Y', 'E', 'E', 'E', 'E', 'E'], // 21
        ], rest: rest, bag: const ['E', 'E', 'E', 'E', 'E', 'E', 'E']);
        for (var i = 0; i < 6; i++) {
          expect(g.applyMove(pass), isNotNull);
        }
        expect(g.isOver, isTrue);
        expect(g.result.code, GameEndReason.wordtilesScoreless);
        expect(g.rackPenalties, rest ? [-16, -21] : [0, 0]);
        expect(g.scores, rest ? [-16, -21] : [0, 0]);
        expect(g.result.draw, !rest, reason: 'without the deduction both have 0');
      });

      test('played out, rest ${rest ? 'on' : 'off'}', () {
        final g = setup([
          ['A', 'B'],
          ['Q', 'X', 'E'],
        ], rest: rest, check: WordCheck.dictionary, validator: WordListValidator(['ab']));
        g.applyMove(WordTilesGame.placeMove([t(7, 7, 'A'), t(7, 8, 'B')]));
        expect(g.isOver, isTrue);
        expect(g.result.code, GameEndReason.wordtilesPlayedOut);
        expect(g.rackPenalties, rest ? [19, -19] : [0, 0]);
        expect(g.scores, rest ? [25, -19] : [6, 0]);
        expect(g.result.winner, Player.a);
      });
    }

    test('the view carries the option and round-trips', () {
      final g = setup([
        ['A', 'B'],
        ['Q', 'X', 'E'],
      ], rest: false);
      final j = g.viewJson(Player.b);
      expect(j['rackPenalty'], false);
      expect(WordTilesView.fromJson(j).rackPenalty, isFalse);
      final on = setup([
        ['A', 'B'],
        ['Q', 'X', 'E'],
      ]);
      expect(on.viewJson(Player.b).containsKey('rackPenalty'), isFalse, reason: 'unchanged JSON with the default');
      expect(WordTilesView.fromJson(on.viewJson(Player.b)).rackPenalty, isTrue);
    });
  });
}
