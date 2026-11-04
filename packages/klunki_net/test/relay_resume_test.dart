// KLD-120: a host whose connection drops (a locked phone, lost Wi-Fi) keeps
// its game: the relay keeps the room for a grace period and lets the host
// come back with the room's key; a direct (LAN) host listens again on the
// same ports after a pause.
@Timeout(Duration(seconds: 60))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:test/test.dart';

import 'support.dart';

const _ping = Duration(milliseconds: 50);
const _timeout = Duration(seconds: 2);

/// A raw WebSocket client of the relay: records every text frame and the
/// close code.
class _Raw {
  final WebSocket ws;
  final List<String> lines = [];
  bool closed = false;
  int _cursor = 0;

  _Raw(this.ws) {
    ws.listen((f) => lines.add(f as String), onError: (_) => closed = true, onDone: () => closed = true);
  }

  static Future<_Raw> connect(RelayServer relay, String query) async =>
      _Raw(await WebSocket.connect('ws://127.0.0.1:${relay.port}/relay?$query'));

  Future<Map<String, dynamic>> nextJson() async {
    await until(() => _cursor < lines.length);
    return jsonDecode(lines[_cursor++]) as Map<String, dynamic>;
  }

  Future<void> expectClosed() => until(() => closed);
}

Uri _url(RelayServer relay) => Uri.parse('ws://127.0.0.1:${relay.port}/relay');

void main() {
  group('relay server: the host away and back', () {
    late RelayServer relay;
    setUp(() async => relay = await RelayServer.start(
        port: 0, address: loopback, pingInterval: null, hostGrace: const Duration(seconds: 30)));
    tearDown(() => relay.close());

    Future<(_Raw, String, String)> openRoom() async {
      final host = await _Raw.connect(relay, 'create');
      final room = await host.nextJson();
      expect(room['t'], 'relay.room');
      final key = room['key'] as String;
      expect(key, hasLength(32), reason: '16 random bytes as hex');
      return (host, room['code'] as String, key);
    }

    test('a dropped host connection keeps the room; the host comes back with its key', () async {
      final (host, code, key) = await openRoom();
      final guest = await _Raw.connect(relay, 'join=$code');
      expect((await host.nextJson())['t'], 'relay.peer');

      await host.ws.close(4000); // "away", not leaving (a dropped connection)
      await guest.expectClosed(); // its session was with the old connection
      expect(relay.roomCount, 1);

      final early = await _Raw.connect(relay, 'join=$code');
      expect(await early.nextJson(), {
        't': 'relay.error',
        'error': 'host-away',
        'message': 'the host of room $code is away, try again in a moment',
      });
      await early.expectClosed();

      for (final query in ['resume=$code&key=${'0' * 32}', 'resume=$code', 'resume=22222&key=$key']) {
        final wrong = await _Raw.connect(relay, query);
        expect((await wrong.nextJson())['message'], startsWith('no room with code'), reason: query);
        await wrong.expectClosed();
      }

      final back = await _Raw.connect(relay, 'resume=${code.toLowerCase()}&key=$key');
      expect(await back.nextJson(), {'t': 'relay.room', 'code': code, 'key': key});
      final again = await _Raw.connect(relay, 'join=$code');
      expect((await back.nextJson())['t'], 'relay.peer');
      again.ws.add('{"type":"hello"}');
      expect(
          jsonDecode(await (() async {
            await until(() => back.lines.length > 2);
            return back.lines[2];
          })()),
          {'type': 'hello'});

      // A clean close is still the host leaving: the room closes.
      await back.ws.close();
      expect(await again.nextJson(), {'t': 'relay.closed', 'reason': 'host left'});
      await until(() => relay.roomCount == 0);
    });

    test('coming back replaces a host connection that still looks open, and drops the guest', () async {
      final (host, code, key) = await openRoom();
      final guest = await _Raw.connect(relay, 'join=$code');
      expect((await host.nextJson())['t'], 'relay.peer');
      final back = await _Raw.connect(relay, 'resume=$code&key=$key');
      expect((await back.nextJson())['t'], 'relay.room');
      expect(await host.nextJson(), {'t': 'relay.closed', 'reason': 'replaced by a new host connection'});
      await host.expectClosed();
      await guest.expectClosed();
      expect(relay.roomCount, 1);
      // The old connection going away does not touch the room.
      final again = await _Raw.connect(relay, 'join=$code');
      expect((await back.nextJson())['t'], 'relay.peer');
      expect(again.closed, isFalse);
    });

    test('a host that does not come back within the grace period loses the room', () async {
      await relay.close();
      relay = await RelayServer.start(
          port: 0, address: loopback, pingInterval: null, hostGrace: const Duration(milliseconds: 300));
      final (host, code, key) = await openRoom();
      await host.ws.close(4000);
      await until(() => relay.roomCount == 0);
      final late = await _Raw.connect(relay, 'resume=$code&key=$key');
      expect((await late.nextJson())['message'], 'no room with code $code');
    });

    test('hostGrace zero: a dropped host closes the room at once, as before KLD-120', () async {
      await relay.close();
      relay = await RelayServer.start(port: 0, address: loopback, pingInterval: null, hostGrace: Duration.zero);
      final (host, code, _) = await openRoom();
      final guest = await _Raw.connect(relay, 'join=$code');
      expect((await host.nextJson())['t'], 'relay.peer');
      await host.ws.close(4000);
      expect(await guest.nextJson(), {'t': 'relay.closed', 'reason': 'host left'});
      await until(() => relay.roomCount == 0);
    });

    // A locked phone behind a reverse proxy (the Docker relay sits behind
    // Caddy): the phone's connection to the proxy ends, and the proxy ends
    // its own connection to the relay with a FIN or a reset, never with a
    // WebSocket close frame of its own. Either way the host is away, not
    // gone: only a close frame with 1000 or no code is a host leaving.
    for (final how in ['FIN', 'reset']) {
      test('the proxy in front of the relay drops the host connection ($how): the room waits', () async {
        final proxy = await ServerSocket.bind(loopback, 0);
        addTearDown(proxy.close);
        final upstream = Completer<Socket>();
        proxy.listen((inbound) async {
          final out = await Socket.connect(loopback, relay.port);
          out.done.ignore();
          inbound.done.ignore();
          void forward(Socket to, List<int> data) {
            try {
              to.add(data);
            } on StateError catch (_) {} // the proxy closed that side
          }

          inbound.listen((d) => forward(out, d), onError: (_) {});
          out.listen((d) => forward(inbound, d), onError: (_) {});
          upstream.complete(out);
        });
        final host = _Raw(await WebSocket.connect('ws://127.0.0.1:${proxy.port}/relay?create'));
        final room = await host.nextJson();
        final code = room['code'] as String, key = room['key'] as String;
        final guest = await _Raw.connect(relay, 'join=$code');
        expect((await host.nextJson())['t'], 'relay.peer');

        final out = await upstream.future;
        if (how == 'FIN') {
          unawaited(out.close()); // a FIN, no close frame
        } else {
          out.destroy();
        }
        await guest.expectClosed();
        expect(relay.roomCount, 1, reason: 'the host is away, the room waits');
        final back = await _Raw.connect(relay, 'resume=$code&key=$key');
        expect((await back.nextJson())['t'], 'relay.room');
      });
    }

    for (final code in [1001, 4000, null, 1000]) {
      final leaves = code == null || code == 1000;
      test('a close frame with ${code ?? 'no code'} from the host: ${leaves ? 'the host left' : 'away'}', () async {
        final (host, _, _) = await openRoom();
        await (code == null ? host.ws.close() : host.ws.close(code));
        await host.expectClosed();
        if (leaves) {
          await until(() => relay.roomCount == 0);
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          expect(relay.roomCount, 1);
        }
      });
    }

    test('the relay logs room events, with close codes and no addresses', () async {
      await relay.close();
      final log = <String>[];
      relay = await RelayServer.start(
          port: 0, address: loopback, pingInterval: null, hostGrace: const Duration(seconds: 30), log: log.add);
      final (host, code, key) = await openRoom();
      final guest = await _Raw.connect(relay, 'join=$code');
      expect((await host.nextJson())['t'], 'relay.peer');
      await host.ws.close(4000);
      await guest.expectClosed();
      final back = await _Raw.connect(relay, 'resume=$code&key=$key');
      expect((await back.nextJson())['t'], 'relay.room');
      final guest2 = await _Raw.connect(relay, 'join=$code');
      expect((await back.nextJson())['t'], 'relay.peer');
      await guest2.ws.close();
      await until(() => log.any((l) => l.contains('guest gone')));
      await back.ws.close(1000);
      await until(() => relay.roomCount == 0);
      expect(log.map((l) => l.replaceAll(RegExp(r'after \d+ s'), 'after N s')), [
        'Room $code: opened',
        'Room $code: guest joined',
        'Room $code: host away (close code 4000), the room waits 30 s for it',
        'Room $code: host back after N s',
        'Room $code: guest joined',
        'Room $code: guest gone (guest disconnected, close code 1005)',
        'Room $code: host left (close code 1000)',
        'Room $code: closed: host left',
      ]);
      expect(log.join('\n'), isNot(contains('127.0.0.1')));
    });
  });

  group('KlunkiHost through the relay comes back', () {
    late RelayServer relay;
    setUp(() async =>
        relay = await RelayServer.start(port: 0, address: loopback, hostGrace: const Duration(seconds: 30)));
    tearDown(() => relay.close());

    test('resume() after a long pause: back in the room, the guest rejoins with its token', () async {
      final host = await KlunkiHost.startRelay(const GameConfig('connect4'), _url(relay),
          name: 'Ada', pingInterval: _ping, timeout: _timeout);
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      final guest = await KlunkiGuest.connectRelay(_url(relay), host.roomCode!,
          name: 'Bea', pingInterval: _ping, timeout: _timeout);
      final guestEvents = <NetEvent>[];
      guest.events.listen(guestEvents.add);
      expect(host.submitLocal({'col': 3}), isNull);
      await until(() => guest.moves.length == 1);

      await host.resume(away: const Duration(milliseconds: 100)); // short: nothing to do
      expect(hostEvents.whereType<RoomReconnecting>(), isEmpty);

      await host.resume(away: _timeout);
      await until(() => hostEvents.whereType<RoomReconnected>().isNotEmpty);
      expect(hostEvents.whereType<RoomReconnecting>(), hasLength(1));
      await until(() => guestEvents.whereType<PeerDisconnected>().isNotEmpty && !host.guestConnected);
      expect(host.roomCode, isNotNull);

      await guest.reconnect();
      await until(() => host.guestConnected);
      expect(await guest.submit({'col': 4}), isNull);
      expect(host.moves, hasLength(2));
      expect(hostEvents.whereType<NetError>(), isEmpty);
      await guest.close();
      await host.close();
      await until(() => relay.roomCount == 0);
    });

    test('the relay connection drops: the host comes back by itself', () async {
      // A proxy between host and relay that can be cut, like lost Wi-Fi.
      final proxy = await _Proxy.start(relay.port);
      addTearDown(proxy.close);
      final host = await KlunkiHost.startRelay(
          const GameConfig('connect4'), Uri.parse('ws://127.0.0.1:${proxy.port}/relay'),
          name: 'Ada', pingInterval: _ping, timeout: _timeout);
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      final guest = await KlunkiGuest.connectRelay(_url(relay), host.roomCode!,
          name: 'Bea', pingInterval: _ping, timeout: _timeout);
      await until(() => host.guestConnected);

      proxy.cut();
      await until(() => hostEvents.whereType<RoomReconnected>().isNotEmpty);
      await until(() => !guest.connected);
      await guest.reconnect();
      await until(() => host.guestConnected);
      expect(hostEvents.whereType<NetError>(), isEmpty);
      await guest.close();
      await host.close();
    });

    test('a relay that no longer has the room: NetError "relay: no room …", as before', () async {
      final proxy = await _Proxy.start(relay.port);
      addTearDown(proxy.close);
      final host = await KlunkiHost.startRelay(
          const GameConfig('connect4'), Uri.parse('ws://127.0.0.1:${proxy.port}/relay'),
          name: 'Ada', pingInterval: _ping, timeout: _timeout);
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      // Another relay (a restarted one) behind the same address: it has no
      // such room.
      final other = await RelayServer.start(port: 0, address: loopback);
      addTearDown(other.close);
      proxy.target = other.port;
      proxy.cut();
      await until(() => hostEvents.whereType<NetError>().isNotEmpty);
      expect(hostEvents.whereType<NetError>().single.message, startsWith('relay: no room with code'));
      expect(hostEvents.whereType<RoomReconnecting>(), hasLength(1));
      await host.close();
    });

    test('an older relay without host keys: the room is lost as before', () async {
      // A fake relay: relay.room without a key, then the connection breaks.
      final server = await HttpServer.bind(loopback, 0);
      addTearDown(() => server.close(force: true));
      final sockets = <WebSocket>[];
      server.listen((req) async {
        final ws = await WebSocketTransformer.upgrade(req);
        sockets.add(ws);
        ws.add(jsonEncode({'t': 'relay.room', 'code': 'K7Q2M'}));
        ws.listen((_) {});
      });
      final host = await KlunkiHost.startRelay(
          const GameConfig('connect4'), Uri.parse('ws://127.0.0.1:${server.port}/relay'),
          name: 'Ada', pingInterval: _ping, timeout: _timeout);
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      await host.resume(away: _timeout); // nothing to come back with
      await sockets.single.close(4000);
      await until(() => hostEvents.whereType<NetError>().isNotEmpty);
      expect(hostEvents.whereType<NetError>().single.message, 'relay connection lost');
      expect(hostEvents.whereType<RoomReconnecting>(), isEmpty);
      expect(sockets, hasLength(1));
      await host.close();
    });
  });

  group('a direct host listens again after a pause', () {
    test('same ports; connected TCP and WebSocket guests stay; new guests get in', () async {
      final host = await KlunkiHost.start(const GameConfig('connect4'),
          address: loopback, name: 'Ada', pingInterval: _ping, timeout: _timeout);
      final (port, wsPort) = (host.port, host.wsPort!);
      final tcp = await KlunkiGuest.connect(loopback, port, name: 'Bea', pingInterval: _ping, timeout: _timeout);
      final token = tcp.token;
      expect(host.submitLocal({'col': 3}), isNull);
      await until(() => tcp.moves.length == 1);

      await host.resume(away: const Duration(minutes: 1));
      expect((host.port, host.wsPort), (port, wsPort));
      expect(tcp.connected, isTrue);
      expect(await tcp.submit({'col': 4}), isNull);

      // The guest's seat is kept: a fresh connection with the token gets it
      // (over WebSocket this time), on the same ports as before.
      final ws = await KlunkiGuest.connectWebSocket(Uri.parse('ws://127.0.0.1:$wsPort'),
          name: 'Bea', token: token, pingInterval: _ping, timeout: _timeout);
      expect(ws.moves, hasLength(2));
      await until(() => !tcp.connected);
      await host.resume();
      expect(ws.connected, isTrue);
      expect(host.submitLocal({'col': 3}), isNull);
      await until(() => ws.moves.length == 3);
      await tcp.reconnect();
      expect(tcp.moves, hasLength(3));
      await tcp.close();
      await ws.close();
      await host.close();
    });
  });
}

/// A TCP pass-through whose connections can be cut, to simulate Wi-Fi loss.
class _Proxy {
  final ServerSocket server;
  int target;
  final List<Socket> _sockets = [];
  _Proxy._(this.server, this.target);

  static Future<_Proxy> start(int targetPort) async {
    final proxy = _Proxy._(await ServerSocket.bind(loopback, 0), targetPort);
    proxy.server.listen((client) async {
      final Socket upstream;
      try {
        upstream = await Socket.connect(loopback, proxy.target);
      } catch (_) {
        client.destroy();
        return;
      }
      proxy._sockets.addAll([client, upstream]);
      for (final s in [client, upstream]) {
        unawaited(s.done.catchError((_) {}));
      }
      client.listen(upstream.add, onDone: upstream.destroy, onError: (_) => upstream.destroy());
      upstream.listen(client.add, onDone: client.destroy, onError: (_) => client.destroy());
    });
    return proxy;
  }

  int get port => server.port;

  void cut() {
    for (final s in _sockets) {
      s.destroy();
    }
    _sockets.clear();
  }

  Future<void> close() async {
    cut();
    await server.close();
  }
}
