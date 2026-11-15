// KLD-127 screenshots: "Rechtliche Hinweise" of the Quartett cards: the page,
// the small link under the card gallery and the deck picker, the entry in the
// game menu and on the About screen (de, plus ar for RTL). Skipped unless
// KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/legal flutter test test/screenshots/quartett_legal_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/ui/about_screen.dart';
import 'package:klunki/ui/games/quartett_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final f = File('$_out/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

Future<void> _app(WidgetTester tester, String lang) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      RepaintBoundary(key: _boundary, child: KlunkiApp(localeController: LocaleController.memory(Locale(lang)))));
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
  await tester.pumpAndSettle();
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  // German: through the whole app (menu, gallery, picker, game, About).
  testWidgets('kld127 de', skip: skip, (tester) async {
    await _app(tester, 'de');
    // The card gallery: the link under the decks, then the page.
    await _tap(tester, find.byKey(const Key('menu-quartett-trumpf-cards')));
    final link = find.byKey(const Key('quartett-legal-link'));
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await _shot(tester, 'de-1-gallery-link');
    await _tap(tester, link);
    await _shot(tester, 'de-2-page');
    await _back(tester);
    await _back(tester);

    // The deck picker before a hot-seat game.
    await _tap(tester, find.byKey(const Key('menu-quartett-trumpf-local')));
    await _shot(tester, 'de-3-deck-picker');
    // In the game: the "⋮" menu.
    await _tap(tester, find.byKey(const Key('quartett-deck-play')));
    // "Wer spielt?" (names) after the deck: keep the defaults.
    if (find.byKey(const Key('hot-seat-names-ok')).evaluate().isNotEmpty) {
      await _tap(tester, find.byKey(const Key('hot-seat-names-ok')));
    }
    await _tap(tester, find.byKey(const Key('shell-menu')));
    await _shot(tester, 'de-4-game-menu');
  });

  testWidgets('kld127 de about', skip: skip, (tester) async {
    await _app(tester, 'de');
    await _tap(tester, find.byKey(const Key('menu-about')));
    final icon = find.descendant(of: find.byKey(const Key('about-app-icon')), matching: find.byType(Image));
    await tester.runAsync(() => precacheImage(tester.widget<Image>(icon).image, tester.element(icon)));
    final tile = find.byKey(const Key('about-quartett-legal'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await _shot(tester, 'de-5-about');
  });

  // Arabic (RTL): gallery link, page and About in a themed app with the web
  // font fallback (the test engine has no Arabic system font).
  for (final (n, home) in [(1, const QuartettGalleryScreen()), (5, const AboutScreen())]) {
    testWidgets('kld127 ar $n', skip: skip, (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
        key: _boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: withAppFonts(KlunkiTheme.light, web: true),
          locale: const Locale('ar'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ));
      await tester.pumpAndSettle();
      final link = find.byKey(Key(n == 1 ? 'quartett-legal-link' : 'about-quartett-legal'));
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await _shot(tester, n == 1 ? 'ar-1-gallery-link' : 'ar-5-about');
      if (n == 1) {
        await _tap(tester, link);
        await _shot(tester, 'ar-2-page');
      }
    });
  }
}
