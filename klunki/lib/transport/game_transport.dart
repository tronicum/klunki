import 'package:klunki_engine/klunki_engine.dart';

/// The transport contract shared by every game screen.
///
/// The engine is pure: `Game.applyMove(move) -> GameEvent?`. A [GameTransport]
/// decides *where moves come from* — the local device (hot-seat), a Wi-Fi
/// peer, later Bluetooth — and runs every one of them through the *same*
/// engine, so the rules can never diverge between players.
///
/// [config] plus [moves] is a full replay of the game
/// (`replay(config, moves.map((m) => m.move))`), which is what network sync
/// and reconnect rely on.
abstract class GameTransport {
  /// Game id + seed this session was created from.
  GameConfig get config;

  /// Players whose moves are produced on this device. Hot-seat: both;
  /// network: just this device's player.
  Set<Player> get localPlayers;

  /// Read-only view of the authoritative local engine state. Never call
  /// `applyMove` on it directly; go through [submit].
  Game get game;

  /// Every accepted move so far, in order (`moves[i].index == i`).
  List<AcceptedMove> get moves;

  /// Every accepted move from any side, in order.
  Stream<AcceptedMove> get accepted;

  /// Submits a move for the current player (a resign, `Game.resignMove`,
  /// for the player it names, any time). Rejections never change state.
  Future<SubmitResult> submit(Map<String, dynamic> move);

  /// Releases resources; afterwards [submit] rejects with
  /// [RejectReason.disconnected].
  void dispose();
}

/// A move the engine accepted.
class AcceptedMove {
  /// Position in the move log (0-based).
  final int index;

  /// The player who made the move.
  final Player player;

  /// The move as submitted (unmodifiable).
  final Map<String, dynamic> move;

  /// What the engine reported for it.
  final GameEvent event;

  const AcceptedMove({
    required this.index,
    required this.player,
    required this.move,
    required this.event,
  });

  @override
  String toString() => 'AcceptedMove(#$index ${player.name} $move)';
}

/// Why a submitted move was not applied.
enum RejectReason {
  /// The current player is not one of the transport's local players.
  notYourTurn,

  /// The engine rejected the move (or it was malformed).
  illegal,

  /// The game is already over.
  gameOver,

  /// The transport is disposed / the connection is gone.
  disconnected,
}

/// Outcome of [GameTransport.submit]: either [accepted] or a [reason].
class SubmitResult {
  final AcceptedMove? accepted;
  final RejectReason? reason;

  const SubmitResult.accepted(AcceptedMove this.accepted) : reason = null;
  const SubmitResult.rejected(RejectReason this.reason) : accepted = null;

  bool get isAccepted => accepted != null;

  /// The engine event for an accepted move, else null.
  GameEvent? get event => accepted?.event;

  @override
  String toString() =>
      isAccepted ? 'SubmitResult.accepted($accepted)' : 'SubmitResult.rejected(${reason!.name})';
}
