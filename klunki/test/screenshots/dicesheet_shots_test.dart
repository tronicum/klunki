// KLD-119 screenshots of Ausgewürfelt: the menu tile, the start options,
// "Wer spielt?" with 4 players, a 4-player game on a phone (before rolling,
// after the first roll with the suggestions, kept dice, the sheet with a
// reached bonus, the game end ranking), the same in dark mode and Arabic,
// an iPhone SE at 130 % text, landscape, an iPad (portrait and landscape)
// and a 2-player game. Skipped unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/dicesheet_shots_test.dart --plain-name kld119
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/fonts.dart' show withAppFonts;
import 'package:klunki/app/theme.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/shake_settings.dart';
import 'package:klunki/ui/games/dicesheet/dicesheet_options.dart';
import 'package:klunki/ui/menu_screen.dart' show MenuScreen, menuShowsDebugConsole;
import 'package:klunki/ui/rules/rules_screen.dart';
import 'package:klunki/ui/seat_players_dialog.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/debug.dart' show DiceSheetText;
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

final String? _out = Platform.environment['KLUNKI_SHOTS'];
const _boundary = Key('shot-boundary');
const _phone = Size(390, 844);

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }

  await family('Roboto', [
    'assets/fonts/Roboto/Roboto-Regular.ttf',
    'assets/fonts/Roboto/Roboto-Medium.ttf',
    'assets/fonts/Roboto/Roboto-Bold.ttf',
  ]);
  await family('NotoSansArabic', [
    'assets/fonts/NotoSansArabic/NotoSansArabic-Regular.ttf',
    'assets/fonts/NotoSansArabic/NotoSansArabic-Bold.ttf',
  ]);
  await family('NotoSansMath', ['assets/fonts/NotoSansMath/NotoSansMath-Regular.ttf']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
}

Future<void> _shot(WidgetTester tester, String name) async {
  debugDisableShadows = false;
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/kld119/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

const _names = {
  'ar': ['سارة', 'عمر', 'ليلى', 'يوسف'],
};
const _deNames = ['Anna', 'Ben', 'Cleo', 'Dani'];

Future<void> _pumpApp(WidgetTester tester, Widget home,
    {Locale locale = const Locale('de'),
    Brightness brightness = Brightness.light,
    Size size = _phone,
    EdgeInsets safe = EdgeInsets.zero,
    double text = 1}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  final pad = FakeViewPadding(left: safe.left * 2, top: safe.top * 2, right: safe.right * 2, bottom: safe.bottom * 2);
  tester.view.padding = pad;
  tester.view.viewPadding = pad;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final theme = brightness == Brightness.dark ? KlunkiTheme.dark : KlunkiTheme.light;
  final names = _names[locale.languageCode] ?? _deNames;
  ExtraSeatNames.debugReset();
  await ExtraSeatNames.shared().set(third: names[2], fourth: names[3], players: 4);
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: PlayerNameScope(
      controller: PlayerNameController.memory(),
      hotSeat: HotSeatNamesController.memory(HotSeatNames(x: names[0], o: names[1])),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: withAppFonts(theme, web: true),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<GameController> _game(WidgetTester tester,
    {int players = 4,
    Locale locale = const Locale('de'),
    Brightness brightness = Brightness.light,
    Size size = _phone,
    EdgeInsets safe = EdgeInsets.zero,
    double text = 1,
    List<List<int>> rolls = const [[2, 5, 5, 3, 5], [5, 5, 5, 6, 2]]}) async {
  final c = GameController.hotSeat(GameConfig('dicesheet', seed: 11, players: players));
  addTearDown(c.dispose);
  (c.game as DiceSheetGame).debugScriptRolls(rolls);
  await _pumpApp(tester, buildGameScreen(c), locale: locale, brightness: brightness, size: size, safe: safe, text: text);
  return c;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Plays [turns] whole turns with the debug bot through the controller
/// (set-up for a later screenshot, not the thing shown).
Future<void> _botTurns(WidgetTester tester, GameController c, int turns, {int seed = 3}) async {
  final rng = Random(seed);
  for (var t = 0; t < turns && !c.game.isOver; t++) {
    while (!c.game.isOver) {
      final m = DiceSheetText(game: c.game as DiceSheetGame).autoMove(rng);
      await c.submit(m);
      if (m['action'] == 'score') break;
    }
  }
  await tester.pumpAndSettle();
}

/// Seat 0 reaches the upper bonus in its first 6 turns (four of each face);
/// the others play with the bot.
Future<void> _withBonus(WidgetTester tester, GameController c) async {
  final rng = Random(5);
  for (var round = 1; round <= 6; round++) {
    final g = c.game as DiceSheetGame;
    g.debugScriptRolls([
      [round, round, round, round, round == 6 ? 1 : 6],
    ]);
    await c.submit(DiceSheetGame.rollMove());
    await c.submit(DiceSheetGame.scoreMove(DiceBox.upperFor(round)));
    for (var s = 1; s < g.playerCount; s++) {
      while (true) {
        final m = DiceSheetText(game: c.game as DiceSheetGame).autoMove(rng);
        await c.submit(m);
        if (m['action'] == 'score') break;
      }
    }
  }
  await tester.pumpAndSettle();
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ShakeSettings.debugReset();
    ExtraSeatNames.debugReset();
  });

  group('kld119', () {
    testWidgets('menu tile', skip: skip, (tester) async {
      menuShowsDebugConsole = false;
      addTearDown(() => menuShowsDebugConsole = true);
      tester.view.physicalSize = _phone * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      const locale = Locale('de');
      await tester.pumpWidget(RepaintBoundary(
        key: _boundary,
        child: PlayerNameScope(
          controller: PlayerNameController.memory(),
          hotSeat: HotSeatNamesController.memory(),
          child: LocaleScope(
            controller: LocaleController.memory(locale),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: withAppFonts(KlunkiTheme.light, web: true),
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const MenuScreen(),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('menu-dicesheet')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('menu-dicesheet-local')), findsOneWidget);
      expect(find.byKey(const Key('menu-dicesheet-network')), findsNothing);
      await _shot(tester, '01-menu-tile');
    });

    testWidgets('start: options and "Wer spielt?" with 4 players', skip: skip, (tester) async {
      await _pumpApp(tester, const Scaffold(body: SizedBox.expand()));
      showDiceSheetOptionsDialog(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();
      await _shot(tester, '02-options');
      Navigator.of(tester.element(find.byKey(const Key('dicesheet-options')))).pop();
      await tester.pumpAndSettle();
      showSeatPlayersDialog(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();
      await _tap(tester, 'seat-players-4');
      await _shot(tester, '03-who-plays-4');
    });

    testWidgets('4 players: rolling, suggestions, kept dice, the second roll', skip: skip, (tester) async {
      await _game(tester);
      await _shot(tester, '04-start-4-players');
      await _tap(tester, 'dicesheet-roll');
      await _shot(tester, '05-first-roll-suggestions');
      await _tap(tester, 'dicesheet-die-1');
      await _tap(tester, 'dicesheet-die-2');
      await _tap(tester, 'dicesheet-die-4');
      await _shot(tester, '06-three-dice-kept');
      await _tap(tester, 'dicesheet-roll');
      await _shot(tester, '07-second-roll-full-house');
      await _tap(tester, 'dicesheet-score-fullHouse');
      await _shot(tester, '08-filled-next-player');
    });

    testWidgets('4 players: the bonus reached, mid-game', skip: skip, (tester) async {
      final c = await _game(tester, rolls: const []);
      await _withBonus(tester, c);
      await _tap(tester, 'dicesheet-roll');
      await _shot(tester, '09-bonus-reached');
    });

    testWidgets('4 players: game end ranking', skip: skip, (tester) async {
      final c = await _game(tester, rolls: const []);
      await _botTurns(tester, c, 52);
      await tester.pumpAndSettle();
      await _shot(tester, '10-game-end-ranking');
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
    });

    for (final (tag, locale, brightness) in [
      ('dark', const Locale('de'), Brightness.dark),
      ('ar', const Locale('ar'), Brightness.light),
      ('en', const Locale('en'), Brightness.light),
    ]) {
      testWidgets('4 players $tag: suggestions and the end', skip: skip, (tester) async {
        final c = await _game(tester, locale: locale, brightness: brightness, rolls: const []);
        await _withBonus(tester, c);
        await _tap(tester, 'dicesheet-roll');
        await _tap(tester, 'dicesheet-die-0');
        await _tap(tester, 'dicesheet-die-1');
        await _shot(tester, '11-$tag-suggestions-kept');
        await _botTurns(tester, c, 60);
        await _shot(tester, '12-$tag-game-end');
      });
    }

    for (final (tag, size, safe, text) in [
      ('se-text130', const Size(375, 667), const EdgeInsets.only(top: 20), 1.3),
      ('15pro', const Size(393, 852), const EdgeInsets.only(top: 59, bottom: 34), 1.0),
      ('15pro-landscape', const Size(852, 393), const EdgeInsets.fromLTRB(59, 0, 59, 21), 1.0),
      ('ipad', const Size(820, 1180), const EdgeInsets.only(top: 24, bottom: 20), 1.0),
      ('ipad-landscape', const Size(1180, 820), const EdgeInsets.only(top: 24, bottom: 20), 1.0),
    ]) {
      testWidgets('4 players on $tag', skip: skip, (tester) async {
        final c = await _game(tester, size: size, safe: safe, text: text, rolls: const []);
        await _withBonus(tester, c);
        await _tap(tester, 'dicesheet-roll');
        await _tap(tester, 'dicesheet-die-2');
        await _shot(tester, '13-$tag-4-players');
        await _botTurns(tester, c, 60);
        await _shot(tester, '14-$tag-game-end');
      });
    }

    testWidgets('2 players', skip: skip, (tester) async {
      final c = await _game(tester, players: 2, rolls: const []);
      await _withBonus(tester, c);
      await _tap(tester, 'dicesheet-roll');
      await _shot(tester, '15-2-players');
    });
    // The rules page (KLD-123), "⋮" menu, "Wer fängt an?" (follow-ups).
    testWidgets('rules page, whole', skip: skip, (tester) async {
      await _pumpApp(tester, const RulesScreen(gameId: 'dicesheet', config: GameConfig('dicesheet', extraFives: true)),
          size: const Size(390, 2600));
      await _shot(tester, '20-rules-page-whole');
    });

    testWidgets('rules page, phone', skip: skip, (tester) async {
      await _pumpApp(tester, const RulesScreen(gameId: 'dicesheet'));
      await _shot(tester, '21-rules-page-top');
      await tester.drag(find.byKey(const Key('rules-page')), const Offset(0, -700));
      await tester.pumpAndSettle();
      await _shot(tester, '22-rules-page-boxes');
    });

    testWidgets('game: "Regeln", "Neu hier?", who starts, the "⋮" menu', skip: skip, (tester) async {
      SeenTips.debugReset();
      await _game(tester);
      await _shot(tester, '23-game-rules-button');
      await _tap(tester, 'shell-menu');
      await _shot(tester, '24-game-menu-open');
    });

    testWidgets('start options: "Wer fängt an?", order with arrows, random start', skip: skip, (tester) async {
      await _pumpApp(tester, const Scaffold(body: SizedBox.expand()));
      showDiceSheetOptionsDialog(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();
      await _tap(tester, 'dicesheet-start-order');
      await _shot(tester, '25-options-start-order');
      Navigator.of(tester.element(find.byKey(const Key('dicesheet-options')))).pop();
      await tester.pumpAndSettle();
      showSeatPlayersDialog(tester.element(find.byType(Scaffold)), reorder: true);
      await tester.pumpAndSettle();
      await _tap(tester, 'seat-players-4');
      await _tap(tester, 'seat-up-2');
      await _shot(tester, '26-who-plays-order');
    });

    testWidgets('random start announced', skip: skip, (tester) async {
      var seed = 0;
      while ((createGame(GameConfig('dicesheet', seed: seed, players: 4, randomStart: true)) as DiceSheetGame)
              .startSeat !=
          2) {
        seed++;
      }
      final c = GameController.hotSeat(GameConfig('dicesheet', seed: seed, players: 4, randomStart: true));
      addTearDown(c.dispose);
      await _pumpApp(tester, buildGameScreen(c));
      await _shot(tester, '27-random-start');
    });

    testWidgets('a two-player game (GameScreen) with the "⋮" menu', skip: skip, (tester) async {
      final c = GameController.hotSeat(const GameConfig('connect4'));
      addTearDown(c.dispose);
      await _pumpApp(tester, buildGameScreen(c));
      await _shot(tester, '28-gamescreen-connect4');
      await _tap(tester, 'shell-menu');
      await _shot(tester, '29-gamescreen-menu-open');
    });
  });
}
