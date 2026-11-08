import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import 'shake.dart';

/// iOS and Android: the event channel `klunki/accelerometer` sends
/// `[x, y, z, ms]` (g, milliseconds) about 50 times a second while it is
/// listened to, the error "unavailable" without a sensor.
const EventChannel _channel = EventChannel('klunki/accelerometer');

bool get motionMaybeAvailable => Platform.isIOS || Platform.isAndroid;

Stream<AccelSample> accelerometerSamples() {
  if (!motionMaybeAvailable) return const Stream.empty();
  return _channel.receiveBroadcastStream().map((event) {
    final v = (event as List).cast<num>();
    return AccelSample(v[0].toDouble(), v[1].toDouble(), v[2].toDouble(), v[3].toDouble());
  });
}

void requestMotionPermission() {}
