import 'dart:ui';

import 'package:klunki_engine/klunki_engine.dart' hide Card;

/// Board geometry shared by the painter and the tap targets.
///
/// The 24 points sit on a 7×7 lattice (same layout as the text console in
/// `klunki_engine/lib/debug/muehle_text.dart`, whose `_xs`/`_ys` use a 25×13
/// character grid: x in 0..24 step 4, y in 0..12 step 2).
abstract final class MuehleGeometry {
  static const _xs = [0, 12, 24, 4, 12, 20, 8, 12, 16, 0, 4, 8, 16, 20, 24, 8, 12, 16, 4, 12, 20, 0, 12, 24];
  static const _ys = [0, 0, 0, 2, 2, 2, 4, 4, 4, 6, 6, 6, 6, 6, 6, 8, 8, 8, 10, 10, 10, 12, 12, 12];

  /// Column (0..6) of point [p].
  static int col(int p) => _xs[p] ~/ 4;

  /// Row (0..6) of point [p].
  static int row(int p) => _ys[p] ~/ 2;

  /// Inner padding of the board as a fraction of its side length.
  static const double margin = 0.08;

  /// Distance between two neighbouring lattice lines for a board of [side].
  static double cell(double side) => side * (1 - 2 * margin) / 6;

  /// Centre of point [p] on a square board of side [side].
  static Offset center(int p, double side) {
    final m = side * margin;
    final c = cell(side);
    return Offset(m + col(p) * c, m + row(p) * c);
  }

  /// All connecting segments (each once) as point pairs.
  static final List<(int, int)> segments = [
    for (var p = 0; p < MuehleGame.pointCount; p++)
      for (final n in MuehleGame.adjacency[p])
        if (n > p) (p, n),
  ];
}
