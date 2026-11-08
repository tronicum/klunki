import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'shake.dart';

/// The web: the browser's `devicemotion` event through `dart:js_interop`
/// from the SDK (no package). `accelerationIncludingGravity` is in m/s².
const double _standardGravity = 9.80665;

bool get motionMaybeAvailable {
  if (!globalContext.has('DeviceMotionEvent')) return false;
  final navigator = globalContext['navigator'];
  if (navigator == null) return false;
  final touch = (navigator as JSObject)['maxTouchPoints'];
  return touch != null && (touch as JSNumber).toDartInt > 0;
}

Stream<AccelSample> accelerometerSamples() {
  JSFunction? listener;
  late final StreamController<AccelSample> controller;
  controller = StreamController<AccelSample>(
    onListen: () {
      if (!globalContext.has('DeviceMotionEvent')) {
        controller.close();
        return;
      }
      final l = ((JSObject event) {
        final a = event['accelerationIncludingGravity'];
        if (a == null) return;
        final acc = a as JSObject;
        final x = acc['x'], y = acc['y'], z = acc['z'];
        if (x == null || y == null || z == null) return;
        final t = event['timeStamp'];
        controller.add(AccelSample(
          (x as JSNumber).toDartDouble / _standardGravity,
          (y as JSNumber).toDartDouble / _standardGravity,
          (z as JSNumber).toDartDouble / _standardGravity,
          t == null ? 0 : (t as JSNumber).toDartDouble,
        ));
      }).toJS;
      listener = l;
      globalContext.callMethod<JSAny?>('addEventListener'.toJS, 'devicemotion'.toJS, l);
    },
    onCancel: () {
      final l = listener;
      if (l != null) globalContext.callMethod<JSAny?>('removeEventListener'.toJS, 'devicemotion'.toJS, l);
      listener = null;
    },
  );
  return controller.stream;
}

bool _asked = false;

/// iOS Safari 13+ will ask for motion access (KLD-123): the browser has
/// `DeviceMotionEvent.requestPermission` and it was not called yet.
bool get motionPermissionPending {
  if (_asked || !globalContext.has('DeviceMotionEvent')) return false;
  return (globalContext['DeviceMotionEvent'] as JSObject).has('requestPermission');
}

/// iOS Safari 13+: `DeviceMotionEvent.requestPermission()` (must run in a
/// user tap). Other browsers have no such method and need nothing.
void requestMotionPermission() {
  if (_asked || !globalContext.has('DeviceMotionEvent')) return;
  final dme = globalContext['DeviceMotionEvent'] as JSObject;
  if (!dme.has('requestPermission')) return;
  _asked = true;
  try {
    final promise = dme.callMethod<JSPromise<JSAny?>>('requestPermission'.toJS);
    // Granted: the samples start to flow; denied: shaking stays unavailable.
    promise.toDart.then((_) {}, onError: (Object _) {});
  } catch (_) {
    // Not in a user tap, or blocked: shaking stays unavailable.
  }
}
