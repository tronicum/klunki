import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki/ui/games/connect4/connect4_board.dart';
import 'package:klunki/ui/games/connect4_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import '../../l10n/l10n_test_utils.dart';

/// Hot-seat transport where only X plays on this device (O is "remote").
class _OnlyXTransport extends HotSeatTransport {
  _OnlyXTransport(super.config);

  @override
  Set<Player> get localPlayers => const {Player.a};
}

Future<GameController> _pump(WidgetTester tester, {GameController? controller, Size? size}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  final c = controller ?? GameController.hotSeat(const GameConfig('connect4'));
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(Connect4Screen(controller: c)));
  await tester.pump();
  return c;
}

Finder _col(int c) => find.byKey(Key('c4-column-$c'));
Connect4Cell _cell(WidgetTester tester, int row, int col) =>
    tester.widget<Connect4Cell>(find.byKey(Key('c4-cell-$row-$col')));

Future<void> _drop(WidgetTester tester, int col) async {
  await tester.tap(_col(col));
  await tester.pump();
  await tester.pump(connect4DropDuration + const Duration(milliseconds: 20));
}

void main() {
  testWidgets('renders 7 columns × 6 cells and the hint', (tester) async {
    await _pump(tester);
    for (var c = 0; c < Connect4Game.cols; c++) {
      expect(_col(c), findsOneWidget);
      for (var r = 0; r < Connect4Game.rows; r++) {
        expect(find.byKey(Key('c4-cell-$r-$c')), findsOneWidget);
      }
    }
    expect(find.text('Tippe auf eine Spalte'), findsOneWidget);
    // Row 0 is the bottom row.
    expect(tester.getCenter(find.byKey(const Key('c4-cell-0-0'))).dy,
        greaterThan(tester.getCenter(find.byKey(const Key('c4-cell-5-0'))).dy));
  });

  testWidgets('tapping a column drops a red X into the bottom row, animated', (tester) async {
    final c = await _pump(tester);
    // Tap near the top of column 3: the piece still lands at the bottom.
    await tester.tapAt(tester.getCenter(find.byKey(const Key('c4-cell-5-3'))));
    await tester.pump();
    expect(_cell(tester, 0, 3).owner, Player.a);
    expect(_cell(tester, 0, 3).pending, isTrue); // still falling
    await tester.pump(connect4DropDuration + const Duration(milliseconds: 20));
    final cell = _cell(tester, 0, 3);
    expect(cell.pending, isFalse);
    expect(cell.lastMove, isTrue);
    expect(_cell(tester, 1, 3).owner, isNull);
    expect(c.moves.single.move['col'], 3);

    final piece = tester.widget<Connect4Piece>(
        find.descendant(of: find.byKey(const Key('c4-cell-0-3')), matching: find.byType(Connect4Piece)));
    final ctx = tester.element(find.byKey(const Key('c4-cell-0-3')));
    expect(piece.color, Connect4Colors.of(ctx).red);
  });

  testWidgets('turns alternate between X (red) and O (yellow)', (tester) async {
    final c = await _pump(tester);
    await _drop(tester, 3);
    expect(find.text('O ist am Zug'), findsOneWidget);
    await _drop(tester, 3);
    await _drop(tester, 4);
    expect(_cell(tester, 0, 3).owner, Player.a);
    expect(_cell(tester, 1, 3).owner, Player.b);
    expect(_cell(tester, 0, 4).owner, Player.a);
    expect(_cell(tester, 1, 3).lastMove, isFalse);
    expect(_cell(tester, 0, 4).lastMove, isTrue);
    expect(c.game.currentPlayer, Player.b);

    final ctx = tester.element(find.byKey(const Key('c4-cell-1-3')));
    final piece = tester.widget<Connect4Piece>(
        find.descendant(of: find.byKey(const Key('c4-cell-1-3')), matching: find.byType(Connect4Piece)));
    expect(piece.color, Connect4Colors.of(ctx).yellow);
  });

  testWidgets('a full column is ignored', (tester) async {
    final c = await _pump(tester);
    for (var i = 0; i < Connect4Game.rows; i++) {
      await _drop(tester, 0);
    }
    expect(c.moves, hasLength(6));
    final player = c.game.currentPlayer;
    await _drop(tester, 0);
    expect(c.moves, hasLength(6));
    expect(c.game.currentPlayer, player);
  });

  testWidgets('scripted diagonal win opens the result dialog and highlights four cells', (tester) async {
    final c = await _pump(tester);
    for (final col in [3, 4, 4, 5, 5, 6, 5, 6, 6, 0, 6]) {
      await _drop(tester, col);
    }
    await tester.pumpAndSettle();
    expect(c.game.result.winner, Player.a);
    expect(find.byKey(const Key('result-dialog')), findsOneWidget);
    expect(find.text('X gewinnt!'), findsOneWidget);

    final winning = tester.widgetList<Connect4Cell>(find.byType(Connect4Cell)).where((w) => w.winning).toList();
    expect(winning, hasLength(4));
    expect({for (final w in winning) (w.key as ValueKey<String>).value},
        {'c4-cell-0-3', 'c4-cell-1-4', 'c4-cell-2-5', 'c4-cell-3-6'});
    expect(connect4WinningCells(c.game as Connect4Game),
        {(col: 3, row: 0), (col: 4, row: 1), (col: 5, row: 2), (col: 6, row: 3)});
  });

  testWidgets('no input while canAct is false', (tester) async {
    final c = await _pump(
      tester,
      controller: GameController(_OnlyXTransport(const GameConfig('connect4'))),
    );
    expect(c.canAct, isTrue);
    await _drop(tester, 2); // X (local)
    expect(c.moves, hasLength(1));
    expect(c.canAct, isFalse); // O is remote
    await tester.pump();
    expect(find.text('Tippe auf eine Spalte'), findsNothing);

    await _drop(tester, 2);
    await _drop(tester, 5);
    expect(c.moves, hasLength(1));
    expect(_cell(tester, 1, 2).owner, isNull);
    expect(tester.widget<GestureDetector>(_col(5)).onTap, isNull);
  });

  testWidgets('history describes moves as "X: Spalte 4"', (tester) async {
    await _pump(tester);
    await _drop(tester, 3);
    await tester.tap(find.byKey(const Key('shell-history')));
    await tester.pumpAndSettle();
    expect(find.text('X: Spalte 4'), findsOneWidget);
  });

  for (final (name, size) in [
    ('phone portrait', const Size(390, 844)),
    ('iPad landscape', const Size(1366, 1024)),
    ('narrow web', const Size(320, 480)),
  ]) {
    testWidgets('fits the screen: $name', (tester) async {
      await _pump(tester, size: size);
      expect(tester.takeException(), isNull);
      final board = tester.getRect(find.byType(Connect4Board));
      final first = tester.getRect(find.byKey(const Key('c4-cell-5-0')));
      final lastCell = tester.getRect(find.byKey(const Key('c4-cell-0-6')));
      expect(board.contains(first.topLeft), isTrue);
      expect(board.contains(lastCell.bottomRight - const Offset(0.1, 0.1)), isTrue);
      expect(lastCell.right <= size.width, isTrue);
      await _drop(tester, 6);
      expect(_cell(tester, 0, 6).owner, Player.a);
    });
  }
}
