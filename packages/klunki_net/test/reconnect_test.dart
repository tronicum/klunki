// KLD-120: the retry rhythm after a pause and the pause clock.
import 'package:klunki_net/klunki_net.dart';
import 'package:test/test.dart';

void main() {
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
