// KLD-094 step 8g (iPhone 15 Pro playtest): the score row names the
// players next to their scores ("① Anna 8   ② Ben 0"), so the shell's players
// legend at the top right is not shown for the word game (it said the same
// again). One line from 320 to 430 px: long names shorten with an ellipsis;
// right to left too, and with the names of a network game. Also the hint
// line that tells about two-finger zoom while the board is not zoomed, and
// the same in "So geht's".
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/shell/game_screen.dart' show PlayerLabels, PlayerLabelsScope;
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';

Finder _name(int s) => find.byKey(Key('wordtiles-name-$s'));
Finder _score(int s) => find.byKey(Key('wordtiles-score-$s'));

Future<void> _loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Roboto/Roboto-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

Future<GameController> _start(
  WidgetTester tester, {
  Size size = const Size(393, 852),
  (double, double) safe = (59, 34),
  Locale locale = testLocale,
  PlayerLabels labels = PlayerLabels.defaults,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: safe.$1, bottom: safe.$2);
  tester.view.viewPadding = FakeViewPadding(top: safe.$1, bottom: safe.$2);
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(const GameConfig('wordtiles', seed: 1));
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(PlayerLabelsScope(labels: labels, child: buildGameScreen(c)), locale: locale));
  await tester.pump();
  await tester.pump();
  return c;
}

String _text(WidgetTester tester, Finder f) => tester.widget<Text>(f).data!;

void main() {
  setUpAll(_loadRoboto);
  setUp(() {
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
  });

  testWidgets('iPhone 15 Pro: "① Anna 0  ② Ben 0" in the score row, no players legend at the top', (tester) async {
    await _start(tester);
    expect(_text(tester, _name(0)), 'Anna');
    expect(_text(tester, _name(1)), 'Ben');
    expect(find.descendant(of: _score(0), matching: find.text('0')), findsOneWidget);
    expect(find.byKey(const Key('shell-players')), findsNothing, reason: 'the score row names the players');
    // One line: name and score side by side, the second seat after the first.
    final n0 = tester.getRect(_name(0)), n1 = tester.getRect(_name(1));
    expect(n0.center.dy, closeTo(n1.center.dy, 1));
    expect(n1.left, greaterThan(n0.right));
    // The player to move is highlighted (and bold).
    final on = tester.widget<Container>(_score(0)).decoration! as BoxDecoration;
    final off = tester.widget<Container>(_score(1)).decoration! as BoxDecoration;
    expect(on.color, isNotNull);
    expect(off.color, isNull);
    expect(tester.widget<Text>(_name(0)).style!.fontWeight, FontWeight.w700);
    expect(tester.takeException(), isNull);
  });

  testWidgets('other games keep the players legend', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = GameController.hotSeat(const GameConfig('connect4', seed: 1));
    addTearDown(c.dispose);
    await tester.pumpWidget(localizedApp(buildGameScreen(c)));
    await tester.pump();
    expect(find.byKey(const Key('shell-players')), findsOneWidget);
  });

  for (final width in [320.0, 375.0, 393.0, 430.0]) {
    testWidgets('$width px with long names: one line, the names shorten', (tester) async {
      await _start(
        tester,
        size: Size(width, width < 360 ? 568 : 852),
        safe: width < 360 ? (20, 0) : (59, 34),
        labels: const PlayerLabels(names: {Player.a: 'Maximiliane-Sophie', Player.b: 'Konstantinopel'}),
      );
      expect(tester.takeException(), isNull, reason: 'no overflow');
      final s0 = tester.getRect(_score(0)), s1 = tester.getRect(_score(1));
      expect(s0.height, lessThan(34), reason: 'one line');
      expect(s0.center.dy, closeTo(s1.center.dy, 1));
      expect(s1.left, greaterThanOrEqualTo(s0.right));
      expect(s1.right, lessThanOrEqualTo(tester.getRect(find.byKey(const Key('wordtiles-bag'))).left));
      final name = tester.renderObject<RenderParagraph>(
          find.descendant(of: _name(0), matching: find.byType(RichText)));
      expect(name.didExceedMaxLines, isTrue, reason: 'ellipsis');
      // The scores stay whole.
      expect(find.descendant(of: _score(1), matching: find.text('0')), findsOneWidget);
    });
  }

  testWidgets('right to left (ar): the first player on the right, names next to the scores', (tester) async {
    await _start(tester, locale: const Locale('ar'));
    expect(tester.takeException(), isNull);
    final s0 = tester.getRect(_score(0)), s1 = tester.getRect(_score(1));
    expect(s0.left, greaterThan(s1.right));
    final n0 = tester.getRect(_name(0));
    expect(n0.left, greaterThanOrEqualTo(s0.left));
    expect(n0.right, lessThanOrEqualTo(s0.right));
    expect(find.byKey(const Key('shell-players')), findsNothing);
  });

  testWidgets('a network game: both players named in the score row', (tester) async {
    await _start(tester,
        labels: const PlayerLabels(names: {Player.a: 'Lea', Player.b: 'Tom'}, local: Player.b));
    expect(_text(tester, _name(0)), 'Lea');
    expect(_text(tester, _name(1)), 'Tom');
  });

  testWidgets('same names: the number joins them, as in the status line', (tester) async {
    await _start(tester, labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Anna'}));
    expect(_text(tester, _name(0)), 'Anna (1)');
    expect(_text(tester, _name(1)), 'Anna (2)');
  });

  group('two-finger zoom', () {
    const zoom = 'Mit zwei Fingern zoomst du.';
    String hint(WidgetTester tester) => _text(tester, find.byKey(const Key('shell-hint')));

    testWidgets('from the second word on the hint line says it while the board is not zoomed', (tester) async {
      await _start(tester);
      const first = 'Das erste Wort muss über den Stern in der Mitte gehen.';
      expect(hint(tester), first, reason: 'the first hint stays one line');
      Future<void> tap(String key) async {
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
      }

      await tap('wordtiles-rack-0');
      await tap('wordtiles-sq-7-7');
      await tap('wordtiles-rack-1');
      await tap('wordtiles-sq-7-8');
      await tap('wordtiles-play');
      await tap('handover-continue');
      await tap('wordtiles-accept');
      const place = 'Ziehe Steine aufs Brett oder tippe einen Stein und dann ein Feld.';
      expect(hint(tester), '$place $zoom');
      // Lay a tile (the phone zooms in on it), take it back: zoomed, the
      // short hint.
      await tap('wordtiles-rack-0');
      await tap('wordtiles-sq-8-7');
      await tap('wordtiles-sq-8-7');
      expect(hint(tester), place);
      expect(tester.takeException(), isNull);
    });

    testWidgets('"So geht\'s" explains zoom and moving a laid tile', (tester) async {
      await _start(tester);
      await tester.tap(find.byKey(const Key('wordtiles-help')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Mit zwei Fingern zoomst du das Brett'), findsOneWidget);
      expect(find.byIcon(Icons.pinch_outlined), findsOneWidget);
    });
  });
}
