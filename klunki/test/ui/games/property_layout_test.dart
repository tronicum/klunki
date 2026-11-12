// KLD-060 follow-up (store shots, November 2026): on tall screens (iPad 13"
// portrait, Android phone and tablets) the board took so much height that
// "Meine Straßen" and "Tauschen" under "Zug beenden" were below the fold.
// In portrait the board leaves room for the action panel: the main button
// and the row "Meine Straßen" / "Tauschen" / "Zug zurücknehmen" are fully on
// screen without scrolling, on phones and tablets, in landscape and with
// text at 130 %. No layout overflows. With the bundled Roboto, so the heights
// are those of the real app (the test font is taller and wider).
//
// Exempt: the iPhone SE (375×667) in portrait keeps a board of a readable
// size; there only the main button is guaranteed, the row may need the
// panel scrolled (checked: the main button is on screen).
//
// KLUNKI_LAYOUT_VERBOSE=1 prints the board side, the street name size and the
// room left under the panel per device.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/ui/games/property/property_names.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';

/// A device: logical size, safe area (left, top, right, bottom), text scale,
/// and whether only the main button must be on screen (the SE).
typedef _Device = ({String name, Size size, EdgeInsets safe, double text, bool mainOnly});

const _devices = <_Device>[
  (name: 'iPhone SE', size: Size(375, 667), safe: EdgeInsets.only(top: 20), text: 1, mainOnly: true),
  (name: 'iPhone SE, text 130 %', size: Size(375, 667), safe: EdgeInsets.only(top: 20), text: 1.3, mainOnly: true),
  (name: 'iPhone 15 Pro', size: Size(402, 874), safe: EdgeInsets.only(top: 62, bottom: 34), text: 1, mainOnly: false),
  (
    name: 'iPhone 15 Pro, text 130 %',
    size: Size(402, 874),
    safe: EdgeInsets.only(top: 62, bottom: 34),
    text: 1.3,
    mainOnly: false,
  ),
  (name: 'iPhone Pro Max', size: Size(440, 956), safe: EdgeInsets.only(top: 62, bottom: 34), text: 1, mainOnly: false),
  (
    name: 'iPhone 15 Pro landscape',
    size: Size(874, 402),
    safe: EdgeInsets.fromLTRB(62, 0, 62, 21),
    text: 1,
    mainOnly: false,
  ),
  (name: 'iPad 13"', size: Size(1032, 1376), safe: EdgeInsets.only(top: 24, bottom: 20), text: 1, mainOnly: false),
  (
    name: 'iPad 13", text 130 %',
    size: Size(1032, 1376),
    safe: EdgeInsets.only(top: 24, bottom: 20),
    text: 1.3,
    mainOnly: false,
  ),
  (
    name: 'iPad 13" landscape',
    size: Size(1376, 1032),
    safe: EdgeInsets.only(top: 24, bottom: 20),
    text: 1,
    mainOnly: false,
  ),
  (name: 'Android phone', size: Size(412, 915), safe: EdgeInsets.only(top: 24, bottom: 24), text: 1, mainOnly: false),
  (name: 'Android phone 16:9', size: Size(411, 731), safe: EdgeInsets.only(top: 24), text: 1, mainOnly: false),
  (
    name: 'Android 7" tablet',
    size: Size(600, 960),
    safe: EdgeInsets.only(top: 24, bottom: 24),
    text: 1,
    mainOnly: false,
  ),
  (
    name: 'Android 10" tablet',
    size: Size(800, 1280),
    safe: EdgeInsets.only(top: 24, bottom: 24),
    text: 1,
    mainOnly: false,
  ),
];

Finder _key(String k) => find.byKey(Key(k));

Future<void> _loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Roboto/Roboto-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

Future<GameController> _start(WidgetTester tester, _Device d, {required int players}) async {
  const dpr = 3.0;
  tester.view.physicalSize = d.size * dpr;
  tester.view.devicePixelRatio = dpr;
  final pad = FakeViewPadding(
    left: d.safe.left * dpr,
    top: d.safe.top * dpr,
    right: d.safe.right * dpr,
    bottom: d.safe.bottom * dpr,
  );
  tester.view.padding = pad;
  tester.view.viewPadding = pad;
  tester.platformDispatcher.textScaleFactorTestValue = d.text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final c = GameController.hotSeat(GameConfig('property', seed: 11, players: players));
  addTearDown(c.dispose);
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
    final inside =
        r.left >= safe.left - 0.5 &&
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

void main() {
  setUpAll(_loadRoboto);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.propertyIntro);
    UndoSettings.debugReset();
  });

  for (final players in [2, 4]) {
    for (final d in _devices) {
      testWidgets('${d.name}, $players players: "Würfeln", "Zug beenden", "Meine Straßen", "Tauschen" on screen', (
        tester,
      ) async {
        final c = await _start(tester, d, players: players);
        const row = ['property-manage', 'property-trade', 'shell-undo'];
        final board = tester.getSize(_key('property-board'));
        if (Platform.environment['KLUNKI_LAYOUT_VERBOSE'] != null) {
          // ignore: avoid_print
          print('${d.name}, $players players: board ${board.width.toStringAsFixed(1)}, '
              'names ${tester.widget<PropertyFieldName>(_key('property-name-1')).size.toStringAsFixed(2)}, '
              'room under the panel ${(d.size.height - d.safe.bottom - tester.getRect(_key('property-controls')).bottom).toStringAsFixed(1)}');
        }
        _onScreen(tester, d, 'roll', ['property-roll', if (!d.mainOnly) ...row]);

        // Roll until a turn ends on "Zug beenden" (no buying: decline,
        // the auction passes).
        final g = c.game as PropertyGame;
        for (var i = 0; i < 20 && g.phase != PropertyPhase.end; i++) {
          final m = g.legalMoves.firstWhere(
            (m) => m['action'] == 'decline' || m['action'] == 'pass',
            orElse: () => g.legalMoves.first,
          );
          if (g.phase == PropertyPhase.roll) {
            await _tap(tester, 'property-roll');
          } else {
            await c.submit(m);
          }
          await tester.pumpAndSettle();
        }
        expect(g.phase, PropertyPhase.end);
        _onScreen(tester, d, 'end', ['property-end', if (!d.mainOnly) ...row]);
        expect(tester.getSize(_key('property-board')), board, reason: '${d.name}: the board keeps its size');
      });
    }
  }
}
