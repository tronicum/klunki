import 'dart:async';

/// Time that this isolate was running, as opposed to wall clock (KLD-109).
///
/// Network timeouts judge the other side ("nothing heard for 10 s"). While
/// this isolate is stalled (a long synchronous frame, a process that gets no
/// CPU, a sleeping machine, an app resumed from the background) it reads
/// nothing, so the other side's messages wait unread however fast they came:
/// the stall is no evidence against the other side. Judged by wall clock, the
/// first timer after a long enough stall fired before the waiting messages
/// were read and dropped a healthy connection.
///
/// [tick] must be called every [step] (a periodic timer): a tick that comes
/// later than that measures a stall, and [elapsed] leaves it out. Under
/// steady load (every tick a bit late) a timeout still fires, just later.
class AwakeClock {
  final Duration step;
  final Stopwatch _wall = Stopwatch()..start();
  final Stopwatch _sinceTick = Stopwatch()..start();
  Duration _stalled = Duration.zero;

  AwakeClock(this.step);

  /// Notes the tick of the periodic timer; returns [elapsed].
  Duration tick() {
    final overdue = _sinceTick.elapsed - step;
    _sinceTick.reset();
    if (overdue > Duration.zero) _stalled += overdue;
    return elapsed;
  }

  /// Wall clock since the start (or [reset]) without the stalls seen by [tick].
  Duration get elapsed => _wall.elapsed - _stalled;

  /// Starts measuring again from now (the tick rhythm is kept).
  void reset() {
    _wall.reset();
    _stalled = Duration.zero;
  }
}

/// Like `Timer(duration, callback)`, but counts only time this isolate was
/// running (see [AwakeClock]). Cancel it like any timer.
Timer awakeTimer(Duration duration, void Function() callback) {
  final step = _stepFor(duration);
  final clock = AwakeClock(step);
  return Timer.periodic(step, (t) {
    if (clock.tick() >= duration) {
      t.cancel();
      callback();
    }
  });
}

/// Like `future.timeout(duration)` (throws [TimeoutException]), but counts
/// only time this isolate was running (see [AwakeClock]).
Future<T> awakeTimeout<T>(Future<T> future, Duration duration) {
  final result = Completer<T>();
  final timer = awakeTimer(duration, () {
    if (!result.isCompleted) result.completeError(TimeoutException(null, duration));
  });
  future.then((v) {
    timer.cancel();
    if (!result.isCompleted) result.complete(v);
  }, onError: (Object e, StackTrace s) {
    timer.cancel();
    if (!result.isCompleted) result.completeError(e, s);
  });
  return result.future;
}

Duration _stepFor(Duration d) {
  final us = d.inMicroseconds ~/ 8;
  return Duration(microseconds: us.clamp(5000, 250000));
}
