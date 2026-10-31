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

/// A piece as a rounded tile in its army's colour. [piece] null shows the
/// blank back of a hidden enemy piece. Known pieces show the rank number
/// (bomb and flag a symbol) and the first letter of the localized name.
///
/// [moved] adds a subtle dot (an enemy piece that moved is no bomb or flag);
/// [known] a small eye (an own piece the opponent has seen).
class GoPieceTile extends StatelessWidget {
  final Player owner;
  final GoPiece? piece;
  final double size;
  final bool moved;
  final bool known;

  const GoPieceTile({
    super.key,
    required this.owner,
    required this.piece,
    required this.size,
    this.moved = false,
    this.known = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = KlunkiPalette.of(context).gostrategy;
    final l10n = AppLocalizations.of(context);
    final color = p.army(owner == Player.a);
    final ink = p.onPiece;
    final kind = piece;
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: size * 0.06, offset: Offset(0, size * 0.04))],
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
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(c.dx + r * 1.35, c.dy - r * 1.25), s * 0.07, Paint()..color = const Color(0xFFFFC233));
  }

  @override
  bool shouldRepaint(GoBombPainter old) => old.color != color;
}
