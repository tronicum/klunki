// KLD-121 screenshots of Mäxchen on a phone (390×844): the menu tile, the
// start options, peeking under the cup, the announcement picker, the
// believe/doubt decision, the handover cover, the reveal and the game end;
// plus the picker in English and Arabic and the decision in dark mode; and
// (KLD-121 follow-up) every phase on an iPhone SE (375×667), with text at
// 130 %, on an iPhone 15 Pro, in landscape and on an iPad
// (`16-<device>-<phase>`).
// Skipped unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/maexchen_shots_test.dart --plain-name kld121
import 'dart:io';
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
import 'package:klunki/ui/games/maexchen/maexchen_options.dart';
import 'package:klunki/ui/menu_screen.dart' show MenuScreen, menuShowsDebugConsole;
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

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
    final f = File('$_out/kld121/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

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
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
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
        labels: PlayerLabels(names: {
          Player.a: locale.languageCode == 'ar' ? 'سارة' : 'Anna',
          Player.b: locale.languageCode == 'ar' ? 'عمر' : 'Ben',
        }),
        child: home,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<GameController> _game(WidgetTester tester, List<List<int>> rolls,
    {Locale locale = const Locale('de'),
    Brightness brightness = Brightness.light,
    int lives = 3,
    Size size = _phone,
    EdgeInsets safe = EdgeInsets.zero,
    double text = 1}) async {
  final c = GameController.hotSeat(GameConfig('maexchen', seed: 5, lives: lives));
  addTearDown(c.dispose);
  (c.game as MaexchenGame).debugScriptRolls(rolls);
  await _pumpApp(tester, buildGameScreen(c),
      locale: locale, brightness: brightness, size: size, safe: safe, text: text);
  return c;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _scrollTop(WidgetTester tester) async {
  await tester.drag(find.byKey(const Key('maexchen-board')), const Offset(0, 600));
  await tester.pumpAndSettle();
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  group('kld121', () {
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
      await tester.ensureVisible(find.byKey(const Key('menu-maexchen')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('menu-maexchen-local')), findsOneWidget);
      expect(find.byKey(const Key('menu-maexchen-network')), findsNothing);
      await _shot(tester, '1-menu-tile');
    });

    testWidgets('options', skip: skip, (tester) async {
      await _pumpApp(tester, const Scaffold(body: SizedBox.expand()));
      showMaexchenOptionsDialog(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();
      await _shot(tester, '2-options');
    });

    testWidgets('a round: peek, picker, handover, decision, reveal', skip: skip, (tester) async {
      await _game(tester, [[5, 3], [6, 2]]);
      await _shot(tester, '3-start');
      await _tap(tester, 'maexchen-roll');
      await _tap(tester, 'maexchen-peek');
      await _scrollTop(tester);
      await _shot(tester, '4-peek-under-the-cup');
      await _tap(tester, 'maexchen-peek');
      await _tap(tester, 'maexchen-value-54');
      await _shot(tester, '5-announcement-picker');
      await _tap(tester, 'maexchen-announce');
      await _shot(tester, '6-handover-cover');
      await _tap(tester, 'handover-continue');
      await _shot(tester, '7-believe-or-doubt');
      await _tap(tester, 'maexchen-doubt');
      await _shot(tester, '8-handover-with-verdict');
      await _tap(tester, 'handover-continue');
      await _shot(tester, '9-reveal');
    });

    testWidgets('Mäxchen announced, then the game end', skip: skip, (tester) async {
      await _game(tester, [[2, 1], [6, 6]], lives: 1);
      await _tap(tester, 'maexchen-roll');
      await _tap(tester, 'maexchen-value-21');
      await _tap(tester, 'maexchen-announce');
      await _tap(tester, 'handover-continue');
      await _shot(tester, '10-maexchen-doubt-or-give-up');
      await _tap(tester, 'maexchen-doubt');
      await tester.pumpAndSettle();
      await _shot(tester, '11-game-end');
    });

    testWidgets('a fake Mäxchen caught (decision 2026-11-06)', skip: skip, (tester) async {
      await _game(tester, [[6, 6]]);
      await _tap(tester, 'maexchen-roll');
      await _tap(tester, 'maexchen-value-21');
      await _tap(tester, 'maexchen-announce');
      await _tap(tester, 'handover-continue');
      await _tap(tester, 'maexchen-doubt');
      await _shot(tester, '14-fake-maexchen-handover');
      await _tap(tester, 'handover-continue');
      await _shot(tester, '15-fake-maexchen-reveal');
    });

    for (final (tag, locale, brightness) in [
      ('en', const Locale('en'), Brightness.light),
      ('ar', const Locale('ar'), Brightness.light),
      ('de-dark', const Locale('de'), Brightness.dark),
    ]) {
      testWidgets('picker and decision $tag', skip: skip, (tester) async {
        await _game(tester, [[4, 1], [3, 3]], locale: locale, brightness: brightness);
        await _tap(tester, 'maexchen-roll');
        await _tap(tester, 'maexchen-peek');
        await _tap(tester, 'maexchen-value-43');
        await _shot(tester, '12-picker-$tag');
        await _tap(tester, 'maexchen-announce');
        await _tap(tester, 'handover-continue');
        await _tap(tester, 'maexchen-believe');
        await _tap(tester, 'maexchen-roll');
        await _tap(tester, 'maexchen-value-44');
        await _tap(tester, 'maexchen-announce');
        await _tap(tester, 'handover-continue');
        await _shot(tester, '13-decision-$tag');
      });
    }

    // KLD-121 follow-up: the actions stay on screen (no scrolling) in every
    // phase, on small phones, with large text, in landscape, on a tablet.
    for (final (tag, size, safe, text) in [
      ('se', const Size(375, 667), const EdgeInsets.only(top: 20), 1.0),
      ('se-text130', const Size(375, 667), const EdgeInsets.only(top: 20), 1.3),
      ('15pro', const Size(393, 852), const EdgeInsets.only(top: 59, bottom: 34), 1.0),
      ('15pro-landscape', const Size(852, 393), const EdgeInsets.fromLTRB(59, 0, 59, 21), 1.0),
      ('ipad', const Size(820, 1180), const EdgeInsets.only(top: 24, bottom: 20), 1.0),
      ('ipad-landscape', const Size(1180, 820), const EdgeInsets.only(top: 24, bottom: 20), 1.0),
    ]) {
      testWidgets('every phase on $tag', skip: skip, (tester) async {
        await _game(tester, [[4, 1], [3, 1]], size: size, safe: safe, text: text);
        await _shot(tester, '16-$tag-1-roll');
        await _tap(tester, 'maexchen-roll');
        await _shot(tester, '16-$tag-2-announce');
        await _tap(tester, 'maexchen-peek');
        await _tap(tester, 'maexchen-value-52');
        await _shot(tester, '16-$tag-3-peek-and-choice');
        await _tap(tester, 'maexchen-announce');
        await _tap(tester, 'handover-continue');
        await _shot(tester, '16-$tag-4-believe-or-doubt');
        await _tap(tester, 'maexchen-doubt');
        await _tap(tester, 'handover-continue');
        await _shot(tester, '16-$tag-5-reveal');
        await _tap(tester, 'maexchen-roll');
        await _tap(tester, 'maexchen-value-21');
        await _tap(tester, 'maexchen-announce');
        await _tap(tester, 'handover-continue');
        await _shot(tester, '16-$tag-6-maexchen');
      });
    }
  });
}
