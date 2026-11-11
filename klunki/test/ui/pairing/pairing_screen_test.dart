// KLD-034: host and join panels of the pairing screen with FakeDiscovery and
// loopback transports.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/discovery.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/net/join_payload.dart';
import 'package:klunki/net/join_qr.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/profile/room_settings.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/device_name.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/pairing/relay_host_screen.dart' show RelayHostScreen;
import 'package:klunki/ui/shell/screen_registry.dart' show networkGameSpecs;
import 'package:klunki_engine/klunki_engine.dart' show ChessColorChoice, GameConfig, MauMauRules, Player;
import 'package:klunki_net/guest_web.dart' show NetException;

import '../../l10n/l10n_test_utils.dart';
import 'pairing_test_utils.dart';

const _timeout = Timeout(Duration(seconds: 30));

Future<void> _openPairing(WidgetTester tester, PairingDeps deps, {bool join = false}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(launcherApp(deps));
  await tester.tap(find.byKey(Key(join ? 'open-join' : 'open-pairing')));
  // No settle on the join screen: the "searching" spinner never stops.
  if (join) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  } else {
    await tester.pumpAndSettle();
  }
}

/// "Raum beitreten" → "Erweitert" → the typed address.
Future<void> _openJoinAdvanced(WidgetTester tester, PairingDeps deps) async {
  await _openPairing(tester, deps, join: true);
  await openAdvanced(tester, 'pair-join-advanced');
}

Future<void> _startHosting(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('pair-host-start')));
  await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty,
      what: 'host waiting view');
}

/// An address of the waiting room (KLD-098: under "Erweitert", also found
/// while collapsed).
Finder _address(int i, String text) => find.descendant(
    of: find.byKey(Key('pair-address-$i'), skipOffstage: false),
    matching: find.text(text, skipOffstage: false),
    skipOffstage: false);

void main() {
  group('host', () {
    // KLD-059 step 3: chess plays over the network; KLD-094 step 7: the word
    // tile game too, now that it is released.
    testWidgets('offers every network game, chess and Wortgewandt included', (tester) async {
      await _openPairing(tester, testDeps(discovery: FakeDiscovery(), created: CreatedTransports(), name: 'Annas Tablet'));
      expect(find.byKey(const Key('pair-game-muehle')), findsOneWidget);
      expect(find.byKey(const Key('pair-game-gostrategy')), findsOneWidget);
      expect(find.byKey(const Key('pair-game-chess')), findsOneWidget);
      expect(networkGameSpecs.map((s) => s.id), contains('chess'));
      expect(find.byKey(const Key('pair-game-wordtiles')), findsOneWidget);
      expect(networkGameSpecs.map((s) => s.id), contains('wordtiles'));
      expect(find.byKey(const Key('pair-game-maumau')), findsOneWidget);
      expect(find.byKey(const Key('pair-game-maexchen')), findsOneWidget);
    });

    testWidgets('shows name, every address with the real port and the QR; advertises', (tester) async {
      final discovery = FakeDiscovery();
      final created = CreatedTransports();
      await _openPairing(tester, testDeps(discovery: discovery, created: created, name: 'Stefans iPhone'));

      await tester.tap(find.byKey(const Key('pair-game-muehle')));
      await tester.pump();
      await _startHosting(tester);

      final port = created.hosts.single.port!;
      expect(find.text('Raum von Stefans iPhone: Mühle'), findsOneWidget);
      expect(find.textContaining('scannen diesen QR-Code'), findsOneWidget);
      // KLD-098: addresses and the browser link are under "Erweitert".
      expect(find.byKey(const Key('pair-address-0')), findsNothing);
      await openAdvanced(tester, 'pair-waiting-advanced');
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
      await _openPairing(tester, testDeps(discovery: discovery, created: created), join: true);
      expect(find.text('Räume in der Nähe'), findsOneWidget);
      expect(find.text('Suche nach Räumen…'), findsOneWidget);

      discovery.addHost(const KlunkiHostInfo(
          name: 'Stefans iPad', host: '192.168.0.20', port: 4747, protocol: klunkiProtocolVersion, gameId: 'connect4'));
      discovery.addHost(const KlunkiHostInfo(name: 'Altes Handy', host: '192.168.0.30', port: 5000, protocol: 99));
      await tester.pump();

      expect(find.text('Raum von Stefans iPad: 4 Gewinnt'), findsOneWidget);
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
      await _openJoinAdvanced(
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

    testWidgets('KLD-071: a host whose seat is taken says "Platz belegt"', (tester) async {
      await _openJoinAdvanced(
        tester,
        testDeps(
          discovery: FakeDiscovery(),
          created: CreatedTransports(),
          joinTransport: (host, port, {required name}) =>
              Future.error(const NetException('peer error: session full')),
        ),
      );
      await tester.enterText(find.byKey(const Key('pair-manual')), '192.168.1.20');
      await tester.tap(find.byKey(const Key('pair-manual-connect')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('pair-join-error')), findsOneWidget);
      expect(find.textContaining('Platz belegt'), findsOneWidget);
      expect(find.textContaining('selben WLAN'), findsNothing);
    });

    testWidgets('a hanging connect times out with the hint text', (tester) async {
      final discovery = FakeDiscovery();
      final created = CreatedTransports();
      final never = Completer<NetworkTransport>();
      await _openJoinAdvanced(
        tester,
        testDeps(
          discovery: discovery,
          created: created,
          joinTimeout: const Duration(seconds: 3),
          joinTransport: (host, port, {required name}) => never.future,
        ),
      );
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
    expect(find.text('Start a room'), findsNWidgets(2)); // title and button
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('Four in a Row'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    await tester.pumpWidget(localizedApp(
      PairingScreen(key: const ValueKey('join'), deps: testDeps(discovery: FakeDiscovery(), created: created), mode: RoomMode.join),
      locale: const Locale('en'),
    ));
    await tester.pump();
    expect(find.text('Join a room'), findsNWidgets(2));
    expect(find.text('Type the room code'), findsOneWidget);
    expect(find.text('Rooms nearby'), findsOneWidget);
    expect(find.text('Looking for rooms…'), findsOneWidget);
    await unmountAndSettleSockets(tester, created);
  });

  // KLD-098: no "host" wording; two equal room buttons in the menu.
  testWidgets('menu: "Mit anderen Geräten spielen" with "Raum starten" and "Raum beitreten" (not web)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The full app (pinned to German): the menu's LanguageButton needs the
    // localization delegates.
    await tester.pumpWidget(klunkiApp());
    expect(find.text('Mit anderen Geräten spielen'), findsOneWidget);
    final start = find.byKey(const Key('menu-room-start'));
    final join = find.byKey(const Key('menu-room-join'));
    expect(find.descendant(of: start, matching: find.text('Raum starten')), findsOneWidget);
    expect(find.descendant(of: start, matching: find.text('Andere kommen mit dem Raumcode dazu')), findsOneWidget);
    expect(find.descendant(of: join, matching: find.text('Raum beitreten')), findsOneWidget);
    expect(find.descendant(of: join, matching: find.text('Code scannen oder eintippen')), findsOneWidget);
    expect(tester.getSize(start), tester.getSize(join));
    expect(find.textContaining('host'), findsNothing);
    expect(find.textContaining('Host'), findsNothing);
  });

  group('KLD-098 room on this device or through the relay', () {
    testWidgets('default: on this device; the relay switch is under "Erweitert" and remembered', (tester) async {
      final created = CreatedTransports();
      final rooms = RoomSettings.memory();
      await _openPairing(tester, testDeps(discovery: FakeDiscovery(), created: created, roomSettings: rooms));
      expect(find.byKey(const Key('pair-via-relay')), findsNothing); // collapsed
      await openAdvanced(tester, 'pair-start-advanced');
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('pair-via-relay'))).value, isFalse);
      expect(find.byKey(const Key('relay-line')), findsNothing);
      await tester.tap(find.byKey(const Key('pair-via-relay')));
      await tester.pump();
      expect(rooms.value, isTrue);
      expect(find.byKey(const Key('relay-line')), findsOneWidget);
      await tester.tap(find.byKey(const Key('pair-via-relay')));
      await tester.pump();
      expect(rooms.value, isFalse);
      await _startHosting(tester);
      expect(created.hosts, hasLength(1)); // TCP on this device
      await unmountAndSettleSockets(tester, created);
    }, timeout: _timeout);
  });

  // KLD-105: a game tile's "Mit anderen" opens "Raum starten" for that game.
  group('KLD-105 room for one game', () {
    Future<void> pumpFor(WidgetTester tester, PairingDeps deps, String gameId) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(localizedApp(PairingScreen(deps: deps, gameId: gameId)));
      await tester.pump();
    }

    testWidgets('on this device: the game is shown, not asked for, and hosted', (tester) async {
      final created = CreatedTransports();
      await pumpFor(tester, testDeps(discovery: FakeDiscovery(), created: created), 'schiffe');
      expect(find.byKey(const Key('pair-game-fixed')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('pair-game-fixed')), matching: find.text('Schiffe versenken')),
          findsOneWidget);
      expect(find.text('Spiel wählen'), findsNothing);
      for (final spec in networkGameSpecs) {
        expect(find.byKey(Key('pair-game-${spec.id}')), findsNothing);
      }
      await _startHosting(tester);
      expect(created.hosts.single.config.gameId, 'schiffe');
      await unmountAndSettleSockets(tester, created);
    }, timeout: _timeout);

    testWidgets('chess from the menu tile: preselected and hosted (KLD-059 step 3)', (tester) async {
      final created = CreatedTransports();
      await pumpFor(tester, testDeps(discovery: FakeDiscovery(), created: created), 'chess');
      expect(find.descendant(of: find.byKey(const Key('pair-game-fixed')), matching: find.text('Schach')),
          findsOneWidget);
      await _startHosting(tester);
      expect(created.hosts.single.config.gameId, 'chess');
      await unmountAndSettleSockets(tester, created);
    }, timeout: _timeout);

    // KLD-059 step 4a: the host chooses its colour; "Zufällig" (the default)
    // is decided by the seed (7 in the tests: the host plays Black).
    for (final (choice, white, text) in [
      (null, Player.b, 'Du spielst Schwarz.'),
      ('white', Player.a, 'Du spielst Weiß.'),
      ('black', Player.b, 'Du spielst Schwarz.'),
      ('random', Player.b, 'Du spielst Schwarz.'),
    ]) {
      testWidgets('chess: colour ${choice ?? 'default (Zufällig)'} -> the config says who plays White (step 4a)',
          (tester) async {
        final created = CreatedTransports();
        await pumpFor(tester, testDeps(discovery: FakeDiscovery(), created: created), 'chess');
        expect(find.byKey(const Key('pair-chess-color')), findsOneWidget);
        expect(find.text('Deine Farbe'), findsOneWidget);
        expect(find.byKey(const Key('pair-chess-color-helper')), findsOneWidget);
        final picker = find.descendant(
            of: find.byKey(const Key('pair-chess-color')), matching: find.byType(SegmentedButton<ChessColorChoice>));
        expect(tester.widget<SegmentedButton<ChessColorChoice>>(picker).selected, {ChessColorChoice.random});
        if (choice != null) {
          await tester.tap(find.byKey(Key('pair-chess-color-$choice')));
          await tester.pump();
          expect(tester.widget<SegmentedButton<ChessColorChoice>>(picker).selected,
              {ChessColorChoice.values.byName(choice)});
        }
        await _startHosting(tester);
        final config = created.hosts.single.config;
        expect(config.chessWhite, white);
        expect(config.toJson().containsKey('white'), white == Player.b);
        expect(tester.widget<Text>(find.byKey(const Key('pair-hosting-options'))).data, text);
        await unmountAndSettleSockets(tester, created);
      }, timeout: _timeout);
    }

    testWidgets('other games show no colour choice', (tester) async {
      final created = CreatedTransports();
      await pumpFor(tester, testDeps(discovery: FakeDiscovery(), created: created), 'muehle');
      expect(find.byKey(const Key('pair-chess-color')), findsNothing);
      await _startHosting(tester);
      expect(created.hosts.single.config.chessWhite, Player.a);
      await unmountAndSettleSockets(tester, created);
    }, timeout: _timeout);

    testWidgets('chess through the relay: the colour chosen goes along to the relay room screen', (tester) async {
      final created = CreatedTransports();
      final configs = <GameConfig>[];
      final deps = testDeps(
        discovery: FakeDiscovery(),
        created: created,
        roomSettings: RoomSettings.memory(true),
        relaySettings: RelaySettings.memory(Uri.parse('ws://127.0.0.1:9/')),
        relayHost: (config, relay, {required name}) async {
          configs.add(config);
          throw const SocketLikeError('no relay');
        },
      );
      await pumpFor(tester, deps, 'chess');
      await tester.tap(find.byKey(const Key('pair-chess-color-white')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pair-host-start')));
      await tester.pumpAndSettle();
      expect(find.byType(RelayHostScreen), findsOneWidget);
      expect(configs.single.chessWhite, Player.a, reason: 'seed 7 would have made the host Black');
      final picker = find.descendant(
          of: find.byKey(const Key('relay-chess-color')), matching: find.byType(SegmentedButton<ChessColorChoice>));
      expect(tester.widget<SegmentedButton<ChessColorChoice>>(picker).selected, {ChessColorChoice.white});
      await unmountAndSettleSockets(tester, created);
    });

    // KLD-118 network step: Mau-Mau's house rules are chosen on "Raum
    // starten", travel in the config and show in the waiting room.
    testWidgets('Mau-Mau: the house rules are chosen, hosted and shown in the room', (tester) async {
      final created = CreatedTransports();
      await pumpFor(tester, testDeps(discovery: FakeDiscovery(), created: created), 'maumau');
      expect(find.byKey(const Key('pair-rules')), findsOneWidget);
      expect(find.byKey(const Key('pair-maumau-jack-info')), findsOneWidget);
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('pair-maumau-rule-jackOnJack'))).value, isFalse);
      await tester.ensureVisible(find.byKey(const Key('pair-maumau-rule-jackOnJack')));
      await tester.tap(find.byKey(const Key('pair-maumau-rule-jackOnJack')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('pair-maumau-rule-eight')));
      await tester.tap(find.byKey(const Key('pair-maumau-rule-eight')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('pair-host-start')));
      await _startHosting(tester);
      final config = created.hosts.single.config;
      expect(config.gameId, 'maumau');
      expect(config.mauMau, const MauMauRules(jackOnJack: true, eightSkips: false));
      expect(tester.widget<Text>(find.byKey(const Key('pair-hosting-options'))).data,
          '7: zwei Karten ziehen · 7 auf 7 · Bube auf Bube · Ass: noch mal · „Mau!“ sagen · Legen, wenn möglich');
      await unmountAndSettleSockets(tester, created);
    }, timeout: _timeout);

    testWidgets('Mau-Mau through the relay: the house rules go along to the relay room screen', (tester) async {
      final created = CreatedTransports();
      final configs = <GameConfig>[];
      final deps = testDeps(
        discovery: FakeDiscovery(),
        created: created,
        roomSettings: RoomSettings.memory(true),
        relaySettings: RelaySettings.memory(Uri.parse('ws://127.0.0.1:9/')),
        relayHost: (config, relay, {required name}) async {
          configs.add(config);
          throw const SocketLikeError('no relay');
        },
      );
      await pumpFor(tester, deps, 'maumau');
      await tester.ensureVisible(find.byKey(const Key('pair-maumau-rule-mau')));
      await tester.tap(find.byKey(const Key('pair-maumau-rule-mau')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('pair-host-start')));
      await tester.tap(find.byKey(const Key('pair-host-start')));
      await tester.pumpAndSettle();
      expect(find.byType(RelayHostScreen), findsOneWidget);
      expect(configs.single.mauMau, const MauMauRules(mauCall: false));
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('relay-maumau-rule-mau'))).value, isFalse);
      await unmountAndSettleSockets(tester, created);
    });

    // KLD-121 network step: Mäxchen's lives, "Unbegrenzte Leben" and
    // "Mäxchen doppelt" on "Raum starten".
    for (final (taps, expected, summary) in [
      (<String>[], const GameConfig('maexchen'), '3 Leben · Mäxchen doppelt'),
      (['pair-maexchen-lives-5', 'pair-maexchen-double'], const GameConfig('maexchen', lives: 5, maexchenDouble: false),
          '5 Leben'),
      (['pair-maexchen-unlimited'], const GameConfig('maexchen', maexchenUnlimited: true),
          'Unbegrenzte Leben · Mäxchen doppelt'),
    ]) {
      testWidgets('Mäxchen: $taps -> hosted and shown in the room as "$summary"', (tester) async {
        final created = CreatedTransports();
        await pumpFor(tester, testDeps(discovery: FakeDiscovery(), created: created), 'maexchen');
        expect(find.byKey(const Key('pair-rules')), findsOneWidget);
        expect(find.byKey(const Key('pair-maexchen-shake')), findsNothing, reason: 'a device setting, not the room');
        for (final k in taps) {
          await tester.ensureVisible(find.byKey(Key(k)));
          await tester.tap(find.byKey(Key(k)));
          await tester.pump();
        }
        await tester.ensureVisible(find.byKey(const Key('pair-host-start')));
        await _startHosting(tester);
        final config = created.hosts.single.config;
        expect(config.copyWith(seed: 0), expected);
        expect(config.players, 2);
        expect(tester.widget<Text>(find.byKey(const Key('pair-hosting-options'))).data, summary);
        await unmountAndSettleSockets(tester, created);
      }, timeout: _timeout);
    }

    testWidgets('Mäxchen through the relay: the options go along to the relay room screen', (tester) async {
      final created = CreatedTransports();
      final configs = <GameConfig>[];
      final deps = testDeps(
        discovery: FakeDiscovery(),
        created: created,
        roomSettings: RoomSettings.memory(true),
        relaySettings: RelaySettings.memory(Uri.parse('ws://127.0.0.1:9/')),
        relayHost: (config, relay, {required name}) async {
          configs.add(config);
          throw const SocketLikeError('no relay');
        },
      );
      await pumpFor(tester, deps, 'maexchen');
      await tester.ensureVisible(find.byKey(const Key('pair-maexchen-lives-5')));
      await tester.tap(find.byKey(const Key('pair-maexchen-lives-5')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('pair-host-start')));
      await tester.tap(find.byKey(const Key('pair-host-start')));
      await tester.pumpAndSettle();
      expect(find.byType(RelayHostScreen), findsOneWidget);
      expect(configs.single.lives, 5);
      expect(find.byKey(const Key('relay-maexchen-lives')), findsOneWidget);
      await unmountAndSettleSockets(tester, created);
    });

    testWidgets('other games show no house rules', (tester) async {
      final created = CreatedTransports();
      await pumpFor(tester, testDeps(discovery: FakeDiscovery(), created: created), 'schiffe');
      expect(find.byKey(const Key('pair-rules')), findsNothing);
      await unmountAndSettleSockets(tester, created);
    });

    testWidgets('Quartett: the deck is still chosen', (tester) async {
      final created = CreatedTransports();
      await pumpFor(tester, testDeps(discovery: FakeDiscovery(), created: created), 'quartett-trumpf');
      expect(find.byKey(const Key('pair-game-fixed')), findsOneWidget);
      expect(find.byKey(const Key('pair-deck')), findsOneWidget);
      await unmountAndSettleSockets(tester, created);
    });

    testWidgets('through the relay: the relay room screen keeps the game fixed', (tester) async {
      final created = CreatedTransports();
      final configs = <GameConfig>[];
      final deps = testDeps(
        discovery: FakeDiscovery(),
        created: created,
        roomSettings: RoomSettings.memory(true),
        relaySettings: RelaySettings.memory(Uri.parse('ws://127.0.0.1:9/')),
        relayHost: (config, relay, {required name}) async {
          configs.add(config);
          throw const SocketLikeError('no relay');
        },
      );
      await pumpFor(tester, deps, 'gostrategy');
      await tester.tap(find.byKey(const Key('pair-host-start')));
      await tester.pumpAndSettle();
      expect(find.byType(RelayHostScreen), findsOneWidget);
      expect(find.byKey(const Key('relay-game-fixed')), findsOneWidget);
      expect(find.byKey(const Key('relay-game-connect4')), findsNothing);
      expect(configs.single.gameId, 'gostrategy');
      await unmountAndSettleSockets(tester, created);
    });
  });
}

class SocketLikeError implements Exception {
  final String message;
  const SocketLikeError(this.message);
  @override
  String toString() => message;
}
