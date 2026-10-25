import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

const resultDialog = Key('result-dialog');
const handoverContinue = Key('handover-continue');
const firstMove = Key('legal-move-0');

/// Pumps the registered screen for a fresh hot-seat game of [id].
Future<GameController> pumpGame(WidgetTester tester, String id, {int seed = 1}) async {
  final controller = GameController.hotSeat(GameConfig(id, seed: seed));
  addTearDown(controller.dispose);
  await tester.pumpWidget(MaterialApp(home: buildGameScreen(controller)));
  await tester.pump();
  return controller;
}

/// Taps the first legal move (acknowledging handovers) until the result
/// dialog shows. Fails after [maxSteps].
Future<void> playToEnd(WidgetTester tester, {int maxSteps = 2000}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (find.byKey(resultDialog).evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
    if (find.byKey(handoverContinue).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(handoverContinue));
    } else {
      await tester.tap(find.byKey(firstMove));
    }
    await tester.pump(); // rebuild after the move
    await tester.pump(); // post-frame: result dialog route
  }
  fail('game did not end within $maxSteps steps');
}

/// Taps the first legal move until the handover cover appears.
Future<void> playUntilHandover(WidgetTester tester, {int maxSteps = 500}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (find.byKey(handoverContinue).evaluate().isNotEmpty) return;
    await tester.tap(find.byKey(firstMove));
    await tester.pump();
  }
  fail('no handover within $maxSteps steps');
}
