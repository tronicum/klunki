// KLD-034 full flow: two complete apps side by side in one widget test. The
// left app hosts, the right app finds it through a shared FakeNetwork and
// joins; the transports are real NetworkTransports on 127.0.0.1. Both end up
// on the game screen of the shell and play against each other.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/connect4/connect4_board.dart';
import 'package:klunki/ui/games/connect4_screen.dart';
import 'package:klunki/ui/games/quartett_trumpf_screen.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import 'pairing_test_utils.dart';

const _timeout = Timeout(Duration(seconds: 45));
const _hostKey = Key('device-host');
const _guestKey = Key('device-guest');

Finder _on(Key device, Finder f) => find.descendant(of: find.byKey(device), matching: f);
bool _has(Key device, Finder f) => _on(device, f).evaluate().isNotEmpty;

class _Pair {
  final FakeDiscovery hostDiscovery, guestDiscovery;
  final CreatedTransports created;
  _Pair(this.hostDiscovery, this.guestDiscovery, this.created);
}

/// Pumps both apps, hosts [gameId] on the left, joins from the right via
/// the discovered host, and waits until both show [screen].
Future<_Pair> _connect(WidgetTester tester, String gameId, Type screen) async {
  tester.view.physicalSize = const Size(1800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final network = FakeNetwork();
  final hostDiscovery = FakeDiscovery(network: network, address: '192.168.0.10');
  final guestDiscovery = FakeDiscovery(network: network, address: '192.168.0.20');
  final created = CreatedTransports();
  final hostDeps = testDeps(discovery: hostDiscovery, created: created, name: 'Host-iPhone');
  final guestDeps = testDeps(discovery: guestDiscovery, created: created, name: 'Gast-iPad');

  Widget device(Key key, PairingDeps deps) => Expanded(child: KeyedSubtree(key: key, child: launcherApp(deps)));
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Row(children: [device(_hostKey, hostDeps), device(_guestKey, guestDeps)]),
  ));
  addTearDown(() => unmountAndSettleSockets(tester, created));

  // Host: open pairing, pick the game, host it.
  await tester.tap(_on(_hostKey, find.byKey(const Key('open-pairing'))));
  await tester.pumpAndSettle();
  await tester.tap(_on(_hostKey, find.byKey(Key('pair-game-$gameId'))));
  await tester.pump();
  await tester.tap(_on(_hostKey, find.byKey(const Key('pair-host-start'))));
  await pumpUntil(tester, () => _has(_hostKey, find.text('Warte auf Mitspieler…')), what: 'host waits');
  final port = created.hosts.single.port!;

  // Guest: open pairing, switch to "Beitreten", tap the discovered host.
  await tester.tap(_on(_guestKey, find.byKey(const Key('open-pairing'))));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1)); // route transition (the host's spinner never settles)
  await tester.tap(_on(_guestKey, find.text('Beitreten')));
  await tester.pump();
  final tile = _on(_guestKey, find.byKey(Key('pair-host-192.168.0.10:$port')));
  await pumpUntil(tester, () => tile.evaluate().isNotEmpty, what: 'guest lists the host');
  expect(_on(_guestKey, find.text('Host-iPhone')), findsOneWidget);
  await tester.tap(tile);

  await pumpUntil(tester, () => _has(_hostKey, find.byType(screen)) && _has(_guestKey, find.byType(screen)),
      what: 'both on the game screen');
  await tester.pump();
  await tester.pump(); // hint post-frame
  expect(hostDiscovery.advertised, isNull, reason: 'advertising stops once the guest is in');
  expect(created.joinCalls.single, ('192.168.0.10', port));
  return _Pair(hostDiscovery, guestDiscovery, created);
}

GameController _controller(WidgetTester tester, Key device) =>
    tester.widget<GameScreen>(_on(device, find.byType(GameScreen))).controller;

void main() {
  testWidgets('host + guest over loopback reach Connect Four; moves cross over; leaving tells the other side',
      (tester) async {
    final pair = await _connect(tester, 'connect4', Connect4Screen);

    // Who is who, and no hot-seat controls over the network.
    expect(_on(_hostKey, find.text('Du bist X · Gegner: Gast-iPad (O)')), findsOneWidget);
    expect(_on(_guestKey, find.text('Du bist O · Gegner: Host-iPhone (X)')), findsOneWidget);
    for (final d in [_hostKey, _guestKey]) {
      expect(_on(d, find.byKey(const Key('shell-undo'))), findsNothing);
      expect(_on(d, find.byKey(const Key('shell-restart'))), findsNothing);
      expect(_on(d, find.byKey(const Key('net-banner'))), findsNothing);
    }
    expect(_controller(tester, _hostKey).transport, isA<NetworkTransport>());

    Connect4Cell cell(Key d, int r, int c) => tester.widget<Connect4Cell>(_on(d, find.byKey(Key('c4-cell-$r-$c'))));

    // X (host) drops into column 3; it shows up on the guest.
    await tester.tap(_on(_hostKey, find.byKey(const Key('c4-column-3'))));
    await pumpUntil(tester, () => cell(_guestKey, 0, 3).owner == Player.a, what: 'X move on the guest');
    await tester.pump(connect4DropDuration + const Duration(milliseconds: 50));
    expect(cell(_hostKey, 0, 3).owner, Player.a);

    // O (guest) answers in column 4; it shows up on the host.
    await tester.tap(_on(_guestKey, find.byKey(const Key('c4-column-4'))));
    await pumpUntil(tester, () => cell(_hostKey, 0, 4).owner == Player.b, what: 'O move on the host');
    await tester.pump(connect4DropDuration + const Duration(milliseconds: 50));
    expect(_controller(tester, _hostKey).moves.length, 2);
    expect(_controller(tester, _guestKey).moves.length, 2);

    // The guest leaves: its transport is closed, the host sees the banner.
    final guestTransport = pair.created.guests.single;
    await tester.tap(_on(_guestKey, find.byType(BackButton)));
    await tester.pumpAndSettle();
    expect(_has(_guestKey, find.byType(Connect4Screen)), isFalse);
    expect(_has(_guestKey, find.byKey(const Key('open-pairing'))), isTrue, reason: 'back on the launcher');
    expect(guestTransport.connection.value, NetConnectionState.closed);
    expect(pair.guestDiscovery.isBrowsing, isFalse);

    await pumpUntil(tester, () => _has(_hostKey, find.byKey(const Key('net-banner'))), what: 'host banner');
    expect(_on(_hostKey, find.textContaining('Gegner hat das Spiel verlassen')), findsOneWidget);

    // The host leaves too: its transport is closed.
    await tester.tap(_on(_hostKey, find.byType(BackButton)));
    await tester.pumpAndSettle();
    expect(pair.created.hosts.single.connection.value, NetConnectionState.closed);
  }, timeout: _timeout);

  testWidgets('hidden-information game over the network never shows the handover cover', (tester) async {
    await _connect(tester, 'quartett-trumpf', QuartettTrumpfScreen);
    Finder cover(Key d) => _on(d, find.byKey(const Key('handover-cover'), skipOffstage: false));

    for (var round = 0; round < 3; round++) {
      final hostC = _controller(tester, _hostKey);
      final guestC = _controller(tester, _guestKey);
      if (hostC.game.isOver) break;
      expect(hostC.canAct != guestC.canAct, isTrue, reason: 'exactly one device acts');
      final mover = hostC.canAct ? _hostKey : _guestKey;
      final other = mover == _hostKey ? _guestKey : _hostKey;
      final before = hostC.moves.length;

      await tester.tap(_on(mover, find.byKey(const Key('qt-stat-ps'))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // reveal animation
      await tester.tap(_on(mover, find.byKey(const Key('qt-continue'))));
      await pumpUntil(
          tester,
          () =>
              _controller(tester, _hostKey).moves.length == before + 1 &&
              _controller(tester, _guestKey).moves.length == before + 1,
          what: 'pick #$round on both');
      await tester.pump();

      for (final d in [mover, other]) {
        expect(cover(d), findsNothing, reason: 'round $round');
        expect(_controller(tester, d).needsHandover, isFalse);
      }
      // The other device may be showing the trick reveal; dismiss it.
      final reveal = _on(other, find.byKey(const Key('qt-continue')));
      if (reveal.evaluate().isNotEmpty) {
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(reveal);
        await tester.pump();
      }
    }
  }, timeout: _timeout);
}
