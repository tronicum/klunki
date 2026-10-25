import 'dart:async';

import 'discovery.dart';

/// An in-memory "local network" for [FakeDiscovery]: every instance on the
/// same network sees the others' advertisements.
class FakeNetwork {
  final Map<FakeDiscovery, KlunkiHostInfo> _ads = {};
  final Set<FakeDiscovery> _browsers = {};

  /// Address [FakeDiscovery] instances report for themselves unless given one.
  int _nextAddress = 2;

  String _allocateAddress() => '192.168.0.${_nextAddress++}';

  void _publish() {
    for (final b in _browsers.toList()) {
      b._sync();
    }
  }
}

/// In-memory [DiscoveryService] for tests (and anywhere without mDNS).
///
/// Instances sharing a [FakeNetwork] discover each other. Tests can also
/// inject hosts directly with [addHost] / [removeHost].
class FakeDiscovery implements DiscoveryService {
  final FakeNetwork network;

  /// The address this instance's advertisement shows up with on others.
  final String address;

  final HostListBroadcaster _list = HostListBroadcaster();
  final Map<String, KlunkiHostInfo> _injected = {};
  bool _browsing = false;

  /// Everything passed to [advertise], in order (for assertions).
  final List<KlunkiHostInfo> advertiseCalls = [];

  FakeDiscovery._(this.network, this.address);

  /// A new instance on [network] (default: a private one) whose
  /// advertisement shows up at [address] (default: the next 192.168.0.x).
  factory FakeDiscovery({FakeNetwork? network, String? address}) {
    final net = network ?? FakeNetwork();
    return FakeDiscovery._(net, address ?? net._allocateAddress());
  }

  /// The current advertisement, null if not advertising.
  KlunkiHostInfo? get advertised => network._ads[this];

  bool get isBrowsing => _browsing;

  @override
  Future<void> advertise(KlunkiHostInfo me) async {
    advertiseCalls.add(me);
    network._ads[this] = me.copyWith(host: address);
    network._publish();
  }

  @override
  Future<void> stopAdvertising() async {
    if (network._ads.remove(this) != null) network._publish();
  }

  @override
  Stream<List<KlunkiHostInfo>> browse() {
    if (!_browsing) {
      _browsing = true;
      network._browsers.add(this);
      _sync();
    }
    return _list.stream;
  }

  @override
  Future<void> stopBrowsing() async {
    _browsing = false;
    network._browsers.remove(this);
    _list.clear();
  }

  @override
  Future<void> dispose() async {
    await stopAdvertising();
    await stopBrowsing();
    await _list.close();
  }

  /// Makes [host] visible to this instance's browser under [id]
  /// (default: `host:port`). Replaces an earlier host with the same id.
  void addHost(KlunkiHostInfo host, {String? id}) {
    _injected[id ?? '${host.host}:${host.port}'] = host;
    _sync();
  }

  /// Removes a host added with [addHost].
  void removeHost(String id) {
    if (_injected.remove(id) != null) _sync();
  }

  void _sync() {
    if (!_browsing) return;
    final want = <String, KlunkiHostInfo>{
      for (final e in network._ads.entries)
        if (e.key != this) 'ad:${identityHashCode(e.key)}': e.value,
      for (final e in _injected.entries) 'id:${e.key}': e.value,
    };
    _list.replaceAll(want);
  }
}
