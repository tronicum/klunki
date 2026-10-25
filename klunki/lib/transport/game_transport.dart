/// The transport contract.
///
/// The engine is pure: it exposes `applyMove(state, move) -> event`. A
/// [GameTransport] decides *where the next move comes from* — a local
/// hot-seat device, a Wi-Fi peer, or a (future) Bluetooth peer — and runs it
/// through the *same* engine, so the rules can never diverge between players.
abstract class GameTransport {
  /// The local device's own player id.
  Object get self;

  /// Moves produced by the opponent (or the AI in single-device practice).
  Stream<Object> get incomingMoves;

  /// Submit a move for the local player to be validated + applied.
  /// Returns the resulting engine event, or null if the move was illegal.
  Future<Object?> submit(Map<String, dynamic> move);

  void dispose();
}
