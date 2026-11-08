import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../maexchen/maexchen_dice.dart' show paintDie;

/// Menu illustration of Ausgewürfelt (KLD-119): a score sheet with a few
/// filled lines and a pencil stroke, three dice in front of it.
class DiceSheetIllustration extends CustomPainter {
  final KlunkiPalette palette;
  const DiceSheetIllustration(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final o = Offset((size.width - s) / 2, (size.height - s) / 2);
    final accent = palette.accent('dicesheet').color;
    // The sheet, slightly turned.
    canvas.save();
    canvas.translate(o.dx + s * 0.42, o.dy + s * 0.42);
    canvas.rotate(-0.12);
    final sheet = Rect.fromCenter(center: Offset.zero, width: s * 0.56, height: s * 0.7);
    canvas.drawRRect(RRect.fromRectAndRadius(sheet.shift(Offset(s * 0.015, s * 0.02)), Radius.circular(s * 0.04)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(RRect.fromRectAndRadius(sheet, Radius.circular(s * 0.04)), Paint()..color = const Color(0xFFFFFDF7));
    canvas.drawRect(Rect.fromLTWH(sheet.left, sheet.top, sheet.width, s * 0.09), Paint()..color = accent);
    final line = Paint()
      ..color = const Color(0xFFB9B2A4)
      ..strokeWidth = max(1, s * 0.008);
    final ink = Paint()
      ..color = accent
      ..strokeWidth = max(1.5, s * 0.016)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final y = sheet.top + s * 0.14 + i * s * 0.075;
      canvas.drawLine(Offset(sheet.left + s * 0.04, y), Offset(sheet.right - s * 0.04, y), line);
      if (i < 4) {
        // A filled entry: a short pencil mark in the right column.
        canvas.drawLine(Offset(sheet.right - s * 0.16, y - s * 0.025), Offset(sheet.right - s * 0.07, y - s * 0.03), ink);
      }
    }
    canvas.drawLine(Offset(sheet.left + s * 0.36, sheet.top + s * 0.1), Offset(sheet.left + s * 0.36, sheet.bottom - s * 0.03),
        line);
    canvas.restore();
    paintDie(canvas, Rect.fromLTWH(o.dx + s * 0.5, o.dy + s * 0.6, s * 0.22, s * 0.22), 5, angle: 0.25);
    paintDie(canvas, Rect.fromLTWH(o.dx + s * 0.72, o.dy + s * 0.5, s * 0.2, s * 0.2), 5, angle: -0.2);
    paintDie(canvas, Rect.fromLTWH(o.dx + s * 0.7, o.dy + s * 0.74, s * 0.19, s * 0.19), 3, angle: 0.1);
  }

  @override
  bool shouldRepaint(DiceSheetIllustration old) => old.palette != palette;
}
