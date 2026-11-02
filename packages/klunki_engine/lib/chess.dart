import 'dart:typed_data';

import 'game.dart';

/// Schach (chess, KLD-059) with the full FIDE rules.
///
/// **Players:** White moves first. By default White is [Player.a] and Black
/// [Player.b] (hot-seat: Spieler 1 is White). [whitePlayer] (KLD-059 step 4a,
/// rules version 3, `GameConfig.chessWhite`) lets [Player.b] play White, so a
/// network host (always [Player.a]) can play Black: then [Player.b] moves
/// first. Pieces carry their [ChessColor]; [colorOf] and [seatOf] map
/// between colours and players. [currentPlayer], results,
/// resigns and the draw offer moves are about players, as in every game.
///
/// **Squares** are algebraic names `a1` … `h8`. Internally (and in [board])
/// a square is an index `rank * 8 + file`: `a1` = 0, `h1` = 7, `a8` = 56,
/// `h8` = 63 ([squareIndex], [squareName]).
///
/// **Moves** are maps like every other Klunki game:
/// `{'action': 'move', 'from': 'e2', 'to': 'e4'}`; a pawn reaching the last
/// rank must name its piece, `'promotion': 'q' | 'r' | 'b' | 'n'`, and any
/// other move must not. Castling is the king's two-square move (`e1`→`g1`,
/// `e1`→`c1`, `e8`→`g8`, `e8`→`c8`); en passant is the pawn's diagonal move
/// to the empty target square. Resign is the common
/// `{'action': 'resign', 'player': 'a' | 'b'}` ([Game.resignMove]).
///
/// **Game end** (all automatic, no claims, so a hot-seat or network game
/// needs no extra "claim draw" move):
/// - checkmate: the mover wins ([GameEndReason.chessCheckmate]);
/// - stalemate ([GameEndReason.chessStalemate]);
/// - insufficient material ([GameEndReason.chessInsufficientMaterial]):
///   no pawns, rooks or queens, and either at most one knight or bishop on
///   the board, or only bishops that all stand on squares of one colour
///   (K–K, K+B–K, K+N–K, K+B–K+B with same-coloured bishops); no sequence
///   of legal moves can then mate;
/// - the 75-move rule ([GameEndReason.chessSeventyFiveMoves], FIDE 9.6.2):
///   150 half-moves without a capture or pawn move, unless the last move
///   mated. There is no claimable 50-move draw;
/// - threefold repetition ([GameEndReason.chessThreefoldRepetition]): the
///   same position (pieces, side to move, castling rights, and an en passant
///   capture only if one is actually legal) occurs for the third time. FIDE
///   makes threefold a claim and fivefold automatic; the app draws at once at
///   three. Repetitions count from the start of this game (a [ChessGame.fromFen]
///   game knows no earlier positions).
///
/// **Draw offer** (KLD-059 step 3, rules version 2): three moves that name
/// their player like a resign ([playerOf]):
/// - `{'action': 'offerDraw', 'player': p}`: [p], the player to move, offers
///   a draw. Refused off turn, while an offer is open, and when [p] already
///   offered in this position (a board move has to come between two offers
///   of one player);
/// - `{'action': 'acceptDraw', 'player': q}`: the other player accepts the
///   open offer; the game ends drawn ([GameEndReason.chessDrawAgreed]);
/// - `{'action': 'declineDraw', 'player': q}`: the other player declines it.
/// While the offer is open the offerer cannot move: the next move is the
/// answer (or a resign). So over the network nothing can cross the answer
/// in flight, and nobody has to read an offer from a stale position. The draw
/// moves are not in [history] or [sanHistory] (they are not board moves),
/// only in the transport's move log; [GameEvent.payload] is
/// `{'drawOffer': 'a'|'b'}`, `{'drawAccepted': …}` or `{'drawDeclined': …}`
/// (the player who sent the move).
///
/// [history] holds the applied moves with their SAN (`'san': 'Nf3'`); the
/// extra key is ignored when a history entry is replayed.
class ChessGame extends Game {
  /// The standard starting position.
  static const String startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  /// Full moves (150 half-moves) without capture or pawn move that draw.
  static const int moveRuleLimit = 75;

  /// How often a position must occur for the repetition draw.
  static const int repetitionLimit = 3;

  /// The position this game started from (for a restart or replay).
  final String startPosition;

  /// The player who plays White (default [Player.a]); the other plays Black.
  final Player whitePlayer;

  // Board: 0 empty, +type White, -type Black.
  final Int8List _b = Int8List(64);
  int _stm = 1; // side to move: 1 White, -1 Black
  int _castling = 0; // 1 White O-O, 2 White O-O-O, 4 Black O-O, 8 Black O-O-O
  int _ep = -1; // en passant target square after a double push
  int _halfmove = 0;
  int _fullmove = 1;
  final List<int> _kings = [4, 60]; // [White, Black]

  final List<int> _undo = [];
  final List<Map<String, dynamic>> _history = [];
  final Map<String, int> _seen = {};
  List<int> _legal = const [];
  GameResult _result = const GameResult();
  Player? _drawOffer;
  final Map<Player, int> _offeredAt = {};

  /// The standard starting position; [white] plays White (KLD-059 step 4a).
  ChessGame({Player white = Player.a}) : this._(startFen, white);

  /// A game from a FEN string. Castling rights whose king or rook is not on
  /// its home square are dropped. Throws [FormatException] for anything
  /// malformed or impossible (no single king per side, pawns on the first or
  /// last rank, an en passant square without the pawn that just moved, or the
  /// side not to move in check). The half-move and full-move fields may be
  /// left out (0 and 1).
  factory ChessGame.fromFen(String fen, {Player white = Player.a}) => ChessGame._(fen.trim(), white);

  ChessGame._(this.startPosition, this.whitePlayer) {
    _loadFen(startPosition);
    _afterPositionChange();
  }

  // ---------------------------------------------------------------- squares

  /// Index of the square [name] (`a1` = 0 … `h8` = 63), or null.
  static int? squareIndex(Object? name) {
    if (name is! String || name.length != 2) return null;
    final f = name.codeUnitAt(0) - 0x61, r = name.codeUnitAt(1) - 0x31;
    if (f < 0 || f > 7 || r < 0 || r > 7) return null;
    return r * 8 + f;
  }

  /// Algebraic name of square [index] (0 = `a1`).
  static String squareName(int index) =>
      String.fromCharCodes([0x61 + (index & 7), 0x31 + (index >> 3)]);

  // ------------------------------------------------------------- public API

  @override
  Player get currentPlayer => seatOf(sideToMove);

  /// The colour to move.
  ChessColor get sideToMove => _stm == 1 ? ChessColor.white : ChessColor.black;

  /// The colour [player] plays.
  ChessColor colorOf(Player player) => player == whitePlayer ? ChessColor.white : ChessColor.black;

  /// The player who plays [color].
  Player seatOf(ChessColor color) =>
      color == ChessColor.white ? whitePlayer : (whitePlayer == Player.a ? Player.b : Player.a);

  /// Piece per square, index `rank * 8 + file` (`a1` = 0, `h8` = 63).
  List<ChessPiece?> get board => List.unmodifiable([for (final p in _b) _pieceOf(p)]);

  /// The piece on [square] (`'e4'`), or null if it is empty or no square.
  ChessPiece? pieceAt(String square) {
    final i = squareIndex(square);
    return i == null ? null : _pieceOf(_b[i]);
  }

  /// Whether the player to move is in check.
  bool get isInCheck => _inCheck();

  /// Half-moves since the last capture or pawn move.
  int get halfmoveClock => _halfmove;

  /// The FEN full-move number (starts at 1, grows after Black's move).
  int get fullmoveNumber => _fullmove;

  /// The current position as FEN. The en passant field names the square
  /// after every double pawn push (as in the original FEN standard).
  String get fen => '${_placement()} ${_stm == 1 ? 'w' : 'b'} ${_castlingText()} '
      '${_ep < 0 ? '-' : squareName(_ep)} $_halfmove $_fullmove';

  @override
  GameResult get playResult => _result;

  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  /// The moves played so far in SAN (`e4`, `Nf3`, `O-O`, `exd6`, `e8=Q#`).
  List<String> get sanHistory => [for (final h in _history) h['san'] as String];

  /// Legal moves of the player to move as move maps; empty once the game is
  /// over (also after a resignation). While a draw offer is open they are
  /// listed but refused until the offer is answered ([drawOfferBy]).
  List<Map<String, dynamic>> get legalMoves => isOver ? const [] : [for (final m in _legal) _toMap(m)];

  /// [legalMoves] that start on [square].
  List<Map<String, dynamic>> legalMovesFrom(String square) {
    final i = squareIndex(square);
    if (i == null || isOver) return const [];
    return [for (final m in _legal) if (_from(m) == i) _toMap(m)];
  }

  // ------------------------------------------------------------ draw offer

  /// The draw offer moves (see the class docs).
  static const String offerDraw = 'offerDraw', acceptDraw = 'acceptDraw', declineDraw = 'declineDraw';

  /// [player] offers a draw.
  static Map<String, dynamic> offerDrawMove(Player player) => {'action': offerDraw, 'player': player.name};

  /// [player] accepts the other player's draw offer.
  static Map<String, dynamic> acceptDrawMove(Player player) => {'action': acceptDraw, 'player': player.name};

  /// [player] declines the other player's draw offer.
  static Map<String, dynamic> declineDrawMove(Player player) => {'action': declineDraw, 'player': player.name};

  /// The player a well-formed draw offer move names, else null.
  static Player? drawPlayerOf(Map<String, dynamic> move) {
    final a = move['action'];
    if (a != offerDraw && a != acceptDraw && a != declineDraw) return null;
    return switch (move['player']) { 'a' => Player.a, 'b' => Player.b, _ => null };
  }

  /// The player whose draw offer is open, or null.
  Player? get drawOfferBy => isOver ? null : _drawOffer;

  /// Whether [player] may offer a draw now: the game runs, it is [player]'s
  /// turn, no offer is open and [player] has not offered in this position yet.
  bool canOfferDraw(Player player) =>
      !isOver && player == currentPlayer && _drawOffer == null && _offeredAt[player] != _history.length;

  /// The draw moves name their player (an answer comes from the player not
  /// to move); everything else as [Game.playerOf].
  @override
  Player playerOf(Map<String, dynamic> move) => drawPlayerOf(move) ?? super.playerOf(move);

  GameEvent? _applyDraw(Map<String, dynamic> move) {
    final p = drawPlayerOf(move);
    if (p == null) return null;
    final other = p == Player.a ? Player.b : Player.a;
    switch (move['action']) {
      case offerDraw:
        if (!canOfferDraw(p)) return null;
        _drawOffer = p;
        _offeredAt[p] = _history.length;
        return GameEvent(payload: {'drawOffer': p.name});
      case acceptDraw:
        if (_drawOffer != other) return null;
        _drawOffer = null;
        _result = const GameResult(draw: true, reason: 'draw agreed', code: GameEndReason.chessDrawAgreed);
        return GameEvent(draw: true, payload: {'drawAccepted': p.name});
      default: // declineDraw
        if (_drawOffer != other) return null;
        _drawOffer = null;
        return GameEvent(payload: {'drawDeclined': p.name});
    }
  }

  /// SAN of [move] in the current position (with `+` / `#`), or null if the
  /// move is not legal here or the game is over.
  String? sanOf(Map<String, dynamic> move) {
    if (isOver) return null;
    final m = _match(move);
    return m == null ? null : _san(m);
  }

  /// Number of leaf nodes of the legal move tree [depth] plies deep (perft),
  /// for testing the move generator. Ignores the game-end rules other than
  /// mate and stalemate.
  int perft(int depth) {
    if (depth <= 0) return 1;
    final moves = _generateLegal();
    if (depth == 1) return moves.length;
    var n = 0;
    for (final m in moves) {
      _make(m);
      n += perft(depth - 1);
      _unmake(m);
    }
    return n;
  }

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) {
    if (isOver) return null;
    if (drawPlayerOf(move) != null || const {offerDraw, acceptDraw, declineDraw}.contains(move['action'])) {
      return _applyDraw(move);
    }
    // An open offer waits for its answer: the offerer (to move) cannot move.
    if (_drawOffer != null) return null;
    final m = _match(move);
    if (m == null) return null;

    final from = _from(m), to = _to(m), promo = _promo(m), flags = _flags(m);
    final piece = _b[from].abs();
    final enPassant = flags & _fEp != 0;
    final captureSquare = enPassant ? to - 8 * _stm : to;
    final captured = _b[captureSquare].abs();
    final sanBase = _sanBase(m, _legal);
    final mover = currentPlayer;

    _make(m);
    _afterPositionChange();
    final check = _inCheck();
    final mate = check && _legal.isEmpty;
    final san = '$sanBase${mate ? '#' : check ? '+' : ''}';
    _history.add({
      'action': 'move',
      'from': squareName(from),
      'to': squareName(to),
      if (promo != 0) 'promotion': _letters[promo],
      'san': san,
    });

    final payload = <String, dynamic>{
      'from': squareName(from),
      'to': squareName(to),
      'piece': _letters[piece],
      'san': san,
      'capture': captured == 0 ? null : _letters[captured],
      'captureSquare': captured == 0 ? null : squareName(captureSquare),
      'enPassant': enPassant,
      'castle': flags & _fCastle == 0 ? null : (to & 7) == 6 ? 'kingside' : 'queenside',
      'promotion': promo == 0 ? null : _letters[promo],
      'check': check,
      'mate': mate,
    };
    assert(_result.winner == null || _result.winner == mover);
    return GameEvent(winner: _result.winner, draw: _result.draw, payload: payload);
  }

  // ------------------------------------------------------------ move codes

  static const int _p = 1, _n = 2, _bishop = 3, _r = 4, _q = 5, _k = 6;
  static const List<String> _letters = ['', 'p', 'n', 'b', 'r', 'q', 'k'];
  static const int _fDouble = 1, _fEp = 2, _fCastle = 4;

  static int _move(int from, int to, [int promo = 0, int flags = 0]) => from | to << 6 | promo << 12 | flags << 15;
  static int _from(int m) => m & 63;
  static int _to(int m) => (m >> 6) & 63;
  static int _promo(int m) => (m >> 12) & 7;
  static int _flags(int m) => m >> 15;

  Map<String, dynamic> _toMap(int m) => {
        'action': 'move',
        'from': squareName(_from(m)),
        'to': squareName(_to(m)),
        if (_promo(m) != 0) 'promotion': _letters[_promo(m)],
      };

  /// The legal move [move] names, or null.
  int? _match(Map<String, dynamic> move) {
    if (move['action'] != 'move') return null;
    final from = squareIndex(move['from']), to = squareIndex(move['to']);
    if (from == null || to == null) return null;
    final p = move['promotion'];
    var promo = 0;
    if (p != null) {
      promo = switch (p) { 'q' => _q, 'r' => _r, 'b' => _bishop, 'n' => _n, _ => -1 };
      if (promo < 0) return null;
    }
    for (final m in _legal) {
      if (_from(m) == from && _to(m) == to && _promo(m) == promo) return m;
    }
    return null;
  }

  // ------------------------------------------------------- precomputed geometry

  static final List<List<int>> _knightTargets = _jumps(const [
    [1, 2], [2, 1], [2, -1], [1, -2], [-1, -2], [-2, -1], [-2, 1], [-1, 2],
  ]);
  static final List<List<int>> _kingTargets = _jumps(const [
    [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1],
  ]);

  // Directions 0–3 orthogonal, 4–7 diagonal.
  static const List<List<int>> _dirs = [
    [0, 1], [0, -1], [1, 0], [-1, 0], [1, 1], [1, -1], [-1, 1], [-1, -1],
  ];
  static final List<List<List<int>>> _rays = [
    for (var sq = 0; sq < 64; sq++)
      [
        for (final d in _dirs)
          [
            for (var f = (sq & 7) + d[0], r = (sq >> 3) + d[1];
                f >= 0 && f < 8 && r >= 0 && r < 8;
                f += d[0], r += d[1])
              r * 8 + f,
          ],
      ],
  ];

  static List<List<int>> _jumps(List<List<int>> deltas) => [
        for (var sq = 0; sq < 64; sq++)
          [
            for (final d in deltas)
              if ((sq & 7) + d[0] >= 0 && (sq & 7) + d[0] < 8 && (sq >> 3) + d[1] >= 0 && (sq >> 3) + d[1] < 8)
                ((sq >> 3) + d[1]) * 8 + (sq & 7) + d[0],
          ],
      ];

  /// Castling rights kept when a piece moves from or to a square.
  static final List<int> _castleMask = [
    for (var sq = 0; sq < 64; sq++)
      switch (sq) { 0 => 15 & ~2, 4 => 15 & ~3, 7 => 15 & ~1, 56 => 15 & ~8, 60 => 15 & ~12, 63 => 15 & ~4, _ => 15 },
  ];

  // --------------------------------------------------------- move generation

  /// Whether [sq] is attacked by side [by] (1 White, -1 Black).
  bool _attacked(int sq, int by) {
    // Pawns of [by] attack diagonally forward, so they stand one rank behind.
    final pr = (sq >> 3) - by, f = sq & 7;
    if (pr >= 0 && pr < 8) {
      if (f > 0 && _b[pr * 8 + f - 1] == _p * by) return true;
      if (f < 7 && _b[pr * 8 + f + 1] == _p * by) return true;
    }
    for (final t in _knightTargets[sq]) {
      if (_b[t] == _n * by) return true;
    }
    for (final t in _kingTargets[sq]) {
      if (_b[t] == _k * by) return true;
    }
    final rays = _rays[sq];
    for (var d = 0; d < 8; d++) {
      final straight = d < 4;
      for (final t in rays[d]) {
        final p = _b[t];
        if (p == 0) continue;
        if (p == _q * by || p == (straight ? _r : _bishop) * by) return true;
        break;
      }
    }
    return false;
  }

  bool _inCheck() => _attacked(_kings[_stm == 1 ? 0 : 1], -_stm);

  void _addPawnMove(List<int> out, int from, int to, int flags) {
    final r = to >> 3;
    if (r == 7 || r == 0) {
      for (final p in const [_q, _r, _bishop, _n]) {
        out.add(_move(from, to, p, flags));
      }
    } else {
      out.add(_move(from, to, 0, flags));
    }
  }

  /// Pseudo-legal moves (own king may be left in check); castling is fully
  /// checked here.
  List<int> _generatePseudo() {
    final out = <int>[];
    final s = _stm;
    for (var sq = 0; sq < 64; sq++) {
      final p = _b[sq] * s;
      if (p <= 0) continue;
      switch (p) {
        case _p:
          final one = sq + 8 * s;
          if (_b[one] == 0) {
            _addPawnMove(out, sq, one, 0);
            final startRank = s == 1 ? 1 : 6;
            if (sq >> 3 == startRank && _b[one + 8 * s] == 0) out.add(_move(sq, one + 8 * s, 0, _fDouble));
          }
          final f = sq & 7;
          for (final df in const [-1, 1]) {
            if (f + df < 0 || f + df > 7) continue;
            final to = one + df;
            if (_b[to] * s < 0) {
              _addPawnMove(out, sq, to, 0);
            } else if (to == _ep) {
              out.add(_move(sq, to, 0, _fEp));
            }
          }
        case _n:
          for (final t in _knightTargets[sq]) {
            if (_b[t] * s <= 0) out.add(_move(sq, t));
          }
        case _k:
          for (final t in _kingTargets[sq]) {
            if (_b[t] * s <= 0) out.add(_move(sq, t));
          }
          _addCastling(out, sq);
        default:
          final rays = _rays[sq];
          final first = p == _bishop ? 4 : 0, last = p == _r ? 4 : 8;
          for (var d = first; d < last; d++) {
            for (final t in rays[d]) {
              final q = _b[t] * s;
              if (q > 0) break;
              out.add(_move(sq, t));
              if (q < 0) break;
            }
          }
      }
    }
    return out;
  }

  void _addCastling(List<int> out, int king) {
    final s = _stm;
    final home = s == 1 ? 4 : 60;
    if (king != home) return;
    final kingSide = s == 1 ? 1 : 4, queenSide = s == 1 ? 2 : 8;
    if (_castling & (kingSide | queenSide) == 0 || _attacked(home, -s)) return;
    if (_castling & kingSide != 0 &&
        _b[home + 1] == 0 &&
        _b[home + 2] == 0 &&
        _b[home + 3] == _r * s &&
        !_attacked(home + 1, -s) &&
        !_attacked(home + 2, -s)) {
      out.add(_move(home, home + 2, 0, _fCastle));
    }
    if (_castling & queenSide != 0 &&
        _b[home - 1] == 0 &&
        _b[home - 2] == 0 &&
        _b[home - 3] == 0 &&
        _b[home - 4] == _r * s &&
        !_attacked(home - 1, -s) &&
        !_attacked(home - 2, -s)) {
      out.add(_move(home, home - 2, 0, _fCastle));
    }
  }

  List<int> _generateLegal() {
    final out = <int>[];
    for (final m in _generatePseudo()) {
      _make(m);
      // After _make the mover is -_stm; its king must not be attacked by _stm.
      if (!_attacked(_kings[_stm == 1 ? 1 : 0], _stm)) out.add(m);
      _unmake(m);
    }
    return out;
  }

  // ------------------------------------------------------------ make / unmake

  void _make(int m) {
    final from = _from(m), to = _to(m), promo = _promo(m), flags = _flags(m);
    final s = _stm;
    final piece = _b[from];
    var captured = _b[to];
    _undo.add((captured + 8) | _castling << 4 | (_ep + 1) << 8 | _halfmove << 15);

    _b[to] = promo != 0 ? promo * s : piece;
    _b[from] = 0;
    if (flags & _fEp != 0) {
      final capSq = to - 8 * s;
      captured = _b[capSq];
      _b[capSq] = 0;
    } else if (flags & _fCastle != 0) {
      final rookFrom = to > from ? to + 1 : to - 2, rookTo = to > from ? to - 1 : to + 1;
      _b[rookTo] = _b[rookFrom];
      _b[rookFrom] = 0;
    }
    if (piece * s == _k) _kings[s == 1 ? 0 : 1] = to;
    _castling &= _castleMask[from] & _castleMask[to];
    _ep = flags & _fDouble != 0 ? from + 8 * s : -1;
    _halfmove = (piece * s == _p || captured != 0) ? 0 : _halfmove + 1;
    if (s == -1) _fullmove++;
    _stm = -s;
  }

  void _unmake(int m) {
    final from = _from(m), to = _to(m), promo = _promo(m), flags = _flags(m);
    final u = _undo.removeLast();
    final s = -_stm;
    _stm = s;
    if (s == -1) _fullmove--;
    final moved = promo != 0 ? _p * s : _b[to];
    _b[from] = moved;
    _b[to] = (u & 15) - 8;
    if (flags & _fEp != 0) {
      _b[to - 8 * s] = -_p * s;
    } else if (flags & _fCastle != 0) {
      final rookFrom = to > from ? to + 1 : to - 2, rookTo = to > from ? to - 1 : to + 1;
      _b[rookFrom] = _b[rookTo];
      _b[rookTo] = 0;
    }
    if (moved * s == _k) _kings[s == 1 ? 0 : 1] = from;
    _castling = (u >> 4) & 15;
    _ep = ((u >> 8) & 127) - 1;
    _halfmove = u >> 15;
  }

  // --------------------------------------------------------------- game end

  /// Recomputes the legal moves, records the position and decides the result.
  void _afterPositionChange() {
    _legal = _generateLegal();
    final key = _positionKey();
    final seen = (_seen[key] ?? 0) + 1;
    _seen[key] = seen;
    final mover = seatOf(_stm == 1 ? ChessColor.black : ChessColor.white);
    if (_legal.isEmpty) {
      _result = _inCheck()
          ? GameResult(winner: mover, reason: 'checkmate', code: GameEndReason.chessCheckmate)
          : const GameResult(draw: true, reason: 'stalemate', code: GameEndReason.chessStalemate);
    } else if (_insufficientMaterial()) {
      _result = const GameResult(
          draw: true, reason: 'insufficient material', code: GameEndReason.chessInsufficientMaterial);
    } else if (_halfmove >= 2 * moveRuleLimit) {
      _result = const GameResult(
          draw: true,
          reason: '$moveRuleLimit moves without capture or pawn move',
          code: GameEndReason.chessSeventyFiveMoves,
          params: {'moves': moveRuleLimit});
    } else if (seen >= repetitionLimit) {
      _result = const GameResult(
          draw: true,
          reason: 'threefold repetition',
          code: GameEndReason.chessThreefoldRepetition,
          params: {'times': repetitionLimit});
    } else {
      _result = const GameResult();
    }
  }

  /// Pieces, side to move, castling rights and a *legal* en passant capture.
  String _positionKey() {
    final epLegal = _legal.any((m) => _flags(m) & _fEp != 0);
    return '${_placement()} $_stm $_castling ${epLegal ? _ep : -1}';
  }

  bool _insufficientMaterial() {
    var minors = 0, knights = 0, bishopColours = 0;
    for (var sq = 0; sq < 64; sq++) {
      switch (_b[sq].abs()) {
        case _p || _r || _q:
          return false;
        case _n:
          minors++;
          knights++;
        case _bishop:
          minors++;
          bishopColours |= 1 << (((sq >> 3) + (sq & 7)) & 1);
      }
    }
    return minors <= 1 || (knights == 0 && bishopColours != 3);
  }

  // -------------------------------------------------------------------- SAN

  /// SAN of legal move [m] with its check / mate suffix.
  String _san(int m) {
    final base = _sanBase(m, _legal);
    _make(m);
    final check = _inCheck();
    final mate = check && _generateLegal().isEmpty;
    _unmake(m);
    return '$base${mate ? '#' : check ? '+' : ''}';
  }

  /// SAN of [m] without `+` / `#`, disambiguated against [legal].
  String _sanBase(int m, List<int> legal) {
    final from = _from(m), to = _to(m), flags = _flags(m), promo = _promo(m);
    if (flags & _fCastle != 0) return (to & 7) == 6 ? 'O-O' : 'O-O-O';
    final piece = _b[from].abs();
    final capture = _b[to] != 0 || flags & _fEp != 0;
    final b = StringBuffer();
    if (piece == _p) {
      if (capture) b.write(squareName(from)[0]);
    } else {
      b.write(_letters[piece].toUpperCase());
      final rivals = [
        for (final o in legal)
          if (_to(o) == to && _from(o) != from && _b[_from(o)].abs() == piece) _from(o),
      ];
      if (rivals.isNotEmpty) {
        final sameFile = rivals.any((r) => r & 7 == from & 7);
        final sameRank = rivals.any((r) => r >> 3 == from >> 3);
        if (!sameFile) {
          b.write(squareName(from)[0]);
        } else if (!sameRank) {
          b.write(squareName(from)[1]);
        } else {
          b.write(squareName(from));
        }
      }
    }
    if (capture) b.write('x');
    b.write(squareName(to));
    if (promo != 0) b.write('=${_letters[promo].toUpperCase()}');
    return b.toString();
  }

  // -------------------------------------------------------------------- FEN

  static ChessPiece? _pieceOf(int p) {
    if (p == 0) return null;
    return ChessPiece(p > 0 ? ChessColor.white : ChessColor.black, ChessPieceType.values[p.abs() - 1]);
  }

  String _placement() {
    final b = StringBuffer();
    for (var r = 7; r >= 0; r--) {
      var empty = 0;
      for (var f = 0; f < 8; f++) {
        final p = _b[r * 8 + f];
        if (p == 0) {
          empty++;
          continue;
        }
        if (empty > 0) b.write(empty);
        empty = 0;
        final l = _letters[p.abs()];
        b.write(p > 0 ? l.toUpperCase() : l);
      }
      if (empty > 0) b.write(empty);
      if (r > 0) b.write('/');
    }
    return b.toString();
  }

  String _castlingText() {
    final t = [
      if (_castling & 1 != 0) 'K',
      if (_castling & 2 != 0) 'Q',
      if (_castling & 4 != 0) 'k',
      if (_castling & 8 != 0) 'q',
    ].join();
    return t.isEmpty ? '-' : t;
  }

  void _loadFen(String fen) {
    Never bad(String why) => throw FormatException('Invalid FEN ($why)', fen);
    final parts = fen.split(RegExp(r'\s+'));
    if (parts.length != 4 && parts.length != 6) bad('expected 4 or 6 fields');

    final ranks = parts[0].split('/');
    if (ranks.length != 8) bad('expected 8 ranks');
    final kings = [0, 0];
    for (var i = 0; i < 8; i++) {
      final r = 7 - i;
      var f = 0;
      for (final c in ranks[i].split('')) {
        final digit = int.tryParse(c);
        if (digit != null) {
          if (digit < 1 || digit > 8) bad('bad digit "$c"');
          f += digit;
          continue;
        }
        final type = _letters.indexOf(c.toLowerCase());
        if (type <= 0) bad('bad piece "$c"');
        if (f > 7) bad('rank ${r + 1} too long');
        final white = c != c.toLowerCase();
        if (type == _p && (r == 0 || r == 7)) bad('pawn on rank ${r + 1}');
        if (type == _k) {
          kings[white ? 0 : 1]++;
          _kings[white ? 0 : 1] = r * 8 + f;
        }
        _b[r * 8 + f] = white ? type : -type;
        f++;
      }
      if (f != 8) bad('rank ${r + 1} has $f squares');
    }
    if (kings[0] != 1 || kings[1] != 1) bad('each side needs exactly one king');

    _stm = switch (parts[1]) { 'w' => 1, 'b' => -1, _ => bad('side to move must be w or b') };

    final c = parts[2];
    if (c != '-') {
      if (!RegExp(r'^K?Q?k?q?$').hasMatch(c) || c.isEmpty) bad('bad castling field "$c"');
      for (final (ch, bit) in const [('K', 1), ('Q', 2), ('k', 4), ('q', 8)]) {
        if (c.contains(ch)) _castling |= bit;
      }
    }
    // Drop rights whose king or rook is not at home.
    if (_b[4] != _k) _castling &= ~3;
    if (_b[7] != _r) _castling &= ~1;
    if (_b[0] != _r) _castling &= ~2;
    if (_b[60] != -_k) _castling &= ~12;
    if (_b[63] != -_r) _castling &= ~4;
    if (_b[56] != -_r) _castling &= ~8;

    if (parts[3] != '-') {
      final ep = squareIndex(parts[3]);
      if (ep == null) bad('bad en passant square "${parts[3]}"');
      // The pawn that just moved two squares stands in front of the target.
      final s = _stm;
      final pawnSq = ep - 8 * s, originSq = ep + 8 * s;
      if (ep >> 3 != (s == 1 ? 5 : 2) || _b[pawnSq] != -_p * s || _b[ep] != 0 || _b[originSq] != 0) {
        bad('en passant square "${parts[3]}" does not follow a double pawn push');
      }
      _ep = ep;
    }

    if (parts.length == 6) {
      final half = int.tryParse(parts[4]), full = int.tryParse(parts[5]);
      if (half == null || half < 0) bad('bad half-move clock');
      if (full == null || full < 1) bad('bad full-move number');
      _halfmove = half;
      _fullmove = full;
    }

    if (_attacked(_kings[_stm == 1 ? 1 : 0], _stm)) bad('the side not to move is in check');
  }
}

/// The six chess pieces; [letter] is the lower-case FEN / move letter.
enum ChessPieceType {
  pawn('p'),
  knight('n'),
  bishop('b'),
  rook('r'),
  queen('q'),
  king('k');

  final String letter;
  const ChessPieceType(this.letter);
}

/// The two sides of the board. Which player plays which colour is the
/// game's ([ChessGame.colorOf], [ChessGame.seatOf]).
enum ChessColor {
  white,
  black;

  ChessColor get opposite => this == white ? black : white;
}

/// What a network host chooses for its own colour when it starts a chess
/// room (KLD-059 step 4a). The host is always [Player.a]; [whitePlayer]
/// turns the choice into `GameConfig.chessWhite` before the game starts, so
/// the config carries the result and both devices create the same game.
enum ChessColorChoice {
  white,
  black,
  random;

  /// The player who plays White when the host ([Player.a]) chose this.
  /// [random] is decided by [seed] (the config's seed: even = the host plays
  /// White), so it is fixed once the config is: nothing is drawn later.
  Player whitePlayer(int seed) => switch (this) {
        white => Player.a,
        black => Player.b,
        random => seed.isEven ? Player.a : Player.b,
      };
}

/// A piece of [color].
class ChessPiece {
  final ChessColor color;
  final ChessPieceType type;
  const ChessPiece(this.color, this.type);

  bool get isWhite => color == ChessColor.white;

  /// FEN letter: upper case for White (`N`), lower case for Black (`n`).
  String get fen => isWhite ? type.letter.toUpperCase() : type.letter;

  @override
  bool operator ==(Object other) => other is ChessPiece && other.color == color && other.type == type;

  @override
  int get hashCode => Object.hash(color, type);

  @override
  String toString() => fen;
}
