import 'chess.dart';
import 'connect4.dart';
import 'game.dart';
import 'gostrategy.dart';
import 'muehle.dart';
import 'quartett.dart';
import 'schiffe.dart';
import 'secrecy.dart';
import 'word_tiles.dart';

/// Everything needed to (re)create the same game on every device: a game id
/// plus the seed for games with shuffled or random setup. Together with the
/// accepted move list this is a full replay, which is what network sync and
/// reconnect rely on.
///
/// [deck] (KLD-069) picks the Quartett deck ([QuartettDeck.byId]); null means
/// the default car deck, which is what configs from before KLD-069 (no
/// `deck` key) get. Games without decks ignore it. The deck is public config:
/// with a secret seed (KLD-064) the host still sends it ([publicJson]).
///
/// [pickLowCards] (KLD-100, Quartett Trumpf only, on by default): the house
/// rule "with 3 or fewer cards you choose which card to play", see
/// [QuartettGame.pickLowCards]. Public config like the deck; JSON key
/// `pickLow`, written only when off (absent = on).
///
/// Word tiles (KLD-094 step 4): [tiles] picks the tile set ([TileSet.byId],
/// JSON `tiles`; null = German), [dictionary] (JSON `dict`, written only
/// when on) checks every word against the list registered in [WordLists]
/// for that tile set ([WordCheck.dictionary]); off = challenge mode. Other
/// games ignore both.
class GameConfig {
  final String gameId;
  final int seed;
  final String? deck;
  final bool pickLowCards;
  final String? tiles;
  final bool dictionary;
  const GameConfig(this.gameId,
      {this.seed = 0, this.deck, this.pickLowCards = true, this.tiles, this.dictionary = false});

  Map<String, dynamic> toJson() => {'game': gameId, 'seed': seed, ..._options};

  /// [toJson] without the seed: what a guest may see of a game whose seed is
  /// secret.
  Map<String, dynamic> publicJson() => {'game': gameId, ..._options};

  Map<String, dynamic> get _options => {
        if (deck != null) 'deck': deck,
        if (!pickLowCards) 'pickLow': false,
        if (tiles != null) 'tiles': tiles,
        if (dictionary) 'dict': true,
      };

  factory GameConfig.fromJson(Map<String, dynamic> json) => GameConfig(json['game'] as String,
      seed: json['seed'] as int? ?? 0,
      deck: json['deck'] as String?,
      pickLowCards: json['pickLow'] != false,
      tiles: json['tiles'] as String?,
      dictionary: json['dict'] == true);

  GameConfig copyWith({int? seed}) => GameConfig(gameId,
      seed: seed ?? this.seed, deck: deck, pickLowCards: pickLowCards, tiles: tiles, dictionary: dictionary);

  @override
  bool operator ==(Object other) =>
      other is GameConfig &&
      other.gameId == gameId &&
      other.seed == seed &&
      other.deck == deck &&
      other.pickLowCards == pickLowCards &&
      other.tiles == tiles &&
      other.dictionary == dictionary;

  @override
  int get hashCode => Object.hash(gameId, seed, deck, pickLowCards, tiles, dictionary);

  @override
  String toString() =>
      'GameConfig($gameId, seed: $seed${deck == null ? '' : ', deck: $deck'}${pickLowCards ? '' : ', pickLow: off'}'
      '${tiles == null ? '' : ', tiles: $tiles'}${dictionary ? ', dict' : ''})';
}

/// One playable game: stable [id] (shared with the debug console and the
/// network protocol), display [title], whether players hold secrets
/// (needs a handover cover in hot-seat) and a factory.
class GameSpec {
  final String id;
  final String title;
  final bool hiddenInformation;

  /// False while the Flutter app has no screen for this game yet: the game
  /// runs in the engine, the CLI and over the network, but the app hides it
  /// (see [appGameSpecs]).
  final bool appReady;

  /// How a network host redacts this game for the remote player (KLD-064);
  /// set exactly for the [hiddenInformation] games.
  final Redaction? redaction;

  /// Whether [GameConfig.deck] picks a Quartett deck for this game (KLD-069).
  final bool usesDeck;

  /// Version of this game's rules (KLD-085). Bump it on every change that
  /// makes an old and a new build disagree about a game (a move accepted by
  /// one and refused by the other, a different deal from the same seed, a
  /// changed move or view format). Network peers must have the same value
  /// ([fingerprintOf]); the higher one is the newer build.
  final int rulesVersion;
  final Game Function(GameConfig config, QuartettDeck deck) _create;
  const GameSpec(this.id, this.title, this._create,
      {this.hiddenInformation = false,
      this.appReady = true,
      this.redaction,
      this.usesDeck = false,
      this.rulesVersion = 1});

  /// A new game; [deck] (games with [usesDeck]) defaults to the car deck.
  /// [pickLowCards]: see [GameConfig.pickLowCards]. Throws [ArgumentError]
  /// for an unknown deck.
  Game create([int seed = 0, String? deck, bool pickLowCards = true]) =>
      createFrom(GameConfig(id, seed: seed, deck: deck, pickLowCards: pickLowCards));

  /// A new game for [config] (its id is not checked against [id]).
  Game createFrom(GameConfig config) {
    final d = QuartettDeck.byId(usesDeck ? config.deck : null);
    if (d == null) throw ArgumentError.value(config.deck, 'deck', 'unknown deck');
    return _create(config, d);
  }
}

/// All games, in menu order.
final List<GameSpec> gameSpecs = [
  GameSpec('connect4', '4 Gewinnt', (_, __) => Connect4Game()),
  GameSpec('muehle', 'Mühle', (_, __) => MuehleGame()),
  // Rules 2 (KLD-100): the "3 or fewer cards: choose" house rule
  // (`choose` moves, GameConfig.pickLowCards).
  GameSpec('quartett-trumpf', 'Quartett (Trumpf)',
      (c, d) => QuartettGame(QuartettMode.trumpf, seed: c.seed, deck: d, pickLowCards: c.pickLowCards),
      hiddenInformation: true, redaction: const QuartettRedaction(), usesDeck: true, rulesVersion: 2),
  // 8 cards each plus a draw pile: with all 32 dealt every ask would hit.
  GameSpec(
      'quartett-sets', 'Quartett (Sets)', (c, d) => QuartettGame(QuartettMode.sets, seed: c.seed, handSize: 8, deck: d),
      hiddenInformation: true, redaction: const QuartettRedaction(), usesDeck: true),
  GameSpec('schiffe', 'Schiffe versenken', (_, __) => SchiffeGame(),
      hiddenInformation: true, redaction: const SchiffeRedaction()),
  GameSpec('gostrategy', 'GoStrategy', (_, __) => GoStrategyGame(),
      hiddenInformation: true, redaction: const GoStrategyRedaction()),
  // KLD-059: hot-seat in the app since step 2; the app offers it for
  // network play from step 3 (see `networkGameSpecs` in the app).
  GameSpec('chess', 'Schach', (_, __) => ChessGame()),
  // KLD-094 step 1: engine only (challenge mode, German tiles, 2 players);
  // title "Wortgewandt" (chosen by the maintainer, 2026-11-01). Rules 2
  // (step 4): tile set and word list per game (GameConfig.tiles /
  // .dictionary), `allow` on placements, the word-list revisions in the
  // fingerprint.
  GameSpec('wordtiles', 'Wortgewandt', _createWordTiles,
      hiddenInformation: true, redaction: const WordTilesRedaction(), appReady: false, rulesVersion: 2),
];

WordTilesGame _createWordTiles(GameConfig c, QuartettDeck _) {
  final tileSet = TileSet.byId(c.tiles ?? TileSet.german.id) ??
      (throw ArgumentError.value(c.tiles, 'tiles', 'unknown tile set'));
  if (!c.dictionary) return WordTilesGame(seed: c.seed, tileSet: tileSet);
  final list = WordLists.of(tileSet.id) ??
      (throw ArgumentError.value(tileSet.id, 'tiles', 'no word list loaded for this tile set'));
  return WordTilesGame(seed: c.seed, tileSet: tileSet, check: WordCheck.dictionary, validator: list);
}

/// The games the Flutter app offers (menu, hosting): [gameSpecs] with a
/// screen.
List<GameSpec> get appGameSpecs => [for (final s in gameSpecs) if (s.appReady) s];

GameSpec? specById(String id) => gameSpecs.where((s) => s.id == id).firstOrNull;

/// Why [config] cannot be played (unknown game or deck), or null if it can.
String? configProblem(GameConfig config) {
  final spec = specById(config.gameId);
  if (spec == null) return 'unknown game "${config.gameId}"';
  if (spec.usesDeck && QuartettDeck.byId(config.deck) == null) return 'unknown deck "${config.deck}"';
  if (config.gameId == 'wordtiles') {
    final tiles = config.tiles ?? TileSet.german.id;
    if (TileSet.byId(tiles) == null) return 'unknown tile set "$tiles"';
    if (config.dictionary && !WordLists.has(tiles)) return 'no word list for "$tiles"';
  }
  return null;
}

/// Creates the game for [config]; throws [ArgumentError] for an unknown id
/// or deck.
Game createGame(GameConfig config) {
  final spec = specById(config.gameId);
  if (spec == null) throw ArgumentError.value(config.gameId, 'gameId', 'unknown game');
  return spec.createFrom(config);
}

/// Rebuilds a game by replaying [moves] on a fresh instance. Returns null if
/// any move is rejected (the logs disagree).
Game? replay(GameConfig config, Iterable<Map<String, dynamic>> moves) {
  final game = createGame(config);
  for (final m in moves) {
    if (game.applyMove(m) == null) return null;
  }
  return game;
}
