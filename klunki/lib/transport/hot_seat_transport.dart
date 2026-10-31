import 'dart:async';

import 'package:klunki_engine/klunki_engine.dart';

import 'game_transport.dart';

/// Hot-seat transport: one device, both players local, the phone is handed
/// back and forth. Owns the engine instance; the engine's `applyMove` is the
/// single source of truth for legality.
///
/// [accepted] is a synchronous broadcast stream: listeners have seen a move
/// before the [submit] future completes.
class HotSeatTransport implements GameTransport {
  @override
  final GameConfig config;

  Game _game;
  final List<AcceptedMove> _moves = [];
  final StreamController<AcceptedMove> _accepted = StreamController<AcceptedMove>.broadcast(sync: true);
  bool _disposed = false;

  HotSeatTransport(this.config) : _game = createGame(config);

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
    final player = _game.currentPlayer;
    if (!localPlayers.contains(player)) return const SubmitResult.rejected(RejectReason.notYourTurn);

    final copy = Map<String, dynamic>.unmodifiable(move);
    GameEvent? event;
    try {
      event = _game.applyMove(copy);
    } catch (_) {
      // Malformed move (e.g. wrong value type): the engines validate before
      // mutating, so the state is unchanged.
      event = null;
    }
    if (event == null) return const SubmitResult.rejected(RejectReason.illegal);

    final accepted = AcceptedMove(index: _moves.length, player: player, move: copy, event: event);
    _moves.add(accepted);
    _accepted.add(accepted);
    return SubmitResult.accepted(accepted);
  }

  /// Whether [undo] can take back a move.
  bool get canUndo => !_disposed && _moves.isNotEmpty;

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
    return true;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _accepted.close();
  }
}
