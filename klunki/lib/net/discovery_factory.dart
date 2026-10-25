import 'discovery.dart';
import 'discovery_factory_stub.dart' if (dart.library.io) 'discovery_factory_io.dart' as impl;

/// The platform's [DiscoveryService]: mDNS via `bonsoir` on Android, iOS and
/// macOS; `null` on web (no mDNS, no sockets) and other platforms, where the
/// pairing screen falls back to manual `IP:port` entry.
///
/// Importing this file is web-safe: `bonsoir` (which uses `dart:io`) is only
/// reachable through the `dart.library.io` branch.
DiscoveryService? createDiscovery() => impl.createPlatformDiscovery();
