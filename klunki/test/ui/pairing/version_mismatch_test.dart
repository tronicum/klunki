// KLD-085: two builds that do not fit together (e.g. an iPhone on a new
// build and a cached older PWA) get a clear "please update" message instead
// of a game that silently diverges.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/build_info.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki_net/guest_web.dart'
    show Incompatibility, NetException, PeerAge, VersionMismatch, protocolVersion;

import 'pairing_test_utils.dart';

const _timeout = Timeout(Duration(seconds: 30));

Future<void> _openPairing(WidgetTester tester, PairingDeps deps, {bool join = false}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(launcherApp(deps));
  await tester.tap(find.byKey(Key(join ? 'open-join' : 'open-pairing')));
  if (join) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // the "searching" spinner never settles
  } else {
    await tester.pumpAndSettle();
  }
}

NetException _refused(PeerAge peer) => NetException('incompatible versions (incompatible-content): …',
    mismatch: VersionMismatch(Incompatibility.content, peer, 'data of "quartett-trumpf/rockets" differs'));

Future<void> _joinFailing(WidgetTester tester, NetException error) async {
  await _openPairing(
    tester,
    testDeps(
      discovery: FakeDiscovery(),
      created: CreatedTransports(),
      joinTransport: (host, port, {required name}) => Future.error(error),
    ),
    join: true,
  );
  await openAdvanced(tester, 'pair-join-advanced');
  await tester.enterText(find.byKey(const Key('pair-manual')), '192.168.1.20');
  await tester.tap(find.byKey(const Key('pair-manual-connect')));
  await tester.pump();
  await tester.pump();
}

void main() {
  group('join: the mismatch message says which device to update', () {
    for (final (peer, text) in [
      (PeerAge.older, 'Das andere Gerät hat eine ältere Version. Bitte dort die App aktualisieren (Browser: neu laden).'),
      (PeerAge.newer, 'Dieses Gerät hat eine ältere Version. Bitte diese App aktualisieren (Browser: neu laden).'),
      (PeerAge.unknown, 'Die Spielversionen passen nicht zusammen – bitte beide Apps aktualisieren (Browser: neu laden).'),
    ]) {
      testWidgets('peer ${peer.name}', (tester) async {
        await _joinFailing(tester, _refused(peer));
        expect(find.byKey(const Key('pair-join-error')), findsOneWidget);
        expect(find.textContaining(text), findsOneWidget);
        // Not a network problem: no Wi-Fi hints, no raw English text.
        expect(find.textContaining('selben WLAN'), findsNothing);
        expect(find.textContaining('incompatible'), findsNothing);
      });
    }
  });

  group('KLD-116: the message also says who has which version', () {
    testWidgets('both names known', (tester) async {
      await _joinFailing(
          tester,
          NetException('incompatible versions …',
              mismatch: const VersionMismatch(Incompatibility.content, PeerAge.newer, 'x',
                  peerBuild: '1.1.0+2026110301 c3d4e5f0',
                  myBuild: '1.0.0+2026110201 b8752a9',
                  myName: 'Anna',
                  peerName: 'Ben')));
      expect(
          find.textContaining('Dieses Gerät hat eine ältere Version. Bitte diese App aktualisieren (Browser: neu laden).\n'
              'Anna hat 1.0.0 (b8752a9), Ben hat 1.1.0 (c3d4e5f).'),
          findsOneWidget);
    });

    testWidgets('other name unknown, this build from the app', (tester) async {
      await _joinFailing(
          tester,
          NetException('incompatible versions …',
              mismatch: const VersionMismatch(Incompatibility.protocol, PeerAge.older, 'x',
                  peerBuild: '0.9.0+3 abc1234', myName: 'Anna')));
      expect(find.textContaining('Dieses Gerät hat $appVersionLine, das andere Gerät hat 0.9.0 (abc1234).'),
          findsOneWidget);
    });

    testWidgets('no build label from the other side: no version line', (tester) async {
      await _joinFailing(tester, _refused(PeerAge.unknown));
      expect(find.textContaining(' hat '), findsNothing);
    });
  });

  testWidgets('KLD-116: host: the turned-away guest\'s name and version are shown', (tester) async {
    final created = CreatedTransports();
    await _openPairing(tester, testDeps(discovery: FakeDiscovery(), created: created));
    await tester.tap(find.byKey(const Key('pair-host-start')));
    await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty,
        what: 'host waiting view');
    final port = created.hosts.single.port!;
    // A current protocol, but a build that knows none of the games.
    await tester.runAsync(() async {
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
      socket.writeln(jsonEncode({
        'type': 'hello',
        'v': protocolVersion,
        'role': 'guest',
        'name': 'Ben',
        'protocol': protocolVersion,
        'build': '0.9.0+2026010101 abc1234',
        'games': <String, dynamic>{},
      }));
      await socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).first;
      socket.destroy();
    });
    await pumpUntil(tester, () => find.byKey(const Key('host-refused-guest')).evaluate().isNotEmpty,
        what: 'refused-guest notice');
    final text = tester.widget<Text>(find.byKey(const Key('host-refused-guest'))).data!;
    expect(text, contains('Das andere Gerät hat eine ältere Version.'));
    expect(text, endsWith('hat $appVersionLine, Ben hat 0.9.0 (abc1234).'));
    await unmountAndSettleSockets(tester, created);
  }, timeout: _timeout);

  testWidgets('host: a guest from an older build (protocol 2) is refused and the host is told', (tester) async {
    final created = CreatedTransports();
    await _openPairing(tester, testDeps(discovery: FakeDiscovery(), created: created));
    await tester.tap(find.byKey(const Key('pair-host-start')));
    await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty,
        what: 'host waiting view');
    final port = created.hosts.single.port!;

    // An old app: protocol 2, no fingerprints in its hello.
    final error = await tester.runAsync(() async {
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
      socket.writeln(jsonEncode({'type': 'hello', 'v': 2, 'role': 'guest', 'name': 'Old', 'protocol': 2}));
      final line = await socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).first;
      socket.destroy();
      return jsonDecode(line) as Map<String, dynamic>;
    });
    // The old app can read the answer (its own envelope version).
    expect(error!['v'], 2);
    expect(error['code'], 'incompatible-protocol');

    await pumpUntil(tester, () => find.byKey(const Key('host-refused-guest')).evaluate().isNotEmpty,
        what: 'refused-guest notice');
    expect(
        find.text('Ein Gerät wollte beitreten, wurde aber abgewiesen: Die Spielversionen passen nicht zusammen: '
            'Das andere Gerät hat eine ältere Version. Bitte dort die App aktualisieren (Browser: neu laden).'),
        findsOneWidget);
    // Still waiting for a guest that fits.
    expect(find.byKey(const Key('pair-host-waiting')), findsOneWidget);
    await unmountAndSettleSockets(tester, created);
  }, timeout: _timeout);
}
