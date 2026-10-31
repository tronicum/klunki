// KLD-083: the localhost notice. A page opened as localhost / 127.x / ::1 /
// *.localhost (or a relay entered that way natively) hosts fine on this
// machine, but the room link and QR carry a host other devices can't reach:
// the relay line and the "Spiel hosten" waiting screen warn, with a
// collapsible "Wie finde ich die Adresse?". Hosting stays allowed.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/ui/pairing/relay_host_screen.dart';
import 'package:klunki/ui/pairing/relay_line.dart';
import 'package:klunki_net/relay_server.dart';

import '../../l10n/l10n_test_utils.dart';
import 'pairing_test_utils.dart';

const _timeout = Timeout(Duration(seconds: 60));

const _fullDe = 'Hinweis: Andere Geräte können „localhost“ nicht erreichen. Öffne die Seite über die WLAN-Adresse '
    'dieses Rechners (z. B. http://192.168.x.x:8081) oder seinen .local-Namen (z. B. http://my-computer.local:8081), '
    'damit Link und QR-Code auf anderen Geräten funktionieren.';

Future<void> _setSize(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _line(RelaySettings settings, {Uri? defaultRelay}) =>
    localizedApp(Scaffold(body: RelayLine(settings: settings, defaultRelay: defaultRelay)));

String _text(WidgetTester tester, Key parent) => tester
    .widget<Text>(find.descendant(of: find.byKey(parent), matching: find.byKey(const Key('loopback-text'))))
    .data!;

Future<RelayServer> _startRelay(WidgetTester tester) async {
  final server = (await tester.runAsync(() => Zone.root.run(
      () => RelayServer.start(port: 0, address: InternetAddress.loopbackIPv4, pingInterval: null))))!;
  addTearDown(() => tester.runAsync(server.close));
  return server;
}

void main() {
  group('relay line', () {
    for (final (page, host) in [
      ('http://localhost:8081/', 'localhost'),
      ('http://127.0.0.1:8081/', '127.0.0.1'),
      ('http://[::1]:8081/', '::1'),
      ('http://foo.localhost:8081/', 'foo.localhost'),
    ]) {
      testWidgets('warns for the page $page', (tester) async {
        await _setSize(tester);
        await tester.pumpWidget(_line(RelaySettings.memory(), defaultRelay: relayUriForPage(Uri.parse(page))));
        expect(find.byKey(const Key('relay-line-loopback')), findsOneWidget);
        expect(_text(tester, const Key('relay-line-loopback')),
            '„$host“ ist nur auf diesem Gerät erreichbar – andere Geräte brauchen die WLAN-Adresse oder den '
            '.local-Namen des Rechners.');
        // Still usable: the relay is shown and can be changed.
        expect(find.byKey(const Key('relay-line-address')), findsOneWidget);
        expect(tester.widget<TextButton>(find.byKey(const Key('relay-change'))).onPressed, isNotNull);
      });
    }

    for (final page in ['http://192.168.1.5:8081/', 'http://10.0.0.9:8081/', 'http://pc.local:8081/',
      'https://klunki.example/']) {
      testWidgets('no warning for the page $page', (tester) async {
        await _setSize(tester);
        await tester.pumpWidget(_line(RelaySettings.memory(), defaultRelay: relayUriForPage(Uri.parse(page))));
        expect(find.byKey(const Key('relay-line-address')), findsOneWidget);
        expect(find.byKey(const Key('relay-line-loopback')), findsNothing);
        expect(find.byKey(const Key('loopback-how')), findsNothing);
      });
    }

    testWidgets('native: localhost entered by hand warns; a LAN address clears it', (tester) async {
      await _setSize(tester);
      final settings = RelaySettings.memory(parseRelayUrl('localhost:4749'));
      await tester.pumpWidget(_line(settings));
      expect(find.byKey(const Key('relay-line-loopback')), findsOneWidget);
      await settings.set(parseRelayUrl('192.168.1.20:4749')!);
      await tester.pump();
      expect(find.byKey(const Key('relay-line-loopback')), findsNothing);
      await settings.set(parseRelayUrl('[::1]:4749')!);
      await tester.pump();
      expect(find.byKey(const Key('relay-line-loopback')), findsOneWidget);
      expect(find.text('Relay: [::1]:4749'), findsOneWidget);
    });

    testWidgets('"Wie finde ich die Adresse?" opens the per-OS help with copyable LTR commands', (tester) async {
      await _setSize(tester);
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.pumpWidget(
          _line(RelaySettings.memory(), defaultRelay: relayUriForPage(Uri.parse('http://localhost:8081/'))));
      expect(find.text('Wie finde ich die Adresse?'), findsOneWidget);
      expect(find.byKey(const Key('loopback-cmd-ipconfig getifaddr en0')), findsNothing); // collapsed
      await tester.tap(find.text('Wie finde ich die Adresse?'));
      await tester.pumpAndSettle();
      for (final cmd in ['ipconfig getifaddr en0', 'ipconfig', 'hostname -I', 'ip -4 addr show']) {
        expect(find.byKey(Key('loopback-cmd-$cmd')), findsOneWidget, reason: cmd);
      }
      for (final os in ['macOS', 'Windows', 'Linux']) {
        expect(find.text(os), findsOneWidget);
      }
      expect(find.textContaining('Allgemein › Freigaben („Lokaler Hostname“)'), findsOneWidget);
      expect(find.textContaining('<Computername>.local'), findsOneWidget);
      expect(find.textContaining('<Hostname>.local, wenn Avahi läuft'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('loopback-how-relay'))).data,
          'Tipp: Die Konsole von „klunki relay“ zeigt diese Adressen beim Start an.');
      await tester.tap(find.byKey(const Key('loopback-copy-hostname -I')));
      await tester.pump();
      expect(copied, ['hostname -I']);
      expect(find.text('Befehl kopiert'), findsOneWidget);
    });

    testWidgets('RTL: host and commands stay left-to-right', (tester) async {
      await _setSize(tester);
      await tester.pumpWidget(localizedApp(
          Scaffold(
              body: RelayLine(
                  settings: RelaySettings.memory(),
                  defaultRelay: relayUriForPage(Uri.parse('http://localhost:8081/')))),
          locale: const Locale('ar')));
      expect(_text(tester, const Key('relay-line-loopback')), contains('\u2066localhost\u2069'));
      await tester.tap(find.byKey(const Key('loopback-how')));
      await tester.pumpAndSettle();
      final cmd = find.byKey(const Key('loopback-cmd-ip -4 addr show'));
      expect(Directionality.of(tester.element(cmd)), TextDirection.ltr);
    });
  });

  group('host waiting screen', () {
    Future<void> host(WidgetTester tester, CreatedTransports created,
        {required Uri? page, required Uri relay, String? connectHost}) async {
      await tester.pumpWidget(localizedApp(RelayHostScreen(
        hostTransport: (config, r, {required name}) =>
            relayHost(created, config, connectHost == null ? r : r.replace(host: connectHost), name: name),
        defaultRelay: page == null ? null : relayUriForPage(page),
        relaySettings: page == null ? RelaySettings.memory(relay) : null,
        pageUrl: page,
        seed: () => 7,
        deviceName: () => 'Ada',
      )));
      await tester.pump();
      await tester.tap(find.byKey(const Key('relay-host-start')));
      await pumpUntil(tester, () => find.byKey(const Key('relay-host-waiting')).evaluate().isNotEmpty,
          what: 'waiting screen');
    }

    testWidgets('the PWA on localhost: hosting works, the full notice sits under the QR and link', (tester) async {
      await _setSize(tester);
      final server = await _startRelay(tester);
      final created = CreatedTransports();
      final page = Uri.parse('http://localhost:${server.port}/');
      await host(tester, created, page: page, relay: relayUriForPage(page)!, connectHost: '127.0.0.1');
      expect(created.hosts.single.roomCode, isNotNull); // hosting is allowed
      expect(find.byKey(const Key('relay-qr')), findsOneWidget);
      expect(_text(tester, const Key('relay-host-loopback')), _fullDe);
      // Right below the link (next to the code and QR).
      expect(tester.getTopLeft(find.byKey(const Key('relay-host-loopback'))).dy,
          greaterThan(tester.getBottomLeft(find.byKey(const Key('relay-link'))).dy));
      expect(find.text('Wie finde ich die Adresse?'), findsOneWidget);
      await unmountAndSettleSockets(tester, created);
      await tester.pump(const Duration(seconds: 6)); // the host close timer
    }, timeout: _timeout);

    testWidgets('natively with a 127.0.0.1 relay: the short notice', (tester) async {
      await _setSize(tester);
      final server = await _startRelay(tester);
      final created = CreatedTransports();
      await host(tester, created, page: null, relay: Uri.parse('ws://127.0.0.1:${server.port}/relay'));
      expect(_text(tester, const Key('relay-host-loopback')),
          '„127.0.0.1“ ist nur auf diesem Gerät erreichbar – andere Geräte brauchen die WLAN-Adresse oder den '
          '.local-Namen des Rechners.');
      await unmountAndSettleSockets(tester, created);
      await tester.pump(const Duration(seconds: 6)); // the host close timer
    }, timeout: _timeout);

    testWidgets('a LAN page and relay: no notice', (tester) async {
      await _setSize(tester);
      final server = await _startRelay(tester);
      final created = CreatedTransports();
      final page = Uri.parse('http://192.168.1.5:${server.port}/');
      // The test relay only listens on loopback; reach it as 0.0.0.0 (the
      // local machine, but not a loopback name): neither the page nor the
      // relay in the link is loopback.
      await host(tester, created, page: page, relay: relayUriForPage(page)!, connectHost: '0.0.0.0');
      expect(find.byKey(const Key('relay-host-waiting')), findsOneWidget);
      expect(find.byKey(const Key('relay-host-loopback')), findsNothing);
      expect(find.byKey(const Key('loopback-how')), findsNothing);
      await unmountAndSettleSockets(tester, created);
      await tester.pump(const Duration(seconds: 6)); // the host close timer
    }, timeout: _timeout);
  });
}
