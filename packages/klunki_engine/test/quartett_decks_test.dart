import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-069: themed Quartett decks.
void main() {
  test('the registry: cars (default), trains, rockets, planes', () {
    expect([for (final d in QuartettDeck.all) d.id], ['cars', 'trains', 'rockets', 'planes']);
    expect(QuartettDeck.byId(null), same(QuartettDeck.cars));
    expect(QuartettDeck.byId('trains'), same(QuartettDeck.trains));
    expect(QuartettDeck.byId('nope'), isNull);
    expect(QuartettDeck.defaultId, 'cars');
  });

  test('a stat id means the same in every deck (one translation per id)', () {
    final seen = <String, QuartettStat>{};
    for (final d in QuartettDeck.all) {
      for (final s in d.stats) {
        final other = seen.putIfAbsent(s.id, () => s);
        expect((s.label, s.unit, s.higherWins), (other.label, other.unit, other.higherWins), reason: s.id);
      }
    }
  });

  for (final deck in QuartettDeck.all) {
    group(deck.id, () {
      test('passes validation: 32 cards A1–H4, 8 named sets of 4, every stat on every card', () {
        expect(deck.validate(), isEmpty);
        expect(deck.cards, hasLength(32));
        expect(deck.stats.length, inInclusiveRange(5, 6));
        for (final set in deck.setNames.keys) {
          expect(deck.cardsOf(set), hasLength(4));
        }
        expect(deck.cards.every((c) => c.deck == deck.id), isTrue);
        expect(deck.cards.map((c) => c.name).toSet(), hasLength(32), reason: 'card names are unique');
      });

      test('ties are rare on every stat (Trumpf), and no stat has one value', () {
        for (final s in deck.stats) {
          expect(deck.tieRate(s.id), lessThan(0.03), reason: s.id);
          expect(deck.cards.map((c) => c.stats[s.id]).toSet().length, greaterThan(16), reason: s.id);
        }
      });

      for (final mode in QuartettMode.values) {
        test('random ${mode.name} games run to the end', () {
          for (var seed = 0; seed < 25; seed++) {
            final g = QuartettGame(mode, seed: seed, deck: deck, handSize: mode == QuartettMode.sets ? 8 : 16);
            final rng = Random(seed);
            var n = 0;
            while (!g.isOver) {
              final legal = g.legalMoves;
              expect(legal, isNotEmpty);
              expect(g.applyMove(legal[rng.nextInt(legal.length)]), isNotNull);
              expect(++n, lessThan(2000));
            }
            if (mode == QuartettMode.sets) {
              expect(g.quartetsOf(Player.a).length + g.quartetsOf(Player.b).length, 8);
            }
            final all = [
              for (final p in Player.values) ...[...g.stackOf(p), ...g.handOf(p)],
            ];
            expect(all.every((c) => c.deck == deck.id), isTrue);
          }
        });
      }

      test('the game uses the deck: its cards, stats and set names', () {
        final g = QuartettGame(QuartettMode.trumpf, seed: 3, deck: deck);
        expect(g.deck, same(deck));
        expect(g.stats, deck.stats);
        expect(g.legalMoves.map((m) => m['stat']), deck.stats.map((s) => s.id));
        expect(g.topCard(Player.a)!.deck, deck.id);
        expect(g.cardById('C2'), same(deck.cardById('C2')));
      });

      test('createGame and the views carry the deck', () {
        for (final id in ['quartett-trumpf', 'quartett-sets']) {
          final config = GameConfig(id, seed: 11, deck: deck.id);
          final g = createGame(config) as QuartettGame;
          expect(g.deck, same(deck));
          final redaction = specById(id)!.redaction!;
          final json = jsonDecode(jsonEncode(redaction.view(g, Player.b))) as Map<String, dynamic>;
          expect(json['deck'], deck.id);
          final view = redaction.fromView(json) as QuartettGame;
          expect(view.deck, same(deck));
          expect(canonicalJson(view.viewJson(Player.b)), canonicalJson(json));
        }
      });
    });
  }

  group('GameConfig.deck', () {
    test('round-trips through JSON; old configs without it get the car deck', () {
      const c = GameConfig('quartett-sets', seed: 5, deck: 'rockets');
      expect(c.toJson(), {'game': 'quartett-sets', 'seed': 5, 'deck': 'rockets'});
      expect(GameConfig.fromJson(jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>), c);
      expect(c.publicJson(), {'game': 'quartett-sets', 'deck': 'rockets'});
      expect(c.copyWith(seed: 6), const GameConfig('quartett-sets', seed: 6, deck: 'rockets'));
      expect(c, isNot(const GameConfig('quartett-sets', seed: 5, deck: 'trains')));

      final old = GameConfig.fromJson({'game': 'quartett-trumpf', 'seed': 5});
      expect(old.deck, isNull);
      expect(old.toJson(), {'game': 'quartett-trumpf', 'seed': 5});
      expect((createGame(old) as QuartettGame).deck, same(QuartettDeck.cars));
    });

    test('an unknown deck is refused; games without decks ignore it', () {
      const bad = GameConfig('quartett-trumpf', deck: 'submarines');
      expect(configProblem(bad), contains('unknown deck'));
      expect(() => createGame(bad), throwsArgumentError);
      expect(configProblem(const GameConfig('connect4', deck: 'trains')), isNull);
      expect(createGame(const GameConfig('connect4', deck: 'trains')), isA<Connect4Game>());
      expect(configProblem(const GameConfig('nope')), contains('unknown game'));
    });

    test('a view names its deck (none: pre-KLD-069 host, the car deck) and resolves cards in it', () {
      final g = QuartettGame(QuartettMode.trumpf, seed: 1);
      final json = g.viewJson(Player.a)..remove('deck');
      expect(QuartettView.fromJson(json).deck, same(QuartettDeck.cars));
      expect(() => QuartettView.fromJson({...json, 'deck': 'nope'}), throwsA(isA<BadViewException>()));
      expect(() => QuartettView.fromJson({...json, 'deck': 3}), throwsA(isA<BadViewException>()));
      final trains = QuartettGame(QuartettMode.trumpf, seed: 1, deck: QuartettDeck.trains);
      final v = QuartettView.fromJson(trains.viewJson(Player.a));
      expect(v.topCard(Player.a), same(trains.topCard(Player.a)));
      expect(v.topCard(Player.a)!.deck, 'trains');
    });
  });

  group('debug console', () {
    test('--deck picks the deck; "new <game> <deck>" switches', () {
      final c = DebugConsole('quartett-trumpf', 1, 'trains');
      expect(c.screen, startsWith('Quartett (Trumpf) – Züge'));
      expect((c.current.game as QuartettGame).deck.id, 'trains');
      expect(c.handle('help'), contains('tractiveKn'));
      expect(c.handle('new quartett-sets rockets'), startsWith('Quartett (Sets) – Raketen'));
      expect((c.current.game as QuartettGame).deck.id, 'rockets');
      expect(c.handle('new'), startsWith('Quartett (Sets) – Raketen'), reason: 'restart keeps the deck');
      expect(c.handle('new quartett-sets boats'), contains('Unknown deck'));
      expect(() => DebugConsole('quartett-sets', 1, 'boats'), throwsArgumentError);
      expect(DebugConsole('quartett-sets').screen, startsWith('Quartett (Sets)\n'));
      final auto = DebugConsole('quartett-trumpf', 1, 'planes')..handle('auto');
      expect(auto.current.game.isOver, isTrue);
    });
  });
}
