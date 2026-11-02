// KLD-094 step 8b (layout): the vertical space of the word tile screen. The
// board sits right under the score row, the rack and the actions right
// under the board, the open Bänkchen right under them; what is left over
// goes to the very bottom (before, the board was centred in a flexible area
// with empty bands above and below it, and the open bench ran to the bottom
// edge). Small phones keep the bench overlay (step 5), a tablet in portrait
// shrinks the board a little instead, landscape keeps board | panel. No size
// overflows. With the bundled Roboto, so the heights are those of the real
// app and the screenshots (the test font is taller and wider).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';

const _toggle = Key('wordtiles-bench-toggle');

/// Between the score row and the board only the last-turn line (one line,
/// reserved before the first turn too, so the board does not jump) and its
/// padding: 20 + 8 px, plus a little for the score row's buttons.
final _underScoreRow = inInclusiveRange(0, 40);
const _overlay = Key('wordtiles-bench-overlay');

Rect _rect(WidgetTester tester, String key) => tester.getRect(find.byKey(Key(key)));

/// The board's outer edges (first and last square).
Rect _board(WidgetTester tester) => _rect(tester, 'wordtiles-sq-0-0').expandToInclude(_rect(tester, 'wordtiles-sq-14-14'));

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> _start(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(const GameConfig('wordtiles', seed: 1));
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await _pump(tester);
  expect(tester.takeException(), isNull, reason: '$size: no overflow (bench closed)');
}

Future<void> _toggleBench(WidgetTester tester, Size size) async {
  await tester.ensureVisible(find.byKey(_toggle));
  await tester.tap(find.byKey(_toggle));
  await _pump(tester);
  expect(tester.takeException(), isNull, reason: '$size: no overflow after toggling the bench');
}

Future<void> _loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Roboto/Roboto-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadRoboto);
  setUp(SeenTips.debugReset);
  setUp(() => SeenTips.shared.markFirst(SeenTips.wordtilesBench));

  // Large phones keep the full board with the bench open; a mid-size phone
  // (390 × 844, 375 × 812) gives up a little board for the bench below the
  // actions instead of the overlay (at most 15 %).
  for (final (size, keepsBoard) in [
    (const Size(430, 932), true),
    (const Size(412, 915), true),
    (const Size(390, 844), false),
    (const Size(375, 812), false),
  ]) {
    testWidgets('phone $size: board under the score row, rack under the board, the open bench fully visible',
        (tester) async {
      await _start(tester, size);
      void expectTight(String state) {
        final board = _board(tester);
        final scoreRow = _rect(tester, 'wordtiles-help');
        expect(board.top - scoreRow.bottom, _underScoreRow, reason: '$state: board right under the score row');
        // Between board and rack only the score preview line (22 px).
        expect(_rect(tester, 'wordtiles-rack').top - board.bottom, inInclusiveRange(0, 32),
            reason: '$state: rack right under the board');
      }

      expectTight('closed');
      final closed = _board(tester);
      expect(closed.width, closeTo(size.width - 8, 3), reason: 'the board as wide as the screen');
      // The leftover space is at the very bottom, below the controls.
      expect(_rect(tester, 'wordtiles-bench').bottom, lessThan(size.height - 40));

      await _toggleBench(tester, size);
      expect(find.byKey(_overlay), findsNothing);
      expectTight('open');
      final open = _board(tester);
      if (keepsBoard) {
        expect(open, closed, reason: 'enough room: the board keeps its size');
      } else {
        expect(open.top, closed.top);
        expect(open.width, inInclusiveRange(closed.width * 0.85, closed.width - 1), reason: 'a little smaller');
        expect((open.center.dx - size.width / 2).abs(), lessThan(2), reason: 'centred');
      }
      final bench = _rect(tester, 'wordtiles-bench');
      expect(bench.top, greaterThanOrEqualTo(_rect(tester, 'wordtiles-play').bottom), reason: 'below the actions');
      expect(bench.bottom, lessThanOrEqualTo(size.height - 7.9), reason: 'fully visible, off the bottom edge');
      expect(_rect(tester, 'wordtiles-bench-1-8').bottom, lessThanOrEqualTo(size.height - 7.9));
    });
  }

  for (final size in [const Size(375, 667), const Size(320, 568), const Size(360, 640), const Size(360, 760)]) {
    testWidgets('small phone $size: the open bench lies over the lower board; no gaps, no overflow', (tester) async {
      await _start(tester, size);
      final closed = _board(tester);
      expect(closed.top - _rect(tester, 'wordtiles-help').bottom, _underScoreRow);
      expect(_rect(tester, 'wordtiles-rack').top - closed.bottom, inInclusiveRange(0, 32));
      await _toggleBench(tester, size);
      final overlay = tester.getRect(find.byKey(_overlay));
      expect(_board(tester), closed, reason: 'the board keeps its size');
      expect(overlay.bottom, closeTo(closed.bottom, 6), reason: 'over the lower part of the board');
      expect(overlay.top, greaterThan(closed.top));
      expect(_rect(tester, 'wordtiles-play').bottom, lessThanOrEqualTo(size.height));
      await _toggleBench(tester, size);
      expect(find.byKey(_overlay), findsNothing);
    });
  }

  testWidgets('tablet portrait: the bench below the actions, the board a little smaller', (tester) async {
    const size = Size(820, 1180);
    await _start(tester, size);
    final closed = _board(tester);
    expect(closed.top - _rect(tester, 'wordtiles-help').bottom, _underScoreRow);
    await _toggleBench(tester, size);
    expect(find.byKey(_overlay), findsNothing, reason: 'room enough for the bench below');
    final open = _board(tester);
    expect(open.top, closed.top);
    expect(open.width, greaterThan(closed.width * 0.8));
    expect(_rect(tester, 'wordtiles-rack').top - open.bottom, inInclusiveRange(0, 32));
    expect(_rect(tester, 'wordtiles-bench').bottom, lessThanOrEqualTo(size.height));
  });

  for (final size in [const Size(1180, 820), const Size(932, 430), const Size(568, 320)]) {
    testWidgets('landscape $size: board left, panel right, no overflow', (tester) async {
      await _start(tester, size);
      expect(_rect(tester, 'wordtiles-rack').left, greaterThanOrEqualTo(_board(tester).right));
      await _toggleBench(tester, size);
      expect(find.byKey(_overlay), findsNothing);
      expect(_rect(tester, 'wordtiles-bench').left, greaterThanOrEqualTo(_board(tester).right));
    });
  }
}
