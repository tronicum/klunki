import 'package:klunki_engine/klunki_engine.dart';

/// Protocol version carried as `v` in every message (and `protocol` in `hello`).
/// 2 since KLD-064 (hidden information is redacted; see PROTOCOL.md).
const int protocolVersion = 2;

/// Something that happened in a session. Host and guest share these types.
sealed class NetEvent {
  const NetEvent();
}

/// The other side completed the handshake ([reconnect]: it was here before).
class PeerConnected extends NetEvent {
  final String name;
  final bool reconnect;
  const PeerConnected(this.name, {this.reconnect = false});
  @override
  String toString() => 'PeerConnected($name, reconnect: $reconnect)';
}

/// The connection to the other side ended (bye, socket closed, error, timeout).
class PeerDisconnected extends NetEvent {
  final String reason;
  final bool timedOut;
  const PeerDisconnected(this.reason, {this.timedOut = false});
  @override
  String toString() => 'PeerDisconnected($reason, timedOut: $timedOut)';
}

/// A move the host accepted; [index] is its position in the move log.
///
/// On a guest of a hidden-information game [move] and [event] are redacted:
/// what this player may know (KLD-064).
class MoveAccepted extends NetEvent {
  final int index;
  final Player player;
  final Map<String, dynamic> move;

  /// What the engine reported for the move (as this side may see it); null
  /// only for entries built without an engine.
  final GameEvent? event;
  const MoveAccepted(this.index, this.player, this.move, {this.event});

  @override
  String toString() => 'MoveAccepted(#$index ${player.name} $move)';
}

/// The host refused a guest move; the game state did not change.
class MoveRejected extends NetEvent {
  final int index;
  final String reason;
  const MoveRejected(this.index, this.reason);
  @override
  String toString() => 'MoveRejected(#$index $reason)';
}

/// Guest only: after a reconnect the game was rebuilt from the host's snapshot
/// via `replay`. [KlunkiGuest.game] is a fresh instance holding [moves] moves.
class Resynced extends NetEvent {
  final int moves;
  const Resynced(this.moves);
  @override
  String toString() => 'Resynced($moves)';
}

/// Guest of a hidden-information game: the host revealed its secrets at the
/// end and the whole game replayed exactly as reported (KLD-064).
class GameVerified extends NetEvent {
  const GameVerified();
  @override
  String toString() => 'GameVerified()';
}

/// Guest of a hidden-information game: the host's reveal did not match its
/// commitments, or the replay differs from what the host reported. [reason]
/// is English, for logs; the app shows its own localized text.
class VerificationFailed extends NetEvent {
  final String reason;
  const VerificationFailed(this.reason);
  @override
  String toString() => 'VerificationFailed($reason)';
}

/// State of the end-of-game check on a guest (KLD-064).
enum Verification {
  /// The game has no hidden information: the guest replays every move itself.
  notNeeded,

  /// Waiting for the host's `reveal` (sent when the game is over).
  pending,

  /// [GameVerified].
  verified,

  /// [VerificationFailed].
  failed,
}

/// A protocol problem (malformed input, divergent logs, refused handshake).
class NetError extends NetEvent {
  final String message;
  const NetError(this.message);
  @override
  String toString() => 'NetError($message)';
}

/// Thrown by [KlunkiGuest.connect] / [KlunkiGuest.reconnect] when the
/// handshake fails.
class NetException implements Exception {
  final String message;
  const NetException(this.message);
  @override
  String toString() => 'NetException: $message';
}

Player playerFromName(Object? name) => switch (name) {
      'a' => Player.a,
      'b' => Player.b,
      _ => throw ProtocolException('bad player: $name'),
    };

Player otherPlayer(Player p) => p == Player.a ? Player.b : Player.a;

/// Raised by message handlers for input that breaks the protocol; the
/// connection answers with `error` and closes.
class ProtocolException implements Exception {
  final String message;
  const ProtocolException(this.message);
  @override
  String toString() => 'ProtocolException: $message';
}
