import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';
import '../../transport/game_transport.dart';
import '../../transport/hot_seat_transport.dart';
import '../../app/theme.dart';
import '../game_titles.dart';
import '../game_visuals.dart';
import '../ltr.dart';
import '../player_name_dialog.dart';
import '../../profile/seen_tips.dart';
import '../rules/rules_screen.dart';
import 'confirm_move.dart';
import 'handover_cover.dart';
import 'player_labels.dart';

export 'player_labels.dart' show PlayerLabels, PlayerLabelsScope;

/// Builds the game-specific board inside a [GameScreen].
typedef BoardBuilder = Widget Function(BuildContext context, GameController controller);

/// Turns an accepted move into readable text for the move history, in the
/// language of [l10n].
typedef MoveDescriber = String Function(AppLocalizations l10n, AcceptedMove move);

/// Internal player marks for widget keys: player A is "X", player B is "O".
/// Never shown: texts name the players (KLD-103, see [PlayerLabels.label]),
/// tokens show [playerNumber] (KLD-106).
String playerMark(Player p) => PlayerLabels.markOf(p);

/// The player number on a player's token: "1" for A, "2" for B (KLD-106,
/// matching "Spieler 1 / 2").
String playerNumber(Player p) => PlayerLabels.numberOf(p);

/// [p] as named inside a sentence (KLD-103): the name ("Anna"), see
/// [PlayerLabels.label], from the nearest [PlayerLabelsScope].
String playerName(BuildContext context, Player p) =>
    PlayerLabelsScope.of(context).label(context, AppLocalizations.of(context), p);

/// A fresh random seed for a new game (seeded games reshuffle, the others
/// ignore it).
int newGameSeed() => Random().nextInt(1 << 31);

/// What a board gets from the surrounding [GameScreen] via [GameScreen.of].
abstract interface class GameShell {
  /// The controller the screen was built with.
  GameController get controller;

  /// Current hint line text (null = no hint line).
  String? get hint;

  /// Sets the hint line under the status line. Safe to call from `build`
  /// (the update is deferred to after the frame then).
  void setHint(String? text);

  /// While [hold] is set, the result dialog of a finished game waits: the
  /// board still has a final move to show (e.g. Quartett tricks queued
  /// behind a reveal on a network device, KLD-089). Releasing it shows the
  /// dialog. Safe to call from `build`.
  void holdResult(bool hold);

  /// Replaces the live status line while the board shows an older state
  /// than the game is in (e.g. a queued Quartett trick on a network device,
  /// KLD-091); null goes back to the live status. Safe to call from `build`
  /// (the update is deferred to after the frame then).
  void setStatusOverride(ShellStatus? status);

  /// The "Regeln" button in the app bar (KLD-123), e.g. for a coach mark
  /// pointing at it. Its context is null for a game without rules page.
  GlobalKey get rulesButtonKey;
}

/// A status line set by the board instead of the live one, see
/// [GameShell.setStatusOverride].
@immutable
class ShellStatus {
  /// The text of the status line.
  final String text;

  /// Whose colour the turn pill and edge show; on a network device the pill
  /// is "active" for the local player, "waiting" for the other one.
  final Player player;

  /// Optional small badge on the status pill (`shell-status-badge`), e.g.
  /// "noch 2 Runden".
  final String? badge;

  const ShellStatus({required this.text, required this.player, this.badge});

  @override
  bool operator ==(Object other) =>
      other is ShellStatus && other.text == text && other.player == player && other.badge == badge;

  @override
  int get hashCode => Object.hash(text, player, badge);
}

/// The shared frame every game screen plugs into:
///
/// * app bar with the game title, resign ("Aufgeben", KLD-065: with a
///   confirmation; in hot-seat the dialog asks which player gives up), move
///   history, "Regeln" and in hot-seat the "⋮" menu ([ShellMenu]) with the
///   player names and "Neues Spiel",
/// * leaving a running game asks first ("Spiel verlassen?", KLD-099): back
///   button, system/predictive back; over the network always, in hot-seat
///   once the game is under way. A confirm dialog closes itself when the
///   game ends underneath it (e.g. the opponent resigns),
/// * status line ("Anna ist am Zug" or, on a network device, "Du bist am
///   Zug (X)" / "Warte auf Ben…") plus a
///   hint line the board can set
///   through [GameScreen.of] → [GameShell.setHint],
/// * "Regeln" (KLD-123, [RulesButton]): the game's rules page, at the end
///   of the app bar in every game, and under the status a "Neu hier? So
///   geht's" line for a new player of this game (until the rules page was
///   opened once for the game or from the 4th game on, [SeenTips]),
/// * network games that offer "Zug bestätigen" (KLD-122): its toggle for
///   this device ([ConfirmMoveToggle]) in the app bar,
/// * "Zug zurück" ([UndoMoveButton], hot-seat only, KLD-117) in the game
///   area: in a small row under the board, unless the board places the
///   button in its own control row ([boardPlacesUndo]),
/// * a [HandoverCover] over the body while the controller needs a handover
///   (the cover offers "Zug zurück" too, so the player who just moved can
///   take the move back before passing the device, without seeing secrets),
/// * a result dialog ("Nochmal" / "Menü") once the game is over.
///
/// Players are named through the nearest [PlayerLabelsScope] (KLD-056,
/// KLD-103): the regional default names ("Anna" / "Ben") unless the players
/// typed their own (hot-seat: at the start and through the app bar action
/// "Spielernamen"; network: each device's player name).
///
/// The screen does not own [controller]; whoever created it disposes it
/// (see `openGame` in `screen_registry.dart`).
class GameScreen extends StatefulWidget {
  final GameController controller;
  final BoardBuilder boardBuilder;

  /// Readable text for a move in the history sheet; defaults to the move
  /// map's `toString()`.
  final MoveDescriber? describeMove;

  /// App bar title; defaults to the registry title of the game.
  final String? title;

  /// Optional public info shown on the hot-seat handover cover (e.g. the
  /// outcome of the last fight in GoStrategy). Must never show secrets.
  final WidgetBuilder? handoverDetail;

  /// Optional game-specific summary under the reason in the result dialog
  /// (e.g. the final scores of a word game). Public info only.
  final WidgetBuilder? resultDetail;

  /// The board shows the [UndoMoveButton] in its own control row (chess next
  /// to the flip buttons, the word game under its actions); otherwise
  /// the shell puts it in a small row under the board (KLD-117).
  final bool boardPlacesUndo;

  /// Hot-seat: both players (token and name) at the top right (KLD-067).
  /// Off for a board that names the players itself (the word game's score
  /// row, KLD-094 step 8g).
  final bool showPlayersLegend;

  const GameScreen({
    super.key,
    required this.controller,
    required this.boardBuilder,
    this.describeMove,
    this.title,
    this.handoverDetail,
    this.resultDetail,
    this.boardPlacesUndo = false,
    this.showPlayersLegend = true,
  });

  /// The [GameShell] of the nearest enclosing [GameScreen].
  static GameShell of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_GameShellScope>();
    assert(scope != null, 'GameScreen.of() called outside a GameScreen');
    return scope!.shell;
  }

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> implements GameShell {
  String? _hint;
  ShellStatus? _statusOverride;
  bool _resultShown = false;
  bool _resultHeld = false;
  late GameTransport _transport;

  /// The open "are you sure?" dialog (resign or leave, KLD-099), closed when
  /// the game ends underneath it.
  ModalRoute<Object?>? _confirmRoute;

  /// Set once the player confirmed leaving: lets the route pop.
  bool _leaving = false;

  final GlobalKey _rulesKey = GlobalKey(debugLabel: 'shell-rules');

  /// The "Neu hier? So geht's" line (KLD-123) is shown in this game.
  bool _rulesIntro = false;

  /// Games of this kind started on this device, the current one included,
  /// up to which the "Neu hier?" line shows.
  static const int rulesIntroGames = 3;

  @override
  GlobalKey get rulesButtonKey => _rulesKey;

  /// Counts a started game and decides about the "Neu hier?" line.
  void _countGame() => _rulesIntro = countGameForRulesIntro(controller.spec.id);

  void _openRules() {
    if (_rulesIntro) setState(() => _rulesIntro = false);
    openRules(context, controller.spec.id, config: controller.config);
  }

  @override
  GameController get controller => widget.controller;

  @override
  String? get hint => _hint;

  @override
  void setHint(String? text) {
    if (text == _hint) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && text != _hint) setState(() => _hint = text);
      });
    } else if (mounted) {
      setState(() => _hint = text);
    }
  }

  @override
  void setStatusOverride(ShellStatus? status) {
    if (status == _statusOverride) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && status != _statusOverride) setState(() => _statusOverride = status);
      });
    } else if (mounted) {
      setState(() => _statusOverride = status);
    }
  }

  @override
  void holdResult(bool hold) {
    if (hold == _resultHeld) return;
    _resultHeld = hold;
    if (!hold) _maybeShowResult();
  }

  /// Shows the result dialog after this frame if the game is over, the
  /// dialog is not up yet and no board holds it back.
  void _maybeShowResult() {
    if (_resultShown || _resultHeld || !controller.game.isOver) return;
    _resultShown = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_resultHeld || !controller.game.isOver) {
        // A board took hold during this frame (e.g. it revealed the final
        // move): wait for it to let go.
        _resultShown = false;
        return;
      }
      _showResult();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void initState() {
    super.initState();
    _transport = controller.transport;
    controller.addListener(_onChange);
    _countGame();
  }

  @override
  void didUpdateWidget(GameScreen old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _transport = controller.transport;
      _hint = null;
      _statusOverride = null;
      _resultShown = false;
      _resultHeld = false;
      _countGame();
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
        // Restarted: fresh game, fresh hint and status.
        _transport = controller.transport;
        _hint = null;
        _statusOverride = null;
        _countGame();
      }
    });
    if (!controller.game.isOver) {
      _resultShown = false;
    } else {
      _closeConfirm();
      _maybeShowResult();
    }
  }

  /// Shows an "are you sure?" dialog that closes itself (answering null) if
  /// the game ends while it is open, e.g. when the opponent resigns (KLD-099).
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

  /// Leaving asks first (KLD-099) while the game is running: always over the
  /// network (it ends the game for both devices), in hot-seat once the game
  /// is under way.
  bool get _confirmLeave => !_leaving && !controller.game.isOver && (!_canRestart || _underway);

  /// A hot-seat game is under way once each side has moved, or after a few
  /// moves (some games let one side move several times in a row).
  bool get _underway {
    final moves = controller.moves.where((m) => Game.resignerOf(m.move) == null);
    if (moves.length >= 4) return true;
    return moves.any((m) => m.player == Player.a) && moves.any((m) => m.player == Player.b);
  }

  /// Back button, system back, predictive back: "Spiel verlassen?" first.
  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm<bool>(
      (ctx) => AlertDialog(
        key: const Key('leave-dialog'),
        title: Text(l10n.shellLeaveTitle),
        content: Text(_canRestart ? l10n.shellNewGameBody : l10n.shellLeaveBody),
        actions: [
          TextButton(
            key: const Key('leave-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.shellCancel),
          ),
          FilledButton(
            key: const Key('leave-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.shellLeave),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _leaving = true);
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  Future<void> _showResult() async {
    final r = controller.game.result;
    final l10n = AppLocalizations.of(context);
    final labels = PlayerLabelsScope.of(context);
    final w = r.winner;
    final headline = r.draw || w == null
        ? l10n.shellDraw
        : labels.isLocal(w)
        ? l10n.shellYouWin
        : l10n.shellWins(labels.label(context, l10n, w));
    final resigner = r.code == GameEndReason.commonResigned ? controller.game.resignedBy : null;
    final reason = resigner != null && labels.isLocal(resigner)
        ? l10n.engineReasonCommonYouResigned
        : localizedResultReason(l10n, r, playerLabel: (p) => labels.label(context, l10n, p));
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('result-dialog'),
        icon: w == null
            ? Icon(
                Icons.handshake_outlined,
                size: 40,
                color: KlunkiPalette.of(ctx).accent(controller.spec.id).onSurface(Theme.of(ctx).brightness),
              )
            : Center(
                child: SizedBox.square(
                  dimension: 64,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(child: Icon(Icons.emoji_events, size: 56, color: KlunkiPalette.of(ctx).trophy)),
                      PositionedDirectional(
                        end: -10,
                        bottom: -2,
                        child: PlayerToken(gameId: controller.spec.id, player: w, size: 28),
                      ),
                    ],
                  ),
                ),
              ),
        title: Text(headline),
        content: widget.resultDetail == null
            ? (reason.isEmpty ? null : Text(reason, key: const Key('result-reason')))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (reason.isNotEmpty) Text(reason, key: const Key('result-reason')),
                    if (reason.isNotEmpty) const SizedBox(height: 12),
                    PlayerLabelsScope(labels: labels, child: Builder(builder: widget.resultDetail!)),
                  ],
                ),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.shellMenu)),
          if (_canRestart) FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.shellPlayAgain)),
        ],
      ),
    );
    if (!mounted) return;
    if (again == true) {
      controller.restart(seed: newGameSeed());
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _restart() async {
    final inProgress = controller.moves.isNotEmpty && !controller.game.isOver;
    if (inProgress) {
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

  /// "Aufgeben" (KLD-065): confirm, then resign. On a network device the
  /// local player resigns; in hot-seat both players are local, so the dialog
  /// asks who gives up (one button per player) instead of guessing from the
  /// turn: either player may resign at any time.
  Future<void> _resign() async {
    final players = controller.canResign;
    if (players.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final labels = PlayerLabelsScope.of(context);
    String label(Player p) => labels.label(context, l10n, p);
    final palette = KlunkiPalette.of(context);
    final accent = palette.accent(controller.spec.id);
    final single = players.length == 1 ? players.first : null;
    final scheme = Theme.of(context).colorScheme;
    final who = await _confirm<Player>(
      (ctx) => AlertDialog(
        key: const Key('resign-dialog'),
        icon: Icon(Icons.flag_outlined, size: 36, color: accent.onSurface(Theme.of(ctx).brightness)),
        title: Text(l10n.shellResignTitle),
        content: Text(single != null ? l10n.shellResignBody(label(single == Player.a ? Player.b : Player.a)) : l10n.shellResignWho),
        actions: [
          TextButton(
            key: const Key('resign-cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.shellCancel),
          ),
          if (single != null)
            FilledButton(
              key: const Key('resign-confirm'),
              // Destructive: the game ends for both devices.
              style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
              onPressed: () => Navigator.of(ctx).pop(single),
              child: Text(l10n.shellResign),
            )
          else
            for (final p in Player.values)
              FilledButton.tonal(
                key: Key('resign-${p.name}'),
                onPressed: () => Navigator.of(ctx).pop(p),
                child: Text(l10n.shellResignPlayer(label(p))),
              ),
        ],
      ),
    );
    if (who == null || !mounted || controller.game.isOver) return;
    await controller.resign(who);
  }

  /// Restart (and "Nochmal") only where the device owns the game: hot-seat.
  /// Over the network the host owns the session (`NetworkTransport` does not
  /// support restart).
  bool get _canRestart => controller.transport is HotSeatTransport;

  String _describe(AppLocalizations l10n, AcceptedMove m) => Game.resignerOf(m.move) != null
      ? l10n.shellResign // the shared resign move; the board describers know only their own moves
      : widget.describeMove?.call(l10n, m) ?? m.move.toString();

  void _showHistory() {
    final moves = controller.moves;
    final l10n = AppLocalizations.of(context);
    final labels = PlayerLabelsScope.of(context);
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
                  itemCount: moves.length,
                  itemBuilder: (_, i) {
                    final m = moves[i];
                    return ListTile(
                      dense: true,
                      // LTR: "12." must not become ".12" in RTL locales.
                      leading: Text('${m.index + 1}.', textDirection: TextDirection.ltr),
                      title: Text(l10n.shellHistoryEntry(labels.label(context, l10n, m.player), _describe(l10n, m))),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _status(BuildContext context, AppLocalizations l10n) {
    final labels = PlayerLabelsScope.of(context);
    String label(Player p) => labels.label(context, l10n, p);
    final game = controller.game;
    final r = game.result;
    if (r.isOver) {
      final w = r.winner;
      if (w == null) return l10n.shellDraw;
      return labels.isLocal(w) ? l10n.shellYouHaveWon : l10n.shellHasWon(label(w));
    }
    final p = game.currentPlayer;
    if (labels.local == null) return l10n.shellToMove(label(p));
    return labels.isLocal(p) ? l10n.shellYourTurn : l10n.shellWaitingFor(label(p));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final accent = KlunkiPalette.of(context).accent(controller.spec.id);
    final game = controller.game;
    final labels = PlayerLabelsScope.of(context);
    final override = _statusOverride;
    final status = override?.text ?? _status(context, l10n);
    // Null once the game is over: the winner (or none for a draw).
    final turnPlayer = override?.player ?? (game.isOver ? game.result.winner : game.currentPlayer);
    final mood = override == null && game.isOver
        ? (turnPlayer == null ? TurnMood.draw : TurnMood.won)
        : (labels.local != null && !labels.isLocal(turnPlayer!) ? TurnMood.waiting : TurnMood.active);
    return _GameShellScope(
      shell: this,
      hint: _hint,
      // KLD-099: back (app bar, system, predictive back) asks first while
      // leaving would end a running game; the iOS back swipe is held back
      // then and the back button shows the dialog.
      child: PopScope<Object?>(
        canPop: !_confirmLeave,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _confirmRoute == null) _leave();
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: accent.color,
            foregroundColor: accent.onColor,
            // KLD-123: a little more room for the title next to the
            // actions; "Spielernamen" and "Neues Spiel" sit in the "⋮" menu.
            titleSpacing: 4,
            title: ShellTitle(
                widget.title ?? localizedGameTitle(l10n, controller.spec.id, fallback: controller.spec.title)),
            actions: [
              // KLD-122: this device's "Zug bestätigen" in a network game
              // (hot-seat sets it per player in "Spielernamen").
              if (!_canRestart && confirmMoveGames.contains(controller.spec.id) && !game.isOver)
                const ConfirmMoveToggle(),
              if (controller.canResign.isNotEmpty)
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
              // KLD-123: last but the menu, in the same place in every game.
              if (hasRules(controller.spec.id))
                KeyedSubtree(
                  key: _rulesKey,
                  child: RulesButton(key: const Key('shell-rules'), onPressed: _openRules),
                ),
              // Hot-seat names (KLD-056, when the app provides the store)
              // and "Neues Spiel", in the "⋮" menu so the title fits.
              if (_canRestart)
                ShellMenu(entries: [
                  if (PlayerNameScope.maybeOf(context) != null)
                    ShellMenuEntry(
                      key: const Key('shell-names'),
                      icon: Icons.people_outline,
                      label: l10n.hotSeatNamesTitle,
                      onSelected: () => showHotSeatNamesDialog(context, gameId: controller.spec.id),
                    ),
                  ShellMenuEntry(
                    key: const Key('shell-restart'),
                    icon: Icons.refresh,
                    label: l10n.shellNewGame,
                    onSelected: _restart,
                  ),
                ]),
            ],
          ),
          body: KlunkiBackground(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Outside the handover cover: whose turn it is is no secret.
                  _TurnEdge(color: _edgeColor(context, mood, turnPlayer)),
                  Expanded(
                    child: HandoverCover(
                      controller: controller,
                      detail: widget.handoverDetail,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                            // A Wrap, not a Row: on narrow phones with long
                            // names the legend moves below the pill instead of
                            // squeezing the status into many lines.
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _TurnIndicator(
                                  gameId: controller.spec.id,
                                  player: turnPlayer,
                                  mood: mood,
                                  network: labels.local != null,
                                  status: status,
                                  badge: override?.badge,
                                ),
                                // Hot-seat: both players with their colours (KLD-067).
                                if (labels.local == null && widget.showPlayersLegend)
                                  _PlayersLegend(
                                    gameId: controller.spec.id,
                                    labels: labels,
                                    current: game.isOver ? null : game.currentPlayer,
                                  ),
                                // KLD-123: in this row where there is room
                                // (wide screens), else on a line of its own.
                                if (_rulesIntro && !game.isOver) RulesIntroLine(onTap: _openRules),
                              ],
                            ),
                          ),
                          if (_hint != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  _hint!,
                                  key: const Key('shell-hint'),
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ),
                          Expanded(child: Builder(builder: (ctx) => widget.boardBuilder(ctx, controller))),
                          // Inside the cover: hidden while the device is
                          // passed on (KLD-117).
                          if (!widget.boardPlacesUndo && _canRestart)
                            const Padding(
                              key: Key('shell-actions'),
                              padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
                              child: Align(alignment: AlignmentDirectional.centerEnd, child: UndoMoveButton()),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The turn edge: the colour of the player to move (faded while waiting
  /// for the other device), the winner's colour at the end, none for a draw.
  Color _edgeColor(BuildContext context, TurnMood mood, Player? p) {
    if (p == null) return Colors.transparent;
    final palette = KlunkiPalette.of(context);
    final c = visibleOn(context, playerColor(palette, controller.spec.id, PlayerLabelsScope.of(context).tokenOf(p)));
    return mood == TurnMood.waiting ? c.withValues(alpha: 0.35) : c;
  }
}

/// "Zug zurück" (KLD-117): takes back the last move, hot-seat only; nothing
/// on a network device. One look for every game: the ↶ icon (mirrored in
/// right-to-left locales) plus the label. Disabled while there is nothing
/// to take back. Must sit inside a [GameScreen]; the shell places it under
/// the board unless the board shows it in its own control row
/// ([GameScreen.boardPlacesUndo]). Key `shell-undo` on the button.
class UndoMoveButton extends StatelessWidget {
  /// Compact by default; a board row of denser buttons passes its own
  /// density, so the row keeps its height.
  final VisualDensity visualDensity;

  /// Only the ↶ icon, the label as its tooltip: for a full board row on a
  /// small phone (Wortgewandt), where a line of its own would cost the
  /// board space.
  final bool iconOnly;

  const UndoMoveButton({super.key, this.visualDensity = VisualDensity.compact, this.iconOnly = false});

  @override
  Widget build(BuildContext context) {
    final controller = GameScreen.of(context).controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _UndoButton(controller: controller, visualDensity: visualDensity, iconOnly: iconOnly),
    );
  }
}

class _UndoButton extends StatelessWidget {
  final GameController controller;
  final VisualDensity visualDensity;
  final bool iconOnly;
  const _UndoButton({required this.controller, required this.visualDensity, required this.iconOnly});

  @override
  Widget build(BuildContext context) {
    if (controller.transport is! HotSeatTransport) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final onPressed = controller.canUndo ? controller.undo : null;
    if (iconOnly) {
      return IconButton(
        key: const Key('shell-undo'),
        tooltip: l10n.shellTakeBack,
        visualDensity: visualDensity,
        icon: const Icon(Icons.undo), // matchTextDirection: mirrored in RTL
        onPressed: onPressed,
      );
    }
    return Tooltip(
      message: l10n.shellUndo,
      excludeFromSemantics: true,
      child: TextButton.icon(
        key: const Key('shell-undo'),
        style: TextButton.styleFrom(visualDensity: visualDensity),
        icon: const Icon(Icons.undo), // matchTextDirection: mirrored in RTL
        label: Text(l10n.shellTakeBack),
        onPressed: onPressed,
      ),
    );
  }
}

/// Makes [shell] the [GameScreen.of] of everything below, for a frame other
/// than [GameScreen] (the seat shell for 3–4 players, KLD-119), so boards
/// and [UndoMoveButton] work the same inside it.
class GameShellScope extends StatelessWidget {
  final GameShell shell;
  final String? hint;
  final Widget child;
  const GameShellScope({super.key, required this.shell, required this.hint, required this.child});

  @override
  Widget build(BuildContext context) => _GameShellScope(shell: shell, hint: hint, child: child);
}

class _GameShellScope extends InheritedWidget {
  final GameShell shell;
  final String? hint;

  const _GameShellScope({required this.shell, required this.hint, required super.child});

  @override
  bool updateShouldNotify(_GameShellScope old) => old.hint != hint;
}

/// A player's token: a small round disc in the player's colour
/// ([playerColor]: accent / slate, GoStrategy red / blue, see
/// `game_visuals.dart`) with the player number "1" / "2" (KLD-106), so the
/// identity is never colour-only (UX-REVIEW 2.1, 2.10). Games with their own
/// piece show it instead ([GameVisuals.tokenIcon]: 4 Gewinnt discs, Mühle
/// stones, the chess king).
class PlayerToken extends StatelessWidget {
  final String gameId;
  final Player player;
  final double size;
  const PlayerToken({super.key, required this.gameId, required this.player, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final palette = KlunkiPalette.of(context);
    final icon = visualsOf(gameId).tokenIcon;
    // Network chess with the host on Black shows the other side's token
    // (PlayerLabels.tokens, KLD-059 step 4a).
    final player = PlayerLabelsScope.of(context).tokenOf(this.player);
    if (icon != null) {
      // A game's own token (chess: the side's king on a light square).
      return ExcludeSemantics(child: SizedBox.square(dimension: size, child: icon(context, player, size)));
    }
    final fill = playerColor(palette, gameId, player);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: Colors.black26, width: size * 0.08),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Text(
          playerNumber(player),
          textDirection: TextDirection.ltr,
          style: TextStyle(color: inkOn(fill), fontSize: size * 0.5, fontWeight: FontWeight.w700, height: 1),
        ),
      ),
    );
  }
}

/// What the status pill shows (KLD-067).
enum TurnMood {
  /// A player on this device moves: hot-seat, or "Du bist am Zug" on a
  /// network device. The pill is filled with the player's colour.
  active,

  /// Network: waiting for the other device. Muted pill, outlined in the
  /// other player's colour, with an hourglass.
  waiting,

  /// Game over with a winner (trophy).
  won,

  /// Game over, draw.
  draw,
}

/// The coloured edge under the app bar: the turn colour across the whole
/// width, so whose turn it is shows at a glance. Animated colour change
/// (instant with reduced motion).
class _TurnEdge extends StatelessWidget {
  final Color color;
  const _TurnEdge({required this.color});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: AnimatedContainer(
          key: const Key('shell-turn-edge'),
          height: 6,
          duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          color: color,
        ),
      );
}

/// The status line as a pill (KLD-062, KLD-067): token plus status text.
///
/// * [TurnMood.active]: filled with the player's colour, text in black or
///   white for contrast, a soft glow. On a network device it pulses once
///   when the turn comes back to this player, with a light haptic tap.
/// * [TurnMood.waiting]: card-coloured, outlined in the other player's
///   colour, hourglass, muted text.
/// * [TurnMood.won] / [TurnMood.draw]: trophy + winner token / handshake.
///
/// Colour is never the only signal: the text and the token (with the mark)
/// stay. Colour changes animate briefly; with reduced motion there is no
/// transition and no pulse.
class _TurnIndicator extends StatefulWidget {
  final String gameId;
  final Player? player;
  final TurnMood mood;
  final bool network;
  final String status;

  /// Optional badge pinned to the pill's top end corner (no layout change,
  /// so nothing below moves under the player's finger).
  final String? badge;

  const _TurnIndicator({
    required this.gameId,
    required this.player,
    required this.mood,
    required this.network,
    required this.status,
    this.badge,
  });

  @override
  State<_TurnIndicator> createState() => _TurnIndicatorState();
}

class _TurnIndicatorState extends State<_TurnIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.07).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.07, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 60),
  ]).animate(_pulse);

  @override
  void didUpdateWidget(_TurnIndicator old) {
    super.didUpdateWidget(old);
    // "Du bist am Zug" again on a network device: a short pulse and tap.
    if (widget.network && widget.mood == TurnMood.active && old.mood != TurnMood.active) {
      HapticFeedback.lightImpact();
      if (!reduceMotion(context)) _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = KlunkiPalette.of(context);
    final p = widget.player;
    final mood = widget.mood;
    final color = p == null
        ? theme.colorScheme.outline
        : playerColor(palette, widget.gameId, PlayerLabelsScope.of(context).tokenOf(p));

    final Color fill;
    final Color border;
    final Color ink;
    List<BoxShadow>? glow;
    switch (mood) {
      case TurnMood.active:
        fill = color;
        // The filled pill's edge keeps non-text contrast (3:1) to the page.
        border = visibleOn(context, color, minRatio: 3);
        ink = inkOn(color);
        glow = [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 12, spreadRadius: 1)];
      case TurnMood.waiting:
        fill = Color.alphaBlend(color.withValues(alpha: 0.10), palette.card);
        border = visibleOn(context, color).withValues(alpha: 0.7);
        ink = theme.colorScheme.onSurfaceVariant;
      case TurnMood.won:
        fill = Color.alphaBlend(palette.trophy.withValues(alpha: 0.14), palette.card);
        border = palette.trophy;
        ink = theme.colorScheme.onSurface;
      case TurnMood.draw:
        fill = palette.card;
        border = theme.colorScheme.outline;
        ink = theme.colorScheme.onSurface;
    }

    final style = theme.textTheme.titleMedium?.copyWith(
      color: ink,
      fontWeight: mood == TurnMood.active ? FontWeight.w700 : null,
    );
    final badge = widget.badge;
    final pill = AnimatedContainer(
        key: const Key('shell-turn'),
        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 14, 6),
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border, width: mood == TurnMood.waiting ? 2 : 1.5),
          boxShadow: glow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p != null)
              PlayerToken(gameId: widget.gameId, player: p, size: 26)
            else
              Icon(Icons.handshake_outlined, size: 24, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            if (mood == TurnMood.won) ...[
              Icon(Icons.emoji_events, size: 20, color: palette.trophy),
              const SizedBox(width: 6),
            ],
            if (mood == TurnMood.waiting) ...[
              Icon(Icons.hourglass_top, key: const Key('shell-waiting'), size: 18, color: ink),
              const SizedBox(width: 4),
            ],
            // liveRegion: screen readers announce turn changes and results.
            Flexible(
              child: Semantics(
                liveRegion: true,
                child: Text(widget.status, key: const Key('shell-status'), style: style),
              ),
            ),
          ],
        ),
      );
    return ScaleTransition(
      scale: _scale,
      child: badge == null
          ? pill
          : Stack(
              clipBehavior: Clip.none,
              children: [
                pill,
                PositionedDirectional(
                  top: -10,
                  end: -4,
                  child: _StatusBadge(key: const Key('shell-status-badge'), text: badge),
                ),
              ],
            ),
    );
  }
}

/// A small badge on the status pill, e.g. "noch 2 Runden".
class _StatusBadge extends StatelessWidget {
  final String text;
  const _StatusBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.surface, width: 1.5),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSecondary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Hot-seat (KLD-067): both players side by side, each as token + name
/// (KLD-103: the default name when none was typed); the one to move at full strength with an
/// underline in its colour, the other faded. Decorative: the status line
/// already says whose turn it is.
class _PlayersLegend extends StatelessWidget {
  final String gameId;
  final PlayerLabels labels;
  final Player? current;

  const _PlayersLegend({required this.gameId, required this.labels, required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = KlunkiPalette.of(context);
    final duration = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 250);
    Widget entry(Player p) {
      final on = current == p;
      final l10n = AppLocalizations.of(context);
      // Same names: "Anna (1)" / "Anna (2)" as in the status line (KLD-106);
      // in games with pieces the token shows no number.
      final n = bidiName(context, labels.name(l10n, p));
      final name = labels.sameNames(l10n) ? l10n.playerLabel(n, PlayerLabels.numberOf(p)) : n;
      final color = playerColor(palette, gameId, labels.tokenOf(p));
      return AnimatedOpacity(
        key: Key('shell-player-${playerMark(p)}'),
        opacity: current == null || on ? 1 : 0.6,
        duration: duration,
        child: AnimatedContainer(
          duration: duration,
          padding: const EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: on ? visibleOn(context, color) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerToken(gameId: gameId, player: p, size: 20),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 72),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: on ? FontWeight.w700 : null),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: Row(
        key: const Key('shell-players'),
        mainAxisSize: MainAxisSize.min,
        children: [entry(Player.a), const SizedBox(width: 10), entry(Player.b)],
      ),
    );
  }
}

/// [color] as a line or edge on the page: the colour itself unless it
/// would vanish there (contrast to the card colour below [minRatio]: light
/// stone on paper, dark stone on the dark table), then the theme outline.
Color visibleOn(BuildContext context, Color color, {double minRatio = 1.4}) =>
    contrastRatio(color, KlunkiPalette.of(context).card) >= minRatio ? color : Theme.of(context).colorScheme.outline;

/// Counts a started game of [gameId] (KLD-123) and says whether its "Neu
/// hier? So geht's" line shows: for a game with a rules page, up to the
/// [_GameScreenState.rulesIntroGames]th game, until the page was opened.
/// Shared by [GameScreen] and the seat shell.
bool countGameForRulesIntro(String gameId) {
  if (!hasRules(gameId)) return false;
  final tips = SeenTips.shared;
  final n = tips.countUp(SeenTips.gamesStarted(gameId));
  return n <= _GameScreenState.rulesIntroGames && !tips.has(SeenTips.rulesOpened(gameId));
}

/// "Neu hier? So geht's ›" (KLD-123): opens the rules page. Shared by
/// [GameScreen] and the seat shell.
class RulesIntroLine extends StatelessWidget {
  final VoidCallback onTap;
  const RulesIntroLine({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return TextButton(
      key: const Key('shell-rules-intro'),
      onPressed: onTap,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 4, 0),
        foregroundColor: color,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(AppLocalizations.of(context).rulesNewHere)),
          Icon(Icons.chevron_right, size: 18, color: color),
        ],
      ),
    );
  }
}

/// The app bar title (KLD-123; also the seat shell's): with five actions on
/// a phone a game title may not fit. It shrinks a little first (down to
/// [minScale] of the app bar's size), only then it is cut with "…".
class ShellTitle extends StatelessWidget {
  final String text;
  const ShellTitle(this.text, {super.key});

  static const double minScale = 0.75;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return LayoutBuilder(builder: (context, box) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      if (!box.hasBoundedWidth || width <= box.maxWidth) return Text(text, maxLines: 1);
      final scale = box.maxWidth / width;
      final size = (style.fontSize ?? 20) * (scale < minScale ? minScale : scale);
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: size * 0.98));
    });
  }
}

/// One entry of the shell's "⋮" menu ([ShellMenu]).
@immutable
class ShellMenuEntry {
  final Key key;
  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  const ShellMenuEntry({required this.key, required this.icon, required this.label, required this.onSelected});
}

/// The "⋮" menu at the end of a game's app bar (key `shell-menu`): the
/// actions needed now and then ("Spielernamen", "Neues Spiel"), each with
/// icon and label and its own key, so the game title fits on a phone next
/// to resign, history and "Regeln". Shared by [GameScreen] and the seat
/// shell. Nothing when [entries] is empty.
class ShellMenu extends StatelessWidget {
  final List<ShellMenuEntry> entries;
  const ShellMenu({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<VoidCallback>(
      key: const Key('shell-menu'),
      icon: const Icon(Icons.more_vert),
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      onSelected: (f) => f(),
      itemBuilder: (_) => [
        for (final e in entries)
          PopupMenuItem<VoidCallback>(
            key: e.key,
            value: e.onSelected,
            child: Row(
              children: [
                // Not the app bar's icon colour (white on the accent).
                Icon(e.icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Flexible(child: Text(e.label)),
              ],
            ),
          ),
      ],
    );
  }
}
