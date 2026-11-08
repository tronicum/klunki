// KLD-123: before the browser's own motion prompt (the web on iOS) a card
// explains what shaking is for; with fakes for the browser
// (`Motion.debugPermissionPending`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/platform/shake.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/shake_settings.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';

Finder _key(String k) => find.byKey(Key(k));

Future<GameController> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(const GameConfig('maexchen', seed: 3));
  addTearDown(c.dispose);
  (c.game as MaexchenGame).debugScriptRolls([
    [3, 1],
    [5, 2],
  ]);
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

List<Object?> _actions(GameController c) => [for (final m in c.moves) m.move['action']];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    ShakeSettings.debugReset();
    Motion.debugReset();
  });
  tearDown(Motion.debugReset);

  testWidgets('"Ja": the browser is asked in that tap, then the dice roll; once only', (tester) async {
    Motion.debugPermissionPending = true;
    final c = await _pump(tester);
    await _tap(tester, 'maexchen-roll');
    expect(_key('shake-consent'), findsOneWidget);
    expect(find.text('Würfeln durch Schütteln?'), findsOneWidget);
    expect(find.text(deL10n.shakeConsentBody), findsOneWidget);
    expect(c.moves, isEmpty, reason: 'the roll waits for the answer');
    expect(Motion.debugPermissionRequests, 0, reason: 'no browser prompt before the card');

    await _tap(tester, 'shake-consent-yes');
    expect(_key('shake-consent'), findsNothing);
    expect(Motion.debugPermissionRequests, 1);
    expect(ShakeSettings.shared().enabled, isTrue);
    expect(_actions(c), ['roll']);
    expect(SeenTips.shared.has(SeenTips.shakeConsent), isTrue);

    // Answered: never again, even if the browser would ask again.
    Motion.debugPermissionPending = true;
    c.restart(seed: 4);
    (c.game as MaexchenGame).debugScriptRolls([
      [6, 5],
    ]);
    await tester.pumpAndSettle();
    await _tap(tester, 'maexchen-roll');
    expect(_key('shake-consent'), findsNothing);
    expect(_actions(c), ['roll']);
    expect(Motion.debugPermissionRequests, 2, reason: 'the tap itself asks, as before');
  });

  testWidgets('"Nein, nur tippen": shaking off, the tap still rolls, no browser prompt', (tester) async {
    Motion.debugPermissionPending = true;
    final c = await _pump(tester);
    await _tap(tester, 'maexchen-roll');
    expect(_key('shake-consent'), findsOneWidget);
    await _tap(tester, 'shake-consent-no');
    expect(_key('shake-consent'), findsNothing);
    expect(ShakeSettings.shared().enabled, isFalse);
    expect(Motion.debugPermissionRequests, 0);
    expect(_actions(c), ['roll']);
  });

  testWidgets('shaking already off: no card', (tester) async {
    Motion.debugPermissionPending = true;
    await ShakeSettings.shared().setEnabled(false);
    final c = await _pump(tester);
    await _tap(tester, 'maexchen-roll');
    expect(_key('shake-consent'), findsNothing);
    expect(_actions(c), ['roll']);
  });

  testWidgets('the apps (no browser prompt): no card, the tap rolls at once', (tester) async {
    expect(Motion.permissionPending, isFalse);
    final c = await _pump(tester);
    await _tap(tester, 'maexchen-roll');
    expect(_key('shake-consent'), findsNothing);
    expect(_actions(c), ['roll']);
    expect(SeenTips.shared.has(SeenTips.shakeConsent), isFalse);
  });
}
