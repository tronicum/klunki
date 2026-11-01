import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/schiffe/schiffe_describe.dart';
import 'package:klunki/ui/games/schiffe/schiffe_grid.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_net/klunki_net.dart' show Verification;
import 'package:shared_preferences/shared_preferences.dart';

import '../shell/shell_test_utils.dart';
import '../../l10n/l10n_test_utils.dart';

Finder own(int r, int c) => find.byKey(Key('sv-own-$r-$c'));
Finder target(int r, int c) => find.byKey(Key('sv-target-$r-$c'));
SchiffeCellView cellOf(WidgetTester t, Finder f) => t.widget<SchiffeCellView>(f);
SchiffeGame gameOf(GameController c) => c.game as SchiffeGame;

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key), skipOffstage: false));
  await tester.pump();
  await tester.tap(find.byKey(Key(key)));
  await tester.pump();
  await tester.pump(); // the shell's hint follows one frame later
}

Future<void> acknowledge(WidgetTester tester) async {
  expect(find.byKey(handoverContinue), findsOneWidget);
  await tester.tap(find.byKey(handoverContinue));
  await tester.pump();
}

/// Taps "Fertig" and lets the (async) submission of the fleet finish.
Future<void> done(WidgetTester tester) async {
  await tapKey(tester, 'sv-done');
  await tester.pump();
}

bool buttonEnabled(WidgetTester tester, String key) => switch (tester.widget(find.byKey(Key(key)))) {
      final ButtonStyleButton b => b.enabled,
      final IconButton b => b.onPressed != null,
      final w => throw StateError('not a button: $w'),
    };
bool doneEnabled(WidgetTester tester) => buttonEnabled(tester, 'sv-done');

/// Ship cells of the setup grid, as `row*10+col`.
Set<int> shipCells(WidgetTester tester) => {
      for (var r = 0; r < 10; r++)
        for (var col = 0; col < 10; col++)
          if (cellOf(tester, own(r, col)).look == SvLook.ship) r * 10 + col,
    };

Set<int> row(int r, int from, int len) => {for (var i = 0; i < len; i++) r * 10 + from + i};
Set<int> column(int c, int from, int len) => {for (var i = 0; i < len; i++) (from + i) * 10 + c};

/// A tap on the setup grid at cell ([r], [c]).
Future<void> tapCell(WidgetTester tester, int r, int c) async {
  await tester.tap(own(r, c));
  await tester.pump();
  await tester.pump(); // hint
}

String hint(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('shell-hint'))).data!;

/// Both players place their fleets with "Zufällig" + "Fertig" (with the
/// handover in between) and the battle starts with X to move.
Future<void> randomFleets(WidgetTester tester, GameController c) async {
  await tapKey(tester, 'sv-random');
  await done(tester);
  await acknowledge(tester);
  await tapKey(tester, 'sv-random');
  await done(tester);
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
    testWidgets('shows the active ship, labels, the harbour and the buttons', (tester) async {
      await pumpGame(tester, 'schiffe');
      expect(find.byKey(const Key('sv-next-ship')), findsOneWidget);
      expect(find.text('Schlachtschiff (5)'), findsWidgets);
      expect(find.text('0 von 6 Schiffen gesetzt · Anna stellt auf'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('sv-fleet-$i'), skipOffstage: false), findsOneWidget);
      }
      expect(find.byKey(const Key('sv-fleet-6'), skipOffstage: false), findsNothing);
      expect(find.byKey(const Key('shell-hint')), findsOneWidget);
      expect(find.text('Drehen'), findsOneWidget);
      expect(find.text('Horizontal'), findsOneWidget);
      expect(doneEnabled(tester), isFalse);
      expect(buttonEnabled(tester, 'sv-remove'), isFalse);
      expect(buttonEnabled(tester, 'sv-reset'), isFalse);
    });

    testWidgets('"Zufällig" sets all 6 ships but submits nothing; "Fertig" submits, the cover hides Anna',
        (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      await tapKey(tester, 'sv-random');
      expect(find.byKey(svShipMarkerKey), findsNWidgets(19));
      expect(c.moves, isEmpty, reason: 'the layout stays editable until "Fertig"');
      expect(find.text('Flotte komplett'), findsOneWidget);
      expect(hint(tester), startsWith('Flotte steht.'));
      expect(doneEnabled(tester), isTrue);

      // Random again: a new layout, still complete.
      final first = shipCells(tester);
      await tapKey(tester, 'sv-random');
      expect(shipCells(tester), hasLength(19));
      expect(shipCells(tester), isNot(first));

      await done(tester);
      expect(c.moves, hasLength(6));
      expect(gameOf(c).placements(Player.a), hasLength(6));
      expect(SchiffeGame.isValidLayout(gameOf(c).placements(Player.a)), isTrue);
      expect(describeSchiffeMove(deL10n, c.moves.first), 'platziert ein Schiff');

      // Handover to O: X's fleet is hidden behind the cover.
      expect(c.needsHandover, isTrue);
      expect(find.text('Gib das Gerät an Ben weiter'), findsOneWidget);
      expect(own(0, 0).hitTestable(), findsNothing);
      await acknowledge(tester);

      // O sees an empty ocean (not X's ships) and a fresh harbour.
      expect(find.text('Ben ist am Zug'), findsOneWidget);
      expect(find.byKey(svShipMarkerKey), findsNothing);
      expect(find.text('0 von 6 Schiffen gesetzt · Ben stellt auf'), findsOneWidget);
      expect(doneEnabled(tester), isFalse);
      await tapKey(tester, 'sv-random');
      await done(tester);
      expect(gameOf(c).placements(Player.b), hasLength(6));
      expect(c.needsHandover, isTrue);
      await acknowledge(tester);

      expect(gameOf(c).phase, SchiffePhase.battle);
      expect(find.text('Anna ist am Zug'), findsOneWidget);
      expect(find.text('Gegner'), findsOneWidget);
      expect(find.text('Dein Meer'), findsOneWidget);
      expect(find.byKey(svShipMarkerKey), findsNWidgets(19));
    });

    testWidgets('placing from the harbour: red/green preview, tap places, "Fertig" only when complete',
        (tester) async {
      final c = await pumpGame(tester, 'schiffe');

      // Horizontal Schlachtschiff at J8 would leave the board: red, not placed.
      var g = await tester.startGesture(tester.getCenter(own(9, 7)));
      await tester.pump();
      expect(cellOf(tester, own(9, 7)).preview, SvPreview.invalid);
      expect(cellOf(tester, own(9, 9)).preview, SvPreview.invalid);
      expect(cellOf(tester, own(9, 6)).preview, isNull);
      await g.up();
      await tester.pump();
      await tester.pump();
      expect(shipCells(tester), isEmpty);
      expect(hint(tester), startsWith('Passt dort nicht'));
      // The invalid footprint flashes red, then clears.
      expect(cellOf(tester, own(9, 8)).preview, SvPreview.invalid);
      await tester.pump(const Duration(seconds: 1));
      expect(cellOf(tester, own(9, 8)).preview, isNull);

      // A1 horizontal fits: green across A1–A5.
      g = await tester.startGesture(tester.getCenter(own(0, 0)));
      await tester.pump();
      for (var col = 0; col < 5; col++) {
        expect(cellOf(tester, own(0, col)).preview, SvPreview.valid);
      }
      expect(cellOf(tester, own(0, 5)).preview, isNull);
      await g.up();
      await tester.pump();
      expect(shipCells(tester), row(0, 0, 5));
      expect(c.moves, isEmpty);
      expect(find.text('Kreuzer (4)'), findsWidgets, reason: 'the next ship from the harbour is active');
      expect(find.text('1 von 6 Schiffen gesetzt · Anna stellt auf'), findsOneWidget);

      // Kreuzer touching the Schlachtschiff at B2: invalid.
      await tapCell(tester, 1, 1);
      expect(shipCells(tester), row(0, 0, 5));

      // "Drehen" switches the harbour ship to vertical; C1 (rows C–F) fits.
      await tapKey(tester, 'sv-rotate');
      expect(find.text('Vertikal'), findsOneWidget);
      g = await tester.startGesture(tester.getCenter(own(2, 0)));
      await tester.pump();
      for (var r = 2; r < 6; r++) {
        expect(cellOf(tester, own(r, 0)).preview, SvPreview.valid);
      }
      await g.up();
      await tester.pump();
      expect(shipCells(tester), {...row(0, 0, 5), ...column(0, 2, 4)});

      // The rest, vertically; one tap off the board in between.
      await tapCell(tester, 2, 9); // Zerstörer C10–E10
      await tapCell(tester, 7, 9); // Zerstörer H10–J10
      await tapCell(tester, 9, 0); // U-Boot from J1 down: off the board
      expect(shipCells(tester), hasLength(15));
      await tapCell(tester, 7, 3); // U-Boot H4–I4
      expect(shipCells(tester), hasLength(17));
      expect(doneEnabled(tester), isFalse);
      await tapCell(tester, 3, 5); // U-Boot D6–E6
      expect(shipCells(tester), hasLength(19));
      expect(doneEnabled(tester), isTrue);

      await done(tester);
      expect(c.moves, hasLength(6));
      expect(gameOf(c).placements(Player.a)[1], const ShipPlacement(length: 4, row: 2, col: 0, horizontal: false));
    });

    testWidgets('select a placed ship, then move it by tapping a cell', (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      await tapCell(tester, 0, 0); // Schlachtschiff A1–A5
      await tapCell(tester, 0, 2); // tap it: selected
      expect(find.text('Schlachtschiff (5)'), findsWidgets);
      expect(hint(tester), startsWith('Schlachtschiff (5) ausgewählt'));
      expect(cellOf(tester, own(0, 2)).selected, isTrue);
      expect(buttonEnabled(tester, 'sv-remove'), isTrue);

      await tapCell(tester, 4, 2); // move: E3–E7
      expect(shipCells(tester), row(4, 2, 5));
      expect(cellOf(tester, own(4, 2)).selected, isTrue, reason: 'stays selected after a move');

      // Moving off the board is refused (flash + hint), the ship stays.
      await tapCell(tester, 6, 7);
      expect(shipCells(tester), row(4, 2, 5));
      expect(hint(tester), startsWith('Passt dort nicht'));
      expect(cellOf(tester, own(6, 9)).preview, SvPreview.invalid);
      await tester.pump(const Duration(seconds: 1));
      expect(c.moves, isEmpty);
    });

    testWidgets('dragging a ship shows a green/red footprint and drops it at the last cell', (tester) async {
      await pumpGame(tester, 'schiffe');
      await tapCell(tester, 4, 2); // Schlachtschiff E3–E7

      // Grab it at its middle cell (E5) and drag.
      final g = await tester.startGesture(tester.getCenter(own(4, 4)));
      await tester.pump();
      await g.moveTo(tester.getCenter(own(9, 9)));
      await tester.pump();
      // Anchored two cells left of the finger: J8–J12 leaves the board.
      expect(cellOf(tester, own(9, 7)).preview, SvPreview.invalid);
      expect(cellOf(tester, own(9, 9)).preview, SvPreview.invalid);
      await g.moveTo(tester.getCenter(own(7, 5)));
      await tester.pump();
      expect(cellOf(tester, own(9, 9)).preview, isNull);
      for (var col = 3; col < 8; col++) {
        expect(cellOf(tester, own(7, col)).preview, SvPreview.valid);
      }
      await g.up();
      await tester.pump();
      expect(shipCells(tester), row(7, 3, 5));
      expect(cellOf(tester, own(7, 3)).selected, isTrue);

      // A drop onto an invalid spot leaves the ship where it was.
      final g2 = await tester.startGesture(tester.getCenter(own(7, 3)));
      await tester.pump();
      await g2.moveTo(tester.getCenter(own(7, 8)));
      await tester.pump();
      expect(cellOf(tester, own(7, 9)).preview, SvPreview.invalid);
      await g2.up();
      await tester.pump();
      expect(shipCells(tester), row(7, 3, 5));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('rotate: tap the selected ship again or "Drehen"; invalid turns flash and explain', (tester) async {
      await pumpGame(tester, 'schiffe');
      await tapCell(tester, 4, 2); // Schlachtschiff E3–E7
      await tapCell(tester, 4, 4); // select
      await tapCell(tester, 4, 4); // again: turn around E5 → C5–G5
      expect(shipCells(tester), column(4, 2, 5));
      expect(find.text('Vertikal'), findsOneWidget, reason: 'the button shows the selected ship');
      await tapKey(tester, 'sv-rotate'); // around the middle E5 → E3–E7
      expect(shipCells(tester), row(4, 2, 5));
      expect(find.text('Horizontal'), findsOneWidget);
      // A tap on any cell of the selected ship turns it around its middle too
      // (KLD-107): E3 tapped, still E5 → C5–G5.
      await tapCell(tester, 4, 2);
      expect(shipCells(tester), column(4, 2, 5));
      await tapCell(tester, 2, 4); // C5 → back to E3–E7
      expect(shipCells(tester), row(4, 2, 5));
      await tester.pump(const Duration(seconds: 1));

      // Schlachtschiff back to A1–A5, Kreuzer at C1–C4 underneath: the
      // Schlachtschiff cannot turn (down it touches, up it leaves the board).
      await tapCell(tester, 0, 0);
      await tapKey(tester, 'sv-fleet-1');
      await tapCell(tester, 2, 0);
      expect(shipCells(tester), {...row(0, 0, 5), ...row(2, 0, 4)});
      await tapCell(tester, 0, 0); // select the Schlachtschiff
      await tapKey(tester, 'sv-rotate');
      expect(shipCells(tester), {...row(0, 0, 5), ...row(2, 0, 4)}, reason: 'unchanged');
      expect(hint(tester), 'Drehen geht hier nicht – zu wenig Platz.');
      expect(cellOf(tester, own(1, 2)).preview, SvPreview.invalid, reason: 'where the turn around A3 would go');
      await tester.pump(const Duration(seconds: 1));
      expect(cellOf(tester, own(1, 2)).preview, isNull);
      // Tapping it again (it is selected) is refused the same way.
      await tapCell(tester, 0, 3);
      expect(shipCells(tester), {...row(0, 0, 5), ...row(2, 0, 4)});
      expect(hint(tester), 'Drehen geht hier nicht – zu wenig Platz.');
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('an invalid action shakes the board; with reduced motion it only flashes', (tester) async {
      await pumpGame(tester, 'schiffe');
      double shift() => tester.widget<Transform>(find.byKey(const Key('sv-shake'))).transform.getTranslation().x;
      expect(shift(), 0);
      await tapCell(tester, 9, 9);
      await tester.pump(const Duration(milliseconds: 100));
      expect(shift(), isNot(0));
      await tester.pump(const Duration(seconds: 1));
      expect(shift(), 0);

      final c = GameController.hotSeat(const GameConfig('schiffe', seed: 1));
      addTearDown(c.dispose);
      await tester.pumpWidget(
        localizedApp(MediaQuery(data: const MediaQueryData(disableAnimations: true), child: buildGameScreen(c))),
      );
      await tester.pump();
      await tapCell(tester, 9, 9);
      expect(cellOf(tester, own(9, 9)).preview, SvPreview.invalid);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('sv-shake')), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(cellOf(tester, own(9, 9)).preview, isNull);
    });

    testWidgets('after an undo the accepted ships stay locked, the rest is editable', (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      await tapKey(tester, 'sv-random');
      await done(tester);
      await acknowledge(tester);
      expect(c.undo(), isTrue); // takes back X's last ship
      await tester.pump();
      if (c.needsHandover) await acknowledge(tester);
      expect(gameOf(c).currentPlayer, Player.a);
      expect(shipCells(tester), hasLength(17));
      expect(find.text('5 von 6 Schiffen gesetzt · Anna stellt auf'), findsOneWidget);
      expect(doneEnabled(tester), isFalse);
      // A locked ship cannot be selected, reset keeps it.
      final locked = gameOf(c).placements(Player.a).first;
      await tapCell(tester, locked.row, locked.col);
      expect(find.byKey(const Key('sv-remove')), findsOneWidget);
      expect(buttonEnabled(tester, 'sv-remove'), isFalse);
      await tapKey(tester, 'sv-random');
      expect(shipCells(tester), hasLength(19));
      await done(tester);
      expect(gameOf(c).placements(Player.a), hasLength(6));
      expect(gameOf(c).placements(Player.a).first, locked);
      expect(c.needsHandover, isTrue);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('remove puts a ship back into the harbour; reset clears the board', (tester) async {
      await pumpGame(tester, 'schiffe');
      await tapKey(tester, 'sv-random');
      expect(shipCells(tester), hasLength(19));
      // Select the Kreuzer through the harbour list, then remove it.
      await tapKey(tester, 'sv-fleet-1');
      expect(hint(tester), startsWith('Kreuzer (4) ausgewählt'));
      await tapKey(tester, 'sv-remove');
      expect(shipCells(tester), hasLength(15));
      expect(doneEnabled(tester), isFalse);
      expect(find.text('5 von 6 Schiffen gesetzt · Anna stellt auf'), findsOneWidget);
      expect(find.text('Kreuzer (4)'), findsWidgets, reason: 'the removed ship is the active one');

      await tapKey(tester, 'sv-reset');
      expect(shipCells(tester), isEmpty);
      expect(find.byKey(svShipMarkerKey), findsNothing);
      expect(doneEnabled(tester), isFalse);
      expect(buttonEnabled(tester, 'sv-reset'), isFalse);
      expect(find.text('Schlachtschiff (5)'), findsWidgets);
    });

    testWidgets('screen reader: cells name the ship and can be tapped', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpGame(tester, 'schiffe');
      expect(find.bySemanticsLabel('A1 Wasser'), findsOneWidget);
      tester.semantics.tap(find.semantics.byLabel('A1 Wasser'));
      await tester.pump();
      expect(shipCells(tester), row(0, 0, 5));
      expect(find.bySemanticsLabel('A1 Schlachtschiff (5)'), findsOneWidget);
      tester.semantics.tap(find.semantics.byLabel('A3 Schlachtschiff (5)'));
      await tester.pump();
      expect(find.bySemanticsLabel('A3 Schlachtschiff (5), ausgewählt'), findsOneWidget);
      expect(find.bySemanticsLabel('Drehen, aktuell Horizontal'), findsOneWidget);
      handle.dispose();
    });

    // KLD-107: the next-ship preview, the dock, the ↻ badge and the tip.
    double previewTurns(WidgetTester tester) =>
        tester.widget<AnimatedRotation>(find.byKey(const Key('sv-preview-ship'))).turns;

    testWidgets('the preview shows the next ship in its orientation; "Drehen" and a tap on it turn it',
        (tester) async {
      await pumpGame(tester, 'schiffe');
      expect(find.byKey(const Key('sv-preview')), findsOneWidget);
      expect(find.text('Schlachtschiff (5)'), findsWidgets);
      expect(previewTurns(tester), 0, reason: 'horizontal');
      expect(find.byKey(const Key('sv-preview-left')), findsNothing, reason: 'only one Schlachtschiff');

      await tapKey(tester, 'sv-rotate');
      expect(previewTurns(tester), 0.25, reason: 'a quarter turn: vertical');
      expect(find.text('Vertikal'), findsOneWidget);
      // The turn is animated (not with reduced motion).
      final ship = find.descendant(of: find.byKey(const Key('sv-preview-ship')), matching: find.byType(Row)).first;
      Matrix4 transform() =>
          (tester.renderObject(find.ancestor(of: ship, matching: find.byType(RotationTransition)).first)
                  as RenderTransform)
              .getTransformTo(null);
      await tester.pump(const Duration(seconds: 1));
      final settled = transform();

      // Tapping the preview turns it on: half a turn, horizontal again.
      await tapKey(tester, 'sv-preview');
      expect(previewTurns(tester), 0.5);
      expect(find.text('Horizontal'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(transform(), isNot(settled), reason: 'mid-turn');
      await tester.pump(const Duration(seconds: 1));

      // Placed horizontally; the Kreuzer is next (no ×), then the Zerstörer (×2).
      await tapCell(tester, 0, 0);
      expect(shipCells(tester), row(0, 0, 5));
      expect(find.text('Kreuzer (4)'), findsWidgets);
      expect(previewTurns(tester), 0, reason: 'another ship: no animation from the old one');
      await tapCell(tester, 2, 0);
      expect(find.text('Zerstörer (3)'), findsWidgets);
      expect(find.text('×2'), findsOneWidget);
      // "Fertig" says why it is still off.
      expect(doneEnabled(tester), isFalse);
      expect(find.text('noch 4 Schiffe'), findsOneWidget);
      await tapKey(tester, 'sv-random');
      expect(find.byKey(const Key('sv-done-left')), findsNothing);
      expect(find.text('Flotte komplett'), findsOneWidget);
    });

    testWidgets('the dock: tapping a ship in the harbour makes it the next one', (tester) async {
      await pumpGame(tester, 'schiffe');
      await tapKey(tester, 'sv-fleet-4');
      expect(find.text('U-Boot (2)'), findsWidgets);
      expect(find.text('×2'), findsOneWidget);
      await tapCell(tester, 9, 0);
      expect(shipCells(tester), row(9, 0, 2));
      expect(find.text('Schlachtschiff (5)'), findsWidgets, reason: 'back to the first ship in the harbour');
      expect(find.text('×2'), findsNothing);
      expect(find.text('noch 5 Schiffe'), findsOneWidget);
    });

    testWidgets('first placed ship: a one-time tip; selected: a ↻ badge that turns it in place, moves with it',
        (tester) async {
      SeenTips.debugReset(); // a fresh install
      await pumpGame(tester, 'schiffe');
      await tapCell(tester, 4, 2); // Schlachtschiff E3–E7
      expect(find.byKey(const Key('sv-coach')), findsOneWidget);
      expect(find.text('Antippen: verschieben oder drehen'), findsOneWidget);
      expect(hint(tester), 'Tippe aufs Meer für das nächste Schiff. Schiff antippen zum Verschieben oder Drehen.');
      expect(SeenTips.shared.has(SeenTips.schiffeMove), isTrue);
      expect(find.byKey(const Key('sv-rotate-badge')), findsNothing, reason: 'only on the selected ship');

      await tapCell(tester, 4, 6); // select it
      expect(find.byKey(const Key('sv-coach')), findsNothing);
      expect(hint(tester), 'Schlachtschiff (5) ausgewählt: ziehen zum Verschieben, nochmal antippen zum Drehen.');
      final badge = find.byKey(const Key('sv-rotate-badge'));
      expect(badge, findsOneWidget);
      expect(tester.getCenter(badge), offsetMoreOrLessEquals(tester.getCenter(own(4, 4)), epsilon: 1),
          reason: 'on the middle cell');
      expect(tester.widget<AnimatedRotation>(badge).turns, 0);

      // A tap on the badge turns the ship around its middle: C5–G5.
      await tester.tapAt(tester.getCenter(badge));
      await tester.pump();
      expect(shipCells(tester), column(4, 2, 5));
      expect(tester.widget<AnimatedRotation>(badge).turns, 0.25);
      expect(previewTurns(tester), 0.25, reason: 'the preview shows the selected ship');
      await tester.pump(const Duration(seconds: 1));

      // Moving it (tap a free cell): the badge follows.
      await tapCell(tester, 3, 8);
      expect(shipCells(tester), column(8, 3, 5));
      expect(tester.getCenter(badge), offsetMoreOrLessEquals(tester.getCenter(own(5, 8)), epsilon: 1));

      // The tip does not come back for the next ship.
      await tapKey(tester, 'sv-fleet-1');
      await tapCell(tester, 0, 0);
      expect(shipCells(tester), {...column(8, 3, 5), ...row(0, 0, 4)});
      expect(find.byKey(const Key('sv-coach')), findsNothing);

      // Once per install, not per player or game: a new game shows no tip.
      await pumpGame(tester, 'schiffe');
      await tapCell(tester, 4, 2);
      expect(shipCells(tester), row(4, 2, 5));
      expect(find.byKey(const Key('sv-coach')), findsNothing);
    });

    test('seen tips: stored per device, loaded at start', () async {
      SharedPreferences.setMockInitialValues({SeenTips.prefsKey: [SeenTips.schiffeMove]});
      SeenTips.debugReset(loaded: true);
      await Future<void>.delayed(Duration.zero);
      expect(SeenTips.shared.has(SeenTips.schiffeMove), isTrue);
      SharedPreferences.setMockInitialValues({});
      SeenTips.debugReset(loaded: true);
      await Future<void>.delayed(Duration.zero);
      expect(SeenTips.shared.markFirst(SeenTips.schiffeMove), isTrue);
      expect(SeenTips.shared.markFirst(SeenTips.schiffeMove), isFalse);
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(SeenTips.prefsKey), [SeenTips.schiffeMove]);
      SeenTips.debugReset();
    });

    testWidgets('↻ on a ship without room: unchanged, shake and the reason', (tester) async {
      await pumpGame(tester, 'schiffe');
      double shift() => tester.widget<Transform>(find.byKey(const Key('sv-shake'))).transform.getTranslation().x;
      await tapCell(tester, 0, 0); // Schlachtschiff A1–A5
      await tapCell(tester, 2, 0); // Kreuzer C1–C4
      await tapCell(tester, 0, 1); // select the Schlachtschiff
      final badge = find.byKey(const Key('sv-rotate-badge'));
      await tester.tapAt(tester.getCenter(badge));
      await tester.pump();
      await tester.pump();
      expect(shipCells(tester), {...row(0, 0, 5), ...row(2, 0, 4)});
      expect(hint(tester), 'Drehen geht hier nicht – zu wenig Platz.');
      expect(tester.widget<AnimatedRotation>(badge).turns, 0, reason: 'no spin when nothing turned');
      await tester.pump(const Duration(milliseconds: 100));
      expect(shift(), isNot(0));
      await tester.pump(const Duration(seconds: 1));
      expect(shift(), 0);
    });

    testWidgets('phone portrait: the setup fits, buttons and harbour items are at least 48 px', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpGame(tester, 'schiffe');
      await tapKey(tester, 'sv-random');
      expect(tester.takeException(), isNull);
      for (final k in ['sv-rotate', 'sv-random', 'sv-remove', 'sv-reset', 'sv-done', 'sv-fleet-0']) {
        final size = tester.getSize(find.byKey(Key(k)));
        expect(size.height, greaterThanOrEqualTo(48), reason: k);
        expect(size.width, greaterThanOrEqualTo(48), reason: k);
      }
      expect(tester.getTopLeft(own(9, 9)).dy, lessThan(tester.getTopLeft(find.byKey(const Key('sv-done'))).dy));
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
      expect(find.text('Ben ist am Zug'), findsOneWidget);
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
      expect(find.text('Deine Flotte: 6 · Gegner (Ben): 5 Schiffe übrig'), findsOneWidget);
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
      expect(find.text('${testName(winner)} gewinnt!'), findsOneWidget);
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

  // KLD-065 with the KLD-068 placement editor: "Aufgeben" while a draft is
  // on the board ends the game cleanly; the draft is never sent.
  group('resign during the placement editor', () {
    Finder inResult(String text) => find.descendant(of: find.byKey(resultDialog), matching: find.text(text));

    testWidgets('hot-seat: X resigns with a draft; O (on its own draft) wins; the editor is inert', (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      await tapKey(tester, 'sv-random');
      expect(doneEnabled(tester), isTrue);
      await tester.tap(find.byKey(const Key('shell-resign')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resign-a')));
      await tester.pumpAndSettle();

      expect(c.moves.single.move, {'action': 'resign', 'player': 'a'}, reason: 'the draft was never submitted');
      expect(inResult('Ben gewinnt!'), findsOneWidget);
      expect(inResult('Anna hat aufgegeben'), findsOneWidget);
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      expect(doneEnabled(tester), isFalse);
      expect(buttonEnabled(tester, 'sv-random'), isFalse);
      final before = shipCells(tester);
      await tester.tap(own(9, 9));
      await tester.pump();
      expect(shipCells(tester), before, reason: 'no editing after the end');
      expect(find.text('Die Schiffe konnten nicht gesetzt werden.'), findsNothing);
      expect(find.byKey(const Key('shell-hint')), findsNothing);
    });

    testWidgets('hot-seat: after X\'s fleet and the cover, O arranges, then X resigns off turn', (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      await tapKey(tester, 'sv-random');
      await done(tester);
      await acknowledge(tester);
      await tapKey(tester, 'sv-random');
      await tester.tap(find.byKey(const Key('shell-resign')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resign-a')));
      await tester.pumpAndSettle();
      expect(c.moves, hasLength(7));
      expect(c.game.resignedBy, Player.a);
      expect(c.needsHandover, isFalse);
      expect(inResult('Ben gewinnt!'), findsOneWidget);
    });

    testWidgets('network: the guest resigns in its editor; the host never sees the draft; the guest verifies',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const ping = Duration(milliseconds: 100), timeout = Duration(seconds: 10); // KLD-070: no keepalive cuts in long pumps
      final (host, guest) = (await tester.runAsync(() async {
        final h = await NetworkTransport.host(const GameConfig('schiffe', seed: 3),
            name: 'Anna', address: InternetAddress.loopbackIPv4, wsPort: null, pingInterval: ping, timeout: timeout);
        final g = await NetworkTransport.join(InternetAddress.loopbackIPv4, h.port!,
            name: 'Ben', pingInterval: ping, timeout: timeout);
        return (h, g);
      }))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        guest.dispose();
        host.dispose();
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump();
        }
      });
      const hostKey = Key('device-host'), guestKey = Key('device-guest');
      Finder on(Key d, Finder f) => find.descendant(of: find.byKey(d), matching: f);
      GameController ctrl(Key d) => tester.widget<GameScreen>(on(d, find.byType(GameScreen))).controller;
      Future<void> until(bool Function() ok, String what) async {
        for (var round = 0;; round++) {
          await tester.pump();
          if (ok()) return tester.pump();
          if (round > 1000) fail('condition not met: $what');
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        }
      }

      Widget device(Key key, NetworkTransport t) => Expanded(
            child: KeyedSubtree(key: key, child: localizedApp(NetworkGameSession(transport: t))),
          );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [device(hostKey, host), device(guestKey, guest)]),
      ));
      await until(() => on(guestKey, find.byKey(const Key('sv-random'))).evaluate().isNotEmpty, 'guest editor');
      expect(ctrl(guestKey).game, isA<SchiffeView>());

      await tester.tap(on(guestKey, find.byKey(const Key('sv-random'))));
      await tester.pump();
      await tester.tap(on(hostKey, find.byKey(const Key('sv-random'))));
      await tester.pump();
      await tester.tap(on(hostKey, find.byKey(const Key('sv-done'))));
      await until(() => ctrl(guestKey).moves.length == 6, 'Anna fleet on the guest');
      expect(tester.widget<ButtonStyleButton>(on(guestKey, find.byKey(const Key('sv-done')))).enabled, isTrue);

      await tester.tap(on(guestKey, find.byKey(const Key('shell-resign'))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(on(guestKey, find.byKey(const Key('resign-confirm'))));
      await until(
          () =>
              ctrl(hostKey).moves.length == 7 &&
              ctrl(guestKey).moves.length == 7 &&
              guest.verification.value == Verification.verified,
          'resign on both, game verified');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(ctrl(hostKey).moves.where((m) => m.player == Player.b).map((m) => m.move).toList(),
          [{'action': 'resign', 'player': 'b'}], reason: "Ben's draft never left the guest");
      for (final d in [hostKey, guestKey]) {
        expect(ctrl(d).game.resignedBy, Player.b);
        expect(on(d, find.text('Spielverlauf konnte nicht bestätigt werden')), findsNothing);
      }
      Finder result(Key d, String text) => on(d, find.descendant(of: find.byKey(resultDialog), matching: find.text(text)));
      expect(result(hostKey, 'Du gewinnst!'), findsOneWidget);
      expect(result(hostKey, 'Ben hat aufgegeben'), findsOneWidget);
      expect(result(guestKey, 'Anna gewinnt!'), findsOneWidget);
      expect(result(guestKey, 'Du hast aufgegeben'), findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(on(guestKey, find.byKey(const Key('sv-done')))).enabled, isFalse);
    }, timeout: const Timeout(Duration(seconds: 60)));
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
