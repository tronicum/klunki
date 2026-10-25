import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/ui/games/schiffe/schiffe_describe.dart';
import 'package:klunki/ui/games/schiffe/schiffe_grid.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../shell/shell_test_utils.dart';
import '../../l10n/l10n_test_utils.dart';

Finder own(int r, int c) => find.byKey(Key('sv-own-$r-$c'));
Finder target(int r, int c) => find.byKey(Key('sv-target-$r-$c'));
SchiffeCellView cellOf(WidgetTester t, Finder f) => t.widget<SchiffeCellView>(f);
SchiffeGame gameOf(GameController c) => c.game as SchiffeGame;

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pump();
}

Future<void> acknowledge(WidgetTester tester) async {
  expect(find.byKey(handoverContinue), findsOneWidget);
  await tester.tap(find.byKey(handoverContinue));
  await tester.pump();
}

/// Both players place their fleets with "Zufällig" (with the handover in
/// between) and the battle starts with X to move.
Future<void> randomFleets(WidgetTester tester, GameController c) async {
  await tapKey(tester, 'sv-random');
  await acknowledge(tester);
  await tapKey(tester, 'sv-random');
  await acknowledge(tester);
  expect(gameOf(c).phase, SchiffePhase.battle);
}

/// Every target cell of the current view: never an unhit ship.
void expectNoEnemyShips(WidgetTester tester, GameController c) {
  final g = gameOf(c);
  final known = g.targetGrid(g.currentPlayer);
  for (var r = 0; r < 10; r++) {
    for (var col = 0; col < 10; col++) {
      final f = target(r, col);
      final look = cellOf(tester, f).look;
      expect(look, isNot(anyOf(SvLook.ship, SvLook.shipHit)), reason: 'target $r,$col');
      expect(find.descendant(of: f, matching: find.byKey(svShipMarkerKey)), findsNothing);
      if (known[r][col] == ShotMark.unknown) expect(look, SvLook.water);
    }
  }
}

void main() {
  group('setup', () {
    testWidgets('shows the next ship, labels and the fleet list', (tester) async {
      await pumpGame(tester, 'schiffe');
      expect(find.byKey(const Key('sv-next-ship')), findsOneWidget);
      expect(find.text('Schlachtschiff (5)'), findsWidgets);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('sv-fleet-$i'), skipOffstage: false), findsOneWidget);
      }
      expect(find.byKey(const Key('sv-fleet-6'), skipOffstage: false), findsNothing);
      expect(find.byKey(const Key('shell-hint')), findsOneWidget);
    });

    testWidgets('manual placement: invalid preview is red, valid is green, tap places', (tester) async {
      final c = await pumpGame(tester, 'schiffe');

      // Horizontal Schlachtschiff at J8 would leave the board: red, not placed.
      var g = await tester.startGesture(tester.getCenter(own(9, 7)));
      await tester.pump();
      expect(cellOf(tester, own(9, 7)).preview, SvPreview.invalid);
      expect(cellOf(tester, own(9, 9)).preview, SvPreview.invalid);
      expect(cellOf(tester, own(9, 6)).preview, isNull);
      await g.up();
      await tester.pump();
      expect(c.moves, isEmpty);
      expect(cellOf(tester, own(9, 7)).preview, isNull);

      // A1 horizontal fits: green across A1–A5.
      g = await tester.startGesture(tester.getCenter(own(0, 0)));
      await tester.pump();
      for (var col = 0; col < 5; col++) {
        expect(cellOf(tester, own(0, col)).preview, SvPreview.valid);
      }
      expect(cellOf(tester, own(0, 5)).preview, isNull);
      await g.up();
      await tester.pump();
      expect(c.moves, hasLength(1));
      expect(gameOf(c).placements(Player.a).single.cells, [
        for (var i = 0; i < 5; i++) [0, i],
      ]);
      for (var col = 0; col < 5; col++) {
        expect(cellOf(tester, own(0, col)).look, SvLook.ship);
      }
      expect(find.text('Kreuzer (4)'), findsWidgets);

      // Next ship (Kreuzer) touching the Schlachtschiff at B2: invalid.
      g = await tester.startGesture(tester.getCenter(own(1, 1)));
      await tester.pump();
      expect(cellOf(tester, own(1, 1)).preview, SvPreview.invalid);
      await g.up();
      await tester.pump();
      expect(c.moves, hasLength(1));

      // Rotate to vertical and place at C1 (rows C–F): valid.
      await tapKey(tester, 'sv-rotate');
      expect(find.text('Vertikal'), findsOneWidget);
      g = await tester.startGesture(tester.getCenter(own(2, 0)));
      await tester.pump();
      for (var r = 2; r < 6; r++) {
        expect(cellOf(tester, own(r, 0)).preview, SvPreview.valid);
      }
      await g.up();
      await tester.pump();
      final p = gameOf(c).placements(Player.a);
      expect(p, hasLength(2));
      expect(p[1].horizontal, isFalse);
      expect(describeSchiffeMove(deL10n, c.moves[0]), 'platziert ein Schiff');
    });

    testWidgets('dragging moves the preview; lifting places at the last cell', (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      final g = await tester.startGesture(tester.getCenter(own(9, 9)));
      await tester.pump();
      expect(cellOf(tester, own(9, 9)).preview, SvPreview.invalid);
      await g.moveTo(tester.getCenter(own(4, 2)));
      await tester.pump();
      expect(cellOf(tester, own(9, 9)).preview, isNull);
      expect(cellOf(tester, own(4, 6)).preview, SvPreview.valid);
      await g.up();
      await tester.pump();
      expect(gameOf(c).placements(Player.a).single.row, 4);
      expect(gameOf(c).placements(Player.a).single.col, 2);
    });

    testWidgets('"Zufällig" completes the fleet and the cover appears before O sets up', (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      // Place one ship by hand first, random fills the rest.
      await tester.tap(own(0, 0));
      await tester.pump();
      await tapKey(tester, 'sv-random');
      expect(gameOf(c).nextShipIndex(Player.a), isNull);
      expect(gameOf(c).placements(Player.a), hasLength(6));
      expect(describeSchiffeMove(deL10n, c.moves.last), 'platziert 5 Schiffe zufällig');

      // Handover to O: X's fleet is hidden behind the cover.
      expect(c.needsHandover, isTrue);
      expect(find.text('Gib das Gerät an O weiter'), findsOneWidget);
      expect(own(0, 0).hitTestable(), findsNothing);
      await acknowledge(tester);

      // O sees an empty ocean (not X's ships) and places their own fleet.
      expect(find.text('O ist am Zug'), findsOneWidget);
      expect(find.byKey(svShipMarkerKey), findsNothing);
      expect(find.text('Schlachtschiff (5)'), findsWidgets);
      await tapKey(tester, 'sv-random');
      expect(gameOf(c).placements(Player.b), hasLength(6));
      expect(c.needsHandover, isTrue);
      await acknowledge(tester);

      expect(gameOf(c).phase, SchiffePhase.battle);
      expect(find.text('X ist am Zug'), findsOneWidget);
      expect(find.text('Gegner'), findsOneWidget);
      expect(find.text('Dein Meer'), findsOneWidget);
      // X's own fleet is visible again: 19 ship cells.
      expect(find.byKey(svShipMarkerKey), findsNWidgets(19));
    });
  });

  group('battle', () {
    testWidgets('a miss passes the turn (cover), a hit keeps it', (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      await randomFleets(tester, c);
      final g = gameOf(c);

      // Find O's ships only through the engine (never through the UI).
      final oShips = {
        for (final p in g.placements(Player.b))
          for (final cell in p.cells) cell[0] * 10 + cell[1],
      };
      final hitCell = oShips.first;
      final missCell = List.generate(100, (i) => i).firstWhere((i) => !oShips.contains(i));

      await tester.tap(target(hitCell ~/ 10, hitCell % 10));
      await tester.pump();
      expect(c.needsHandover, isFalse);
      expect(g.currentPlayer, Player.a);
      expect(find.textContaining('Treffer! Nochmal'), findsWidgets);
      expect(find.byKey(const Key('sv-extra-shot')), findsOneWidget);
      expect(cellOf(tester, target(hitCell ~/ 10, hitCell % 10)).look, anyOf(SvLook.hit, SvLook.sunk));
      expect(
        describeSchiffeMove(deL10n, c.moves.last),
        startsWith('schießt auf ${svCellName(hitCell ~/ 10, hitCell % 10)}: '),
      );

      // Firing at a known cell does nothing.
      await tester.tap(target(hitCell ~/ 10, hitCell % 10));
      await tester.pump();
      expect(c.moves.where((m) => m.move['action'] == 'fire'), hasLength(1));

      await tester.tap(target(missCell ~/ 10, missCell % 10));
      await tester.pump();
      expect(g.currentPlayer, Player.b);
      expect(c.needsHandover, isTrue);
      expect(describeSchiffeMove(deL10n, c.moves.last), 'schießt auf ${svCellName(missCell ~/ 10, missCell % 10)}: Wasser');
      await acknowledge(tester);

      // O's view: X's shots show up on O's own grid; O's target grid is unknown.
      expect(find.text('O ist am Zug'), findsOneWidget);
      expect(cellOf(tester, own(missCell ~/ 10, missCell % 10)).look, SvLook.miss);
      expect(cellOf(tester, own(hitCell ~/ 10, hitCell % 10)).look, anyOf(SvLook.shipHit, SvLook.sunk));
      expect(find.byKey(const Key('sv-incoming')), findsOneWidget);
      expect(find.byKey(const Key('sv-extra-shot')), findsNothing);
      expectNoEnemyShips(tester, c);
    });

    testWidgets('sunk ships are filled and outlined; remaining counts update', (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      await randomFleets(tester, c);
      final g = gameOf(c);
      final sub = g.placements(Player.b).last; // a 2-cell U-Boot
      for (final cell in sub.cells) {
        await tester.tap(target(cell[0], cell[1]));
        await tester.pump();
      }
      for (final cell in sub.cells) {
        expect(cellOf(tester, target(cell[0], cell[1])).look, SvLook.sunk);
      }
      expect(sunkShips(g.targetGrid(Player.a)).single.cells, sub.cells);
      expect(find.textContaining('U-Boot versenkt – Treffer! Nochmal'), findsOneWidget);
      expect(find.text('Deine Flotte: 6 · Gegner (O): 5 Schiffe übrig'), findsOneWidget);
      expect(describeSchiffeMove(deL10n, c.moves.last), endsWith(': U-Boot versenkt'));
    });

    testWidgets('the target grid never shows unhit enemy ships', (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      await randomFleets(tester, c);
      expectNoEnemyShips(tester, c);
      // A few turns for both sides, checking after every handover.
      for (var turn = 0; turn < 6; turn++) {
        final legal = gameOf(c).legalMoves;
        final m = legal[(turn * 37) % legal.length];
        await tester.tap(target(m['row'] as int, m['col'] as int));
        await tester.pump();
        if (c.needsHandover) await acknowledge(tester);
        expectNoEnemyShips(tester, c);
      }
      // Only the player to move's ships appear anywhere (own grid only).
      final g = gameOf(c);
      final ownShipCells = g.ownGrid(g.currentPlayer).expand((row) => row).where((x) => x == SchiffeCell.ship).length;
      final hitCells = g.ownGrid(g.currentPlayer).expand((row) => row).where((x) => x == SchiffeCell.hit).length;
      expect(find.byKey(svShipMarkerKey), findsNWidgets(ownShipCells + hitCells));
    });

    testWidgets('full game: random fleets, shots in order, ends in the result dialog', (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      await randomFleets(tester, c);
      final next = {Player.a: 0, Player.b: 0};
      for (var step = 0; step < 500; step++) {
        if (find.byKey(resultDialog).evaluate().isNotEmpty) break;
        if (find.byKey(handoverContinue).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(handoverContinue));
        } else {
          final p = gameOf(c).currentPlayer;
          final i = next[p]!;
          next[p] = i + 1;
          await tester.tap(target(i ~/ 10, i % 10));
        }
        await tester.pump();
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(gameOf(c).isOver, isTrue);
      expect(find.byKey(resultDialog), findsOneWidget);
      final winner = gameOf(c).result.winner!;
      expect(find.text('${playerMark(winner)} gewinnt!'), findsOneWidget);
      expect(gameOf(c).shipsRemaining(winner == Player.a ? Player.b : Player.a), 0);
    });

    testWidgets('phone portrait: target grid above and larger than the own grid', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = await pumpGame(tester, 'schiffe');
      await randomFleets(tester, c);
      final t = tester.getSize(target(0, 0));
      final o = tester.getSize(own(0, 0));
      expect(t.width, greaterThan(o.width));
      expect(tester.getTopLeft(target(9, 9)).dy, lessThan(tester.getTopLeft(own(0, 0)).dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide screen: grids side by side', (tester) async {
      tester.view.physicalSize = const Size(1180, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = await pumpGame(tester, 'schiffe');
      await randomFleets(tester, c);
      expect(tester.getTopLeft(target(0, 0)).dy, closeTo(tester.getTopLeft(own(0, 0)).dy, 1));
      expect(tester.getTopLeft(target(0, 0)).dx, lessThan(tester.getTopLeft(own(0, 0)).dx));
    });
  });

  testWidgets('input is disabled when the controller cannot act', (tester) async {
    final c = await pumpGame(tester, 'schiffe');
    await randomFleets(tester, c);
    // Finish the game through the engine, then the board is inert.
    while (!c.game.isOver) {
      final m = gameOf(c).legalMoves.first;
      await c.submit(m);
      if (c.needsHandover) c.acknowledgeHandover();
    }
    await tester.pumpAndSettle();
    expect(c.canAct, isFalse);
    expect(find.byKey(resultDialog), findsOneWidget);
    for (var r = 0; r < 10; r++) {
      for (var col = 0; col < 10; col++) {
        expect(cellOf(tester, target(r, col)).onTap, isNull);
      }
    }
    expect(find.text('Alle Schiffe versenkt.'), findsOneWidget);
  });

  test('describeSchiffeMove hides placement coordinates', () {
    final place = AcceptedMove(
      index: 0,
      player: Player.b,
      move: const {'action': 'place', 'ship': 0, 'row': 3, 'col': 4, 'dir': 'h'},
      event: const GameEvent(payload: {'placed': 0, 'length': 5}),
    );
    expect(describeSchiffeMove(deL10n, place), 'platziert ein Schiff');
    final fire = AcceptedMove(
      index: 1,
      player: Player.a,
      move: const {'action': 'fire', 'row': 4, 'col': 4},
      event: const GameEvent(payload: {'row': 4, 'col': 4, 'result': 'hit', 'ship': 4}),
    );
    expect(describeSchiffeMove(deL10n, fire), 'schießt auf E5: Treffer');
  });
}
