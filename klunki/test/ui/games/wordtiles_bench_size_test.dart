// KLD-094 step 8e: where there is room (tablets, the landscape side panel,
// browser widths) the Bänkchen tiles are about as big as the rack tiles, not
// shrunk to a small bench size; on a phone they may stay smaller so both
// rows fit without scrolling. Nothing overflows on any size.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';

const _bench00 = Key('wordtiles-bench-0-0');

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
  });

  // (size, wide: bench tile at least 90 % of the rack tile)
  const sizes = [
    (Size(390, 844), false),
    (Size(375, 667), false),
    (Size(430, 932), false),
    (Size(820, 1180), true),
    (Size(1180, 820), true),
    (Size(1280, 800), true),
    (Size(1440, 900), true),
  ];
  for (final (size, wide) in sizes) {
    testWidgets(
      '${size.width.toInt()}×${size.height.toInt()}: bench tiles ${wide ? 'as big as' : 'up to'} the rack tiles',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final c = GameController.hotSeat(const GameConfig('wordtiles', seed: 1));
        addTearDown(c.dispose);
        (c.game as WordTilesGame).debugSetup(
          racks: const [
            ['H', 'A', 'U', 'S', 'E', 'N', '?'],
            ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
          ],
          bag: List.filled(40, 'E'),
        );
        await tester.pumpWidget(localizedApp(buildGameScreen(c)));
        await _pump(tester);
        if (find.byKey(_bench00).evaluate().isEmpty) {
          await tester.tap(find.byKey(const Key('wordtiles-bench-toggle')));
          await _pump(tester);
        }
        final rackTile = tester.getSize(find.byKey(const Key('wordtiles-rack-1')));
        // A tile on the bench: the H.
        await tester.ensureVisible(find.byKey(const Key('wordtiles-rack-0')));
        await tester.tap(find.byKey(const Key('wordtiles-rack-0')));
        await _pump(tester);
        await tester.ensureVisible(find.byKey(_bench00));
        await tester.tap(find.byKey(_bench00));
        await _pump(tester);
        expect(find.descendant(of: find.byKey(_bench00), matching: find.text('H')), findsOneWidget);
        final benchTile = tester.getSize(find.byKey(_bench00));
        expect(benchTile.width, lessThanOrEqualTo(rackTile.width + 0.01));
        if (wide) {
          expect(
            benchTile.width,
            greaterThanOrEqualTo(rackTile.width * 0.9),
            reason: 'bench ${benchTile.width}, rack ${rackTile.width}',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
