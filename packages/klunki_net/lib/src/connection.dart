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
    // Flush pending output (e.g. the `error`/`bye` message), then close.
    channel.close();
    onClosed(reason, timedOut: timedOut);
  }
}
