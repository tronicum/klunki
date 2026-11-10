import 'dart:math';

import 'game.dart';
import 'seats.dart';
import 'secrecy.dart';

part 'maexchen_view.dart';

/// What the player to move has to do in a Mäxchen game.
enum MaexchenPhase {
  /// Shake the cup (`roll`): at the start of a round, or after believing.
  roll,

  /// Announce a value (`announce`) that beats the round's announcement; the
  /// player who rolled may lie.
  announce,

  /// The next player answers the announcement: `believe`, `doubt`, or, after
  /// an announced Mäxchen, `giveUp`.
  respond,
}

/// How a round ended (public once it ended): after a doubt the dice were
/// shown, after a give-up they stay hidden.
class MaexchenRoundEnd {
  /// The round that ended (1-based).
  final int round;

  /// The value announced last.
  final int announced;

  /// The seat that announced it.
  final int announcer;

  /// The seat that doubted or gave up.
  final int challenger;

  /// True if the challenger gave up after a Mäxchen (no dice shown).
  final bool gaveUp;

  /// The dice under the cup, as rolled; null after a give-up.
  final List<int>? dice;

  /// The seat that lost lives, and how many (1, or 2 for a doubted true
  /// Mäxchen with [MaexchenGame.maexchenDouble]).
  final int loser;
  final int lost;

  const MaexchenRoundEnd({
    required this.round,
    required this.announced,
    required this.announcer,
    required this.challenger,
    required this.gaveUp,
    required this.dice,
    required this.loser,
    required this.lost,
  });

  /// The real value under the cup (null after a give-up).
  int? get value => dice == null ? null : MaexchenGame.valueOf(dice![0], dice![1]);

  /// True if the announcement was a lie that a doubt caught.
  bool get bluff => !gaveUp && MaexchenGame.rankOf(value!) < MaexchenGame.rankOf(announced);

  Map<String, dynamic> toJson() => {
        'round': round,
        'announced': announced,
        'announcer': announcer,
        'challenger': challenger,
        if (gaveUp) 'gaveUp': true,
        if (dice != null) 'dice': List.of(dice!),
        'loser': loser,
        'lost': lost,
      };

  static MaexchenRoundEnd fromJson(Object? j) {
    if (j is! Map) throw BadViewException('bad round end $j');
    final dice = j['dice'];
    return MaexchenRoundEnd(
      round: j['round'] as int,
      announced: j['announced'] as int,
      announcer: j['announcer'] as int,
      challenger: j['challenger'] as int,
      gaveUp: j['gaveUp'] == true,
      dice: dice == null ? null : (dice as List).cast<int>(),
      loser: j['loser'] as int,
      lost: j['lost'] as int,
    );
  }
}

/// Mäxchen (also called Meiern): the dice bluffing game, KLD-121.
///
/// * Two dice under a cup, read with the higher die first: 3 and 1 is 31.
///   Order from low to high: 31, 32, 41, 42, 43, 51 … 54, 61 … 65, then the
///   doubles 11, 22 … 66, then 21, "Mäxchen", the highest ([ranking]).
/// * A turn: `roll` (only the roller sees the dice), then `announce` a value
///   that beats the round's last announcement. It may be a lie.
/// * The next player answers: `believe` (takes the cup, rolls again and must
///   announce higher), or `doubt`: the dice are shown; if they are lower
///   than announced the announcer loses a life, otherwise the doubter does.
/// * An announced Mäxchen cannot be beaten: the next player doubts or gives
///   up (`giveUp`: loses one life, the dice stay hidden). With
///   [maexchenDouble] (on by default) everything about an announced
///   Mäxchen counts double: a doubted real one costs the doubter 2 lives, a
///   caught fake one costs the bluffer 2 lives.
/// * A doubt or a give-up ends the round for good: hot-seat "Zug zurücknehmen"
///   never goes back across it ([endsRound], `GameSpec.undoBarrier`).
/// * After a doubt or a give-up a new round starts with the player who lost
///   the life (the next one in turn if that player is out).
/// * Every player starts with [startLives] lives; a player with none left is
///   out and skipped: the cup always passes to the next seat still in. The
///   last one with lives wins; the others rank by the order they went out
///   (the one who went out last is second).
/// * Rule variant "Unbegrenzte Leben" ([unlimitedLives], KLD-121 step 2,
///   off by default): nobody drops out. Every lost life is counted
///   ([lostOf]); the game goes on until the players end it (`end`, any time,
///   [endMove]); then the fewest lives lost wins, equal counts share a
///   place. [startLives] does not matter then.
///
/// Seats (KLD-121 step 2): 2–4 seats (`0 … playerCount-1`, seat 0 is
/// [Player.a], seat 1 [Player.b]); the game is a [SeatGame], so 3–4 seats
/// are played through the seat API ([actorSeat], [seatResult]; seats 2+
/// have no [Player], [currentPlayer] throws for them). With 3–4 seats a
/// resign names a seat (`{'action': 'resign', 'seat': n}`): that seat is
/// out, a round under way is dropped without a loser and starts again, the
/// others play on. Two seats are the game as before (same moves, rolls,
/// events and views), the network session is 2-player.
///
/// Deterministic: the dice come from `Random(seed)`, two draws per `roll`,
/// so config + seed + moves is a full replay. The seed is secret over the
/// network ([MaexchenRedaction.secretSeed]): it decides every roll.
class MaexchenGame extends Game implements SeatGame {
  /// All values from lowest to highest.
  static const List<int> ranking = [
    31, 32, 41, 42, 43, 51, 52, 53, 54, 61, 62, 63, 64, 65, //
    11, 22, 33, 44, 55, 66, //
    21,
  ];

  /// The highest value, "Mäxchen".
  static const int maexchen = 21;

  /// Lives to choose from at the start (the engine takes 1 to 9).
  static const List<int> livesOptions = [3, 5];

  static const int defaultLives = 3;

  /// The value of a roll: the higher die first (5 and 3 is 53), a double is
  /// 11 … 66, 2 and 1 is Mäxchen (21).
  static int valueOf(int d1, int d2) {
    final hi = max(d1, d2), lo = min(d1, d2);
    return hi * 10 + lo;
  }

  /// Position of [value] in [ranking] (0 = 31, 20 = Mäxchen); -1 if it is
  /// no value.
  static int rankOf(int value) => ranking.indexOf(value);

  static bool isValue(Object? v) => v is int && ranking.contains(v);

  /// Whether [a] beats [b].
  static bool beats(int a, int b) => rankOf(a) > rankOf(b);

  static bool isDouble(int value) => value != maexchen && value % 11 == 0;

  /// The values that beat [announced] (all of them when null), low to high.
  static List<int> valuesAbove(int? announced) =>
      announced == null ? List.of(ranking) : ranking.sublist(rankOf(announced) + 1);

  final int startLives;

  /// House rule "Mäxchen doppelt" (maintainer decision 2026-11-06): an
  /// announced Mäxchen counts double both ways: doubted and real, the
  /// doubter loses 2 lives; doubted and fake, the bluffer loses 2.
  final bool maexchenDouble;

  /// Rule variant "Unbegrenzte Leben": nobody drops out, lost lives are
  /// counted, the players end the game ([endMove]).
  final bool unlimitedLives;

  /// The most seats (KLD-121 step 2: 2–4 on one device).
  static const int maxPlayers = 4;

  @override
  final int playerCount;

  final Random _rng;
  final List<int> _lives;

  /// Lives lost per seat (all of them, also below 0 lives).
  final List<int> _lost;

  /// Seats that are out (no lives left, or resigned with 3–4 seats), in the
  /// order they went out.
  final List<int> _out = [];

  /// The players ended an "Unbegrenzte Leben" game.
  bool _ended = false;

  /// With 3–4 seats: the others resigned and one seat is left.
  bool _othersResigned = false;
  MaexchenPhase _phase = MaexchenPhase.roll;
  int _seat = 0;
  int _round = 1;

  /// The dice under the cup as rolled, and who rolled them; null at the
  /// start of a round.
  List<int>? _dice;
  int? _roller;

  /// The round's announcement and who made it; null before the first one.
  int? _announced;
  int? _announcer;

  MaexchenRoundEnd? _lastRound;
  int? _winnerSeat;
  final List<List<int>> _scripted = [];
  final List<Map<String, dynamic>> _history = [];

  MaexchenGame(
      {int seed = 0,
      this.startLives = defaultLives,
      this.maexchenDouble = true,
      this.unlimitedLives = false,
      this.playerCount = 2})
      : _rng = Random(seed),
        _lives = List.filled(playerCount < 0 ? 0 : playerCount, startLives),
        _lost = List.filled(playerCount < 0 ? 0 : playerCount, 0) {
    if (playerCount < 2 || playerCount > maxPlayers) {
      throw ArgumentError.value(playerCount, 'playerCount', 'must be 2..$maxPlayers');
    }
    if (startLives < 1 || startLives > 9) throw ArgumentError.value(startLives, 'startLives', 'must be 1..9');
  }

  // ------------------------------------------------------------- state

  MaexchenPhase get phase => _phase;

  /// The seat to move.
  int get currentSeat => _seat;

  /// [Player] of a seat: seat 0 = A, 1 = B; null for seats 2 and 3.
  static Player? playerOfSeat(int seat) => seat < Player.values.length ? Player.values[seat] : null;

  @override
  Player get currentPlayer =>
      playerOfSeat(_seat) ?? (throw StateError('seat $_seat has no Player (more than 2 seats)'));

  @override
  int? get actorSeat => isOver ? null : _seat;

  @override
  int seatOfMove(Map<String, dynamic> move) {
    if (move['action'] == 'resign') {
      final s = playerCount == 2 ? Game.resignerOf(move)?.index : move['seat'];
      if (s is int) return s;
    }
    return _seat;
  }

  /// Whether [seat] is out: no lives left, or (3–4 seats) resigned.
  @override
  bool isSeatOut(int seat) => _out.contains(seat);

  /// The seats that are out, in the order they went out.
  List<int> get outSeats => List.unmodifiable(_out);

  /// The seats still in, in seat order.
  List<int> get activeSeats => [
        for (var s = 0; s < playerCount; s++)
          if (!_out.contains(s)) s
      ];

  /// Lives left of [seat].
  int livesOfSeat(int seat) => _lives[seat];

  /// Lives [seat] lost so far (the tally of "Unbegrenzte Leben").
  int lostOf(int seat) => _lost[seat];

  /// Lives lost per seat.
  List<int> get lost => List.unmodifiable(_lost);

  /// The players ended an "Unbegrenzte Leben" game ([endMove]).
  bool get ended => _ended;

  /// Round number, from 1.
  int get round => _round;

  /// Lives left of [p].
  int livesOf(Player p) => _lives[p.index];

  /// Lives left per seat.
  List<int> get lives => List.unmodifiable(_lives);

  /// The round's announcement (null before the first one).
  int? get announced => _announced;

  /// Who made [announced] (2 seats; see [announcerSeat]).
  Player? get announcer => _announcer == null ? null : playerOfSeat(_announcer!);

  /// The seat that made [announced].
  int? get announcerSeat => _announcer;

  /// Who rolled the dice now under the cup (null at the start of a round;
  /// 2 seats, see [rollerSeat]).
  Player? get roller => _roller == null ? null : playerOfSeat(_roller!);

  /// The seat that rolled the dice now under the cup.
  int? get rollerSeat => _roller;

  /// The dice under the cup, as rolled: secret, only [roller] may see them
  /// (screens show them only to the roller who lifts the cup). Null at the
  /// start of a round, and in a view for anyone but the roller.
  List<int>? get dice => _dice == null ? null : List.unmodifiable(_dice!);

  /// The value under the cup ([dice]), or null.
  int? get diceValue => _dice == null ? null : valueOf(_dice![0], _dice![1]);

  /// How the last round ended (null in the first round).
  MaexchenRoundEnd? get lastRound => _lastRound;

  @override
  bool get isOver => resignedBy != null || _winnerSeat != null || _ended || _othersResigned;

  /// The seats in first place once over: the last one with lives, the one
  /// left after the others resigned, or (ended "Unbegrenzte Leben" game)
  /// the seats still in with the fewest lives lost.
  List<int> get winnerSeats {
    final w = _winnerSeat;
    if (w != null) return [w];
    if (_othersResigned) return activeSeats;
    if (!_ended) return const [];
    final active = activeSeats;
    final best = active.map((s) => _lost[s]).reduce(min);
    return [
      for (final s in active)
        if (_lost[s] == best) s
    ];
  }

  GameEndReason? get _endCode => _winnerSeat != null
      ? GameEndReason.maexchenNoLives
      : _othersResigned
          ? GameEndReason.commonResigned
          : _ended
              ? GameEndReason.maexchenEnded
              : null;

  /// The two-player outcome (params `a`, `b`: lives left; lives lost after
  /// an ended "Unbegrenzte Leben" game). With 3–4 seats a winner in seat 2+
  /// or a shared first place cannot be named as a [Player]: then
  /// [GameResult.draw] says that the game is over; use [seatResult].
  @override
  GameResult get playResult {
    final code = _endCode;
    if (code == null) return const GameResult();
    final w = winnerSeats;
    final winner = w.length == 1 ? playerOfSeat(w.single) : null;
    final counts = code == GameEndReason.maexchenEnded ? _lost : _lives;
    return GameResult(
        winner: winner,
        draw: winner == null,
        reason: switch (code) {
          GameEndReason.maexchenEnded => 'ended by the players; lives lost ${_lost.join(', ')}',
          GameEndReason.commonResigned => 'the others resigned',
          _ => 'no lives left',
        },
        code: code,
        params: {
          for (var s = 0; s < playerCount && s < 2; s++) Player.values[s].name: counts[s],
          if (code == GameEndReason.commonResigned) 'player': _out.last,
        });
  }

  /// The outcome per seat: the winner first, then the seats in the reverse
  /// order they went out; after an ended "Unbegrenzte Leben" game by lives
  /// lost (fewest first, equal counts share a place), resigned seats behind.
  /// Params: `lives<seat>` and `lost<seat>`.
  @override
  SeatResult get seatResult {
    final resigner = resignedBy;
    if (resigner != null) {
      return SeatResult(
          isOver: true,
          places: [for (var s = 0; s < playerCount; s++) s == resigner.index ? 2 : 1],
          code: GameEndReason.commonResigned.code,
          params: {'seat': resigner.index},
          reason: '${playerNameOf(resigner)} resigned');
    }
    final code = _endCode;
    if (code == null) return const SeatResult();
    return SeatResult(
        isOver: true,
        places: code == GameEndReason.maexchenEnded
            ? SeatResult.placesFor([for (final l in _lost) -l], out: _out)
            : SeatResult.placesFor(List.filled(playerCount, 0), out: _out),
        code: code.code,
        params: {
          for (var s = 0; s < playerCount; s++) 'lives$s': _lives[s],
          for (var s = 0; s < playerCount; s++) 'lost$s': _lost[s],
          if (code == GameEndReason.commonResigned) 'seat': _out.last,
        },
        reason: playResult.reason);
  }

  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  // ------------------------------------------------------------- moves

  static const Map<String, dynamic> rollMove = {'action': 'roll'};
  static const Map<String, dynamic> believeMove = {'action': 'believe'};
  static const Map<String, dynamic> doubtMove = {'action': 'doubt'};
  static const Map<String, dynamic> giveUpMove = {'action': 'giveUp'};
  static Map<String, dynamic> announceMove(int value) => {'action': 'announce', 'value': value};

  /// "Spiel beenden" of the rule variant "Unbegrenzte Leben": allowed at any
  /// time while the game runs (a round under way does not count); not in
  /// [legalMoves], like a resign.
  static const Map<String, dynamic> endMove = {'action': 'end'};

  /// The resign move for [seat] in a game with 3–4 seats.
  static Map<String, dynamic> resignSeatMove(int seat) => {'action': 'resign', 'seat': seat};

  /// Whether [move] ends a round (`doubt` shows the dice, `giveUp` costs a
  /// life): hot-seat undo never takes such a move back (maintainer decision
  /// 2026-11-06), see `GameSpec.undoBarrier`.
  static bool endsRound(Map<String, dynamic> move) => move['action'] == 'doubt' || move['action'] == 'giveUp';

  /// The legal moves of the player to move; announcements low to high.
  /// Empty once the game is over.
  List<Map<String, dynamic>> get legalMoves {
    if (isOver) return const [];
    return switch (_phase) {
      MaexchenPhase.roll => [rollMove],
      MaexchenPhase.announce => [for (final v in valuesAbove(_announced)) announceMove(v)],
      MaexchenPhase.respond => _announced == maexchen ? [doubtMove, giveUpMove] : [believeMove, doubtMove],
    };
  }

  /// With 3–4 seats a resign names a seat and lets the others play on; with
  /// two it is the common resign of [Game].
  @override
  GameEvent? applyMove(Map<String, dynamic> move) {
    if (playerCount == 2 || move['action'] != 'resign') return super.applyMove(move);
    return _resignSeat(move);
  }

  GameEvent? _resignSeat(Map<String, dynamic> move) {
    final seat = move['seat'];
    if (isOver || move.length != 2 || seat is! int || seat < 0 || seat >= playerCount || isSeatOut(seat)) return null;
    _out.add(seat);
    _history.add(Map.unmodifiable(move));
    // A round under way is dropped (no loser) and starts again: the seat to
    // move stays, unless it was the one that left.
    final midRound = _roller != null || _announced != null;
    if (midRound) {
      _dice = null;
      _roller = null;
      _announced = null;
      _announcer = null;
      _phase = MaexchenPhase.roll;
      _lastRound = null;
    }
    if (_seat == seat) _seat = _nextSeat(seat);
    if (activeSeats.length == 1) _othersResigned = true;
    return GameEvent(payload: {'resigned': seat, if (midRound) 'roundDropped': true});
  }

  GameEvent? _end() {
    if (!unlimitedLives) return null;
    _log(endMove);
    _ended = true;
    final w = winnerSeats;
    return GameEvent(
        winner: w.length == 1 ? playerOfSeat(w.single) : null,
        draw: w.length != 1 || playerOfSeat(w.single) == null,
        payload: {'ended': true, 'lost': List.of(_lost)});
  }

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) {
    if (isOver) return null;
    return switch (move['action']) {
      'end' => _end(),
      'roll' => _roll(),
      'announce' => _announce(move['value']),
      'believe' => _believe(),
      'doubt' => _doubt(),
      'giveUp' => _giveUp(),
      _ => null,
    };
  }

  GameEvent? _roll() {
    if (_phase != MaexchenPhase.roll) return null;
    final d = _scripted.isNotEmpty ? _scripted.removeAt(0) : [_rng.nextInt(6) + 1, _rng.nextInt(6) + 1];
    _dice = d;
    _roller = _seat;
    _phase = MaexchenPhase.announce;
    _log(rollMove);
    return GameEvent(payload: {'rolled': true, 'dice': List.of(d), 'value': valueOf(d[0], d[1])});
  }

  GameEvent? _announce(Object? value) {
    if (_phase != MaexchenPhase.announce || !isValue(value)) return null;
    final v = value as int;
    final previous = _announced;
    if (previous != null && !beats(v, previous)) return null;
    _announced = v;
    _announcer = _seat;
    _log(announceMove(v));
    _seat = _nextSeat(_seat);
    _phase = MaexchenPhase.respond;
    return GameEvent(payload: {'announced': v});
  }

  GameEvent? _believe() {
    if (_phase != MaexchenPhase.respond || _announced == maexchen) return null;
    _log(believeMove);
    _phase = MaexchenPhase.roll;
    return GameEvent(payload: {'believed': _announced});
  }

  GameEvent? _doubt() {
    if (_phase != MaexchenPhase.respond) return null;
    final announced = _announced!, announcer = _announcer!, doubter = _seat;
    final dice = _dice!;
    final real = valueOf(dice[0], dice[1]);
    final bluff = rankOf(real) < rankOf(announced);
    final loser = bluff ? announcer : doubter;
    final lost = announced == maexchen && maexchenDouble ? 2 : 1;
    _log(doubtMove);
    final end = MaexchenRoundEnd(
        round: _round,
        announced: announced,
        announcer: announcer,
        challenger: doubter,
        gaveUp: false,
        dice: List.of(dice),
        loser: loser,
        lost: lost);
    return _endRound(end);
  }

  GameEvent? _giveUp() {
    if (_phase != MaexchenPhase.respond || _announced != maexchen) return null;
    _log(giveUpMove);
    final end = MaexchenRoundEnd(
        round: _round,
        announced: _announced!,
        announcer: _announcer!,
        challenger: _seat,
        gaveUp: true,
        dice: null,
        loser: _seat,
        lost: 1);
    return _endRound(end);
  }

  GameEvent _endRound(MaexchenRoundEnd end) {
    _lost[end.loser] += end.lost;
    if (!unlimitedLives) _lives[end.loser] = max(0, _lives[end.loser] - end.lost);
    if (_lives[end.loser] == 0 && !_out.contains(end.loser)) _out.add(end.loser);
    _lastRound = end;
    _round++;
    _dice = null;
    _roller = null;
    _announced = null;
    _announcer = null;
    _phase = MaexchenPhase.roll;
    final alive = activeSeats;
    if (alive.length == 1) {
      _winnerSeat = alive.single;
    } else {
      _seat = _out.contains(end.loser) ? _nextSeat(end.loser) : end.loser;
    }
    final winner = _winnerSeat == null ? null : playerOfSeat(_winnerSeat!);
    return GameEvent(winner: winner, draw: _winnerSeat != null && winner == null, payload: {
      'roundEnd': end.toJson(),
      'lives': List.of(_lives),
      if (unlimitedLives) 'lost': List.of(_lost),
    });
  }

  /// The next seat after [seat] that is still in.
  int _nextSeat(int seat) {
    for (var i = 1; i <= playerCount; i++) {
      final s = (seat + i) % playerCount;
      if (!_out.contains(s)) return s;
    }
    return seat;
  }

  /// History entry: the move with its `player` (seats 0 / 1) or `seat`.
  void _log(Map<String, dynamic> move) {
    final p = playerOfSeat(_seat);
    _history.add({...move, if (p != null) 'player': p else 'seat': _seat});
  }

  /// Tests, demos and screenshots only: the next `roll` moves show these
  /// dice (each a pair 1–6) before the seeded ones. Not part of the config:
  /// a replay ([replay], hot-seat undo) rolls from the seed again.
  void debugScriptRolls(List<List<int>> rolls) {
    for (final r in rolls) {
      if (r.length != 2 || r.any((d) => d < 1 || d > 6)) throw ArgumentError.value(r, 'rolls', 'two dice 1–6');
      _scripted.add(List.of(r));
    }
  }

  // ------------------------------------------------------------- views

  /// What [viewer] may know, as JSON (see [MaexchenRedaction]): everything
  /// but the dice under the cup, which only their roller sees.
  Map<String, dynamic> viewJson(Player viewer) => {
        'viewer': viewer.name,
        'players': playerCount,
        'startLives': startLives,
        'double': maexchenDouble,
        if (unlimitedLives) 'unlimited': true,
        'phase': _phase.name,
        'seat': _seat,
        'round': _round,
        'lives': List.of(_lives),
        if (unlimitedLives) 'lost': List.of(_lost),
        if (_out.isNotEmpty && playerCount > 2) 'out': List.of(_out),
        if (_ended) 'ended': true,
        if (_othersResigned) 'othersResigned': true,
        if (_announced != null) 'announced': _announced,
        if (_announcer != null) 'announcer': _announcer,
        if (_roller != null) 'roller': _roller,
        if (_roller == viewer.index && _dice != null) 'dice': List.of(_dice!),
        if (_lastRound != null) 'last': _lastRound!.toJson(),
        if (_winnerSeat != null) 'winner': _winnerSeat,
        if (resignedBy != null) 'resigned': resignedBy!.name,
      };
}
