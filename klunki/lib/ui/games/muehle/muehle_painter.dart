import 'package:flutter/material.dart';

import 'muehle_geometry.dart';

/// Board colours (fixed "wood" look, independent of the app theme).
abstract final class MuehleColors {
  static const board = Color(0xFFE9C98F);
  static const boardEdge = Color(0xFFB98A4B);
  static const line = Color(0xFF5B3A1A);
  static const light = Color(0xFFFAF7F0);
  static const lightEdge = Color(0xFF8C8270);
  static const dark = Color(0xFF2B2B2E);
  static const darkEdge = Color(0xFF000000);
  static const mill = Color(0xFFFFB300);
  static const target = Color(0xFF2E7D32);
  static const remove = Color(0xFFC62828);
  static const select = Color(0xFF1565C0);
}

/// Draws the board: background, the three squares with their connecting
/// lines, small dots on every point and (while [flash] > 0) the freshly
/// formed mill lines.
class MuehleBoardPainter extends CustomPainter {
  /// Mills (three points each) to highlight.
  final List<List<int>> millLines;

  /// Highlight intensity 0..1.
  final double flash;

  const MuehleBoardPainter({this.millLines = const [], this.flash = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final rect = Offset.zero & Size(side, side);
    final r = Radius.circular(side * 0.03);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, r), Paint()..color = MuehleColors.board);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(side * 0.006), r),
      Paint()
        ..color = MuehleColors.boardEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.012,
    );

    final line = Paint()
      ..color = MuehleColors.line
      ..strokeWidth = (side * 0.008).clamp(1.5, 5)
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in MuehleGeometry.segments) {
      canvas.drawLine(MuehleGeometry.center(a, side), MuehleGeometry.center(b, side), line);
    }

    if (flash > 0 && millLines.isNotEmpty) {
      final glow = Paint()
        ..color = MuehleColors.mill.withValues(alpha: flash.clamp(0, 1))
        ..strokeWidth = side * 0.035
        ..strokeCap = StrokeCap.round;
      for (final m in millLines) {
        canvas.drawLine(MuehleGeometry.center(m.first, side), MuehleGeometry.center(m.last, side), glow);
      }
    }

    final dot = Paint()..color = MuehleColors.line;
    for (var p = 0; p < 24; p++) {
      canvas.drawCircle(MuehleGeometry.center(p, side), side * 0.014, dot);
    }
  }

  @override
  bool shouldRepaint(MuehleBoardPainter old) => old.flash != flash || old.millLines != millLines;
}
