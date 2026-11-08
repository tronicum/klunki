import 'package:flutter/material.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';
import '../../l10n/app_localizations.dart';
import '../game_titles.dart';
import '../games/chess_screen.dart';
import '../games/connect4_screen.dart';
import '../games/dicesheet/dicesheet_options.dart';
import '../games/dicesheet/dicesheet_screen.dart';
import '../games/gostrategy_screen.dart';
import '../games/maexchen/maexchen_options.dart';
import '../games/maexchen/maexchen_screen.dart';
import '../games/muehle_screen.dart';
import '../games/quartett_deck_picker.dart';
import '../games/quartett_sets_screen.dart';
import '../games/quartett_trumpf_screen.dart';
import '../games/schiffe_screen.dart';
import '../games/wordtiles_screen.dart';
import '../games/wordtiles/wordtiles_options.dart';
import '../games/maumau/maumau_options.dart';
import '../games/maumau/maumau_screen.dart';
import '../../profile/player_name_controller.dart';
import '../player_name_dialog.dart' show showHotSeatNamesDialog;
import '../seat_players_dialog.dart';
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
  'maumau': (c) => MauMauScreen(controller: c),
  'maexchen': (c) => MaexchenScreen(controller: c),
  'dicesheet': (c) => DiceSheetScreen(controller: c),
};

/// Games with a screen that are not in the app yet (`GameSpec.appReady`
/// false): only debug builds offer them, from the menu's debug section.
/// Empty since Wortgewandt was released (KLD-094 step 7); kept for the next
/// game that gets a screen before its release.
const Set<String> previewGames = {};

/// Games the app plays in hot-seat only for now: hidden from the host
/// pickers of "Über WLAN spielen" and the relay host. A guest joining a host
/// that plays one still gets its screen. Empty since chess (KLD-059 step 3)
/// and Wortgewandt (KLD-094 step 6) play over the network. Mau-Mau
/// (KLD-118) is hot-seat only until its network step. Mäxchen (KLD-121) is
/// one device only for now: the engine has its redaction, the app's network
/// screens do not offer it yet. Ausgewürfelt (KLD-119) is for 2–4 players
/// at one table; the network session is 2-player.
const Set<String> hotSeatOnlyGames = {'maumau', 'maexchen', 'dicesheet'};

/// Games played in the seat shell for 2–4 players on one device (KLD-119,
/// `SeatGameScreen`): the menu asks "Wer spielt?" with the player count.
const Set<String> seatGames = {'dicesheet'};

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
Future<void> openGame(BuildContext context, String gameId,
    {int? seed,
    String? deck,
    String? tiles,
    bool dictionary = false,
    bool jokerSwap = false,
    MauMauRules mauMau = const MauMauRules(),
    int lives = 3,
    bool maexchenDouble = true,
    int players = 2,
    bool extraFives = false}) {
  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => GameSession(
        config: GameConfig(gameId,
            seed: seed ?? newGameSeed(),
            deck: deck,
            tiles: tiles,
            dictionary: dictionary,
            jokerSwap: jokerSwap,
            mauMau: mauMau,
            lives: lives,
            maexchenDouble: maexchenDouble,
            players: players,
            extraFives: extraFives)),
  ));
}

/// The menu's way into a game: Quartett first asks for the deck
/// (KLD-069, [showQuartettDeckPicker]), Wortgewandt for the tile language
/// and the word list (KLD-094, [showWordTilesOptionsDialog]); then "Wer
/// spielt?" (KLD-103) asks for both player names, prefilled with the last
/// ones or the default names (only with the app's [PlayerNameScope]).
/// Cancelling any of them starts nothing. A Wortgewandt game with "Wörterbuch
/// prüfen" loads its word list before the game opens.
Future<void> openGameFromMenu(BuildContext context, String gameId, {QuartettDeckSettings? deckSettings}) async {
  String? deck;
  if (specById(gameId)?.usesDeck == true) {
    deck = await showQuartettDeckPicker(context, settings: deckSettings);
    if (deck == null || !context.mounted) return;
  }
  WordTilesOptions? words;
  if (gameId == 'wordtiles') {
    words = await showWordTilesOptionsDialog(context);
    if (words == null || !context.mounted) return;
  }
  MauMauRules? mauMau;
  if (gameId == 'maumau') {
    // Mau-Mau: the house rules first (KLD-118).
    mauMau = await showMauMauOptionsDialog(context);
    if (mauMau == null || !context.mounted) return;
  }
  // Mäxchen (KLD-121): lives and the house rule "Mäxchen doppelt".
  MaexchenOptions? dice;
  if (gameId == 'maexchen') {
    dice = await showMaexchenOptionsDialog(context);
    if (dice == null || !context.mounted) return;
  }
  // Ausgewürfelt (KLD-119): the house rule, then how many play and who.
  DiceSheetOptions? sheet;
  var players = 2;
  if (gameId == 'dicesheet') {
    sheet = await showDiceSheetOptionsDialog(context);
    if (sheet == null || !context.mounted) return;
  }
  if (seatGames.contains(gameId)) {
    final n = await showSeatPlayersDialog(context);
    if (n == null || !context.mounted) return;
    players = n;
  } else {
    final go = await showHotSeatNamesDialog(context, gameId: gameId, start: true);
    if (!go || !context.mounted) return;
  }
  if (words != null && words.dictionary) {
    if (!await loadWordListWithProgress(context, words.tiles) || !context.mounted) return;
  }
  return openGame(context, gameId,
      deck: deck,
      tiles: words?.tiles,
      dictionary: words?.dictionary ?? false,
      jokerSwap: words?.joker ?? false,
      mauMau: mauMau ?? const MauMauRules(),
      lives: dice?.lives ?? 3,
      maexchenDouble: dice?.double ?? true,
      players: players,
      extraFives: sheet?.extraFives ?? false);
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
    // Hot-seat names (KLD-056, KLD-103); "Nochmal" keeps them (same store).
    return ValueListenableBuilder<HotSeatNames>(
      valueListenable: hotSeat,
      builder: (context, names, child) => PlayerLabelsScope(labels: hotSeatLabels(names), child: child!),
      child: screen,
    );
  }
}

/// Labels for a hot-seat game: both players on this device; a player
/// without a typed name gets the default name ([defaultPlayerName]).
PlayerLabels hotSeatLabels(HotSeatNames names) => PlayerLabels(names: {
      Player.a: ?names.x,
      Player.b: ?names.o,
    });
