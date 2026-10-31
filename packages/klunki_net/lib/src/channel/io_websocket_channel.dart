import 'dart:async';
import 'dart:io';

import 'channel.dart';

/// One message per text frame over a `dart:io` [WebSocket]: the host's side
/// of a browser guest, or a VM / terminal guest (`klunki join ws://…`).
///
/// The channel keeps reading until the WebSocket is closed, also after the
/// reader of [messages] cancelled: cancelling a dart:io WebSocket's
/// subscription shuts down the socket's read side, the peer's next frames
/// stay unread, and the close then resets the connection (RST) instead of
/// finishing it, so a peer could lose our last message (`bye`, `error`).
class IoWebSocketChannel implements MessageChannel {
  final WebSocket _ws;
  final Zone _zone = Zone.current;
  // Synchronous, like the stream it forwards: a message must be handled
  // before dart:io parses what follows it in the same read (a close frame
  // would make the answer to a ping fail with "not open").
  final _incoming = StreamController<String>(sync: true);
  Future<void>? _closed;

  IoWebSocketChannel(this._ws) {
    _ws.done.catchError((_) {});
    _ws.listen(
      (frame) {
        if (_closed != null) return; // closing: drain
        frame is String ? _incoming.add(frame) : _incoming.addError(const MalformedInput('binary frame'));
      },
      onError: (Object e) {
        if (_closed == null) _incoming.addError(e);
      },
      onDone: () {
        if (!_incoming.isClosed) _incoming.close();
      },
    );
  }

  @override
  late final Stream<String> messages = _incoming.stream;

  @override
  String get kind => 'ws';

  @override
  void send(String message) {
    if (_ws.readyState != WebSocket.open) throw StateError('WebSocket is not open');
    _ws.add(message);
  }

  /// Sends the queued frames, then the close frame; gives up waiting after
  /// a moment. dart:io keeps reading until the peer's close frame (or its
  /// own 5 s close timeout). Runs in the zone that created the channel, like
  /// the WebSocket's own callbacks and timers, whoever calls it.
  @override
  Future<void> close() => _closed ??= _zone.run<Future<void>>(() async {
        if (!_incoming.isClosed) unawaited(_incoming.close());
        try {
          await _ws.close(WebSocketStatus.normalClosure).timeout(const Duration(seconds: 2));
        } catch (_) {
          // already closed, or the peer vanished
        }
      });
}
