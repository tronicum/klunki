// KLD-057b: browser vs browser through the relay. The "Spiel hosten" waiting
// screen (room code, QR, link), the room-code join (validation, relay
// address, error mapping), `?room=` at startup, and an in-process end to end
// game: a real RelayServer on loopback, host via relay ↔ guest via relay
// through NetworkTransport, Four in a Row to the result.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/net/join_qr.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/connect4/connect4_board.dart';
import 'package:klunki/ui/games/connect4_screen.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/pairing/relay_host_screen.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';
import 'pairing_test_utils.dart';

const _timeout = Timeout(Duration(seconds: 60));

final _page = Uri.parse('http://192.168.1.5:8000/');
final _pageRelay = Uri.parse('ws://192.168.1.5:8000/relay');

/// Records room-code joins and fails them with [error].
class _JoinRecorder {
  Object error;
  _JoinRecorder() : error = const NetException('relay: no room with code K7Q2M');
  final List<(Uri, String, String)> calls = [];
  Future<NetworkTransport> join(Uri relay, String code, {required String name}) {
    calls.add((relay, code, name));
    return Future.error(error);
  }
}

Future<NetworkTransport> _noJoin(Uri url, {required String name}) => Future.error(StateError('unused'));

Future<RelayServer> _startRelay(WidgetTester tester) async {
  final server = (await tester.runAsync(() => Zone.root.run(
      () => RelayServer.start(port: 0, address: InternetAddress.loopbackIPv4, pingInterval: null))))!;
  addTearDown(() => tester.runAsync(server.close));
  return server;
}

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
}

void main() {
  group('room-code join', () {
    testWidgets('validates the code; a valid one joins the page relay, normalised', (tester) async {
      await _setSize(tester, const Size(800, 1600));
      final r = _JoinRecorder();
      await tester.pumpWidget(localizedApp(
          WebJoinScreen(pageUrl: _page, deps: WebJoinDeps(joinTransport: _noJoin, relayJoin: r.join))));
      await tester.pump();
      expect(find.byKey(const Key('web-host')), findsOneWidget);
      expect(find.text('Mit Raumcode beitreten'), findsOneWidget);
      for (final bad in ['', 'K7Q2', 'K7Q2MM', 'K7Q0M', 'OIL23']) {
        await tester.enterText(find.byKey(const Key('room-code')), bad);
        await _tapVisible(tester, find.byKey(const Key('room-join-button')));
        await tester.pump();
        expect(find.textContaining('Ungültiger Raumcode'), findsOneWidget, reason: bad);
      }
      expect(r.calls, isEmpty);

      await tester.enterText(find.byKey(const Key('room-code')), 'k7q-2m');
      await _tapVisible(tester, find.byKey(const Key('room-join-button')));
      await tester.pump();
      await tester.pump();
      expect(r.calls.single, (_pageRelay, 'K7Q2M', 'Browser'));
      expect(find.textContaining('Ungültiger Raumcode'), findsNothing);
      expect(tester.widget<Text>(find.byKey(const Key('room-error'))).data,
          'Kein Raum mit dem Code K7Q 2M. Stimmt der Code, und wartet der Host noch?');
    });

    testWidgets('relay errors become friendly messages; unreachable shows how to start a relay', (tester) async {
      await _setSize(tester, const Size(800, 1600));
      final r = _JoinRecorder();
      await tester.pumpWidget(localizedApp(
          WebJoinScreen(pageUrl: _page, deps: WebJoinDeps(joinTransport: _noJoin, relayJoin: r.join))));
      await tester.pump();
      final cases = <Object, String>{
        const NetException('relay: room K7Q2M is full'): 'Raum K7Q 2M ist schon voll: Dort spielen bereits zwei.',
        const NetException('relay: host left'): 'Der Host hat den Raum verlassen. Das Spiel ist beendet.',
        const NetException('relay: room expired (idle)'): 'Der Raum ist abgelaufen (10 Minuten ohne Aktivität).',
        const NetException('cannot connect: cannot open ws://192.168.1.5:8000/relay?join=K7Q2M'):
            'Kein Relay erreichbar unter 192.168.1.5:8000.',
        const NetException('handshake timed out'): 'Verbindung zu K7Q 2M fehlgeschlagen (NetException: handshake timed out).',
      };
      for (final MapEntry(key: error, value: text) in cases.entries) {
        r.error = error;
        await tester.enterText(find.byKey(const Key('room-code')), 'K7Q2M');
        await _tapVisible(tester, find.byKey(const Key('room-join-button')));
        await tester.pump();
        await tester.pump();
        expect(tester.widget<Text>(find.byKey(const Key('room-error'))).data, text, reason: '$error');
        final unreachable = text.startsWith('Kein Relay');
        expect(find.byKey(const Key('room-start-hint')), unreachable ? findsOneWidget : findsNothing);
        if (unreachable) {
          expect(tester.widget<SelectableText>(find.byKey(const Key('relay-start-command'))).data,
              'dart run packages/klunki_net/bin/klunki.dart relay --web klunki/build/web');
        }
      }
    });

    testWidgets('one visible relay line: "ändern" sets another relay; invalid refused; default resets',
        (tester) async {
      await _setSize(tester, const Size(800, 1600));
      final r = _JoinRecorder();
      final settings = RelaySettings.memory();
      await tester.pumpWidget(localizedApp(WebJoinScreen(
          pageUrl: _page,
          deps: WebJoinDeps(joinTransport: _noJoin, relayJoin: r.join, relaySettings: () => settings))));
      await tester.pump();
      // No expanders, one relay line for hosting and joining.
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byKey(const Key('relay-line')), findsOneWidget);
      expect(find.text('Über Relay spielen (Raumcode)'), findsOneWidget);
      expect(find.text('Relay: 192.168.1.5:8000'), findsOneWidget);

      await _tapVisible(tester, find.byKey(const Key('relay-change')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const Key('relay-dialog-address'))).controller!.text,
          '192.168.1.5:8000');
      await tester.enterText(find.byKey(const Key('relay-dialog-address')), 'not a :: relay');
      await tester.tap(find.byKey(const Key('relay-dialog-save')));
      await tester.pump();
      expect(find.textContaining('Ungültige Relay-Adresse'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('relay-dialog-address')), '10.0.0.9:4749');
      await tester.tap(find.byKey(const Key('relay-dialog-save')));
      await tester.pumpAndSettle();
      expect(settings.value, Uri.parse('ws://10.0.0.9:4749/relay'));
      expect(find.text('Relay: 10.0.0.9:4749'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('room-code')), 'K7Q2M');
      await _tapVisible(tester, find.byKey(const Key('room-join-button')));
      await tester.pump();
      await tester.pump();
      expect(r.calls.single.$1, Uri.parse('ws://10.0.0.9:4749/relay'));

      // "Standard: <page>" goes back to the page's own relay.
      await _tapVisible(tester, find.byKey(const Key('relay-change')));
      await tester.pumpAndSettle();
      expect(find.text('Standard: 192.168.1.5:8000'), findsOneWidget);
      await tester.tap(find.byKey(const Key('relay-dialog-default')));
      await tester.pumpAndSettle();
      expect(settings.value, isNull);
      expect(find.text('Relay: 192.168.1.5:8000'), findsOneWidget);
    });

    testWidgets('the host screen shows the same relay line and uses the shared relay', (tester) async {
      await _setSize(tester, const Size(800, 1600));
      final hosts = <Uri>[];
      final settings = RelaySettings.memory(Uri.parse('ws://10.0.0.9:4749/relay'));
      await tester.pumpWidget(localizedApp(WebJoinScreen(
          pageUrl: _page,
          deps: WebJoinDeps(
            joinTransport: _noJoin,
            relaySettings: () => settings,
            relayHost: (config, relay, {required name}) {
              hosts.add(relay);
              return Future.error(const NetException('cannot connect: nope'));
            },
          ))));
      await tester.pump();
      await _tapVisible(tester, find.byKey(const Key('web-host')));
      await tester.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.text('Relay: 10.0.0.9:4749'), findsOneWidget);
      await _tapVisible(tester, find.byKey(const Key('relay-host-start')));
      await tester.pumpAndSettle();
      expect(hosts.single, Uri.parse('ws://10.0.0.9:4749/relay'));
      expect(find.text('Kein Relay erreichbar unter 10.0.0.9:4749.'), findsOneWidget);
    });

    testWidgets('native join tab: no relay yet → "Kein Relay eingerichtet", joining asks for one, then remembers it',
        (tester) async {
      await _setSize(tester, const Size(800, 2000));
      final r = _JoinRecorder();
      final created = CreatedTransports();
      final settings = RelaySettings.memory();
      final deps = PairingDeps(
        discovery: () => FakeDiscovery(),
        hostTransport: (config, {required name, required port, required wsPort}) => Future.error('unused'),
        joinTransport: (host, port, {required name}) => Future.error('unused'),
        relayJoin: r.join,
        localAddresses: () async => const [],
        deviceName: () => 'Pixel',
        relaySettings: () => settings,
      );
      await tester.pumpWidget(localizedApp(PairingScreen(deps: deps)));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.login));
      await tester.pump();
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.text('Kein Relay eingerichtet – Adresse eingeben'), findsOneWidget);
      // The groups, in order: relay (room code) first, direct second.
      final relayY = tester.getTopLeft(find.byKey(const Key('relay-group-title'))).dy;
      final directY = tester.getTopLeft(find.byKey(const Key('pair-direct-title'))).dy;
      expect(relayY, lessThan(directY));
      expect(find.text('Direkt mit einem Gerät verbinden'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('room-code')), 'K7Q2M');
      await _tapVisible(tester, find.byKey(const Key('room-join-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('relay-dialog-address')), findsOneWidget);
      expect(find.byKey(const Key('relay-dialog-default')), findsNothing); // an app has no default
      await tester.enterText(find.byKey(const Key('relay-dialog-address')), '192.168.1.20:4749');
      await tester.tap(find.byKey(const Key('relay-dialog-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(r.calls.single, (Uri.parse('ws://192.168.1.20:4749/relay'), 'K7Q2M', 'Pixel'));
      expect(settings.value, Uri.parse('ws://192.168.1.20:4749/relay'));
      expect(find.text('Relay: 192.168.1.20:4749'), findsOneWidget);
      expect(find.byKey(const Key('room-error')), findsOneWidget);
      await unmountAndSettleSockets(tester, created);
    });
  });

  group('?room= at startup', () {
    Future<_JoinRecorder> start(WidgetTester tester, String query) async {
      final r = _JoinRecorder();
      await tester.pumpWidget(KlunkiApp(
        localeController: LocaleController.memory(testLocale),
        pageUrl: Uri.parse('http://192.168.1.5:8000/?$query'),
        webJoinDeps: WebJoinDeps(joinTransport: _noJoin, relayJoin: r.join),
      ));
      await tester.pump(); // post-frame: push
      await tester.pumpAndSettle();
      return r;
    }

    testWidgets('opens the room join, asks for the name, then joins the page relay', (tester) async {
      final r = await start(tester, 'room=k7q2m');
      expect(find.byType(WebJoinScreen), findsOneWidget);
      expect(find.byKey(const Key('player-name-dialog')), findsOneWidget);
      expect(r.calls, isEmpty);
      await tester.tap(find.byKey(const Key('player-name-ok')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const Key('room-code'))).controller!.text, 'K7Q2M');
      expect(r.calls.single, (_pageRelay, 'K7Q2M', 'Browser'));
      expect(find.byKey(const Key('room-error')), findsOneWidget);
    });

    testWidgets('&relay= picks another relay (and shows it on the relay line)', (tester) async {
      final r = await start(tester, 'room=K7Q2M&relay=10.0.0.9:4749');
      await tester.tap(find.byKey(const Key('player-name-ok')));
      await tester.pumpAndSettle();
      expect(r.calls.single.$1, Uri.parse('ws://10.0.0.9:4749/relay'));
      expect(find.text('Relay: 10.0.0.9:4749'), findsOneWidget);
    });

    testWidgets('an invalid code is prefilled but not joined', (tester) async {
      final r = await start(tester, 'room=OOPS0');
      await tester.tap(find.byKey(const Key('player-name-ok')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const Key('room-code'))).controller!.text, 'OOPS0');
      expect(r.calls, isEmpty);
    });
  });

  group('host waiting screen', () {
    testWidgets('shows the grouped code, QR and link; the guest arrives and the game starts', (tester) async {
      await _setSize(tester, const Size(800, 1600));
      final server = await _startRelay(tester);
      final created = CreatedTransports();
      final page = Uri.parse('http://127.0.0.1:${server.port}/');
      await tester.pumpWidget(localizedApp(RelayHostScreen(
        hostTransport: (config, relay, {required name}) => relayHost(created, config, relay, name: name),
        defaultRelay: relayUriForPage(page),
        pageUrl: page,
        seed: () => 7,
        deviceName: () => 'Ada',
      )));
      await tester.pump();
      await tester.tap(find.byKey(const Key('relay-host-start')));
      await pumpUntil(tester, () => find.byKey(const Key('relay-host-waiting')).evaluate().isNotEmpty,
          what: 'waiting screen');
      final host = created.hosts.single;
      final code = host.roomCode!;
      expect(created.relayHostCalls.single, Uri.parse('ws://127.0.0.1:${server.port}/relay'));
      final shown = tester.widget<Text>(find.byKey(const Key('relay-room-code'))).data!;
      expect(shown, '${code.substring(0, 3)} ${code.substring(3)}');
      final link = tester.widget<SelectableText>(find.byKey(const Key('relay-link'))).data!;
      expect(link, 'http://127.0.0.1:${server.port}/?room=$code');
      expect(tester.widget<KlunkiQrCode>(find.byKey(const Key('relay-qr'))).data, link);
      expect(find.text('Relay: 127.0.0.1:${server.port}'), findsOneWidget);
      expect(find.text('Ada hostet 4 Gewinnt'), findsOneWidget);
      expect(find.textContaining('Öffne den Link auf dem zweiten Gerät'), findsOneWidget);

      // The guest types the code as shown, with the space.
      await tester.runAsync(() => relayJoin(created, host.relayUrl!, shown, name: 'Bea'));
      await pumpUntil(tester, () => find.byType(Connect4Screen).evaluate().isNotEmpty, what: 'game starts');
      await tester.pump();
      expect(find.byType(NetworkGameSession), findsOneWidget);
      expect(netStatus('Du (Ada, X) · Gegner: Bea (O)'), findsOneWidget);
      await unmountAndSettleSockets(tester, created);
      await tester.pump(const Duration(seconds: 6));
    }, timeout: _timeout);

    testWidgets('a page without a relay: clear message with the start command', (tester) async {
      await _setSize(tester, const Size(800, 1600));
      // A free port nobody listens on.
      final probe = (await tester.runAsync(() => ServerSocket.bind(InternetAddress.loopbackIPv4, 0)))!;
      final port = probe.port;
      await tester.runAsync(probe.close);
      final created = CreatedTransports();
      final page = Uri.parse('http://127.0.0.1:$port/');
      await tester.pumpWidget(localizedApp(RelayHostScreen(
        hostTransport: (config, relay, {required name}) => relayHost(created, config, relay, name: name),
        defaultRelay: relayUriForPage(page),
        pageUrl: page,
      )));
      await tester.pump();
      await tester.tap(find.byKey(const Key('relay-host-start')));
      await pumpUntil(tester, () => find.byKey(const Key('relay-host-error')).evaluate().isNotEmpty,
          what: 'error shown');
      expect(tester.widget<Text>(find.byKey(const Key('relay-host-error'))).data,
          'Kein Relay erreichbar unter 127.0.0.1:$port.');
      expect(find.byKey(const Key('relay-start-command')), findsOneWidget);
      expect(find.byKey(const Key('relay-host-waiting')), findsNothing);
    }, timeout: _timeout);

    testWidgets('the relay stops while waiting: room lost, back to the setup', (tester) async {
      await _setSize(tester, const Size(800, 1600));
      final server = await _startRelay(tester);
      final created = CreatedTransports();
      final page = Uri.parse('http://127.0.0.1:${server.port}/');
      await tester.pumpWidget(localizedApp(RelayHostScreen(
        hostTransport: (config, relay, {required name}) => relayHost(created, config, relay, name: name),
        defaultRelay: relayUriForPage(page),
        pageUrl: page,
      )));
      await tester.pump();
      await tester.tap(find.byKey(const Key('relay-host-start')));
      await pumpUntil(tester, () => find.byKey(const Key('relay-host-waiting')).evaluate().isNotEmpty,
          what: 'waiting screen');
      await tester.runAsync(server.close);
      await pumpUntil(tester, () => find.byKey(const Key('relay-host-error')).evaluate().isNotEmpty,
          what: 'room lost');
      expect(tester.widget<Text>(find.byKey(const Key('relay-host-error'))).data,
          'Die Verbindung zum Relay ist abgebrochen.');
      expect(find.byKey(const Key('relay-host-start')), findsOneWidget);
      await unmountAndSettleSockets(tester, created);
    }, timeout: _timeout);
  });

  testWidgets('end to end: browser hosts via relay, browser joins by code, Four in a Row to the result',
      (tester) async {
    await _setSize(tester, const Size(1800, 1600));
    final server = await _startRelay(tester);
    final created = CreatedTransports();
    final page = Uri.parse('http://127.0.0.1:${server.port}/');
    const hostKey = Key('device-a');
    const guestKey = Key('device-b');
    Finder on(Key device, Finder f) => find.descendant(of: find.byKey(device), matching: f);
    bool has(Key device, Finder f) => on(device, f).evaluate().isNotEmpty;

    Widget browser(String name) {
      final deps = WebJoinDeps(
        joinTransport: _noJoin,
        relayHost: (config, relay, {required name}) => relayHost(created, config, relay, name: name),
        relayJoin: (relay, code, {required name}) => relayJoin(created, relay, code, name: name),
        seed: () => 3,
        deviceName: () => name,
      );
      return localizedApp(
        debugShowCheckedModeBanner: false,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open'),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => WebJoinScreen(pageUrl: page, deps: deps))),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [
        Expanded(child: KeyedSubtree(key: hostKey, child: browser('Ada'))),
        Expanded(child: KeyedSubtree(key: guestKey, child: browser('Bea'))),
      ]),
    ));
    addTearDown(() => unmountAndSettleSockets(tester, created));

    // Browser A: Über WLAN spielen → Spiel hosten → 4 Gewinnt → room code.
    await tester.tap(on(hostKey, find.byKey(const Key('open'))));
    await tester.pumpAndSettle();
    await tester.tap(on(hostKey, find.byKey(const Key('web-host'))));
    await tester.pumpAndSettle();
    await tester.tap(on(hostKey, find.byKey(const Key('relay-game-connect4'))));
    await tester.pump();
    await tester.tap(on(hostKey, find.byKey(const Key('relay-host-start'))));
    await pumpUntil(tester, () => has(hostKey, find.byKey(const Key('relay-room-code'))), what: 'room code');
    final shown = tester.widget<Text>(on(hostKey, find.byKey(const Key('relay-room-code')))).data!;

    // Browser B types the code in lower case.
    await tester.tap(on(guestKey, find.byKey(const Key('open'))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // route transition (A's spinner never settles)
    await tester.enterText(on(guestKey, find.byKey(const Key('room-code'))), shown.toLowerCase());
    await tester.tap(on(guestKey, find.byKey(const Key('room-join-button'))));
    await pumpUntil(tester, () => has(hostKey, find.byType(Connect4Screen)) && has(guestKey, find.byType(Connect4Screen)),
        what: 'both on the game screen');
    await tester.pump();
    expect(created.relayJoinCalls.single, (Uri.parse('ws://127.0.0.1:${server.port}/relay'), shown.replaceAll(' ', '')));
    expect(on(hostKey, netStatus('Du (Ada, X) · Gegner: Bea (O)')), findsOneWidget);
    expect(on(guestKey, netStatus('Du (Bea, O) · Gegner: Ada (X)')), findsOneWidget);

    Connect4Cell cell(Key d, int r, int c) => tester.widget<Connect4Cell>(on(d, find.byKey(Key('c4-cell-$r-$c'))));
    GameScreen screen(Key d) => tester.widget<GameScreen>(on(d, find.byType(GameScreen)));

    // X: column 1 four times, O: column 2 three times → X wins.
    for (var i = 0; i < 7; i++) {
      final x = i.isEven;
      final device = x ? hostKey : guestKey;
      final other = x ? guestKey : hostKey;
      final col = x ? 0 : 1;
      final row = i ~/ 2;
      await tester.tap(on(device, find.byKey(Key('c4-column-$col'))));
      await pumpUntil(tester, () => cell(other, row, col).owner == (x ? Player.a : Player.b),
          what: 'move $i reaches the other browser');
      await tester.pump(connect4DropDuration + const Duration(milliseconds: 50));
    }
    expect(screen(hostKey).controller.game.isOver, isTrue);
    expect(screen(guestKey).controller.game.isOver, isTrue);
    expect(screen(hostKey).controller.moves.length, 7);
    await pumpUntil(tester, () => has(hostKey, find.byKey(resultDialog)) && has(guestKey, find.byKey(resultDialog)),
        what: 'result on both');
    expect(on(hostKey, find.textContaining('Du gewinnst')), findsWidgets);
    expect(on(guestKey, find.textContaining('Ada (X) gewinnt')), findsWidgets);

    // The host leaves ("Menü" in its result dialog): the guest is told the
    // room is closed, without a pointless "Neu verbinden".
    await tester.tap(on(hostKey, find.descendant(of: find.byKey(resultDialog), matching: find.byType(TextButton))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(has(hostKey, find.byType(NetworkGameSession)), isFalse);
    await pumpUntil(tester, () => has(guestKey, find.byKey(const Key('net-banner'))), what: 'guest banner');
    expect(on(guestKey, find.textContaining('Der Host hat den Raum verlassen')), findsOneWidget);
    expect(on(guestKey, find.byKey(const Key('net-reconnect'))), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  }, timeout: _timeout);
}
