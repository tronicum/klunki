// KLD-119: Ausgewürfelt with 4 players on a phone. The dice and "Würfeln"
// are always fully on screen without scrolling, inside the safe area and
// tappable, the sheet's header (names) and totals too; only the boxes
// scroll. iPhone SE (375×667) and iPhone 15 Pro (393×852) with text at 100 %
// and 130 %, landscape, iPad; 2 and 4 players. No layout overflows. With the
// bundled Roboto, so the heights are those of the real app.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/shake_settings.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';

typedef _Device = ({String name, Size size, EdgeInsets safe, double text});

const _devices = <_Device>[
  (name: 'iPhone SE', size: Size(375, 667), safe: EdgeInsets.only(top: 20), text: 1),
  (name: 'iPhone SE, text 130 %', size: Size(375, 667), safe: EdgeInsets.only(top: 20), text: 1.3),
  (name: 'iPhone 15 Pro', size: Size(393, 852), safe: EdgeInsets.only(top: 59, bottom: 34), text: 1),
  (name: 'iPhone 15 Pro, text 130 %', size: Size(393, 852), safe: EdgeInsets.only(top: 59, bottom: 34), text: 1.3),
  (name: 'iPhone 15 Pro landscape', size: Size(852, 393), safe: EdgeInsets.fromLTRB(59, 0, 59, 21), text: 1),
  (name: 'iPad', size: Size(820, 1180), safe: EdgeInsets.only(top: 24, bottom: 20), text: 1),
  (name: 'iPad landscape', size: Size(1180, 820), safe: EdgeInsets.only(top: 24, bottom: 20), text: 1),
];

Finder _key(String k) => find.byKey(Key(k));

Future<void> _loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Roboto/Roboto-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

Future<GameController> _start(WidgetTester tester, _Device d, int players) async {
  const dpr = 3.0;
  tester.view.physicalSize = d.size * dpr;
  tester.view.devicePixelRatio = dpr;
  final pad = FakeViewPadding(
      left: d.safe.left * dpr, top: d.safe.top * dpr, right: d.safe.right * dpr, bottom: d.safe.bottom * dpr);
  tester.view.padding = pad;
  tester.view.viewPadding = pad;
  tester.platformDispatcher.textScaleFactorTestValue = d.text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final c = GameController.hotSeat(GameConfig('dicesheet', seed: 3, players: players, extraFives: true));
  addTearDown(c.dispose);
  (c.game as DiceSheetGame).debugScriptRolls([
    [2, 2, 4, 4, 6],
    [2, 2, 2, 5, 1],
  ]);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

void _onScreen(WidgetTester tester, _Device d, String phase, List<String> keys) {
  expect(tester.takeException(), isNull, reason: '${d.name}, $phase: no overflow');
  final safe = Rect.fromLTRB(d.safe.left, d.safe.top, d.size.width - d.safe.right, d.size.height - d.safe.bottom);
  for (final k in keys) {
    expect(_key(k), findsOneWidget, reason: '${d.name}, $phase: $k shown');
    final r = tester.getRect(_key(k));
    final inside = r.left >= safe.left - 0.5 &&
        r.top >= safe.top - 0.5 &&
        r.right <= safe.right + 0.5 &&
        r.bottom <= safe.bottom + 0.5;
    expect(inside, isTrue, reason: '${d.name}, $phase: $k at $r, safe area $safe');
    // The names and totals are text, not buttons: on screen is enough.
    if (k.startsWith('dicesheet-head-') || k.startsWith('dicesheet-total-')) continue;
    expect(_key(k).hitTestable(), findsOneWidget, reason: '${d.name}, $phase: $k can be tapped');
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadRoboto);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ShakeSettings.debugReset();
    ExtraSeatNames.debugReset();
  });

  for (final players in [4, 2]) {
    for (final d in _devices) {
      testWidgets('${d.name}, $players players: dice, "Würfeln", names and totals always on screen', (tester) async {
        await _start(tester, d, players);
        final dice = [for (var i = 0; i < 5; i++) 'dicesheet-die-$i'];
        final sheet = [
          for (var s = 0; s < players; s++) ...['dicesheet-head-$s', 'dicesheet-total-$s'],
        ];
        _onScreen(tester, d, 'before rolling', ['dicesheet-roll', 'shell-status', ...dice, ...sheet]);

        await _tap(tester, 'dicesheet-roll');
        _onScreen(tester, d, 'after the first roll', ['dicesheet-roll', 'shell-undo', ...dice, ...sheet]);
        // The first boxes are on screen without scrolling; the rest scroll.
        _onScreen(tester, d, 'suggestions', ['dicesheet-score-ones']);

        await _tap(tester, 'dicesheet-die-0');
        await _tap(tester, 'dicesheet-die-1');
        expect(find.text('behalten'), findsNWidgets(2));
        _onScreen(tester, d, 'two dice kept', ['dicesheet-roll', ...dice]);

        await _tap(tester, 'dicesheet-roll');
        await _tap(tester, 'dicesheet-roll');
        _onScreen(tester, d, 'no roll left', ['dicesheet-roll', ...dice, ...sheet]);
        expect(tester.widget<FilledButton>(_key('dicesheet-roll')).onPressed, isNull);

        // A box further down: scroll the sheet to it, fill it.
        await tester.ensureVisible(_key('dicesheet-score-chance'));
        await tester.pumpAndSettle();
        await _tap(tester, 'dicesheet-score-chance');
        _onScreen(tester, d, 'next player', ['dicesheet-roll', ...dice, ...sheet]);
      });
    }
  }
}
