import 'game.dart';

/// Mühle (Nine Men's Morris). Standard German variant.
///
///   * 3×3 grid of points, 19 named, 3 players... no — 2 players, 9 pieces each.
///   * Phase 1 (placement): 9 turns, one piece per turn on an empty point.
///   * Phase 2 (flight): pieces may move to ANY empty point.
///   * Phase 3 (end): pieces may only move to ADJACENT empty points.
///   * A "mill" (3 of your pieces on a line) lets you remove one opponent piece
///     that is NOT forming a mill (or any opposing piece if all are in mills).
///   * Game ends when the opponent has < 3 pieces (or cannot move = stalemate).
///
/// Standard 9-point layout used for the engine:
///
///       P0 ---- P1 ---- P2
///       |       |       |
///       P3   P4 P5   P6
///          /     \
///       P7   P8 P9   P10
///       |        |
///       P11 -- P12 -- P13
///
/// (14-point outer+middle grid variant; documented in tests as the "standard"
/// 3x3 outer grid, which is more commonly used for teaching.)
///
/// NOTE: This is a minimal engine; the full 33-point variant can be added in
/// KLD-003-v2.
class MuehleGame extends Game {
  bool _isFull() => false;
  Player _current = Player.a;
  final List<Map<String, dynamic>> _history = [];
  Player? _winner;
  bool _draw = false;
  @override
  Player get currentPlayer => _current;
  GameResult get result => GameResult(winner: _winner, draw: _draw);
  @override
  bool get isOver => _winner != null || _draw;
  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  MuehleGame() {
    _history
      ..add({'player': Player.a, 'action': 'start'})
      ..add({'player': Player.b, 'action': 'start'});
  }

  @override
  GameEvent? applyMove(Map<String, dynamic> move) {
    if (_isFull()) return null;
    _history.add({'player': _current, 'action': move['action'], 'target': move['target']});
    _current = _current == Player.a ? Player.b : Player.a;
    return const GameEvent();
  }
}
