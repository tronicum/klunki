import 'game.dart';

/// 4 Gewinnt (Connect Four): 7 columns × 6 rows. Players drop markers into a
/// column; the marker falls to the lowest empty row. First to line up four of
/// the same colour (row, column, or diagonal) wins.
///
/// Board is stored column-major: `board[col][row]` where row 0 is the
/// *bottom*.
class Connect4Game implements Game {
  static const int cols = 7;
  static const int rows = 6;

  // board[col][row]; null = empty.
  late final List<List<Player?>> _board;
  Player _current = Player.a;
  final List<Map<String, dynamic>> _history = [];
  Player? _winner;
  bool _draw = false;

  Connect4Game() {
    _board = List.generate(cols, (_) => List.filled(rows, null));
  }

  List<List<Player?>> get board => _board;

  @override
  Player get currentPlayer => _current;

  GameResult get result => GameResult(
      winner: _winner,
      draw: _draw,
      reason: _winner != null ? 'four in a row' : (_draw ? 'board full' : ''),
      code: _winner != null
          ? GameEndReason.connect4FourInARow
          : (_draw ? GameEndReason.connect4BoardFull : null));

  @override
  bool get isOver => _winner != null || _draw;

  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  /// Columns that still accept a piece; empty once the game is over.
  List<int> get legalMoves => isOver
      ? const []
      : [for (var c = 0; c < cols; c++) if (_board[c][rows - 1] == null) c];

  /// Lowest empty row in [col] (the bottom of the stack), or null if full.
  int? _dropRow(int col) {
    for (var r = 0; r < rows; r++) {
      if (_board[col][r] == null) return r;
    }
    return null;
  }

  @override
  GameEvent? applyMove(Map<String, dynamic> move) {
    if (isOver) return null;
    final int col = move['col'];
    if (col < 0 || col >= cols) return null; // out of range
    final row = _dropRow(col);
    if (row == null) return null; // invalid: column full

    _board[col][row] = _current;
    _history.add({'col': col, 'row': row, 'player': _current});

    final Player player = _current;
    if (_checkWin(player, col, row)) {
      _winner = player;
      return GameEvent(winner: player, payload: {'col': col, 'row': row});
    }

    if (_isFull()) {
      _draw = true;
      return const GameEvent(draw: true);
    }

    _current = _current == Player.a ? Player.b : Player.a;
    return const GameEvent();
  }

  bool _isFull() {
    for (var c = 0; c < cols; c++) {
      if (_board[c][rows - 1] == null) return false;
    }
    return true;
  }

  /// True if the piece just placed at ([col], [row]) completes four or more
  /// in a row for [player] in any direction (gaps filled count too).
  bool _checkWin(Player player, int col, int row) {
    const dirs = <List<int>>[
      [1, 0], [0, 1], [1, 1], [1, -1],
    ];
    for (final d in dirs) {
      final fwd = _run(player, col, row, d[0], d[1]);
      final back = _run(player, col, row, -d[0], -d[1]);
      if (1 + fwd + back >= 4) return true;
    }
    return false;
  }

  /// Consecutive [player] pieces from ([col], [row]) stepping by ([dc], [dr]),
  /// excluding the start cell.
  int _run(Player player, int col, int row, int dc, int dr) {
    var n = 0;
    while (_lineOf(col + dc * (n + 1), row + dr * (n + 1)) == player) {
      n++;
    }
    return n;
  }

  Player? _lineOf(int col, int row) {
    if (col < 0 || col >= cols || row < 0 || row >= rows) return null;
    return _board[col][row];
  }

  /// Human-friendly board for rendering: row 0 at top.
  List<List<Player?>> toRenderRows() {
    final out = <List<Player?>>[];
    for (var r = 0; r < rows; r++) {
      out.add(List.generate(cols, (c) => _board[c][rows - 1 - r]));
    }
    return out;
  }
}
