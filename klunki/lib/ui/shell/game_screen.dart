import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';
import '../../transport/game_transport.dart';
import '../../transport/hot_seat_transport.dart';
import '../game_titles.dart';
import 'handover_cover.dart';

/// Builds the game-specific board inside a [GameScreen].
typedef BoardBuilder = Widget Function(BuildContext context, GameController controller);

/// Turns an accepted move into readable text for the move history, in the
/// language of [l10n].
typedef MoveDescriber = String Function(AppLocalizations l10n, AcceptedMove move);

/// Player marks used everywhere in the UI, consistent with the text console:
/// player A is "X", player B is "O".
String playerMark(Player p) => p == Player.a ? 'X' : 'O';

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
}

/// The shared frame every game screen plugs into:
///
/// * app bar with the game title, undo (hot-seat), restart and move history,
/// * status line ("X ist am Zug") plus a hint line the board can set
///   through [GameScreen.of] → [GameShell.setHint],
/// * a [HandoverCover] over the body while the controller needs a handover,
/// * a result dialog ("Nochmal" / "Menü") once the game is over.
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

  const GameScreen({
    super.key,
    required this.controller,
    required this.boardBuilder,
    this.describeMove,
    this.title,
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
    final over = controller.game.isOver;
    if (!over) {
      _resultShown = false;
    } else if (!_resultShown) {
      _resultShown = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showResult();
      });
    }
  }

  Future<void> _showResult() async {
    final r = controller.game.result;
    final l10n = AppLocalizations.of(context);
    final headline = r.draw || r.winner == null ? l10n.shellDraw : l10n.shellWins(playerMark(r.winner!));
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('result-dialog'),
        title: Text(headline),
        content: r.reason.isEmpty ? null : Text(r.reason),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.shellMenu)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.shellPlayAgain)),
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

  String _describe(AppLocalizations l10n, AcceptedMove m) => widget.describeMove?.call(l10n, m) ?? m.move.toString();

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
                  itemCount: moves.length,
                  itemBuilder: (_, i) {
                    final m = moves[i];
                    return ListTile(
                      dense: true,
                      leading: Text('${m.index + 1}.'),
                      title: Text(l10n.shellHistoryEntry(playerMark(m.player), _describe(l10n, m))),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _status(AppLocalizations l10n) {
    final game = controller.game;
    final r = game.result;
    if (r.isOver) {
      return r.winner == null ? l10n.shellDraw : l10n.shellHasWon(playerMark(r.winner!));
    }
    return l10n.shellToMove(playerMark(game.currentPlayer));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return _GameShellScope(
      shell: this,
      hint: _hint,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? localizedGameTitle(l10n, controller.spec.id, fallback: controller.spec.title)),
          actions: [
            if (controller.transport is HotSeatTransport)
              IconButton(
                key: const Key('shell-undo'),
                tooltip: l10n.shellUndo,
                icon: const Icon(Icons.undo),
                onPressed: controller.canUndo ? controller.undo : null,
              ),
            IconButton(
              key: const Key('shell-restart'),
              tooltip: l10n.shellNewGame,
              icon: const Icon(Icons.refresh),
              onPressed: _restart,
            ),
            IconButton(
              key: const Key('shell-history'),
              tooltip: l10n.shellMoves,
              icon: const Icon(Icons.history),
              onPressed: _showHistory,
            ),
          ],
        ),
        body: SafeArea(
          child: HandoverCover(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(_status(l10n), key: const Key('shell-status'), style: theme.textTheme.titleMedium),
                ),
                if (_hint != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(_hint!, key: const Key('shell-hint'), style: theme.textTheme.bodyMedium),
                  ),
                Expanded(
                  child: Builder(builder: (ctx) => widget.boardBuilder(ctx, controller)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameShellScope extends InheritedWidget {
  final GameShell shell;
  final String? hint;

  const _GameShellScope({required this.shell, required this.hint, required super.child});

  @override
  bool updateShouldNotify(_GameShellScope old) => old.hint != hint;
}
