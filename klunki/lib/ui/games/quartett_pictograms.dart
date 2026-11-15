import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Drawn pictograms of the Quartett decks (KLD-069): a car, a high-speed
/// train, a rocket, a plane, an elephant (KLD-128) and a motorcycle
/// (KLD-129), side view. No
/// downloaded images or logos: plain shapes, coloured per set by the caller.
///
/// Drawn in a 100 × 60 box, scaled to fit the canvas and centred. [color]
/// fills the body, [detail] the windows and wheel hubs (usually the
/// background the pictogram sits on).
///
/// Per-set pictograms (KLD-128): a deck in [setPictogramDecks] draws one
/// pictogram per set when [set] is given (the card header and the gallery
/// grid pass the card's set): the animal deck shows a big cat, bear, ape,
/// elephant, whale, shark fin, bird or crocodile. Without [set] (card back,
/// deck picker, deck list), and for every other deck, the deck pictogram.
class QuartettPictogram extends CustomPainter {
  final String deck;

  /// The set letter `A`–`H` of the card shown; null = the deck pictogram.
  final String? set;
  final Color color;
  final Color detail;
  const QuartettPictogram(this.deck, {this.set, required this.color, required this.detail});

  /// Decks with one pictogram per set; a new deck opts in here and in
  /// [_setPictogram].
  static const setPictogramDecks = {'animals'};

  /// Whether this painter draws a set pictogram (not the deck pictogram).
  bool get showsSet => set != null && setPictogramDecks.contains(deck);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 100) < (size.height / 60) ? size.width / 100 : size.height / 60;
    canvas
      ..save()
      ..translate((size.width - 100 * scale) / 2, (size.height - 60 * scale) / 2)
      ..scale(scale);
    final body = Paint()..color = color;
    final fine = Paint()..color = detail;
    if (showsSet) {
      _setPictogram(canvas, body, fine);
    } else {
      _deckPictogram(canvas, body, fine);
    }
    canvas.restore();
  }

  void _setPictogram(Canvas c, Paint body, Paint fine) {
    switch ((deck, set)) {
      case ('animals', 'A'):
        _bigCat(c, body, fine);
      case ('animals', 'B'):
        _bear(c, body, fine);
      case ('animals', 'C'):
        _ape(c, body, fine);
      case ('animals', 'E'):
        _whale(c, body, fine);
      case ('animals', 'F'):
        _sharkFin(c, body, fine);
      case ('animals', 'G'):
        _bird(c, body, fine);
      case ('animals', 'H'):
        _crocodile(c, body, fine);
      default: // animals D (Savanne): the elephant; an unknown set: the deck.
        _deckPictogram(c, body, fine);
    }
  }

  void _deckPictogram(Canvas canvas, Paint body, Paint fine) {
    switch (deck) {
      case 'trains':
        _train(canvas, body, fine);
      case 'rockets':
        _rocket(canvas, body, fine);
      case 'planes':
        _plane(canvas, body, fine);
      case 'animals':
        _elephant(canvas, body, fine);
      case 'motorcycles':
        _motorcycle(canvas, body, fine);
      default:
        _car(canvas, body, fine);
    }
  }

  void _car(Canvas c, Paint body, Paint fine) {
    final p = Path()
      ..moveTo(6, 42)
      ..lineTo(6, 32)
      ..quadraticBezierTo(8, 27, 18, 26)
      ..lineTo(32, 24)
      ..quadraticBezierTo(42, 13, 56, 13)
      ..lineTo(66, 13)
      ..quadraticBezierTo(76, 14, 82, 24)
      ..lineTo(90, 26)
      ..quadraticBezierTo(96, 28, 96, 36)
      ..lineTo(96, 42)
      ..close();
    c.drawPath(p, body);
    final window = Path()
      ..moveTo(38, 24)
      ..quadraticBezierTo(46, 17, 56, 17)
      ..lineTo(60, 17)
      ..lineTo(60, 24)
      ..close()
      ..moveTo(64, 17)
      ..lineTo(68, 17)
      ..quadraticBezierTo(73, 18, 77, 24)
      ..lineTo(64, 24)
      ..close();
    c.drawPath(window, fine);
    for (final x in [24.0, 78.0]) {
      c.drawCircle(Offset(x, 43), 9, body);
      c.drawCircle(Offset(x, 43), 4, fine);
    }
  }

  void _train(Canvas c, Paint body, Paint fine) {
    final p = Path()
      ..moveTo(4, 44)
      ..lineTo(4, 20)
      ..quadraticBezierTo(4, 14, 10, 14)
      ..lineTo(62, 14)
      ..quadraticBezierTo(84, 15, 97, 38)
      ..quadraticBezierTo(98, 44, 92, 44)
      ..close();
    c.drawPath(p, body);
    for (var x = 10.0; x < 56; x += 11) {
      c.drawRRect(RRect.fromLTRBR(x, 20, x + 8, 28, const Radius.circular(1.5)), fine);
    }
    final cab = Path()
      ..moveTo(64, 20)
      ..lineTo(70, 20)
      ..quadraticBezierTo(80, 23, 86, 30)
      ..lineTo(64, 30)
      ..close();
    c.drawPath(cab, fine);
    c.drawRect(const Rect.fromLTRB(4, 34, 94, 36), fine);
    for (final x in [16.0, 28.0, 66.0, 78.0]) {
      c.drawCircle(Offset(x, 48), 5, body);
      c.drawCircle(Offset(x, 48), 2, fine);
    }
    c.drawRect(const Rect.fromLTRB(2, 53, 98, 55), body);
  }

  void _rocket(Canvas c, Paint body, Paint fine) {
    // Flying to the right, tilted slightly up.
    c
      ..save()
      ..translate(50, 30)
      ..rotate(-0.35)
      ..translate(-50, -30);
    final hull = Path()
      ..moveTo(22, 22)
      ..lineTo(66, 22)
      ..quadraticBezierTo(88, 24, 96, 30)
      ..quadraticBezierTo(88, 36, 66, 38)
      ..lineTo(22, 38)
      ..close();
    c.drawPath(hull, body);
    final fins = Path()
      ..moveTo(22, 22)
      ..lineTo(32, 22)
      ..lineTo(24, 10)
      ..lineTo(14, 10)
      ..close()
      ..moveTo(22, 38)
      ..lineTo(32, 38)
      ..lineTo(24, 50)
      ..lineTo(14, 50)
      ..close();
    c.drawPath(fins, body);
    c.drawCircle(const Offset(62, 30), 4.5, fine);
    c.drawRect(const Rect.fromLTRB(44, 22, 47, 38), fine);
    final flame = Path()
      ..moveTo(22, 25)
      ..quadraticBezierTo(8, 26, 2, 30)
      ..quadraticBezierTo(8, 34, 22, 35)
      ..close();
    c.drawPath(flame, Paint()..color = color.withValues(alpha: 0.55));
    c.restore();
  }

  void _plane(Canvas c, Paint body, Paint fine) {
    final fuselage = Path()
      ..moveTo(8, 26)
      ..lineTo(84, 26)
      ..quadraticBezierTo(97, 28, 98, 32)
      ..quadraticBezierTo(96, 37, 84, 38)
      ..lineTo(18, 38)
      ..quadraticBezierTo(10, 37, 8, 32)
      ..close();
    c.drawPath(fuselage, body);
    final tail = Path()
      ..moveTo(8, 28)
      ..lineTo(4, 8)
      ..lineTo(12, 8)
      ..lineTo(26, 27)
      ..close();
    c.drawPath(tail, body);
    final wing = Path()
      ..moveTo(40, 33)
      ..lineTo(58, 33)
      ..lineTo(44, 54)
      ..lineTo(34, 54)
      ..close();
    c.drawPath(wing, body);
    for (var x = 30.0; x < 78; x += 7) {
      c.drawCircle(Offset(x, 30.5), 1.6, fine);
    }
    final cockpit = Path()
      ..moveTo(86, 28.5)
      ..quadraticBezierTo(92, 29, 94, 31)
      ..lineTo(86, 31)
      ..close();
    c.drawPath(cockpit, fine);
  }

  /// Animals (KLD-128): an elephant, side view, trunk to the right.
  void _elephant(Canvas c, Paint body, Paint fine) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Tail with a tuft.
    c
      ..drawLine(const Offset(13, 22), const Offset(7, 36), stroke..strokeWidth = 2)
      ..drawCircle(const Offset(7, 37), 2.2, body);
    // Back, belly and legs.
    c.drawRRect(RRect.fromLTRBR(11, 11, 72, 42, const Radius.circular(15)), body);
    for (final x in [15.0, 29.0, 46.0, 60.0]) {
      c.drawRRect(RRect.fromLTRBR(x, 32, x + 11, 56, const Radius.circular(2.5)), body);
    }
    // Head and trunk, curling forward at the tip.
    c.drawCircle(const Offset(76, 21), 13.5, body);
    final trunk = Path()
      ..moveTo(84, 25)
      ..cubicTo(94, 30, 93, 44, 92, 50)
      ..quadraticBezierTo(92, 55, 97, 53);
    c.drawPath(trunk, stroke..strokeWidth = 7);
    // Ear (outlined in the detail colour), eye and tusk.
    final ear = Path()
      ..moveTo(70, 10)
      ..quadraticBezierTo(55, 10, 57, 24)
      ..quadraticBezierTo(59, 36, 71, 32)
      ..quadraticBezierTo(74, 20, 70, 10)
      ..close();
    c
      ..drawPath(ear, body)
      ..drawPath(
          ear,
          Paint()
            ..color = detail
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6)
      ..drawCircle(const Offset(82, 17), 1.8, fine);
    final tusk = Path()
      ..moveTo(83, 29)
      ..quadraticBezierTo(88, 36, 96, 34)
      ..lineTo(95, 31.5)
      ..quadraticBezierTo(89, 32, 86, 27)
      ..close();
    c.drawPath(tusk, fine);
  }

  /// Motorcycles (KLD-129): a road bike, side view, front wheel to the right.
  void _motorcycle(Canvas c, Paint body, Paint fine) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Wheels: tyre, rim gap and hub.
    for (final x in [20.0, 80.0]) {
      c
        ..drawCircle(Offset(x, 42), 14, body)
        ..drawCircle(Offset(x, 42), 9, fine)
        ..drawCircle(Offset(x, 42), 3.5, body);
    }
    // Swingarm to the rear hub, fork to the front hub, handlebar.
    c
      ..drawLine(const Offset(44, 36), const Offset(20, 42), stroke..strokeWidth = 4.5)
      ..drawLine(const Offset(69, 17), const Offset(80, 42), stroke..strokeWidth = 4.5)
      ..drawLine(const Offset(65, 11), const Offset(73, 13), stroke..strokeWidth = 3.5);
    // Seat and tail, tank, engine down to the swingarm.
    final frame = Path()
      ..moveTo(8, 22)
      ..quadraticBezierTo(9, 18, 15, 19)
      ..lineTo(38, 21)
      ..quadraticBezierTo(44, 13, 56, 13)
      ..quadraticBezierTo(66, 13, 71, 20)
      ..lineTo(64, 28)
      ..lineTo(58, 40)
      ..lineTo(40, 40)
      ..lineTo(34, 30)
      ..lineTo(14, 28)
      ..quadraticBezierTo(8, 27, 8, 22)
      ..close();
    c.drawPath(frame, body);
    // Engine block and seat line in the detail colour, the headlight.
    final line = Paint()
      ..color = detail
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    c
      ..drawRRect(RRect.fromLTRBR(42, 29, 56, 37, const Radius.circular(2)), fine)
      ..drawLine(const Offset(16, 23), const Offset(36, 24.5), line)
      ..drawCircle(const Offset(74, 21), 3.5, body)
      ..drawCircle(const Offset(75, 21), 1.6, fine);
  }

  Paint _stroke(double width, Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Animals A (Raubkatzen): a lion's head with its mane, front view.
  void _bigCat(Canvas c, Paint body, Paint fine) {
    // The mane: a ring of rounded, shaggy tufts around the head.
    const centre = Offset(50, 30);
    const tufts = 13;
    Offset at(double a, double r) => centre + Offset(math.cos(a) * r, math.sin(a) * r);
    final mane = Path();
    for (var i = 0; i < tufts; i++) {
      final a0 = i * 2 * math.pi / tufts - math.pi / 2;
      final a1 = (i + 1) * 2 * math.pi / tufts - math.pi / 2;
      final p0 = at(a0, 21), tip = at(a0 + (a1 - a0) * 0.65, 28), p1 = at(a1, 21);
      final ctl = at(a0 + (a1 - a0) * 0.2, 29);
      if (i == 0) mane.moveTo(p0.dx, p0.dy);
      mane
        ..quadraticBezierTo(ctl.dx, ctl.dy, tip.dx, tip.dy)
        ..lineTo(p1.dx, p1.dy);
    }
    c
      ..drawPath(mane..close(), body)
      ..drawCircle(centre, 21, body);
    // Round ears in the mane, then a smaller face, set off by a thin gap.
    for (final x in [40.0, 60.0]) {
      c
        ..drawCircle(Offset(x, 16), 5.5, fine)
        ..drawCircle(Offset(x, 16), 4, body);
    }
    c
      ..drawOval(const Rect.fromLTRB(36.5, 15.5, 63.5, 50.5), fine)
      ..drawOval(const Rect.fromLTRB(38.5, 17.5, 61.5, 48.5), body);
    // Eyes, a broad nose and the mouth.
    for (final x in [44.0, 56.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, 27), width: 6, height: 4), fine);
    }
    c.drawPath(
        Path()
          ..moveTo(45, 35)
          ..lineTo(55, 35)
          ..lineTo(50, 41)
          ..close(),
        fine);
    final mouth = _stroke(1.8, detail);
    c
      ..drawLine(const Offset(50, 41), const Offset(50, 44), mouth)
      ..drawPath(
          Path()
            ..moveTo(44, 45)
            ..quadraticBezierTo(50, 48, 50, 44)
            ..quadraticBezierTo(50, 48, 56, 45),
          mouth);
  }

  /// Animals B (Bären): a bear walking, side view, head to the right.
  void _bear(Canvas c, Paint body, Paint fine) {
    // A rounded back with only a slight rise over the shoulders.
    c
      ..drawCircle(const Offset(14, 27), 3.5, body) // tail
      ..drawPath(
          Path()
            ..moveTo(14, 36)
            ..cubicTo(14, 25, 24, 21, 36, 21)
            ..cubicTo(46, 21, 50, 17, 58, 17)
            ..cubicTo(66, 17, 70, 22, 74, 27)
            ..lineTo(74, 42)
            ..lineTo(16, 42)
            ..close(),
          body);
    for (final x in [16.0, 29.0, 49.0, 62.0]) {
      c.drawRRect(RRect.fromLTRBR(x, 34, x + 11, 55, const Radius.circular(3)), body);
    }
    // The head, held a little low: round ears and a tapered snout.
    c
      ..drawCircle(const Offset(79, 30), 9, body)
      ..drawCircle(const Offset(75, 21), 4.5, body) // ear
      ..drawPath(
          Path()
            ..moveTo(84, 25)
            ..quadraticBezierTo(92, 27, 96, 30)
            ..quadraticBezierTo(99, 33, 95, 36)
            ..lineTo(84, 38)
            ..close(),
          body) // snout
      ..drawCircle(const Offset(75, 21), 1.8, fine)
      ..drawCircle(const Offset(81, 27), 1.7, fine) // eye
      ..drawCircle(const Offset(96, 31.5), 2, fine); // nose
  }

  /// Animals C (Affen): an ape's face, front view.
  void _ape(Canvas c, Paint body, Paint fine) {
    for (final x in [29.0, 71.0]) {
      c
        ..drawCircle(Offset(x, 31), 8, body)
        ..drawCircle(Offset(x, 31), 3.8, fine);
    }
    c.drawCircle(const Offset(50, 30), 21, body);
    // The bare face: two eye patches over a muzzle.
    c
      ..drawCircle(const Offset(43.5, 27), 7.5, fine)
      ..drawCircle(const Offset(56.5, 27), 7.5, fine)
      ..drawOval(const Rect.fromLTRB(36, 29, 64, 49), fine)
      ..drawCircle(const Offset(43.5, 26.5), 2.4, body)
      ..drawCircle(const Offset(56.5, 26.5), 2.4, body)
      ..drawCircle(const Offset(47.5, 36), 1.3, body)
      ..drawCircle(const Offset(52.5, 36), 1.3, body)
      ..drawPath(
          Path()
            ..moveTo(43, 42)
            ..quadraticBezierTo(50, 46, 57, 42),
          _stroke(1.8, color));
  }

  /// Animals E (Wale & Delfine): a whale with its spout, head to the right.
  void _whale(Canvas c, Paint body, Paint fine) {
    final p = Path()
      ..moveTo(95, 32)
      ..cubicTo(95, 17, 78, 14, 60, 16)
      ..cubicTo(42, 18, 30, 27, 21, 31)
      ..lineTo(8, 21)
      ..lineTo(13, 34)
      ..lineTo(7, 46)
      ..lineTo(22, 37)
      ..cubicTo(34, 45, 60, 49, 80, 45)
      ..cubicTo(90, 43, 95, 39, 95, 32)
      ..close();
    c
      ..drawPath(p, body)
      ..drawPath(
          Path()
            ..moveTo(58, 44)
            ..lineTo(50, 55)
            ..lineTo(67, 46)
            ..close(),
          body)
      ..drawCircle(const Offset(82, 29), 2.2, fine)
      ..drawPath(
          Path()
            ..moveTo(94, 35)
            ..quadraticBezierTo(86, 39, 75, 37),
          _stroke(1.6, detail));
    final spout = _stroke(2.6, color);
    c
      ..drawLine(const Offset(76, 12), const Offset(76, 6), spout)
      ..drawPath(
          Path()
            ..moveTo(76, 7)
            ..quadraticBezierTo(70, 1, 66, 5),
          spout)
      ..drawPath(
          Path()
            ..moveTo(76, 7)
            ..quadraticBezierTo(82, 1, 86, 5),
          spout);
  }

  /// Animals F (Haie): a shark's dorsal fin cutting through the waves,
  /// swimming to the left: a slightly convex leading edge rising to a tip
  /// that points back, and a concave trailing edge dropping steeply.
  void _sharkFin(Canvas c, Paint body, Paint fine) {
    c.drawPath(
        Path()
          ..moveTo(22, 42)
          ..cubicTo(36, 36, 52, 20, 70, 4)
          ..quadraticBezierTo(56, 24, 61, 42)
          ..close(),
        body);
    final wave = _stroke(4, color);
    for (final (y, shift) in [(44.0, 0.0), (54.0, 6.0)]) {
      final p = Path()..moveTo(6 + shift, y);
      for (var x = 6.0 + shift; x < 88; x += 14) {
        p.quadraticBezierTo(x + 7, y - 5, x + 14, y);
      }
      c.drawPath(p, wave);
    }
  }

  /// Animals G (Vögel): a bird with spread wings, front view.
  void _bird(Canvas c, Paint body, Paint fine) {
    final wing = Path()
      ..moveTo(45, 25)
      ..quadraticBezierTo(28, 10, 4, 12)
      ..lineTo(11, 19)
      ..lineTo(5, 23)
      ..lineTo(14, 27)
      ..lineTo(9, 32)
      ..quadraticBezierTo(30, 35, 45, 38)
      ..close();
    c.drawPath(wing, body);
    c
      ..save()
      ..translate(100, 0)
      ..scale(-1, 1)
      ..drawPath(wing, body)
      ..restore();
    c
      ..drawOval(const Rect.fromLTRB(41, 21, 59, 47), body)
      ..drawPath(
          Path()
            ..moveTo(44, 43)
            ..lineTo(56, 43)
            ..lineTo(61, 55)
            ..lineTo(39, 55)
            ..close(),
          body)
      ..drawCircle(const Offset(50, 16), 8, body)
      ..drawCircle(const Offset(46.8, 14.5), 1.5, fine)
      ..drawCircle(const Offset(53.2, 14.5), 1.5, fine)
      ..drawPath(
          Path()
            ..moveTo(47.5, 18)
            ..lineTo(52.5, 18)
            ..lineTo(50, 23)
            ..close(),
          fine);
  }

  /// Animals H (Reptilien): a crocodile, side view, snout to the right.
  void _crocodile(Canvas c, Paint body, Paint fine) {
    final p = Path()
      ..moveTo(2, 38)
      ..quadraticBezierTo(16, 28, 32, 25)
      ..lineTo(66, 24)
      ..quadraticBezierTo(73, 22, 78, 26)
      ..lineTo(95, 29)
      ..quadraticBezierTo(99, 33, 96, 38)
      ..lineTo(72, 40)
      ..quadraticBezierTo(60, 44, 44, 44)
      ..quadraticBezierTo(20, 44, 2, 38)
      ..close();
    // Legs, bent like a walking crocodile, with feet.
    for (final x in [30.0, 58.0]) {
      c
        ..drawRRect(RRect.fromLTRBR(x, 38, x + 9, 52, const Radius.circular(3)), body)
        ..drawRRect(RRect.fromLTRBR(x - 3, 48, x + 13, 53, const Radius.circular(2.5)), body);
    }
    c.drawPath(p, body);
    // Ridges on the back.
    final ridges = Path();
    for (var x = 28.0; x <= 62; x += 8.5) {
      ridges
        ..moveTo(x, 25.6)
        ..lineTo(x + 3.5, 19.5)
        ..lineTo(x + 7, 25.2)
        ..close();
    }
    c
      ..drawPath(ridges, body)
      ..drawCircle(const Offset(75, 23), 4.2, body)
      ..drawCircle(const Offset(75.5, 22.5), 1.6, fine)
      ..drawPath(
          Path()
            ..moveTo(72, 34.5)
            ..lineTo(96, 33.5),
          _stroke(1.4, detail));
  }

  @override
  bool shouldRepaint(QuartettPictogram old) =>
      old.deck != deck || old.set != set || old.color != color || old.detail != detail;
}
