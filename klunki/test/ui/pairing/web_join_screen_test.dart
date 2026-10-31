// KLD-055: the browser (PWA) join screen. Join-only, manual entry in every
// accepted form, `?join=` at startup, errors/timeouts with the browser hints,
// and a real loopback game: a native host (PairingScreen, TCP + WebSocket)
// against the web-style join through `NetworkTransport.joinWebSocket`.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/net/join_payload.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/connect4/connect4_board.dart';
import 'package:klunki/ui/games/connect4_screen.dart';
import 'package:klunki/ui/menu_screen.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import 'pairing_test_utils.dart';

const _timeout = Timeout(Duration(seconds: 45));

/// A join factory that records the URL and name and fails (no network).
class _Recorder {
  final List<(Uri, String)> calls = [];
  Future<NetworkTransport> join(Uri url, {required String name}) {
    calls.add((url, name));
    return Future.error(StateError('connection refused'));
  }
}

Future<void> _pumpScreen(WidgetTester tester, WebJoinScreen screen) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(localizedApp(screen));
  await tester.pump();
}

Future<void> _enterAndConnect(WidgetTester tester, String input) async {
  await tester.enterText(find.byKey(const Key('web-join-address')), input);
  await tester.tap(find.byKey(const Key('web-join-connect')));
  await tester.pump();
  await tester.pump();
}

Uri _ws(String host, int port) => Uri(scheme: 'ws', host: host, port: port);

void main() {
  group('web join screen', () {
    testWidgets('join-only: no host tab, no discovery list; name defaults to "Browser"', (tester) async {
      final r = _Recorder();
      await _pumpScreen(tester, WebJoinScreen(deps: WebJoinDeps(joinTransport: r.join)));
      expect(find.text('Über WLAN spielen'), findsOneWidget);
      expect(find.text('Hosten'), findsNothing);
      expect(find.byKey(const Key('pair-host-panel')), findsNothing);
      expect(find.text('Suche nach Spielen…'), findsNothing);
      expect(tester.widget<TextField>(find.byKey(const Key('web-join-name'))).controller!.text, 'Browser');
      expect(find.textContaining('Browser-Port (WebSocket)'), findsOneWidget, reason: 'helper explains the port');
      expect(find.byKey(const Key('web-join-https')), findsNothing);
    });

    testWidgets('every input form connects to the right ws:// URL', (tester) async {
      final r = _Recorder();
      await _pumpScreen(tester, WebJoinScreen(deps: WebJoinDeps(joinTransport: r.join)));
      final link = const JoinPayload(host: '10.0.0.7', port: 4747, name: 'iPad', gameId: 'connect4', wsPort: 4800)
          .format();
      final cases = <String, Uri>{
        '192.168.1.20': _ws('192.168.1.20', 4748),
        '192.168.1.20:5000': _ws('192.168.1.20', 5000),
        link: _ws('10.0.0.7', 4800),
        'klunki://join?h=10.0.0.8&p=4747&v=3': _ws('10.0.0.8', 4748),
        'ws://10.0.0.9:4801': _ws('10.0.0.9', 4801),
      };
      for (final MapEntry(key: input, value: uri) in cases.entries) {
        await _enterAndConnect(tester, input);
        expect(r.calls.last, (uri, 'Browser'), reason: input);
        expect(find.byKey(const Key('web-join-error')), findsOneWidget, reason: 'the recorder fails');
      }
      expect(r.calls, hasLength(cases.length));
    });

    testWidgets('a klunki:// link shows the host name and game before connecting', (tester) async {
      final r = _Recorder();
      await _pumpScreen(tester, WebJoinScreen(deps: WebJoinDeps(joinTransport: r.join)));
      await tester.enterText(find.byKey(const Key('web-join-address')),
          const JoinPayload(host: '10.0.0.7', name: 'Stefans iPhone', gameId: 'muehle', wsPort: 4748).format());
      await tester.pump();
      expect(find.text('Stefans iPhone · Mühle · ws://10.0.0.7:4748'), findsOneWidget);
    });

    testWidgets('invalid input shows the error and does not connect', (tester) async {
      final r = _Recorder();
      await _pumpScreen(tester, WebJoinScreen(deps: WebJoinDeps(joinTransport: r.join)));
      for (final bad in ['not an address', 'wss://10.0.0.7:4748', '10.0.0.7:99999']) {
        await _enterAndConnect(tester, bad);
        expect(find.textContaining('Ungültige Adresse'), findsOneWidget, reason: bad);
      }
      expect(r.calls, isEmpty);
    });

    testWidgets('a failed join shows the reason and the browser hints; the edited name is sent', (tester) async {
      final r = _Recorder();
      await _pumpScreen(tester, WebJoinScreen(deps: WebJoinDeps(joinTransport: r.join)));
      await tester.enterText(find.byKey(const Key('web-join-name')), 'Laptop');
      await _enterAndConnect(tester, '192.168.1.20');
      expect(r.calls.single, (_ws('192.168.1.20', 4748), 'Laptop'));
      final error = tester.widget<Text>(find.byKey(const Key('web-join-error'))).data!;
      expect(error, contains('Verbindung zu 192.168.1.20:4748 fehlgeschlagen'));
      expect(error, contains('connection refused'));
      expect(error, contains('selben WLAN'));
      expect(error, contains('http://'));
      expect(error, contains('Browser-Unterstützung'));
    });

    testWidgets('a hanging connect times out with the hints; cancel is possible meanwhile', (tester) async {
      final pending = Completer<NetworkTransport>();
      await _pumpScreen(
        tester,
        WebJoinScreen(
          deps: WebJoinDeps(
            joinTransport: (url, {required name}) => pending.future,
            joinTimeout: const Duration(seconds: 3),
          ),
        ),
      );
      await _enterAndConnect(tester, '10.0.0.7');
      expect(find.byKey(const Key('web-join-progress')), findsOneWidget);
      expect(find.text('Verbinde mit 10.0.0.7:4748…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.byKey(const Key('web-join-progress')), findsNothing);
      final error = tester.widget<Text>(find.byKey(const Key('web-join-error'))).data!;
      expect(error, contains('Zeitüberschreitung'));
      expect(error, contains('nicht über https://'));
    });

    testWidgets('an https page warns that ws:// is blocked', (tester) async {
      final r = _Recorder();
      await _pumpScreen(
          tester, WebJoinScreen(deps: WebJoinDeps(joinTransport: r.join), pageUrl: Uri.parse('https://x.example/')));
      expect(find.byKey(const Key('web-join-https')), findsOneWidget);
    });
  });

  group('?join= at startup', () {
    testWidgets('opens the join screen over the menu, asks for the name once, then connects', (tester) async {
      final r = _Recorder();
      final link = const JoinPayload(host: '10.0.0.7', port: 4747, name: 'iPad', wsPort: 4800).format();
      await tester.pumpWidget(KlunkiApp(
        localeController: LocaleController.memory(testLocale),
        pageUrl: Uri.parse('http://192.168.1.5:8000/?join=${Uri.encodeQueryComponent(link)}&lang=de'),
        webJoinDeps: WebJoinDeps(joinTransport: r.join),
      ));
      await tester.pump(); // post-frame: push
      await tester.pumpAndSettle();
      expect(find.byType(WebJoinScreen), findsOneWidget);
      // First visit, no saved name: "Wie heißt du?" before connecting (KLD-056).
      expect(find.byKey(const Key('player-name-dialog')), findsOneWidget);
      expect(find.text('Wie heißt du?'), findsOneWidget);
      expect(r.calls, isEmpty);
      expect(tester.widget<TextField>(find.byKey(const Key('player-name-field'))).controller!.text, 'Browser');
      await tester.tap(find.byKey(const Key('player-name-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('player-name-dialog')), findsNothing);
      expect(tester.widget<TextField>(find.byKey(const Key('web-join-address'))).controller!.text, link);
      expect(r.calls.single, (_ws('10.0.0.7', 4800), 'Browser'));
      expect(find.byKey(const Key('web-join-error')), findsOneWidget);

      // Back goes to the menu.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(MenuScreen), findsOneWidget);
      expect(find.byType(WebJoinScreen), findsNothing);
    });

    testWidgets('without ?join= the menu stays put', (tester) async {
      final r = _Recorder();
      await tester.pumpWidget(KlunkiApp(
        localeController: LocaleController.memory(testLocale),
        pageUrl: Uri.parse('http://192.168.1.5:8000/?lang=de'),
        webJoinDeps: WebJoinDeps(joinTransport: r.join),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(WebJoinScreen), findsNothing);
      expect(r.calls, isEmpty);
    });
  });

  testWidgets('loopback: native host (TCP + WebSocket) vs the web join over joinWebSocket, Four in a Row',
      (tester) async {
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const hostKey = Key('device-host');
    const webKey = Key('device-web');
    Finder on(Key device, Finder f) => find.descendant(of: find.byKey(device), matching: f);
    bool has(Key device, Finder f) => on(device, f).evaluate().isNotEmpty;

    final created = CreatedTransports();
    final hostDeps = testDeps(discovery: FakeDiscovery(), created: created, name: 'Host-iPhone');
    final webDeps = WebJoinDeps(
      joinTransport: (url, {required name}) => loopbackWebJoin(created, url, name: name),
    );
    final web = localizedApp(
      debugShowCheckedModeBanner: false,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('open-web-join'),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WebJoinScreen(deps: webDeps))),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [
        Expanded(child: KeyedSubtree(key: hostKey, child: launcherApp(hostDeps))),
        Expanded(child: KeyedSubtree(key: webKey, child: web)),
      ]),
    ));
    addTearDown(() => unmountAndSettleSockets(tester, created));

    // Native host: Four in a Row (the default first game), TCP + WebSocket.
    await tester.tap(on(hostKey, find.byKey(const Key('open-pairing'))));
    await tester.pumpAndSettle();
    await tester.tap(on(hostKey, find.byKey(const Key('pair-game-connect4'))));
    await tester.pump();
    await tester.tap(on(hostKey, find.byKey(const Key('pair-host-start'))));
    await pumpUntil(tester, () => has(hostKey, find.byKey(const Key('pair-link'))), what: 'host shows the link');
    final host = created.hosts.single;
    final link = tester.widget<SelectableText>(on(hostKey, find.byKey(const Key('pair-link')))).data!;
    expect(link, contains('w=${host.wsPort}'));

    // Browser: paste the host's link.
    await tester.tap(on(webKey, find.byKey(const Key('open-web-join'))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // route transition (the host's spinner never settles)
    // An Arabic name in the German UI (KLD-056).
    await tester.enterText(on(webKey, find.byKey(const Key('web-join-name'))), 'علی');
    await tester.enterText(on(webKey, find.byKey(const Key('web-join-address'))), link);
    await tester.tap(on(webKey, find.byKey(const Key('web-join-connect'))));

    await pumpUntil(
        tester, () => has(hostKey, find.byType(Connect4Screen)) && has(webKey, find.byType(Connect4Screen)),
        what: 'both on the game screen');
    await tester.pump();
    expect(created.webJoinCalls.single, Uri(scheme: 'ws', host: '192.168.0.10', port: host.wsPort));
    expect(on(webKey, find.byType(NetworkGameSession)), findsOneWidget);
    expect(on(webKey, netStatus('Du (\u2068علی\u2069, O) · Gegner: Host-iPhone (X)')), findsOneWidget);
    expect(on(hostKey, netStatus('Du (Host-iPhone, X) · Gegner: \u2068علی\u2069 (O)')), findsOneWidget);
    expect(on(hostKey, find.text('Du bist am Zug (X)')), findsOneWidget);
    expect(on(webKey, find.text('Warte auf Host-iPhone (X)…')), findsOneWidget);

    Connect4Cell cell(Key d, int r, int c) => tester.widget<Connect4Cell>(on(d, find.byKey(Key('c4-cell-$r-$c'))));
    GameScreen screen(Key d) => tester.widget<GameScreen>(on(d, find.byType(GameScreen)));

    await tester.tap(on(hostKey, find.byKey(const Key('c4-column-3'))));
    await pumpUntil(tester, () => cell(webKey, 0, 3).owner == Player.a, what: 'X move in the browser');
    await tester.pump(connect4DropDuration + const Duration(milliseconds: 50));

    await tester.tap(on(webKey, find.byKey(const Key('c4-column-4'))));
    await pumpUntil(tester, () => cell(hostKey, 0, 4).owner == Player.b, what: 'O move on the host');
    await tester.pump(connect4DropDuration + const Duration(milliseconds: 50));
    expect(screen(hostKey).controller.moves.length, 2);
    expect(screen(webKey).controller.moves.length, 2);

    // The browser leaves: the host sees the banner.
    await tester.tap(on(webKey, find.byType(BackButton)));
    await tester.pumpAndSettle();
    await pumpUntil(tester, () => has(hostKey, find.byKey(const Key('net-banner'))), what: 'host banner');
    expect(on(hostKey, find.textContaining('\u2068علی\u2069 hat das Spiel verlassen')), findsOneWidget,
        reason: 'host disconnect reason: ${host.lastDisconnectReason}');
    expect(created.guests.single.connection.value, NetConnectionState.closed);
  }, timeout: _timeout);

  testWidgets('host falls back to a free WebSocket port when 4748 is busy, keeping 4747', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final created = CreatedTransports();
    final attempts = <(int, int)>[];
    final deps = testDeps(
      discovery: FakeDiscovery(),
      created: created,
      preferredPort: 4747,
      preferredWsPort: 4748,
      hostTransport: (config, {required name, required port, required wsPort}) {
        attempts.add((port, wsPort));
        // Pretend 4748 is taken; 4747 is free but bind 0 for real in the test.
        if (wsPort == 4748) return Future.error(StateError('address in use'));
        return loopbackHost(created, config, name: name, port: 0, wsPort: wsPort);
      },
    );
    await tester.pumpWidget(localizedApp(PairingScreen(deps: deps)));
    await tester.tap(find.byKey(const Key('pair-host-start')));
    await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty,
        what: 'host waiting view');
    expect(attempts, [(4747, 4748), (4747, 0)]);
    expect(created.hosts.single.wsPort, isNot(4748));
    await unmountAndSettleSockets(tester, created);
  }, timeout: _timeout);
}
