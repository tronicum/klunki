// KLD-054: WebSocket guests (the browser PWA) against a native host. The host
// runs the same protocol over TCP (NDJSON) and WebSocket (one JSON message
// per text frame); these tests use dart:io's WebSocket as the guest, which
// shares everything but the socket with the browser implementation.
@Timeout(Duration(seconds: 30))
library;

import 'dart:convert';
import 'dart:io';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:test/test.dart';

import 'e2e_support.dart';
import 'support.dart';

/// A hand-driven WebSocket peer: sends raw frames, records decoded messages.
class RawWsPeer {
  final WebSocket ws;
  final List<Map<String, dynamic>> received = [];
  bool closed = false;
  int _cursor = 0;

  RawWsPeer(this.ws) {
    ws.listen(
      (frame) => received.add(jsonDecode(frame as String) as Map<String, dynamic>),
      onError: (_) => closed = true,
      onDone: () => closed = true,
    );
  }

  static Future<RawWsPeer> connect(int port) async =>
      RawWsPeer(await WebSocket.connect(webSocketUri(loopback.address, port).toString()));

  void frame(Object raw) => ws.add(raw);
  void send(String type, [Map<String, dynamic> fields = const {}, int v = protocolVersion]) =>
      frame(jsonEncode({'type': type, 'v': v, ...fields}));

  Future<Map<String, dynamic>> next(String type) async {
    while (true) {
      await until(() => _cursor < received.length);
      final m = received[_cursor++];
      if (m['type'] == type) return m;
    }
  }
}

Future<KlunkiGuest> joinWs(int wsPort, {String name = 'Web', String? token}) =>
    KlunkiGuest.connectWebSocket(webSocketUri(loopback.address, wsPort), name: name, token: token);

void main() {
  group('Mühle, TCP host vs WebSocket guest', () {
    late MuehleMatch match;
    tearDown(() => match.close());

    test('the Zwickmühle demo is played to the end, identically on both sides', () async {
      match = await MuehleMatch.start(webSocket: true);
      expect(match.android.guest!.transport, 'ws');
      expect(match.android.guest!.webSocketUrl!.scheme, 'ws');
      await match.playUntil();
      match.assertFinished();
    });

    test('reconnect over WebSocket: rejoin with the token (fresh instance) and reconnect() with replay', () async {
      match = await MuehleMatch.start(webSocket: true, seed: 5);
      final ios = match.ios, android = match.android;
      final host = ios.host!;

      // Drop 1 while the guest owes a removal; a new app instance rejoins.
      await match.playUntil(13);
      expect(android.game.pendingRemoval, isTrue);
      final token = android.guest!.token!;
      match.proxy.cut();
      await until(() => !host.guestConnected && !android.guest!.connected);
      expect(await android.guest!.submit(match.scriptMoves[13]), 'not connected');
      await android.guest!.close();
      android.attach(await KlunkiGuest.connectWebSocket(webSocketUri(loopback.address, match.proxy.port),
          name: 'someone else', token: token, pingInterval: pingInterval, timeout: netTimeout));
      await until(() => host.guestConnected);
      expect(ios.events.whereType<PeerConnected>().last.reconnect, isTrue);
      expect(android.guest!.transport, 'ws');
      match.assertInSync('after rejoin 1');
      expect(android.game.pendingRemoval, isTrue, reason: 'the snapshot restores the owed removal');

      // Drop 2: the host plays while the guest is away; reconnect() replays it.
      await match.playUntil(21);
      expect(match.nextMover, ios);
      match.proxy.cut();
      await until(() => !host.guestConnected && !android.guest!.connected);
      await match.step();
      expect(android.moves, hasLength(21));
      await android.guest!.reconnect();
      await until(() => host.guestConnected && android.events.whereType<Resynced>().isNotEmpty);
      expect(android.events.whereType<Resynced>().single.moves, 22);
      expect(android.events.whereType<MoveAccepted>().last.index, 21, reason: 'the missed move is emitted');
      match.assertInSync('after rejoin 2');

      await match.playUntil();
      match.assertFinished();
      expect(ios.events.whereType<PeerConnected>().map((e) => e.reconnect), [false, true, true]);
      expect(match.proxy.connections, 3);
    });
  });

  group('mixed TCP and WebSocket guests', () {
    test('a WebSocket guest is refused while a TCP guest holds the session', () async {
      final host = await startHost(const GameConfig('connect4'));
      final tcp = await joinHost(host.port, name: 'Bea');
      await expectLater(joinWs(host.wsPort!, name: 'Mallory'),
          throwsA(isA<NetException>().having((e) => e.message, 'message', contains('session full'))));
      expect(tcp.connected, isTrue);
      expect(host.submitLocal({'col': 0}), isNull);
      await until(() => tcp.moves.length == 1);
      await tcp.close();
      await host.close();
    });

    test('KLD-071: a WebSocket intruder with the guest\'s name is refused, the token gets back in', () async {
      final host = await startHost(const GameConfig('connect4'));
      final web = await joinWs(host.wsPort!, name: 'Ben');
      await expectLater(joinWs(host.wsPort!, name: 'Ben'),
          throwsA(isA<NetException>().having((e) => e.message, 'message', contains('session full'))));
      expect(web.connected, isTrue);
      final token = web.token!;
      await web.close();
      await until(() => !host.guestConnected);
      await expectLater(joinWs(host.wsPort!, name: 'Ben'),
          throwsA(isA<NetException>().having((e) => e.message, 'message', contains('session full'))));
      final again = await joinWs(host.wsPort!, name: 'Ben', token: token);
      expect(again.connected, isTrue);
      await again.close();
      await host.close();
    });

    test('a TCP guest is refused while a WebSocket guest holds the session', () async {
      final host = await startHost(const GameConfig('connect4'));
      final ws = await joinWs(host.wsPort!, name: 'Web');
      await expectLater(joinHost(host.port, name: 'Mallory'),
          throwsA(isA<NetException>().having((e) => e.message, 'message', contains('session full'))));
      expect(ws.connected, isTrue);
      await ws.close();
      await host.close();
    });

    test('the joined guest can switch from TCP to WebSocket with its token', () async {
      final host = await startHost(const GameConfig('connect4'));
      final events = <NetEvent>[];
      host.events.listen(events.add);
      final tcp = await joinHost(host.port, name: 'Bea');
      expect(host.submitLocal({'col': 3}), isNull);
      await until(() => tcp.moves.length == 1);

      final ws = await joinWs(host.wsPort!, name: 'Bea on the web', token: tcp.token);
      expect(ws.moves, [
        {'col': 3}
      ]);
      expect(ws.me, Player.b);
      await until(() => !tcp.connected);
      expect(await ws.submit({'col': 4}), isNull);
      expect(host.moves, hasLength(2));
      expect(events.whereType<PeerConnected>().map((e) => e.reconnect), [false, true]);
      await tcp.close();
      await ws.close();
      await host.close();
    });
  });

  group('protocol over WebSocket', () {
    test('handshake and moves: one JSON message per text frame', () async {
      final host = await startHost(const GameConfig('connect4'));
      final peer = await RawWsPeer.connect(host.wsPort!);
      peer.send('hello', guestHello('Raw'));
      expect(await peer.next('hello'), {
        'type': 'hello',
        'v': protocolVersion,
        ...hostHello(const GameConfig('connect4'), name: 'Host'),
        'build': '',
      });
      final welcome = await peer.next('welcome');
      expect(welcome['config'], {'game': 'connect4', 'seed': 0});
      expect(welcome['you'], 'b');
      host.submitLocal({'col': 2});
      expect(await peer.next('accepted'), {'type': 'accepted', 'v': protocolVersion, 'index': 0, 'player': 'a', 'move': {'col': 2}});
      peer.send('move', {'index': 1, 'move': {'col': 9}});
      expect((await peer.next('rejected'))['reason'], 'illegal move');
      await peer.ws.close();
      await host.close();
    });

    test('protocol version mismatch: an old (v1) guest is refused with a clear error', () async {
      final host = await startHost(const GameConfig('connect4'));
      final v1 = await RawWsPeer.connect(host.wsPort!);
      v1.send('hello', {'role': 'guest', 'name': 'Old', 'protocol': 1}, 1);
      // KLD-085: the error comes in the old peer's envelope version, so it
      // can read it.
      final error = await v1.next('error');
      expect(error['v'], 1);
      expect(error['code'], 'incompatible-protocol');
      expect(error['message'], contains('please update this app (browser: reload the page)'));
      await until(() => v1.closed);

      final p2 = await RawWsPeer.connect(host.wsPort!);
      p2.send('hello', {'role': 'guest', 'name': 'Old', 'protocol': 1});
      expect((await p2.next('error'))['code'], 'incompatible-protocol');
      await until(() => p2.closed);
      expect(host.guestConnected, isFalse);

      // The session is still open for a compatible guest.
      final ok = await joinWs(host.wsPort!);
      expect(ok.connected, isTrue);
      await ok.close();
      await host.close();
    });

    test('a WebSocket guest refuses a host speaking another protocol version', () async {
      final fake = await HttpServer.bind(loopback, 0);
      fake.listen((req) async {
        final peer = RawWsPeer(await WebSocketTransformer.upgrade(req));
        await peer.next('hello');
        peer.send('hello', {'role': 'host', 'name': 'Old', 'protocol': 1}, 1);
      });
      await expectLater(
          joinWs(fake.port),
          throwsA(isA<NetException>()
              .having((e) => e.mismatch?.kind, 'kind', Incompatibility.protocol)
              .having((e) => e.mismatch?.peer, 'peer', PeerAge.older)));
      await fake.close(force: true);
    });

    test('binary frames and malformed text are protocol errors', () async {
      final host = await startHost(const GameConfig('connect4'));
      final binary = await RawWsPeer.connect(host.wsPort!);
      binary.frame(utf8.encode('{"type":"hello","v":1}'));
      expect((await binary.next('error'))['message'], 'malformed input (binary frame)');
      await until(() => binary.closed);
      for (final bad in ['garbage', '[1,2]', '{"v":1}']) {
        final peer = await RawWsPeer.connect(host.wsPort!);
        peer.frame(bad);
        expect((await peer.next('error'))['message'], startsWith('malformed input'), reason: bad);
        await until(() => peer.closed);
      }
      await host.close();
    });

    test('bye from the host reaches a WebSocket guest', () async {
      final host = await startHost(const GameConfig('connect4'));
      final guest = await joinWs(host.wsPort!);
      final events = <NetEvent>[];
      guest.events.listen(events.add);
      await host.close(reason: 'bedtime');
      await until(() => events.whereType<PeerDisconnected>().isNotEmpty);
      expect(events.whereType<PeerDisconnected>().single.reason, contains('bedtime'));
      await guest.close();
    });

    test('the host detects a silent WebSocket guest (ping timeout)', () async {
      final host = await startHost(const GameConfig('connect4'),
          pingInterval: const Duration(milliseconds: 20), timeout: const Duration(milliseconds: 150));
      final events = <NetEvent>[];
      host.events.listen(events.add);
      final peer = await RawWsPeer.connect(host.wsPort!); // never answers ping
      peer.send('hello', guestHello('Raw'));
      await peer.next('welcome');
      await until(() => events.whereType<PeerDisconnected>().isNotEmpty);
      expect(events.whereType<PeerDisconnected>().single.timedOut, isTrue);
      await host.close();
    });
  });

  group('WebSocket listener', () {
    test('a plain HTTP request to the WebSocket port gets 426 Upgrade Required', () async {
      final host = await startHost(const GameConfig('connect4'));
      final client = HttpClient();
      final res = await (await client.get(loopback.address, host.wsPort!, '/')).close();
      expect(res.statusCode, HttpStatus.upgradeRequired);
      expect(await res.transform(utf8.decoder).join(), contains('WebSocket'));
      client.close(force: true);
      await host.close();
    });

    test('wsPort: null hosts TCP only', () async {
      final host = await KlunkiHost.start(const GameConfig('connect4'), address: loopback, wsPort: null);
      expect(host.wsPort, isNull);
      final guest = await joinHost(host.port);
      expect(guest.transport, 'tcp');
      await guest.close();
      await host.close();
    });

    test('a taken WebSocket port fails start and leaves nothing bound', () async {
      final blocker = await ServerSocket.bind(loopback, 0);
      final tcpPort = (await ServerSocket.bind(loopback, 0).then((s) async {
        final p = s.port;
        await s.close();
        return p;
      }));
      await expectLater(
          KlunkiHost.start(const GameConfig('connect4'), address: loopback, port: tcpPort, wsPort: blocker.port),
          throwsA(isA<SocketException>()));
      final rebound = await ServerSocket.bind(loopback, tcpPort); // the TCP port was released
      await rebound.close();
      await blocker.close();
    });

    test('connectWebSocket: bad URLs and unreachable hosts', () async {
      await expectLater(KlunkiGuest.connectWebSocket(Uri.parse('http://127.0.0.1:4748')), throwsArgumentError);
      final closed = await ServerSocket.bind(loopback, 0);
      final port = closed.port;
      await closed.close();
      await expectLater(joinWs(port), throwsA(isA<NetException>()));
    });

    test('webSocketUri and the default ports', () {
      expect(webSocketUri('192.168.1.20', defaultWebSocketPort).toString(), 'ws://192.168.1.20:4748');
      expect(defaultTcpPort, 4747);
    });
  });
}
