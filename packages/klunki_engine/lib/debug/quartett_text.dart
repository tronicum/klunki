import 'dart:math';

import '../game.dart';
import '../quartett.dart';
import 'text_game.dart';

/// " – Züge" for a deck other than the default cars (KLD-069).
String _deckSuffix(QuartettGame g) => g.deck.id == QuartettDeck.defaultId ? '' : ' – ${g.deck.name}';

/// The player named by a payload key `a` / `b` (KLD-102: Anna / Ben).
String _player(String key) => playerNameOf(key == 'a' ? Player.a : Player.b);

String _value(QuartettStat s, num v) => s.unit.isEmpty ? s.formatNumber(v) : '${s.formatNumber(v)} ${s.unit}';

/// Quartett (Trumpf): the Trumpf mode that compares stats. Shows only the
/// card of the player to move: the top card, or (KLD-100,
/// [QuartettGame.pickLowCards], on by default like the app's GameConfig) the
/// whole stack of a player with 3 or fewer cards, to choose from.
class QuartettTrumpfText extends TextGame {
  QuartettTrumpfText([this.seed = 0, QuartettDeck? deck, bool pickLowCards = true])
      : game = QuartettGame(QuartettMode.trumpf, seed: seed, deck: deck, pickLowCards: pickLowCards);

  /// Wraps an existing engine instance (e.g. one built from a network `GameConfig`).
  QuartettTrumpfText.forGame(this.game) : seed = game.seed;

  final int seed;
  @override
  final QuartettGame game;

  @override
  String get id => 'quartett-trumpf';
  @override
  String get title => 'Quartett (Trumpf)${_deckSuffix(game)}';
  @override
  String get moveHelp => game.mustChoose
      ? '<n|card id>   choose the card to play (1–${game.stackSize(game.currentPlayer)} or its id)'
      : '<stat>   pick a stat of your card: '
          '${[for (final (i, s) in game.stats.indexed) '${i + 1}/${s.id}'].join(', ')}';

  @override
  QuartettTrumpfText restart() => QuartettTrumpfText(seed, game.deck, game.pickLowCards);

  @override
  String render() {
    final me = game.currentPlayer;
    final opp = me == Player.a ? Player.b : Player.a;
    final b = StringBuffer('Cards: ${playerName(me)} ${game.stackSize(me)}, ${playerName(opp)} ${game.stackSize(opp)}'
        '${game.potSize > 0 ? ', pot ${game.potSize}' : ''}   (round ${game.tricks})');
    if (game.isOver) return b.toString();
    final announced = game.announcedStat;
    if (game.mustChoose) {
      final cards = game.stackOf(me);
      b.writeln();
      if (announced != null) {
        b.writeln('${playerName(game.picker)} picks ${announced.label} '
            '(${announced.higherWins ? 'higher wins' : 'lower wins'}). ${playerName(me)}, choose your card:');
      } else {
        b.writeln('${playerName(me)} has only ${cards.length} cards – choose one:');
      }
      for (final (i, c) in cards.indexed) {
        final values = announced != null
            ? _value(announced, c.stats[announced.id]!)
            : [for (final s in game.stats) '${s.id} ${_value(s, c.stats[s.id]!)}'].join(', ');
        b.writeln('  ${i + 1} ${c.id} ${c.name.padRight(24)} $values');
      }
      return b.toString().trimRight();
    }
    final card = game.playedCard(me);
    if (card != null) {
      final which = game.chosenCard(me) != null ? 'chosen card' : 'top card';
      b
        ..writeln()
        ..writeln("${playerName(me)}'s $which: ${card.id} ${card.name} (${game.setNames[card.set]})");
      for (final (i, s) in game.stats.indexed) {
        b.writeln('  ${i + 1} ${s.id.padRight(9)} ${s.label.padRight(22)} '
            '${_value(s, card.stats[s.id]!).padLeft(10)}  ${s.higherWins ? 'higher wins' : 'lower wins'}');
      }
    }
    return b.toString().trimRight();
  }

  @override
  Map<String, dynamic>? parse(String input) {
    final s = input.trim().toLowerCase();
    final n = int.tryParse(s);
    if (game.mustChoose) {
      final cards = game.stackOf(game.currentPlayer);
      final id = n != null && n >= 1 && n <= cards.length
          ? cards[n - 1].id
          : cards.map((c) => c.id).where((id) => id == s.toUpperCase()).firstOrNull;
      return id == null ? null : {'action': 'choose', 'card': id};
    }
    final stat = n != null && n >= 1 && n <= game.stats.length
        ? game.stats[n - 1].id
        : game.stats.map((x) => x.id).where((id) => id == s).firstOrNull;
    return stat == null ? null : {'action': 'pick', 'stat': stat};
  }

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  /// A pick as its stat, a choice as its card ("a card" when redacted).
  @override
  String format(Map<String, dynamic> move) =>
      move['action'] == 'choose' ? '${move['card'] ?? 'a card'}' : '${move['stat']}';

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final p = event.payload as Map;
    final me = playerName(mover);
    if (p['chose'] == true) return '$me chooses a card.';
    final stat = game.statById(p['stat'] as String)!;
    if (p['announced'] == true) {
      return '$me picks ${stat.label} – ${playerName(mover == Player.a ? Player.b : Player.a)} chooses a card.';
    }
    final cards = p['cards'] as Map, values = p['values'] as Map;
    String side(String k) =>
        "${_player(k)}'s ${game.cardById(cards[k] as String)!.name} (${_value(stat, values[k] as num)})";
    // A round the defender's choice completed names its picker (KLD-100).
    final first = p['picker'] as String? ?? (mover == Player.a ? 'a' : 'b');
    final second = first == 'a' ? 'b' : 'a';
    final picker = _player(first);
    var s = p['picker'] != null
        ? '$me chooses: ${side(first)} vs ${side(second)}'
        : '$me picks ${stat.label}: ${side(first)} vs ${side(second)}';
    final winner = p['trickWinner'] as String?;
    s += winner == null
        ? ' – tie, tie-break! Both cards go to the pot (${p['pot']}), $picker picks again.'
        : ' → ${_player(winner)} wins the round (${playerName(Player.a)} ${game.stackSize(Player.a)}, ${playerName(Player.b)} ${game.stackSize(Player.b)} cards).';
    if (event.winner != null) s += ' ${playerName(event.winner)} wins: ${game.result.reason}.';
    if (event.draw) s += ' Draw: ${game.result.reason}.';
    return s;
  }

  /// How strong [card] is in [s]: the share of deck cards it beats.
  double _rank(Card card, QuartettStat s) {
    final v = card.stats[s.id]!;
    return game.cards.where((c) => s.beats(v, c.stats[s.id]!)).length / game.cards.length;
  }

  /// Picks the stat in which the played card ranks best within the deck.
  /// Choosing (KLD-100): the defender takes its best card for the announced
  /// stat; a low picker the card with the strongest stat.
  @override
  Map<String, dynamic> autoMove(Random rng) {
    final me = game.currentPlayer;
    if (game.mustChoose) {
      final cards = game.stackOf(me);
      final announced = game.announcedStat;
      final Card best;
      if (announced != null) {
        best = cards.reduce((x, y) => announced.beats(y.stats[announced.id]!, x.stats[announced.id]!) ? y : x);
      } else {
        double strength(Card c) => game.stats.map((s) => _rank(c, s)).reduce(max);
        best = cards.reduce((x, y) => strength(y) > strength(x) ? y : x);
      }
      return {'action': 'choose', 'card': best.id};
    }
    final card = game.playedCard(me)!;
    final best = game.stats.reduce((a, b) => _rank(card, a) >= _rank(card, b) ? a : b);
    return {'action': 'pick', 'stat': best.id};
  }

  @override
  List<String>? get demoScript => null;
}

/// Classic Quartett. Hands of [handSize] with a draw pile: with the full deck
/// dealt and two players every ask would hit (see quartett.dart), so the
/// Go-Fish pile is what makes misses, and therefore a contest, possible.
class QuartettSetsText extends TextGame {
  QuartettSetsText([this.seed = 0, this.handSize = 8, QuartettDeck? deck])
      : game = QuartettGame(QuartettMode.sets, seed: seed, handSize: handSize, deck: deck);

  /// Wraps an existing engine instance (e.g. one built from a network `GameConfig`).
  QuartettSetsText.forGame(this.game)
      : seed = game.seed,
        handSize = game.handSize;

  final int seed;
  final int handSize;
  @override
  final QuartettGame game;

  @override
  String get id => 'quartett-sets';
  @override
  String get title => 'Quartett (Sets)${_deckSuffix(game)}';
  @override
  String get moveHelp => '<card id>   ask your opponent for a card, e.g. "B3" '
      '(you must hold a card of that set but not the card itself)';

  @override
  QuartettSetsText restart() => QuartettSetsText(seed, handSize, game.deck);

  @override
  String render() {
    final me = game.currentPlayer;
    final opp = me == Player.a ? Player.b : Player.a;
    String quartets(Player p) {
      final q = game.quartetsOf(p);
      return '${q.length}${q.isEmpty ? '' : ' (${q.join(' ')})'}';
    }

    final b = StringBuffer()
      ..writeln('Quartets: ${playerName(Player.a)} ${quartets(Player.a)}, ${playerName(Player.b)} ${quartets(Player.b)}'
          '   |   ${playerName(opp)} holds ${game.handOf(opp).length} cards, pile ${game.stockSize}');
    if (!game.isOver) {
      b.writeln("${playerName(me)}'s hand:");
      final bySet = <String, List<Card>>{};
      for (final c in game.handOf(me)) {
        (bySet[c.set] ??= []).add(c);
      }
      for (final MapEntry(key: set, value: cards) in bySet.entries) {
        b.writeln('  $set ${game.setNames[set]!.padRight(16)} ${cards.map((c) => '${c.id} ${c.name}').join(', ')}');
      }
    }
    return b.toString().trimRight();
  }

  @override
  Map<String, dynamic>? parse(String input) {
    final id = input.trim().toUpperCase();
    return game.cardById(id) == null ? null : {'action': 'ask', 'card': id};
  }

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  @override
  String format(Map<String, dynamic> move) => '${move['card']}';

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final p = event.payload as Map;
    final me = playerName(mover), opp = _player(p['from'] as String);
    final card = game.cardById(p['card'] as String)!;
    var s = '$me asks $opp for ${card.id} (${card.name}): ';
    if (p['hit'] == true) {
      s += '$opp has it and hands it over.';
    } else {
      s += "$opp doesn't have it.${p['drew'] != null ? ' $me draws a card from the pile.' : ''}";
    }
    if (p['quartet'] case final String set) {
      s += ' $me completes quartet $set (${game.setNames[set]})!';
    }
    if (event.winner != null) return '$s ${playerName(event.winner)} wins: ${game.result.reason}.';
    if (event.draw) return '$s Draw: ${game.result.reason}.';
    return '$s ${game.currentPlayer == mover ? '$me asks again.' : 'Now it is ${playerName(game.currentPlayer)}\'s turn.'}';
  }

  /// Asks for a missing card of the set it holds most of.
  @override
  Map<String, dynamic> autoMove(Random rng) {
    final hand = game.handOf(game.currentPlayer);
    int held(String set) => hand.where((c) => c.set == set).length;
    final legal = legalMoves;
    final most = legal.map((m) => held((m['card'] as String)[0])).reduce(max);
    final best = legal.where((m) => held((m['card'] as String)[0]) == most).toList();
    return best[rng.nextInt(best.length)];
  }

  @override
  bool isHighlight(GameEvent event) =>
      super.isHighlight(event) || event.payload is Map && (event.payload as Map)['quartet'] != null;
}
