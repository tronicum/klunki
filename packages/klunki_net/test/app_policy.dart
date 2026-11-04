// What the app does around a locked phone (klunki/lib/transport/
// network_transport.dart, KLD-120), on plain klunki_net objects, so the
// suspend tests can run it in a process they freeze. Not a test file.
//
// [AppPolicy.current] is the app's code path (GuestReconnector,
// pauseMakesStale). [AppPolicy.before] is how the first KLD-120 build
// behaved, kept to measure against: after a pause the old connection was
// trusted unless the pause was at least the keepalive timeout, and retries
// waited 0.5, 1, 2, then 3 s.
import 'dart:async';

import 'package:klunki_net/klunki_net.dart';

class AppPolicy {
  final bool before;
  final KlunkiHost? host;
  final KlunkiGuest? guest;
  final Duration timeout;
  GuestReconnector? _reconnector;
  Completer<void>? _wakeBefore;
  Future<void>? _loop;
  StreamSubscription<NetEvent>? _sub;

  AppPolicy({required this.before, required this.timeout, this.host, this.guest}) {
    // A guest reconnects by itself after the connection dropped, unless the
    // host said goodbye or the relay closed the room.
    _sub = guest?.events.listen((e) {
      if (e is PeerDisconnected && !e.reason.startsWith('peer left') && !e.reason.startsWith('relay:')) {
        _start(force: false);
      }
    });
  }

  static AppPolicy named(String name,
          {required Duration timeout, KlunkiHost? host, KlunkiGuest? guest}) =>
      AppPolicy(before: name == 'before', timeout: timeout, host: host, guest: guest);

  /// The app is in the foreground again after [away].
  Future<void> resumed(Duration away) async {
    final threshold = before ? timeout : pauseMakesStale;
    final h = host;
    if (h != null) {
      // Before: the relay host came back only after a full timeout away.
      await h.resume(away: before && away < timeout ? Duration.zero : away);
      return;
    }
    final g = guest!;
    if (!g.connected || away >= threshold) _start(force: g.connected);
  }

  void _start({required bool force}) {
    if (_loop != null) {
      _reconnector?.wake();
      final w = _wakeBefore;
      if (w != null && !w.isCompleted) w.complete();
      return;
    }
    _loop = (before ? _runBefore(force) : _runCurrent(force)).whenComplete(() => _loop = null);
  }

  Future<void> _runCurrent(bool force) async {
    final r = _reconnector = GuestReconnector(guest!);
    await r.run(force: force);
    _reconnector = null;
  }

  Future<void> _runBefore(bool force) async {
    final g = guest!;
    var delay = Duration.zero;
    final clock = Stopwatch()..start();
    while (clock.elapsed < const Duration(minutes: 5)) {
      if (delay > Duration.zero) {
        final w = _wakeBefore = Completer<void>();
        await Future.any([w.future, Future<void>.delayed(delay)]);
        _wakeBefore = null;
      }
      if (g.connected && !force) return;
      force = false;
      try {
        await g.reconnect();
        return;
      } catch (e) {
        if (!reconnectRetryable(e)) return;
      }
      final next = delay == Duration.zero ? const Duration(milliseconds: 500) : delay * 2;
      delay = next > const Duration(seconds: 3) ? const Duration(seconds: 3) : next;
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _reconnector?.stop();
  }
}
