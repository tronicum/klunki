import 'dart:math' as math;
import 'dart:typed_data';
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
  // Variants of (c), the user's pick.
  'c1': ('Tasche: Chip-Nieten, Karte, Bauer, Fahne, Chip', paintConceptC1),
  'c2': ('Tasche mit Klappe, Mühlestein-Knopf, Karte, Springer, Schiff', paintConceptC2),
  'c3': ('Schräge Tasche, 5 Teile mit K-Buchstabenstein', paintConceptC3),
  'c4': ('Minimal: 3 große Teile, Chip-Nieten', paintConceptC4),
  'c5': ('Jeanstasche (Denim) wie c1', paintConceptC5),
  // The user's pick c5, final size, and phone ideas on top of it.
  'c5-final': ('Jeanstasche, größere Tasche', paintConceptC5Final),
  'c5-p1': ('Jeanstasche: Handy statt Karte', paintConceptC5P1),
  'c5-p2': ('Jeanstasche: Handy als Stickerei', paintConceptC5P2),
  'c5-p3': ('Jeanstasche: Handy hinter den Steinen', paintConceptC5P3),
  // The user's pick c5-p1 with the word "Klunki" (centred on the pocket first).
  'c5-k1': ('c5-p1 + Lederpatch "Klunki" mittig', paintConceptC5K1),
  'c5-k2': ('c5-p1 + "Klunki" gestickt mittig', paintConceptC5K2),
  'c5-k3': ('c5-p1 + "Klunki" weiß gedruckt mittig', paintConceptC5K3),
  'c5-k4': ('c5-p1 + "Klunki" gelb im Bogen mittig', paintConceptC5K4),
  'c5-k5': ('c5-p1 + Banner "Klunki" unten', paintConceptC5K5),
  'c5-k6': ('c5-p1 + "Klunki" auf größerer Fahne', paintConceptC5K6),
};

/// Concepts that letter the word "Klunki" with Roboto: the renderer must load
/// `assets/fonts/Roboto` under [iconFontFamily] before painting them.
const String iconFontFamily = 'Roboto';

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

/// Fills and outlines [parts] (designed in a 100 box) placed at [box], with a
/// soft drop shadow, like the chess pieces in `chess_pieces.dart`.
void _piece(Canvas c, Rect box, List<Path> parts, {required Color fill, Color line = _ink, double lineWidth = 5}) {
  _inBox(c, box, (c) {
    for (final p in parts) {
      c.drawPath(p.shift(const Offset(2, 3)), _fill(_shadow));
    }
    for (final p in parts) {
      c.drawPath(p, _fill(fill));
      c.drawPath(p, _stroke(line, lineWidth));
    }
  });
}

/// Draws [body] in a 100 box placed at [box].
void _inBox(Canvas c, Rect box, void Function(Canvas c) body) {
  c.save();
  c.translate(box.left, box.top);
  c.scale(box.width / 100, box.height / 100);
  body(c);
  c.restore();
}

/// A chess pawn (shape of `chess_pieces.dart`, bolder outline) in a 100 box
/// placed at [box].
void _pawn(Canvas c, Rect box, {required Color fill, Color line = _ink, double lineWidth = 5}) {
  _piece(
    c,
    box,
    [
      Path()
        ..moveTo(29, 81)
        ..cubicTo(29, 68, 41, 63, 43, 55)
        ..lineTo(57, 55)
        ..cubicTo(59, 63, 71, 68, 71, 81)
        ..close(),
      Path()..addRRect(RRect.fromLTRBR(35, 47, 65, 56, const Radius.circular(3))),
      Path()..addOval(Rect.fromCircle(center: const Offset(50, 33), radius: 14)),
      Path()..addRRect(RRect.fromLTRBR(21, 80, 79, 91, const Radius.circular(4))),
    ],
    fill: fill,
    line: line,
    lineWidth: lineWidth,
  );
  _inBox(c, box, (c) => c.drawCircle(const Offset(45, 28), 4, _fill(const Color(0xB3FFFFFF))));
}

/// A chess knight (shape of `chess_pieces.dart`).
void _knight(Canvas c, Rect box, {required Color fill, Color line = _ink, Color eye = _ink, double lineWidth = 5}) {
  _piece(
    c,
    box,
    [
      Path()
        ..moveTo(30, 81)
        ..cubicTo(30, 68, 38, 61, 46, 55)
        ..cubicTo(40, 55, 32, 58, 27, 59)
        ..cubicTo(19, 60, 14, 55, 18, 48)
        ..lineTo(35, 27)
        ..cubicTo(39, 22, 45, 20, 49, 19)
        ..lineTo(53, 9)
        ..lineTo(59, 19)
        ..cubicTo(74, 25, 81, 50, 76, 81)
        ..close(),
      Path()..addRRect(RRect.fromLTRBR(21, 80, 79, 91, const Radius.circular(4))),
    ],
    fill: fill,
    line: line,
    lineWidth: lineWidth,
  );
  _inBox(c, box, (c) => c.drawCircle(const Offset(41, 32), 4, _fill(eye)));
}

/// A Mühle stone seen from above: flat disc with a soft highlight.
void _stone(Canvas c, Offset o, double r, {required bool white}) {
  final m = _p.muehle;
  c.drawCircle(o.translate(r * 0.06, r * 0.12), r, _fill(_shadow));
  c.drawCircle(
    o,
    r,
    Paint()
      ..shader = ui.Gradient.radial(o.translate(-r * 0.3, -r * 0.35), r * 1.4, [
        white ? m.light : m.darkShine,
        white ? m.lightShade : m.dark,
      ]),
  );
  c.drawCircle(o, r * 0.6, _stroke(const Color(0x33000000), r * 0.08));
  c.drawCircle(o, r, _stroke(_ink, r * 0.1));
}

/// A small grey warship in side view with a red waterline (Schiffe).
void _ship(Canvas c, Rect box, {double lineWidth = 4}) {
  final hull = Path()
    ..moveTo(3, 52)
    ..lineTo(97, 52)
    ..lineTo(85, 76)
    ..lineTo(14, 76)
    ..close();
  final deck = Path()..addRRect(RRect.fromLTRBR(26, 36, 70, 52, const Radius.circular(3)));
  final bridge = Path()..addRRect(RRect.fromLTRBR(36, 22, 56, 36, const Radius.circular(3)));
  final funnel = Path()..addRRect(RRect.fromLTRBR(59, 24, 67, 36, const Radius.circular(2)));
  _piece(c, box, [funnel, bridge, deck], fill: const Color(0xFFB7C1CA), lineWidth: lineWidth);
  _piece(c, box, [hull], fill: _p.schiffe.ship, lineWidth: lineWidth);
  _inBox(c, box, (c) {
    c.drawLine(const Offset(14, 68), const Offset(86, 68), _stroke(_p.schiffe.hit, 5));
    for (final x in [42.0, 50.0]) {
      c.drawCircle(Offset(x, 29), 2.4, _fill(_ink));
    }
  });
}

/// A GoStrategy flag: wooden pole and foot, pennant in the army colour.
void _flag(Canvas c, Rect box, Color color, {double lineWidth = 5}) {
  final wood = _p.muehle.boardLight;
  _piece(
    c,
    box,
    [
      Path()
        ..moveTo(34, 12)
        ..quadraticBezierTo(60, 8, 88, 22)
        ..quadraticBezierTo(62, 34, 34, 46)
        ..close(),
    ],
    fill: color,
    lineWidth: lineWidth,
  );
  _piece(
    c,
    box,
    [
      Path()..addRRect(RRect.fromLTRBR(26, 6, 35, 88, const Radius.circular(4))),
      Path()..addRRect(RRect.fromLTRBR(12, 82, 49, 94, const Radius.circular(5))),
    ],
    fill: wood,
    lineWidth: lineWidth,
  );
}

/// A wooden letter tile with a drawn "K" (no font) for the word game.
void _tile(Canvas c, Rect box, {double angle = 0}) {
  c.save();
  c.translate(box.center.dx, box.center.dy);
  c.rotate(angle);
  c.translate(-box.center.dx, -box.center.dy);
  final face = RRect.fromLTRBR(6, 6, 94, 94, const Radius.circular(14));
  _piece(c, box, [Path()..addRRect(face)], fill: _p.muehle.boardLight);
  _inBox(c, box, (c) {
    c.drawRRect(RRect.fromLTRBR(9, 80, 91, 91, const Radius.circular(10)), _fill(const Color(0x22000000)));
    final k = _stroke(_p.muehle.line, 12);
    c.drawLine(const Offset(34, 24), const Offset(34, 72), k);
    c.drawLine(const Offset(66, 24), const Offset(38, 50), k);
    c.drawLine(const Offset(46, 44), const Offset(68, 72), k);
  });
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

// ---------------------------------------------------- variants of (c) --

/// Pocket leather: gradient top → bottom, stitching colour.
typedef _Leather = ({Color top, Color bottom, Color stitch});

final _Leather _brown = (top: const Color(0xFF9E4A22), bottom: _p.quartett.backA, stitch: _p.quartett.onBack);
const _Leather _denim = (top: Color(0xFF3B6A9E), bottom: Color(0xFF244873), stitch: Color(0xFFF2B33D));

/// Outline of the (c) pocket in its own 1024 design (opening at y 470).
Path _pocketOutline() => Path()
  ..moveTo(236, 470)
  ..lineTo(788, 470)
  ..lineTo(770, 740)
  ..quadraticBezierTo(766, 772, 736, 786)
  ..lineTo(540, 862)
  ..quadraticBezierTo(512, 872, 484, 862)
  ..lineTo(288, 786)
  ..quadraticBezierTo(258, 772, 254, 740)
  ..close();

/// The jeans-style back pocket of (c), scaled by [k] around [topCenter] (the
/// middle of its opening). [pieces] are drawn first, clipped so nothing pokes
/// out below the opening beside the pocket (they sit *in* it). [rivets] are
/// drawn on the two top corners; [flap] adds a front flap with [button] on
/// its tip; [emblem] draws on the pocket front (pocket design coordinates).
void _pocket(
  Canvas c,
  Offset topCenter,
  double k,
  _Leather leather, {
  void Function(Canvas c)? pieces,
  void Function(Canvas c, Offset at, double r)? rivets,
  bool flap = false,
  void Function(Canvas c, Offset at)? button,
  void Function(Canvas c, _Leather leather)? emblem,
}) {
  if (pieces != null) {
    final m = Float64List.fromList([
      k, 0, 0, 0, //
      0, k, 0, 0,
      0, 0, 1, 0,
      topCenter.dx - 512 * k, topCenter.dy - 470 * k, 0, 1,
    ]);
    c.save();
    c.clipPath(
      Path.combine(
        PathOperation.union,
        Path()..addRect(Rect.fromLTRB(-1024, -1024, 2048, topCenter.dy + 4)),
        _pocketOutline().transform(m),
      ),
    );
    pieces(c);
    c.restore();
  }
  c.save();
  c.translate(topCenter.dx, topCenter.dy);
  c.scale(k);
  c.translate(-512, -470);
  final pocket = _pocketOutline();
  final shader = ui.Gradient.linear(const Offset(0, 470), const Offset(0, 870), [leather.top, leather.bottom]);
  c.drawPath(pocket.shift(const Offset(6, 16)), _fill(_shadow));
  c.drawPath(pocket, Paint()..shader = shader);
  c.drawPath(pocket, _stroke(_ink, 14));
  final stitchPaint = _stroke(leather.stitch, 9);
  if (!flap) {
    c.drawLine(const Offset(244, 516), const Offset(780, 516), _stroke(const Color(0x33000000), 10));
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
    _dashed(c, stitch, stitchPaint, 30, 22);
  } else {
    final stitch = Path()
      ..moveTo(300, 740)
      ..lineTo(500, 814)
      ..quadraticBezierTo(512, 818, 524, 814)
      ..lineTo(724, 740);
    _dashed(c, stitch, stitchPaint, 30, 22);
    final f = Path()
      ..moveTo(222, 458)
      ..lineTo(802, 458)
      ..lineTo(790, 600)
      ..lineTo(540, 676)
      ..quadraticBezierTo(512, 684, 484, 676)
      ..lineTo(234, 600)
      ..close();
    c.drawPath(f.shift(const Offset(0, 16)), _fill(const Color(0x55000000)));
    c.drawPath(f, Paint()..shader = shader);
    c.drawPath(f, _stroke(_ink, 14));
    final fs = Path()
      ..moveTo(262, 494)
      ..lineTo(762, 494)
      ..lineTo(754, 574)
      ..lineTo(524, 642)
      ..quadraticBezierTo(512, 646, 500, 642)
      ..lineTo(270, 574)
      ..close();
    _dashed(c, fs, stitchPaint, 30, 22);
    button?.call(c, const Offset(512, 616));
  }
  emblem?.call(c, leather);
  if (rivets != null) {
    rivets(c, const Offset(286, 522), 42);
    rivets(c, const Offset(738, 522), 42);
  }
  c.restore();
}

/// (c1) Smaller pocket with chip rivets; card, pawn, flag and chip peek out.
void paintConceptC1(Canvas canvas, double size) => _grid(canvas, size, (c) => _c1(c, _brown));

/// (c5) As c1, in denim blue with orange stitching (contrast test).
void paintConceptC5(Canvas canvas, double size) => _grid(canvas, size, (c) => _c1(c, _denim));

void _c1(Canvas c, _Leather leather) {
  _table(c);
  _fit(c, 1.04, dy: -18); // group ≈ 66 % of the icon, centred
  final c4 = _p.connect4;
  _pocket(
    c,
    const Offset(512, 560),
    0.74,
    leather,
    pieces: (c) {
      _flag(c, const Rect.fromLTWH(470, 196, 360, 360), _p.gostrategy.red, lineWidth: 4.5);
      _card(c, const Offset(404, 446), const Size(214, 330), -0.2, _p.quartett.sets['F']!, outline: 13);
      _pawn(c, const Rect.fromLTWH(344, 262, 330, 330), fill: _p.chess.whiteFill, lineWidth: 4.5);
      _chip(c, const Offset(624, 540), 90, c4.red);
    },
    rivets: (c, at, r) => _chip(c, at, r, c4.yellow),
  );
}

/// (c5-final) c5 with a ~12 % bigger pocket (pieces unchanged). The pocket
/// opening moves up a little so the group stays at ~69 % of the icon.
void paintConceptC5Final(Canvas canvas, double size) => _grid(canvas, size, (c) => _c5(c, _C5Phone.none));

/// (c5-p1) A generic phone instead of the card, with a tiny Four-in-a-Row
/// board on its screen.
void paintConceptC5P1(Canvas canvas, double size) => _grid(canvas, size, (c) => _c5(c, _C5Phone.insteadOfCard));

/// (c5-p2) A subtle phone outline embroidered on the pocket in the stitching
/// colour; it simply fades away at small sizes.
void paintConceptC5P2(Canvas canvas, double size) => _grid(canvas, size, (c) => _c5(c, _C5Phone.embroidered));

/// (c5-p3) A phone standing upright behind the pieces, which pop out in front
/// of its lit screen.
void paintConceptC5P3(Canvas canvas, double size) => _grid(canvas, size, (c) => _c5(c, _C5Phone.behind));

enum _C5Phone { none, insteadOfCard, embroidered, behind }

void _c5(
  Canvas c,
  _C5Phone phone, {
  void Function(Canvas c, _Leather leather)? emblem,
  Rect flagBox = const Rect.fromLTWH(470, 196, 360, 360),
  bool flagWord = false,
}) {
  _table(c);
  _fit(c, 1.04, dy: -24);
  final c4 = _p.connect4;
  _pocket(
    c,
    const Offset(512, 540),
    0.83,
    _denim,
    pieces: (c) {
      if (phone == _C5Phone.behind) {
        // The phone takes the card's place, standing behind the pieces.
        _phone(c, const Offset(430, 420), const Size(236, 380), -0.14, screen: _screenGlow);
      }
      _flag(c, flagBox, _p.gostrategy.red, lineWidth: 4.5 * 360 / flagBox.width);
      if (flagWord) _flagWord(c, flagBox);
      if (phone == _C5Phone.insteadOfCard) {
        _phone(c, const Offset(404, 440), const Size(204, 344), -0.2, screen: _screenBoard);
      } else if (phone != _C5Phone.behind) {
        _card(c, const Offset(404, 446), const Size(214, 330), -0.2, _p.quartett.sets['F']!, outline: 13);
      }
      _pawn(c, const Rect.fromLTWH(344, 262, 330, 330), fill: _p.chess.whiteFill, lineWidth: 4.5);
      _chip(c, const Offset(624, 540), 90, c4.red);
    },
    rivets: (c, at, r) => _chip(c, at, r, c4.yellow),
    emblem: emblem ?? (phone == _C5Phone.embroidered ? _embroideredPhone : null),
  );
}

// ------------------------------------------- c5-p1 with "Klunki" (k) --

/// (c5-k1) A brown leather jeans patch, centred on the pocket, with "Klunki"
/// pressed into it (cream letters with a dark bevel above them).
void paintConceptC5K1(Canvas canvas, double size) =>
    _grid(canvas, size, (c) => _c5(c, _C5Phone.insteadOfCard, emblem: _leatherPatch));

/// (c5-k2) "Klunki" embroidered straight on the denim in the yellow thread
/// (satin stitch: diagonal thread stripes, raised by a small shadow).
void paintConceptC5K2(Canvas canvas, double size) =>
    _grid(canvas, size, (c) => _c5(c, _C5Phone.insteadOfCard, emblem: _embroideredWord));

/// (c5-k3) "Klunki" as a bold white print with a dark outline, centred.
void paintConceptC5K3(Canvas canvas, double size) =>
    _grid(canvas, size, (c) => _c5(c, _C5Phone.insteadOfCard, emblem: _printedWord));

/// (c5-k4) Big yellow letters on a gentle rainbow arch (badge style), dark
/// outline, centred.
void paintConceptC5K4(Canvas canvas, double size) =>
    _grid(canvas, size, (c) => _c5(c, _C5Phone.insteadOfCard, emblem: _arcWord));

/// (c5-k5) A red ribbon banner across the lower pocket with white letters.
void paintConceptC5K5(Canvas canvas, double size) =>
    _grid(canvas, size, (c) => _c5(c, _C5Phone.insteadOfCard, emblem: _banner));

/// (c5-k6) A bigger red flag with "Klunki" on its pennant.
void paintConceptC5K6(Canvas canvas, double size) => _grid(
  canvas,
  size,
  (c) => _c5(c, _C5Phone.insteadOfCard, flagBox: const Rect.fromLTWH(440, 150, 450, 450), flagWord: true),
);

/// Lays out "Klunki" in Roboto Bold.
TextPainter _wordPainter(double fontSize, {Paint? foreground, Color? color, double spacing = 0}) => TextPainter(
  text: TextSpan(
    text: 'Klunki',
    style: TextStyle(
      fontFamily: iconFontFamily,
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      letterSpacing: spacing,
      height: 1,
      color: foreground == null ? color : null,
      foreground: foreground,
    ),
  ),
  textDirection: TextDirection.ltr,
)..layout();

/// Paints "Klunki" centred at [center] with each paint in [paints] in turn
/// (and the matching offset), so outlines, shadows and fills line up.
void _word(Canvas c, Offset center, double fontSize, List<(Paint, Offset)> paints, {double spacing = 0}) {
  for (final (paint, shift) in paints) {
    final tp = _wordPainter(fontSize, foreground: paint, spacing: spacing);
    // Centre on the cap height, not the line box (no descenders in "Klunki");
    // Roboto's cap height is 0.711 em. Trailing letter spacing is dropped.
    final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(c, center + shift - Offset((tp.width - spacing) / 2, base - fontSize * 0.711 / 2));
  }
}

/// Centre of the pocket front between the stitching (pocket design coords).
const _front = Offset(512, 664);

void _leatherPatch(Canvas c, _Leather leather) {
  final r = RRect.fromRectAndRadius(
    Rect.fromCenter(center: _front, width: 408, height: 180),
    const Radius.circular(22),
  );
  c.save();
  c.translate(_front.dx, _front.dy);
  c.rotate(-0.035);
  c.translate(-_front.dx, -_front.dy);
  c.drawRRect(r.shift(const Offset(4, 10)), _fill(const Color(0x55000000)));
  c.drawRRect(
    r,
    Paint()
      ..shader = ui.Gradient.linear(r.outerRect.topCenter, r.outerRect.bottomCenter, [
        const Color(0xFFB0662F),
        const Color(0xFF7E3A18),
      ]),
  );
  _dashed(c, Path()..addRRect(r.deflate(16)), _stroke(const Color(0xFFF7DDB0), 6), 18, 12);
  c.drawRRect(r, _stroke(_ink, 10));
  _word(c, _front, 110, [
    (_fill(const Color(0xFF4A2410)), const Offset(0, -4)),
    (_fill(const Color(0xFFFFE7BF)), const Offset(0, 2)),
  ], spacing: 2);
  c.restore();
}

void _embroideredWord(Canvas c, _Leather leather) {
  final hsl = HSLColor.fromColor(leather.stitch);
  final dark = hsl.withLightness(hsl.lightness - 0.14).toColor();
  final satin = Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      const Offset(7, 7),
      [leather.stitch, leather.stitch, dark, dark],
      [0, 0.6, 0.6, 1],
      TileMode.repeated,
    );
  _word(c, _front, 142, [
    (_fill(const Color(0x66000000)), const Offset(3, 7)),
    (_stroke(dark, 6), Offset.zero),
    (satin, Offset.zero),
  ], spacing: 3);
}

void _printedWord(Canvas c, _Leather leather) {
  _word(c, _front, 156, [
    (_fill(const Color(0x55000000)), const Offset(4, 9)),
    (_stroke(_ink, 22), Offset.zero),
    (_fill(const Color(0xFFFFFBF2)), Offset.zero),
  ], spacing: 2);
}

void _arcWord(Canvas c, _Leather leather) {
  // Letters on a circle arc that rises in the middle (circle centre below).
  const fontSize = 146.0;
  const radius = 760.0;
  const center = Offset(512, 652 + radius);
  final glyphs = [for (final ch in 'Klunki'.split('')) (ch, _glyph(ch, fontSize, Paint()).width)];
  final total = glyphs.fold(0.0, (a, g) => a + g.$2) + 6 * (glyphs.length - 1);
  var x = -total / 2;
  for (final (ch, w) in glyphs) {
    final angle = (x + w / 2) / radius;
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(angle);
    c.translate(0, -radius);
    for (final (paint, shift) in [
      (_fill(const Color(0x55000000)), const Offset(4, 9)),
      (_stroke(_ink, 20), Offset.zero),
      (_fill(const Color(0xFFFFC93C)), Offset.zero),
    ]) {
      final tp = _glyph(ch, fontSize, paint);
      final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      tp.paint(c, Offset(-w / 2, -base + fontSize * 0.711 / 2) + shift);
    }
    c.restore();
    x += w + 6;
  }
}

TextPainter _glyph(String ch, double fontSize, Paint paint) => TextPainter(
  text: TextSpan(
    text: ch,
    style: TextStyle(
      fontFamily: iconFontFamily,
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      height: 1,
      foreground: paint,
    ),
  ),
  textDirection: TextDirection.ltr,
)..layout();

void _banner(Canvas c, _Leather leather) {
  const red = Color(0xFFC62D2D), redDark = Color(0xFF8E1B1B);
  const y = 730.0, h = 136.0, half = 300.0;
  // Folded tails behind the ends.
  for (final s in [-1.0, 1.0]) {
    final tail = Path()
      ..moveTo(512 + s * (half - 40), y - h / 2 + 34)
      ..lineTo(512 + s * (half + 70), y - h / 2 + 34)
      ..lineTo(512 + s * (half + 34), y + 34)
      ..lineTo(512 + s * (half + 70), y + h / 2 + 34)
      ..lineTo(512 + s * (half - 40), y + h / 2 + 34)
      ..close();
    c.drawPath(tail.shift(const Offset(4, 10)), _fill(const Color(0x55000000)));
    c.drawPath(tail, _fill(redDark));
    c.drawPath(tail, _stroke(_ink, 10));
  }
  final band = Rect.fromCenter(center: const Offset(512, y), width: half * 2, height: h);
  final p = Path()
    ..moveTo(band.left, band.top)
    ..quadraticBezierTo(512, band.top + 30, band.right, band.top)
    ..lineTo(band.right, band.bottom)
    ..quadraticBezierTo(512, band.bottom + 30, band.left, band.bottom)
    ..close();
  c.drawPath(p.shift(const Offset(4, 10)), _fill(const Color(0x55000000)));
  c.drawPath(p, _fill(red));
  c.drawPath(p, _stroke(_ink, 10));
  _word(c, const Offset(512, y + 12), 112, [
    (_fill(redDark), const Offset(0, 5)),
    (_fill(const Color(0xFFFFFBF2)), Offset.zero),
  ], spacing: 4);
}

/// "Klunki" across the GoStrategy pennant (flag [box], see [_flag]).
void _flagWord(Canvas c, Rect box) {
  _inBox(c, box, (c) {
    final pennant = Path()
      ..moveTo(34, 12)
      ..quadraticBezierTo(60, 8, 88, 22)
      ..quadraticBezierTo(62, 34, 34, 46)
      ..close();
    c.save();
    c.clipPath(pennant);
    c.translate(56, 24);
    c.rotate(-0.08);
    _word(c, Offset.zero, 12.5, [(_fill(const Color(0xFFFFFBF2)), Offset.zero)]);
    c.restore();
  });
}

/// A generic phone: graphite rounded body and a screen; no notch, no
/// buttons, no brand cues.
void _phone(Canvas c, Offset center, Size s, double angle, {required void Function(Canvas c, RRect screen) screen}) {
  c.save();
  c.translate(center.dx, center.dy);
  c.rotate(angle);
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: s.width, height: s.height),
    Radius.circular(s.width * 0.17),
  );
  c.drawRRect(body.shift(const Offset(8, 14)), _fill(_shadow));
  c.drawRRect(body, _fill(const Color(0xFF2E3136)));
  final m = s.width * 0.08;
  final scr = RRect.fromRectAndRadius(
    Rect.fromLTRB(body.left + m, body.top + m, body.right - m, body.bottom - m),
    Radius.circular(s.width * 0.1),
  );
  c.save();
  c.clipRRect(scr);
  screen(c, scr);
  c.restore();
  c.drawRRect(body, _stroke(_ink, 13));
  c.restore();
}

/// Phone screen with a tiny 3 × 4 Four-in-a-Row board.
void _screenBoard(Canvas c, RRect s) {
  final c4 = _p.connect4;
  c.drawRRect(s, _fill(c4.board));
  // Near the top of the screen: the lower half is inside the pocket.
  const pattern = ['..r.', '.yr.', 'yryy'];
  final cell = s.width / 4;
  final top = s.top + cell * 0.35;
  for (var row = 0; row < pattern.length; row++) {
    for (var col = 0; col < 4; col++) {
      final o = Offset(s.left + (col + 0.5) * cell, top + (row + 0.5) * cell);
      final ch = pattern[row][col];
      c.drawCircle(
        o,
        cell * 0.36,
        _fill(
          ch == 'r'
              ? c4.red
              : ch == 'y'
              ? c4.yellow
              : c4.boardShade,
        ),
      );
    }
  }
}

/// Phone screen as a lit deep-blue glow with a glass glint, so the light
/// pieces in front stand out and it can't be mistaken for a card.
void _screenGlow(Canvas c, RRect s) {
  c.drawRRect(
    s,
    Paint()
      ..shader = ui.Gradient.radial(s.center.translate(0, -s.height * 0.2), s.height * 0.7, [
        const Color(0xFF4F8BD6),
        const Color(0xFF1C3F7A),
      ]),
  );
  c.drawPath(
    Path()
      ..moveTo(s.left, s.top + s.height * 0.32)
      ..lineTo(s.right, s.top + s.height * 0.08)
      ..lineTo(s.right, s.top + s.height * 0.2)
      ..lineTo(s.left, s.top + s.height * 0.44)
      ..close(),
    _fill(const Color(0x22FFFFFF)),
  );
}

/// Phone outline stitched on the pocket front (pocket design coordinates).
void _embroideredPhone(Canvas c, _Leather leather) {
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(center: const Offset(512, 672), width: 132, height: 210),
    const Radius.circular(26),
  );
  c.drawRRect(body.deflate(20), _fill(const Color(0x1FFFFFFF)));
  _dashed(c, Path()..addRRect(body), _stroke(leather.stitch, 9), 22, 14);
}

/// (c2) Pocket with a front flap and a white Mühle stone as its button;
/// card, knight and ship peek out.
void paintConceptC2(Canvas canvas, double size) => _grid(canvas, size, (c) {
  _table(c);
  _fit(c, 1.04, dy: -18);
  _pocket(
    c,
    const Offset(512, 560),
    0.74,
    _brown,
    flap: true,
    button: (c, at) => _stone(c, at, 56, white: true),
    pieces: (c) {
      _card(c, const Offset(404, 436), const Size(214, 330), -0.2, _p.quartett.sets['A']!, outline: 13);
      _knight(
        c,
        const Rect.fromLTWH(452, 214, 340, 340),
        fill: _p.chess.blackFill,
        eye: _p.chess.blackDetail,
        lineWidth: 4,
      );
      _ship(c, const Rect.fromLTWH(380, 392, 260, 260), lineWidth: 3.8);
    },
  );
});

/// (c3) A slightly tilted pocket, fuller: flag, card, pawn, letter tile "K"
/// and chip; Mühle stones as rivets.
void paintConceptC3(Canvas canvas, double size) => _grid(canvas, size, (c) {
  _table(c);
  _fit(c, 1.04, dy: -20);
  c.translate(512, 512);
  c.rotate(-0.1);
  c.translate(-512, -512);
  _pocket(
    c,
    const Offset(512, 566),
    0.74,
    _brown,
    pieces: (c) {
      _flag(c, const Rect.fromLTWH(276, 222, 340, 340), _p.gostrategy.blue, lineWidth: 4.5);
      _card(c, const Offset(628, 440), const Size(204, 310), 0.2, _p.quartett.sets['E']!, outline: 13);
      _pawn(c, const Rect.fromLTWH(330, 300, 280, 280), fill: _p.chess.whiteFill, lineWidth: 4.5);
      _tile(c, const Rect.fromLTWH(470, 400, 184, 184), angle: -0.12);
      _chip(c, const Offset(386, 540), 76, _p.connect4.red);
    },
    rivets: (c, at, r) => _stone(c, at, r, white: false),
  );
});

/// (c4) Minimal: smaller pocket, three big pieces (card, pawn, chip), chip
/// rivets.
void paintConceptC4(Canvas canvas, double size) => _grid(canvas, size, (c) {
  _table(c);
  _fit(c, 1.04, dy: -22);
  final c4 = _p.connect4;
  _pocket(
    c,
    const Offset(512, 576),
    0.7,
    _brown,
    pieces: (c) {
      _card(c, const Offset(420, 424), const Size(250, 370), -0.22, _p.quartett.sets['F']!, outline: 15);
      _pawn(c, const Rect.fromLTWH(304, 214, 400, 400), fill: _p.chess.whiteFill, lineWidth: 4);
      _chip(c, const Offset(606, 520), 110, c4.red);
    },
    rivets: (c, at, r) => _chip(c, at, r, c4.yellow),
  );
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
