// KLD-109: timeouts that judge the other side count only the time this
// isolate was running, so a stall (busy CPU, long frame, sleeping machine)
// does not fire them before the waiting messages are read.
import 'dart:async';

import 'package:klunki_net/src/awake_clock.dart';
import 'package:test/test.dart';

void _stall(Duration d) {
  final sw = Stopwatch()..start();
  while (sw.elapsed < d) {}
}

void main() {
  test('awakeTimer: a stall longer than the timer does not fire it; awake time does', () async {
    const d = Duration(milliseconds: 150);
    var fired = false;
    final timer = awakeTimer(d, () => fired = true);
    _stall(d * 4);
    final awake = Stopwatch()..start();
    // Messages that waited during the stall are handled now, before the
    // timer could judge (the old Timer fired on the first turn).
    await Future<void>.delayed(Duration.zero);
    expect(fired, isFalse);
    while (!fired) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(awake.elapsed, greaterThanOrEqualTo(d ~/ 2));
    expect(timer.isActive, isFalse);
  });

  test('awakeTimeout: a reply that arrives right after a stall wins', () async {
    final reply = Completer<String>();
    final result = awakeTimeout(reply.future, const Duration(milliseconds: 100));
    _stall(const Duration(milliseconds: 400));
    Timer.run(() => reply.complete('welcome')); // was waiting during the stall
    expect(await result, 'welcome');
  });

  test('awakeTimeout: no reply still times out, and errors pass through', () async {
    await expectLater(awakeTimeout(Completer<void>().future, const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()));
    await expectLater(awakeTimeout(Future<void>.error(StateError('x')), const Duration(seconds: 1)),
        throwsA(isA<StateError>()));
  });

  test('a cancelled awakeTimer never fires', () async {
    var fired = false;
    awakeTimer(const Duration(milliseconds: 20), () => fired = true).cancel();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(fired, isFalse);
  });
}
