// KLD-069: themed Quartett decks in the app: the deck picker before a
// hot-seat game, a card of every deck, the view-only card gallery and the
// deck choice when hosting over a relay.
import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/profile/quartett_deck_settings.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki/ui/games/quartett_card.dart';
import 'package:klunki/ui/games/quartett_deck_picker.dart';
import 'package:klunki/ui/games/quartett_gallery.dart';
import 'package:klunki/ui/games/quartett_pictograms.dart';
import 'package:klunki/ui/games/quartett_trumpf_screen.dart';
import 'package:klunki/ui/pairing/relay_host_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Future<void> _phone(WidgetTester tester, [Size size = const Size(390, 844)]) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// A button that opens the hot-seat Quartett flow like the menu does.
Widget _launcher(QuartettDeckSettings settings, {String gameId = 'quartett-trumpf'}) => localizedApp(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('start'),
              onPressed: () => openGameFromMenu(context, gameId, deckSettings: settings),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );

void main() {
  group('deck picker', () {
    testWidgets('lists every deck with name and card count; the chosen deck is played and remembered',
        (tester) async {
      await _phone(tester);
      final settings = QuartettDeckSettings.memory();
      await tester.pumpWidget(_launcher(settings));
      await tester.tap(find.byKey(const Key('start')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quartett-deck-picker')), findsOneWidget);
      expect(find.text('Kartendeck wählen'), findsOneWidget);
      for (final (id, name) in [
        ('cars', 'Autos'), ('trains', 'Züge'), ('rockets', 'Raketen'), ('planes', 'Flugzeuge'), ('animals', 'Tiere'),
      ]) {
        final tile = find.byKey(Key('quartett-deck-$id'));
        expect(tile, findsOneWidget);
        expect(find.descendant(of: tile, matching: find.text(name)), findsOneWidget);
        expect(find.descendant(of: tile, matching: find.text('32 Karten · 8 Sets à 4 Karten')), findsOneWidget);
        expect(find.descendant(of: tile, matching: find.byType(QuartettDeckPreview)), findsOneWidget);
      }
      // The car deck is preselected.
      expect(tester.getSemantics(find.byKey(const Key('quartett-deck-cars'))), isNotNull);
      expect(
          find.descendant(of: find.byKey(const Key('quartett-deck-cars')), matching: find.byIcon(Icons.radio_button_checked)),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('quartett-deck-trains')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('quartett-deck-play')));
      await tester.pumpAndSettle();

      expect(settings.value, 'trains');
      expect(find.byType(QuartettTrumpfScreen), findsOneWidget);
      final c = controllerOf(tester);
      expect(c.config.deck, 'trains');
      final game = c.game as QuartettGame;
      expect(game.deck.id, 'trains');
      expect(find.text('Quartett (Trumpf) · Züge'), findsOneWidget);
      expect(find.text(game.topCard(Player.a)!.name), findsOneWidget);
      expect(findLabel(localizedStatLabel(deL10n, 'tractiveKn')), findsOneWidget);

      // "Nochmal" keeps the deck.
      c.restart(seed: 99);
      expect(c.config.deck, 'trains');
      expect((c.game as QuartettGame).deck.id, 'trains');

      // Next time the picker preselects trains.
      Navigator.of(tester.element(find.byType(QuartettTrumpfScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start')));
      await tester.pumpAndSettle();
      expect(
          find.descendant(
              of: find.byKey(const Key('quartett-deck-trains')), matching: find.byIcon(Icons.radio_button_checked)),
          findsOneWidget);
    });

    testWidgets('dismissing the picker starts no game', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_launcher(QuartettDeckSettings.memory(), gameId: 'quartett-sets'));
      await tester.tap(find.byKey(const Key('start')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // barrier
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quartett-deck-picker')), findsNothing);
      expect(find.byType(QuartettTrumpfScreen), findsNothing);
      expect(find.byKey(const Key('start')), findsOneWidget);
    });

    testWidgets('"Karten ansehen" in the picker opens the gallery of the selected deck', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_launcher(QuartettDeckSettings.memory('rockets')));
      await tester.tap(find.byKey(const Key('start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quartett-deck-gallery')));
      await tester.pumpAndSettle();
      expect(find.byType(QuartettDeckGalleryScreen), findsOneWidget);
      expect(find.text('Raketen'), findsOneWidget);
      expect(find.text('A  Mondraketen'), findsOneWidget);
    });

    test('settings persist through shared_preferences and ignore unknown ids', () async {
      SharedPreferences.setMockInitialValues({QuartettDeckSettings.prefsKey: 'planes'});
      final p = await SharedPreferences.getInstance();
      final s = QuartettDeckSettings.shared();
      await Future<void>.delayed(Duration.zero);
      expect(s.value, 'planes');
      expect(s.deck, same(QuartettDeck.planes));
      await s.set('trains');
      expect(p.getString(QuartettDeckSettings.prefsKey), 'trains');
      expect(() => s.set('boats'), throwsArgumentError);
    });
  });

  group('set pictograms (KLD-128)', () {
    QuartettPictogram painterOf(WidgetTester tester, String deck) =>
        tester.widget<CustomPaint>(find.byKey(Key('quartett-pictogram-$deck'))).painter! as QuartettPictogram;

    testWidgets('animal cards show their set pictogram at every card size, LTR and RTL; other decks keep theirs',
        (tester) async {
      for (final locale in [const Locale('de'), const Locale('ar')]) {
        for (final (compact, dense, width) in [(false, false, 340.0), (false, true, 180.0), (true, false, 150.0)]) {
          for (final deck in QuartettDeck.all) {
            for (final set in deck.setNames.keys) {
              final card = deck.cardsOf(set).first;
              await tester.pumpWidget(localizedApp(
                locale: locale,
                Scaffold(
                  body: SingleChildScrollView(
                    child: SizedBox(width: width, child: QuartettCard(card: card, compact: compact, dense: dense)),
                  ),
                ),
              ));
              final p = painterOf(tester, deck.id);
              expect(p.set, set);
              expect(p.showsSet, deck.id == 'animals', reason: '${deck.id} $set');
              expect(tester.takeException(), isNull, reason: '${locale.languageCode} ${deck.id} $set $width');
            }
          }
        }
      }
    });

    testWidgets('the card back and the deck picker keep the deck pictogram (the elephant)', (tester) async {
      await tester.pumpWidget(localizedApp(
        Scaffold(body: Center(child: QuartettDeckPreview(deck: QuartettDeck.animals))),
      ));
      final preview = tester.widget<CustomPaint>(
          find.descendant(of: find.byType(QuartettDeckPreview), matching: find.byType(CustomPaint)).last);
      expect((preview.painter! as QuartettPictogram).showsSet, isFalse);
      expect(const QuartettPictogram('animals', color: Colors.white, detail: Colors.black).showsSet, isFalse);
      expect(const QuartettPictogram('cars', set: 'A', color: Colors.white, detail: Colors.black).showsSet, isFalse);
      expect(QuartettPictogram.setPictogramDecks, {'animals'});
    });

    test('every set pictogram paints without errors', () {
      for (final set in 'ABCDEFGH'.split('')) {
        final recorder = PictureRecorder();
        QuartettPictogram('animals', set: set, color: Colors.white, detail: Colors.black)
            .paint(Canvas(recorder), const Size(100, 60));
        recorder.endRecording().dispose();
      }
    });
  });

  group('a card of every deck', () {
    for (final deck in QuartettDeck.all) {
      testWidgets('${deck.id}: name, localized set name and stats, pictogram, in de and en', (tester) async {
        final card = deck.cardById('C2')!;
        for (final l10n in [deL10n, enL10n]) {
          await tester.pumpWidget(localizedApp(
            locale: Locale(l10n.localeName),
            Scaffold(body: SingleChildScrollView(child: SizedBox(width: 340, child: QuartettCard(card: card)))),
          ));
          expect(find.text(localizedCardName(l10n, card)), findsOneWidget);
          expect(find.text(localizedSetName(l10n, 'C', deck.id)), findsOneWidget);
          expect(find.byKey(Key('quartett-pictogram-${deck.id}')), findsOneWidget);
          for (final s in deck.stats) {
            expect(findLabel(localizedStatLabel(l10n, s.id)), findsOneWidget, reason: s.id);
            expect(
              find.text(formatQuartettValue(s, card.stats[s.id]!,
                  locale: l10n.localeName, unit: localizedStatUnit(l10n, s.id))),
              findsWidgets,
              reason: s.id,
            );
          }
          expect(tester.takeException(), isNull);
        }
      });
    }

    test('set names and stat labels are translated per deck (no fallback, distinct within a deck)', () {
      for (final l10n in [deL10n, enL10n]) {
        for (final deck in QuartettDeck.all) {
          final sets = {for (final s in deck.setNames.keys) localizedSetName(l10n, s, deck.id)};
          expect(sets, hasLength(8), reason: deck.id);
          final labels = {for (final s in deck.stats) localizedStatLabel(l10n, s.id)};
          expect(labels, hasLength(deck.stats.length), reason: deck.id);
          expect(localizedDeckName(l10n, deck.id), isNot(deck.id));
        }
      }
      for (final deck in QuartettDeck.all) {
        expect(localizedDeckName(deL10n, deck.id), deck.name);
        for (final e in deck.setNames.entries) {
          expect(localizedSetName(deL10n, e.key, deck.id), e.value, reason: '${deck.id} ${e.key}');
        }
        for (final s in deck.stats) {
          expect(localizedStatLabel(deL10n, s.id), s.label, reason: s.id);
          expect(localizedStatUnit(deL10n, s.id), s.unit, reason: s.id);
        }
      }
      expect(localizedSetName(enL10n, 'G', 'trains'), 'Steam legends');
      expect(localizedStatLabel(enL10n, 'thrustKn'), 'Liftoff thrust');
    });

    group('animals (KLD-128): translated card names', () {
      final deck = QuartettDeck.animals;
      final locales = [for (final c in ['de', 'en', 'fr', 'es', 'zh', 'ar', 'fa']) lookupAppLocalizations(Locale(c))];

      test('every card has a name in every locale, distinct within the deck; German = the engine name', () {
        for (final l10n in locales) {
          final names = {for (final c in deck.cards) localizedCardName(l10n, c)};
          expect(names, hasLength(32), reason: l10n.localeName);
          expect(names.every((n) => n.trim().isNotEmpty && !n.contains(softHyphen)), isTrue);
        }
        for (final c in deck.cards) {
          expect(localizedCardName(deL10n, c), c.name, reason: c.id);
        }
        expect(localizedCardName(enL10n, deck.cardById('H4')!), 'Black mamba');
        expect(localizedCardName(lookupAppLocalizations(const Locale('ar')), deck.cardById('D2')!), 'زرافة');
        // The vehicle decks keep their real names in every locale.
        final porsche = QuartettDeck.cars.cardById('A1')!;
        expect(localizedCardName(enL10n, porsche), porsche.name);
      });

      test('units and labels: "Jahre" / "Tage" translated, weight wins high under its own id', () {
        expect(localizedStatUnit(enL10n, 'lifeYears'), 'years');
        expect(localizedStatUnit(enL10n, 'gestationD'), 'days');
        expect(localizedStatLabel(deL10n, 'gestationD'), 'Tragzeit / Brutzeit');
        expect(localizedStatLabelHyphenated(deL10n, 'gestationD'), 'Trag${softHyphen}zeit / Brut${softHyphen}zeit');
        expect(localizedStatLabel(enL10n, 'weightKg'), localizedStatLabel(enL10n, 'kg'));
        final kmh = deck.statById('kmh')!;
        expect(formatQuartettValue(kmh, 0.3, locale: 'de'), '0,3 km/h');
        expect(formatQuartettValue(kmh, 104, locale: 'de'), '104 km/h');
        expect(formatQuartettValue(deck.statById('weightKg')!, 136000, locale: 'de'), '136.000 kg');
      });

      test('display names never reach the game: the fingerprint and the views use the engine data', () {
        final before = fingerprintOf(const GameConfig('quartett-trumpf', deck: 'animals'));
        // The fingerprint hashes the engine's (German) names; nothing in it
        // depends on the app's locale.
        expect(deckGameplayData(deck).toString(), contains('Schwarze Mamba'));
        expect(deckGameplayData(deck).toString(), isNot(contains('Black mamba')));
        expect(fingerprintOf(const GameConfig('quartett-trumpf', deck: 'animals')), before);
      });
    });

    test('launch counts have no unit; values use Western digits', () {
      final flights = QuartettDeck.rockets.statById('flights')!;
      expect(formatQuartettValue(flights, 786, locale: 'fa', unit: ''), '786');
      final len = QuartettDeck.trains.statById('lengthM')!;
      expect(formatQuartettValue(len, 200.8, locale: 'de'), '200,8 m');
      expect(formatQuartettValue(len, 200.8, locale: 'fa'), '200.8 m');
    });

    testWidgets('an electric car shows "–" for Hubraum, not "0 cm³"; a combustion car keeps its cm³', (tester) async {
      final cars = QuartettDeck.cars;
      final ccm = cars.statById('ccm')!;
      final electric = cars.cardById('G1')!, combustion = cars.cardById('H1')!;
      expect(electric.stats['ccm'], 0);
      for (final l10n in [deL10n, enL10n, lookupAppLocalizations(const Locale('fr'))]) {
        for (final (card, expected) in [(electric, '–'), (combustion, null)]) {
          await tester.pumpWidget(localizedApp(
            locale: Locale(l10n.localeName),
            Scaffold(body: SingleChildScrollView(child: SizedBox(width: 340, child: QuartettCard(card: card)))),
          ));
          final value = formatQuartettValue(ccm, card.stats['ccm']!,
              locale: l10n.localeName, unit: localizedStatUnit(l10n, 'ccm'));
          if (expected != null) expect(value, expected);
          expect(find.text(value), findsOneWidget, reason: '${l10n.localeName} ${card.id}');
          expect(find.textContaining(RegExp(r'^0\s')), findsNothing, reason: '${l10n.localeName} ${card.id}');
        }
      }
      expect(formatQuartettValue(ccm, 1998), '1.998 cm³');
      expect(formatQuartettValue(ccm, 1998, locale: 'en', unit: localizedStatUnit(enL10n, 'ccm')),
          '1,998 ${localizedStatUnit(enL10n, 'ccm')}');
      // Display only: the value stays 0 and still loses on Hubraum.
      expect(ccm.beats(1998, 0), isTrue);
      // Only the Hubraum dashes its zero; any other 0 still prints as a number.
      expect(formatQuartettValue(QuartettDeck.rockets.statById('flights')!, 0, unit: ''), '0');
    });
  });

  group('card gallery', () {
    testWidgets('only the Quartett tiles have "Karten", next to "Regeln", and no entry of its own', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(klunkiApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('menu-quartett-gallery')), findsNothing);
      for (final spec in appGameSpecs) {
        expect(find.byKey(Key('menu-${spec.id}-cards')), spec.usesDeck ? findsOneWidget : findsNothing, reason: spec.id);
      }
      for (final id in ['quartett-trumpf', 'quartett-sets']) {
        final cards = find.byKey(Key('menu-$id-cards'));
        await tester.ensureVisible(cards);
        await tester.pumpAndSettle();
        expect(find.descendant(of: cards, matching: find.text('Karten')), findsOneWidget);
        // In the lower corner of the picture box (end side), whole on the
        // tile, above the title; "Regeln" stays at the foot.
        final link = tester.getRect(cards);
        final tile = tester.getRect(find.byKey(Key('menu-$id-tile')));
        expect(link.right <= tile.right && link.left >= tile.left && link.top >= tile.top, isTrue,
            reason: '$id: $link in $tile');
        expect(link.center.dx, greaterThan(tile.center.dx), reason: 'end side (ltr)');
        final name = id == 'quartett-trumpf' ? 'Quartett (Trumpf)' : 'Quartett (Sets)';
        final title = tester.getRect(find.descendant(of: find.byKey(Key('menu-$id-tile')), matching: find.text(name)));
        expect(link.bottom, lessThanOrEqualTo(title.top + 1), reason: '$id: $link above $title');
        expect(tester.getRect(find.byKey(Key('menu-$id-rules'))).top, greaterThan(link.bottom));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('menu → decks → sets with 4 cards each → full card → swipe and step', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(klunkiApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('menu-quartett-trumpf-cards')));
      await tester.tap(find.byKey(const Key('menu-quartett-trumpf-cards')));
      await tester.pumpAndSettle();

      expect(find.text('Quartett-Karten'), findsOneWidget);
      for (final deck in QuartettDeck.all) {
        final tile = find.byKey(Key('gallery-deck-${deck.id}'));
        expect(tile, findsOneWidget);
        expect(find.descendant(of: tile, matching: find.text(localizedDeckName(deL10n, deck.id))), findsOneWidget);
        expect(find.descendant(of: tile, matching: find.text('32 Karten · 8 Sets à 4 Karten')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('gallery-deck-trains')));
      await tester.pumpAndSettle();

      expect(find.byType(QuartettDeckGalleryScreen), findsOneWidget);
      expect(find.byKey(const Key('gallery-sets')), findsOneWidget);
      // Every set as a section with its four cards.
      final deck = QuartettDeck.trains;
      for (final set in deck.setNames.keys) {
        final header = find.byKey(Key('gallery-set-$set'));
        await tester.ensureVisible(header);
        expect(find.text('$set  ${deck.setNames[set]}'), findsOneWidget);
        for (final card in deck.cardsOf(set)) {
          final mini = find.byKey(Key('gallery-card-${card.id}'));
          await tester.ensureVisible(mini);
          expect(find.descendant(of: mini, matching: find.text(card.name)), findsOneWidget);
        }
      }
      // Screen readers get one label per card.
      final b3 = find.byKey(const Key('gallery-card-B3'));
      await tester.ensureVisible(b3);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(b3).label, 'Karte B3: Shinkansen N700S, Set Shinkansen');

      await tester.tap(b3);
      await tester.pumpAndSettle();
      expect(find.byType(QuartettCardPagerScreen), findsOneWidget);
      expect(find.text('Züge · Karte 7 von 32'), findsOneWidget);
      expect(find.byKey(const Key('gallery-full-B3')), findsOneWidget);
      for (final s in deck.stats) {
        expect(find.byKey(Key('quartett-pictogram-trains')), findsWidgets);
        expect(findLabel(localizedStatLabel(deL10n, s.id)), findsOneWidget);
      }
      expect(find.text('höher gewinnt'), findsOneWidget);
      expect(find.text('niedriger gewinnt'), findsOneWidget);

      // Swipe to the next card, then step back and forth with the buttons.
      await tester.fling(find.byKey(const Key('gallery-pager')), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Züge · Karte 8 von 32'), findsOneWidget);
      expect(find.byKey(const Key('gallery-full-B4')), findsOneWidget);
      await tester.tap(find.byKey(const Key('gallery-previous')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gallery-previous')));
      await tester.pumpAndSettle();
      expect(find.text('Züge · Karte 6 von 32'), findsOneWidget);
      await tester.tap(find.byKey(const Key('gallery-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gallery-full-B3')), findsOneWidget);
    });

    testWidgets('the first and last card disable the step buttons', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(localizedApp(QuartettCardPagerScreen(deck: QuartettDeck.planes, initialIndex: 31)));
      await tester.pumpAndSettle();
      expect(find.text('Flugzeuge · Karte 32 von 32'), findsOneWidget);
      expect(tester.widget<IconButton>(find.byKey(const Key('gallery-next'))).onPressed, isNull);
      await tester.pumpWidget(localizedApp(QuartettCardPagerScreen(key: UniqueKey(), deck: QuartettDeck.planes)));
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(find.byKey(const Key('gallery-previous'))).onPressed, isNull);
    });

    testWidgets('Top 5 by a stat, best first; "lower wins" stats rank ascending; a row opens the card',
        (tester) async {
      await _phone(tester);
      await tester.pumpWidget(localizedApp(QuartettDeckGalleryScreen(deck: QuartettDeck.trains)));
      await tester.tap(find.byKey(const Key('gallery-top-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gallery-top-kmh')));
      await tester.pumpAndSettle();
      expect(find.text('Top 5: Höchstgeschwindigkeit'), findsOneWidget);
      final rows = tester.widgetList<ListTile>(find.descendant(of: find.byKey(const Key('gallery-top')), matching: find.byType(ListTile)));
      expect([for (final r in rows) (r.key! as ValueKey<String>).value],
          ['gallery-top-C4', 'gallery-top-E3', 'gallery-top-D3', 'gallery-top-F4', 'gallery-top-D2']);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gallery-top-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gallery-top-massT')));
      await tester.pumpAndSettle();
      final first = tester.widgetList<ListTile>(find.byType(ListTile)).first;
      expect(first.key, const Key('gallery-top-F3'), reason: 'the lightest (Re 460, 83 t) wins');
      await tester.tap(find.byKey(const Key('gallery-top-F3')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gallery-full-F3')), findsOneWidget);
    });

    for (final (code, size, brightness, deckId) in [
      ('ar', const Size(360, 640), Brightness.light, 'planes'),
      ('zh', const Size(390, 844), Brightness.dark, 'planes'),
      ('en', const Size(1180, 820), Brightness.light, 'planes'),
      // KLD-128: translated animal names, the longest labels in fr and fa.
      ('ar', const Size(360, 640), Brightness.light, 'animals'),
      ('fr', const Size(320, 640), Brightness.light, 'animals'),
      ('fa', const Size(360, 640), Brightness.dark, 'animals'),
    ]) {
      testWidgets('$code ${size.width.toInt()} $deckId: gallery, sets and full card render without overflow',
          (tester) async {
        await _phone(tester, size);
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(localizedApp(const QuartettGalleryScreen(), locale: Locale(code)));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.byKey(Key('gallery-deck-$deckId')), 200,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('gallery-deck-$deckId')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('gallery-card-A1')));
        await tester.pumpAndSettle();
        // RTL: swiping towards the reading direction's end goes forward.
        await tester.fling(find.byKey(const Key('gallery-pager')), Offset(code == 'ar' || code == 'fa' ? 300 : -300, 0), 1000);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('gallery-full-A2')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('network host', () {
    testWidgets('relay host: the deck choice shows for Quartett only and goes into the config', (tester) async {
      await _phone(tester, const Size(800, 1400));
      final configs = <GameConfig>[];
      final settings = QuartettDeckSettings.memory('planes');
      await tester.pumpWidget(localizedApp(RelayHostScreen(
        hostTransport: (config, relay, {required name}) async {
          configs.add(config);
          throw StateError('no relay in this test');
        },
        defaultRelay: Uri.parse('ws://127.0.0.1:9/relay'),
        deckSettings: settings,
        seed: () => 7,
        deviceName: () => 'Ada',
      )));
      await tester.pump();
      expect(find.byKey(const Key('relay-deck')), findsNothing, reason: 'Four in a Row has no deck');

      await tester.tap(find.byKey(const Key('relay-game-quartett-trumpf')));
      await tester.pump();
      expect(find.byKey(const Key('relay-deck')), findsOneWidget);
      expect(find.text('Kartendeck'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('relay-deck-planes')), matching: find.byIcon(Icons.radio_button_checked)),
          findsOneWidget,
          reason: 'the remembered deck');
      await tester.tap(find.byKey(const Key('relay-deck-rockets')));
      await tester.pump();
      expect(settings.value, 'rockets');
      await tester.ensureVisible(find.byKey(const Key('relay-host-start')));
      await tester.tap(find.byKey(const Key('relay-host-start')));
      await tester.pumpAndSettle();
      expect(configs.single, const GameConfig('quartett-trumpf', seed: 7, deck: 'rockets'));

      // Another game: no deck in its config.
      await tester.tap(find.byKey(const Key('relay-game-schiffe')));
      await tester.pump();
      expect(find.byKey(const Key('relay-deck')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('relay-host-start')));
      await tester.tap(find.byKey(const Key('relay-host-start')));
      await tester.pumpAndSettle();
      expect(configs.last, const GameConfig('schiffe', seed: 7));
    });
  });
}
