import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../shell/game_screen.dart';
import '../../shell/seat_game_screen.dart';
import '../maexchen/maexchen_dice.dart' show paintDie;
import '../shake_to_roll.dart';

/// Where everything sits on the 11 × 11 grid of the board (KLD-131): the
/// classic cross with four arms of three columns, a house in each corner.
/// Cells are `(column, row)`, `(0, 0)` top left; the track runs clockwise.
abstract final class LudoGrid {
  static const int size = 11;

  /// Track field 0–39 → cell. Field `10·c` is the start field of corner `c`
  /// (0 top left, 1 top right, 2 bottom right, 3 bottom left).
  static const List<(int, int)> track = [
    (0, 4), (1, 4), (2, 4), (3, 4), (4, 4), (4, 3), (4, 2), (4, 1), (4, 0), (5, 0), //
    (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (7, 4), (8, 4), (9, 4), (10, 4), (10, 5), //
    (10, 6), (9, 6), (8, 6), (7, 6), (6, 6), (6, 7), (6, 8), (6, 9), (6, 10), (5, 10), //
    (4, 10), (4, 9), (4, 8), (4, 7), (4, 6), (3, 6), (2, 6), (1, 6), (0, 6), (0, 5),
  ];

  /// The finish lane of each corner, from its entry to the centre.
  static const List<List<(int, int)>> lanes = [
    [(1, 5), (2, 5), (3, 5), (4, 5)],
    [(5, 1), (5, 2), (5, 3), (5, 4)],
    [(9, 5), (8, 5), (7, 5), (6, 5)],
    [(5, 9), (5, 8), (5, 7), (5, 6)],
  ];

  /// The four house spots of each corner.
  static const List<List<(int, int)>> houses = [
    [(0, 0), (1, 0), (0, 1), (1, 1)],
    [(9, 0), (10, 0), (9, 1), (10, 1)],
    [(9, 9), (10, 9), (9, 10), (10, 10)],
    [(0, 9), (1, 9), (0, 10), (1, 10)],
  ];

  /// The cell of pawn [pawn] of [seat] in [game].
  static (int, int) cellOf(LudoGame game, int seat, int pawn) {
    final p = game.progressOf(seat, pawn);
    final c = game.cornerOf(seat);
    if (p == LudoGame.house) return houses[c][pawn];
    if (p >= LudoGame.laneStart) return lanes[c][p - LudoGame.laneStart];
    return track[game.trackFieldOf(seat, p)];
  }
}

/// The colours of the four corners: a seat's colour ([seatColor]) where a
/// seat plays, null for an empty corner (2–3 players).
List<Color?> ludoCornerColors(BuildContext context, int playerCount) {
  final corners = LudoGame.cornersFor(playerCount);
  return [
    for (var c = 0; c < LudoGame.corners; c++)
      corners.contains(c) ? seatColor(context, corners.indexOf(c)) : null,
  ];
}

/// The Rauswurf board (KLD-131): the cross drawn in code with the pawns on
/// it, the die below (beside it in landscape). Tapping the die rolls (or
/// shaking the phone, [ShakeToRoll]); then the pawns that may move glow and
/// a tap moves one. The hint line says what to do and what just happened
/// (no move possible, a pawn sent home, a 6 to roll again).
///
/// Keys: `ludo-board`, `ludo-die`, `ludo-pawn-<seat>-<pawn>` ([LudoPawn],
/// `active` while it may move).
class LudoBoard extends StatefulWidget {
  final GameController controller;
  const LudoBoard({super.key, required this.controller});

  @override
  State<LudoBoard> createState() => _LudoBoardState();
}

class _LudoBoardState extends State<LudoBoard> {
  GameController get controller => widget.controller;
  LudoGame get game => controller.game as LudoGame;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(LudoBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  bool get _canRoll => controller.canAct && game.mustRoll;

  void _roll({bool shaken = false}) {
    if (!_canRoll) return;
    HapticFeedback.mediumImpact();
    if (shaken) {
      controller.submit(LudoGame.rollMove);
      return;
    }
    ShakeToRoll.rollFromTap(context, () {
      if (mounted && _canRoll) controller.submit(LudoGame.rollMove);
    });
  }

  void _move(int pawn) {
    if (!controller.canAct || !game.movablePawns.contains(pawn)) return;
    HapticFeedback.selectionClick();
    controller.submit(LudoGame.pawnMove(pawn));
  }

  String _name(BuildContext context, AppLocalizations l10n, int seat) =>
      SeatLabelsScope.of(context).label(context, l10n, seat, count: game.playerCount);

  /// What to do now, after what just happened.
  String? _hint(BuildContext context, AppLocalizations l10n) {
    final g = game;
    if (g.isOver) return null;
    final last = controller.moves.isEmpty ? null : controller.moves.last;
    final p = last?.event.payload;
    final parts = <String>[];
    if (last != null && p is Map) {
      if (last.move['action'] == 'roll' && p['passed'] == true) {
        parts.add(l10n.ludoHintNoMove(_name(context, l10n, last.seat), p['rolled'] as int));
      } else if (p['captured'] case {'seat': final int s}) {
        parts.add(l10n.ludoHintCaptured(_name(context, l10n, s)));
      }
    }
    final die = g.die;
    if (die != null) {
      parts.add(l10n.ludoHintMove(die));
      final options = g.options;
      if (die == 6 && options.every((o) => o.from == LudoGame.house)) {
        parts.add(l10n.ludoHintBringOut);
      } else if (g.startClearing != null) {
        parts.add(l10n.ludoHintClearStart);
      } else if (g.rules.mustCapture && options.every((o) => o.captures != null)) {
        parts.add(l10n.ludoHintMustCapture);
      }
    } else {
      final again = last != null && p is Map && p['again'] == true && last.seat == g.currentSeat;
      if (again && p['tries'] is int) {
        parts.add(l10n.ludoHintTriesLeft(p['tries'] as int));
      } else if (again) {
        parts.add(l10n.ludoHintSixAgain);
      } else if (g.triesAllowed > 1) {
        parts.add(l10n.ludoHintNeedSix(g.triesAllowed));
      } else {
        parts.add(l10n.ludoHintRoll);
      }
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    GameScreen.of(context).setHint(_hint(context, l10n));
    return ShakeToRoll(
      enabled: _canRoll,
      onShake: () => _roll(shaken: true),
      builder: (context, shakeReady) => LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth >= 500 && box.maxWidth > box.maxHeight * 1.15;
        final board = Padding(
          padding: const EdgeInsets.all(8),
          child: Center(child: AspectRatio(aspectRatio: 1, child: _board(context, l10n))),
        );
        final controls = _controls(context, l10n, wide: wide);
        if (wide) {
          return Row(children: [
            Expanded(child: board),
            SizedBox(width: min(260.0, box.maxWidth * 0.32), child: Center(child: controls)),
          ]);
        }
        return Column(children: [
          Expanded(child: board),
          Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: controls),
        ]);
      }),
    );
  }

  Widget _board(BuildContext context, AppLocalizations l10n) {
    final g = game;
    final colors = ludoCornerColors(context, g.playerCount);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final movable = controller.canAct ? g.movablePawns.toSet() : const <int>{};
    return LayoutBuilder(builder: (context, box) {
      final side = box.biggest.shortestSide;
      final cell = side / LudoGrid.size;
      final r = cell * 0.36;
      return SizedBox.square(
        key: const Key('ludo-board'),
        dimension: side,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: LudoBoardPainter(colors: colors, dark: dark))),
            for (var s = 0; s < g.playerCount; s++)
              if (!g.isSeatOut(s))
                for (var i = 0; i < LudoGame.pawns; i++)
                  () {
                    final (cx, cy) = LudoGrid.cellOf(g, s, i);
                    final active = s == g.currentSeat && movable.contains(i);
                    final size = active ? r * 2.5 : r * 2;
                    return AnimatedPositioned(
                      key: ValueKey('ludo-pos-$s-$i'),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: (cx + 0.5) * cell - size / 2,
                      top: (cy + 0.5) * cell - size / 2,
                      width: size,
                      height: size,
                      child: LudoPawn(
                        key: Key('ludo-pawn-$s-$i'),
                        seat: s,
                        color: seatColor(context, s),
                        active: active,
                        label: l10n.ludoPawn(_name(context, l10n, s)),
                        onTap: active ? () => _move(i) : null,
                      ),
                    );
                  }(),
          ],
        ),
      );
    });
  }

  Widget _controls(BuildContext context, AppLocalizations l10n, {required bool wide}) {
    final g = game;
    final theme = Theme.of(context);
    final value = g.die ?? g.lastRoll?.value ?? 0;
    final rollSeat = g.die != null ? g.currentSeat : (g.lastRoll?.seat ?? g.currentSeat);
    final canRoll = _canRoll;
    final color = seatColor(context, canRoll ? g.currentSeat : rollSeat);
    final die = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, a) => RotationTransition(
        turns: Tween<double>(begin: -0.15, end: 0).animate(a),
        child: ScaleTransition(scale: a, child: child),
      ),
      child: SizedBox.square(
        key: ValueKey('ludo-die-face-${controller.moves.length}'),
        dimension: 54,
        child: CustomPaint(painter: _DiePainter(value)),
      ),
    );
    final button = Material(
      color: canRoll ? color.withValues(alpha: 0.16) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: canRoll ? color : theme.colorScheme.outlineVariant, width: canRoll ? 3 : 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('ludo-die'),
        onTap: canRoll ? _roll : null,
        child: Semantics(
          button: true,
          enabled: canRoll,
          label: l10n.ludoRoll,
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                die,
                const SizedBox(width: 12),
                Flexible(
                  child: Text(l10n.ludoRoll,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: canRoll ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (wide) {
      final undo = g.isOver ? const SizedBox.shrink() : const UndoMoveButton();
      return Column(
          key: const Key('ludo-controls'),
          mainAxisSize: MainAxisSize.min,
          children: [button, const SizedBox(height: 8), undo]);
    }
    // A phone: the die button as wide as it gets (a big target), the ↶
    // icon next to it (its label as the tooltip).
    return Row(key: const Key('ludo-controls'), children: [
      Expanded(child: button),
      if (!g.isOver) ...[const SizedBox(width: 8), const UndoMoveButton(iconOnly: true)],
    ]);
  }
}

class _DiePainter extends CustomPainter {
  final int value;
  const _DiePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) => paintDie(canvas, Offset.zero & size, value);

  @override
  bool shouldRepaint(_DiePainter old) => old.value != value;
}

/// One pawn: a round piece in the seat's colour with the seat number (told
/// apart without colour too, like [SeatToken]); a pawn that may move now
/// is bigger and glows.
class LudoPawn extends StatelessWidget {
  final int seat;
  final Color color;
  final bool active;
  final String label;
  final VoidCallback? onTap;
  const LudoPawn(
      {super.key, required this.seat, required this.color, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final glow = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFFFFC233);
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: LayoutBuilder(builder: (context, box) {
          final d = box.biggest.shortestSide;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.4),
                colors: [Color.lerp(color, Colors.white, 0.45)!, color, Color.lerp(color, Colors.black, 0.35)!],
                stops: const [0, 0.55, 1],
              ),
              border: Border.all(color: active ? glow : Colors.black45, width: active ? max(2.5, d * 0.1) : max(1, d * 0.06)),
              boxShadow: [
                if (active) BoxShadow(color: glow.withValues(alpha: 0.85), blurRadius: d * 0.35, spreadRadius: d * 0.06),
                const BoxShadow(color: Color(0x55000000), blurRadius: 2, offset: Offset(0.5, 1.5)),
              ],
            ),
            child: Text(
              '${seat + 1}',
              textDirection: TextDirection.ltr,
              style: TextStyle(color: inkOn(color), fontSize: d * 0.42, fontWeight: FontWeight.w800, height: 1),
            ),
          );
        }),
      ),
    );
  }
}

/// The board without the pawns: the cross of fields, the houses, start
/// fields and finish lanes in the corner colours ([colors], null = a
/// corner nobody plays), the centre with the four colours.
class LudoBoardPainter extends CustomPainter {
  final List<Color?> colors;
  final bool dark;
  const LudoBoardPainter({required this.colors, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final cell = side / LudoGrid.size;
    final bg = dark ? const Color(0xFF2A2823) : const Color(0xFFFFF4DC);
    final field = dark ? const Color(0xFF45413A) : Colors.white;
    final line = dark ? const Color(0xFF8E877A) : const Color(0xFF6B6558);
    final neutral = dark ? const Color(0xFF5A564E) : const Color(0xFFCFC8B8);
    final rect = Offset.zero & Size.square(side);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.5)), Paint()..color = bg);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(cell * 0.5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, cell * 0.06)
          ..color = line.withValues(alpha: 0.5));
    Offset centre((int, int) c) => Offset((c.$1 + 0.5) * cell, (c.$2 + 0.5) * cell);
    final r = cell * 0.42;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, cell * 0.05)
      ..color = line;
    void spot((int, int) c, Color fill) {
      canvas.drawCircle(centre(c), r, Paint()..color = fill);
      canvas.drawCircle(centre(c), r, stroke);
    }

    // The houses: a soft square in the corner colour.
    for (var c = 0; c < 4; c++) {
      final color = colors[c] ?? neutral;
      final cells = LudoGrid.houses[c];
      final x = cells.map((e) => e.$1).reduce(min), y = cells.map((e) => e.$2).reduce(min);
      final area = Rect.fromLTWH(x * cell, y * cell, 2 * cell, 2 * cell).deflate(cell * 0.04);
      canvas.drawRRect(RRect.fromRectAndRadius(area, Radius.circular(cell * 0.4)),
          Paint()..color = color.withValues(alpha: dark ? 0.32 : 0.22));
      for (final h in cells) {
        spot(h, Color.lerp(field, color, 0.25)!);
      }
    }
    // The track, the start fields in full colour.
    for (var f = 0; f < LudoGame.trackLength; f++) {
      final c = f % LudoGame.cornerStep == 0 ? colors[f ~/ LudoGame.cornerStep] : null;
      spot(LudoGrid.track[f], c ?? field);
    }
    // The finish lanes, the centre.
    for (var c = 0; c < 4; c++) {
      final color = colors[c] ?? neutral;
      for (final l in LudoGrid.lanes[c]) {
        spot(l, Color.lerp(field, color, 0.6)!);
      }
    }
    final mid = centre((5, 5));
    final h = cell * 0.5;
    final tips = [Offset(-h, -h), Offset(h, -h), Offset(h, h), Offset(-h, h)];
    // Each corner's triangle points from the side its lane comes from.
    const sides = [(3, 0), (0, 1), (1, 2), (2, 3)];
    for (var c = 0; c < 4; c++) {
      final (a, b) = sides[c];
      final path = Path()
        ..moveTo(mid.dx, mid.dy)
        ..lineTo(mid.dx + tips[a].dx, mid.dy + tips[a].dy)
        ..lineTo(mid.dx + tips[b].dx, mid.dy + tips[b].dy)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[c] ?? neutral);
      canvas.drawPath(path, stroke);
    }
    // Small arrows on the start fields' outer side would crowd a phone:
    // the full colour marks them.
  }

  @override
  bool shouldRepaint(LudoBoardPainter old) => old.dark != dark || !_same(old.colors, colors);

  static bool _same(List<Color?> a, List<Color?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Menu illustration of Rauswurf: the cross in small with a pawn of each
/// colour and a die.
class LudoIllustration extends CustomPainter {
  final KlunkiPalette palette;
  const LudoIllustration(this.palette);

  static const _colors = [Color(0xFF1F6FB2), Color(0xFFD9822B), Color(0xFF2E8B57), Color(0xFFA23B72)];

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final o = Offset((size.width - s) / 2, (size.height - s) / 2);
    canvas.save();
    canvas.translate(o.dx + s * 0.06, o.dy + s * 0.06);
    final b = s * 0.78;
    LudoBoardPainter(colors: _colors, dark: palette.background.computeLuminance() < 0.2).paint(canvas, Size.square(b));
    final cell = b / LudoGrid.size;
    void pawn((int, int) c, Color color) {
      final p = Offset((c.$1 + 0.5) * cell, (c.$2 + 0.5) * cell);
      canvas.drawCircle(p.translate(0.6, 1.2), cell * 0.44, Paint()..color = const Color(0x55000000));
      canvas.drawCircle(p, cell * 0.44, Paint()..color = color);
      canvas.drawCircle(
          p,
          cell * 0.44,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1, cell * 0.08)
            ..color = Colors.black45);
    }

    pawn(LudoGrid.track[3], _colors[0]);
    pawn(LudoGrid.track[16], _colors[1]);
    pawn(LudoGrid.lanes[2][1], _colors[2]);
    pawn(LudoGrid.track[33], _colors[3]);
    canvas.restore();
    paintDie(canvas, Rect.fromLTWH(o.dx + s * 0.66, o.dy + s * 0.66, s * 0.26, s * 0.26), 6, angle: 0.2);
  }

  @override
  bool shouldRepaint(LudoIllustration old) => old.palette != palette;
}
