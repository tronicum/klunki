import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'channel.dart';

/// NDJSON over a TCP [Socket]: one message per line.
class SocketChannel implements MessageChannel {
  final Socket _socket;
  @override
  late final Stream<String> messages;

  SocketChannel(this._socket) {
    _socket.done.catchError((_) {}); // errors surface through the read side
    messages = _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .handleError((Object e) => throw e is FormatException ? const MalformedInput('not UTF-8') : e);
  }

  @override
  String get kind => 'tcp';

  @override
  void send(String message) => _socket.writeln(message);

  /// Flushes pending output (e.g. the `error`/`bye` line), then drops the
  /// socket.
  @override
  Future<void> close() => _socket.flush().catchError((_) {}).whenComplete(_socket.destroy);
}
