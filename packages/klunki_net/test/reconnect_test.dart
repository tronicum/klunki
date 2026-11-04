// KLD-120: the retry rhythm after a pause, the pause clock, and a guest
// reconnect that runs only once at a time.
import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  // Two reconnects at once (the automatic retry loop and a tap on
  // "reconnect") share one attempt. Over the relay, a second connection
  // racing for the seat used to be told "room is full".
  group('a reconnect while one is running joins it', () {
    for (final viaRelay in [false, true]) {
      test(viaRelay ? 'relay' : 'LAN', () async {
        RelayServer? relay;
        if (viaRelay) {
          relay = await RelayServer.start(port: 0, address: loopback);
          addTearDown(relay.close);
        }
        Uri relayUrl() => Uri.parse('ws://127.0.0.1:${relay!.port}/relay');
        final host = viaRelay
            ? await KlunkiHost.startRelay(const GameConfig('connect4'), relayUrl(), name: 'Ada')
            : await KlunkiHost.start(const GameConfig('connect4'), address: loopback, wsPort: null, name: 'Ada');
        addTearDown(host.close);
        final rejoins = <PeerConnected>[];
        host.events.listen((e) {
          if (e is PeerConnected && e.reconnect) rejoins.add(e);
        });
        final guest = viaRelay
            ? await KlunkiGuest.connectRelay(relayUrl(), host.roomCode!, name: 'Bea')
            : await KlunkiGuest.connect(loopback, host.port, name: 'Bea');
        addTearDown(guest.close);
        await until(() => host.guestConnected);

        final first = guest.reconnect();
        final second = guest.reconnect();
        expect(identical(first, second), isTrue);
        await Future.wait([first, second]);
        expect(guest.connected, isTrue);
        await until(() => rejoins.isNotEmpty && host.guestConnected);
        expect(rejoins, hasLength(1));
        expect(host.submitLocal({'col': 3}), isNull);
        await until(() => guest.moves.length == 1);

        // Done: the next call is a new attempt.
        final third = guest.reconnect();
        expect(identical(third, first), isFalse);
        await third;
        expect(guest.connected, isTrue);
      });
    }
  });

  test('retries: 0.5 s, then every second for 30 s, then up to the slow step', () {
    const s = Duration(seconds: 1);
    expect(nextRetryDelay(Duration.zero, Duration.zero), const Duration(milliseconds: 500));
    expect(nextRetryDelay(const Duration(milliseconds: 500), s), s);
    expect(nextRetryDelay(s, const Duration(seconds: 29)), s);
    expect(nextRetryDelay(s, const Duration(seconds: 31)), s * 2);
    expect(nextRetryDelay(s * 2, const Duration(seconds: 40)), s * 3);
    expect(nextRetryDelay(s * 3, const Duration(seconds: 50), slow: s * 5), s * 5);
  });

  test('a pause is the longer of the monotonic and the wall clock', () {
    var now = DateTime(2026, 11, 4, 12);
    final clock = PauseClock(now: () => now);
    // A phone asleep: the monotonic clock may stand still, the wall clock not.
    now = now.add(const Duration(seconds: 40));
    expect(clock.elapsed, greaterThanOrEqualTo(const Duration(seconds: 40)));
    // A wall clock set back: the monotonic clock still counts.
    now = now.subtract(const Duration(hours: 1));
    expect(clock.elapsed, greaterThanOrEqualTo(Duration.zero));
  });

  test('which reconnect errors are worth another try', () {
    expect(reconnectRetryable(const NetException('handshake timed out')), isTrue);
    expect(reconnectRetryable(const NetException('relay: $relayHostAwayText')), isTrue);
    expect(reconnectRetryable(const NetException('relay: room 22222 is full')), isTrue);
    expect(reconnectRetryable(const NetException('relay: no room with code 22222')), isFalse);
    expect(reconnectRetryable(const NetException('session full')), isFalse);
    expect(reconnectRetryable(StateError('x')), isTrue);
  });
}
