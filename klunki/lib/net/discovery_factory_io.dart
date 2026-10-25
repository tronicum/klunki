import 'package:flutter/foundation.dart';

import 'bonsoir_discovery.dart';
import 'discovery.dart';

/// Native: bonsoir where Klunki ships and bonsoir has an implementation.
DiscoveryService? createPlatformDiscovery() {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS => BonsoirDiscoveryService(),
    _ => null,
  };
}
