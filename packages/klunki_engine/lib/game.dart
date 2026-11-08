/// Shared, framework-agnostic types used by every Klunki game.
///
/// IMPORTANT: this file and the engine must keep *zero* Flutter imports so the
/// logic stays pure and testable without a device.
library;

/// A player id. `A` / `B` for hot-seat, or a runtime id over the network.
enum Player { a, b }

/// English name of [p] in the engine's own texts (CLI, debug console, result
/// reasons, test logs; KLD-103): "Anna" for A, "Ben" for B, the app's default
/// names. The app shows its own, localized names; the protocol only knows
/// `a` / `b`.
String playerNameOf(Player? p) => switch (p) {
      Player.a => 'Anna',
      Player.b => 'Ben',
      null => 'nobody',
    };

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
  /// Any game: a player resigned (KLD-065). params: `player` (the resigner's
  /// [Player.index]: 0 = A, 1 = B); the winner is the other player.
  commonResigned('common.resigned'),
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
  schiffeAllSunk('schiffe.allSunk'),
  gostrategyFlagCaptured('gostrategy.flagCaptured'),
  /// The loser had no legal move on their turn.
  gostrategyNoMoves('gostrategy.noMoves'),
  /// Draw: neither player can move.
  gostrategyBothBlocked('gostrategy.bothBlocked'),
  /// params: `moves` (the draw limit).
  gostrategyMoveLimit('gostrategy.moveLimit'),
  /// The winner mated the loser (KLD-059).
  chessCheckmate('chess.checkmate'),
  /// Draw: the player to move has no legal move but is not in check.
  chessStalemate('chess.stalemate'),
  /// Draw: neither side can ever mate (e.g. K–K, K+B–K, K+N–K).
  chessInsufficientMaterial('chess.insufficientMaterial'),
  /// Draw: no capture or pawn move for `moves` (75) moves by each side.
  chessSeventyFiveMoves('chess.seventyFiveMoves'),
  /// Draw: the same position for the `times`-th (3rd) time.
  chessThreefoldRepetition('chess.threefoldRepetition'),
  /// Draw: one player offered a draw and the other accepted it (KLD-059
  /// step 3).
  chessDrawAgreed('chess.drawAgreed'),
  /// Word tiles (KLD-094): a player used up the last tiles with the bag
  /// empty; the others' rack values went to them. params: `a`, `b` (final
  /// scores).
  wordtilesPlayedOut('wordtiles.playedOut'),
  /// Word tiles: `turns` consecutive scoreless turns; every rack value was
  /// subtracted. params: `turns`, `a`, `b` (final scores).
  wordtilesScoreless('wordtiles.scorelessTurns'),
  /// Mau-Mau (KLD-118): the winner laid the last card.
  maumauEmptyHand('maumau.emptyHand'),

  /// Mäxchen (KLD-121): the loser has no lives left. params: `a`, `b`
  /// (lives left).
  maexchenNoLives('maexchen.noLives'),

  /// Ausgewürfelt (KLD-119): every sheet still in is full; the highest
  /// total wins. params: `a`, `b` (totals of seats 0 and 1; the
  /// [SeatResult] has `score0…score3`).
  dicesheetAllFilled('dicesheet.allFilled');

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
///
/// Resigning (KLD-065) lives here, once for every game: the move
/// `{'action': 'resign', 'player': 'a' | 'b'}` ([resignMove]) ends any
/// running game at once, in every phase (setup included) and regardless of
/// whose turn it is; the other player wins with [GameEndReason.commonResigned].
/// It is an ordinary move, so it goes through the same move log as every
/// other move (network replication, replay, hot-seat undo). Because it may
/// come from the player who is *not* to move, the move names its player;
/// use [playerOf] instead of [currentPlayer] to learn who made a move.
///
/// Games implement the play rules in [applyPlayMove] and [playResult];
/// [applyMove], [result] and [isOver] add the resignation on top.
abstract class Game {
  Player get currentPlayer;

  Player? _resignedBy;

  /// The player who resigned, or null.
  Player? get resignedBy => _resignedBy;

  /// The outcome by the game's own rules, ignoring a resignation.
  GameResult get playResult;

  /// The outcome: [playResult], or the resignation result once a player
  /// resigned.
  GameResult get result {
    final r = _resignedBy;
    if (r == null) return playResult;
    return GameResult(
        winner: _other(r),
        reason: '${playerNameOf(r)} resigned',
        code: GameEndReason.commonResigned,
        params: {'player': r.index});
  }

  bool get isOver => _resignedBy != null || playResult.isOver;

  /// The game's own move log (resignation not included: see [resignedBy]).
  /// The full log, resign included, is the transport's / session's move list.
  List<Map<String, dynamic>> get history;

  /// Applies [move]: a resign ([resignMove]) for the player it names, any
  /// other move for [currentPlayer] via [applyPlayMove]. Returns null if the
  /// move is illegal or the game is over; the state is then unchanged.
  GameEvent? applyMove(Map<String, dynamic> move) {
    if (move['action'] == 'resign') {
      final p = resignerOf(move);
      if (p == null || isOver) return null;
      _resignedBy = p;
      return GameEvent(winner: _other(p), payload: {'resigned': p});
    }
    if (isOver) return null;
    return applyPlayMove(move);
  }

  /// Applies a game move for [currentPlayer]; null if illegal. Only called
  /// while the game is running.
  GameEvent? applyPlayMove(Map<String, dynamic> move);

  /// The player who makes [move]: the resigner for a resign, else
  /// [currentPlayer]. Transports use this to attribute moves.
  Player playerOf(Map<String, dynamic> move) => resignerOf(move) ?? currentPlayer;

  /// The resign move for [player].
  static Map<String, dynamic> resignMove(Player player) => {'action': 'resign', 'player': player.name};

  /// The resigning player if [move] is a well-formed resign move, else null.
  static Player? resignerOf(Map<String, dynamic> move) {
    if (move['action'] != 'resign') return null;
    return switch (move['player']) { 'a' => Player.a, 'b' => Player.b, _ => null };
  }

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;
}
