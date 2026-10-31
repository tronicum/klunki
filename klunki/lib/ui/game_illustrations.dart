import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Small drawn menu illustrations (KLD-062), one per game. All colours come
/// from the [KlunkiPalette]; everything is drawn in code (no image assets).
/// Each painter draws into a square centred in its size.

Rect _square(Size size, [double inset = 0.08]) {
  final s = size.shortestSide;
  final r = Rect.fromCenter(center: size.center(Offset.zero), width: s, height: s);
  return r.deflate(s * inset);
}

Paint _fill(Color c) => Paint()..color = c;

void _disc(Canvas canvas, Offset c, double r, Color color, {Color? edge}) {
  canvas.drawCircle(c + Offset(r * 0.08, r * 0.14), r, _fill(Colors.black.withValues(alpha: 0.18)));
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        colors: [Color.lerp(color, Colors.white, 0.35)!, color],
      ).createShader(Rect.fromCircle(center: c, radius: r)),
  );
  if (edge != null) {
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12
          ..color = edge);
  }
}

/// 4 Gewinnt: blue frame with a diagonal four of red and yellow discs.
class Connect4Illustration extends CustomPainter {
  final KlunkiPalette palette;
  const Connect4Illustration(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette.connect4;
    final r = _square(size);
    const cols = 5, rows = 4;
    final cell = r.width / cols;
    final board = Rect.fromLTWH(r.left, r.top + (r.height - rows * cell) / 2, r.width, rows * cell);
    canvas.drawRRect(RRect.fromRectAndRadius(board.shift(Offset(0, cell * 0.12)), Radius.circular(cell * 0.3)),
        _fill(p.boardShade));
    canvas.drawRRect(RRect.fromRectAndRadius(board, Radius.circular(cell * 0.3)), _fill(p.board));
    // Pieces (col, row from the bottom) → colour.
    final pieces = <(int, int), Color>{
      (0, 0): p.red, (1, 0): p.yellow, (2, 0): p.yellow, (3, 0): p.red, (4, 0): p.yellow,
      (1, 1): p.red, (2, 1): p.red, (3, 1): p.yellow,
      (2, 2): p.red, (3, 2): p.yellow,
      (3, 3): p.red,
    };
    for (var c = 0; c < cols; c++) {
      for (var row = 0; row < rows; row++) {
        final center = Offset(board.left + (c + 0.5) * cell, board.bottom - (row + 0.5) * cell);
        final color = pieces[(c, row)];
        if (color == null) {
          canvas.drawCircle(center, cell * 0.36, _fill(p.hole));
        } else {
          _disc(canvas, center, cell * 0.38, color);
        }
      }
    }
  }

  @override
  bool shouldRepaint(Connect4Illustration old) => old.palette != palette;
}

/// Mühle: wooden board with the three squares and a few stones.
class MuehleIllustration extends CustomPainter {
  final KlunkiPalette palette;
  const MuehleIllustration(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final m = palette.muehle;
    final r = _square(size);
    final s = r.width;
    canvas.drawRRect(RRect.fromRectAndRadius(r.shift(Offset(0, s * 0.03)), Radius.circular(s * 0.08)),
        _fill(Colors.black.withValues(alpha: 0.2)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(s * 0.08)),
      Paint()..shader = LinearGradient(colors: [m.boardLight, m.board]).createShader(r),
    );
    final line = Paint()
      ..color = m.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, s * 0.025);
    final c = r.center;
    for (final f in const [0.38, 0.26, 0.14]) {
      canvas.drawRect(Rect.fromCenter(center: c, width: s * f * 2, height: s * f * 2), line);
    }
    for (final d in const [Offset(0, -1), Offset(0, 1), Offset(-1, 0), Offset(1, 0)]) {
      canvas.drawLine(c + d * (s * 0.14), c + d * (s * 0.38), line);
    }
    final stone = s * 0.075;
    Offset at(double fx, double fy) => c + Offset(fx, fy) * s;
    _disc(canvas, at(-0.38, -0.38), stone, m.light, edge: m.lightEdge);
    _disc(canvas, at(0, -0.38), stone, m.light, edge: m.lightEdge);
    _disc(canvas, at(0.38, -0.38), stone, m.light, edge: m.lightEdge);
    _disc(canvas, at(0.26, 0), stone, m.dark);
    _disc(canvas, at(-0.14, 0.14), stone, m.dark);
    _disc(canvas, at(0, 0.38), stone, m.dark);
  }

  @override
  bool shouldRepaint(MuehleIllustration old) => old.palette != palette;
}

/// Quartett: three fanned cards with coloured set headers.
class QuartettIllustration extends CustomPainter {
  final KlunkiPalette palette;

  /// Header set letters of the three cards, back to front.
  final List<String> sets;
  const QuartettIllustration(this.palette, {this.sets = const ['F', 'E', 'A']});

  @override
  void paint(Canvas canvas, Size size) {
    final q = palette.quartett;
    final r = _square(size, 0.04);
    final w = r.width * 0.46, h = w * 1.4;
    final pivot = Offset(r.center.dx, r.bottom - r.height * 0.02);
    for (var i = 0; i < sets.length; i++) {
      final angle = (i - (sets.length - 1) / 2) * 0.32;
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(angle);
      final card = Rect.fromLTWH(-w / 2, -h - r.height * 0.02, w, h);
      final rr = RRect.fromRectAndRadius(card, Radius.circular(w * 0.1));
      canvas.drawRRect(rr.shift(Offset(w * 0.03, w * 0.05)), _fill(Colors.black.withValues(alpha: 0.2)));
      canvas.drawRRect(rr, _fill(q.onBack));
      final color = q.set(sets[i]);
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawRect(Rect.fromLTWH(card.left, card.top, w, h * 0.28), _fill(color));
      // Stat rows.
      final row = Paint()..color = const Color(0xFF9E9E9E).withValues(alpha: 0.5);
      for (var k = 0; k < 4; k++) {
        final y = card.top + h * (0.4 + k * 0.14);
        final hl = i == sets.length - 1 && k == 1;
        if (hl) {
          canvas.drawRect(Rect.fromLTWH(card.left, y - h * 0.05, w, h * 0.1), _fill(color.withValues(alpha: 0.22)));
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(card.left + w * 0.12, y - h * 0.015, w * 0.4, h * 0.03),
              Radius.circular(h * 0.015)),
          row,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(card.left + w * 0.62, y - h * 0.015, w * 0.24, h * 0.03),
              Radius.circular(h * 0.015)),
          hl ? (Paint()..color = color) : row,
        );
      }
      canvas.restore();
      canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1, w * 0.03)
            ..color = color);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(QuartettIllustration old) => old.palette != palette || old.sets != sets;
}

/// Schiffe versenken: a sea grid with a ship, a hit and a miss.
class SchiffeIllustration extends CustomPainter {
  final KlunkiPalette palette;
  const SchiffeIllustration(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette.schiffe;
    final r = _square(size);
    const n = 5;
    final cell = r.width / n;
    final rr = RRect.fromRectAndRadius(r, Radius.circular(cell * 0.3));
    canvas.drawRRect(rr.shift(Offset(0, cell * 0.1)), _fill(Colors.black.withValues(alpha: 0.18)));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.water, p.waterDeep],
        ).createShader(r),
    );
    final grid = Paint()
      ..color = p.gridLine
      ..strokeWidth = math.max(1, cell * 0.04);
    for (var i = 1; i < n; i++) {
      canvas.drawLine(Offset(r.left + i * cell, r.top), Offset(r.left + i * cell, r.bottom), grid);
      canvas.drawLine(Offset(r.left, r.top + i * cell), Offset(r.right, r.top + i * cell), grid);
    }
    // Ship: row 1, cols 1..3.
    final ship = Rect.fromLTWH(r.left + cell * 1.12, r.top + cell * 1.18, cell * 2.76, cell * 0.64);
    canvas.drawRRect(RRect.fromRectAndRadius(ship, Radius.circular(cell * 0.32)), _fill(p.ship));
    canvas.drawRRect(
        RRect.fromRectAndRadius(ship, Radius.circular(cell * 0.32)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.06
          ..color = p.shipEdge);
    // Hit on the ship's last cell.
    _cross(canvas, Offset(r.left + cell * 3.5, r.top + cell * 1.5), cell * 0.26, p.hit, cell * 0.12);
    // Misses.
    for (final (c, row) in const [(1, 3), (3, 3), (4, 0)]) {
      final o = Offset(r.left + cell * (c + 0.5), r.top + cell * (row + 0.5));
      canvas.drawCircle(o, cell * 0.14, _fill(p.miss));
    }
  }

  void _cross(Canvas canvas, Offset c, double r, Color color, double w) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(-r, -r), c + Offset(r, r), paint);
    canvas.drawLine(c + Offset(r, -r), c + Offset(-r, r), paint);
  }

  @override
  bool shouldRepaint(SchiffeIllustration old) => old.palette != palette;
}

/// Fallback for games without their own illustration: a die.
class DefaultGameIllustration extends CustomPainter {
  final KlunkiPalette palette;
  final Color color;
  const DefaultGameIllustration(this.palette, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final r = _square(size, 0.2);
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.18));
    canvas.drawRRect(rr, _fill(color));
    final dot = _fill(Colors.white);
    for (final (fx, fy) in const [(0.28, 0.28), (0.5, 0.5), (0.72, 0.72), (0.72, 0.28), (0.28, 0.72)]) {
      canvas.drawCircle(Offset(r.left + r.width * fx, r.top + r.height * fy), r.width * 0.08, dot);
    }
  }

  @override
  bool shouldRepaint(DefaultGameIllustration old) => old.palette != palette || old.color != color;
}
