import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/ui/menu_screen.dart';

import 'l10n_test_utils.dart';

void main() {
  test('Arabic script: ar and fa only', () {
    expect(usesArabicScript(const Locale('ar')), isTrue);
    expect(usesArabicScript(const Locale('fa')), isTrue);
    for (final code in ['de', 'en', 'fr', 'es', 'zh']) {
      expect(usesArabicScript(Locale(code)), isFalse, reason: code);
    }
  });

  List<String>? themeFallback(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(MenuScreen))).textTheme.bodyMedium!.fontFamilyFallback;

  List<String>? appBarTitleFallback(WidgetTester tester) => tester
      .widget<RichText>(find.descendant(of: find.byType(AppBar), matching: find.byType(RichText)).first)
      .text
      .style
      ?.fontFamilyFallback;

  for (final code in ['ar', 'fa']) {
    testWidgets('$code: text falls back to the bundled Noto Sans Arabic', (tester) async {
      await tester.pumpWidget(klunkiApp(locale: Locale(code)));
      await tester.pumpAndSettle();
      expect(themeFallback(tester), arabicFontFallback);
      expect(appBarTitleFallback(tester), contains(arabicFontFamily));
    });
  }

  for (final code in ['de', 'zh']) {
    testWidgets('$code: no Arabic fallback in the theme', (tester) async {
      await tester.pumpWidget(klunkiApp(locale: Locale(code)));
      await tester.pumpAndSettle();
      expect(themeFallback(tester), isNot(contains(arabicFontFamily)));
    });
  }

  testWidgets('language picker endonyms use the Arabic fallback in any locale', (tester) async {
    await tester.pumpWidget(klunkiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-button')));
    await tester.pumpAndSettle();
    final style = tester.widget<Text>(find.text('العربية')).style;
    expect(style?.fontFamilyFallback, arabicFontFallback);
  });

  test('font files are bundled TrueType fonts', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final name in ['Regular', 'Bold']) {
      final data = await rootBundle.load('assets/fonts/NotoSansArabic/NotoSansArabic-$name.ttf');
      expect(data.lengthInBytes, greaterThan(50000), reason: name);
      expect(data.getUint32(0), 0x00010000, reason: '$name: TrueType magic');
    }
  });

  test('OFL license is registered once', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFontLicenses();
    registerFontLicenses();
    final entries = await LicenseRegistry.licenses
        .where((e) => e.packages.contains('Noto Sans Arabic'))
        .toList();
    expect(entries, hasLength(1));
    final text = entries.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('SIL Open Font License, Version 1.1'));
  });
}
