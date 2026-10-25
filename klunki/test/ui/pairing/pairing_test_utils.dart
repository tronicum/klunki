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
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

const pingInterval = Duration(milliseconds: 100);
const netTimeout = Duration(seconds: 2);

/// Records every transport the factories created.
class CreatedTransports {
  final List<NetworkTransport> hosts = [];
  final List<NetworkTransport> guests = [];
  final List<(String, int)> joinCalls = [];
  final List<int> hostPorts = [];
}

/// Host on 127.0.0.1 (port as asked), created in the root zone.
Future<NetworkTransport> loopbackHost(CreatedTransports created, GameConfig config, {required String name, required int port}) {
  created.hostPorts.add(port);
  return Zone.root.run(() async {
    final t = await NetworkTransport.host(config,
        name: name, port: port, address: InternetAddress.loopbackIPv4, pingInterval: pingInterval, timeout: netTimeout);
    created.hosts.add(t);
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
  String name = 'Testgerät',
  List<String> addresses = const ['192.168.0.10', '10.0.0.7'],
  int preferredPort = 0,
  HostTransportFactory? hostTransport,
  JoinTransportFactory? joinTransport,
  Duration joinTimeout = const Duration(seconds: 12),
}) =>
    PairingDeps(
      discovery: () => discovery,
      hostTransport: hostTransport ??
          (config, {required name, required port}) => loopbackHost(created, config, name: name, port: port),
      joinTransport:
          joinTransport ?? (host, port, {required name}) => loopbackJoin(created, host, port, name: name),
      localAddresses: () async => addresses,
      deviceName: () => name,
      seed: () => 7,
      preferredPort: preferredPort,
      joinTimeout: joinTimeout,
    );

/// A launcher page with an "open" button that pushes the pairing screen, so
/// leaving the game / pairing screen has somewhere to go back to.
Widget launcherApp(PairingDeps deps) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('open-pairing'),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PairingScreen(deps: deps))),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

/// Pumps frames with short real waits in between until [condition] holds.
Future<void> pumpUntil(WidgetTester tester, bool Function() condition,
    {String? what, Duration limit = const Duration(seconds: 5)}) async {
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
