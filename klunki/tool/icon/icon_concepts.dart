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
  // The user's pick k1 (leather patch): patch / lettering styles and cards.
  'c5-k1a': ('k1: dunkles Leder, Goldprägung', (c, s) => _k1(c, s, _patchA)),
  'c5-k1b': ('k1: helles Leder, Ton-in-Ton geprägt', (c, s) => _k1(c, s, _patchB)),
  'c5-k1c': ('k1: weiße Versalien, gesperrt', (c, s) => _k1(c, s, _patchC)),
  'c5-k1d': ('k1: dünne Schrift creme', (c, s) => _k1(c, s, _patchD)),
  'c5-k1e': ('k1: rotbraunes Leder, schmale Gold-Versalien', (c, s) => _k1(c, s, _patchE)),
  'c5-k1f': ('k1: kursiv, erhaben mit Kontur', (c, s) => _k1(c, s, _patchF)),
  'c5-k1-card-a': ('k1: Karte statt Handy', paintConceptC5K1CardA),
  'c5-k1-card-b': ('k1: Karte hinter dem Handy', paintConceptC5K1CardB),
  // The user's pick c5-k1-card-b: patch steps from k1 to k1b, letter tile.
  'c5-cb-a': ('card-b: Patch wie k1 (creme auf mittelbraun)', paintConceptCbA),
  'c5-cb-b': ('card-b: Patch wie k1b (hell, Ton in Ton)', paintConceptCbB),
  'c5-cb-c': ('card-b: Patch heller als k1, creme Schrift', paintConceptCbC),
  'c5-cb-d': ('card-b: helles Leder, dunkel geprägt', paintConceptCbD),
  'c5-cb-e': ('card-b: hellbraun, creme Schrift', paintConceptCbE),
  'c5-cb-tile-1': ('card-b: Buchstabenstein vor dem Handy', paintConceptCbTile1),
  'c5-cb-tile-2': ('card-b: Buchstabenstein statt rotem Stein', paintConceptCbTile2),
  'c5-cb-tile-3': ('card-b: Buchstabenstein zwischen Bauer und Fahne', paintConceptCbTile3),
  // The user's pick c5-cb-tile-1 plus a small die behind the red piece.
  'c5-final-d1': ('tile-1 + weißer Würfel, 5, flach', paintConceptFinalD1),
  'c5-final-d2': ('tile-1 + elfenbein Würfel, 6, mit Oberseite', paintConceptFinalD2),
  'c5-final-d3': ('tile-1 + weißer Würfel, 5, 3D (Oberseite und Seite)', paintConceptFinalD3),
  'c5-final-d4': ('tile-1 + kleiner elfenbein Würfel, 6, stark gedreht', paintConceptFinalD4),
  // Maintainer feedback on d4: zoom in, bigger lettering.
  'c5-zoom-a': ('d4 herangezoomt, Schrift etwas fetter', paintConceptZoomA),
  'c5-zoom-b': ('d4: größere Tasche, breiter Patch, große fette Schrift', paintConceptZoomB),
  'c5-zoom-c': ('wie b ohne Karte und Würfel, größerer Buchstabenstein', paintConceptZoomC),
  'c5-zoom-d': ('d4 ohne Schriftzug, am weitesten herangezoomt', paintConceptZoomD),
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

/// The layers of an Android adaptive icon: [full] is the normal icon,
/// [foreground] everything but the table (on transparent), [background] only
/// the table.
enum IconLayer { full, foreground, background }

/// Which layer the painters draw; set by the export tool, normally [IconLayer.full].
IconLayer iconLayer = IconLayer.full;

/// Runs [body] on a 1024 × 1024 grid scaled to [size].
void _grid(Canvas canvas, double size, void Function(Canvas c) body) {
  canvas.save();
  canvas.scale(size / 1024);
  canvas.clipRect(const Rect.fromLTWH(0, 0, 1024, 1024));
  if (iconLayer == IconLayer.background) {
    _table(canvas);
  } else {
    body(canvas);
  }
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
  if (iconLayer == IconLayer.foreground) return;
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

enum _C5Phone { none, insteadOfCard, embroidered, behind, cardAndPhone }

void _c5(
  Canvas c,
  _C5Phone phone, {
  void Function(Canvas c, _Leather leather)? emblem,
  Rect flagBox = const Rect.fromLTWH(470, 196, 360, 360),
  bool flagWord = false,
  bool chip = true,
  void Function(Canvas c)? extra,
  void Function(Canvas c)? behindChip,
  double zoom = 1.04,
  double dy = -24,
  double pocketScale = 0.83,
  bool card = true,
}) {
  _table(c);
  _fit(c, zoom, dy: dy);
  final c4 = _p.connect4;
  _pocket(
    c,
    const Offset(512, 540),
    pocketScale,
    _denim,
    pieces: (c) {
      if (phone == _C5Phone.behind) {
        // The phone takes the card's place, standing behind the pieces.
        _phone(c, const Offset(430, 420), const Size(236, 380), -0.14, screen: _screenGlow);
      }
      _flag(c, flagBox, _p.gostrategy.red, lineWidth: 4.5 * 360 / flagBox.width);
      if (flagWord) _flagWord(c, flagBox);
      if (phone == _C5Phone.cardAndPhone && card) {
        _card(c, const Offset(364, 392), const Size(190, 290), -0.46, _p.quartett.sets['E']!, outline: 12);
      }
      if (phone == _C5Phone.insteadOfCard || phone == _C5Phone.cardAndPhone) {
        _phone(c, const Offset(404, 440), const Size(204, 344), -0.2, screen: _screenBoard);
      } else if (phone == _C5Phone.none || phone == _C5Phone.embroidered) {
        _card(c, const Offset(404, 446), const Size(214, 330), -0.2, _p.quartett.sets['F']!, outline: 13);
      }
      _pawn(c, const Rect.fromLTWH(344, 262, 330, 330), fill: _p.chess.whiteFill, lineWidth: 4.5);
      behindChip?.call(c);
      if (chip) _chip(c, const Offset(624, 540), 90, c4.red);
      extra?.call(c);
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

/// c5-k1a…f: c5-p1 with a restyled leather patch.
void _k1(Canvas canvas, double size, void Function(Canvas c, _Leather leather) patch) =>
    _grid(canvas, size, (c) => _c5(c, _C5Phone.insteadOfCard, emblem: patch));

/// The patch style used with the cards (the pick of the k1 styles).
const _cardPatch = _patchA;

/// (c5-k1-card-a) The Quartett card back in the phone's place, k1 patch.
void paintConceptC5K1CardA(Canvas canvas, double size) =>
    _grid(canvas, size, (c) => _c5(c, _C5Phone.none, emblem: _cardPatch));

/// (c5-k1-card-b) Phone in front, the Quartett card peeking out behind it.
void paintConceptC5K1CardB(Canvas canvas, double size) =>
    _grid(canvas, size, (c) => _c5(c, _C5Phone.cardAndPhone, emblem: _cardPatch));

// ------------------------------------------ c5-k1-card-b round (cb) --

/// c5-k1-card-b (phone in front, green card behind) with [patch] and an
/// optional letter [tile] (drawn last among the pieces; [chip]: keep the red
/// piece).
void _cb(
  Canvas canvas,
  double size,
  void Function(Canvas c, _Leather leather) patch, {
  void Function(Canvas c)? tile,
  bool chip = true,
  void Function(Canvas c)? behindChip,
}) => _grid(
  canvas,
  size,
  (c) => _c5(c, _C5Phone.cardAndPhone, emblem: patch, extra: tile, chip: chip, behindChip: behindChip),
);

/// cb-c: halfway between k1 and k1b: lighter leather than k1, cream letters
/// pressed in with a dark edge above (k1 style), so it still reads at 180 px.
void _patchCbC(Canvas c, _Leather leather) => _patch(
  c,
  top: const Color(0xFFCB8A4C),
  bottom: const Color(0xFFA0602C),
  stitch: const Color(0xFFFBE6C2),
  letters: [
    (_fill(const Color(0xFF4A2410)), const Offset(0, -4)),
    (_fill(const Color(0xFFFFEDCF)), const Offset(0, 2)),
  ],
);

/// cb-d: k1b's light tan leather, but the pressed-in letters in deep brown.
void _patchCbD(Canvas c, _Leather leather) => _patch(
  c,
  top: const Color(0xFFE2AE72),
  bottom: const Color(0xFFC08347),
  stitch: const Color(0xFF7A4520),
  letters: [
    (_fill(const Color(0xFFF8DDB4)), const Offset(0, 4)),
    (_fill(const Color(0xFF2E1408)), const Offset(0, -3)),
    (_fill(const Color(0xFF5A2C10)), Offset.zero),
  ],
);

/// cb-e: like cb-c on a slightly darker tan (a step towards k1b's leather
/// with cream letters).
void _patchCbE(Canvas c, _Leather leather) => _patch(
  c,
  top: const Color(0xFFD99C5E),
  bottom: const Color(0xFFB27238),
  stitch: const Color(0xFF6E3C1A),
  letters: [
    (_fill(const Color(0xFF4A2410)), const Offset(0, -4)),
    (_fill(const Color(0xFFFFF4E2)), const Offset(0, 2)),
  ],
);

/// The patch used for the tile placements (the pick of cb-a…e).
const _tilePatch = _patchCbC;

/// A light-wood word-game tile: "K" with a small point value in the corner.
void _letterTile(Canvas c, Offset center, double side, double angle) {
  c.save();
  c.translate(center.dx, center.dy);
  c.rotate(angle);
  final box = Rect.fromCenter(center: Offset.zero, width: side, height: side);
  _piece(
    c,
    box,
    [Path()..addRRect(RRect.fromLTRBR(6, 6, 94, 94, const Radius.circular(12)))],
    fill: const Color(0xFFF3DDB0),
    lineWidth: 5,
  );
  _inBox(c, box, (c) {
    // Lower bevel and wood grain.
    c.drawRRect(RRect.fromLTRBR(9, 82, 91, 91, const Radius.circular(9)), _fill(const Color(0x22000000)));
    for (final y in [22.0, 48.0, 70.0]) {
      c.drawLine(Offset(14, y), Offset(86, y + 3), _stroke(const Color(0x14000000), 2));
    }
    void text(String s, double size, Offset at) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: iconFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: size,
            height: 1,
            color: const Color(0xFF3A1E0E),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      tp.paint(c, at - Offset(tp.width / 2, base - size * 0.711 / 2));
    }

    text('K', 62, const Offset(46, 47));
    text('5', 20, const Offset(79, 77));
  });
  c.restore();
}

/// cb-a: k1's patch (cream on mid brown).
void paintConceptCbA(Canvas canvas, double size) => _cb(canvas, size, _leatherPatch);

/// cb-b: k1b's patch (tonal deboss on light tan).
void paintConceptCbB(Canvas canvas, double size) => _cb(canvas, size, _patchB);

/// cb-c: in between, lighter than k1 but with cream letters.
void paintConceptCbC(Canvas canvas, double size) => _cb(canvas, size, _patchCbC);

/// cb-d: k1b leather with deep-brown pressed letters.
void paintConceptCbD(Canvas canvas, double size) => _cb(canvas, size, _patchCbD);

/// cb-e: tan leather with cream letters (between cb-c and k1b).
void paintConceptCbE(Canvas canvas, double size) => _cb(canvas, size, _patchCbE);

/// tile-1: the tile in front of the phone's lower left, rising from the
/// pocket.
void paintConceptCbTile1(Canvas canvas, double size) => _cb(canvas, size, _tilePatch, tile: _tile1);

// ------------------------------------------- final: tile-1 + die (d) --

const _dieWhite = (face: Color(0xFFFFFFFF), shade: Color(0xFFD9DDE3), pip: Color(0xFF26201C));
const _dieIvory = (face: Color(0xFFFFF4DC), shade: Color(0xFFE2CFA6), pip: Color(0xFF3A1E0E));

/// A die centred at [center] (front face [side] wide, rotated by [angle])
/// showing [pips] (5 or 6). [depth] > 0 adds a top face (and with [sideFace]
/// a right face) for a 3D hint; the top face shows one pip.
void _die(
  Canvas c,
  Offset center,
  double side,
  double angle,
  int pips,
  ({Color face, Color shade, Color pip}) col, {
  double depth = 0,
  bool sideFace = false,
}) {
  c.save();
  c.translate(center.dx, center.dy);
  c.rotate(angle);
  final h = side / 2, r = side * 0.18, d = depth * side;
  final front = RRect.fromLTRBR(-h, -h, h, h, Radius.circular(r));
  final line = _stroke(_ink, side * 0.07);
  // Shadow.
  c.drawRRect(front.shift(Offset(side * 0.06, side * 0.12)), _fill(_shadow));
  if (d > 0) {
    Path face(List<Offset> pts) => Path()..addPolygon(pts, true);
    final top = face([
      Offset(-h + r * 0.4, -h),
      Offset(h - r * 0.4, -h),
      Offset(h + d - r * 0.4, -h - d),
      Offset(-h + d + r * 0.4, -h - d),
    ]);
    c.drawPath(top, _fill(col.face));
    c.drawPath(top, line);
    // One pip on the top face, squashed into the parallelogram.
    c.save();
    c.translate(d / 2, -h - d / 2);
    c.scale(1, 0.45);
    c.drawCircle(Offset.zero, side * 0.09, _fill(col.pip));
    c.restore();
    if (sideFace) {
      final right = face([
        Offset(h, -h + r * 0.4),
        Offset(h + d, -h - d + r * 0.4),
        Offset(h + d, h - d - r * 0.4),
        Offset(h, h - r * 0.4),
      ]);
      c.drawPath(right, _fill(col.shade));
      c.drawPath(right, line);
    }
  }
  c.drawRRect(front, Paint()..shader = ui.Gradient.linear(Offset(-h, -h), Offset(h, h), [col.face, col.shade]));
  c.drawRRect(front, line);
  final q = side * 0.27, pr = side * 0.09;
  final spots = <Offset>[
    Offset(-q, -q), Offset(q, q), Offset(q, -q), Offset(-q, q), //
    if (pips == 5) Offset.zero,
    if (pips == 6) ...[Offset(-q, 0), Offset(q, 0)],
  ];
  for (final o in spots) {
    c.drawCircle(o, pr, _fill(col.pip));
  }
  c.restore();
}

void _tile1(Canvas c) => _letterTile(c, const Offset(318, 474), 136, -0.22);

void _final(Canvas canvas, double size, void Function(Canvas c) die) =>
    _cb(canvas, size, _tilePatch, tile: _tile1, behindChip: die);

/// d1: small white die, 5 pips, flat, tilted right, peeking out right of
/// the red piece.
void paintConceptFinalD1(Canvas canvas, double size) =>
    _final(canvas, size, (c) => _die(c, const Offset(712, 452), 92, 0.3, 5, _dieWhite));

/// d2: ivory die, 6 pips, with a hint of its top face.
void paintConceptFinalD2(Canvas canvas, double size) =>
    _final(canvas, size, (c) => _die(c, const Offset(708, 460), 96, -0.12, 6, _dieIvory, depth: 0.26));

/// d3: white die, 5 pips, 3D with top and right face.
void paintConceptFinalD3(Canvas canvas, double size) =>
    _final(canvas, size, (c) => _die(c, const Offset(702, 462), 92, 0.18, 5, _dieWhite, depth: 0.26, sideFace: true));

/// d4: smaller ivory die, 6 pips, strongly turned, flat.
void paintConceptFinalD4(Canvas canvas, double size) =>
    _final(canvas, size, (c) => _die(c, const Offset(716, 466), 80, 0.62, 6, _dieIvory));

// ------------------------------------- zoom round on c5-final-d4 (z) --
//
// Maintainer feedback on c5-final-d4: the motif leaves a lot of table around
// it and "Klunki" is a blur at home-screen size. These variants fill more of
// the square (the group spans ~85–90 % instead of ~68 %) and set the word
// bigger and bolder; some drop small pieces so the rest can grow.

/// d4's die (smaller ivory die, 6 pips, strongly turned).
void _dieD4(Canvas c) => _die(c, const Offset(716, 466), 80, 0.62, 6, _dieIvory);

/// The cb-c patch (light leather, cream letters with a dark edge above),
/// sized [size], lettered at [fontSize] and thickened by [bold].
void Function(Canvas c, _Leather leather) _zoomPatch(Size size, double fontSize, double bold) =>
    (c, leather) => _patch(
      c,
      top: const Color(0xFFCB8A4C),
      bottom: const Color(0xFFA0602C),
      stitch: const Color(0xFFFBE6C2),
      size: size,
      fontSize: fontSize,
      bold: bold,
      spacing: 0,
      letters: [
        (_fill(const Color(0xFF4A2410)), const Offset(0, -5)),
        (_fill(const Color(0xFFFFEDCF)), const Offset(0, 2)),
      ],
    );

/// d4 drawn with the given zoom, pocket size, patch and optional pieces.
void _zoomed(
  Canvas canvas,
  double size, {
  required double zoom,
  required double dy,
  double pocketScale = 0.83,
  void Function(Canvas c, _Leather leather)? patch,
  bool card = true,
  bool die = true,
  Offset tileAt = const Offset(318, 474),
  double tileSide = 136,
}) => _grid(
  canvas,
  size,
  (c) => _c5(
    c,
    _C5Phone.cardAndPhone,
    emblem: patch,
    extra: (c) => _letterTile(c, tileAt, tileSide, -0.22),
    behindChip: die ? _dieD4 : null,
    zoom: zoom,
    dy: dy,
    pocketScale: pocketScale,
    card: card,
  ),
);

/// zoom-a: d4 unchanged, only zoomed in; the letters a little bolder.
void paintConceptZoomA(Canvas canvas, double size) =>
    _zoomed(canvas, size, zoom: 1.30, dy: -16, patch: _zoomPatch(const Size(408, 180), 112, 5));

/// zoom-b: bigger pocket (the patch and its word grow with it), zoomed in;
/// a wider patch with bigger, bolder letters. All pieces kept.
void paintConceptZoomB(Canvas canvas, double size) =>
    _zoomed(canvas, size, zoom: 1.22, dy: -70, pocketScale: 0.95, patch: _zoomPatch(const Size(446, 196), 132, 7));

/// zoom-c: like b without the green card and the die (fewer small parts),
/// a bigger letter tile; the patch takes most of the pocket front.
void paintConceptZoomC(Canvas canvas, double size) => _zoomed(
  canvas,
  size,
  zoom: 1.24,
  dy: -74,
  pocketScale: 0.95,
  patch: _zoomPatch(const Size(448, 206), 142, 8),
  card: false,
  die: false,
  tileAt: const Offset(322, 462),
  tileSide: 160,
);

/// zoom-d: no lettering (the name sits under the icon anyway): a smaller
/// plain stitched pocket (as in c1), so the pieces get most of the room, all
/// pieces kept, zoomed in furthest.
void paintConceptZoomD(Canvas canvas, double size) => _zoomed(canvas, size, zoom: 1.40, dy: 10, pocketScale: 0.72);

/// tile-2: the tile replaces the red piece.
void paintConceptCbTile2(Canvas canvas, double size) =>
    _cb(canvas, size, _tilePatch, chip: false, tile: (c) => _letterTile(c, const Offset(636, 456), 168, 0.14));

/// tile-3: a smaller tile leaning between pawn and flag, on the red piece.
void paintConceptCbTile3(Canvas canvas, double size) =>
    _cb(canvas, size, _tilePatch, tile: (c) => _letterTile(c, const Offset(706, 414), 124, 0.24));

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

/// A lettering face: text, family, weight, slant and cap height (em, for
/// centring).
typedef _Face = ({String text, String family, FontWeight weight, bool italic, double cap});

const _Face _robotoBold = (text: 'Klunki', family: iconFontFamily, weight: FontWeight.w700, italic: false, cap: 0.711);
const _Face _robotoCaps = (text: 'KLUNKI', family: iconFontFamily, weight: FontWeight.w500, italic: false, cap: 0.711);
const _Face _robotoItalic = (text: 'Klunki', family: iconFontFamily, weight: FontWeight.w700, italic: true, cap: 0.711);

const _Face _robotoRegular = (
  text: 'Klunki',
  family: iconFontFamily,
  weight: FontWeight.w400,
  italic: false,
  cap: 0.711,
);
const _Face _robotoBoldCaps = (
  text: 'KLUNKI',
  family: iconFontFamily,
  weight: FontWeight.w700,
  italic: false,
  cap: 0.711,
);

/// Lays out [face] at [fontSize] with [foreground].
TextPainter _wordPainter(_Face face, double fontSize, Paint foreground, double spacing) => TextPainter(
  text: TextSpan(
    text: face.text,
    style: TextStyle(
      fontFamily: face.family,
      fontWeight: face.weight,
      fontStyle: face.italic ? FontStyle.italic : FontStyle.normal,
      fontSize: fontSize,
      letterSpacing: spacing,
      height: 1,
      foreground: foreground,
    ),
  ),
  textDirection: TextDirection.ltr,
)..layout();

/// Paints the word centred at [center] with each paint in [paints] in turn
/// (and the matching offset), so outlines, shadows and fills line up.
void _word(
  Canvas c,
  Offset center,
  double fontSize,
  List<(Paint, Offset)> paints, {
  double spacing = 0,
  _Face face = _robotoBold,
  double stretch = 1,
}) {
  c.save();
  // Horizontal stretch around the centre (< 1: condensed).
  c.translate(center.dx, 0);
  c.scale(stretch, 1);
  c.translate(-center.dx, 0);
  for (final (paint, shift) in paints) {
    final tp = _wordPainter(face, fontSize, paint, spacing);
    // Centre on the cap height, not the line box (no descenders in "Klunki").
    // Trailing letter spacing is dropped.
    final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(c, center + shift - Offset((tp.width - spacing) / 2, base - fontSize * face.cap / 2));
  }
  c.restore();
}

/// Centre of the pocket front between the stitching (pocket design coords).
const _front = Offset(512, 664);

/// Lettering on the patch: (paint, offset) layers from back to front.
typedef _Letters = List<(Paint, Offset)>;

/// A leather jeans patch centred on the pocket front, slightly tilted, with
/// its own stitching, lettered with [face] in [letters].
void _patch(
  Canvas c, {
  Color top = const Color(0xFFB0662F),
  Color bottom = const Color(0xFF7E3A18),
  Color stitch = const Color(0xFFF7DDB0),
  _Face face = _robotoBold,
  double fontSize = 110,
  double spacing = 2,
  Offset nudge = Offset.zero,
  double stretch = 1,
  Size size = const Size(408, 180),
  double bold = 0,
  required _Letters letters,
}) {
  final r = RRect.fromRectAndRadius(
    Rect.fromCenter(center: _front, width: size.width, height: size.height),
    const Radius.circular(22),
  );
  c.save();
  c.translate(_front.dx, _front.dy);
  c.rotate(-0.035);
  c.translate(-_front.dx, -_front.dy);
  c.drawRRect(r.shift(const Offset(4, 10)), _fill(const Color(0x55000000)));
  c.drawRRect(r, Paint()..shader = ui.Gradient.linear(r.outerRect.topCenter, r.outerRect.bottomCenter, [top, bottom]));
  _dashed(c, Path()..addRRect(r.deflate(16)), _stroke(stitch, 6), 18, 12);
  c.drawRRect(r, _stroke(_ink, 10));
  // [bold] > 0 thickens every letter layer with a stroke in its own paint
  // (Roboto Bold is the heaviest bundled weight).
  final layers = [
    for (final (paint, shift) in letters) ...[
      if (bold > 0)
        (
          Paint()
            ..color = paint.color
            ..shader = paint.shader
            ..style = PaintingStyle.stroke
            ..strokeWidth = bold
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true,
          shift,
        ),
      (paint, shift),
    ],
  ];
  _word(c, _front + nudge, fontSize, layers, spacing: spacing, face: face, stretch: stretch);
  c.restore();
}

/// k1: mid-brown leather, cream Roboto Bold pressed in (dark edge above).
void _leatherPatch(Canvas c, _Leather leather) => _patch(
  c,
  letters: [
    (_fill(const Color(0xFF4A2410)), const Offset(0, -4)),
    (_fill(const Color(0xFFFFE7BF)), const Offset(0, 2)),
  ],
);

/// Gold foil: vertical gradient, light top, deep amber bottom.
Paint _gold(double fontSize) => Paint()
  ..shader = ui.Gradient.linear(
    Offset(0, _front.dy - fontSize * 0.4),
    Offset(0, _front.dy + fontSize * 0.4),
    [const Color(0xFFFFE9A0), const Color(0xFFE6B34A), const Color(0xFFB07A1E)],
    [0, 0.5, 1],
  );

/// k1a: dark chocolate leather, gold foil letters, gold stitching.
void _patchA(Canvas c, _Leather leather) => _patch(
  c,
  top: const Color(0xFF5E2E16),
  bottom: const Color(0xFF3A1A0B),
  stitch: const Color(0xFFE6B34A),
  letters: [(_fill(const Color(0xFF1E0C04)), const Offset(0, 5)), (_gold(110), Offset.zero)],
);

/// k1b: light tan leather, classic tonal deboss (letters pressed in, darker
/// than the leather, with a light lip below).
void _patchB(Canvas c, _Leather leather) => _patch(
  c,
  top: const Color(0xFFE2AE72),
  bottom: const Color(0xFFC08347),
  stitch: const Color(0xFF7A4520),
  letters: [
    (_fill(const Color(0xFFF6D6A8)), const Offset(0, 4)),
    (_fill(const Color(0xFF4A2410)), const Offset(0, -3)),
    (_fill(const Color(0xFF8A4E22)), Offset.zero),
  ],
);

/// k1c: mid leather, white caps print with wide spacing (Roboto Medium).
void _patchC(Canvas c, _Leather leather) => _patch(
  c,
  face: _robotoCaps,
  fontSize: 84,
  spacing: 9,
  letters: [(_fill(const Color(0x88000000)), const Offset(0, 4)), (_fill(const Color(0xFFFFFFFF)), Offset.zero)],
);

/// k1d: mid leather, light cream Roboto Regular, a bit larger, printed.
void _patchD(Canvas c, _Leather leather) => _patch(
  c,
  face: _robotoRegular,
  fontSize: 122,
  spacing: 1,
  letters: [(_fill(const Color(0xFF3A1A0B)), const Offset(0, 5)), (_fill(const Color(0xFFFFEFD2)), Offset.zero)],
);

/// k1e: dark red-brown leather, tall condensed gold caps (Roboto Bold
/// squeezed to 78 %), workwear-label style.
void _patchE(Canvas c, _Leather leather) => _patch(
  c,
  top: const Color(0xFF7A2E1A),
  bottom: const Color(0xFF4E1A0E),
  stitch: const Color(0xFFE6B34A),
  face: _robotoBoldCaps,
  fontSize: 116,
  spacing: 4,
  stretch: 0.78,
  letters: [(_fill(const Color(0xFF1E0C04)), const Offset(0, 5)), (_gold(116), Offset.zero)],
);

/// k1f: mid leather, raised cream Roboto Bold Italic with a dark outline and
/// a shadow down-right.
void _patchF(Canvas c, _Leather leather) => _patch(
  c,
  fontSize: 112,
  face: _robotoItalic,
  letters: [
    (_fill(const Color(0xAA2A1206)), const Offset(4, 6)),
    (_stroke(_ink, 9), Offset.zero),
    (_fill(const Color(0xFFFFE7BF)), Offset.zero),
  ],
);

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
