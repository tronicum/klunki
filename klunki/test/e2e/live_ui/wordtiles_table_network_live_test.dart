// KLD-088 step 4: Wortgewandt for 3 players over the network, played to the
// end through the real UI on three phones side by side: host Anna, guest Ben
// (WebSocket, the browser's way) and guest Cleo (TCP through the seeded
// Wi-Fi latency proxy), each in its own NetworkGameSession over real sockets.
//
// Before the game: every device shows the lobby (who sits where, "Warte auf
// noch 1 Mitspieler…") and the game starts on all three once the last guest
// sat down. During the game, after every step: each device names the seat to
// move ("Du bist am Zug" on its own turn), holds the same number of moves,
// shows only its own rack (never another seat's tiles) and lets only its own
// seat act. Midway Cleo's connection drops: everyone sees the pause, nobody
// can move, Cleo comes back by herself and the game goes on. At the end
// every device shows the result and both guests verified the host's reveal.
//
//   cd klunki && flutter test test/e2e/live_ui/wordtiles_table_network_live_test.dart
//   KLUNKI_LIVE_UI_VERBOSE=1 flutter test test/e2e/live_ui/wordtiles_table_network_live_test.dart
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_net/klunki_net.dart' show Verification;

import '../../l10n/l10n_test_utils.dart';
import '../../support/test_run.dart';
import '../e2e_support.dart';
import 'live_ui_driver.dart';
import 'wordtiles_adapter.dart';

const _names = ['Anna', 'Ben', 'Cleo'];

/// The two-player adapter, with the rack check of a device by its seat (a
/// [UiDevice] knows only a [Player]; seat 2 has none).
class _TableAdapter extends WordTilesAdapter {
  final Map<UiDevice, int> seats;
  _TableAdapter(this.seats);

  @override
  void checkRack(WidgetTester tester, UiDevice d, WordTilesGame g) {
    if (g.isOver || g.allowRequest != null) return;
    final seat = seats[d]!;
    final n = g.rackSizeOf(seat);
    for (var i = 0; i < n; i++) {
      expect(d.on(find.byKey(Key('wordtiles-rack-$i'))), findsOneWidget,
          reason: '${d.name}: rack tile $i of $n not on screen');
    }
    expect(d.on(find.byKey(Key('wordtiles-rack-$n'))), findsNothing, reason: '${d.name}: one rack only');
  }
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('3 players on 3 devices: lobby, a whole game, a dropped guest pauses the table, verified at the end',
      (tester) async {
    const config = GameConfig('wordtiles', seed: 5, players: 3);
    tester.view.physicalSize = const Size(390.0 * 3, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final alive = testRunGuard(tester);

    final (host, proxy) = (await tester.runAsync(() async {
      final h = await NetworkTransport.host(config,
          name: 'Anna', address: loopback, pingInterval: pingInterval, timeout: widgetNetTimeout);
      final p = await WifiProxy.start(h.port!, seed: config.seed);
      return (h, p);
    }))!;
    final guests = <NetworkTransport>[];
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      for (final g in guests) {
        g.dispose();
      }
      host.dispose();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await proxy.close();
      });
    });

    final devices = [
      for (var s = 0; s < 3; s++) UiDevice(_names[s], scope: Key('device-$s'), me: s == 0 ? Player.a : Player.b),
    ];
    final transports = <NetworkTransport?>[host, null, null];
    Widget phone(int s) => Expanded(
          child: KeyedSubtree(
            key: Key('device-$s'),
            child: transports[s] == null
                ? const ColoredBox(color: Colors.black12)
                : localizedApp(NetworkGameSession(transport: transports[s]!), debugShowCheckedModeBanner: false),
          ),
        );
    Future<void> show() => tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [for (var s = 0; s < 3; s++) phone(s)]),
        ));
    Future<void> net() async {
      alive();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
      await tester.pump();
      await tester.pump();
    }

    Future<void> until(bool Function() done, String why) async {
      final clock = Stopwatch()..start();
      for (var i = 0; i < 2000 || clock.elapsed < const Duration(minutes: 1); i++) {
        if (done()) {
          await net();
          return;
        }
        await net();
      }
      fail('timed out: $why');
    }

    String? textOf(UiDevice d, Key k) {
      final f = d.on(find.byKey(k));
      return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
    }

    // --- The lobby: Anna's room waits for two, then for one.
    await show();
    await net();
    expect(devices[0].hasKey(const Key('table-lobby')), isTrue);
    expect(textOf(devices[0], const Key('table-waiting')), deL10n.tableWaitingFor(2));
    final ben = (await tester.runAsync(() => NetworkTransport.joinWebSocket(
        Uri.parse('ws://${loopback.address}:${host.wsPort}'),
        name: 'Ben',
        pingInterval: pingInterval,
        timeout: widgetNetTimeout)))!;
    guests.add(ben);
    transports[1] = ben;
    await show();
    await until(() => devices[0].has(find.text('Ben')) && devices[1].hasKey(const Key('table-waiting')), 'Ben sits');
    for (final d in devices.take(2)) {
      expect(textOf(d, const Key('table-waiting')), deL10n.tableWaitingFor(1), reason: d.name);
      expect(d.has(find.text(deL10n.tableSeatFree)), isTrue, reason: d.name);
    }
    expect(devices[1].has(find.text(deL10n.netBarYou('Ben'))), isTrue);
    expect(devices[1].has(find.text(deL10n.roomOfPlayer('Anna', 'Wortgewandt'))), isTrue);
    expect(devices[1].has(find.byType(SeatGameScreen)), isFalse, reason: 'no game before the table is full');
    final cleo = (await tester.runAsync(() => NetworkTransport.join(loopback, proxy.port,
        name: 'Cleo', pingInterval: pingInterval, timeout: widgetNetTimeout)))!;
    guests.add(cleo);
    transports[2] = cleo;
    await show();
    await until(() => devices.every((d) => d.has(find.byType(SeatGameScreen))), 'the game starts everywhere');
    expect([for (final t in transports) t!.seat], [0, 1, 2]);

    // --- The game.
    final adapter = _TableAdapter({for (var s = 0; s < 3; s++) devices[s]: s});
    final rng = Random(5);
    final engine = host.game as WordTilesGame;
    var dropped = false;
    for (var step = 0; step < 3000 && !engine.isOver; step++) {
      final n = host.moves.length;
      final actor = engine.actorSeat!;
      for (var s = 0; s < 3; s++) {
        final d = devices[s];
        final c = d.controller(tester);
        final g = c.game as WordTilesGame;
        expect(transports[s]!.moves.length, n, reason: '${d.name} at step $step');
        expect(textOf(d, const Key('shell-status')),
            s == actor ? deL10n.shellYourTurn : deL10n.shellToMove(_names[actor]),
            reason: '${d.name} at step $step');
        expect(c.canAct, s == actor, reason: '${d.name} at step $step');
        // Only its own rack: the other seats' tiles never reach a guest.
        if (s > 0) {
          for (var o = 0; o < 3; o++) {
            if (o == s || engine.rackOf(o).isEmpty) continue;
            expect(g.rackOf(o), isNot(engine.rackOf(o)), reason: '${d.name} knows seat $o\'s rack');
          }
        }
      }
      // Midway: Cleo's connection breaks; the table pauses until she is back.
      if (!dropped && n >= 12 && actor != 2) {
        dropped = true;
        proxy.refuse = true;
        await tester.runAsync(() async => proxy.cut());
        await until(() => host.paused && devices[0].hasKey(const Key('net-banner')), 'the host sees the pause');
        expect(devices[0].has(find.text(deL10n.tablePaused('Cleo'))), isTrue);
        await until(() => devices[1].has(find.text(deL10n.tablePaused('Cleo'))), 'Ben sees the pause too');
        expect(devices[0].hasKey(const Key('table-let-leave-2')), isTrue, reason: 'the host may let Cleo leave');
        expect(devices[0].controller(tester).canAct, isFalse, reason: 'nobody moves while Cleo is away');
        expect((await tester.runAsync(() => host.submit(const {'action': 'pass'})))!.isAccepted, isFalse);
        proxy.refuse = false;
        await until(() => !host.paused && !devices[0].hasKey(const Key('net-banner')), 'Cleo comes back');
        await until(() => cleo.connection.value == NetConnectionState.connected, 'Cleo reconnected');
        continue;
      }
      final d = devices[actor];
      final m = await adapter.play(tester, d, rng);
      if (m == null) fail('${d.name} has nothing to do at step $step');
      await until(() => host.moves.length > n && guests.every((g) => g.moves.length == host.moves.length),
          '${d.name}\'s ${m['action']} on every device');
      expect(host.moves[n].seat, actor);
      expect(host.moves[n].move['action'], m['action']);
    }
    expect(engine.isOver, isTrue, reason: 'the game did not end');
    expect(dropped, isTrue);
    await until(() => devices.every((d) => d.resultShown()), 'the result on every device');
    for (final g in guests) {
      await until(() => g.verification.value != Verification.pending, 'verification');
      expect(g.verification.value, Verification.verified);
    }
    for (final d in devices) {
      expect(d.hasKey(const Key('net-verification-failed')), isFalse, reason: d.name);
      expect(d.hasKey(const Key('result-again')), isFalse, reason: '${d.name}: no "Nochmal" over the network');
    }
    debugPrint('wordtiles table: ${adapter.tapped}, ${host.moves.length} moves, ${engine.seatResult.code}, '
        'scores ${engine.scores}');
  }, timeout: liveUiTimeout);
}
