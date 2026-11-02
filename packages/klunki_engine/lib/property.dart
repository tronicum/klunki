/// Baulöwe (en working title "Housing Corp"), the property-trading dice game
/// (KLD-060 step 1, id `property`):
/// engine only.
///
/// **Players are seats** `0 … playerCount-1` (2–6), not [Player] a/b: the
/// game is network-only with every player on their own device, and the
/// shared [Game] interface, the registry and the protocol only know two
/// players today. The engine therefore stands alone (it does not extend
/// [Game] and is not in `gameSpecs` yet); the later registry/protocol step
/// (n-player lobby, KLD-088) maps seats to network players. See the card
/// `docs/tasks/KLD-060-property-game.md` for the adapter plan.
///
/// The board and cards come from a [PropertyTheme] (default: Berlin); the
/// rules do not depend on it.
///
/// Deterministic: the dice and the two shuffled card decks come from one
/// `Random(seed)`, so `(playerCount, seed, maxRounds)` plus the move list is
/// a full replay ([PropertyGame.replay]). Money, properties and held cards are
/// public; the seed and the deck order are not (a guest must never get them:
/// [PropertyGame.toJson] leaves both out).
///
/// ## Turn flow
///
/// [phase] says what is expected and [actor] who is expected to move:
/// - [PropertyPhase.roll]: the current player rolls (in the pause: or pays
///   the bail / uses a free card first). Property management is allowed.
/// - [PropertyPhase.buy]: landed on an unowned property: `buy` or `decline`
///   (decline starts an auction).
/// - [PropertyPhase.auction]: ascending open bids in seat order (see
///   [PropertyAuction]); the actor is the bidder whose turn it is.
/// - [PropertyPhase.trade]: an offer waits for the other player's answer.
/// - [PropertyPhase.debt]: someone owes more than their cash and has to sell
///   houses / mortgage (each such move pays the debt automatically once the
///   cash suffices) or declare `bankrupt`.
/// - [PropertyPhase.end]: the turn is resolved: `endTurn` (management and
///   trade offers still allowed).
/// - [PropertyPhase.over].
///
/// Cash never goes negative: an unpayable amount becomes a debt.
library;

import 'dart:math';

import 'property_theme.dart';

export 'property_theme.dart';

/// What the game waits for. See the library docs.
enum PropertyPhase { roll, buy, auction, trade, debt, end, over }

/// One player's state. Public information.
class PropertySeat {
  int cash;

  /// Board square 0–39.
  int pos = 0;

  /// Sitting in the "Auszeit" (pause).
  bool inPause = false;

  /// Failed doubles rolls in the current pause (0–2).
  int pauseTries = 0;

  /// Ids of the free cards held (they go back under their deck when used).
  final List<String> freeCards = [];

  /// Bankrupt or resigned: out of the game.
  bool out = false;

  PropertySeat(this.cash);

  Map<String, dynamic> toJson() => {
        'cash': cash,
        'pos': pos,
        if (inPause) 'inPause': true,
        if (pauseTries > 0) 'pauseTries': pauseTries,
        if (freeCards.isNotEmpty) 'freeCards': List.of(freeCards),
        if (out) 'out': true,
      };
}

/// An open auction. Bidders bid in turn (seat order, starting after the
/// player who declined, who bids last); each `bid` must beat the high bid
/// (the first at least [PropertyGame.minFirstBid]) and fit the bidder's
/// cash; a `pass` drops the bidder out for good. The last bidder left with
/// the high bid buys; if everyone passes the property stays with the bank.
/// Open bids in turn fit the one-actor-at-a-time network turn model and
/// need no hidden information (sealed bids would).
class PropertyAuction {
  final int square;

  /// Seats still in, in bidding order.
  final List<int> bidders;

  /// Index into [bidders] of the seat to bid next.
  int turn = 0;
  int high = 0;
  int? highSeat;
  PropertyAuction(this.square, this.bidders);

  int get actor => bidders[turn];

  /// The smallest bid allowed now.
  int get minBid => max(PropertyGame.minFirstBid, high + 1);

  Map<String, dynamic> toJson() => {
        'square': square,
        'bidders': List.of(bidders),
        'turn': actor,
        'high': high,
        if (highSeat != null) 'highSeat': highSeat,
      };
}

/// One side of a trade: money, properties (square indexes) and free cards.
class PropertyTradeSide {
  final int money;
  final List<int> squares;
  final int cards;
  const PropertyTradeSide({this.money = 0, this.squares = const [], this.cards = 0});

  bool get isEmpty => money == 0 && squares.isEmpty && cards == 0;

  Map<String, dynamic> toJson() => {
        if (money != 0) 'money': money,
        if (squares.isNotEmpty) 'squares': List.of(squares),
        if (cards != 0) 'cards': cards,
      };

  /// Parses a side of a `tradeOffer` move; null if malformed.
  static PropertyTradeSide? parse(Object? json) {
    if (json == null) return const PropertyTradeSide();
    if (json is! Map) return null;
    final money = json['money'] ?? 0, squares = json['squares'] ?? const [], cards = json['cards'] ?? 0;
    if (money is! int || money < 0 || cards is! int || cards < 0 || squares is! List) return null;
    final list = <int>[];
    for (final s in squares) {
      if (s is! int || s < 0 || s >= propertyLayout.length || list.contains(s)) return null;
      list.add(s);
    }
    return PropertyTradeSide(money: money, squares: List.unmodifiable(list), cards: cards);
  }
}

/// A trade offer from the current player to [to]: [from] gives [give] and
/// gets [get]. One offer at a time; [to] answers with `tradeAccept` or
/// `tradeDecline`.
class PropertyTrade {
  final int from;
  final int to;
  final PropertyTradeSide give;
  final PropertyTradeSide get;
  const PropertyTrade(this.from, this.to, this.give, this.get);

  Map<String, dynamic> toJson() => {'from': from, 'to': to, 'give': give.toJson(), 'get': get.toJson()};
}

/// Money [debtor] owes [creditor] (null = the bank).
class PropertyDebt {
  final int debtor;
  final int? creditor;
  final int amount;

  /// Why: `rent`, `tax`, `bail`, `card`.
  final String reason;
  const PropertyDebt(this.debtor, this.creditor, this.amount, this.reason);

  Map<String, dynamic> toJson() =>
      {'debtor': debtor, if (creditor != null) 'creditor': creditor, 'amount': amount, 'reason': reason};
}

/// How the game ended. Codes are stable strings like [GameEndReason] codes
/// (the shared enum only knows two players, so they live here for now).
class PropertyResult {
  final bool isOver;

  /// The winning seat; null while running and on a tie at the round limit.
  final int? winner;

  /// The tied leaders on a draw at the round limit.
  final List<int> leaders;

  /// `property.lastSolvent` (everyone else is bankrupt or resigned) or
  /// `property.roundLimit` (richest by [PropertyGame.netWorth]); null while
  /// running.
  final String? code;

  /// English reason for the CLI.
  final String reason;
  const PropertyResult({this.isOver = false, this.winner, this.leaders = const [], this.code, this.reason = ''});

  bool get draw => isOver && winner == null;

  Map<String, dynamic> toJson() => {
        'over': isOver,
        if (winner != null) 'winner': winner,
        if (leaders.isNotEmpty) 'leaders': List.of(leaders),
        if (code != null) 'code': code,
      };
}

/// Result of an accepted move: what happened, in order, as JSON-ready maps
/// (`{'type': 'rolled', 'dice': [3, 4]}`, `{'type': 'paid', …}`, …), for
/// narration, animation and (later) the redacted network step.
class PropertyEvent {
  final List<Map<String, dynamic>> events;
  const PropertyEvent(this.events);
}

/// Baulöwe for 2–6 seats. See the library docs.
class PropertyGame {
  /// Rules version (KLD-085) for the fingerprint once registered.
  static const int rulesVersion = 1;
  static const int minPlayers = 2;
  static const int maxPlayers = 6;
  static const int startCash = 1500;
  static const int startSalary = 200;
  static const int bail = 50;
  static const int maxPauseTries = 3;
  static const int minFirstBid = 10;

  /// Trade offers per turn (keeps a turn finite: an offer the other side
  /// declines cannot be repeated forever).
  static const int maxTradeOffersPerTurn = 3;
  static const int pauseSquare = 10;

  final int playerCount;
  final int seed;

  /// Names, prices, rents and cards.
  final PropertyTheme theme;

  /// Optional game length: the game ends after this many full rounds and
  /// the richest seat wins ([netWorth]). Null (the default) = play until
  /// only one player is left; the limit is an opt-in setting.
  final int? maxRounds;

  final Random _rng;
  List<PropertySquare> get _board => theme.squares;
  List<List<int>> get _groups => theme.groups;

  /// Scripted dice for tests and demos (consumed before [_rng]).
  final List<int> _scriptedDice;

  final List<PropertySeat> _seats;
  final List<int?> _owner = List.filled(40, null);
  final List<int> _houses = List.filled(40, 0);
  final List<bool> _mortgaged = List.filled(40, false);
  final Map<PropertyDeck, List<PropertyCard>> _decks = {};

  /// Net money the bank received (negative: paid out). Σcash + [_bank] is
  /// always `playerCount × startCash`.
  int _bank = 0;
  int _current = 0;
  PropertyPhase _turnPhase = PropertyPhase.roll;
  bool _rollAgain = false;
  int _doubles = 0;
  List<int>? _dice;
  int _tradeOffers = 0;
  int _rounds = 0;
  PropertyAuction? _auction;
  PropertyTrade? _trade;
  final List<PropertyDebt> _debts = [];
  final List<Map<String, dynamic>> _history = [];
  PropertyResult _result = const PropertyResult();
  late List<Map<String, dynamic>> _ev;

  /// A new game. Throws [ArgumentError] for a player count outside 2–6 or a
  /// [maxRounds] below 1.
  ///
  /// [dice] and [deckOrder] are for tests and scripted demos only: dice
  /// values (1–6) used before the seeded ones, and a deck order (card ids,
  /// top first; the deck's other cards follow in seeded order).
  PropertyGame({this.playerCount = 2, this.seed = 0, this.maxRounds, PropertyTheme? theme, List<int> dice = const [],
      Map<PropertyDeck, List<String>> deckOrder = const {}})
      : theme = theme ?? PropertyTheme.berlin,
        _rng = Random(seed),
        _scriptedDice = List.of(dice),
        _seats = List.generate(playerCount.clamp(0, maxPlayers), (_) => PropertySeat(startCash)) {
    if (playerCount < minPlayers || playerCount > maxPlayers) {
      throw ArgumentError.value(playerCount, 'playerCount', 'must be $minPlayers–$maxPlayers');
    }
    if (maxRounds != null && maxRounds! < 1) throw ArgumentError.value(maxRounds, 'maxRounds', 'must be at least 1');
    if (dice.any((d) => d < 1 || d > 6)) throw ArgumentError.value(dice, 'dice', 'values must be 1–6');
    final problems = this.theme.validate();
    if (problems.isNotEmpty) throw ArgumentError.value(this.theme.id, 'theme', problems.join('; '));
    for (final deck in PropertyDeck.values) {
      final cards = [for (final c in this.theme.cards) if (c.deck == deck) c];
      for (var i = cards.length - 1; i > 0; i--) {
        final j = _rng.nextInt(i + 1);
        final t = cards[i];
        cards[i] = cards[j];
        cards[j] = t;
      }
      final top = [for (final id in deckOrder[deck] ?? const <String>[]) cards.firstWhere((c) => c.id == id)];
      _decks[deck] = [...top, for (final c in cards) if (!top.contains(c)) c];
    }
  }

  /// Rebuilds a game from its settings and move list; null if a move is
  /// refused (the logs disagree).
  static PropertyGame? replay(int playerCount, int seed, Iterable<Map<String, dynamic>> moves,
      {int? maxRounds, PropertyTheme? theme}) {
    final g = PropertyGame(playerCount: playerCount, seed: seed, maxRounds: maxRounds, theme: theme);
    for (final m in moves) {
      if (g.applyMove(m) == null) return null;
    }
    return g;
  }

  // ---------------------------------------------------------------- getters

  List<PropertySeat> get seats => List.unmodifiable(_seats);
  int get currentSeat => _current;
  int get rounds => _rounds;
  List<int>? get dice => _dice == null ? null : List.unmodifiable(_dice!);
  PropertyAuction? get auction => _auction;
  PropertyTrade? get trade => _trade;
  List<PropertyDebt> get debts => List.unmodifiable(_debts);
  PropertyResult get result => _result;
  bool get isOver => _result.isOver;
  int get bankBalance => _bank;
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  int? ownerOf(int square) => _owner[square];
  int housesOn(int square) => _houses[square];
  bool isMortgaged(int square) => _mortgaged[square];

  /// Seats still in the game.
  List<int> get activeSeats => [for (var i = 0; i < playerCount; i++) if (!_seats[i].out) i];

  /// Squares [seat] owns.
  List<int> ownedBy(int seat) => [for (var i = 0; i < 40; i++) if (_owner[i] == seat) i];

  PropertyPhase get phase {
    if (_result.isOver) return PropertyPhase.over;
    if (_debts.isNotEmpty) return PropertyPhase.debt;
    if (_auction != null) return PropertyPhase.auction;
    if (_trade != null) return PropertyPhase.trade;
    return _turnPhase;
  }

  /// The seat expected to move now; null once the game is over. A move may
  /// name its seat (`'seat': n`); it is refused when that is not [actor].
  int? get actor => switch (phase) {
        PropertyPhase.over => null,
        PropertyPhase.debt => _debts.first.debtor,
        PropertyPhase.auction => _auction!.actor,
        PropertyPhase.trade => _trade!.to,
        _ => _current,
      };

  /// The seat that makes [move]: the named seat of a resign, else [actor].
  int? seatOf(Map<String, dynamic> move) {
    if (move['action'] != 'resign') return actor;
    final s = move['seat'];
    return s is int ? s : null;
  }

  /// Cash plus the price of every property (mortgaged: price minus the
  /// mortgage value) plus what the houses cost. Decides the round limit.
  int netWorth(int seat) {
    var w = _seats[seat].cash;
    for (final i in ownedBy(seat)) {
      final sq = _board[i];
      w += _mortgaged[i] ? sq.price - sq.mortgageValue : sq.price;
      w += _houses[i] * sq.houseCost;
    }
    return w;
  }

  /// Rent [square] costs right now for a lander (dice total [diceTotal] for
  /// utilities); 0 if unowned or mortgaged.
  int rentFor(int square, {int? diceTotal}) {
    final owner = _owner[square];
    if (owner == null || _mortgaged[square]) return 0;
    final sq = _board[square];
    switch (sq.kind) {
      case PropertyKind.street:
        final h = _houses[square];
        if (h > 0) return sq.rents[h];
        return _ownsGroup(owner, sq.group) ? sq.rents[0] * 2 : sq.rents[0];
      case PropertyKind.station:
        final n = _countOwned(owner, PropertyKind.station);
        return sq.rents[n - 1];
      case PropertyKind.utility:
        final n = _countOwned(owner, PropertyKind.utility);
        final d = diceTotal ?? (_dice == null ? 7 : _dice![0] + _dice![1]);
        return sq.rents[n - 1] * d;
      default:
        return 0;
    }
  }

  bool _ownsGroup(int seat, int group) => _groups[group].every((i) => _owner[i] == seat);
  int _countOwned(int seat, PropertyKind kind) =>
      [for (var i = 0; i < 40; i++) if (_owner[i] == seat && _board[i].kind == kind) i].length;
  Iterable<int> _groupOf(int square) =>
      _board[square].group < 0 ? [square] : _groups[_board[square].group];

  // ------------------------------------------------------- legality checks

  bool get _canManage =>
      phase == PropertyPhase.roll || phase == PropertyPhase.buy || phase == PropertyPhase.end;

  bool canBuild(int seat, int square) {
    if (!_canManage || seat != _current || !_validSquare(square)) return false;
    final sq = _board[square];
    if (sq.kind != PropertyKind.street || _owner[square] != seat || _houses[square] >= 5) return false;
    final group = _groups[sq.group];
    if (!_ownsGroup(seat, sq.group) || group.any((i) => _mortgaged[i])) return false;
    if (_houses[square] > group.map((i) => _houses[i]).reduce(min)) return false;
    return _seats[seat].cash >= sq.houseCost;
  }

  bool canSell(int seat, int square) {
    if (!(_canManage && seat == _current) && !(phase == PropertyPhase.debt && seat == actor)) return false;
    if (!_validSquare(square) || _owner[square] != seat || _houses[square] == 0) return false;
    return _houses[square] >= _groupOf(square).map((i) => _houses[i]).reduce(max);
  }

  bool canMortgage(int seat, int square) {
    if (!(_canManage && seat == _current) && !(phase == PropertyPhase.debt && seat == actor)) return false;
    if (!_validSquare(square) || _owner[square] != seat || _mortgaged[square]) return false;
    return _groupOf(square).every((i) => _houses[i] == 0);
  }

  bool canUnmortgage(int seat, int square) {
    if (!_canManage || seat != _current || !_validSquare(square)) return false;
    return _owner[square] == seat && _mortgaged[square] && _seats[seat].cash >= _board[square].unmortgageCost;
  }

  static bool _validSquare(int square) => square >= 0 && square < 40;

  /// Why [offer] by the current player cannot be made, or null if it can.
  String? tradeProblem(int to, PropertyTradeSide give, PropertyTradeSide get) {
    if (phase != PropertyPhase.roll && phase != PropertyPhase.end) return 'not now';
    if (_tradeOffers >= maxTradeOffersPerTurn) return 'too many offers this turn';
    if (to < 0 || to >= playerCount || to == _current || _seats[to].out) return 'no such player';
    if (give.isEmpty && get.isEmpty) return 'empty offer';
    return _sideProblem(_current, give) ?? _sideProblem(to, get);
  }

  String? _sideProblem(int seat, PropertyTradeSide side) {
    final s = _seats[seat];
    if (side.money > s.cash) return 'not enough money';
    if (side.cards > s.freeCards.length) return 'not enough free cards';
    for (final i in side.squares) {
      if (_owner[i] != seat) return 'square $i is not theirs';
      if (_groupOf(i).any((j) => _houses[j] > 0)) return 'sell the houses of square $i first';
    }
    return null;
  }

  /// Legal moves for [actor], as move maps, for UIs and bots. Bids are
  /// offered as the minimum and +50 / +100 (any amount in range is legal);
  /// trade offers are not listed (see [tradeProblem]); resign is always
  /// possible and not listed.
  List<Map<String, dynamic>> get legalMoves {
    final a = actor;
    if (a == null) return const [];
    final s = _seats[a];
    final out = <Map<String, dynamic>>[];
    void manage({bool raiseOnly = false}) {
      for (var i = 0; i < 40; i++) {
        if (_owner[i] != a) continue;
        if (!raiseOnly && canBuild(a, i)) out.add({'action': 'build', 'square': i});
        if (canSell(a, i)) out.add({'action': 'sell', 'square': i});
        if (canMortgage(a, i)) out.add({'action': 'mortgage', 'square': i});
        if (!raiseOnly && canUnmortgage(a, i)) out.add({'action': 'unmortgage', 'square': i});
      }
    }

    switch (phase) {
      case PropertyPhase.debt:
        manage(raiseOnly: true);
        out.add({'action': 'bankrupt'});
      case PropertyPhase.auction:
        final m = _auction!.minBid;
        for (final b in {m, m + 50, m + 100}) {
          if (b <= s.cash) out.add({'action': 'bid', 'amount': b});
        }
        out.add({'action': 'pass'});
      case PropertyPhase.trade:
        out.addAll([{'action': 'tradeAccept'}, {'action': 'tradeDecline'}]);
      case PropertyPhase.buy:
        if (s.cash >= _board[s.pos].price) out.add({'action': 'buy'});
        out.add({'action': 'decline'});
        manage();
      case PropertyPhase.roll:
        out.add({'action': 'roll'});
        if (s.inPause && s.cash >= bail) out.add({'action': 'payBail'});
        if (s.inPause && s.freeCards.isNotEmpty) out.add({'action': 'useCard'});
        manage();
      case PropertyPhase.end:
        out.add({'action': 'endTurn'});
        manage();
      case PropertyPhase.over:
        break;
    }
    return out;
  }

  // ------------------------------------------------------------------ moves

  /// Applies [move] for [actor] (a resign for the seat it names). Returns
  /// null for an illegal or malformed move; the state is then unchanged.
  ///
  /// Moves: `roll`, `buy`, `decline`, `bid` (`amount`), `pass`, `build` /
  /// `sell` / `mortgage` / `unmortgage` (`square`), `payBail`, `useCard`,
  /// `endTurn`, `tradeOffer` (`to`, `give`, `get`: `{money, squares, cards}`),
  /// `tradeAccept`, `tradeDecline`, `bankrupt`, `resign` (`seat`). A move may
  /// carry `seat` (the sender); it must then be the [actor].
  PropertyEvent? applyMove(Map<String, dynamic> move) {
    if (_result.isOver) return null;
    final action = move['action'];
    _ev = [];
    if (action == 'resign') {
      final s = move['seat'];
      if (s is! int || s < 0 || s >= playerCount || _seats[s].out) return null;
      _ev.add({'type': 'resigned', 'seat': s});
      _eliminate(s, null);
      return _accept(move);
    }
    final a = actor!;
    if (move.containsKey('seat') && move['seat'] != a) return null;
    final ok = switch (action) {
      'roll' => _roll(),
      'buy' => _buy(),
      'decline' => _decline(),
      'bid' => _bid(move['amount']),
      'pass' => _pass(),
      'build' => _build(a, move['square']),
      'sell' => _sell(a, move['square']),
      'mortgage' => _mortgage(a, move['square']),
      'unmortgage' => _unmortgage(a, move['square']),
      'payBail' => _payBail(),
      'useCard' => _useCard(),
      'endTurn' => _endTurn(),
      'tradeOffer' => _tradeOffer(move),
      'tradeAccept' => _tradeAnswer(true),
      'tradeDecline' => _tradeAnswer(false),
      'bankrupt' => _bankrupt(),
      _ => false,
    };
    return ok ? _accept(move) : null;
  }

  PropertyEvent _accept(Map<String, dynamic> move) {
    _history.add(Map.of(move));
    return PropertyEvent(List.unmodifiable(_ev));
  }

  int _nextDie() => _scriptedDice.isNotEmpty ? _scriptedDice.removeAt(0) : _rng.nextInt(6) + 1;

  bool _roll() {
    if (phase != PropertyPhase.roll) return false;
    final d1 = _nextDie(), d2 = _nextDie();
    _dice = [d1, d2];
    final doubles = d1 == d2;
    _ev.add({'type': 'rolled', 'dice': [d1, d2]});
    final s = _seats[_current];
    if (s.inPause) {
      _rollAgain = false;
      if (doubles) {
        s.inPause = false;
        s.pauseTries = 0;
        _ev.add({'type': 'leftPause', 'by': 'doubles'});
      } else if (++s.pauseTries >= maxPauseTries) {
        s.inPause = false;
        s.pauseTries = 0;
        _ev.add({'type': 'leftPause', 'by': 'bail'});
        _charge(_current, null, bail, 'bail');
      } else {
        _ev.add({'type': 'stayInPause', 'tries': s.pauseTries});
        _turnPhase = PropertyPhase.end;
        return true;
      }
      _moveBy(d1 + d2);
      return true;
    }
    if (doubles && ++_doubles >= 3) {
      _ev.add({'type': 'threeDoubles'});
      _sendToPause();
      return true;
    }
    _rollAgain = doubles;
    _moveBy(d1 + d2);
    return true;
  }

  void _moveBy(int steps) {
    final s = _seats[_current];
    final to = s.pos + steps;
    if (to >= 40) _salary();
    s.pos = to % 40;
    _ev.add({'type': 'moved', 'to': s.pos});
    _land();
  }

  void _salary() {
    _seats[_current].cash += startSalary;
    _bank -= startSalary;
    _ev.add({'type': 'salary', 'seat': _current, 'amount': startSalary});
  }

  void _land() {
    final pos = _seats[_current].pos;
    final sq = _board[pos];
    switch (sq.kind) {
      case PropertyKind.street || PropertyKind.station || PropertyKind.utility:
        final owner = _owner[pos];
        if (owner == null) {
          _turnPhase = PropertyPhase.buy;
          return;
        }
        if (owner != _current) {
          final rent = rentFor(pos);
          if (rent > 0) _charge(_current, owner, rent, 'rent');
        }
      case PropertyKind.tax:
        _charge(_current, null, sq.amount, 'tax');
      case PropertyKind.surprise:
        _draw(PropertyDeck.surprise);
        return;
      case PropertyKind.neighbourhood:
        _draw(PropertyDeck.neighbourhood);
        return;
      case PropertyKind.goToPause:
        _sendToPause();
        return;
      case PropertyKind.start || PropertyKind.pause || PropertyKind.free:
        break;
    }
    _afterLanding();
  }

  void _afterLanding() => _turnPhase = _rollAgain ? PropertyPhase.roll : PropertyPhase.end;

  void _sendToPause() {
    final s = _seats[_current];
    s
      ..pos = pauseSquare
      ..inPause = true
      ..pauseTries = 0;
    _rollAgain = false;
    _turnPhase = PropertyPhase.end;
    _ev.add({'type': 'toPause', 'seat': _current});
  }

  void _draw(PropertyDeck deck) {
    final cards = _decks[deck]!;
    final card = cards.removeAt(0);
    _ev.add({'type': 'card', 'deck': deck.name, 'id': card.id});
    final s = _seats[_current];
    if (card.kind == PropertyCardKind.freeCard) {
      s.freeCards.add(card.id);
    } else {
      cards.add(card);
    }
    switch (card.kind) {
      case PropertyCardKind.advanceTo:
        _moveBy((card.value - s.pos + 40) % 40);
        return;
      case PropertyCardKind.nearestStation:
        var steps = 1;
        while (_board[(s.pos + steps) % 40].kind != PropertyKind.station) {
          steps++;
        }
        _moveBy(steps);
        return;
      case PropertyCardKind.backTo || PropertyCardKind.back:
        s.pos = card.kind == PropertyCardKind.back ? (s.pos - card.value + 40) % 40 : card.value;
        _ev.add({'type': 'moved', 'to': s.pos});
        _land();
        return;
      case PropertyCardKind.toPause:
        _sendToPause();
        return;
      case PropertyCardKind.collect:
        s.cash += card.value;
        _bank -= card.value;
        _ev.add({'type': 'collected', 'seat': _current, 'amount': card.value});
      case PropertyCardKind.pay:
        _charge(_current, null, card.value, 'card');
      case PropertyCardKind.collectEach:
        for (final o in activeSeats) {
          if (o != _current) _charge(o, _current, card.value, 'card');
        }
      case PropertyCardKind.payEach:
        for (final o in activeSeats) {
          if (o != _current) _charge(_current, o, card.value, 'card');
        }
      case PropertyCardKind.repairs:
        var total = 0;
        for (final i in ownedBy(_current)) {
          total += _houses[i] == 5 ? card.value2 : _houses[i] * card.value;
        }
        _charge(_current, null, total, 'card');
      case PropertyCardKind.freeCard:
        break;
    }
    _afterLanding();
  }

  /// [debtor] owes [amount] to [creditor] (null = bank): queued, paid at once
  /// if the cash suffices and nothing is queued before it.
  void _charge(int debtor, int? creditor, int amount, String reason) {
    if (amount <= 0) return;
    _debts.add(PropertyDebt(debtor, creditor, amount, reason));
    _settleDebts();
  }

  /// Pays queued debts from the front while the debtor can.
  void _settleDebts() {
    while (_debts.isNotEmpty && _seats[_debts.first.debtor].cash >= _debts.first.amount) {
      final d = _debts.removeAt(0);
      _transfer(d.debtor, d.creditor, d.amount);
      _ev.add({'type': 'paid', ...d.toJson()});
    }
  }

  void _transfer(int from, int? to, int amount) {
    _seats[from].cash -= amount;
    if (to == null) {
      _bank += amount;
    } else {
      _seats[to].cash += amount;
    }
  }

  bool _buy() {
    if (phase != PropertyPhase.buy) return false;
    final s = _seats[_current];
    final sq = _board[s.pos];
    if (s.cash < sq.price) return false;
    _transfer(_current, null, sq.price);
    _owner[s.pos] = _current;
    _ev.add({'type': 'bought', 'seat': _current, 'square': s.pos, 'price': sq.price});
    _afterLanding();
    return true;
  }

  bool _decline() {
    if (phase != PropertyPhase.buy) return false;
    final order = [for (var k = 1; k <= playerCount; k++) (_current + k) % playerCount];
    _auction = PropertyAuction(_seats[_current].pos, [for (final s in order) if (!_seats[s].out) s]);
    _ev.add({'type': 'auction', 'square': _auction!.square});
    return true;
  }

  bool _bid(Object? amount) {
    final au = _auction;
    if (phase != PropertyPhase.auction || amount is! int) return false;
    if (amount < au!.minBid || amount > _seats[au.actor].cash) return false;
    au
      ..high = amount
      ..highSeat = au.actor;
    _ev.add({'type': 'bid', 'seat': au.actor, 'amount': amount});
    au.turn = (au.turn + 1) % au.bidders.length;
    _auctionNext();
    return true;
  }

  bool _pass() {
    if (phase != PropertyPhase.auction) return false;
    final au = _auction!;
    _ev.add({'type': 'passed', 'seat': au.actor});
    au.bidders.removeAt(au.turn);
    if (au.turn >= au.bidders.length) au.turn = 0;
    _auctionNext();
    return true;
  }

  /// Ends the auction when it is decided; else skips the high bidder.
  void _auctionNext() {
    final au = _auction!;
    if (au.bidders.isEmpty) {
      _auction = null;
      _ev.add({'type': 'unsold', 'square': au.square});
      _afterLanding();
      return;
    }
    if (au.bidders.length == 1 && au.highSeat == au.bidders.first) {
      final w = au.highSeat!;
      _transfer(w, null, au.high);
      _owner[au.square] = w;
      _auction = null;
      _ev.add({'type': 'bought', 'seat': w, 'square': au.square, 'price': au.high, 'auction': true});
      _afterLanding();
      return;
    }
    if (au.actor == au.highSeat) au.turn = (au.turn + 1) % au.bidders.length;
  }

  static int? _square(Object? v) => v is int && _validSquare(v) ? v : null;

  bool _build(int a, Object? square) {
    final i = _square(square);
    if (i == null || !canBuild(a, i)) return false;
    _transfer(a, null, _board[i].houseCost);
    _houses[i]++;
    _ev.add({'type': 'built', 'seat': a, 'square': i, 'houses': _houses[i]});
    return true;
  }

  bool _sell(int a, Object? square) {
    final i = _square(square);
    if (i == null || !canSell(a, i)) return false;
    final refund = _board[i].houseCost ~/ 2;
    _seats[a].cash += refund;
    _bank -= refund;
    _houses[i]--;
    _ev.add({'type': 'sold', 'seat': a, 'square': i, 'houses': _houses[i], 'amount': refund});
    _settleDebts();
    return true;
  }

  bool _mortgage(int a, Object? square) {
    final i = _square(square);
    if (i == null || !canMortgage(a, i)) return false;
    final v = _board[i].mortgageValue;
    _seats[a].cash += v;
    _bank -= v;
    _mortgaged[i] = true;
    _ev.add({'type': 'mortgaged', 'seat': a, 'square': i, 'amount': v});
    _settleDebts();
    return true;
  }

  bool _unmortgage(int a, Object? square) {
    final i = _square(square);
    if (i == null || !canUnmortgage(a, i)) return false;
    final cost = _board[i].unmortgageCost;
    _transfer(a, null, cost);
    _mortgaged[i] = false;
    _ev.add({'type': 'unmortgaged', 'seat': a, 'square': i, 'amount': cost});
    return true;
  }

  bool _payBail() {
    final s = _seats[_current];
    if (phase != PropertyPhase.roll || !s.inPause || s.cash < bail) return false;
    _transfer(_current, null, bail);
    s
      ..inPause = false
      ..pauseTries = 0;
    _ev.add({'type': 'leftPause', 'by': 'payBail'});
    return true;
  }

  bool _useCard() {
    final s = _seats[_current];
    if (phase != PropertyPhase.roll || !s.inPause || s.freeCards.isEmpty) return false;
    final id = s.freeCards.removeAt(0);
    _returnFreeCard(id);
    s
      ..inPause = false
      ..pauseTries = 0;
    _ev.add({'type': 'leftPause', 'by': 'card', 'id': id});
    return true;
  }

  /// Puts the free card [id] back under its deck.
  void _returnFreeCard(String id) {
    final card = theme.card(id)!;
    _decks[card.deck]!.add(card);
  }

  bool _endTurn() {
    if (phase != PropertyPhase.end) return false;
    _nextTurn();
    return true;
  }

  bool _tradeOffer(Map<String, dynamic> move) {
    final to = move['to'];
    final give = PropertyTradeSide.parse(move['give']), get = PropertyTradeSide.parse(move['get']);
    if (to is! int || give == null || get == null || tradeProblem(to, give, get) != null) return false;
    _trade = PropertyTrade(_current, to, give, get);
    _tradeOffers++;
    _ev.add({'type': 'tradeOffered', ..._trade!.toJson()});
    return true;
  }

  bool _tradeAnswer(bool accept) {
    final t = _trade;
    if (phase != PropertyPhase.trade) return false;
    _trade = null;
    if (!accept) {
      _ev.add({'type': 'tradeDeclined', 'from': t!.from, 'to': t.to});
      return true;
    }
    void move(int from, int to, PropertyTradeSide side) {
      _seats[from].cash -= side.money;
      _seats[to].cash += side.money;
      for (final i in side.squares) {
        _owner[i] = to;
      }
      for (var k = 0; k < side.cards; k++) {
        _seats[to].freeCards.add(_seats[from].freeCards.removeAt(0));
      }
    }

    move(t!.from, t.to, t.give);
    move(t.to, t.from, t.get);
    _ev.add({'type': 'traded', ...t.toJson()});
    return true;
  }

  bool _bankrupt() {
    if (phase != PropertyPhase.debt) return false;
    final d = _debts.first;
    _ev.add({'type': 'bankrupt', 'seat': d.debtor, if (d.creditor != null) 'to': d.creditor});
    _eliminate(d.debtor, d.creditor);
    return true;
  }

  /// Takes [seat] out of the game. Houses go back to the bank for half their
  /// cost; then cash, properties (mortgages included) and free cards go to
  /// [creditor], or with no creditor the cash to the bank, the properties
  /// back to the bank unmortgaged and the free cards under their decks.
  /// Debts from and to the seat lapse.
  void _eliminate(int seat, int? creditor) {
    final s = _seats[seat];
    for (final i in ownedBy(seat)) {
      if (_houses[i] > 0) {
        final refund = _houses[i] * (_board[i].houseCost ~/ 2);
        s.cash += refund;
        _bank -= refund;
        _houses[i] = 0;
      }
    }
    if (creditor != null) {
      _seats[creditor].cash += s.cash;
      for (final i in ownedBy(seat)) {
        _owner[i] = creditor;
      }
      _seats[creditor].freeCards.addAll(s.freeCards);
    } else {
      _bank += s.cash;
      for (final i in ownedBy(seat)) {
        _owner[i] = null;
        _mortgaged[i] = false;
      }
      s.freeCards.forEach(_returnFreeCard);
    }
    s
      ..cash = 0
      ..freeCards.clear()
      ..inPause = false
      ..pauseTries = 0
      ..out = true;
    _debts.removeWhere((d) => d.debtor == seat || d.creditor == seat);
    if (_trade != null && (_trade!.from == seat || _trade!.to == seat)) _trade = null;
    final au = _auction;
    if (au != null && seat != _current) {
      final at = au.bidders.indexOf(seat);
      if (at >= 0) {
        au.bidders.removeAt(at);
        if (at < au.turn) au.turn--;
        if (au.turn >= au.bidders.length) au.turn = 0;
      }
      if (au.highSeat == seat) {
        au
          ..highSeat = null
          ..high = 0;
      }
      _auctionNext();
    }
    final left = activeSeats;
    if (left.length == 1) {
      _auction = null;
      _trade = null;
      _result = PropertyResult(
          isOver: true, winner: left.single, code: 'property.lastSolvent', reason: 'everyone else is bankrupt');
      _ev.add({'type': 'over', ..._result.toJson()});
      return;
    }
    if (seat == _current) {
      _auction = null;
      _trade = null;
      _nextTurn();
    }
    _settleDebts();
  }

  void _nextTurn() {
    final prev = _current;
    var next = prev;
    do {
      next = (next + 1) % playerCount;
    } while (_seats[next].out);
    if (next <= prev) {
      _rounds++;
      if (maxRounds != null && _rounds >= maxRounds!) {
        _finishByWorth();
        return;
      }
    }
    _current = next;
    _turnPhase = PropertyPhase.roll;
    _rollAgain = false;
    _doubles = 0;
    _tradeOffers = 0;
    _ev.add({'type': 'turn', 'seat': next});
  }

  void _finishByWorth() {
    final worth = {for (final s in activeSeats) s: netWorth(s)};
    final best = worth.values.reduce(max);
    final leaders = [for (final e in worth.entries) if (e.value == best) e.key];
    _result = PropertyResult(
        isOver: true,
        winner: leaders.length == 1 ? leaders.single : null,
        leaders: leaders.length == 1 ? const [] : leaders,
        code: 'property.roundLimit',
        reason: leaders.length == 1 ? 'richest after $_rounds rounds' : 'tie after $_rounds rounds');
    _debts.clear();
    _auction = null;
    _trade = null;
    _ev.add({'type': 'over', ..._result.toJson()});
  }

  // ------------------------------------------------------------- debugging

  /// Test and demo setup, not a move (not in the history, not replayed):
  /// gives [square] to [seat] (null = bank) with [houses] and [mortgaged].
  void debugSetSquare(int square, int? seat, {int houses = 0, bool mortgaged = false}) {
    _owner[square] = seat;
    _houses[square] = houses;
    _mortgaged[square] = mortgaged;
  }

  /// Test and demo setup: sets [seat]'s cash (the bank balances it, so the
  /// money invariant holds) and optionally its position.
  void debugSetCash(int seat, int cash, {int? pos}) {
    _bank -= cash - _seats[seat].cash;
    _seats[seat].cash = cash;
    if (pos != null) _seats[seat].pos = pos;
  }

  // ------------------------------------------------------------------ view

  /// The public state as JSON: everything every player may see. Leaves out
  /// the seed and the deck order (only the deck sizes).
  Map<String, dynamic> toJson() => {
        'players': playerCount,
        'theme': theme.id,
        if (maxRounds != null) 'maxRounds': maxRounds,
        'rounds': _rounds,
        'current': _current,
        'phase': phase.name,
        if (actor != null) 'actor': actor,
        if (_dice != null) 'dice': List.of(_dice!),
        if (_doubles > 0) 'doubles': _doubles,
        'seats': [for (final s in _seats) s.toJson()],
        'squares': {
          for (var i = 0; i < 40; i++)
            if (_owner[i] != null)
              '$i': {'owner': _owner[i], if (_houses[i] > 0) 'houses': _houses[i], if (_mortgaged[i]) 'mortgaged': true},
        },
        'decks': {for (final d in PropertyDeck.values) d.name: _decks[d]!.length},
        if (_auction != null) 'auction': _auction!.toJson(),
        if (_trade != null) 'trade': _trade!.toJson(),
        if (_debts.isNotEmpty) 'debts': [for (final d in _debts) d.toJson()],
        if (_result.isOver) 'result': _result.toJson(),
      };
}
