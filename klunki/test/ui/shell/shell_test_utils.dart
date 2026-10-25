import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/legal_move_board.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

const resultDialog = Key('result-dialog');
const handoverContinue = Key('handover-continue');

/// Pumps the registered screen for a fresh hot-seat game of [id].
Future<GameController> pumpGame(WidgetTester tester, String id, {int seed = 1}) async {
  final controller = GameController.hotSeat(GameConfig(id, seed: seed));
  addTearDown(controller.dispose);
  await tester.pumpWidget(MaterialApp(home: buildGameScreen(controller)));
  await tester.pump();
  return controller;
}

/// The controller of the (single) [GameScreen] in the widget tree. Works for
/// games opened from the menu too, where the test never sees the controller.
GameController controllerOf(WidgetTester tester) =>
    tester.widget<GameScreen>(find.byType(GameScreen)).controller;

/// Submits legal move [index] of the current position through the controller
/// (board-agnostic: no knowledge of any screen's widgets) and pumps.
Future<void> playMove(WidgetTester tester, {int index = 0}) async {
  final c = controllerOf(tester);
  final moves = legalMovesOf(c.game);
  expect(index, lessThan(moves.length), reason: 'no legal move #$index');
  await c.submit(moves[index]);
  await tester.pump(); // rebuild after the move
  await tester.pump(); // post-frame: result dialog route
}

/// Plays the first legal move (acknowledging handovers) until the result
/// dialog shows. Fails after [maxSteps].
Future<void> playToEnd(WidgetTester tester, {int maxSteps = 2000}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (find.byKey(resultDialog).evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
    if (find.byKey(handoverContinue).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(handoverContinue));
      await tester.pump();
    } else {
      await playMove(tester);
    }
  }
  fail('game did not end within $maxSteps steps');
}

/// Plays the first legal move until the handover cover appears.
Future<void> playUntilHandover(WidgetTester tester, {int maxSteps = 500}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (find.byKey(handoverContinue).evaluate().isNotEmpty) return;
    await playMove(tester);
  }
  fail('no handover within $maxSteps steps');
}
