import 'package:klunki_engine/klunki_engine.dart';

/// Protocol version carried as `v` in every message (and `protocol` in `hello`).
const int protocolVersion = 1;

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
class MoveAccepted extends NetEvent {
  final int index;
  final Player player;
  final Map<String, dynamic> move;
  const MoveAccepted(this.index, this.player, this.move);

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
