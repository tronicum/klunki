// KLD-094 step 8d: a tile laid on the board this turn (not yet played with
// "Legen") moves by long-press and drag: to another free square, onto
// another laid tile (they swap), back to the rack or onto the bench. A tap
// still takes it back to the rack; a plain pan still scrolls a zoomed
// board; tiles of earlier turns stay where they are.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_tiles.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _sq(int r, int c) => find.byKey(Key('wordtiles-sq-$r-$c'));
Finder _rack(int i) => find.byKey(Key('wordtiles-rack-$i'));
Finder _letter(int r, int c, String l) => find.descendant(of: _sq(r, c), matching: find.text(l));

WordTilesGame _game(GameController c) => c.game as WordTilesGame;

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await _pump(tester);
}

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<GameController> _start(
  WidgetTester tester, {
  Size size = const Size(1180, 820),
  Locale locale = testLocale,
}) async {
  _size(tester, size);
  final c = GameController.hotSeat(const GameConfig('wordtiles', seed: 1));
  addTearDown(c.dispose);
  _game(c).debugSetup(
    racks: const [
      ['H', 'A', 'U', 'S', 'E', 'N', '?'],
      ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
    ],
    bag: List.filled(40, 'E'),
  );
  await tester.pumpWidget(localizedApp(buildGameScreen(c), locale: locale));
  await _pump(tester);
  return c;
}

Future<void> _lay(WidgetTester tester, List<(int, int, int)> tiles) async {
  for (final (i, r, col) in tiles) {
    await tester.ensureVisible(_sq(r, col));
    await _tap(tester, _rack(i));
    await _tap(tester, _sq(r, col));
  }
}

/// Long-press on [from], drag to [to], let go.
Future<void> _longDrag(WidgetTester tester, Finder from, Offset to) async {
  final g = await tester.startGesture(tester.getCenter(from));
  await tester.pump(const Duration(milliseconds: 600));
  // In steps, as a finger moves.
  final start = tester.getCenter(from);
  for (var i = 1; i <= 5; i++) {
    await g.moveTo(Offset.lerp(start, to, i / 5)!);
    await tester.pump();
  }
  await g.up();
  await _pump(tester);
}

String _preview(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('wordtiles-preview'))).data!;

void main() {
  setUp(() {
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
  });

  testWidgets('a tap still takes a laid tile back to the rack', (tester) async {
    await _start(tester);
    await _lay(tester, [(0, 7, 7)]);
    expect(_rack(0), findsNothing);
    await _tap(tester, _sq(7, 7));
    expect(_rack(0), findsOneWidget);
    expect(_letter(7, 7, 'H'), findsNothing);
  });

  testWidgets('long-press and drag moves a laid tile to another square; the preview follows', (tester) async {
    await _start(tester);
    await _lay(tester, [(0, 7, 7), (1, 7, 8)]);
    expect(_preview(tester), 'HA: 4 Punkte');
    await _longDrag(tester, _sq(7, 7), tester.getCenter(_sq(7, 9)));
    expect(_letter(7, 7, 'H'), findsNothing);
    expect(_letter(7, 9, 'H'), findsOneWidget);
    expect(_rack(0), findsNothing, reason: 'still on the board');
    expect(_preview(tester), isNot('HA: 4 Punkte'), reason: 'A H, not HA: the preview changed');
    // Back next to the A, the other way round: AH.
    await _longDrag(tester, _sq(7, 9), tester.getCenter(_sq(7, 7)));
    expect(_letter(7, 7, 'H'), findsOneWidget);
    expect(_preview(tester), 'HA: 4 Punkte');
    expect(tester.takeException(), isNull);
  });

  testWidgets('onto another laid tile the two swap places', (tester) async {
    await _start(tester);
    await _lay(tester, [(0, 7, 7), (1, 7, 8)]);
    await _longDrag(tester, _sq(7, 7), tester.getCenter(_sq(7, 8)));
    expect(_letter(7, 8, 'H'), findsOneWidget);
    expect(_letter(7, 7, 'A'), findsOneWidget);
    expect(_preview(tester), 'AH: 4 Punkte');
  });

  testWidgets('drag back to the rack and onto the bench', (tester) async {
    await _start(tester);
    expect(find.byKey(const Key('wordtiles-bench-0-0')), findsOneWidget, reason: 'bench open on a tablet');
    await _lay(tester, [(0, 7, 7), (1, 7, 8)]);
    await _longDrag(tester, _sq(7, 7), tester.getCenter(find.byKey(const Key('wordtiles-rack'))));
    expect(_rack(0), findsOneWidget);
    expect(_letter(7, 7, 'H'), findsNothing);
    await _longDrag(tester, _sq(7, 8), tester.getCenter(find.byKey(const Key('wordtiles-bench-0-0'))));
    expect(_letter(7, 8, 'A'), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('wordtiles-bench-0-0')), matching: find.text('A')), findsOneWidget);
  });

  testWidgets('onto a tile of an earlier turn: refused, the tile goes back to its square', (tester) async {
    final c = await _start(tester);
    await _lay(tester, [(0, 7, 7), (1, 7, 8)]);
    await _tap(tester, find.byKey(const Key('wordtiles-play')));
    await _tap(tester, find.byKey(handoverContinue));
    await _tap(tester, find.byKey(const Key('wordtiles-accept')));
    expect(_game(c).tileAt(7, 7), isNotNull, reason: 'HA is on the board');
    await _lay(tester, [(0, 8, 7)]); // Ben's T under the H
    await _longDrag(tester, _sq(8, 7), tester.getCenter(_sq(7, 8)));
    expect(_letter(8, 7, 'T'), findsOneWidget, reason: 'snapped back');
    expect(_letter(7, 8, 'A'), findsOneWidget);
    // An earlier tile does not move.
    await _longDrag(tester, _sq(7, 7), tester.getCenter(_sq(9, 9)));
    expect(_letter(7, 7, 'H'), findsOneWidget);
    expect(_letter(9, 9, 'H'), findsNothing);
  });

  testWidgets('a blank keeps its chosen letter when it moves', (tester) async {
    await _start(tester);
    await _tap(tester, _rack(6));
    await _tap(tester, _sq(7, 7));
    await _tap(tester, find.byKey(const Key('wordtiles-blank-E')));
    await _longDrag(tester, _sq(7, 7), tester.getCenter(_sq(7, 9)));
    final tile = find.descendant(of: _sq(7, 9), matching: find.byType(LetterTile));
    expect(tile, findsOneWidget);
    expect(tester.widget<LetterTile>(tile).letter, 'E');
    expect(tester.widget<LetterTile>(tile).blank, isTrue);
    expect(find.byKey(const Key('wordtiles-blank-picker')), findsNothing, reason: 'not asked again');
  });

  testWidgets('phone, zoomed in: long-press drags the tile, a plain pan scrolls the board', (tester) async {
    await _start(tester, size: const Size(390, 844));
    final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
    await _lay(tester, [(0, 7, 7)]);
    await tester.pumpAndSettle();
    expect(viewer.value.getMaxScaleOnAxis(), greaterThan(1.5), reason: 'zoomed in on the first tile');
    await _longDrag(tester, _sq(7, 7), tester.getCenter(_sq(7, 8)));
    expect(_letter(7, 8, 'H'), findsOneWidget);
    expect(_letter(7, 7, 'H'), findsNothing);

    // A plain pan starting on the laid tile scrolls; the tile stays.
    final before = viewer.value.getTranslation();
    await tester.dragFrom(tester.getCenter(_sq(7, 8)), const Offset(-60, 0));
    await tester.pumpAndSettle();
    expect(viewer.value.getTranslation(), isNot(before));
    expect(_letter(7, 8, 'H'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic (right to left): drag moves the tile to the square under the finger', (tester) async {
    await _start(tester, locale: const Locale('ar'));
    await _lay(tester, [(0, 7, 7)]);
    await _longDrag(tester, _sq(7, 7), tester.getCenter(_sq(7, 9)));
    expect(_letter(7, 9, 'H'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
