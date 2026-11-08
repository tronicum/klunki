import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

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
const goRankBadgeKey = Key('go-rank-badge');

/// Dark grey edge around the white insignia and the badges (KLD-058), so
/// the white shapes keep a border against the army colour.
const goInsigniaEdge = Color(0xFF3C3C3C);

/// Edge width for a tile or insignia of [size] px: 3 % of it, 0.8–1.5 px.
double goInsigniaEdgeWidth(double size) => (size * 0.03).clamp(0.8, 1.5);

/// A piece as a rounded tile in its army's colour. [piece] null shows the
/// blank back of a hidden enemy piece. Known pieces show their rank insignia
/// ([GoInsigniaPainter]) centred in the tile as if there were no badges, the
/// rank number in a small badge in the top left corner drawn over it.
///
/// [moved] adds a subtle dot (an enemy piece that moved is no bomb or flag);
/// [known] a small eye badge top right (an own piece the opponent has seen).
/// [badges] false leaves out number and eye (the small 22–24 px tiles of the
/// setup legend and the armies panel, where name or count stand next to them).
class GoPieceTile extends StatelessWidget {
  final Player owner;
  final GoPiece? piece;
  final double size;
  final bool moved;
  final bool known;
  final bool badges;

  const GoPieceTile({
    super.key,
    required this.owner,
    required this.piece,
    required this.size,
    this.moved = false,
    this.known = false,
    this.badges = true,
  });

  /// The insignia's area in tile units: centred, equal margins on all sides.
  static const insigniaArea = Rect.fromLTRB(0.14, 0.14, 0.86, 0.86);

  /// Badge height and its inset from the tile's top corners, in tile units.
  static const badgeSize = 0.3, badgeInset = 0.05;

  @override
  Widget build(BuildContext context) {
    final p = KlunkiPalette.of(context).gostrategy;
    final color = p.army(owner == Player.a);
    final ink = p.onPiece;
    final kind = piece;
    final rank = kind?.rank;
    final radius = BorderRadius.circular(size * 0.2);
    final edgeWidth = goInsigniaEdgeWidth(size);
    final b = size * badgeSize, inset = size * badgeInset;
    // A small rounded box in a darker army colour with the thin grey edge,
    // fully inside the tile, over the insignia.
    Widget badge(Widget child) => Container(
      height: b,
      constraints: BoxConstraints(minWidth: b),
      padding: EdgeInsets.symmetric(horizontal: b * 0.14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.black, 0.3),
        borderRadius: BorderRadius.circular(b / 2),
        border: Border.all(color: goInsigniaEdge, width: edgeWidth),
      ),
      child: child,
    );
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
          if (kind == null)
            // Blank back with an inset frame and a small diamond emblem.
            Center(
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
            )
          else
            Positioned(
              left: insigniaArea.left * size,
              top: insigniaArea.top * size,
              width: insigniaArea.width * size,
              height: insigniaArea.height * size,
              child: CustomPaint(
                painter: GoInsigniaPainter(piece: kind, ink: ink, edge: goInsigniaEdge, edgeWidth: edgeWidth),
              ),
            ),
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
          if (badges && rank != null)
            Positioned(
              key: goRankBadgeKey,
              left: inset,
              top: inset,
              child: badge(
                Text(
                  '$rank',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: ink, fontSize: b * 0.72, fontWeight: FontWeight.w800, height: 1),
                ),
              ),
            ),
          if (badges && known && kind != null)
            Positioned(
              key: goKnownMarkerKey,
              right: inset,
              top: inset,
              child: badge(Icon(Icons.visibility, size: b * 0.68, color: ink)),
            ),
        ],
      ),
    );
  }
}

/// The rank insignia of [piece] (KLD-058) in a [size] square, drawn by
/// [GoInsigniaPainter]: crossed batons (Marschall), peaked cap (General),
/// three, two, one star (Oberst, Major, Hauptmann), a bar (Leutnant),
/// chevrons (Feldwebel), pickaxe (Mineur), binoculars (Aufklärer), hat and mask
/// (Spion); bomb and flag are the usual symbols. [color] is the ink, [edge]
/// (null: none) the thin outline. Holes (lenses, eye holes) show what lies
/// beneath, so it works on any background (rules pages).
class GoInsignia extends StatelessWidget {
  final GoPiece piece;
  final Color color;
  final double size;
  final Color? edge;

  const GoInsignia({
    super.key,
    required this.piece,
    required this.color,
    required this.size,
    this.edge = goInsigniaEdge,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: GoInsigniaPainter(piece: piece, ink: color, edge: edge, edgeWidth: goInsigniaEdgeWidth(size)),
  );
}

/// Paints a rank insignia (see [GoInsignia]) exactly centred in its canvas
/// (the centre of its bounding box on the canvas centre).
///
/// Consistent weight: every picture (batons, cap, pickaxe, binoculars, hat
/// and mask, single star, bomb, flag) has the same height `u`; the two- and
/// three-star groups share one star size; chevrons have one stroke width. `u`
/// is the canvas height, or its width / 1.15 when that is less; wider
/// pictures (the cap, the bar) shrink to fit the width.
///
/// [edge]: a thin outline of that colour, [edgeWidth] px wide, around the
/// whole insignia (holes included).
class GoInsigniaPainter extends CustomPainter {
  final GoPiece piece;
  final Color ink;
  final Color? edge;
  final double edgeWidth;

  const GoInsigniaPainter({required this.piece, required this.ink, this.edge, this.edgeWidth = 1});

  static final Paint _clear = Paint()..blendMode = BlendMode.clear;

  /// Star radius, star spacing, stroke of the chevrons, in units of `u`.
  static const _starR = 0.32, _starStep = 0.68, _stroke = 0.18;

  /// The single star (Hauptmann) to a star of the two- and three-star
  /// groups.
  static const _singleStar = 1.35;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final e = edge;
    if (e != null) {
      // The insignia once more below itself, grown by the edge width and
      // tinted: an outline that also rings the holes.
      final r = edgeWidth;
      canvas.saveLayer(
        (Offset.zero & size).inflate(r * 3),
        Paint()
          ..imageFilter = ui.ImageFilter.dilate(radiusX: r, radiusY: r)
          ..colorFilter = ColorFilter.mode(e, BlendMode.srcIn),
      );
      _paintInsignia(canvas, size);
      canvas.restore();
    }
    _paintInsignia(canvas, size);
  }

  void _paintInsignia(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    final u = math.min(area.height, area.width / 1.15);
    if (u <= 0) return;
    switch (piece) {
      case GoPiece.bomb:
        // GoBombPainter's drawing spans about 0.82 of its box, centred at (0.54, 0.51).
        final b = u / 0.82;
        canvas.save();
        canvas.translate(area.center.dx - 0.54 * b, area.center.dy - 0.51 * b);
        GoBombPainter(ink).paint(canvas, Size.square(b));
        canvas.restore();
        return;
      case GoPiece.flag:
        // The flag glyph spans 17/24 of the font size, centred 0.5/24 low.
        final fs = u / 0.71;
        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.flag.codePoint),
            style: TextStyle(
              fontFamily: Icons.flag.fontFamily,
              package: Icons.flag.fontPackage,
              fontSize: fs,
              color: ink,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, area.center - Offset(tp.width / 2, tp.height / 2 + fs * 0.5 / 24));
        tp.dispose();
        return;
      default:
    }
    canvas.saveLayer(area.inflate(u * 0.2), Paint());
    final detail = u >= 30;
    switch (piece) {
      case GoPiece.marshal:
        _batons(canvas, area, u);
      case GoPiece.general:
        _cap(canvas, area, u, detail);
      case GoPiece.colonel:
        _stars(canvas, area, u, const [(0, 0), (-0.5, 1), (0.5, 1)]);
      case GoPiece.major:
        _stars(canvas, area, u, const [(-0.5, 0), (0.5, 0)]);
      case GoPiece.captain:
        // Alone, the star is a little bigger than one of a group (about
        // midway between that and filling the area; maintainer, v6).
        _fill(canvas, _star(0, 0, _starR), area, _singleStar * _starScale(area, u));
      case GoPiece.lieutenant:
        // Alone, the bar is longer and thicker than a chevron stroke.
        final bar = Path()..addRRect(RRect.fromLTRBR(0, 0, 1.2, 0.3, const Radius.circular(0.04)));
        _fill(canvas, bar, area, u);
      case GoPiece.sergeant:
        _chevrons(canvas, area, u);
      case GoPiece.miner:
        _pickaxe(canvas, area, u);
      case GoPiece.scout:
        _binoculars(canvas, area, u);
      case GoPiece.spy:
        _spy(canvas, area, u);
      case GoPiece.bomb:
      case GoPiece.flag:
        break;
    }
    canvas.restore();
  }

  /// Moves the canvas so [bounds] (in drawing units) is centred in [area] at
  /// [scale] pixels per unit (less if it would not fit). Leaves one
  /// canvas.save() open: the caller draws, then [Canvas.restore].
  void _place(Canvas canvas, Rect area, Rect bounds, double scale) {
    final s = math.min(scale, math.min(area.width / bounds.width, area.height / bounds.height));
    canvas.save();
    canvas.translate(area.center.dx, area.center.dy);
    canvas.scale(s);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
  }

  /// [path] at [scale] pixels per unit, centred.
  void _fill(Canvas canvas, Path path, Rect area, double scale) {
    _place(canvas, area, path.getBounds(), scale);
    canvas.drawPath(path, Paint()..color = ink);
    canvas.restore();
  }

  /// A picture scaled to height [u], centred; [draw] adds holes and details.
  void _picture(Canvas canvas, Rect area, double u, Path path, [void Function()? draw]) {
    final bounds = path.getBounds();
    _place(canvas, area, bounds, u / bounds.height);
    canvas.drawPath(path, Paint()..color = ink);
    draw?.call();
    canvas.restore();
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

  /// Stars of one size at grid [cells] (column offset, row), centred. The
  /// scale is that of the three-star triangle (1.29 × 1.0 units), so two and
  /// three stars are the same size. The triangle is nested: the top star
  /// sits between the two below.
  void _stars(Canvas canvas, Rect area, double u, List<(double, int)> cells) {
    final path = Path();
    for (final (col, row) in cells) {
      path.addPath(_star(col * _starStep, row * 0.42, _starR), Offset.zero);
    }
    _fill(canvas, path, area, _starScale(area, u));
  }

  /// Pixels per unit of the star groups (see [_stars]).
  static double _starScale(Rect area, double u) => math.min(u, math.min(area.width / 1.29, area.height / 1.0));

  /// Three chevrons pointing up, stroke [_stroke], one unit wide.
  void _chevrons(Canvas canvas, Rect area, double u) {
    const rise = 0.18, half = 0.5;
    final v = _stroke / math.cos(math.atan(rise / half)); // vertical band height
    const gap = 0.12;
    final path = Path();
    for (var i = 0; i < 3; i++) {
      final y = i * (v + gap);
      path
        ..moveTo(0, y + rise)
        ..lineTo(half, y)
        ..lineTo(2 * half, y + rise)
        ..lineTo(2 * half, y + rise + v)
        ..lineTo(half, y + v)
        ..lineTo(0, y + rise + v)
        ..close();
    }
    _fill(canvas, path, area, u);
  }

  /// [p] turned by [angle] around [c].
  static Path _turned(Path p, double angle, Offset c) {
    final cs = math.cos(angle), sn = math.sin(angle);
    final m = Float64List.fromList([
      cs, sn, 0, 0, //
      -sn, cs, 0, 0,
      0, 0, 1, 0,
      c.dx - cs * c.dx + sn * c.dy, c.dy - sn * c.dx - cs * c.dy, 0, 1,
    ]);
    return p.transform(m);
  }

  /// Two crossed batons with end bands, symmetric about the centre.
  void _batons(Canvas canvas, Rect area, double u) {
    const len = 1.2, w = 0.2, c = Offset(0.6, 0.6);
    final stick = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: len, height: w), const Radius.circular(w / 2)),
      );
    final a = _turned(stick, -math.pi / 4, c), b = _turned(stick, math.pi / 4, c);
    final bounds = a.getBounds().expandToInclude(b.getBounds());
    _place(canvas, area, bounds, u / bounds.height);
    void ends(double angle) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      for (final dir in [-1.0, 1.0]) {
        // A thin gap sets the end band off.
        canvas.drawRect(
          Rect.fromCenter(center: Offset(dir * (len / 2 - 0.2), 0), width: 0.05, height: w * 1.2),
          _clear,
        );
      }
      canvas.restore();
    }

    canvas.drawPath(a, Paint()..color = ink);
    ends(-math.pi / 4);
    // A gap around the second baton so the two read as separate sticks.
    canvas.drawPath(
      b,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.1,
    );
    canvas.drawPath(b, Paint()..color = ink);
    ends(math.pi / 4);
    canvas.restore();
  }

  /// A peaked cap from the front: crown, band, visor, badge; oak leaves on
  /// the visor when large.
  void _cap(Canvas canvas, Rect area, double u, bool detail) {
    final path = Path()
      ..moveTo(0.2, 0.6)
      ..lineTo(0.03, 0.38)
      ..quadraticBezierTo(0.02, 0.18, 0.5, 0.14)
      ..quadraticBezierTo(0.98, 0.18, 0.97, 0.38)
      ..lineTo(0.8, 0.6)
      ..close()
      ..addRect(const Rect.fromLTRB(0.2, 0.58, 0.8, 0.73))
      ..moveTo(0.14, 0.77)
      ..quadraticBezierTo(0.5, 0.71, 0.86, 0.77)
      ..quadraticBezierTo(0.5, 1.0, 0.14, 0.77)
      ..close();
    _picture(canvas, area, u, path, () {
      canvas.drawLine(
        const Offset(0.1, 0.585),
        const Offset(0.9, 0.585),
        Paint()
          ..blendMode = BlendMode.clear
          ..strokeWidth = 0.05,
      );
      canvas.drawCircle(const Offset(0.5, 0.4), 0.12, _clear);
      canvas.drawCircle(const Offset(0.5, 0.4), 0.075, Paint()..color = ink);
      if (detail) {
        for (final x in [0.3, 0.42, 0.58, 0.7]) {
          canvas.save();
          canvas.translate(x, 0.82);
          canvas.rotate(x < 0.5 ? -0.5 : 0.5);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 0.1, height: 0.05), _clear);
          canvas.restore();
        }
      }
    });
  }

  /// A pickaxe, tilted: curved head across a handle.
  void _pickaxe(Canvas canvas, Rect area, double u) {
    final upright = Path()
      ..addRRect(RRect.fromLTRBR(0.43, 0.24, 0.57, 1.0, const Radius.circular(0.05)))
      ..moveTo(0.0, 0.5)
      ..quadraticBezierTo(0.5, -0.16, 1.0, 0.5)
      ..quadraticBezierTo(0.5, 0.2, 0.0, 0.5)
      ..close();
    _picture(canvas, area, u, _turned(upright, -math.pi / 5, const Offset(0.5, 0.5)));
  }

  /// Binoculars from the front: two barrels with lenses and a bridge.
  void _binoculars(Canvas canvas, Rect area, double u) {
    final path = Path()..addRect(const Rect.fromLTRB(0.35, 0.3, 0.65, 0.46));
    for (final x in [0.27, 0.73]) {
      path
        ..addRRect(RRect.fromLTRBR(x - 0.13, 0.12, x + 0.13, 0.64, const Radius.circular(0.06)))
        ..addOval(Rect.fromCircle(center: Offset(x, 0.67), radius: 0.24));
    }
    _picture(canvas, area, u, path, () {
      for (final x in [0.27, 0.73]) {
        canvas.drawCircle(Offset(x, 0.68), 0.11, _clear);
      }
    });
  }

  /// A brimmed hat over a domino mask with two eye holes.
  void _spy(Canvas canvas, Rect area, double u) {
    final path = Path()
      ..moveTo(0.24, 0.36)
      ..lineTo(0.3, 0.08)
      ..quadraticBezierTo(0.5, 0.0, 0.7, 0.08)
      ..lineTo(0.76, 0.36)
      ..close()
      ..addOval(const Rect.fromLTRB(0.02, 0.32, 0.98, 0.46))
      ..moveTo(0.5, 0.58)
      ..cubicTo(0.38, 0.52, 0.12, 0.5, 0.06, 0.6)
      ..cubicTo(0.02, 0.74, 0.12, 0.9, 0.3, 0.9)
      ..cubicTo(0.42, 0.9, 0.45, 0.8, 0.5, 0.8)
      ..cubicTo(0.55, 0.8, 0.58, 0.9, 0.7, 0.9)
      ..cubicTo(0.88, 0.9, 0.98, 0.74, 0.94, 0.6)
      ..cubicTo(0.88, 0.5, 0.62, 0.52, 0.5, 0.58)
      ..close();
    _picture(canvas, area, u, path, () {
      // Dent in the crown, a gap above the band, the eye holes.
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
      for (final x in [0.29, 0.71]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(x, 0.7), width: 0.22, height: 0.12), _clear);
      }
    });
  }

  @override
  bool shouldRepaint(GoInsigniaPainter oldDelegate) =>
      oldDelegate.piece != piece ||
      oldDelegate.ink != ink ||
      oldDelegate.edge != edge ||
      oldDelegate.edgeWidth != edgeWidth;
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
