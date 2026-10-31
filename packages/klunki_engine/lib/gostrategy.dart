import 'dart:math';

import 'game.dart';

/// Phase of a GoStrategy game. Game over is reported via
/// [GoStrategyGame.isOver]; the phase stays [play] after the last move.
enum GoStrategyPhase { setup, play }

/// The twelve piece kinds. [rank] is null for the immobile bomb and flag.
/// [id] (the enum name) is the stable string used in moves and payloads.
enum GoPiece {
  marshal(10, 1),
  general(9, 1),
  colonel(8, 2),
  major(7, 3),
  captain(6, 4),
  lieutenant(5, 4),
  sergeant(4, 4),
  miner(3, 5),
  scout(2, 8),
  spy(1, 1),
  bomb(null, 6),
  flag(null, 1);

  /// Fighting strength 1–10; null for [bomb] and [flag].
  final int? rank;

  /// How many of this kind each player has (40 in total).
  final int count;
  const GoPiece(this.rank, this.count);

  String get id => name;

  /// Bombs and the flag never move.
  bool get movable => rank != null;

  /// The piece for [id], or null if unknown.
  static GoPiece? fromId(Object? id) {
    for (final p in values) {
      if (p.name == id) return p;
    }
    return null;
  }
}

/// Outcome of an attack, seen from the attacker. [id] is the payload string.
enum GoFightOutcome {
  /// Defender removed; the attacker takes its square.
  attackerWins('attacker'),

  /// Attacker removed; the defender stays.
  defenderWins('defender'),

  /// Equal ranks: both removed.
  bothLose('both'),

  /// The defender was the flag: the attacker wins the game.
  flagCaptured('flag');

  final String id;
  const GoFightOutcome(this.id);
}

/// One square as seen by a viewer (see [GoStrategyGame.viewFor]).
class GoCell {
  /// Owner of the piece; null for an empty square or a lake.
  final Player? owner;

  /// The piece, or null when the square is empty or the viewer may not know
  /// it (an unrevealed enemy piece).
  final GoPiece? piece;

  /// Both players know this piece's kind (it fought, or a scout moved more
  /// than one square).
  final bool revealed;

  /// The piece has moved at least once, so it is neither a bomb nor a flag.
  /// Public knowledge, like [revealed].
  final bool moved;

  /// The square is one of the eight lake squares (never holds a piece).
  final bool lake;

  const GoCell({this.owner, this.piece, this.revealed = false, this.moved = false, this.lake = false});

  bool get isEmpty => owner == null;

  /// An enemy piece whose kind the viewer does not know.
  bool get hidden => owner != null && piece == null;

  @override
  bool operator ==(Object other) =>
      other is GoCell &&
      other.owner == owner &&
      other.piece == piece &&
      other.revealed == revealed &&
      other.moved == moved &&
      other.lake == lake;

  @override
  int get hashCode => Object.hash(owner, piece, revealed, moved, lake);

  @override
  String toString() => lake
      ? 'GoCell(lake)'
      : owner == null
          ? 'GoCell(empty)'
          : 'GoCell(${owner!.name} ${piece?.id ?? '?'}${revealed ? ' revealed' : ''}${moved ? ' moved' : ''})';
}

class _Unit {
  final GoPiece piece;
  final Player owner;
  bool revealed = false;
  bool moved = false;
  _Unit(this.piece, this.owner);
}

/// GoStrategy: the classic two-player hidden-rank capture-the-flag game.
///
/// * Board 10×10, squares numbered `row * 10 + col` (0–99), row 0 at the
///   top. Two 2×2 lakes in rows 4–5, columns 2–3 and 6–7 ([lakes]); no piece
///   may enter them.
/// * Player A's home rows are 6–9 (bottom), player B's are 0–3 (top).
/// * Setup: A submits a full placement of 40 pieces, then B. Each placement
///   is a list of 40 piece ids in **player-relative order** ([setupSquare]):
///   index 0–9 is the player's front row from their own left to right,
///   30–39 their back row. Both players see their own side the same way.
/// * Play: A moves first. One piece one step orthogonally onto an empty
///   square or an enemy (an attack). Bombs and the flag never move. A scout
///   moves any number of empty squares in a straight line and may attack
///   the piece at the end of that line in the same move.
/// * Attack: both pieces are revealed; higher rank wins, equal ranks remove
///   both. The spy beats the marshal only when the spy attacks. Attacking a
///   bomb removes the attacker unless it is a miner (which removes the bomb
///   and takes its square). Attacking the flag wins.
/// * Two-square rule: a piece may move back and forth between the same two
///   squares at most [maxRepeats] times in a row (the player's own
///   consecutive moves; attacks reset the count).
/// * End: flag captured; the player to move has no legal move loses; draw
///   when neither side can move; draw after [noCaptureLimit] moves (both
///   players counted) without a fight.
///
/// Moves (Map convention):
///   * `{'action': 'setup', 'pieces': [40 piece ids]}`
///   * `{'action': 'autosetup', 'seed': s}` — [randomSetup] of seed s
///   * `{'action': 'move', 'from': square, 'to': square}`
///
/// Illegal moves (and any move after the game is over) return `null` and
/// leave the state untouched.
class GoStrategyGame extends Game {
  static const int size = 10;
  static const int squareCount = size * size;
  static const int piecesPerPlayer = 40;
  static const int maxRepeats = 3;
  static const int defaultNoCaptureLimit = 200;

  /// The eight lake squares.
  static const Set<int> lakes = {42, 43, 46, 47, 52, 53, 56, 57};

  /// One full army in rank order (marshal first, flag last).
  static final List<GoPiece> army = List.unmodifiable([
    for (final p in GoPiece.values) ...List.filled(p.count, p),
  ]);

  static bool isLake(int square) => lakes.contains(square);
  static int square(int row, int col) => row * size + col;
  static int rowOf(int square) => square ~/ size;
  static int colOf(int square) => square % size;

  /// Board square of setup index [i] (0–39) for [player]: A's index 0 is
  /// square 60 (row 6, col 0), B's index 0 is square 39 (row 3, col 9):
  /// the same layout rotated by 180°.
  static int setupSquare(Player player, int i) => player == Player.a ? 60 + i : 39 - i;

  /// The 40 home squares of [player], in setup order.
  static List<int> homeSquares(Player player) => [for (var i = 0; i < piecesPerPlayer; i++) setupSquare(player, i)];

  /// Moves (both players) without a fight before the game is a draw.
  final int noCaptureLimit;

  final List<_Unit?> _board = List.filled(squareCount, null);
  GoStrategyPhase _phase;
  Player _current;
  final Map<Player, bool> _setupDone;
  final List<Map<String, dynamic>> _history = [];
  int _movesSinceCapture = 0;
  final Map<Player, (int, int)?> _lastMove = {Player.a: null, Player.b: null};
  final Map<Player, int> _streak = {Player.a: 0, Player.b: 0};
  Map<String, dynamic>? _lastFight;
  Player? _winner;
  bool _draw = false;
  String _reason = '';
  GameEndReason? _code;
  Map<String, int> _params = const {};

  GoStrategyGame({this.noCaptureLimit = defaultNoCaptureLimit})
      : _phase = GoStrategyPhase.setup,
        _current = Player.a,
        _setupDone = {Player.a: false, Player.b: false};

  /// A game that starts in the play phase with [pieces] (square → owner and
  /// piece) and [toMove] to move. For tests, puzzles and UI previews; it is
  /// not reproducible from a [GameConfig] and its history holds only the
  /// moves made after the start.
  GoStrategyGame.position(Map<int, (Player, GoPiece)> pieces,
      {Player toMove = Player.a, this.noCaptureLimit = defaultNoCaptureLimit})
      : _phase = GoStrategyPhase.play,
        _current = toMove,
        _setupDone = {Player.a: true, Player.b: true} {
    for (final e in pieces.entries) {
      if (e.key < 0 || e.key >= squareCount || isLake(e.key)) {
        throw ArgumentError.value(e.key, 'pieces', 'not a land square');
      }
      _board[e.key] = _Unit(e.value.$2, e.value.$1);
    }
  }

  GoStrategyPhase get phase => _phase;

  @override
  Player get currentPlayer => _current;

  @override
  GameResult get playResult =>
      GameResult(winner: _winner, draw: _draw, reason: _reason, code: _code, params: _params);


  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  /// Whether [p] has submitted their setup.
  bool hasSetup(Player p) => _setupDone[p]!;

  /// Consecutive moves (both players) since the last fight.
  int get movesSinceCapture => _movesSinceCapture;

  /// The most recent fight (same map as the `fight` payload), or null.
  Map<String, dynamic>? get lastFight => _lastFight;

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;

  // ----------------------------------------------------------------- views

  GoCell _cell(int sq, Player? viewer) {
    if (isLake(sq)) return const GoCell(lake: true);
    final u = _board[sq];
    if (u == null) return const GoCell();
    final known = viewer == null || u.owner == viewer || u.revealed;
    return GoCell(owner: u.owner, piece: known ? u.piece : null, revealed: u.revealed, moved: u.moved);
  }

  /// The full truth (both armies visible). Never show this to a player.
  List<GoCell> get board => List.unmodifiable([for (var i = 0; i < squareCount; i++) _cell(i, null)]);

  /// What [viewer] may see: own pieces always, enemy pieces only once
  /// revealed (enemy [GoCell.moved] is public too). Index = square.
  List<GoCell> viewFor(Player viewer) =>
      List.unmodifiable([for (var i = 0; i < squareCount; i++) _cell(i, viewer)]);

  /// One square of [viewFor] (or of [board] when [viewer] is null).
  GoCell cellAt(int square, {Player? viewer}) => _cell(square, viewer);

  /// [p]'s pieces still on the board, per kind (public knowledge: every
  /// removed piece was revealed in its fight).
  Map<GoPiece, int> remaining(Player p) {
    final out = {for (final k in GoPiece.values) k: 0};
    for (final u in _board) {
      if (u != null && u.owner == p) out[u.piece] = out[u.piece]! + 1;
    }
    return out;
  }

  // ----------------------------------------------------------------- setup

  /// Why [pieces] is not a valid setup (wrong length, unknown id, wrong
  /// counts), or null if it is valid. Placement is always on the home rows,
  /// which never contain a lake, because the index decides the square.
  static String? setupError(Object? pieces) {
    if (pieces is! List) return 'pieces must be a list';
    if (pieces.length != piecesPerPlayer) return 'need $piecesPerPlayer pieces, got ${pieces.length}';
    final counts = <GoPiece, int>{};
    for (final id in pieces) {
      final p = GoPiece.fromId(id);
      if (p == null) return 'unknown piece "$id"';
      counts[p] = (counts[p] ?? 0) + 1;
    }
    for (final p in GoPiece.values) {
      if ((counts[p] ?? 0) != p.count) return 'need ${p.count} × ${p.id}, got ${counts[p] ?? 0}';
    }
    return null;
  }

  static bool isValidSetup(Object? pieces) => setupError(pieces) == null;

  /// The `setup` move for [pieces] (in setup order).
  static Map<String, dynamic> setupMove(List<GoPiece> pieces) =>
      {'action': 'setup', 'pieces': [for (final p in pieces) p.id]};

  /// A random, legal and sensible setup, deterministic for [seed]: the flag
  /// on the back row with bombs on its free sides, the other bombs behind
  /// the front row, and only movable pieces in the front row (so the army
  /// can always move at the start).
  static List<GoPiece> randomSetup(int seed) {
    final rng = Random(seed);
    final out = List<GoPiece?>.filled(piecesPerPlayer, null);
    final flagCol = rng.nextInt(size);
    out[30 + flagCol] = GoPiece.flag;
    var bombs = GoPiece.bomb.count;
    for (final i in [if (flagCol > 0) 30 + flagCol - 1, if (flagCol < size - 1) 30 + flagCol + 1, 20 + flagCol]) {
      out[i] = GoPiece.bomb;
      bombs--;
    }
    final free = [for (var i = size; i < piecesPerPlayer; i++) if (out[i] == null) i]..shuffle(rng);
    for (var b = 0; b < bombs; b++) {
      out[free[b]] = GoPiece.bomb;
    }
    final rest = [for (final p in army) if (p.movable) p]..shuffle(rng);
    var k = 0;
    for (var i = 0; i < piecesPerPlayer; i++) {
      if (out[i] == null) out[i] = rest[k++];
    }
    return List.unmodifiable(out.cast<GoPiece>());
  }

  // ----------------------------------------------------------------- moves

  /// Squares the piece on [from] may move to (empty or enemy) for
  /// [currentPlayer], respecting the two-square rule. Empty if it is not
  /// the current player's movable piece, outside the play phase, or after
  /// the game is over.
  List<int> targetsFrom(int from) {
    if (isOver || _phase != GoStrategyPhase.play) return const [];
    return _targets(_current, from);
  }

  List<int> _targets(Player p, int from) {
    if (from < 0 || from >= squareCount) return const [];
    final u = _board[from];
    if (u == null || u.owner != p || !u.piece.movable) return const [];
    final out = <int>[];
    final r0 = rowOf(from), c0 = colOf(from);
    for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      var r = r0 + dr, c = c0 + dc;
      while (r >= 0 && r < size && c >= 0 && c < size) {
        final sq = square(r, c);
        if (isLake(sq)) break;
        final t = _board[sq];
        if (t != null) {
          if (t.owner != p) out.add(sq);
          break;
        }
        out.add(sq);
        if (u.piece != GoPiece.scout) break;
        r += dr;
        c += dc;
      }
    }
    final last = _lastMove[p];
    if (last != null && last.$2 == from && _streak[p]! >= maxRepeats) {
      out.remove(last.$1);
    }
    return out;
  }

  List<Map<String, dynamic>> _moveOptions(Player p) => [
        for (var from = 0; from < squareCount; from++)
          for (final to in _targets(p, from)) {'action': 'move', 'from': from, 'to': to},
      ];

  /// Legal moves for [currentPlayer]. Setup: a sample of ten random setups
  /// (`autosetup` seeds 0–9; any valid `setup` is accepted too). Play: every
  /// legal `move`. Empty when the game is over.
  List<Map<String, dynamic>> get legalMoves {
    if (isOver) return const [];
    if (_phase == GoStrategyPhase.setup) {
      return [for (var s = 0; s < 10; s++) {'action': 'autosetup', 'seed': s}];
    }
    return _moveOptions(_current);
  }

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) {
    if (isOver) return null;
    switch (move['action']) {
      case 'setup':
        if (_phase != GoStrategyPhase.setup || setupError(move['pieces']) != null) return null;
        return _setup(move, [for (final id in move['pieces'] as List) GoPiece.fromId(id)!]);
      case 'autosetup':
        final seed = move['seed'];
        if (_phase != GoStrategyPhase.setup || seed is! int) return null;
        return _setup(move, randomSetup(seed));
      case 'move':
        return _move(move);
      default:
        return null;
    }
  }

  GameEvent _setup(Map<String, dynamic> move, List<GoPiece> pieces) {
    final player = _current;
    for (var i = 0; i < piecesPerPlayer; i++) {
      _board[setupSquare(player, i)] = _Unit(pieces[i], player);
    }
    _setupDone[player] = true;
    _history.add({...move, 'player': player});
    final payload = {'setup': player};
    if (player == Player.a) {
      _current = Player.b;
      return GameEvent(payload: payload);
    }
    _phase = GoStrategyPhase.play;
    _current = Player.b; // _endTurn passes the turn to A
    return _endTurn(Player.b, payload);
  }

  GameEvent? _move(Map<String, dynamic> move) {
    if (_phase != GoStrategyPhase.play) return null;
    final from = move['from'], to = move['to'];
    if (from is! int || to is! int) return null;
    final player = _current;
    if (!_targets(player, from).contains(to)) return null;

    final unit = _board[from]!;
    final defender = _board[to];
    _history.add({'action': 'move', 'from': from, 'to': to, 'player': player});
    final payload = <String, dynamic>{'from': from, 'to': to};

    if (defender == null) {
      _board[to] = unit;
      _board[from] = null;
      unit.moved = true;
      if (unit.piece == GoPiece.scout && (rowOf(from) - rowOf(to)).abs() + (colOf(from) - colOf(to)).abs() > 1) {
        unit.revealed = true;
        payload['scout'] = true;
      }
      _movesSinceCapture++;
      final last = _lastMove[player];
      _streak[player] = last != null && last.$1 == to && last.$2 == from ? _streak[player]! + 1 : 1;
      _lastMove[player] = (from, to);
      return _endTurn(player, payload);
    }

    final outcome = fight(unit.piece, defender.piece);
    unit
      ..revealed = true
      ..moved = true;
    defender.revealed = true;
    switch (outcome) {
      case GoFightOutcome.attackerWins || GoFightOutcome.flagCaptured:
        _board[to] = unit;
        _board[from] = null;
      case GoFightOutcome.defenderWins:
        _board[from] = null;
      case GoFightOutcome.bothLose:
        _board[from] = null;
        _board[to] = null;
    }
    _movesSinceCapture = 0;
    _lastMove[player] = null;
    _streak[player] = 0;
    _lastFight = {
      'attacker': unit.piece.id,
      'defender': defender.piece.id,
      'attackerRank': unit.piece.rank,
      'defenderRank': defender.piece.rank,
      'attackerPlayer': player,
      'outcome': outcome.id,
      'from': from,
      'to': to,
    };
    payload['fight'] = _lastFight;
    if (outcome == GoFightOutcome.flagCaptured) {
      return _finish(player, 'flag captured', GameEndReason.gostrategyFlagCaptured, payload);
    }
    return _endTurn(player, payload);
  }

  /// Outcome when [attacker] attacks [defender] (pure rules, no state).
  static GoFightOutcome fight(GoPiece attacker, GoPiece defender) {
    if (defender == GoPiece.flag) return GoFightOutcome.flagCaptured;
    if (defender == GoPiece.bomb) {
      return attacker == GoPiece.miner ? GoFightOutcome.attackerWins : GoFightOutcome.defenderWins;
    }
    if (attacker == GoPiece.spy && defender == GoPiece.marshal) return GoFightOutcome.attackerWins;
    final a = attacker.rank!, d = defender.rank!;
    if (a == d) return GoFightOutcome.bothLose;
    return a > d ? GoFightOutcome.attackerWins : GoFightOutcome.defenderWins;
  }

  /// End checks after [player]'s move, then passes the turn.
  GameEvent _endTurn(Player player, Map<String, dynamic> payload) {
    final opp = _other(player);
    if (_movesSinceCapture >= noCaptureLimit) {
      _draw = true;
      _reason = '$noCaptureLimit moves without a capture';
      _code = GameEndReason.gostrategyMoveLimit;
      _params = {'moves': noCaptureLimit};
      return GameEvent(draw: true, payload: payload);
    }
    _current = opp;
    if (_moveOptions(opp).isEmpty) {
      if (_moveOptions(player).isEmpty) {
        _draw = true;
        _reason = 'neither player can move';
        _code = GameEndReason.gostrategyBothBlocked;
        return GameEvent(draw: true, payload: payload);
      }
      return _finish(player, 'opponent cannot move', GameEndReason.gostrategyNoMoves, payload);
    }
    return GameEvent(payload: payload);
  }

  GameEvent _finish(Player winner, String reason, GameEndReason code, Map<String, dynamic> payload) {
    _winner = winner;
    _reason = reason;
    _code = code;
    return GameEvent(winner: winner, payload: payload);
  }
}
