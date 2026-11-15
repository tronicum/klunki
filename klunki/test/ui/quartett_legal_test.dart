// KLD-127: "Rechtliche Hinweise" of the Quartett cards: the small link under
// the deck picker and the card gallery, the entry in the game's "⋮" menu and
// on the About screen all open the notice page; the page shows the generic
// trademark text, the photo and drawing lines and links the image credits.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/profile/quartett_deck_settings.dart';
import 'package:klunki/ui/games/quartett_gallery.dart';
import 'package:klunki/ui/games/quartett_media.dart';
import 'package:klunki/ui/games/quartett_trumpf_screen.dart';
import 'package:klunki/ui/quartett_legal_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' show QuartettDeck;

import '../l10n/l10n_test_utils.dart';

const _trademarks = 'Namen von Herstellern und Produkten auf den Karten dienen nur zur Bezeichnung. '
    'Sie können Marken ihrer jeweiligen Inhaber sein. Klunki steht in keiner Verbindung zu diesen Herstellern '
    'und wird nicht von ihnen unterstützt.';

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Taps [link] and checks that the notice page with its German text opened.
Future<void> _opensNotice(WidgetTester tester, Finder link) async {
  await tester.ensureVisible(link);
  await tester.pumpAndSettle();
  await tester.tap(link);
  await tester.pumpAndSettle();
  expect(find.byType(QuartettLegalScreen), findsOneWidget);
  expect(find.text('Rechtliche Hinweise'), findsWidgets);
  expect(find.text(_trademarks), findsOneWidget);
}

void main() {
  testWidgets('the page shows the notice, the photo and drawing lines; Bildnachweise opens the credits',
      (tester) async {
    await _phone(tester);
    await tester.pumpWidget(localizedApp(const QuartettLegalScreen()));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Rechtliche Hinweise'), findsOneWidget);
    expect(find.text(_trademarks), findsOneWidget);
    expect(find.textContaining('Wikimedia Commons'), findsOneWidget);
    expect(find.textContaining('selbst gezeichnet'), findsOneWidget);
    // Generic: no deck-specific word.
    for (final key in ['quartett-legal-trademarks', 'quartett-legal-photos', 'quartett-legal-drawings']) {
      final text = tester.widget<Text>(find.byKey(Key(key))).data!;
      expect(text, isNot(matches(RegExp('Fahrzeug|Auto|Rakete|Flugzeug|Zug'))), reason: key);
    }
    await tester.tap(find.byKey(const Key('quartett-legal-credits')));
    await tester.pumpAndSettle();
    expect(find.byType(QuartettImageCreditsScreen), findsOneWidget);
  });

  testWidgets('Arabic: the page is laid out right to left', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(localizedApp(const QuartettLegalScreen(), locale: const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('ملاحظات قانونية'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byKey(const Key('quartett-legal-trademarks')))), TextDirection.rtl);
  });

  testWidgets('deck picker: the small link opens the notice', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(localizedApp(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const Key('start'),
            onPressed: () => openGameFromMenu(context, 'quartett-trumpf', deckSettings: QuartettDeckSettings.memory()),
            child: const Text('go'),
          ),
        ),
      ),
    )));
    await tester.tap(find.byKey(const Key('start')));
    await tester.pumpAndSettle();
    final link = find.descendant(
        of: find.byKey(const Key('quartett-deck-picker')), matching: find.byKey(const Key('quartett-legal-link')));
    expect(link, findsOneWidget);
    await _opensNotice(tester, link);
  });

  testWidgets('card gallery: the deck list has the link', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(localizedApp(const QuartettGalleryScreen()));
    // Below six decks (KLD-129) the lazy list builds the link only when scrolled to.
    await tester.scrollUntilVisible(find.byKey(const Key('quartett-legal-link')), 200,
        scrollable: find.byType(Scrollable).first);
    await _opensNotice(tester, find.byKey(const Key('quartett-legal-link')));
  });

  testWidgets('card gallery: a deck has the link under its cards', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(localizedApp(QuartettDeckGalleryScreen(deck: QuartettDeck.byId('rockets')!)));
    await tester.pumpAndSettle();
    await _opensNotice(tester, find.byKey(const Key('quartett-legal-link')));
  });

  for (final gameId in ['quartett-trumpf', 'quartett-sets']) {
    testWidgets('$gameId: "Rechtliche Hinweise" in the game menu', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(localizedApp(Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('start'),
              onPressed: () => openGameFromMenu(context, gameId, deckSettings: QuartettDeckSettings.memory()),
              child: const Text('go'),
            ),
          ),
        ),
      )));
      await tester.tap(find.byKey(const Key('start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quartett-deck-play')));
      await tester.pumpAndSettle();
      if (gameId == 'quartett-trumpf') expect(find.byType(QuartettTrumpfScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('shell-menu')));
      await tester.pumpAndSettle();
      await _opensNotice(tester, find.byKey(const Key('quartett-legal-menu')));
    });
  }

  testWidgets('About: "Rechtliche Hinweise" next to Impressum opens the notice', (tester) async {
    tester.view.physicalSize = const Size(390, 1400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(klunkiApp());
    await tester.pump();
    final about = find.byKey(const Key('menu-about'));
    await tester.ensureVisible(about);
    await tester.tap(about);
    await tester.pumpAndSettle();
    final tile = find.byKey(const Key('about-quartett-legal'));
    expect(find.descendant(of: tile, matching: find.text('Quartett-Karten')), findsOneWidget);
    await _opensNotice(tester, tile);
  });
}
