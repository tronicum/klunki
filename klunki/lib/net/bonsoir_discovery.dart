import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

import 'discovery.dart';

/// [DiscoveryService] over mDNS/DNS-SD via `bonsoir` (Android NSD, Apple
/// Network framework). Not for web: `bonsoir` imports `dart:io`. Get it via
/// `createDiscovery()`.
///
/// Needs, on device: Android `INTERNET` + `CHANGE_WIFI_MULTICAST_STATE`
/// (merged from bonsoir's own manifest; bonsoir takes the multicast lock
/// itself), iOS `NSLocalNetworkUsageDescription` + `NSBonjourServices`
/// containing `_klunki._tcp` (KLD-040).
class BonsoirDiscoveryService implements DiscoveryService {
  final Random _random;
  final bool _printLogs;

  BonsoirBroadcast? _broadcast;
  StreamSubscription<BonsoirBroadcastEvent>? _broadcastSub;

  /// The service name we announced (after a platform rename, if any), so the
  /// browser can hide this device's own advertisement.
  String? _ownServiceName;

  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;
  Future<void>? _browseStart;
  final HostListBroadcaster _list = HostListBroadcaster();

  BonsoirDiscoveryService({Random? random, bool printLogs = kDebugMode}) : this._(random ?? Random(), printLogs);

  BonsoirDiscoveryService._(this._random, this._printLogs);

  @override
  Future<void> advertise(KlunkiHostInfo me) async {
    await stopAdvertising();
    final name = uniqueServiceName(me.name, _random);
    final broadcast = BonsoirBroadcast(
      printLogs: _printLogs,
      service: BonsoirService(
        name: name,
        type: klunkiServiceType,
        port: me.port,
        attributes: klunkiTxtRecord(me),
      ),
    );
    _broadcast = broadcast;
    _ownServiceName = name;
    await broadcast.initialize();
    _broadcastSub = broadcast.eventStream?.listen((event) {
      final service = event.service;
      if (event is BonsoirBroadcastStartedEvent && service != null) {
        _ownServiceName = service.name;
        _hideOwn();
      }
    });
    await broadcast.start();
    _hideOwn();
  }

  @override
  Future<void> stopAdvertising() async {
    final broadcast = _broadcast;
    _broadcast = null;
    _ownServiceName = null;
    await _broadcastSub?.cancel();
    _broadcastSub = null;
    if (broadcast != null && !broadcast.isStopped) await broadcast.stop();
  }

  @override
  Stream<List<KlunkiHostInfo>> browse() {
    _browseStart ??= _startBrowsing().catchError((Object e, StackTrace st) {
      _browseStart = null;
      _list.addError(e, st);
    });
    return _list.stream;
  }

  Future<void> _startBrowsing() async {
    final discovery = BonsoirDiscovery(type: klunkiServiceType, printLogs: _printLogs);
    _discovery = discovery;
    await discovery.initialize();
    _discoverySub = discovery.eventStream?.listen((event) => _onDiscovery(discovery, event));
    await discovery.start();
  }

  void _onDiscovery(BonsoirDiscovery discovery, BonsoirDiscoveryEvent event) {
    if (!identical(discovery, _discovery)) return;
    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent(:final service):
        service.resolve(discovery.serviceResolver);
      case BonsoirDiscoveryServiceResolvedEvent(:final service):
      case BonsoirDiscoveryServiceUpdatedEvent(:final service):
        if (service.hostAddresses.isEmpty) {
          service.resolve(discovery.serviceResolver);
          return;
        }
        _put(service);
      case BonsoirDiscoveryServiceLostEvent(:final service):
        _list.remove(service.name);
      default:
        break;
    }
  }

  void _put(BonsoirService service) {
    if (service.name == _ownServiceName) return;
    final host = pickHostAddress(service.hostAddresses);
    if (host == null) return;
    _list.put(
      service.name,
      hostInfoFromTxt(serviceName: service.name, host: host, port: service.port, txt: service.attributes),
    );
  }

  void _hideOwn() {
    final own = _ownServiceName;
    if (own != null) _list.remove(own);
  }

  @override
  Future<void> stopBrowsing() async {
    final discovery = _discovery;
    final starting = _browseStart;
    _discovery = null;
    _browseStart = null;
    await _discoverySub?.cancel();
    _discoverySub = null;
    _list.clear();
    if (starting != null) await starting;
    if (discovery != null && discovery.isReady) await discovery.stop();
  }

  @override
  Future<void> dispose() async {
    await stopAdvertising();
    await stopBrowsing();
    await _list.close();
  }
}

/// Max bytes of a DNS-SD instance name label (RFC 6763 §4.1.1).
const int maxServiceNameBytes = 63;

/// [displayName] plus a short random suffix (`"Stefans iPhone #3fa2"`),
/// trimmed to fit an mDNS label, so two devices with the same name do not
/// collide. The clean name travels in the TXT record.
@visibleForTesting
String uniqueServiceName(String displayName, Random random) {
  final suffix = ' #${random.nextInt(0x10000).toRadixString(16).padLeft(4, '0')}';
  var base = displayName.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
  if (base.isEmpty) base = 'Klunki';
  while (utf8.encode('$base$suffix').length > maxServiceNameBytes) {
    base = String.fromCharCodes(base.runes.take(base.runes.length - 1));
  }
  return '${base.trimRight()}$suffix';
}

/// The address to connect to: the first IPv4 one if any, else the first one.
@visibleForTesting
String? pickHostAddress(List<String> addresses) {
  final ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
  for (final a in addresses) {
    if (ipv4.hasMatch(a)) return a;
  }
  return addresses.isEmpty ? null : addresses.first;
}
