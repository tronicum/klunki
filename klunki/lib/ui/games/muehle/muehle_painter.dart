import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'muehle_geometry.dart';

/// Draws the board: a wooden panel (gradient, grain, bevelled edge), the
/// three squares with their connecting lines, a point on every position and
/// (while [flash] > 0) the freshly formed mill lines. Colours come from the
/// theme's [MuehlePalette].
class MuehleBoardPainter extends CustomPainter {
  final MuehlePalette colors;

  /// Mills (three points each) to highlight.
  final List<List<int>> millLines;

  /// Highlight intensity 0..1.
  final double flash;

  const MuehleBoardPainter({required this.colors, this.millLines = const [], this.flash = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final c = colors;
    final side = size.shortestSide;
    final rect = Offset.zero & Size(side, side);
    final r = Radius.circular(side * 0.03);
    final rrect = RRect.fromRectAndRadius(rect, r);

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.boardLight, c.board, c.boardLight, c.board],
          stops: const [0, 0.35, 0.65, 1],
        ).createShader(rect),
    );

    // Wood grain: soft wavy lines across the board (deterministic).
    canvas.save();
    canvas.clipRRect(rrect);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..color = c.grain.withValues(alpha: 0.13)
      ..strokeWidth = math.max(1, side * 0.004);
    for (var i = 0; i < 26; i++) {
      final y0 = side * (i + 0.5) / 26;
      final amp = side * (0.004 + 0.006 * ((i * 7) % 5) / 4);
      final phase = i * 1.7;
      final path = Path()..moveTo(0, y0);
      for (var x = 0.0; x <= side; x += side / 40) {
        path.lineTo(x, y0 + amp * math.sin(x / side * math.pi * 3 + phase));
      }
      canvas.drawPath(path, grain);
    }
    canvas.restore();

    // Bevel: light top-left, dark bottom-right edge.
    canvas.drawRRect(
      rrect.deflate(side * 0.008),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.016
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.boardLight, c.boardEdge],
        ).createShader(rect),
    );

    final line = Paint()
      ..color = c.line
      ..strokeWidth = (side * 0.009).clamp(1.5, 5)
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in MuehleGeometry.segments) {
      canvas.drawLine(MuehleGeometry.center(a, side), MuehleGeometry.center(b, side), line);
    }

    if (flash > 0 && millLines.isNotEmpty) {
      final glow = Paint()
        ..color = c.mill.withValues(alpha: flash.clamp(0, 1))
        ..strokeWidth = side * 0.035
        ..strokeCap = StrokeCap.round;
      for (final m in millLines) {
        canvas.drawLine(MuehleGeometry.center(m.first, side), MuehleGeometry.center(m.last, side), glow);
      }
    }

    // Points: a ring with a light centre, like an inlaid peg hole.
    final dot = Paint()..color = c.line;
    final inner = Paint()..color = c.boardLight;
    for (var p = 0; p < 24; p++) {
      final o = MuehleGeometry.center(p, side);
      canvas.drawCircle(o, side * 0.018, dot);
      canvas.drawCircle(o, side * 0.008, inner);
    }
  }

  @override
  bool shouldRepaint(MuehleBoardPainter old) =>
      old.flash != flash || old.millLines != millLines || old.colors != colors;
}
