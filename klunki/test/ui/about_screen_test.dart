// KLD-102: "Über Klunki" in the menu: version, privacy policy and Impressum
// (stored in the app, offline), support (web page), source code, licences.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/build_info.dart';
import 'package:klunki/app/site_links.dart';
import 'package:klunki/ui/about_screen.dart';

import '../l10n/l10n_test_utils.dart';

Future<void> _openAbout(WidgetTester tester, {Locale locale = testLocale}) async {
  tester.view.physicalSize = const Size(390, 1400) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(klunkiApp(locale: locale));
  await tester.pump();
  final entry = find.byKey(const Key('menu-about'));
  await tester.ensureVisible(entry);
  await tester.tap(entry);
  await tester.pumpAndSettle();
}

/// Waits for a stored legal text: the asset loads asynchronously (real I/O).
Future<void> _waitForText(WidgetTester tester, String text) async {
  for (var i = 0; i < 100 && find.text(text).evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
}

void main() {
  final opened = <Uri>[];
  setUp(() {
    opened.clear();
    aboutLinkOpener = (uri) async {
      opened.add(uri);
      return true;
    };
  });
  tearDown(resetAboutLinkOpener);

  test('page URLs come from one base and pick the page language', () {
    expect(siteBaseUrl, 'https://tronicum.github.io/klunki/');
    expect(sitePageUri(SitePage.privacy, 'de').toString(), 'https://tronicum.github.io/klunki/privacy/');
    expect(sitePageUri(SitePage.impressum, 'de').toString(), 'https://tronicum.github.io/klunki/impressum/');
    expect(sitePageUri(SitePage.support, 'de').toString(), 'https://tronicum.github.io/klunki/support/');
    for (final lang in ['en', 'fr', 'es', 'zh', 'ar', 'fa']) {
      expect(sitePageUri(SitePage.privacy, lang).toString(), 'https://tronicum.github.io/klunki/privacy/#en');
      expect(sitePageUri(SitePage.support, lang).toString(), 'https://tronicum.github.io/klunki/support/#en');
    }
  });

  test('the pages exist in site/ with the anchors the links use', () {
    for (final page in SitePage.values) {
      final html = File('../site/${page.path}index.html').readAsStringSync();
      expect(html, contains('<article id="de"'), reason: page.name);
      expect(html, contains('<article id="en"'), reason: page.name);
    }
  });

  testWidgets('menu footer has "Über Klunki"; it shows version and the links', (tester) async {
    await _openAbout(tester);
    expect(find.text('Über Klunki'), findsWidgets);
    expect(find.text('Version $appVersionLine'), findsOneWidget);
    // The app icon (bundled PNG), not the three-chip menu mark.
    final icon = find.descendant(of: find.byKey(const Key('about-app-icon')), matching: find.byType(Image));
    expect((tester.widget<Image>(icon).image as AssetImage).assetName, 'assets/icon/app_icon.png');
    for (final t in ['Datenschutz', 'Impressum', 'Support', 'Quellcode', 'Open-Source-Lizenzen']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('Klunki ist freie Software unter der GNU AGPL 3.0.'), findsOneWidget);

    // Stored in the app: chevron; web pages: external-link icon.
    Icon trailing(String key) => tester.widget<Icon>(
        find.descendant(of: find.byKey(Key(key)), matching: find.byType(Icon)).last);
    for (final key in ['about-privacy', 'about-impressum', 'about-licenses']) {
      expect(trailing(key).icon, Icons.chevron_right, reason: key);
    }
    for (final key in ['about-support', 'about-source']) {
      expect(trailing(key).icon, Icons.open_in_new, reason: key);
    }

    await tester.tap(find.byKey(const Key('about-support')));
    await tester.tap(find.byKey(const Key('about-source')));
    await tester.pump();
    expect(opened.map((u) => u.toString()), [
      'https://tronicum.github.io/klunki/support/',
      'https://github.com/tronicum/klunki',
    ]);
  });

  testWidgets('English: Support points to the English part', (tester) async {
    await _openAbout(tester, locale: const Locale('en'));
    expect(find.text('About Klunki'), findsWidgets);
    await tester.tap(find.byKey(const Key('about-support')));
    await tester.pump();
    expect(opened.single.toString(), 'https://tronicum.github.io/klunki/support/#en');
  });

  // Local first: the Impressum is readable without the web pages (GitHub
  // Pages may be unpublished or the device offline).
  testWidgets('Impressum opens the stored text; web action and link open the page', (tester) async {
    await _openAbout(tester);
    await tester.tap(find.byKey(const Key('about-impressum')));
    await tester.pumpAndSettle();
    await _waitForText(tester, 'Angaben gemäß § 5 DDG');
    expect(opened, isEmpty);
    expect(find.byKey(const Key('impressum-text')), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Impressum'), findsOneWidget);
    expect(find.text('Angaben gemäß § 5 DDG'), findsOneWidget);
    expect(find.textContaining('Markgrafendamm 4'), findsWidgets);
    expect(find.text('E-Mail: contact@tronicum.com'), findsOneWidget);
    expect(find.textContaining('Maßgeblich ist die Seite im Web'), findsOneWidget);
    await tester.tap(find.byKey(const Key('impressum-open-web')));
    await tester.tap(find.byKey(const Key('impressum-web-link')));
    await tester.pump();
    expect(opened.map((u) => u.toString()), List.filled(2, 'https://tronicum.github.io/klunki/impressum/'));
  });

  testWidgets('English: Impressum shows the English text and links to #en', (tester) async {
    await _openAbout(tester, locale: const Locale('en'));
    await tester.tap(find.byKey(const Key('about-impressum')));
    await tester.pumpAndSettle();
    await _waitForText(tester, 'Information according to § 5 DDG (German Digital Services Act)');
    expect(find.widgetWithText(AppBar, 'Legal notice (Impressum)'), findsOneWidget);
    expect(find.text('Information according to § 5 DDG (German Digital Services Act)'), findsOneWidget);
    expect(find.text('Email: contact@tronicum.com'), findsOneWidget);
    expect(find.text('Angaben gemäß § 5 DDG'), findsNothing);
    await tester.tap(find.byKey(const Key('impressum-open-web')));
    await tester.pump();
    expect(opened.single.toString(), 'https://tronicum.github.io/klunki/impressum/#en');
  });

  testWidgets('Datenschutz opens the stored text, readable offline; web link opens the page', (tester) async {
    await _openAbout(tester);
    await tester.tap(find.byKey(const Key('about-privacy')));
    await tester.pumpAndSettle();
    await _waitForText(tester, 'Datenschutzerklärung für Klunki');
    expect(opened, isEmpty);
    expect(find.text('Datenschutzerklärung für Klunki'), findsOneWidget);
    expect(find.text('Kurz gesagt'), findsOneWidget);
    await tester.tap(find.byKey(const Key('privacy-open-web')));
    await tester.tap(find.byKey(const Key('privacy-web-link')));
    await tester.pump();
    expect(opened.map((u) => u.toString()), List.filled(2, 'https://tronicum.github.io/klunki/privacy/'));
  });

  testWidgets('Arabic: RTL screen, English privacy text laid out LTR', (tester) async {
    await _openAbout(tester, locale: const Locale('ar'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('about-privacy')));
    await tester.pumpAndSettle();
    await _waitForText(tester, 'Privacy Policy for Klunki');
    final h1 = find.text('Privacy Policy for Klunki');
    expect(h1, findsOneWidget);
    expect(Directionality.of(tester.element(h1)), TextDirection.ltr);
    expect(Directionality.of(tester.element(find.byKey(const Key('privacy-web-link')))), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('licence page opens', (tester) async {
    await _openAbout(tester);
    await tester.tap(find.byKey(const Key('about-licenses')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  test('stored legal pages are listed in pubspec.yaml; Support is not stored', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final page in LegalPage.values) {
      expect(pubspec, contains('- ${page.asset}'), reason: page.name);
    }
    expect(LegalPage.values.map((p) => p.site), isNot(contains(SitePage.support)));
  });

  // The stored texts must say what the web pages say: rerun
  // `python3 -I site/export_legal_text.py` after editing a page.
  for (final page in LegalPage.values) {
    test('${page.asset} matches site/${page.site.path}index.html', () {
      final values = (jsonDecode(File('../site/site.json').readAsStringSync()) as Map).cast<String, String>();
      final html = File('../site/${page.site.path}index.html')
          .readAsStringSync()
          .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
          .replaceAllMapped(RegExp(r'\{\{([A-Z_]+)\}\}'), (m) => values[m[1]] ?? m[0]!);
      final asset = File(page.asset).readAsStringSync();
      List<String> words(String s) => s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      for (final lang in ['de', 'en']) {
        final article = RegExp('<article id="$lang"[^>]*>(.*?)</article>', dotAll: true).firstMatch(html)![1]!;
        final pageWords = words(article.replaceAll(RegExp(r'<[^>]+>'), ''));
        final assetWords = words(parseLegalBlocks(asset, lang).map((b) => b.text).join(' '));
        expect(assetWords, pageWords, reason: '$lang: run python3 -I site/export_legal_text.py');
      }
    });
  }
}
