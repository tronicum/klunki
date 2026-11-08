// KLD-058: the GoStrategy board zooms like Wortgewandt's (pinch, pan, the
// zoom button, the mouse wheel); taps select and move at any zoom, the setup
// editor swaps by taps and drags at zoom, each player keeps their own view
// (hot-seat: the turned board), the coordinates follow the zoomed squares.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../shell/shell_test_utils.dart';
import 'gostrategy_screen_test.dart'
    show acknowledge, cell, gameOf, pumpPosition, shown, squareOf, tapKey, tapOn;

/// iPhone 15 Pro, logical pixels.
void iphone(WidgetTester tester) {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

TransformationController zoomOf(WidgetTester tester) =>
    tester.widget<InteractiveViewer>(find.byKey(const Key('go-zoom-view'))).transformationController!;

double scaleOf(WidgetTester tester) => zoomOf(tester).value.getMaxScaleOnAxis();

/// Two fingers around [at], [from] px apart, spread to [to] px apart.
Future<void> pinch(WidgetTester tester, Offset at, {double from = 30, double to = 110, int pointer = 1}) async {
  final a = await tester.startGesture(at - Offset(from / 2, 0), pointer: pointer);
  await tester.pump(const Duration(milliseconds: 16));
  final b = await tester.startGesture(at + Offset(from / 2, 0), pointer: pointer + 1);
  for (var i = 1; i <= 10; i++) {
    final d = from + (to - from) * i / 10;
    await a.moveTo(at - Offset(d / 2, 0));
    await b.moveTo(at + Offset(d / 2, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await a.up();
  await b.up();
  await tester.pumpAndSettle();
}

/// The square's centre lies in the board's visible area.
bool visible(WidgetTester tester, int sq) {
  final view = tester.getRect(find.byKey(const Key('go-zoom-view')));
  return view.contains(tester.getCenter(cell(sq)));
}

/// X captain on 64 (open front), O sergeant on 35, both flags at the back.
GoStrategyGame _front() => GoStrategyGame.position({
      64: (Player.a, GoPiece.captain),
      99: (Player.a, GoPiece.flag),
      35: (Player.b, GoPiece.sergeant),
      0: (Player.b, GoPiece.flag),
    });

void main() {
  group('play', () {
    testWidgets('pinch zooms; then tap-select and tap-move work at zoom', (tester) async {
      iphone(tester);
      final c = await pumpPosition(tester, _front());
      expect(scaleOf(tester), 1);
      final before = tester.getSize(cell(64)).width * scaleOf(tester);
      await pinch(tester, tester.getCenter(cell(64)));
      expect(scaleOf(tester), greaterThan(1.5));
      final rect = tester.getRect(cell(64));
      // getRect is untransformed; the drawn square is the scaled one.
      expect(rect.width * scaleOf(tester), greaterThan(before * 1.5));
      expect(visible(tester, 64), isTrue);

      await tapOn(tester, cell(64));
      expect(squareOf(tester, 64).selected, isTrue);
      expect(squareOf(tester, 54).target, isTrue);
      expect(visible(tester, 54), isTrue);
      await tapOn(tester, cell(54));
      expect(gameOf(c).viewFor(Player.a)[54].owner, Player.a);
      expect(tester.takeException(), isNull);
    });

    testWidgets('one finger pans a zoomed board; the coordinates follow the squares', (tester) async {
      iphone(tester);
      await pumpPosition(tester, _front());
      await pinch(tester, tester.getCenter(cell(55)));
      final zoom = zoomOf(tester);
      final before = zoom.value.getTranslation();
      // From an empty square: the board moves, nothing is selected.
      await tester.dragFrom(tester.getCenter(cell(55)), const Offset(60, 60));
      await tester.pumpAndSettle();
      expect(zoom.value.getTranslation(), isNot(before));
      expect(squareOf(tester, 55).selected, isFalse);

      // Each rank label stands beside its (zoomed) row, each file label
      // under its column; X's view: display row 0 is rank 10 (squares 0–9).
      final s = scaleOf(tester);
      for (var i = 0; i < 10; i++) {
        final rowCentre = tester.getTopLeft(cell(i * 10)).dy + tester.getSize(cell(0)).height * s / 2;
        expect(tester.getCenter(find.byKey(Key('go-rank-$i'))).dy, moreOrLessEquals(rowCentre, epsilon: 1));
        final colCentre = tester.getTopLeft(cell(i)).dx + tester.getSize(cell(0)).width * s / 2;
        expect(tester.getCenter(find.byKey(Key('go-file-$i'))).dx, moreOrLessEquals(colCentre, epsilon: 1));
      }
      // The labels keep their size.
      final style = tester.widget<Text>(find.byKey(const Key('go-rank-0'))).style!;
      expect(style.fontSize, lessThanOrEqualTo(12));
    });

    testWidgets('the zoom button: in on the selected piece, then the whole board', (tester) async {
      iphone(tester);
      await pumpPosition(tester, _front());
      await tapOn(tester, cell(64));
      await tapKey(tester, 'go-zoom');
      await tester.pumpAndSettle();
      expect(scaleOf(tester), greaterThan(1.5));
      final view = tester.getRect(find.byKey(const Key('go-zoom-view')));
      final s = scaleOf(tester);
      final centre = tester.getTopLeft(cell(64)) + Offset(tester.getSize(cell(64)).width * s / 2, tester.getSize(cell(64)).height * s / 2);
      expect((centre - view.center).distance, lessThan(view.width * 0.25), reason: 'the piece near the middle');
      expect(squareOf(tester, 64).selected, isTrue, reason: 'zooming keeps the selection');
      expect(find.byTooltip('Ganzes Brett'), findsOneWidget);
      await tapKey(tester, 'go-zoom');
      await tester.pumpAndSettle();
      expect(scaleOf(tester), 1);
      expect(find.byTooltip('Vergrößern'), findsOneWidget);
    });

    testWidgets('the hint says that two fingers zoom while the board is whole', (tester) async {
      iphone(tester);
      await pumpPosition(tester, _front());
      expect(find.text('Tippe eine deiner Figuren an, dann ein markiertes Feld. Mit zwei Fingern zoomst du.'),
          findsOneWidget);
      await pinch(tester, tester.getCenter(cell(55)));
      await tester.pump();
      expect(find.text('Tippe eine deiner Figuren an, dann ein markiertes Feld.'), findsOneWidget);
    });

    testWidgets('hot-seat: each player keeps their own view of the (turned) board', (tester) async {
      iphone(tester);
      final c = await pumpPosition(tester, _front());
      await pinch(tester, tester.getCenter(cell(64)));
      final mine = zoomOf(tester).value.clone();
      await tapOn(tester, cell(64));
      await tapOn(tester, cell(54));
      // The cover is up and no board is built behind it.
      expect(c.needsHandover, isTrue);
      expect(find.byKey(const Key('go-zoom-view')), findsNothing);
      await acknowledge(tester);
      // O's turned board is whole, not X's zoom.
      expect(scaleOf(tester), 1);
      // O moves (their board is turned; 35 is in O's front row).
      await tapOn(tester, cell(35));
      await tapOn(tester, cell(45));
      expect(gameOf(c).viewFor(Player.b)[45].owner, Player.b);
      await acknowledge(tester);
      // X's zoom is back as X left it.
      expect(zoomOf(tester).value, mine);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mouse: the wheel zooms the board, a click selects at zoom', (tester) async {
      iphone(tester);
      await pumpPosition(tester, _front());
      final mouse = TestPointer(1, PointerDeviceKind.mouse);
      final at = tester.getCenter(cell(64));
      await tester.sendEventToBinding(mouse.hover(at));
      for (var i = 0; i < 3; i++) {
        await tester.sendEventToBinding(mouse.scroll(const Offset(0, -120)));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(scaleOf(tester), greaterThan(1.2));
      await tester.tap(cell(64), kind: PointerDeviceKind.mouse);
      await tester.pump();
      expect(squareOf(tester, 64).selected, isTrue);
    });
  });

  group('setup', () {
    testWidgets('pinch on the own pieces zooms and moves none; swap by taps and by a drag at zoom', (tester) async {
      iphone(tester);
      await pumpGame(tester, 'gostrategy');
      final start = shown(tester, Player.a);
      // Both fingers start on own pieces.
      await pinch(tester, tester.getCenter(cell(75)), from: 40, to: 120);
      expect(scaleOf(tester), greaterThan(1.5));
      expect(shown(tester, Player.a), start, reason: 'a pinch moves no piece');

      // Two visible own squares in the same row.
      final row = [for (var sq = 60; sq < 100; sq++) if (visible(tester, sq)) sq];
      expect(row.length, greaterThanOrEqualTo(4));
      final a = row.first, b = row[1];
      await tapOn(tester, cell(a));
      expect(squareOf(tester, a).selected, isTrue);
      await tapOn(tester, cell(b));
      final swapped = shown(tester, Player.a);
      expect(swapped[a], start[b]);
      expect(swapped[b], start[a]);

      // A drag of a piece at zoom swaps it with the one under the finger
      // (it does not pan the board).
      final view = zoomOf(tester).value.clone();
      final from = row[2], to = row[3];
      final g = await tester.startGesture(tester.getCenter(cell(from)));
      final target = tester.getTopLeft(cell(to)) +
          Offset(tester.getSize(cell(to)).width, tester.getSize(cell(to)).height) * scaleOf(tester) / 2;
      for (var i = 1; i <= 10; i++) {
        await g.moveTo(Offset.lerp(tester.getCenter(cell(from)), target, i / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(shown(tester, Player.a)[to], swapped[from]);
      expect(shown(tester, Player.a)[from], swapped[to]);
      expect(zoomOf(tester).value, view, reason: 'the board did not move');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the zoom button in the setup zooms on the own rows; play starts with the whole board',
        (tester) async {
      iphone(tester);
      final c = await pumpGame(tester, 'gostrategy');
      await tapKey(tester, 'go-zoom');
      await tester.pumpAndSettle();
      expect(scaleOf(tester), greaterThan(1.5));
      expect(visible(tester, 95), isTrue, reason: 'the own back row in view');
      await tapKey(tester, 'go-done');
      await acknowledge(tester);
      expect(scaleOf(tester), 1, reason: "O's setup, own view");
      await tapKey(tester, 'go-done');
      await acknowledge(tester);
      expect(gameOf(c).phase, GoStrategyPhase.play);
      expect(scaleOf(tester), 1, reason: 'play has its own view');
    });
  });
}
