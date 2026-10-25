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

/// Machine-readable reason why a game ended, for UIs that localize the
/// result. [code] is a stable string (`<game>.<reason>`), safe to persist or
/// compare; the English [GameResult.reason] stays the console text.
enum GameEndReason {
  connect4FourInARow('connect4.fourInARow'),
  connect4BoardFull('connect4.boardFull'),
  muehleFewerThanThree('muehle.fewerThanThree'),
  muehleBlocked('muehle.blocked'),
  /// params: `moves` (the draw limit).
  muehleNoRemovalLimit('muehle.noRemovalLimit'),
  quartettBothStacksEmpty('quartett.bothStacksEmpty'),
  quartettAllCards('quartett.allCards'),
  /// params: `a`, `b` (stack sizes).
  quartettTrickLimitEqual('quartett.trickLimitEqual'),
  /// params: `a`, `b` (stack sizes).
  quartettTrickLimitMoreCards('quartett.trickLimitMoreCards'),
  /// params: `a`, `b` (quartet counts).
  quartettAllQuartetsEqual('quartett.allQuartetsEqual'),
  /// params: `a`, `b` (quartet counts).
  quartettMostQuartets('quartett.mostQuartets'),
  schiffeAllSunk('schiffe.allSunk');

  final String code;
  const GameEndReason(this.code);

  /// The reason for [code], or null if unknown.
  static GameEndReason? fromCode(String code) {
    for (final r in values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

/// Outcome summary of a finished / ongoing game.
class GameResult {
  final Player? winner;
  final bool draw;

  /// English, human-readable reason (CLI, debug console). Empty while the
  /// game is running.
  final String reason;

  /// Machine-readable reason; null while the game is running.
  final GameEndReason? code;

  /// Numbers that belong to [code] (see the enum docs), e.g. `{'a': 5, 'b': 3}`.
  final Map<String, int> params;
  const GameResult(
      {this.winner,
      this.draw = false,
      this.reason = '',
      this.code,
      this.params = const {}});

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
