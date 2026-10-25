import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:klunki_engine/klunki_engine.dart';

import 'connection.dart';
import 'events.dart';

/// The joining side: runs its own engine but applies only moves the host
/// accepted, in log order.
class KlunkiGuest {
  final Object host;
  final int port;
  final String name;
  final Duration _pingInterval;
  final Duration _timeout;
  final _events = StreamController<NetEvent>.broadcast();
  final List<MoveAccepted> _log = [];
  final Map<int, List<Completer<String?>>> _waiting = {};

  late GameConfig _config;
  late Player _me;
  late Game _game;
  bool _joined = false; // received a welcome at least once
  String? _token;
  String? _hostName;
  Connection? _conn;
  bool _connected = false; // handshake done on the current connection

  KlunkiGuest._(this.host, this.port, this.name, this._token, this._pingInterval, this._timeout);

  /// Connects to [host]:[port] and completes after the `welcome` snapshot was
  /// replayed. Throws [NetException] if the handshake fails.
  static Future<KlunkiGuest> connect(
    Object host,
    int port, {
    String name = 'Guest',
    String? token,
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final guest = KlunkiGuest._(host, port, name, token, pingInterval, timeout);
    await guest._open();
    return guest;
  }

  GameConfig get config => _config;

  /// The guest's player (chosen by the host).
  Player get me => _me;

  /// The local engine. A fresh instance after a reconnect ([Resynced]).
  Game get game => _game;
  List<Map<String, dynamic>> get moves => [for (final a in _log) a.move];
  String? get token => _token;
  String? get hostName => _hostName;
  bool get connected => _connected;

  /// All session events, including [MoveAccepted] for both players' moves.
  Stream<NetEvent> get events => _events.stream;

  /// Only the accepted moves, in log order.
  Stream<MoveAccepted> get accepted => events.where((e) => e is MoveAccepted).cast<MoveAccepted>();

  /// Sends [move] to the host. Completes with null once the host accepted it
  /// (the local game has then applied it), or with the rejection reason.
  Future<String?> submit(Map<String, dynamic> move) {
    final conn = _conn;
    if (conn == null || !_connected) return Future.value('not connected');
    final index = _log.length;
    final c = Completer<String?>();
    _waiting.putIfAbsent(index, () => []).add(c);
    conn.send('move', {'index': index, 'move': move});
    return c.future;
  }

  /// Opens a new connection (after a disconnect) using the token from
  /// `welcome`; the snapshot is replayed and must extend the local log.
  Future<void> reconnect() => _open();

  /// Says `bye` and closes the connection.
  Future<void> close({String reason = 'guest left'}) async {
    _conn?.close(reason);
    await _events.close();
  }

  Future<void> _open() async {
    _conn?.close('reconnecting');
    final Socket socket;
    try {
      socket = await Socket.connect(host, port, timeout: _timeout);
    } on SocketException catch (e) {
      throw NetException('cannot connect: ${e.message}');
    }
    final welcome = Completer<void>();
    welcome.future.ignore(); // errors are rethrown by the await below
    late final Connection conn;
    conn = Connection(
      socket,
      pingInterval: _pingInterval,
      timeout: _timeout,
      onMessage: (m) => _onMessage(conn, m, welcome),
      onClosed: (reason, {timedOut = false}) => _onClosed(conn, reason, timedOut, welcome),
    );
    _conn = conn;
    conn.send('hello', {
      'role': 'guest',
      'name': name,
      'protocol': protocolVersion,
      if (_token != null) 'token': _token,
    });
    try {
      await welcome.future.timeout(_timeout);
    } on TimeoutException {
      conn.fail('no welcome within ${_timeout.inMilliseconds} ms');
      throw const NetException('handshake timed out');
    }
  }

  void _onMessage(Connection conn, Map<String, dynamic> m, Completer<void> welcome) {
    switch (m['type']) {
      case 'hello':
        if (m['role'] != 'host') throw const ProtocolException('expected role "host"');
        if (m['protocol'] != protocolVersion) throw ProtocolException('unsupported protocol ${m['protocol']}');
        _hostName = m['name'] as String?;
      case 'welcome':
        if (welcome.isCompleted) throw const ProtocolException('duplicate welcome');
        final error = _onWelcome(m);
        if (error != null) {
          welcome.completeError(NetException(error));
          _emit(NetError(error));
          conn.fail(error);
          return;
        }
        _connected = true;
        welcome.complete();
      case 'accepted' when _connected:
        _onAccepted(conn, m);
      case 'rejected' when _connected:
        final index = m['index'] as int, reason = m['reason'] as String? ?? 'rejected';
        _complete(index, reason);
        _emit(MoveRejected(index, reason));
      default:
        throw ProtocolException('unexpected message "${m['type']}"');
    }
  }

  /// Applies a snapshot; returns an error message on divergence.
  String? _onWelcome(Map<String, dynamic> m) {
    final config = GameConfig.fromJson(m['config'] as Map<String, dynamic>);
    final me = playerFromName(m['you']);
    final snapshot = [for (final x in m['moves'] as List) x as Map<String, dynamic>];
    _hostName = m['host'] as String? ?? _hostName;
    _token = m['token'] as String? ?? _token;
    if (_joined && (config != _config || me != _me)) return 'reconnected to a different game';
    if (specById(config.gameId) == null) return 'unknown game "${config.gameId}"';
    // The host only ever extends its log, so ours must be a prefix of it.
    if (snapshot.length < _log.length ||
        Iterable.generate(_log.length).any((i) => jsonEncode(snapshot[i]) != jsonEncode(_log[i].move))) {
      return 'diverged: local move log is not a prefix of the snapshot';
    }
    final game = createGame(config);
    final entries = <MoveAccepted>[];
    for (final move in snapshot) {
      final by = game.currentPlayer;
      if (game.applyMove(jsonDecode(jsonEncode(move)) as Map<String, dynamic>) == null) {
        return 'diverged: snapshot does not replay';
      }
      entries.add(MoveAccepted(entries.length, by, move));
    }
    final known = _joined ? _log.length : 0;
    _config = config;
    _me = me;
    _game = game;
    _log
      ..clear()
      ..addAll(entries);
    if (_joined) {
      for (final e in entries.skip(known)) {
        _complete(e.index, e.player == _me ? null : 'not your turn');
        _emit(e);
      }
      _emit(Resynced(entries.length));
    }
    _joined = true;
    return null;
  }

  void _onAccepted(Connection conn, Map<String, dynamic> m) {
    final index = m['index'] as int;
    final player = playerFromName(m['player']);
    final move = m['move'] as Map<String, dynamic>;
    if (index < _log.length) return; // already applied (duplicate)
    if (index > _log.length) throw ProtocolException('gap: got move $index, have ${_log.length}');
    if (player != _game.currentPlayer || _game.applyMove(jsonDecode(jsonEncode(move)) as Map<String, dynamic>) == null) {
      const error = 'diverged: accepted move does not apply locally';
      conn.fail(error);
      _emit(const NetError(error));
      return;
    }
    final entry = MoveAccepted(index, player, move);
    _log.add(entry);
    if (player == _me) _complete(index, null);
    _emit(entry);
  }

  void _complete(int index, String? reason) {
    for (final c in _waiting.remove(index) ?? const <Completer<String?>>[]) {
      c.complete(reason);
    }
  }

  void _onClosed(Connection conn, String reason, bool timedOut, Completer<void> welcome) {
    if (!welcome.isCompleted) welcome.completeError(NetException(reason));
    if (conn != _conn) return;
    final wasConnected = _connected;
    _connected = false;
    for (final list in _waiting.values) {
      for (final c in list) {
        c.complete('disconnected');
      }
    }
    _waiting.clear();
    if (wasConnected) _emit(PeerDisconnected(reason, timedOut: timedOut));
  }

  void _emit(NetEvent e) {
    if (!_events.isClosed) _events.add(e);
  }
}
