import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:klunki_engine/klunki_engine.dart';

import 'game_clock.dart';
import 'game_transport.dart';

/// Hot-seat transport: one device, both players local (every seat in a
/// game for 3–4 players, KLD-119), the phone is handed back and forth. Owns the engine instance; the engine's `applyMove` is the
/// single source of truth for legality.
///
/// [accepted] is a synchronous broadcast stream: listeners have seen a move
/// before the [submit] future completes.
///
/// A chess game with a clock (KLD-126): the transport owns the clock. White's
/// clock starts with the transport, a board move switches it, the flag
/// fall is submitted here as [ChessGame.timeoutMove], [setClockPaused] is
/// the pause cover (no agreement on one device), and [undo] puts the clock
/// back to where it stood before the undone move.
class HotSeatTransport implements GameTransport, ClockedTransport {
  @override
  final GameConfig config;

  Game _game;
  final List<AcceptedMove> _moves = [];
  final StreamController<AcceptedMove> _accepted = StreamController<AcceptedMove>.broadcast(sync: true);
  bool _disposed = false;

  // KLD-126: the chess clock.
  ChessClock? _clock;
  final int Function() _now;
  final List<ChessClockSnapshot> _clockBefore = []; // parallel to _moves
  final ClockNotifier _clockChanges = ClockNotifier();
  Timer? _flagTimer;
  bool _clockPaused = false;

  /// [clockNow]: the clock's time in ms (default: a monotonic stopwatch;
  /// tests pass a fake).
  HotSeatTransport(this.config, {int Function()? clockNow})
      : _game = createGame(config),
        _now = clockNow ?? stopwatchClock() {
    final control = config.gameId == 'chess' ? config.chessClock : null;
    if (control != null) {
      _clock = ChessClock(control)..start(_game.currentPlayer, _now());
      _armFlag();
    }
  }

  @override
  ChessClock? get clock => _clock;

  @override
  int clockNow() => _now();

  @override
  Listenable get clockChanges => _clockChanges;

  /// Whether the clocks stand still behind the pause cover.
  bool get clockPaused => _clockPaused;

  /// Stops or restarts both clocks (the hot-seat pause cover, KLD-126).
  void setClockPaused(bool paused) {
    final clock = _clock;
    if (clock == null || _disposed || paused == _clockPaused) return;
    _clockPaused = paused;
    clock.setPaused(paused, _now());
    _clockChanged();
  }

  void _clockChanged() {
    _armFlag();
    _clockChanges.changed();
  }

  void _armFlag() {
    _flagTimer?.cancel();
    final until = _clock?.untilFlag(_now());
    if (until == null || _disposed || _game.isOver) return;
    _flagTimer = Timer(Duration(milliseconds: until < 0 ? 0 : until), _onFlag);
  }

  void _onFlag() {
    final clock = _clock;
    if (clock == null || _disposed || _game.isOver) return;
    final flagged = clock.flagged(_now());
    if (flagged == null) return _armFlag(); // fired early
    submitSync(ChessGame.timeoutMove(flagged));
  }

  @override
  Set<Player> get localPlayers => const {Player.a, Player.b};

  @override
  Game get game => _game;

  @override
  bool get fullInformation => true;

  @override
  List<AcceptedMove> get moves => List.unmodifiable(_moves);

  @override
  Stream<AcceptedMove> get accepted => _accepted.stream;

  @override
  Future<SubmitResult> submit(Map<String, dynamic> move) async => submitSync(move);

  /// Synchronous core of [submit].
  SubmitResult submitSync(Map<String, dynamic> move) {
    if (_disposed) return const SubmitResult.rejected(RejectReason.disconnected);
    if (_game.isOver) return const SubmitResult.rejected(RejectReason.gameOver);
    // The player to move, or the resigner for a resign (KLD-065); by seat
    // in a game with more than two seats (KLD-119), where `playerOf` would
    // throw for seats 2 and 3. Every seat is local here.
    final game = _game;
    final int seat;
    final Player player;
    if (game is SeatGame && (game as SeatGame).playerCount > 2) {
      seat = (game as SeatGame).seatOfMove(move);
      player = seat == 1 ? Player.b : Player.a;
    } else {
      player = game.playerOf(move);
      seat = player.index;
      if (!localPlayers.contains(player)) return const SubmitResult.rejected(RejectReason.notYourTurn);
    }

    final copy = Map<String, dynamic>.unmodifiable(move);
    final clock = _clock;
    final now = _now();
    // KLD-126: a move after the flag fell (its timer not run yet: a busy
    // or sleeping device) is too late; the time-out ends the game instead.
    if (clock != null && !ChessGame.isTimeout(copy)) {
      final flagged = clock.flagged(now);
      if (flagged != null) {
        submitSync(ChessGame.timeoutMove(flagged));
        return const SubmitResult.rejected(RejectReason.gameOver);
      }
    }
    final before = clock?.snapshot(now);
    GameEvent? event;
    try {
      event = _game.applyMove(copy);
    } catch (_) {
      // Malformed move (e.g. wrong value type): the engines validate before
      // mutating, so the state is unchanged.
      event = null;
    }
    if (event == null) return const SubmitResult.rejected(RejectReason.illegal);

    final accepted = AcceptedMove(index: _moves.length, player: player, seat: seat, move: copy, event: event);
    _moves.add(accepted);
    if (clock != null) {
      _clockBefore.add(before!);
      if (ChessGame.isBoardMove(copy)) clock.moveMade(player, now);
      if (_game.isOver) clock.stop(now);
    }
    _accepted.add(accepted);
    if (clock != null) _clockChanged();
    return SubmitResult.accepted(accepted);
  }

  /// Whether [undo] can take back a move: not past a move the game marks
  /// as final (`GameSpec.undoBarrier`, e.g. Mäxchen's doubt, KLD-121).
  bool get canUndo {
    if (_disposed || _moves.isEmpty) return false;
    final barrier = specById(config.gameId)?.undoBarrier;
    return barrier == null || !barrier(_moves.last.move);
  }

  /// Takes back the last accepted move by replaying the log minus one on a
  /// fresh engine. Returns false if there is nothing to undo. Emits nothing
  /// on [accepted].
  bool undo() {
    if (!canUndo) return false;
    final rest = _moves.sublist(0, _moves.length - 1);
    final rebuilt = replay(config, rest.map((m) => m.move));
    if (rebuilt == null) {
      throw StateError('replay of the accepted log failed for $config');
    }
    _game = rebuilt;
    _moves.removeLast();
    // KLD-126: the clock as it stood before the move, still paused if the
    // cover is up.
    final control = _clock?.control;
    if (control != null) {
      final now = _now();
      _clock = ChessClock.fromSnapshot(control, _clockBefore.removeLast(), now)..setPaused(_clockPaused, now);
      _clockChanged();
    }
    return true;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _flagTimer?.cancel();
    _accepted.close();
  }
}
