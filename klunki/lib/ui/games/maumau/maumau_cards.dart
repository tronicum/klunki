import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' show MauMauCard, MauMauRank, MauMauSuit;

import '../../../app/theme.dart';

/// Our own Mau-Mau card faces (KLD-118): drawn in Flutter, no card art from
/// anywhere else. A white card with the rank and the suit in two corners and
/// a big suit (number cards and the ace) or the rank letter over a suit
/// (jack, queen, king) in the middle. Hearts and diamonds red, clubs and
/// spades black, as on every French deck.

/// Red of hearts and diamonds.
const Color maumauRed = Color(0xFFC62828);

/// Black of clubs and spades.
const Color maumauBlack = Color(0xFF212121);

/// Colour of [suit] on a card face.
Color maumauSuitColor(MauMauSuit suit) => suit.isRed ? maumauRed : maumauBlack;

/// Width : height of a card.
const double maumauCardAspect = 2 / 3;

/// The localized name of [suit] ("Herz").
String maumauSuitName(AppLocalizations l10n, MauMauSuit suit) => switch (suit) {
  MauMauSuit.clubs => l10n.maumauSuitClubs,
  MauMauSuit.spades => l10n.maumauSuitSpades,
  MauMauSuit.hearts => l10n.maumauSuitHearts,
  MauMauSuit.diamonds => l10n.maumauSuitDiamonds,
};

/// The rank as printed in a card corner ("7", "10", "B" for the German jack).
String maumauRankLabel(AppLocalizations l10n, MauMauRank rank) => switch (rank) {
  MauMauRank.jack => l10n.maumauRankLetterJack,
  MauMauRank.queen => l10n.maumauRankLetterQueen,
  MauMauRank.king => l10n.maumauRankLetterKing,
  MauMauRank.ace => l10n.maumauRankLetterAce,
  _ => rank.code,
};

/// The rank as a word in a sentence ("7", "Bube").
String maumauRankName(AppLocalizations l10n, MauMauRank rank) => switch (rank) {
  MauMauRank.jack => l10n.maumauRankJack,
  MauMauRank.queen => l10n.maumauRankQueen,
  MauMauRank.king => l10n.maumauRankKing,
  MauMauRank.ace => l10n.maumauRankAce,
  _ => rank.code,
};

/// The card in a sentence ("Herz 7", "Pik Bube").
String maumauCardName(AppLocalizations l10n, MauMauCard card) =>
    l10n.maumauCardName(maumauSuitName(l10n, card.suit), maumauRankName(l10n, card.rank));

/// The shape of [suit] filling a square canvas.
Path maumauSuitPath(MauMauSuit suit, Size size) {
  final w = size.width, h = size.height;
  Offset p(double x, double y) => Offset(x * w, y * h);
  final path = Path();
  switch (suit) {
    case MauMauSuit.hearts:
      path
        ..moveTo(p(0.5, 0.95).dx, p(0.5, 0.95).dy)
        ..cubicTo(0.12 * w, 0.66 * h, 0.0, 0.47 * h, 0.0, 0.3 * h)
        ..cubicTo(0.0, 0.13 * h, 0.13 * w, 0.03 * h, 0.27 * w, 0.03 * h)
        ..cubicTo(0.39 * w, 0.03 * h, 0.47 * w, 0.1 * h, 0.5 * w, 0.2 * h)
        ..cubicTo(0.53 * w, 0.1 * h, 0.61 * w, 0.03 * h, 0.73 * w, 0.03 * h)
        ..cubicTo(0.87 * w, 0.03 * h, w, 0.13 * h, w, 0.3 * h)
        ..cubicTo(w, 0.47 * h, 0.88 * w, 0.66 * h, 0.5 * w, 0.95 * h)
        ..close();
    case MauMauSuit.diamonds:
      path
        ..moveTo(0.5 * w, 0.0)
        ..lineTo(0.88 * w, 0.5 * h)
        ..lineTo(0.5 * w, h)
        ..lineTo(0.12 * w, 0.5 * h)
        ..close();
    case MauMauSuit.spades:
      path
        ..moveTo(0.5 * w, 0.02 * h)
        ..cubicTo(0.32 * w, 0.25 * h, 0.0, 0.4 * h, 0.0, 0.6 * h)
        ..cubicTo(0.0, 0.75 * h, 0.12 * w, 0.84 * h, 0.26 * w, 0.84 * h)
        ..cubicTo(0.35 * w, 0.84 * h, 0.43 * w, 0.8 * h, 0.47 * w, 0.73 * h)
        ..lineTo(0.38 * w, h)
        ..lineTo(0.62 * w, h)
        ..lineTo(0.53 * w, 0.73 * h)
        ..cubicTo(0.57 * w, 0.8 * h, 0.65 * w, 0.84 * h, 0.74 * w, 0.84 * h)
        ..cubicTo(0.88 * w, 0.84 * h, w, 0.75 * h, w, 0.6 * h)
        ..cubicTo(w, 0.4 * h, 0.68 * w, 0.25 * h, 0.5 * w, 0.02 * h)
        ..close();
    case MauMauSuit.clubs:
      final r = 0.22 * w;
      path
        ..addOval(Rect.fromCircle(center: p(0.5, 0.25), radius: r))
        ..addOval(Rect.fromCircle(center: p(0.26, 0.58), radius: r))
        ..addOval(Rect.fromCircle(center: p(0.74, 0.58), radius: r))
        ..addOval(Rect.fromCircle(center: p(0.5, 0.5), radius: 0.14 * w))
        ..moveTo(0.5 * w, 0.5 * h)
        ..lineTo(0.62 * w, h)
        ..lineTo(0.38 * w, h)
        ..close();
  }
  return path;
}

/// A suit symbol, painted (no font glyph needed).
class MauMauSuitIcon extends StatelessWidget {
  final MauMauSuit suit;
  final double size;
  final Color? color;
  const MauMauSuitIcon({super.key, required this.suit, required this.size, this.color});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _SuitPainter(suit, color ?? maumauSuitColor(suit))),
  );
}

class _SuitPainter extends CustomPainter {
  final MauMauSuit suit;
  final Color color;
  const _SuitPainter(this.suit, this.color);

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(maumauSuitPath(suit, size), Paint()..color = color);

  @override
  bool shouldRepaint(_SuitPainter old) => old.suit != suit || old.color != color;
}

/// A face-up card [width] wide. [highlight] draws a coloured frame (a card
/// that may be laid), [dimmed] greys it a little (a card that does not fit).
/// The semantics label names the card ("Herz 7").
class MauMauCardFace extends StatelessWidget {
  final MauMauCard card;
  final double width;
  final Color? highlight;
  final bool dimmed;
  const MauMauCardFace({super.key, required this.card, required this.width, this.highlight, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = width, h = width / maumauCardAspect;
    final color = maumauSuitColor(card.suit);
    final label = maumauRankLabel(l10n, card.rank);
    final face = card.rank == MauMauRank.jack || card.rank == MauMauRank.queen || card.rank == MauMauRank.king;
    Widget corner() => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: color,
            fontSize: w * 0.24,
            height: 1.0,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: w * 0.02),
        MauMauSuitIcon(suit: card.suit, size: w * 0.17),
      ],
    );
    final center = face
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textScaler: TextScaler.noScaling,
                style: TextStyle(color: color, fontSize: w * 0.42, height: 1.0, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: w * 0.04),
              MauMauSuitIcon(suit: card.suit, size: w * 0.3),
            ],
          )
        : MauMauSuitIcon(suit: card.suit, size: w * (card.rank == MauMauRank.ace ? 0.56 : 0.44));
    return Semantics(
      label: maumauCardName(l10n, card),
      excludeSemantics: true,
      child: Directionality(
        // Corners stay where a card has them, also in RTL layouts.
        textDirection: TextDirection.ltr,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: dimmed ? const Color(0xFFE6E2DA) : Colors.white,
            borderRadius: BorderRadius.circular(w * 0.1),
            border: Border.all(
              color: highlight ?? const Color(0xFFBDB6A8),
              width: highlight == null ? 1 : math.max(2.5, w * 0.05),
            ),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0.5, 1.5))],
          ),
          child: Opacity(
            opacity: dimmed ? 0.55 : 1,
            child: Stack(
              children: [
                Positioned(left: w * 0.06, top: w * 0.05, child: corner()),
                Positioned(
                  right: w * 0.06,
                  bottom: w * 0.05,
                  child: RotatedBox(quarterTurns: 2, child: corner()),
                ),
                Center(child: center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The back of a card in the game's accent: a frame and a diamond pattern.
class MauMauCardBack extends StatelessWidget {
  final double width;
  const MauMauCardBack({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final accent = KlunkiPalette.of(context).accent('maumau').color;
    return SizedBox(
      width: width,
      height: width / maumauCardAspect,
      child: CustomPaint(painter: _BackPainter(accent)),
    );
  }
}

class _BackPainter extends CustomPainter {
  final Color color;
  const _BackPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) => paintMauMauBack(canvas, Offset.zero & size, color);

  @override
  bool shouldRepaint(_BackPainter old) => old.color != color;
}

/// Paints a card back into [r] (also used by the menu illustration).
void paintMauMauBack(Canvas canvas, Rect r, Color color) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.1));
  canvas.drawRRect(rr.shift(Offset(r.width * 0.01, r.width * 0.03)), Paint()..color = const Color(0x40000000));
  canvas.drawRRect(rr, Paint()..color = Colors.white);
  final inner = rr.deflate(r.width * 0.07);
  canvas.drawRRect(inner, Paint()..color = color);
  canvas.save();
  canvas.clipRRect(inner);
  final line = Paint()
    ..color = Colors.white.withValues(alpha: 0.28)
    ..strokeWidth = math.max(1, r.width * 0.025);
  final step = r.width * 0.16;
  for (var x = -r.height; x < r.width + r.height; x += step) {
    canvas.drawLine(Offset(r.left + x, r.top), Offset(r.left + x + r.height, r.bottom), line);
    canvas.drawLine(Offset(r.left + x, r.bottom), Offset(r.left + x + r.height, r.top), line);
  }
  canvas.restore();
}

/// Menu illustration: three fanned cards (hearts 7, a back, the jack of
/// spades) over the accent.
class MauMauIllustration extends CustomPainter {
  final KlunkiPalette palette;
  const MauMauIllustration(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final square = Rect.fromCenter(center: size.center(Offset.zero), width: s, height: s).deflate(s * 0.04);
    final w = square.width * 0.42, h = w / maumauCardAspect;
    final pivot = Offset(square.center.dx, square.bottom - square.height * 0.02);
    final accent = palette.accent('maumau').color;
    const cards = [MauMauSuit.hearts, null, MauMauSuit.spades];
    for (var i = 0; i < cards.length; i++) {
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate((i - 1) * 0.34);
      final card = Rect.fromLTWH(-w / 2, -h - square.height * 0.02, w, h);
      final suit = cards[i];
      if (suit == null) {
        paintMauMauBack(canvas, card, accent);
      } else {
        final rr = RRect.fromRectAndRadius(card, Radius.circular(w * 0.1));
        canvas.drawRRect(rr.shift(Offset(w * 0.02, w * 0.05)), Paint()..color = const Color(0x40000000));
        canvas.drawRRect(rr, Paint()..color = Colors.white);
        final big = w * 0.5;
        canvas.save();
        canvas.translate(card.center.dx - big / 2, card.center.dy - big / 2);
        canvas.drawPath(maumauSuitPath(suit, Size.square(big)), Paint()..color = maumauSuitColor(suit));
        canvas.restore();
        final small = w * 0.18;
        canvas.save();
        canvas.translate(card.left + w * 0.08, card.top + w * 0.08);
        canvas.drawPath(maumauSuitPath(suit, Size.square(small)), Paint()..color = maumauSuitColor(suit));
        canvas.restore();
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(MauMauIllustration old) => old.palette != palette;
}
