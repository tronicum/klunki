import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';

import 'awake_clock.dart';
import 'channel/channel.dart';
import 'channel/listener.dart';
import 'channel/platform.dart';
import 'compat.dart';
import 'connection.dart';
import 'events.dart';
import 'names.dart';
import 'reconnect.dart';
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
///
/// A chess game with a clock (KLD-126, `GameConfig.chessClock`): the host
/// keeps the authoritative clock ([clock], [clockUpdates]). It starts when
/// the guest joins, stands still while the guest is away, charges the
/// guest's own measured think time within [clockLagCreditMs] of what the
/// host measured, sends the clock with every `accepted` and `welcome`, and
/// plays the `timeout` move when a flag falls (PROTOCOL.md, "Chess clock").
class KlunkiHost {
  final GameConfig config;
  /// The host's player name, sanitised ([sanitizePlayerName]; the mark of
  /// [me] if empty). Sent as `name` in `hello` and `host` in `welcome`.
  final String name;

  /// The host's player; the guest plays the other one.
  final Player me;

  /// What this build sends and checks in the handshake (KLD-085).
  final BuildCompat compat;
  HostListener _server; // replaced when a direct host binds again (KLD-120)
  StreamSubscription<MessageChannel>? _serverSub;
  StreamSubscription<NetEvent>? _statusSub;
  final Object? _address; // where a direct host listens (for binding again)
  Future<void>? _rebinding;
  bool _closing = false;
  final Duration _pingInterval;
  final Duration _timeout;
  final _events = StreamController<NetEvent>.broadcast();
  final List<MoveAccepted> _log = [];
  Game _game;

  Connection? _guest; // the connection that completed the handshake
  final Set<Connection> _pending = {}; // connected, no hello yet
  final Map<Connection, Timer> _helloDeadlines = {}; // pending ones without hello are dropped
  String? _guestName;
  String? _token; // set once a guest has joined; required to rejoin

  // Hidden-information games only (KLD-064).
  final Redaction? _redaction;
  final List<_GuestRecord> _guestLog = []; // parallel to _log
  String _startViewHash = '';
  final String _seedSalt = newSalt();
  Map<String, dynamic>? _lastGuestView; // the guest's view after the last move

  // Chess with a clock only (KLD-126).
  final ChessClock? _clock;
  final Stopwatch _watch = Stopwatch()..start();
  final List<ChessClockSnapshot?> _clockLog = []; // parallel to _log
  final _clockUpdates = StreamController<ChessClockSnapshot>.broadcast(sync: true);
  Timer? _flagTimer;

  /// How much of the host's measured time a guest's move may leave
  /// uncharged (ms), for the network delay (PROTOCOL.md, "Chess clock").
  /// It is also the guest's grace after its time ran out on the host's
  /// clock, for a move that is on its way.
  int clockLagCreditMs = 1000;

  /// Test hook: the clock's time in ms (default: a monotonic stopwatch).
  int Function()? debugClockNow;

  /// Test hook: rewrites (or drops, by returning null) every message to the
  /// guest before it is sent. Lets tests play a cheating host.
  Map<String, dynamic>? Function(String type, Map<String, dynamic> fields)? debugRewriteOutgoing;

  KlunkiHost._(
      this.config, this.name, this.me, this._server, this._pingInterval, this._timeout, this._game, this.compat,
      [this._address])
      : _redaction = specById(config.gameId)?.redaction,
        _clock = config.gameId == 'chess' && config.chessClock != null ? ChessClock(config.chessClock!) : null {
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
    BuildCompat? compat,
  }) async {
    _validateLog(config, moves);
    final server = await bindHostListener(address: address, port: port, wsPort: wsPort);
    return KlunkiHost._(config, playerNameOr(name, hostPlayer), hostPlayer, server, pingInterval, timeout,
        createGame(config), compat ?? BuildCompat(), address)
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
  ///
  /// KLD-120: a relay connection that merely drops (a locked phone, lost
  /// Wi-Fi) is not the end: the host comes back to its room
  /// ([RoomReconnecting], then [RoomReconnected]) and the guest rejoins
  /// with its token. [resume] does that at once after the app was
  /// suspended. Only a relay that no longer has the room (or an older relay
  /// without host keys) ends it with the [NetError].
  ///
  /// [clubCode]: the club code of a gated relay (KLD-112; sent only to the
  /// relay, never to the guest). A gated relay refuses a missing or wrong
  /// one with `NetException("relay: club code required" / "… not accepted")`.
  static Future<KlunkiHost> startRelay(
    GameConfig config,
    Uri relayUrl, {
    String name = 'Host',
    Player hostPlayer = Player.a,
    List<Map<String, dynamic>> moves = const [],
    Duration pingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 10),
    BuildCompat? compat,
    String? clubCode,
  }) async {
    _validateLog(config, moves);
    final relay = await RelayHostListener.connect(relayUrl, timeout: timeout, clubCode: clubCode);
    return KlunkiHost._(config, playerNameOr(name, hostPlayer), hostPlayer, relay, pingInterval, timeout,
        createGame(config), compat ?? BuildCompat())
      .._listen(moves);
  }

  /// Throws [ArgumentError] (before anything is bound) if [moves] do not
  /// replay for [config], or if [config] is for more than two players (the
  /// session is host + one guest; 3–4 seats are one-device only until the
  /// n-player protocol, KLD-088), or for a game without network play yet
  /// ([GameSpec.networkPlay]: Baulöwe, KLD-060).
  static void _validateLog(GameConfig config, List<Map<String, dynamic>> moves) {
    if (config.players != 2) {
      throw ArgumentError.value(config.players, 'players', 'network play is for 2 players (KLD-088)');
    }
    if (specById(config.gameId)?.networkPlay == false) {
      // Baulöwe (KLD-060): its seed decides dice and cards; not hosted
      // until its redacted n-player network step.
      throw ArgumentError.value(config.gameId, 'gameId', 'not playable over the network yet');
    }
    if (replay(config, [for (final m in moves) jsonDecode(jsonEncode(m)) as Map<String, dynamic>]) == null) {
      throw ArgumentError.value(moves, 'moves', 'do not replay for $config');
    }
  }

  void _listen(List<Map<String, dynamic>> moves) {
    for (final m in moves) {
      final reason = _apply(_game.playerOf(m), m); // a resign may come from either player
      if (reason != null) throw StateError('resumed move does not apply: $reason');
    }
    _listenTo(_server);
    final server = _server;
    if (server is RelayHostListener) _statusSub = server.status.listen(_emit);
  }

  void _listenTo(HostListener server) {
    _serverSub = server.channels.listen(_onChannel, onError: (Object e) {
      // KLD-120: a direct host whose listening socket broke (iOS may take it
      // from a suspended app) listens again on the same ports.
      if (server is! RelayHostListener && identical(server, _server)) {
        unawaited(_rebind());
        return;
      }
      _emit(NetError(e is NetException ? e.message : '$e'));
    });
  }

  /// KLD-120: call when the app comes back from the background ([away]:
  /// how long it was suspended, as far as it knows). A direct host listens
  /// again on the same ports (iOS may have taken the listening socket from
  /// the suspended app; connected guests are not touched). A relay host
  /// that was away for at least [pauseMakesStale] comes back to its
  /// room on a fresh connection at once (the old one may be dead without a
  /// word, and the relay drops it soon anyway); the guest rejoins.
  Future<void> resume({Duration away = Duration.zero}) async {
    if (_closing) return;
    final server = _server;
    if (server is RelayHostListener) {
      if (away >= pauseMakesStale || server.reattaching) server.reattach();
      return;
    }
    await _rebind();
  }

  /// Binds the direct listener again on its ports; retries for a while if
  /// a port is still taken, then reports a [NetError].
  Future<void> _rebind() => _rebinding ??= () async {
        try {
          final old = _server;
          final port = old.port, wsPort = old.wsPort;
          await _serverSub?.cancel();
          await old.close();
          Object? error;
          for (var attempt = 0; attempt < 20 && !_closing; attempt++) {
            if (attempt > 0) await Future<void>.delayed(const Duration(milliseconds: 500));
            if (_closing) return;
            try {
              final server = await bindHostListener(address: _address, port: port, wsPort: wsPort);
              if (_closing) {
                await server.close();
                return;
              }
              _server = server;
              _listenTo(server);
              return;
            } catch (e) {
              error = e;
            }
          }
          if (!_closing) _emit(NetError('cannot listen again on port $port: $error'));
        } finally {
          _rebinding = null;
        }
      }();

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

  /// The authoritative clock of a chess game with a clock (KLD-126), else
  /// null. Read it with [clockNow]; never change it.
  ChessClock? get clock => _clock;

  /// The [clock]'s current time in ms.
  int clockNow() => debugClockNow?.call() ?? _watch.elapsedMilliseconds;

  /// The clock after every change (a move, a pause, the guest away or
  /// back); synchronous.
  Stream<ChessClockSnapshot> get clockUpdates => _clockUpdates.stream;

  /// Says `bye` to the guest and stops listening (a relay host leaves its
  /// room, which the relay then closes).
  Future<void> close({String reason = 'host closed the game'}) async {
    _closing = true;
    _flagTimer?.cancel();
    await _rebinding;
    await _statusSub?.cancel();
    _guest?.close(reason);
    for (final c in _pending.toList()) {
      c.close(reason);
    }
    for (final t in _helloDeadlines.values) {
      t.cancel();
    }
    _helloDeadlines.clear();
    await _server.close();
    await _events.close();
    await _clockUpdates.close();
  }

  void _onChannel(MessageChannel channel) {
    late final Connection conn;
    conn = Connection(
      channel,
      pingInterval: _pingInterval,
      timeout: _timeout,
      onMessage: (m) => _onMessage(conn, m),
      onClosed: (reason, {timedOut = false}) => _onClosed(conn, reason, timedOut),
      build: compat.build,
    );
    _pending.add(conn);
    // A connection that never says hello must not hold a relay room's guest
    // slot (the relay refuses further joins while it is attached).
    _helloDeadlines[conn] = awakeTimer(_timeout, () {
      _helloDeadlines.remove(conn);
      if (_pending.contains(conn)) conn.fail('no hello within ${_timeout.inMilliseconds} ms');
    });
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
    // KLD-085: the builds must fit together, checked before the seat (an
    // incompatible guest never gets "session full" or the guest's seat).
    // Untrusted input: sanitised like a typed name, the guest's mark as fallback.
    final raw = m['name'];
    final name = playerNameOr(raw is String ? raw : null, guestPlayer);
    final mismatch = _checkCompat(m);
    if (mismatch != null) {
      // KLD-116: names on both sides, so the app can say who has which version.
      final typed = raw is String ? sanitizePlayerName(raw) : '';
      return _refuse(conn, mismatch.withSides(peerName: typed.isEmpty ? null : typed));
    }
    final token = m['token'];
    final reconnect = _token != null;
    // KLD-071: once a guest has joined, its seat is reclaimed only with the
    // session token (never by name: names and marks are public).
    if (reconnect && !(token is String && _sameToken(token, _token!))) {
      return conn.fail('session full');
    }
    _pending.remove(conn);
    _helloDeadlines.remove(conn)?.cancel();
    final old = _guest;
    _guest = conn;
    old?.close('replaced by a new connection');
    _guestName = name;
    _token ??= _newToken();
    // KLD-126: the clock starts when the guest is first here and goes on
    // when it is back.
    final clock = _clock;
    final now = clockNow();
    if (clock != null) {
      clock.setHeld(false, now);
      if (!_game.isOver) clock.start(_game.currentPlayer, now);
    }
    _send(conn, 'hello', {
      'role': 'host',
      'name': this.name,
      'protocol': protocolVersion,
      'build': compat.build,
      'game': compatKey(config),
      if (_fingerprint case final f?) 'fingerprint': f.toJson(),
    });
    final redaction = _redaction;
    if (redaction == null) {
      _send(conn, 'welcome', {
        'config': config.toJson(),
        'you': guestPlayer.name,
        'moves': moves,
        'token': _token,
        'host': this.name,
        if (clock != null) 'clock': clock.snapshot(now).toJson(),
      });
    } else {
      _send(conn, 'welcome', {
        'config': redaction.secretSeed ? config.publicJson() : config.toJson(),
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
    _clockChanged();
  }

  /// This build's fingerprint of the hosted game.
  GameFingerprint? get _fingerprint => compat.of(config);

  /// Compares the guest's `hello` with this build (KLD-085); null if they
  /// fit. A `hello` without the fields is from a build before KLD-085.
  VersionMismatch? _checkCompat(Map<String, dynamic> m) {
    final build = m['build'] is String ? m['build'] as String : null;
    final protocol = m['protocol'];
    if (protocol != protocolVersion) {
      return protocolMismatch(protocol is int ? protocol : null, peerBuild: build, myBuild: compat.build);
    }
    final games = m['games'];
    if (games is! Map<String, dynamic>) {
      return VersionMismatch(Incompatibility.protocol, compareBuilds(compat.build, build), 'hello without "games"',
          peerBuild: build);
    }
    final key = compatKey(config);
    return compareFingerprints(key, _fingerprint, GameFingerprint.tryParse(games[key]),
        peerBuild: build, myBuild: compat.build);
  }

  /// Refuses a guest whose build does not fit: `error` with the mismatch's
  /// `code` and this side's fingerprint, then [IncompatiblePeer].
  void _refuse(Connection conn, VersionMismatch mismatch) {
    _pending.remove(conn);
    _helloDeadlines.remove(conn)?.cancel();
    conn.fail(mismatch.message,
        mismatchErrorFields(mismatch, compat, key: compatKey(config), fingerprint: _fingerprint, name: name));
    _emit(IncompatiblePeer(mismatch.withSides(myBuild: compat.build, myName: name)));
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
      final think = m['think'];
      // KLD-126: time is up when the host's clock says so, never the guest.
      reason = ChessGame.isTimeout(move)
          ? 'only the host calls time'
          : _apply(guestPlayer, move, think: think is int ? think : null);
    }
    if (reason != null) {
      _send(conn, 'rejected', {'index': index, 'reason': reason});
      _emit(MoveRejected(index, reason));
    }
  }

  /// Validates and applies [move] for [by]; null on success, else the reason.
  /// [think]: the guest's own measure of its turn (KLD-126).
  String? _apply(Player by, Map<String, dynamic> move, {int? think}) {
    if (_game.isOver) return 'game is over';
    // The player to move, or for a resign the player it names (either
    // player may resign at any time, KLD-065).
    if (_game.playerOf(move) != by) return 'not your turn';
    // KLD-126: what the move costs on the clock; a move after the flag
    // fell ends the game on time instead.
    final clock = _clock;
    final now = clock == null ? 0 : clockNow();
    int? charge;
    if (clock != null && ChessGame.isBoardMove(move) && clock.ticking && clock.running == by) {
      final measured = clock.turnElapsed(now);
      charge = by == guestPlayer && think != null && think >= 0
          ? think.clamp(max(0, measured - clockLagCreditMs), measured)
          : measured;
      if (clock.remainingOf(by, now) + measured - charge <= 0) {
        _apply(by, ChessGame.timeoutMove(by));
        return 'time is up';
      }
    }
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
    _clockAfter(entry, result, now, charge);
    final redaction = _redaction;
    if (redaction != null) _recordForGuest(redaction, entry, result);
    final guest = _guest;
    if (guest != null) {
      _send(guest, 'accepted', _fields(entry));
      if (redaction != null && _game.isOver) _sendReveal(guest);
    }
    _emit(entry);
    _clockChanged();
    return null;
  }

  /// KLD-126: runs the clock for an accepted move: a board move switches
  /// it, an agreed pause stops it, the end of the game stops it for good.
  /// Records the clock for the move's `accepted`.
  void _clockAfter(MoveAccepted entry, GameEvent event, int now, int? charge) {
    final clock = _clock;
    if (clock == null) return _clockLog.add(null);
    if (ChessGame.isBoardMove(entry.move)) clock.moveMade(entry.player, now, charge: charge);
    final payload = event.payload;
    if (payload is Map && payload['clockPaused'] is bool) clock.setPaused(payload['clockPaused'] as bool, now);
    if (_game.isOver) clock.stop(now);
    _clockLog.add(clock.snapshot(now));
  }

  /// Tells listeners about the clock and sets the timer for the next flag.
  void _clockChanged() {
    final clock = _clock;
    if (clock == null) return;
    final now = clockNow();
    if (!_clockUpdates.isClosed) _clockUpdates.add(clock.snapshot(now));
    _flagTimer?.cancel();
    final until = clock.untilFlag(now);
    if (until == null || _closing) return;
    final grace = clock.running == guestPlayer ? clockLagCreditMs : 0;
    _flagTimer = Timer(Duration(milliseconds: max(0, until + grace)), _onFlagTimer);
  }

  /// The running player's time is up (the guest's after its grace): the
  /// host plays the `timeout` move for that player.
  void _onFlagTimer() {
    final clock = _clock;
    final running = clock?.running;
    if (clock == null || running == null || _game.isOver || _closing) return;
    final grace = running == guestPlayer ? clockLagCreditMs : 0;
    if (clock.remainingOf(running, clockNow()) + grace > 0) return _clockChanged(); // early
    _apply(running, ChessGame.timeoutMove(running));
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
    final wasPending = _pending.remove(conn);
    _helloDeadlines.remove(conn)?.cancel();
    // KLD-085: a guest of another protocol version (e.g. a cached old PWA),
    // or a guest that refused our build after the handshake.
    final mismatch = conn.versionMismatch
        ? protocolMismatch(conn.peerVersion, myBuild: compat.build)
        : mismatchFromError(conn.peerError, compat);
    if (mismatch != null && (wasPending || conn == _guest)) {
      _emit(IncompatiblePeer(
          mismatch.withSides(myBuild: compat.build, myName: name, peerName: conn == _guest ? _guestName : null)));
    }
    if (conn != _guest) return;
    _guest = null;
    // KLD-126: the clocks stand still while the guest is away.
    _clock?.setHeld(true, clockNow());
    _emit(PeerDisconnected(reason, timedOut: timedOut));
    _clockChanged();
    // KLD-120: through a relay, silence from the guest may as well be our
    // own relay connection gone quiet (the system silenced it while the app
    // was suspended, a NAT forgot it). It has no keepalive of its own, so
    // come back to the room on a fresh one: cheap, and the guest is gone
    // anyway. Otherwise the host could wait forever while the relay, which
    // dropped the quiet connection, tells the guest that the host is away.
    final server = _server;
    if (timedOut && !_closing && server is RelayHostListener) server.reattach();
  }

  void _emit(NetEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  Map<String, dynamic> _fields(MoveAccepted e) {
    if (_redaction == null) {
      final clock = _clockLog[e.index];
      return {'index': e.index, 'player': e.player.name, 'move': e.move, if (clock != null) 'clock': clock.toJson()};
    }
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

  /// Compares two tokens in time independent of where they differ.
  static bool _sameToken(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
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
