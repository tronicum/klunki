import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../game/game_controller.dart';
import '../../../app/theme.dart';
import '../../ltr.dart';

/// Duration of the drop animation of the last piece.
const connect4DropDuration = Duration(milliseconds: 250);

/// 4 Gewinnt colours from the theme's [KlunkiPalette] (classic preset: blue
/// frame, red and yellow pieces, holes in the page colour).
class Connect4Colors {
  final Color board;
  final Color boardShade;
  final Color red;
  final Color yellow;
  final Color hole;
  final Color highlight;

  const Connect4Colors({
    required this.board,
    this.boardShade = const Color(0xFF0D3C8C),
    required this.red,
    required this.yellow,
    required this.hole,
    required this.highlight,
  });

  factory Connect4Colors.of(BuildContext context) {
    final p = KlunkiPalette.of(context).connect4;
    return Connect4Colors(
      board: p.board,
      boardShade: p.boardShade,
      red: p.red,
      yellow: p.yellow,
      hole: p.hole,
      highlight: p.highlight,
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
  // Only a four in a row has a line (not a resign, KLD-065).
  if (winner == null || game.result.code != GameEndReason.connect4FourInARow || game.history.isEmpty) return const {};
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
                ringed: p == Player.b,
                faded: faded,
                ring: winning ? colors.highlight : null,
                marker: lastMove && !winning,
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // A hole: darker at the top edge (inner shadow look).
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(colors.hole, Colors.black, 0.22)!, colors.hole, colors.hole],
                    stops: const [0, 0.35, 1],
                  ),
                  border: Border.all(color: colors.boardShade, width: size * 0.025),
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

  /// Draw an embossed inner ring (player O), so X and O differ by shape as
  /// well as by colour (UX-REVIEW 2.10).
  final bool ringed;

  const Connect4Piece(
      {super.key, required this.color, this.ring, this.marker = false, this.faded = false, this.ringed = false});

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
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: d * 0.05, offset: Offset(0, d * 0.04))]
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
              : ringed
                  ? Center(
                      child: Container(
                        width: d * 0.56,
                        height: d * 0.56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.16), width: d * 0.05),
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
/// coordinates, row 0 = bottom).
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
    if (n == _seenMoves + 1 && !reduceMotion(context)) {
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

    // LtrBoard: column 0 is always on the left (RTL locales too), so the Row
    // of columns and the Positioned(left:) drop animation match engine indices.
    return LtrBoard(child: LayoutBuilder(builder: (context, cons) {
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
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cell * 0.18),
            boxShadow: [
              BoxShadow(color: colors.boardShade, offset: Offset(0, cell * 0.08)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: cell * 0.2, offset: Offset(0, cell * 0.1)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cell * 0.18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(colors.board, Colors.white, 0.08)!, colors.board],
                ),
              ),
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
    }));
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
          label: AppLocalizations.of(context).connect4Column(c + 1),
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
    return column;
  }
}
