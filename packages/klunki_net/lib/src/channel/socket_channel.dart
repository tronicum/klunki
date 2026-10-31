import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'channel.dart';

/// NDJSON over a TCP [Socket]: one message per line.
///
/// Closing is graceful: the queued lines are sent, then FIN, and the input
/// is read (and dropped) until the peer closes too. Closing a socket with
/// unread input makes the kernel reset the connection (RST), and a peer
/// that sees the RST before it has read our last line (`bye`, `error`)
/// loses it. The other side keeps sending pings until it has read that
/// line, so there is nearly always unread input.
class SocketChannel implements MessageChannel {
  /// How long [close] waits for the peer to close its side before it drops
  /// the socket anyway.
  static const lingerTimeout = Duration(seconds: 2);

  final Socket _socket;
  final Zone _zone = Zone.current;
  // Synchronous, like the stream it forwards: each line is handled as it
  // is read.
  final _incoming = StreamController<String>(sync: true);
  final _peerClosed = Completer<void>();
  Future<void>? _closed;

  SocketChannel(this._socket) {
    // Failed writes (e.g. to a peer that reset the connection) complete
    // `done` with an error and are never thrown by write(): handle them
    // here. The read side reports the same failure.
    _socket.done.catchError((_) {});
    // The channel owns the read subscription so it can keep draining after
    // the reader of [messages] cancelled and [close] was called.
    _socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        if (_closed == null) _incoming.add(line);
      },
      onError: (Object e) {
        if (_closed == null) _incoming.addError(e is FormatException ? const MalformedInput('not UTF-8') : e);
      },
      onDone: () {
        if (!_peerClosed.isCompleted) _peerClosed.complete();
        if (!_incoming.isClosed) _incoming.close();
      },
    );
  }

  @override
  late final Stream<String> messages = _incoming.stream;

  @override
  String get kind => 'tcp';

  @override
  void send(String message) => _socket.writeln(message);

  /// Flushes pending output (e.g. the `error`/`bye` line), half-closes and
  /// drains until the peer closes (at most [lingerTimeout]), then drops the
  /// socket. Runs in the zone that created the channel, like the socket's
  /// own callbacks, whoever calls it.
  @override
  Future<void> close() => _closed ??= _zone.run<Future<void>>(() async {
        if (!_incoming.isClosed) unawaited(_incoming.close());
        try {
          await _socket.flush();
          await _socket.close();
        } catch (_) {
          // the peer is gone already
        }
        await _peerClosed.future.timeout(lingerTimeout, onTimeout: () {});
        _socket.destroy();
      });
}
