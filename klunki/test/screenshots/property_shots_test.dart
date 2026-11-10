// KLD-060 screenshots of Baulöwe: the menu tile, the start options, the
// start of a 3-player game and its first roll, a mid-game state with "Meine
// Straßen", a street, the result, dark mode with 4 players, landscape, the
// tour and the rules page. Skipped unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/property_shots_test.dart --plain-name kld060
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
import 'package:klunki/profile/beginner_settings.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/board_zoom.dart';
import 'package:klunki/ui/games/property/property_options.dart';
import 'package:klunki/ui/menu_screen.dart' show MenuScreen, menuShowsDebugConsole;
import 'package:klunki/ui/rules/rules_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
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

Future<void> _shot(WidgetTester tester, String name, {String dir = 'kld060', bool wait = true}) async {
  debugDisableShadows = false;
  if (wait) {
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/$dir/$name.png');
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
    {int players = 3,
    PropertyOptions options = const PropertyOptions(),
    int seed = 4,
    Locale locale = const Locale('de'),
    Brightness brightness = Brightness.light,
    Size size = _phone,
    EdgeInsets safe = EdgeInsets.zero}) async {
  final c = GameController.hotSeat(GameConfig('property', seed: seed, players: players, property: options));
  addTearDown(c.dispose);
  await _pumpApp(tester, buildGameScreen(c), locale: locale, brightness: brightness, size: size, safe: safe);
  return c;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Plays [moves] bot moves through the controller (set-up for a later
/// screenshot, not the thing shown), then on to the next "Würfeln" of seat
/// [until] (or the end).
Future<void> _botMoves(WidgetTester tester, GameController c, int moves, {int? until, int seed = 3}) async {
  final bot = PropertyBot(Random(seed));
  Map<String, Object?> next() {
    final g = c.game as PropertyGame;
    final m = bot.choose(g);
    // Trades are shown in property_trade_shots_test.dart: play on instead.
    if (m['action'] == 'tradeOffer') {
      return g.legalMoves.firstWhere((x) => x['action'] == 'endTurn' || x['action'] == 'roll');
    }
    return m;
  }

  for (var i = 0; i < moves && !c.game.isOver; i++) {
    await c.submit(next());
  }
  if (until != null) {
    while (!c.game.isOver) {
      final g = c.game as PropertyGame;
      if (g.actor == until && g.phase == PropertyPhase.roll) break;
      await c.submit(next());
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
    BeginnerSettings.debugReset();
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.propertyIntro);
    ExtraSeatNames.debugReset();
  });

  // KLD-060 screenshots of Baulöwe (de, phone, light unless named). Into
  // <KLUNKI_SHOTS>/kld060:
  //
  //   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/property_shots_test.dart --plain-name kld060
  group('kld060', () {
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
      await tester.ensureVisible(find.byKey(const Key('menu-property')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('menu-property-local')), findsOneWidget);
      expect(find.byKey(const Key('menu-property-network')), findsNothing);
      await _shot(tester, '01-menu-tile');
    });

    testWidgets('start options', skip: skip, (tester) async {
      await _pumpApp(tester, const Scaffold(body: SizedBox.expand()));
      showPropertyOptionsDialog(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();
      await _shot(tester, '02-options');
      await tester.drag(find.byKey(const Key('property-options')), const Offset(0, -600));
      await tester.pumpAndSettle();
      await _shot(tester, '03-options-scrolled');
    });

    testWidgets('the start and the first roll', skip: skip, (tester) async {
      await _game(tester);
      await _shot(tester, '04-start-3-players');
      await _tap(tester, 'property-roll');
      await _shot(tester, '05-first-roll');
    });

    testWidgets('mid-game', skip: skip, (tester) async {
      final c = await _game(tester);
      await _botMoves(tester, c, 220, until: 0);
      await _shot(tester, '06-mid-game');
      await _tap(tester, 'shell-history');
      await _shot(tester, '06b-mid-game-history');
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      await _tap(tester, 'property-manage');
      await _shot(tester, '07-mid-game-my-streets');
    });

    testWidgets('a street sheet', skip: skip, (tester) async {
      final c = await _game(tester);
      await _botMoves(tester, c, 120, until: 0);
      final g = c.game as PropertyGame;
      final owned = g.ownedBy(1);
      await _tap(tester, 'property-square-${owned.isEmpty ? 1 : owned.first}');
      await _shot(tester, '08-street-sheet');
    });

    testWidgets('the result', skip: skip, (tester) async {
      final c = await _game(tester, options: const PropertyOptions(rounds: 30));
      await _botMoves(tester, c, 100000);
      expect(c.game.isOver, isTrue);
      await _shot(tester, '09-result');
    });

    testWidgets('mid-game, dark and 4 players', skip: skip, (tester) async {
      final c = await _game(tester, players: 4, brightness: Brightness.dark, seed: 9);
      await _botMoves(tester, c, 260, until: 0);
      await _shot(tester, '10-dark-4-players');
    });

    testWidgets('mid-game, landscape', skip: skip, (tester) async {
      final c = await _game(tester,
          size: const Size(852, 393), safe: const EdgeInsets.fromLTRB(59, 0, 59, 21));
      await _botMoves(tester, c, 220, until: 0);
      await _shot(tester, '11-landscape');
    });

    testWidgets('the tour, step 1', skip: skip, (tester) async {
      SeenTips.debugReset();
      await _game(tester);
      expect(find.byKey(const Key('property-coach')), findsOneWidget);
      await _shot(tester, '12-tour-step-1');
    });

    // A roll as it is shown (maintainer feedback on build 2026110911): the
    // dice tumble, the token walks (here over Start), then the card and the
    // question. Into <KLUNKI_SHOTS>/anim.
    testWidgets('anim: dice, walk, card', skip: skip, (tester) async {
      final c = GameController.hotSeat(const GameConfig('property', seed: 4, players: 3));
      addTearDown(c.dispose);
      final g = c.game as PropertyGame;
      g.debugSetCash(0, 1500, pos: 34);
      g.debugScriptDice([4, 5]);
      await _pumpApp(tester, buildGameScreen(c));
      await _shot(tester, 'a0-before-roll', dir: 'anim');
      await tester.ensureVisible(find.byKey(const Key('property-roll')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('property-roll')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await _shot(tester, 'a1-dice-mid-roll', dir: 'anim', wait: false);
      await tester.pump(const Duration(milliseconds: 300));
      await _shot(tester, 'a2-dice-landing', dir: 'anim', wait: false);
      // From square 34: Start is the 6th step; mid-hop onto it.
      await tester.pump(const Duration(milliseconds: 200 + 5 * 150 + 90));
      await _shot(tester, 'a3-token-mid-walk-over-start', dir: 'anim', wait: false);
      await tester.pump(const Duration(milliseconds: 2 * 150));
      await _shot(tester, 'a4-token-almost-there', dir: 'anim', wait: false);
      await tester.pumpAndSettle();
      await _shot(tester, 'a5-card-and-question', dir: 'anim');
    });

    testWidgets('rules page', skip: skip, (tester) async {
      await _pumpApp(
          tester,
          const RulesScreen(
              gameId: 'property',
              config: GameConfig('property', property: PropertyOptions(free: PropertyFreeSquare.pot, doubleStart: true))),
          size: const Size(390, 2400));
      await _shot(tester, '13-rules-page');
    });
  });

  // KLD-060: street names on the board (read from the bottom, one size per
  // board, short forms on a phone, full names on a tablet or zoomed in).
  // Into <KLUNKI_SHOTS>/names-final2:
  //
  //   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/property_shots_test.dart --plain-name names
  // KLD-060: the compact deed card in the board centre (landing, buy
  // question, an owned street with its rent highlighted). Into
  // <KLUNKI_SHOTS>/deed-centre:
  //
  //   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/property_shots_test.dart --plain-name deed-centre
  group('deed-centre', () {
    for (final (dev, size, safe) in [
      ('iphone15pro', const Size(393, 852), const EdgeInsets.only(top: 59, bottom: 34)),
      ('iphonese', const Size(375, 667), EdgeInsets.zero),
      ('ipad', const Size(820, 1180), const EdgeInsets.only(top: 24, bottom: 20)),
    ]) {
      testWidgets('on $dev', skip: skip, (tester) async {
        final c = await _game(tester, size: size, safe: safe);
        // Play until a player stands on an unowned street: the buy question.
        final bot = PropertyBot(Random(3));
        for (var i = 0; i < 400 && !c.game.isOver; i++) {
          final g = c.game as PropertyGame;
          if (i > 20 && g.phase == PropertyPhase.buy && g.theme.squares[g.seats[g.actor!].pos].kind == PropertyKind.street) {
            break;
          }
          final m = bot.choose(g);
          await c.submit(m['action'] == 'tradeOffer'
              ? g.legalMoves.firstWhere((x) => x['action'] == 'endTurn' || x['action'] == 'roll')
              : m);
        }
        await tester.pumpAndSettle();
        await _shot(tester, '$dev-buy', dir: 'deed-centre');
        // Later: an owned street, its rent row highlighted.
        await _botMoves(tester, c, 200, until: 0);
        await _shot(tester, '$dev-owned', dir: 'deed-centre');
      });
    }
  });

  // KLD-060: names on big squares (tablet portrait and landscape, a large
  // iPhone, a zoomed phone board). Into <KLUNKI_SHOTS>/names-ipad:
  //
  //   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/property_shots_test.dart --plain-name names-big
  group('names-big', () {
    for (final (dev, size, safe) in [
      ('ipad', const Size(820, 1180), const EdgeInsets.only(top: 24, bottom: 20)),
      ('ipad-landscape', const Size(1180, 820), const EdgeInsets.only(top: 24, bottom: 20)),
      ('iphone15promax', const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    ]) {
      for (final board in ['berlin', 'fantasie']) {
        testWidgets('on $dev, $board', skip: skip, (tester) async {
          final c = await _game(tester, size: size, safe: safe, options: PropertyOptions(theme: board));
          await _botMoves(tester, c, 220, until: 0);
          await _shot(tester, '$dev-$board', dir: 'names-ipad');
          if (dev == 'iphone15promax') {
            final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
            final side = tester.getSize(find.byType(InteractiveViewer)).width;
            for (final zoom in [1.6, 2.5, 4.0]) {
              viewer.transformationController!.value = BoardZoom.focusOn(Offset(side * 0.2, side * 0.8), zoom, side);
              await tester.pumpAndSettle();
              await _shot(tester, '$dev-$board-zoom-$zoom', dir: 'names-ipad');
            }
          }
        });
      }
    }
  });

  group('names', () {
    for (final (dev, size, safe) in [
      ('iphone15pro', const Size(393, 852), const EdgeInsets.only(top: 59, bottom: 34)),
      ('ipad', const Size(820, 1180), const EdgeInsets.only(top: 24, bottom: 20)),
    ]) {
      for (final board in ['berlin', 'fantasie']) {
        testWidgets('on $dev, $board', skip: skip, (tester) async {
          final c = await _game(tester, size: size, safe: safe, options: PropertyOptions(theme: board));
          await _botMoves(tester, c, 220, until: 0);
          await _shot(tester, '$dev-$board', dir: 'names-final2');
          if (dev == 'iphone15pro') {
            // Zoomed in (as by a pinch) on the bottom left corner: full names.
            final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
            final side = tester.getSize(find.byType(InteractiveViewer)).width;
            viewer.transformationController!.value = BoardZoom.focusOn(Offset(side * 0.2, side * 0.8), 2.2, side);
            await tester.pumpAndSettle();
            await _shot(tester, '$dev-$board-zoomed', dir: 'names-final2');
          }
        });
      }
    }
  });
}
