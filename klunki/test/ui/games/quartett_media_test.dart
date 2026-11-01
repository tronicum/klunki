// KLD-082: Wikipedia links and Commons photos on the Quartett cards (rockets
// deck first, KLD-084 planes, trains, cars): data and licence checks, the photo on the card, the credit
// dialog, the Wikipedia button and the image credits screen. Also the
// number format fix (years and whole numbers never show a decimal; counts
// grouped, percent per locale) and the new stats (built, success rate).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki/ui/games/quartett_card.dart';
import 'package:klunki/ui/games/quartett_gallery.dart';
import 'package:klunki/ui/games/quartett_media.dart';
import 'package:klunki/ui/games/quartett_media_data.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_engine/klunki_engine.dart' as qe show Card;

import '../../l10n/glyph_coverage_test.dart' show cmapCodePoints, needsGlyph;
import '../../l10n/l10n_test_utils.dart';

/// Licences that allow use in the app with attribution (KLD-082): public
/// domain, CC0, CC BY / BY-SA (any version, ports, IGO), Free Art License,
/// OGL, Licence Ouverte (Etalab), GODL-India. Never NC / ND / GFDL-only.
final _allowedLicence = RegExp(
  r'^(Public domain|PD.*|CC0.*|CC BY(-SA)? \d(\.\d)?( [a-z]{2,3})?( igo)?|FAL.*|Free Art Licen[cs]e.*|OGL.*|'
  r'Open Government Licen[cs]e.*|Licence Ouverte.*|GODL-India|Attribution)$',
  caseSensitive: false,
);
final _forbidden = RegExp(r'\b(NC|ND)\b|non-?commercial|fair use|^GFDL', caseSensitive: false);

const _maxBytes = 40 * 1024;

Future<void> _phone(WidgetTester tester, [Size size = const Size(390, 844)]) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Records the links the app opens instead of launching them.
List<Uri> _fakeOpener({bool ok = true}) {
  final opened = <Uri>[];
  quartettLinkOpener = (uri) async {
    opened.add(uri);
    return ok;
  };
  addTearDown(resetQuartettLinkOpener);
  return opened;
}

/// Decks whose photos and links have been collected (KLD-082 rockets,
/// KLD-084 the others); every other deck keeps its pictograms.
const _mediaDecks = ['rockets', 'planes', 'trains', 'cars'];

void main() {
  for (final deckId in _mediaDecks) {
    _mediaDataTests(deckId);
  }

  group('media data (all decks)', () {
    test('the article follows the UI language, else English, else German', () {
      const both = QuartettCardMedia(
        wikiDe: 'https://de.wikipedia.org/wiki/A',
        wikiEn: 'https://en.wikipedia.org/wiki/A',
      );
      expect(both.wikipediaUrl('de'), contains('de.wikipedia'));
      expect(both.wikipediaUrl('en'), contains('en.wikipedia'));
      expect(both.wikipediaUrl('zh'), contains('en.wikipedia'));
      const deOnly = QuartettCardMedia(wikiDe: 'https://de.wikipedia.org/wiki/A');
      expect(deOnly.wikipediaUrl('fr'), contains('de.wikipedia'));
      const enOnly = QuartettCardMedia(wikiEn: 'https://en.wikipedia.org/wiki/A');
      expect(enOnly.wikipediaUrl('de'), contains('en.wikipedia'));
    });

    test('exactly the collected decks have media data and an asset folder', () {
      expect(quartettMediaData.keys.toSet(), _mediaDecks.toSet());
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final d in QuartettDeck.all) {
        expect(pubspec.contains('- assets/quartett/${d.id}/'), _mediaDecks.contains(d.id), reason: d.id);
      }
    });

    test('credit texts are drawable offline: every character in a bundled font (update_web_fonts.py subset)', () {
      final covered = <int>{
        for (final dir in ['Roboto', 'NotoSansArabic', 'NotoSansSC', 'NotoSansMath'])
          for (final f in Directory(
            'assets/fonts/$dir',
          ).listSync().whereType<File>().where((f) => f.path.endsWith('.ttf')))
            ...cmapCodePoints(f.readAsBytesSync()),
      };
      for (final deck in quartettMediaData.values) {
        for (final m in deck.values) {
          final img = m.image;
          if (img == null) continue;
          final missing = '${img.author}${img.license}'.runes.where(needsGlyph).where((c) => !covered.contains(c));
          expect(missing, isEmpty, reason: '${img.author}: run `python3 -I tool/update_web_fonts.py subset`');
        }
      }
    });

    test('decks without collected media yet have no entry (they keep the pictograms)', () {
      for (final d in QuartettDeck.all) {
        if (_mediaDecks.contains(d.id)) continue;
        expect(quartettMediaOf(d.cards.first), isNull, reason: d.id);
      }
    });
  });

  _widgetTests();
}

void _mediaDataTests(String deckId) {
  group('$deckId media data', () {
    final deck = QuartettDeck.all.firstWhere((d) => d.id == deckId);
    final media = quartettMediaData[deckId]!;

    test('every card has an entry; an image always comes with complete, allowed credits', () {
      expect(media.keys.toSet(), {for (final c in deck.cards) c.id});
      for (final MapEntry(key: id, value: m) in media.entries) {
        final img = m.image;
        if (img == null) continue;
        expect(img.author.trim(), isNotEmpty, reason: id);
        expect(img.license.trim(), isNotEmpty, reason: id);
        expect(img.license, matches(_allowedLicence), reason: '$id: ${img.license}');
        expect(img.license, isNot(matches(_forbidden)), reason: '$id: ${img.license}');
        expect(Uri.parse(img.licenseUrl).scheme, 'https', reason: id);
        expect(img.source, startsWith('https://commons.wikimedia.org/wiki/File:'), reason: id);
        expect(img.asset, 'assets/quartett/$deckId/$id.jpg');
        expect(img.shareAlike, img.license.contains('SA'), reason: id);
      }
    });

    test('the photo files exist, are JPEGs and stay under 40 KB; no stray files; ~1.1 MB per deck', () {
      final dir = Directory('assets/quartett/$deckId');
      final expected = {
        for (final m in media.values)
          if (m.image != null) m.image!.asset.split('/').last,
      };
      final files = {for (final f in dir.listSync().whereType<File>()) f.uri.pathSegments.last};
      expect(files, {...expected, 'credits.json'});
      for (final name in expected) {
        final bytes = File('${dir.path}/$name').readAsBytesSync();
        expect(bytes.length, lessThanOrEqualTo(_maxBytes), reason: name);
        expect(bytes.sublist(0, 3), [0xFF, 0xD8, 0xFF], reason: '$name is a JPEG');
      }
      final total = dir.listSync().whereType<File>().fold<int>(0, (sum, f) => sum + f.lengthSync());
      expect(total, lessThanOrEqualTo(1200 * 1024), reason: 'size budget of a deck (rockets: 1.09 MB)');
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/quartett/$deckId/'));
    });

    test('Wikipedia links are well-formed https article URLs; every card has one', () {
      for (final MapEntry(key: id, value: m) in media.entries) {
        expect(m.wikiDe ?? m.wikiEn, isNotNull, reason: id);
        for (final (lang, url) in [('de', m.wikiDe), ('en', m.wikiEn)]) {
          if (url == null) continue;
          final u = Uri.parse(url);
          expect(u.scheme, 'https', reason: url);
          expect(u.host, '$lang.wikipedia.org', reason: url);
          expect(u.path, startsWith('/wiki/'), reason: url);
          expect(u.path.length, greaterThan(6), reason: url);
          expect(u.hasQuery || u.hasFragment, isFalse, reason: url);
        }
      }
    });

    test('the generated Dart data matches credits.json (rerun tool/fetch_card_media.py)', () {
      final json = jsonDecode(File('assets/quartett/$deckId/credits.json').readAsStringSync()) as Map<String, dynamic>;
      expect(json['deck'], deckId);
      final cards = (json['cards'] as Map).cast<String, dynamic>();
      expect(cards.keys.toSet(), media.keys.toSet());
      for (final MapEntry(key: id, value: raw) in cards.entries) {
        final c = (raw as Map).cast<String, dynamic>();
        final wiki = (c['wikipedia'] as Map).cast<String, dynamic>();
        expect(media[id]!.wikiDe, wiki['de'], reason: id);
        expect(media[id]!.wikiEn, wiki['en'], reason: id);
        final img = (c['image'] as Map?)?.cast<String, dynamic>();
        final m = media[id]!.image;
        expect(m == null, img == null, reason: id);
        if (img == null || m == null) continue;
        expect(m.source, img['source'], reason: id);
        expect(m.author, img['author'], reason: id);
        expect(m.license, img['license'], reason: id);
        expect(m.licenseUrl, img['licenseUrl'], reason: id);
        expect(img['modified'], startsWith('resized'), reason: id);
        expect(img['file'], '$id.jpg', reason: id);
      }
    });

    testWidgets('the small $deckId cards in the gallery show their photos', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(localizedApp(QuartettDeckGalleryScreen(deck: deck)));
      for (final c in deck.cards.take(2)) {
        expect(
          find.byKey(Key('gallery-photo-${c.id}')),
          media[c.id]!.image == null ? findsNothing : findsOneWidget,
          reason: c.id,
        );
      }
      expect(find.byKey(const Key('gallery-image-credits')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

void _widgetTests() {
  group('card with photo', () {
    testWidgets('a rocket card shows its photo above the stats; the stat rows are unchanged', (tester) async {
      final card = QuartettDeck.rockets.cardById('A1')!;
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 340,
                child: QuartettCard(card: card, statKeyPrefix: 's-'),
              ),
            ),
          ),
        ),
      );
      final photo = find.byKey(const Key('quartett-photo-rockets-A1'));
      expect(photo, findsOneWidget);
      expect(find.byKey(const Key('quartett-pictogram-rockets')), findsOneWidget);
      // The photo sits between header and the first stat row.
      final firstStat = find.byKey(const Key('s-heightM'));
      expect(tester.getBottomLeft(photo).dy, lessThanOrEqualTo(tester.getTopLeft(firstStat).dy));
      for (final s in QuartettDeck.rockets.stats) {
        expect(find.byKey(Key('s-${s.id}')), findsOneWidget);
      }
      // In a trick (no showLinks) there is no credit button and no link.
      expect(find.byKey(const Key('quartett-photo-info')), findsNothing);
      expect(find.byKey(const Key('quartett-wikipedia')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a card without a photo keeps the drawn pictogram only', (tester) async {
      // Every deck card has a photo since KLD-084: a card id without media.
      final a1 = QuartettDeck.cars.cardById('A1')!;
      final card = qe.Card(id: 'Z9', name: 'Ohne Foto', set: a1.set, deck: a1.deck, stats: a1.stats);
      expect(quartettMediaOf(card), isNull);
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 340, child: QuartettCard(card: card, showLinks: true)),
            ),
          ),
        ),
      );
      expect(find.byType(QuartettCardPhoto), findsNothing);
      expect(find.byKey(const Key('quartett-pictogram-cars')), findsOneWidget);
      expect(find.byKey(const Key('quartett-photo-info')), findsNothing);
    });

    testWidgets('a missing asset falls back silently (no exception)', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          const Scaffold(
            body: QuartettCardPhoto(
              credit: QuartettImageCredit(
                asset: 'assets/quartett/rockets/missing.jpg',
                source: 'https://commons.wikimedia.org/wiki/File:X.jpg',
                author: 'X',
                license: 'CC0',
                licenseUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
              ),
              height: 100,
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the small rocket cards in the gallery show their photos', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(localizedApp(QuartettDeckGalleryScreen(deck: QuartettDeck.rockets)));
      expect(find.byKey(const Key('gallery-photo-A1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('credit and Wikipedia links', () {
    testWidgets('the full card: ⓘ shows "Foto: <Autor>, <Lizenz>" with licence and source links', (tester) async {
      await _phone(tester);
      final opened = _fakeOpener();
      final d = QuartettDeck.rockets;
      final img = quartettMediaData['rockets']!['B3']!.image!;
      await tester.pumpWidget(
        localizedApp(QuartettCardPagerScreen(deck: d, initialIndex: d.cards.indexOf(d.cardById('B3')!))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quartett-photo-info')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quartett-photo-credit')), findsOneWidget);
      expect(find.text('Foto: ${img.author}, ${img.license}'), findsOneWidget);
      expect(find.textContaining('Für die App verkleinert.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('quartett-photo-license')));
      await tester.tap(find.byKey(const Key('quartett-photo-source')));
      await tester.pump();
      expect(opened, [Uri.parse(img.licenseUrl), Uri.parse(img.source)]);
      await tester.tap(find.byKey(const Key('quartett-photo-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quartett-photo-credit')), findsNothing);
    });

    testWidgets('share-alike photos say that the resized copy keeps the licence', (tester) async {
      await _phone(tester);
      final d = QuartettDeck.rockets;
      final sa = d.cards.firstWhere((c) => quartettMediaOf(c)?.image?.shareAlike ?? false);
      await tester.pumpWidget(localizedApp(QuartettCardPagerScreen(deck: d, initialIndex: d.cards.indexOf(sa))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quartett-photo-info')));
      await tester.pumpAndSettle();
      expect(find.textContaining('derselben Lizenz'), findsOneWidget);
    });

    for (final (locale, host) in [
      (const Locale('de'), 'de.wikipedia.org'),
      (const Locale('en'), 'en.wikipedia.org'),
      (const Locale('fr'), 'en.wikipedia.org'),
    ]) {
      testWidgets('"Auf Wikipedia lesen" opens the ${locale.languageCode} UI article on $host', (tester) async {
        await _phone(tester);
        final opened = _fakeOpener();
        final d = QuartettDeck.rockets;
        await tester.pumpWidget(localizedApp(QuartettCardPagerScreen(deck: d), locale: locale));
        await tester.pumpAndSettle();
        final button = find.byKey(const Key('quartett-wikipedia'));
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: button, matching: find.text(lookupAppLocalizations(locale).quartettWikipediaRead)),
          findsOneWidget,
        );
        await tester.tap(button);
        await tester.pump();
        expect(opened, hasLength(1));
        expect(opened.single.host, host);
        expect(opened.single.toString(), quartettMediaData['rockets']!['A1']!.wikipediaUrl(locale.languageCode));
      });
    }

    testWidgets('a link that cannot be opened shows a snack bar', (tester) async {
      await _phone(tester);
      _fakeOpener(ok: false);
      await tester.pumpWidget(localizedApp(QuartettCardPagerScreen(deck: QuartettDeck.rockets)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('quartett-wikipedia')));
      await tester.tap(find.byKey(const Key('quartett-wikipedia')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Der Link konnte nicht geöffnet werden.'), findsOneWidget);
    });

    testWidgets('Bildnachweise from the gallery lists every photo of every deck with its credit', (tester) async {
      await _phone(tester);
      _fakeOpener();
      await tester.pumpWidget(localizedApp(const QuartettGalleryScreen()));
      await tester.tap(find.byKey(const Key('gallery-image-credits')));
      await tester.pumpAndSettle();
      expect(find.text('Bildnachweise'), findsOneWidget);
      expect(find.byKey(const Key('quartett-image-credits')), findsOneWidget);
      for (final deckId in _mediaDecks) {
        final deck = QuartettDeck.all.firstWhere((d) => d.id == deckId);
        final media = quartettMediaData[deckId]!;
        for (final card in deck.cards) {
          final img = media[card.id]!.image;
          if (img == null) continue;
          final tile = find.byKey(Key('quartett-credit-$deckId-${card.id}'));
          expect(tile, findsOneWidget, reason: '$deckId ${card.id}');
          expect(
            find.descendant(of: tile, matching: find.text('Foto: ${img.author}, ${img.license}')),
            findsOneWidget,
            reason: '$deckId ${card.id}',
          );
        }
      }
      // A tile opens the same credit dialog.
      await tester.ensureVisible(find.byKey(const Key('quartett-credit-rockets-H4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quartett-credit-rockets-H4')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quartett-photo-credit')), findsOneWidget);
    });

    testWidgets('every deck gallery has a Bildnachweise button that lists only that deck', (tester) async {
      await _phone(tester);
      for (final deck in QuartettDeck.all) {
        await tester.pumpWidget(localizedApp(QuartettDeckGalleryScreen(deck: deck)));
        expect(find.byKey(const Key('gallery-image-credits')), findsOneWidget, reason: deck.id);
        await tester.tap(find.byKey(const Key('gallery-image-credits')));
        await tester.pumpAndSettle();
        expect(find.byKey(Key('quartett-credit-${deck.id}-A1')), findsOneWidget, reason: deck.id);
        for (final other in QuartettDeck.all.where((d) => d != deck)) {
          expect(find.byKey(Key('quartett-credit-${other.id}-A1')), findsNothing, reason: '${deck.id}/${other.id}');
        }
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
      }
    });
  });

  group('number format (years, counts, percent, decimals)', () {
    final locales = [for (final l in AppLocalizations.supportedLocales) l.languageCode];
    // A year stat as a future deck would declare it (no deck has one now).
    const year = QuartettStat(id: 'year', label: 'Jahr', unit: '', isYear: true);

    test('a year is bare digits in every locale, also as a double (the web runtime)', () {
      for (final l in locales) {
        expect(formatQuartettValue(year, 1999, locale: l), '1999', reason: l);
        expect(formatQuartettValue(year, 1999.0, locale: l), '1999', reason: l);
        expect(
          formatQuartettValue(year, 1999.0, locale: l, unit: 'x'),
          '1999',
          reason: 'years have no unit',
        );
      }
    });

    test('whole numbers have no decimals; decimals, counts and percent follow the stat and the locale', () {
      final flights = QuartettDeck.rockets.statById('flights')!;
      final thrust = QuartettDeck.rockets.statById('thrustKn')!;
      final height = QuartettDeck.rockets.statById('heightM')!;
      final success = QuartettDeck.rockets.statById('successPct')!;
      final built = QuartettDeck.planes.statById('built')!;
      final sec = QuartettDeck.cars.statById('sec0to100')!;
      expect(formatQuartettValue(flights, 550.0), '550');
      expect(formatQuartettValue(thrust, 35100.0), '35100 kN');
      expect(formatQuartettValue(height, 110.6), '110,6 m');
      expect(formatQuartettValue(height, 70.0), '70 m');
      expect(formatQuartettValue(sec, 7.0), '7,0 s');
      expect(formatQuartettValue(sec, 7.0, locale: 'en'), '7.0 s');
      expect(formatQuartettValue(height, 110.6, locale: 'fa'), '110.6 m');
      expect(formatQuartettValue(height, 110.6, locale: 'ar'), '110.6 m');
      expect(formatQuartettValue(built, 45000.0), '45.000 Stk.');
      expect(formatQuartettValue(built, 45000, locale: 'en', unit: 'units'), '45,000 units');
      expect(formatQuartettValue(built, 45000, locale: 'fa'), '45,000 Stk.');
      expect(formatQuartettValue(built, 1.0), '1 Stk.');
      expect(formatQuartettValue(success, 100.0), matches(RegExp(r'^100\s%$')));
      expect(formatQuartettValue(success, 92.3), matches(RegExp(r'^92,3\s%$')));
      expect(formatQuartettValue(success, 99.0, locale: 'en'), '99%');
      expect(formatQuartettValue(success, 92.3, locale: 'en'), '92.3%');
      for (final l in locales) {
        expect(formatQuartettValue(success, 92.3, locale: l), contains(RegExp(r'92[.,]3')), reason: l);
      }
    });

    test('every formatted value of every deck in every locale is drawable offline (bundled fonts)', () {
      final covered = <int>{
        for (final dir in ['Roboto', 'NotoSansArabic', 'NotoSansSC', 'NotoSansMath'])
          for (final f in Directory(
            'assets/fonts/$dir',
          ).listSync().whereType<File>().where((f) => f.path.endsWith('.ttf')))
            ...cmapCodePoints(f.readAsBytesSync()),
      };
      for (final l in locales) {
        final l10n = lookupAppLocalizations(Locale(l));
        for (final deck in QuartettDeck.all) {
          for (final card in deck.cards) {
            for (final s in deck.stats) {
              final text = formatQuartettValue(s, card.stats[s.id]!, locale: l, unit: localizedStatUnit(l10n, s.id));
              final missing = text.runes.where(needsGlyph).where((c) => !covered.contains(c)).toList();
              expect(
                missing,
                isEmpty,
                reason: '$l ${deck.id} ${card.id} ${s.id}: "$text" U+${missing.map((c) => c.toRadixString(16))}',
              );
            }
          }
        }
      }
    });

    for (final locale in [const Locale('de'), const Locale('en'), const Locale('fa')]) {
      testWidgets('every card of every deck (${locale.languageCode}): no ",0" on whole numbers, Western digits', (
        tester,
      ) async {
        final l10n = lookupAppLocalizations(locale);
        for (final deck in QuartettDeck.all) {
          for (final card in deck.cards) {
            await tester.pumpWidget(
              localizedApp(
                locale: locale,
                Scaffold(
                  body: SingleChildScrollView(
                    child: SizedBox(
                      width: 360,
                      child: QuartettCard(card: card, statKeyPrefix: 's-'),
                    ),
                  ),
                ),
              ),
            );
            for (final s in deck.stats) {
              final texts = tester
                  .widgetList<Text>(find.descendant(of: find.byKey(Key('s-${s.id}')), matching: find.byType(Text)))
                  .map((t) => t.semanticsLabel ?? t.data ?? '')
                  .toList();
              final value = texts.firstWhere((t) => t != localizedStatLabel(l10n, s.id));
              final where = '${deck.id} ${card.id} ${s.id}: "$value"';
              expect(value, matches(RegExp(r'^[0-9]')), reason: where);
              expect(value, isNot(contains(RegExp(r'[٠-٩۰-۹]'))), reason: where);
              final v = card.stats[s.id]!;
              // Grouped counts ("4.000 Stk.") have a separator but no decimals (decimals: 0).
              if (!s.grouped && (s.decimals == 0 || (v == v.roundToDouble() && !s.fixedDecimals))) {
                expect(value, isNot(contains(RegExp(r'[.,]0+(\s|%|$)'))), reason: where);
              }
              if (s.isYear) expect(value, matches(RegExp(r'^[0-9]{4}$')), reason: where);
            }
          }
        }
      });
    }
  });
}
