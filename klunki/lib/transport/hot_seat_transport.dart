import 'dart:async';

import 'game_transport.dart';

/// Hot-seat transport: one device, two players handed the phone back and
/// forth. This is the M1 single-device PoC transport.
///
/// There is no network: the "opponent" is the other human on the same device.
class HotSeatTransport implements GameTransport {
  final Object myId;
  late final StreamController<Object> _controller =
      StreamController<Object>.broadcast();

  HotSeatTransport(this.myId);

  @override
  Object get self => myId;

  @override
  Stream<Object> get incomingMoves => _controller.stream;

  @override
  Future<Object?> submit(Map<String, dynamic> move) async {
    // In single-device hot-seat the same surface both produces and validates.
    // The engine's `applyMove` is the single source of truth for legality.
    _controller.add(move);
    return null;
  }

  @override
  void dispose() => _controller.close();
}
