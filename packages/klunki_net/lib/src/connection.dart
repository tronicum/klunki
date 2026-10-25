import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'events.dart';

/// One NDJSON connection: framing, validation of the envelope (`type`, `v`),
/// keepalive (`ping`/`pong`), `bye`, `error` and timeout detection.
///
/// Everything else is handed to [onMessage]. A handler that throws
/// [ProtocolException] makes the connection send `error` and close.
/// [onClosed] is called exactly once.
class Connection {
  final Socket _socket;
  final Duration timeout;
  final void Function(Map<String, dynamic> message) onMessage;
  final void Function(String reason, {bool timedOut}) onClosed;

  late final StreamSubscription<String> _sub;
  late final Timer _timer;
  final Stopwatch _sinceLastSeen = Stopwatch()..start();
  bool _closed = false;

  Connection(
    this._socket, {
    required Duration pingInterval,
    required this.timeout,
    required this.onMessage,
    required this.onClosed,
  }) {
    _socket.done.catchError((_) {}); // errors surface through the read side
    _sub = _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine,
            onError: (Object e) => e is FormatException
                ? fail('malformed input (not UTF-8)')
                : _finish('socket error: $e'),
            onDone: () => _finish('connection closed'));
    _timer = Timer.periodic(pingInterval, (_) => _tick());
  }

  bool get isClosed => _closed;

  /// Sends one message; `v` is added automatically.
  void send(String type, [Map<String, dynamic> fields = const {}]) {
    if (_closed) return;
    try {
      _socket.writeln(jsonEncode({'type': type, 'v': protocolVersion, ...fields}));
    } catch (_) {
      _finish('write failed');
    }
  }

  /// Polite close: `bye {reason}`, then close.
  void close(String reason) {
    send('bye', {'reason': reason});
    _finish(reason);
  }

  /// Protocol error: `error {message}`, then close.
  void fail(String message) {
    send('error', {'message': message});
    _finish('protocol error: $message');
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
    if (decoded['v'] != protocolVersion) {
      return fail('unsupported protocol version ${decoded['v']} (expected $protocolVersion)');
    }
    switch (decoded['type']) {
      case 'ping':
        send('pong');
      case 'pong':
        break;
      case 'bye':
        _finish('peer left: ${decoded['reason'] ?? ''}');
      case 'error':
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
    // Flush pending output (e.g. the `error`/`bye` line), then drop the socket.
    _socket.flush().catchError((_) {}).whenComplete(_socket.destroy);
    onClosed(reason, timedOut: timedOut);
  }
}
