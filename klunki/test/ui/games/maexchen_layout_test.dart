// KLD-121 follow-up (build 2026110806 on an iPhone 15 Pro): the "ansagen"
// button was below the fold. In every phase the action buttons (Würfeln /
// Nachschauen + ansagen / Glauben–Anzweifeln / Leben abgeben) are fully on
// screen without scrolling, inside the safe area, and actually tappable:
// on an iPhone SE (375×667) and an iPhone 15 Pro (393×852), with text at
// 100 % and 130 %, in landscape and on an iPad. No layout overflows. With
// the bundled Roboto, so the heights are those of the real app (the test
// font is taller and wider).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';

/// A device: logical size, safe area (left, top, right, bottom), text scale.
typedef _Device = ({String name, Size size, EdgeInsets safe, double text});

const _devices = <_Device>[
  (name: 'iPhone SE', size: Size(375, 667), safe: EdgeInsets.only(top: 20), text: 1),
  (name: 'iPhone SE, text 130 %', size: Size(375, 667), safe: EdgeInsets.only(top: 20), text: 1.3),
  (name: 'iPhone 15 Pro', size: Size(393, 852), safe: EdgeInsets.only(top: 59, bottom: 34), text: 1),
  (name: 'iPhone 15 Pro, text 130 %', size: Size(393, 852), safe: EdgeInsets.only(top: 59, bottom: 34), text: 1.3),
  (name: 'iPhone 15 Pro landscape', size: Size(852, 393), safe: EdgeInsets.fromLTRB(59, 0, 59, 21), text: 1),
  (name: 'iPhone SE landscape', size: Size(667, 375), safe: EdgeInsets.zero, text: 1),
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

Future<GameController> _start(WidgetTester tester, _Device d, List<List<int>> rolls,
    {int players = 2, bool unlimited = false}) async {
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
  final c = GameController.hotSeat(
      GameConfig('maexchen', seed: 3, players: players, lives: players > 2 ? 5 : 3, maexchenUnlimited: unlimited));
  addTearDown(c.dispose);
  (c.game as MaexchenGame).debugScriptRolls(rolls);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

/// [keys] are fully inside the screen's safe area, without scrolling, and a
/// tap on their centre reaches them.
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
    expect(_key(k).hitTestable(), findsOneWidget, reason: '${d.name}, $phase: $k can be tapped');
  }
}

/// Taps [key] where it is (no scrolling: it must be on screen already).
Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

/// The handover cover is the shell's (it scrolls in phone landscape).
Future<void> _handOver(WidgetTester tester) async {
  await tester.ensureVisible(_key('handover-continue'));
  await tester.pumpAndSettle();
  await _tap(tester, 'handover-continue');
}

void main() {
  setUpAll(_loadRoboto);

  // KLD-121 step 2: also with 4 players (seat shell, a lives row of four
  // cells, 5 lives) and with the tally of "Unbegrenzte Leben".
  for (final (players, unlimited) in [(2, false), (4, false), (4, true)]) {
    for (final d in _devices) {
      final what = players == 2 ? '' : ', $players players${unlimited ? ', Unbegrenzte Leben' : ', 5 lives'}';
      testWidgets('${d.name}$what: every action is on screen in every phase', (tester) async {
        await _start(tester, d, [[4, 1], [3, 1], [2, 1]], players: players, unlimited: unlimited);
        _onScreen(tester, d, 'roll', ['maexchen-roll']);

        await _tap(tester, 'maexchen-roll');
        _onScreen(tester, d, 'announce, nothing chosen', ['maexchen-peek', 'maexchen-announce', 'maexchen-value-31']);
        expect(tester.widget<FilledButton>(_key('maexchen-announce')).onPressed, isNull);
        expect(find.text('Wähle eine Zahl'), findsOneWidget, reason: 'the button says what to do first');

        await _tap(tester, 'maexchen-peek');
        _onScreen(tester, d, 'announce, peeking', ['maexchen-peek', 'maexchen-announce']);
        // The lowest value is always on screen; the chosen one ("Mäxchen!" is
        // the last cell) may need the grid scrolled on the smallest screens.
        await tester.ensureVisible(_key('maexchen-value-52'));
        await tester.pumpAndSettle();
        await _tap(tester, 'maexchen-value-52');
        _onScreen(tester, d, 'announce, 52 chosen', ['maexchen-announce']);
        expect(find.text('52 ansagen'), findsOneWidget);

        await _tap(tester, 'maexchen-announce');
        await _handOver(tester);
        _onScreen(tester, d, 'respond', ['maexchen-believe', 'maexchen-doubt']);

        await _tap(tester, 'maexchen-doubt');
        await _handOver(tester);
        _onScreen(tester, d, 'after the reveal', ['maexchen-roll', 'maexchen-summary']);

        await _tap(tester, 'maexchen-roll');
        await tester.ensureVisible(_key('maexchen-value-21'));
        await tester.pumpAndSettle();
        await _tap(tester, 'maexchen-value-21');
        _onScreen(tester, d, 'announce, Mäxchen chosen', ['maexchen-peek', 'maexchen-announce']);
        await _tap(tester, 'maexchen-announce');
        await _handOver(tester);
        _onScreen(tester, d, 'respond to Mäxchen', ['maexchen-giveup', 'maexchen-doubt']);
      });
    }
  }
}
