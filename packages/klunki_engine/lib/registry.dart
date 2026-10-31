import 'connect4.dart';
import 'game.dart';
import 'gostrategy.dart';
import 'muehle.dart';
import 'quartett.dart';
import 'schiffe.dart';
import 'secrecy.dart';

/// Everything needed to (re)create the same game on every device: a game id
/// plus the seed for games with shuffled or random setup. Together with the
/// accepted move list this is a full replay, which is what network sync and
/// reconnect rely on.
class GameConfig {
  final String gameId;
  final int seed;
  const GameConfig(this.gameId, {this.seed = 0});

  Map<String, dynamic> toJson() => {'game': gameId, 'seed': seed};

  factory GameConfig.fromJson(Map<String, dynamic> json) =>
      GameConfig(json['game'] as String, seed: json['seed'] as int? ?? 0);

  @override
  bool operator ==(Object other) => other is GameConfig && other.gameId == gameId && other.seed == seed;

  @override
  int get hashCode => Object.hash(gameId, seed);

  @override
  String toString() => 'GameConfig($gameId, seed: $seed)';
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
  final Game Function(int seed) _create;
  const GameSpec(this.id, this.title, this._create,
      {this.hiddenInformation = false, this.appReady = true, this.redaction});

  Game create([int seed = 0]) => _create(seed);
}

/// All games, in menu order.
final List<GameSpec> gameSpecs = [
  GameSpec('connect4', '4 Gewinnt', (_) => Connect4Game()),
  GameSpec('muehle', 'Mühle', (_) => MuehleGame()),
  GameSpec('quartett-trumpf', 'Quartett (Trumpf)', (s) => QuartettGame(QuartettMode.trumpf, seed: s),
      hiddenInformation: true, redaction: const QuartettRedaction()),
  // 8 cards each plus a draw pile: with all 32 dealt every ask would hit.
  GameSpec('quartett-sets', 'Quartett (Sets)', (s) => QuartettGame(QuartettMode.sets, seed: s, handSize: 8),
      hiddenInformation: true, redaction: const QuartettRedaction()),
  GameSpec('schiffe', 'Schiffe versenken', (_) => SchiffeGame(),
      hiddenInformation: true, redaction: const SchiffeRedaction()),
  GameSpec('gostrategy', 'GoStrategy', (_) => GoStrategyGame(),
      hiddenInformation: true, redaction: const GoStrategyRedaction()),
];

/// The games the Flutter app offers (menu, hosting): [gameSpecs] with a
/// screen.
List<GameSpec> get appGameSpecs => [for (final s in gameSpecs) if (s.appReady) s];

GameSpec? specById(String id) => gameSpecs.where((s) => s.id == id).firstOrNull;

/// Creates the game for [config]; throws [ArgumentError] for an unknown id.
Game createGame(GameConfig config) {
  final spec = specById(config.gameId);
  if (spec == null) throw ArgumentError.value(config.gameId, 'gameId', 'unknown game');
  return spec.create(config.seed);
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
