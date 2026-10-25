import 'package:flutter/material.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';
import '../games/connect4_screen.dart';
import '../games/muehle_screen.dart';
import '../games/quartett_sets_screen.dart';
import '../games/quartett_trumpf_screen.dart';
import '../games/schiffe_screen.dart';
import 'game_screen.dart';

/// Builds the screen widget for a game; the screen renders a [GameScreen].
typedef GameScreenBuilder = Widget Function(GameController controller);

/// `GameSpec.id` → screen. Every id in `gameSpecs` must have an entry.
final Map<String, GameScreenBuilder> gameScreens = {
  'connect4': (c) => Connect4Screen(controller: c),
  'muehle': (c) => MuehleScreen(controller: c),
  'quartett-trumpf': (c) => QuartettTrumpfScreen(controller: c),
  'quartett-sets': (c) => QuartettSetsScreen(controller: c),
  'schiffe': (c) => SchiffeScreen(controller: c),
};

/// The screen for [controller]'s game.
Widget buildGameScreen(GameController controller) {
  final builder = gameScreens[controller.config.gameId];
  if (builder == null) throw ArgumentError('no screen for ${controller.config.gameId}');
  return builder(controller);
}

/// Starts a hot-seat game of [gameId] (random seed unless given) and pushes
/// its screen. The controller lives as long as the route and is disposed
/// when it is popped.
Future<void> openGame(BuildContext context, String gameId, {int? seed}) {
  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => GameSession(config: GameConfig(gameId, seed: seed ?? newGameSeed())),
  ));
}

/// Owns a hot-seat [GameController] for [config] and shows its screen.
class GameSession extends StatefulWidget {
  final GameConfig config;
  const GameSession({super.key, required this.config});

  @override
  State<GameSession> createState() => _GameSessionState();
}

class _GameSessionState extends State<GameSession> {
  late final GameController _controller = GameController.hotSeat(widget.config);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildGameScreen(_controller);
}
