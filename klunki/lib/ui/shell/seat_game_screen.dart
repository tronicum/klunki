import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../app/theme.dart';
import '../../game/game_controller.dart';
import '../../transport/game_transport.dart';
import '../../transport/hot_seat_transport.dart';
import '../engine_l10n.dart';
import '../game_titles.dart';
import '../seat_players_dialog.dart';
import 'game_screen.dart';
import 'seat_labels.dart';

export 'seat_labels.dart';

/// The frame of a game for 2–4 players on one device (KLD-088, KLD-119):
/// the counterpart of [GameScreen] by seat instead of `Player {a, b}`, so a
/// game with 3 or 4 seats never asks for `currentPlayer` (which throws for
/// seats 2 and 3). The two-player games keep [GameScreen]; the five-dice
/// game uses this one for every player count, the word tile game can move
/// over for 3–4 players later.
///
/// * app bar: title, "Spielernamen" ([showSeatPlayersDialog] with the
///   game's player count), restart, resign ("Wer gibt auf?" over the seats
///   still in; with 3–4 seats the others play on), move history, and
///   [actions] of the game (e.g. a rules button);
/// * leaving a game under way asks first ("Spiel verlassen?", as KLD-099);
/// * the turn edge and the status pill in the colour of the seat to move
///   ([seatColor], [SeatToken] with the number);
/// * a hint line the board sets through [GameScreen.of] (this screen is the
///   [GameShell]), and [UndoMoveButton] works inside the board;
/// * the result dialog with the ranking: place, token, name and points
///   (`score<seat>` of [SeatResult.params]), shared places, seats that left
///   last; "Nochmal" / "Menü".
///
/// No handover cover: it is meant for games without secrets (a game with
/// hidden information needs the seat cover first, KLD-088 step 2).
/// Hot-seat only (the network session is 2-player). Names come from the
/// nearest [SeatLabelsScope] ([SeatNamesBuilder] adds the app's).
class SeatGameScreen extends StatefulWidget {
  final GameController controller;
  final BoardBuilder boardBuilder;
  final MoveDescriber? describeMove;
  final String? title;

  /// More app-bar actions before the shell's own (e.g. the rules).
  final List<Widget> actions;

  const SeatGameScreen({
    super.key,
    required this.controller,
    required this.boardBuilder,
    this.describeMove,
    this.title,
    this.actions = const [],
  });

  @override
  State<SeatGameScreen> createState() => _SeatGameScreenState();
}

/// The seat that is to move in [game] (null once over), for 2–4 seats.
int? actorSeatOf(Game game) {
  if (game.isOver) return null;
  if (game is SeatGame) return (game as SeatGame).actorSeat;
  return game.currentPlayer.index;
}

/// The number of seats of [game] (2 for a game without seats).
int seatCountOf(Game game) => game is SeatGame ? (game as SeatGame).playerCount : 2;

/// The outcome of [game] by seat (a two-player game's result as places).
SeatResult seatResultOf(Game game) {
  if (game is SeatGame) return (game as SeatGame).seatResult;
  final r = game.result;
  if (!r.isOver) return const SeatResult();
  final w = r.winner;
  return SeatResult(isOver: true, places: [
    for (final p in Player.values) w == null || w == p ? 1 : 2,
  ], code: r.code?.code, params: r.params, reason: r.reason);
}

class _SeatGameScreenState extends State<SeatGameScreen> implements GameShell {
  String? _hint;
  bool _resultShown = false;
  bool _resultHeld = false;
  bool _leaving = false;
  ModalRoute<Object?>? _confirmRoute;
  late GameTransport _transport;

  @override
  GameController get controller => widget.controller;

  Game get _game => controller.game;

  @override
  String? get hint => _hint;

  void _later(VoidCallback f) {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(f);
      });
    } else if (mounted) {
      setState(f);
    }
  }

  @override
  void setHint(String? text) {
    if (text != _hint) _later(() => _hint = text);
  }

  /// No board of a seat game shows an older state than the game is in.
  @override
  void setStatusOverride(ShellStatus? status) {}

  @override
  void holdResult(bool hold) {
    if (hold == _resultHeld) return;
    _resultHeld = hold;
    if (!hold) _maybeShowResult();
  }

  @override
  void initState() {
    super.initState();
    _transport = controller.transport;
    controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(SeatGameScreen old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _transport = controller.transport;
      _hint = null;
      _resultShown = false;
      _resultHeld = false;
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
      if (!identical(_transport, controller.transport)) {
        _transport = controller.transport;
        _hint = null;
      }
    });
    if (!_game.isOver) {
      _resultShown = false;
    } else {
      _closeConfirm();
      _maybeShowResult();
    }
  }

  void _maybeShowResult() {
    if (_resultShown || _resultHeld || !_game.isOver) return;
    _resultShown = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_resultHeld || !_game.isOver) {
        _resultShown = false;
        return;
      }
      _showResult();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  Future<T?> _confirm<T>(WidgetBuilder builder) async {
    try {
      return await showDialog<T>(
        context: context,
        builder: (ctx) {
          _confirmRoute = ModalRoute.of(ctx);
          return builder(ctx);
        },
      );
    } finally {
      _confirmRoute = null;
    }
  }

  void _closeConfirm() {
    final r = _confirmRoute;
    _confirmRoute = null;
    final nav = r?.navigator;
    if (r == null || nav == null || !r.isActive) return;
    if (r.isCurrent) {
      nav.pop();
    } else {
      nav.removeRoute(r);
    }
  }

  bool get _canRestart => controller.transport is HotSeatTransport;

  /// Under way once a second seat moved, or after a few moves.
  bool get _underway {
    final moves = controller.moves.where((m) => m.move['action'] != 'resign');
    return moves.length >= 4 || moves.any((m) => m.seat != 0);
  }

  bool get _confirmLeave => !_leaving && !_game.isOver && (!_canRestart || _underway);

  String _name(int seat) =>
      SeatLabelsScope.of(context).label(context, AppLocalizations.of(context), seat, count: seatCountOf(_game));

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm<bool>(
      (ctx) => AlertDialog(
        key: const Key('leave-dialog'),
        title: Text(l10n.shellLeaveTitle),
        content: Text(l10n.shellNewGameBody),
        actions: [
          TextButton(
              key: const Key('leave-cancel'), onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.shellCancel)),
          FilledButton(
              key: const Key('leave-confirm'), onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.shellLeave)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _leaving = true);
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  Future<void> _restart() async {
    if (controller.moves.isNotEmpty && !_game.isOver) {
      final l10n = AppLocalizations.of(context);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.shellNewGameTitle),
          content: Text(l10n.shellNewGameBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.shellCancel)),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.shellRestart)),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    controller.restart(seed: newGameSeed());
  }

  /// The seats that may resign now.
  List<int> get _resignable =>
      controller.seatGame != null ? controller.canResignSeats : ([for (final p in controller.canResign) p.index]..sort());

  /// "Aufgeben": one button per seat still in. With 3–4 seats that seat
  /// leaves and the others play on; with two the game ends.
  Future<void> _resign() async {
    final seats = _resignable;
    if (seats.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final many = controller.seatGame != null;
    final who = await _confirm<int>(
      (ctx) => AlertDialog(
        key: const Key('resign-dialog'),
        icon: Icon(Icons.flag_outlined, size: 36, color: scheme.error),
        title: Text(l10n.shellResignTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(many ? l10n.seatResignWho : l10n.shellResignWho),
            const SizedBox(height: 12),
            for (final s in seats)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(
                  key: Key(many ? 'resign-seat-$s' : 'resign-${Player.values[s].name}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    alignment: AlignmentDirectional.centerStart,
                    side: BorderSide(color: seatColor(ctx, s), width: 2),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(s),
                  icon: SeatToken(seat: s, size: 24),
                  label: Text(l10n.shellResignPlayer(_name(s))),
                ),
              ),
          ],
        ),
        scrollable: true,
        actions: [
          TextButton(
              key: const Key('resign-cancel'), onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.shellCancel)),
        ],
      ),
    );
    if (who == null || !mounted || _game.isOver) return;
    if (many) {
      await controller.resignSeat(who);
    } else {
      await controller.resign(Player.values[who]);
    }
  }

  String _describe(AppLocalizations l10n, AcceptedMove m) => m.move['action'] == 'resign'
      ? l10n.shellResign
      : widget.describeMove?.call(l10n, m) ?? m.move.toString();

  void _showHistory() {
    final moves = controller.moves;
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          key: const Key('history-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.shellMoves, style: Theme.of(ctx).textTheme.titleLarge),
            ),
            if (moves.isEmpty)
              Padding(padding: const EdgeInsets.all(16), child: Text(l10n.shellNoMoves))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  reverse: false,
                  itemCount: moves.length,
                  itemBuilder: (_, i) {
                    final m = moves[i];
                    return ListTile(
                      dense: true,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${m.index + 1}.', textDirection: TextDirection.ltr),
                          const SizedBox(width: 8),
                          SeatToken(seat: m.seat, size: 20),
                        ],
                      ),
                      title: Text(l10n.shellHistoryEntry(_name(m.seat), _describe(l10n, m))),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The ranking with places, names and points.
  Widget _ranking(BuildContext context, SeatResult r) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final game = _game;
    return Column(
      key: const Key('result-ranking'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in r.ranking)
          Padding(
            key: Key('result-rank-$s'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('${r.places[s]}.',
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (r.places[s] == 1 && !(game is SeatGame && (game as SeatGame).isSeatOut(s)))
                  Icon(Icons.emoji_events, size: 20, color: KlunkiPalette.of(context).trophy)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 6),
                SeatToken(seat: s, size: 24, out: game is SeatGame && (game as SeatGame).isSeatOut(s)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_name(s),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: r.places[s] == 1 ? FontWeight.w700 : null)),
                ),
                const SizedBox(width: 12),
                if (game is SeatGame && (game as SeatGame).isSeatOut(s))
                  Text(l10n.seatOut, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                else if (r.params['score$s'] != null)
                  Text(l10n.seatPoints(r.params['score$s']!), style: theme.textTheme.titleMedium),
              ],
            ),
          ),
      ],
    );
  }

  String _reason(AppLocalizations l10n, SeatResult r) {
    final code = r.code == null ? null : GameEndReason.fromCode(r.code!);
    if (code == null) return r.reason;
    if (code == GameEndReason.commonResigned) {
      return controller.seatGame != null
          ? l10n.seatReasonOthersResigned
          : l10n.engineReasonCommonResigned(_name(r.params['seat'] ?? r.params['player'] ?? 0));
    }
    return localizedEndReason(l10n, code, r.params);
  }

  Future<void> _showResult() async {
    final r = seatResultOf(_game);
    final l10n = AppLocalizations.of(context);
    final w = r.winner;
    final headline = w == null ? l10n.seatSharedFirst : l10n.shellWins(_name(w));
    final reason = _reason(l10n, r);
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SeatLabelsScope(
        labels: SeatLabelsScope.of(context),
        child: AlertDialog(
          key: const Key('result-dialog'),
          icon: Icon(Icons.emoji_events, size: 52, color: KlunkiPalette.of(ctx).trophy),
          title: Text(headline, key: const Key('result-headline')),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reason.isNotEmpty) Text(reason, key: const Key('result-reason')),
              const SizedBox(height: 12),
              _ranking(ctx, r),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.shellMenu)),
            if (_canRestart)
              FilledButton(
                  key: const Key('result-again'),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.shellPlayAgain)),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (again == true) {
      controller.restart(seed: newGameSeed());
    } else {
      Navigator.of(context).maybePop();
    }
  }

  String _status(AppLocalizations l10n) {
    if (_game.isOver) {
      final w = seatResultOf(_game).winner;
      return w == null ? l10n.seatSharedFirst : l10n.shellHasWon(_name(w));
    }
    return l10n.shellToMove(_name(actorSeatOf(_game)!));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = KlunkiPalette.of(context).accent(controller.spec.id);
    final game = _game;
    final over = game.isOver;
    final seat = over ? seatResultOf(game).winner : actorSeatOf(game);
    final color = seat == null ? Colors.transparent : seatColor(context, seat);
    return GameShellScope(
      shell: this,
      hint: _hint,
      child: PopScope<Object?>(
        canPop: !_confirmLeave,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _confirmRoute == null) _leave();
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: accent.color,
            foregroundColor: accent.onColor,
            title: Text(widget.title ?? localizedGameTitle(l10n, controller.spec.id, fallback: controller.spec.title)),
            actions: [
              ...widget.actions,
              if (_canRestart)
                IconButton(
                  key: const Key('shell-names'),
                  tooltip: l10n.hotSeatNamesTitle,
                  icon: const Icon(Icons.people_outline),
                  onPressed: () => showSeatPlayersDialog(context, players: seatCountOf(game)),
                ),
              if (_canRestart)
                IconButton(
                  key: const Key('shell-restart'),
                  tooltip: l10n.shellNewGame,
                  icon: const Icon(Icons.refresh),
                  onPressed: _restart,
                ),
              if (_resignable.isNotEmpty)
                IconButton(
                  key: const Key('shell-resign'),
                  tooltip: l10n.shellResign,
                  icon: const Icon(Icons.flag_outlined),
                  onPressed: _resign,
                ),
              IconButton(
                key: const Key('shell-history'),
                tooltip: l10n.shellMoves,
                icon: const Icon(Icons.history),
                onPressed: _showHistory,
              ),
            ],
          ),
          body: KlunkiBackground(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeSemantics(
                    child: AnimatedContainer(
                      key: const Key('shell-turn-edge'),
                      height: 6,
                      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 300),
                      color: color,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _SeatPill(seat: seat, won: over, status: _status(l10n)),
                    ),
                  ),
                  if (_hint != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _hint!,
                          key: const Key('shell-hint'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  Expanded(child: Builder(builder: (ctx) => widget.boardBuilder(ctx, controller))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The status pill: filled with the colour of the seat to move, its token
/// and "Anna ist am Zug"; at the end a trophy with the winner (or the shared
/// first place without a token).
class _SeatPill extends StatelessWidget {
  final int? seat;
  final bool won;
  final String status;
  const _SeatPill({required this.seat, required this.won, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = KlunkiPalette.of(context);
    final s = seat;
    final Color fill;
    final Color ink;
    final Color border;
    if (won) {
      fill = Color.alphaBlend(palette.trophy.withValues(alpha: 0.14), palette.card);
      ink = theme.colorScheme.onSurface;
      border = palette.trophy;
    } else {
      final c = seatColor(context, s ?? 0);
      fill = c;
      ink = inkOn(c);
      border = visibleOn(context, c, minRatio: 3);
    }
    return AnimatedContainer(
      key: const Key('shell-turn'),
      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 250),
      padding: const EdgeInsetsDirectional.fromSTEB(6, 5, 14, 5),
      constraints: const BoxConstraints(minHeight: 38),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s != null) SeatToken(seat: s, size: 26) else Icon(Icons.handshake_outlined, size: 24, color: ink),
          const SizedBox(width: 8),
          if (won) ...[
            Icon(Icons.emoji_events, size: 20, color: palette.trophy),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Semantics(
              liveRegion: true,
              child: Text(
                status,
                key: const Key('shell-status'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
