import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';

import 'game_transport.dart';

/// Connection state of a [NetworkTransport], for the pairing / reconnect UI.
enum NetConnectionState {
  /// Host: listening, no guest has joined yet.
  connecting,

  /// Both sides are connected (handshake done).
  connected,

  /// The other side went away (bye, socket closed, timeout). The host keeps
  /// listening; the guest can call [NetworkTransport.reconnect].
  peerMissing,

  /// Guest: a [NetworkTransport.reconnect] is in progress.
  reconnecting,

  /// The transport was disposed.
  closed,
}

/// Which end of the session this device is.
enum NetRole { host, guest }

/// A [GameTransport] for two devices on one network, on top of `klunki_net`.
/// One local player per device: [localPlayers] is `{me}`, so a
/// `GameController` never raises `needsHandover` and `canAct` is true only on
/// the device whose player is to move.
///
/// - [game] is the net session's engine ([KlunkiHost.game] /
///   [KlunkiGuest.game]); after a guest reconnect ([Resynced]) it is the new
///   replayed instance.
/// - [moves] / [accepted] mirror the session's accepted log with the
///   protocol indexes and each move's [GameEvent] as the net layer reports
///   it (the host's engine, or the guest's).
/// - Hidden-information games (KLD-064): on the guest, [game] is a read-only
///   view (e.g. `SchiffeView`) with only what this player may know, and the
///   moves and events of the opponent are redacted ([fullInformation] is
///   false). When the game is over the guest checks the host's reveal
///   ([verification]).
/// - [accepted] is a synchronous broadcast stream; for an accepted [submit]
///   the listeners have seen the move before the future completes.
///
/// Restart is not supported over the network (the host owns the session);
/// a `GameController` for this transport should not call `restart`.
class NetworkTransport implements GameTransport {
  final NetRole role;
  final KlunkiHost? _host;
  final KlunkiGuest? _guest;

  final List<AcceptedMove> _moves = [];
  final StreamController<AcceptedMove> _accepted = StreamController<AcceptedMove>.broadcast(sync: true);
  final ValueNotifier<NetConnectionState> _state;
  final StreamController<NetConnectionState> _stateChanges = StreamController<NetConnectionState>.broadcast();
  late final StreamSubscription<NetEvent> _netSub;
  String? _peerName;
  String? _lastDisconnectReason;
  bool _disposed = false;
  Future<void>? _closing;

  NetworkTransport._host(KlunkiHost host)
      : role = NetRole.host,
        _host = host,
        _guest = null,
        _state = ValueNotifier(host.guestConnected ? NetConnectionState.connected : NetConnectionState.connecting),
        _peerName = host.guestName {
    _init(host.events);
  }

  NetworkTransport._guest(KlunkiGuest guest)
      : role = NetRole.guest,
        _host = null,
        _guest = guest,
        _state = ValueNotifier(guest.connected ? NetConnectionState.connected : NetConnectionState.peerMissing),
        _peerName = guest.hostName {
    _init(guest.events);
  }

  /// Starts hosting [config] on [port] (0 = ephemeral; read [port]). The host
  /// plays A, the guest B. [address] defaults to all IPv4 interfaces.
  /// Browser guests join over WebSocket on [wsPort] (0 = ephemeral, read
  /// [wsPort]; null = TCP only). Throws a `SocketException` if a port is taken.
  static Future<NetworkTransport> host(
    GameConfig config, {
    String name = 'Host',
    int port = 0,
    int? wsPort = 0,
    Object? address,
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final host = await KlunkiHost.start(config,
        port: port, wsPort: wsPort, name: name, address: address, pingInterval: pingInterval, timeout: timeout);
    return NetworkTransport._host(host);
  }

  /// Joins the host at [host]:[port]. [token] rejoins an earlier session
  /// (see [token]). Throws [NetException] if the handshake fails.
  static Future<NetworkTransport> join(
    Object host,
    int port, {
    String name = 'Guest',
    String? token,
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final guest = await KlunkiGuest.connect(host, port,
        name: name, token: token, pingInterval: pingInterval, timeout: timeout);
    return NetworkTransport._guest(guest);
  }

  /// Joins the host over WebSocket at [url] (`ws://host:wsPort`, e.g.
  /// `JoinPayload.webSocketUri`). This is how the browser (PWA) joins; it
  /// also works natively. Throws [NetException] if the handshake fails.
  static Future<NetworkTransport> joinWebSocket(
    Uri url, {
    String name = 'Guest',
    String? token,
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final guest = await KlunkiGuest.connectWebSocket(url,
        name: name, token: token, pingInterval: pingInterval, timeout: timeout);
    return NetworkTransport._guest(guest);
  }

  /// Hosts [config] through the relay at [relayUrl] (`ws://host:port/relay`,
  /// KLD-057): completes once the relay assigned a room code ([roomCode]).
  /// The host plays A. Web-safe (this is how a browser hosts). Throws
  /// [NetException] if the relay cannot be reached or refuses.
  static Future<NetworkTransport> hostRelay(
    GameConfig config,
    Uri relayUrl, {
    String name = 'Host',
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final host =
        await KlunkiHost.startRelay(config, relayUrl, name: name, pingInterval: pingInterval, timeout: timeout);
    return NetworkTransport._host(host);
  }

  /// Joins room [code] on the relay at [relayUrl] (KLD-057). Throws
  /// [ArgumentError] for a malformed code and [NetException] if the relay
  /// refuses (`relay: no room with code …`, `… is full`) or the handshake fails.
  static Future<NetworkTransport> joinRelay(
    Uri relayUrl,
    String code, {
    String name = 'Guest',
    String? token,
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final guest = await KlunkiGuest.connectRelay(relayUrl, code,
        name: name, token: token, pingInterval: pingInterval, timeout: timeout);
    return NetworkTransport._guest(guest);
  }

  void _init(Stream<NetEvent> events) {
    _netSub = events.listen(_onNetEvent);
    _catchUp(); // the snapshot (guest) or a resumed log (host)
  }

  // ---- GameTransport ------------------------------------------------------

  @override
  GameConfig get config => _host?.config ?? _guest!.config;

  /// This device's player.
  Player get me => _host?.me ?? _guest!.me;

  @override
  Set<Player> get localPlayers => {me};

  @override
  Game get game => _host?.game ?? _guest!.game;

  @override
  bool get fullInformation => !(_guest?.redacted ?? false);

  @override
  List<AcceptedMove> get moves => List.unmodifiable(_moves);

  @override
  Stream<AcceptedMove> get accepted => _accepted.stream;

  @override
  Future<SubmitResult> submit(Map<String, dynamic> move) async {
    if (_disposed) return const SubmitResult.rejected(RejectReason.disconnected);
    if (game.isOver) return const SubmitResult.rejected(RejectReason.gameOver);
    if (game.currentPlayer != me) return const SubmitResult.rejected(RejectReason.notYourTurn);
    try {
      jsonEncode(move); // a non-JSON move would break the guest's connection
    } on JsonUnsupportedObjectError {
      return const SubmitResult.rejected(RejectReason.illegal);
    }

    final host = _host;
    final String? reason;
    final int index;
    if (host != null) {
      index = host.moves.length;
      reason = host.submitLocal(move);
    } else {
      final guest = _guest!;
      index = guest.moves.length;
      reason = await guest.submit(move);
    }
    if (reason != null) return SubmitResult.rejected(mapReason(reason));
    if (_disposed) return const SubmitResult.rejected(RejectReason.disconnected);
    _catchUp();
    if (index >= _moves.length) return const SubmitResult.rejected(RejectReason.disconnected);
    return SubmitResult.accepted(_moves[index]);
  }

  /// Maps a `klunki_net` rejection reason to a [RejectReason].
  @visibleForTesting
  static RejectReason mapReason(String reason) {
    if (reason == 'not your turn' || reason.startsWith('stale index') || reason.startsWith('index ahead')) {
      // A stale/ahead index means the log moved under us: not our turn there.
      return RejectReason.notYourTurn;
    }
    if (reason == 'game is over') return RejectReason.gameOver;
    if (reason == 'not connected' || reason == 'disconnected') return RejectReason.disconnected;
    return RejectReason.illegal; // 'illegal move', 'move is not JSON', anything else
  }

  /// Says `bye` and closes the session (fire and forget; await [close] to
  /// wait for it). Afterwards [submit] rejects with [RejectReason.disconnected].
  @override
  void dispose() {
    close();
  }

  /// Like [dispose], but completes once the session is closed.
  Future<void> close() {
    final closing = _closing;
    if (closing != null) return closing;
    _disposed = true;
    _netSub.cancel();
    _setState(NetConnectionState.closed);
    _accepted.close();
    _stateChanges.close();
    return _closing = (_host != null ? _host.close() : _guest!.close()).catchError((Object _) {});
  }

  // ---- Network specifics --------------------------------------------------

  /// Current connection state.
  ValueListenable<NetConnectionState> get connection => _state;

  /// Connection state changes (the current value is in [connection]).
  Stream<NetConnectionState> get connectionChanges => _stateChanges.stream;

  /// The other side's player name (guest name on the host, host name on the
  /// guest), cleaned by `klunki_net` (the peer's mark if it sent none); null
  /// until a guest joined.
  String? get peerName => _peerName;

  /// This device's player name as sent to the other side (KLD-056), cleaned;
  /// the own mark if it is empty.
  String get localName {
    final n = _host?.name ?? _guest!.name;
    return n.isEmpty ? (me == Player.a ? 'X' : 'O') : n;
  }

  /// The relay room's code (host or guest through a relay), else null.
  String? get roomCode => _host != null ? _host.roomCode : _guest!.roomCode;

  /// The relay endpoint (host or guest through a relay), else null.
  Uri? get relayUrl => _host != null ? _host.relayUrl : _guest!.relayUrl;

  /// Host through a relay: why the room was lost (relay restart, idle
  /// expiry, network loss; a `relay: …` message), else null. The session
  /// cannot continue in that room.
  String? get roomLost => _roomLost.value;
  final ValueNotifier<String?> _roomLost = ValueNotifier(null);

  /// Guest of a hidden-information game: the end-of-game check of the
  /// host's reveal (KLD-064). [Verification.notNeeded] on the host and for
  /// games without hidden information.
  ValueListenable<Verification> get verification => _verification;
  late final ValueNotifier<Verification> _verification =
      ValueNotifier(_guest?.verification ?? Verification.notNeeded);

  /// The host's reveal did not confirm the game ([verification] failed).
  bool get verificationFailed => _verification.value == Verification.failed;

  /// Fires on every [connection] change, when the room is lost
  /// ([roomLost]) and when [verification] changes; for UI that shows them.
  late final Listenable changes = Listenable.merge([_state, _roomLost, _verification]);

  /// Reason of the most recent disconnect, if any.
  String? get lastDisconnectReason => _lastDisconnectReason;

  /// Host: the listening TCP port.
  int? get port => _host?.port;

  /// Host: the WebSocket port for browser guests (advertise it as `w=` in the
  /// join payload and `ws` in the TXT record), or null if disabled.
  int? get wsPort => _host?.wsPort;

  /// Guest: the rejoin token from the host (pass it to [join] to rejoin from
  /// a fresh transport).
  String? get token => _guest?.token;

  /// Guest only: reconnects after a disconnect. The snapshot is replayed by
  /// the net layer; [game] becomes the new instance and the moves missed
  /// while away are emitted on [accepted], in order, exactly once.
  /// Throws [NetException] if the handshake fails (state goes back to
  /// [NetConnectionState.peerMissing]).
  Future<void> reconnect() async {
    final guest = _guest;
    if (guest == null) throw StateError('only a guest can reconnect');
    if (_disposed) throw StateError('transport is disposed');
    _setState(NetConnectionState.reconnecting);
    try {
      await guest.reconnect();
    } catch (_) {
      if (!_disposed) _setState(NetConnectionState.peerMissing);
      rethrow;
    }
    if (_disposed) return;
    _peerName = guest.hostName ?? _peerName;
    _catchUp();
    _setState(guest.connected ? NetConnectionState.connected : NetConnectionState.peerMissing);
  }

  void _onNetEvent(NetEvent e) {
    if (_disposed) return;
    switch (e) {
      case PeerConnected(:final name):
        _peerName = name;
        _setState(NetConnectionState.connected);
      case PeerDisconnected(:final reason):
        _lastDisconnectReason = reason;
        // A disconnect of the old connection during reconnect() is expected.
        if (_state.value != NetConnectionState.reconnecting) _setState(NetConnectionState.peerMissing);
      case MoveAccepted():
      case Resynced():
        _catchUp();
      case NetError(:final message) when role == NetRole.host && message.startsWith('relay'):
        _lastDisconnectReason = message;
        _roomLost.value = message;
        _setState(NetConnectionState.peerMissing);
      case GameVerified() || VerificationFailed():
        _verification.value = _guest?.verification ?? Verification.notNeeded;
      case MoveRejected():
      case NetError():
        break;
    }
  }

  /// Brings [_moves] up to the session's log: every net entry with an index
  /// we have not emitted yet is appended and emitted, with its event.
  /// Reading the log instead of the event payloads makes this idempotent and
  /// immune to events emitted before we subscribed.
  void _catchUp() {
    if (_disposed) return;
    final log = _host?.entries ?? _guest!.entries;
    while (_moves.length < log.length) {
      final index = _moves.length;
      final net = log[index];
      final event = net.event;
      if (event == null) throw StateError('accepted move #$index of $config has no event');
      final move = Map<String, dynamic>.unmodifiable(net.move);
      final entry = AcceptedMove(index: index, player: net.player, move: move, event: event);
      _moves.add(entry);
      _accepted.add(entry);
    }
  }

  void _setState(NetConnectionState s) {
    if (_state.value == s) return;
    _state.value = s;
    if (!_stateChanges.isClosed) _stateChanges.add(s);
  }
}
