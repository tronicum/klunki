import 'game.dart';

/// Quartett — classic German card-set game.
///
/// Players ask each other for cards sharing an attribute. A correct answer
/// transfers the card to the asker. A completed "Quartett" (4 of a set) allows
/// the caller to deal a new set. The game ends when all cards are distributed.

class Card {
  final String name;
  final int setId;
  final Map<String, int> attributes;
  final Map<String, String> tags;
  const Card({
    required this.name,
    required this.setId,
    this.attributes = const {},
    this.tags = const {},
  });
}

class QuartettGame extends Game {
  // Player A vs Player B.
  late final List<Player> _players = [Player.a, Player.b];
  late final Map<Player, Set<int>> _playerCards = {
    Player.a: <int>{},
    Player.b: <int>{},
  };
  final List<Map<String, dynamic>> _history = [];
  Player? _current = Player.a;
  Player? _winner;
  bool _draw = false;

  QuartettGame() {
    _history.add({'action': 'init', 'players': [Player.a, Player.b]});
  }

  @override
  Player get currentPlayer => _current!;

  GameResult get result => GameResult(winner: _winner, draw: _draw);
  @override
  bool get isOver => _winner != null || _draw;

  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  @override
  GameEvent? applyMove(Map<String, dynamic> move) {
    if (_isFull()) return null;
    _history.add({'player': _current, 'action': move['action']});
    _current = _current == Player.a ? Player.b : Player.a;
    return const GameEvent();
  }
}

extension _X on QuartettGame {
  bool _isFull() => false;
}
