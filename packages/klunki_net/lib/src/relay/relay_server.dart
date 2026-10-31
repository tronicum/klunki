import 'dart:async';
import 'dart:io';
import 'dart:math';

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
///   `relay.closed`, then the connection is closed.
/// - Anything else on `/relay` without a WebSocket upgrade: `426`. With
///   [webRoot], other paths serve files from it (GET/HEAD only).
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

  final Duration? _pingInterval;
  final Random _random;
  final Map<String, _Room> _rooms = {};
  late final Timer _sweeper;
  bool _closed = false;

  RelayServer._(this._http, this.webRoot, this._webRootPath, this.idleTimeout, this.maxLineLength, this.maxRooms,
      this._pingInterval, this._random) {
    final period = Duration(microseconds: (idleTimeout.inMicroseconds ~/ 4).clamp(10000, 30000000));
    _sweeper = Timer.periodic(period, (_) => _sweep());
    _http.listen(_onRequest);
  }

  /// Binds the relay on [port] (0 = ephemeral, read [port] afterwards) at
  /// [address] (default: all IPv4 interfaces).
  ///
  /// [webRoot]: serve this directory (a built PWA) on every path but
  /// `/relay`. [pingInterval]: WebSocket-level pings that detect vanished
  /// peers (null = off). [random] picks room codes (tests pass a seeded one).
  static Future<RelayServer> start({
    int port = defaultRelayPort,
    Object? address,
    Directory? webRoot,
    Duration idleTimeout = const Duration(minutes: 10),
    int maxLineLength = 256 * 1024,
    int maxRooms = 500,
    Duration? pingInterval = const Duration(seconds: 20),
    Random? random,
  }) async {
    String? rootPath;
    if (webRoot != null) {
      if (!webRoot.existsSync()) throw ArgumentError.value(webRoot.path, 'webRoot', 'no such directory');
      rootPath = webRoot.absolute.resolveSymbolicLinksSync();
      if (rootPath.length > 1 && rootPath.endsWith(Platform.pathSeparator)) {
        rootPath = rootPath.substring(0, rootPath.length - 1);
      }
    }
    final http = await HttpServer.bind(address ?? InternetAddress.anyIPv4, port);
    http.autoCompress = false;
    return RelayServer._(http, webRoot, rootPath, idleTimeout, maxLineLength, maxRooms, pingInterval,
        random ?? Random.secure());
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
    if (query.containsKey('create')) return _create(ws);
    final join = query['join'];
    if (join != null) return _join(ws, join);
    _refuse(ws, 'bad request: use ?create or ?join=CODE');
  }

  void _create(WebSocket ws) {
    if (_rooms.length >= maxRooms) return _refuse(ws, 'too many rooms, try again later');
    String code;
    do {
      code = newRoomCode(_random);
    } while (_rooms.containsKey(code));
    final room = _rooms[code] = _Room(this, code, ws);
    room.start();
  }

  void _join(WebSocket ws, String raw) {
    final code = normalizeRoomCode(raw);
    final room = code == null ? null : _rooms[code];
    if (room == null) return _refuse(ws, 'no room with code ${code ?? raw.trim().toUpperCase()}');
    if (room.guest != null) return _refuse(ws, 'room $code is full');
    room.attachGuest(ws);
  }

  void _refuse(WebSocket ws, String message) {
    ws.done.catchError((_) {});
    _send(ws, relayControl(relayError, {'message': message}));
    _close(ws, WebSocketStatus.policyViolation);
  }

  void _sweep() {
    for (final room in _rooms.values.toList()) {
      if (room.idle.elapsed > idleTimeout) room.shutDown('room expired (idle)');
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
  final WebSocket host;
  WebSocket? guest;
  final Stopwatch idle = Stopwatch()..start();
  bool _closed = false;

  _Room(this.server, this.code, this.host);

  void start() {
    host.done.catchError((_) {});
    RelayServer._send(host, relayControl(relayRoom, {'code': code}));
    host.listen(_fromHost, onDone: () => shutDown('host left'), onError: (_) => shutDown('host connection failed'));
  }

  void attachGuest(WebSocket ws) {
    guest = ws;
    ws.done.catchError((_) {});
    idle.reset();
    RelayServer._send(host, relayControl(relayPeer));
    ws.listen((frame) => _fromGuest(ws, frame),
        onDone: () => _guestGone(ws, 'guest disconnected'), onError: (_) => _guestGone(ws, 'guest connection failed'));
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

  void _fromHost(Object? frame) {
    if (_closed) return;
    final line = _check(host, frame);
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
    RelayServer._send(host, line);
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

  /// The host asked to drop the guest (after the lines it already sent).
  void _dropGuest() {
    final g = guest;
    if (g == null) return;
    guest = null; // no `relay.left`: the host already knows
    RelayServer._close(g);
  }

  void _guestGone(WebSocket ws, String reason) {
    if (_closed || !identical(ws, guest)) return;
    guest = null;
    RelayServer._send(host, relayControl(relayLeft, {'reason': reason}));
  }

  /// Closes the room: the guest and (if still there) the host get
  /// `relay.closed {reason}`, then both connections are closed.
  void shutDown(String reason) {
    if (_closed) return;
    _closed = true;
    server._rooms.remove(code);
    for (final ws in [host, guest]) {
      if (ws == null) continue;
      RelayServer._send(ws, relayControl(relayClosed, {'reason': reason}));
      RelayServer._close(ws, WebSocketStatus.goingAway);
    }
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
