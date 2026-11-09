import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../maexchen/maexchen_dice.dart' show paintDie;
import 'property_board.dart' show propertyGroupColor;

/// Menu illustration of Baulöwe (KLD-060): a slightly turned board with
/// coloured streets along its edges, a small house and a bigger building
/// in the middle, and two dice in front. Centred in the tile picture like
/// the other games' pictures.
class PropertyIllustration extends CustomPainter {
  final KlunkiPalette palette;
  const PropertyIllustration(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final o = Offset((size.width - s) / 2, (size.height - s) / 2);
    final accent = palette.accent('property').color;
    canvas.save();
    canvas.translate(o.dx + s * 0.46, o.dy + s * 0.46);
    canvas.rotate(-0.1);
    final board = Rect.fromCenter(center: Offset.zero, width: s * 0.74, height: s * 0.74);
    canvas.drawRRect(RRect.fromRectAndRadius(board.shift(Offset(s * 0.015, s * 0.025)), Radius.circular(s * 0.04)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(RRect.fromRectAndRadius(board, Radius.circular(s * 0.04)), Paint()..color = const Color(0xFFFFFBF0));
    // The ring of squares: 5 per side, the streets with their colour band.
    final cell = board.width / 6;
    final line = Paint()
      ..color = const Color(0xFF9AA58F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, s * 0.006);
    final inner = board.deflate(cell);
    canvas.drawRect(inner, Paint()..color = const Color(0xFFD9EAD3));
    canvas.drawRect(inner, line);
    var group = 0;
    for (var i = 0; i < 4; i++) {
      // Each side: four streets between the corners.
      for (var k = 1; k < 5; k++) {
        final Rect sq;
        final Rect band;
        switch (i) {
          case 0: // bottom
            sq = Rect.fromLTWH(board.right - (k + 1) * cell, board.bottom - cell, cell, cell);
            band = Rect.fromLTWH(sq.left, sq.top, cell, cell * 0.3);
          case 1: // left
            sq = Rect.fromLTWH(board.left, board.bottom - (k + 1) * cell, cell, cell);
            band = Rect.fromLTWH(sq.right - cell * 0.3, sq.top, cell * 0.3, cell);
          case 2: // top
            sq = Rect.fromLTWH(board.left + k * cell, board.top, cell, cell);
            band = Rect.fromLTWH(sq.left, sq.bottom - cell * 0.3, cell, cell * 0.3);
          default: // right
            sq = Rect.fromLTWH(board.right - cell, board.top + k * cell, cell, cell);
            band = Rect.fromLTWH(sq.left, sq.top, cell * 0.3, cell);
        }
        if (k != 3) canvas.drawRect(band, Paint()..color = propertyGroupColor(group ~/ 2 % 8));
        group++;
        canvas.drawRect(sq, line);
      }
    }
    for (final c in [board.topLeft, board.topRight - Offset(cell, 0), board.bottomLeft - Offset(0, cell), board.bottomRight - Offset(cell, cell)]) {
      canvas.drawRect(Rect.fromLTWH(c.dx, c.dy, cell, cell), line);
    }
    // A house and a bigger building in the middle, in the game's colour.
    final ground = inner.center + Offset(0, inner.height * 0.22);
    void building(double x, double w, double h, Color c, {bool roof = true}) {
      final body = Rect.fromLTWH(ground.dx + x, ground.dy - h, w, h);
      canvas.drawRect(body, Paint()..color = c);
      if (roof) {
        canvas.drawPath(
            Path()
              ..moveTo(body.left - w * 0.12, body.top)
              ..lineTo(body.center.dx, body.top - w * 0.55)
              ..lineTo(body.right + w * 0.12, body.top)
              ..close(),
            Paint()..color = const Color(0xFFB3261E));
      }
      // Windows.
      final win = Paint()..color = const Color(0xFFFFE9A8);
      final cols = roof ? 1 : 2;
      final rows = roof ? 1 : 3;
      for (var r = 0; r < rows; r++) {
        for (var q = 0; q < cols; q++) {
          final ww = w * (roof ? 0.36 : 0.26);
          final x0 = body.left + (cols == 1 ? (w - ww) / 2 : w * (0.16 + q * 0.42));
          canvas.drawRect(Rect.fromLTWH(x0, body.top + h * (0.18 + r * 0.27), ww, ww * 0.9), win);
        }
      }
    }

    building(-inner.width * 0.36, inner.width * 0.26, inner.height * 0.26, const Color(0xFF2E8B57));
    building(-inner.width * 0.04, inner.width * 0.32, inner.height * 0.62, accent, roof: false);
    canvas.restore();
    paintDie(canvas, Rect.fromLTWH(o.dx + s * 0.62, o.dy + s * 0.66, s * 0.2, s * 0.2), 4, angle: 0.25);
    paintDie(canvas, Rect.fromLTWH(o.dx + s * 0.78, o.dy + s * 0.56, s * 0.18, s * 0.18), 3, angle: -0.2);
  }

  @override
  bool shouldRepaint(PropertyIllustration old) => old.palette != palette;
}
