// KLD-034 full flow: two complete apps side by side in one widget test. The
// left app hosts, the right app finds it through a shared FakeNetwork and
// joins; the transports are real NetworkTransports on 127.0.0.1. Both end up
// on the game screen of the shell and play against each other. The player
// names (KLD-056) are "Anna" (host) and "Ben" (guest).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/connect4/connect4_board.dart';
import 'package:klunki/ui/games/connect4_screen.dart';
import 'package:klunki/ui/games/quartett_sets_screen.dart';
import 'package:klunki/ui/games/quartett_trumpf_screen.dart';
import 'package:klunki/ui/games/schiffe/schiffe_grid.dart';
import 'package:klunki/ui/games/schiffe_screen.dart';
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
Future<_Pair> _connect(WidgetTester tester, String gameId, Type screen, {String? deck}) async {
  tester.view.physicalSize = const Size(1800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final network = FakeNetwork();
  final hostDiscovery = FakeDiscovery(network: network, address: '192.168.0.10');
  final guestDiscovery = FakeDiscovery(network: network, address: '192.168.0.20');
  final created = CreatedTransports();
  final hostDeps = testDeps(discovery: hostDiscovery, created: created, name: 'Anna');
  final guestDeps = testDeps(discovery: guestDiscovery, created: created, name: 'Ben');

  Widget device(Key key, PairingDeps deps) => Expanded(child: KeyedSubtree(key: key, child: launcherApp(deps)));
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Row(children: [device(_hostKey, hostDeps), device(_guestKey, guestDeps)]),
  ));
  addTearDown(() => unmountAndSettleSockets(tester, created));

  // Host: "Raum starten", pick the game, start the room (on this device).
  await tester.tap(_on(_hostKey, find.byKey(const Key('open-pairing'))));
  await tester.pumpAndSettle();
  await tester.tap(_on(_hostKey, find.byKey(Key('pair-game-$gameId'))));
  await tester.pump();
  if (deck != null) {
    await tester.tap(_on(_hostKey, find.byKey(Key('pair-deck-$deck'))));
    await tester.pump();
  }
  await tester.tap(_on(_hostKey, find.byKey(const Key('pair-host-start'))));
  await pumpUntil(tester, () => _has(_hostKey, find.text('Warte auf Mitspieler…')), what: 'host waits');
  final port = created.hosts.single.port!;

  // Guest: "Raum beitreten", tap the room found nearby.
  await tester.tap(_on(_guestKey, find.byKey(const Key('open-join'))));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1)); // route transition (the host's spinner never settles)
  final tile = _on(_guestKey, find.byKey(Key('pair-host-192.168.0.10:$port')));
  await pumpUntil(tester, () => tile.evaluate().isNotEmpty, what: 'guest lists the host');
  expect(_on(_guestKey, find.textContaining('Raum von Anna: ')), findsOneWidget);
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
  testWidgets('host + guest over loopback reach Four in a Row; moves cross over; leaving tells the other side',
      (tester) async {
    final pair = await _connect(tester, 'connect4', Connect4Screen);

    // Who is who, and no hot-seat controls over the network.
    expect(_on(_hostKey, netStatus('Du (Anna, X) · Gegner: Ben (O)')), findsOneWidget);
    expect(_on(_guestKey, netStatus('Du (Ben, O) · Gegner: Anna (X)')), findsOneWidget);
    // KLD-067: each side as token (colour + mark) and name in the bar.
    PlayerToken token(Key device, String key) =>
        tester.widget<PlayerToken>(_on(device, find.byKey(Key(key))));
    expect(token(_hostKey, 'net-you-token').player, Player.a);
    expect(token(_hostKey, 'net-peer-token').player, Player.b);
    expect(token(_guestKey, 'net-you-token').player, Player.b);
    expect(token(_guestKey, 'net-you-token').gameId, 'connect4');
    expect(_on(_hostKey, find.text('Du (Anna)')), findsOneWidget);
    expect(_on(_hostKey, find.text('Gegner: Ben')), findsOneWidget);
    expect(_on(_hostKey, find.byKey(const Key('shell-waiting'))), findsNothing);
    expect(_on(_guestKey, find.byKey(const Key('shell-waiting'))), findsOneWidget);
    // The status line names the players (KLD-056).
    expect(_on(_hostKey, find.text('Du bist am Zug (X)')), findsOneWidget);
    expect(_on(_guestKey, find.text('Warte auf Anna (X)…')), findsOneWidget);
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
    expect(_on(_hostKey, find.text('Du bist am Zug (X)')), findsOneWidget);
    expect(_on(_guestKey, find.text('Warte auf Anna (X)…')), findsOneWidget);

    // The history names who moved, on both sides.
    for (final d in [_hostKey, _guestKey]) {
      await tester.tap(_on(d, find.byKey(const Key('shell-history'))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_on(d, find.textContaining('Anna (X): ')), findsOneWidget);
      expect(_on(d, find.textContaining('Ben (O): ')), findsOneWidget);
      await tester.tapAt(tester.getTopLeft(find.byKey(d)) + const Offset(8, 8)); // close the sheet
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    // The guest leaves: its transport is closed, the host sees the banner.
    final guestTransport = pair.created.guests.single;
    await tester.tap(_on(_guestKey, find.byType(BackButton)));
    await tester.pumpAndSettle();
    expect(_has(_guestKey, find.byType(Connect4Screen)), isFalse);
    expect(_has(_guestKey, find.byKey(const Key('open-pairing'))), isTrue, reason: 'back on the launcher');
    expect(guestTransport.connection.value, NetConnectionState.closed);
    expect(pair.guestDiscovery.isBrowsing, isFalse);

    await pumpUntil(tester, () => _has(_hostKey, find.byKey(const Key('net-banner'))), what: 'host banner');
    expect(_on(_hostKey, find.textContaining('Ben hat das Spiel verlassen')), findsOneWidget);

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
      // The host previews the trick and submits on "Weiter"; the guest holds
      // no deal (KLD-064), so its pick goes out at once and the accepted
      // event reveals the trick.
      if (mover == _hostKey) await tester.tap(_on(mover, find.byKey(const Key('qt-continue'))));
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
      // Devices may be showing the trick reveal; dismiss it.
      for (final d in [mover, other]) {
        final reveal = _on(d, find.byKey(const Key('qt-continue')));
        if (reveal.evaluate().isNotEmpty) {
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(reveal);
          await tester.pump();
        }
      }
    }
  }, timeout: _timeout);

  testWidgets('Quartett with a deck (KLD-069): the host picks rockets, the guest plays the rocket deck',
      (tester) async {
    await _connect(tester, 'quartett-sets', QuartettSetsScreen, deck: 'rockets');
    for (final d in [_hostKey, _guestKey]) {
      final c = _controller(tester, d);
      expect(c.config.deck, 'rockets');
      final game = c.game as QuartettGame;
      expect(game.deck.id, 'rockets');
      expect(_on(d, find.text('Quartett (Sets) · Raketen')), findsOneWidget, reason: 'app bar names the deck');
    }
    final guest = _controller(tester, _guestKey).game as QuartettGame;
    final own = guest.handOf(Player.b);
    expect(own, isNotEmpty);
    expect(own.every((c) => c.deck == 'rockets'), isTrue);
    expect(_on(_guestKey, find.text(own.first.name)), findsWidgets, reason: 'the guest shows its rocket cards');
  }, timeout: _timeout);

  testWidgets('Schiffe over the network: the guest renders its board from the redacted view (KLD-064)',
      (tester) async {
    await _connect(tester, 'schiffe', SchiffeScreen);
    SvLook look(Key d, String grid, int r, int c) =>
        tester.widget<SchiffeCellView>(_on(d, find.byKey(Key('sv-$grid-$r-$c')))).look;

    await tester.pump(const Duration(seconds: 1)); // route transitions
    // O (guest) may arrange its fleet while X still places (KLD-068), but
    // "Fertig" waits for its turn.
    bool doneEnabled(Key d) => tester.widget<ButtonStyleButton>(_on(d, find.byKey(const Key('sv-done')))).enabled;
    await tester.tap(_on(_guestKey, find.byKey(const Key('sv-random'))));
    await tester.pump();
    expect(_on(_guestKey, find.byKey(svShipMarkerKey)), findsNWidgets(19));
    expect(doneEnabled(_guestKey), isFalse);
    expect(_controller(tester, _hostKey).moves, isEmpty, reason: 'the draft stays on the guest');

    // X (host) places its fleet at random and confirms, then O.
    await tester.tap(_on(_hostKey, find.byKey(const Key('sv-random'))));
    await tester.pump();
    expect(doneEnabled(_hostKey), isTrue);
    await tester.tap(_on(_hostKey, find.byKey(const Key('sv-done'))));
    await pumpUntil(tester, () => _controller(tester, _guestKey).moves.length == 6, what: 'X fleet on the guest');
    await tester.pump();
    expect(doneEnabled(_guestKey), isTrue);
    // The guest's arrangement survived X's moves; confirm it.
    expect(_on(_guestKey, find.byKey(svShipMarkerKey)), findsNWidgets(19));
    await tester.tap(_on(_guestKey, find.byKey(const Key('sv-done'))));
    await pumpUntil(tester, () => _controller(tester, _hostKey).moves.length == 12, what: 'O fleet on the host');
    await tester.pump();

    final guestC = _controller(tester, _guestKey);
    expect(guestC.transport.fullInformation, isFalse);
    expect(guestC.game, isA<SchiffeView>(), reason: 'the guest holds a view, not the engine');
    final truth = _controller(tester, _hostKey).game as SchiffeGame;
    for (var i = 0; i < 6; i++) {
      expect(guestC.moves[i].move, {'action': 'place', 'ship': i}, reason: "X's positions never reach the guest");
    }

    // The guest's own grid shows its own fleet; its target grid shows no
    // trace of X's fleet.
    final mine = truth.ownGrid(Player.b);
    for (var r = 0; r < 10; r++) {
      for (var c = 0; c < 10; c++) {
        expect(look(_guestKey, 'own', r, c), mine[r][c] == SchiffeCell.ship ? SvLook.ship : SvLook.water);
        expect(look(_guestKey, 'target', r, c), SvLook.water);
      }
    }

    // X fires into the water of O's ocean: the guest's own grid shows the miss.
    final water = [
      for (var r = 0; r < 10; r++)
        for (var c = 0; c < 10; c++)
          if (mine[r][c] == SchiffeCell.empty) (r, c)
    ].first;
    await tester.tap(_on(_hostKey, find.byKey(Key('sv-target-${water.$1}-${water.$2}'))));
    await pumpUntil(tester, () => _controller(tester, _guestKey).moves.length == 13, what: 'X shot on the guest');
    await tester.pump();
    expect(look(_guestKey, 'own', water.$1, water.$2), SvLook.miss);

    // O fires at one of X's ship squares: the hit comes from the host's event.
    final hostShip = truth.placements(Player.a).first.cells.first;
    await tester.tap(_on(_guestKey, find.byKey(Key('sv-target-${hostShip[0]}-${hostShip[1]}'))));
    await pumpUntil(tester, () => _controller(tester, _guestKey).moves.length == 14, what: 'O shot');
    await tester.pump();
    expect(look(_guestKey, 'target', hostShip[0], hostShip[1]), anyOf(SvLook.hit, SvLook.sunk));
    expect((_controller(tester, _guestKey).moves.last.event.payload as Map)['result'], isNot('miss'));
    expect(_on(_guestKey, find.byKey(const Key('net-verification-failed'))), findsNothing);
  }, timeout: _timeout);
}
