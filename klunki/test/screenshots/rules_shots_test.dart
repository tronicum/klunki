// KLD-123 screenshots on a phone (390×844): the "Regeln" button in three
// games with the "Neu hier?" line, the menu tile's "Regeln" link, the rules
// pages (whole page, tall) of GoStrategy, chess, Mau-Mau, Mäxchen,
// Wortgewandt and 4 Gewinnt, Mau-Mau dark and Arabic, the last step of the
// Mau-Mau tour and the shake consent card. Skipped unless KLUNKI_SHOTS=<dir>:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/rules_shots_test.dart --plain-name kld123
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/fonts.dart' show chineseFontFamilies, withAppFonts;
import 'package:klunki/app/theme.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/platform/shake.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/shake_settings.dart';
import 'package:klunki/ui/menu_screen.dart' show MenuScreen, menuShowsDebugConsole;
import 'package:klunki/ui/rules/rules_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import '../support/asset_images.dart';

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
  // Every part of the Chinese subset (NotoSansSC, NotoSansSC2, ...: tool/update_web_fonts.py).
  for (final f in chineseFontFamilies) {
    await family(f, ['assets/fonts/NotoSansSC/$f-Regular.ttf', 'assets/fonts/NotoSansSC/$f-Bold.ttf']);
  }
  await family('NotoSansMath', ['assets/fonts/NotoSansMath/NotoSansMath-Regular.ttf']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
}

Future<void> _shot(WidgetTester tester, String name) async {
  await precacheShownImages(tester);
  debugDisableShadows = false;
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/kld123/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

Widget _app(Widget home, {Locale locale = const Locale('de'), Brightness brightness = Brightness.light}) {
  final theme = brightness == Brightness.dark ? KlunkiTheme.dark : KlunkiTheme.light;
  return RepaintBoundary(
    key: _boundary,
    child: PlayerNameScope(
      controller: PlayerNameController.memory(),
      hotSeat: HotSeatNamesController.memory(),
      child: LocaleScope(
        controller: LocaleController.memory(locale),
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
          home: PlayerLabelsScope(
            labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}),
            child: home,
          ),
        ),
      ),
    ),
  );
}

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Future<GameController> _game(WidgetTester tester, GameConfig config,
    {Locale locale = const Locale('de'), Brightness brightness = Brightness.light}) async {
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  // Pushed over a page, as from the menu: with the back button.
  await tester.pumpWidget(_app(const Scaffold(body: SizedBox.expand()), locale: locale, brightness: brightness));
  Navigator.of(tester.element(find.byType(Scaffold))).push(MaterialPageRoute<void>(builder: (_) => buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

/// The whole rules page in one picture: the view grows to its height.
Future<void> _page(WidgetTester tester, String id, String name,
    {GameConfig? config, Locale locale = const Locale('de'), Brightness brightness = Brightness.light}) async {
  _size(tester, const Size(390, 4000));
  await tester.pumpWidget(_app(RulesScreen(gameId: id, config: config), locale: locale, brightness: brightness));
  await tester.pumpAndSettle();
  final column = tester.getRect(find.descendant(of: find.byKey(const Key('rules-page')), matching: find.byType(Column)).first);
  final appBar = tester.getRect(find.byType(AppBar));
  tester.view.physicalSize = Size(390, appBar.height + column.height + 44) * 2;
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await _shot(tester, name);
}

void main() {
  setUpAll(_loadFonts);
  final skip = _out == null;

  group('kld123', () {
    setUp(() {
      SeenTips.debugReset();
      SeenTips.shared
        ..markFirst(SeenTips.maumauIntro)
        ..markFirst(SeenTips.dicesheetIntro)
        ..markFirst(SeenTips.propertyIntro)
        ..markFirst(SeenTips.wordtilesBench);
      ShakeSettings.debugReset();
      Motion.debugReset();
    });
    tearDown(Motion.debugReset);

    for (final (id, config) in [
      ('connect4', const GameConfig('connect4')),
      ('chess', const GameConfig('chess')),
      ('maumau', const GameConfig('maumau', seed: 5)),
      ('wordtiles', const GameConfig('wordtiles', seed: 5)),
      ('schiffe', const GameConfig('schiffe')),
      ('quartett-trumpf', const GameConfig('quartett-trumpf', seed: 5)),
    ]) {
      testWidgets('game $id: "Regeln" and "Neu hier?"', skip: skip, (tester) async {
        _size(tester, _phone);
        await _game(tester, config);
        expect(find.byKey(const Key('shell-rules')), findsOneWidget);
        expect(find.byKey(const Key('shell-rules-intro')), findsOneWidget);
        await _shot(tester, '01-game-$id');
      });
    }

    testWidgets('menu tiles with "Regeln"', skip: skip, (tester) async {
      _size(tester, _phone);
      menuShowsDebugConsole = false;
      addTearDown(() => menuShowsDebugConsole = true);
      await tester.pumpWidget(_app(const MenuScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('menu-chess')));
      await tester.pumpAndSettle();
      await _shot(tester, '02-menu');
    });

    for (final id in ['gostrategy', 'chess', 'maumau', 'maexchen', 'wordtiles', 'connect4']) {
      testWidgets('rules page $id', skip: skip, (tester) async {
        await _page(tester, id, '03-page-$id', config: GameConfig(id));
      });
    }

    testWidgets('rules pages: Mau-Mau from the menu, dark, Arabic', skip: skip, (tester) async {
      await _page(tester, 'maumau', '04-page-maumau-menu');
      await _page(tester, 'maumau', '04-page-maumau-dark',
          config: const GameConfig('maumau', mauMau: MauMauRules(jackOnJack: true, sevenDraws: false)),
          brightness: Brightness.dark);
      await _page(tester, 'maumau', '04-page-maumau-ar', config: const GameConfig('maumau'), locale: const Locale('ar'));
      await _page(tester, 'gostrategy', '04-page-gostrategy-ar',
          config: const GameConfig('gostrategy'), locale: const Locale('ar'));
    });

    testWidgets('the Mau-Mau tour ends at "Regeln"', skip: skip, (tester) async {
      SeenTips.debugReset();
      _size(tester, _phone);
      await _game(tester, const GameConfig('maumau', seed: 5));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('maumau-coach-next')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('maumau-coach-step-4')), findsOneWidget);
      await _shot(tester, '05-maumau-tour-4');
    });

    testWidgets('shake consent card', skip: skip, (tester) async {
      _size(tester, _phone);
      Motion.debugPermissionPending = true;
      await _game(tester, const GameConfig('maexchen', seed: 3));
      await tester.tap(find.byKey(const Key('maexchen-roll')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shake-consent')), findsOneWidget);
      await _shot(tester, '06-shake-consent');
    });

    testWidgets('shake consent card, English dark', skip: skip, (tester) async {
      _size(tester, _phone);
      Motion.debugPermissionPending = true;
      await _game(tester, const GameConfig('maexchen', seed: 3), locale: const Locale('en'), brightness: Brightness.dark);
      await tester.tap(find.byKey(const Key('maexchen-roll')));
      await tester.pumpAndSettle();
      await _shot(tester, '06-shake-consent-en-dark');
    });
  });
}
