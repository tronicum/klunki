// KLD-088: the countdown before a table of 3–4 starts, "Pause" in the status
// pill while a player is away, and the plural name hint of the room setup.
// Real loopback transports (see pairing_test_utils.dart); the host's
// countdown tick is an hour, so the tests take its steps themselves
// (`debugAdvanceCountdown`) and nothing depends on timing.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import 'pairing_test_utils.dart';

const _never = Duration(hours: 1);

/// The number of the countdown on screen (the last one while the old
/// number fades out).
String? _countdownNumber(WidgetTester tester) {
  final f = find.byKey(const Key('table-countdown-number'));
  return f.evaluate().isEmpty ? null : (f.evaluate().last.widget as Text).data;
}

Future<NetworkTransport> _join(WidgetTester tester, int port, String name) async =>
    (await tester.runAsync(() => NetworkTransport.join(InternetAddress.loopbackIPv4, port,
        name: name, pingInterval: pingInterval, timeout: netTimeout)))!;

Future<void> _step(WidgetTester tester, NetworkTransport host) =>
    tester.runAsync(() async => host.debugAdvanceCountdown());

void main() {
  testWidgets('a guest sees "Alle sind da!" and the host\'s countdown; a leave stops it, the game starts after 1',
      (tester) async {
    const config = GameConfig('wordtiles', seed: 3, players: 3);
    final host = (await tester.runAsync(() => NetworkTransport.host(config,
        name: 'Anna',
        address: InternetAddress.loopbackIPv4,
        pingInterval: pingInterval,
        timeout: netTimeout,
        countdownTick: _never)))!;
    final guests = <NetworkTransport>[];
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      for (final t in [...guests, host]) {
        t.dispose();
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    });
    final ben = await _join(tester, host.port!, 'Ben');
    guests.add(ben);
    await tester.pumpWidget(localizedApp(NetworkGameSession(transport: ben)));
    await pumpUntil(tester, () => find.byKey(const Key('table-waiting')).evaluate().isNotEmpty, what: 'the lobby');
    expect(find.text(deL10n.tableWaitingFor(1)), findsOneWidget);
    expect(find.byKey(const Key('table-countdown')), findsNothing);

    // Cleo completes the table: 5 on Ben's screen.
    final cleo = await _join(tester, host.port!, 'Cleo');
    guests.add(cleo);
    await pumpUntil(tester, () => _countdownNumber(tester) == '5', what: 'the countdown');
    expect(find.text(deL10n.tableAllHere), findsOneWidget);
    expect(find.text(deL10n.tableStartsIn), findsOneWidget);
    expect(find.byKey(const Key('table-waiting')), findsNothing);
    expect(find.byType(SeatGameScreen), findsNothing);
    await _step(tester, host);
    await _step(tester, host);
    await pumpUntil(tester, () => _countdownNumber(tester) == '3', what: '3');
    expect(host.countdown, 3);

    // Cleo leaves: back to waiting.
    await tester.runAsync(() async => cleo.dispose());
    guests.remove(cleo);
    await pumpUntil(tester, () => find.byKey(const Key('table-waiting')).evaluate().isNotEmpty, what: 'waiting again');
    expect(find.byKey(const Key('table-countdown')), findsNothing);
    expect(find.text(deL10n.tableWaitingFor(1)), findsOneWidget);
    expect(host.countdown, isNull);

    // Cleo again: from 5; five steps later the game opens.
    guests.add(await _join(tester, host.port!, 'Cleo'));
    await pumpUntil(tester, () => _countdownNumber(tester) == '5', what: 'the countdown again');
    for (var i = 0; i < 4; i++) {
      await _step(tester, host);
    }
    await pumpUntil(tester, () => _countdownNumber(tester) == '1', what: '1');
    expect(ben.started, isFalse);
    await _step(tester, host);
    await pumpUntil(tester, () => find.byType(SeatGameScreen).evaluate().isNotEmpty, what: 'the game');
    expect(find.byKey(const Key('table-countdown')), findsNothing);
    expect(find.text(deL10n.shellToMove('Anna')), findsOneWidget);
  });

  testWidgets('the host counts down in the room (no QR code meanwhile) and opens the game after it; '
      'the name hint is plural for 3–4', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final created = CreatedTransports();
    final deps = testDeps(
      discovery: FakeDiscovery(),
      created: created,
      name: 'Anna',
      hostTransport: (config, {required name, required port, required wsPort}) =>
          loopbackHost(created, config, name: name, port: port, wsPort: wsPort, countdownTick: _never),
    );
    final guests = <NetworkTransport>[];
    addTearDown(() async {
      for (final g in guests) {
        g.dispose();
      }
      await unmountAndSettleSockets(tester, created);
    });
    await tester.pumpWidget(localizedApp(
        PairingScreen(deps: deps, nameController: PlayerNameController.memory(name: 'Anna'), gameId: 'wordtiles')));
    await tester.pump();
    expect(find.text(deL10n.pairingDeviceNameHelper), findsOneWidget, reason: '2 players: one other player');
    await tester.tap(find.byKey(const Key('pair-players-3')));
    await tester.pump();
    expect(find.text(deL10n.pairingDeviceNameHelperTable), findsOneWidget);
    expect(find.text(deL10n.pairingDeviceNameHelper), findsNothing);
    await tester.tap(find.byKey(const Key('pair-players-2')));
    await tester.pump();
    expect(find.text(deL10n.pairingDeviceNameHelper), findsOneWidget);
    await tester.tap(find.byKey(const Key('pair-players-4')));
    await tester.pump();
    expect(find.text(deL10n.pairingDeviceNameHelperTable), findsOneWidget);
    await tester.tap(find.byKey(const Key('pair-players-3')));
    await tester.pump();

    final dict = find.byKey(const Key('pair-wordtiles-dict'));
    await tester.ensureVisible(dict);
    await tester.tap(dict); // no word list download in a test
    await tester.pump();
    final start = find.byKey(const Key('pair-host-start'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await pumpUntil(tester, () => find.byKey(const Key('table-lobby')).evaluate().isNotEmpty, what: 'the lobby');
    final host = created.hosts.single;
    expect(find.byKey(const Key('pair-qr')), findsOneWidget);
    guests.add(await _join(tester, host.port!, 'Ben'));
    guests.add(await _join(tester, host.port!, 'Cleo'));
    await pumpUntil(tester, () => _countdownNumber(tester) == '5', what: 'the countdown on the host');
    expect(find.text(deL10n.tableAllHere), findsOneWidget);
    expect(find.byKey(const Key('pair-qr')), findsNothing, reason: 'the table is full');
    expect(find.byKey(const Key('pair-host-waiting')), findsOneWidget, reason: 'still in the room');
    for (var i = 0; i < 5; i++) {
      await _step(tester, host);
    }
    await pumpUntil(tester, () => find.byType(SeatGameScreen).evaluate().isNotEmpty, what: 'the game on the host');
    expect(find.text(deL10n.shellYourTurn), findsOneWidget);
  });

  testWidgets('a paused table: the status pill says "Pause" instead of whose turn it is', (tester) async {
    const config = GameConfig('wordtiles', seed: 2, players: 3);
    final controller = GameController.hotSeat(config);
    addTearDown(controller.dispose);
    Widget app(bool paused) => localizedApp(SeatLabelsScope(
          labels: SeatLabels(const ['Anna', 'Ben', 'Cleo'], 1, paused),
          // The seat shell itself (the hot-seat screen adds the app's names).
          child: SeatGameScreen(controller: controller, boardBuilder: (context, controller) => const SizedBox()),
        ));
    await tester.pumpWidget(app(false));
    await tester.pump();
    String status() => tester.widget<Text>(find.byKey(const Key('shell-status'))).data!;
    expect(status(), deL10n.shellToMove('Anna'));
    expect(find.byKey(const Key('shell-paused')), findsNothing);
    await tester.pumpWidget(app(true));
    await tester.pump();
    expect(status(), deL10n.seatPausedStatus);
    expect(find.byKey(const Key('shell-paused')), findsOneWidget);
    await tester.pumpWidget(app(false));
    await tester.pump();
    expect(status(), deL10n.shellToMove('Anna'));
  });
}
