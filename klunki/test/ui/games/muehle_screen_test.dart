import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/games/muehle_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

Key point(int p) => Key('muehle-point-$p');
Finder stone(int p, String mark) => find.byKey(Key('muehle-stone-$p-$mark'));
Finder hint(String text) => find.descendant(of: find.byKey(const Key('shell-hint')), matching: find.text(text), matchRoot: true);

Future<GameController> pumpMuehle(WidgetTester tester, {Size size = const Size(800, 1000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(const GameConfig('muehle'));
  addTearDown(c.dispose);
  await tester.pumpWidget(MaterialApp(home: MuehleScreen(controller: c)));
  await tester.pump();
  await tester.pump();
  return c;
}

MuehleGame gameOf(GameController c) => c.game as MuehleGame;

Future<void> tapPoint(WidgetTester tester, int p) async {
  await tester.tap(find.byKey(point(p)));
  await tester.pump();
  await tester.pump(); // hint is set post-frame by the shell
}

/// All 18 stones placed without forming a mill (X starts).
const xPlaces = [0, 2, 4, 10, 12, 15, 17, 19, 21];
const oPlaces = [1, 3, 5, 6, 8, 9, 13, 22, 23];

void main() {
  testWidgets('renders 24 tappable points, panels and the placing hint', (tester) async {
    await pumpMuehle(tester);
    for (var p = 0; p < 24; p++) {
      expect(find.byKey(point(p)), findsOneWidget);
    }
    expect(hint('Setze einen Stein'), findsOneWidget);
    expect(find.byKey(const Key('muehle-panel-X')), findsOneWidget);
    expect(find.byKey(const Key('muehle-panel-O')), findsOneWidget);
    expect(find.text('Hand: 9 · Brett: 0'), findsNWidgets(2));
    expect(find.text('Setzen'), findsNWidgets(2));
  });

  testWidgets('placing alternates between X and O', (tester) async {
    final c = await pumpMuehle(tester);
    await tapPoint(tester, 5);
    expect(stone(5, 'X'), findsOneWidget);
    expect(find.text('O ist am Zug'), findsOneWidget);
    await tapPoint(tester, 16);
    expect(stone(16, 'O'), findsOneWidget);
    expect(find.text('X ist am Zug'), findsOneWidget);
    await tapPoint(tester, 0);
    expect(stone(0, 'X'), findsOneWidget);
    expect(c.moves, hasLength(3));
    expect(find.text('Hand: 7 · Brett: 2'), findsOneWidget);
    expect(find.text('Hand: 8 · Brett: 1'), findsOneWidget);
  });

  testWidgets('tapping an occupied point is a no-op', (tester) async {
    final c = await pumpMuehle(tester);
    await tapPoint(tester, 7);
    await tapPoint(tester, 7);
    expect(c.moves, hasLength(1));
    expect(c.game.currentPlayer, Player.b);
    expect(stone(7, 'X'), findsOneWidget);
    expect(stone(7, 'O'), findsNothing);
  });

  testWidgets('a mill switches to removal mode; tapping O on 9 removes it', (tester) async {
    final c = await pumpMuehle(tester);
    for (final p in [0, 9, 1, 10, 2]) {
      await tapPoint(tester, p);
    }
    final g = gameOf(c);
    expect(g.pendingRemoval, isTrue);
    expect(find.text('X ist am Zug'), findsOneWidget);
    expect(hint('Mühle! Entferne einen Stein von O'), findsOneWidget);
    expect(find.byKey(const Key('muehle-removable-9')), findsOneWidget);
    expect(find.byKey(const Key('muehle-removable-10')), findsOneWidget);

    // Own stones and empty points are not removal targets.
    await tapPoint(tester, 0);
    await tapPoint(tester, 5);
    expect(c.moves, hasLength(5));

    await tapPoint(tester, 9);
    expect(g.board[9], isNull);
    expect(stone(9, 'O'), findsNothing);
    expect(g.pendingRemoval, isFalse);
    expect(find.text('O ist am Zug'), findsOneWidget);
    expect(find.byKey(const Key('muehle-removable-10')), findsNothing);
    expect(find.text('Geschlagen: 1'), findsOneWidget);
    expect(describeMuehleMove(c.moves, c.moves.last), 'entfernt Stein auf 9');
    await tester.pumpAndSettle(); // mill flash finishes
  });

  testWidgets('select-and-move after the placing phase', (tester) async {
    final c = await pumpMuehle(tester);
    for (var i = 0; i < 9; i++) {
      await c.submit({'action': 'place', 'to': xPlaces[i]});
      await c.submit({'action': 'place', 'to': oPlaces[i]});
    }
    await tester.pump();
    await tester.pump();
    final g = gameOf(c);
    expect(g.phaseOf(Player.a), MuehlePhase.moving);
    expect(hint('Wähle einen Stein zum Ziehen'), findsOneWidget);
    expect(find.text('Ziehen'), findsNWidgets(2));

    // Select 10: targets are its empty neighbours 11 and 18.
    await tapPoint(tester, 10);
    expect(find.byKey(const Key('muehle-selected-10')), findsOneWidget);
    expect(find.byKey(const Key('muehle-target-11')), findsOneWidget);
    expect(find.byKey(const Key('muehle-target-18')), findsOneWidget);
    expect(find.byKey(const Key('muehle-target-7')), findsNothing);

    // Tap again: deselect.
    await tapPoint(tester, 10);
    expect(find.byKey(const Key('muehle-selected-10')), findsNothing);
    expect(find.byKey(const Key('muehle-target-11')), findsNothing);

    // Non-adjacent empty point and opponent stone are no-ops.
    await tapPoint(tester, 10);
    await tapPoint(tester, 7);
    await tapPoint(tester, 9);
    expect(c.moves, hasLength(18));

    await tapPoint(tester, 11);
    expect(c.moves, hasLength(19));
    expect(stone(11, 'X'), findsOneWidget);
    expect(stone(10, 'X'), findsNothing);
    expect(find.text('O ist am Zug'), findsOneWidget);
    expect(find.byKey(const Key('muehle-selected-10')), findsNothing);
    expect(describeMuehleMove(c.moves, c.moves.last), 'zieht 10→11');
  });

  testWidgets('full demo script through taps ends with "O gewinnt!"', (tester) async {
    final c = await pumpMuehle(tester);
    final demo = MuehleText().demoScript;
    for (final cmd in demo) {
      expect(c.game.isOver, isFalse, reason: 'game ended before "$cmd"');
      final before = c.moves.length;
      if (cmd.startsWith('x')) {
        await tapPoint(tester, int.parse(cmd.substring(1)));
      } else if (cmd.contains('-')) {
        final parts = cmd.split('-').map(int.parse).toList();
        await tapPoint(tester, parts[0]);
        await tapPoint(tester, parts[1]);
      } else {
        await tapPoint(tester, int.parse(cmd));
      }
      expect(c.moves.length, before + 1, reason: 'command "$cmd" was not applied');
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result-dialog')), findsOneWidget);
    expect(find.text('O gewinnt!'), findsOneWidget);
    expect(c.canAct, isFalse);

    final texts = [for (final m in c.moves) '${playerMark(m.player)}: ${describeMuehleMove(c.moves, m)}'];
    expect(texts.first, 'X: setzt auf 21');
    expect(texts, contains('O: entfernt Stein auf 8'));
    expect(texts, contains('O: zieht 15→16'));
    expect(texts, contains('X: springt 20→9'));
  });

  testWidgets('board ignores taps when the controller cannot act', (tester) async {
    final c = await pumpMuehle(tester);
    final text = MuehleText();
    for (final cmd in text.demoScript) {
      await c.submit(text.parse(cmd)!);
    }
    await tester.pump();
    await tester.pump();
    expect(c.canAct, isFalse);
    final ignore = find.ancestor(of: find.byKey(point(7)), matching: find.byType(IgnorePointer));
    expect(tester.widgetList<IgnorePointer>(ignore).any((w) => w.ignoring), isTrue);
    expect(find.byKey(const Key('shell-hint')), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('landscape layout puts the panels beside the board', (tester) async {
    await pumpMuehle(tester, size: const Size(1200, 700));
    final board = tester.getCenter(find.byKey(point(4)));
    expect(tester.getCenter(find.byKey(const Key('muehle-panel-X'))).dx, lessThan(board.dx));
    expect(tester.getCenter(find.byKey(const Key('muehle-panel-O'))).dx, greaterThan(board.dx));
    await tapPoint(tester, 4);
    expect(stone(4, 'X'), findsOneWidget);
  });
}
