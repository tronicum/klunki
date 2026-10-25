import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../game/game_controller.dart';

/// Duration of the drop animation of the last piece.
const connect4DropDuration = Duration(milliseconds: 250);

/// Classic 4 Gewinnt colours, slightly adjusted for dark themes.
class Connect4Colors {
  final Color board;
  final Color red;
  final Color yellow;
  final Color hole;
  final Color highlight;

  const Connect4Colors({
    required this.board,
    required this.red,
    required this.yellow,
    required this.hole,
    required this.highlight,
  });

  factory Connect4Colors.of(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Connect4Colors(
      board: dark ? const Color(0xFF0D3C8C) : const Color(0xFF1565C0),
      red: dark ? const Color(0xFFE53935) : const Color(0xFFD32F2F),
      yellow: dark ? const Color(0xFFFFCA28) : const Color(0xFFFFC107),
      hole: theme.colorScheme.surface,
      highlight: Colors.white,
    );
  }

  /// X = red, O = yellow.
  Color piece(Player p) => p == Player.a ? red : yellow;
}

/// A board position in engine coordinates: [row] 0 is the bottom row.
typedef Connect4Pos = ({int col, int row});

/// Cells of the winning line(s) of a finished [game], computed from the board
/// (the engine does not expose the line). Uses the last move, which is part
/// of every winning line; empty if there is no winner.
Set<Connect4Pos> connect4WinningCells(Connect4Game game) {
  final winner = game.result.winner;
  if (winner == null || game.history.isEmpty) return const {};
  final last = game.history.last;
  final col = last['col'] as int, row = last['row'] as int;
  final board = game.board;
  Player? at(int c, int r) =>
      c < 0 || c >= Connect4Game.cols || r < 0 || r >= Connect4Game.rows ? null : board[c][r];

  final out = <Connect4Pos>{};
  const dirs = [(1, 0), (0, 1), (1, 1), (1, -1)];
  for (final (dc, dr) in dirs) {
    final line = <Connect4Pos>[(col: col, row: row)];
    for (final sign in const [1, -1]) {
      var c = col + dc * sign, r = row + dr * sign;
      while (at(c, r) == winner) {
        line.add((col: c, row: r));
        c += dc * sign;
        r += dr * sign;
      }
    }
    if (line.length >= 4) out.addAll(line);
  }
  return out;
}

/// One hole of the board. Key: `c4-cell-<row>-<col>` (row 0 = bottom).
class Connect4Cell extends StatelessWidget {
  /// Piece in this hole (engine state), null = empty.
  final Player? owner;

  /// Part of the winning four.
  final bool winning;

  /// The most recent move.
  final bool lastMove;

  /// The piece is still falling: draw the hole empty for now.
  final bool pending;

  /// Draw the piece faded (game won by a line this piece is not part of).
  final bool faded;

  final double size;

  const Connect4Cell({
    super.key,
    required this.owner,
    required this.size,
    this.winning = false,
    this.lastMove = false,
    this.pending = false,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Connect4Colors.of(context);
    final p = owner;
    final visible = p != null && !pending;
    return SizedBox.square(
      dimension: size,
      child: Padding(
        padding: EdgeInsets.all(size * 0.09),
        child: visible
            ? Connect4Piece(
                color: colors.piece(p),
                faded: faded,
                ring: winning ? colors.highlight : null,
                marker: lastMove && !winning,
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.hole,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: size * 0.04),
                  ],
                ),
              ),
      ),
    );
  }
}

/// A round playing piece.
class Connect4Piece extends StatelessWidget {
  final Color color;
  final Color? ring;
  final bool marker;
  final bool faded;

  const Connect4Piece({super.key, required this.color, this.ring, this.marker = false, this.faded = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final d = c.biggest.shortestSide;
      return Opacity(
        opacity: faded ? 0.55 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.35),
              colors: [Color.lerp(color, Colors.white, 0.25)!, color],
            ),
            border: ring == null
                ? Border.all(color: Colors.black.withValues(alpha: 0.18), width: d * 0.04)
                : Border.all(color: ring!, width: d * 0.1),
            boxShadow: ring == null
                ? null
                : [BoxShadow(color: ring!.withValues(alpha: 0.8), blurRadius: d * 0.25, spreadRadius: d * 0.02)],
          ),
          child: marker
              ? Center(
                  child: Container(
                    width: d * 0.22,
                    height: d * 0.22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ),
                )
              : const SizedBox.expand(),
        ),
      );
    });
  }
}

/// The interactive 7×6 board. Tap anywhere in a column to drop a piece.
///
/// Keys: `c4-column-<c>` per column, `c4-cell-<r>-<c>` per hole (engine
/// coordinates, row 0 = bottom). Each *legal* column additionally carries
/// `legal-move-<i>` (i = index in `legalMoves`), the key contract of the
/// shell's `LegalMoveBoard`, so the generic shell tests keep driving the game.
class Connect4Board extends StatefulWidget {
  final GameController controller;

  const Connect4Board({super.key, required this.controller});

  @override
  State<Connect4Board> createState() => _Connect4BoardState();
}

class _Connect4BoardState extends State<Connect4Board> with SingleTickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(vsync: this, duration: connect4DropDuration, value: 1);
  int _seenMoves = 0;
  int? _hoverCol;
  int? _pressedCol;

  GameController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _seenMoves = _c.moves.length;
    _c.addListener(_onChange);
  }

  @override
  void didUpdateWidget(Connect4Board old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _seenMoves = _c.moves.length;
      _drop.value = 1;
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _drop.dispose();
    super.dispose();
  }

  void _onChange() {
    final n = _c.moves.length;
    if (n == _seenMoves + 1) {
      _drop.forward(from: 0);
    } else {
      _drop.value = 1; // undo / restart: no animation
    }
    _seenMoves = n;
    if (!_c.canAct) {
      _hoverCol = null;
      _pressedCol = null;
    }
    if (mounted) setState(() {});
  }

  void _tap(int col) {
    setState(() => _pressedCol = null);
    final game = _c.game as Connect4Game;
    if (!_c.canAct || !game.legalMoves.contains(col)) return; // full column: no-op
    _c.submit({'col': col});
  }

  @override
  Widget build(BuildContext context) {
    final game = _c.game as Connect4Game;
    final colors = Connect4Colors.of(context);
    final enabled = _c.canAct;
    final legal = game.legalMoves;
    final history = game.history;
    final last = history.isEmpty ? null : history.last;
    final winning = game.isOver ? connect4WinningCells(game) : const <Connect4Pos>{};
    const cols = Connect4Game.cols, rows = Connect4Game.rows;

    return LayoutBuilder(builder: (context, cons) {
      const outer = 12.0;
      const frame = 0.3; // frame padding (both sides) in cells
      final cell = math.max(
        8.0,
        math.min(96.0, math.min((cons.maxWidth - 2 * outer) / (cols + frame), (cons.maxHeight - 2 * outer) / (rows + frame))),
      );
      final pad = cell * frame / 2;
      final width = cell * cols + 2 * pad, height = cell * rows + 2 * pad;
      final highlightCol = enabled ? (_pressedCol ?? _hoverCol) : null;

      return Center(
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cell * 0.18),
            child: ColoredBox(
              color: colors.board,
              child: AnimatedBuilder(
                animation: _drop,
                builder: (context, _) {
                  final falling = last != null && _drop.isAnimating;
                  return Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(pad),
                        child: Row(
                          children: [
                            for (var c = 0; c < cols; c++)
                              _column(
                                c,
                                game: game,
                                cell: cell,
                                legalIndex: legal.indexOf(c),
                                enabled: enabled,
                                highlighted: highlightCol == c && legal.contains(c),
                                last: last,
                                falling: falling,
                                winning: winning,
                              ),
                          ],
                        ),
                      ),
                      if (falling)
                        Positioned(
                          left: pad + (last['col'] as int) * cell,
                          top: _fallTop(pad, cell, last['row'] as int),
                          width: cell,
                          height: cell,
                          child: IgnorePointer(
                            child: Padding(
                              padding: EdgeInsets.all(cell * 0.09),
                              child: Connect4Piece(color: colors.piece(last['player'] as Player)),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }

  double _fallTop(double pad, double cell, int row) {
    final end = pad + (Connect4Game.rows - 1 - row) * cell;
    final t = Curves.easeIn.transform(_drop.value);
    return -cell + (end + cell) * t;
  }

  Widget _column(
    int c, {
    required Connect4Game game,
    required double cell,
    required int legalIndex,
    required bool enabled,
    required bool highlighted,
    required Map<String, dynamic>? last,
    required bool falling,
    required Set<Connect4Pos> winning,
  }) {
    final colors = Connect4Colors.of(context);
    final Widget cells = Column(
      children: [
        for (var r = Connect4Game.rows - 1; r >= 0; r--)
          Connect4Cell(
            key: Key('c4-cell-$r-$c'),
            size: cell,
            owner: game.board[c][r],
            winning: winning.contains((col: c, row: r)),
            faded: winning.isNotEmpty && !winning.contains((col: c, row: r)),
            lastMove: last != null && last['col'] == c && last['row'] == r,
            pending: falling && last!['col'] == c && last['row'] == r,
          ),
      ],
    );
    final Widget column = MouseRegion(
      cursor: enabled && legalIndex >= 0 ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hoverCol = c),
      onExit: (_) {
        if (_hoverCol == c) setState(() => _hoverCol = null);
      },
      child: GestureDetector(
        key: Key('c4-column-$c'),
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressedCol = c) : null,
        onTapCancel: enabled ? () => setState(() => _pressedCol = null) : null,
        onTap: enabled ? () => _tap(c) : null,
        child: Semantics(
          button: true,
          enabled: enabled && legalIndex >= 0,
          label: 'Spalte ${c + 1}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: highlighted ? colors.highlight.withValues(alpha: 0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(cell * 0.5),
            ),
            child: cells,
          ),
        ),
      ),
    );
    // Outermost, so a tap anywhere in the column (also between holes) hits it.
    return legalIndex >= 0 ? KeyedSubtree(key: Key('legal-move-$legalIndex'), child: column) : column;
  }
}
