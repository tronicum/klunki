import 'package:flutter/foundation.dart';
import 'package:klunki_engine/klunki_engine.dart';

/// A transport that may run a chess clock (KLD-126): the hot-seat
/// transport owns one, a network transport shows the host's (the guest a
/// local copy of it). The clock itself is engine code ([ChessClock]); time
/// is read with [clockNow].
abstract interface class ClockedTransport {
  /// The game's clock, or null when the game has none.
  ChessClock? get clock;

  /// The clock's current time in ms (pass it to [ChessClock.remainingOf]).
  int clockNow();

  /// Notifies on every change of the clock (a move, a pause, a player away
  /// or back, the end), not on every tick.
  Listenable get clockChanges;
}

/// The clock of [transport], or null (no clock, or a transport without).
ChessClock? clockOf(Object transport) => transport is ClockedTransport ? transport.clock : null;

/// A [Listenable] for [ClockedTransport.clockChanges].
class ClockNotifier extends ChangeNotifier {
  void changed() => notifyListeners();
}

/// A monotonic time source in ms (a running stopwatch).
int Function() stopwatchClock() {
  final watch = Stopwatch()..start();
  return () => watch.elapsedMilliseconds;
}
