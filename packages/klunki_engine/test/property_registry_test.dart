import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// Baulöwe in the registry (KLD-060 step 2, KLD-088 step 3): a seat-game
/// spec next to the two-player specs, config keys, the SeatGame view,
/// fingerprints and the public (redacted) step.
void main() {
  Map<String, dynamic> mv(String action, [Map<String, dynamic> more = const {}]) => {'action': action, ...more};

  group('registry', () {
    test('a seat game spec, not a two-player spec', () {
      final spec = seatSpecById('property')!;
      expect(spec.title, 'Baulöwe');
      expect((spec.minPlayers, spec.maxPlayers), (2, 6));
      expect(spec.rulesVersion, 1);
      expect(spec.secretSeed, isTrue);
      expect(specById('property'), isNull, reason: 'two-player transports, the session and the menu iterate gameSpecs');
      expect(gameSpecs.map((s) => s.id), isNot(contains('property')));
      expect(appGameSpecs.map((s) => s.id), isNot(contains('property')));
      expect(DebugConsole.games.keys, isNot(contains('property')));
      expect(seatSpecById('chess'), isNull);
      expect(() => createGame(const GameConfig('property')), throwsA(isA<ArgumentError>()));
    });

    test('createSeatGame builds the configured game', () {
      final g = createSeatGame(const GameConfig('property', seed: 4, players: 5, rounds: 20, theme: 'fantasie'))
          as PropertyGame;
      expect(g.playerCount, 5);
      expect(g.seed, 4);
      expect(g.maxRounds, 20);
      expect(g.theme.id, 'fantasie');
      final d = createSeatGame(const GameConfig('property')) as PropertyGame;
      expect((d.playerCount, d.maxRounds, d.theme.id), (2, null, 'berlin'));
      expect(() => createSeatGame(const GameConfig('property', players: 7)), throwsArgumentError);
      expect(() => createSeatGame(const GameConfig('property', theme: 'paris')), throwsArgumentError);
      expect(() => createSeatGame(const GameConfig('connect4')), throwsArgumentError);
    });

    test('configProblem: 2–6 players, a known theme, a round limit of 1–1000', () {
      for (var n = 2; n <= 6; n++) {
        expect(configProblem(GameConfig('property', players: n)), isNull);
      }
      expect(configProblem(const GameConfig('property', players: 1)), contains('2–6'));
      expect(configProblem(const GameConfig('property', players: 7)), contains('2–6'));
      expect(configProblem(const GameConfig('property', theme: 'fantasie', rounds: 30)), isNull);
      expect(configProblem(const GameConfig('property', theme: 'paris')), contains('unknown theme'));
      expect(configProblem(const GameConfig('property', rounds: 0)), contains('round limit'));
      expect(configProblem(const GameConfig('property', rounds: 1001)), contains('round limit'));
      expect(configProblem(const GameConfig('property', rounds: 1000)), isNull);
      // Two-player games are unchanged.
      expect(configProblem(const GameConfig('chess', players: 3)), contains('2 players'));
      expect(configProblem(const GameConfig('nope')), contains('unknown game'));
    });
  });

  group('GameConfig keys rounds and theme', () {
    test('written only when set; round-trip', () {
      const c = GameConfig('property', seed: 9, players: 4, rounds: 30, theme: 'fantasie');
      expect(c.toJson(), {'game': 'property', 'seed': 9, 'players': 4, 'rounds': 30, 'theme': 'fantasie'});
      expect(c.publicJson(), {'game': 'property', 'players': 4, 'rounds': 30, 'theme': 'fantasie'});
      expect(GameConfig.fromJson(c.toJson()), c);
      expect(GameConfig.fromJson(c.toJson()).hashCode, c.hashCode);
      expect(c.copyWith(seed: 1), const GameConfig('property', seed: 1, players: 4, rounds: 30, theme: 'fantasie'));
      expect(c, isNot(const GameConfig('property', seed: 9, players: 4, rounds: 20, theme: 'fantasie')));
      expect(c, isNot(const GameConfig('property', seed: 9, players: 4, rounds: 30)));
      expect(c.toString(), contains('rounds: 30'));
      expect(c.toString(), contains('theme: fantasie'));
    });

    test('every existing config is byte-identical (no new keys)', () {
      expect(const GameConfig('connect4', seed: 3).toJson(), {'game': 'connect4', 'seed': 3});
      expect(const GameConfig('property').toJson(), {'game': 'property', 'seed': 0});
      expect(GameConfig.fromJson({'game': 'chess', 'seed': 1}), const GameConfig('chess', seed: 1));
      expect(const GameConfig('chess').toString(), 'GameConfig(chess, seed: 0)');
    });
  });

  group('SeatGame', () {
    test('actor, seat of a move, seats out', () {
      final g = PropertyGame(playerCount: 3, dice: [1, 2]);
      final SeatGame s = g;
      expect(s.playerCount, 3);
      expect(s.actorSeat, 0);
      expect(s.seatOfMove(mv('roll')), 0);
      expect(s.seatOfMove(mv('resign', {'seat': 2})), 2);
      expect(s.applyMove(mv('roll')), isA<PropertyEvent>());
      expect(s.applyMove(mv('decline')), isNotNull);
      expect(s.actorSeat, 1, reason: 'the first bidder after the decliner');
      expect(s.applyMove(mv('resign', {'seat': 1})), isNotNull);
      expect(s.isSeatOut(1), isTrue);
      expect(s.isSeatOut(0), isFalse);
      expect(g.outSeats, [1]);
      expect(s.seatResult.isOver, isFalse);
      expect(s.seatResult.places, isEmpty);
      expect(s.history.length, 3);
      expect(s.applyMove(mv('roll')), isNull, reason: 'an auction is open');
    });

    test('last solvent: first place; the others by the order they left', () {
      final g = PropertyGame(playerCount: 4);
      g.applyMove(mv('resign', {'seat': 2}));
      g.applyMove(mv('resign', {'seat': 0}));
      expect(g.seatResult.isOver, isFalse);
      g.applyMove(mv('resign', {'seat': 3}));
      final r = g.seatResult;
      expect(r.isOver, isTrue);
      expect(r.code, 'property.lastSolvent');
      expect(r.winner, 1);
      expect(r.places, [3, 1, 4, 2]);
      expect(r.ranking, [1, 3, 0, 2]);
      expect(g.actorSeat, isNull);
      expect(g.toJson()['outOrder'], [2, 0, 3]);
    });

    test('round limit: places by net worth, ties share, seats out behind', () {
      final g = PropertyGame(playerCount: 4, maxRounds: 1, dice: [1, 2, 4, 6, 4, 6]);
      g.applyMove(mv('resign', {'seat': 3}));
      for (final m in ['roll', 'buy', 'endTurn', 'roll', 'endTurn', 'roll', 'endTurn']) {
        expect(g.applyMove(mv(m)), isNotNull, reason: m);
      }
      final r = g.seatResult;
      expect(r.isOver, isTrue);
      expect(r.code, 'property.roundLimit');
      expect(r.params, {'rounds': 1});
      // Seat 0 paid 60 for a 60 street: 1500; seats 1 and 2 kept 1500.
      expect(r.places, [1, 1, 1, 4]);
      expect(r.winners, [0, 1, 2]);
      expect(g.result.leaders, [0, 1, 2]);
    });

    test('round limit with a clear winner', () {
      final g = PropertyGame(maxRounds: 1, dice: [1, 2, 1, 3]);
      for (final m in ['roll', 'buy', 'endTurn', 'roll', 'endTurn']) {
        g.applyMove(mv(m));
      }
      expect(g.seatResult.places, [1, 2]);
      expect(g.seatResult.winner, 0);
    });
  });

  group('replay', () {
    test('replaySeatGame rebuilds a bot game; a bad log returns null', () {
      for (final players in [2, 4, 6]) {
        final config = GameConfig('property', seed: players * 7, players: players, rounds: 15);
        final g = createSeatGame(config) as PropertyGame;
        final bot = PropertyBot(Random(players));
        while (!g.isOver) {
          expect(g.applyMove(bot.choose(g)), isNotNull);
        }
        final r = replaySeatGame(config, jsonDecode(jsonEncode(g.history)).cast<Map<String, dynamic>>())!
            as PropertyGame;
        expect(jsonEncode(r.toJson()), jsonEncode(g.toJson()));
        expect(r.seatResult.places, g.seatResult.places);
        expect(r.seatResult.isOver, isTrue);
        expect(g.seatResult.places.where((p) => p == 1), isNotEmpty);
      }
      expect(replaySeatGame(const GameConfig('property'), [mv('buy')]), isNull);
    });
  });

  group('fingerprint', () {
    test('keyed by theme; seed, players and round limit do not matter', () {
      expect(compatKey(const GameConfig('property')), 'property/berlin');
      expect(compatKey(const GameConfig('property', theme: 'fantasie', players: 5, rounds: 20)), 'property/fantasie');
      final f = fingerprintOf(const GameConfig('property'))!;
      expect(f.rules, PropertyGame.rulesVersion);
      expect(f.revision, PropertyTheme.berlin.revision);
      expect(fingerprintOf(const GameConfig('property', seed: 5, players: 6, rounds: 40)), f);
      expect(fingerprintOf(const GameConfig('property', theme: 'berlin')), f);
      expect(fingerprintOf(const GameConfig('property', theme: 'fantasie')), isNot(f));
      expect(fingerprintOf(const GameConfig('property', theme: 'paris')), isNull);
      expect(fingerprintOf(const GameConfig('property', players: 7)), isNull);
      expect(allFingerprints().keys, containsAll(['property/berlin', 'property/fantasie']));
    });

    test('the content hash covers the theme data', () {
      final berlin = PropertyTheme.berlin;
      final base = contentHash('property', null, theme: berlin);
      expect(contentHash('property', null, theme: PropertyTheme.fromJson(berlin.toJson())), base);
      final json = berlin.toJson();
      (json['squares'] as List)[1]['price'] = 61;
      expect(contentHash('property', null, theme: PropertyTheme.fromJson(json)), isNot(base));
      expect(contentHash('property', null), isNot(base));
    });
  });

  group('public step (for the n-player network)', () {
    test('no seed, no deck order: two seeds look the same until dice or cards differ', () {
      final a = PropertyGame(playerCount: 3, seed: 1), b = PropertyGame(playerCount: 3, seed: 2);
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
      expect(a.toJson().containsKey('seed'), isFalse);
      expect(a.toJson()['decks'], {'surprise': 16, 'neighbourhood': 16});
      final config = const GameConfig('property', seed: 123456, players: 3);
      expect(config.publicJson().containsKey('seed'), isFalse);
    });

    test('a step carries the move, the events and the public view', () {
      final g = PropertyGame(playerCount: 2, seed: 987654, dice: [3, 4], deckOrder: {
        PropertyDeck.surprise: [PropertyTheme.berlin.cards.firstWhere((c) => c.deck == PropertyDeck.surprise).id],
      });
      final e = g.applyMove(mv('roll'))!;
      final step = g.publicStep(mv('roll'), e);
      expect(step['move'], mv('roll'));
      expect((step['events'] as List).first, {'type': 'rolled', 'dice': [3, 4]});
      expect((step['events'] as List).any((x) => x['type'] == 'card'), isTrue, reason: 'square 7 draws a card');
      expect(step['view'], g.toJson());
      final text = jsonEncode(step);
      expect(text, isNot(contains('987654')));
      expect(text, isNot(contains('"seed"')));
    });
  });
}
