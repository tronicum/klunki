import 'dart:math';

import 'package:test/test.dart';
import 'package:klunki_engine/klunki_engine.dart';

List<String> ids(List<Card> cards) => cards.map((c) => c.id).toList();

/// Everything observable about a game, for "no state change" checks.
String snapshot(QuartettGame g) => [
      g.currentPlayer,
      g.isOver,
      g.result.reason,
      g.history.length,
      g.tricks,
      g.potSize,
      for (final p in Player.values) ...[
        g.topCard(p)?.id,
        g.stackSize(p),
        ids(g.handOf(p)).join(','),
        g.quartetsOf(p).join(','),
      ],
      g.stockSize,
      g.legalMoves.length,
    ].join('|');

QuartettGame replay(
    QuartettMode mode, int seed, List<Map<String, dynamic>> moves,
    {int handSize = 16}) {
  final g = QuartettGame(mode, seed: seed, handSize: handSize);
  for (final m in moves) {
    expect(g.applyMove(m), isNotNull);
  }
  return g;
}

Map<String, dynamic> pick(String stat) => {'action': 'pick', 'stat': stat};
Map<String, dynamic> ask(String card) => {'action': 'ask', 'card': card};

/// Picks the stat where [g]'s current top card beats the most deck cards.
String greedyStat(QuartettGame g) {
  final c = g.topCard(g.currentPlayer)!;
  var best = QuartettGame.stats.first.id;
  var bestScore = -1;
  for (final s in QuartettGame.stats) {
    final n = QuartettGame.deck
        .where((d) => s.beats(c.stats[s.id]!, d.stats[s.id]!))
        .length;
    if (n > bestScore) {
      bestScore = n;
      best = s.id;
    }
  }
  return best;
}

void main() {
  group('deck', () {
    test('32 unique cards, 8 sets of 4, all stats present', () {
      expect(QuartettGame.deck.length, 32);
      expect(QuartettGame.deck.map((c) => c.id).toSet().length, 32);
      for (final s in 'ABCDEFGH'.split('')) {
        expect(QuartettGame.deck.where((c) => c.set == s).length, 4);
      }
      for (final c in QuartettGame.deck) {
        for (final s in QuartettGame.stats) {
          expect(c.stats[s.id], isNotNull, reason: '${c.id} ${s.id}');
        }
      }
      expect(QuartettGame.statById('kg')!.higherWins, isFalse);
      expect(QuartettGame.statById('sec0to100')!.higherWins, isFalse);
      expect(QuartettGame.statById('ps')!.higherWins, isTrue);
    });

    test('deterministic deal per seed', () {
      for (final mode in QuartettMode.values) {
        final g1 = QuartettGame(mode, seed: 42);
        final g2 = QuartettGame(mode, seed: 42);
        final g3 = QuartettGame(mode, seed: 43);
        expect(snapshot(g1), snapshot(g2));
        expect(snapshot(g1), isNot(snapshot(g3)));
      }
      final s1 = QuartettGame(QuartettMode.sets, seed: 7);
      final s2 = QuartettGame(QuartettMode.sets, seed: 7);
      final s3 = QuartettGame(QuartettMode.sets, seed: 8);
      expect(ids(s1.handOf(Player.a)), ids(s2.handOf(Player.a)));
      expect(ids(s1.handOf(Player.a)), isNot(ids(s3.handOf(Player.a))));
      expect(s1.mode, QuartettMode.sets);
      expect(s1.seed, 7);
    });
  });

  group('trumpf', () {
    test('deal: 16 each, A starts, 5 legal picks', () {
      final g = QuartettGame(QuartettMode.trumpf);
      expect(g.stackSize(Player.a), 16);
      expect(g.stackSize(Player.b), 16);
      expect(g.currentPlayer, Player.a);
      expect(g.legalMoves.length, QuartettGame.stats.length);
    });

    /// Plays one trick with [stat] and checks the outcome against the values.
    void checkTrick(QuartettGame g, String stat) {
      final s = QuartettGame.statById(stat)!;
      final ca = g.topCard(Player.a)!, cb = g.topCard(Player.b)!;
      final va = ca.stats[stat]!, vb = cb.stats[stat]!;
      final before = g.currentPlayer;
      final na = g.stackSize(Player.a), nb = g.stackSize(Player.b);
      final pot = g.potSize;
      final e = g.applyMove(pick(stat))!;
      final p = e.payload as Map;
      expect(p['stat'], stat);
      expect(p['cards'], {'a': ca.id, 'b': cb.id});
      expect(p['values'], {'a': va, 'b': vb});
      expect(g.tricks, greaterThan(0));
      if (va == vb) {
        expect(p['trickWinner'], isNull);
        expect(g.potSize, pot + 2);
        expect(g.currentPlayer, before);
        return;
      }
      final w = s.beats(va, vb) ? Player.a : Player.b;
      final l = w == Player.a ? Player.b : Player.a;
      expect(p['trickWinner'], w.name);
      expect(p['pot'], 0);
      expect(g.potSize, 0);
      expect(g.currentPlayer, w);
      expect(g.stackSize(w), (w == Player.a ? na : nb) + 1 + pot);
      expect(g.stackSize(l), (l == Player.a ? na : nb) - 1);
    }

    test('higher-wins and lower-wins stats decide tricks correctly', () {
      for (var seed = 0; seed < 20; seed++) {
        for (final s in QuartettGame.stats) {
          checkTrick(QuartettGame(QuartettMode.trumpf, seed: seed), s.id);
        }
      }
    });

    test('kg: lighter card wins, own card then opponent card to bottom', () {
      final g = QuartettGame(QuartettMode.trumpf, seed: 0);
      final ca = g.topCard(Player.a)!, cb = g.topCard(Player.b)!;
      expect(ca.stats['kg'], isNot(cb.stats['kg']));
      final w = ca.stats['kg']! < cb.stats['kg']! ? Player.a : Player.b;
      final own = w == Player.a ? ca : cb, opp = w == Player.a ? cb : ca;
      g.applyMove(pick('kg'));
      expect(g.currentPlayer, w);
      expect(g.stackSize(w), 17);
      final stack = g.stackOf(w);
      expect(stack.sublist(15), [own, opp]);
    });

    test('tie -> pot, same player picks again, next winner takes the pot', () {
      // Play seed 3 with 'ps' until the top cards tie on some stat.
      final g = QuartettGame(QuartettMode.trumpf, seed: 3);
      String? tied;
      while (!g.isOver && tied == null) {
        final a = g.topCard(Player.a)!, b = g.topCard(Player.b)!;
        for (final s in QuartettGame.stats) {
          if (a.stats[s.id] == b.stats[s.id]) tied = s.id;
        }
        if (tied == null) g.applyMove(pick('ps'));
      }
      expect(tied, isNotNull, reason: 'seed 3 should reach a tie');
      final picker = g.currentPlayer;
      final total = g.stackSize(Player.a) + g.stackSize(Player.b);
      final e = g.applyMove(pick(tied!))!;
      expect((e.payload as Map)['trickWinner'], isNull);
      expect((e.payload as Map)['pot'], 2);
      expect(g.potSize, 2);
      expect(g.currentPlayer, picker);
      expect(g.stackSize(Player.a) + g.stackSize(Player.b), total - 2);
      // Resolve: keep picking until someone wins a trick; they get the pot.
      while (!g.isOver && g.potSize > 0) {
        final a = g.topCard(Player.a)!, b = g.topCard(Player.b)!;
        final decisive = QuartettGame.stats
            .firstWhere((s) => a.stats[s.id] != b.stats[s.id]);
        final pot = g.potSize;
        final w = decisive.beats(a.stats[decisive.id]!, b.stats[decisive.id]!)
            ? Player.a
            : Player.b;
        final nw = g.stackSize(w);
        final e2 = g.applyMove(pick(decisive.id))!;
        expect((e2.payload as Map)['trickWinner'], w.name);
        expect(g.stackSize(w), nw + 1 + pot);
        expect(g.currentPlayer, w);
      }
      expect(g.potSize, 0);
      expect(g.stackSize(Player.a) + g.stackSize(Player.b), 32);
    });

    test('loss by empty stack (seed 2, greedy picks -> A wins in 16 tricks)',
        () {
      final g = QuartettGame(QuartettMode.trumpf, seed: 2);
      while (!g.isOver) {
        g.applyMove(pick(greedyStat(g)));
      }
      expect(g.tricks, 16);
      expect(g.result.winner, Player.a);
      expect(g.stackSize(Player.b), 0);
      expect(g.topCard(Player.b), isNull);
      expect(g.stackSize(Player.a), 32);
      expect(g.result.reason, contains('no cards'));
      expect(g.result.code, GameEndReason.quartettAllCards);
      expect(g.legalMoves, isEmpty);
    });

    test('trick limit: seed 1 always "ps" -> draw 16:16 after 200 tricks', () {
      final g = QuartettGame(QuartettMode.trumpf, seed: 1);
      while (!g.isOver) {
        g.applyMove(pick('ps'));
      }
      expect(g.tricks, QuartettGame.maxTricks);
      expect(g.result.draw, isTrue);
      expect(g.result.reason, contains('trick limit'));
      expect(g.result.code, GameEndReason.quartettTrickLimitEqual);
expect(g.result.params, {'a': 16, 'b': 16});
    });

    test('trick limit: seed 8 always "ps" -> A wins on cards', () {
      final g = QuartettGame(QuartettMode.trumpf, seed: 8);
      while (!g.isOver) {
        g.applyMove(pick('ps'));
      }
      expect(g.tricks, QuartettGame.maxTricks);
      expect(g.result.winner, Player.a);
      expect(g.stackSize(Player.a), greaterThan(g.stackSize(Player.b)));
      expect(g.result.code, GameEndReason.quartettTrickLimitMoreCards);
      expect(g.result.params,
          {'a': g.stackSize(Player.a), 'b': g.stackSize(Player.b)});
    });

    test('illegal picks -> null, no change', () {
      final g = QuartettGame(QuartettMode.trumpf, seed: 5);
      g.applyMove(pick('ps'));
      final snap = snapshot(g);
      for (final m in <Map<String, dynamic>>[
        pick('nope'),
        {'action': 'pick'},
        {'action': 'pick', 'stat': 3},
        ask('A1'),
        {},
      ]) {
        expect(g.applyMove(m), isNull, reason: '$m');
        expect(snapshot(g), snap);
      }
    });
  });

  group('sets', () {
    test('hit moves the card, asker continues, quartet laid down', () {
      // Seed 0: A holds B2,B3,B4 — B has B1.
      final g = QuartettGame(QuartettMode.sets, seed: 0);
      expect(ids(g.handOf(Player.a)), containsAll(['B2', 'B3', 'B4']));
      expect(ids(g.handOf(Player.b)), contains('B1'));
      final e = g.applyMove(ask('B1'))!;
      expect(e.payload, {
        'card': 'B1',
        'from': 'b',
        'hit': true,
        'quartet': 'B',
        'drew': null,
      });
      expect(g.currentPlayer, Player.a);
      expect(g.quartetsOf(Player.a), ['B']);
      expect(ids(g.handOf(Player.a)).where((id) => id[0] == 'B'), isEmpty);
      expect(ids(g.handOf(Player.b)), isNot(contains('B1')));
      expect(g.handOf(Player.a).length + g.handOf(Player.b).length, 28);
    });

    test('hit without completing a set', () {
      // Seed 0: A holds only A2 of set A.
      final g = QuartettGame(QuartettMode.sets, seed: 0);
      final e = g.applyMove(ask('A1'))!;
      expect((e.payload as Map)['hit'], isTrue);
      expect((e.payload as Map)['quartet'], isNull);
      expect(ids(g.handOf(Player.a)), contains('A1'));
      expect(g.currentPlayer, Player.a);
    });

    test('full deal: every legal ask hits (2 players, no stock)', () {
      for (var seed = 0; seed < 5; seed++) {
        final g = QuartettGame(QuartettMode.sets, seed: seed);
        while (!g.isOver) {
          final e = g.applyMove(g.legalMoves.first)!;
          expect((e.payload as Map)['hit'], isTrue);
        }
      }
    });

    test('quartets dealt directly are laid down at the start', () {
      // Seed 4: A was dealt all of set D; seed 1: B was dealt G and H.
      final g = QuartettGame(QuartettMode.sets, seed: 4);
      expect(g.quartetsOf(Player.a), ['D']);
      expect(g.handOf(Player.a).length, 12);
      final g1 = QuartettGame(QuartettMode.sets, seed: 1);
      expect(g1.quartetsOf(Player.b), containsAll(['G', 'H']));
      expect(g1.handOf(Player.b).length, 8);
    });

    test('miss passes the turn and draws from the stock (handSize 4)', () {
      final g = QuartettGame(QuartettMode.sets, seed: 0, handSize: 4);
      expect(g.stockSize, 24);
      // Find a legal ask whose card is not in B's hand.
      final bIds = ids(g.handOf(Player.b)).toSet();
      final m = g.legalMoves.firstWhere((m) => !bIds.contains(m['card']));
      final handBefore = g.handOf(Player.a).length;
      final e = g.applyMove(m)!;
      final p = e.payload as Map;
      expect(p['hit'], isFalse);
      expect(p['from'], 'b');
      expect(p['drew'], isA<String>());
      expect(g.stockSize, 23);
      expect(g.currentPlayer, Player.b);
      expect(g.handOf(Player.a).length + g.quartetsOf(Player.a).length * 4,
          handBefore + 1);
    });

    test('illegal asks -> null and no change', () {
      // Seed 11: A laid down A, B laid down D; A holds no D card.
      final g = QuartettGame(QuartettMode.sets, seed: 11);
      final own = g.handOf(Player.a).first.id;
      final small = QuartettGame(QuartettMode.sets, seed: 0, handSize: 4);
      final heldSets = small.handOf(Player.a).map((c) => c.set).toSet();
      final notHeld =
          QuartettGame.deck.firstWhere((c) => !heldSets.contains(c.set));
      for (final (game, m) in <(QuartettGame, Map<String, dynamic>)>[
        (g, ask(own)), // own card
        (g, ask('D1')), // laid-down set (by B)
        (g, ask('A1')), // laid-down set (by A)
        (g, ask('Z9')), // unknown card
        (g, {'action': 'ask'}),
        (g, {'action': 'ask', 'card': 7}),
        (g, pick('ps')), // wrong mode
        (small, ask(notHeld.id)), // set not held
      ]) {
        final snap = snapshot(game);
        expect(game.applyMove(m), isNull, reason: '$m');
        expect(snapshot(game), snap);
      }
    });

    test('empty hand after a quartet: asker draws from the stock', () {
      // Search deterministic games for a hit that lays down the asker's last
      // cards while the stock is non-empty: the asker draws one and goes on.
      var found = 0;
      for (var seed = 0; seed < 50; seed++) {
        final g = QuartettGame(QuartettMode.sets, seed: seed, handSize: 3);
        while (!g.isOver) {
          final me = g.currentPlayer;
          final stock = g.stockSize;
          final e = g.applyMove(g.legalMoves.first)!;
          final p = e.payload as Map;
          if (!g.isOver && p['hit'] == true && g.stockSize == stock - 1) {
            found++;
            expect(p['quartet'], isNotNull);
            expect(g.currentPlayer, me);
            expect(g.handOf(me).length, 1);
          }
          // Invariant: whoever is to move can always ask.
          if (!g.isOver) expect(g.legalMoves, isNotEmpty);
        }
      }
      expect(found, greaterThan(0));
    });

    test('game can be decided by the deal alone', () {
      // Defensive: if both dealt hands consist only of quartets the game is
      // over right away. Not hit by the demo seeds, but the deal path runs
      // the end check; verify no seed starts with an unplayable state.
      for (var seed = 0; seed < 200; seed++) {
        final g = QuartettGame(QuartettMode.sets, seed: seed);
        expect(g.isOver || g.legalMoves.isNotEmpty, isTrue);
      }
    });
  });

  group('common contract', () {
    final rnd = Random(1234);

    void randomGame(QuartettMode mode, int seed, {int handSize = 16}) {
      final g = QuartettGame(mode, seed: seed, handSize: handSize);
      var moves = 0;
      while (!g.isOver) {
        final legal = g.legalMoves;
        expect(legal, isNotEmpty);
        expect(g.applyMove(legal[rnd.nextInt(legal.length)]), isNotNull);
        if (!g.isOver && mode == QuartettMode.sets) {
          expect(g.handOf(g.currentPlayer), isNotEmpty);
        }
        expect(++moves, lessThan(10000));
      }
      expect(g.result.isOver, isTrue);
      expect(g.result.reason, isNotEmpty);
      expect(g.result.code, isNotNull);
      expect(g.legalMoves, isEmpty);
      final snap = snapshot(g);
      expect(
          g.applyMove(g.mode == QuartettMode.trumpf ? pick('ps') : ask('A1')),
          isNull);
      expect(snapshot(g), snap);
      if (mode == QuartettMode.sets) {
        final qa = g.quartetsOf(Player.a).length;
        final qb = g.quartetsOf(Player.b).length;
        expect(qa + qb, 8);
        expect(g.result.draw, qa == qb);
      }
      expect(g.history.length, moves);
    }

    test('random legal games terminate in every mode', () {
      for (var seed = 0; seed < 25; seed++) {
        randomGame(QuartettMode.trumpf, seed);
        randomGame(QuartettMode.sets, seed);
        randomGame(QuartettMode.sets, seed, handSize: 1 + seed % 8);
      }
    });

    test('legalMoves consistent with applyMove on random states', () {
      final candidates = {
        QuartettMode.trumpf: [
          for (final s in QuartettGame.stats) pick(s.id),
          pick('x'),
          ask('A1'),
        ],
        QuartettMode.sets: [
          for (final c in QuartettGame.deck) ask(c.id),
          ask('Q1'),
          pick('ps'),
        ],
      };
      for (final mode in QuartettMode.values) {
        for (final handSize in mode == QuartettMode.sets ? [16, 5] : [16]) {
          for (var seed = 0; seed < 8; seed++) {
            // Random prefix.
            final prefix = <Map<String, dynamic>>[];
            final g = QuartettGame(mode, seed: seed, handSize: handSize);
            final steps = rnd.nextInt(40);
            for (var i = 0; i < steps && !g.isOver; i++) {
              final legal = g.legalMoves;
              final m = legal[rnd.nextInt(legal.length)];
              prefix.add(m);
              g.applyMove(m);
            }
            final legal = g.legalMoves.map((m) => m.toString()).toSet();
            for (final m in candidates[mode]!) {
              final probe = replay(mode, seed, prefix, handSize: handSize);
              final snap = snapshot(probe);
              final e = probe.applyMove(m);
              if (legal.contains(m.toString())) {
                expect(e, isNotNull, reason: '$m should be legal');
              } else {
                expect(e, isNull, reason: '$m should be illegal');
                expect(snapshot(probe), snap);
              }
            }
          }
        }
      }
    });
  });
}
