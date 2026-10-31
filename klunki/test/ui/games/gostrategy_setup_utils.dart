// KLD-081 helpers: arrange a recognisable setup on the board and read
// back where each piece is displayed, for hot-seat and network tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/ui/games/gostrategy/gostrategy_board.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

/// The recognisable squares for [p], as the owner sees them: the flag in
/// the bottom-left corner, a bomb right of it, a scout on the right end of
/// the front row, a marshal in the middle of the front row.
({int flag, int bomb, int scout, int marshal}) markSquares(Player p) => p == Player.a
    ? (flag: 90, bomb: 91, scout: 69, marshal: 64)
    : (flag: 9, bomb: 8, scout: 30, marshal: 35);

/// The pieces the editor (or the board) shows on [p]'s home squares.
Map<int, GoPiece> shownPieces(WidgetTester tester, Player p, Finder Function(int sq) cell) => {
      for (final sq in GoStrategyGame.homeSquares(p))
        if (tester.widget<GoSquareView>(cell(sq)).cell.piece != null) sq: tester.widget<GoSquareView>(cell(sq)).cell.piece!,
    };

/// Display position (row, column from the top left of the board) of every
/// square, from the cell rectangles on screen.
Map<int, (int, int)> displayed(WidgetTester tester, Finder Function(int sq) cell) {
  final origin = tester.getTopLeft(cell(0));
  final end = tester.getTopLeft(cell(99));
  final size = tester.getSize(cell(0));
  final left = origin.dx < end.dx ? origin.dx : end.dx;
  final top = origin.dy < end.dy ? origin.dy : end.dy;
  return {
    for (var sq = 0; sq < 100; sq++)
      sq: (
        ((tester.getTopLeft(cell(sq)).dy - top) / size.height).round(),
        ((tester.getTopLeft(cell(sq)).dx - left) / size.width).round(),
      ),
  };
}

/// Swaps pieces in the editor by taps until [p]'s draft has the flag, a
/// bomb, a scout and the marshal on [markSquares]. [tap] taps and pumps.
Future<void> arrangeMarks(
  WidgetTester tester,
  Player p,
  Finder Function(int sq) cell,
  Future<void> Function(Finder f) tap,
) async {
  final m = markSquares(p);
  final done = <int>{};
  for (final (target, kind) in [
    (m.flag, GoPiece.flag),
    (m.bomb, GoPiece.bomb),
    (m.scout, GoPiece.scout),
    (m.marshal, GoPiece.marshal),
  ]) {
    final shown = shownPieces(tester, p, cell);
    if (shown[target] != kind) {
      final from = shown.entries.firstWhere((e) => e.value == kind && !done.contains(e.key)).key;
      await tap(cell(from));
      await tap(cell(target));
      expect(shownPieces(tester, p, cell)[target], kind);
    }
    done.add(target);
  }
}
