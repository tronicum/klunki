// KLD-056: player names in the handshake (sanitising, fallbacks, reconnect).
import 'dart:io';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('sanitizePlayerName', () {
    test('keeps ordinary names in any script', () {
      expect(sanitizePlayerName('Anna'), 'Anna');
      expect(sanitizePlayerName('علی'), 'علی');
      expect(sanitizePlayerName('小明'), '小明');
      expect(sanitizePlayerName('می‌خواهم'), 'می‌خواهم', reason: 'ZWNJ stays');
      expect(sanitizePlayerName('👩‍💻 Bea'), '👩‍💻 Bea', reason: 'ZWJ emoji stays');
    });

    test('trims and collapses whitespace of every kind', () {
      expect(sanitizePlayerName('  Anna   Lena \t'), 'Anna Lena');
      expect(sanitizePlayerName('Anna\nLena'), 'Anna Lena');
      expect(sanitizePlayerName('Anna\u00A0\u3000\u2028Lena'), 'Anna Lena');
    });

    test('drops control characters', () {
      expect(sanitizePlayerName('An\u0000na\u0007'), 'Anna');
      expect(sanitizePlayerName('\u007FBen\u0085\u009B'), 'Ben');
    });

    test('drops bidi overrides, isolates and marks', () {
      expect(sanitizePlayerName('\u202EnnA'), 'nnA');
      expect(sanitizePlayerName('\u2066Anna\u2069\u200F\u200E\u061C\u202A\u202C'), 'Anna');
      expect(sanitizePlayerName('\uFEFFBen'), 'Ben');
    });

    test('drops lone surrogates and noncharacters', () {
      expect(sanitizePlayerName('A\uD800n\uDC00na\uFFFF'), 'Anna');
    });

    test('limits the length to 20 code points without a trailing space', () {
      expect(sanitizePlayerName('a' * 30), 'a' * 20);
      expect(sanitizePlayerName('${'a' * 19} bcd'), 'a' * 19);
      expect(sanitizePlayerName('😀' * 25).runes.length, 20);
      expect(maxPlayerNameLength, 20);
    });

    test('empty input stays empty; playerNameOr falls back to the mark', () {
      expect(sanitizePlayerName(null), '');
      expect(sanitizePlayerName(''), '');
      expect(sanitizePlayerName(' \t\u202E\u0000 '), '');
      expect(playerNameOr('  ', Player.a), 'X');
      expect(playerNameOr(null, Player.b), 'O');
      expect(playerNameOr(' Ben ', Player.b), 'Ben');
    });
  });

  group('handshake names', () {
    test('both sides learn each other\'s name, any script', () async {
      final host = await KlunkiHost.start(const GameConfig('connect4'), address: loopback, name: 'علی');
      final guest = await joinHost(host.port, name: 'Anna');
      await until(() => host.guestConnected);
      expect(host.name, 'علی');
      expect(guest.hostName, 'علی');
      expect(host.guestName, 'Anna');
      await guest.close();
      await host.close();
    });

    test('the host sanitises an incoming name', () async {
      final host = await startHost(const GameConfig('connect4'));
      final peer = await RawPeer.connect(host.port);
      peer.send('hello', {'role': 'guest', 'name': '\u202E  Ev\u0000il\n  ${'x' * 30}', 'protocol': 1});
      await peer.next('welcome');
      expect(host.guestName, 'Evil ${'x' * 15}');
      peer.destroy();
      await host.close();
    });

    test('an empty, missing or non-string guest name becomes the guest mark', () async {
      for (final name in <Object?>['', '  \u2066\u2069 ', null, 42]) {
        final host = await startHost(const GameConfig('connect4'));
        final peer = await RawPeer.connect(host.port);
        peer.send('hello', {'role': 'guest', 'protocol': 1, if (name != null) 'name': name});
        await peer.next('welcome');
        expect(host.guestName, 'O', reason: 'name $name');
        peer.destroy();
        await host.close();
      }
    });

    test('an empty host name becomes the host mark on both sides', () async {
      final host = await KlunkiHost.start(const GameConfig('connect4'),
          address: loopback, name: ' \u202E ', hostPlayer: Player.b);
      expect(host.name, 'O');
      final guest = await joinHost(host.port);
      expect(guest.hostName, 'O');
      await guest.close();
      await host.close();
    });

    test('the guest sanitises the host name and falls back to its mark', () async {
      final fake = await RawHost.start((peer) async {
        await peer.next('hello');
        peer.send('hello', {'role': 'host', 'name': '\u202Eevil', 'protocol': 1});
        peer.send('welcome', {
          'config': {'game': 'connect4', 'seed': 0},
          'you': 'b',
          'moves': [],
          'token': 't',
          'host': 'Ho\u0000st\u2067',
        });
      });
      final guest = await KlunkiGuest.connect(loopback, fake.port, name: 'Bea');
      expect(guest.hostName, 'Host');
      await guest.close();
      await fake.close();

      final silent = await RawHost.start((peer) async {
        await peer.next('hello');
        peer.send('hello', {'role': 'host', 'protocol': 1});
        peer.send('welcome', {
          'config': {'game': 'connect4', 'seed': 0},
          'you': 'b',
          'moves': [],
          'token': 't',
        });
      });
      final guest2 = await KlunkiGuest.connect(loopback, silent.port, name: 'Bea');
      expect(guest2.hostName, 'X');
      await guest2.close();
      await silent.close();
    });

    test('the guest sends its sanitised name', () async {
      final host = await startHost(const GameConfig('connect4'));
      final guest = await joinHost(host.port, name: '  Bea\u202E  ');
      expect(guest.name, 'Bea');
      await until(() => host.guestConnected);
      expect(host.guestName, 'Bea');
      await guest.close();
      await host.close();
    });

    test('names stay the same after a reconnect (TCP and WebSocket)', () async {
      final host = await KlunkiHost.start(const GameConfig('connect4'), address: loopback, name: 'Anna');
      final proxy = await Proxy.start(host.port);
      final guest = await KlunkiGuest.connect(loopback, proxy.port, name: 'Ben');
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      proxy.cut();
      await until(() => !host.guestConnected && !guest.connected);
      await guest.reconnect();
      await until(() => host.guestConnected);
      expect(guest.hostName, 'Anna');
      expect(host.guestName, 'Ben');
      expect(hostEvents.whereType<PeerConnected>().single,
          isA<PeerConnected>().having((e) => e.name, 'name', 'Ben').having((e) => e.reconnect, 'reconnect', isTrue));
      await guest.close();

      final ws = await KlunkiGuest.connectWebSocket(webSocketUri(loopback.address, host.wsPort!),
          name: 'Ben', token: guest.token);
      expect(ws.hostName, 'Anna');
      await until(() => host.guestConnected);
      expect(host.guestName, 'Ben');
      await ws.close();
      await proxy.close();
      await host.close();
    });
  });
}

/// A hand-driven fake host: [script] runs for every incoming connection.
class RawHost {
  final ServerSocket server;
  final List<RawPeer> peers = [];
  RawHost._(this.server);

  static Future<RawHost> start(Future<void> Function(RawPeer peer) script) async {
    final h = RawHost._(await ServerSocket.bind(loopback, 0));
    h.server.listen((s) {
      final peer = RawPeer(s);
      h.peers.add(peer);
      script(peer);
    });
    return h;
  }

  int get port => server.port;

  Future<void> close() async {
    for (final p in peers) {
      p.destroy();
    }
    await server.close();
  }
}
