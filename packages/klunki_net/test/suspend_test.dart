// KLD-120: a phone that locks during a network game. One side runs in its
// own process (test/suspend_peer.dart) and is frozen with SIGSTOP, like a
// suspended app: it reads nothing, answers no ping, and its timers do not
// run. After SIGCONT the game must go on with the existing token rejoin.
@TestOn('mac-os || linux')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:test/test.dart';

import 'support.dart';

// The peer process uses the same values (test/suspend_peer.dart).
const _ping = Duration(milliseconds: 100);
const _timeout = Duration(milliseconds: 800);

/// Locked for a few keepalive timeouts: long enough that the other side
/// (and the relay) gave up on the frozen one.
const _locked = Duration(milliseconds: 3000);

/// One side of the session in its own process.
class _Peer {
  final Process process;
  final List<Map<String, dynamic>> lines = [];
  _Peer._(this.process) {
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((l) {
      lines.add(jsonDecode(l) as Map<String, dynamic>);
    });
    process.stderr.transform(utf8.decoder).listen(stderr.write);
  }

  static Future<_Peer> start(List<String> args) async {
    final peer = _Peer._(await Process.start(Platform.resolvedExecutable, ['test/suspend_peer.dart', ...args]));
    addTearDown(() {
      peer.process.kill(ProcessSignal.sigcont);
      peer.process.kill();
    });
    await peer.waitFor((m) => m['e'] == 'ready', limit: const Duration(seconds: 60));
    return peer;
  }

  Map<String, dynamic> get ready => lines.firstWhere((m) => m['e'] == 'ready');
  Iterable<String> get events => lines.where((m) => m['e'] == 'event').map((m) => m['text'] as String);

  void send(String command) => process.stdin.writeln(command);
  void lock() => process.kill(ProcessSignal.sigstop);
  void unlock() => process.kill(ProcessSignal.sigcont);

  Future<Map<String, dynamic>> waitFor(bool Function(Map<String, dynamic>) test,
      {Duration limit = const Duration(seconds: 10)}) async {
    await until(() => lines.any(test), limit: limit);
    return lines.lastWhere(test);
  }

  /// Sends [command] and waits for its answer `{"e": answer}`.
  Future<Map<String, dynamic>> ask(String command, String answer) async {
    final before = lines.length;
    send(command);
    await until(() => lines.skip(before).any((m) => m['e'] == answer));
    return lines.skip(before).firstWhere((m) => m['e'] == answer);
  }

  Future<void> quit() async {
    send('quit');
    await process.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => -1);
  }
}

Future<void> _sleep(Duration d) => Future<void>.delayed(d);

void main() {
  late RelayServer relay;
  Uri relayUrl() => Uri.parse('ws://127.0.0.1:${relay.port}/relay');

  setUp(() async {
    // The relay pings every 300 ms, so it notices a frozen host while it is
    // locked (dart:io closes a WebSocket whose ping goes unanswered).
    relay = await RelayServer.start(port: 0, address: loopback, pingInterval: const Duration(milliseconds: 300));
  });
  tearDown(() => relay.close());

  group('the guest locks its phone', () {
    for (final viaRelay in [false, true]) {
      test(viaRelay ? 'relay' : 'LAN', () async {
        final host = viaRelay
            ? await KlunkiHost.startRelay(const GameConfig('connect4'), relayUrl(),
                name: 'Ada', pingInterval: _ping, timeout: _timeout)
            : await KlunkiHost.start(const GameConfig('connect4'),
                address: loopback, wsPort: null, name: 'Ada', pingInterval: _ping, timeout: _timeout);
        addTearDown(host.close);
        final events = <NetEvent>[];
        host.events.listen(events.add);
        final guest = await _Peer.start(
            viaRelay ? ['guest', 'relay', '${relayUrl()}', host.roomCode!] : ['guest', 'lan', '${host.port}']);
        await until(() => host.guestConnected);
        expect(host.submitLocal({'col': 3}), isNull);
        await guest.waitFor((m) => m['e'] == 'event' && m['moves'] == 1);

        guest.lock();
        // Today's behaviour, kept: the host notices after its timeout (or
        // the relay's ping, `relay.left`, whichever is first) and keeps the
        // seat (the token) for the guest; a relay room stays open.
        await until(() => !host.guestConnected);
        expect(events.whereType<PeerDisconnected>(), hasLength(1));
        await _sleep(_locked);
        if (viaRelay) expect(relay.roomCount, 1);

        guest.unlock();
        await guest.waitFor((m) => m['e'] == 'event' && m['kind'] == 'PeerDisconnected');
        expect((await guest.ask('reconnect', 'reconnect'))['ok'], isTrue);
        await until(() => host.guestConnected);
        expect(events.whereType<PeerConnected>().last.reconnect, isTrue);
        expect((await guest.ask('move {"col":4}', 'move'))['reason'], isNull);
        expect(host.moves, hasLength(2));
        await guest.quit();
      });
    }
  });

  group('the host locks its phone', () {
    test('LAN: the guest cannot get in while the host is frozen; after resume it rejoins', () async {
      final host = await _Peer.start(['host', 'lan']);
      final port = host.ready['port'] as int;
      final guest = await KlunkiGuest.connect(loopback, port, name: 'Bea', pingInterval: _ping, timeout: _timeout);
      addTearDown(guest.close);
      final events = <NetEvent>[];
      guest.events.listen(events.add);
      await host.ask('move {"col":3}', 'move');
      await until(() => guest.moves.length == 1);

      host.lock();
      await until(() => events.whereType<PeerDisconnected>().isNotEmpty);
      expect(events.whereType<PeerDisconnected>().single.timedOut, isTrue);
      // The kernel still accepts the connection, but nobody answers hello.
      await expectLater(guest.reconnect(), throwsA(isA<NetException>()));
      await _sleep(_locked);

      host.unlock();
      await host.ask('resume ${_locked.inMilliseconds}', 'resumed');
      await guest.reconnect();
      expect(guest.connected, isTrue);
      expect(guest.moves, hasLength(1));
      expect(await guest.submit({'col': 4}), isNull);
      await host.quit();
    });

    test('relay: the room waits for the host, which comes back on its own', () async {
      final host = await _Peer.start(['host', 'relay', '${relayUrl()}']);
      final code = host.ready['code'] as String;
      final guest =
          await KlunkiGuest.connectRelay(relayUrl(), code, name: 'Bea', pingInterval: _ping, timeout: _timeout);
      addTearDown(guest.close);
      final events = <NetEvent>[];
      guest.events.listen(events.add);
      await host.ask('move {"col":3}', 'move');
      await until(() => guest.moves.length == 1);

      host.lock();
      await until(() => events.whereType<PeerDisconnected>().isNotEmpty);
      await _sleep(_locked);
      // The relay dropped the frozen host (no pong), but keeps its room:
      // a guest is told to come back in a moment, not that the room is gone.
      expect(relay.roomCount, 1);
      await expectLater(guest.reconnect(),
          throwsA(isA<NetException>().having((e) => e.message, 'message', 'relay: $relayHostAwayText')));

      host.unlock();
      await host.waitFor((m) => m['e'] == 'event' && m['kind'] == 'RoomReconnected');
      expect(host.events, isNot(contains(startsWith('NetError'))));
      await guest.reconnect();
      expect(guest.connected, isTrue);
      expect(await guest.submit({'col': 4}), isNull);
      await host.quit();
    });
  });
}
