import 'dart:async';
import 'dart:io';

import 'channel.dart';

/// One message per text frame over a `dart:io` [WebSocket]: the host's side
/// of a browser guest, or a VM / terminal guest (`klunki join ws://…`).
class IoWebSocketChannel implements MessageChannel {
  final WebSocket _ws;
  @override
  late final Stream<String> messages;

  IoWebSocketChannel(this._ws) {
    _ws.done.catchError((_) {});
    messages = _ws.map((frame) => frame is String ? frame : throw const MalformedInput('binary frame'));
  }

  @override
  String get kind => 'ws';

  @override
  void send(String message) {
    if (_ws.readyState != WebSocket.open) throw StateError('WebSocket is not open');
    _ws.add(message);
  }

  /// Sends the queued frames, then the close frame; gives up waiting for the
  /// peer's close frame after a moment.
  @override
  Future<void> close() async {
    try {
      await _ws.close(WebSocketStatus.normalClosure).timeout(const Duration(seconds: 2));
    } catch (_) {
      // already closed, or the peer vanished
    }
  }
}
