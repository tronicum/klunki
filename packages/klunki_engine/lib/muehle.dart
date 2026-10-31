import 'game.dart';

/// Phase a single player is in. Phases are tracked *per player*: one player
/// may already be flying while the other is still moving.
enum MuehlePhase {
  /// The player still has pieces in hand and places one per turn.
  placing,

  /// All pieces placed; a piece moves to an *adjacent* empty point.
  moving,

  /// All pieces placed and exactly 3 left on the board; a piece may jump to
  /// *any* empty point.
  flying,
}

/// Mühle (Nine Men's Morris), standard German rules.
///
/// Board: 24 points in three nested squares, numbered row by row from the
/// top-left corner of the outer square:
///
/// ```text
///  0-----------1-----------2
///  |           |           |
///  |   3-------4-------5   |
///  |   |       |       |   |
///  |   |   6---7---8   |   |
///  |   |   |       |   |   |
///  9--10--11      12--13--14
///  |   |   |       |   |   |
///  |   |  15--16--17   |   |
///  |   |       |       |   |
///  |  18------19------20   |
///  |           |           |
/// 21----------22----------23
/// ```
///
/// Rules implemented:
///   * Each player has 9 pieces. Per player the phase is [MuehlePhase.placing]
///     until all 9 are placed, then [MuehlePhase.moving] (to an adjacent empty
///     point), then [MuehlePhase.flying] once exactly 3 pieces are left.
///   * Forming a *new* mill (3 own pieces on one of the 16 [mills]) obliges
///     the same player to remove an opponent piece as a separate move
///     ([pendingRemoval]); the turn passes only after that removal. Pieces
///     inside a mill are protected unless every opponent piece is in a mill.
///   * A player loses when, after placing all pieces, they have fewer than 3
///     on the board, or when they have no legal move on their turn.
///   * Draw after [drawMoveLimit] consecutive place/move actions (both players
///     counted) without a removal.
///
/// Moves (Map convention):
///   * `{'action': 'place', 'to': p}`
///   * `{'action': 'move', 'from': a, 'to': b}` (moving and flying)
///   * `{'action': 'remove', 'at': p}`
///
/// Illegal moves (and any move after the game is over) return `null` and leave
/// the state untouched.
class MuehleGame extends Game {
  static const int pointCount = 24;
  static const int piecesPerPlayer = 9;
  static const int drawMoveLimit = 50;

  /// Neighbours of each point (index = point).
  static const List<List<int>> adjacency = [
    [1, 9], // 0
    [0, 2, 4], // 1
    [1, 14], // 2
    [4, 10], // 3
    [1, 3, 5, 7], // 4
    [4, 13], // 5
    [7, 11], // 6
    [4, 6, 8], // 7
    [7, 12], // 8
    [0, 10, 21], // 9
    [3, 9, 11, 18], // 10
    [6, 10, 15], // 11
    [8, 13, 17], // 12
    [5, 12, 14, 20], // 13
    [2, 13, 23], // 14
    [11, 16], // 15
    [15, 17, 19], // 16
    [12, 16], // 17
    [10, 19], // 18
    [16, 18, 20, 22], // 19
    [13, 19], // 20
    [9, 22], // 21
    [19, 21, 23], // 22
    [14, 22], // 23
  ];

  /// The 16 mills (three points on one line).
  static const List<List<int>> mills = [
    // horizontal
    [0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11],
    [12, 13, 14], [15, 16, 17], [18, 19, 20], [21, 22, 23],
    // vertical
    [0, 9, 21], [3, 10, 18], [6, 11, 15], [1, 4, 7],
    [16, 19, 22], [8, 12, 17], [5, 13, 20], [2, 14, 23],
  ];

  final List<Player?> _board = List<Player?>.filled(pointCount, null);
  final Map<Player, int> _inHand = {
    Player.a: piecesPerPlayer,
    Player.b: piecesPerPlayer,
  };
  Player _current = Player.a;
  bool _pendingRemoval = false;
  int _movesSinceRemoval = 0;
  final List<Map<String, dynamic>> _history = [];
  Player? _winner;
  bool _draw = false;
  String _reason = '';
  GameEndReason? _code;
  Map<String, int> _params = const {};

  /// Read-only view of the 24 points; `null` = empty.
  List<Player?> get board => List.unmodifiable(_board);

  @override
  Player get currentPlayer => _current;

  /// True while [currentPlayer] owes a removal after forming a mill.
  bool get pendingRemoval => _pendingRemoval;

  /// Consecutive place/move actions since the last removal.
  int get movesSinceRemoval => _movesSinceRemoval;

  @override
  GameResult get playResult =>
      GameResult(
          winner: _winner,
          draw: _draw,
          reason: _reason,
          code: _code,
          params: _params);


  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  int piecesInHand(Player p) => _inHand[p]!;

  int piecesOnBoard(Player p) {
    var n = 0;
    for (final c in _board) {
      if (c == p) n++;
    }
    return n;
  }

  MuehlePhase phaseOf(Player p) {
    if (_inHand[p]! > 0) return MuehlePhase.placing;
    return piecesOnBoard(p) == 3 ? MuehlePhase.flying : MuehlePhase.moving;
  }

  /// Legal moves for [currentPlayer] (only removals while [pendingRemoval]).
  /// Empty once the game is over.
  List<Map<String, dynamic>> get legalMoves {
    if (isOver) return const [];
    if (_pendingRemoval) {
      return [
        for (final p in _removablePoints(_other(_current)))
          {'action': 'remove', 'at': p},
      ];
    }
    return _placeOrMoveOptions(_current);
  }

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;

  static bool _validPoint(Object? p) => p is int && p >= 0 && p < pointCount;

  List<Map<String, dynamic>> _placeOrMoveOptions(Player p) {
    final out = <Map<String, dynamic>>[];
    switch (phaseOf(p)) {
      case MuehlePhase.placing:
        for (var i = 0; i < pointCount; i++) {
          if (_board[i] == null) out.add({'action': 'place', 'to': i});
        }
      case MuehlePhase.moving:
        for (var i = 0; i < pointCount; i++) {
          if (_board[i] != p) continue;
          for (final n in adjacency[i]) {
            if (_board[n] == null)
              out.add({'action': 'move', 'from': i, 'to': n});
          }
        }
      case MuehlePhase.flying:
        for (var i = 0; i < pointCount; i++) {
          if (_board[i] != p) continue;
          for (var j = 0; j < pointCount; j++) {
            if (_board[j] == null)
              out.add({'action': 'move', 'from': i, 'to': j});
          }
        }
    }
    return out;
  }

  bool _inMill(int point) {
    final owner = _board[point];
    if (owner == null) return false;
    for (final m in mills) {
      if (m.contains(point) && m.every((q) => _board[q] == owner)) return true;
    }
    return false;
  }

  /// Opponent points [current] may remove: pieces outside mills, or any piece
  /// if all of [owner]'s pieces are in mills.
  List<int> _removablePoints(Player owner) {
    final all = <int>[];
    final free = <int>[];
    for (var i = 0; i < pointCount; i++) {
      if (_board[i] != owner) continue;
      all.add(i);
      if (!_inMill(i)) free.add(i);
    }
    return free.isEmpty ? all : free;
  }

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) {
    if (isOver) return null;
    final action = move['action'];
    final player = _current;

    if (_pendingRemoval) {
      if (action != 'remove') return null;
      final at = move['at'];
      if (!_validPoint(at)) return null;
      if (!_removablePoints(_other(player)).contains(at)) return null;
      _board[at as int] = null;
      _pendingRemoval = false;
      _movesSinceRemoval = 0;
      _history.add({'player': player, 'action': 'remove', 'at': at});
      return _endTurn(player, {'removed': at});
    }

    final int to;
    switch (phaseOf(player)) {
      case MuehlePhase.placing:
        if (action != 'place') return null;
        final t = move['to'];
        if (!_validPoint(t) || _board[t as int] != null) return null;
        to = t;
        _board[to] = player;
        _inHand[player] = _inHand[player]! - 1;
        _history.add({'player': player, 'action': 'place', 'to': to});
      case MuehlePhase.moving:
      case MuehlePhase.flying:
        if (action != 'move') return null;
        final f = move['from'];
        final t = move['to'];
        if (!_validPoint(f) || !_validPoint(t)) return null;
        if (_board[f as int] != player || _board[t as int] != null) return null;
        if (phaseOf(player) == MuehlePhase.moving &&
            !adjacency[f].contains(t)) {
          return null;
        }
        to = t;
        _board[f] = null;
        _board[to] = player;
        _history.add({'player': player, 'action': 'move', 'from': f, 'to': to});
    }
    _movesSinceRemoval++;

    if (_inMill(to) && piecesOnBoard(_other(player)) > 0) {
      _pendingRemoval = true;
      return const GameEvent(payload: {'mill': true});
    }
    return _endTurn(player, null);
  }

  /// Checks end conditions after [player] finished their turn, then passes
  /// the turn to the opponent.
  GameEvent _endTurn(Player player, Object? payload) {
    final opp = _other(player);
    if (_inHand[opp] == 0 && piecesOnBoard(opp) < 3) {
      return _finish(player, 'opponent has fewer than 3 pieces',
          GameEndReason.muehleFewerThanThree, payload);
    }
    if (_movesSinceRemoval >= drawMoveLimit) {
      _draw = true;
      _reason = '$drawMoveLimit moves without a removal';
      _code = GameEndReason.muehleNoRemovalLimit;
      _params = {'moves': drawMoveLimit};
      return GameEvent(draw: true, payload: payload);
    }
    _current = opp;
    if (_placeOrMoveOptions(opp).isEmpty) {
      return _finish(player, 'opponent has no legal move',
          GameEndReason.muehleBlocked, payload);
    }
    return GameEvent(payload: payload);
  }

  GameEvent _finish(
      Player winner, String reason, GameEndReason code, Object? payload) {
    _winner = winner;
    _reason = reason;
    _code = code;
    return GameEvent(winner: winner, payload: payload);
  }
}
