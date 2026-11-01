import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';

/// Chess pieces drawn in code (KLD-059 step 2): Staunton-like silhouettes as
/// [Path]s in a 100 × 100 box, filled and outlined in the side's colours of
/// the [ChessPalette]. No font glyphs (U+2654–265F are not in the bundled
/// fonts, render as emoji on some platforms, and the PWA must not fetch a
/// fallback font) and no image assets.
class ChessPiecePainter extends CustomPainter {
  final ChessPieceType type;
  final bool white;
  final ChessPalette colors;

  const ChessPiecePainter({required this.type, required this.white, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);
    final fill = Paint()..color = white ? colors.whiteFill : colors.blackFill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = white ? colors.whiteLine : colors.blackLine;
    final detailColor = white ? colors.whiteLine : colors.blackDetail;
    final detail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = detailColor;
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.22);

    final parts = _parts(type);
    // A soft drop shadow under the whole piece, then each part filled and
    // outlined back to front.
    for (final p in parts) {
      canvas.drawPath(p.shift(const Offset(1.6, 2.2)), shadow);
    }
    for (final p in parts) {
      canvas.drawPath(p, fill);
      canvas.drawPath(p, line);
    }
    _details(canvas, type, detail, Paint()..color = detailColor);
    canvas.restore();
  }

  static RRect _r(double l, double t, double r, double b, [double radius = 3]) =>
      RRect.fromLTRBR(l, t, r, b, Radius.circular(radius));

  static Path _base() => Path()..addRRect(_r(21, 80, 79, 90));

  /// The outlined parts of a piece, back to front.
  static List<Path> _parts(ChessPieceType type) {
    switch (type) {
      case ChessPieceType.pawn:
        return [
          Path()
            ..moveTo(29, 81)
            ..cubicTo(29, 68, 41, 63, 43, 55)
            ..lineTo(57, 55)
            ..cubicTo(59, 63, 71, 68, 71, 81)
            ..close(),
          Path()..addRRect(_r(35, 47, 65, 55)),
          Path()..addOval(Rect.fromCircle(center: const Offset(50, 34), radius: 13)),
          _base(),
        ];
      case ChessPieceType.rook:
        return [
          Path()
            ..moveTo(32, 74)
            ..lineTo(35, 41)
            ..lineTo(65, 41)
            ..lineTo(68, 74)
            ..close(),
          Path()
            ..moveTo(27, 42)
            ..lineTo(27, 17)
            ..lineTo(36.5, 17)
            ..lineTo(36.5, 24)
            ..lineTo(45.3, 24)
            ..lineTo(45.3, 17)
            ..lineTo(54.7, 17)
            ..lineTo(54.7, 24)
            ..lineTo(63.5, 24)
            ..lineTo(63.5, 17)
            ..lineTo(73, 17)
            ..lineTo(73, 42)
            ..close(),
          Path()..addRRect(_r(27, 72, 73, 81, 2)),
          _base(),
        ];
      case ChessPieceType.knight:
        return [
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
          _base(),
        ];
      case ChessPieceType.bishop:
        return [
          Path()
            ..moveTo(31, 81)
            ..cubicTo(36, 76, 40, 72, 41, 68)
            ..lineTo(59, 68)
            ..cubicTo(60, 72, 64, 76, 69, 81)
            ..close(),
          Path()..addRRect(_r(36, 61, 64, 69)),
          Path()
            ..moveTo(50, 18)
            ..cubicTo(63, 27, 70, 41, 64, 53)
            ..cubicTo(61, 59, 56, 61, 50, 61)
            ..cubicTo(44, 61, 39, 59, 36, 53)
            ..cubicTo(30, 41, 37, 27, 50, 18)
            ..close(),
          Path()..addOval(Rect.fromCircle(center: const Offset(50, 13), radius: 5)),
          _base(),
        ];
      case ChessPieceType.queen:
        return [
          Path()
            ..moveTo(27, 73)
            ..lineTo(15, 34)
            ..lineTo(34, 56)
            ..lineTo(35, 28)
            ..lineTo(45, 54)
            ..lineTo(50, 23)
            ..lineTo(55, 54)
            ..lineTo(65, 28)
            ..lineTo(66, 56)
            ..lineTo(85, 34)
            ..lineTo(73, 73)
            ..close(),
          for (final (x, y, r) in const [(15.0, 31.0, 5.0), (35.0, 25.0, 5.0), (50.0, 19.0, 5.5), (65.0, 25.0, 5.0), (85.0, 31.0, 5.0)])
            Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r)),
          Path()..addRRect(_r(27, 71, 73, 80, 2)),
          _base(),
        ];
      case ChessPieceType.king:
        return [
          Path.combine(
            PathOperation.union,
            Path()..addRect(const Rect.fromLTRB(46.5, 8, 53.5, 33)),
            Path()..addRect(const Rect.fromLTRB(40.5, 14, 59.5, 21)),
          ),
          Path()
            ..moveTo(29, 73)
            ..cubicTo(13, 60, 17, 37, 36, 41)
            ..cubicTo(43, 42, 48, 47, 50, 53)
            ..cubicTo(52, 47, 57, 42, 64, 41)
            ..cubicTo(83, 37, 87, 60, 71, 73)
            ..close(),
          Path()
            ..moveTo(41, 62)
            ..cubicTo(40, 45, 45, 36, 50, 33)
            ..cubicTo(55, 36, 60, 45, 59, 62)
            ..close(),
          Path()..addRRect(_r(27, 71, 73, 80, 2)),
          _base(),
        ];
    }
  }

  /// Inner lines (light on the black pieces) that make the shapes read as
  /// carved pieces: the rook's battlement line, the bishop's slit, the
  /// knight's eye, nostril and mane.
  static void _details(Canvas canvas, ChessPieceType type, Paint line, Paint dot) {
    switch (type) {
      case ChessPieceType.rook:
        canvas.drawLine(const Offset(31, 34), const Offset(69, 34), line);
      case ChessPieceType.bishop:
        canvas.drawLine(const Offset(57, 29), const Offset(47, 44), line);
      case ChessPieceType.knight:
        canvas.drawCircle(const Offset(41, 31), 3, dot);
        canvas.drawCircle(const Offset(22, 50), 1.8, dot);
        canvas.drawPath(
            Path()
              ..moveTo(61, 24)
              ..cubicTo(70, 33, 73, 50, 71, 72),
            line);
      case ChessPieceType.queen:
      case ChessPieceType.king:
        canvas.drawLine(const Offset(31, 66), const Offset(69, 66), line);
      case ChessPieceType.pawn:
        break;
    }
  }

  @override
  bool shouldRepaint(ChessPiecePainter old) => old.type != type || old.white != white || old.colors != colors;
}

/// A chess piece as a widget of [size] (square), drawn by [ChessPiecePainter].
class ChessPieceIcon extends StatelessWidget {
  final ChessPiece piece;
  final double size;

  const ChessPieceIcon({super.key, required this.piece, required this.size});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: ChessPiecePainter(
            type: piece.type,
            white: piece.isWhite,
            colors: KlunkiPalette.of(context).chess,
          ),
        ),
      );
}

/// Localized piece name ("Dame").
String chessPieceName(AppLocalizations l10n, ChessPieceType t) => switch (t) {
      ChessPieceType.pawn => l10n.chessPiecePawn,
      ChessPieceType.knight => l10n.chessPieceKnight,
      ChessPieceType.bishop => l10n.chessPieceBishop,
      ChessPieceType.rook => l10n.chessPieceRook,
      ChessPieceType.queen => l10n.chessPieceQueen,
      ChessPieceType.king => l10n.chessPieceKing,
    };

/// Localized side name: "Weiß" (player A) / "Schwarz" (player B).
String chessSideName(AppLocalizations l10n, Player p) => p == Player.a ? l10n.chessWhite : l10n.chessBlack;

/// Material value for the captured-pieces balance.
int chessPieceValue(ChessPieceType t) => switch (t) {
      ChessPieceType.pawn => 1,
      ChessPieceType.knight || ChessPieceType.bishop => 3,
      ChessPieceType.rook => 5,
      ChessPieceType.queen => 9,
      ChessPieceType.king => 0,
    };

/// The piece type of a FEN letter (either case), null for anything else.
ChessPieceType? chessPieceTypeOf(Object? letter) {
  if (letter is! String) return null;
  final l = letter.toLowerCase();
  for (final t in ChessPieceType.values) {
    if (t.letter == l) return t;
  }
  return null;
}
