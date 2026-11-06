import 'dart:math';

import 'game.dart';
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
///   [maexchenDouble] (on by default) a doubted true Mäxchen costs 2 lives.
/// * After a doubt or a give-up a new round starts with the player who lost
///   the life (the next one in turn if that player is out).
/// * Every player starts with [startLives] lives; a player with none left is
///   out. With two players the other one wins.
///
/// Seats: the state is kept per seat (`0 … playerCount-1`, seat 0 is A,
/// seat 1 is B) so the game can take 3+ players later (KLD-088); for now
/// [playerCount] is 2.
///
/// Deterministic: the dice come from `Random(seed)`, two draws per `roll`,
/// so config + seed + moves is a full replay. The seed is secret over the
/// network ([MaexchenRedaction.secretSeed]): it decides every roll.
class MaexchenGame extends Game {
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

  /// House rule: a doubted Mäxchen that is real costs the doubter 2 lives.
  final bool maexchenDouble;

  final int playerCount;

  final Random _rng;
  final List<int> _lives;
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

  MaexchenGame({int seed = 0, this.startLives = defaultLives, this.maexchenDouble = true, this.playerCount = 2})
      : _rng = Random(seed),
        _lives = List.filled(playerCount, startLives) {
    if (playerCount != 2) throw ArgumentError.value(playerCount, 'playerCount', 'only 2 players for now');
    if (startLives < 1 || startLives > 9) throw ArgumentError.value(startLives, 'startLives', 'must be 1..9');
  }

  // ------------------------------------------------------------- state

  MaexchenPhase get phase => _phase;

  /// The seat to move.
  int get currentSeat => _seat;

  @override
  Player get currentPlayer => Player.values[_seat];

  /// Round number, from 1.
  int get round => _round;

  /// Lives left of [p].
  int livesOf(Player p) => _lives[p.index];

  /// Lives left per seat.
  List<int> get lives => List.unmodifiable(_lives);

  /// The round's announcement (null before the first one).
  int? get announced => _announced;

  /// Who made [announced].
  Player? get announcer => _announcer == null ? null : Player.values[_announcer!];

  /// Who rolled the dice now under the cup (null at the start of a round).
  Player? get roller => _roller == null ? null : Player.values[_roller!];

  /// The dice under the cup, as rolled: secret, only [roller] may see them
  /// (screens show them only to the roller who lifts the cup). Null at the
  /// start of a round, and in a view for anyone but the roller.
  List<int>? get dice => _dice == null ? null : List.unmodifiable(_dice!);

  /// The value under the cup ([dice]), or null.
  int? get diceValue => _dice == null ? null : valueOf(_dice![0], _dice![1]);

  /// How the last round ended (null in the first round).
  MaexchenRoundEnd? get lastRound => _lastRound;

  @override
  GameResult get playResult {
    final w = _winnerSeat;
    if (w == null) return const GameResult();
    return GameResult(
        winner: Player.values[w],
        reason: 'no lives left',
        code: GameEndReason.maexchenNoLives,
        params: {'a': _lives[0], 'b': _lives[1]});
  }

  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  // ------------------------------------------------------------- moves

  static const Map<String, dynamic> rollMove = {'action': 'roll'};
  static const Map<String, dynamic> believeMove = {'action': 'believe'};
  static const Map<String, dynamic> doubtMove = {'action': 'doubt'};
  static const Map<String, dynamic> giveUpMove = {'action': 'giveUp'};
  static Map<String, dynamic> announceMove(int value) => {'action': 'announce', 'value': value};

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

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) {
    if (isOver) return null;
    return switch (move['action']) {
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
    final lost = !bluff && announced == maexchen && maexchenDouble ? 2 : 1;
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
    _lives[end.loser] = max(0, _lives[end.loser] - end.lost);
    _lastRound = end;
    _round++;
    _dice = null;
    _roller = null;
    _announced = null;
    _announcer = null;
    _phase = MaexchenPhase.roll;
    final alive = [for (var s = 0; s < playerCount; s++) if (_lives[s] > 0) s];
    if (alive.length == 1) {
      _winnerSeat = alive.single;
    } else {
      _seat = _lives[end.loser] > 0 ? end.loser : _nextSeat(end.loser);
    }
    final winner = _winnerSeat == null ? null : Player.values[_winnerSeat!];
    return GameEvent(winner: winner, payload: {'roundEnd': end.toJson(), 'lives': List.of(_lives)});
  }

  /// The next seat after [seat] that still has lives.
  int _nextSeat(int seat) {
    for (var i = 1; i <= playerCount; i++) {
      final s = (seat + i) % playerCount;
      if (_lives[s] > 0) return s;
    }
    return seat;
  }

  void _log(Map<String, dynamic> move) => _history.add({...move, 'player': currentPlayer});

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
        'phase': _phase.name,
        'seat': _seat,
        'round': _round,
        'lives': List.of(_lives),
        if (_announced != null) 'announced': _announced,
        if (_announcer != null) 'announcer': _announcer,
        if (_roller != null) 'roller': _roller,
        if (_roller == viewer.index && _dice != null) 'dice': List.of(_dice!),
        if (_lastRound != null) 'last': _lastRound!.toJson(),
        if (_winnerSeat != null) 'winner': _winnerSeat,
        if (resignedBy != null) 'resigned': resignedBy!.name,
      };
}
