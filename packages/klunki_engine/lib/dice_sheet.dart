import 'dart:math';

import 'game.dart';
import 'seats.dart';

/// The 13 boxes of the score sheet, upper section first. [id] is the name
/// used in moves (`{'action': 'score', 'box': 'fullHouse'}`).
enum DiceBox {
  ones(1),
  twos(2),
  threes(3),
  fours(4),
  fives(5),
  sixes(6),
  threeKind(0),
  fourKind(0),
  fullHouse(0),
  smallStraight(0),
  largeStraight(0),
  fiveKind(0),
  chance(0);

  /// The face an upper box counts (1–6); 0 for the lower boxes.
  final int face;
  const DiceBox(this.face);

  String get id => name;

  bool get upper => face > 0;

  static DiceBox? byId(Object? id) {
    for (final b in values) {
      if (b.name == id) return b;
    }
    return null;
  }

  /// The upper box for [face] (1–6).
  static DiceBox upperFor(int face) => values[face - 1];

  static List<DiceBox> get upperBoxes => values.sublist(0, 6);
  static List<DiceBox> get lowerBoxes => values.sublist(6);
}

/// "Ausgewürfelt" (KLD-119, id `dicesheet`): the five-dice score-sheet game
/// for 2–4 players (seats `0 … playerCount-1`, seat 0 starts).
///
/// * A turn: up to three rolls of five dice (`roll`). The first roll rolls
///   all five; before the second and third the player keeps any dice
///   (`keep`: their positions 0–4) and rolls the others again.
/// * After at least one roll the player fills exactly one empty box of
///   their sheet with what the dice give there (`score`); a box the dice do
///   not fit gets 0 (struck). Then the next seat rolls.
/// * Upper section: ones … sixes, the sum of the dice showing that face;
///   [upperBonus] (35) once the upper boxes add up to [upperBonusAt] (63) or
///   more. Lower section: three of a kind and four of a kind (the sum of all
///   dice), full house (three of one face and two of another, 25), small
///   straight (four in a row, 30), large straight (five in a row, 40), five
///   of a kind (50), chance (the sum of all dice).
/// * After 13 rounds every sheet is full: the highest total wins, equal
///   totals share the place ([SeatResult.placesFor]).
/// * House rule [extraFives] (off by default; JSON `extraFives`): another
///   five of a kind while the five-of-a-kind box already holds 50 earns
///   [extraFivesBonus] (100) on top; and whenever five of a kind is rolled
///   with that box already filled (50 or 0) it is a joker with a forced
///   choice: the upper box of its face if that is empty, else any empty
///   lower box at full value (full house 25, straights 30 / 40), else an
///   upper box with 0. Off: five of a kind is not a full house or a
///   straight, and there is no extra bonus.
/// * Who starts: seat 0, unless [randomStart] (JSON `start: random` in the
///   config, KLD-119 follow-up): then the seed draws the starting seat (the
///   first number of `Random(seed)`, before any dice). Then clockwise.
/// * Resign: two seats use the common resign (the other seat wins). With
///   3–4 seats `{'action': 'resign', 'seat': n}` lets seat `n` leave at any
///   time; the others play on, the last one in wins (`common.resigned`).
///
/// Deterministic: the dice come from `Random(seed)`. Every `roll` draws all
/// five values and uses only those of the positions rolled, so the draws
/// never depend on what was kept: "Zug zurück" plus another choice could
/// not fish for better dice. A roll is final anyway in the app ([isRoll] is
/// the hot-seat undo barrier); only a scoring can be taken back, until the
/// next player rolls. No hidden information: every player sees everything.
class DiceSheetGame extends Game implements SeatGame {
  static const int diceCount = 5;
  static const int maxRolls = 3;
  static const int upperBonusAt = 63;
  static const int upperBonus = 35;
  static const int fullHouseScore = 25;
  static const int smallStraightScore = 30;
  static const int largeStraightScore = 40;
  static const int fiveKindScore = 50;
  static const int extraFivesBonus = 100;

  /// Rounds per game: one box per round.
  static int get rounds => DiceBox.values.length;

  /// The rules as data, for the build fingerprint (`compat.dart`).
  static List<Object> gameplayData() => [
        [for (final b in DiceBox.values) b.id],
        [diceCount, maxRolls, upperBonusAt, upperBonus],
        [fullHouseScore, smallStraightScore, largeStraightScore, fiveKindScore, extraFivesBonus],
      ];

  @override
  final int playerCount;
  final bool extraFives;

  /// The seed picks the starting seat (else seat 0).
  final bool randomStart;

  /// The seat that started.
  late final int startSeat;

  final Random _rng;
  int _seat = 0;
  List<int> _dice = const [];
  int _rolls = 0;
  final List<Map<DiceBox, int>> _sheets;
  final List<int> _extraBonus;
  final List<int> _outOrder = [];
  bool _over = false;
  GameEndReason? _endCode;
  final List<List<int>> _scripted = [];
  final List<Map<String, dynamic>> _history = [];

  DiceSheetGame({int seed = 0, this.playerCount = 2, this.extraFives = false, this.randomStart = false})
      : _rng = Random(seed),
        _sheets = [for (var s = 0; s < playerCount; s++) <DiceBox, int>{}],
        _extraBonus = List.filled(playerCount, 0) {
    if (playerCount < 2 || playerCount > 4) throw ArgumentError.value(playerCount, 'playerCount', 'must be 2..4');
    startSeat = randomStart ? _rng.nextInt(playerCount) : 0;
    _seat = startSeat;
  }

  // ------------------------------------------------------------- scoring

  /// What [dice] score in [box] by the plain rules (no joker).
  static int scoreFor(DiceBox box, List<int> dice) {
    final counts = List.filled(7, 0);
    for (final d in dice) {
      counts[d]++;
    }
    final sum = dice.fold(0, (a, b) => a + b);
    final most = counts.reduce(max);
    bool run(int from, int len) => [for (var f = from; f < from + len; f++) counts[f] > 0].every((x) => x);
    return switch (box) {
      DiceBox.threeKind => most >= 3 ? sum : 0,
      DiceBox.fourKind => most >= 4 ? sum : 0,
      DiceBox.fullHouse => counts.contains(3) && counts.contains(2) ? fullHouseScore : 0,
      DiceBox.smallStraight => run(1, 4) || run(2, 4) || run(3, 4) ? smallStraightScore : 0,
      DiceBox.largeStraight => run(1, 5) || run(2, 5) ? largeStraightScore : 0,
      DiceBox.fiveKind => most == 5 ? fiveKindScore : 0,
      DiceBox.chance => sum,
      _ => counts[box.face] * box.face,
    };
  }

  static bool isFiveKind(List<int> dice) => dice.length == diceCount && dice.every((d) => d == dice.first);

  // ------------------------------------------------------------- state

  /// The seat to move (also once over: the seat that would be next).
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

  /// The dice on the table (empty before the turn's first roll).
  List<int> get dice => List.unmodifiable(_dice);

  /// Rolls made this turn (0–3).
  int get rollsUsed => _rolls;

  int get rollsLeft => maxRolls - _rolls;

  bool get canRoll => !isOver && _rolls < maxRolls;

  /// A box can be filled now: at least one roll this turn.
  bool get canScore => !isOver && _rolls > 0;

  /// The round of [seat] (1–13): its next box; 14 once its sheet is full.
  int roundOf(int seat) => _sheets[seat].length + 1;

  /// The current round (1–13) of the seat to move.
  int get round => min(roundOf(_seat), rounds);

  /// What [seat] wrote into [box], or null while it is empty.
  int? entryOf(int seat, DiceBox box) => _sheets[seat][box];

  bool isFilled(int seat, DiceBox box) => _sheets[seat].containsKey(box);

  bool sheetFull(int seat) => _sheets[seat].length == rounds;

  int upperSumOf(int seat) => [for (final b in DiceBox.upperBoxes) _sheets[seat][b] ?? 0].fold(0, (a, b) => a + b);

  /// 35 once [upperSumOf] reaches 63, else 0.
  int upperBonusOf(int seat) => upperSumOf(seat) >= upperBonusAt ? upperBonus : 0;

  int lowerSumOf(int seat) => [for (final b in DiceBox.lowerBoxes) _sheets[seat][b] ?? 0].fold(0, (a, b) => a + b);

  /// The [extraFives] bonus of [seat] so far (100 per extra five of a kind).
  int extraBonusOf(int seat) => _extraBonus[seat];

  int totalOf(int seat) => upperSumOf(seat) + upperBonusOf(seat) + lowerSumOf(seat) + extraBonusOf(seat);

  List<int> get totals => [for (var s = 0; s < playerCount; s++) totalOf(s)];

  /// The current roll is a joker ([extraFives]): five of a kind with the
  /// five-of-a-kind box already filled.
  bool get isJoker => extraFives && _rolls > 0 && isFiveKind(_dice) && isFilled(_seat, DiceBox.fiveKind);

  /// The current roll earns the extra bonus when scored ([extraFives]).
  bool get earnsExtraBonus => isJoker && entryOf(_seat, DiceBox.fiveKind) == fiveKindScore;

  /// The boxes the seat to move may fill now (empty before the first roll
  /// or once over); with a joker only the forced ones.
  List<DiceBox> get allowedBoxes {
    if (!canScore) return const [];
    final empty = [for (final b in DiceBox.values) if (!isFilled(_seat, b)) b];
    if (!isJoker) return empty;
    final own = DiceBox.upperFor(_dice.first);
    if (empty.contains(own)) return [own];
    final lower = empty.where((b) => !b.upper).toList();
    return lower.isNotEmpty ? lower : empty;
  }

  /// What filling [box] with the current dice would write for the seat to
  /// move (a joker counts full value in the lower boxes); null if [box] is
  /// not allowed now.
  int? scoreIfFilled(DiceBox box) {
    if (!allowedBoxes.contains(box)) return null;
    if (isJoker && !box.upper) {
      return switch (box) {
        DiceBox.fullHouse => fullHouseScore,
        DiceBox.smallStraight => smallStraightScore,
        DiceBox.largeStraight => largeStraightScore,
        _ => scoreFor(box, _dice),
      };
    }
    return scoreFor(box, _dice);
  }

  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  // ------------------------------------------------------------- results

  @override
  bool get isOver => resignedBy != null || _over;

  /// The outcome per seat: places by total (ties share), seats that left
  /// behind. With two seats a common resign gives the resigner place 2.
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
    return SeatResult(
        isOver: true,
        places: _endCode == GameEndReason.commonResigned
            ? SeatResult.placesFor(List.filled(playerCount, 0), out: _outOrder)
            : SeatResult.placesFor(totals, out: _outOrder),
        code: _endCode!.code,
        params: {
          for (var s = 0; s < playerCount; s++) 'score$s': totalOf(s),
          if (_endCode == GameEndReason.commonResigned) 'seat': _outOrder.last,
        },
        reason: playResult.reason);
  }

  /// The seats in first place once over (seats that left do not count).
  List<int> get winnerSeats {
    if (!_over) return const [];
    final active = activeSeats;
    if (_endCode == GameEndReason.commonResigned) return active;
    final best = active.map(totalOf).reduce(max);
    return [for (final s in active) if (totalOf(s) == best) s];
  }

  /// The two-player outcome. With 3–4 seats a winner in seat 2+ (or a
  /// shared first place) cannot be named as a [Player]: [GameResult.draw]
  /// is then true only to say that the game is over; use [seatResult].
  @override
  GameResult get playResult {
    if (!_over) return const GameResult();
    final w = winnerSeats;
    final winner = w.length == 1 && w.single < 2 ? Player.values[w.single] : null;
    final scoreText = [for (var s = 0; s < playerCount; s++) '${seatName(s)} ${totalOf(s)}'].join(', ');
    final why = _endCode == GameEndReason.commonResigned ? 'the others resigned' : 'all sheets full';
    return GameResult(
        winner: winner,
        draw: winner == null,
        reason: '$why; $scoreText',
        code: _endCode,
        params: {
          for (var s = 0; s < 2; s++) Player.values[s].name: totalOf(s),
          if (_endCode == GameEndReason.commonResigned) 'player': _outOrder.last,
        });
  }

  /// The engine's English name for [seat] (CLI, logs): Anna, Ben, P3, P4.
  static String seatName(int seat) => seat < 2 ? playerNameOf(Player.values[seat]) : 'P${seat + 1}';

  // ------------------------------------------------------------- moves

  /// A roll keeping the dice at [keep] (positions 0–4; empty on the first
  /// roll of a turn).
  static Map<String, dynamic> rollMove([Iterable<int> keep = const []]) =>
      {'action': 'roll', 'keep': (keep.toSet().toList()..sort())};

  static Map<String, dynamic> scoreMove(DiceBox box) => {'action': 'score', 'box': box.id};

  /// The resign move for [seat] in a game with 3–4 seats.
  static Map<String, dynamic> resignSeatMove(int seat) => {'action': 'resign', 'seat': seat};

  /// Whether [move] is a roll: hot-seat undo never takes a roll back (the
  /// dice were seen), see `GameSpec.undoBarrier`.
  static bool isRoll(Map<String, dynamic> move) => move['action'] == 'roll';

  /// Every legal move of the seat to move: the rolls (each choice of kept
  /// dice) and the boxes it may fill. Empty once over.
  List<Map<String, dynamic>> get legalMoves {
    if (isOver) return const [];
    return [
      if (_rolls == 0)
        rollMove()
      else if (_rolls < maxRolls)
        for (var mask = 0; mask < (1 << diceCount) - 1; mask++)
          rollMove([for (var i = 0; i < diceCount; i++) if (mask & (1 << i) != 0) i]),
      for (final b in allowedBoxes) scoreMove(b),
    ];
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
      'score' => _score(move),
      _ => null,
    };
  }

  GameEvent? _roll(Map<String, dynamic> move) {
    if (_rolls >= maxRolls || move.keys.any((k) => k != 'action' && k != 'keep')) return null;
    final raw = move['keep'] ?? const [];
    if (raw is! List) return null;
    final keep = <int>{};
    for (final k in raw) {
      if (k is! int || k < 0 || k >= diceCount || !keep.add(k)) return null;
    }
    if (_rolls == 0 ? keep.isNotEmpty : keep.length == diceCount) return null;
    // All five drawn every time (see the class docs).
    final drawn = _scripted.isNotEmpty
        ? _scripted.removeAt(0)
        : [for (var i = 0; i < diceCount; i++) _rng.nextInt(6) + 1];
    _dice = [for (var i = 0; i < diceCount; i++) keep.contains(i) ? _dice[i] : drawn[i]];
    _rolls++;
    _history.add({'action': 'roll', 'keep': (keep.toList()..sort()), 'seat': _seat, 'dice': List.of(_dice)});
    return GameEvent(payload: {'rolled': List.of(_dice), 'kept': (keep.toList()..sort()), 'rolls': _rolls});
  }

  GameEvent? _score(Map<String, dynamic> move) {
    final box = DiceBox.byId(move['box']);
    if (box == null || move.length != 2) return null;
    final points = scoreIfFilled(box);
    if (points == null) return null;
    final bonus = earnsExtraBonus ? extraFivesBonus : 0;
    final seat = _seat;
    _sheets[seat][box] = points;
    _extraBonus[seat] += bonus;
    _history.add({'action': 'score', 'box': box.id, 'seat': seat, 'points': points, if (bonus > 0) 'bonus': bonus});
    _dice = const [];
    _rolls = 0;
    _advance();
    return _event({'scored': box.id, 'seat': seat, 'points': points, if (bonus > 0) 'bonus': bonus});
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
      _dice = const [];
      _rolls = 0;
      _advance();
    } else {
      _checkEnd();
    }
    return _event({'resigned': seat});
  }

  /// Passes the turn to the next seat still in that has empty boxes, or
  /// ends the game when every sheet still in is full.
  void _advance() {
    if (_checkEnd()) return;
    var s = _seat;
    do {
      s = (s + 1) % playerCount;
    } while (isSeatOut(s) || sheetFull(s));
    _seat = s;
  }

  bool _checkEnd() {
    if (activeSeats.every(sheetFull)) {
      _over = true;
      _endCode = GameEndReason.dicesheetAllFilled;
    }
    return _over;
  }

  GameEvent _event(Map<String, dynamic> payload) {
    final r = playResult;
    return GameEvent(winner: r.winner, draw: r.draw, payload: payload);
  }

  /// Tests, demos and screenshots only: the next `roll` moves draw these
  /// five values (each 1–6, used for the positions rolled) before the
  /// seeded ones. Not part of the config: a replay rolls from the seed.
  void debugScriptRolls(List<List<int>> rolls) {
    for (final r in rolls) {
      if (r.length != diceCount || r.any((d) => d < 1 || d > 6)) {
        throw ArgumentError.value(r, 'rolls', 'five dice 1–6');
      }
      _scripted.add(List.of(r));
    }
  }

  /// The whole state as JSON (logs, tests): nothing is secret.
  Map<String, dynamic> toJson() => {
        'players': playerCount,
        if (extraFives) 'extraFives': true,
        if (startSeat != 0) 'start': startSeat,
        'seat': _seat,
        'rolls': _rolls,
        'dice': List.of(_dice),
        'sheets': [
          for (var s = 0; s < playerCount; s++) {for (final e in _sheets[s].entries) e.key.id: e.value}
        ],
        if (_extraBonus.any((b) => b > 0)) 'extra': List.of(_extraBonus),
        'totals': totals,
        if (_outOrder.isNotEmpty) 'out': List.of(_outOrder),
        if (resignedBy != null) 'resigned': resignedBy!.name,
        if (_over) 'over': _endCode!.code,
      };
}
