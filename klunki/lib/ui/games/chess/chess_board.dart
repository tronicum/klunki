import 'dart:math';

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../ltr.dart';
import '../../shell/game_screen.dart';
import 'chess_pieces.dart';

/// The interactive chess board (KLD-059 step 2).
///
/// * Tap one of your pieces: it gets the selection ring, its legal targets a
///   dot (quiet move) or a ring (capture, also en passant). Tap a target to
///   move, the piece again or anything else to deselect. Pieces can also be
///   dragged onto a target. Castling is the king's two-square move.
/// * A pawn move to the last rank opens the promotion picker (queen, rook,
///   bishop, knight in the mover's colour); cancelling leaves the pawn.
/// * Last move (from and to) tinted, the king in check in red, "Schach!" as
///   a badge.
/// * Orientation: in hot-seat the board turns to the side to move (like
///   GoStrategy turns to its player), unless "turn automatically" is off;
///   the flip button turns it by 180° on top of that. On a network device
///   the own side is at the bottom.
/// * Captured pieces per side with the material balance, and the move list
///   in SAN (one scrollable line, the latest move always visible).
///
/// Keys for tests: squares `chess-sq-<e4>` ([ChessSquareView]), `chess-flip`,
/// `chess-auto-flip`, `chess-check`, `chess-moves`, `chess-move-<i>`,
/// `chess-captured-<a|b>`, `chess-promotion` with `chess-promote-<q|r|b|n>`
/// and `chess-promote-cancel`, coordinates `chess-file-<i>` / `chess-rank-<i>`
/// (screen order).
class ChessBoard extends StatefulWidget {
  final GameController controller;

  const ChessBoard({super.key, required this.controller});

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  String? _selected;
  bool _autoFlip = true;
  bool _flipped = false;
  bool _promoting = false;
  late GameTransport _transport;
  int _seen = 0;

  GameController get controller => widget.controller;
  ChessGame get game => controller.game as ChessGame;

  @override
  void initState() {
    super.initState();
    _transport = controller.transport;
    _seen = controller.moves.length;
    controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(ChessBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _transport = controller.transport;
      _seen = controller.moves.length;
      _selected = null;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {
      if (!identical(_transport, controller.transport) || controller.moves.length != _seen) {
        _transport = controller.transport;
        _seen = controller.moves.length;
        _selected = null;
      }
    });
  }

  /// The side shown at the bottom.
  Player get _bottom {
    final local = controller.transport.localPlayers;
    final base = local.length == 1 ? local.single : (_autoFlip ? game.currentPlayer : Player.a);
    return _flipped ? (base == Player.a ? Player.b : Player.a) : base;
  }

  bool get _canMove => controller.canAct && !_promoting;

  List<Map<String, dynamic>> _movesFrom(String? sq) => sq == null || !_canMove ? const [] : game.legalMovesFrom(sq);

  // ------------------------------------------------------------ interaction

  void _tap(String sq) {
    if (!_canMove) return;
    final from = _selected;
    if (from != null && _tryMove(from, sq)) return;
    final piece = game.pieceAt(sq);
    setState(() {
      _selected = piece != null && piece.color == game.currentPlayer && sq != from ? sq : null;
    });
  }

  /// Moves the selected piece from [from] to [to] if that is legal (asking
  /// for the promotion piece first); false if it is no legal target.
  bool _tryMove(String from, String to) {
    final moves = [for (final m in _movesFrom(from)) if (m['to'] == to) m];
    if (moves.isEmpty) return false;
    if (moves.length == 1) {
      setState(() => _selected = null);
      controller.submit(moves.single);
    } else {
      _promote(from, to);
    }
    return true;
  }

  Future<void> _promote(String from, String to) async {
    final color = game.currentPlayer;
    setState(() {
      _selected = from;
      _promoting = true;
    });
    final letter = await showDialog<String>(
      context: context,
      builder: (ctx) => ChessPromotionDialog(color: color),
    );
    if (!mounted) return;
    setState(() {
      _promoting = false;
      _selected = null;
    });
    if (letter == null || game.currentPlayer != color || controller.game.isOver) return;
    controller.submit({'action': 'move', 'from': from, 'to': to, 'promotion': letter});
  }

  void _dragStarted(String sq) {
    if (!_canMove) return;
    setState(() => _selected = sq);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = game;
    GameScreen.of(context).setHint(g.isOver || !controller.canAct
        ? null
        : _selected == null
            ? l10n.chessHintSelect
            : l10n.chessHintTarget);

    final bottom = _bottom;
    final top = bottom == Player.a ? Player.b : Player.a;
    final check = !g.isOver && g.isInCheck;

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('chess-flip'),
          tooltip: l10n.chessFlipBoard,
          icon: const Icon(Icons.swap_vert),
          onPressed: () => setState(() => _flipped = !_flipped),
        ),
        if (controller.transport.localPlayers.length > 1)
          IconButton(
            key: const Key('chess-auto-flip'),
            tooltip: l10n.chessAutoFlip,
            isSelected: _autoFlip,
            icon: const Icon(Icons.screen_rotation_outlined),
            selectedIcon: const Icon(Icons.screen_rotation),
            onPressed: () => setState(() => _autoFlip = !_autoFlip),
          ),
      ],
    );
    final checkBadge = check ? const _CheckBadge() : const SizedBox.shrink();
    final moves = _MoveList(san: g.sanHistory, wrap: true);

    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 720 && box.maxWidth > box.maxHeight;
      if (wide) {
        final extent = min(box.maxHeight - 24, box.maxWidth - 340);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Center(child: _frame(context, extent, bottom))),
              const SizedBox(width: 16),
              SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Captured(controller: controller, player: top),
                    const SizedBox(height: 8),
                    Row(children: [checkBadge, const Spacer(), controls]),
                    const SizedBox(height: 8),
                    Expanded(child: _MovePane(child: moves)),
                    const SizedBox(height: 8),
                    _Captured(controller: controller, player: bottom),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      // Phone: captured (top side), board, captured (bottom side), the
      // check badge with the buttons, then the move list (wrapped, scrolled
      // to the latest move) in the height that is left.
      const reserved = 2 * 30 + 48 + 44;
      final extent = max(160.0, min(box.maxWidth - 16, box.maxHeight - reserved));
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        child: Column(
          children: [
            SizedBox(width: extent, child: _Captured(controller: controller, player: top)),
            _frame(context, extent, bottom),
            SizedBox(width: extent, child: _Captured(controller: controller, player: bottom)),
            SizedBox(
              width: extent,
              height: 48,
              child: Row(children: [checkBadge, const Spacer(), controls]),
            ),
            Expanded(
              child: SizedBox(
                width: extent,
                child: _MovePane(child: moves),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _frame(BuildContext context, double extent, Player bottom) {
    final g = game;
    final l10n = AppLocalizations.of(context);
    final board = g.board;
    final selected = _selected;
    final legal = _movesFrom(selected);
    final targets = {for (final m in legal) m['to'] as String};
    final last = _lastMove(controller.moves);
    final checkSquare = g.isInCheck ? _kingSquare(board, g.currentPlayer) : null;
    final canMove = _canMove;

    Widget square(String name, double size) {
      final i = ChessGame.squareIndex(name)!;
      final piece = board[i];
      final from = selected == null ? null : board[ChessGame.squareIndex(selected)!];
      final isTarget = targets.contains(name);
      // En passant: a pawn moving diagonally captures on an empty square.
      final capture = isTarget && (piece != null || (from?.type == ChessPieceType.pawn && selected![0] != name[0]));
      final label = piece == null
          ? l10n.chessSquareEmpty(name)
          : l10n.chessSquarePiece(name, chessPieceName(l10n, piece.type), chessSideName(l10n, piece.color));
      final view = ChessSquareView(
        key: Key('chess-sq-$name'),
        square: name,
        piece: piece,
        size: size,
        selected: selected == name,
        target: isTarget && !capture,
        captureTarget: capture,
        lastMove: last != null && (last.$1 == name || last.$2 == name),
        check: checkSquare == name,
        semanticLabel: label,
        onTap: canMove ? () => _tap(name) : null,
      );
      final movable = canMove && piece != null && piece.color == g.currentPlayer;
      Widget child = view;
      if (movable) {
        child = Draggable<String>(
          data: name,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          onDragStarted: () => _dragStarted(name),
          feedback: Transform.translate(
            offset: Offset(-size * 0.6, -size * 0.6),
            child: ChessPieceIcon(piece: piece, size: size * 1.2),
          ),
          childWhenDragging: ChessSquareView(
            square: name,
            piece: null,
            size: size,
            selected: true,
            target: false,
            captureTarget: false,
            lastMove: false,
            check: false,
            semanticLabel: label,
          ),
          child: view,
        );
      }
      if (!canMove) return child;
      return DragTarget<String>(
        onWillAcceptWithDetails: (d) => d.data != name,
        onAcceptWithDetails: (d) {
          if (!_tryMove(d.data, name)) setState(() => _selected = null);
        },
        builder: (context, accepted, rejected) => child,
      );
    }

    return ChessBoardFrame(flip: bottom == Player.b, extent: extent, square: square);
  }

  static String? _kingSquare(List<ChessPiece?> board, Player color) {
    for (var i = 0; i < 64; i++) {
      final p = board[i];
      if (p != null && p.type == ChessPieceType.king && p.color == color) return ChessGame.squareName(i);
    }
    return null;
  }

  /// From / to of the most recent board move (null before the first one).
  static (String, String)? _lastMove(List<AcceptedMove> moves) {
    for (var i = moves.length - 1; i >= 0; i--) {
      final m = moves[i].move;
      if (m['action'] == 'move') return (m['from'] as String, m['to'] as String);
    }
    return null;
  }
}

// ------------------------------------------------------------- board frame

/// The 8×8 board with files a–h under it and ranks 1–8 on its left, turned
/// by 180° for [flip] (Black at the bottom). [square] builds the widget for
/// a square name; [extent] is the whole size including the coordinate bands.
class ChessBoardFrame extends StatelessWidget {
  final bool flip;
  final double extent;
  final Widget Function(String square, double size) square;

  const ChessBoardFrame({super.key, required this.flip, required this.extent, required this.square});

  /// Width of the coordinate band for a frame of [extent].
  static double bandFor(double extent) => (extent * 0.045).clamp(12.0, 20.0);

  @override
  Widget build(BuildContext context) {
    final palette = KlunkiPalette.of(context).chess;
    final theme = Theme.of(context);
    final band = bandFor(extent);
    final side = extent - band - 6;
    final cell = side / 8;
    final style = theme.textTheme.labelSmall?.copyWith(
      fontSize: (band * 0.62).clamp(9.0, 12.0),
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      height: 1,
    );
    // Screen row 0 is rank 8 for White at the bottom, rank 1 when flipped.
    int rankAt(int dr) => flip ? dr : 7 - dr;
    int fileAt(int dc) => flip ? 7 - dc : dc;

    final board = Container(
      key: const Key('chess-board'),
      width: side + 6,
      height: side + 6,
      decoration: BoxDecoration(
        color: palette.edge,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          for (var dr = 0; dr < 8; dr++)
            Expanded(
              child: Row(
                children: [
                  for (var dc = 0; dc < 8; dc++)
                    Expanded(child: square(ChessGame.squareName(rankAt(dr) * 8 + fileAt(dc)), cell)),
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
        height: side + 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            children: [
              for (var dr = 0; dr < 8; dr++)
                Expanded(child: Center(child: Text('${rankAt(dr) + 1}', key: Key('chess-rank-$dr'), style: style))),
            ],
          ),
        ),
      ),
    );
    final files = ExcludeSemantics(
      child: SizedBox(
        width: side + 6,
        height: band,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Row(
            children: [
              for (var dc = 0; dc < 8; dc++)
                Expanded(
                  child: Center(
                    child: Text(String.fromCharCode(0x61 + fileAt(dc)), key: Key('chess-file-$dc'), style: style),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return LtrBoard(
      child: SizedBox(
        width: side + 6 + band,
        height: side + 6 + band,
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

/// One square as rendered (tests read its fields).
class ChessSquareView extends StatelessWidget {
  final String square;
  final ChessPiece? piece;
  final double size;

  /// [target]: a quiet legal move ends here (dot); [captureTarget]: a
  /// capture does (ring), en passant included.
  final bool selected, target, captureTarget, lastMove, check;
  final String semanticLabel;
  final VoidCallback? onTap;

  const ChessSquareView({
    super.key,
    required this.square,
    required this.piece,
    required this.size,
    required this.selected,
    required this.target,
    required this.captureTarget,
    required this.lastMove,
    required this.check,
    required this.semanticLabel,
    this.onTap,
  });

  bool get light => ((square.codeUnitAt(0) - 0x61) + (square.codeUnitAt(1) - 0x31)).isOdd;

  @override
  Widget build(BuildContext context) {
    final p = KlunkiPalette.of(context).chess;
    final pc = piece;
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ColoredBox(
          color: light ? p.lightSquare : p.darkSquare,
          child: ExcludeSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (lastMove) ColoredBox(key: const Key('chess-last'), color: p.lastMove),
                if (check)
                  DecoratedBox(
                    key: const Key('chess-in-check'),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [p.check, p.check.withValues(alpha: 0.55), p.check.withValues(alpha: 0)],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                if (pc != null) Center(child: ChessPieceIcon(piece: pc, size: size * 0.9)),
                if (selected)
                  IgnorePointer(
                    child: Container(
                      key: const Key('chess-selected'),
                      decoration: BoxDecoration(
                        border: Border.all(color: p.select, width: max(3, size * 0.1)),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black.withValues(alpha: 0.7), width: max(1, size * 0.025)),
                        ),
                      ),
                    ),
                  ),
                if (target)
                  Center(
                    child: Container(
                      key: const Key('chess-target-dot'),
                      width: size * 0.3,
                      height: size * 0.3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.target.withValues(alpha: 0.8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                      ),
                    ),
                  ),
                if (captureTarget)
                  IgnorePointer(
                    child: Container(
                      key: const Key('chess-target-capture'),
                      margin: EdgeInsets.all(size * 0.03),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: p.target.withValues(alpha: 0.9), width: max(3, size * 0.09)),
                      ),
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

/// The promotion picker: queen, rook, bishop, knight in [color]; pops the
/// letter (`q`, `r`, `b`, `n`) or null (cancel: the pawn stays).
class ChessPromotionDialog extends StatelessWidget {
  final Player color;
  const ChessPromotionDialog({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = KlunkiPalette.of(context).chess;
    return AlertDialog(
      key: const Key('chess-promotion'),
      title: Text(l10n.chessPromotionTitle),
      content: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in const [ChessPieceType.queen, ChessPieceType.rook, ChessPieceType.bishop, ChessPieceType.knight])
            Tooltip(
              message: chessPieceName(l10n, t),
              child: Semantics(
                button: true,
                label: chessPieceName(l10n, t),
                child: InkWell(
                  key: Key('chess-promote-${t.letter}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pop(t.letter),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: c.lightSquare,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.edge, width: 1.5),
                    ),
                    child: ExcludeSemantics(child: ChessPieceIcon(piece: ChessPiece(color, t), size: 56)),
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('chess-promote-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.shellCancel),
        ),
      ],
    );
  }
}

/// "Schach!" as a red badge while the side to move is in check.
class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = KlunkiPalette.of(context).chess;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('chess-check'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFC62828), borderRadius: BorderRadius.circular(14), boxShadow: [
          BoxShadow(color: p.check.withValues(alpha: 0.4), blurRadius: 6),
        ]),
        child: Text(
          l10n.chessCheck,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// The moves in SAN: "1. e4 e5 2. Nf3 …", the latest in bold. One line that
/// scrolls sideways and starts at the end (phone), or wrapped ([wrap]).
class _MoveList extends StatelessWidget {
  final List<String> san;
  final bool wrap;
  const _MoveList({required this.san, this.wrap = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium;
    final muted = base?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final items = <Widget>[];
    for (var i = 0; i < san.length; i++) {
      final number = i.isEven ? '${i ~/ 2 + 1}.' : null;
      items.add(Padding(
        padding: const EdgeInsetsDirectional.only(end: 6),
        child: Text.rich(
          TextSpan(children: [
            if (number != null) TextSpan(text: '$number ', style: muted),
            TextSpan(
              text: san[i],
              style: i == san.length - 1 ? base?.copyWith(fontWeight: FontWeight.w700) : base,
            ),
          ]),
          key: Key('chess-move-$i'),
        ),
      ));
    }
    // SAN reads left to right in every locale.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: wrap
          ? Wrap(key: const Key('chess-moves'), runSpacing: 4, children: items)
          : Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                key: const Key('chess-moves'),
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(children: items),
              ),
            ),
    );
  }
}

/// The pieces [player] has captured (in the opponent's colour, most
/// valuable first) and, when ahead, the material balance ("+3").
class _Captured extends StatelessWidget {
  final GameController controller;
  final Player player;
  const _Captured({required this.controller, required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mine = <ChessPieceType>[], theirs = <ChessPieceType>[];
    for (final m in controller.moves) {
      final payload = m.event.payload;
      final t = chessPieceTypeOf(payload is Map ? payload['capture'] : null);
      if (t == null) continue;
      (m.player == player ? mine : theirs).add(t);
    }
    int value(List<ChessPieceType> l) => l.fold(0, (s, t) => s + chessPieceValue(t));
    final lead = value(mine) - value(theirs);
    mine.sort((a, b) => chessPieceValue(b).compareTo(chessPieceValue(a)));
    final opponent = player == Player.a ? Player.b : Player.a;
    final chip = KlunkiPalette.of(context).chess.lightSquare;
    return SizedBox(
      key: Key('chess-captured-${player.name}'),
      height: 30,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            if (mine.isNotEmpty)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: chip.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
                  child: ClipRect(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final t in mine)
                          Align(widthFactor: 0.7, child: ChessPieceIcon(piece: ChessPiece(opponent, t), size: 22)),
                      ],
                    ),
                  ),
                ),
              ),
            if (lead > 0)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text('+$lead', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
          ],
        ),
      ),
    );
  }
}

/// The move list in the remaining height: top-aligned while it fits,
/// scrolled to the latest move once it does not.
class _MovePane extends StatelessWidget {
  final Widget child;
  const _MovePane({required this.child});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          reverse: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight, minWidth: box.maxWidth),
            child: Align(alignment: AlignmentDirectional.topStart, child: child),
          ),
        ),
      );
}
