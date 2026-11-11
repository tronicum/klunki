import 'dart:math';

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../../transport/game_clock.dart';
import '../../../transport/game_transport.dart';
import '../../../transport/hot_seat_transport.dart';
import '../../ltr.dart';
import '../../shell/confirm_move.dart';
import '../../shell/game_screen.dart';
import 'chess_clock_view.dart';
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
///   the own colour is at the bottom (KLD-059 step 4a: the host may play
///   Black, so that is not always A = White), and the hint line says "Du
///   spielst Weiß/Schwarz" until the first board move.
/// * Captured pieces per side with the material balance, and the move list
///   in SAN (one scrollable line, the latest move always visible).
/// * Draw offer (KLD-059 step 3): on the own turn the handshake button
///   offers a draw (after a confirmation); the pieces wait until the other
///   player has accepted or declined it in a dialog; it closes by itself when the offer goes away underneath it
///   (e.g. a resign). The hint line tells the offerer that the other side
///   decides, and both sides when an offer was declined.
///
/// * "Zug bestätigen" (KLD-122): when it is on for the mover
///   ([confirmMoveFor]: the device's choice over the network, the seat's in
///   hot-seat), a chosen move (tap, drag, or promotion after the piece is
///   picked) is only shown: the piece on its target, a faint copy on the
///   square it left, a captured piece small and faint in the corner of its
///   square, and "✗ Anders ziehen" / "✓ Ziehen" under the board ([ConfirmMoveBar]).
///   Nothing is submitted before "Ziehen"; "Anders ziehen" restores the board. A
///   draw offer, a resign or an undo drops the pending move.
///
/// Keys for tests: squares `chess-sq-<e4>` ([ChessSquareView]), `chess-flip`,
/// `chess-auto-flip`, `chess-check`, `chess-moves`, `chess-move-<i>`,
/// `chess-captured-<a|b>`, `chess-promotion` with `chess-promote-<q|r|b|n>`
/// and `chess-promote-cancel`, the draw offer `chess-offer-draw`,
/// `chess-offer-dialog` (`chess-offer-confirm` / `chess-offer-cancel`) and
/// `chess-draw-offer-dialog` (`chess-draw-accept` / `chess-draw-decline`),
/// coordinates `chess-file-<i>` / `chess-rank-<i>`
/// (screen order).
class ChessBoard extends StatefulWidget {
  final GameController controller;

  const ChessBoard({super.key, required this.controller});

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> with WidgetsBindingObserver {
  String? _selected;
  bool _autoFlip = true;
  bool _flipped = false;
  bool _promoting = false;
  late GameTransport _transport;
  int _seen = 0;

  /// The open "accept the draw?" dialog and the log index of the offer it
  /// answers.
  ModalRoute<Object?>? _offerRoute;
  int? _offerShownFor;

  /// The open "offer a draw?" confirmation, closed when the game ends.
  ModalRoute<Object?>? _confirmRoute;

  /// The move waiting for "Ziehen" (KLD-122), or null.
  _Pending? _pending;

  GameController get controller => widget.controller;
  ChessGame get game => controller.game as ChessGame;

  @override
  void initState() {
    super.initState();
    _transport = controller.transport;
    _seen = controller.moves.length;
    controller.addListener(_onChange);
    _listenClock(null, _transport);
    WidgetsBinding.instance.addObserver(this);
    _syncDrawOffer(); // e.g. a guest that rejoins while an offer is open
  }

  // ------------------------------------------------------------------ clock

  /// The transport with a chess clock (KLD-126), or null.
  ClockedTransport? get _clocked {
    final t = controller.transport;
    return t is ClockedTransport && (t as ClockedTransport).clock != null ? t as ClockedTransport : null;
  }

  void _listenClock(GameTransport? old, GameTransport? now) {
    if (old is ClockedTransport) (old as ClockedTransport).clockChanges.removeListener(_onClock);
    if (now is ClockedTransport) (now as ClockedTransport).clockChanges.addListener(_onClock);
  }

  void _onClock() {
    if (mounted) setState(() {});
  }

  /// Whether the clocks stand still: the hot-seat pause cover or an agreed
  /// pause of a network game.
  bool get _paused {
    final t = controller.transport;
    if (_clocked == null || game.isOver) return false;
    return t is HotSeatTransport ? t.clockPaused : game.clockPaused;
  }

  /// Hot-seat: the device goes to the background (a call, the phone
  /// locked): the clocks stop behind the pause cover.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final t = controller.transport;
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.hidden) &&
        t is HotSeatTransport &&
        t.clock != null &&
        !game.isOver) {
      t.setClockPaused(true);
    }
  }

  /// "Pause": on one device at once, over the network a request.
  void _pause() {
    final t = controller.transport;
    if (t is HotSeatTransport) return t.setClockPaused(true);
    final me = _offerer;
    if (game.canRequestClock(me)) controller.submit(ChessGame.clockMove(ChessGame.clockPause, me));
  }

  /// "Weiter" on the cover: on one device at once, over the network a
  /// request.
  void _resume() {
    final t = controller.transport;
    if (t is HotSeatTransport) return t.setClockPaused(false);
    final me = _offerer;
    if (game.canRequestClock(me)) controller.submit(ChessGame.clockMove(ChessGame.clockResume, me));
  }

  /// The local player who answers the open pause / resume request, or null.
  Player? get _clockAnswerer {
    final r = game.clockRequest;
    if (r == null) return null;
    final to = _other(r.by);
    return controller.transport.localPlayers.contains(to) ? to : null;
  }

  void _answerClock(bool agree) {
    final to = _clockAnswerer;
    if (to == null) return;
    controller.submit(ChessGame.clockMove(agree ? ChessGame.clockAgree : ChessGame.clockRefuse, to));
  }

  /// The hint about a pause request (network): "Angefragt – Ben
  /// entscheidet." on the asking device, "Ben möchte nicht." after a
  /// refusal; null otherwise.
  String? _clockHint(AppLocalizations l10n) {
    final r = game.clockRequest;
    if (r != null) {
      final to = _other(r.by);
      return controller.transport.localPlayers.contains(to) ? null : l10n.chessClockWaiting(playerName(context, to));
    }
    final moves = controller.moves;
    if (moves.isEmpty || moves.last.move['action'] != ChessGame.clockRefuse) return null;
    return l10n.chessClockRefusedHint(playerName(context, moves.last.player));
  }

  /// The captured pieces of [player] with the player's clock at the end.
  Widget _side(Player player) {
    final clocked = _clocked;
    final captured = _Captured(controller: controller, player: player);
    if (clocked == null) return captured;
    return Row(
      children: [
        Expanded(child: captured),
        const SizedBox(width: 6),
        ChessClockFace(transport: clocked, player: player, playerLabel: playerName(context, player)),
      ],
    );
  }

  /// The board with the pause cover (KLD-126) or, over the network, the
  /// question of the other player on top.
  Widget _withClockOverlay(Widget board) {
    if (_clocked == null || game.isOver) return board;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final request = game.clockRequest;
    final answerer = _clockAnswerer;
    Widget answerButtons() => Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            OutlinedButton(
              key: const Key('chess-clock-refuse'),
              onPressed: () => _answerClock(false),
              child: Text(l10n.chessDrawDecline),
            ),
            FilledButton(
              key: const Key('chess-clock-agree'),
              onPressed: () => _answerClock(true),
              child: Text(l10n.chessDrawAccept),
            ),
          ],
        );
    final Widget? overlay;
    if (_paused) {
      overlay = Positioned.fill(
        child: Container(
          key: const Key('chess-pause-cover'),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pause_circle_outline, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(l10n.chessClockPausedTitle, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (request != null && answerer != null) ...[
                    Text(l10n.chessClockResumeAsk(playerName(context, request.by)), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    answerButtons(),
                  ] else if (request != null)
                    Text(l10n.chessClockWaiting(playerName(context, _other(request.by))), textAlign: TextAlign.center)
                  else
                    FilledButton.icon(
                      key: const Key('chess-resume'),
                      onPressed: _resume,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.chessClockResume),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (request != null && answerer != null && !request.resume) {
      overlay = Positioned(
        left: 8,
        right: 8,
        top: 8,
        child: Material(
          key: const Key('chess-clock-request'),
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.chessClockPauseAsk(playerName(context, request.by)), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                answerButtons(),
              ],
            ),
          ),
        ),
      );
    } else {
      overlay = null;
    }
    if (overlay == null) return board;
    return Stack(children: [board, overlay]);
  }

  @override
  void didUpdateWidget(ChessBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _listenClock(_transport, controller.transport);
      _transport = controller.transport;
      _seen = controller.moves.length;
      _selected = null;
      _pending = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listenClock(_transport, null);
    controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {
      if (!identical(_transport, controller.transport) || controller.moves.length != _seen) {
        if (!identical(_transport, controller.transport)) _listenClock(_transport, controller.transport);
        _transport = controller.transport;
        _seen = controller.moves.length;
        _selected = null;
        _pending = null; // a resign, a draw offer, an undo, a restart
      }
      if (game.isOver) _pending = null;
    });
    _syncDrawOffer();
    if (game.isOver) {
      final r = _confirmRoute;
      _confirmRoute = null;
      _closeRoute(r);
    }
  }

  // ------------------------------------------------------------- draw offer

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;

  /// Who offers a draw from this device: the own player on a network
  /// device, the player to move in hot-seat.
  Player get _offerer {
    final local = controller.transport.localPlayers;
    return local.length == 1 ? local.single : game.currentPlayer;
  }

  /// The local player who has to answer the open draw offer, or null.
  Player? get _offerTo {
    final by = game.drawOfferBy;
    if (by == null) return null;
    final to = _other(by);
    return controller.transport.localPlayers.contains(to) ? to : null;
  }

  /// Log index of the most recent draw offer (-1 if none).
  int get _lastOfferIndex => controller.moves.lastIndexWhere((m) => m.move['action'] == ChessGame.offerDraw);

  /// Shows the answer dialog for a new open offer to a local player, closes
  /// it when the offer is gone.
  void _syncDrawOffer() {
    final to = _offerTo;
    if (to == null) {
      _offerShownFor = null;
      final r = _offerRoute;
      _offerRoute = null;
      _closeRoute(r);
      return;
    }
    final index = _lastOfferIndex;
    if (_offerShownFor == index) return;
    _offerShownFor = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _offerTo == to && _offerShownFor == index) _answerDrawOffer(to);
    });
  }

  static void _closeRoute(ModalRoute<Object?>? r) {
    final nav = r?.navigator;
    if (r == null || nav == null || !r.isActive) return;
    if (r.isCurrent) {
      nav.pop();
    } else {
      nav.removeRoute(r);
    }
  }

  Future<void> _answerDrawOffer(Player to) async {
    final l10n = AppLocalizations.of(context);
    final by = _other(to);
    final name = playerName(context, by);
    final accent = KlunkiPalette.of(context).accent(controller.spec.id);
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        _offerRoute = ModalRoute.of(ctx);
        return AlertDialog(
          key: const Key('chess-draw-offer-dialog'),
          icon: Icon(Icons.handshake_outlined, size: 36, color: accent.onSurface(Theme.of(ctx).brightness)),
          title: Text(l10n.chessDrawOfferTitle),
          content: Text(l10n.chessDrawOfferBody(name)),
          actions: [
            TextButton(
              key: const Key('chess-draw-decline'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.chessDrawDecline),
            ),
            FilledButton(
              key: const Key('chess-draw-accept'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.chessDrawAccept),
            ),
          ],
        );
      },
    );
    _offerRoute = null;
    if (accept == null || !mounted || game.drawOfferBy != by) return;
    final r = await controller.submit(accept ? ChessGame.acceptDrawMove(to) : ChessGame.declineDrawMove(to));
    // Not delivered (e.g. the connection dropped): ask again while the
    // offer is still open.
    if (!r.isAccepted && mounted && game.drawOfferBy == by) {
      _offerShownFor = null;
      _syncDrawOffer();
    }
  }

  /// "Remis anbieten": confirm, then send the offer.
  Future<void> _offerDraw() async {
    final me = _offerer;
    if (!game.canOfferDraw(me)) return;
    final l10n = AppLocalizations.of(context);
    final name = playerName(context, _other(me));
    final accent = KlunkiPalette.of(context).accent(controller.spec.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        _confirmRoute = ModalRoute.of(ctx);
        return AlertDialog(
          key: const Key('chess-offer-dialog'),
          icon: Icon(Icons.handshake_outlined, size: 36, color: accent.onSurface(Theme.of(ctx).brightness)),
          title: Text(l10n.chessOfferDrawTitle),
          content: Text(l10n.chessOfferDrawBody(name)),
          actions: [
            TextButton(
              key: const Key('chess-offer-cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.shellCancel),
            ),
            FilledButton(
              key: const Key('chess-offer-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.chessOfferDrawConfirm),
            ),
          ],
        );
      },
    );
    _confirmRoute = null;
    if (ok != true || !mounted || !game.canOfferDraw(me)) return;
    setState(() => _pending = null);
    controller.submit(ChessGame.offerDrawMove(me));
  }

  /// The hint about a draw offer: "Remis angeboten – Ben entscheidet." while
  /// the other device decides, "Ben lehnt das Remis ab." right after a
  /// decline; null otherwise.
  String? _drawHint(AppLocalizations l10n) {
    final by = game.drawOfferBy;
    if (by != null) {
      final to = _other(by);
      return controller.transport.localPlayers.contains(to) ? null : l10n.chessHintDrawOffered(playerName(context, to));
    }
    final moves = controller.moves;
    if (moves.isEmpty || moves.last.move['action'] != ChessGame.declineDraw) return null;
    return l10n.chessHintDrawDeclined(playerName(context, moves.last.player));
  }

  /// The player shown at the bottom: the own player on a network device; in
  /// hot-seat the player to move, or White with auto-turn off.
  Player get _bottom {
    final local = controller.transport.localPlayers;
    final base = local.length == 1 ? local.single : (_autoFlip ? game.currentPlayer : game.seatOf(ChessColor.white));
    return _flipped ? _other(base) : base;
  }

  /// "Du spielst Weiß/Schwarz." on a network device until the first board
  /// move (KLD-059 step 4a: the host chooses the colours), else null.
  String? _colorHint(AppLocalizations l10n) {
    final local = controller.transport.localPlayers;
    if (local.length != 1 || game.sanHistory.isNotEmpty) return null;
    return chessYouPlay(l10n, game.colorOf(local.single));
  }

  /// Pieces move on the own turn, not while the promotion picker is up, a
  /// draw offer waits for its answer (the offerer is the player to move) or
  /// a move waits for "Ziehen".
  bool get _canMove =>
      controller.canAct && !_promoting && game.drawOfferBy == null && _pending == null && !_paused;

  List<Map<String, dynamic>> _movesFrom(String? sq) => sq == null || !_canMove ? const [] : game.legalMovesFrom(sq);

  // ------------------------------------------------------------ interaction

  void _tap(String sq) {
    if (!_canMove) return;
    final from = _selected;
    if (from != null && _tryMove(from, sq)) return;
    final piece = game.pieceAt(sq);
    setState(() {
      _selected = piece != null && piece.color == game.sideToMove && sq != from ? sq : null;
    });
  }

  /// Moves the selected piece from [from] to [to] if that is legal (asking
  /// for the promotion piece first); false if it is no legal target.
  bool _tryMove(String from, String to) {
    final moves = [for (final m in _movesFrom(from)) if (m['to'] == to) m];
    if (moves.isEmpty) return false;
    if (moves.length == 1) {
      _play(moves.single);
    } else {
      _promote(from, to);
    }
    return true;
  }

  Future<void> _promote(String from, String to) async {
    final color = game.sideToMove;
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
    if (letter == null || game.sideToMove != color || controller.game.isOver) return;
    _play({'action': 'move', 'from': from, 'to': to, 'promotion': letter});
  }

  /// Submits [move], or with "Zug bestätigen" on for the mover (KLD-122)
  /// keeps it as pending: shown on a private copy of the game, not sent.
  void _play(Map<String, dynamic> move) {
    if (confirmMoveFor(context, controller, game.currentPlayer)) {
      final preview = controller.previewCopy();
      final event = preview?.applyMove(move);
      if (preview is ChessGame && event != null) {
        setState(() {
          _selected = null;
          _pending = _Pending(move, preview, event.payload is Map ? event.payload as Map : const {}, _seen);
        });
        return;
      }
    }
    setState(() => _selected = null);
    controller.submit(move);
  }

  /// "✓ Ziehen": now the pending move counts. If it was not delivered (e.g.
  /// the connection dropped) it is pending again.
  Future<void> _commit() async {
    final p = _pending;
    if (p == null || !controller.canAct || controller.moves.length != p.seen) return;
    setState(() => _pending = null);
    final r = await controller.submit(p.move);
    if (!r.isAccepted && mounted && _pending == null && controller.canAct && controller.moves.length == p.seen) {
      setState(() => _pending = p);
    }
  }

  /// "✗ Anders ziehen": the board as before, choose again.
  void _back() => setState(() => _pending = null);

  void _dragStarted(String sq) {
    if (!_canMove) return;
    setState(() => _selected = sq);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = game;
    GameScreen.of(context).setHint(g.isOver
        ? null
        : _pending != null
            ? l10n.confirmMoveHint
            : _clockHint(l10n) ??
            _drawHint(l10n) ??
            (_selected == null ? _colorHint(l10n) : null) ??
            (!controller.canAct
                ? null
                : _selected == null
                    ? l10n.chessHintSelect
                    : l10n.chessHintTarget));

    final bottom = _bottom;
    final top = _other(bottom);
    final check = !g.isOver && g.isInCheck;

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Zug zurücknehmen" (hot-seat, KLD-117) next to the board buttons.
        const UndoMoveButton(),
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
        // KLD-126: the pause (hot-seat at once, network a request).
        if (!g.isOver && _clocked != null)
          IconButton(
            key: const Key('chess-pause'),
            tooltip: l10n.chessClockPause,
            icon: const Icon(Icons.pause),
            onPressed: !_paused && (controller.transport is HotSeatTransport || g.canRequestClock(_offerer))
                ? _pause
                : null,
          ),
        if (!g.isOver)
          IconButton(
            key: const Key('chess-offer-draw'),
            tooltip: l10n.chessOfferDraw,
            icon: const Icon(Icons.handshake_outlined),
            onPressed: g.canOfferDraw(_offerer) && _offerTo == null && !_paused ? _offerDraw : null,
          ),
      ],
    );
    final checkBadge = check ? const _CheckBadge() : const SizedBox.shrink();
    // The check badge at the start, the buttons at the end. With "Zug
    // zurück" (KLD-117) the buttons can be wider than a narrow board: they
    // shrink to fit then, the badge takes what is left.
    Widget controlRow(double width) => Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FittedBox(fit: BoxFit.scaleDown, child: checkBadge),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width),
              child: FittedBox(fit: BoxFit.scaleDown, child: controls),
            ),
          ],
        );
    final moves = _MoveList(san: g.sanHistory, wrap: true);
    // KLD-122: "✗ Anders ziehen" / "✓ Ziehen" above the move list while a move
    // waits; in a very short pane the bar takes all of it (and shrinks).
    Widget movePane() => _pending == null
        ? _MovePane(child: moves)
        : LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                SizedBox(
                  height: min(48.0, box.maxHeight),
                  child: Center(child: ConfirmMoveBar(onCommit: _commit, onBack: _back)),
                ),
                Expanded(child: _MovePane(child: moves)),
              ],
            ),
          );

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
                    _side(top),
                    const SizedBox(height: 8),
                    controlRow(300),
                    const SizedBox(height: 8),
                    Expanded(child: movePane()),
                    const SizedBox(height: 8),
                    _side(bottom),
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
            SizedBox(width: extent, child: _side(top)),
            _frame(context, extent, bottom),
            SizedBox(width: extent, child: _side(bottom)),
            SizedBox(
              width: extent,
              height: 48,
              child: controlRow(extent),
            ),
            Expanded(
              child: SizedBox(
                width: extent,
                child: movePane(),
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
    final pending = _pending;
    // A pending move (KLD-122) shows the position after it.
    final shown = pending?.preview ?? g;
    final board = shown.board;
    final selected = _selected;
    final legal = _movesFrom(selected);
    final targets = {for (final m in legal) m['to'] as String};
    final last = pending == null ? _lastMove(controller.moves) : null;
    final checkSquare = shown.isInCheck ? _kingSquare(board, shown.sideToMove) : null;
    final moved = pending == null ? null : g.pieceAt(pending.from);
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
        pendingFrom: pending != null && pending.from == name ? moved : null,
        pendingTo: pending != null && pending.to == name,
        pendingCapture: pending != null && pending.captureSquare == name ? pending.captured : null,
      );
      final movable = canMove && piece != null && piece.color == g.sideToMove;
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

    return _withClockOverlay(
        ChessBoardFrame(flip: g.colorOf(bottom) == ChessColor.black, extent: extent, square: square));
  }

  static String? _kingSquare(List<ChessPiece?> board, ChessColor color) {
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

/// A move waiting for "Ziehen" (KLD-122): the move, the game after it (a
/// private copy) and its event payload; [seen] = the log length it was
/// chosen at.
class _Pending {
  final Map<String, dynamic> move;
  final ChessGame preview;
  final Map<dynamic, dynamic> payload;
  final int seen;
  const _Pending(this.move, this.preview, this.payload, this.seen);

  String get from => move['from'] as String;
  String get to => move['to'] as String;
  String? get captureSquare => payload['captureSquare'] as String?;

  /// The captured piece (the opponent's colour), or null.
  ChessPiece? get captured {
    final t = chessPieceTypeOf(payload['capture']);
    return t == null ? null : ChessPiece(preview.sideToMove, t);
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

  /// A pending move (KLD-122): [pendingFrom] is the piece that left this
  /// square (shown faintly), [pendingTo] marks its target, [pendingCapture]
  /// the piece it takes here (small and faint in a corner).
  final ChessPiece? pendingFrom;
  final bool pendingTo;
  final ChessPiece? pendingCapture;

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
    this.pendingFrom,
    this.pendingTo = false,
    this.pendingCapture,
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
                if (pendingFrom != null)
                  Center(
                    key: const Key('chess-pending-from'),
                    child: Opacity(opacity: 0.3, child: ChessPieceIcon(piece: pendingFrom!, size: size * 0.9)),
                  ),
                if (pendingCapture != null)
                  PositionedDirectional(
                    key: const Key('chess-pending-capture'),
                    top: size * 0.02,
                    end: size * 0.02,
                    width: size * 0.42,
                    height: size * 0.42,
                    child: Opacity(opacity: 0.55, child: ChessPieceIcon(piece: pendingCapture!, size: size * 0.42)),
                  ),
                if (pc != null) Center(child: ChessPieceIcon(piece: pc, size: size * 0.9)),
                if (pendingTo)
                  IgnorePointer(
                    child: Container(
                      key: const Key('chess-pending-to'),
                      decoration: BoxDecoration(
                        border: Border.all(color: p.select, width: max(3, size * 0.1)),
                      ),
                    ),
                  ),
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
  final ChessColor color;
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
    final opponent = (controller.game as ChessGame).colorOf(player).opposite;
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
