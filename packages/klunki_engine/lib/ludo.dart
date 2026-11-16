import 'game.dart';
import 'prng.dart';
import 'seats.dart';

/// The house rules of "Rauswurf" (KLD-131), all on by default (the
/// maintainer's table rules). JSON key `ludo` in [GameConfig] with only the
/// switches that differ from the defaults.
class LudoRules {
  /// Three tries for a 6 while no pawn can move without one (all pawns in
  /// the house, or the rest stuck at the end of the finish lane).
  final bool threeTries;

  /// "Schlagzwang": if a move can capture, one of the capturing moves must
  /// be made (a filter on the legal moves, no penalty).
  final bool mustCapture;

  /// "Startfeld räumen": while pawns wait in the house, a pawn on the own
  /// start field must leave it first (if it can move).
  final bool clearStart;

  /// A 6 lets the same player roll again.
  final bool sixAgain;

  const LudoRules({this.threeTries = true, this.mustCapture = true, this.clearStart = true, this.sixAgain = true});

  bool get isDefault => this == const LudoRules();

  /// Only the switches that differ from the defaults (`{}` for the
  /// defaults).
  Map<String, dynamic> toJson() => {
        if (!threeTries) 'tries': false,
        if (!mustCapture) 'capture': false,
        if (!clearStart) 'start': false,
        if (!sixAgain) 'six': false,
      };

  factory LudoRules.fromJson(Object? json) {
    if (json is! Map) return const LudoRules();
    return LudoRules(
      threeTries: json['tries'] != false,
      mustCapture: json['capture'] != false,
      clearStart: json['start'] != false,
      sixAgain: json['six'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LudoRules &&
      other.threeTries == threeTries &&
      other.mustCapture == mustCapture &&
      other.clearStart == clearStart &&
      other.sixAgain == sixAgain;

  @override
  int get hashCode => Object.hash(threeTries, mustCapture, clearStart, sixAgain);

  @override
  String toString() => 'LudoRules(${toJson()})';
}

/// A pawn that a move sends home: its seat and pawn number.
typedef LudoPawnRef = ({int seat, int pawn});

/// One possible pawn move for the die on the table.
class LudoMoveOption {
  final int pawn;

  /// Progress before and after (see [LudoGame.progressOf]).
  final int from;
  final int to;

  /// The pawn of another seat this move sends home, or null.
  final LudoPawnRef? captures;
  const LudoMoveOption(this.pawn, this.from, this.to, this.captures);
}

/// "Rauswurf" (KLD-131, id `ludo`; en "Ludo"): the cross-and-circle race
/// game for 2–4 players (seats `0 … playerCount-1`, seat 0 starts).
///
/// * The board: a track of [trackLength] (40) fields, four corners with a
///   house of four pawns, a start field and a finish lane of [laneLength]
///   (4) fields each. Seat `s` plays corner [cornerOf] (two players sit
///   opposite: corners 0 and 2). The start field of corner `c` is track
///   field `10·c`; a pawn walks once round the track (fields 0–39 counted
///   from its own start) and then into its finish lane (40–43).
/// * Progress of a pawn ([progressOf]): -1 in the house, 0–39 on the track
///   (steps from the own start field), 40–43 in the finish lane.
/// * A turn: `roll` the die. With a legal pawn move the player picks one
///   (`move` with `pawn` 0–3); without one the roll is spent: another try
///   or the next seat (no extra move needed).
/// * A 6 brings a pawn out of the house onto the free own start field; this
///   is compulsory while pawns wait in the house and the start field is not
///   held by an own pawn. A pawn landing on another seat's pawn sends it
///   home ("Rauswurf"); it can never land on an own pawn. Pawns jump over
///   pawns on the track, but never over a pawn in the finish lane, and the
///   finish lane needs the exact number.
/// * House rules ([LudoRules], all on): three tries for a 6 while nothing
///   can move without one; Schlagzwang; Startfeld räumen; a 6 rolls again
///   (also a 6 that cannot be moved). Startfeld räumen uses the classic
///   blocker rule: if the start pawn's target holds an own pawn, that pawn
///   must move instead (along the chain, see [startClearing]).
/// * The order of the move filters: Startfeld räumen, then bringing out on
///   a 6 (both leave only one kind of move), then Schlagzwang among what is
///   left.
/// * The first seat with all four pawns in the finish lane wins; the others
///   rank by their pawns in the finish lane (equal counts share a place).
/// * Resign: two seats use the common resign (the other seat wins). With
///   3–4 seats `{'action': 'resign', 'seat': n}` lets seat `n` leave at any
///   time: its pawns leave the board, the others play on, the last one in
///   wins (`common.resigned`).
///
/// Deterministic: the die comes from `GameRandom(seed)`, one draw per roll.
/// A roll is final in the app ([isRoll] is the hot-seat undo barrier); a
/// pawn move can be taken back until the next roll. No hidden information.
class LudoGame extends Game implements SeatGame {
  static const int trackLength = 40;
  static const int laneLength = 4;
  static const int pawns = 4;
  static const int corners = 4;
  static const int maxPlayers = 4;

  /// The track fields between two start fields.
  static const int cornerStep = trackLength ~/ corners;

  /// Progress of a pawn in the house.
  static const int house = -1;

  /// The first and the last progress of the finish lane.
  static const int laneStart = trackLength;
  static const int goal = trackLength + laneLength - 1;

  /// Failed rolls allowed for a 6 when nothing can move without one.
  static const int sixTries = 3;

  /// The rules as data, for the build fingerprint (`compat.dart`).
  static List<Object> gameplayData() => [
        [trackLength, laneLength, pawns, corners, sixTries],
        [for (var n = 2; n <= maxPlayers; n++) cornersFor(n)],
      ];

  /// The corners used by [playerCount] seats: two sit opposite.
  static List<int> cornersFor(int playerCount) => playerCount == 2 ? const [0, 2] : [for (var c = 0; c < playerCount; c++) c];

  @override
  final int playerCount;
  final LudoRules rules;

  final GameRandom _rng;
  final List<List<int>> _pos;
  int _seat = 0;
  int? _die;
  int _tries = 0;
  ({int seat, int value})? _lastRoll;
  final List<int> _outOrder = [];
  bool _over = false;
  GameEndReason? _endCode;
  final List<int> _scripted = [];
  final List<Map<String, dynamic>> _history = [];

  LudoGame({int seed = 0, this.playerCount = 2, this.rules = const LudoRules()})
      : _rng = GameRandom(seed),
        _pos = [for (var s = 0; s < playerCount; s++) List.filled(pawns, house)] {
    if (playerCount < 2 || playerCount > maxPlayers) {
      throw ArgumentError.value(playerCount, 'playerCount', 'must be 2..$maxPlayers');
    }
  }

  // ------------------------------------------------------------- geometry

  /// The corner (0–3) of [seat].
  int cornerOf(int seat) => cornersFor(playerCount)[seat];

  /// The track field (0–39) of a pawn of [seat] with [progress] 0–39.
  int trackFieldOf(int seat, int progress) => (cornerOf(seat) * cornerStep + progress) % trackLength;

  /// The progress of [seat]'s pawn [pawn]: -1 house, 0–39 track, 40–43 lane.
  int progressOf(int seat, int pawn) => _pos[seat][pawn];

  /// All progress values of [seat] (a copy).
  List<int> pawnsOf(int seat) => List.of(_pos[seat]);

  /// Pawns of [seat] in the finish lane.
  int homeCount(int seat) => _pos[seat].where((p) => p >= laneStart).length;

  /// Pawns of [seat] in the house.
  int houseCount(int seat) => _pos[seat].where((p) => p == house).length;

  /// The pawn of a seat still in on track field [field], or null.
  LudoPawnRef? pawnOnField(int field) {
    for (var s = 0; s < playerCount; s++) {
      if (isSeatOut(s)) continue;
      for (var i = 0; i < pawns; i++) {
        final p = _pos[s][i];
        if (p >= 0 && p < trackLength && trackFieldOf(s, p) == field) return (seat: s, pawn: i);
      }
    }
    return null;
  }

  bool _ownAt(int seat, int progress) => _pos[seat].contains(progress);

  // ------------------------------------------------------------- state

  /// The seat to move (also once over: the seat that moved last).
  int get currentSeat => _seat;

  @override
  int? get actorSeat => isOver ? null : _seat;

  @override
  Player get currentPlayer =>
      _seat < 2 ? Player.values[_seat] : (throw StateError('seat $_seat has no Player (more than 2 seats, KLD-088)'));

  @override
  int seatOfMove(Map<String, dynamic> move) {
    if (move['action'] == 'resign') {
      final s = playerCount == 2 ? Game.resignerOf(move)?.index : move['seat'];
      if (s is int) return s;
    }
    return _seat;
  }

  @override
  bool isSeatOut(int seat) => _outOrder.contains(seat);

  /// The seats that resigned, in the order they left (3–4 seats).
  List<int> get outSeats => List.unmodifiable(_outOrder);

  /// The seats still in, in seat order.
  List<int> get activeSeats => [for (var s = 0; s < playerCount; s++) if (!isSeatOut(s)) s];

  /// The die waiting for a pawn move, or null when the seat must roll.
  int? get die => _die;

  /// The seat must roll now.
  bool get mustRoll => !isOver && _die == null;

  /// The last roll (seat and value), also one that was spent without a move.
  ({int seat, int value})? get lastRoll => _lastRoll;

  /// Failed rolls of the seat to move in this turn so far.
  int get triesUsed => _tries;

  /// How many failed rolls the seat to move has in all (3 while it cannot
  /// move without a 6 and [LudoRules.threeTries] is on, else 1).
  int get triesAllowed => rules.threeTries && needsSix(_seat) ? sixTries : 1;

  /// True if no pawn of [seat] can move with 1–5: only a 6 helps.
  bool needsSix(int seat) {
    for (var v = 1; v <= 5; v++) {
      if (_candidates(seat, v).isNotEmpty) return false;
    }
    return true;
  }

  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  // ------------------------------------------------------------- moves

  /// Where pawn [pawn] of [seat] would go with [value], ignoring the house
  /// rules' filters; null if it cannot move.
  int? _target(int seat, int pawn, int value) {
    final p = _pos[seat][pawn];
    if (p == house) {
      if (value != 6 || _ownAt(seat, 0)) return null;
      return 0;
    }
    final t = p + value;
    if (t > goal) return null;
    if (t < laneStart) return _ownAt(seat, t) ? null : t;
    // Into or inside the finish lane: never jump over a pawn there.
    for (var q = (p < laneStart ? laneStart : p + 1); q <= t; q++) {
      if (_ownAt(seat, q)) return null;
    }
    return t;
  }

  List<LudoMoveOption> _candidates(int seat, int value) => [
        for (var i = 0; i < pawns; i++)
          if (_target(seat, i, value) case final t?)
            LudoMoveOption(i, _pos[seat][i], t, t < laneStart ? _victim(seat, t) : null),
      ];

  LudoPawnRef? _victim(int seat, int progress) {
    final hit = pawnOnField(trackFieldOf(seat, progress));
    return hit == null || hit.seat == seat ? null : hit;
  }

  /// The moves [seat] may make with [value], after the house rules'
  /// filters (see the class docs for the order).
  List<LudoMoveOption> optionsFor(int seat, int value) {
    var options = _candidates(seat, value);
    if (options.isEmpty) return options;
    final waiting = houseCount(seat) > 0;
    if (rules.clearStart && waiting) {
      final clear = _startChain(seat, value, options);
      if (clear != null) return [clear];
    }
    if (value == 6 && waiting) {
      final out = options.where((o) => o.from == house).toList();
      if (out.isNotEmpty) return out;
    }
    if (rules.mustCapture) {
      final hits = options.where((o) => o.captures != null).toList();
      if (hits.isNotEmpty) return hits;
    }
    return options;
  }

  /// "Startfeld räumen" with the classic blocker rule: the pawn on the own
  /// start field must move; if its target holds an own pawn, that pawn must
  /// move instead, and so on along the chain. The first pawn of the chain
  /// that can move ([options], unfiltered) is the only legal move; null if
  /// no pawn is on the start field or nobody in the chain can move (then
  /// the normal moves apply).
  LudoMoveOption? _startChain(int seat, int value, List<LudoMoveOption> options) {
    var p = 0;
    while (_ownAt(seat, p)) {
      final pawn = _pos[seat].indexOf(p);
      final o = options.where((o) => o.pawn == pawn).firstOrNull;
      if (o != null) return o;
      final t = p + value;
      if (t >= laneStart || !_ownAt(seat, t)) return null;
      p = t;
    }
    return null;
  }

  /// The move "Startfeld räumen" forces now (the start pawn or a blocker in
  /// its chain), or null.
  LudoMoveOption? get startClearing {
    final d = _die;
    if (d == null || isOver || !rules.clearStart || houseCount(_seat) == 0) return null;
    return _startChain(_seat, d, _candidates(_seat, d));
  }

  /// The moves for the die on the table (empty while the seat must roll).
  List<LudoMoveOption> get options => _die == null || isOver ? const [] : optionsFor(_seat, _die!);

  /// The pawns the seat to move may move now.
  List<int> get movablePawns => [for (final o in options) o.pawn];

  static const Map<String, dynamic> rollMove = {'action': 'roll'};

  static Map<String, dynamic> pawnMove(int pawn) => {'action': 'move', 'pawn': pawn};

  /// The resign move for [seat] in a game with 3–4 seats.
  static Map<String, dynamic> resignSeatMove(int seat) => {'action': 'resign', 'seat': seat};

  /// Whether [move] is a roll: hot-seat undo never takes a roll back (the
  /// die was seen), see `GameSpec.undoBarrier`.
  static bool isRoll(Map<String, dynamic> move) => move['action'] == 'roll';

  /// Every legal move of the seat to move. Empty once over.
  List<Map<String, dynamic>> get legalMoves {
    if (isOver) return const [];
    if (_die == null) return const [rollMove];
    return [for (final o in options) pawnMove(o.pawn)];
  }

  @override
  GameEvent? applyMove(Map<String, dynamic> move) {
    if (playerCount == 2 || move['action'] != 'resign') return super.applyMove(move);
    return _resignSeat(move);
  }

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) {
    if (_over) return null;
    return switch (move['action']) {
      'roll' => _roll(move),
      'move' => _move(move),
      _ => null,
    };
  }

  GameEvent? _roll(Map<String, dynamic> move) {
    if (_die != null || move.length != 1) return null;
    final seat = _seat;
    final value = _scripted.isNotEmpty ? _scripted.removeAt(0) : _rng.nextInt(6) + 1;
    _lastRoll = (seat: seat, value: value);
    final moves = optionsFor(seat, value);
    final payload = <String, dynamic>{'rolled': value, 'seat': seat};
    if (moves.isNotEmpty) {
      _die = value;
      payload['pawns'] = [for (final o in moves) o.pawn];
    } else if (value == 6 && rules.sixAgain) {
      // A 6 that cannot move: still another roll.
      _tries = 0;
      payload['again'] = true;
    } else {
      _tries++;
      if (_tries < triesAllowed) {
        payload['again'] = true;
        payload['tries'] = triesAllowed - _tries;
      } else {
        _next();
        payload['passed'] = true;
      }
    }
    _history.add({'action': 'roll', 'seat': seat, 'die': value});
    return GameEvent(payload: payload);
  }

  GameEvent? _move(Map<String, dynamic> move) {
    final die = _die;
    final pawn = move['pawn'];
    if (die == null || move.length != 2 || pawn is! int) return null;
    final seat = _seat;
    final option = optionsFor(seat, die).where((o) => o.pawn == pawn).firstOrNull;
    if (option == null) return null;
    final hit = option.captures;
    if (hit != null) _pos[hit.seat][hit.pawn] = house;
    _pos[seat][pawn] = option.to;
    _die = null;
    _tries = 0;
    final payload = <String, dynamic>{
      'seat': seat,
      'pawn': pawn,
      'from': option.from,
      'to': option.to,
      if (hit != null) 'captured': {'seat': hit.seat, 'pawn': hit.pawn},
    };
    _history.add({'action': 'move', 'pawn': pawn, 'seat': seat, 'die': die, 'from': option.from, 'to': option.to,
      if (hit != null) 'captured': [hit.seat, hit.pawn]});
    if (homeCount(seat) == pawns) {
      _over = true;
      _endCode = GameEndReason.ludoAllHome;
    } else if (die == 6 && rules.sixAgain) {
      payload['again'] = true;
    } else {
      _next();
    }
    return _event(payload);
  }

  GameEvent? _resignSeat(Map<String, dynamic> move) {
    final seat = move['seat'];
    if (isOver || move.length != 2 || seat is! int || seat < 0 || seat >= playerCount || isSeatOut(seat)) return null;
    _outOrder.add(seat);
    _history.add({'action': 'resign', 'seat': seat});
    if (activeSeats.length == 1) {
      _over = true;
      _endCode = GameEndReason.commonResigned;
    } else if (_seat == seat) {
      _next();
    }
    return _event({'resigned': seat});
  }

  /// The next seat still in rolls; a fresh turn.
  void _next() {
    _die = null;
    _tries = 0;
    var s = _seat;
    do {
      s = (s + 1) % playerCount;
    } while (isSeatOut(s));
    _seat = s;
  }

  GameEvent _event(Map<String, dynamic> payload) {
    final r = playResult;
    return GameEvent(winner: r.winner, draw: r.draw, payload: payload);
  }

  // ------------------------------------------------------------- results

  @override
  bool get isOver => resignedBy != null || _over;

  /// The seat that brought all four pawns home, or null.
  int? get winnerSeat => _endCode == GameEndReason.ludoAllHome
      ? _seat
      : _endCode == GameEndReason.commonResigned
          ? activeSeats.single
          : null;

  /// Places by pawns in the finish lane (the winner has all four); seats
  /// that left rank behind. With two seats a common resign gives the
  /// resigner place 2.
  @override
  SeatResult get seatResult {
    final resigner = resignedBy;
    if (resigner != null) {
      return SeatResult(
          isOver: true,
          places: [for (var s = 0; s < playerCount; s++) s == resigner.index ? 2 : 1],
          code: GameEndReason.commonResigned.code,
          params: {'seat': resigner.index},
          reason: '${seatName(resigner.index)} resigned');
    }
    if (!_over) return const SeatResult();
    final resigned = _endCode == GameEndReason.commonResigned;
    return SeatResult(
        isOver: true,
        places: resigned
            ? SeatResult.placesFor(List.filled(playerCount, 0), out: _outOrder)
            : SeatResult.placesFor([for (var s = 0; s < playerCount; s++) homeCount(s)], out: _outOrder),
        code: _endCode!.code,
        params: {
          for (var s = 0; s < playerCount; s++) 'home$s': homeCount(s),
          if (resigned) 'seat': _outOrder.last,
        },
        reason: playResult.reason);
  }

  /// The two-player outcome. With 3–4 seats a winner in seat 2+ cannot be
  /// named as a [Player]: [GameResult.draw] is then true only to say that
  /// the game is over; use [seatResult].
  @override
  GameResult get playResult {
    if (!_over) return const GameResult();
    final w = winnerSeat!;
    final winner = w < 2 ? Player.values[w] : null;
    final why = _endCode == GameEndReason.commonResigned
        ? 'the others resigned'
        : '${seatName(w)} has all pawns home';
    return GameResult(
        winner: winner,
        draw: winner == null,
        reason: why,
        code: _endCode,
        params: {
          for (var s = 0; s < 2; s++) Player.values[s].name: homeCount(s),
          if (_endCode == GameEndReason.commonResigned) 'player': _outOrder.last,
        });
  }

  /// The engine's English name for [seat] (CLI, logs): Anna, Ben, P3, P4.
  static String seatName(int seat) => seat < 2 ? playerNameOf(Player.values[seat]) : 'P${seat + 1}';

  // ------------------------------------------------------------- debug

  /// Tests, demos and screenshots only: the next rolls give these values
  /// (1–6) before the seeded ones. Not part of the config: a replay rolls
  /// from the seed.
  void debugScriptRolls(List<int> values) {
    for (final v in values) {
      if (v < 1 || v > 6) throw ArgumentError.value(v, 'values', 'die values 1–6');
      _scripted.add(v);
    }
  }

  /// Tests only: puts the pawns of every seat at [progress] (per seat four
  /// values, -1 house, 0–43) and gives the turn to [seat] (to roll).
  void debugSetPawns(List<List<int>> progress, {int seat = 0}) {
    if (progress.length != playerCount || progress.any((p) => p.length != pawns || p.any((x) => x < house || x > goal))) {
      throw ArgumentError.value(progress, 'progress', 'four values -1..$goal per seat');
    }
    for (var s = 0; s < playerCount; s++) {
      _pos[s].setAll(0, progress[s]);
    }
    _seat = seat;
    _die = null;
    _tries = 0;
  }

  /// The whole state as JSON (logs, tests): nothing is secret.
  Map<String, dynamic> toJson() => {
        'players': playerCount,
        if (!rules.isDefault) 'rules': rules.toJson(),
        'seat': _seat,
        if (_die != null) 'die': _die,
        if (_tries > 0) 'tries': _tries,
        'pawns': [for (final p in _pos) List.of(p)],
        if (_outOrder.isNotEmpty) 'out': List.of(_outOrder),
        if (resignedBy != null) 'resigned': resignedBy!.name,
        if (_over) 'over': _endCode!.code,
      };
}
