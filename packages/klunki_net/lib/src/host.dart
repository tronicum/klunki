import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';

import 'channel/channel.dart';
import 'channel/listener.dart';
import 'channel/platform.dart';
import 'connection.dart';
import 'events.dart';
import 'names.dart';
import 'relay/relay_client.dart';
import 'secrecy/secrecy.dart';

/// The authoritative side of a session: owns the engine and the move log,
/// listens for one guest and validates every move.
///
/// Guests connect over TCP (NDJSON, [port]) or WebSocket (one message per
/// text frame, [wsPort]); both run the same protocol through the same code.
/// Listening needs `dart:io` ([start] fails in a browser).
///
/// [startRelay] hosts through a relay instead (see PROTOCOL.md, "Relay"):
/// the host connects out to the relay, gets a [roomCode], and the guest that
/// joins the room is served by the same session code. That works in the
/// browser too.
///
/// Hidden-information games (`GameSpec.redaction`, KLD-064): the host is the
/// referee. The guest gets only redacted moves, events and its own view; the
/// host commits to every secret of its own (its setup, a secret seed) and
/// reveals them with `reveal` once the game is over, so the guest can check
/// the whole game.
class KlunkiHost {
  final GameConfig config;
  /// The host's player name, sanitised ([sanitizePlayerName]; the mark of
  /// [me] if empty). Sent as `name` in `hello` and `host` in `welcome`.
  final String name;

  /// The host's player; the guest plays the other one.
  final Player me;
  final HostListener _server;
  final Duration _pingInterval;
  final Duration _timeout;
  final _events = StreamController<NetEvent>.broadcast();
  final List<MoveAccepted> _log = [];
  Game _game;

  Connection? _guest; // the connection that completed the handshake
  final Set<Connection> _pending = {}; // connected, no hello yet
  String? _guestName;
  String? _token; // set once a guest has joined; required to rejoin

  // Hidden-information games only (KLD-064).
  final Redaction? _redaction;
  final List<_GuestRecord> _guestLog = []; // parallel to _log
  String _startViewHash = '';
  final String _seedSalt = newSalt();
  Map<String, dynamic>? _lastGuestView; // the guest's view after the last move

  /// Test hook: rewrites (or drops, by returning null) every message to the
  /// guest before it is sent. Lets tests play a cheating host.
  Map<String, dynamic>? Function(String type, Map<String, dynamic> fields)? debugRewriteOutgoing;

  KlunkiHost._(this.config, this.name, this.me, this._server, this._pingInterval, this._timeout, this._game)
      : _redaction = specById(config.gameId)?.redaction {
    final redaction = _redaction;
    if (redaction != null) _startViewHash = viewHash(redaction.view(_game, guestPlayer));
  }

  /// Binds a TCP server on [port] and a WebSocket server on [wsPort] (0 =
  /// ephemeral, read [port] / [wsPort] afterwards; [wsPort] null = TCP only).
  /// Throws a `SocketException` if a port is taken (nothing stays bound).
  /// [moves] resumes a game from an earlier move log (must replay cleanly).
  static Future<KlunkiHost> start(
    GameConfig config, {
    int port = 0,
    int? wsPort = 0,
    String name = 'Host',
    Player hostPlayer = Player.a,
    Object? address,
    List<Map<String, dynamic>> moves = const [],
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _validateLog(config, moves);
    final server = await bindHostListener(address: address, port: port, wsPort: wsPort);
    return KlunkiHost._(
        config, playerNameOr(name, hostPlayer), hostPlayer, server, pingInterval, timeout, createGame(config))
      .._listen(moves);
  }

  /// Hosts through the relay at [relayUrl] (`ws://host:port/relay`, e.g. from
  /// `parseRelayUrl` or `relayUriForPage(Uri.base)` in the PWA) instead of
  /// listening: creates a room and completes once the relay assigned its
  /// code ([roomCode]). The guest joins with [KlunkiGuest.connectRelay] and
  /// [code]; from then on it is the same session as on a direct connection
  /// ([PeerConnected] when its `hello` arrives, names, moves, reconnect with
  /// the token while the room is open).
  ///
  /// Web-safe (only an outgoing WebSocket). Throws [NetException] if the
  /// relay cannot be reached or refuses (e.g. too many rooms). If the room
  /// is lost later (relay restart, idle expiry, network loss), [events]
  /// emits a [NetError] starting with `relay` (after [PeerDisconnected] if a
  /// guest was connected); the session cannot continue in that room.
  static Future<KlunkiHost> startRelay(
    GameConfig config,
    Uri relayUrl, {
    String name = 'Host',
    Player hostPlayer = Player.a,
    List<Map<String, dynamic>> moves = const [],
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _validateLog(config, moves);
    final relay = await RelayHostListener.connect(relayUrl, timeout: timeout);
    return KlunkiHost._(
        config, playerNameOr(name, hostPlayer), hostPlayer, relay, pingInterval, timeout, createGame(config))
      .._listen(moves);
  }

  /// Throws [ArgumentError] (before anything is bound) if [moves] do not
  /// replay for [config].
  static void _validateLog(GameConfig config, List<Map<String, dynamic>> moves) {
    if (replay(config, [for (final m in moves) jsonDecode(jsonEncode(m)) as Map<String, dynamic>]) == null) {
      throw ArgumentError.value(moves, 'moves', 'do not replay for $config');
    }
  }

  void _listen(List<Map<String, dynamic>> moves) {
    for (final m in moves) {
      final reason = _apply(_game.playerOf(m), m); // a resign may come from either player
      if (reason != null) throw StateError('resumed move does not apply: $reason');
    }
    _server.channels.listen(_onChannel, onError: (Object e) {
      _emit(NetError(e is NetException ? e.message : '$e'));
    });
  }

  /// The relay room's code when hosting through a relay ([startRelay]),
  /// otherwise null. Shown to the user; the guest types it.
  String? get roomCode => switch (_server) { RelayHostListener(:final code) => code, _ => null };

  /// The relay endpoint when hosting through a relay, otherwise null.
  Uri? get relayUrl => switch (_server) { RelayHostListener(:final relayUrl) => relayUrl, _ => null };

  /// The TCP port (NDJSON guests: apps, the CLI); 0 for a relay host.
  int get port => _server.port;

  /// The WebSocket port (browser guests), or null if not enabled.
  int? get wsPort => _server.wsPort;

  Player get guestPlayer => otherPlayer(me);
  Game get game => _game;

  /// The accepted move log (full moves; for a hidden-information game the
  /// guest gets the redacted log instead).
  List<Map<String, dynamic>> get moves => [for (final a in _log) a.move];

  /// The accepted log with each move's [GameEvent].
  List<MoveAccepted> get entries => List.unmodifiable(_log);
  bool get guestConnected => _guest != null;
  /// The guest's name from its `hello`, sanitised ([sanitizePlayerName];
  /// the guest's mark if empty); null until a guest joined.
  String? get guestName => _guestName;

  /// All session events, including [MoveAccepted] for both players' moves.
  Stream<NetEvent> get events => _events.stream;

  /// Only the accepted moves, in log order.
  Stream<MoveAccepted> get accepted => events.where((e) => e is MoveAccepted).cast<MoveAccepted>();

  /// Plays [move] for the host. Returns null when accepted (and sent to the
  /// guest), otherwise the rejection reason; the state is then unchanged.
  String? submitLocal(Map<String, dynamic> move) => _apply(me, move);

  /// Says `bye` to the guest and stops listening (a relay host leaves its
  /// room, which the relay then closes).
  Future<void> close({String reason = 'host closed the game'}) async {
    _guest?.close(reason);
    for (final c in _pending.toList()) {
      c.close(reason);
    }
    await _server.close();
    await _events.close();
  }

  void _onChannel(MessageChannel channel) {
    late final Connection conn;
    conn = Connection(
      channel,
      pingInterval: _pingInterval,
      timeout: _timeout,
      onMessage: (m) => _onMessage(conn, m),
      onClosed: (reason, {timedOut = false}) => _onClosed(conn, reason, timedOut),
    );
    _pending.add(conn);
  }

  void _onMessage(Connection conn, Map<String, dynamic> m) {
    if (conn != _guest) return _onHello(conn, m);
    switch (m['type']) {
      case 'move':
        return _onGuestMove(conn, m);
      default:
        throw ProtocolException('unexpected message "${m['type']}"');
    }
  }

  void _onHello(Connection conn, Map<String, dynamic> m) {
    if (m['type'] != 'hello') throw const ProtocolException('expected hello');
    if (m['role'] != 'guest') throw const ProtocolException('expected role "guest"');
    if (m['protocol'] != protocolVersion) {
      throw ProtocolException('unsupported protocol ${m['protocol']}');
    }
    // Untrusted input: sanitised like a typed name, the guest's mark as fallback.
    final raw = m['name'];
    final name = playerNameOr(raw is String ? raw : null, guestPlayer);
    final token = m['token'] as String?;
    final reconnect = _token != null;
    if (reconnect && token != _token && name != _guestName) {
      return conn.fail('session full');
    }
    _pending.remove(conn);
    final old = _guest;
    _guest = conn;
    old?.close('replaced by a new connection');
    _guestName = name;
    _token ??= _newToken();
    _send(conn, 'hello', {'role': 'host', 'name': this.name, 'protocol': protocolVersion});
    final redaction = _redaction;
    if (redaction == null) {
      _send(conn, 'welcome', {
        'config': config.toJson(),
        'you': guestPlayer.name,
        'moves': moves,
        'token': _token,
        'host': this.name,
      });
    } else {
      _send(conn, 'welcome', {
        'config': redaction.secretSeed ? {'game': config.gameId} : config.toJson(),
        'you': guestPlayer.name,
        'token': _token,
        'host': this.name,
        'redacted': true,
        if (redaction.secretSeed) 'seedCommit': commitment(_seedSalt, 'seed', config.seed),
        'start': _startViewHash,
        'log': [for (final r in _guestLog) r.step.toJson()],
        'view': redaction.view(_game, guestPlayer),
      });
      if (_game.isOver) _sendReveal(conn);
    }
    _emit(PeerConnected(name, reconnect: reconnect));
  }

  void _onGuestMove(Connection conn, Map<String, dynamic> m) {
    final index = m['index'];
    final move = m['move'];
    if (index is! int || move is! Map<String, dynamic>) {
      throw const ProtocolException('move needs an int "index" and an object "move"');
    }
    String? reason;
    if (index < _log.length) {
      final entry = _log[index];
      if (entry.player == guestPlayer && jsonEncode(entry.move) == jsonEncode(move)) {
        // A resend: confirm again (redacted games keep only the latest view).
        if (_redaction == null || index == _log.length - 1) {
          _send(conn, 'accepted', _fields(entry));
          return;
        }
      }
      reason = 'stale index $index (log has ${_log.length} moves)';
    } else if (index > _log.length) {
      reason = 'index ahead: $index (log has ${_log.length} moves)';
    } else {
      reason = _apply(guestPlayer, move);
    }
    if (reason != null) {
      _send(conn, 'rejected', {'index': index, 'reason': reason});
      _emit(MoveRejected(index, reason));
    }
  }

  /// Validates and applies [move] for [by]; null on success, else the reason.
  String? _apply(Player by, Map<String, dynamic> move) {
    if (_game.isOver) return 'game is over';
    // The player to move, or for a resign the player it names (either
    // player may resign at any time, KLD-065).
    if (_game.playerOf(move) != by) return 'not your turn';
    final String encoded;
    try {
      encoded = jsonEncode(move);
    } on JsonUnsupportedObjectError {
      return 'move is not JSON';
    }
    GameEvent? result;
    try {
      result = _game.applyMove(jsonDecode(encoded) as Map<String, dynamic>);
    } catch (_) {
      result = null; // e.g. a wrongly typed field; rebuild to be safe
      _game = replay(config, moves)!;
    }
    if (result == null) return 'illegal move';
    final entry = MoveAccepted(_log.length, by, jsonDecode(encoded) as Map<String, dynamic>, event: result);
    _log.add(entry);
    final redaction = _redaction;
    if (redaction != null) _recordForGuest(redaction, entry, result);
    final guest = _guest;
    if (guest != null) {
      _send(guest, 'accepted', _fields(entry));
      if (redaction != null && _game.isOver) _sendReveal(guest);
    }
    _emit(entry);
    return null;
  }

  /// The guest's redacted step for [entry]; a move that hides a secret of
  /// the host gets a fresh salt and a commitment.
  void _recordForGuest(Redaction redaction, MoveAccepted entry, GameEvent event) {
    final step = redaction.step(_game, entry.move, entry.player, event, guestPlayer);
    final move = step['move'] as Map<String, dynamic>;
    final view = step['view'] as Map<String, dynamic>;
    final secret = entry.player != guestPlayer && canonicalJson(move) != canonicalJson(entry.move);
    final salt = secret ? newSalt() : null;
    _guestLog.add(_GuestRecord(
        RedactedStep(entry.player, move, step['event'] as Map<String, dynamic>, viewHash(view),
            salt == null ? null : commitment(salt, 'move:${entry.index}', entry.move)),
        salt));
    _lastGuestView = view;
  }

  /// `reveal`: the secret seed and every committed move with its salt, so
  /// the guest can check the finished game.
  void _sendReveal(Connection conn) {
    final redaction = _redaction!;
    _send(conn, 'reveal', {
      if (redaction.secretSeed) ...{'seed': config.seed, 'seedSalt': _seedSalt},
      'secrets': [
        for (var i = 0; i < _guestLog.length; i++)
          if (_guestLog[i].salt != null) {'index': i, 'move': _log[i].move, 'salt': _guestLog[i].salt},
      ],
    });
  }

  /// Test hook: plays a cheating host that swaps its own move at [index]
  /// (e.g. its fleet) for [move] after the fact and rebuilds its engine.
  /// Commitments already sent stay as they were. Returns false (and changes
  /// nothing) if the log no longer replays.
  bool debugReplaceMove(int index, Map<String, dynamic> move) {
    final moves = this.moves..[index] = move;
    final game = replay(config, moves);
    if (game == null) return false;
    _log[index] = MoveAccepted(index, _log[index].player, move, event: _log[index].event);
    _game = game;
    return true;
  }

  void _send(Connection conn, String type, Map<String, dynamic> fields) {
    final hook = debugRewriteOutgoing;
    final out = hook == null ? fields : hook(type, fields);
    if (out != null) conn.send(type, out);
  }

  void _onClosed(Connection conn, String reason, bool timedOut) {
    _pending.remove(conn);
    if (conn != _guest) return;
    _guest = null;
    _emit(PeerDisconnected(reason, timedOut: timedOut));
  }

  void _emit(NetEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  Map<String, dynamic> _fields(MoveAccepted e) {
    if (_redaction == null) return {'index': e.index, 'player': e.player.name, 'move': e.move};
    final step = _guestLog[e.index].step;
    return {
      'index': e.index,
      'player': e.player.name,
      'move': step.move,
      'event': step.event,
      'view': _lastGuestView,
      if (step.commit != null) 'commit': step.commit,
    };
  }

  static String _newToken() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}

/// The guest's side of one log entry of a hidden-information game, plus the
/// salt of its commitment (host only, sent with `reveal`).
class _GuestRecord {
  final RedactedStep step;
  final String? salt;
  const _GuestRecord(this.step, this.salt);
}
