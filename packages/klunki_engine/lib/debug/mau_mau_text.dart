import 'dart:math';

import '../game.dart';
import '../mau_mau.dart';
import 'text_game.dart';

const _suitNames = {
  MauMauSuit.clubs: 'clubs',
  MauMauSuit.spades: 'spades',
  MauMauSuit.hearts: 'hearts',
  MauMauSuit.diamonds: 'diamonds',
};

/// Mau-Mau (KLD-118) as text. Shows only the hand of the player to move.
/// Commands: a card id (`h7`, `s10`, `cj h` = jack wishing hearts, add
/// `mau` on the second-to-last card when the Mau call is on), `draw`,
/// `pass`.
class MauMauText extends TextGame {
  MauMauText([this.seed = 0, MauMauRules rules = const MauMauRules()]) : game = MauMauGame(seed: seed, rules: rules);

  /// Wraps an existing engine instance (e.g. one built from a network `GameConfig`).
  MauMauText.forGame(this.game) : seed = game.seed;

  final int seed;
  @override
  final MauMauGame game;

  @override
  String get id => 'maumau';
  @override
  String get title => 'Mau-Mau';
  @override
  String get moveHelp => '<card> [suit] [mau] | draw | pass   e.g. h7, s10, cJ h (jack wishing hearts); '
      'suits c s h d, ranks 7 8 9 10 J Q K A';

  @override
  MauMauText restart() => MauMauText(seed, game.rules);

  @override
  String render() {
    final me = game.currentPlayer;
    final opp = me == Player.a ? Player.b : Player.a;
    final b = StringBuffer('Top card: ${game.topCard}');
    if (game.wish case final w?) b.write('   wished suit: ${_suitNames[w]}');
    if (game.penalty > 0) b.write('   ${playerName(me)} must draw ${game.penalty} (or lay a 7)');
    b
      ..writeln()
      ..write('${playerName(opp)} holds ${game.handCount(opp)} cards, draw pile ${game.stockCount}, '
          'discard pile ${game.discardCount}');
    if (game.isOver) return b.toString();
    final hand = MauMauCard.sorted(game.handOf(me));
    b
      ..writeln()
      ..write("${playerName(me)}'s hand: ${[for (final c in hand) game.canPlay(c) ? '${c.id}*' : c.id].join(' ')}");
    if (game.drawnCard case final d?) b.write('   (drew $d: lay it or pass)');
    return b.toString();
  }

  @override
  Map<String, dynamic>? parse(String input) {
    final words = input.trim().split(RegExp(r'\s+'));
    final first = words.first.toLowerCase();
    if (words.length == 1 && (first == 'draw' || first == 'pass')) return {'action': first};
    if (first.length < 2) return null;
    final id = first.substring(0, 1) + first.substring(1).toUpperCase();
    if (MauMauCard.byId(id) == null) return null;
    final move = <String, dynamic>{'action': 'play', 'card': id};
    for (final w in words.skip(1).map((w) => w.toLowerCase())) {
      if (w == 'mau') {
        move['mau'] = true;
      } else if (MauMauSuit.byCode(w) != null && !move.containsKey('suit')) {
        move['suit'] = w;
      } else {
        return null;
      }
    }
    return move;
  }

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  @override
  String format(Map<String, dynamic> move) => switch (move['action']) {
        'play' => [move['card'], if (move['suit'] != null) move['suit'], if (move['mau'] == true) 'mau'].join(' '),
        final a => '$a',
      };

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final p = event.payload as Map;
    final me = playerName(mover);
    final next = playerName(game.currentPlayer);
    final s = StringBuffer();
    switch (move['action']) {
      case 'play':
        s.write('$me lays ${p['card']}');
        if (p['wish'] case final String w) s.write(' and wishes ${_suitNames[MauMauSuit.byCode(w)]}');
        s.write('.');
        if (p['mau'] == true) s.write(' "Mau!"');
        if (p['forgotMau'] == true) s.write(' $me forgot to say "Mau" and draws a penalty card.');
        if (event.winner != null) {
          s.write(' $me has no cards left and wins!');
          return s.toString();
        }
        if (p['penalty'] case final int n) s.write(' $next must draw $n or lay a 7.');
        if (p['again'] == true) s.write(' $me lays again.');
      case 'draw':
        final n = p['count'];
        if (p['penalty'] != null) {
          s.write('$me draws $n penalty card${n == 1 ? '' : 's'}.');
        } else {
          s.write('$me draws a card${p['fits'] == true ? ' that fits: lay it or keep it' : ''}.');
        }
        if (p['reshuffled'] == true) s.write(' The discard pile was shuffled into a new draw pile.');
      case 'pass':
        s.write(p['kept'] == true ? '$me keeps the drawn card.' : '$me cannot lay or draw and passes.');
    }
    if (game.currentPlayer != mover) s.write(' Now it is $next\'s turn.');
    return s.toString();
  }

  /// Lays a card when possible (a 7 or 8 first, a jack last, wishing the
  /// suit it holds most of), else draws; lays a fitting drawn card.
  @override
  Map<String, dynamic> autoMove(Random rng) {
    final legal = legalMoves;
    final plays = legal.where((m) => m['action'] == 'play').toList();
    if (plays.isEmpty) return legal[rng.nextInt(legal.length)];
    final hand = game.handOf(game.currentPlayer);
    int count(String suit) => hand.where((c) => c.suit.code == suit && c.rank != MauMauRank.jack).length;
    final nonJack = plays.where((m) => !(m['card'] as String).endsWith('J')).toList();
    if (nonJack.isNotEmpty) {
      final special = nonJack.where((m) => RegExp(r'^.[78]$').hasMatch(m['card'] as String)).toList();
      final pool = special.isNotEmpty ? special : nonJack;
      return pool[rng.nextInt(pool.length)];
    }
    plays.sort((x, y) => count(y['suit'] as String).compareTo(count(x['suit'] as String)));
    return plays.first;
  }

  @override
  bool isHighlight(GameEvent event) => super.isHighlight(event) || (event.payload as Map?)?['wish'] != null;
}
