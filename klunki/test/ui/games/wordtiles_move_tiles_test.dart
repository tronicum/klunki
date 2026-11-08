// KLD-094 step 8d: a tile laid on the board this turn (not yet played with
// "Legen") moves by drag (step 8h: at once, no hold): to another free
// square, onto another laid tile (they swap), back to the rack or onto the
// bench. A tap still takes it back to the rack; a pan that starts elsewhere
// still scrolls a zoomed board; tiles of earlier turns stay where they are.
import 'package:flutter/gestures.dart';
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

/// [safe]: an iPhone's top and bottom safe areas (notch, home indicator).
void _size(WidgetTester tester, Size size, {(double, double) safe = (0, 0)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: safe.$1, bottom: safe.$2);
  tester.view.viewPadding = FakeViewPadding(top: safe.$1, bottom: safe.$2);
  addTearDown(tester.view.reset);
}

Future<GameController> _start(
  WidgetTester tester, {
  Size size = const Size(1180, 820),
  (double, double) safe = (0, 0),
  Locale locale = testLocale,
}) async {
  _size(tester, size, safe: safe);
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
    SeenTips.shared.markFirst(SeenTips.rulesOpened('wordtiles')); // no "Neu hier?" line (KLD-123)
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

  testWidgets('phone, zoomed in: a long drag moves the tile, a pan from an empty square scrolls', (tester) async {
    await _start(tester, size: const Size(390, 844));
    final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
    await _lay(tester, [(0, 7, 7)]);
    await tester.pumpAndSettle();
    expect(viewer.value.getMaxScaleOnAxis(), greaterThan(1.5), reason: 'zoomed in on the first tile');
    await _longDrag(tester, _sq(7, 7), tester.getCenter(_sq(7, 8)));
    expect(_letter(7, 8, 'H'), findsOneWidget);
    expect(_letter(7, 7, 'H'), findsNothing);

    // A pan starting on the empty square next to it scrolls; the tile stays.
    final before = viewer.value.getTranslation();
    await tester.dragFrom(tester.getCenter(_sq(7, 7)), const Offset(-60, 0));
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

  // KLD-094 step 8h, the PWA on a computer ("dragging of placed letters in
  // the github version does not work"): the mouse presses a laid tile and
  // drags at once (it needs no hold: a mouse does not scroll the board by
  // dragging a tile), or after a pause; both move the tile. A click still
  // takes it back.
  group('mouse', () {
    Future<void> mouse(WidgetTester tester, Offset from, Offset to,
        {Duration hold = Duration.zero}) async {
      final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: from);
      await g.down(from);
      if (hold > Duration.zero) await tester.pump(hold);
      for (var i = 1; i <= 12; i++) {
        await g.moveTo(Offset.lerp(from, to, i / 12)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await g.removePointer();
      await tester.pumpAndSettle();
    }

    for (final (name, size) in [('tablet', Size(1180, 820)), ('desktop browser', Size(1200, 900))]) {
      for (final hold in [0, 300]) {
        testWidgets('$name: click and drag (hold $hold ms) moves a laid tile', (tester) async {
          await _start(tester, size: size);
          await _lay(tester, [(0, 7, 7)]);
          await tester.pumpAndSettle();
          await mouse(tester, tester.getCenter(_sq(7, 7)), tester.getCenter(_sq(7, 9)),
              hold: Duration(milliseconds: hold));
          expect(_letter(7, 9, 'H'), findsOneWidget);
          expect(_letter(7, 7, 'H'), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('phone layout, zoomed in: the mouse drags the laid tile at once', (tester) async {
      await _start(tester, size: const Size(390, 844));
      await _lay(tester, [(0, 7, 7)]);
      await tester.pumpAndSettle();
      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
      expect(viewer.value.getMaxScaleOnAxis(), greaterThan(1.5));
      await mouse(tester, tester.getCenter(_sq(7, 7)), tester.getCenter(_sq(8, 7)));
      expect(_letter(8, 7, 'H'), findsOneWidget);
      expect(_letter(7, 7, 'H'), findsNothing);
    });

    testWidgets('a mouse click takes the laid tile back to the rack', (tester) async {
      await _start(tester);
      await _lay(tester, [(0, 7, 7)]);
      await tester.pumpAndSettle();
      await tester.tap(_sq(7, 7), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(_rack(0), findsOneWidget);
      expect(_letter(7, 7, 'H'), findsNothing);
    });
  });

  // KLD-094 step 8g: the iPhone 15 Pro playtest (393 × 852 with its safe
  // areas: the small-phone layout with the Bänkchen bar under the board).
  // A finger, not a test tap: it rests a while and wobbles a few pixels
  // (within the touch slop) before it moves, in frames of 16 ms. Before the
  // fix a laid tile needed Flutter's full 500 ms long press; a finger that
  // started moving earlier scrolled the zoomed board, and on the unzoomed
  // board nothing moved at all.
  group('iPhone 15 Pro, a real finger', () {
    const phone = Size(393, 852);
    const safe = (59.0, 34.0);

    InteractiveViewer viewer(WidgetTester tester) => tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    double scale(WidgetTester tester) => viewer(tester).transformationController!.value.getMaxScaleOnAxis();

    Future<void> unzoom(WidgetTester tester) async {
      viewer(tester).transformationController!.value = Matrix4.identity();
      await tester.pumpAndSettle();
      expect(scale(tester), 1);
    }

    /// Finger down on [from], resting [hold] while wobbling up to [wobble]
    /// px, then a move to [to] in steps; [check] runs mid-drag.
    Future<void> finger(WidgetTester tester, Offset from, Offset to,
        {Duration hold = Duration.zero, double wobble = 3, void Function(Offset at)? check}) async {
      final g = await tester.startGesture(from, kind: PointerDeviceKind.touch);
      final frames = hold.inMilliseconds ~/ 16;
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        await g.moveTo(from + Offset(i.isEven ? wobble : -wobble / 2, wobble / 3));
      }
      for (var i = 1; i <= 12; i++) {
        await g.moveTo(Offset.lerp(from, to, i / 12)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      check?.call(to);
      await g.up();
      await tester.pumpAndSettle();
    }

    Future<void> layH(WidgetTester tester) async {
      await _lay(tester, [(0, 7, 7)]);
      await tester.pumpAndSettle();
    }

    testWidgets('small-phone layout: the Bänkchen bar is under the board', (tester) async {
      await _start(tester, size: phone, safe: safe);
      expect(find.byKey(const Key('wordtiles-bench-bar')), findsOneWidget);
    });

    testWidgets('not zoomed: a laid tile moves after a short rest', (tester) async {
      await _start(tester, size: phone, safe: safe);
      await layH(tester);
      await unzoom(tester);
      await finger(tester, tester.getCenter(_sq(7, 7)), tester.getCenter(_sq(9, 7)),
          hold: const Duration(milliseconds: 160));
      expect(_letter(9, 7, 'H'), findsOneWidget);
      expect(_letter(7, 7, 'H'), findsNothing);
    });

    testWidgets('not zoomed: rest a little longer, then drag', (tester) async {
      await _start(tester, size: phone, safe: safe);
      await layH(tester);
      await unzoom(tester);
      await finger(tester, tester.getCenter(_sq(7, 7)), tester.getCenter(_sq(7, 10)),
          hold: const Duration(milliseconds: 300));
      expect(_letter(7, 10, 'H'), findsOneWidget);
    });

    for (final hold in [300, 450, 700]) {
      testWidgets('zoomed in: rest $hold ms (wobbling), then drag: the tile moves', (tester) async {
        await _start(tester, size: phone, safe: safe);
        await layH(tester);
        expect(scale(tester), greaterThan(1.5), reason: 'zoomed in on the first tile');
        await finger(tester, tester.getCenter(_sq(7, 7)), tester.getCenter(_sq(9, 7)),
            hold: Duration(milliseconds: hold), wobble: 6);
        expect(_letter(9, 7, 'H'), findsOneWidget);
        expect(_letter(7, 7, 'H'), findsNothing);
      });
    }

    // KLD-094 step 8h (maintainer decision): no rest any more.
    for (final zoomed in [false, true]) {
      testWidgets('${zoomed ? 'zoomed in' : 'not zoomed'}: a finger drags the laid tile at once', (tester) async {
        await _start(tester, size: phone, safe: safe);
        await layH(tester);
        if (!zoomed) await unzoom(tester);
        final before = viewer(tester).transformationController!.value.clone();
        await finger(tester, tester.getCenter(_sq(7, 7)), tester.getCenter(_sq(8, 8)), wobble: 0);
        expect(_letter(8, 8, 'H'), findsOneWidget);
        expect(_letter(7, 7, 'H'), findsNothing);
        expect(viewer(tester).transformationController!.value, before, reason: 'the board did not scroll');
      });
    }

    testWidgets('zoomed in: a drag starting on an empty square scrolls the board', (tester) async {
      await _start(tester, size: phone, safe: safe);
      await layH(tester);
      final before = viewer(tester).transformationController!.value.getTranslation();
      final from = tester.getCenter(_sq(8, 8));
      await finger(tester, from, from + const Offset(-80, -40));
      expect(viewer(tester).transformationController!.value.getTranslation(), isNot(before));
      expect(_letter(7, 7, 'H'), findsOneWidget, reason: 'the tile stays');
    });

    // Fingers 1 and 2 pinch in, one of them starting on the laid tile.
    for (final first in [true, false]) {
      testWidgets('zoomed in: a pinch with the ${first ? 'first' : 'second'} finger on the laid tile zooms',
          (tester) async {
        await _start(tester, size: phone, safe: safe);
        await layH(tester);
        final start = scale(tester);
        final tile = tester.getCenter(_sq(7, 7));
        final other = tile + const Offset(70, 70);
        final (p1, p2) = first ? (tile, other) : (other, tile);
        final a = await tester.startGesture(p1, pointer: 1);
        await tester.pump(const Duration(milliseconds: 16));
        final b = await tester.startGesture(p2, pointer: 2);
        for (var i = 1; i <= 10; i++) {
          await a.moveTo(Offset.lerp(p1, (p1 + p2) / 2, i / 20)!);
          await b.moveTo(Offset.lerp(p2, (p1 + p2) / 2, i / 20)!);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await a.up();
        await b.up();
        await tester.pumpAndSettle();
        expect(scale(tester), lessThan(start - 0.2), reason: 'zoomed out');
        expect(_letter(7, 7, 'H'), findsOneWidget);
      });
    }

    for (final zoomed in [false, true]) {
      testWidgets('${zoomed ? 'zoomed' : 'not zoomed'}: the lifted tile keeps the spot under the finger',
          (tester) async {
        await _start(tester, size: phone, safe: safe);
        await layH(tester);
        if (!zoomed) await unzoom(tester);
        final tile = tester.getRect(_sq(7, 7));
        // Near the tile's top left corner: the finger stays near the lifted
        // tile's top left corner (before: the tile hung beside the finger).
        final from = tile.topLeft + Offset(tile.width * 0.25, tile.height * 0.25);
        final target = tester.getCenter(_sq(9, 9));
        await finger(tester, from, target, hold: const Duration(milliseconds: 300), check: (at) {
          final lifted = tester.getRect(find.byWidgetPredicate((w) => w is LetterTile && w.lifted));
          expect(lifted.width, greaterThanOrEqualTo(52));
          expect((at.dx - lifted.left) / lifted.width, closeTo(0.25, 0.06));
          expect((at.dy - lifted.top) / lifted.height, closeTo(0.25, 0.06));
        });
        expect(_letter(9, 9, 'H'), findsOneWidget, reason: 'dropped on the square under the finger');
      });
    }

    testWidgets('not zoomed: two fingers starting on a laid tile zoom, the tile stays', (tester) async {
      await _start(tester, size: phone, safe: safe);
      await layH(tester);
      await unzoom(tester);
      final c = tester.getCenter(_sq(7, 7));
      final a = await tester.startGesture(c, pointer: 1);
      final b = await tester.startGesture(c + const Offset(40, 40), pointer: 2);
      for (var i = 1; i <= 10; i++) {
        await a.moveTo(c - Offset(6.0 * i, 6.0 * i));
        await b.moveTo(c + Offset(40 + 6.0 * i, 40 + 6.0 * i));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      expect(scale(tester), greaterThan(1.2));
      expect(_letter(7, 7, 'H'), findsOneWidget);
    });

    testWidgets('a tap still takes the laid tile back; rack tiles still drag onto the board', (tester) async {
      await _start(tester, size: phone, safe: safe);
      await layH(tester);
      await _tap(tester, _sq(7, 7));
      expect(_rack(0), findsOneWidget);
      expect(_letter(7, 7, 'H'), findsNothing);
      await finger(tester, tester.getCenter(_rack(1)), tester.getCenter(_sq(7, 7)));
      expect(_letter(7, 7, 'A'), findsOneWidget);
    });

    testWidgets('the open Bänkchen: a laid tile drags onto it, a bench tile back onto the board', (tester) async {
      await _start(tester, size: phone, safe: safe);
      await layH(tester);
      await unzoom(tester);
      await _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));
      final slot = find.byKey(const Key('wordtiles-bench-0-0'));
      expect(slot, findsOneWidget);
      await finger(tester, tester.getCenter(_sq(7, 7)), tester.getCenter(slot), hold: const Duration(milliseconds: 160));
      expect(find.descendant(of: slot, matching: find.text('H')), findsOneWidget);
      expect(_letter(7, 7, 'H'), findsNothing);
      await finger(tester, tester.getCenter(slot), tester.getCenter(_sq(3, 7)));
      expect(_letter(3, 7, 'H'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // KLD-094 step 8h, browser playtest: "if i touch another letter the first
  // one can only be removed by click not by drag". One mouse (or one finger
  // after the other) does everything in a row: lay, select, drag other
  // tiles, then drag the first one again.
  for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    group('${kind.name}: after touching another letter', () {
      late TestGesture mouse;
      var next = 100;

      Future<TestGesture> press(WidgetTester tester, Offset at) async {
        if (kind == PointerDeviceKind.mouse) {
          await mouse.down(at);
          return mouse;
        }
        return tester.startGesture(at, kind: kind, pointer: next++);
      }

      Future<void> click(WidgetTester tester, Finder f) async {
        await tester.ensureVisible(f);
        final g = await press(tester, tester.getCenter(f));
        await tester.pump(const Duration(milliseconds: 60));
        await g.up();
        await tester.pumpAndSettle();
      }

      Future<void> drag(WidgetTester tester, Finder from, Finder to) async {
        final a = tester.getCenter(from);
        final b = tester.getCenter(to);
        final g = await press(tester, a);
        for (var i = 1; i <= 12; i++) {
          await g.moveTo(Offset.lerp(a, b, i / 12)!);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await tester.pumpAndSettle();
      }

      Future<void> start(WidgetTester tester) async {
        await _start(tester, size: const Size(1200, 900));
        if (kind == PointerDeviceKind.mouse) {
          mouse = await tester.createGesture(kind: kind);
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
        }
        await click(tester, _rack(0));
        await click(tester, _sq(7, 7)); // H
        expect(_letter(7, 7, 'H'), findsOneWidget);
      }

      testWidgets('another tile laid by tap, then the first one drags', (tester) async {
        await start(tester);
        await click(tester, _rack(1));
        await click(tester, _sq(7, 8)); // A
        await drag(tester, _sq(7, 7), _sq(8, 7));
        expect(_letter(8, 7, 'H'), findsOneWidget);
      });

      testWidgets('dragged once, a rack tile selected, then it drags again', (tester) async {
        await start(tester);
        await drag(tester, _sq(7, 7), _sq(7, 9));
        expect(_letter(7, 9, 'H'), findsOneWidget);
        await click(tester, _rack(1));
        await drag(tester, _sq(7, 9), _sq(8, 9));
        expect(_letter(8, 9, 'H'), findsOneWidget);
      });

      testWidgets('another laid tile dragged, then the first one drags', (tester) async {
        await start(tester);
        await click(tester, _rack(1));
        await click(tester, _sq(7, 8)); // A
        await drag(tester, _sq(7, 8), _sq(8, 8));
        expect(_letter(8, 8, 'A'), findsOneWidget);
        await drag(tester, _sq(7, 7), _sq(6, 7));
        expect(_letter(6, 7, 'H'), findsOneWidget);
        await drag(tester, _sq(8, 8), _sq(9, 8));
        expect(_letter(9, 8, 'A'), findsOneWidget);
      });

      testWidgets('a rack tile dragged onto the board, then the first one drags', (tester) async {
        await start(tester);
        await drag(tester, _rack(1), _sq(7, 8));
        expect(_letter(7, 8, 'A'), findsOneWidget);
        await drag(tester, _sq(7, 7), _sq(8, 7));
        expect(_letter(8, 7, 'H'), findsOneWidget);
      });

      testWidgets('a rack tile swapped in by tap, then it drags', (tester) async {
        await start(tester);
        await click(tester, _rack(1));
        await click(tester, _sq(7, 7)); // A takes the square, H back to the rack
        expect(_letter(7, 7, 'A'), findsOneWidget);
        await drag(tester, _sq(7, 7), _sq(8, 7));
        expect(_letter(8, 7, 'A'), findsOneWidget);
      });

      // A press whose release never reaches the app (a right click that
      // opens the browser's menu, a button let go outside the window) must
      // not count as a finger that stays down: the next drag still lifts.
      testWidgets('a press without a release elsewhere, then it drags', (tester) async {
        await start(tester);
        final lost = await tester.createGesture(kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
        await lost.down(tester.getCenter(_rack(1)));
        await tester.pump();
        await drag(tester, _sq(7, 7), _sq(8, 7));
        expect(_letter(8, 7, 'H'), findsOneWidget);
        await lost.cancel();
      });

      testWidgets('dropped on the bench and back, then it drags', (tester) async {
        await start(tester);
        final slot = find.byKey(const Key('wordtiles-bench-0-0'));
        await drag(tester, _sq(7, 7), slot);
        await drag(tester, slot, _sq(7, 8));
        expect(_letter(7, 8, 'H'), findsOneWidget);
        await drag(tester, _sq(7, 8), _sq(8, 8));
        expect(_letter(8, 8, 'H'), findsOneWidget);
      });
    });
  }

  // A finger that rests on another letter (the rack) or anywhere off the
  // board cannot pinch the board: a second finger still drags the laid tile.
  // On the board, a resting finger makes it a pinch: the tile stays.
  for (final (name, size) in [('tablet', Size(1180, 820)), ('phone, zoomed', Size(393, 852))]) {
    testWidgets('$name: a finger resting on a rack letter, another finger drags the laid tile', (tester) async {
      await _start(tester, size: size);
      await _lay(tester, [(0, 7, 7)]);
      await tester.pumpAndSettle();
      final rest = await tester.startGesture(tester.getCenter(_rack(1)), pointer: 41);
      await tester.pump(const Duration(milliseconds: 100));
      final a = tester.getCenter(_sq(7, 7));
      final b = tester.getCenter(_sq(8, 7));
      final g = await tester.startGesture(a, pointer: 42);
      for (var i = 1; i <= 12; i++) {
        await g.moveTo(Offset.lerp(a, b, i / 12)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(_letter(8, 7, 'H'), findsOneWidget);
      await rest.cancel();
      await tester.pumpAndSettle();
    });
  }

  testWidgets('a finger resting on the board: the other finger pinches, the laid tile stays', (tester) async {
    await _start(tester);
    await _lay(tester, [(0, 7, 7)]);
    await tester.pumpAndSettle();
    final rest = await tester.startGesture(tester.getCenter(_sq(3, 3)), pointer: 41);
    await tester.pump(const Duration(milliseconds: 100));
    final a = tester.getCenter(_sq(7, 7));
    final g = await tester.startGesture(a, pointer: 42);
    for (var i = 1; i <= 12; i++) {
      await g.moveTo(a + Offset(6.0 * i, 6.0 * i));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await rest.up();
    await tester.pumpAndSettle();
    expect(_letter(7, 7, 'H'), findsOneWidget);
  });
}
