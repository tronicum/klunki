/// Build compatibility (KLD-085): a deterministic fingerprint of everything
/// two devices must agree on to play a game together, so the network
/// handshake can refuse a peer running another build instead of letting the
/// game diverge (e.g. an iPhone on a new build and a cached older PWA with a
/// different Quartett deck).
///
/// A [GameFingerprint] has three parts:
/// * [GameFingerprint.rules]: the game's [GameSpec.rulesVersion], bumped by
///   hand on breaking rule changes;
/// * [GameFingerprint.revision]: the deck's [QuartettDeck.revision] (1 for
///   games without a deck), bumped by hand when deck data changes;
/// * [GameFingerprint.content]: a hash of the gameplay data itself (for
///   Quartett the deck: id, card ids, names, sets, stat ids in order with
///   `higherWins`, every value), so a change that forgot its bump is still
///   caught.
///
/// Presentation is left out on purpose: stat labels, units and number
/// formats, set and deck names, and everything the app keeps outside the
/// engine (card photos, Wikipedia links, image credits). A build that only
/// adds photos stays compatible.
library;

import 'dart:convert';

import 'dice_sheet.dart';
import 'maexchen.dart';
import 'quartett.dart';
import 'registry.dart';
import 'sha256.dart';
import 'word_tiles.dart';

/// What two peers compare for one game (and deck).
class GameFingerprint {
  final int rules;
  final int revision;

  /// 32 lower-case hex characters (the first 128 bits of a SHA-256).
  final String content;
  const GameFingerprint({required this.rules, required this.revision, required this.content});

  /// `{"rules": 1, "rev": 1, "content": "…"}`.
  Map<String, dynamic> toJson() => {'rules': rules, 'rev': revision, 'content': content};

  /// Null for anything that is not a well-formed fingerprint (untrusted
  /// network input).
  static GameFingerprint? tryParse(Object? json) {
    if (json is! Map) return null;
    final rules = json['rules'], rev = json['rev'], content = json['content'];
    if (rules is! int || rev is! int || content is! String) return null;
    return GameFingerprint(rules: rules, revision: rev, content: content);
  }

  @override
  bool operator ==(Object other) =>
      other is GameFingerprint && other.rules == rules && other.revision == revision && other.content == content;

  @override
  int get hashCode => Object.hash(rules, revision, content);

  @override
  String toString() => 'GameFingerprint(rules $rules, rev $revision, $content)';
}

/// The key a fingerprint is filed under: the game id, plus `/deck` for a
/// game that uses a deck (the default deck when [GameConfig.deck] is null).
/// The seed does not matter.
String compatKey(GameConfig config) {
  final spec = specById(config.gameId);
  if (spec == null || !spec.usesDeck) return config.gameId;
  return '${config.gameId}/${config.deck ?? QuartettDeck.defaultId}';
}

/// The fingerprint of the game [config] names; null if this build does not
/// know the game or deck ([configProblem]).
GameFingerprint? fingerprintOf(GameConfig config) {
  if (configProblem(config, wordList: false) != null) return null;
  final spec = specById(config.gameId)!;
  final deck = spec.usesDeck ? QuartettDeck.byId(config.deck)! : null;
  return GameFingerprint(rules: spec.rulesVersion, revision: deck?.revision ?? 1, content: contentHash(spec.id, deck));
}

/// [GameFingerprint.content] for game [gameId] played with [deck] (null for
/// a game without a deck). The word tile game adds its tile sets and premium
/// layout ([WordTilesGame.gameplayData], KLD-094), Mäxchen its order of
/// values ([MaexchenGame.ranking], KLD-121), Ausgewürfelt its boxes and
/// scores ([DiceSheetGame.gameplayData], KLD-119).
String contentHash(String gameId, QuartettDeck? deck) {
  final data = jsonEncode([
    'game',
    gameId,
    if (deck != null) deckGameplayData(deck),
    if (gameId == 'wordtiles') WordTilesGame.gameplayData(),
    if (gameId == 'maexchen') MaexchenGame.ranking,
    if (gameId == 'dicesheet') DiceSheetGame.gameplayData(),
  ]);
  return sha256Hex('klunki-content-v1\n$data').substring(0, 32);
}

/// Every game and deck this build knows, by [compatKey] (what a guest sends
/// in its `hello`).
Map<String, GameFingerprint> allFingerprints() => {
      for (final spec in gameSpecs)
        if (spec.usesDeck)
          for (final deck in QuartettDeck.all)
            compatKey(GameConfig(spec.id, deck: deck.id)): fingerprintOf(GameConfig(spec.id, deck: deck.id))!
        else
          spec.id: fingerprintOf(GameConfig(spec.id))!,
    };

/// A short code over [allFingerprints] (8 hex characters) for people to
/// compare by eye, e.g. in the app's version line: equal codes mean every
/// game and deck matches.
String catalogFingerprint() {
  final all = allFingerprints();
  final keys = all.keys.toList()..sort();
  final text = [for (final k in keys) '$k=${all[k]!.rules}.${all[k]!.revision}.${all[k]!.content}'].join('\n');
  return sha256Hex('klunki-catalog-v1\n$text').substring(0, 8);
}

/// The gameplay data of [deck] as JSON-ready lists: what [fingerprintOf]
/// hashes. Numbers are written as strings ([_number]) so the VM and the
/// browser (where every number is a double) produce the same bytes.
List<Object> deckGameplayData(QuartettDeck deck) => [
      deck.id,
      [for (final s in deck.stats) [s.id, s.higherWins]],
      [
        for (final c in deck.cards)
          [c.id, c.set, c.name, [for (final s in deck.stats) _number(c.stats[s.id])]],
      ],
    ];

/// Platform-independent text of a stat value: whole numbers without a
/// decimal point (`1999`, also for `1999.0`), others with up to 6 decimals,
/// trailing zeros dropped (`110.6`).
String _number(num? v) {
  if (v == null) return '-';
  if (v.isFinite && v == v.roundToDouble()) return v.round().toString();
  var s = v.toStringAsFixed(6);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}
