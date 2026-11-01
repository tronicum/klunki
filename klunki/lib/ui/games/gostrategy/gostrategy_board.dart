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

/// The GoStrategy board (KLD-058b): the setup editor on the board (KLD-081) until the viewer's army
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

  /// Setup draft per player, keyed by engine square (KLD-081): the editor
  /// shows and edits squares on the real board; [GoStrategyGame.setupFromSquares]
  /// turns the draft into the setup move. Kept while arranging, and after an
  /// undo of the setup.
  final Map<Player, Map<int, GoPiece>> _draft = {};

  /// The square picked first for a swap (setup).
  int? _swapFirst;

  /// A square that just refused a piece (outside the own four rows).
  int? _rejected;

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
    _draft.clear();
    _swapFirst = null;
    _rejected = null;
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
        _rejected = null;
        if (moves.length < _seen) {
          // Undo: drop a running reveal. A setup taken back returns to the
          // editor with its draft as it was submitted.
          _fight = null;
          _reveal.stop();
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

  /// [p]'s draft (square → piece), starting from the seeded random setup.
  Map<int, GoPiece> _draftOf(Player p) => _draft.putIfAbsent(
        p,
        () => GoStrategyGame.setupToSquares(
            p, GoStrategyGame.randomSetup(controller.config.seed * 2 + (p == Player.a ? 0 : 1))),
      );

  void _shuffle(Player p) => setState(() {
        _draft[p] = GoStrategyGame.setupToSquares(p, GoStrategyGame.randomSetup(_rng.nextInt(1 << 31)));
        _swapFirst = null;
        _rejected = null;
      });

  /// Moves the piece on [from] to [to], swapping with what stands there.
  /// Only [p]'s home squares take pieces; anything else is refused (and
  /// shown as such).
  void _place(Player p, int from, int to) {
    final draft = _draftOf(p);
    if (!GoStrategyGame.isHome(p, to) || !draft.containsKey(from)) {
      _rejected = to;
      return;
    }
    _rejected = null;
    if (from == to) return;
    final moving = draft[from]!;
    final there = draft[to];
    if (there == null) {
      draft.remove(from);
    } else {
      draft[from] = there;
    }
    draft[to] = moving;
  }

  void _tapSetup(Player p, int sq) => setState(() {
        final first = _swapFirst;
        if (first == null) {
          _rejected = null;
          if (_draftOf(p).containsKey(sq)) _swapFirst = sq;
        } else if (first == sq) {
          _swapFirst = null;
        } else {
          _place(p, first, sq);
          if (_rejected == null) _swapFirst = null;
        }
      });

  void _dropSetup(Player p, int from, int to) => setState(() {
        _swapFirst = null;
        _place(p, from, to);
      });

  bool _setupComplete(Player p) => _draftOf(p).length == GoStrategyGame.piecesPerPlayer;

  void _submitSetup(Player p) {
    if (!_setupComplete(p)) return;
    _swapFirst = null;
    _rejected = null;
    controller.submit(GoStrategyGame.setupMove(GoStrategyGame.setupFromSquares(p, _draftOf(p))));
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
      final picked = first == null ? null : _draftOf(me)[first];
      shell.setHint(_rejected != null
          ? l10n.goSetupInvalid
          : !mine
              ? l10n.goSetupFirst(label(goOther(me)))
              : picked == null
                  ? l10n.goSetupHint
                  : l10n.goSetupSelected(goPieceName(l10n, picked)));
      return _Setup(state: this, me: me, canSubmit: mine, title: l10n.goSetupTitle(label(me)));
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

/// The setup editor on the real 10×10 board (KLD-081): same squares, same
/// orientation as play ([GoBoardFrame], turned for O), the lakes and the
/// neutral rows visible, the enemy's four rows dimmed and empty (their
/// setup is never shown, also not in hot-seat). Only the own four rows take
/// pieces: tap two pieces to swap them, or drag a piece onto another square
/// of the own rows (swap). Cells keep the play keys `go-cell-<square>`, so
/// what you see here is where the pieces will stand.
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
    final draft = state._draftOf(me);
    final complete = state._setupComplete(me);

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
          onPressed: canSubmit && complete ? () => state._submitSetup(me) : null,
          icon: const Icon(Icons.check),
          label: Text(l10n.goSetupDone),
        ),
      ],
    );

    Widget square(int sq, double size) {
      final piece = draft[sq];
      final home = GoStrategyGame.isHome(me, sq);
      final lake = GoStrategyGame.isLake(sq);
      final cell = lake ? const GoCell(lake: true) : GoCell(owner: piece == null ? null : me, piece: piece);
      final content = lake ? l10n.goCellLake : (piece == null ? l10n.goCellFree : goPieceLabel(l10n, piece));
      return DragTarget<int>(
        onWillAcceptWithDetails: (d) => home,
        onAcceptWithDetails: (d) => state._dropSetup(me, d.data, sq),
        builder: (context, accepted, rejected) {
          final view = GoSquareView(
            key: Key('go-cell-$sq'),
            square: sq,
            cell: cell,
            viewer: me,
            selected: state._swapFirst == sq,
            target: false,
            lastMove: false,
            size: size,
            dimmed: !lake && GoStrategyGame.isHome(goOther(me), sq),
            drop: home && accepted.isNotEmpty,
            refused: rejected.isNotEmpty || state._rejected == sq,
            semanticLabel: l10n.goCellLabel(goSquareName(sq), content),
            onTap: lake ? null : () => state._tapSetup(me, sq),
          );
          if (piece == null) return view;
          return Draggable<int>(
            data: sq,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: Transform.translate(
              offset: Offset(-size * 0.5, -size * 0.5),
              child: GoPieceTile(owner: me, piece: piece, size: size * 0.95),
            ),
            childWhenDragging: Opacity(opacity: 0.35, child: view),
            child: view,
          );
        },
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
      final wide = box.maxWidth >= 720 && box.maxWidth > box.maxHeight;
      final header = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, key: const Key('go-setup-title'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          buttons,
        ],
      );
      if (wide) {
        final extent = min(box.maxHeight - 24, box.maxWidth - 340);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Center(child: GoBoardFrame(flip: me == Player.b, extent: extent, square: square))),
              const SizedBox(width: 16),
              SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [header, const SizedBox(height: 12), legend],
                  ),
                ),
              ),
            ],
          ),
        );
      }
      // Phone: header, the board as large as the space allows (as in play),
      // the legend scrolling in what is left.
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: header),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(builder: (context, rest) {
                final extent = min(rest.maxWidth, max(rest.maxHeight - 56, min(rest.maxHeight, 120.0)));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: GoBoardFrame(flip: me == Player.b, extent: extent, square: square)),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                        child: legend,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}

// ------------------------------------------------------------- board frame

/// The 10×10 board with its coordinates, shared by setup and play
/// (KLD-081), so both look and turn the same. [flip] turns it by 180° for O
/// (own army at the bottom); the engine squares are untouched, [square]
/// builds the widget for an engine square. Files a–j under the board and
/// ranks 1–10 on its left turn with it (the names of [goSquareName]).
/// [extent] is the whole size including the coordinate bands.
class GoBoardFrame extends StatelessWidget {
  final bool flip;
  final double extent;
  final Widget Function(int square, double size) square;

  const GoBoardFrame({super.key, required this.flip, required this.extent, required this.square});

  /// Width of the coordinate band for a frame of [extent].
  static double bandFor(double extent) => (extent * 0.045).clamp(12.0, 20.0);

  @override
  Widget build(BuildContext context) {
    final palette = KlunkiPalette.of(context).gostrategy;
    final theme = Theme.of(context);
    final band = bandFor(extent);
    final side = extent - band - 4;
    final cell = side / GoStrategyGame.size;
    final style = theme.textTheme.labelSmall?.copyWith(
      fontSize: (band * 0.62).clamp(9.0, 12.0),
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      height: 1,
    );
    int rowAt(int dr) => flip ? GoStrategyGame.size - 1 - dr : dr;
    int colAt(int dc) => flip ? GoStrategyGame.size - 1 - dc : dc;

    final board = Container(
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
                    Expanded(child: square(GoStrategyGame.square(rowAt(dr), colAt(dc)), cell)),
                ],
              ),
            ),
        ],
      ),
    );

    // A visual aid only: every square's semantics label already names it.
    final ranks = ExcludeSemantics(
      child: SizedBox(
        width: band,
        height: side + 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              for (var dr = 0; dr < GoStrategyGame.size; dr++)
                Expanded(
                  child: Center(
                    child: Text('${GoStrategyGame.size - rowAt(dr)}', key: Key('go-rank-$dr'), style: style),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final files = ExcludeSemantics(
      child: SizedBox(
        width: side + 4,
        height: band,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              for (var dc = 0; dc < GoStrategyGame.size; dc++)
                Expanded(
                  child: Center(
                    child: Text(String.fromCharCode(0x61 + colAt(dc)), key: Key('go-file-$dc'), style: style),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return LtrBoard(
      child: SizedBox(
        width: side + 4 + band,
        height: side + 4 + band,
        child: Column(
          children: [
            Row(children: [ranks, board]),
            Row(children: [SizedBox(width: band), files]),
          ],
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

  /// Setup (KLD-081): the enemy's rows, dimmed; a valid drop under a
  /// dragged piece; a square that refuses a piece (red).
  final bool dimmed, drop, refused;
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
    this.dimmed = false,
    this.drop = false,
    this.refused = false,
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
        child: GoPieceTile(
          owner: owner,
          piece: cell.piece,
          size: size * 0.86,
          moved: cell.moved,
          known: owner == viewer && cell.revealed,
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
                if (dimmed) ColoredBox(key: const Key('go-dimmed'), color: Colors.black.withValues(alpha: 0.22)),
                if (drop) ColoredBox(key: const Key('go-drop'), color: p.target.withValues(alpha: 0.35)),
                ?piece,
                // The selection on top of the piece (KLD-081: it used to sit
                // underneath, hidden by the tile): a thick amber ring with a
                // dark inner line and a glow, clear on red, blue and the land.
                if (selected)
                  IgnorePointer(
                    child: Container(
                      key: const Key('go-selected'),
                      margin: EdgeInsets.all(size * 0.02),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size * 0.2),
                        border: Border.all(color: p.select, width: max(3, size * 0.11)),
                        boxShadow: [BoxShadow(color: p.select.withValues(alpha: 0.7), blurRadius: size * 0.25)],
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(size * 0.12),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.75), width: max(1, size * 0.03)),
                        ),
                      ),
                    ),
                  ),
                if (refused)
                  Container(
                    key: const Key('go-refused'),
                    decoration: BoxDecoration(
                      color: p.attack.withValues(alpha: 0.25),
                      border: Border.all(color: p.attack, width: max(2, size * 0.07)),
                    ),
                  ),
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

    Widget square(int sq, double size) => GoSquareView(
          key: Key('go-cell-$sq'),
          square: sq,
          cell: view[sq],
          viewer: me,
          selected: state._selected == sq,
          target: targets.contains(sq),
          lastMove: last != null && (last.$1 == sq || last.$2 == sq),
          size: size,
          semanticLabel: cellLabel(sq),
          onTap: canAct && !view[sq].lake ? () => state._tapSquare(me, view, sq) : null,
        );

    final fight = state._fight;
    Widget boardWithReveal(double extent) => Stack(
          children: [
            GoBoardFrame(flip: flip, extent: extent, square: square),
            if (fight != null)
              Positioned.fill(child: _FightReveal(fight: fight, animation: state._reveal, onDismiss: state._dismissReveal)),
          ],
        );

    final panel = _ArmyPanel(game: g, me: me);

    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 720 && box.maxWidth > box.maxHeight;
      if (wide) {
        final side = min(box.maxHeight - 24, box.maxWidth - 340);
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
      final side = min(box.maxWidth - 16, box.maxHeight * 0.68);
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
        side(me, l10n.goArmyOwn),
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
