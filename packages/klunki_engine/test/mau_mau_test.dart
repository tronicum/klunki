import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-118: the Mau-Mau engine.
void main() {
  Map<String, dynamic> play(String card, {String? suit, bool mau = false}) =>
      {'action': 'play', 'card': card, if (suit != null) 'suit': suit, if (mau) 'mau': true};
  const draw = {'action': 'draw'};
  const pass = {'action': 'pass'};

  MauMauGame setup(List<String> a, List<String> b, String top,
          {List<String> stock = const [], MauMauRules rules = const MauMauRules()}) =>
      MauMauGame(rules: rules)..debugSetup(a: a, b: b, top: top, stock: stock);

  List<String> ids(Iterable<MauMauCard> cards) => [for (final c in cards) c.id];

  /// [move] is refused and changes nothing.
  void refused(MauMauGame g, Map<String, dynamic> move) {
    final before = jsonEncode([g.viewJson(Player.a), g.viewJson(Player.b), g.history.length, g.stockCount]);
    expect(g.applyMove(move), isNull, reason: '$move');
    expect(jsonEncode([g.viewJson(Player.a), g.viewJson(Player.b), g.history.length, g.stockCount]), before,
        reason: '$move changed the state');
  }

  group('deck and deal', () {
    test('32 cards, 7 to ace in four suits, ids round-trip', () {
      expect(MauMauCard.deck, hasLength(32));
      expect(MauMauCard.deck.toSet(), hasLength(32));
      for (final c in MauMauCard.deck) {
        expect(MauMauCard.byId(c.id), c);
      }
      expect(MauMauCard.byId('h10')!.rank, MauMauRank.ten);
      expect(MauMauCard.byId('cJ')!.suit, MauMauSuit.clubs);
      expect(MauMauCard.byId('x7'), isNull);
      expect(MauMauCard.byId('h6'), isNull);
      expect(MauMauCard.byId('h'), isNull);
    });

    test('5 cards each, one face up, 21 in the draw pile; every card once; A starts', () {
      for (final seed in [0, 1, 42]) {
        final g = MauMauGame(seed: seed);
        expect(g.handCount(Player.a), 5);
        expect(g.handCount(Player.b), 5);
        expect(g.discardCount, 1);
        expect(g.stockCount, 21);
        expect(g.currentPlayer, Player.a);
        expect(g.wish, isNull);
        expect(g.penalty, 0, reason: 'the start card has no effect');
        final all = [...g.handOf(Player.a), ...g.handOf(Player.b), g.topCard];
        expect(all.toSet(), hasLength(11));
      }
    });

    test('the same seed deals the same, another seed differently', () {
      expect(ids(MauMauGame(seed: 7).handOf(Player.a)), ids(MauMauGame(seed: 7).handOf(Player.a)));
      expect(MauMauGame(seed: 7).topCard, MauMauGame(seed: 7).topCard);
      expect(ids(MauMauGame(seed: 7).handOf(Player.a)), isNot(ids(MauMauGame(seed: 8).handOf(Player.a))));
    });
  });

  group('laying and drawing', () {
    test('a card of the same suit or rank fits, others do not', () {
      final g = setup(['h7', 'c9', 'sK', 'dA', 'cQ'], ['s8', 's9', 'd9', 'dK', 'dQ'], 'h9', stock: ['c8']);
      expect(ids(g.playableCards), ['h7', 'c9']);
      refused(g, play('sK'));
      refused(g, play('dA'));
      refused(
        g,
        play('s8'),
      );
      final e = g.applyMove(play('c9'))!;
      expect(e.payload, {'card': 'c9'});
      expect(g.topCard.id, 'c9');
      expect(g.handCount(Player.a), 4);
      expect(g.currentPlayer, Player.b);
      expect(g.discardCount, 2);
    });

    test('a drawn card that does not fit ends the turn', () {
      final g = setup(['c7', 'c8', 'sK', 'sQ', 'cA'], ['s8'], 'h9', stock: ['dK', 'h10']);
      final e = g.applyMove(draw)!;
      expect(e.payload, {
        'drew': ['dK'],
        'count': 1,
        'fits': false
      });
      expect(g.currentPlayer, Player.b);
      expect(g.handCount(Player.a), 6);
      expect(g.stockCount, 1);
      expect(g.hasDrawn, isFalse);
    });

    test('a drawn card that fits may be laid at once, nothing else', () {
      final g = setup(['h7', 'c8'], ['s8'], 'h9', stock: ['h10', 'dK']);
      final e = g.applyMove(draw)!;
      expect(e.payload, {
        'drew': ['h10'],
        'count': 1,
        'fits': true
      });
      expect(g.currentPlayer, Player.a);
      expect(g.drawnCard!.id, 'h10');
      expect(g.legalMoves, [play('h10'), pass]);
      refused(g, play('h7'));
      refused(g, draw);
      expect(g.applyMove(play('h10')), isNotNull);
      expect(g.currentPlayer, Player.b);
      expect(g.drawnCard, isNull);
    });

    test('or kept with pass', () {
      final g = setup(['h7', 'c8'], ['s8'], 'h9', stock: ['h10', 'dK']);
      g.applyMove(draw);
      final e = g.applyMove(pass)!;
      expect(e.payload, {'kept': true});
      expect(g.currentPlayer, Player.b);
      expect(ids(g.handOf(Player.a)), ['h7', 'c8', 'h10']);
      expect(g.hasDrawn, isFalse);
    });

    test('pass is not allowed while there is something to draw', () {
      final g = setup(['c7'], ['s8'], 'h9', stock: ['dK']);
      refused(g, pass);
    });

    test('drawing is allowed even with a card that fits', () {
      final g = setup(['h7', 'c8'], ['s8'], 'h9', stock: ['dK']);
      expect(g.legalMoves, containsAll([play('h7'), draw]));
      expect(g.applyMove(draw), isNotNull);
    });

    test('malformed moves are refused without a change', () {
      final g = setup(['h7', 'cJ', 'c8'], ['s8'], 'h9', stock: ['dK']);
      for (final m in <Map<String, dynamic>>[
        {'action': 'play'},
        {'action': 'play', 'card': 7},
        {'action': 'play', 'card': 'h7', 'suit': 'c'},
        {'action': 'play', 'card': 'cJ'},
        {'action': 'play', 'card': 'cJ', 'suit': 'x'},
        {'action': 'play', 'card': 'h7', 'mau': true},
        {'action': 'play', 'card': 'h7', 'extra': 1},
        {'action': 'pass', 'x': 1},
        {'action': 'jump'},
        {},
      ]) {
        refused(g, m);
      }
    });
  });

  group('7: draw two', () {
    test('the next player draws 2 and the turn ends', () {
      final g = setup(['h7', 'c8'], ['s9', 'd9'], 'h9', stock: ['dK', 'dQ', 'd10']);
      final e = g.applyMove(play('h7'))!;
      expect(e.payload, {'card': 'h7', 'penalty': 2});
      expect(g.currentPlayer, Player.b);
      expect(g.penalty, 2);
      expect(g.legalMoves, [draw], reason: 'B has no 7');
      refused(g, play('s9'));
      final d = g.applyMove(draw)!;
      expect(d.payload, {
        'drew': ['dK', 'dQ'],
        'count': 2,
        'penalty': 2
      });
      expect(g.handCount(Player.b), 4);
      expect(g.penalty, 0);
      expect(g.currentPlayer, Player.a, reason: 'the penalty draw ends the turn');
    });

    test('stacked 7s add up: 2, 4, …', () {
      final g = setup(['h7', 'c7', 'c8'], ['s7', 'd9'], 'h9', stock: ['dK', 'dQ', 'd10', 'sQ', 'sK', 'cK']);
      g.applyMove(play('h7'));
      expect(g.legalMoves, [play('s7'), draw]);
      final e = g.applyMove(play('s7'))!;
      expect(e.payload, {'card': 's7', 'penalty': 4});
      expect(g.currentPlayer, Player.a);
      g.applyMove(play('c7'));
      expect(g.penalty, 6);
      g.applyMove(draw);
      expect(g.handCount(Player.b), 7);
      expect(g.currentPlayer, Player.a);
    });

    test('without stacking a 7 cannot be answered with a 7', () {
      final g =
          setup(['h7', 'c8'], ['s7', 'd9'], 'h9', stock: ['dK', 'dQ'], rules: const MauMauRules(stackSevens: false));
      g.applyMove(play('h7'));
      expect(g.legalMoves, [draw]);
      refused(g, play('s7'));
    });

    test('switched off, a 7 is a plain card', () {
      final g = setup(['h7', 'c8'], ['s9', 'd9'], 'h9', stock: ['dK'], rules: const MauMauRules(sevenDraws: false));
      expect(g.applyMove(play('h7'))!.payload, {'card': 'h7'});
      expect(g.penalty, 0);
      expect(g.currentPlayer, Player.b);
    });
  });

  group('8: skip', () {
    test('the other player is skipped: the same player lays again', () {
      final g = setup(['h8', 'c8', 'cK'], ['s9'], 'h9', stock: ['dK']);
      final e = g.applyMove(play('h8'))!;
      expect(e.payload, {'card': 'h8', 'again': true});
      expect(g.currentPlayer, Player.a);
      expect(g.applyMove(play('c8')), isNotNull);
      expect(g.currentPlayer, Player.a);
      expect(g.applyMove(play('cK')), isNotNull);
      expect(g.isOver, isTrue);
    });

    test('switched off, an 8 is a plain card', () {
      final g = setup(['h8', 'c8'], ['s9'], 'h9', rules: const MauMauRules(eightSkips: false));
      g.applyMove(play('h8'));
      expect(g.currentPlayer, Player.b);
    });
  });

  group('jack: wish a suit', () {
    test('lies on anything and wishes a suit, which the next card must have', () {
      final g = setup(['cJ', 'c8'], ['s9', 'd9', 'dK', 'h9'], 'hK', stock: ['dQ']);
      expect(g.legalMoves.where((m) => m['card'] == 'cJ'), [
        for (final s in ['c', 's', 'h', 'd']) play('cJ', suit: s)
      ]);
      final e = g.applyMove(play('cJ', suit: 'd'))!;
      expect(e.payload, {'card': 'cJ', 'wish': 'd'});
      expect(g.wish, MauMauSuit.diamonds);
      expect(ids(g.playableCards), ['d9', 'dK'], reason: 'not s9 or h9 (no clubs or jack rank match either)');
      refused(g, play('h9'));
      g.applyMove(play('d9'));
      expect(g.wish, isNull, reason: 'the wish is fulfilled');
      expect(g.topCard.id, 'd9');
    });

    test('the wish stays while the next player draws', () {
      final g = setup(['cJ', 'c8'], ['s9'], 'hK', stock: ['sK', 'hQ']);
      g.applyMove(play('cJ', suit: 'd'));
      g.applyMove(draw); // B: sK does not fit the wish
      expect(g.wish, MauMauSuit.diamonds);
      expect(g.currentPlayer, Player.a);
      refused(g, play('c8'));
    });

    test('no jack on a jack, unless the house rule allows it', () {
      final g = setup(['cJ', 'c8'], ['sJ', 'd9'], 'hK', stock: ['dQ']);
      g.applyMove(play('cJ', suit: 'd'));
      expect(ids(g.playableCards), ['d9']);
      refused(g, play('sJ', suit: 'h'));

      final h = setup(['cJ', 'c8'], ['sJ', 'd9'], 'hK', stock: ['dQ'], rules: const MauMauRules(jackOnJack: true));
      h.applyMove(play('cJ', suit: 'd'));
      expect(h.applyMove(play('sJ', suit: 'h')), isNotNull);
      expect(h.wish, MauMauSuit.hearts);
    });

    test('a jack needs a suit; other cards must not name one', () {
      final g = setup(['cJ', 'h8'], ['s9'], 'hK');
      refused(g, play('cJ'));
      refused(g, play('h8', suit: 'h'));
    });

    test('a jack as the start card wishes nothing: its suit counts', () {
      final g = setup(['c8', 'h8', 'dJ'], ['s9'], 'cJ', stock: ['dQ']);
      expect(g.wish, isNull);
      expect(ids(g.playableCards), ['c8'], reason: 'no jack on a jack');
    });
  });

  group('ace (house rule)', () {
    test('off by default: a plain card', () {
      final g = setup(['hA', 'c8'], ['s9'], 'h9');
      g.applyMove(play('hA'));
      expect(g.currentPlayer, Player.b);
    });

    test('on: the same player lays again', () {
      final g = setup(['hA', 'c8'], ['s9'], 'h9', rules: const MauMauRules(aceAgain: true));
      expect(g.applyMove(play('hA'))!.payload, {'card': 'hA', 'again': true});
      expect(g.currentPlayer, Player.a);
    });
  });

  group('"Mau" (house rule)', () {
    const rules = MauMauRules(mauCall: true);

    test('the second-to-last card needs "Mau"; legal moves say it', () {
      final g = setup(['h7', 'h8'], ['s9', 'd9'], 'h9', stock: ['dK', 'dQ'], rules: rules);
      expect(g.mauDue, isTrue);
      expect(g.legalMoves, containsAll([play('h7', mau: true), play('h8', mau: true)]));
      final e = g.applyMove(play('h8', mau: true))!;
      expect(e.payload, {'card': 'h8', 'mau': true, 'again': true});
      expect(g.handCount(Player.a), 1);
      refused(g, play('h7', mau: true));
      expect(g.applyMove(play('h7')), isNotNull);
      expect(g.result.winner, Player.a);
    });

    test('forgetting it costs a penalty card', () {
      final g = setup(['h7', 'c8'], ['s9', 'd9'], 'h9', stock: ['dK', 'dQ', 'd10'], rules: rules);
      final e = g.applyMove(play('h7'))!;
      expect(e.payload, {
        'card': 'h7',
        'forgotMau': true,
        'drew': ['dK'],
        'penalty': 2
      });
      expect(ids(g.handOf(Player.a)), ['c8', 'dK']);
      expect(g.currentPlayer, Player.b);
    });

    test('off: "Mau" is not part of a move', () {
      final g = setup(['h7', 'c8'], ['s9'], 'h9', stock: ['dK']);
      expect(g.mauDue, isFalse);
      refused(g, play('h7', mau: true));
      g.applyMove(play('h7'));
      expect(g.handCount(Player.a), 1);
    });
  });

  group('draw pile', () {
    test('runs out: the discard pile without its top card is shuffled into a new one', () {
      final g = setup(['h7', 'h8', 'hK', 'c9'], ['s9', 'hQ', 'h10'], 'h9',
          stock: ['dK'], rules: const MauMauRules(eightSkips: false, sevenDraws: false));
      g.applyMove(play('h8')); // A
      g.applyMove(play('hQ')); // B
      g.applyMove(play('hK')); // A
      g.applyMove(play('h10')); // B
      expect(g.discardCount, 5);
      g.applyMove(draw); // A draws dK, the last card: does not fit
      expect(g.stockCount, 0);
      final e = g.applyMove(draw)!; // B: reshuffle
      expect((e.payload as Map)['reshuffled'], isTrue);
      expect(g.discardCount, 1);
      expect(g.topCard.id, 'h10');
      expect(g.stockCount, 3);
      final inPlay = [...g.handOf(Player.a), ...g.handOf(Player.b), g.topCard];
      expect(ids(inPlay).toSet().intersection({'h9', 'h8', 'hQ', 'hK'}), hasLength(1),
          reason: 'the drawn card came from the old discard pile');
    });

    test('nothing left to draw: who cannot lay passes', () {
      final g = setup(['c7', 'c8'], ['s9', 'h8'], 'h9');
      expect(g.drawable, 0);
      expect(g.legalMoves, [pass]);
      refused(g, draw);
      expect(g.applyMove(pass)!.payload, isEmpty);
      expect(g.currentPlayer, Player.b);
      refused(g, pass);
    });

    test('a 7 penalty with nothing to draw takes what there is', () {
      final g = setup(['h7', 'c8'], ['s9'], 'h9', stock: ['dK'], rules: const MauMauRules(stackSevens: false));
      g.applyMove(play('h7'));
      final e = g.applyMove(draw)!;
      expect((e.payload as Map)['count'], 2, reason: 'dK plus h9 from the reshuffled discard pile');
      expect(g.applyMove(draw), isNull, reason: 'A to move; nothing left');
    });
  });

  group('win', () {
    test('the last card wins, also a 7, an 8 or a jack', () {
      for (final (card, suit) in [('h7', null), ('h8', null), ('cJ', 'h')]) {
        final g = setup([card], ['s9'], 'h9');
        final e = g.applyMove(play(card, suit: suit))!;
        expect(e.winner, Player.a);
        expect(g.isOver, isTrue);
        expect(g.result.code, GameEndReason.maumauEmptyHand);
        expect(g.penalty, 0);
        expect(g.legalMoves, isEmpty);
        refused(g, draw);
      }
    });
  });

  group('replay and determinism', () {
    test('random games end, replay to the same state, and agree with the view', () {
      for (var seed = 0; seed < 40; seed++) {
        final rules = MauMauRules(
            stackSevens: seed.isEven, jackOnJack: seed % 3 == 0, aceAgain: seed % 4 == 0, mauCall: seed % 5 == 0);
        final config = GameConfig('maumau', seed: seed, mauMau: rules);
        final g = createGame(config) as MauMauGame;
        final rng = Random(seed);
        final moves = <Map<String, dynamic>>[];
        while (!g.isOver) {
          expect(moves.length, lessThan(3000), reason: 'seed $seed');
          final legal = g.legalMoves;
          expect(legal, isNotEmpty);
          // Prefer laying a card, as people do.
          final plays = legal.where((m) => m['action'] == 'play').toList();
          final m = plays.isNotEmpty && rng.nextInt(4) > 0
              ? plays[rng.nextInt(plays.length)]
              : legal[rng.nextInt(legal.length)];
          expect(g.applyMove(m), isNotNull, reason: '$m');
          moves.add(m);
          final total = g.handCount(Player.a) + g.handCount(Player.b) + g.stockCount + g.discardCount;
          expect(total, 32, reason: 'no card lost or doubled');
        }
        final r = replay(config, moves)! as MauMauGame;
        expect(jsonEncode(r.viewJson(Player.a)), jsonEncode(g.viewJson(Player.a)));
        expect(jsonEncode(r.viewJson(Player.b)), jsonEncode(g.viewJson(Player.b)));
        expect(r.result.winner, g.result.winner);
      }
    });

    test('config JSON: defaults leave no trace, house rules round-trip', () {
      expect(const GameConfig('maumau', seed: 3).toJson(), {'game': 'maumau', 'seed': 3});
      const c = GameConfig('maumau', seed: 3, mauMau: MauMauRules(stackSevens: false, mauCall: true));
      expect(c.toJson(), {
        'game': 'maumau',
        'seed': 3,
        'maumau': {'stack7': false, 'mau': true}
      });
      expect(GameConfig.fromJson(c.toJson()), c);
      expect(c.copyWith(seed: 4).mauMau, c.mauMau);
      expect((createGame(c) as MauMauGame).rules, c.mauMau);
      expect(MauMauRules.fromJson(null), const MauMauRules());
    });
  });

  group('view and redaction', () {
    test('the opponent\'s hand, the draw pile and the seed stay hidden', () {
      final g = MauMauGame(seed: 5);
      const r = MauMauRedaction();
      final json = jsonEncode(r.view(g, Player.b));
      for (final c in g.handOf(Player.a)) {
        expect(json, isNot(contains('"${c.id}"')));
      }
      expect(json, isNot(contains('seed')));
      final v = r.fromView(r.view(g, Player.b)) as MauMauView;
      expect(v.handOf(Player.a), isEmpty);
      expect(v.handCount(Player.a), 5);
      expect(ids(v.handOf(Player.b)), ids(g.handOf(Player.b)));
      expect(v.topCard, g.topCard);
      expect(v.stockCount, 21);
      expect(v.legalMoves, isEmpty, reason: 'A is to move');
      final va = r.fromView(r.view(g, Player.a)) as MauMauView;
      expect(va.legalMoves, g.legalMoves);
    });

    test('drawn cards reach the other player as a count', () {
      const r = MauMauRedaction();
      final payload = {
        'drew': ['dK', 'dQ'],
        'count': 2,
        'penalty': 2
      };
      expect(r.redactPayload(payload, Player.a, Player.b), {'count': 2, 'penalty': 2});
      expect(r.redactPayload(payload, Player.a, Player.a), payload);
      expect(
          r.redactPayload({
            'drew': ['h10'],
            'count': 1,
            'fits': true
          }, Player.a, Player.b),
          {'count': 1});
      expect(r.redactMove(draw, Player.a, Player.b), draw);
    });

    test('the drawn card is the drawer\'s secret', () {
      final g = setup(['h7', 'c8'], ['s8'], 'h9', stock: ['h10', 'dK']);
      g.applyMove(draw);
      final b = g.viewJson(Player.b);
      expect(b['hasDrawn'], isTrue);
      expect(b.containsKey('drawn'), isFalse);
      expect(g.viewJson(Player.a)['drawn'], 'h10');
      final v = MauMauView.fromJson(jsonDecode(jsonEncode(g.viewJson(Player.a))) as Map<String, dynamic>);
      expect(v.legalMoves, [play('h10'), pass]);
    });
  });

  group('text console', () {
    test('parses and formats moves', () {
      final t = MauMauText();
      expect(t.parse('h7'), play('h7'));
      expect(t.parse('S10'), play('s10'));
      expect(t.parse('cj h'), play('cJ', suit: 'h'));
      expect(t.parse('h7 mau'), play('h7', mau: true));
      expect(t.parse('draw'), draw);
      expect(t.parse('pass'), pass);
      expect(t.parse('h6'), isNull);
      expect(t.parse('h7 x'), isNull);
      expect(t.format(play('cJ', suit: 'h')), 'cJ h');
      expect(t.format(draw), 'draw');
    });

    test('auto-plays whole games to the end', () {
      for (var seed = 0; seed < 10; seed++) {
        final c = DebugConsole('maumau', seed)..handle('auto');
        expect(c.current.game.isOver, isTrue, reason: 'seed $seed');
        expect(c.current.game.result.code, GameEndReason.maumauEmptyHand);
      }
    });

    test('renders the hand of the player to move only', () {
      final t = MauMauText.forGame(setup(['h7', 'c8'], ['s9', 'd9'], 'h9', stock: ['dK']));
      final s = t.render();
      expect(s, contains('Top card: h9'));
      expect(s, contains("Anna's hand: c8 h7*"));
      expect(s, isNot(contains('s9')));
    });
  });
}
