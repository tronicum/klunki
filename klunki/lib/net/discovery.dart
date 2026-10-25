/// Platform-neutral discovery types: what a Klunki host announces on the local
/// network and how the pairing screen finds it. Pure Dart (no `dart:io`, no
/// Flutter), so it is safe to import from web code paths.
///
/// Implementations: `BonsoirDiscovery` (mDNS, Android/iOS/macOS) and
/// `FakeDiscovery` (in memory, for tests). Get the platform one from
/// `createDiscovery()` in `discovery_factory.dart` (null on web).
library;

import 'dart:async';

/// DNS-SD service type Klunki hosts advertise.
const String klunkiServiceType = '_klunki._tcp';

/// TXT record keys of an advertised Klunki host.
abstract final class KlunkiTxt {
  /// Protocol version (`klunki_net`'s `protocolVersion`), as decimal string.
  static const String protocol = 'v';

  /// Game id (e.g. `muehle`); absent when the host has not picked one yet.
  static const String game = 'game';

  /// Display name (the mDNS service name carries a uniqueness suffix).
  static const String name = 'name';
}

/// A Klunki host on the local network: what the host advertises and what a
/// guest discovers (or parses from a manual entry / QR code).
///
/// When advertising, [host] is ignored (the platform announces this device's
/// addresses); when discovered, it is the resolved address to connect to.
class KlunkiHostInfo {
  /// Display name, e.g. "Stefans iPhone".
  final String name;

  /// IP address (or host name) to connect to.
  final String host;

  /// TCP port of the `klunki_net` session.
  final int port;

  /// The host's `klunki_net` protocol version.
  final int protocol;

  /// Game id the host offers, if already chosen.
  final String? gameId;

  const KlunkiHostInfo({
    required this.name,
    required this.host,
    required this.port,
    required this.protocol,
    this.gameId,
  });

  KlunkiHostInfo copyWith({String? name, String? host, int? port, int? protocol, String? gameId}) => KlunkiHostInfo(
        name: name ?? this.name,
        host: host ?? this.host,
        port: port ?? this.port,
        protocol: protocol ?? this.protocol,
        gameId: gameId ?? this.gameId,
      );

  @override
  bool operator ==(Object other) =>
      other is KlunkiHostInfo &&
      other.name == name &&
      other.host == host &&
      other.port == port &&
      other.protocol == protocol &&
      other.gameId == gameId;

  @override
  int get hashCode => Object.hash(name, host, port, protocol, gameId);

  @override
  String toString() => 'KlunkiHostInfo($name @ $host:$port, v$protocol${gameId == null ? '' : ', $gameId'})';
}

/// Advertise this device as a Klunki host and/or browse for other hosts.
abstract class DiscoveryService {
  /// Starts announcing [me] (replaces an earlier advertisement). `me.host`
  /// is ignored.
  Future<void> advertise(KlunkiHostInfo me);

  /// Stops announcing. No-op if not advertising.
  Future<void> stopAdvertising();

  /// Starts browsing (if not already) and returns the current list of hosts
  /// followed by every change (hosts appearing, updating, disappearing).
  /// Each listener first gets the current list. This device's own
  /// advertisement is not listed.
  Stream<List<KlunkiHostInfo>> browse();

  /// Stops browsing; listeners get an empty list. [browse] restarts it.
  Future<void> stopBrowsing();

  /// Stops everything and releases resources.
  Future<void> dispose();
}

/// Keeps the browse result keyed by service id and replays the current list
/// to every new listener. Shared by the implementations.
class HostListBroadcaster {
  final Map<String, KlunkiHostInfo> _hosts = {};
  final StreamController<List<KlunkiHostInfo>> _changes = StreamController.broadcast(sync: true);

  /// Current hosts, sorted by name then address.
  List<KlunkiHostInfo> get hosts {
    final list = _hosts.values.toList()
      ..sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return byName != 0 ? byName : '${a.host}:${a.port}'.compareTo('${b.host}:${b.port}');
      });
    return List.unmodifiable(list);
  }

  /// The current list, then every change.
  Stream<List<KlunkiHostInfo>> get stream => Stream.multi((controller) {
        controller.add(hosts);
        final sub = _changes.stream.listen(controller.add, onError: controller.addError, onDone: controller.close);
        controller.onCancel = sub.cancel;
      });

  /// Adds or replaces the host with [id]; emits only on change.
  void put(String id, KlunkiHostInfo host) {
    if (_hosts[id] == host) return;
    _hosts[id] = host;
    _emit();
  }

  /// Removes the host with [id]; emits only on change.
  void remove(String id) {
    if (_hosts.remove(id) != null) _emit();
  }

  /// Replaces the whole list with [hosts] (id → host); emits once, only on
  /// change.
  void replaceAll(Map<String, KlunkiHostInfo> hosts) {
    if (hosts.length == _hosts.length && hosts.entries.every((e) => _hosts[e.key] == e.value)) return;
    _hosts
      ..clear()
      ..addAll(hosts);
    _emit();
  }

  /// Removes all hosts; emits only on change.
  void clear() {
    if (_hosts.isEmpty) return;
    _hosts.clear();
    _emit();
  }

  /// Reports a failure (e.g. mDNS could not start) to the listeners.
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_changes.isClosed) _changes.addError(error, stackTrace);
  }

  Future<void> close() => _changes.close();

  void _emit() {
    if (!_changes.isClosed) _changes.add(hosts);
  }
}

/// Builds the TXT attributes for [me].
Map<String, String> klunkiTxtRecord(KlunkiHostInfo me) => {
      KlunkiTxt.protocol: '${me.protocol}',
      KlunkiTxt.name: me.name,
      if (me.gameId != null && me.gameId!.isNotEmpty) KlunkiTxt.game: me.gameId!,
    };

/// Reads a discovered service back into a [KlunkiHostInfo]. [serviceName] is
/// the fallback display name; a missing or bad `v` gives protocol 0 (the UI
/// can show it as incompatible).
KlunkiHostInfo hostInfoFromTxt({
  required String serviceName,
  required String host,
  required int port,
  required Map<String, String> txt,
}) {
  final game = txt[KlunkiTxt.game];
  final name = txt[KlunkiTxt.name];
  return KlunkiHostInfo(
    name: name == null || name.isEmpty ? serviceName : name,
    host: host,
    port: port,
    protocol: int.tryParse(txt[KlunkiTxt.protocol] ?? '') ?? 0,
    gameId: game == null || game.isEmpty ? null : game,
  );
}
