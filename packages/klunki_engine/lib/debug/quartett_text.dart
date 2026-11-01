import 'dart:math';

import '../game.dart';
import '../quartett.dart';
import 'text_game.dart';

/// " – Züge" for a deck other than the default cars (KLD-069).
String _deckSuffix(QuartettGame g) => g.deck.id == QuartettDeck.defaultId ? '' : ' – ${g.deck.name}';

String _player(String key) => key == 'a' ? 'X' : 'O';

String _value(QuartettStat s, num v) => s.unit.isEmpty ? s.formatNumber(v) : '${s.formatNumber(v)} ${s.unit}';

/// Quartett (Trumpf): the Trumpf mode that compares stats. Shows only the top card of the player to move.
class QuartettTrumpfText extends TextGame {
  QuartettTrumpfText([this.seed = 0, QuartettDeck? deck])
      : game = QuartettGame(QuartettMode.trumpf, seed: seed, deck: deck);

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
  String get moveHelp => '<stat>   pick a stat of your top card: '
      '${[for (final (i, s) in game.stats.indexed) '${i + 1}/${s.id}'].join(', ')}';

  @override
  QuartettTrumpfText restart() => QuartettTrumpfText(seed, game.deck);

  @override
  String render() {
    final me = game.currentPlayer;
    final opp = me == Player.a ? Player.b : Player.a;
    final card = game.topCard(me);
    final b = StringBuffer('Cards: ${mark(me)} ${game.stackSize(me)}, ${mark(opp)} ${game.stackSize(opp)}'
        '${game.potSize > 0 ? ', pot ${game.potSize}' : ''}   (round ${game.tricks})');
    if (card != null && !game.isOver) {
      b
        ..writeln()
        ..writeln("${mark(me)}'s top card: ${card.id} ${card.name} (${game.setNames[card.set]})");
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
    final stat = n != null && n >= 1 && n <= game.stats.length
        ? game.stats[n - 1].id
        : game.stats.map((x) => x.id).where((id) => id == s).firstOrNull;
    return stat == null ? null : {'action': 'pick', 'stat': stat};
  }

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  @override
  String format(Map<String, dynamic> move) => '${move['stat']}';

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final p = event.payload as Map;
    final stat = game.statById(p['stat'] as String)!;
    final cards = p['cards'] as Map, values = p['values'] as Map;
    String side(String k) =>
        "${_player(k)}'s ${game.cardById(cards[k] as String)!.name} (${_value(stat, values[k] as num)})";
    final me = mark(mover);
    final first = mover == Player.a ? 'a' : 'b', second = first == 'a' ? 'b' : 'a';
    var s = '$me picks ${stat.label}: ${side(first)} vs ${side(second)}';
    final winner = p['trickWinner'] as String?;
    s += winner == null
        ? ' – tie, tie-break! Both cards go to the pot (${p['pot']}), $me picks again.'
        : ' → ${_player(winner)} wins the round (X ${game.stackSize(Player.a)}, O ${game.stackSize(Player.b)} cards).';
    if (event.winner != null) s += ' ${mark(event.winner)} wins: ${game.result.reason}.';
    if (event.draw) s += ' Draw: ${game.result.reason}.';
    return s;
  }

  /// Picks the stat in which the top card ranks best within the deck.
  @override
  Map<String, dynamic> autoMove(Random rng) {
    final card = game.topCard(game.currentPlayer)!;
    double rank(QuartettStat s) {
      final v = card.stats[s.id]!;
      return game.cards.where((c) => s.beats(v, c.stats[s.id]!)).length / game.cards.length;
    }

    final best = game.stats.reduce((a, b) => rank(a) >= rank(b) ? a : b);
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
      ..writeln('Quartets: ${mark(Player.a)} ${quartets(Player.a)}, ${mark(Player.b)} ${quartets(Player.b)}'
          '   |   ${mark(opp)} holds ${game.handOf(opp).length} cards, pile ${game.stockSize}');
    if (!game.isOver) {
      b.writeln("${mark(me)}'s hand:");
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
    final me = mark(mover), opp = _player(p['from'] as String);
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
    if (event.winner != null) return '$s ${mark(event.winner)} wins: ${game.result.reason}.';
    if (event.draw) return '$s Draw: ${game.result.reason}.';
    return '$s ${game.currentPlayer == mover ? '$me asks again.' : 'Now it is ${mark(game.currentPlayer)}\'s turn.'}';
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
