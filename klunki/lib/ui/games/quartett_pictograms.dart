import 'package:flutter/material.dart';

/// Drawn pictograms of the Quartett decks (KLD-069): a car, a high-speed
/// train, a rocket and a plane, side view, facing the reading end. No
/// downloaded images or logos: plain shapes, coloured per set by the caller.
///
/// Drawn in a 100 × 60 box, scaled to fit the canvas and centred. [color]
/// fills the body, [detail] the windows and wheel hubs (usually the
/// background the pictogram sits on).
class QuartettPictogram extends CustomPainter {
  final String deck;
  final Color color;
  final Color detail;
  const QuartettPictogram(this.deck, {required this.color, required this.detail});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 100) < (size.height / 60) ? size.width / 100 : size.height / 60;
    canvas
      ..save()
      ..translate((size.width - 100 * scale) / 2, (size.height - 60 * scale) / 2)
      ..scale(scale);
    final body = Paint()..color = color;
    final fine = Paint()..color = detail;
    switch (deck) {
      case 'trains':
        _train(canvas, body, fine);
      case 'rockets':
        _rocket(canvas, body, fine);
      case 'planes':
        _plane(canvas, body, fine);
      default:
        _car(canvas, body, fine);
    }
    canvas.restore();
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

  @override
  bool shouldRepaint(QuartettPictogram old) => old.deck != deck || old.color != color || old.detail != detail;
}
