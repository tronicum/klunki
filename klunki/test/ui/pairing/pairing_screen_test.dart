// KLD-034: host and join panels of the pairing screen with FakeDiscovery and
// loopback transports.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/discovery.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/net/join_payload.dart';
import 'package:klunki/net/join_qr.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/device_name.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';

import '../../l10n/l10n_test_utils.dart';
import 'pairing_test_utils.dart';

const _timeout = Timeout(Duration(seconds: 30));

Future<void> _openPairing(WidgetTester tester, PairingDeps deps) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(launcherApp(deps));
  await tester.tap(find.byKey(const Key('open-pairing')));
  await tester.pumpAndSettle();
}

Future<void> _startHosting(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('pair-host-start')));
  await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty,
      what: 'host waiting view');
}

Finder _address(int i, String text) =>
    find.descendant(of: find.byKey(Key('pair-address-$i')), matching: find.text(text));

void main() {
  group('host', () {
    testWidgets('shows name, every address with the real port and the QR; advertises', (tester) async {
      final discovery = FakeDiscovery();
      final created = CreatedTransports();
      await _openPairing(tester, testDeps(discovery: discovery, created: created, name: 'Stefans iPhone'));

      await tester.tap(find.byKey(const Key('pair-game-muehle')));
      await tester.pump();
      await _startHosting(tester);

      final port = created.hosts.single.port!;
      expect(find.text('Stefans iPhone hostet Mühle'), findsOneWidget);
      expect(_address(0, '192.168.0.10:$port'), findsOneWidget);
      expect(_address(1, '10.0.0.7:$port'), findsOneWidget);
      expect(find.text('Warte auf Mitspieler…'), findsOneWidget);

      final qr = tester.widget<JoinQrCode>(find.byType(JoinQrCode));
      final wsPort = created.hosts.single.wsPort!;
      expect(wsPort, isNot(port));
      expect(qr.payload,
          JoinPayload(host: '192.168.0.10', port: port, name: 'Stefans iPhone', gameId: 'muehle', wsPort: wsPort));
      expect(qr.payload.format(), contains('w=$wsPort'));
      // Browser guests: the WebSocket address and the copyable link.
      expect(find.text('192.168.0.10:$wsPort'), findsOneWidget);
      expect(tester.widget<SelectableText>(find.byKey(const Key('pair-link'))).data, qr.payload.format());

      // Tapping the second address puts it in the QR code.
      await tester.tap(find.byKey(const Key('pair-address-1')));
      await tester.pump();
      expect(tester.widget<JoinQrCode>(find.byType(JoinQrCode)).payload.host, '10.0.0.7');

      final ad = discovery.advertised!;
      expect(ad.name, 'Stefans iPhone');
      expect(ad.port, port);
      expect(ad.gameId, 'muehle');
      expect(ad.protocol, klunkiProtocolVersion);
      expect(ad.wsPort, wsPort);
      expect(created.hosts.single.config.seed, 7);

      await unmountAndSettleSockets(tester, created);
    }, timeout: _timeout);

    testWidgets('falls back to a free port when 4747 is busy and shows the real port', (tester) async {
      final discovery = FakeDiscovery();
      final created = CreatedTransports();
      await _openPairing(
        tester,
        testDeps(
          discovery: discovery,
          created: created,
          preferredPort: klunkiDefaultPort,
          hostTransport: (config, {required name, required port, required wsPort}) {
            if (port == klunkiDefaultPort) {
              created.hostPorts.add(port);
              return Future.error(const SocketLikeError('address in use'));
            }
            return loopbackHost(created, config, name: name, port: port, wsPort: wsPort);
          },
        ),
      );
      await _startHosting(tester);

      expect(created.hostPorts, [klunkiDefaultPort, 0]);
      final port = created.hosts.single.port!;
      expect(port, isNot(klunkiDefaultPort));
      expect(_address(0, '192.168.0.10:$port'), findsOneWidget);
      expect(discovery.advertised!.port, port);

      await unmountAndSettleSockets(tester, created);
    }, timeout: _timeout);

    testWidgets('leaving the waiting screen stops advertising and closes the transport', (tester) async {
      final discovery = FakeDiscovery();
      final created = CreatedTransports();
      await _openPairing(tester, testDeps(discovery: discovery, created: created));
      await _startHosting(tester);
      expect(discovery.advertised, isNotNull);

      await tester.tap(find.byType(BackButton)); // pageBack() looks for the English "Back" tooltip
      await tester.pumpAndSettle();

      expect(find.byType(PairingScreen), findsNothing);
      expect(discovery.advertised, isNull);
      expect(created.hosts.single.connection.value, NetConnectionState.closed);
      await unmountAndSettleSockets(tester, created);
    }, timeout: _timeout);

    testWidgets('"Abbrechen" stops advertising and closes the transport', (tester) async {
      final discovery = FakeDiscovery();
      final created = CreatedTransports();
      await _openPairing(tester, testDeps(discovery: discovery, created: created));
      await _startHosting(tester);

      await tester.tap(find.byKey(const Key('pair-host-cancel')));
      await tester.pump();

      expect(find.byKey(const Key('pair-host-start')), findsOneWidget);
      expect(discovery.advertised, isNull);
      expect(created.hosts.single.connection.value, NetConnectionState.closed);
      await unmountAndSettleSockets(tester, created);
    }, timeout: _timeout);
  });

  group('join', () {
    testWidgets('lists discovered hosts with name, game and IP', (tester) async {
      final discovery = FakeDiscovery();
      final created = CreatedTransports();
      await _openPairing(tester, testDeps(discovery: discovery, created: created));
      await tester.tap(find.text('Beitreten'));
      await tester.pump();
      expect(find.text('Suche nach Spielen…'), findsOneWidget);

      discovery.addHost(const KlunkiHostInfo(
          name: 'Stefans iPad', host: '192.168.0.20', port: 4747, protocol: klunkiProtocolVersion, gameId: 'connect4'));
      discovery.addHost(const KlunkiHostInfo(name: 'Altes Handy', host: '192.168.0.30', port: 5000, protocol: 99));
      await tester.pump();

      expect(find.text('Stefans iPad hostet 4 Gewinnt'), findsOneWidget);
      expect(find.text('192.168.0.20:4747'), findsOneWidget);
      expect(find.text('Altes Handy'), findsOneWidget);
      expect(find.text('192.168.0.30:5000 · andere Klunki-Version'), findsOneWidget);
      expect(discovery.isBrowsing, isTrue);

      discovery.removeHost('192.168.0.30:5000');
      await tester.pump();
      expect(find.text('Altes Handy'), findsNothing);

      // Leaving stops browsing.
      await tester.tap(find.byType(BackButton)); // pageBack() looks for the English "Back" tooltip
      await tester.pumpAndSettle();
      expect(discovery.isBrowsing, isFalse);
    });

    testWidgets('manual entry: invalid input shows an error, valid forms connect', (tester) async {
      final discovery = FakeDiscovery();
      final created = CreatedTransports();
      final calls = <(String, int)>[];
      await _openPairing(
        tester,
        testDeps(
          discovery: discovery,
          created: created,
          joinTransport: (host, port, {required name}) {
            calls.add((host, port));
            return Future.error(const SocketLikeError('Connection refused'));
          },
        ),
      );
      await tester.tap(find.text('Beitreten'));
      await tester.pump();

      Future<void> submit(String text) async {
        await tester.enterText(find.byKey(const Key('pair-manual')), text);
        await tester.tap(find.byKey(const Key('pair-manual-connect')));
        await tester.pump();
        await tester.pump();
      }

      for (final bad in ['', 'abc def', '192.168.1.300', '192.168.1.2:99999', 'http://192.168.1.2']) {
        await submit(bad);
        expect(find.textContaining('Ungültige Adresse'), findsOneWidget, reason: bad);
      }
      expect(calls, isEmpty);

      await submit('192.168.1.20');
      expect(find.textContaining('Ungültige Adresse'), findsNothing);
      await submit('192.168.1.21:5000');
      await submit('klunki://join?h=10.0.0.5&p=4800&n=Bob');
      expect(calls, [('192.168.1.20', 4747), ('192.168.1.21', 5000), ('10.0.0.5', 4800)]);

      // The failure is explained in German with hints.
      expect(find.byKey(const Key('pair-join-error')), findsOneWidget);
      expect(find.textContaining('Verbindung zu Bob fehlgeschlagen'), findsOneWidget);
      expect(find.textContaining('selben WLAN'), findsOneWidget);
    });

    testWidgets('a hanging connect times out with the hint text', (tester) async {
      final discovery = FakeDiscovery();
      final created = CreatedTransports();
      final never = Completer<NetworkTransport>();
      await _openPairing(
        tester,
        testDeps(
          discovery: discovery,
          created: created,
          joinTimeout: const Duration(seconds: 3),
          joinTransport: (host, port, {required name}) => never.future,
        ),
      );
      await tester.tap(find.text('Beitreten'));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('pair-manual')), '192.168.1.20');
      await tester.tap(find.byKey(const Key('pair-manual-connect')));
      await tester.pump();
      expect(find.byKey(const Key('pair-join-progress')), findsOneWidget);
      expect(find.text('Verbinde mit 192.168.1.20:4747…'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.byKey(const Key('pair-join-progress')), findsNothing);
      expect(find.textContaining('Zeitüberschreitung'), findsOneWidget);
      expect(find.textContaining('Lokales Netzwerk'), findsOneWidget);
    });
  });

  test('device name from the host name', () {
    expect(deviceNameFromHostname('Stefans-iPhone.local', TargetPlatform.iOS), 'Stefans iPhone');
    expect(deviceNameFromHostname('localhost', TargetPlatform.iOS), 'iPhone/iPad');
    expect(deviceNameFromHostname('', TargetPlatform.android), 'Android');
    expect(deviceNameFromHostname('pixel-7', TargetPlatform.android), 'pixel 7');
  });

  testWidgets('pairing screen in English (I18N-02b)', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final created = CreatedTransports();
    await tester.pumpWidget(localizedApp(
      PairingScreen(deps: testDeps(discovery: FakeDiscovery(), created: created)),
      locale: const Locale('en'),
    ));
    expect(find.text('Play over Wi-Fi'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('Host game'), findsOneWidget);
    expect(find.text('Four in a Row'), findsOneWidget);
    await tester.tap(find.text('Join'));
    await tester.pump();
    expect(find.text('Searching for games…'), findsOneWidget);
    expect(find.text('Or enter an address'), findsOneWidget);
    await unmountAndSettleSockets(tester, created);
  });

  testWidgets('menu has "Über WLAN spielen" (not web)', (tester) async {
    // The full app (pinned to German): the menu's LanguageButton needs the
    // localization delegates.
    await tester.pumpWidget(klunkiApp());
    expect(find.byKey(const Key('menu-network')), findsOneWidget);
    expect(find.text('Über WLAN spielen'), findsOneWidget);
  });
}

class SocketLikeError implements Exception {
  final String message;
  const SocketLikeError(this.message);
  @override
  String toString() => message;
}
