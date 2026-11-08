import 'dart:math';

import 'game.dart';
import 'secrecy.dart';

part 'mau_mau_view.dart';

/// Mau-Mau (KLD-118): the traditional shedding card game for two players
/// with a 32-card deck (7 to ace in four suits).
///
/// Deal (from the seed): the deck is shuffled with `Random(seed)`, each
/// player gets [MauMauGame.handSize] (5) cards, alternating A, B, A, …; the
/// next card is turned face up as the start of the discard pile, the rest is
/// the face-down draw pile. Player A starts. The start card has no effect
/// (a start 7 makes nobody draw, a start 8 skips nobody, a start jack wishes
/// nothing: its own suit counts).
///
/// A turn: lay one card that matches the top card by suit or rank, or draw.
/// After a plain draw the player may lay exactly the drawn card if it fits
/// (`play`) or keep it (`pass`); a drawn card that does not fit ends the turn
/// at once. Whoever lays the last card wins. When the draw pile runs out the
/// discard pile without its top card is shuffled (with the game's own
/// generator, so a replay reshuffles the same way) and becomes the new draw
/// pile. With nothing left to draw at all a player who cannot lay passes.
///
/// Special cards, see [MauMauRules] for the switches:
/// * 7: the next player draws 2 and the turn ends; with
///   [MauMauRules.stackSevens] they may lay another 7 instead and pass on
///   2 more.
/// * 8: the next player is skipped (with two players: the same player again).
/// * jack (Bube): lies on any card except another jack
///   ([MauMauRules.jackOnJack] allows that too); the player wishes a suit,
///   which the next card must have (or be a jack).
/// * ace ([MauMauRules.aceAgain], on by default): the same player lays
///   again, on the ace; this chains (ace after ace); with no fitting card
///   they draw as usual (a drawn card that fits may be laid at once).
/// * "Legen, wenn möglich" ([MauMauRules.mustPlay], on by default): `draw`
///   only when no card of the hand may be laid. A 7 chain is the exception:
///   answering with a 7 stays a choice, the cards can always be taken. A
///   drawn card that fits may still be kept (`pass`).
/// * "Mau" ([MauMauRules.mauCall], on by default): who lays the
///   second-to-last card says "Mau" (`mau: true` on the move); forgetting
///   it costs one penalty card.
///
/// Moves:
/// * `{'action': 'play', 'card': 'h7'}`; a jack names the wished suit:
///   `{'action': 'play', 'card': 'cJ', 'suit': 'h'}`; plus `'mau': true` on
///   the second-to-last card when [MauMauRules.mauCall] is on;
/// * `{'action': 'draw'}`: one card, or the whole penalty of a 7 chain;
/// * `{'action': 'pass'}`: keep the card just drawn, or (nothing left to
///   draw, no card fits) let the turn go.
///
/// An illegal move, or any move after the game is over, returns null and
/// leaves the state untouched.
class MauMauGame extends Game {
  /// Cards dealt to each player. The common German default for two players
  /// is 5 (some families play 6 or 7).
  static const int handSize = 5;

  /// Cards a 7 makes the next player draw.
  static const int sevenPenalty = 2;

  /// Stands for a card the viewer may not see (the opponent's hand in a
  /// [MauMauView]). Never part of [MauMauCard.deck].
  static const MauMauCard hiddenCard = MauMauCard._hidden();

  final int seed;
  final MauMauRules rules;

  final Random _rng;
  final Map<Player, List<MauMauCard>> _hands = {Player.a: [], Player.b: []};

  /// Face down, last = top.
  final List<MauMauCard> _stock = [];

  /// Face up, last = top.
  final List<MauMauCard> _discard = [];

  Player _current = Player.a;
  MauMauSuit? _wish;
  int _penalty = 0;

  /// The card [_current] drew this turn and may still lay; null otherwise.
  MauMauCard? _drawn;
  bool _hasDrawn = false;
  Player? _winner;
  final List<Map<String, dynamic>> _history = [];

  MauMauGame({this.seed = 0, this.rules = const MauMauRules()}) : _rng = Random(seed) {
    final cards = List<MauMauCard>.of(MauMauCard.deck);
    for (var i = cards.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final t = cards[i];
      cards[i] = cards[j];
      cards[j] = t;
    }
    for (var i = 0; i < handSize * 2; i++) {
      _hands[i.isEven ? Player.a : Player.b]!.add(cards[i]);
    }
    _discard.add(cards[handSize * 2]);
    // The rest, the first undealt card on top.
    _stock.addAll(cards.skip(handSize * 2 + 1).toList().reversed);
  }

  /// Empty game for [MauMauView].
  MauMauGame._empty(this.rules)
      : seed = 0,
        _rng = Random(0);

  @override
  Player get currentPlayer => _current;

  @override
  GameResult get playResult => _winner == null
      ? const GameResult()
      : GameResult(winner: _winner, reason: 'no cards left', code: GameEndReason.maumauEmptyHand);

  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  /// [p]'s cards in the order they came (the UI sorts them).
  List<MauMauCard> handOf(Player p) => List.unmodifiable(_hands[p]!);

  int handCount(Player p) => _hands[p]!.length;

  /// The face-up card everybody plays on.
  MauMauCard get topCard => _discard.last;

  /// Cards in the discard pile (top card included).
  int get discardCount => _discard.length;

  /// Cards in the face-down draw pile.
  int get stockCount => _stock.length;

  /// The suit a jack wished for; null when no wish is open.
  MauMauSuit? get wish => _wish;

  /// Cards the [currentPlayer] has to draw because of a 7 (chain); 0 = none.
  int get penalty => _penalty;

  /// The card the [currentPlayer] just drew and may still lay (or keep with
  /// `pass`); null when they have not drawn a fitting card this turn.
  MauMauCard? get drawnCard => _drawn;

  /// The [currentPlayer] drew a fitting card this turn and decides now
  /// (`play` it or `pass`). In a [MauMauView] also known for the opponent,
  /// without the card.
  bool get hasDrawn => _hasDrawn;

  /// Cards that can still be drawn: the draw pile plus the discard pile
  /// below its top card (reshuffled when needed).
  int get drawable => _stock.length + _discard.length - 1;

  /// Whether [card] may be laid on the current top card, ignoring whose
  /// hand it is in and a pending draw.
  bool fits(MauMauCard card) {
    final top = topCard;
    if (card.rank == MauMauRank.jack) return top.rank != MauMauRank.jack || rules.jackOnJack;
    final wish = _wish;
    if (wish != null) return card.suit == wish;
    return card.suit == top.suit || card.rank == top.rank;
  }

  /// Whether the [currentPlayer] may lay [card] now (it is in the hand,
  /// fits, and is the drawn card or a 7 while one is due).
  bool canPlay(MauMauCard card) {
    if (isOver) return false;
    if (!_hands[_current]!.contains(card)) return false;
    if (_penalty > 0) return rules.stackSevens && card.rank == MauMauRank.seven;
    if (_hasDrawn) return card == _drawn;
    return fits(card);
  }

  /// The cards the [currentPlayer] may lay now.
  List<MauMauCard> get playableCards => [
        for (final c in _hands[_current]!)
          if (canPlay(c)) c
      ];

  /// `draw` is possible now: with [MauMauRules.mustPlay] only when no card
  /// of the hand may be laid (taking a 7 chain's cards always is).
  bool get canDraw =>
      !isOver &&
      !_hasDrawn &&
      (_penalty > 0 || (drawable > 0 && (!rules.mustPlay || playableCards.isEmpty)));

  /// [MauMauRules.mustPlay] keeps the [currentPlayer] from drawing: a card
  /// of the hand fits (for the hint "leg sie").
  bool get mustPlayNow =>
      !isOver && rules.mustPlay && !_hasDrawn && _penalty == 0 && drawable > 0 && playableCards.isNotEmpty;

  /// `pass` is possible now.
  bool get canPass => !isOver && (_hasDrawn || (_penalty == 0 && drawable == 0 && playableCards.isEmpty));

  /// Whether laying a card now needs `mau: true` (it is the second-to-last
  /// card and [MauMauRules.mauCall] is on).
  bool get mauDue => rules.mauCall && _hands[_current]!.length == 2;

  /// Legal moves for the [currentPlayer]: every playable card (a jack once
  /// per suit; with `mau: true` when [mauDue]), `draw`, `pass`. Laying the
  /// second-to-last card without `mau` is legal too (it costs a penalty
  /// card), but not listed.
  List<Map<String, dynamic>> get legalMoves {
    if (isOver) return const [];
    final mau = mauDue;
    return [
      for (final c in playableCards)
        if (c.rank == MauMauRank.jack)
          for (final s in MauMauSuit.values) {'action': 'play', 'card': c.id, 'suit': s.code, if (mau) 'mau': true}
        else
          {'action': 'play', 'card': c.id, if (mau) 'mau': true},
      if (canDraw) {'action': 'draw'},
      if (canPass) {'action': 'pass'},
    ];
  }

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) => switch (move['action']) {
        'play' => _play(move),
        'draw' => move.length == 1 ? _drawMove() : null,
        'pass' => move.length == 1 ? _pass() : null,
        _ => null,
      };

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;

  GameEvent _event(Map<String, dynamic> payload) => GameEvent(winner: _winner, payload: payload);

  GameEvent? _play(Map<String, dynamic> move) {
    const keys = {'action', 'card', 'suit', 'mau'};
    if (move.keys.any((k) => !keys.contains(k))) return null;
    final id = move['card'];
    final card = id is String ? MauMauCard.byId(id) : null;
    if (card == null || !canPlay(card)) return null;
    final isJack = card.rank == MauMauRank.jack;
    final suitCode = move['suit'];
    final wish = suitCode is String ? MauMauSuit.byCode(suitCode) : null;
    if (isJack != (wish != null) || (suitCode != null && wish == null)) return null;
    final mau = move['mau'];
    if (mau != null && (mau != true || !mauDue)) return null;

    final me = _current;
    final hand = _hands[me]!;
    hand.remove(card);
    _discard.add(card);
    _drawn = null;
    _hasDrawn = false;
    _wish = wish;
    _history.add({'player': me, ...move});
    final payload = <String, dynamic>{'card': card.id, if (wish != null) 'wish': wish.code};
    if (hand.isEmpty) {
      _winner = me;
      _penalty = 0;
      return _event(payload);
    }
    if (rules.mauCall && hand.length == 1) {
      if (mau == true) {
        payload['mau'] = true;
      } else {
        // Forgot "Mau": one penalty card.
        final (drew, reshuffled) = _take(me, 1);
        payload['forgotMau'] = true;
        payload['drew'] = [for (final c in drew) c.id];
        if (reshuffled) payload['reshuffled'] = true;
      }
    }
    var again = false;
    if (card.rank == MauMauRank.seven && rules.sevenDraws) {
      _penalty += sevenPenalty;
      payload['penalty'] = _penalty;
    } else if ((card.rank == MauMauRank.eight && rules.eightSkips) || (card.rank == MauMauRank.ace && rules.aceAgain)) {
      again = true;
      payload['again'] = true;
    }
    if (!again) _current = _other(me);
    return _event(payload);
  }

  GameEvent? _drawMove() {
    if (!canDraw) return null;
    final me = _current;
    _history.add({'player': me, 'action': 'draw'});
    if (_penalty > 0) {
      final (drew, reshuffled) = _take(me, _penalty);
      final n = _penalty;
      _penalty = 0;
      _current = _other(me);
      return _event({
        'drew': [for (final c in drew) c.id],
        'count': drew.length,
        'penalty': n,
        if (reshuffled) 'reshuffled': true,
      });
    }
    final (drew, reshuffled) = _take(me, 1);
    final card = drew.single;
    final fitting = fits(card);
    if (fitting) {
      _drawn = card;
      _hasDrawn = true;
    } else {
      _current = _other(me);
    }
    return _event({
      'drew': [card.id],
      'count': 1,
      'fits': fitting,
      if (reshuffled) 'reshuffled': true,
    });
  }

  GameEvent? _pass() {
    if (!canPass) return null;
    final me = _current;
    _history.add({'player': me, 'action': 'pass'});
    final kept = _hasDrawn;
    _drawn = null;
    _hasDrawn = false;
    _current = _other(me);
    return _event({if (kept) 'kept': true});
  }

  /// Moves up to [n] cards from the draw pile into [p]'s hand, reshuffling
  /// the discard pile (without its top card) when the draw pile is empty.
  (List<MauMauCard>, bool) _take(Player p, int n) {
    final drew = <MauMauCard>[];
    var reshuffled = false;
    while (drew.length < n) {
      if (_stock.isEmpty) {
        if (_discard.length < 2) break;
        final top = _discard.removeLast();
        final pile = List<MauMauCard>.of(_discard);
        _discard
          ..clear()
          ..add(top);
        for (var i = pile.length - 1; i > 0; i--) {
          final j = _rng.nextInt(i + 1);
          final t = pile[i];
          pile[i] = pile[j];
          pile[j] = t;
        }
        _stock.addAll(pile);
        reshuffled = true;
      }
      final c = _stock.removeLast();
      _hands[p]!.add(c);
      drew.add(c);
    }
    return (drew, reshuffled);
  }

  /// What [viewer] may know, as JSON (see [MauMauRedaction]): the own hand,
  /// the counts, the top card, the wish, a pending 7 chain. Never the
  /// opponent's cards, the draw pile or the seed.
  Map<String, dynamic> viewJson(Player viewer) => {
        'viewer': viewer.name,
        if (!rules.isDefault) 'rules': rules.toJson(),
        'current': _current.name,
        'hand': [for (final c in _hands[viewer]!) c.id],
        'hands': {'a': handCount(Player.a), 'b': handCount(Player.b)},
        'top': topCard.id,
        'discard': discardCount,
        'stock': stockCount,
        if (_wish != null) 'wish': _wish!.code,
        if (_penalty > 0) 'penalty': _penalty,
        if (_hasDrawn) 'hasDrawn': true,
        if (_hasDrawn && viewer == _current) 'drawn': _drawn!.id,
        'result': resultToJson(playResult),
        if (resignedBy != null) 'resigned': resignedBy!.name,
      };

  /// Test hook: replaces the deal. [hands] for A and B, [top] the start
  /// card, [stock] the draw pile with its top card first; every card at
  /// most once (not checked against the full deck: cards may be left out).
  void debugSetup(
      {required List<String> a, required List<String> b, required String top, List<String> stock = const []}) {
    MauMauCard card(String id) => MauMauCard.byId(id) ?? (throw ArgumentError.value(id, 'card'));
    final all = [...a, ...b, top, ...stock];
    if (all.toSet().length != all.length) throw ArgumentError('a card appears twice');
    _hands[Player.a]!
      ..clear()
      ..addAll(a.map(card));
    _hands[Player.b]!
      ..clear()
      ..addAll(b.map(card));
    _discard
      ..clear()
      ..add(card(top));
    _stock
      ..clear()
      ..addAll(stock.reversed.map(card));
  }

  @override
  String toString() => 'MauMauGame(seed $seed, $rules)';
}

/// The four suits (French deck: the usual Mau-Mau cards in most of
/// Germany). [code] is the letter in card ids and moves.
enum MauMauSuit {
  clubs('c'),
  spades('s'),
  hearts('h'),
  diamonds('d');

  final String code;
  const MauMauSuit(this.code);

  bool get isRed => this == hearts || this == diamonds;

  static MauMauSuit? byCode(String code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// The eight ranks of the 32-card deck, low to high. [code] is the rank
/// part of a card id (international letters; the app shows its own).
enum MauMauRank {
  seven('7'),
  eight('8'),
  nine('9'),
  ten('10'),
  jack('J'),
  queen('Q'),
  king('K'),
  ace('A');

  final String code;
  const MauMauRank(this.code);

  static MauMauRank? byCode(String code) {
    for (final r in values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

/// One card; [id] is suit code plus rank code (`h7`, `s10`, `cJ`, `dA`).
class MauMauCard {
  final MauMauSuit suit;
  final MauMauRank rank;
  final bool _isHidden;
  const MauMauCard(this.suit, this.rank) : _isHidden = false;
  const MauMauCard._hidden()
      : suit = MauMauSuit.clubs,
        rank = MauMauRank.seven,
        _isHidden = true;

  String get id => _isHidden ? '?' : '${suit.code}${rank.code}';

  /// All 32 cards, suit by suit, 7 to ace.
  static final List<MauMauCard> deck = List.unmodifiable([
    for (final s in MauMauSuit.values)
      for (final r in MauMauRank.values) MauMauCard(s, r),
  ]);

  /// [cards] sorted by suit (clubs, spades, hearts, diamonds), then rank.
  static List<MauMauCard> sorted(Iterable<MauMauCard> cards) => cards.toList()
    ..sort((x, y) => x.suit != y.suit ? x.suit.index.compareTo(y.suit.index) : x.rank.index.compareTo(y.rank.index));

  /// The card with [id], or null.
  static MauMauCard? byId(String id) {
    if (id.length < 2) return null;
    final suit = MauMauSuit.byCode(id.substring(0, 1));
    final rank = MauMauRank.byCode(id.substring(1));
    return suit == null || rank == null ? null : MauMauCard(suit, rank);
  }

  @override
  bool operator ==(Object other) =>
      other is MauMauCard && other.suit == suit && other.rank == rank && other._isHidden == _isHidden;

  @override
  int get hashCode => Object.hash(suit, rank, _isHidden);

  @override
  String toString() => id;
}

/// The house rules of a Mau-Mau game (KLD-118), part of the [GameConfig]
/// (JSON `maumau`, only the switches that differ from the defaults). The
/// defaults are a proposal for families with children; see the task card.
class MauMauRules {
  /// A 7 makes the next player draw 2 (on).
  final bool sevenDraws;

  /// That player may lay another 7 instead and pass on 2 more (on).
  final bool stackSevens;

  /// An 8 skips the next player (on).
  final bool eightSkips;

  /// A jack may also lie on a jack (off: "no jack on a jack").
  final bool jackOnJack;

  /// An ace lets the same player lay again (on; chains ace after ace).
  final bool aceAgain;

  /// Say "Mau" on the second-to-last card or draw a penalty card (on;
  /// maintainer decision 2026-11-06).
  final bool mauCall;

  /// "Legen, wenn möglich": draw only when no card fits (on; maintainer
  /// decision 2026-11-08). Taking a 7 chain's cards is always allowed.
  final bool mustPlay;

  const MauMauRules({
    this.sevenDraws = true,
    this.stackSevens = true,
    this.eightSkips = true,
    this.jackOnJack = false,
    this.aceAgain = true,
    this.mauCall = true,
    this.mustPlay = true,
  });

  bool get isDefault => this == const MauMauRules();

  /// Only the switches that differ from the defaults (`{}` for the
  /// defaults).
  Map<String, dynamic> toJson() => {
        if (!sevenDraws) 'seven': false,
        if (!stackSevens) 'stack7': false,
        if (!eightSkips) 'eight': false,
        if (jackOnJack) 'jackOnJack': true,
        if (!aceAgain) 'ace': false,
        if (!mauCall) 'mau': false,
        if (!mustPlay) 'mustPlay': false,
      };

  factory MauMauRules.fromJson(Object? json) {
    if (json is! Map) return const MauMauRules();
    return MauMauRules(
      sevenDraws: json['seven'] != false,
      stackSevens: json['stack7'] != false,
      eightSkips: json['eight'] != false,
      jackOnJack: json['jackOnJack'] == true,
      aceAgain: json['ace'] != false,
      mauCall: json['mau'] != false,
      mustPlay: json['mustPlay'] != false,
    );
  }

  MauMauRules copyWith(
          {bool? sevenDraws,
          bool? stackSevens,
          bool? eightSkips,
          bool? jackOnJack,
          bool? aceAgain,
          bool? mauCall,
          bool? mustPlay}) =>
      MauMauRules(
        sevenDraws: sevenDraws ?? this.sevenDraws,
        stackSevens: stackSevens ?? this.stackSevens,
        eightSkips: eightSkips ?? this.eightSkips,
        jackOnJack: jackOnJack ?? this.jackOnJack,
        aceAgain: aceAgain ?? this.aceAgain,
        mauCall: mauCall ?? this.mauCall,
        mustPlay: mustPlay ?? this.mustPlay,
      );

  @override
  bool operator ==(Object other) =>
      other is MauMauRules &&
      other.sevenDraws == sevenDraws &&
      other.stackSevens == stackSevens &&
      other.eightSkips == eightSkips &&
      other.jackOnJack == jackOnJack &&
      other.aceAgain == aceAgain &&
      other.mauCall == mauCall &&
      other.mustPlay == mustPlay;

  @override
  int get hashCode => Object.hash(sevenDraws, stackSevens, eightSkips, jackOnJack, aceAgain, mauCall, mustPlay);

  @override
  String toString() => 'MauMauRules(${toJson()})';
}
