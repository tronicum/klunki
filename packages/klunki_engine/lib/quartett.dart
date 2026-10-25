import 'dart:math';

import 'game.dart';

/// Quartett for two players, in two flavours sharing one 32-card deck
/// (8 sets A–H × 4 cards, ids like `B3`):
///
/// * [QuartettMode.trumpf] — Auto-Quartett / Supertrumpf: compare a stat of
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
  const QuartettStat(
      {required this.id,
      required this.label,
      required this.unit,
      this.higherWins = true});

  /// Whether [x] beats [y] for this stat.
  bool beats(num x, num y) => higherWins ? x > y : x < y;
}

/// A single Quartett card. [set] is the set letter `A`–`H`.
class Card {
  final String id;
  final String name;
  final String set;
  final Map<String, num> stats;
  const Card(
      {required this.id,
      required this.name,
      required this.set,
      required this.stats});

  @override
  String toString() => '$id $name';
}

Card _c(String id, String name, num ps, num kmh, num ccm, num kg, num sec) =>
    Card(id: id, name: name, set: id[0], stats: {
      'ps': ps, 'kmh': kmh, 'ccm': ccm, 'kg': kg, 'sec0to100': sec, //
    });

/// Rules engine. Moves:
/// * trumpf: `{'action': 'pick', 'stat': id}`
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
class QuartettGame implements Game {
  static const int maxTricks = 200;

  static const List<QuartettStat> stats = [
    QuartettStat(id: 'ps', label: 'Leistung', unit: 'PS'),
    QuartettStat(id: 'kmh', label: 'Höchstgeschwindigkeit', unit: 'km/h'),
    QuartettStat(id: 'ccm', label: 'Hubraum', unit: 'cm³'),
    QuartettStat(id: 'kg', label: 'Gewicht', unit: 'kg', higherWins: false),
    QuartettStat(
        id: 'sec0to100', label: '0–100 km/h', unit: 's', higherWins: false),
  ];

  /// Display names of the eight sets.
  static const Map<String, String> setNames = {
    'A': 'Supersportwagen',
    'B': 'Hypercars',
    'C': 'Klassiker',
    'D': 'Muscle Cars',
    'E': 'Rallye-Legenden',
    'F': 'Gran Turismo',
    'G': 'Elektro',
    'H': 'Kleine Flitzer',
  };

  /// The built-in demo deck (32 cards, sorted by id).
  static final List<Card> deck = List.unmodifiable([
    _c('A1', 'Porsche 911 Turbo S', 650, 330, 3745, 1640, 2.7),
    _c('A2', 'Ferrari F8 Tributo', 720, 340, 3902, 1435, 2.9),
    _c('A3', 'Lamborghini Huracán EVO', 640, 325, 5204, 1422, 2.9),
    _c('A4', 'McLaren 720S', 720, 341, 3994, 1419, 2.9),
    _c('B1', 'Bugatti Chiron', 1500, 420, 7993, 1995, 2.4),
    _c('B2', 'Koenigsegg Jesko', 1600, 480, 5065, 1420, 2.5),
    _c('B3', 'Pagani Huayra', 800, 383, 5980, 1350, 2.8),
    _c('B4', 'Rimac Nevera', 1914, 412, 0, 2300, 1.9),
    _c('C1', 'Mercedes 300 SL', 215, 260, 2996, 1295, 9.3),
    _c('C2', 'Jaguar E-Type', 269, 241, 3781, 1234, 7.0),
    _c('C3', 'Ferrari 250 GTO', 300, 280, 2953, 880, 6.1),
    _c('C4', 'Lamborghini Miura', 350, 280, 3929, 1180, 6.7),
    _c('D1', 'Ford Mustang Shelby GT500', 760, 290, 5163, 1916, 3.7),
    _c('D2', 'Dodge Challenger Hellcat', 717, 315, 6166, 2000, 3.6),
    _c('D3', 'Chevrolet Camaro ZL1', 659, 318, 6162, 1800, 4.0),
    _c('D4', 'Chevrolet Corvette Z06', 680, 315, 5500, 1600, 2.6),
    _c('E1', 'Lancia Delta Integrale', 215, 220, 1995, 1300, 5.7),
    _c('E2', 'Audi Sport quattro', 306, 250, 2133, 1300, 4.8),
    _c('E3', 'Subaru Impreza WRX STI', 300, 255, 2457, 1500, 5.2),
    _c('E4', 'Mitsubishi Lancer Evo IX', 280, 250, 1997, 1400, 4.8),
    _c('F1', 'Aston Martin DB11 V12', 608, 322, 5204, 1875, 3.9),
    _c('F2', 'Bentley Continental GT', 659, 335, 5950, 2244, 3.6),
    _c('F3', 'Mercedes-AMG GT R', 585, 318, 3982, 1630, 3.6),
    _c('F4', 'Nissan GT-R Nismo', 600, 315, 3799, 1725, 2.8),
    _c('G1', 'Tesla Model S Plaid', 1020, 322, 0, 2162, 2.1),
    _c('G2', 'Porsche Taycan Turbo S', 761, 260, 0, 2295, 2.8),
    _c('G3', 'Lucid Air Sapphire', 1234, 330, 0, 2375, 1.9),
    _c('G4', 'Audi e-tron GT', 646, 250, 0, 2350, 3.3),
    _c('H1', 'Mini Cooper S', 178, 235, 1998, 1265, 6.7),
    _c('H2', 'VW Polo GTI', 207, 238, 1984, 1355, 6.5),
    _c('H3', 'Toyota GR Yaris', 261, 230, 1618, 1280, 5.5),
    _c('H4', 'Abarth 595 Competizione', 180, 218, 1368, 1120, 7.3),
  ]);

  static final Map<String, Card> _byId = {for (final c in deck) c.id: c};

  /// Looks up a card by id; null if unknown.
  static Card? cardById(String id) => _byId[id];

  static QuartettStat? statById(String id) {
    for (final s in stats) {
      if (s.id == id) return s;
    }
    return null;
  }

  final QuartettMode mode;
  final int seed;

  /// Cards dealt to each player in sets mode (16 = whole deck, no stock).
  final int handSize;

  Player _current = Player.a;
  Player? _winner;
  bool _draw = false;
  String _reason = '';
  final List<Map<String, dynamic>> _history = [];

  // trumpf: stacks, front = top.
  final Map<Player, List<Card>> _stacks = {Player.a: [], Player.b: []};
  final List<Card> _pot = [];
  int _tricks = 0;

  // sets: hands, stock (front = top), laid-down set letters.
  final Map<Player, List<Card>> _hands = {Player.a: [], Player.b: []};
  final List<Card> _stock = [];
  final Map<Player, List<String>> _quartets = {Player.a: [], Player.b: []};

  QuartettGame(this.mode, {this.seed = 0, this.handSize = 16})
      : assert(handSize >= 1 && handSize <= 16) {
    final cards = List<Card>.of(deck);
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

  @override
  Player get currentPlayer => _current;

  @override
  GameResult get result =>
      GameResult(winner: _winner, draw: _draw, reason: _reason);

  @override
  bool get isOver => _winner != null || _draw;

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

  // --- sets getters ---

  /// [p]'s hand, sorted by id.
  List<Card> handOf(Player p) => List.unmodifiable(
      List<Card>.of(_hands[p]!)..sort((x, y) => x.id.compareTo(y.id)));

  /// Set letters laid down by [p], in order of completion.
  List<String> quartetsOf(Player p) => List.unmodifiable(_quartets[p]!);
  int get stockSize => _stock.length;

  /// Legal moves for [currentPlayer]; empty when the game is over.
  List<Map<String, dynamic>> get legalMoves {
    if (isOver) return const [];
    if (mode == QuartettMode.trumpf) {
      return [
        for (final s in stats) {'action': 'pick', 'stat': s.id}
      ];
    }
    final hand = _hands[_current]!;
    final held = hand.map((c) => c.id).toSet();
    final sets = hand.map((c) => c.set).toSet();
    return [
      for (final c in deck)
        if (sets.contains(c.set) && !held.contains(c.id))
          {'action': 'ask', 'card': c.id}
    ];
  }

  @override
  GameEvent? applyMove(Map<String, dynamic> move) {
    if (isOver) return null;
    return mode == QuartettMode.trumpf ? _pick(move) : _ask(move);
  }

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;

  GameEvent _event(Map<String, dynamic> payload) =>
      GameEvent(winner: _winner, draw: _draw, payload: payload);

  // --- trumpf ---

  GameEvent? _pick(Map<String, dynamic> move) {
    if (move['action'] != 'pick') return null;
    final stat = move['stat'];
    final s = stat is String ? statById(stat) : null;
    if (s == null) return null;
    final ca = topCard(Player.a), cb = topCard(Player.b);
    if (ca == null || cb == null) return null; // unreachable: game is over

    final picker = _current;
    _stacks[Player.a]!.removeAt(0);
    _stacks[Player.b]!.removeAt(0);
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
    _history.add({'player': picker, 'action': 'pick', 'stat': s.id});
    _checkTrumpfOver();
    return _event({
      'stat': s.id,
      'cards': {'a': ca.id, 'b': cb.id},
      'values': {'a': va, 'b': vb},
      'trickWinner': trickWinner?.name,
      'pot': _pot.length,
    });
  }

  void _checkTrumpfOver() {
    final ea = _stacks[Player.a]!.isEmpty, eb = _stacks[Player.b]!.isEmpty;
    if (ea && eb) {
      _draw = true;
      _reason = 'both stacks empty';
    } else if (ea || eb) {
      _winner = ea ? Player.b : Player.a;
      _reason = 'opponent has no cards left';
    } else if (_tricks >= maxTricks) {
      final na = stackSize(Player.a), nb = stackSize(Player.b);
      if (na == nb) {
        _draw = true;
        _reason = 'trick limit reached with equal stacks ($na:$nb)';
      } else {
        _winner = na > nb ? Player.a : Player.b;
        _reason = 'trick limit reached, more cards ($na:$nb)';
      }
    }
  }

  // --- sets ---

  GameEvent? _ask(Map<String, dynamic> move) {
    if (move['action'] != 'ask') return null;
    final id = move['card'];
    final card = id is String ? _byId[id] : null;
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
    } else {
      _winner = qa > qb ? Player.a : Player.b;
      _reason = 'more quartets ($qa:$qb)';
    }
  }
}
