// KLD-102: "Über Klunki" in the menu: version, privacy policy (stored in the
// app, offline), Impressum, support, source code, licences.
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

/// Waits for the privacy text: the asset loads asynchronously (real I/O).
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
    for (final t in ['Datenschutz', 'Impressum', 'Support', 'Quellcode', 'Open-Source-Lizenzen']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('Klunki ist freie Software unter der GNU AGPL 3.0.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('about-impressum')));
    await tester.tap(find.byKey(const Key('about-support')));
    await tester.tap(find.byKey(const Key('about-source')));
    await tester.pump();
    expect(opened.map((u) => u.toString()), [
      'https://tronicum.github.io/klunki/impressum/',
      'https://tronicum.github.io/klunki/support/',
      'https://github.com/tronicum/klunki',
    ]);
  });

  testWidgets('English: links point to the English part', (tester) async {
    await _openAbout(tester, locale: const Locale('en'));
    expect(find.text('About Klunki'), findsWidgets);
    await tester.tap(find.byKey(const Key('about-impressum')));
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

  // The stored text must say what the web page says: rerun
  // `python3 -I site/export_privacy_text.py` after editing the page.
  test('assets/legal/privacy.json matches site/privacy/index.html', () {
    final values = (jsonDecode(File('../site/site.json').readAsStringSync()) as Map).cast<String, String>();
    final html = File('../site/privacy/index.html')
        .readAsStringSync()
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
        .replaceAllMapped(RegExp(r'\{\{([A-Z_]+)\}\}'), (m) => values[m[1]] ?? m[0]!);
    final asset = File(privacyAsset).readAsStringSync();
    List<String> words(String s) => s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    for (final lang in ['de', 'en']) {
      final article = RegExp('<article id="$lang"[^>]*>(.*?)</article>', dotAll: true).firstMatch(html)![1]!;
      final pageWords = words(article.replaceAll(RegExp(r'<[^>]+>'), ''));
      final assetWords = words(parsePrivacyBlocks(asset, lang).map((b) => b.text).join(' '));
      expect(assetWords, pageWords, reason: '$lang: run python3 -I site/export_privacy_text.py');
    }
  });
}
