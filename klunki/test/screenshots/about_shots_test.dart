// KLD-102 screenshots: the menu footer with "Über Klunki", the About screen
// and the stored privacy and Impressum texts (de, plus ar for RTL). Skipped unless
// KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/about flutter test test/screenshots/about_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/l10n/locale_controller.dart';

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

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  for (final lang in ['de', 'ar']) {
    testWidgets('about $lang', skip: skip, (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
          key: _boundary, child: KlunkiApp(localeController: LocaleController.memory(Locale(lang)))));
      await tester.pump();
      final entry = find.byKey(const Key('menu-about'));
      await tester.scrollUntilVisible(entry, 300, scrollable: find.byType(Scrollable).first);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      await _shot(tester, '$lang-1-menu-footer');
      await tester.tap(entry);
      await tester.pumpAndSettle();
      // The app icon is an asset image: decode it before the shot.
      final icon = find.descendant(of: find.byKey(const Key('about-app-icon')), matching: find.byType(Image));
      await tester.runAsync(() => precacheImage(tester.widget<Image>(icon).image, tester.element(icon)));
      await tester.pump();
      await _shot(tester, '$lang-2-about');
      // The stored texts (KLD-102): privacy policy, then Impressum.
      for (final (n, page) in [(3, 'privacy'), (4, 'impressum')]) {
        await tester.tap(find.byKey(Key('about-$page')));
        await tester.pumpAndSettle();
        for (var i = 0; i < 100 && find.byKey(Key('$page-text')).evaluate().isEmpty; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump();
        }
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
        await _shot(tester, '$lang-$n-$page');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
    });
  }
}
