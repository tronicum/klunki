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

  /// True when [game] is the full engine (hot-seat, network host, network
  /// guest of a game without hidden information), so a screen may replay
  /// [moves] on a copy to preview a move. False for a network guest of a
  /// hidden-information game: [game] is then a read-only view of what this
  /// player may know, [config] carries no secret seed, and [moves] /
  /// events are redacted (KLD-064).
  bool get fullInformation;

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

  /// The player who made the move. In a game with more than two seats
  /// (KLD-088/KLD-119) this is only meaningful for seats 0 and 1 (A and B);
  /// a move of seat 2 or 3 carries [Player.a] here: read [seat].
  final Player player;

  /// The seat that made the move (`0 … playerCount-1`); [player]'s index
  /// unless given (every two-player transport).
  final int seat;

  /// The move as submitted (unmodifiable).
  final Map<String, dynamic> move;

  /// What the engine reported for it.
  final GameEvent event;

  const AcceptedMove({
    required this.index,
    required this.player,
    int? seat,
    required this.move,
    required this.event,
  }) : seat = seat ?? (player == Player.a ? 0 : 1);

  @override
  String toString() => 'AcceptedMove(#$index ${seat < 2 ? player.name : 'seat $seat'} $move)';
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
