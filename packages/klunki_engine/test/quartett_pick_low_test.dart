import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-100: the Trumpf house rule "with 3 or fewer cards you choose which
/// card to play" ([QuartettGame.pickLowCards]).
void main() {
  Map<String, dynamic> pick(String stat) => {'action': 'pick', 'stat': stat};
  Map<String, dynamic> choose(String card) => {'action': 'choose', 'card': card};
  Player other(Player p) => p == Player.a ? Player.b : Player.a;
  List<String> ids(Iterable<Card> cards) => [for (final c in cards) c.id];

  /// Everything observable, for "a rejected move changes nothing".
  String snapshot(QuartettGame g) => jsonEncode([
        g.currentPlayer.name,
        g.picker.name,
        g.announcedStat?.id,
        g.tricks,
        g.potSize,
        for (final p in Player.values) [ids(g.stackOf(p)), g.chosenCard(p)?.id],
        g.history.length,
        g.legalMoves,
      ]);

  /// Plays [g] (first legal move, or a random one with [rng]) until [stop]
  /// holds; false if the game ended first.
  bool playUntil(QuartettGame g, bool Function(QuartettGame) stop, [Random? rng]) {
    while (!stop(g)) {
      if (g.isOver) return false;
      final legal = g.legalMoves;
      expect(g.applyMove(legal[rng?.nextInt(legal.length) ?? 0]), isNotNull);
    }
    return true;
  }

  /// A game with the rule on reaching [stop] (searching seeds).
  QuartettGame findGame(bool Function(QuartettGame) stop) {
    for (var seed = 0; seed < 400; seed++) {
      final g = QuartettGame(QuartettMode.trumpf, seed: seed, pickLowCards: true);
      if (playUntil(g, stop, Random(seed))) return g;
    }
    fail('no game reached the position');
  }

  /// 32 cards, `same` equal on every card (every pick of it ties), `n`
  /// distinct: the card's position in the deck (A1 = 1 … H4 = 32).
  final tieDeck = QuartettDeck.build(
    id: 'test-ties',
    name: 'Test',
    stats: const [
      QuartettStat(id: 'same', label: 'Same', unit: ''),
      QuartettStat(id: 'n', label: 'Number', unit: ''),
    ],
    setNames: {for (final s in 'ABCDEFGH'.split('')) s: s},
    rows: [
      for (final (i, s) in 'ABCDEFGH'.split('').indexed)
        for (var k = 1; k <= 4; k++) ('$s$k', '$s$k', [1, i * 4 + k]),
    ],
  );

  group('rule off', () {
    test('a bare engine keeps the classic rules: only picks, the top card plays, all game long', () {
      for (var seed = 0; seed < 20; seed++) {
        final g = QuartettGame(QuartettMode.trumpf, seed: seed);
        expect(g.pickLowCards, isFalse);
        final rng = Random(seed);
        while (!g.isOver) {
          expect(g.legalMoves.every((m) => m['action'] == 'pick'), isTrue);
          expect(g.mustChoose, isFalse);
          final p = g.currentPlayer;
          final ta = g.topCard(Player.a)!.id, tb = g.topCard(Player.b)!.id;
          final legal = g.legalMoves;
          final e = g.applyMove(legal[rng.nextInt(legal.length)])!;
          expect((e.payload as Map)['cards'], {'a': ta, 'b': tb});
          expect((e.payload as Map).containsKey('picker'), isFalse);
          expect((e.payload as Map).containsKey('chosen'), isFalse);
          if (!g.isOver && (e.payload as Map)['trickWinner'] == null) expect(g.currentPlayer, p);
        }
      }
    });

    test('choose is refused', () {
      final g = QuartettGame(QuartettMode.trumpf, seed: 3);
      final before = snapshot(g);
      expect(g.applyMove(choose(g.topCard(Player.a)!.id)), isNull);
      expect(snapshot(g), before);
    });

    test('GameConfig: on by default, carried as pickLow: false when off', () {
      const on = GameConfig('quartett-trumpf', seed: 4);
      const off = GameConfig('quartett-trumpf', seed: 4, pickLowCards: false);
      expect(on.pickLowCards, isTrue);
      expect(on.toJson().containsKey('pickLow'), isFalse);
      expect(off.toJson()['pickLow'], false);
      expect(off.publicJson(), {'game': 'quartett-trumpf', 'pickLow': false});
      expect(GameConfig.fromJson(off.toJson()), off);
      expect(GameConfig.fromJson(on.toJson()), on);
      expect(GameConfig.fromJson({'game': 'quartett-trumpf'}).pickLowCards, isTrue);
      expect(off.copyWith(seed: 9).pickLowCards, isFalse);
      expect(on == off, isFalse);
      expect((createGame(on) as QuartettGame).pickLowCards, isTrue);
      expect((createGame(off) as QuartettGame).pickLowCards, isFalse);
    });

    test('the rule bumps the Trumpf rules version (old builds refuse new ones)', () {
      expect(specById('quartett-trumpf')!.rulesVersion, 2);
      expect(fingerprintOf(const GameConfig('quartett-trumpf'))!.rules, 2);
      expect(specById('quartett-sets')!.rulesVersion, 1);
    });
  });

  group('rule on', () {
    test('with 4 or more cards nothing changes', () {
      final g = QuartettGame(QuartettMode.trumpf, seed: 1, pickLowCards: true);
      expect(g.choosesCard(Player.a), isFalse);
      expect(g.legalMoves.every((m) => m['action'] == 'pick'), isTrue);
      final before = snapshot(g);
      expect(g.applyMove(choose(g.topCard(Player.a)!.id)), isNull);
      expect(snapshot(g), before);
    });

    test('a low picker sees its cards, must choose first, then picks; the chosen card is compared', () {
      final g = findGame((g) =>
          g.currentPlayer == g.picker &&
          g.choosesCard(g.picker) &&
          g.stackSize(g.picker) >= 2 &&
          !g.choosesCard(other(g.picker)));
      final me = g.picker, opp = other(me);
      final stack = g.stackOf(me);
      expect(g.mustChoose, isTrue);
      expect(g.legalMoves, [for (final c in stack) choose(c.id)]);

      // Picking first, a card not held, or a malformed move: refused.
      var before = snapshot(g);
      expect(g.applyMove(pick(g.stats.first.id)), isNull);
      expect(g.applyMove(choose(g.stackOf(opp).first.id)), isNull);
      expect(g.applyMove({'action': 'choose'}), isNull);
      expect(g.applyMove({'action': 'choose', 'card': 7}), isNull);
      expect(snapshot(g), before);

      // Choose the last card (not the top one): the turn stays.
      final chosen = stack.last;
      final e = g.applyMove(choose(chosen.id))!;
      expect(e.payload, {'chose': true});
      expect(g.currentPlayer, me);
      expect(g.chosenCard(me), chosen);
      expect(g.playedCard(me), chosen);
      expect(g.legalMoves.every((m) => m['action'] == 'pick'), isTrue);
      before = snapshot(g);
      expect(g.applyMove(choose(stack.first.id)), isNull, reason: 'one choice per round');
      expect(snapshot(g), before);

      final oppTop = g.topCard(opp)!;
      final r = g.applyMove(pick('ps'))!.payload as Map;
      expect(r['cards'], {me.name: chosen.id, opp.name: oppTop.id});
      expect(r['chosen'], [me.name]);
      expect(r.containsKey('picker'), isFalse);
      expect(g.chosenCard(me), isNull);
      // The rest of the stack keeps its order; the chosen card moved like a
      // top card would.
      final rest = ids(stack.where((c) => c != chosen));
      final w = r['trickWinner'];
      if (w == me.name) {
        expect(ids(g.stackOf(me)).take(rest.length + 2), [...rest, chosen.id, oppTop.id]);
      } else {
        expect(ids(g.stackOf(me)), rest);
        if (w == opp.name) expect(ids(g.stackOf(opp)).reversed.take(2).toList().reversed, isNotEmpty);
      }
      expect(g.history.map((h) => h['action']).toList().reversed.take(2), ['pick', 'choose']);
    });

    test('a low defender chooses after the stat is announced; then the round is compared', () {
      final g = findGame((g) =>
          g.currentPlayer == g.picker &&
          !g.choosesCard(g.picker) &&
          g.choosesCard(other(g.picker)) &&
          g.stackSize(other(g.picker)) >= 2);
      final me = g.picker, opp = other(me);
      final myTop = g.topCard(me)!;
      final oppStack = g.stackOf(opp);
      expect(g.legalMoves.every((m) => m['action'] == 'pick'), isTrue);

      final announce = g.applyMove(pick('ps'))!;
      expect(announce.payload, {'stat': 'ps', 'announced': true});
      expect(g.currentPlayer, opp, reason: 'the defender acts');
      expect(g.picker, me);
      expect(g.announcedStat!.id, 'ps');
      expect(g.mustChoose, isTrue);
      expect(g.legalMoves, [for (final c in oppStack) choose(c.id)]);

      final before = snapshot(g);
      expect(g.applyMove(pick('ps')), isNull, reason: 'no second pick');
      expect(g.applyMove(choose(myTop.id)), isNull, reason: "not the defender's card");
      expect(snapshot(g), before);

      // The defender takes its best card for the stat.
      final stat = g.statById('ps')!;
      final best = oppStack.reduce((x, y) => stat.beats(y.stats['ps']!, x.stats['ps']!) ? y : x);
      final tricks = g.tricks;
      final r = g.applyMove(choose(best.id))!.payload as Map;
      expect(r['cards'], {me.name: myTop.id, opp.name: best.id});
      expect(r['picker'], me.name);
      expect(r['chosen'], [opp.name]);
      expect(g.tricks, tricks + 1);
      expect(g.announcedStat, isNull);
      expect(g.chosenCard(opp), isNull);
      final w = r['trickWinner'];
      if (!g.isOver) expect(g.currentPlayer, w == null ? me : (w == 'a' ? Player.a : Player.b));
    });

    test('both low: picker chooses, picks, defender chooses; ties feed the pot as usual', () {
      final g = QuartettGame(QuartettMode.trumpf, seed: 5, deck: tieDeck, pickLowCards: true);
      // 13 ties: 3 cards each, 26 in the pot, the same picker throughout.
      for (var i = 0; i < 13; i++) {
        expect(g.mustChoose, isFalse);
        expect(g.applyMove(pick('same')), isNotNull);
      }
      expect(g.stackSize(Player.a), 3);
      expect(g.stackSize(Player.b), 3);
      expect(g.potSize, 26);
      expect(g.picker, Player.a);
      expect(g.choosesCard(Player.a) && g.choosesCard(Player.b), isTrue);

      // A tie with chosen cards: both go to the pot, the picker picks again.
      final a1 = g.stackOf(Player.a)[1], b2 = g.stackOf(Player.b)[2];
      g.applyMove(choose(a1.id));
      expect(g.applyMove(pick('same'))!.payload, {'stat': 'same', 'announced': true});
      expect(g.currentPlayer, Player.b);
      final tie = g.applyMove(choose(b2.id))!.payload as Map;
      expect(tie['cards'], {'a': a1.id, 'b': b2.id});
      expect(tie['trickWinner'], isNull);
      expect(tie['chosen'], ['a', 'b']);
      expect(tie['picker'], 'a');
      expect(g.potSize, 28);
      expect(g.stackOf(Player.a), isNot(contains(a1)));
      expect(g.stackOf(Player.b), isNot(contains(b2)));
      expect(g.currentPlayer, Player.a);
      expect(g.mustChoose, isTrue);

      // A decides with its weaker card, B answers with its stronger one: B
      // wins the pot and plays its top card again (more than 3 cards).
      final aCards = g.stackOf(Player.a), bCards = g.stackOf(Player.b);
      int n(Card c) => c.stats['n']!.toInt();
      final aWeak = aCards.reduce((x, y) => n(x) < n(y) ? x : y);
      final bStrong = bCards.reduce((x, y) => n(x) > n(y) ? x : y);
      g.applyMove(choose(aWeak.id));
      g.applyMove(pick('n'));
      final r = g.applyMove(choose(bStrong.id))!.payload as Map;
      final bWins = n(bStrong) > n(aWeak);
      expect(r['trickWinner'], bWins ? 'b' : 'a');
      if (bWins) {
        expect(g.stackSize(Player.b), 1 + 2 + 28);
        expect(g.stackSize(Player.a), 1);
        expect(ids(g.stackOf(Player.b)).sublist(1, 3), [bStrong.id, aWeak.id]);
        // B is back above 3: the top card plays. A's single last card has
        // no alternative: no choice, the round is compared at once.
        expect(g.currentPlayer, Player.b);
        expect(g.choosesCard(Player.b), isFalse);
        expect(g.choosesCard(Player.a), isFalse);
        expect(g.legalMoves.every((m) => m['action'] == 'pick'), isTrue);
        final last = g.stackOf(Player.a).single;
        final r2 = g.applyMove(pick('n'))!.payload as Map;
        expect((r2['cards'] as Map)['a'], last.id);
        expect(r2.containsKey('chosen'), isFalse);
      }
    });

    test('back above 3 cards the top card plays again', () {
      final g = findGame((g) {
        if (g.history.length < 2 || g.currentPlayer != g.picker) return false;
        final last = g.history.last;
        // The last round was completed with a choice by a player who won it
        // and now holds more than 3 cards.
        return last['action'] == 'choose' && g.stackSize(last['player'] as Player) > 3 && g.announcedStat == null;
      });
      final p = g.history.last['player'] as Player;
      expect(g.choosesCard(p), isFalse);
      if (g.currentPlayer == p) expect(g.legalMoves.every((m) => m['action'] == 'pick'), isTrue);
    });

    test('random full games stay consistent and always end', () {
      var chooses = 0;
      for (var seed = 0; seed < 60; seed++) {
        final g = QuartettGame(QuartettMode.trumpf, seed: seed, pickLowCards: true);
        final rng = Random(seed);
        var steps = 0;
        while (!g.isOver) {
          expect(++steps, lessThan(2000));
          expect(g.stackSize(Player.a) + g.stackSize(Player.b) + g.potSize, 32);
          final legal = g.legalMoves;
          expect(legal, isNotEmpty);
          final acting = g.currentPlayer;
          expect(legal.every((m) => m['action'] == (g.mustChoose ? 'choose' : 'pick')), isTrue);
          if (g.announcedStat != null) expect(acting, other(g.picker));
          final m = legal[rng.nextInt(legal.length)];
          if (m['action'] == 'choose') chooses++;
          expect(g.applyMove(m), isNotNull);
        }
        expect(g.tricks, lessThanOrEqualTo(QuartettGame.maxTricks));
      }
      expect(chooses, greaterThan(0), reason: 'the low phase is reached');
    });

    test('replays through the registry (on by default) and resigns mid-choice', () {
      final game = createGame(const GameConfig('quartett-trumpf', seed: 11)) as QuartettGame;
      final moves = <Map<String, dynamic>>[];
      final rng = Random(2);
      while (!game.isOver && !moves.any((m) => m['action'] == 'choose')) {
        final legal = game.legalMoves;
        final m = legal[rng.nextInt(legal.length)];
        moves.add(m);
        game.applyMove(m);
      }
      final copy = replay(const GameConfig('quartett-trumpf', seed: 11), moves) as QuartettGame;
      expect(snapshot(copy), snapshot(game));
      expect(replay(const GameConfig('quartett-trumpf', seed: 11, pickLowCards: false), moves), isNull);
      if (!game.isOver) {
        final defender = game.currentPlayer; // whoever acts
        expect(game.applyMove(Game.resignMove(defender)), isNotNull);
        expect(game.result.winner, other(defender));
        expect(game.legalMoves, isEmpty);
      }
    });
  });

  group('redaction', () {
    const r = QuartettRedaction();

    test("the opponent sees that a card was chosen, not which", () {
      expect(r.redactMove(choose('B3'), Player.a, Player.b), {'action': 'choose'});
      expect(r.redactMove(choose('B3'), Player.a, Player.a), choose('B3'));
      expect(r.redactMove(pick('ps'), Player.a, Player.b), pick('ps'));
    });

    test("views never hold the opponent's low hand or choice; the announced stat is public", () {
      void noLeak(Map<String, dynamic> view, Iterable<Card> secret) {
        final text = jsonEncode(view);
        for (final c in secret) {
          expect(text, isNot(contains('"${c.id}"')), reason: '${c.id} leaks to ${view['viewer']}');
        }
      }

      // A low picker: its hand and choice stay its own.
      final g1 = findGame((g) => g.currentPlayer == g.picker && g.choosesCard(g.picker) && g.stackSize(g.picker) >= 2);
      final p1 = g1.picker, o1 = other(p1);
      final mine = g1.stackOf(p1).last;
      g1.applyMove(choose(mine.id));
      final own = r.view(g1, p1), theirs = r.view(g1, o1);
      expect(own['hand'], ids(g1.stackOf(p1)));
      expect(own['chosen'], mine.id);
      expect(theirs.containsKey('chosen'), isFalse);
      noLeak(theirs, g1.stackOf(p1));
      final v1 = r.fromView(jsonDecode(jsonEncode(own)) as Map<String, dynamic>) as QuartettGame;
      expect(v1.chosenCard(p1), mine);
      expect(v1.legalMoves.every((m) => m['action'] == 'pick'), isTrue);

      // A low defender after the announcement.
      final g = findGame((g) =>
          g.currentPlayer == g.picker &&
          !g.choosesCard(g.picker) &&
          g.choosesCard(other(g.picker)) &&
          g.stackSize(other(g.picker)) >= 2);
      final me = g.picker, opp = other(me);
      final myTop = g.topCard(me)!;
      g.applyMove(pick('kg'));
      final forMe = r.view(g, me), forOpp = r.view(g, opp);
      expect(forOpp['hand'], ids(g.stackOf(opp)));
      expect(forMe.containsKey('hand'), isFalse);
      expect(forMe['announced'], 'kg');
      expect(forOpp['announced'], 'kg');
      expect(forMe['current'], opp.name);
      noLeak(forMe, g.stackOf(opp));
      noLeak(forOpp, g.stackOf(me));

      // The defender's view: its turn, its own hand to choose from.
      final vd = r.fromView(jsonDecode(jsonEncode(forOpp)) as Map<String, dynamic>) as QuartettGame;
      expect(vd.currentPlayer, opp);
      expect(vd.picker, me);
      expect(vd.announcedStat!.id, 'kg');
      expect(vd.legalMoves, [for (final c in g.stackOf(opp)) choose(c.id)]);
      // The picker's view: waiting.
      final vp = r.fromView(jsonDecode(jsonEncode(forMe)) as Map<String, dynamic>) as QuartettGame;
      expect(vp.currentPlayer, opp);
      expect(vp.legalMoves, isEmpty);
      expect(vp.stackOf(opp), isEmpty);

      // The resolved round shows both cards (the reveal); the choice itself
      // reaches the picker without its card.
      final card = g.stackOf(opp).last;
      final e = g.applyMove(choose(card.id))!;
      final step = r.step(g, choose(card.id), opp, e, me);
      expect(step['move'], {'action': 'choose'});
      expect((step['event'] as Map)['payload']['cards'], {me.name: myTop.id, opp.name: card.id});
    });

    test('malformed views are refused', () {
      final g = findGame((g) => g.choosesCard(Player.a) && g.stackSize(Player.a) >= 2);
      final v = r.view(g, Player.a);
      expect(
          () => r.fromView({
                ...v,
                'hand': ['A1']
              }),
          throwsA(isA<BadViewException>()));
      expect(() => r.fromView({...v, 'chosen': 'ZZ'}), throwsA(isA<BadViewException>()));
      expect(() => r.fromView({...v, 'announced': 'nope'}), throwsA(isA<BadViewException>()));
    });
  });

  group('text game', () {
    test('autoMove plays the new phases to the end; the defender takes its best card for the stat', () {
      var defended = 0;
      for (var seed = 0; seed < 30; seed++) {
        final t = QuartettTrumpfText(seed);
        final g = t.game;
        expect(g.pickLowCards, isTrue);
        final rng = Random(seed);
        while (!g.isOver) {
          final m = t.autoMove(rng);
          expect(t.legalMoves, anyElement(equals(m)));
          final announced = g.announcedStat;
          if (announced != null) {
            defended++;
            final best = g
                .stackOf(g.currentPlayer)
                .map((c) => c.stats[announced.id]!)
                .reduce((x, y) => announced.beats(y, x) ? y : x);
            expect(g.cardById(m['card'] as String)!.stats[announced.id], best);
          }
          final mover = g.currentPlayer;
          final e = g.applyMove(m)!;
          expect(t.narrate(mover, m, e), isNotEmpty);
        }
      }
      expect(defended, greaterThan(0));
    });

    test('render, parse and narrate the choose phases', () {
      final g = findGame((g) =>
          g.currentPlayer == g.picker &&
          g.choosesCard(g.picker) &&
          g.stackSize(g.picker) >= 2 &&
          !g.choosesCard(other(g.picker)));
      final t = QuartettTrumpfText.forGame(g);
      final me = g.picker;
      final cards = g.stackOf(me);
      expect(t.render(), contains('has only ${cards.length} cards – choose one:'));
      expect(t.render(), contains(cards.last.name));
      expect(t.parse('2'), choose(cards[1].id));
      expect(t.parse(cards.last.id.toLowerCase()), choose(cards.last.id));
      expect(t.parse('ps'), isNull);
      expect(t.parse('9'), isNull);
      expect(t.moveHelp, contains('choose the card'));
      final m = t.parse('${cards.length}')!;
      expect(t.narrate(me, m, g.applyMove(m)!), '${t.mark(me)} chooses a card.');
      expect(t.format(m), cards.last.id);
      expect(t.format({'action': 'choose'}), 'a card');
      expect(t.render(), contains("chosen card: ${cards.last.id}"));
      expect(t.parse('1'), pick(g.stats.first.id));
      final e = g.applyMove(pick('ps'))!;
      expect(t.narrate(me, pick('ps'), e), startsWith('${t.mark(me)} picks Leistung:'));

      final d =
          findGame((g) => g.currentPlayer == g.picker && !g.choosesCard(g.picker) && g.choosesCard(other(g.picker)));
      final td = QuartettTrumpfText.forGame(d);
      final picker = d.picker;
      final a = d.applyMove(pick('kg'))!;
      expect(td.narrate(picker, pick('kg'), a),
          '${td.mark(picker)} picks Gewicht – ${td.mark(other(picker))} chooses a card.');
      expect(td.render(),
          contains('${td.mark(picker)} picks Gewicht (lower wins). ${td.mark(other(picker))}, choose your card:'));
      final c = td.parse('1')!;
      final r = d.applyMove(c)!;
      expect(td.narrate(other(picker), c, r), startsWith('${td.mark(other(picker))} chooses: ${td.mark(picker)}'));
    });

    test('restart keeps the rule setting; the console plays it', () {
      expect(QuartettTrumpfText(1, null, false).restart().game.pickLowCards, isFalse);
      expect(QuartettTrumpfText(1).restart().game.pickLowCards, isTrue);
      final c = DebugConsole('quartett-trumpf', 3)..handle('auto');
      expect(c.current.game.isOver, isTrue);
    });
  });
}
