// KLD-092: long stat labels ("Höchstgeschwindigkeit") never break in the
// middle of a word without a hyphen; they break at their soft hyphens with a
// "-" and shrink a little.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki/ui/games/hyphenated_label.dart';
import 'package:klunki/ui/games/quartett_card.dart';
import 'package:klunki_engine/klunki_engine.dart' show QuartettDeck;

import '../../l10n/l10n_test_utils.dart';

/// The bundled fonts, so the widths are those of the real app (the test
/// font draws every glyph as a square).
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
}

// The web font setup (Roboto + the bundled fallbacks): since KLD-093 only the
// web build uses it, and tests run as non-web, so without this Arabic, Persian
// and Chinese labels would be measured with the test font. Android/iOS use the
// system fonts, which tests cannot load; the bundled fonts are the closest
// stand-in with real glyph widths.
Widget _app(Widget home, Locale locale) => MaterialApp(
  theme: withAppFonts(KlunkiTheme.light, web: true),
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// [lines] put back together: a line ending in "-" (a soft hyphen) joins the
/// next one without a space.
String _rejoin(List<String> lines) {
  final b = StringBuffer();
  for (final (i, l) in lines.indexed) {
    if (i > 0 && !lines[i - 1].endsWith('-')) b.write(' ');
    b.write(l.endsWith('-') && i < lines.length - 1 ? l.substring(0, l.length - 1) : l);
  }
  return b.toString();
}

void main() {
  setUpAll(_loadFonts);
  // The test font (every glyph a 10 px square), for exact widths.
  const style = TextStyle(fontSize: 10, fontFamily: 'FlutterTest');

  group('layoutHyphenated', () {
    test('fits: one line, full size', () {
      final f = layoutHyphenated('Hub\u00ADraum', style, 200);
      expect(f.lines, ['Hubraum']);
      expect(f.scale, 1.0);
    });

    test('a long word breaks at a soft hyphen with "-", at full size first', () {
      // "Höchstgeschwindigkeit" = 21 glyphs = 210 px; 150 px fits "Höchstge-".
      final f = layoutHyphenated('Höchst\u00ADge\u00ADschwin\u00ADdig\u00ADkeit', style, 150);
      expect(f.scale, 1.0);
      expect(f.lines, ['Höchstge-', 'schwindigkeit']);
    });

    test('words wrap at spaces before any hyphenation', () {
      final f = layoutHyphenated('Nutz\u00ADlast (LEO)', style, 100);
      expect(f.lines, ['Nutzlast', '(LEO)']);
      expect(f.scale, 1.0);
    });

    test('shrinks modestly when two lines are not enough at full size', () {
      // 3 lines at 10 px in 70 px; at 9 px "Höchst-" (63) + ... two lines.
      final f = layoutHyphenated('Höchst\u00ADge\u00ADschwin\u00ADdig\u00ADkeit', style, 120);
      expect(f.lines, hasLength(2));
      expect(_rejoin(f.lines), 'Höchstgeschwindigkeit');
    });

    test('a word without soft hyphens shrinks until it fits, never split', () {
      final f = layoutHyphenated('Supercalifragilistic', style, 100);
      expect(f.lines, ['Supercalifragilistic']);
      expect(f.scale * 10 * 20, lessThanOrEqualTo(100));
    });
  });

  // Every stat label of every deck in every locale, with the real fonts, on
  // a full card at phone width (390 px: 366 px inside the screen padding)
  // and on a dense reveal card (179 px, half of it): each rendered line fits
  // its box (so Flutter never cuts a word), and the lines put back together
  // are the plain label. Chinese breaks between any characters anyway.
  for (final locale in AppLocalizations.supportedLocales) {
    for (final (width, dense) in [(366.0, false), (179.0, true)]) {
      testWidgets('${locale.languageCode} ${width.toInt()} px${dense ? ' dense' : ''}: no label breaks mid-word', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final l10n = lookupAppLocalizations(locale);
        for (final deck in QuartettDeck.all) {
          await tester.pumpWidget(
            _app(
              Scaffold(
                body: SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: width,
                      child: QuartettCard(card: deck.cards.first, dense: dense),
                    ),
                  ),
                ),
              ),
              locale,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          final labels = find.byType(HyphenatedLabel);
          expect(labels, findsNWidgets(deck.stats.length), reason: '${deck.id}: one label per stat');
          for (final s in deck.stats) {
            final plain = localizedStatLabel(l10n, s.id);
            final label = find.byWidgetPredicate(
              (w) => w is HyphenatedLabel && w.text.replaceAll(softHyphen, '') == plain,
            );
            expect(label, findsOneWidget, reason: '${deck.id} ${s.id}');
            final textFinder = find.descendant(of: label, matching: find.byType(Text));
            if (textFinder.evaluate().isEmpty) continue;
            final text = tester.widget<Text>(textFinder);
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: textFinder, matching: find.byType(RichText)),
            );
            final lines = text.data!.split('\n');
            if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(plain)) continue;
            expect(_rejoin(lines), plain, reason: '${deck.id} ${s.id}: lines $lines');
            expect(lines.length, lessThanOrEqualTo(3), reason: '${deck.id} ${s.id}: $lines');
            expect(
              paragraph.getMaxIntrinsicWidth(double.infinity),
              lessThanOrEqualTo(paragraph.size.width + 0.01),
              reason: '${locale.languageCode} ${deck.id} ${s.id}: "$lines" is wider than its box',
            );
            expect(paragraph.didExceedMaxLines, isFalse);
          }
        }
      });
    }
  }

  testWidgets('semantics: the plain label, no soft hyphens', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      localizedApp(
        const Scaffold(
          body: SizedBox(
            width: 90,
            child: HyphenatedLabel('Höchst\u00ADge\u00ADschwin\u00ADdig\u00ADkeit', style: style),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Höchstgeschwindigkeit'), findsOneWidget);
    final text = tester.widget<Text>(find.descendant(of: find.byType(HyphenatedLabel), matching: find.byType(Text)));
    expect(text.data, contains('-\n'));
    handle.dispose();
  });
}
