// KLD-089: who picks next in Quartett (Trumpf), over many complete games.
//
// Rule: the trick winner picks the next trick; after a tie the same player
// picks again. Every trick of every game (all four decks, many seeds, a mix
// of random and "strongest stat" picks) is checked against it, through the
// engine's own event payloads and through a replay of the move log.
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// The stat in which [card] ranks best within [deck] (what a player who only
/// sees their own card would pick).
String strongestStat(QuartettDeck deck, Card card) {
  var best = deck.stats.first.id;
  var bestRank = -1.0;
  for (final s in deck.stats) {
    final v = card.stats[s.id]!;
    final beaten = deck.cards.where((o) => s.beats(v, o.stats[s.id]!)).length;
    final rank = beaten / deck.cards.length;
    if (rank > bestRank) {
      bestRank = rank;
      best = s.id;
    }
  }
  return best;
}

void main() {
  for (final deck in QuartettDeck.all) {
    test('${deck.id}: the trick winner picks next, a tie keeps the picker (300 seeds)', () {
      var tricks = 0, ties = 0, repeats = 0;
      for (var seed = 0; seed < 300; seed++) {
        final g = QuartettGame(QuartettMode.trumpf, seed: seed, deck: deck);
        final rng = Random(seed);
        final moves = <Map<String, dynamic>>[];
        Player? expectedPicker = Player.a;
        while (!g.isOver) {
          final picker = g.currentPlayer;
          expect(picker, expectedPicker, reason: '${deck.id} seed $seed trick ${moves.length}');
          final top = g.topCard(picker)!;
          final stat = rng.nextBool() ? deck.stats[rng.nextInt(deck.stats.length)].id : strongestStat(deck, top);
          final move = {'action': 'pick', 'stat': stat};
          final event = g.applyMove(move)!;
          moves.add(move);
          final p = event.payload as Map;
          final w = p['trickWinner'];
          final winner = w == null ? null : Player.values.byName(w as String);
          expectedPicker = winner ?? picker;
          if (winner == null) ties++;
          if (expectedPicker == picker) repeats++;
          tricks++;
          // The history names the picker of every trick.
          expect(g.history.last['player'], picker);
        }
        // A replay of the log reaches the same end and the same pickers.
        final r = QuartettGame(QuartettMode.trumpf, seed: seed, deck: deck);
        for (var i = 0; i < moves.length; i++) {
          expect(r.currentPlayer, g.history[i]['player'], reason: 'replay trick $i');
          r.applyMove(moves[i]);
        }
        expect(r.result.winner, g.result.winner);
        expect(r.result.draw, g.result.draw);
      }
      // The sample really exercised ties and repeated pickers.
      expect(tricks, greaterThan(1000));
      expect(ties, greaterThan(0));
      expect(repeats, greaterThan(0));
    });
  }
}
