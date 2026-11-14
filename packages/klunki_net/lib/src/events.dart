import 'package:klunki_engine/klunki_engine.dart';

/// Protocol version carried as `v` in every message (and `protocol` in `hello`).
/// 2 since KLD-064 (hidden information is redacted), 3 since KLD-085 (the
/// `hello`s carry build fingerprints; see PROTOCOL.md).
///
/// Every two-player session speaks exactly this version, so builds before
/// KLD-088 step 4 still play two-player games with this one.
const int protocolVersion = 3;

/// The protocol of a **table**: a session for 3–4 players, the host and up
/// to three guests (KLD-088 step 4). A guest that can sit at a table says
/// so in its (version 3) `hello` (`maxProtocol`); the host of a table then
/// answers in this version and every later message of that connection
/// carries `v: 4`. See PROTOCOL.md, "Tables".
const int tableProtocolVersion = 4;

/// Something that happened in a session. Host and guest share these types.
sealed class NetEvent {
  const NetEvent();
}

/// The other side completed the handshake ([reconnect]: it was here before).
///
/// At a table (KLD-088) the host emits it per guest with the guest's [seat];
/// a guest gets none (it learns who is there from [LobbyChanged]).
class PeerConnected extends NetEvent {
  final String name;
  final bool reconnect;

  /// The guest's seat at a table (host side), else null.
  final int? seat;
  const PeerConnected(this.name, {this.reconnect = false, this.seat});
  @override
  String toString() => 'PeerConnected($name, reconnect: $reconnect${seat == null ? '' : ', seat $seat'})';
}

/// The connection to the other side ended (bye, socket closed, error, timeout).
///
/// At a table (KLD-088) the host emits it per guest with the guest's [seat];
/// a guest emits it (without a seat) when its own connection to the host ends.
class PeerDisconnected extends NetEvent {
  final String reason;
  final bool timedOut;

  /// The guest's seat at a table (host side), else null.
  final int? seat;
  const PeerDisconnected(this.reason, {this.timedOut = false, this.seat});
  @override
  String toString() => 'PeerDisconnected($reason, timedOut: $timedOut${seat == null ? '' : ', seat $seat'})';
}

/// One seat of a table (KLD-088): who sits there and whether that device is
/// connected now. The host's seat (0) is always [here].
class TableSeat {
  /// The player's name (sanitised); null for a seat nobody took yet.
  final String? name;

  /// Connected now (the host: always).
  final bool here;
  const TableSeat(this.name, {this.here = false});

  /// Nobody sits here yet.
  bool get free => name == null;

  Map<String, dynamic>? toJson() => name == null ? null : {'name': name, 'here': here};

  @override
  bool operator ==(Object other) => other is TableSeat && other.name == name && other.here == here;
  @override
  int get hashCode => Object.hash(name, here);
  @override
  String toString() => name == null ? 'free' : '$name${here ? '' : ' (away)'}';
}

/// A table (KLD-088): the seats changed (a guest sat down, left the lobby,
/// went away or came back) or the game started. Host and guests.
class LobbyChanged extends NetEvent {
  /// Seat by seat, `0 … players-1` (seat 0 is the host).
  final List<TableSeat> seats;

  /// Every seat was taken once: the game runs (paused while a seat is away).
  final bool started;
  const LobbyChanged(this.seats, {required this.started});

  /// Seats nobody took yet (before the start).
  int get missing => seats.where((s) => s.free).length;

  /// Every seat is taken and connected.
  bool get complete => seats.every((s) => !s.free && s.here);
  @override
  String toString() => 'LobbyChanged($seats, started: $started)';
}

/// A move the host accepted; [index] is its position in the move log.
///
/// On a guest of a hidden-information game [move] and [event] are redacted:
/// what this player may know (KLD-064).
///
/// At a table (KLD-088) entries are by [seat] (`0 … players-1`); [player]
/// exists only for seats 0 and 1.
class MoveAccepted extends NetEvent {
  final int index;

  /// The seat that made the move: the [Player]'s index in a two-player game.
  final int seat;
  final Map<String, dynamic> move;

  /// What the engine reported for the move (as this side may see it); null
  /// only for entries built without an engine.
  final GameEvent? event;
  MoveAccepted(this.index, Player player, this.move, {this.event}) : seat = player.index;

  /// An entry of a table (KLD-088), by seat.
  const MoveAccepted.bySeat(this.index, this.seat, this.move, {this.event});

  /// The player who moved; throws for seat 2+ (read [seat]).
  Player get player => switch (seat) {
        0 => Player.a,
        1 => Player.b,
        _ => throw StateError('seat $seat has no Player (KLD-088)'),
      };

  @override
  String toString() => 'MoveAccepted(#$index ${seat < 2 ? player.name : 'seat $seat'} $move)';
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

/// Host only: a guest could not join because the two builds do not fit
/// together (KLD-085); the guest was refused, the host keeps waiting.
class IncompatiblePeer extends NetEvent {
  final VersionMismatch mismatch;
  const IncompatiblePeer(this.mismatch);
  @override
  String toString() => 'IncompatiblePeer($mismatch)';
}

/// What does not match between two builds (KLD-085), as the `code` of the
/// `error` message that refuses the handshake.
enum Incompatibility {
  /// Another protocol version, or a `hello` without the fingerprint fields
  /// (a build from before KLD-085).
  protocol('incompatible-protocol'),

  /// The game's rules version differs ([GameSpec.rulesVersion]).
  rules('incompatible-rules'),

  /// The game's data differs (Quartett deck: cards, stats, values), or one
  /// side does not know the game or deck at all.
  content('incompatible-content');

  /// The wire code.
  final String code;
  const Incompatibility(this.code);

  static Incompatibility? fromCode(Object? code) {
    for (final i in values) {
      if (i.code == code) return i;
    }
    return null;
  }
}

/// How the other side's build compares to this one.
enum PeerAge {
  /// The other side runs an older build: it should update.
  older,

  /// The other side runs a newer build: this side should update.
  newer,

  /// Cannot tell (e.g. two builds with the same version numbers but
  /// different data): both should update.
  unknown,
}

/// Why two builds cannot play together (KLD-085). [peer] says which side
/// is older, from this side's point of view; [peerBuild] is the other
/// side's build label, if it sent one (informational).
///
/// KLD-116: [myBuild], [myName] and [peerName] let the apps say who has
/// which version ("Anna hat 1.0.0 (b8752a9), Ben hat 1.1.0 (c3d4e5f)");
/// filled in by the host and guest where they know them ([withSides]).
class VersionMismatch {
  final Incompatibility kind;
  final PeerAge peer;
  final String? peerBuild;

  /// This side's build label (as in its `hello`), if known.
  final String? myBuild;

  /// This side's player name, if known.
  final String? myName;

  /// The other side's player name, if it sent one before the refusal.
  final String? peerName;

  /// English details for logs and for the other side's error message.
  final String detail;
  const VersionMismatch(this.kind, this.peer, this.detail,
      {this.peerBuild, this.myBuild, this.myName, this.peerName});

  /// A copy with the given sides' build and names (null keeps the current).
  VersionMismatch withSides({String? myBuild, String? myName, String? peerName}) => VersionMismatch(
        kind,
        peer,
        detail,
        peerBuild: peerBuild,
        myBuild: myBuild ?? this.myBuild,
        myName: myName ?? this.myName,
        peerName: peerName ?? this.peerName,
      );

  /// English, one line: what the apps show only as a fallback.
  String get message => 'incompatible versions (${kind.code}): $detail – ${switch (peer) {
        PeerAge.older => 'the other device runs an older build, please update it',
        PeerAge.newer => 'this device runs an older build, please update it',
        PeerAge.unknown => 'please update both',
      }} (browser: reload the page)';

  @override
  String toString() => 'VersionMismatch(${kind.code}, peer ${peer.name}, $detail)';
}

/// Host through a relay (KLD-120): the connection to the relay dropped (a
/// locked phone, lost Wi-Fi) and the host is trying to come back to its
/// room ([reason]: what ended the connection). [RoomReconnected] follows on
/// success; otherwise a [NetError] starting with `relay`: the room is lost.
class RoomReconnecting extends NetEvent {
  final String reason;
  const RoomReconnecting(this.reason);
  @override
  String toString() => 'RoomReconnecting($reason)';
}

/// Host through a relay (KLD-120): back in the room after
/// [RoomReconnecting]; the guest can rejoin.
class RoomReconnected extends NetEvent {
  const RoomReconnected();
  @override
  String toString() => 'RoomReconnected()';
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

  /// Set when the handshake failed because the builds do not fit together
  /// (KLD-085).
  final VersionMismatch? mismatch;
  const NetException(this.message, {this.mismatch});
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
