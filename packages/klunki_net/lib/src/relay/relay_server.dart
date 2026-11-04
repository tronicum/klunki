import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'club_codes.dart';
import 'relay_protocol.dart';

/// The Klunki relay (`klunki relay`): rooms with short codes that join one
/// host and one guest, plus optional static serving of the built PWA. Runs
/// no game logic; see PROTOCOL.md, "Relay".
///
/// - `GET /relay?create` (WebSocket): opens a room; the host gets
///   `relay.room {code}`, later `relay.peer` when a guest joined and
///   `relay.left` when that guest's connection ended (the room stays open,
///   so the guest can rejoin with the same code).
/// - `GET /relay?join=CODE` (WebSocket): joins the room; unknown code or a
///   guest already present: `relay.error`, then close.
/// - Between `relay.peer` and the end, every text frame is forwarded
///   unchanged to the other side. Relay control lines from the guest are
///   refused (`relay.error`, close), so a guest cannot impersonate the relay.
/// - The host leaving (or the room expiring) closes the room: the guest gets
///   `relay.closed`, then the connection is closed. Leaving means a clean
///   close (WebSocket close code 1000, or none). A host connection that
///   drops otherwise (a locked phone, lost Wi-Fi, no answer to the relay's
///   ping; KLD-120) only makes the host *away*: the guest's connection is
///   closed (no message), joins get `relay.error {error: "host-away"}`, and
///   for [hostGrace] the host can come back with `?resume=CODE&key=KEY`
///   (the key came with `relay.room`). Then it gets `relay.room` again and
///   the guest can rejoin. A host that does not come back in time closes
///   the room (`host left`).
/// - Anything else on `/relay` without a WebSocket upgrade: `426`. With
///   [webRoot], other paths serve files from it (GET/HEAD only).
/// - With [clubCodes] (KLD-112, `--codes FILE`) the relay is gated: every
///   WebSocket must carry a current club code (`&club=CODE`), checked before
///   anything else, so a refused client learns nothing about rooms.
class RelayServer {
  final HttpServer _http;

  /// Directory the PWA is served from, or null (then only `/relay`).
  final Directory? webRoot;
  final String? _webRootPath; // resolved, without trailing separator

  /// A room with no forwarded frame for this long is closed.
  final Duration idleTimeout;

  /// Longest accepted frame, in UTF-16 code units (≈ bytes for JSON).
  final int maxLineLength;

  /// Most rooms open at once; further `create`s get `relay.error`.
  final int maxRooms;

  /// How long a room waits for a host whose connection dropped (KLD-120);
  /// zero closes the room at once, like before.
  final Duration hostGrace;

  /// The club codes of a gated relay (KLD-112), or null: an open relay.
  final ClubCodes? clubCodes;
  final ClubStrikes _strikes;

  /// One line per room event (opened, guest in/out, host away/back, closed
  /// with its reason), e.g. the relay terminal; null: quiet. Room codes and
  /// WebSocket close codes only, no addresses.
  final void Function(String line)? log;

  final Duration? _pingInterval;
  final Random _random;
  final Map<String, _Room> _rooms = {};
  late final Timer _sweeper;
  bool _closed = false;

  RelayServer._(this._http, this.webRoot, this._webRootPath, this.idleTimeout, this.maxLineLength, this.maxRooms,
      this._pingInterval, this._random, this.clubCodes, this._strikes, this.hostGrace, this.log) {
    var shortest = idleTimeout;
    if (hostGrace > Duration.zero && hostGrace < shortest) shortest = hostGrace;
    final period = Duration(microseconds: (shortest.inMicroseconds ~/ 4).clamp(10000, 30000000));
    _sweeper = Timer.periodic(period, (_) => _sweep());
    _http.listen(_onRequest);
  }

  /// Binds the relay on [port] (0 = ephemeral, read [port] afterwards) at
  /// [address] (default: all interfaces, IPv6 and IPv4 dual-stack, so a
  /// `<name>.local` that resolves to an IPv6 address works as well as the
  /// IPv4 LAN address; IPv4 only where the system has no IPv6).
  ///
  /// [webRoot]: serve this directory (a built PWA) on every path but
  /// `/relay`. [pingInterval]: WebSocket-level pings that detect vanished
  /// peers (null = off). [random] picks room codes (tests pass a seeded one).
  /// [clubCodes]: require a club code (KLD-112); [clubStrikes] limits wrong
  /// codes per address (default: 10 per 10 minutes). [hostGrace]: how long
  /// a room waits for its host after the host's connection dropped (KLD-120).
  /// [log]: see [RelayServer.log].
  static Future<RelayServer> start({
    int port = defaultRelayPort,
    Object? address,
    Directory? webRoot,
    Duration idleTimeout = const Duration(minutes: 10),
    int maxLineLength = 256 * 1024,
    int maxRooms = 500,
    Duration? pingInterval = const Duration(seconds: 20),
    Random? random,
    ClubCodes? clubCodes,
    ClubStrikes? clubStrikes,
    Duration hostGrace = const Duration(minutes: 5),
    void Function(String line)? log,
  }) async {
    String? rootPath;
    if (webRoot != null) {
      if (!webRoot.existsSync()) throw ArgumentError.value(webRoot.path, 'webRoot', 'no such directory');
      rootPath = webRoot.absolute.resolveSymbolicLinksSync();
      if (rootPath.length > 1 && rootPath.endsWith(Platform.pathSeparator)) {
        rootPath = rootPath.substring(0, rootPath.length - 1);
      }
    }
    final http = await _bind(address, port);
    http.autoCompress = false;
    return RelayServer._(http, webRoot, rootPath, idleTimeout, maxLineLength, maxRooms, pingInterval,
        random ?? Random.secure(), clubCodes, clubStrikes ?? ClubStrikes(), hostGrace, log);
  }

  int get port => _http.port;

  /// Number of open rooms (for tests and logs).
  int get roomCount => _rooms.length;

  /// Closes every room (`relay.closed "relay shutting down"`) and stops.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _sweeper.cancel();
    for (final room in _rooms.values.toList()) {
      room.shutDown('relay shutting down');
    }
    await _http.close(force: true);
  }

  // ------------------------------------------------------------------ HTTP

  Future<void> _onRequest(HttpRequest request) async {
    final path = request.uri.path;
    if (path == relayPath || path == '$relayPath/') return _onRelayRequest(request);
    if (_webRootPath != null) return _serveStatic(request);
    _plain(request, HttpStatus.notFound, 'Klunki relay: connect a WebSocket to $relayPath.\n');
  }

  Future<void> _onRelayRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.headers.set(HttpHeaders.upgradeHeader, 'websocket');
      return _plain(request, HttpStatus.upgradeRequired,
          'Klunki relay: connect a WebSocket (?create to host, ?join=CODE to join).\n');
    }
    final WebSocket ws;
    try {
      ws = await WebSocketTransformer.upgrade(request);
    } catch (_) {
      return; // a broken upgrade request: dart:io already answered it
    }
    ws.pingInterval = _pingInterval;
    final query = request.uri.queryParameters;
    if (_closed) return _refuse(ws, 'relay shutting down');
    if (clubCodes != null) {
      if (!await _clubAdmits(ws, request, query[relayClubParam])) return;
      if (_closed) return _refuse(ws, 'relay shutting down');
    }
    if (query.containsKey('create')) return _create(ws);
    final join = query['join'];
    if (join != null) return _join(ws, join);
    final resume = query[relayResumeParam];
    if (resume != null) return _resume(ws, resume, query[relayKeyParam] ?? '');
    _refuse(ws, 'bad request: use ?create or ?join=CODE');
  }

  void _create(WebSocket ws) {
    if (_rooms.length >= maxRooms) return _refuse(ws, 'too many rooms, try again later');
    String code;
    do {
      code = newRoomCode(_random);
    } while (_rooms.containsKey(code));
    final room = _rooms[code] = _Room(this, code, _newKey());
    room.attachHost(ws);
  }

  String _newKey() => List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

  void _join(WebSocket ws, String raw) {
    final code = normalizeRoomCode(raw);
    final room = code == null ? null : _rooms[code];
    if (room == null) return _refuse(ws, 'no room with code ${code ?? raw.trim().toUpperCase()}');
    if (room.host == null) {
      return _refuse(ws, 'the host of room $code is away, try again in a moment', error: relayErrorHostAway);
    }
    if (room.guest != null) return _refuse(ws, 'room $code is full');
    room.attachGuest(ws);
  }

  /// KLD-120: a host comes back to its room. A wrong key gets the same
  /// answer as an unknown code.
  void _resume(WebSocket ws, String raw, String key) {
    final code = normalizeRoomCode(raw);
    final room = code == null ? null : _rooms[code];
    if (room == null || !_sameKey(key, room.key)) {
      return _refuse(ws, 'no room with code ${code ?? raw.trim().toUpperCase()}');
    }
    room.attachHost(ws);
  }

  static bool _sameKey(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  void _refuse(WebSocket ws, String message, {String? error}) {
    ws.done.catchError((_) {});
    _send(ws, relayControl(relayError, {if (error != null) relayErrorField: error, 'message': message}));
    _close(ws, WebSocketStatus.policyViolation);
  }

  /// KLD-112: whether [raw] is a current club code; refuses [ws] if not.
  /// Missing, unknown, revoked and rate-limited codes are refused the same
  /// way for create and join, before any room is looked at.
  Future<bool> _clubAdmits(WebSocket ws, HttpRequest request, String? raw) async {
    if (raw == null || raw.trim().isEmpty) {
      _refuse(ws, relayClubMissingText, error: relayErrorClubMissing);
      return false;
    }
    final address = request.connectionInfo?.remoteAddress.address ?? '?';
    if (_strikes.blocked(address)) {
      _refuse(ws, 'too many wrong club codes, try again later', error: relayErrorClubWrong);
      return false;
    }
    if (await clubCodes!.check(raw) == null) {
      _strikes.strike(address);
      _refuse(ws, relayClubWrongText, error: relayErrorClubWrong);
      return false;
    }
    return true;
  }

  void _sweep() {
    _strikes.prune();
    for (final room in _rooms.values.toList()) {
      if (room.idle.elapsed > idleTimeout) {
        room.shutDown('room expired (idle)');
      } else if ((room.away?.elapsed ?? Duration.zero) > hostGrace) {
        room._log('the host did not come back within ${hostGrace.inSeconds} s');
        room.shutDown('host left');
      }
    }
  }

  // ---------------------------------------------------------------- static

  Future<void> _serveStatic(HttpRequest request) async {
    final response = request.response;
    if (request.method != 'GET' && request.method != 'HEAD') {
      response.headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
      return _plain(request, HttpStatus.methodNotAllowed, 'Method not allowed.\n');
    }
    final file = await _resolve(request.uri);
    if (file == null) return _plain(request, HttpStatus.notFound, 'Not found.\n');
    final name = file.path.split(Platform.pathSeparator).last;
    response.headers
      ..contentType = ContentType.parse(mimeTypeFor(name))
      ..set('X-Content-Type-Options', 'nosniff')
      // index.html, the service worker and the manifest must be revalidated
      // so a new build is picked up; everything else may be cached briefly.
      ..set(HttpHeaders.cacheControlHeader, _revalidate(name) ? 'no-cache' : 'max-age=300');
    try {
      final length = await file.length();
      response.contentLength = length;
      if (request.method == 'HEAD') {
        await response.close();
      } else {
        await response.addStream(file.openRead());
        await response.close();
      }
    } catch (_) {
      try {
        await response.close();
      } catch (_) {}
    }
  }

  static bool _revalidate(String name) =>
      name.endsWith('.html') || name == 'flutter_service_worker.js' || name == 'sw.js' || name.endsWith('.webmanifest') ||
      name == 'manifest.json' || name == 'version.json';

  /// The file for [uri] inside [webRoot], or null. `/` and directories map
  /// to their `index.html`. Path segments `.`/`..`, encoded separators and
  /// symbolic links leading outside the root are refused.
  Future<File?> _resolve(Uri uri) async {
    final root = _webRootPath!;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    for (final s in segments) {
      if (s == '.' || s == '..' || s.contains('/') || s.contains('\\') || s.contains('\u0000')) return null;
    }
    var path = [root, ...segments].join(Platform.pathSeparator);
    if (await FileSystemEntity.isDirectory(path)) path = '$path${Platform.pathSeparator}index.html';
    final file = File(path);
    if (!await file.exists()) return null;
    final String resolved;
    try {
      resolved = await file.resolveSymbolicLinks();
    } on FileSystemException {
      return null;
    }
    if (!resolved.startsWith('$root${Platform.pathSeparator}')) return null;
    return File(resolved);
  }

  static void _plain(HttpRequest request, int status, String body) {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.text
      ..write(body);
    request.response.close().catchError((_) {});
  }

  // ----------------------------------------------------------- forwarding

  static void _send(WebSocket ws, String line) {
    try {
      if (ws.readyState == WebSocket.open) ws.add(line);
    } catch (_) {}
  }

  static void _close(WebSocket ws, [int code = WebSocketStatus.normalClosure]) {
    ws.close(code).timeout(const Duration(seconds: 2), onTimeout: () => null).catchError((_) => null);
  }
}

class _Room {
  final RelayServer server;
  final String code;

  /// The secret that lets the host come back (KLD-120), sent with `relay.room`.
  final String key;

  /// The host's connection; null while the host is away (KLD-120).
  WebSocket? host;
  WebSocket? guest;
  final Stopwatch idle = Stopwatch()..start();

  /// Running while the host is away.
  Stopwatch? away;
  bool _closed = false;

  _Room(this.server, this.code, this.key);

  void _log(String event) => server.log?.call('Room $code: $event');

  /// The host's connection: a new room, or the host coming back (KLD-120).
  /// A connection the host still had is replaced, and a guest is dropped:
  /// its session was with the host's old connection; it rejoins.
  void attachHost(WebSocket ws) {
    final old = host;
    final wasAway = away?.elapsed;
    if (wasAway != null) {
      _log('host back after ${wasAway.inSeconds} s');
    } else if (old != null) {
      _log('host back (its old connection is replaced)');
    } else {
      _log('opened');
    }
    host = ws;
    away = null;
    idle.reset();
    if (old != null) {
      RelayServer._send(old, relayControl(relayClosed, {'reason': 'replaced by a new host connection'}));
      RelayServer._close(old, WebSocketStatus.goingAway);
    }
    _dropGuest();
    ws.done.catchError((_) {});
    RelayServer._send(ws, relayControl(relayRoom, {'code': code, 'key': key}));
    ws.listen((frame) => _fromHost(ws, frame),
        onDone: () => _hostGone(ws), onError: (_) => _hostGone(ws, failed: true));
  }

  void attachGuest(WebSocket ws) {
    guest = ws;
    _log('guest joined');
    ws.done.catchError((_) {});
    idle.reset();
    RelayServer._send(host!, relayControl(relayPeer));
    ws.listen((frame) => _fromGuest(ws, frame),
        onDone: () => _guestGone(ws, 'guest disconnected'), onError: (_) => _guestGone(ws, 'guest connection failed'));
  }

  /// The host's connection [ws] ended. A clean close (code 1000, or none)
  /// is the host leaving; anything else (no close frame, no answer to the
  /// relay's ping, "going away") makes it away for [RelayServer.hostGrace].
  void _hostGone(WebSocket ws, {bool failed = false}) {
    if (_closed || !identical(ws, host)) return;
    final code = ws.closeCode;
    final left = !failed && (code == WebSocketStatus.normalClosure || code == WebSocketStatus.noStatusReceived);
    final how = failed ? 'connection error' : 'close code $code';
    if (left || server.hostGrace <= Duration.zero) {
      _log(left ? 'host left ($how)' : 'host connection ended ($how), no grace period');
      return shutDown(failed ? 'host connection failed' : 'host left');
    }
    _log('host away ($how), the room waits ${server.hostGrace.inSeconds} s for it');
    host = null;
    away = Stopwatch()..start();
    _dropGuest();
  }

  /// Checks one frame; returns the line to forward, or null after refusing.
  String? _check(WebSocket from, Object? frame) {
    if (frame is! String) {
      _violation(from, 'binary frames are not relayed');
      return null;
    }
    if (frame.length > server.maxLineLength) {
      _violation(from, 'line too long (max ${server.maxLineLength} characters)');
      return null;
    }
    return frame;
  }

  void _fromHost(WebSocket ws, Object? frame) {
    if (_closed || !identical(ws, host)) return;
    final line = _check(ws, frame);
    if (line == null) return;
    idle.reset();
    final control = parseRelayControl(line);
    if (control != null) {
      if (control['t'] == relayKick) _dropGuest();
      return; // other control lines from the host are ignored
    }
    final g = guest;
    if (g != null) RelayServer._send(g, line);
  }

  void _fromGuest(WebSocket ws, Object? frame) {
    if (_closed || !identical(ws, guest)) return;
    final line = _check(ws, frame);
    if (line == null) return;
    if (parseRelayControl(line) != null) return _violation(ws, 'relay control messages are not allowed from a guest');
    idle.reset();
    final h = host;
    if (h != null) RelayServer._send(h, line);
  }

  /// A rule broken by [ws]: `relay.error`, then close. The host breaking a
  /// rule closes the room; a guest only loses its own connection.
  void _violation(WebSocket ws, String message) {
    RelayServer._send(ws, relayControl(relayError, {'message': message}));
    if (identical(ws, host)) {
      shutDown('host broke the relay rules');
    } else {
      _guestGone(ws, message);
      RelayServer._close(ws, WebSocketStatus.policyViolation);
    }
  }

  /// Drops the guest without `relay.left`: the host asked for it
  /// (`relay.kick`), or the host's connection changed (KLD-120).
  void _dropGuest() {
    final g = guest;
    if (g == null) return;
    guest = null;
    RelayServer._close(g);
  }

  void _guestGone(WebSocket ws, String reason) {
    if (_closed || !identical(ws, guest)) return;
    guest = null;
    _log('guest gone ($reason, close code ${ws.closeCode})');
    final h = host;
    if (h != null) RelayServer._send(h, relayControl(relayLeft, {'reason': reason}));
  }

  /// Closes the room: the guest and (if still there) the host get
  /// `relay.closed {reason}`, then both connections are closed.
  void shutDown(String reason) {
    if (_closed) return;
    _closed = true;
    _log('closed: $reason');
    server._rooms.remove(code);
    for (final ws in [host, guest]) {
      if (ws == null) continue;
      RelayServer._send(ws, relayControl(relayClosed, {'reason': reason}));
      RelayServer._close(ws, WebSocketStatus.goingAway);
    }
    host = null;
    guest = null;
  }
}

/// The Content-Type for a file name (by extension), for serving a Flutter
/// web build: `.wasm`, `.mjs`, `.webmanifest` included. Unknown extensions
/// are `application/octet-stream`.
String mimeTypeFor(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final ext = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  return switch (ext) {
    'html' || 'htm' => 'text/html; charset=utf-8',
    'js' || 'mjs' => 'text/javascript; charset=utf-8',
    'json' || 'map' => 'application/json; charset=utf-8',
    'webmanifest' => 'application/manifest+json; charset=utf-8',
    'wasm' => 'application/wasm',
    'css' => 'text/css; charset=utf-8',
    'txt' => 'text/plain; charset=utf-8',
    'svg' => 'image/svg+xml',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'ico' => 'image/x-icon',
    'ttf' => 'font/ttf',
    'otf' => 'font/otf',
    'woff' => 'font/woff',
    'woff2' => 'font/woff2',
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'xml' => 'application/xml',
    _ => 'application/octet-stream',
  };
}

/// Binds [address], or by default every interface dual-stack (IPv6 `::`
/// with `v6Only: false`, which accepts IPv4 too); IPv4 `0.0.0.0` where
/// IPv6 is not available.
Future<HttpServer> _bind(Object? address, int port) async {
  if (address != null) return HttpServer.bind(address, port);
  try {
    return await HttpServer.bind(InternetAddress.anyIPv6, port, v6Only: false);
  } on SocketException {
    return HttpServer.bind(InternetAddress.anyIPv4, port);
  }
}
