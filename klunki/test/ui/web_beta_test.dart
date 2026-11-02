// KLD-108: the web beta on GitHub Pages. The Pages build (KLUNKI_WEB_CHANNEL
// =pages-beta) shows a "Beta" badge and a line in "Über Klunki"; on any
// https page without a usable (wss://) relay the network entries are greyed
// out and explain themselves in a sheet; the app links appear only when
// configured.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/web_channel.dart';
import 'package:klunki/net/room_link.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/ui/about_screen.dart';
import 'package:klunki/ui/menu_screen.dart';
import 'package:klunki/ui/pairing/network_unavailable.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' show appGameSpecs;

import '../l10n/l10n_test_utils.dart';

final _pages = Uri.parse('https://tronicum.github.io/klunki/');
final _lan = Uri.parse('http://192.168.1.20:8081/');

const _sheetText = 'Im Browser noch nicht verfügbar – mit der App könnt ihr auf mehreren Geräten spielen.';
const _teaser = 'App-Beta in Vorbereitung.';

Future<void> _pumpMenu(WidgetTester tester, {Uri? pageUrl, RelaySettings? relay, Locale locale = testLocale}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    localizedApp(
      MenuScreen(pageUrl: pageUrl, relaySettings: relay ?? RelaySettings.memory()),
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
}

/// The network entries of the menu: every "Mit anderen" link and both room buttons.
List<Finder> _networkEntries() => [
  for (final spec in appGameSpecs)
    if (!hotSeatOnlyGames.contains(spec.id)) find.byKey(Key('menu-${spec.id}-network')),
  // KLD-094 step 6: the debug preview's link (Wortgewandt online) too.
  for (final id in previewGames)
    if (!hotSeatOnlyGames.contains(id)) find.byKey(Key('menu-preview-$id-network')),
  find.byKey(const Key('menu-room-start')),
  find.byKey(const Key('menu-room-join')),
];

bool _greyed(WidgetTester tester, Finder entry) =>
    find.descendant(of: entry, matching: find.byWidgetPredicate((w) => w is Greyed && w.blocked)).evaluate().isNotEmpty;

void main() {
  tearDown(() {
    appWebChannel = '';
    appIosBetaUrl = '';
    appAndroidUrl = '';
    resetAboutLinkOpener();
  });

  group('browserCannotPlayOnline', () {
    bool blocked(Uri? page, String? relay) =>
        browserCannotPlayOnline(pageUrl: page, chosenRelay: relay == null ? null : Uri.parse(relay));

    test('native and http pages can always try', () {
      expect(blocked(null, null), isFalse);
      expect(blocked(_lan, null), isFalse);
      expect(blocked(_lan, 'ws://192.168.1.20:4749/relay'), isFalse);
    });

    test('https needs a relay the browser may open', () {
      expect(blocked(_pages, null), isTrue, reason: 'the page\'s own wss:// relay does not exist on Pages');
      expect(blocked(_pages, 'ws://192.168.1.20:4749/relay'), isTrue, reason: 'mixed content');
      expect(blocked(_pages, 'wss://relay.example.org/relay'), isFalse);
      expect(blocked(_pages, 'ws://localhost:4749/relay'), isFalse, reason: 'browsers allow ws:// to loopback');
    });
  });

  group('menu', () {
    testWidgets('native (no page URL): network entries enabled', (tester) async {
      await _pumpMenu(tester);
      for (final e in _networkEntries()) {
        expect(e, findsOneWidget);
        expect(_greyed(tester, e), isFalse, reason: '$e');
      }
    });

    testWidgets('relay-served http page on the LAN: enabled, "Raum starten" opens the room screen', (tester) async {
      await _pumpMenu(tester, pageUrl: _lan);
      for (final e in _networkEntries()) {
        expect(_greyed(tester, e), isFalse, reason: '$e');
      }
      await tester.tap(find.byKey(const Key('menu-room-start')));
      await tester.pumpAndSettle();
      expect(find.byType(NetworkUnavailableSheet), findsNothing);
      expect(find.byType(MenuScreen), findsNothing, reason: 'a room screen was pushed');
    });

    testWidgets('relay-served http page: a tile\'s "Mit anderen" asks start or join (KLD-111)', (tester) async {
      await _pumpMenu(tester, pageUrl: _lan);
      await tester.tap(find.byKey(const Key('menu-connect4-network')));
      await tester.pumpAndSettle();
      expect(find.byType(NetworkUnavailableSheet), findsNothing);
      expect(find.byKey(const Key('menu-room-choice-start')), findsOneWidget);
      expect(find.byKey(const Key('menu-room-choice-join')), findsOneWidget);
      await tester.tap(find.byKey(const Key('menu-room-choice-join')));
      await tester.pumpAndSettle();
      expect(find.byType(MenuScreen), findsNothing, reason: 'the join screen was pushed');
    });

    testWidgets('https without a wss:// relay: greyed out, a tap explains', (tester) async {
      await _pumpMenu(tester, pageUrl: _pages);
      final entries = _networkEntries();
      for (final e in entries) {
        expect(e, findsOneWidget, reason: 'still visible: $e');
        expect(_greyed(tester, e), isTrue, reason: '$e');
      }
      // "Ein Gerät" stays as it is.
      expect(_greyed(tester, find.byKey(const Key('menu-connect4-local'))), isFalse);

      for (final e in entries) {
        await tester.ensureVisible(e);
        await tester.tap(e);
        await tester.pumpAndSettle();
        expect(find.byType(NetworkUnavailableSheet), findsOneWidget, reason: '$e');
        // KLD-111: no "Raum starten / beitreten" choice in front of it.
        expect(find.byKey(const Key('menu-room-choice')), findsNothing, reason: '$e');
        expect(find.text(_sheetText), findsOneWidget);
        expect(find.text(_teaser), findsOneWidget);
        // No links configured: no buttons.
        expect(find.byKey(const Key('network-unavailable-ios')), findsNothing);
        expect(find.byKey(const Key('network-unavailable-android')), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
        expect(find.byType(MenuScreen), findsOneWidget, reason: 'nothing pushed');
        Navigator.of(tester.element(find.byType(NetworkUnavailableSheet))).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('https: a wss:// relay in the settings enables network play again', (tester) async {
      final relay = RelaySettings.memory();
      await _pumpMenu(tester, pageUrl: _pages, relay: relay);
      expect(_greyed(tester, find.byKey(const Key('menu-room-join'))), isTrue);

      await relay.set(Uri.parse('ws://192.168.1.20:4749/relay'));
      await tester.pump();
      expect(_greyed(tester, find.byKey(const Key('menu-room-join'))), isTrue, reason: 'ws:// is blocked on https');

      await relay.set(Uri.parse('wss://relay.example.org/relay'));
      await tester.pump();
      for (final e in _networkEntries()) {
        expect(_greyed(tester, e), isFalse, reason: '$e');
      }
    });

    testWidgets('configured app links become buttons; non-https links are ignored', (tester) async {
      final opened = <Uri>[];
      aboutLinkOpener = (uri) async {
        opened.add(uri);
        return true;
      };
      appIosBetaUrl = 'https://beta.example.org/klunki';
      appAndroidUrl = 'http://example.org/klunki.apk';
      await _pumpMenu(tester, pageUrl: _pages);
      await tester.tap(find.byKey(const Key('menu-room-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('network-unavailable-android')), findsNothing);
      final ios = find.byKey(const Key('network-unavailable-ios'));
      expect(ios, findsOneWidget);
      expect(find.text('App für iPhone und iPad testen'), findsOneWidget);
      await tester.tap(ios);
      await tester.pumpAndSettle();
      expect(opened, [Uri.parse('https://beta.example.org/klunki')]);

      appAndroidUrl = 'https://example.org/klunki.apk';
      Navigator.of(tester.element(find.byType(NetworkUnavailableSheet))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-room-join')));
      await tester.pumpAndSettle();
      expect(find.text('App für Android laden'), findsOneWidget);
      expect(find.text(_teaser), findsOneWidget, reason: 'the teaser stays');
    });

    testWidgets('sheet in Arabic (RTL) and Chinese', (tester) async {
      appIosBetaUrl = 'https://beta.example.org/klunki';
      appAndroidUrl = 'https://example.org/klunki.apk';
      for (final locale in const [Locale('ar'), Locale('zh'), Locale('fa')]) {
        await _pumpMenu(tester, pageUrl: _pages, locale: locale);
        await tester.tap(find.byKey(const Key('menu-room-start')));
        await tester.pumpAndSettle();
        final sheet = find.byType(NetworkUnavailableSheet);
        expect(sheet, findsOneWidget);
        expect(
          Directionality.of(tester.element(sheet)),
          locale.languageCode == 'zh' ? TextDirection.ltr : TextDirection.rtl,
        );
        expect(find.textContaining(_sheetText), findsNothing, reason: 'translated');
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(sheet)).pop();
        await tester.pumpAndSettle();
      }
    });
  });

  group('Pages beta flag', () {
    testWidgets('no badge and no About line without the flag', (tester) async {
      await _pumpMenu(tester, pageUrl: _pages);
      expect(find.byKey(const Key('menu-beta-badge')), findsNothing);
      await tester.tap(find.byKey(const Key('menu-about')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('about-web-beta')), findsNothing);
    });

    testWidgets('the flag shows the badge and the About line', (tester) async {
      appWebChannel = pagesBetaChannel;
      expect(isPagesBeta, isTrue);
      await _pumpMenu(tester, pageUrl: _pages);
      final badge = find.byKey(const Key('menu-beta-badge'));
      expect(badge, findsOneWidget);
      expect(find.descendant(of: find.byType(AppBar), matching: badge), findsOneWidget);
      expect(find.descendant(of: badge, matching: find.text('Beta')), findsOneWidget);
      await tester.tap(find.byKey(const Key('menu-about')));
      await tester.pumpAndSettle();
      expect(find.text('Web-Beta – Spiele mit mehreren Geräten gibt es in der App.'), findsOneWidget);
    });

    testWidgets('badge in every locale fits the app bar', (tester) async {
      appWebChannel = pagesBetaChannel;
      for (final locale in const [Locale('en'), Locale('fr'), Locale('zh'), Locale('ar'), Locale('fa')]) {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(localizedApp(MenuScreen(relaySettings: RelaySettings.memory()), locale: locale));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('menu-beta-badge')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });
}
