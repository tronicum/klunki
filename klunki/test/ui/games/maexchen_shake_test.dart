// KLD-121 follow-up: "Schütteln zum Würfeln" on the Mäxchen screen, with a
// fake motion sensor (`Motion.debugSamples`).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/platform/shake.dart';
import 'package:klunki/profile/shake_settings.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _key(String k) => find.byKey(Key(k));

late StreamController<AccelSample> _sensor;
var _t = 0.0;

/// Shakes the fake phone (two jolts of 3 g) and lets the UI react.
Future<void> _shake(WidgetTester tester) async {
  for (final g in [3.0, 1.0, 3.2, 1.0]) {
    _t += 120;
    _sensor.add(AccelSample(0, 0, g, _t));
  }
  await tester.pumpAndSettle();
  // Next shake well after the debounce.
  _t += ShakeDetector.debounce.inMilliseconds + 100;
}

Future<GameController> _pump(WidgetTester tester, List<List<int>> rolls) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(const GameConfig('maexchen', seed: 3));
  addTearDown(c.dispose);
  (c.game as MaexchenGame).debugScriptRolls(rolls);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ShakeSettings.debugReset();
    Motion.debugReset();
    _sensor = StreamController<AccelSample>.broadcast();
    Motion.debugSamples = () => _sensor.stream;
  });
  tearDown(() {
    Motion.debugReset();
    _sensor.close();
  });

  testWidgets('a shake rolls exactly once; the hint shows once the sensor works', (tester) async {
    final c = await _pump(tester, [[3, 1]]);
    expect(_sensor.hasListener, isTrue, reason: 'listening while a roll is allowed');
    expect(_key('maexchen-shake-hint'), findsNothing, reason: 'no sample yet: maybe no sensor');
    _sensor.add(AccelSample(0, 0, 1, _t));
    await tester.pumpAndSettle();
    expect(find.text('oder schüttle das Handy'), findsOneWidget);

    await _shake(tester);
    expect(c.moves.map((m) => m.move['action']), ['roll']);
    expect((c.game as MaexchenGame).phase, MaexchenPhase.announce);
    expect(_sensor.hasListener, isFalse, reason: 'no roll allowed now: the sensor is off');
    await _shake(tester);
    await _shake(tester);
    expect(c.moves, hasLength(1), reason: 'more shaking does not roll again');
  });

  testWidgets('ignored while announcing, responding and under the handover cover', (tester) async {
    final c = await _pump(tester, [[3, 1]]);
    await _shake(tester);
    await _tap(tester, 'maexchen-value-31');
    await _tap(tester, 'maexchen-announce');
    expect(_key('handover-cover'), findsOneWidget);
    await _shake(tester);
    await tester.tap(_key('handover-continue'));
    await tester.pumpAndSettle();
    await _shake(tester);
    expect(c.moves.map((m) => m.move['action']), ['roll', 'announce'], reason: 'Ben must answer first');
    // Ben believes: now he may roll, by shaking too.
    await _tap(tester, 'maexchen-believe');
    expect(_sensor.hasListener, isTrue);
    await _shake(tester);
    expect(c.moves.last.move['action'], 'roll');
  });

  testWidgets('a picked-up phone or one bump does not roll', (tester) async {
    final c = await _pump(tester, [[3, 1]]);
    for (final g in [1.2, 1.6, 1.3, 1.0, 3.5, 3.4, 1.0]) {
      _t += 60;
      _sensor.add(AccelSample(0, 0, g, _t));
    }
    await tester.pumpAndSettle();
    expect(c.moves, isEmpty);
  });

  testWidgets('setting off: the sensor stays off, the button still rolls', (tester) async {
    await ShakeSettings.shared().setEnabled(false);
    final c = await _pump(tester, [[3, 1]]);
    expect(_sensor.hasListener, isFalse);
    await _shake(tester);
    expect(c.moves, isEmpty);
    expect(_key('maexchen-shake-hint'), findsNothing);
    await _tap(tester, 'maexchen-roll');
    expect(c.moves, hasLength(1));
  });

  testWidgets('no shake while a dialog lies over the game', (tester) async {
    final c = await _pump(tester, [[3, 1]]);
    await tester.tap(_key('shell-history'));
    await tester.pumpAndSettle();
    expect(_sensor.hasListener, isFalse);
    await _shake(tester);
    expect(c.moves, isEmpty);
  });

  testWidgets('a sensor that fails (none on the device): the button still works', (tester) async {
    Motion.debugSamples = () => Stream<AccelSample>.error(Exception('unavailable'));
    final c = await _pump(tester, [[3, 1]]);
    expect(Motion.unavailable, isTrue);
    expect(_key('maexchen-shake-hint'), findsNothing);
    await _tap(tester, 'maexchen-roll');
    expect(c.moves, hasLength(1));
  });

  testWidgets('the options dialog has the switch; it is stored', (tester) async {
    // The app's settings, read from (mock) storage.
    ShakeSettings.debugReset(loaded: true);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pumpWidget(localizedApp(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(onPressed: () => openGameFromMenu(context, 'maexchen'), child: const Text('open')),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Schütteln zum Würfeln'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(_key('maexchen-shake')).value, isTrue, reason: 'on by default');
    await tester.tap(_key('maexchen-shake'));
    await tester.pumpAndSettle();
    expect(ShakeSettings.shared().enabled, isFalse);
    await tester.tap(_key('maexchen-options-next'));
    await tester.pumpAndSettle();
    // "Wer spielt?" (2–4 players, KLD-121 step 2).
    await tester.tap(_key('hot-seat-names-ok'));
    await tester.pumpAndSettle();
    expect(_sensor.hasListener, isFalse);
    // A fresh start reads the stored choice.
    ShakeSettings.debugReset(loaded: true);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    expect(ShakeSettings.shared().enabled, isFalse);
    expect((await SharedPreferences.getInstance()).getBool(ShakeSettings.prefsKey), isFalse);
    expect(controllerOf(tester).moves, isEmpty);
  });
}
