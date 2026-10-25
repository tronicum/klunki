import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../game/game_controller.dart';
import '../../shell/game_screen.dart';
import 'muehle_geometry.dart';
import 'muehle_painter.dart';

/// Localized phase names.
String muehlePhaseName(AppLocalizations l10n, MuehlePhase p) => switch (p) {
      MuehlePhase.placing => l10n.muehlePhasePlacing,
      MuehlePhase.moving => l10n.muehlePhaseMoving,
      MuehlePhase.flying => l10n.muehlePhaseFlying,
    };

/// The interactive Mühle board plus the two player panels.
///
/// Tap flow:
/// * placing: tap an empty point,
/// * moving / flying: tap an own stone (it and its targets light up), then a
///   target; tap the stone again to deselect,
/// * after a mill: tap one of the highlighted opponent stones.
///
/// Every point is a tap target with the key `muehle-point-<p>`. Visual state
/// keys for tests: `muehle-stone-<p>-X|O`, `muehle-selected-<p>`,
/// `muehle-target-<p>`, `muehle-removable-<p>`.
class MuehleBoard extends StatefulWidget {
  final GameController controller;

  const MuehleBoard({super.key, required this.controller});

  @override
  State<MuehleBoard> createState() => _MuehleBoardState();
}

class _MuehleBoardState extends State<MuehleBoard> with SingleTickerProviderStateMixin {
  int? _selected;
  int _seenMoves = 0;
  Object? _seenTransport;
  List<List<int>> _millLines = const [];
  late final AnimationController _flash =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  GameController get _c => widget.controller;
  MuehleGame get _game => _c.game as MuehleGame;

  @override
  void initState() {
    super.initState();
    _sync();
    _c.addListener(_onChange);
  }

  @override
  void didUpdateWidget(MuehleBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _reset();
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _flash.dispose();
    super.dispose();
  }

  void _sync() {
    _seenMoves = _c.moves.length;
    _seenTransport = _c.transport;
  }

  void _reset() {
    _selected = null;
    _millLines = const [];
    _flash.value = 0;
    _sync();
  }

  void _onChange() {
    if (!mounted) return;
    final moves = _c.moves;
    final grew = identical(_seenTransport, _c.transport) && moves.length > _seenMoves;
    setState(() {
      _selected = null;
      if (!grew) {
        _millLines = const [];
        _flash.value = 0;
      } else {
        final last = moves.last;
        if (last.event.payload case {'mill': true}) {
          final to = last.move['to'] as int;
          final board = _game.board;
          _millLines = [
            for (final m in MuehleGame.mills)
              if (m.contains(to) && m.every((q) => board[q] == last.player)) m,
          ];
          _flash.forward(from: 0);
        }
      }
      _sync();
    });
  }

  // --- derived state -------------------------------------------------------

  List<Map<String, dynamic>> get _legal => _c.canAct ? _game.legalMoves : const [];

  Set<int> get _removable => {
        if (_game.pendingRemoval)
          for (final m in _legal)
            if (m['action'] == 'remove') m['at'] as int,
      };

  Set<int> _targetsOf(int from) => {
        for (final m in _legal)
          if (m['action'] == 'move' && m['from'] == from) m['to'] as int,
      };

  Set<int> get _movable => {
        for (final m in _legal)
          if (m['action'] == 'move') m['from'] as int,
      };

  String? _hint(AppLocalizations l10n) {
    final g = _game;
    if (g.isOver || !_c.canAct) return null;
    final me = g.currentPlayer;
    if (g.pendingRemoval) {
      return l10n.muehleHintRemove(playerMark(me == Player.a ? Player.b : Player.a));
    }
    final phase = g.phaseOf(me);
    if (phase == MuehlePhase.placing) return l10n.muehleHintPlace;
    if (_selected != null) return l10n.muehleHintTarget;
    return phase == MuehlePhase.flying ? l10n.muehleHintSelectFly : l10n.muehleHintSelectMove;
  }

  // --- interaction ---------------------------------------------------------

  void _tap(int p) {
    final g = _game;
    if (!_c.canAct || g.isOver) return;
    final me = g.currentPlayer;
    final board = g.board;

    if (g.pendingRemoval) {
      if (_removable.contains(p)) _c.submit({'action': 'remove', 'at': p});
      return;
    }
    if (g.phaseOf(me) == MuehlePhase.placing) {
      if (board[p] == null) _c.submit({'action': 'place', 'to': p});
      return;
    }
    // Moving / flying.
    if (board[p] == me) {
      setState(() => _selected = (_selected == p || !_movable.contains(p)) ? null : p);
      return;
    }
    final from = _selected;
    if (from != null && _targetsOf(from).contains(p)) {
      _c.submit({'action': 'move', 'from': from, 'to': p});
    }
  }

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    GameScreen.of(context).setHint(_hint(AppLocalizations.of(context)));
    final g = _game;
    final enabled = _c.canAct;

    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth > box.maxHeight * 1.25;
      final board = Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AspectRatio(aspectRatio: 1, child: _board(g, enabled)),
        ),
      );
      final a = _PlayerPanel(game: g, player: Player.a, active: !g.isOver && g.currentPlayer == Player.a);
      final b = _PlayerPanel(game: g, player: Player.b, active: !g.isOver && g.currentPlayer == Player.b);
      if (wide) {
        return Row(children: [
          SizedBox(width: math.min(180, box.maxWidth * 0.22), child: Center(child: a)),
          Expanded(child: board),
          SizedBox(width: math.min(180, box.maxWidth * 0.22), child: Center(child: b)),
        ]);
      }
      return Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [Expanded(child: a), const SizedBox(width: 8), Expanded(child: b)]),
        ),
        Expanded(child: board),
      ]);
    });
  }

  Widget _board(MuehleGame g, bool enabled) {
    final board = g.board;
    final removable = _removable;
    final selected = _selected;
    final targets = selected == null ? const <int>{} : _targetsOf(selected);
    final movable = selected == null ? _movable : const <int>{};

    return LayoutBuilder(builder: (context, box) {
      final side = box.biggest.shortestSide;
      final hit = MuehleGeometry.cell(side) * 0.95;
      final stone = MuehleGeometry.cell(side) * 0.72;
      return IgnorePointer(
        ignoring: !enabled,
        child: SizedBox(
          width: side,
          height: side,
          child: Stack(children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _flash,
                builder: (_, _) => CustomPaint(
                  painter: MuehleBoardPainter(
                    millLines: _millLines,
                    flash: _flash.isAnimating ? math.sin(_flash.value * math.pi * 3).abs() * (1 - _flash.value * 0.4) : 0,
                  ),
                ),
              ),
            ),
            for (var p = 0; p < MuehleGame.pointCount; p++)
              Positioned(
                left: MuehleGeometry.center(p, side).dx - hit / 2,
                top: MuehleGeometry.center(p, side).dy - hit / 2,
                width: hit,
                height: hit,
                child: _Point(
                  key: Key('muehle-point-$p'),
                  point: p,
                  owner: board[p],
                  stoneSize: stone,
                  selected: selected == p,
                  target: targets.contains(p),
                  removable: removable.contains(p),
                  movable: movable.contains(p),
                  onTap: () => _tap(p),
                ),
              ),
          ]),
        ),
      );
    });
  }
}

class _Point extends StatelessWidget {
  final int point;
  final Player? owner;
  final double stoneSize;
  final bool selected, target, removable, movable;
  final VoidCallback onTap;

  const _Point({
    super.key,
    required this.point,
    required this.owner,
    required this.stoneSize,
    required this.selected,
    required this.target,
    required this.removable,
    required this.movable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final o = owner;
    Widget? child;
    if (o != null) {
      final light = o == Player.a;
      final ring = selected
          ? MuehleColors.select
          : removable
              ? MuehleColors.remove
              : movable
                  ? MuehleColors.target
                  : (light ? MuehleColors.lightEdge : MuehleColors.darkEdge);
      final ringWidth = selected || removable ? stoneSize * 0.14 : (movable ? stoneSize * 0.08 : 1.5);
      child = AnimatedScale(
        scale: selected ? 1.12 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          key: Key('muehle-stone-$point-${playerMark(o)}'),
          width: stoneSize,
          height: stoneSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: light ? MuehleColors.light : MuehleColors.dark,
            border: Border.all(color: ring, width: ringWidth),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(1, 2))],
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: light
                  ? const [Colors.white, MuehleColors.light, Color(0xFFDCD5C4)]
                  : const [Color(0xFF5A5A60), MuehleColors.dark, Color(0xFF151517)],
            ),
          ),
          child: selected
              ? SizedBox(key: Key('muehle-selected-$point'))
              : removable
                  ? Icon(Icons.close, key: Key('muehle-removable-$point'), size: stoneSize * 0.6, color: MuehleColors.remove)
                  : null,
        ),
      );
    } else if (target) {
      child = Container(
        key: Key('muehle-target-$point'),
        width: stoneSize * 0.5,
        height: stoneSize * 0.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MuehleColors.target.withValues(alpha: 0.35),
          border: Border.all(color: MuehleColors.target, width: 2.5),
        ),
      );
    }
    final l10n = AppLocalizations.of(context);
    final label = o == null ? l10n.muehlePointEmpty(point) : l10n.muehlePointOwned(point, playerMark(o));
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  final MuehleGame game;
  final Player player;
  final bool active;

  const _PlayerPanel({required this.game, required this.player, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = playerMark(player);
    final opp = player == Player.a ? Player.b : Player.a;
    final hand = game.piecesInHand(player);
    final onBoard = game.piecesOnBoard(player);
    final captured = MuehleGame.piecesPerPlayer - game.piecesInHand(opp) - game.piecesOnBoard(opp);
    final light = player == Player.a;
    final small = theme.textTheme.bodySmall;
    final l10n = AppLocalizations.of(context);
    return Card(
      key: Key('muehle-panel-$mark'),
      elevation: active ? 3 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: active ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: active ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: light ? MuehleColors.light : MuehleColors.dark,
                  border: Border.all(color: light ? MuehleColors.lightEdge : MuehleColors.darkEdge),
                ),
              ),
              const SizedBox(width: 6),
              Text(mark, style: theme.textTheme.titleMedium),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  muehlePhaseName(l10n, game.phaseOf(player)),
                  key: Key('muehle-phase-$mark'),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(l10n.muehleCounts(hand, onBoard), key: Key('muehle-counts-$mark'), style: small),
            Text(l10n.muehleCaptured(captured), key: Key('muehle-captured-$mark'), style: small),
          ],
        ),
      ),
    );
  }
}
