// KLD-057a: the relay (`klunki relay`) and its clients. A host connects out
// to the relay and gets a room code; a guest joins with the code; the relay
// forwards lines unchanged and the host stays authoritative.
@Timeout(Duration(seconds: 60))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:klunki_engine/debug/muehle_text.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:test/test.dart';

import 'support.dart';

const _ping = Duration(milliseconds: 50);
const _timeout = Duration(seconds: 3);

/// A raw WebSocket client of the relay: records every text frame.
class RelayPeer {
  final WebSocket ws;
  final List<String> lines = [];
  bool closed = false;
  int _cursor = 0;

  RelayPeer(this.ws) {
    ws.listen((f) => lines.add(f as String), onError: (_) => closed = true, onDone: () => closed = true);
  }

  static Future<RelayPeer> connect(RelayServer relay, String query) async =>
      RelayPeer(await WebSocket.connect('ws://127.0.0.1:${relay.port}/relay?$query'));

  void send(Object frame) => ws.add(frame);

  /// The next line (after the previous [next]).
  Future<String> next() async {
    await until(() => _cursor < lines.length);
    return lines[_cursor++];
  }

  /// The next line, decoded.
  Future<Map<String, dynamic>> nextJson() async => jsonDecode(await next()) as Map<String, dynamic>;

  Future<void> close() => ws.close();
}

Uri relayUrlOf(RelayServer relay) => Uri.parse('ws://127.0.0.1:${relay.port}/relay');

/// Host opens a room; returns (host peer, code).
Future<(RelayPeer, String)> openRoom(RelayServer relay) async {
  final host = await RelayPeer.connect(relay, 'create');
  final room = await host.nextJson();
  expect(room['t'], 'relay.room');
  return (host, room['code'] as String);
}

void main() {
  group('relay server', () {
    late RelayServer relay;
    tearDown(() => relay.close());

    test('create, join, forward unchanged in both directions', () async {
      relay = await RelayServer.start(port: 0, address: loopback);
      final (host, code) = await openRoom(relay);
      expect(code, hasLength(5));
      expect(code.split('').every(roomCodeAlphabet.contains), isTrue);
      expect(relay.roomCount, 1);

      final guest = await RelayPeer.connect(relay, 'join=${code.toLowerCase()}'); // case-insensitive
      expect(await host.nextJson(), {'t': 'relay.peer'});
      const hello = '{"type":"hello","v":1,"role":"guest","name":"Bea","protocol":1}';
      guest.send(hello);
      expect(await host.next(), hello, reason: 'forwarded byte for byte');
      const odd = '  not even JSON {"t" ';
      host.send(odd);
      expect(await guest.next(), odd, reason: 'the relay does not interpret game lines');
      // A game line that merely contains a "t" key inside is not a control line.
      const move = '{"type":"move","v":1,"index":0,"move":{"t":"relay.left"}}';
      guest.send(move);
      expect(await host.next(), move);
      await guest.close();
      await host.close();
    });

    test('unknown, malformed and missing codes get relay.error, then close', () async {
      relay = await RelayServer.start(port: 0, address: loopback, random: Random(1));
      final (host, code) = await openRoom(relay);
      final wrongCode = code == '22222' ? '33333' : '22222';
      for (final (query, message) in [
        ('join=$wrongCode', 'no room with code $wrongCode'),
        ('join=OOOOO', 'no room with code OOOOO'),
        ('join=', 'no room with code '),
        ('', 'bad request: use ?create or ?join=CODE'),
      ]) {
        final guest = await RelayPeer.connect(relay, query);
        expect(await guest.nextJson(), {'t': 'relay.error', 'message': message}, reason: query);
        await until(() => guest.closed);
      }
      expect(host.lines, hasLength(1), reason: 'the host saw nothing but its room');
      await host.close();
    });

    test('one guest per room: a second guest gets "room … is full"', () async {
      relay = await RelayServer.start(port: 0, address: loopback);
      final (host, code) = await openRoom(relay);
      final first = await RelayPeer.connect(relay, 'join=$code');
      await host.nextJson();
      final second = await RelayPeer.connect(relay, 'join=$code');
      expect(await second.nextJson(), {'t': 'relay.error', 'message': 'room $code is full'});
      await until(() => second.closed);
      first.send('still here');
      expect(await host.next(), 'still here');
      await first.close();
      await host.close();
    });

    test('guest leaves: host gets relay.left, the room stays open for a new guest', () async {
      relay = await RelayServer.start(port: 0, address: loopback);
      final (host, code) = await openRoom(relay);
      final g1 = await RelayPeer.connect(relay, 'join=$code');
      await host.nextJson();
      await g1.close();
      expect(await host.nextJson(), {'t': 'relay.left', 'reason': 'guest disconnected'});
      final g2 = await RelayPeer.connect(relay, 'join=$code');
      expect(await host.nextJson(), {'t': 'relay.peer'});
      host.send('hi again');
      expect(await g2.next(), 'hi again');
      await g2.close();
      await host.close();
    });

    test('host leaves: the guest gets relay.closed and is closed; the code is gone', () async {
      relay = await RelayServer.start(port: 0, address: loopback);
      final (host, code) = await openRoom(relay);
      final guest = await RelayPeer.connect(relay, 'join=$code');
      await host.nextJson();
      await host.close();
      expect(await guest.nextJson(), {'t': 'relay.closed', 'reason': 'host left'});
      await until(() => guest.closed);
      expect(relay.roomCount, 0);
      final late = await RelayPeer.connect(relay, 'join=$code');
      expect((await late.nextJson())['t'], 'relay.error');
    });

    test('host kick: the guest is closed after the lines before it, without relay.left', () async {
      relay = await RelayServer.start(port: 0, address: loopback);
      final (host, code) = await openRoom(relay);
      final guest = await RelayPeer.connect(relay, 'join=$code');
      await host.nextJson();
      host.send('{"type":"error","v":1,"message":"session full"}');
      host.send('{"t":"relay.kick"}');
      expect(await guest.next(), contains('session full'));
      await until(() => guest.closed);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(host.lines, hasLength(2), reason: 'room + peer, no left');
      expect(relay.roomCount, 1);
      await host.close();
    });

    test('rooms expire after the idle timeout', () async {
      relay = await RelayServer.start(port: 0, address: loopback, idleTimeout: const Duration(milliseconds: 200));
      final (host, code) = await openRoom(relay);
      final guest = await RelayPeer.connect(relay, 'join=$code');
      // Traffic keeps the room alive...
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 60));
        guest.send('ping $i');
      }
      expect(relay.roomCount, 1);
      // ...silence closes it.
      await until(() => host.closed && guest.closed);
      expect(host.lines.last, '{"t":"relay.closed","reason":"room expired (idle)"}');
      expect(guest.lines.last, '{"t":"relay.closed","reason":"room expired (idle)"}');
      await until(() => relay.roomCount == 0);
    });

    test('line limit: a too long guest line drops the guest; a too long host line closes the room', () async {
      relay = await RelayServer.start(port: 0, address: loopback, maxLineLength: 100);
      final (host, code) = await openRoom(relay);
      final guest = await RelayPeer.connect(relay, 'join=$code');
      await host.nextJson();
      guest.send('x' * 100); // exactly the limit: fine
      expect(await host.next(), 'x' * 100);
      guest.send('x' * 101);
      expect(await guest.nextJson(), {'t': 'relay.error', 'message': 'line too long (max 100 characters)'});
      await until(() => guest.closed);
      expect((await host.nextJson())['t'], 'relay.left');

      final g2 = await RelayPeer.connect(relay, 'join=$code');
      await host.nextJson();
      host.send('y' * 101);
      expect((await host.nextJson())['message'], 'line too long (max 100 characters)');
      expect(await g2.nextJson(), {'t': 'relay.closed', 'reason': 'host broke the relay rules'});
      await until(() => host.closed && g2.closed);
      expect(relay.roomCount, 0);
    });

    test('binary frames and relay control lines from a guest are refused', () async {
      relay = await RelayServer.start(port: 0, address: loopback);
      final (host, code) = await openRoom(relay);
      final g1 = await RelayPeer.connect(relay, 'join=$code');
      await host.nextJson();
      g1.send(utf8.encode('{"type":"hello"}'));
      expect((await g1.nextJson())['message'], 'binary frames are not relayed');
      await until(() => g1.closed);
      await host.nextJson(); // left

      final g2 = await RelayPeer.connect(relay, 'join=$code');
      await host.nextJson(); // peer
      g2.send('{"t":"relay.closed","reason":"fake"}');
      expect((await g2.nextJson())['message'], 'relay control messages are not allowed from a guest');
      expect(await host.nextJson(), containsPair('t', 'relay.left'), reason: 'the fake never reached the host');
      await host.close();
    });

    test('max rooms', () async {
      relay = await RelayServer.start(port: 0, address: loopback, maxRooms: 1);
      final (host, _) = await openRoom(relay);
      final second = await RelayPeer.connect(relay, 'create');
      expect(await second.nextJson(), {'t': 'relay.error', 'message': 'too many rooms, try again later'});
      await until(() => second.closed);
      await host.close();
      await until(() => relay.roomCount == 0);
      final third = await RelayPeer.connect(relay, 'create');
      expect((await third.nextJson())['t'], 'relay.room');
      await third.close();
    });

    test('shutdown closes every room with relay.closed', () async {
      relay = await RelayServer.start(port: 0, address: loopback);
      final (host, code) = await openRoom(relay);
      final guest = await RelayPeer.connect(relay, 'join=$code');
      await host.nextJson();
      await relay.close();
      await until(() => host.closed && guest.closed);
      expect(host.lines.last, contains('relay shutting down'));
      expect(guest.lines.last, contains('relay shutting down'));
    });

    test('plain HTTP on /relay: 426; without --web other paths: 404', () async {
      relay = await RelayServer.start(port: 0, address: loopback);
      final client = HttpClient();
      final upgrade = await (await client.get('127.0.0.1', relay.port, '/relay?create')).close();
      expect(upgrade.statusCode, HttpStatus.upgradeRequired);
      await upgrade.drain<void>();
      final other = await (await client.get('127.0.0.1', relay.port, '/index.html')).close();
      expect(other.statusCode, HttpStatus.notFound);
      await other.drain<void>();
      client.close(force: true);
    });
  });

  group('relay clients (KlunkiHost.startRelay / KlunkiGuest.connectRelay)', () {
    late RelayServer relay;
    setUp(() async => relay = await RelayServer.start(port: 0, address: loopback));
    tearDown(() => relay.close());

    Future<KlunkiHost> startRelayHost(GameConfig config, {String name = 'Ada'}) =>
        KlunkiHost.startRelay(config, relayUrlOf(relay), name: name, pingInterval: _ping, timeout: _timeout);
    Future<KlunkiGuest> joinRelay(String code, {String name = 'Bea', String? token}) =>
        KlunkiGuest.connectRelay(relayUrlOf(relay), code,
            name: name, token: token, pingInterval: _ping, timeout: _timeout);

    test('room code, names, moves both ways, same session as a direct guest', () async {
      final host = await startRelayHost(const GameConfig('connect4'));
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      expect(normalizeRoomCode(host.roomCode!), host.roomCode);
      expect(host.relayUrl, relayUrlOf(relay));
      expect(host.port, 0);
      expect(host.wsPort, isNull);

      final guest = await joinRelay(host.roomCode!.toLowerCase());
      expect(guest.transport, 'relay');
      expect(guest.roomCode, host.roomCode);
      expect(guest.relayUrl, relayUrlOf(relay));
      expect(guest.hostName, 'Ada');
      expect(guest.me, Player.b);
      await until(() => host.guestConnected);
      expect(host.guestName, 'Bea');
      expect(hostEvents.whereType<PeerConnected>().single.name, 'Bea');

      expect(host.submitLocal({'col': 3}), isNull);
      await until(() => guest.moves.length == 1);
      expect(await guest.submit({'col': 4}), isNull);
      expect(await guest.submit({'col': 4}), 'not your turn');
      expect(host.moves, guest.moves);
      await guest.close();
      await host.close();
    });

    test('KLD-083: the default bind is dual-stack: host via ::1, guest via 127.0.0.1, plus HTTP on both', () async {
      final dual = await RelayServer.start(port: 0, pingInterval: null);
      addTearDown(dual.close);
      final v6 = Uri.parse('ws://[::1]:${dual.port}/relay');
      final v4 = Uri.parse('ws://127.0.0.1:${dual.port}/relay');
      final host = await KlunkiHost.startRelay(const GameConfig('connect4'), v6,
          name: 'Ada', pingInterval: _ping, timeout: _timeout);
      final guest = await KlunkiGuest.connectRelay(v4, host.roomCode!,
          name: 'Bea', pingInterval: _ping, timeout: _timeout);
      await until(() => host.guestConnected);
      expect(guest.hostName, 'Ada');
      final client = HttpClient();
      addTearDown(client.close);
      for (final h in ['[::1]', '127.0.0.1']) {
        final res = await (await client.getUrl(Uri.parse('http://$h:${dual.port}/nothing'))).close();
        await res.drain<void>();
        expect(res.statusCode, isNot(0), reason: h); // answered at all (no web root: 404)
      }
      await guest.close();
      await host.close();
    });

    test('a wrong code and a full room fail with readable NetExceptions', () async {
      final host = await startRelayHost(const GameConfig('connect4'));
      final wrong = host.roomCode == '22222' ? '33333' : '22222';
      await expectLater(joinRelay(wrong),
          throwsA(isA<NetException>().having((e) => e.message, 'message', 'relay: no room with code $wrong')));
      final bea = await joinRelay(host.roomCode!);
      await expectLater(joinRelay(host.roomCode!, name: 'Mallory'),
          throwsA(isA<NetException>().having((e) => e.message, 'message', 'relay: room ${host.roomCode} is full')));
      expect(bea.connected, isTrue);
      expect(() => joinRelay('K7Q'), throwsArgumentError);
      expect(() => KlunkiGuest.connectRelay(Uri.parse('http://127.0.0.1:1/relay'), 'K7Q2M'), throwsArgumentError);
      await bea.close();
      await host.close();
    });

    test('a guest that left can rejoin the same room with its token', () async {
      final host = await startRelayHost(const GameConfig('connect4'));
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      final bea = await joinRelay(host.roomCode!);
      expect(host.submitLocal({'col': 0}), isNull);
      await until(() => bea.moves.length == 1);
      final token = bea.token;
      await bea.close(reason: 'phone locked');
      await until(() => !host.guestConnected);
      expect(hostEvents.whereType<PeerDisconnected>().single.reason, 'peer left: phone locked');

      final again = await joinRelay(host.roomCode!, name: 'Bea', token: token);
      expect(again.moves, [
        {'col': 0}
      ]);
      await until(() => host.guestConnected);
      expect(hostEvents.whereType<PeerConnected>().map((e) => e.reconnect), [false, true]);
      expect(await again.submit({'col': 1}), isNull);
      await again.close();
      await host.close();
    });

    test('KLD-071: whoever has the code cannot take a guest\'s seat without its token', () async {
      final host = await startRelayHost(const GameConfig('schiffe', seed: 3));
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      final bea = await joinRelay(host.roomCode!, name: 'Bea');
      await until(() => host.guestConnected);
      // While Bea is connected the relay itself says the room is full.
      await expectLater(joinRelay(host.roomCode!, name: 'Bea'),
          throwsA(isA<NetException>().having((e) => e.message, 'message', contains('is full'))));
      expect(bea.connected, isTrue);
      final token = bea.token!;
      await bea.close(reason: 'phone locked');
      await until(() => !host.guestConnected);

      // The slot is free at the relay, but the host refuses anyone without the
      // token: same name, default mark, wrong token. Nobody sees Bea's fleet.
      for (final (name, t) in [('Bea', null), ('O', null), ('Bea', 'f' * token.length)]) {
        await expectLater(joinRelay(host.roomCode!, name: name, token: t),
            throwsA(isA<NetException>().having((e) => e.message, 'message', contains('session full'))));
      }
      expect(hostEvents.whereType<PeerConnected>(), hasLength(1));

      final again = await joinRelay(host.roomCode!, name: 'Bea', token: token);
      expect(again.me, Player.b);
      await until(() => host.guestConnected);
      expect(hostEvents.whereType<PeerConnected>().map((e) => e.reconnect), [false, true]);
      await again.close();
      await host.close();
    });

    test('guest.reconnect() rejoins the room after the relay dropped the guest', () async {
      final host = await startRelayHost(const GameConfig('connect4'));
      final guest = await joinRelay(host.roomCode!);
      final events = <NetEvent>[];
      guest.events.listen(events.add);
      // A bogus guest line breaks the relay's rules: the relay drops the guest
      // (as if Wi-Fi was lost); the room stays.
      final raw = await RelayPeer.connect(relay, 'join=${host.roomCode}');
      expect((await raw.nextJson())['message'], contains('is full'));
      expect(host.submitLocal({'col': 2}), isNull);
      await until(() => guest.moves.length == 1);
      await relayDropGuest(relay, host, guest);
      await until(() => events.whereType<PeerDisconnected>().isNotEmpty);
      expect(host.submitLocal({'col': 2}), 'not your turn');
      await guest.reconnect();
      expect(guest.connected, isTrue);
      expect(events.whereType<Resynced>(), isNotEmpty);
      expect(await guest.submit({'col': 5}), isNull);
      await guest.close();
      await host.close();
    });

    test('host leaves: the guest learns it; the relay closes the room', () async {
      final host = await startRelayHost(const GameConfig('connect4'));
      final guest = await joinRelay(host.roomCode!);
      final events = <NetEvent>[];
      guest.events.listen(events.add);
      await host.close(reason: 'bedtime');
      await until(() => events.whereType<PeerDisconnected>().isNotEmpty);
      expect(events.whereType<PeerDisconnected>().single.reason, 'peer left: bedtime');
      await until(() => relay.roomCount == 0);
      await guest.close();
    });

    test('the relay going away: host gets NetError "relay: …", guest PeerDisconnected', () async {
      final host = await startRelayHost(const GameConfig('connect4'));
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      final guest = await joinRelay(host.roomCode!);
      final guestEvents = <NetEvent>[];
      guest.events.listen(guestEvents.add);
      await until(() => host.guestConnected);
      await relay.close();
      await until(() => hostEvents.whereType<NetError>().isNotEmpty && guestEvents.whereType<PeerDisconnected>().isNotEmpty);
      expect(hostEvents.whereType<NetError>().single.message, 'relay: relay shutting down');
      await until(() => hostEvents.whereType<PeerDisconnected>().isNotEmpty);
      expect(hostEvents.whereType<PeerDisconnected>(), hasLength(1));
      expect(guestEvents.whereType<PeerDisconnected>().single.reason, 'relay: relay shutting down');
      await guest.close();
      await host.close();
    });

    test('startRelay fails cleanly: unreachable relay, full relay, not a relay', () async {
      final closed = await ServerSocket.bind(loopback, 0);
      final port = closed.port;
      await closed.close();
      await expectLater(KlunkiHost.startRelay(const GameConfig('connect4'), Uri.parse('ws://127.0.0.1:$port/relay')),
          throwsA(isA<NetException>()));

      await relay.close();
      relay = await RelayServer.start(port: 0, address: loopback, maxRooms: 0);
      await expectLater(startRelayHost(const GameConfig('connect4')),
          throwsA(isA<NetException>().having((e) => e.message, 'message', 'relay: too many rooms, try again later')));

      // A plain game host's WebSocket port is not a relay.
      final direct = await startHost(const GameConfig('connect4'));
      await expectLater(
          KlunkiHost.startRelay(const GameConfig('connect4'), Uri.parse('ws://127.0.0.1:${direct.wsPort}/relay'),
              timeout: const Duration(milliseconds: 500)),
          throwsA(isA<NetException>()));
      await direct.close();
    });
  });

  group('end to end through the relay', () {
    test('Mühle: host and guest both via the relay play the demo script to the end', () async {
      final relay = await RelayServer.start(port: 0, address: loopback);
      addTearDown(relay.close);
      const config = GameConfig('muehle');
      final text = MuehleText();
      final script = [for (final c in text.demoScript) text.parse(c)!];
      final host = await KlunkiHost.startRelay(config, relayUrlOf(relay),
          name: 'Ada im Browser', pingInterval: _ping, timeout: _timeout);
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      final guest = await KlunkiGuest.connectRelay(relayUrlOf(relay), host.roomCode!,
          name: 'Bea im Browser', pingInterval: _ping, timeout: _timeout);
      final guestEvents = <NetEvent>[];
      guest.events.listen(guestEvents.add);
      await until(() => host.guestConnected);
      expect(guest.hostName, 'Ada im Browser');
      expect(host.guestName, 'Bea im Browser');

      for (var i = 0; i < script.length; i++) {
        final mover = host.game.currentPlayer;
        if (mover == host.me) {
          expect(host.submitLocal(Map.of(script[i])), isNull, reason: 'host move #$i');
          await until(() => guest.moves.length == i + 1);
        } else {
          expect(await guest.submit(Map.of(script[i])), isNull, reason: 'guest move #$i');
        }
        expect(guest.moves, host.moves);
      }
      final h = host.game as MuehleGame, g = guest.game as MuehleGame;
      expect(host.moves, script);
      expect(guest.moves, script);
      expect(g.board, h.board);
      expect(h.isOver && g.isOver, isTrue);
      expect(g.result.winner, h.result.winner);
      expect(h.result.winner, Player.b);
      expect(g.result.reason, h.result.reason);
      await until(() => guestEvents.whereType<MoveAccepted>().length == script.length);
      expect([for (final e in guestEvents.whereType<MoveAccepted>()) e.index], List.generate(script.length, (i) => i));
      expect(hostEvents.whereType<NetError>(), isEmpty);
      expect(guestEvents.whereType<NetError>(), isEmpty);
      await guest.close();
      await host.close();
    });
  });

  group('static files (--web)', () {
    late Directory tmp, web;
    late RelayServer relay;
    final client = HttpClient();

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('klunki_relay_web');
      web = Directory('${tmp.path}/web')..createSync();
      File('${tmp.path}/secret.txt').writeAsStringSync('top secret');
      File('${web.path}/index.html').writeAsStringSync('<!doctype html><title>Klunki</title>');
      File('${web.path}/main.dart.js').writeAsStringSync('console.log(1)');
      File('${web.path}/main.dart.wasm').writeAsBytesSync([0, 97, 115, 109]);
      File('${web.path}/manifest.json').writeAsStringSync('{}');
      File('${web.path}/app.webmanifest').writeAsStringSync('{}');
      Directory('${web.path}/assets').createSync();
      File('${web.path}/assets/index.html').writeAsStringSync('assets index');
      File('${web.path}/assets/font.woff2').writeAsBytesSync([1, 2]);
      Link('${web.path}/escape.txt').createSync('${tmp.path}/secret.txt');
      relay = await RelayServer.start(port: 0, address: loopback, webRoot: web);
    });
    tearDown(() async {
      await relay.close();
      await tmp.delete(recursive: true);
    });

    Future<(int, String?, String)> get(String path, {String method = 'GET'}) async {
      final req = await client.open(method, '127.0.0.1', relay.port, path);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      return (res.statusCode, res.headers.value(HttpHeaders.contentTypeHeader), body);
    }

    /// Sends [path] verbatim (HttpClient would normalise `..` away).
    Future<String> rawGet(String path) async {
      final s = await Socket.connect(loopback, relay.port);
      s.write('GET $path HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n');
      final text = await s.cast<List<int>>().transform(utf8.decoder).join();
      s.destroy();
      return text;
    }

    test('MIME types and index.html fallback', () async {
      expect(await get('/'), (200, 'text/html; charset=utf-8', '<!doctype html><title>Klunki</title>'));
      expect((await get('/index.html')).$1, 200);
      expect((await get('/main.dart.js')).$2, 'text/javascript; charset=utf-8');
      expect((await get('/main.dart.wasm')).$2, 'application/wasm');
      expect((await get('/manifest.json')).$2, 'application/json; charset=utf-8');
      expect((await get('/app.webmanifest')).$2, 'application/manifest+json; charset=utf-8');
      expect((await get('/assets/font.woff2')).$2, 'font/woff2');
      expect((await get('/assets/')).$3, 'assets index');
      expect((await get('/assets')).$3, 'assets index');
      expect((await get('/nope.js')).$1, 404);
      expect(await get('/main.dart.js', method: 'HEAD'), (200, 'text/javascript; charset=utf-8', ''));
      expect((await get('/', method: 'POST')).$1, 405);
      expect(mimeTypeFor('x.MJS'), 'text/javascript; charset=utf-8');
      expect(mimeTypeFor('README'), 'application/octet-stream');
      // The relay endpoint still works next to the files.
      expect((await get('/relay')).$1, HttpStatus.upgradeRequired);
    });

    test('no path traversal outside the web root', () async {
      for (final path in [
        '/../secret.txt',
        '/assets/../../secret.txt',
        '/%2e%2e/secret.txt',
        '/..%2fsecret.txt',
        '/assets/..%5c..%5csecret.txt',
        '/escape.txt', // a symbolic link pointing outside
      ]) {
        final response = await rawGet(path);
        expect(response, isNot(contains('top secret')), reason: path);
        expect(response, anyOf(startsWith('HTTP/1.1 404'), startsWith('HTTP/1.1 400')), reason: path);
      }
    });

    tearDownAll(() => client.close(force: true));
  });

  group('codes and addresses', () {
    test('normalizeRoomCode', () {
      expect(normalizeRoomCode('k7q2m'), 'K7Q2M');
      expect(normalizeRoomCode(' K7Q-2M '), 'K7Q2M');
      for (final bad in ['K7Q2', 'K7Q2MM', 'K7Q2O', 'K7Q20', 'K7Q21', 'K7Q2I', 'K7Q2L', '']) {
        expect(normalizeRoomCode(bad), isNull, reason: bad);
      }
      expect(roomCodeAlphabet, isNot(matches(RegExp('[01OIL]'))));
      expect(roomCodeAlphabet.length, 31);
    });

    test('parseRelayUrl and relayUriForPage', () {
      expect(parseRelayUrl('ws://192.168.1.20:8080').toString(), 'ws://192.168.1.20:8080/relay');
      expect(parseRelayUrl('192.168.1.20:8080').toString(), 'ws://192.168.1.20:8080/relay');
      expect(parseRelayUrl('http://pc.local:8080/').toString(), 'ws://pc.local:8080/relay');
      expect(parseRelayUrl('wss://relay.example/relay?x=1').toString(), 'wss://relay.example/relay');
      expect(parseRelayUrl('ftp://x'), isNull);
      expect(parseRelayUrl(''), isNull);
      expect(relayUriForPage(Uri.parse('http://192.168.1.20:8080/?lang=de')).toString(),
          'ws://192.168.1.20:8080/relay');
      expect(relayUriForPage(Uri.parse('https://klunki.example/app/')).toString(), 'wss://klunki.example/relay');
      expect(relayUriForPage(Uri.parse('file:///index.html')), isNull);
      // KLD-083: `.local` names and bracketed IPv6 hosts.
      expect(parseRelayUrl('Stefans-MacBook.local:8081').toString(), 'ws://stefans-macbook.local:8081/relay');
      expect(parseRelayUrl('[::1]:8081').toString(), 'ws://[::1]:8081/relay');
      expect(parseRelayUrl('http://[fd00::5]:8081/').toString(), 'ws://[fd00::5]:8081/relay');
      expect(relayUriForPage(Uri.parse('http://pc.local:8081/')).toString(), 'ws://pc.local:8081/relay');
      expect(relayUriForPage(Uri.parse('http://[::1]:8081/')).toString(), 'ws://[::1]:8081/relay');
    });
  });
}

/// Makes the relay drop [guest]'s connection as if the network was lost:
/// the host session sees a timeout-free disconnect via `relay.left`.
Future<void> relayDropGuest(RelayServer relay, KlunkiHost host, KlunkiGuest guest) async {
  // Too long a line from the guest is a relay rule violation: the relay
  // closes the guest connection and tells the host `relay.left`.
  await guest.submit({'pad': 'x' * (300 * 1024)});
  await until(() => !host.guestConnected && !guest.connected);
}
