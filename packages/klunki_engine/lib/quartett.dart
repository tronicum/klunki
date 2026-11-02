import 'dart:math';

import 'game.dart';
import 'secrecy.dart';

part 'quartett_decks.dart';
part 'quartett_view.dart';

/// Quartett for two players, in two flavours, with any [QuartettDeck] of 32
/// cards (8 sets A–H × 4 cards, ids like `B3`; KLD-069: cars, trains,
/// rockets, planes):
///
/// * [QuartettMode.trumpf] — Quartett (Trumpf), Trumpf mode: compare a stat of
///   the two top cards, the better value takes the trick.
/// * [QuartettMode.sets] — classic Quartett: ask the opponent for cards and
///   collect complete sets ("quartets").
enum QuartettMode { trumpf, sets }

/// One comparable value on a card.
class QuartettStat {
  final String id;
  final String label;
  final String unit;

  /// `true`: the larger value wins; `false`: the smaller value wins.
  final bool higherWins;

  /// Most digits after the decimal point the values of this stat use
  /// (0 = whole numbers). The display never shows more; [QuartettDeck.validate]
  /// rejects values with more. Whole-number stats (years, counts, PS, kW, ...)
  /// always print as integers, even on the web, where every number is a JS
  /// double (`1999 is double` is true there: the "1999,0" bug, KLD-082).
  final int decimals;

  /// Always show exactly [decimals] digits ("7.0 s"); otherwise trailing
  /// zeros are dropped ("70 m", "110.6 m").
  final bool fixedDecimals;

  /// A calendar year: bare digits, no unit, no decimals, never grouped
  /// ("1990", not "1.990"). No deck uses a year since KLD-082 (years made a
  /// poor "older/newer" trump), the format stays for future decks. Every
  /// other value is grouped by the app per locale ("35.100 kN" in de,
  /// KLD-110); [formatNumber] never groups (CLI, data).
  final bool isYear;

  /// A percentage (unit `%`): the app formats it per locale ("99 %" in de,
  /// "99%" in en).
  bool get isPercent => unit == '%';

  const QuartettStat(
      {required this.id,
      required this.label,
      required this.unit,
      this.higherWins = true,
      this.decimals = 0,
      this.fixedDecimals = false,
      this.isYear = false})
      : assert(!isYear || decimals == 0),
        assert(decimals >= 0 && decimals <= 3);

  /// [v] as plain ASCII digits with `.` as the decimal point and no grouping,
  /// per [decimals] / [fixedDecimals], without unit. The app swaps in the
  /// locale's decimal separator and thousands grouping.
  String formatNumber(num v) {
    if (decimals == 0) return v.round().toString();
    final s = v.toStringAsFixed(decimals);
    if (fixedDecimals) return s;
    var t = s;
    while (t.endsWith('0')) {
      t = t.substring(0, t.length - 1);
    }
    return t.endsWith('.') ? t.substring(0, t.length - 1) : t;
  }

  /// Whether [x] beats [y] for this stat.
  bool beats(num x, num y) => higherWins ? x > y : x < y;
}

/// A single Quartett card. [set] is the set letter `A`–`H`, [deck] the id of
/// its [QuartettDeck] (ids `A1`…`H4` repeat across decks).
class Card {
  final String id;
  final String name;
  final String set;
  final String deck;
  final Map<String, num> stats;
  const Card(
      {required this.id,
      required this.name,
      required this.set,
      this.deck = QuartettDeck.defaultId,
      required this.stats});

  @override
  String toString() => '$id $name';
}

/// Rules engine. Moves:
/// * trumpf: `{'action': 'pick', 'stat': id}`, with [pickLowCards] also
///   `{'action': 'choose', 'card': id}` (see below)
/// * sets:   `{'action': 'ask', 'card': id}`
///
/// An illegal move, or any move after the game is over, returns `null` and
/// leaves the state untouched.
///
/// Sets-mode decisions:
/// * By default all 32 cards are dealt (16 each). With two players and no
///   stock, the opponent necessarily holds every card the asker may legally
///   ask for, so every legal ask hits. Pass a smaller `handSize` to keep a
///   face-down stock (Go-Fish style): on a miss the asker draws one card from
///   the stock (if any) and the turn passes.
/// * Quartets are laid down automatically whenever a hand holds all four cards
///   of a set — right after the deal, after a hit and after a draw.
/// * A player whose turn starts with an empty hand draws one card from the
///   stock; if the stock is empty the turn passes to the opponent. (With two
///   players and an empty stock that pass cannot actually occur: all
///   remaining cards would be in the opponent's hand, i.e. complete sets that
///   are already down, so the game is over. It is kept as a safe fallback.)
/// * A player holding any card always has a legal ask (every held set is
///   incomplete), so the game always progresses until all 8 sets are down.
/// * If the deal alone completes all 8 sets (e.g. 4 quartets each), the game
///   is over before the first move.
///
/// Trumpf-mode decisions:
/// * A tie puts both cards into the pot; the same player picks again.
/// * After each trick, a player with an empty stack loses. If both stacks are
///   empty (the last cards tied into the pot) the game is a draw.
/// * After [maxTricks] tricks the larger stack wins (pot ignored); equal is a
///   draw.
///
/// Trumpf house rule [pickLowCards] (KLD-100, "with 3 or fewer cards you
/// choose"): a player whose stack (pot excluded) holds at most
/// [pickLowLimit] cards sees all of them and chooses the card to play
/// instead of playing the top card. One round then runs:
/// 1. the picker, if low, chooses a card (`choose`; the turn stays);
/// 2. the picker announces the stat (`pick`);
/// 3. the defender, if low, chooses a card knowing the stat (`choose`; during
///    this phase [currentPlayer] is the defender, [picker] stays the picker,
///    [announcedStat] is set);
/// 4. the two played cards ([playedCard]) are compared as usual: a chosen card
///    leaves the stack exactly like the top card would, the rest keeps its
///    order; tie-break (Stechen) and pot are unchanged.
/// With more than [pickLowLimit] cards a player plays the top card again; a
/// single last card has no alternative and plays like a top card (no choice).
/// The trick payload names the [picker] (`picker`) when the defender's
/// choice completed it, and the players who chose (`chosen`).
class QuartettGame extends Game {
  static const int maxTricks = 200;

  /// Highest stack size at which [pickLowCards] lets a player choose.
  static const int pickLowLimit = 3;

  /// The deck in play (default: [QuartettDeck.cars]).
  final QuartettDeck deck;

  /// The stats of [deck], in card order.
  List<QuartettStat> get stats => deck.stats;

  /// Display names (engine, German) of the eight sets of [deck].
  Map<String, String> get setNames => deck.setNames;

  /// All 32 cards of [deck], sorted by id.
  List<Card> get cards => deck.cards;

  /// Stands for a card the viewer may not see (opponent's cards and the
  /// face-down stock in a [QuartettView]). Never part of [deck].
  static const Card hiddenCard = Card(id: '?', name: '?', set: '?', deck: '?', stats: {});

  /// Looks up a card of [deck] by id; null if unknown.
  Card? cardById(String id) => deck.cardById(id);

  QuartettStat? statById(String id) => deck.statById(id);

  final QuartettMode mode;
  final int seed;

  /// Cards dealt to each player in sets mode (16 = whole deck, no stock).
  final int handSize;

  /// Trumpf house rule (KLD-100): with at most [pickLowLimit] cards a player
  /// chooses the card to play. Off for a bare engine (the classic rules); the
  /// app's [GameConfig] turns it on by default.
  final bool pickLowCards;

  Player _current = Player.a;
  Player? _winner;
  bool _draw = false;
  String _reason = '';
  GameEndReason? _code;
  Map<String, int> _params = const {};
  final List<Map<String, dynamic>> _history = [];

  // trumpf: stacks, front = top.
  final Map<Player, List<Card>> _stacks = {Player.a: [], Player.b: []};
  final List<Card> _pot = [];
  int _tricks = 0;
  // pickLowCards: the cards chosen this round, the stat announced while the
  // defender chooses.
  final Map<Player, Card?> _chosen = {Player.a: null, Player.b: null};
  QuartettStat? _announced;

  // sets: hands, stock (front = top), laid-down set letters.
  final Map<Player, List<Card>> _hands = {Player.a: [], Player.b: []};
  final List<Card> _stock = [];
  final Map<Player, List<String>> _quartets = {Player.a: [], Player.b: []};

  QuartettGame(this.mode, {this.seed = 0, this.handSize = 16, QuartettDeck? deck, this.pickLowCards = false})
      : deck = deck ?? QuartettDeck.cars,
        assert(handSize >= 1 && handSize <= 16) {
    final cards = List<Card>.of(this.deck.cards);
    final rnd = Random(seed);
    for (var i = cards.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final t = cards[i];
      cards[i] = cards[j];
      cards[j] = t;
    }
    if (mode == QuartettMode.trumpf) {
      for (var i = 0; i < cards.length; i++) {
        _stacks[i.isEven ? Player.a : Player.b]!.add(cards[i]);
      }
    } else {
      for (var i = 0; i < handSize * 2; i++) {
        _hands[i.isEven ? Player.a : Player.b]!.add(cards[i]);
      }
      _stock.addAll(cards.skip(handSize * 2));
      _layDownAll(Player.a);
      _layDownAll(Player.b);
      _checkSetsOver();
      _startTurn();
    }
  }

  /// The player to act: the [picker], or the defender while it chooses its
  /// card for the [announcedStat].
  @override
  Player get currentPlayer => _announced != null ? _other(_current) : _current;

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

  // --- trumpf getters ---

  /// Top card of [p]'s stack, or null if empty.
  Card? topCard(Player p) => _stacks[p]!.isEmpty ? null : _stacks[p]!.first;
  int stackSize(Player p) => _stacks[p]!.length;

  /// [p]'s whole stack, top first (for inspection; face-down in the UI).
  List<Card> stackOf(Player p) => List.unmodifiable(_stacks[p]!);
  int get potSize => _pot.length;
  int get tricks => _tricks;

  /// Trumpf: the player who announces the stat this round (equals
  /// [currentPlayer] except while the defender chooses).
  Player get picker => _current;

  /// [pickLowCards]: the stat the picker announced while the defender still
  /// chooses its card; null otherwise.
  QuartettStat? get announcedStat => _announced;

  /// [pickLowCards]: the card [p] chose this round (null: none yet).
  Card? chosenCard(Player p) => _chosen[p];

  /// Whether [p] chooses its card ([pickLowCards] and at most
  /// [pickLowLimit] cards left; a single card has no choice and plays like a
  /// top card).
  bool choosesCard(Player p) =>
      mode == QuartettMode.trumpf && pickLowCards && _stacks[p]!.length >= 2 && _stacks[p]!.length <= pickLowLimit;

  /// The [currentPlayer] has to choose a card now (`choose` moves).
  bool get mustChoose => !isOver && choosesCard(currentPlayer) && _chosen[currentPlayer] == null;

  /// The card [p] plays this round: the chosen one, else the top card.
  Card? playedCard(Player p) => _chosen[p] ?? topCard(p);

  // --- sets getters ---

  /// [p]'s hand, sorted by id.
  List<Card> handOf(Player p) => List.unmodifiable(
      List<Card>.of(_hands[p]!)..sort((x, y) => x.id.compareTo(y.id)));

  /// Set letters laid down by [p], in order of completion.
  List<String> quartetsOf(Player p) => List.unmodifiable(_quartets[p]!);
  int get stockSize => _stock.length;

  /// What [viewer] may know, as JSON (KLD-064, see [QuartettRedaction]):
  /// counts, laid-down quartets, the viewer's own top card (Trumpf) or hand
  /// (Sets). Never the opponent's cards, the stock or the seed.
  Map<String, dynamic> viewJson(Player viewer) => {
        'viewer': viewer.name,
        'mode': mode.name,
        'deck': deck.id,
        'handSize': handSize,
        'current': currentPlayer.name,
        'result': resultToJson(playResult),
        if (resignedBy != null) 'resigned': resignedBy!.name,
        if (mode == QuartettMode.trumpf) ...{
          'tricks': tricks,
          'pot': potSize,
          'stacks': {'a': stackSize(Player.a), 'b': stackSize(Player.b)},
          'top': topCard(viewer)?.id,
          if (pickLowCards) 'pickLow': true,
          // KLD-100: a low player sees its whole stack; only its own choice.
          if (choosesCard(viewer)) 'hand': [for (final c in _stacks[viewer]!) c.id],
          if (_chosen[viewer] case final c?) 'chosen': c.id,
          if (_announced case final s?) 'announced': s.id,
        } else ...{
          'hand': [for (final c in handOf(viewer)) c.id],
          'hands': {'a': handOf(Player.a).length, 'b': handOf(Player.b).length},
          'stock': stockSize,
          'quartets': {'a': quartetsOf(Player.a), 'b': quartetsOf(Player.b)},
        },
      };

  /// Legal moves for [currentPlayer]; empty when the game is over.
  List<Map<String, dynamic>> get legalMoves {
    if (isOver) return const [];
    if (mode == QuartettMode.trumpf) {
      if (mustChoose) {
        return [
          for (final c in _stacks[currentPlayer]!) {'action': 'choose', 'card': c.id}
        ];
      }
      if (_announced != null) return const []; // unreachable: the defender chooses
      return [
        for (final s in stats) {'action': 'pick', 'stat': s.id}
      ];
    }
    final hand = _hands[_current]!;
    final held = hand.map((c) => c.id).toSet();
    final sets = hand.map((c) => c.set).toSet();
    return [
      for (final c in deck.cards)
        if (sets.contains(c.set) && !held.contains(c.id))
          {'action': 'ask', 'card': c.id}
    ];
  }

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) {
    if (isOver) return null;
    if (mode == QuartettMode.sets) return _ask(move);
    return move['action'] == 'choose' ? _choose(move) : _pick(move);
  }

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;

  GameEvent _event(Map<String, dynamic> payload) =>
      GameEvent(winner: _winner, draw: _draw, payload: payload);

  // --- trumpf ---

  GameEvent? _pick(Map<String, dynamic> move) {
    if (move['action'] != 'pick' || _announced != null) return null;
    final stat = move['stat'];
    final s = stat is String ? statById(stat) : null;
    if (s == null) return null;
    if (topCard(Player.a) == null || topCard(Player.b) == null) return null; // unreachable: game is over
    if (mustChoose) return null; // a low picker chooses its card first

    _history.add({'player': _current, 'action': 'pick', 'stat': s.id});
    if (choosesCard(_other(_current))) {
      // KLD-100: the defender chooses its card for the announced stat.
      _announced = s;
      return _event({'stat': s.id, 'announced': true});
    }
    return _resolve(s);
  }

  /// KLD-100: the low picker (before `pick`) or the low defender (after it)
  /// chooses the card to play; the defender's choice completes the round.
  GameEvent? _choose(Map<String, dynamic> move) {
    if (!mustChoose) return null;
    final id = move['card'];
    final me = currentPlayer;
    final card = _stacks[me]!.where((c) => c.id == id).firstOrNull;
    if (card == null) return null;
    _chosen[me] = card;
    _history.add({'player': me, 'action': 'choose', 'card': card.id});
    final s = _announced;
    if (s == null) return _event({'chose': true});
    return _resolve(s);
  }

  /// Compares the played cards of both players for [s] and settles the
  /// round.
  GameEvent _resolve(QuartettStat s) {
    final ca = playedCard(Player.a)!, cb = playedCard(Player.b)!;
    final picker = _current;
    final byDefender = _announced != null;
    final chose = [for (final p in Player.values) if (_chosen[p] != null) p.name];
    _stacks[Player.a]!.remove(ca);
    _stacks[Player.b]!.remove(cb);
    _chosen[Player.a] = null;
    _chosen[Player.b] = null;
    _announced = null;
    final va = ca.stats[s.id]!, vb = cb.stats[s.id]!;
    Player? trickWinner;
    if (s.beats(va, vb)) {
      trickWinner = Player.a;
    } else if (s.beats(vb, va)) {
      trickWinner = Player.b;
    }

    if (trickWinner == null) {
      _pot.addAll([ca, cb]);
    } else {
      final own = trickWinner == Player.a ? ca : cb;
      final opp = trickWinner == Player.a ? cb : ca;
      _stacks[trickWinner]!.addAll([own, opp, ..._pot]);
      _pot.clear();
      _current = trickWinner;
    }
    _tricks++;
    _checkTrumpfOver();
    return _event({
      'stat': s.id,
      'cards': {'a': ca.id, 'b': cb.id},
      'values': {'a': va, 'b': vb},
      'trickWinner': trickWinner?.name,
      'pot': _pot.length,
      if (byDefender) 'picker': picker.name,
      if (chose.isNotEmpty) 'chosen': chose,
    });
  }

  void _checkTrumpfOver() {
    final ea = _stacks[Player.a]!.isEmpty, eb = _stacks[Player.b]!.isEmpty;
    if (ea && eb) {
      _draw = true;
      _reason = 'both stacks empty';
      _code = GameEndReason.quartettBothStacksEmpty;
    } else if (ea || eb) {
      _winner = ea ? Player.b : Player.a;
      _reason = 'opponent has no cards left';
      _code = GameEndReason.quartettAllCards;
    } else if (_tricks >= maxTricks) {
      final na = stackSize(Player.a), nb = stackSize(Player.b);
      if (na == nb) {
        _draw = true;
        _reason = 'round limit reached with equal stacks ($na:$nb)';
        _code = GameEndReason.quartettTrickLimitEqual;
        _params = {'a': na, 'b': nb};
      } else {
        _winner = na > nb ? Player.a : Player.b;
        _reason = 'round limit reached, more cards ($na:$nb)';
        _code = GameEndReason.quartettTrickLimitMoreCards;
        _params = {'a': na, 'b': nb};
      }
    }
  }

  // --- sets ---

  GameEvent? _ask(Map<String, dynamic> move) {
    if (move['action'] != 'ask') return null;
    final id = move['card'];
    final card = id is String ? deck.cardById(id) : null;
    if (card == null) return null;
    final me = _current, opp = _other(me);
    final hand = _hands[me]!;
    if (hand.any((c) => c.id == card.id)) return null; // own card
    if (!hand.any((c) => c.set == card.set)) return null; // set not held
    // A laid-down set can't be held, so the check above covers it too.

    final oppHand = _hands[opp]!;
    final idx = oppHand.indexWhere((c) => c.id == card.id);
    final hit = idx >= 0;
    String? drew;
    String? quartet;
    if (hit) {
      hand.add(oppHand.removeAt(idx));
      quartet = _layDown(me, card.set);
    } else {
      if (_stock.isNotEmpty) {
        final d = _stock.removeAt(0);
        hand.add(d);
        drew = d.id;
        quartet = _layDown(me, d.set);
      }
      _current = opp;
    }
    _history.add({'player': me, 'action': 'ask', 'card': card.id});
    _checkSetsOver();
    if (!isOver) _startTurn();
    return _event({
      'card': card.id,
      'from': opp.name,
      'hit': hit,
      'quartet': quartet,
      'drew': drew,
    });
  }

  /// Lays down [set] for [p] if their hand holds all four; returns the letter.
  String? _layDown(Player p, String set) {
    final hand = _hands[p]!;
    if (hand.where((c) => c.set == set).length < 4) return null;
    hand.removeWhere((c) => c.set == set);
    _quartets[p]!.add(set);
    return set;
  }

  void _layDownAll(Player p) {
    for (final s in setNames.keys) {
      _layDown(p, s);
    }
  }

  /// Ensures the current player can ask: draw if the hand is empty, else pass.
  void _startTurn() {
    if (isOver || _hands[_current]!.isNotEmpty) return;
    if (_stock.isNotEmpty) {
      _hands[_current]!
          .add(_stock.removeAt(0)); // one card never completes a set
    } else {
      _current = _other(_current); // opponent must hold cards (game not over)
    }
  }

  void _checkSetsOver() {
    final qa = _quartets[Player.a]!.length, qb = _quartets[Player.b]!.length;
    if (qa + qb < setNames.length) return;
    if (qa == qb) {
      _draw = true;
      _reason = 'all quartets laid down, $qa:$qb';
      _code = GameEndReason.quartettAllQuartetsEqual;
      _params = {'a': qa, 'b': qb};
    } else {
      _winner = qa > qb ? Player.a : Player.b;
      _reason = 'more quartets ($qa:$qb)';
      _code = GameEndReason.quartettMostQuartets;
      _params = {'a': qa, 'b': qb};
    }
  }
}
