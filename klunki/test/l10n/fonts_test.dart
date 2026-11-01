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

  // KLD-093: on iOS a fallback list displaced the system font (Latin from the
  // Noto Sans SC subset, umlauts from the system fallback: a bold "ä"). The
  // tests run as a native (non-web) app, like Android/iOS.
  for (final code in ['de', 'en', 'fr', 'es', 'zh', 'ar', 'fa']) {
    testWidgets('$code: native text uses no bundled fallback ahead of the platform font', (tester) async {
      await tester.pumpWidget(klunkiApp(locale: Locale(code)));
      await tester.pumpAndSettle();
      expect(themeFallback(tester), isNull);
      expect(appBarTitleFallback(tester), anyOf(isNull, isEmpty));
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

  test('platformFontFallback: bundled fonts on the web only', () {
    expect(platformFontFallback(web: true), appFontFallback);
    expect(platformFontFallback(web: false), isNull);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('native ${platform.name}: no text style lists a bundled fallback family', () {
      final base = ThemeData(useMaterial3: true, platform: platform);
      final native = withAppFonts(base, web: false);
      for (final t in [native.textTheme, native.primaryTextTheme]) {
        for (final style in [t.titleSmall, t.bodyMedium, t.labelLarge, t.headlineSmall]) {
          for (final f in [arabicFontFamily, symbolFontFamily, chineseFontFamily]) {
            expect(style!.fontFamilyFallback ?? const <String>[], isNot(contains(f)));
          }
        }
      }
      // The platform typography (CupertinoSystemText / Roboto) is untouched.
      expect(native.textTheme, base.textTheme);
    });
  }

  testWidgets('language picker endonyms: no bundled fallback on native', (tester) async {
    await tester.pumpWidget(klunkiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-button')));
    await tester.pumpAndSettle();
    for (final name in ['العربية', '简体中文']) {
      expect(tester.widget<Text>(find.text(name)).style?.fontFamilyFallback, isNull, reason: name);
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
