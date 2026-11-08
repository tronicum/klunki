import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../transport/game_transport.dart';
import '../../ltr.dart';

/// Shared GoStrategy UI pieces (KLD-058b): localized piece names, square
/// names, the fight description from an event payload, the move history
/// text and the piece tile.

/// Localized name of [p] ("Hauptmann", "Captain", …).
String goPieceName(AppLocalizations l10n, GoPiece p) => switch (p) {
  GoPiece.marshal => l10n.goPieceMarshal,
  GoPiece.general => l10n.goPieceGeneral,
  GoPiece.colonel => l10n.goPieceColonel,
  GoPiece.major => l10n.goPieceMajor,
  GoPiece.captain => l10n.goPieceCaptain,
  GoPiece.lieutenant => l10n.goPieceLieutenant,
  GoPiece.sergeant => l10n.goPieceSergeant,
  GoPiece.miner => l10n.goPieceMiner,
  GoPiece.scout => l10n.goPieceScout,
  GoPiece.spy => l10n.goPieceSpy,
  GoPiece.bomb => l10n.goPieceBomb,
  GoPiece.flag => l10n.goPieceFlag,
};

/// "Hauptmann (6)"; bomb and flag without a rank.
String goPieceLabel(AppLocalizations l10n, GoPiece p) {
  final rank = p.rank;
  return rank == null ? goPieceName(l10n, p) : l10n.goPieceRank(goPieceName(l10n, p), '$rank');
}

/// Square name like the text console: files `a`–`j` left to right, ranks
/// `1`–`10` from X's back row (bottom) to O's back row (top). Square 60 is
/// `a4`, square 0 is `a10`.
String goSquareName(int square) =>
    '${String.fromCharCode(0x61 + GoStrategyGame.colOf(square))}${GoStrategyGame.size - GoStrategyGame.rowOf(square)}';

Player goOther(Player p) => p == Player.a ? Player.b : Player.a;

/// One fight, read from an accepted move's event payload (`fight`). Fights
/// are public: both pieces are revealed to both players.
@immutable
class GoFight {
  final Player attackerPlayer;
  final GoPiece attacker, defender;
  final GoFightOutcome outcome;
  final int from, to;

  const GoFight({
    required this.attackerPlayer,
    required this.attacker,
    required this.defender,
    required this.outcome,
    required this.from,
    required this.to,
  });

  Player get defenderPlayer => goOther(attackerPlayer);

  /// The attacker is removed (lost or both fell).
  bool get attackerFalls => outcome == GoFightOutcome.defenderWins || outcome == GoFightOutcome.bothLose;

  /// The defender is removed (lost, both fell, or the flag was taken).
  bool get defenderFalls => outcome != GoFightOutcome.defenderWins;

  /// The fight of [m], or null for a setup or a quiet move.
  static GoFight? fromMove(AcceptedMove m) {
    final payload = m.event.payload;
    if (payload is! Map) return null;
    final f = payload['fight'];
    if (f is! Map) return null;
    final a = GoPiece.fromId(f['attacker']);
    final d = GoPiece.fromId(f['defender']);
    final o = GoFightOutcome.values.where((x) => x.id == f['outcome']).firstOrNull;
    final from = f['from'] ?? m.move['from'];
    final to = f['to'] ?? m.move['to'];
    if (a == null || d == null || o == null || from is! int || to is! int) return null;
    // The mover is the attacker (also when the payload's player arrives as text).
    return GoFight(attackerPlayer: m.player, attacker: a, defender: d, outcome: o, from: from, to: to);
  }
}

/// "Hauptmann (6) schlägt Leutnant (5)", "Beide fallen",
/// "Mineur (3) entschärft die Bombe", "Fahne erobert!" …
String goFightText(AppLocalizations l10n, GoFight f) {
  final a = goPieceLabel(l10n, f.attacker), d = goPieceLabel(l10n, f.defender);
  return switch (f.outcome) {
    GoFightOutcome.flagCaptured => l10n.goFightFlag,
    GoFightOutcome.bothLose => l10n.goFightBoth,
    GoFightOutcome.attackerWins => f.defender == GoPiece.bomb ? l10n.goFightDefused(a) : l10n.goFightBeats(a, d),
    GoFightOutcome.defenderWins => f.defender == GoPiece.bomb ? l10n.goFightBomb(a) : l10n.goFightBeats(d, a),
  };
}

/// Move history text. Setups never show positions (they are secret).
String describeGoStrategyMove(AppLocalizations l10n, AcceptedMove m) {
  final action = m.move['action'];
  if (action == 'setup' || action == 'autosetup') return l10n.goMoveSetup;
  final from = m.move['from'], to = m.move['to'];
  if (from is! int || to is! int) return m.move.toString();
  final fight = GoFight.fromMove(m);
  // Square names stay LTR inside RTL sentences.
  final f = ltrIsolate(goSquareName(from)), t = ltrIsolate(goSquareName(to));
  if (fight == null) return l10n.goMoveStep(f, t);
  return l10n.goMoveAttack(f, t, goFightText(l10n, fight));
}

/// Keys of the small markers (tests look for them).
const goMovedMarkerKey = Key('go-moved-marker');
const goKnownMarkerKey = Key('go-known-marker');

/// How a known piece shows its rank (KLD-058, insignia step 1). The
/// maintainer picks one of the insignia looks; until then the app keeps
/// [classic]. Switch [goPieceLook] to change the whole game.
enum GoPieceLook {
  /// Rank number in the middle, first letter of the name in a corner.
  classic,

  /// Variant A: the insignia on a small shoulder board, stars and bars gold.
  shoulderBoard,

  /// Variant B: the insignia free on the tile, all in the ink colour.
  insignia,

  /// Variant C: like [insignia], stars, bars and chevrons in gold.
  insigniaGold,
}

/// The look the app uses. KLD-058: stays [GoPieceLook.classic] until the
/// maintainer has chosen from the variant sheet (`kld058-insignia`).
const GoPieceLook goPieceLook = GoPieceLook.classic;

/// Overrides [goPieceLook] below it (screenshots, variant sheet, tests).
class GoPieceLookScope extends InheritedWidget {
  final GoPieceLook look;
  const GoPieceLookScope({super.key, required this.look, required super.child});

  static GoPieceLook of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GoPieceLookScope>()?.look ?? goPieceLook;

  @override
  bool updateShouldNotify(GoPieceLookScope oldWidget) => oldWidget.look != look;
}

/// Gold of stars, bars and chevrons in the gold looks.
const goInsigniaGold = Color(0xFFFFCB45);

/// A piece as a rounded tile in its army's colour. [piece] null shows the
/// blank back of a hidden enemy piece. Known pieces show their rank: in the
/// [GoPieceLook.classic] look the number (bomb and flag a symbol) and the
/// first letter of the localized name; in the insignia looks a drawn rank
/// insignia ([GoInsignia]) and, if [rankNumber], the number small in a corner.
///
/// [moved] adds a subtle dot (an enemy piece that moved is no bomb or flag);
/// [known] a small eye (an own piece the opponent has seen). [look] defaults
/// to [GoPieceLookScope.of].
class GoPieceTile extends StatelessWidget {
  final Player owner;
  final GoPiece? piece;
  final double size;
  final bool moved;
  final bool known;
  final GoPieceLook? look;
  final bool rankNumber;

  const GoPieceTile({
    super.key,
    required this.owner,
    required this.piece,
    required this.size,
    this.moved = false,
    this.known = false,
    this.look,
    this.rankNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = KlunkiPalette.of(context).gostrategy;
    final l10n = AppLocalizations.of(context);
    final color = p.army(owner == Player.a);
    final ink = p.onPiece;
    final kind = piece;
    final look = this.look ?? GoPieceLookScope.of(context);
    final radius = BorderRadius.circular(size * 0.2);
    Widget face;
    if (kind == null) {
      // Blank back with an inset frame and a small diamond emblem.
      face = Center(
        child: Container(
          width: size * 0.62,
          height: size * 0.62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.12),
            border: Border.all(color: ink.withValues(alpha: 0.45), width: math.max(1, size * 0.05)),
          ),
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: size * 0.16, height: size * 0.16, color: ink.withValues(alpha: 0.45)),
          ),
        ),
      );
    } else if (look != GoPieceLook.classic) {
      final rank = kind.rank;
      final number = rankNumber && rank != null;
      // With the number the insignia moves a little down and to the right.
      final box = size * (number ? 0.66 : 0.74);
      final shift = number ? size * 0.08 : 0.0;
      face = Stack(
        children: [
          Positioned(
            left: (size - box) / 2 + shift,
            top: (size - box) / 2 + shift,
            child: GoInsignia(
              piece: kind,
              color: ink,
              size: box,
              accent: look == GoPieceLook.insignia ? null : goInsigniaGold,
              board: look == GoPieceLook.shoulderBoard ? Color.lerp(color, Colors.black, 0.45) : null,
            ),
          ),
          if (number)
            Positioned(
              left: size * 0.08,
              top: size * 0.03,
              child: Text(
                '$rank',
                textDirection: TextDirection.ltr,
                style: TextStyle(color: ink, fontSize: size * 0.27, fontWeight: FontWeight.w800, height: 1.05),
              ),
            ),
        ],
      );
    } else {
      final rank = kind.rank;
      final Widget center = switch (kind) {
        GoPiece.bomb => CustomPaint(size: Size.square(size * 0.56), painter: GoBombPainter(ink)),
        GoPiece.flag => Icon(Icons.flag, size: size * 0.58, color: ink),
        _ => Text(
          '$rank',
          textDirection: TextDirection.ltr,
          style: TextStyle(color: ink, fontSize: size * 0.44, fontWeight: FontWeight.w800, height: 1),
        ),
      };
      final name = goPieceName(l10n, kind);
      face = Stack(
        children: [
          Center(child: center),
          if (rank != null && size >= 26)
            Positioned(
              left: size * 0.09,
              top: size * 0.04,
              child: Text(
                name.characters.first,
                style: TextStyle(
                  color: ink.withValues(alpha: 0.85),
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
        ],
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.18)!, color],
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.35), width: math.max(0.5, size * 0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: size * 0.06,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: face),
          if (moved && kind == null)
            Positioned(
              key: goMovedMarkerKey,
              right: size * 0.1,
              top: size * 0.1,
              child: Container(
                width: size * 0.16,
                height: size * 0.16,
                decoration: BoxDecoration(shape: BoxShape.circle, color: ink.withValues(alpha: 0.9)),
              ),
            ),
          if (known && kind != null && size >= 26)
            Positioned(
              key: goKnownMarkerKey,
              right: size * 0.06,
              bottom: size * 0.04,
              child: Icon(Icons.visibility, size: size * 0.24, color: ink.withValues(alpha: 0.8)),
            ),
        ],
      ),
    );
  }
}

/// The rank insignia of [piece] (KLD-058), drawn by [GoInsigniaPainter] in a
/// [size] square: crossed batons (Marschall), peaked cap (General), three,
/// two, one star (Oberst, Major, Hauptmann), a bar (Leutnant), chevrons
/// (Feldwebel), pickaxe (Mineur), binoculars (Späher), mask (Spion). Bomb
/// and flag are the usual symbols. [color] is the ink; [accent] (null: ink)
/// colours stars, bars, chevrons and small details; [board] (null: none)
/// puts the insignia on a shoulder board of that colour. Holes (lenses, eye
/// holes) show what lies beneath, so it works on any background (rules pages).
class GoInsignia extends StatelessWidget {
  final GoPiece piece;
  final Color color;
  final double size;
  final Color? accent;
  final Color? board;

  const GoInsignia({super.key, required this.piece, required this.color, required this.size, this.accent, this.board});

  @override
  Widget build(BuildContext context) {
    if (piece == GoPiece.flag) {
      return SizedBox.square(
        dimension: size,
        child: Center(
          child: Icon(Icons.flag, size: size * 0.8, color: color),
        ),
      );
    }
    if (piece == GoPiece.bomb) {
      return SizedBox.square(
        dimension: size,
        child: Center(
          child: CustomPaint(size: Size.square(size * 0.78), painter: GoBombPainter(color)),
        ),
      );
    }
    return CustomPaint(
      size: Size.square(size),
      painter: GoInsigniaPainter(piece: piece, ink: color, accent: accent, board: board),
    );
  }
}

/// Paints a rank insignia (see [GoInsignia]) in unit coordinates scaled to
/// the canvas. Below about 44 px small details (oak leaves on the cap) are left
/// out so the shapes stay readable on the board.
class GoInsigniaPainter extends CustomPainter {
  final GoPiece piece;
  final Color ink;
  final Color? accent;
  final Color? board;

  const GoInsigniaPainter({required this.piece, required this.ink, this.accent, this.board});

  static final Paint _clear = Paint()..blendMode = BlendMode.clear;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (s <= 0) return;
    final detail = s >= 44;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    canvas.scale(s);
    final bounds = const Rect.fromLTWH(-0.1, -0.1, 1.2, 1.2);
    final boardColor = board;
    final starsOnBoard =
        boardColor != null && (piece == GoPiece.colonel || piece == GoPiece.major || piece == GoPiece.captain);
    var unit = s;
    if (boardColor != null) {
      _shoulderBoard(canvas, boardColor, s);
      if (!starsOnBoard) {
        // The insignia sits on the board below the button.
        canvas.translate(0.24, 0.32);
        canvas.scale(0.52);
        unit = s * 0.52;
      }
    }
    canvas.saveLayer(bounds, Paint());
    final fill = Paint()..color = ink;
    final gold = accent;
    if (starsOnBoard) {
      // Stars stack along the board.
      _boardStars(canvas, piece.rank! - 5, s);
      canvas.restore();
      canvas.restore();
      return;
    }
    switch (piece) {
      case GoPiece.marshal:
        _batons(canvas, gold);
      case GoPiece.general:
        _cap(canvas, fill, gold, detail);
      case GoPiece.colonel:
        _stars(canvas, const [(0.5, 0.27), (0.24, 0.71), (0.76, 0.71)], 0.235, gold, unit);
      case GoPiece.major:
        _stars(canvas, const [(0.25, 0.52), (0.75, 0.52)], 0.25, gold, unit);
      case GoPiece.captain:
        _stars(canvas, const [(0.5, 0.53)], 0.4, gold, unit);
      case GoPiece.lieutenant:
        _accentShape(
          canvas,
          Path()..addRRect(RRect.fromLTRBR(0.1, 0.38, 0.9, 0.64, const Radius.circular(0.05))),
          gold,
          unit,
        );
      case GoPiece.sergeant:
        _chevrons(canvas, gold, unit);
      case GoPiece.miner:
        _pickaxe(canvas, fill);
      case GoPiece.scout:
        _binoculars(canvas, fill);
      case GoPiece.spy:
        _mask(canvas, fill);
      case GoPiece.bomb:
      case GoPiece.flag:
        break; // drawn by [GoInsignia]
    }
    canvas.restore();
    canvas.restore();
  }

  /// A shoulder board: a strap with a pointed upper end and a button.
  void _shoulderBoard(Canvas canvas, Color color, double s) {
    final path = Path()
      ..moveTo(0.22, 0.97)
      ..lineTo(0.22, 0.24)
      ..quadraticBezierTo(0.22, 0.17, 0.3, 0.13)
      ..lineTo(0.5, 0.03)
      ..lineTo(0.7, 0.13)
      ..quadraticBezierTo(0.78, 0.17, 0.78, 0.24)
      ..lineTo(0.78, 0.97)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = ink.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.035, 1 / s),
    );
    canvas.drawCircle(const Offset(0.5, 0.19), 0.055, Paint()..color = accent ?? ink);
  }

  /// [n] stars stacked on the shoulder board.
  void _boardStars(Canvas canvas, int n, double s) {
    final ys = switch (n) {
      1 => [0.6],
      2 => [0.45, 0.76],
      _ => [0.38, 0.6, 0.82],
    };
    final r = n == 3 ? 0.13 : 0.16;
    _stars(canvas, [for (final y in ys) (0.5, y)], r, accent, s);
  }

  Paint _accentPaint(Color? gold) => Paint()..color = gold ?? ink;

  /// Fills [path] in the accent; gold gets a thin dark edge so it reads on red.
  void _accentShape(Canvas canvas, Path path, Color? gold, double s) {
    canvas.drawPath(path, _accentPaint(gold));
    if (gold != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.025, 0.8 / s),
      );
    }
  }

  static Path _star(double cx, double cy, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.48;
      final x = cx + rr * math.cos(a), y = cy + rr * math.sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  void _stars(Canvas canvas, List<(double, double)> at, double r, Color? gold, double s) {
    final path = Path();
    for (final (x, y) in at) {
      path.addPath(_star(x, y, r), Offset.zero);
    }
    _accentShape(canvas, path, gold, s);
  }

  void _chevrons(Canvas canvas, Color? gold, double s) {
    final path = Path();
    for (var i = 0; i < 3; i++) {
      final y = 0.14 + i * 0.25;
      // One chevron pointing up, as a filled band 0.14 thick.
      path
        ..moveTo(0.08, y + 0.3)
        ..lineTo(0.5, y)
        ..lineTo(0.92, y + 0.3)
        ..lineTo(0.92, y + 0.44)
        ..lineTo(0.5, y + 0.15)
        ..lineTo(0.08, y + 0.44)
        ..close();
    }
    canvas.save();
    canvas.translate(0.5, 0.5);
    canvas.scale(0.95, 0.82);
    canvas.translate(-0.5, -0.56);
    _accentShape(canvas, path, gold, s);
    canvas.restore();
  }

  /// Two crossed batons with end bands.
  void _batons(Canvas canvas, Color? gold) {
    const w = 0.15;
    void baton(Offset a, Offset b) {
      final stick = Paint()
        ..color = ink
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, stick);
      // End caps in the accent, separated by a thin gap.
      final d = (b - a) / (b - a).distance;
      for (final (end, dir) in [(a, d), (b, -d)]) {
        final cut = end + dir * 0.17;
        final n = Offset(-dir.dy, dir.dx) * (w * 0.75);
        canvas.drawLine(
          cut - n,
          cut + n,
          Paint()
            ..blendMode = BlendMode.clear
            ..strokeWidth = 0.045,
        );
        if (gold != null) {
          canvas.drawLine(
            end,
            end + dir * 0.13,
            Paint()
              ..color = gold
              ..strokeWidth = w
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    // Ends kept off the corners: the upper left one clears the number.
    baton(const Offset(0.12, 0.9), const Offset(0.9, 0.12));
    // A gap around the second baton so the two read as separate sticks.
    canvas.drawLine(
      const Offset(0.18, 0.18),
      const Offset(0.9, 0.9),
      Paint()
        ..blendMode = BlendMode.clear
        ..strokeWidth = w + 0.09
        ..strokeCap = StrokeCap.round,
    );
    baton(const Offset(0.18, 0.18), const Offset(0.9, 0.9));
  }

  /// A peaked cap seen from the front: crown, band, visor, badge; oak
  /// leaves on the visor when large.
  void _cap(Canvas canvas, Paint fill, Color? gold, bool detail) {
    final crown = Path()
      ..moveTo(0.2, 0.6)
      ..lineTo(0.03, 0.38)
      ..quadraticBezierTo(0.02, 0.18, 0.5, 0.14)
      ..quadraticBezierTo(0.98, 0.18, 0.97, 0.38)
      ..lineTo(0.8, 0.6)
      ..close();
    canvas.drawPath(crown, fill);
    canvas.drawRect(const Rect.fromLTRB(0.2, 0.58, 0.8, 0.73), fill);
    // Gaps between crown and band and between band and visor.
    final gap = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 0.05;
    canvas.drawLine(const Offset(0.1, 0.585), const Offset(0.9, 0.585), gap);
    final visor = Path()
      ..moveTo(0.14, 0.77)
      ..quadraticBezierTo(0.5, 0.71, 0.86, 0.77)
      ..quadraticBezierTo(0.5, 1.0, 0.14, 0.77)
      ..close();
    canvas.drawPath(visor, fill);
    // Badge on the crown: a cleared ring around an accent dot.
    canvas.drawCircle(const Offset(0.5, 0.4), 0.12, _clear);
    canvas.drawCircle(const Offset(0.5, 0.4), 0.075, _accentPaint(gold));
    if (detail) {
      final leaf = gold == null ? _clear : (Paint()..color = gold);
      for (final x in [0.3, 0.42, 0.58, 0.7]) {
        canvas.save();
        canvas.translate(x, 0.82);
        canvas.rotate(x < 0.5 ? -0.5 : 0.5);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 0.1, height: 0.05), leaf);
        canvas.restore();
      }
    }
  }

  /// A pickaxe, tilted: curved head across a handle.
  void _pickaxe(Canvas canvas, Paint fill) {
    canvas.save();
    canvas.translate(0.5, 0.5);
    canvas.rotate(-math.pi / 5);
    canvas.translate(-0.5, -0.5);
    canvas.drawRRect(RRect.fromLTRBR(0.43, 0.24, 0.57, 1.0, const Radius.circular(0.05)), fill);
    final head = Path()
      ..moveTo(0.0, 0.5)
      ..quadraticBezierTo(0.5, -0.16, 1.0, 0.5)
      ..quadraticBezierTo(0.5, 0.2, 0.0, 0.5)
      ..close();
    canvas.drawPath(head, fill);
    canvas.restore();
  }

  /// Binoculars from the front: two barrels with lenses and a bridge.
  void _binoculars(Canvas canvas, Paint fill) {
    for (final x in [0.27, 0.73]) {
      canvas.drawRRect(RRect.fromLTRBR(x - 0.13, 0.12, x + 0.13, 0.64, const Radius.circular(0.06)), fill);
      canvas.drawCircle(Offset(x, 0.67), 0.24, fill);
    }
    canvas.drawRect(const Rect.fromLTRB(0.35, 0.3, 0.65, 0.46), fill);
    // Gap between the two barrels, then the lenses.
    for (final x in [0.27, 0.73]) {
      canvas.drawCircle(Offset(x, 0.68), 0.11, _clear);
    }
  }

  /// A brimmed hat over a domino mask with two eye holes.
  void _mask(Canvas canvas, Paint fill) {
    final hat = Path()
      ..moveTo(0.24, 0.36)
      ..lineTo(0.3, 0.08)
      ..quadraticBezierTo(0.5, 0.0, 0.7, 0.08)
      ..lineTo(0.76, 0.36)
      ..close();
    canvas.drawPath(hat, fill);
    // Dent in the crown and a gap above the band.
    canvas.drawLine(
      const Offset(0.5, 0.06),
      const Offset(0.5, 0.14),
      Paint()
        ..blendMode = BlendMode.clear
        ..strokeWidth = 0.06
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(0.2, 0.26),
      const Offset(0.8, 0.26),
      Paint()
        ..blendMode = BlendMode.clear
        ..strokeWidth = 0.045,
    );
    canvas.drawOval(const Rect.fromLTRB(0.02, 0.32, 0.98, 0.46), fill);
    final mask = Path()
      ..moveTo(0.5, 0.58)
      ..cubicTo(0.38, 0.52, 0.12, 0.5, 0.06, 0.6)
      ..cubicTo(0.02, 0.74, 0.12, 0.9, 0.3, 0.9)
      ..cubicTo(0.42, 0.9, 0.45, 0.8, 0.5, 0.8)
      ..cubicTo(0.55, 0.8, 0.58, 0.9, 0.7, 0.9)
      ..cubicTo(0.88, 0.9, 0.98, 0.74, 0.94, 0.6)
      ..cubicTo(0.88, 0.5, 0.62, 0.52, 0.5, 0.58)
      ..close();
    canvas.drawPath(mask, fill);
    for (final x in [0.29, 0.71]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, 0.7), width: 0.22, height: 0.12), _clear);
    }
  }

  @override
  bool shouldRepaint(GoInsigniaPainter oldDelegate) =>
      oldDelegate.piece != piece ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent ||
      oldDelegate.board != board;
}

/// A round bomb with a fuse and a spark.
class GoBombPainter extends CustomPainter {
  final Color color;
  const GoBombPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width * 0.45, size.height * 0.58);
    final r = s * 0.34;
    canvas.drawCircle(c, r, Paint()..color = color);
    final neck = Rect.fromCenter(center: c + Offset(r * 0.62, -r * 0.62), width: r * 0.5, height: r * 0.5);
    canvas.save();
    canvas.translate(neck.center.dx, neck.center.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 0.5, height: r * 0.4), Paint()..color = color);
    canvas.restore();
    final fuse = Path()
      ..moveTo(neck.center.dx + r * 0.15, neck.center.dy - r * 0.15)
      ..quadraticBezierTo(c.dx + r * 1.2, c.dy - r * 1.6, c.dx + r * 1.35, c.dy - r * 1.25);
    canvas.drawPath(
      fuse,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, s * 0.06)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(c.dx + r * 1.35, c.dy - r * 1.25), s * 0.07, Paint()..color = const Color(0xFFFFC233));
  }

  @override
  bool shouldRepaint(GoBombPainter old) => old.color != color;
}
