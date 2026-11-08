// KLD-119 follow-up: "Wer fängt an?" in Ausgewürfelt's start options:
// "Erster Spieler" (default), "Reihenfolge festlegen" (arrows in "Wer
// spielt?", the order of the names is the seat order) and "Zufall" (the
// seed picks the first seat). The game says who starts until the first move.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/beginner_settings.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/shake_settings.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

/// From the menu to "Wer spielt?" with [start] chosen.
Future<void> _toPlayers(WidgetTester tester, String start) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(klunkiApp());
  await tester.pumpAndSettle();
  await _tap(tester, 'menu-dicesheet-local');
  expect(_key('dicesheet-start-first'), findsOneWidget);
  await _tap(tester, 'dicesheet-start-$start');
  expect(_key('dicesheet-start-explain'), findsOneWidget);
  await _tap(tester, 'dicesheet-options-next');
  expect(_key('hot-seat-start-dialog'), findsOneWidget);
}

GameController _controller(WidgetTester tester) => controllerOf(tester);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ShakeSettings.debugReset();
    BeginnerSettings.debugReset();
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.dicesheetIntro);
    ExtraSeatNames.debugReset();
  });

  testWidgets('"Erster Spieler": no arrows; seat 1 starts and the game says so', (tester) async {
    await _toPlayers(tester, 'first');
    expect(_key('seat-up-0'), findsNothing);
    await _tap(tester, 'hot-seat-names-ok');
    final c = _controller(tester);
    expect(c.config.randomStart, isFalse);
    expect((c.game as DiceSheetGame).currentSeat, 0);
    expect(find.text('Los geht’s: Anna fängt an.'), findsOneWidget);
    await _tap(tester, 'dicesheet-roll');
    expect(_key('seat-starter'), findsNothing, reason: 'gone after the first move');
  });

  testWidgets('"Reihenfolge festlegen": the arrows reorder the names, that order plays', (tester) async {
    await _toPlayers(tester, 'order');
    await _tap(tester, 'seat-players-3');
    expect(_key('seat-order-hint'), findsOneWidget);
    expect(tester.widget<IconButton>(_key('seat-up-0')).onPressed, isNull);
    expect(tester.widget<IconButton>(_key('seat-down-2')).onPressed, isNull);
    final names = [for (var s = 0; s < 3; s++) tester.widget<TextField>(_key('seat-name-$s')).controller!.text];
    // The third name to the top: up twice.
    await _tap(tester, 'seat-up-2');
    await _tap(tester, 'seat-up-1');
    expect([for (var s = 0; s < 3; s++) tester.widget<TextField>(_key('seat-name-$s')).controller!.text],
        [names[2], names[0], names[1]]);
    await _tap(tester, 'hot-seat-names-ok');
    final c = _controller(tester);
    expect(c.config.players, 3);
    expect((c.game as DiceSheetGame).currentSeat, 0);
    expect(find.text('Los geht’s: ${names[2]} fängt an.'), findsOneWidget);
    // Stored in that order: the next "Wer spielt?" shows it.
    expect(ExtraSeatNames.shared().nameOf(2), names[1] == 'Cleo' ? null : names[1]);
  });

  testWidgets('"Zufall": the config says so, the drawn seat starts and is announced', (tester) async {
    await _toPlayers(tester, 'random');
    expect(find.text('Wer anfängt, lost das Spiel aus.'), findsOneWidget);
    await _tap(tester, 'seat-players-4');
    await _tap(tester, 'hot-seat-names-ok');
    final c = _controller(tester);
    expect(c.config.randomStart, isTrue);
    final g = c.game as DiceSheetGame;
    expect(g.currentSeat, g.startSeat);
    expect(_key('seat-starter'), findsOneWidget);
    expect(find.textContaining('Ausgelost: '), findsOneWidget);
    expect(find.byIcon(Icons.casino_outlined), findsWidgets);
  });

}
