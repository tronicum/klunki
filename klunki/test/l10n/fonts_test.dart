import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/ui/menu_screen.dart';

import 'l10n_test_utils.dart';

void main() {
  List<String>? themeFallback(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(MenuScreen))).textTheme.bodyMedium!.fontFamilyFallback;

  List<String>? appBarTitleFallback(WidgetTester tester) => tester
      .widget<RichText>(find.descendant(of: find.byType(AppBar), matching: find.byType(RichText)).first)
      .text
      .style
      ?.fontFamilyFallback;

  test('fallback order: Arabic, symbols, then the Chinese subset', () {
    expect(appFontFallback, [arabicFontFamily, symbolFontFamily, chineseFontFamily]);
  });

  for (final code in ['de', 'en', 'fr', 'es', 'zh', 'ar', 'fa']) {
    testWidgets('$code: text falls back to the bundled fonts', (tester) async {
      await tester.pumpWidget(klunkiApp(locale: Locale(code)));
      await tester.pumpAndSettle();
      expect(themeFallback(tester), appFontFallback);
      expect(appBarTitleFallback(tester), containsAll(appFontFallback));
    });
  }

  test('web: Roboto is the primary family of every text style', () {
    for (final theme in [KlunkiTheme.light, KlunkiTheme.dark]) {
      final web = withAppFonts(theme, web: true);
      for (final style in [web.textTheme.bodyMedium, web.textTheme.titleMedium, web.primaryTextTheme.labelLarge]) {
        expect(style!.fontFamily, robotoFontFamily);
        expect(style.fontFamilyFallback, appFontFallback);
      }
    }
  });

  test('native: the platform font stays the primary family', () {
    final base = ThemeData(useMaterial3: true);
    final native = withAppFonts(base, web: false);
    expect(native.textTheme.bodyMedium!.fontFamily, base.textTheme.bodyMedium!.fontFamily);
    expect(native.textTheme.bodyMedium!.fontFamilyFallback, appFontFallback);
  });

  testWidgets('language picker endonyms use the bundled fallback in any locale', (tester) async {
    await tester.pumpWidget(klunkiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-button')));
    await tester.pumpAndSettle();
    for (final name in ['العربية', '简体中文']) {
      expect(tester.widget<Text>(find.text(name)).style?.fontFamilyFallback, appFontFallback, reason: name);
    }
  });

  test('font files are bundled TrueType fonts', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const files = {
      'Roboto/Roboto-Regular.ttf': 100000,
      'Roboto/Roboto-Medium.ttf': 100000,
      'Roboto/Roboto-Bold.ttf': 100000,
      'NotoSansArabic/NotoSansArabic-Regular.ttf': 50000,
      'NotoSansArabic/NotoSansArabic-Bold.ttf': 50000,
      'NotoSansSC/NotoSansSC-Regular.ttf': 10000,
      'NotoSansSC/NotoSansSC-Bold.ttf': 10000,
      'NotoSansMath/NotoSansMath-Regular.ttf': 1000,
    };
    for (final e in files.entries) {
      final data = await rootBundle.load('assets/fonts/${e.key}');
      expect(data.lengthInBytes, greaterThan(e.value), reason: e.key);
      expect(data.getUint32(0), 0x00010000, reason: '${e.key}: TrueType magic');
    }
  });

  test('OFL licenses are registered once per font', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFontLicenses();
    registerFontLicenses();
    final entries = await LicenseRegistry.licenses.toList();
    for (final package in fontLicenseAssets.keys) {
      final mine = entries.where((e) => e.packages.contains(package)).toList();
      expect(mine, hasLength(1), reason: package);
      final text = mine.single.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('SIL Open Font License, Version 1.1'), reason: package);
    }
  });
}
