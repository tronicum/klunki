// KLD-124 screenshots: the people chip ("2", "2–4") on the menu tiles
// (phone light/dark, Arabic, iPhone SE with text at 1.3) and at the top of
// a rules page. Skipped unless KLUNKI_SHOTS=<dir> (pictures in <dir>/kld124):
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/player_count_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/fonts.dart' show chineseFontFamilies, withAppFonts;
import 'package:klunki/app/theme.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/ui/menu_screen.dart';
import 'package:klunki/ui/rules/rules_screen.dart';
import '../support/asset_images.dart';

final String? _out = Platform.environment['KLUNKI_SHOTS'];
const _boundary = Key('shot-boundary');

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
  // The fallback chain names NotoSansMath before the Chinese parts: unloaded,
  // the test font would draw some Chinese characters as boxes.
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
    final f = File('$_out/kld124/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

void _setup(WidgetTester tester, Size size, {double text = 1}) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _pump(WidgetTester tester, Widget home, {Locale locale = const Locale('de'), Brightness b = Brightness.light}) async {
  final theme = b == Brightness.dark ? KlunkiTheme.dark : KlunkiTheme.light;
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: PlayerNameScope(
      controller: PlayerNameController.memory(name: 'Anna'),
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
          home: home,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  // (name, frame, locale, brightness, text scale)
  const menus = <(String, Size, Locale, Brightness, double)>[
    ('menu-phone-de-light', Size(390, 844), Locale('de'), Brightness.light, 1),
    ('menu-phone-de-dark', Size(390, 844), Locale('de'), Brightness.dark, 1),
    ('menu-phone-ar-light', Size(390, 844), Locale('ar'), Brightness.light, 1),
    ('menu-se-de-text1.3', Size(375, 667), Locale('de'), Brightness.light, 1.3),
  ];
  for (final (name, size, locale, b, text) in menus) {
    testWidgets('kld124 $name', skip: skip, (tester) async {
      _setup(tester, size, text: text);
      await _pump(tester, const MenuScreen(), locale: locale, b: b);
      await _shot(tester, name);
      // The whole menu, down to Ausgewürfelt's "2–4".
      tester.view.physicalSize = Size(size.width, 2400 * text) * 2;
      await tester.pumpAndSettle();
      await _shot(tester, '$name-full');
    });
  }

  const pages = <(String, String, Locale, Brightness)>[
    ('rules-dicesheet-de-light', 'dicesheet', Locale('de'), Brightness.light),
    ('rules-connect4-de-dark', 'connect4', Locale('de'), Brightness.dark),
    ('rules-dicesheet-ar-light', 'dicesheet', Locale('ar'), Brightness.light),
  ];
  for (final (name, id, locale, b) in pages) {
    testWidgets('kld124 $name', skip: skip, (tester) async {
      _setup(tester, const Size(390, 480));
      await _pump(tester, RulesScreen(gameId: id), locale: locale, b: b);
      await _shot(tester, name);
    });
  }
}
