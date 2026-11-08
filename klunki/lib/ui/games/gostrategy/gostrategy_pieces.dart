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

  /// Variant B1: [insignia] with a thin black outline around the white shapes.
  insigniaBlack,

  /// Variant B2: [insignia] with a thin dark grey outline.
  insigniaGrey,

  /// Variant B3: [insignia] with a soft dark halo instead of an outline.
  insigniaHalo,

  /// v4: [insigniaBlack] centred in the whole tile; number and "seen" eye
  /// as small bordered badges on the top corners.
  badgeBlack,

  /// v4: like [badgeBlack] with the dark grey edge of [insigniaGrey].
  badgeGrey,
}

/// Outline colour of [look] (null: none) and whether it is a soft halo.
(Color?, bool) goInsigniaEdge(GoPieceLook look) => switch (look) {
  GoPieceLook.insigniaBlack => (const Color(0xFF000000), false),
  GoPieceLook.insigniaGrey => (const Color(0xFF3C3C3C), false),
  GoPieceLook.insigniaHalo => (const Color(0xB3000000), true),
  GoPieceLook.badgeBlack => (const Color(0xFF000000), false),
  GoPieceLook.badgeGrey => (const Color(0xFF3C3C3C), false),
  _ => (null, false),
};

/// Outline width for a tile or insignia of [size] px: 3 % of it, 0.8–1.5 px.
double goInsigniaEdgeWidth(double size) => (size * 0.03).clamp(0.8, 1.5);

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
      final layout = GoInsigniaLayout(look, rankNumber: rankNumber, eye: known && size >= 26);
      final area = layout.area(kind);
      final boardLook = look == GoPieceLook.shoulderBoard && kind.rank != null;
      final (edge, halo) = goInsigniaEdge(look);
      face = Stack(
        children: [
          Positioned(
            left: area.left * size,
            top: area.top * size,
            width: area.width * size,
            height: area.height * size,
            child: CustomPaint(
              painter: GoInsigniaPainter(
                piece: kind,
                ink: ink,
                accent: look == GoPieceLook.insigniaGold || look == GoPieceLook.shoulderBoard ? goInsigniaGold : null,
                board: boardLook ? Color.lerp(color, Colors.black, 0.45) : null,
                edge: edge,
                edgeWidth: goInsigniaEdgeWidth(size),
                halo: halo,
                maxAspect: layout.badges ? 1 : 1.3,
              ),
            ),
          ),
          if (number && !layout.badges)
            Positioned(
              left: size * 0.07,
              top: size * 0.03,
              child: Text(
                '$rank',
                textDirection: TextDirection.ltr,
                style: TextStyle(color: ink, fontSize: size * 0.25, fontWeight: FontWeight.w800, height: 1),
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
    final layout = GoInsigniaLayout(look, rankNumber: rankNumber, eye: true);
    final eye = layout.eyeRect;
    final (edge, _) = goInsigniaEdge(look);
    final rank = kind?.rank;
    // v4 badges: a small rounded box in the army colour with a thin border
    // in the edge colour, a little over the tile's top corner.
    final badgeSize = size * GoInsigniaLayout.badgeSize;
    final badgeOut = size * GoInsigniaLayout.badgeOverflow;
    Widget badge(Widget child) => Container(
      height: badgeSize,
      constraints: BoxConstraints(minWidth: badgeSize),
      padding: EdgeInsets.symmetric(horizontal: badgeSize * 0.14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.black, 0.12),
        borderRadius: BorderRadius.circular(badgeSize / 2),
        border: Border.all(color: edge ?? Colors.black, width: goInsigniaEdgeWidth(size)),
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
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: face),
          if (layout.badges && kind != null && rank != null && rankNumber)
            Positioned(
              left: -badgeOut,
              top: -badgeOut,
              child: badge(
                Text(
                  '$rank',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: ink, fontSize: badgeSize * 0.72, fontWeight: FontWeight.w800, height: 1),
                ),
              ),
            ),
          if (layout.badges && known && kind != null && size >= 26)
            Positioned(
              key: goKnownMarkerKey,
              right: -badgeOut,
              top: -badgeOut,
              child: badge(Icon(Icons.visibility, size: badgeSize * 0.68, color: ink)),
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
          if (!layout.badges && known && kind != null && size >= 26)
            Positioned(
              key: goKnownMarkerKey,
              left: eye.left * size,
              top: eye.top * size,
              child: Icon(Icons.visibility, size: eye.width * size, color: ink.withValues(alpha: 0.8)),
            ),
        ],
      ),
    );
  }
}

/// Where things sit on a tile in the insignia looks, in tile units (0–1).
/// The corner number (top left) and the "seen" eye each have a corner of
/// their own that the insignia never enters, so nothing overlaps and every
/// insignia has the same centre.
@immutable
class GoInsigniaLayout {
  final GoPieceLook look;
  final bool rankNumber, eye;
  const GoInsigniaLayout(this.look, {required this.rankNumber, required this.eye});

  /// Space kept free for the number and the eye (not with badges).
  bool get reserve => !badges && (rankNumber || eye);

  /// v4: number and eye as badges over the top corners; the insignia is
  /// centred in the whole tile.
  bool get badges => look == GoPieceLook.badgeBlack || look == GoPieceLook.badgeGrey;

  /// Badge height and how far it reaches over the tile edge (tile units).
  static const badgeSize = 0.34, badgeOverflow = 0.06;

  /// Variant A: every shoulder board has this size and place.
  Rect get board => reserve ? const Rect.fromLTWH(0.38, 0.11, 0.5, 0.8) : const Rect.fromLTWH(0.25, 0.1, 0.5, 0.8);

  /// The insignia's area for [piece] (the board itself in variant A).
  Rect area(GoPiece piece) {
    if (look == GoPieceLook.shoulderBoard) {
      final b = board;
      // Bomb and flag have no board: the same column, a little shorter.
      return piece.rank != null ? b : Rect.fromLTRB(b.left - 0.03, b.top + 0.12, b.right + 0.03, b.bottom - 0.02);
    }
    // v4: centred, equal margins, clear of the badges' inner corners.
    if (badges) return const Rect.fromLTRB(0.2, 0.2, 0.8, 0.8);
    // B and C: a strip at the top for the number (left) and the eye (right).
    return reserve ? const Rect.fromLTRB(0.08, 0.28, 0.92, 0.9) : const Rect.fromLTRB(0.13, 0.13, 0.87, 0.87);
  }

  /// The "seen" eye: bottom right in the classic look, top right in B and
  /// C (next to the number), bottom left under the number in A.
  Rect get eyeRect => switch (look) {
    GoPieceLook.classic => const Rect.fromLTWH(0.7, 0.72, 0.24, 0.24),
    GoPieceLook.shoulderBoard => const Rect.fromLTWH(0.06, 0.7, 0.24, 0.24),
    _ => const Rect.fromLTWH(0.72, 0.04, 0.22, 0.22),
  };
}

/// The rank insignia of [piece] (KLD-058) in a [size] square, drawn by
/// [GoInsigniaPainter]: crossed batons (Marschall), peaked cap (General),
/// three, two, one star (Oberst, Major, Hauptmann), a bar (Leutnant),
/// chevrons (Feldwebel), pickaxe (Mineur), binoculars (Späher), hat and mask
/// (Spion); bomb and flag are the usual symbols. [color] is the ink;
/// [accent] (null: ink) colours stars, bars, chevrons and small details;
/// [board] (null: none) puts the insignia on a shoulder board of that
/// colour. Holes (lenses, eye holes) show what lies beneath, so it works on
/// any background (rules pages). [edge] (null: none) draws a thin outline of
/// that colour around the shapes, or a soft glow if [halo].
class GoInsignia extends StatelessWidget {
  final GoPiece piece;
  final Color color;
  final double size;
  final Color? accent;
  final Color? board;
  final Color? edge;
  final bool halo;

  const GoInsignia({
    super.key,
    required this.piece,
    required this.color,
    required this.size,
    this.accent,
    this.board,
    this.edge,
    this.halo = false,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: GoInsigniaPainter(
      piece: piece,
      ink: color,
      accent: accent,
      board: board,
      edge: edge,
      edgeWidth: goInsigniaEdgeWidth(size),
      halo: halo,
    ),
  );
}

/// Paints a rank insignia (see [GoInsignia]) centred in its canvas.
///
/// Consistent weight: every picture (batons, cap, pickaxe, binoculars, hat
/// and mask, bomb, flag) has the same height `u`; stars have one size for
/// one, two and three stars; bar and chevrons share one stroke width. `u` is
/// the canvas height (or its width / 1.3 when that is less, so the widest
/// picture, the cap, still fits). With [board] the canvas holds a shoulder
/// board (width 5/8 of its height, always the same outline) and the
/// insignia sits on it below the button. Free-standing (no board), the
/// single star and the bar are larger, like a picture.
///
/// [edge]: a thin outline of that colour, [edgeWidth] px wide, around the
/// whole insignia (holes included), so white shapes keep a border on any
/// background; with [halo] a soft glow instead.
class GoInsigniaPainter extends CustomPainter {
  final GoPiece piece;
  final Color ink;
  final Color? accent;
  final Color? board;
  final Color? edge;
  final double edgeWidth;
  final bool halo;

  /// Widest picture / its height that still gets the full height `u`;
  /// wider pictures (the cap) shrink to fit the width.
  final double maxAspect;

  const GoInsigniaPainter({
    required this.piece,
    required this.ink,
    this.accent,
    this.board,
    this.edge,
    this.edgeWidth = 1,
    this.halo = false,
    this.maxAspect = 1.3,
  });

  static final Paint _clear = Paint()..blendMode = BlendMode.clear;

  /// Star radius, star spacing, stroke of bar and chevrons, in units of `u`.
  static const _starR = 0.32, _starStep = 0.68, _stroke = 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final e = edge;
    if (e != null) {
      // The insignia once more below itself, grown by the edge width (or
      // blurred) and tinted: an outline that also rings the holes.
      final r = edgeWidth;
      final filter = halo
          ? ui.ImageFilter.compose(
              outer: ui.ImageFilter.blur(sigmaX: r * 1.3, sigmaY: r * 1.3, tileMode: TileMode.decal),
              inner: ui.ImageFilter.dilate(radiusX: r * 0.6, radiusY: r * 0.6),
            )
          : ui.ImageFilter.dilate(radiusX: r, radiusY: r);
      canvas.saveLayer(
        (Offset.zero & size).inflate(r * 5),
        Paint()
          ..imageFilter = filter
          ..colorFilter = ColorFilter.mode(e, BlendMode.srcIn),
      );
      _paintInsignia(canvas, size);
      canvas.restore();
    }
    _paintInsignia(canvas, size);
  }

  void _paintInsignia(Canvas canvas, Size size) {
    var area = Offset.zero & size;
    final boardColor = board;
    if (boardColor != null) {
      final h = math.min(size.height, size.width / 0.625);
      final b = Rect.fromCenter(center: area.center, width: h * 0.625, height: h);
      _shoulderBoard(canvas, b, boardColor);
      area = Rect.fromLTRB(
        b.left + b.width * 0.09,
        b.top + b.height * 0.3,
        b.right - b.width * 0.09,
        b.bottom - b.height * 0.07,
      );
    }
    final u = boardColor != null ? math.min(area.height, area.width) : math.min(area.height, area.width / maxAspect);
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
    final gold = accent;
    final detail = u >= 30;
    switch (piece) {
      case GoPiece.marshal:
        _batons(canvas, area, u, gold);
      case GoPiece.general:
        _cap(canvas, area, u, gold, detail);
      case GoPiece.colonel:
        _stars(canvas, area, u, const [(0, 0), (-0.5, 1), (0.5, 1)], gold);
      case GoPiece.major:
        _stars(canvas, area, u, const [(-0.5, 0), (0.5, 0)], gold);
      case GoPiece.captain when boardColor == null:
        // Alone, the star fills the area like a picture.
        final star = _star(0, 0, _starR);
        _accent(canvas, star, _place(canvas, area, star.getBounds(), u / star.getBounds().height), gold);
      case GoPiece.captain:
        _stars(canvas, area, u, const [(0, 0)], gold);
      case GoPiece.lieutenant:
        // Alone, the bar is longer and thicker than a chevron stroke.
        final big = boardColor == null;
        final bar = Path()
          ..addRRect(RRect.fromLTRBR(0, 0, big ? 1.2 : 1, big ? 0.3 : _stroke, const Radius.circular(0.04)));
        _accent(canvas, bar, _place(canvas, area, bar.getBounds(), u), gold);
      case GoPiece.sergeant:
        _chevrons(canvas, area, u, gold);
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
  /// [scale] pixels per unit (less if it would not fit). Returns the scale.
  /// Leaves one canvas.save() open: the caller draws, then [Canvas.restore].
  double _place(Canvas canvas, Rect area, Rect bounds, double scale) {
    final s = math.min(scale, math.min(area.width / bounds.width, area.height / bounds.height));
    canvas.save();
    canvas.translate(area.center.dx, area.center.dy);
    canvas.scale(s);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
    return s;
  }

  /// A picture scaled to height [u], centred; [draw] adds holes and details.
  void _picture(Canvas canvas, Rect area, double u, Path path, [void Function(double scale)? draw]) {
    final bounds = path.getBounds();
    final s = _place(canvas, area, bounds, u / bounds.height);
    canvas.drawPath(path, Paint()..color = ink);
    draw?.call(s);
    canvas.restore();
  }

  /// Fills [path] in the accent; gold gets a thin dark edge so it reads on
  /// red. Closes the save of [_place].
  void _accent(Canvas canvas, Path path, double scale, Color? gold) {
    canvas.drawPath(path, Paint()..color = gold ?? ink);
    if (gold != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 / scale,
      );
    }
    canvas.restore();
  }

  /// A shoulder board in [b]: a strap with a pointed upper end and a button.
  void _shoulderBoard(Canvas canvas, Rect b, Color color) {
    double x(double f) => b.left + b.width * f;
    double y(double f) => b.top + b.height * f;
    final path = Path()
      ..moveTo(x(0), y(1))
      ..lineTo(x(0), y(0.2))
      ..quadraticBezierTo(x(0), y(0.15), x(0.1), y(0.12))
      ..lineTo(x(0.5), y(0))
      ..lineTo(x(0.9), y(0.12))
      ..quadraticBezierTo(x(1), y(0.15), x(1), y(0.2))
      ..lineTo(x(1), y(1))
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = ink.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, b.width * 0.06),
    );
    canvas.drawCircle(Offset(x(0.5), y(0.17)), b.width * 0.09, Paint()..color = accent ?? ink);
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
  /// scale is that of the three-star triangle (1.29 × 1.0 units) for every
  /// count, so one, two and three stars are the same size everywhere. The
  /// triangle is nested: the top star sits between the two below.
  void _stars(Canvas canvas, Rect area, double u, List<(double, int)> cells, Color? gold) {
    final scale = math.min(u, math.min(area.width / 1.29, area.height / 1.0));
    final path = Path();
    for (final (col, row) in cells) {
      path.addPath(_star(col * _starStep, row * 0.42, _starR), Offset.zero);
    }
    _accent(canvas, path, _place(canvas, area, path.getBounds(), scale), gold);
  }

  /// Three chevrons pointing up, stroke [_stroke], one unit wide.
  void _chevrons(Canvas canvas, Rect area, double u, Color? gold) {
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
    _accent(canvas, path, _place(canvas, area, path.getBounds(), u), gold);
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

  /// Two crossed batons with end bands (gold in the gold looks).
  void _batons(Canvas canvas, Rect area, double u, Color? gold) {
    const len = 1.2, w = 0.2, c = Offset(0.6, 0.6);
    final stick = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: len, height: w), const Radius.circular(w / 2)),
      );
    final a = _turned(stick, -math.pi / 4, c), b = _turned(stick, math.pi / 4, c);
    final bounds = a.getBounds().expandToInclude(b.getBounds());
    // The X fills its box to the corners: a little smaller, so the ends
    // keep clear of corner badges and it weighs like the other pictures.
    _place(canvas, area, bounds, 0.9 * u / bounds.height);
    void ends(double angle) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      for (final dir in [-1.0, 1.0]) {
        if (gold != null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(dir < 0 ? -len / 2 : len / 2 - 0.2, -w / 2, dir < 0 ? -len / 2 + 0.2 : len / 2, w / 2),
              const Radius.circular(w / 2),
            ),
            Paint()..color = gold,
          );
        }
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
  void _cap(Canvas canvas, Rect area, double u, Color? gold, bool detail) {
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
    _picture(canvas, area, u, path, (s) {
      canvas.drawLine(
        const Offset(0.1, 0.585),
        const Offset(0.9, 0.585),
        Paint()
          ..blendMode = BlendMode.clear
          ..strokeWidth = 0.05,
      );
      canvas.drawCircle(const Offset(0.5, 0.4), 0.12, _clear);
      canvas.drawCircle(const Offset(0.5, 0.4), 0.075, Paint()..color = gold ?? ink);
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
    _picture(canvas, area, u, path, (s) {
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
    _picture(canvas, area, u, path, (s) {
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
      oldDelegate.accent != accent ||
      oldDelegate.board != board ||
      oldDelegate.edge != edge ||
      oldDelegate.edgeWidth != edgeWidth ||
      oldDelegate.halo != halo ||
      oldDelegate.maxAspect != maxAspect;
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
