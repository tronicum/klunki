import 'package:flutter/widgets.dart';

import '../game/game_controller.dart';
import '../transport/game_transport.dart';
import '../transport/hot_seat_transport.dart';
import 'save_store.dart';
import 'saved_game.dart';

/// Keeps the save of a running hot-seat game up to date (KLD-079): writes
/// the game's slot in [store] after every accepted move or undo, when the
/// app goes to the background (`paused` / `hidden`) and when the game screen
/// closes; deletes it once the game is over.
///
/// Only a [HotSeatTransport] is saved (network games are not, yet). A game
/// without a move writes nothing, so opening a game and leaving it keeps an
/// older save of the same game; undoing back to the start deletes the save
/// this game wrote.
class GameAutosave with WidgetsBindingObserver {
  final GameController controller;
  final SaveStore store;

  /// The typed hot-seat names per seat (null = default name), read at save
  /// time.
  final List<String?> Function(int players) names;

  GameTransport? _transport;
  int _count = 0;

  /// This session's game holds the slot (it wrote it, or was resumed from
  /// it): only then does its end delete the save.
  bool _owns;

  GameAutosave({required this.controller, required this.store, required this.names, bool resumed = false})
      : _owns = resumed {
    _transport = controller.transport;
    _count = controller.moves.length;
    controller.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  String get _gameId => controller.config.gameId;

  void _changed() {
    final t = controller.transport;
    final n = controller.moves.length;
    final sameGame = identical(t, _transport);
    if (sameGame && n == _count && !controller.game.isOver) return;
    final undoneToStart = sameGame && n == 0 && _count > 0;
    _transport = t;
    _count = n;
    if (undoneToStart && _owns) {
      store.remove(_gameId);
      return;
    }
    saveNow();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) saveNow();
  }

  /// Writes the current state now (or deletes the save of a finished game).
  void saveNow() {
    final t = controller.transport;
    if (t is! HotSeatTransport) return;
    if (controller.game.isOver) {
      if (_owns) {
        store.remove(_gameId);
        _owns = false;
      }
      return;
    }
    final moves = controller.moves;
    if (moves.isEmpty) return;
    final clock = t.clock;
    store.save(SavedGame.now(
      t.config,
      [for (final m in moves) m.move],
      names: names(t.config.players),
      clock: clock?.snapshot(t.clockNow()),
      clockBefore: clock == null ? const [] : t.clockHistory,
    ));
    _owns = true;
  }

  /// Saves a last time and stops listening (the game screen closes).
  void dispose() {
    saveNow();
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_changed);
  }
}
