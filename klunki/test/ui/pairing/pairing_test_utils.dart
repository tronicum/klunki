// Helpers for the pairing screen tests (KLD-034): injected dependencies with
// FakeDiscovery and real loopback NetworkTransports.
//
// Real sockets inside testWidgets: the test factories create the transports
// in the root zone (so their sockets and ping timers are real, not fake-async
// timers), and the tests interleave `tester.pump()` with short real waits in
// `tester.runAsync` (see [pumpUntil]) — the same idea as `test/e2e`.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/profile/room_settings.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/pairing/relay_host_screen.dart';
import 'package:klunki/ui/pairing/room_join.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';

const pingInterval = Duration(milliseconds: 100);

/// Keepalive / handshake timeout of the loopback transports in widget tests.
///
/// The sockets and their keepalive timers run in the real zone, but every
/// `tester.pump()` is synchronous: while a frame of two side-by-side apps is
/// laid out and painted, the isolate cannot read pongs. Under full-suite load
/// (one test isolate per core) a single pump can take more than 2 s of wall
/// time, so a 2 s timeout dropped the connection mid-game and the next
/// [pumpUntil] failed ("X move in the browser", KLD-070). No pairing test
/// relies on the timeout firing (they all leave with a `bye`), so it is the
/// library default instead; the cut/Wi-Fi-loss tests in `test/e2e` and
/// `klunki_net` keep their short timeouts outside widget tests.
const netTimeout = Duration(seconds: 10);

/// Records every transport the factories created.
class CreatedTransports {
  final List<NetworkTransport> hosts = [];
  final List<NetworkTransport> guests = [];
  final List<(String, int)> joinCalls = [];
  final List<int> hostPorts = [];
  final List<int> hostWsPorts = [];
  final List<Uri> webJoinCalls = [];
  final List<Uri> relayHostCalls = [];
  final List<(Uri, String)> relayJoinCalls = [];
}

/// Relay host (KLD-057b) through `NetworkTransport.hostRelay`, created in the
/// root zone.
Future<NetworkTransport> relayHost(CreatedTransports created, GameConfig config, Uri relay, {required String name}) {
  created.relayHostCalls.add(relay);
  return _rootZone(() async {
    final t = await NetworkTransport.hostRelay(config, relay, name: name, pingInterval: pingInterval, timeout: netTimeout);
    created.hosts.add(t);
    return t;
  });
}

/// Runs [body] in the root zone and hands its result or error back to the
/// caller's zone (an error does not cross error zones by itself).
Future<T> _rootZone<T>(Future<T> Function() body) async {
  final (T?, Object?) r = await Zone.root.run(() async {
    try {
      return (await body(), null);
    } catch (e) {
      return (null, e);
    }
  });
  if (r.$2 != null) throw r.$2!;
  return r.$1 as T;
}

/// Room-code join (KLD-057b) through `NetworkTransport.joinRelay`, created
/// in the root zone.
Future<NetworkTransport> relayJoin(CreatedTransports created, Uri relay, String code, {required String name}) {
  created.relayJoinCalls.add((relay, code));
  return _rootZone(() async {
    final t =
        await NetworkTransport.joinRelay(relay, code, name: name, pingInterval: pingInterval, timeout: netTimeout);
    created.guests.add(t);
    return t;
  });
}

/// Host on 127.0.0.1 (TCP and WebSocket ports as asked), created in the root zone.
Future<NetworkTransport> loopbackHost(CreatedTransports created, GameConfig config,
    {required String name, required int port, int wsPort = 0}) {
  created.hostPorts.add(port);
  created.hostWsPorts.add(wsPort);
  return Zone.root.run(() async {
    final t = await NetworkTransport.host(config,
        name: name,
        port: port,
        wsPort: wsPort,
        address: InternetAddress.loopbackIPv4,
        pingInterval: pingInterval,
        timeout: netTimeout);
    created.hosts.add(t);
    return t;
  });
}

/// Browser-style guest (KLD-055): joins the WebSocket port of [url] on
/// 127.0.0.1 whatever host the UI asked for, through
/// `NetworkTransport.joinWebSocket`, created in the root zone.
Future<NetworkTransport> loopbackWebJoin(CreatedTransports created, Uri url, {required String name}) {
  created.webJoinCalls.add(url);
  return Zone.root.run(() async {
    final t = await NetworkTransport.joinWebSocket(url.replace(host: '127.0.0.1'),
        name: name, pingInterval: pingInterval, timeout: netTimeout);
    created.guests.add(t);
    return t;
  });
}

/// Joins [port] on 127.0.0.1 whatever [host] the UI asked for (discovered
/// fake hosts have 192.168.0.x addresses), created in the root zone.
Future<NetworkTransport> loopbackJoin(CreatedTransports created, String host, int port, {required String name}) {
  created.joinCalls.add((host, port));
  return Zone.root.run(() async {
    final t = await NetworkTransport.join(InternetAddress.loopbackIPv4, port,
        name: name, pingInterval: pingInterval, timeout: netTimeout);
    created.guests.add(t);
    return t;
  });
}

PairingDeps testDeps({
  required FakeDiscovery discovery,
  required CreatedTransports created,
  String? name = 'Testgerät',
  List<String> addresses = const ['192.168.0.10', '10.0.0.7'],
  int preferredPort = 0,
  int preferredWsPort = 0,
  HostTransportFactory? hostTransport,
  JoinTransportFactory? joinTransport,
  Duration joinTimeout = const Duration(seconds: 12),
  RoomSettings? roomSettings,
  RelaySettings? relaySettings,
  RelayHostTransportFactory? relayHost,
  RelayJoinTransportFactory? relayJoin,
}) =>
    PairingDeps(
      discovery: () => discovery,
      hostTransport: hostTransport ??
          (config, {required name, required port, required wsPort}) =>
              loopbackHost(created, config, name: name, port: port, wsPort: wsPort),
      joinTransport:
          joinTransport ?? (host, port, {required name}) => loopbackJoin(created, host, port, name: name),
      localAddresses: () async => addresses,
      deviceName: name == null ? null : () => name,
      seed: () => 7,
      preferredPort: preferredPort,
      preferredWsPort: preferredWsPort,
      joinTimeout: joinTimeout,
      roomSettings: () => roomSettings ?? RoomSettings.memory(),
      relaySettings: () => relaySettings ?? RelaySettings.memory(),
      relayHost: relayHost ?? platformRelayHost,
      relayJoin: relayJoin ?? platformRelayJoin,
    );

/// A launcher page with two buttons that push the room screens ("open-pairing":
/// "Raum starten", "open-join": "Raum beitreten"), so leaving the game /
/// pairing screen has somewhere to go back to. Pinned to German (see
/// `l10n_test_utils.dart`).
Widget launcherApp(PairingDeps deps) => localizedApp(
      debugShowCheckedModeBanner: false,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  key: const Key('open-pairing'),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => PairingScreen(deps: deps))),
                  child: const Text('open'),
                ),
                ElevatedButton(
                  key: const Key('open-join'),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => PairingScreen(deps: deps, mode: RoomMode.join))),
                  child: const Text('join'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

/// Opens the "Erweitert" section [id] (KLD-098) and scrolls it into view
/// (no settle: a searching spinner may be running).
Future<void> openAdvanced(WidgetTester tester, String id) async {
  final toggle = find.byKey(Key('$id-toggle'));
  await tester.ensureVisible(toggle);
  await tester.pump();
  await tester.tap(toggle);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pumps frames with short real waits in between until [condition] holds.
///
/// [limit] is wall-clock time (`Stopwatch` is not faked by the widget test's
/// fake-async zone), so it only bounds a hang; generous for loaded CI runners.
Future<void> pumpUntil(WidgetTester tester, bool Function() condition,
    {String? what, Duration limit = const Duration(seconds: 15)}) async {
  final sw = Stopwatch()..start();
  while (true) {
    await tester.pump();
    if (condition()) return;
    if (sw.elapsed > limit) fail('condition not met${what == null ? '' : ': $what'}');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
}

/// Unmounts everything and gives the sockets a moment to close for real.
Future<void> unmountAndSettleSockets(WidgetTester tester, CreatedTransports created) async {
  await tester.pumpWidget(const SizedBox());
  for (final t in [...created.hosts, ...created.guests]) {
    t.dispose();
  }
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
}

/// The network connection bar's status sentence ("Du: Anna · Gegner: Ben",
/// KLD-107): since KLD-067 it is the bar's semantics label, shown as tokens
/// plus "Du: Anna" / "Gegner: Ben".
Finder netStatus(String text) => find.byWidgetPredicate(
    (w) => w is Semantics && w.key == const Key('net-status') && w.properties.label == text,
    description: 'net-status "$text"');
