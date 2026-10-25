import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/bonsoir_discovery.dart';
import 'package:klunki/net/discovery_factory.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('bonsoir on Android, iOS, macOS; null elsewhere', () {
    for (final (platform, isBonsoir) in [
      (TargetPlatform.android, true),
      (TargetPlatform.iOS, true),
      (TargetPlatform.macOS, true),
      (TargetPlatform.linux, false),
      (TargetPlatform.windows, false),
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      final d = createDiscovery();
      expect(d is BonsoirDiscoveryService, isBonsoir, reason: '$platform');
      if (!isBonsoir) expect(d, isNull);
    }
  });
}
