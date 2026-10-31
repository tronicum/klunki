import 'channel.dart';

/// Where a host accepts guests: a TCP port (NDJSON) and, optionally, a
/// second port for WebSocket guests (browsers). Every accepted connection is
/// handed out as a [MessageChannel], so the host logic does not care which.
abstract class HostListener {
  /// The TCP port (NDJSON guests).
  int get port;

  /// The WebSocket port, or null when WebSocket guests are not accepted.
  int? get wsPort;

  /// Every new guest connection, TCP or WebSocket. Single subscription.
  Stream<MessageChannel> get channels;

  /// Stops accepting connections (open channels stay open).
  Future<void> close();
}
