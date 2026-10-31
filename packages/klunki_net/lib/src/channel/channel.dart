import 'dart:async';

/// A bidirectional stream of protocol messages, one JSON object (as text) per
/// message, independent of the wire:
///
/// - TCP: NDJSON, one message per `\n`-terminated line (`SocketChannel`).
/// - WebSocket: one message per text frame (`dart:io` `WebSocket` on the VM
///   and the host, the browser `WebSocket` on the web).
///
/// `Connection` runs the protocol (envelope checks, keepalive, `bye`/`error`,
/// timeout) on top of any channel, so host and guest logic exist once.
abstract class MessageChannel {
  /// Incoming messages; single subscription. Errors: [MalformedInput] for
  /// input that cannot be a message (invalid UTF-8, a binary frame); anything
  /// else is a transport failure. The stream ends when the peer closes.
  Stream<String> get messages;

  /// Queues [message] for sending. May throw if the channel is broken.
  void send(String message);

  /// Flushes queued messages (best effort), then closes the channel.
  /// Never throws.
  Future<void> close();

  /// Short transport name for logs and tests: `tcp` or `ws`.
  String get kind;
}

/// Input on the wire that is not a protocol message at all; the receiver
/// answers with `error "malformed input (<what>)"`.
class MalformedInput implements Exception {
  final String what;
  const MalformedInput(this.what);
  @override
  String toString() => 'MalformedInput: $what';
}
