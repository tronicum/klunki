import 'package:flutter/material.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';
import '../../l10n/app_localizations.dart';
import '../game_titles.dart';
import '../games/chess_screen.dart';
import '../games/connect4_screen.dart';
import '../games/gostrategy_screen.dart';
import '../games/muehle_screen.dart';
import '../games/quartett_deck_picker.dart';
import '../games/quartett_sets_screen.dart';
import '../games/quartett_trumpf_screen.dart';
import '../games/schiffe_screen.dart';
import '../games/wordtiles_screen.dart';
import '../../profile/player_name_controller.dart';
import '../../profile/quartett_deck_settings.dart';
import 'game_screen.dart';

/// Builds the screen widget for a game; the screen renders a [GameScreen].
typedef GameScreenBuilder = Widget Function(GameController controller);

/// `GameSpec.id` → screen. Every id in `appGameSpecs` must have an entry,
/// plus the [previewGames]; other games (`GameSpec.appReady` false) show
/// [GameNotInAppScreen].
final Map<String, GameScreenBuilder> gameScreens = {
  'connect4': (c) => Connect4Screen(controller: c),
  'muehle': (c) => MuehleScreen(controller: c),
  'quartett-trumpf': (c) => QuartettTrumpfScreen(controller: c),
  'quartett-sets': (c) => QuartettSetsScreen(controller: c),
  'schiffe': (c) => SchiffeScreen(controller: c),
  'gostrategy': (c) => GoStrategyScreen(controller: c),
  'chess': (c) => ChessScreen(controller: c),
  'wordtiles': (c) => WordTilesScreen(controller: c),
};

/// Games with a screen that are not in the app yet (`GameSpec.appReady`
/// false): only debug builds offer them, from the menu's debug section
/// (KLD-094: the word tile game until its name and word list are decided).
const Set<String> previewGames = {'wordtiles'};

/// Games the app plays in hot-seat only for now: hidden from the host
/// pickers of "Über WLAN spielen" and the relay host (KLD-059: chess network
/// play is step 3; KLD-094: word tiles, also step 3). A guest joining a host
/// that plays one still gets its screen.
const Set<String> hotSeatOnlyGames = {'chess', 'wordtiles'};

/// The games the app offers to host over the network: [appGameSpecs]
/// without [hotSeatOnlyGames].
List<GameSpec> get networkGameSpecs => [
      for (final s in appGameSpecs)
        if (!hotSeatOnlyGames.contains(s.id)) s,
    ];

/// The screen for [controller]'s game.
Widget buildGameScreen(GameController controller) {
  final builder = gameScreens[controller.config.gameId];
  if (builder == null) return GameNotInAppScreen(gameId: controller.config.gameId);
  return builder(controller);
}

/// Placeholder for a game the engine knows but the app cannot show yet
/// (`GameSpec.appReady` false), e.g. when joining a CLI host that plays a
/// game added to the engine before its screen.
class GameNotInAppScreen extends StatelessWidget {
  final String gameId;
  const GameNotInAppScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = localizedGameTitle(l10n, gameId, fallback: specById(gameId)?.title ?? gameId);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.gameNotInApp(title), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// Starts a hot-seat game of [gameId] (random seed unless given; [deck] for
/// Quartett, KLD-069) and pushes its screen. The controller lives as long as
/// the route and is disposed when it is popped.
Future<void> openGame(BuildContext context, String gameId, {int? seed, String? deck}) {
  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => GameSession(config: GameConfig(gameId, seed: seed ?? newGameSeed(), deck: deck)),
  ));
}

/// The menu's way into a game: Quartett first asks for the deck
/// (KLD-069, [showQuartettDeckPicker]); other games start right away.
Future<void> openGameFromMenu(BuildContext context, String gameId, {QuartettDeckSettings? deckSettings}) async {
  if (specById(gameId)?.usesDeck != true) return openGame(context, gameId);
  final deck = await showQuartettDeckPicker(context, settings: deckSettings);
  if (deck == null || !context.mounted) return;
  return openGame(context, gameId, deck: deck);
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
  Widget build(BuildContext context) {
    final screen = buildGameScreen(_controller);
    final hotSeat = PlayerNameScope.maybeOf(context)?.hotSeat;
    if (hotSeat == null) return screen;
    // Optional hot-seat names (KLD-056); "Nochmal" keeps them (same store).
    return ValueListenableBuilder<HotSeatNames>(
      valueListenable: hotSeat,
      builder: (context, names, child) => PlayerLabelsScope(labels: hotSeatLabels(names), child: child!),
      child: screen,
    );
  }
}

/// Labels for a hot-seat game: both players on this device, names optional.
PlayerLabels hotSeatLabels(HotSeatNames names) => PlayerLabels(names: {
      Player.a: ?names.x,
      Player.b: ?names.o,
    });
