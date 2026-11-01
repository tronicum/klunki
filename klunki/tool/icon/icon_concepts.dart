import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:klunki/app/theme.dart';

/// App icon concepts (KLD-097 step 1). Each concept paints a full-bleed,
/// opaque square of any size (designed on a 1024 grid). Colours come from
/// [KlunkiPalette.classicLight] (the "Spieltisch" look, KLD-062) so the icon
/// matches the app. Key content stays inside the central ~66 % (Android
/// adaptive icons crop to a circle / squircle); no text, no transparency.
///
/// Rendered by `render_icons_test.dart` (see README.md).
typedef IconConcept = void Function(Canvas canvas, double size);

const KlunkiPalette _p = KlunkiPalette.classicLight;

/// id → (title, painter).
final Map<String, (String, IconConcept)> iconConcepts = {
  'a': ('K aus Spielsteinen', paintConceptA),
  'b': ('Kartenfächer mit Chip', paintConceptB),
  'c': ('Tasche mit Spielsteinen', paintConceptC),
  'd': ('Vier-Gewinnt-K', paintConceptD),
};

// ---------------------------------------------------------------- shared --

/// Warm table colours.
const _tableLight = Color(0xFFE59A48); // lit amber
const _tableDark = Color(0xFFA9531F); // terracotta rim
const _ink = Color(0xFF4A2410); // dark brown outline
const _shadow = Color(0x40000000);

Paint _fill(Color c) => Paint()
  ..color = c
  ..isAntiAlias = true;

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..isAntiAlias = true;

/// Runs [body] on a 1024 × 1024 grid scaled to [size].
void _grid(Canvas canvas, double size, void Function(Canvas c) body) {
  canvas.save();
  canvas.scale(size / 1024);
  canvas.clipRect(const Rect.fromLTWH(0, 0, 1024, 1024));
  body(canvas);
  canvas.restore();
}

/// Scales the motif by [scale] around the centre and moves it by [dx], [dy].
void _fit(Canvas c, double scale, {double dx = 0, double dy = 0}) {
  c.translate(512 + dx, 512 + dy);
  c.scale(scale);
  c.translate(-512, -512);
}

/// The table: a warm radial gradient, lighter in the upper middle.
void _table(Canvas c, {Color light = _tableLight, Color dark = _tableDark}) {
  const r = Rect.fromLTWH(0, 0, 1024, 1024);
  c.drawRect(r, Paint()..shader = ui.Gradient.radial(const Offset(512, 430), 720, [light, dark], [0.0, 1.0]));
}

/// A Four-in-a-Row disc: base colour, darker rim, inner ring, highlight.
void _chip(Canvas c, Offset o, double r, Color color, {bool outline = true}) {
  final hsl = HSLColor.fromColor(color);
  final dark = hsl.withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0)).toColor();
  final light = hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
  c.drawCircle(o.translate(r * 0.06, r * 0.12), r, _fill(_shadow));
  c.drawCircle(o, r, _fill(dark));
  c.drawCircle(o, r * 0.86, _fill(color));
  c.drawCircle(o, r * 0.6, _stroke(dark, r * 0.09));
  c.drawCircle(o.translate(-r * 0.3, -r * 0.34), r * 0.16, _fill(light));
  if (outline) c.drawCircle(o, r, _stroke(_ink, r * 0.1));
}

/// A chess pawn (shape of `chess_pieces.dart`, bolder outline) in a 100 box
/// placed at [box].
void _pawn(Canvas c, Rect box, {required Color fill, Color line = _ink, double lineWidth = 5}) {
  c.save();
  c.translate(box.left, box.top);
  c.scale(box.width / 100, box.height / 100);
  final parts = [
    Path()
      ..moveTo(29, 81)
      ..cubicTo(29, 68, 41, 63, 43, 55)
      ..lineTo(57, 55)
      ..cubicTo(59, 63, 71, 68, 71, 81)
      ..close(),
    Path()..addRRect(RRect.fromLTRBR(35, 47, 65, 56, const Radius.circular(3))),
    Path()..addOval(Rect.fromCircle(center: const Offset(50, 33), radius: 14)),
    Path()..addRRect(RRect.fromLTRBR(21, 80, 79, 91, const Radius.circular(4))),
  ];
  for (final p in parts) {
    c.drawPath(p.shift(const Offset(2, 3)), _fill(_shadow));
  }
  for (final p in parts) {
    c.drawPath(p, _fill(fill));
    c.drawPath(p, _stroke(line, lineWidth));
  }
  c.drawCircle(const Offset(45, 28), 4, _fill(const Color(0xFFFFFFFF).withValues(alpha: 0.7)));
  c.restore();
}

/// A Quartett card centred at [center], rotated by [angle]: cream face,
/// coloured header band and a simple picture block.
void _card(Canvas c, Offset center, Size s, double angle, Color band, {double outline = 12, bool lines = false}) {
  c.save();
  c.translate(center.dx, center.dy);
  c.rotate(angle);
  final r = Rect.fromCenter(center: Offset.zero, width: s.width, height: s.height);
  final rr = RRect.fromRectAndRadius(r, Radius.circular(s.width * 0.11));
  c.drawRRect(rr.shift(const Offset(8, 14)), _fill(_shadow));
  c.drawRRect(rr, _fill(_p.quartett.cardFace));
  // Header band and picture.
  c.save();
  c.clipRRect(rr);
  c.drawRect(Rect.fromLTRB(r.left, r.top, r.right, r.top + s.width * 0.42), _fill(band));
  c.restore();
  final pic = Rect.fromLTRB(
    r.left + s.width * 0.18,
    r.top + s.width * 0.6,
    r.right - s.width * 0.18,
    r.top + s.width * 1.0,
  );
  c.drawRRect(RRect.fromRectAndRadius(pic, Radius.circular(s.width * 0.06)), _fill(band.withValues(alpha: 0.28)));
  for (var i = 0; i < (lines ? 2 : 0); i++) {
    final y = r.top + s.height * (0.69 + i * 0.12);
    c.drawLine(
      Offset(r.left + s.width * 0.2, y),
      Offset(r.right - s.width * (0.2 + i * 0.16), y),
      _stroke(band.withValues(alpha: 0.45), s.width * 0.06),
    );
  }
  c.drawRRect(rr, _stroke(_ink, outline));
  c.restore();
}

// ------------------------------------------------------------- concepts --

/// (a) A "K" built from game pieces: the stem is an upright Quartett card,
/// the upper arm a red and a yellow chip, the lower leg a leaning pawn.
void paintConceptA(Canvas canvas, double size) => _grid(canvas, size, (c) {
  _table(c);
  _fit(c, 0.9, dx: -22, dy: -14);
  final c4 = _p.connect4;
  // Stem: the card.
  _card(c, const Offset(356, 512), const Size(200, 560), 0, _p.quartett.sets['A']!, outline: 16);
  // Lower leg: a pawn leaning out to the lower right, head at the joint.
  c.save();
  c.translate(584, 630);
  c.rotate(-0.76);
  _pawn(c, const Rect.fromLTWH(-215, -215, 430, 430), fill: _p.chess.whiteFill, lineWidth: 4);
  c.restore();
  // Upper arm: two chips climbing to the upper right.
  _chip(c, const Offset(548, 440), 92, c4.yellow);
  _chip(c, const Offset(688, 294), 106, c4.red);
});

/// (b) A small fan of three Quartett cards with a red chip in front.
void paintConceptB(Canvas canvas, double size) => _grid(canvas, size, (c) {
  _table(c);
  _fit(c, 0.88, dy: 20);
  const pivot = Offset(512, 900);
  const card = Size(290, 420);
  final sets = _p.quartett.sets;
  final cards = [(-0.36, sets['F']!), (0.0, sets['E']!), (0.36, sets['B']!)];
  for (final (angle, band) in cards) {
    c.save();
    c.translate(pivot.dx, pivot.dy);
    c.rotate(angle);
    _card(c, const Offset(0, -460), card, 0, band, outline: 14);
    c.restore();
  }
  _chip(c, const Offset(512, 660), 136, _p.connect4.red);
});

/// (c) A pocket ("Tasche") with a card, a pawn and a chip peeking out.
void paintConceptC(Canvas canvas, double size) => _grid(canvas, size, (c) {
  _table(c);
  _fit(c, 0.94, dy: -34);
  // Pieces behind the pocket.
  _card(c, const Offset(368, 400), const Size(210, 300), -0.26, _p.quartett.sets['F']!, outline: 13);
  _pawn(c, const Rect.fromLTWH(420, 150, 310, 310), fill: _p.chess.whiteFill, lineWidth: 5);
  _chip(c, const Offset(694, 418), 100, _p.connect4.red);
  // The pocket: a jeans-style back pocket in leather brown.
  final pocket = Path()
    ..moveTo(236, 470)
    ..lineTo(788, 470)
    ..lineTo(770, 740)
    ..quadraticBezierTo(766, 772, 736, 786)
    ..lineTo(540, 862)
    ..quadraticBezierTo(512, 872, 484, 862)
    ..lineTo(288, 786)
    ..quadraticBezierTo(258, 772, 254, 740)
    ..close();
  c.drawPath(pocket.shift(const Offset(6, 16)), _fill(_shadow));
  c.drawPath(
    pocket,
    Paint()
      ..shader = ui.Gradient.linear(const Offset(0, 470), const Offset(0, 870), [
        const Color(0xFF9E4A22),
        _p.quartett.backA,
      ]),
  );
  c.drawPath(pocket, _stroke(_ink, 14));
  // Hem at the opening.
  c.drawLine(const Offset(244, 516), const Offset(780, 516), _stroke(const Color(0x33000000), 10));
  // Stitching.
  final stitch = Path()
    ..moveTo(284, 546)
    ..lineTo(740, 546)
    ..lineTo(726, 732)
    ..quadraticBezierTo(722, 752, 702, 760)
    ..lineTo(530, 826)
    ..quadraticBezierTo(512, 832, 494, 826)
    ..lineTo(322, 760)
    ..quadraticBezierTo(302, 752, 298, 732)
    ..close();
  _dashed(c, stitch, _stroke(_p.quartett.onBack, 9), 30, 22);
});

/// (d) Four-in-a-Row board whose yellow discs form a "K" (4 × 5 grid); the
/// empty holes are dark so the letter carries at small sizes.
void paintConceptD(Canvas canvas, double size) => _grid(canvas, size, (c) {
  _table(c);
  _fit(c, 0.96);
  final c4 = _p.connect4;
  const cols = 4, rows = 5;
  const cell = 124.0;
  const board = Rect.fromLTWH(
    512 - cols * cell / 2 - 26,
    512 - rows * cell / 2 - 26,
    cols * cell + 52,
    rows * cell + 52,
  );
  final rr = RRect.fromRectAndRadius(board, const Radius.circular(64));
  c.drawRRect(rr.shift(const Offset(8, 22)), _fill(_shadow));
  c.drawRRect(rr.shift(const Offset(0, 12)), _fill(c4.boardShade));
  c.drawRRect(rr, _fill(c4.board));
  c.drawRRect(rr, _stroke(const Color(0xFF0E2E5E), 12));
  const k = ['X..X', 'X.X.', 'XX..', 'X.X.', 'X..X'];
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      final o = Offset(512 + (col - (cols - 1) / 2) * cell, 512 + (row - (rows - 1) / 2) * cell);
      if (k[row][col] == 'X') {
        _chip(c, o, cell * 0.45, c4.yellow, outline: false);
      } else {
        // Empty holes stay dark: yellow on dark blue has the most luminance
        // contrast, so the "K" still carries at 40 px (red does not).
        c.drawCircle(o, cell * 0.34, _fill(const Color(0xFF0E2E5E)));
        c.drawCircle(o.translate(0, 5), cell * 0.31, _fill(c4.boardShade));
      }
    }
  }
});

void _dashed(Canvas c, Path path, Paint paint, double dash, double gap) {
  for (final m in path.computeMetrics()) {
    var d = 0.0;
    while (d < m.length) {
      c.drawPath(m.extractPath(d, math.min(d + dash, m.length)), paint);
      d += dash + gap;
    }
  }
}
