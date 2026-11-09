import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-085: the build compatibility fingerprint.
void main() {
  // Golden values. A change here means old and new builds can no longer
  // play this game together: intended only together with a rules or deck
  // change (bump GameSpec.rulesVersion / QuartettDeck.revision too). Print
  // the current values with `dart run tool/print_fingerprints.dart`.
  const golden = {
    'connect4': (1, 1, '282ff8588e55894fee40310288ba4cd3'),
    'muehle': (1, 1, '11dc77e785302ff02798301f8c3e6ca2'),
    'quartett-trumpf/cars': (2, 1, '378d71ae1272e96537ba43c00efe4312'),
    'quartett-trumpf/trains': (2, 2, '27d8444e107ce25df18d9dcff7083ea7'),
    'quartett-trumpf/rockets': (2, 2, 'fcbe8f667602a34eba264ab20115b388'),
    'quartett-trumpf/planes': (2, 2, '1e09887644babc40be5c137ef613d1cf'),
    'quartett-sets/cars': (1, 1, '9929298ad7256ca5d6a59621440e6709'),
    'quartett-sets/trains': (1, 2, 'b5a57d4235755cb6e9482c01b516c22c'),
    'quartett-sets/rockets': (1, 2, '6f2b13617f2f9f61c7c306f4ce7cb278'),
    'quartett-sets/planes': (1, 2, 'a3abec801f5a7a83862d97aad08e7ee4'),
    'schiffe': (1, 1, '372bb8310b020f23ee9328eb838c0a4c'),
    'gostrategy': (1, 1, 'd1b9bdcaf3d263cb700033edd0c0cf3e'),
    'chess': (3, 1, '5f2d81a850dc003d33424219c180126a'),
    'wordtiles': (5, 1, '9cf165a9d01bf6c5d92110e50aa45d69'),
    'maumau': (1, 1, '70ca586971256574b6ae28af6fdb38b4'),
    'maexchen': (1, 1, '2bdb761a0b8eb3f4ea54c9156bfda505'),
    'dicesheet': (1, 1, 'efb31c5c6fa32b9e12e025988708b559'),
    // KLD-060: Baulöwe, keyed by board theme (revision = theme revision).
    'property/berlin': (1, 2, 'c58289b803d547d6488c1ba052f7b60b'),
    'property/fantasie': (1, 1, 'ff566d40ca1e0c34ec459de12ecfa9a8'),
  };

  test('golden fingerprint per game and deck', () {
    final all = allFingerprints();
    expect(all.keys.toSet(), golden.keys.toSet(), reason: 'a new game or deck needs a golden value');
    for (final MapEntry(:key, value: (rules, rev, content)) in golden.entries) {
      expect(all[key], GameFingerprint(rules: rules, revision: rev, content: content), reason: key);
    }
  });

  test('keys: game id, plus the deck for Quartett (null = default deck); the seed does not matter', () {
    expect(compatKey(const GameConfig('connect4', seed: 9)), 'connect4');
    expect(compatKey(const GameConfig('connect4', deck: 'rockets')), 'connect4');
    expect(compatKey(const GameConfig('quartett-trumpf')), 'quartett-trumpf/cars');
    expect(compatKey(const GameConfig('quartett-sets', seed: 3, deck: 'planes')), 'quartett-sets/planes');
    expect(fingerprintOf(const GameConfig('quartett-trumpf', seed: 1, deck: 'rockets')),
        fingerprintOf(const GameConfig('quartett-trumpf', seed: 2, deck: 'rockets')));
    expect(fingerprintOf(const GameConfig('quartett-trumpf')), fingerprintOf(const GameConfig('quartett-trumpf', deck: 'cars')));
  });

  test('unknown game or deck: no fingerprint', () {
    expect(fingerprintOf(const GameConfig('backgammon')), isNull);
    expect(fingerprintOf(const GameConfig('quartett-trumpf', deck: 'ships')), isNull);
  });

  test('stable: computed twice, same value; JSON round trip', () {
    final a = allFingerprints(), b = allFingerprints();
    expect(a, b);
    for (final f in a.values) {
      expect(GameFingerprint.tryParse(f.toJson()), f);
      expect(f.content, matches(RegExp(r'^[0-9a-f]{32}$')));
    }
    expect(catalogFingerprint(), catalogFingerprint());
    expect(catalogFingerprint(), matches(RegExp(r'^[0-9a-f]{8}$')));
    expect(GameFingerprint.tryParse(null), isNull);
    expect(GameFingerprint.tryParse({'rules': '1', 'rev': 1, 'content': 'x'}), isNull);
  });

  group('content hash of a deck', () {
    final rockets = QuartettDeck.rockets;
    final base = contentHash('quartett-trumpf', rockets);

    test('equals the registered deck when rebuilt from its own data', () {
      expect(contentHash('quartett-trumpf', _rebuild(rockets)), base);
    });

    test('changes with a stat value', () {
      expect(contentHash('quartett-trumpf', _rebuild(rockets, value: (c, s) => c.id == 'A1' && s.id == 'flights')),
          isNot(base));
    });

    test('changes with higherWins, the stat order, a stat id, a card name', () {
      expect(contentHash('quartett-trumpf', _rebuild(rockets, stats: [
        for (final s in rockets.stats) s.id == 'leoT' ? _copy(s, higherWins: !s.higherWins) : s,
      ])), isNot(base));
      expect(contentHash('quartett-trumpf', _rebuild(rockets, stats: rockets.stats.reversed.toList())), isNot(base));
      expect(contentHash('quartett-trumpf', _rebuild(rockets, stats: [
        for (final s in rockets.stats) s.id == 'flights' ? _copy(s, id: 'firstFlight') : s,
      ])), isNot(base));
      expect(contentHash('quartett-trumpf', _rebuild(rockets, name: (c) => c.id == 'B2' ? '${c.name}X' : c.name)),
          isNot(base));
    });

    test('ignores presentation: labels, units, formats, set and deck names, revision', () {
      final restyled = QuartettDeck.build(
        id: rockets.id,
        name: 'Rockets (photos)',
        revision: 99,
        stats: [
          for (final s in rockets.stats)
            QuartettStat(id: s.id, label: '${s.label}!', unit: 'u', higherWins: s.higherWins, decimals: 3, fixedDecimals: true),
        ],
        setNames: {for (final k in rockets.setNames.keys) k: 'Set $k'},
        rows: [for (final c in rockets.cards) (c.id, c.name, [for (final s in rockets.stats) c.stats[s.id]!])],
      );
      expect(contentHash('quartett-trumpf', restyled), base);
      // Card photos, Wikipedia links and image credits live in the app
      // (quartett_media_data.dart), not in the engine: they cannot reach
      // the hash at all.
    });

    test('whole-number values hash the same as doubles (VM vs. browser)', () {
      final doubles = _rebuild(rockets, asDouble: true);
      expect(contentHash('quartett-trumpf', doubles), base);
    });

    test('the deck differs per game mode and per deck', () {
      expect(contentHash('quartett-sets', rockets), isNot(base));
      expect(contentHash('quartett-trumpf', QuartettDeck.planes), isNot(base));
    });
  });
}

QuartettStat _copy(QuartettStat s, {String? id, bool? higherWins}) => QuartettStat(
    id: id ?? s.id,
    label: s.label,
    unit: s.unit,
    higherWins: higherWins ?? s.higherWins,
    decimals: s.decimals,
    fixedDecimals: s.fixedDecimals,
    isYear: s.isYear);

/// [deck] built again from its own data, optionally changed: one value +1
/// where [value] says so, other [stats] (same order of values), other
/// [name]s, every value as a double.
QuartettDeck _rebuild(QuartettDeck deck,
    {bool Function(Card, QuartettStat)? value,
    List<QuartettStat>? stats,
    String Function(Card)? name,
    bool asDouble = false}) {
  final order = deck.stats;
  return QuartettDeck.build(
    id: deck.id,
    name: deck.name,
    revision: deck.revision,
    stats: stats ?? order,
    setNames: deck.setNames,
    rows: [
      for (final c in deck.cards)
        (
          c.id,
          name?.call(c) ?? c.name,
          [
            for (final s in stats ?? order)
              () {
                final orig = order.where((o) => o.id == s.id).firstOrNull ?? order[(stats ?? order).indexOf(s)];
                final v = c.stats[orig.id]! + ((value?.call(c, s) ?? false) ? 1 : 0);
                return asDouble ? v.toDouble() : v;
              }(),
          ]
        ),
    ],
  );
}
