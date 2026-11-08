import 'shake.dart';

bool get motionMaybeAvailable => false;

Stream<AccelSample> accelerometerSamples() => const Stream.empty();

bool get motionPermissionPending => false;

void requestMotionPermission() {}
