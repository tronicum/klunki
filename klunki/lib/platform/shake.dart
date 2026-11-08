import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'accelerometer_stub.dart'
    if (dart.library.io) 'accelerometer_io.dart'
    if (dart.library.js_interop) 'accelerometer_web.dart' as platform;

/// One accelerometer reading (KLD-121 follow-up): the acceleration
/// including gravity along the device axes in g (a phone lying still reads
/// about 1 g in total), [ms] a monotonic timestamp in milliseconds.
@immutable
class AccelSample {
  final double x, y, z;
  final double ms;
  const AccelSample(this.x, this.y, this.z, this.ms);

  /// The total acceleration in g (the direction does not matter for a shake).
  double get g => sqrt(x * x + y * y + z * z);

  @override
  String toString() => 'AccelSample(${g.toStringAsFixed(2)} g @ ${ms.toStringAsFixed(0)} ms)';
}

/// Turns accelerometer samples into "shake" events. Pure Dart without
/// timers: the time comes from the samples, so it is easy to test
/// (`test/platform/shake_test.dart`).
///
/// A shake is [hitsNeeded] jolts above [thresholdG] within [window]; a jolt
/// counts once while the reading stays above the threshold. A single jolt
/// (the phone put down hard, a bump on the table) or picking the phone up
/// (well below 2 g) is no shake. After a shake, [debounce] passes before the
/// next one can count, so one shaking rolls once.
///
/// The constants are the knobs to tune on real devices.
class ShakeDetector {
  /// Total acceleration (incl. gravity) a jolt must exceed, in g. A phone
  /// picked up reads about 1.2–1.6 g; shaken like a dice cup 2.5–4 g.
  static const double thresholdG = 2.2;

  /// Jolts within [window] that make a shake.
  static const int hitsNeeded = 2;

  /// The time in which the jolts of one shake must come.
  static const Duration window = Duration(milliseconds: 900);

  /// Quiet time after a shake.
  static const Duration debounce = Duration(milliseconds: 1500);

  final List<double> _hits = [];
  bool _above = false;
  double? _lastShake;

  /// Feeds [s]; true when it completes a shake.
  bool add(AccelSample s) {
    final above = s.g > thresholdG;
    final rising = above && !_above;
    _above = above;
    if (!rising) return false;
    final last = _lastShake;
    if (last != null && s.ms - last < debounce.inMilliseconds) return false;
    _hits
      ..add(s.ms)
      ..removeWhere((t) => s.ms - t > window.inMilliseconds);
    if (_hits.length < hitsNeeded) return false;
    _hits.clear();
    _lastShake = s.ms;
    return true;
  }

  void reset() {
    _hits.clear();
    _above = false;
    _lastShake = null;
  }
}

/// The device's motion sensor (KLD-121 follow-up), behind a small platform
/// channel of our own, no package: iOS CoreMotion (`AppDelegate.swift`) and
/// Android SensorManager (`MainActivity.kt`) on the event channel
/// `klunki/accelerometer`; on the web the `devicemotion` event. Elsewhere
/// (desktop, tests) there are no samples.
abstract final class Motion {
  /// Whether this device may have a motion sensor (the iOS/Android app, a
  /// touch browser with `DeviceMotionEvent`): only then the shake setting is
  /// offered. Whether it really works shows when the first sample arrives
  /// ([working]).
  static bool get maybeAvailable => debugSamples != null || platform.motionMaybeAvailable;

  /// Samples while listened to (the sensor only runs then). Without a sensor
  /// the stream ends at once or fails.
  static Stream<AccelSample> samples() => (debugSamples ?? platform.accelerometerSamples)();

  /// The web on iOS (Safari 13+) gives motion only after
  /// `DeviceMotionEvent.requestPermission()`, which must run in a user tap:
  /// call this synchronously from a tap handler. Asks at most once; does
  /// nothing elsewhere.
  static void askPermission() {
    if (debugSamples == null) platform.requestMotionPermission();
  }

  /// Tests: a fake sensor.
  @visibleForTesting
  static Stream<AccelSample> Function()? debugSamples;

  /// Samples arrived at least once in this run: shaking works here.
  static final ValueNotifier<bool> working = ValueNotifier(false);

  /// The sensor failed (none on this device): no more tries in this run.
  static bool unavailable = false;

  @visibleForTesting
  static void debugReset() {
    debugSamples = null;
    working.value = false;
    unavailable = false;
  }
}
