import 'dart:async';
import 'dart:convert';

import 'channel/channel.dart';
import 'events.dart';

/// One protocol connection over a [MessageChannel] (TCP NDJSON or
/// WebSocket): validation of the envelope (`type`, `v`), keepalive
/// (`ping`/`pong`), `bye`, `error` and timeout detection. Pure Dart, so it
/// runs on the VM and in the browser.
///
/// Everything else is handed to [onMessage]. A handler that throws
/// [ProtocolException] makes the connection send `error` and close.
/// [onClosed] is called exactly once.
class Connection {
  final MessageChannel channel;
  final Duration timeout;
  final void Function(Map<String, dynamic> message) onMessage;
  final void Function(String reason, {bool timedOut}) onClosed;

  /// This side's build label, sent with a protocol version error (KLD-085).
  final String build;

  /// The `error` message the other side sent before it closed, if any (its
  /// `code` tells a version mismatch, KLD-085).
  Map<String, dynamic>? peerError;

  /// Set when the other side's envelope `v` was not [protocolVersion]: its
  /// version (null if not an int). The connection is then closed (KLD-085).
  int? peerVersion;
  bool _versionMismatch = false;

  /// Whether the connection ended because the protocol versions differ.
  bool get versionMismatch => _versionMismatch;

  late final StreamSubscription<String> _sub;
  late final Timer _timer;
  final Stopwatch _sinceLastSeen = Stopwatch()..start();
  bool _closed = false;

  Connection(
    this.channel, {
    required Duration pingInterval,
    required this.timeout,
    required this.onMessage,
    required this.onClosed,
    this.build = '',
  }) {
    _sub = channel.messages.listen(_onLine,
        onError: (Object e) => switch (e) {
              MalformedInput(:final what) => fail('malformed input ($what)'),
              NetException(:final message) => _finish(message), // e.g. a relay saying the room is gone
              _ => _finish('socket error: $e'),
            },
        onDone: () => _finish('connection closed'));
    _timer = Timer.periodic(pingInterval, (_) => _tick());
  }

  bool get isClosed => _closed;

  /// Sends one message; `v` is added automatically.
  void send(String type, [Map<String, dynamic> fields = const {}]) {
    if (_closed) return;
    try {
      channel.send(jsonEncode({'type': type, 'v': protocolVersion, ...fields}));
    } catch (_) {
      _finish('write failed');
    }
  }

  /// Polite close: `bye {reason}`, then close.
  void close(String reason) {
    send('bye', {'reason': reason});
    _finish(reason);
  }

  /// Protocol error: `error {message}` (plus [fields], e.g. the `code` of a
  /// version mismatch), then close.
  void fail(String message, [Map<String, dynamic> fields = const {}]) {
    send('error', {...fields, 'message': message});
    _finish('protocol error: $message');
  }

  /// The other side speaks protocol [v] (KLD-085): answer with an `error`
  /// in *its* envelope version, so that an older build reads it as an error
  /// message (and shows it) instead of failing on the envelope, then close.
  void _failVersion(Object? v) {
    _versionMismatch = true;
    peerVersion = v is int ? v : null;
    final theirs = peerVersion;
    final message = theirs == null || theirs < protocolVersion
        ? 'incompatible versions: the other device runs a newer Klunki (protocol $protocolVersion, '
            'this one ${theirs ?? '?'}) – please update this app (browser: reload the page)'
        : 'incompatible versions: the other device runs an older Klunki (protocol $protocolVersion, '
            'this one $theirs) – please update the other device (browser: reload the page)';
    if (!_closed) {
      try {
        channel.send(jsonEncode({
          'type': 'error',
          'v': theirs ?? protocolVersion,
          'message': message,
          'code': 'incompatible-protocol',
          'protocol': protocolVersion,
          'build': build,
        }));
      } catch (_) {}
    }
    _finish('protocol error: unsupported protocol version $v (expected $protocolVersion)');
  }

  void _tick() {
    if (_sinceLastSeen.elapsed > timeout) {
      _finish('timeout: no message for ${timeout.inMilliseconds} ms', timedOut: true);
    } else {
      send('ping');
    }
  }

  void _onLine(String line) {
    if (_closed || line.trim().isEmpty) return;
    _sinceLastSeen.reset();
    Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      return fail('malformed input (not JSON)');
    }
    if (decoded is! Map<String, dynamic> || decoded['type'] is! String) {
      return fail('malformed input (expected an object with "type")');
    }
    final v = decoded['v'];
    if (v != protocolVersion) {
      // KLD-085: an older or newer build. Its own `error` (e.g. an old host
      // refusing our version) is read, not answered.
      if (decoded['type'] == 'error') {
        _versionMismatch = true;
        peerVersion = v is int ? v : null;
        peerError = decoded;
        return _finish('peer error: ${decoded['message'] ?? ''}');
      }
      return _failVersion(v);
    }
    switch (decoded['type']) {
      case 'ping':
        send('pong');
      case 'pong':
        break;
      case 'bye':
        _finish('peer left: ${decoded['reason'] ?? ''}');
      case 'error':
        peerError = decoded;
        _finish('peer error: ${decoded['message'] ?? ''}');
      default:
        try {
          onMessage(decoded);
        } on ProtocolException catch (e) {
          fail(e.message);
        } on TypeError catch (e) {
          fail('bad message fields: $e');
        }
    }
  }

  void _finish(String reason, {bool timedOut = false}) {
    if (_closed) return;
    _closed = true;
    _timer.cancel();
    _sub.cancel();
    // Flush pending output (e.g. the `error`/`bye` message), then close.
    channel.close();
    onClosed(reason, timedOut: timedOut);
  }
}
