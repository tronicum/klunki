import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Pip positions per face (fractions of the die's side), the classic
/// layout: 1 in the middle, 2/3 on the diagonal, 4/5/6 in two columns.
const Map<int, List<(double, double)>> _pips = {
  1: [(0.5, 0.5)],
  2: [(0.27, 0.27), (0.73, 0.73)],
  3: [(0.27, 0.27), (0.5, 0.5), (0.73, 0.73)],
  4: [(0.27, 0.27), (0.73, 0.27), (0.27, 0.73), (0.73, 0.73)],
  5: [(0.27, 0.27), (0.73, 0.27), (0.5, 0.5), (0.27, 0.73), (0.73, 0.73)],
  6: [(0.27, 0.25), (0.73, 0.25), (0.27, 0.5), (0.73, 0.5), (0.27, 0.75), (0.73, 0.75)],
};

/// Paints one die face [value] (1–6) into [rect]: an ivory rounded square
/// with dark pips (the 1 in red, as on many real dice).
void paintDie(Canvas canvas, Rect rect, int value, {double angle = 0}) {
  final side = rect.shortestSide;
  canvas.save();
  canvas.translate(rect.center.dx, rect.center.dy);
  canvas.rotate(angle);
  final r = Rect.fromCenter(center: Offset.zero, width: side, height: side);
  final rr = RRect.fromRectAndRadius(r, Radius.circular(side * 0.18));
  canvas.drawRRect(rr.shift(Offset(side * 0.03, side * 0.05)), Paint()..color = const Color(0x55000000));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFEDE6D8)],
      ).createShader(r),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, side * 0.03)
      ..color = const Color(0xFFB9AE99),
  );
  final pip = Paint()..color = value == 1 ? const Color(0xFFC62828) : const Color(0xFF222222);
  final radius = side * (value == 1 ? 0.12 : 0.085);
  for (final (fx, fy) in _pips[value] ?? const <(double, double)>[]) {
    canvas.drawCircle(Offset(r.left + r.width * fx, r.top + r.height * fy), radius, pip);
  }
  canvas.restore();
}

/// One die face as a widget ([value] 1–6), [size] logical pixels square.
class DieFace extends StatelessWidget {
  final int value;
  final double size;
  final double angle;
  const DieFace({super.key, required this.value, this.size = 48, this.angle = 0});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _DiePainter(value, angle)),
      );
}

class _DiePainter extends CustomPainter {
  final int value;
  final double angle;
  const _DiePainter(this.value, this.angle);

  @override
  void paint(Canvas canvas, Size size) => paintDie(canvas, Offset.zero & size, value, angle: angle);

  @override
  bool shouldRepaint(_DiePainter old) => old.value != value || old.angle != angle;
}

/// The value [value] (e.g. 53, 21) as two small dice, the higher one first.
class ValueDice extends StatelessWidget {
  final int value;
  final double size;
  const ValueDice({super.key, required this.value, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final hi = value ~/ 10, lo = value % 10;
    // Dice read left to right in every language.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [DieFace(value: hi, size: size), SizedBox(width: size * 0.18), DieFace(value: lo, size: size)],
      ),
    );
  }
}

/// Paints the dice cup upside down on the table: a leather-brown beaker,
/// wider at the bottom, with two rim bands. [rect] is the cup's box.
void paintCup(Canvas canvas, Rect rect, {Color body = const Color(0xFF6D3B1F), Color band = const Color(0xFFD9A441)}) {
  final w = rect.width, h = rect.height;
  final top = rect.top, bottom = rect.bottom;
  final path = Path()
    ..moveTo(rect.left + w * 0.18, top)
    ..lineTo(rect.right - w * 0.18, top)
    ..lineTo(rect.right, bottom)
    ..lineTo(rect.left, bottom)
    ..close();
  canvas.drawPath(path.shift(Offset(w * 0.03, h * 0.04)), Paint()..color = const Color(0x44000000));
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        colors: [Color.lerp(body, Colors.black, 0.25)!, Color.lerp(body, Colors.white, 0.18)!, body, Color.lerp(body, Colors.black, 0.35)!],
        stops: const [0, 0.35, 0.6, 1],
      ).createShader(rect),
  );
  // The closed top (the cup's bottom, it stands upside down).
  final topOval = Rect.fromLTRB(rect.left + w * 0.18, top - h * 0.06, rect.right - w * 0.18, top + h * 0.06);
  canvas.drawOval(topOval, Paint()..color = Color.lerp(body, Colors.white, 0.12)!);
  // Two bands near the open rim and one near the top.
  final bandPaint = Paint()..color = band;
  for (final (f, thick) in const [(0.78, 0.07), (0.9, 0.05), (0.14, 0.05)]) {
    final y = top + h * f;
    final inset = w * 0.18 * (1 - f);
    final bh = h * thick;
    canvas.drawRect(Rect.fromLTRB(rect.left + inset, y, rect.right - inset, y + bh), bandPaint);
  }
}

/// The table with the cup: the cup stands on the felt, lifted by [lift]
/// (0 = down over the dice, 1 = up and tilted, the dice visible). [dice]
/// are painted under the cup (only pass them when they may be seen).
/// [shake] (0–1) wobbles the cup while it is shaken.
class CupTable extends StatelessWidget {
  final List<int>? dice;
  final double lift;
  final double shake;
  const CupTable({super.key, this.dice, this.lift = 0, this.shake = 0});

  @override
  Widget build(BuildContext context) {
    final palette = KlunkiPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _TablePainter(
        felt: dark ? const Color(0xFF1E4D3A) : const Color(0xFF2E7D5B),
        cup: palette.accent('maexchen').color,
        dice: dice,
        lift: lift,
        shake: shake,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _TablePainter extends CustomPainter {
  final Color felt;
  final Color cup;
  final List<int>? dice;
  final double lift;
  final double shake;
  const _TablePainter({required this.felt, required this.cup, this.dice, required this.lift, required this.shake});

  @override
  void paint(Canvas canvas, Size size) {
    final table = Offset.zero & size;
    canvas.clipRect(table);
    final rr = RRect.fromRectAndRadius(table.deflate(4), const Radius.circular(28));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = RadialGradient(colors: [Color.lerp(felt, Colors.white, 0.12)!, felt], radius: 0.9).createShader(table),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFF5A3A22),
    );
    final unit = min(min(size.width * 0.62, size.height * 0.8), 260.0);
    final cupH = unit * 0.62, cupW = unit * 0.5;
    final floor = size.height * 0.5 + cupH * 0.42;
    final d = dice;
    if (d != null && lift > 0) {
      final die = cupW * 0.48;
      final cx = size.width / 2;
      for (var i = 0; i < 2; i++) {
        final x = cx - cupW * 0.25 + (i == 0 ? -1 : 1) * die * 0.62;
        paintDie(canvas, Rect.fromCenter(center: Offset(x, floor - die * 0.6), width: die, height: die), d[i],
            angle: i == 0 ? -0.12 : 0.18);
      }
    }
    // The cup: lifted up and to the side, tilted.
    final wobble = sin(shake * pi * 6) * 0.12 * (1 - shake);
    canvas.save();
    final pivot = Offset(size.width / 2, floor);
    canvas.translate(pivot.dx + lift * cupW * 0.85, pivot.dy - lift * cupH * 0.3);
    canvas.rotate(lift * 0.45 + wobble);
    paintCup(canvas, Rect.fromLTWH(-cupW / 2, -cupH, cupW, cupH), body: cup);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TablePainter old) =>
      old.felt != felt || old.cup != cup || old.lift != lift || old.shake != shake || old.dice != dice;
}

/// Menu illustration: the cup tipped over, two dice showing Mäxchen (2 and 1).
class MaexchenIllustration extends CustomPainter {
  final KlunkiPalette palette;
  const MaexchenIllustration(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final o = Offset((size.width - s) / 2, (size.height - s) / 2);
    canvas.save();
    canvas.translate(o.dx + s * 0.34, o.dy + s * 0.5);
    canvas.rotate(-0.45);
    paintCup(canvas, Rect.fromLTWH(-s * 0.2, -s * 0.3, s * 0.4, s * 0.5), body: palette.accent('maexchen').color);
    canvas.restore();
    paintDie(canvas, Rect.fromLTWH(o.dx + s * 0.52, o.dy + s * 0.5, s * 0.24, s * 0.24), 2, angle: 0.2);
    paintDie(canvas, Rect.fromLTWH(o.dx + s * 0.7, o.dy + s * 0.32, s * 0.22, s * 0.22), 1, angle: -0.15);
  }

  @override
  bool shouldRepaint(MaexchenIllustration old) => old.palette != palette;
}
