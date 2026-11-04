import 'dart:async';

import 'events.dart';
import 'guest.dart';
import 'relay/relay_protocol.dart';

/// KLD-120: a pause (a locked phone, the app in the background) at least
/// this long makes the connections of the paused side suspect. The system
/// may have dropped them without a word, and the other side gave up on a
/// peer that answered nothing after its timeout. So after such a pause a
/// guest reconnects and a relay host comes back to its room at once instead
/// of waiting for its keepalive to notice (another timeout).
const Duration pauseMakesStale = Duration(seconds: 2);

/// The wait before the next try to get back in: none for the first, then
/// 0.5 s, then every second for [fastFor] (the other side comes back from
/// its own pause any moment), then every [slow].
Duration nextRetryDelay(Duration previous, Duration elapsed,
    {Duration fastFor = const Duration(seconds: 30), Duration slow = const Duration(seconds: 3)}) {
  if (previous == Duration.zero) return const Duration(milliseconds: 500);
  if (elapsed < fastFor) return const Duration(seconds: 1);
  final next = previous * 2;
  return next > slow ? slow : next;
}

/// Whether another [KlunkiGuest.reconnect] may work after it threw [e]: the
/// host or the network is not back yet (no answer, connection refused, the
/// relay says the host is away, the relay still holds our old connection).
/// Not: other builds, a taken seat, a diverged game, a room that is gone, a
/// club code problem.
bool reconnectRetryable(Object e) {
  if (e is! NetException) return true;
  if (e.mismatch != null) return false;
  final m = e.message;
  if (m.contains('session full') || m.contains('diverged') || m.contains('different game')) return false;
  if (m.startsWith('relay:')) return m == 'relay: $relayHostAwayText' || m.contains('is full');
  return true;
}

/// Retries [KlunkiGuest.reconnect] with [nextRetryDelay] (KLD-120) until it
/// works, an error says that retrying cannot help ([reconnectRetryable]),
/// [within] has passed, or [stop] is called.
class GuestReconnector {
  final KlunkiGuest guest;
  final Duration within;
  Completer<void>? _wake;
  bool _stopped = false;

  GuestReconnector(this.guest, {this.within = const Duration(minutes: 5)});

  /// Skips the current wait: try again now (the app is back in front).
  void wake() {
    final w = _wake;
    if (w != null && !w.isCompleted) w.complete();
  }

  /// Ends [run] at its next step.
  void stop() {
    _stopped = true;
    wake();
  }

  bool get stopped => _stopped;

  /// Tries until connected. [force]: reconnect even though the old
  /// connection still looks open (it may be dead after a pause). Returns
  /// whether the guest is connected, and the error that ended the tries
  /// when retrying could not help (null after a timeout or [stop]).
  Future<({bool connected, Object? error})> run({bool force = false}) async {
    final clock = Stopwatch()..start();
    var delay = Duration.zero;
    while (!_stopped) {
      if (delay > Duration.zero) {
        final wake = _wake = Completer<void>();
        await Future.any([wake.future, Future<void>.delayed(delay)]);
        _wake = null;
        if (_stopped) break;
      }
      if (guest.connected && !force) break;
      force = false;
      try {
        await guest.reconnect();
        if (!_stopped) return (connected: true, error: null);
        break;
      } catch (e) {
        if (_stopped) break;
        if (!reconnectRetryable(e)) return (connected: guest.connected, error: e);
      }
      if (clock.elapsed >= within) break;
      delay = nextRetryDelay(delay, clock.elapsed);
    }
    return (connected: guest.connected, error: null);
  }
}

/// How long the app was away: the longer of a [Stopwatch] (monotonic) and
/// the wall clock, because a monotonic clock may stand still while a phone
/// sleeps and would make a long pause look short.
class PauseClock {
  final Stopwatch _watch = Stopwatch()..start();
  final DateTime _start;
  final DateTime Function() _now;

  PauseClock({DateTime Function()? now})
      : _now = now ?? DateTime.now,
        _start = (now ?? DateTime.now)();

  Duration get elapsed {
    final wall = _now().difference(_start);
    return wall > _watch.elapsed ? wall : _watch.elapsed;
  }
}
