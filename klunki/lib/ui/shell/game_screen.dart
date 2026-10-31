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
import 'handover_cover.dart';
import 'player_labels.dart';

export 'player_labels.dart' show PlayerLabels, PlayerLabelsScope;

/// Builds the game-specific board inside a [GameScreen].
typedef BoardBuilder = Widget Function(BuildContext context, GameController controller);

/// Turns an accepted move into readable text for the move history, in the
/// language of [l10n].
typedef MoveDescriber = String Function(AppLocalizations l10n, AcceptedMove move);

/// Player marks used everywhere in the UI, consistent with the text console:
/// player A is "X", player B is "O".
String playerMark(Player p) => PlayerLabels.markOf(p);

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
}

/// The shared frame every game screen plugs into:
///
/// * app bar with the game title, undo (hot-seat), restart, resign
///   ("Aufgeben", KLD-065: with a confirmation; in hot-seat the dialog asks
///   which player gives up) and move history,
/// * status line ("X ist am Zug", with names "Anna (X) ist am Zug" or, on a
///   network device, "Du bist am Zug (X)" / "Warte auf Ben (O)…") plus a
///   hint line the board can set
///   through [GameScreen.of] → [GameShell.setHint],
/// * a [HandoverCover] over the body while the controller needs a handover,
/// * a result dialog ("Nochmal" / "Menü") once the game is over.
///
/// Players are named through the nearest [PlayerLabelsScope] (KLD-056):
/// marks only by default, names in network games and, when the players typed
/// some, in hot-seat games (app bar action "Spielernamen").
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

  const GameScreen({
    super.key,
    required this.controller,
    required this.boardBuilder,
    this.describeMove,
    this.title,
    this.handoverDetail,
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
  bool _resultShown = false;
  bool _resultHeld = false;
  late GameTransport _transport;

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
  }

  @override
  void didUpdateWidget(GameScreen old) {
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
        // Restarted: fresh game, fresh hint.
        _transport = controller.transport;
        _hint = null;
      }
    });
    if (!controller.game.isOver) {
      _resultShown = false;
    } else {
      _maybeShowResult();
    }
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
        content: reason.isEmpty ? null : Text(reason, key: const Key('result-reason')),
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
    final who = await showDialog<Player>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    if (who == null || !mounted) return;
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
    return labels.isLocal(p) ? l10n.shellYourTurn(playerMark(p)) : l10n.shellWaitingFor(label(p));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final accent = KlunkiPalette.of(context).accent(controller.spec.id);
    final game = controller.game;
    final status = _status(context, l10n);
    final labels = PlayerLabelsScope.of(context);
    // Null once the game is over: the winner (or none for a draw).
    final turnPlayer = game.isOver ? game.result.winner : game.currentPlayer;
    final mood = game.isOver
        ? (turnPlayer == null ? TurnMood.draw : TurnMood.won)
        : (labels.local != null && !labels.isLocal(game.currentPlayer) ? TurnMood.waiting : TurnMood.active);
    return _GameShellScope(
      shell: this,
      hint: _hint,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: accent.color,
          foregroundColor: accent.onColor,
          title: Text(widget.title ?? localizedGameTitle(l10n, controller.spec.id, fallback: controller.spec.title)),
          actions: [
            if (controller.transport is HotSeatTransport)
              IconButton(
                key: const Key('shell-undo'),
                tooltip: l10n.shellUndo,
                icon: const Icon(Icons.undo),
                onPressed: controller.canUndo ? controller.undo : null,
              ),
            // Hot-seat names (KLD-056), when the app provides the store.
            if (_canRestart && PlayerNameScope.maybeOf(context) != null)
              IconButton(
                key: const Key('shell-names'),
                tooltip: l10n.hotSeatNamesTitle,
                icon: const Icon(Icons.people_outline),
                onPressed: () => showHotSeatNamesDialog(context),
              ),
            if (_canRestart)
              IconButton(
                key: const Key('shell-restart'),
                tooltip: l10n.shellNewGame,
                icon: const Icon(Icons.refresh),
                onPressed: _restart,
              ),
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
                              ),
                              // Hot-seat: both players with their colours (KLD-067).
                              if (labels.local == null)
                                _PlayersLegend(
                                  gameId: controller.spec.id,
                                  labels: labels,
                                  current: game.isOver ? null : game.currentPlayer,
                                ),
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
                      ],
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

  /// The turn edge: the colour of the player to move (faded while waiting
  /// for the other device), the winner's colour at the end, none for a draw.
  Color _edgeColor(BuildContext context, TurnMood mood, Player? p) {
    if (p == null) return Colors.transparent;
    final palette = KlunkiPalette.of(context);
    final c = visibleOn(context, playerColor(palette, controller.spec.id, p));
    return mood == TurnMood.waiting ? c.withValues(alpha: 0.35) : c;
  }
}

class _GameShellScope extends InheritedWidget {
  final GameShell shell;
  final String? hint;

  const _GameShellScope({required this.shell, required this.hint, required super.child});

  @override
  bool updateShouldNotify(_GameShellScope old) => old.hint != hint;
}

/// A player's piece as a small round token in the player's colour
/// ([playerColor]: 4 Gewinnt red/yellow, Mühle light/dark, accent / slate
/// elsewhere, see `game_visuals.dart`) plus the mark, so the identity is
/// never colour-only (UX-REVIEW 2.1, 2.10).
class PlayerToken extends StatelessWidget {
  final String gameId;
  final Player player;
  final double size;
  const PlayerToken({super.key, required this.gameId, required this.player, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final fill = playerColor(KlunkiPalette.of(context), gameId, player);
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
          playerMark(player),
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

  const _TurnIndicator({
    required this.gameId,
    required this.player,
    required this.mood,
    required this.network,
    required this.status,
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
    final color = p == null ? theme.colorScheme.outline : playerColor(palette, widget.gameId, p);

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
    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
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
      ),
    );
  }
}

/// Hot-seat (KLD-067): both players side by side, each as token + name
/// (just the token when unnamed); the one to move at full strength with an
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
      final name = labels.nameOf(p);
      final color = playerColor(palette, gameId, p);
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
              if (name != null) ...[
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 72),
                  child: Text(
                    bidiName(context, name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: on ? FontWeight.w700 : null),
                  ),
                ),
              ],
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
