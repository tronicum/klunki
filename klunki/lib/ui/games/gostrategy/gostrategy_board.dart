import 'dart:math';

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../ltr.dart';
import '../../shell/game_screen.dart';
import 'gostrategy_pieces.dart';

/// How long the fight reveal stays (fade in, hold, fade out).
const goRevealDuration = Duration(milliseconds: 2400);

/// The player whose view this device shows: the local player in a network
/// game, the player to move in hot-seat (behind the handover cover).
Player goViewer(GameController c) {
  final local = c.transport.localPlayers;
  return local.length == 1 ? local.single : c.game.currentPlayer;
}

/// The GoStrategy board (KLD-058b): the setup editor until the viewer's army
/// stands, then the 10×10 board with the armies panel and the fight reveal.
///
/// Renders only [GoStrategyGame.viewFor] of [goViewer] plus the public fight
/// info of the event payloads, never the full board. The board is drawn
/// rotated for player O, so the own army is always at the bottom; the
/// engine's square numbering is untouched (cell keys are `go-cell-<square>`).
class GoStrategyBoard extends StatefulWidget {
  final GameController controller;

  const GoStrategyBoard({super.key, required this.controller});

  @override
  State<GoStrategyBoard> createState() => _GoStrategyBoardState();
}

class _GoStrategyBoardState extends State<GoStrategyBoard> with SingleTickerProviderStateMixin {
  final Random _rng = Random();
  late GameTransport _transport;
  late final AnimationController _reveal = AnimationController(vsync: this, duration: goRevealDuration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _fight = null);
    });

  /// Setup arrangement per player (setup order), kept while arranging.
  final Map<Player, List<GoPiece>> _arrangement = {};
  int? _swapFirst;

  int? _selected;
  List<int> _targets = const [];

  /// Moves already looked at for fights.
  int _seen = 0;
  GoFight? _fight;
  bool _fightStarted = false;

  GameController get controller => widget.controller;
  GoStrategyGame get game => controller.game as GoStrategyGame;

  @override
  void initState() {
    super.initState();
    _transport = controller.transport;
    _seen = controller.moves.length;
    controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(GoStrategyBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _reset();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    _reveal.dispose();
    super.dispose();
  }

  void _reset() {
    _transport = controller.transport;
    _arrangement.clear();
    _swapFirst = null;
    _selected = null;
    _targets = const [];
    _seen = controller.moves.length;
    _fight = null;
    _reveal.stop();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {
      if (!identical(_transport, controller.transport)) {
        _reset(); // restarted
        return;
      }
      final moves = controller.moves;
      if (moves.length != _seen) {
        _selected = null;
        _targets = const [];
        _swapFirst = null;
        if (moves.length < _seen) {
          // Undo: drop a running reveal; forget arrangements of players
          // whose setup was taken back so they start fresh.
          _fight = null;
          _reveal.stop();
          for (final p in Player.values) {
            if (!game.hasSetup(p)) _arrangement.remove(p);
          }
        } else {
          _fight = GoFight.fromMove(moves.last);
          _fightStarted = false;
          _reveal.stop();
        }
        _seen = moves.length;
      }
      // In hot-seat the cover hides the board after a move: the reveal
      // waits until the next player has taken the device.
      if (_fight != null && !_fightStarted && !controller.needsHandover) {
        _fightStarted = true;
        _reveal.forward(from: 0);
      }
    });
  }

  void _dismissReveal() {
    _reveal.stop();
    setState(() => _fight = null);
  }

  // ----------------------------------------------------------------- setup

  List<GoPiece> _arrangementOf(Player p) => _arrangement.putIfAbsent(
        p,
        () => List.of(GoStrategyGame.randomSetup(controller.config.seed * 2 + (p == Player.a ? 0 : 1))),
      );

  void _shuffle(Player p) => setState(() {
        _arrangement[p] = List.of(GoStrategyGame.randomSetup(_rng.nextInt(1 << 31)));
        _swapFirst = null;
      });

  void _tapSetup(Player p, int i) => setState(() {
        final first = _swapFirst;
        if (first == null) {
          _swapFirst = i;
        } else if (first == i) {
          _swapFirst = null;
        } else {
          final list = _arrangementOf(p);
          final t = list[first];
          list[first] = list[i];
          list[i] = t;
          _swapFirst = null;
        }
      });

  void _submitSetup(Player p) {
    _swapFirst = null;
    controller.submit(GoStrategyGame.setupMove(_arrangementOf(p)));
  }

  // ------------------------------------------------------------------ play

  void _tapSquare(Player me, List<GoCell> view, int sq) {
    if (!controller.canAct || game.phase != GoStrategyPhase.play || _fight != null) return;
    final cell = view[sq];
    final selected = _selected;
    if (selected != null && _targets.contains(sq)) {
      setState(() {
        _selected = null;
        _targets = const [];
      });
      controller.submit({'action': 'move', 'from': selected, 'to': sq});
      return;
    }
    setState(() {
      if (cell.owner == me && sq != selected) {
        _selected = sq;
        _targets = game.targetsFrom(sq);
      } else {
        _selected = null;
        _targets = const [];
      }
    });
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final g = game;
    final me = goViewer(controller);
    final l10n = AppLocalizations.of(context);
    final labels = PlayerLabelsScope.of(context);
    String label(Player p) => labels.label(context, l10n, p);
    final shell = GameScreen.of(context);

    if (!g.hasSetup(me) && !g.isOver) {
      final mine = controller.canAct && g.currentPlayer == me;
      final first = _swapFirst;
      shell.setHint(!mine
          ? l10n.goSetupFirst(label(goOther(me)))
          : first == null
              ? l10n.goSetupHint
              : l10n.goSetupSelected(goPieceName(l10n, _arrangementOf(me)[first])));
      return _Setup(state: this, me: me, canSubmit: mine, title: l10n.goSetupTitle(playerMark(me)));
    }

    final selected = _selected;
    final String? hint;
    if (g.isOver) {
      hint = null;
    } else if (g.phase == GoStrategyPhase.setup) {
      hint = l10n.goWaitingSetup(label(g.currentPlayer));
    } else if (!controller.canAct) {
      hint = l10n.goHintWaiting(label(g.currentPlayer));
    } else if (selected != null) {
      final piece = g.viewFor(me)[selected].piece;
      final name = piece == null ? '' : goPieceLabel(l10n, piece);
      hint = _targets.isEmpty ? l10n.goHintNoTargets(name) : l10n.goHintSelected(name);
    } else {
      hint = l10n.goHintSelect;
    }
    shell.setHint(hint);
    return _Play(state: this, me: me);
  }
}

// ------------------------------------------------------------------ setup

class _Setup extends StatelessWidget {
  final _GoStrategyBoardState state;
  final Player me;
  final bool canSubmit;
  final String title;

  const _Setup({required this.state, required this.me, required this.canSubmit, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final list = state._arrangementOf(me);
    final palette = KlunkiPalette.of(context).gostrategy;

    final buttons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          key: const Key('go-shuffle'),
          onPressed: () => state._shuffle(me),
          icon: const Icon(Icons.casino_outlined),
          label: Text(l10n.goSetupShuffle),
        ),
        FilledButton.icon(
          key: const Key('go-done'),
          onPressed: canSubmit ? () => state._submitSetup(me) : null,
          icon: const Icon(Icons.check),
          label: Text(l10n.goSetupDone),
        ),
      ],
    );

    Widget grid(double width) {
      final cell = width / GoStrategyGame.size;
      return LtrBoard(
        child: Container(
          key: const Key('go-setup-grid'),
          width: width,
          height: cell * 4,
          decoration: BoxDecoration(
            color: palette.land,
            border: Border.all(color: palette.edge, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              for (var row = 0; row < 4; row++)
                Expanded(
                  child: Row(
                    children: [
                      for (var col = 0; col < GoStrategyGame.size; col++)
                        Expanded(child: _setupCell(context, list, row * GoStrategyGame.size + col, cell)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final legend = Column(
      key: const Key('go-legend'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.goLegendTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            for (final p in GoPiece.values)
              Row(
                key: Key('go-legend-${p.id}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  GoPieceTile(owner: me, piece: p, size: 24),
                  const SizedBox(width: 4),
                  Text('${goPieceName(l10n, p)} ×${p.count}', style: theme.textTheme.bodySmall),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.goLegendRules, style: theme.textTheme.bodySmall),
      ],
    );

    return LayoutBuilder(builder: (context, box) {
      final width = max(120.0, min(min(box.maxWidth - 24, 640.0), box.maxHeight * 0.9));
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 664),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, key: const Key('go-setup-title'), style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                buttons,
                const SizedBox(height: 10),
                Center(child: grid(width)),
                const SizedBox(height: 10),
                Expanded(child: SingleChildScrollView(child: legend)),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _setupCell(BuildContext context, List<GoPiece> list, int i, double cell) {
    final palette = KlunkiPalette.of(context).gostrategy;
    final l10n = AppLocalizations.of(context);
    final selected = state._swapFirst == i;
    final row = i ~/ GoStrategyGame.size, col = i % GoStrategyGame.size;
    final sq = GoStrategyGame.setupSquare(me, i);
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.goCellLabel(goSquareName(sq), goPieceLabel(l10n, list[i])),
      child: GestureDetector(
        key: Key('go-setup-$i'),
        behavior: HitTestBehavior.opaque,
        onTap: () => state._tapSetup(me, i),
        child: Container(
          decoration: BoxDecoration(
            color: (row + col).isEven ? palette.land : palette.landAlt,
            border: Border.all(color: palette.line, width: 0.5),
          ),
          padding: EdgeInsets.all(cell * 0.06),
          child: AnimatedScale(
            scale: selected ? 1.08 : 1,
            duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 120),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cell * 0.2),
                border: selected ? Border.all(color: palette.select, width: 3) : null,
              ),
              child: ExcludeSemantics(child: GoPieceTile(owner: me, piece: list[i], size: cell * 0.88)),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- play

/// One board square as rendered (tests read its fields).
class GoSquareView extends StatelessWidget {
  final int square;
  final GoCell cell;
  final Player viewer;
  final bool selected, target, lastMove;
  final double size;
  final String semanticLabel;
  final VoidCallback? onTap;

  const GoSquareView({
    super.key,
    required this.square,
    required this.cell,
    required this.viewer,
    required this.selected,
    required this.target,
    required this.lastMove,
    required this.size,
    required this.semanticLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = KlunkiPalette.of(context);
    final p = palette.gostrategy;
    final row = GoStrategyGame.rowOf(square), col = GoStrategyGame.colOf(square);
    final owner = cell.owner;
    final attack = target && owner != null;
    Widget? piece;
    if (owner != null) {
      piece = Padding(
        padding: EdgeInsets.all(size * 0.07),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.2),
            border: selected ? Border.all(color: p.select, width: max(2, size * 0.08)) : null,
            boxShadow: selected ? [BoxShadow(color: p.select.withValues(alpha: 0.6), blurRadius: size * 0.2)] : null,
          ),
          child: GoPieceTile(
            owner: owner,
            piece: cell.piece,
            size: size * 0.86,
            moved: cell.moved,
            known: owner == viewer && cell.revealed,
          ),
        ),
      );
    }
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cell.lake ? null : ((row + col).isEven ? p.land : p.landAlt),
            gradient: cell.lake
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.schiffe.water, palette.schiffe.waterDeep],
                  )
                : null,
            border: cell.lake ? null : Border.all(color: p.line, width: 0.5),
          ),
          child: ExcludeSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (lastMove) ColoredBox(color: p.lastMove),
                ?piece,
                if (target && !attack)
                  Center(
                    child: Container(
                      key: const Key('go-target-dot'),
                      width: size * 0.3,
                      height: size * 0.3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.target.withValues(alpha: 0.85),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                      ),
                    ),
                  ),
                if (attack)
                  Container(
                    key: const Key('go-target-attack'),
                    margin: EdgeInsets.all(size * 0.02),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * 0.22),
                      border: Border.all(color: p.attack, width: max(2, size * 0.09)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Play extends StatelessWidget {
  final _GoStrategyBoardState state;
  final Player me;

  const _Play({required this.state, required this.me});

  @override
  Widget build(BuildContext context) {
    final g = state.game;
    final view = g.viewFor(me);
    final l10n = AppLocalizations.of(context);
    final labels = PlayerLabelsScope.of(context);
    final palette = KlunkiPalette.of(context).gostrategy;
    final flip = me == Player.b;
    final canAct = state.controller.canAct && g.phase == GoStrategyPhase.play;
    final targets = state._targets.toSet();
    final last = _lastMove(state.controller.moves);

    String cellLabel(int sq) {
      final c = view[sq];
      final owner = c.owner;
      String content;
      if (c.lake) {
        content = l10n.goCellLake;
      } else if (owner == null) {
        content = l10n.goCellFree;
      } else {
        final who = labels.label(context, l10n, owner);
        final piece = c.piece;
        content = piece == null ? l10n.goCellHidden(who) : l10n.goCellPiece(goPieceLabel(l10n, piece), who);
        if (c.moved && piece == null) content = l10n.goCellMoved(content);
      }
      return l10n.goCellLabel(goSquareName(sq), content);
    }

    Widget board(double side) {
      final cell = side / GoStrategyGame.size;
      return LtrBoard(
        child: Container(
          key: const Key('go-board'),
          width: side + 4,
          height: side + 4,
          decoration: BoxDecoration(
            color: palette.edge,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              for (var dr = 0; dr < GoStrategyGame.size; dr++)
                Expanded(
                  child: Row(
                    children: [
                      for (var dc = 0; dc < GoStrategyGame.size; dc++)
                        Expanded(
                          child: Builder(builder: (context) {
                            // Rendering only: O sees the board turned by 180°.
                            final r = flip ? GoStrategyGame.size - 1 - dr : dr;
                            final c = flip ? GoStrategyGame.size - 1 - dc : dc;
                            final sq = GoStrategyGame.square(r, c);
                            return GoSquareView(
                              key: Key('go-cell-$sq'),
                              square: sq,
                              cell: view[sq],
                              viewer: me,
                              selected: state._selected == sq,
                              target: targets.contains(sq),
                              lastMove: last != null && (last.$1 == sq || last.$2 == sq),
                              size: cell,
                              semanticLabel: cellLabel(sq),
                              onTap: canAct && !view[sq].lake ? () => state._tapSquare(me, view, sq) : null,
                            );
                          }),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final fight = state._fight;
    Widget boardWithReveal(double side) => SizedBox.square(
          dimension: side + 4,
          child: Stack(
            children: [
              board(side),
              if (fight != null)
                Positioned.fill(child: _FightReveal(fight: fight, animation: state._reveal, onDismiss: state._dismissReveal)),
            ],
          ),
        );

    final panel = _ArmyPanel(game: g, me: me);

    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 720 && box.maxWidth > box.maxHeight;
      if (wide) {
        final side = min(box.maxHeight - 24, box.maxWidth - 340) - 4;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Center(child: boardWithReveal(side))),
              const SizedBox(width: 16),
              SizedBox(width: 300, child: SingleChildScrollView(child: panel)),
            ],
          ),
        );
      }
      final side = min(box.maxWidth - 16, box.maxHeight * 0.68) - 4;
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Column(
          children: [
            Center(child: boardWithReveal(side)),
            const SizedBox(height: 8),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 4), child: panel)),
          ],
        ),
      );
    });
  }

  /// From/to of the most recent move (null before the first move).
  static (int, int)? _lastMove(List<AcceptedMove> moves) {
    if (moves.isEmpty) return null;
    final m = moves.last.move;
    final f = m['from'], t = m['to'];
    return f is int && t is int ? (f, t) : null;
  }
}

/// Pieces left per side (captured kinds faded) and the move-limit hint.
class _ArmyPanel extends StatelessWidget {
  final GoStrategyGame game;
  final Player me;

  const _ArmyPanel({required this.game, required this.me});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final labels = PlayerLabelsScope.of(context);
    final left = game.noCaptureLimit - game.movesSinceCapture;

    Widget side(Player p, String heading) {
      final rem = game.remaining(p);
      final total = rem.values.fold(0, (a, b) => a + b);
      return Column(
        key: Key('go-army-${playerMark(p)}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(heading, style: theme.textTheme.titleSmall),
              Text(
                l10n.goArmyLeft('$total', '${GoStrategyGame.piecesPerPlayer}'),
                key: Key('go-army-left-${playerMark(p)}'),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final k in GoPiece.values)
                Opacity(
                  opacity: rem[k] == 0 ? 0.35 : 1,
                  child: Tooltip(
                    message: goPieceLabel(l10n, k),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GoPieceTile(owner: p, piece: k, size: 22),
                        const SizedBox(width: 2),
                        Text(
                          '×${rem[k]}',
                          key: Key('go-left-${playerMark(p)}-${k.id}'),
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    final opp = goOther(me);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!game.isOver && game.phase == GoStrategyPhase.play && left <= 30)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              l10n.goMoveLimit('$left'),
              key: const Key('go-move-limit'),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        side(opp, l10n.goArmyEnemy(labels.label(context, l10n, opp))),
        const SizedBox(height: 8),
        side(me, l10n.goArmyOwn(playerMark(me))),
      ],
    );
  }
}

/// The fight as a short card over the board: both pieces with their ranks,
/// then the outcome. Fades/scales in and out (static with reduced motion);
/// a tap dismisses it.
class _FightReveal extends StatelessWidget {
  final GoFight fight;
  final Animation<double> animation;
  final VoidCallback onDismiss;

  const _FightReveal({required this.fight, required this.animation, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return GestureDetector(
      key: const Key('go-reveal'),
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value;
          final fade = still ? 1.0 : (t < 0.12 ? t / 0.12 : (t > 0.88 ? (1 - t) / 0.12 : 1.0));
          final scale = still ? 1.0 : 0.85 + 0.15 * Curves.easeOutBack.transform((t / 0.15).clamp(0.0, 1.0));
          final outcome = still ? 1.0 : ((t - 0.15) / 0.12).clamp(0.0, 1.0);
          return ColoredBox(
            color: Colors.black.withValues(alpha: 0.28 * fade),
            child: Center(
              child: Opacity(
                opacity: fade.clamp(0.0, 1.0),
                child: Transform.scale(scale: scale, child: GoFightCard(fight: fight, outcome: outcome)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Both pieces of [fight] and the outcome text. [outcome] 0–1 fades in the
/// result (losers dimmed). Used by the reveal and the handover cover.
class GoFightCard extends StatelessWidget {
  final GoFight fight;
  final double outcome;
  final bool compact;

  const GoFightCard({super.key, required this.fight, this.outcome = 1, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final labels = PlayerLabelsScope.of(context);
    final size = compact ? 40.0 : 64.0;

    Widget piece(Player owner, GoPiece kind, bool falls) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: falls ? 1 - 0.6 * outcome : 1,
              child: GoPieceTile(owner: owner, piece: kind, size: size),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: size * 2,
              child: Text(
                goPieceLabel(l10n, kind),
                textAlign: TextAlign.center,
                style: compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium,
              ),
            ),
          ],
        );

    return Container(
      key: const Key('go-fight-card'),
      constraints: const BoxConstraints(maxWidth: 320),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: KlunkiPalette.of(context).card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.goFightBy(labels.label(context, l10n, fight.attackerPlayer)), style: theme.textTheme.labelLarge),
          SizedBox(height: compact ? 6 : 10),
          LtrBoard(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                piece(fight.attackerPlayer, fight.attacker, fight.attackerFalls),
                Padding(
                  padding: EdgeInsets.only(top: size * 0.3),
                  child: Icon(Icons.bolt, size: size * 0.45, color: theme.colorScheme.error),
                ),
                piece(fight.defenderPlayer, fight.defender, fight.defenderFalls),
              ],
            ),
          ),
          SizedBox(height: compact ? 6 : 10),
          Opacity(
            opacity: outcome,
            child: Text(
              goFightText(l10n, fight),
              key: const Key('go-reveal-text'),
              textAlign: TextAlign.center,
              style: (compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// The last fight on the hot-seat handover cover (public information), so
/// the attacker sees the outcome before passing the device.
class GoLastFightOnCover extends StatelessWidget {
  final GameController controller;
  const GoLastFightOnCover({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final moves = controller.moves;
    final fight = moves.isEmpty ? null : GoFight.fromMove(moves.last);
    if (fight == null) return const SizedBox.shrink();
    return KeyedSubtree(key: const Key('go-cover-fight'), child: GoFightCard(fight: fight, compact: true));
  }
}
