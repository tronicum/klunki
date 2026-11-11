import 'dart:async';
import 'dart:convert';

import 'package:klunki_engine/klunki_engine.dart';

import 'awake_clock.dart';
import 'channel/channel.dart';
import 'channel/platform.dart' as platform;
import 'compat.dart';
import 'connection.dart';
import 'events.dart';
import 'names.dart';
import 'relay/relay_client.dart';
import 'relay/relay_protocol.dart';
import 'secrecy/secrecy.dart';

/// The joining side: runs its own engine but applies only moves the host
/// accepted, in log order.
///
/// Hidden-information games (KLD-064, [redacted]): the guest runs no engine.
/// It holds only its own view ([game] is a read-only view object such as a
/// `SchiffeView`), redacted moves and events, and the host's commitments.
/// When the game is over the host reveals its secrets and the guest replays
/// the whole game to check it ([verification], [GameVerified] /
/// [VerificationFailed]).
///
/// Two transports, same protocol: [connect] (TCP, NDJSON; needs `dart:io`)
/// and [connectWebSocket] (`ws://`, one message per text frame; works on the
/// VM and in the browser). This file does not import `dart:io`.
class KlunkiGuest {
  /// The host's address (for WebSocket: [webSocketUrl]'s host).
  final Object host;

  /// The host's TCP port, or its WebSocket port for a WebSocket guest.
  final int port;

  /// Set for a WebSocket guest: the `ws://` URL it (re)connects to. For a
  /// relay guest: the relay endpoint ([relayUrl]).
  final Uri? webSocketUrl;

  /// Set for a relay guest ([connectRelay]): the room it (re)joins.
  final String? roomCode;

  /// The club code a relay guest sends to a gated relay (KLD-112).
  final String? _clubCode;

  /// This guest's player name, sanitised ([sanitizePlayerName]; may be
  /// empty, the host then shows the guest's mark).
  final String name;

  /// What this build sends and checks in the handshake (KLD-085).
  final BuildCompat compat;
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
  Map<String, dynamic>? _hostHello; // the host's hello on the current connection (KLD-085)

  // Hidden-information games only (KLD-064).
  bool _redacted = false;
  final List<RedactedStep> _steps = []; // parallel to _log
  String _startViewHash = '';
  String? _seedCommit;
  final Map<int, Map<String, dynamic>> _sent = {}; // own moves by index, to check the echo
  Verification _verification = Verification.notNeeded;
  String? _verificationError;

  KlunkiGuest._(this.host, this.port, this.webSocketUrl, String name, this._token, this._pingInterval, this._timeout,
      {this.roomCode, BuildCompat? compat, String? clubCode})
      : _clubCode = clubCode,
        name = sanitizePlayerName(name),
        compat = compat ?? BuildCompat();

  /// Connects over TCP to [host]:[port] and completes after the `welcome`
  /// snapshot was replayed. Throws [NetException] if the handshake fails
  /// (and always in a browser: use [connectWebSocket] there).
  static Future<KlunkiGuest> connect(
    Object host,
    int port, {
    String name = 'Guest',
    String? token,
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
    BuildCompat? compat,
  }) async {
    final guest = KlunkiGuest._(host, port, null, name, token, pingInterval, timeout, compat: compat);
    await guest._open();
    return guest;
  }

  /// Connects over WebSocket to [url] (`ws://host:port`, e.g. from
  /// [webSocketUri]) and completes after the `welcome` snapshot was
  /// replayed. Works on the VM and in the browser (the PWA). Throws
  /// [NetException] if the connection or the handshake fails, and
  /// [ArgumentError] for a URL that is not `ws://` / `wss://`.
  static Future<KlunkiGuest> connectWebSocket(
    Uri url, {
    String name = 'Guest',
    String? token,
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
    BuildCompat? compat,
  }) async {
    if ((url.scheme != 'ws' && url.scheme != 'wss') || url.host.isEmpty) {
      throw ArgumentError.value(url, 'url', 'expected ws://host:port');
    }
    final guest = KlunkiGuest._(url.host, url.port, url, name, token, pingInterval, timeout, compat: compat);
    await guest._open();
    return guest;
  }

  /// Joins room [code] on the relay at [relayUrl] (`ws://host:port/relay`,
  /// see `parseRelayUrl` / `relayUriForPage`) and completes after the
  /// host's `welcome` snapshot was replayed; from then on it is the same
  /// session as [connectWebSocket] (events, [submit], [reconnect] into the
  /// same room while it is open). [code] is normalised
  /// (`normalizeRoomCode`: case and dashes do not matter). Works on the VM
  /// and in the browser.
  ///
  /// Throws [ArgumentError] for a malformed [code] or a [relayUrl] that is
  /// not `ws://` / `wss://`, and [NetException] if the relay is unreachable
  /// or refuses (message `relay: no room with code …` / `relay: room …
  /// is full`) or the handshake fails.
  static Future<KlunkiGuest> connectRelay(
    Uri relayUrl,
    String code, {
    String name = 'Guest',
    String? token,
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
    BuildCompat? compat,
    String? clubCode,
  }) async {
    if ((relayUrl.scheme != 'ws' && relayUrl.scheme != 'wss') || relayUrl.host.isEmpty) {
      throw ArgumentError.value(relayUrl, 'relayUrl', 'expected ws://host:port/relay');
    }
    final room = normalizeRoomCode(code);
    if (room == null) throw ArgumentError.value(code, 'code', 'not a room code');
    final guest = KlunkiGuest._(relayUrl.host, relayUrl.port, relayUrl, name, token, pingInterval, timeout,
        roomCode: room, compat: compat, clubCode: clubCode);
    await guest._open();
    return guest;
  }

  /// `tcp`, `ws` or `relay`.
  String get transport => roomCode != null ? 'relay' : (webSocketUrl == null ? 'tcp' : 'ws');

  /// The relay endpoint of a relay guest, otherwise null.
  Uri? get relayUrl => roomCode != null ? webSocketUrl : null;

  /// Where this guest connects: `host:port`, the `ws://` URL, or
  /// `room CODE on ws://…/relay`.
  String get address => roomCode != null
      ? 'room $roomCode on $webSocketUrl'
      : webSocketUrl?.toString() ?? '$host:$port';

  GameConfig get config => _config;

  /// The guest's player (chosen by the host).
  Player get me => _me;

  /// The local engine. A fresh instance after a reconnect ([Resynced]).
  /// For a [redacted] game: this player's read-only view, a fresh instance
  /// after every move.
  Game get game => _game;

  /// The accepted moves (redacted for a [redacted] game).
  List<Map<String, dynamic>> get moves => [for (final a in _log) a.move];

  /// The accepted log with each move's event (redacted for a [redacted] game).
  List<MoveAccepted> get entries => List.unmodifiable(_log);

  /// True for a hidden-information game: the host sends only what this
  /// player may see (KLD-064).
  bool get redacted => _redacted;

  /// State of the end-of-game check (always [Verification.notNeeded] for a
  /// game without hidden information).
  Verification get verification => _verification;

  /// Why the check failed (English), when [verification] is
  /// [Verification.failed].
  String? get verificationError => _verificationError;
  String? get token => _token;
  /// The host's name from `hello` / `welcome`, sanitised
  /// ([sanitizePlayerName]; the host's mark if empty or missing).
  String? get hostName => _hostName;
  bool get connected => _connected;

  /// The handshake / keepalive timeout this guest was created with.
  Duration get timeout => _timeout;

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
    if (_redacted) _sent[index] = jsonSafe(move) as Map<String, dynamic>;
    conn.send('move', {'index': index, 'move': move});
    return c.future;
  }

  /// Opens a new connection (after a disconnect) using the token from
  /// `welcome`; the snapshot is replayed and must extend the local log.
  ///
  /// Single-flight: a call while a reconnect is still running joins it
  /// instead of opening a second connection. Two parallel attempts (the
  /// automatic retry loop and a tap on "reconnect", say) would otherwise
  /// race for the one seat, and over the relay the loser is told that the
  /// room is full.
  Future<void> reconnect() => _reconnecting ??= _open().whenComplete(() => _reconnecting = null);
  Future<void>? _reconnecting;

  /// Says `bye` and closes the connection.
  Future<void> close({String reason = 'guest left'}) async {
    _conn?.close(reason);
    await _events.close();
  }

  Future<void> _open() async {
    _conn?.close('reconnecting');
    final url = webSocketUrl;
    final room = roomCode;
    final MessageChannel channel = room != null
        ? await RelayGuestChannel.connect(url!, room, _timeout, clubCode: _clubCode)
        : url != null
            ? await platform.connectWebSocket(url, _timeout)
            : await platform.connectTcp(host, port, _timeout);
    final welcome = Completer<void>();
    welcome.future.ignore(); // errors are rethrown by the await below
    late final Connection conn;
    conn = Connection(
      channel,
      pingInterval: _pingInterval,
      timeout: _timeout,
      onMessage: (m) => _onMessage(conn, m, welcome),
      onClosed: (reason, {timedOut = false}) => _onClosed(conn, reason, timedOut, welcome),
      build: compat.build,
    );
    _conn = conn;
    _hostHello = null;
    conn.send('hello', {
      'role': 'guest',
      'name': name,
      'protocol': protocolVersion,
      if (_token != null) 'token': _token,
      'build': compat.build,
      'games': compat.gamesJson(),
    });
    try {
      await awakeTimeout(welcome.future, _timeout);
    } on TimeoutException {
      conn.fail('no welcome within ${_timeout.inMilliseconds} ms');
      throw const NetException('handshake timed out');
    }
  }

  void _onMessage(Connection conn, Map<String, dynamic> m, Completer<void> welcome) {
    switch (m['type']) {
      case 'hello':
        if (m['role'] != 'host') throw const ProtocolException('expected role "host"');
        if (m['protocol'] != protocolVersion) {
          final build = m['build'] is String ? m['build'] as String : null;
          final protocol = m['protocol'];
          return _incompatible(conn, welcome,
              protocolMismatch(protocol is int ? protocol : null, peerBuild: build, myBuild: compat.build));
        }
        _hostHello = m;
        final name = m['name'];
        if (name is String) _hostName = sanitizePlayerName(name);
      case 'welcome':
        if (welcome.isCompleted) throw const ProtocolException('duplicate welcome');
        final mismatch = _checkCompat(m);
        if (mismatch != null) return _incompatible(conn, welcome, mismatch);
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
        _redacted ? _onRedactedAccepted(conn, m) : _onAccepted(conn, m);
      case 'reveal' when _connected && _redacted:
        _onReveal(m);
      case 'rejected' when _connected:
        final index = m['index'] as int, reason = m['reason'] as String? ?? 'rejected';
        _complete(index, reason);
        _emit(MoveRejected(index, reason));
      default:
        throw ProtocolException('unexpected message "${m['type']}"');
    }
  }

  /// Checks the host's build against ours (KLD-085) once `welcome` names
  /// the game: the host's `hello` must carry the fingerprint of exactly
  /// that game (and deck), equal to ours. A host from before KLD-085 sends
  /// none: that is a mismatch too, never "compatible".
  VersionMismatch? _checkCompat(Map<String, dynamic> welcome) {
    final hello = _hostHello;
    final build = hello?['build'] is String ? hello!['build'] as String : null;
    final rawConfig = welcome['config'];
    final game = rawConfig is Map<String, dynamic> ? rawConfig['game'] : null;
    if (hello == null || hello['fingerprint'] == null || game is! String) {
      return VersionMismatch(Incompatibility.protocol, compareBuilds(compat.build, build),
          hello == null ? 'welcome without hello' : 'the host sent no game fingerprint',
          peerBuild: build);
    }
    final deck = (rawConfig as Map<String, dynamic>)['deck'];
    final config = GameConfig(game, deck: deck is String ? deck : null);
    final key = compatKey(config);
    if (hello['game'] != key) {
      return VersionMismatch(Incompatibility.content, compareBuilds(compat.build, build),
          'the host announced "${hello['game']}" but hosts "$key"',
          peerBuild: build);
    }
    return compareFingerprints(key, compat.of(config), GameFingerprint.tryParse(hello['fingerprint']),
        peerBuild: build, myBuild: compat.build);
  }

  /// The builds do not fit: tell the host (`error` with the `code`) and
  /// fail the handshake with a [NetException] carrying [mismatch].
  void _incompatible(Connection conn, Completer<void> welcome, VersionMismatch mismatch) {
    if (!welcome.isCompleted) {
      // KLD-116: both names, so the app can say who has which version.
      final named = mismatch.withSides(myBuild: compat.build, myName: name, peerName: _hostName);
      welcome.completeError(NetException(mismatch.message, mismatch: named));
    }
    _emit(NetError(mismatch.message));
    conn.fail(mismatch.message, mismatchErrorFields(mismatch, compat, name: name));
  }

  /// Applies a snapshot; returns an error message on divergence.
  String? _onWelcome(Map<String, dynamic> m) {
    final config = GameConfig.fromJson(m['config'] as Map<String, dynamic>);
    final me = playerFromName(m['you']);
    final hostName = m['host'];
    if (hostName is String) _hostName = sanitizePlayerName(hostName);
    _token = m['token'] as String? ?? _token;
    if (_joined && (config != _config || me != _me)) return 'reconnected to a different game';
    // A word tile game's word list may still be loading: the guest creates
    // no engine for it now (it only needs the list to check its own words
    // and, at the end, to replay the game; KLD-094 step 6).
    final problem = configProblem(config, wordList: false);
    if (problem != null) return problem;
    if (config.players != 2) return 'the host started a game for ${config.players} players';
    final spec = specById(config.gameId)!;
    if (!spec.networkPlay) return '"${spec.id}" is not playable over the network yet';
    final redaction = spec.redaction;
    final redacted = m['redacted'] == true;
    if (redacted != (redaction != null)) {
      return redacted ? 'host redacted a game without hidden information' : 'host did not redact a hidden game';
    }
    final (game, entries, error) = redaction == null ? _replaySnapshot(m, config) : _loadRedacted(m, redaction, me);
    if (error != null) return error;
    final known = _joined ? _log.length : 0;
    _config = config;
    _me = me;
    _redacted = redacted;
    if (_verification == Verification.notNeeded && redacted) _verification = Verification.pending;
    if (_hostName == null || _hostName!.isEmpty) _hostName = markOf(otherPlayer(me));
    _game = game!;
    _log
      ..clear()
      ..addAll(entries!);
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

  /// A full snapshot (`moves`): replay it on a fresh engine.
  (Game?, List<MoveAccepted>?, String?) _replaySnapshot(Map<String, dynamic> m, GameConfig config) {
    final snapshot = [for (final x in m['moves'] as List) x as Map<String, dynamic>];
    // The host only ever extends its log, so ours must be a prefix of it.
    if (snapshot.length < _log.length ||
        Iterable<int>.generate(_log.length).any((i) => jsonEncode(snapshot[i]) != jsonEncode(_log[i].move))) {
      return (null, null, 'diverged: local move log is not a prefix of the snapshot');
    }
    final game = createGame(config);
    final entries = <MoveAccepted>[];
    for (final move in snapshot) {
      final by = game.playerOf(move);
      final event = game.applyMove(jsonDecode(jsonEncode(move)) as Map<String, dynamic>);
      if (event == null) return (null, null, 'diverged: snapshot does not replay');
      entries.add(MoveAccepted(entries.length, by, move, event: event));
    }
    return (game, entries, null);
  }

  /// A redacted snapshot (`log`, `view`, `start`, `seedCommit`): check it
  /// against what we already know and load the view.
  (Game?, List<MoveAccepted>?, String?) _loadRedacted(Map<String, dynamic> m, Redaction redaction, Player me) {
    final steps = [for (final x in m['log'] as List) RedactedStep.fromJson(x as Map<String, dynamic>)];
    final start = m['start'];
    final seedCommit = m['seedCommit'];
    final view = m['view'];
    if (start is! String || view is! Map<String, dynamic>) throw const ProtocolException('welcome needs "start" and "view"');
    if (redaction.secretSeed && seedCommit is! String) throw const ProtocolException('welcome needs "seedCommit"');
    if (_joined) {
      if (start != _startViewHash || seedCommit != _seedCommit) return (null, null, 'diverged: the game start changed');
      if (steps.length < _steps.length ||
          Iterable<int>.generate(_steps.length).any((i) =>
              canonicalJson(steps[i].toJson()) != canonicalJson(_steps[i].toJson()))) {
        return (null, null, 'diverged: local move log is not a prefix of the snapshot');
      }
    }
    if (viewHash(view) != (steps.isEmpty ? start : steps.last.viewHash)) {
      return (null, null, 'diverged: the view does not match the log');
    }
    if (view['viewer'] != me.name) return (null, null, 'diverged: the view is not ours');
    final Game game;
    try {
      game = redaction.fromView(view);
    } on BadViewException catch (e) {
      return (null, null, 'bad view: ${e.message}');
    }
    _steps
      ..clear()
      ..addAll(steps);
    _startViewHash = start;
    _seedCommit = seedCommit as String?;
    return (
      game,
      [
        for (var i = 0; i < steps.length; i++)
          MoveAccepted(i, steps[i].player, steps[i].move, event: eventFromJson(steps[i].event)),
      ],
      null
    );
  }

  void _onAccepted(Connection conn, Map<String, dynamic> m) {
    final index = m['index'] as int;
    final player = playerFromName(m['player']);
    final move = m['move'] as Map<String, dynamic>;
    if (index < _log.length) return; // already applied (duplicate)
    if (index > _log.length) throw ProtocolException('gap: got move $index, have ${_log.length}');
    final event = player == _game.playerOf(move)
        ? _game.applyMove(jsonDecode(jsonEncode(move)) as Map<String, dynamic>)
        : null;
    if (event == null) return _diverged(conn, 'diverged: accepted move does not apply locally');
    final entry = MoveAccepted(index, player, move, event: event);
    _log.add(entry);
    if (player == _me) _complete(index, null);
    _emit(entry);
  }

  /// `accepted` of a hidden-information game: a redacted move, its event,
  /// our new view and (for a secret of the host) a commitment.
  void _onRedactedAccepted(Connection conn, Map<String, dynamic> m) {
    final index = m['index'] as int;
    final player = playerFromName(m['player']);
    final move = m['move'] as Map<String, dynamic>;
    final event = m['event'] as Map<String, dynamic>;
    final view = m['view'] as Map<String, dynamic>;
    final commit = m['commit'];
    if (commit != null && commit is! String) throw const ProtocolException('"commit" must be a string');
    if (index < _log.length) return; // already applied (duplicate)
    if (index > _log.length) throw ProtocolException('gap: got move $index, have ${_log.length}');
    if (player != _game.playerOf(move)) return _diverged(conn, 'diverged: move reported for the wrong player');
    if (player == _me) {
      final sent = _sent.remove(index);
      if (commit != null || (sent != null && canonicalJson(sent) != canonicalJson(move))) {
        return _diverged(conn, 'diverged: the host changed our move');
      }
    }
    if (view['viewer'] != _me.name) return _diverged(conn, 'diverged: the view is not ours');
    final Game game;
    try {
      game = specById(_config.gameId)!.redaction!.fromView(view);
    } on BadViewException catch (e) {
      return _diverged(conn, 'bad view: ${e.message}');
    }
    _steps.add(RedactedStep(player, move, event, viewHash(view), commit as String?));
    _game = game;
    final entry = MoveAccepted(index, player, move, event: eventFromJson(event));
    _log.add(entry);
    if (player == _me) _complete(index, null);
    _emit(entry);
  }

  /// `reveal`: the host's secrets after the game. Replays and checks the
  /// whole game ([verifyRedactedGame]).
  void _onReveal(Map<String, dynamic> m) {
    if (!_game.isOver) throw const ProtocolException('reveal before the game is over');
    String? error;
    try {
      final secrets = <int, RevealedMove>{};
      for (final x in m['secrets'] as List) {
        final e = x as Map<String, dynamic>;
        final index = e['index'] as int;
        if (secrets.containsKey(index)) throw FormatException('move $index revealed twice');
        secrets[index] = RevealedMove(e['move'] as Map<String, dynamic>, e['salt'] as String);
      }
      final secretSeed = specById(_config.gameId)!.redaction!.secretSeed;
      error = verifyRedactedGame(
        config: _config,
        gameId: _config.gameId,
        deck: _config.deck,
        pickLowCards: _config.pickLowCards,
        tiles: _config.tiles,
        dictionary: _config.dictionary,
        jokerSwap: _config.jokerSwap,
        lives: _config.lives,
        maexchenDouble: _config.maexchenDouble,
        maexchenUnlimited: _config.maexchenUnlimited,
        me: _me,
        seed: secretSeed ? m['seed'] as int : _config.seed,
        seedSalt: secretSeed ? m['seedSalt'] as String : null,
        seedCommit: _seedCommit,
        startViewHash: _startViewHash,
        steps: _steps,
        secrets: secrets,
      );
    } catch (e) {
      error = 'malformed reveal: $e';
    }
    if (error == null) {
      _verification = Verification.verified;
      _verificationError = null;
      _emit(const GameVerified());
    } else {
      _verification = Verification.failed;
      _verificationError = error;
      _emit(VerificationFailed(error));
    }
  }

  void _diverged(Connection conn, String error) {
    conn.fail(error);
    _emit(NetError(error));
  }

  void _complete(int index, String? reason) {
    for (final c in _waiting.remove(index) ?? const <Completer<String?>>[]) {
      c.complete(reason);
    }
  }

  void _onClosed(Connection conn, String reason, bool timedOut, Completer<void> welcome) {
    if (!welcome.isCompleted) {
      // KLD-085: the host refused our build, or speaks another protocol
      // version (e.g. an old host answering our hello with its own error).
      final mismatch = conn.versionMismatch
          ? protocolMismatch(conn.peerVersion, myBuild: compat.build)
          : mismatchFromError(conn.peerError, compat);
      welcome.completeError(
          NetException(mismatch?.message ?? reason, mismatch: mismatch?.withSides(myBuild: compat.build, myName: name)));
    }
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
