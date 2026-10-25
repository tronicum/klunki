import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';

import 'connection.dart';
import 'events.dart';

/// The authoritative side of a session: owns the engine and the move log,
/// listens for one guest and validates every move.
class KlunkiHost {
  final GameConfig config;
  final String name;

  /// The host's player; the guest plays the other one.
  final Player me;
  final ServerSocket _server;
  final Duration _pingInterval;
  final Duration _timeout;
  final _events = StreamController<NetEvent>.broadcast();
  final List<MoveAccepted> _log = [];
  Game _game;

  Connection? _guest; // the connection that completed the handshake
  final Set<Connection> _pending = {}; // connected, no hello yet
  String? _guestName;
  String? _token; // set once a guest has joined; required to rejoin

  KlunkiHost._(this.config, this.name, this.me, this._server, this._pingInterval, this._timeout, this._game);

  /// Binds a TCP server ([port] 0 = ephemeral, read [port] afterwards).
  /// [moves] resumes a game from an earlier move log (must replay cleanly).
  static Future<KlunkiHost> start(
    GameConfig config, {
    int port = 0,
    String name = 'Host',
    Player hostPlayer = Player.a,
    Object? address,
    List<Map<String, dynamic>> moves = const [],
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final game = createGame(config);
    final log = <MoveAccepted>[];
    for (final m in moves) {
      final by = game.currentPlayer;
      if (game.applyMove(m) == null) throw ArgumentError.value(moves, 'moves', 'do not replay for $config');
      log.add(MoveAccepted(log.length, by, m));
    }
    final server = await ServerSocket.bind(address ?? InternetAddress.anyIPv4, port);
    final host = KlunkiHost._(config, name, hostPlayer, server, pingInterval, timeout, game);
    host._log.addAll(log);
    server.listen(host._onSocket);
    return host;
  }

  int get port => _server.port;
  Player get guestPlayer => otherPlayer(me);
  Game get game => _game;

  /// The accepted move log (what `welcome` sends as the snapshot).
  List<Map<String, dynamic>> get moves => [for (final a in _log) a.move];
  bool get guestConnected => _guest != null;
  String? get guestName => _guestName;

  /// All session events, including [MoveAccepted] for both players' moves.
  Stream<NetEvent> get events => _events.stream;

  /// Only the accepted moves, in log order.
  Stream<MoveAccepted> get accepted => events.where((e) => e is MoveAccepted).cast<MoveAccepted>();

  /// Plays [move] for the host. Returns null when accepted (and sent to the
  /// guest), otherwise the rejection reason; the state is then unchanged.
  String? submitLocal(Map<String, dynamic> move) => _apply(me, move);

  /// Says `bye` to the guest and stops listening.
  Future<void> close({String reason = 'host closed the game'}) async {
    _guest?.close(reason);
    for (final c in _pending.toList()) {
      c.close(reason);
    }
    await _server.close();
    await _events.close();
  }

  void _onSocket(Socket socket) {
    late final Connection conn;
    conn = Connection(
      socket,
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
    final name = m['name'] as String? ?? 'Guest';
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
    conn.send('hello', {'role': 'host', 'name': this.name, 'protocol': protocolVersion});
    conn.send('welcome', {
      'config': config.toJson(),
      'you': guestPlayer.name,
      'moves': moves,
      'token': _token,
      'host': this.name,
    });
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
        conn.send('accepted', _fields(entry)); // a resend: confirm again
        return;
      }
      reason = 'stale index $index (log has ${_log.length} moves)';
    } else if (index > _log.length) {
      reason = 'index ahead: $index (log has ${_log.length} moves)';
    } else {
      reason = _apply(guestPlayer, move);
    }
    if (reason != null) {
      conn.send('rejected', {'index': index, 'reason': reason});
      _emit(MoveRejected(index, reason));
    }
  }

  /// Validates and applies [move] for [by]; null on success, else the reason.
  String? _apply(Player by, Map<String, dynamic> move) {
    if (_game.isOver) return 'game is over';
    if (_game.currentPlayer != by) return 'not your turn';
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
    final entry = MoveAccepted(_log.length, by, jsonDecode(encoded) as Map<String, dynamic>);
    _log.add(entry);
    _guest?.send('accepted', _fields(entry));
    _emit(entry);
    return null;
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

  static Map<String, dynamic> _fields(MoveAccepted e) =>
      {'index': e.index, 'player': e.player.name, 'move': e.move};

  static String _newToken() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
