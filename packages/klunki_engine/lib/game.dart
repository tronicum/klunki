/// Shared, framework-agnostic types used by every Klunki game.
///
/// IMPORTANT: this file and the engine must keep *zero* Flutter imports so the
/// logic stays pure and testable without a device.
library;

/// A player id. `A` / `B` for hot-seat, or a runtime id over the network.
enum Player { a, b }

/// Result of applying a move.
class GameEvent {
  final Player? winner;
  final bool draw;
  final dynamic payload; // game-specific (e.g. captured piece, quartett set)
  const GameEvent({this.winner, this.draw = false, this.payload});
}

/// Outcome summary of a finished / ongoing game.
class GameResult {
  final Player? winner;
  final bool draw;
  final String reason;
  const GameResult({this.winner, this.draw = false, this.reason = ''});

  bool get isOver => winner != null || draw;
}

/// Common shape every game exposes.
abstract class Game {
  Player get currentPlayer;
  GameResult get result;
  bool get isOver => result.isOver;
  List<Map<String, dynamic>> get history; // for undo / network replay

  /// Apply a move for [currentPlayer]. Returns [null] if the game is over.
  GameEvent? applyMove(Map<String, dynamic> move);
}
