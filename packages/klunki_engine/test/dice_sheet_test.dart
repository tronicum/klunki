import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-119: Ausgewürfelt, the five-dice score-sheet game.
void main() {
  int score(DiceBox b, List<int> d) => DiceSheetGame.scoreFor(b, d);

  /// Plays a whole game with the debug bot; returns the moves.
  List<Map<String, dynamic>> botGame(DiceSheetGame g, int seed, {bool Function(DiceSheetGame g)? after}) {
    final t = DiceSheetText(game: g);
    final rng = Random(seed);
    final moves = <Map<String, dynamic>>[];
    var n = 0;
    while (!g.isOver && n++ < 1000) {
      final m = t.autoMove(rng);
      expect(g.applyMove(m), isNotNull, reason: 'bot move $m in ${g.toJson()}');
      moves.add(m);
      if (after != null && !after(g)) break;
    }
    return moves;
  }

  group('scoring', () {
    test('upper boxes count their face', () {
      expect(score(DiceBox.ones, [1, 1, 2, 3, 1]), 3);
      expect(score(DiceBox.threes, [3, 3, 3, 3, 2]), 12);
      expect(score(DiceBox.sixes, [1, 2, 3, 4, 5]), 0);
      expect(score(DiceBox.fives, [5, 5, 5, 5, 5]), 25);
    });

    test('three and four of a kind: the sum of all dice', () {
      expect(score(DiceBox.threeKind, [4, 4, 4, 1, 2]), 15);
      expect(score(DiceBox.threeKind, [4, 4, 1, 1, 2]), 0);
      expect(score(DiceBox.threeKind, [6, 6, 6, 6, 6]), 30);
      expect(score(DiceBox.fourKind, [2, 2, 2, 2, 6]), 14);
      expect(score(DiceBox.fourKind, [2, 2, 2, 5, 6]), 0);
    });

    test('full house 25: three of one face, two of another; five of a kind is none', () {
      expect(score(DiceBox.fullHouse, [3, 3, 5, 5, 5]), 25);
      expect(score(DiceBox.fullHouse, [3, 3, 5, 5, 6]), 0);
      expect(score(DiceBox.fullHouse, [5, 5, 5, 5, 5]), 0);
      expect(score(DiceBox.fullHouse, [5, 5, 5, 5, 2]), 0);
    });

    test('straights: four in a row 30, five in a row 40', () {
      expect(score(DiceBox.smallStraight, [1, 2, 3, 4, 6]), 30);
      expect(score(DiceBox.smallStraight, [3, 4, 5, 6, 6]), 30);
      expect(score(DiceBox.smallStraight, [2, 3, 4, 5, 2]), 30);
      expect(score(DiceBox.smallStraight, [1, 2, 3, 5, 6]), 0);
      expect(score(DiceBox.smallStraight, [1, 2, 3, 4, 5]), 30);
      expect(score(DiceBox.largeStraight, [5, 4, 3, 2, 1]), 40);
      expect(score(DiceBox.largeStraight, [2, 3, 4, 5, 6]), 40);
      expect(score(DiceBox.largeStraight, [1, 2, 3, 4, 6]), 0);
    });

    test('five of a kind 50, chance the sum', () {
      expect(score(DiceBox.fiveKind, [2, 2, 2, 2, 2]), 50);
      expect(score(DiceBox.fiveKind, [2, 2, 2, 2, 3]), 0);
      expect(score(DiceBox.chance, [1, 2, 3, 4, 6]), 16);
    });

    test('box ids round-trip', () {
      for (final b in DiceBox.values) {
        expect(DiceBox.byId(b.id), b);
      }
      expect(DiceBox.byId('yahoo'), isNull);
      expect(DiceBox.upperBoxes.length + DiceBox.lowerBoxes.length, 13);
    });
  });

  group('rolls', () {
    test('first roll rolls all five; keep only from the second roll; three at most', () {
      final g = DiceSheetGame(seed: 1);
      expect(g.canRoll, isTrue);
      expect(g.canScore, isFalse);
      expect(g.applyMove(DiceSheetGame.scoreMove(DiceBox.chance)), isNull, reason: 'no roll yet');
      expect(g.applyMove(DiceSheetGame.rollMove([0])), isNull, reason: 'nothing to keep yet');
      expect(g.applyMove(DiceSheetGame.rollMove()), isNotNull);
      expect(g.dice, hasLength(5));
      expect(g.rollsLeft, 2);
      final first = g.dice;
      expect(g.applyMove(DiceSheetGame.rollMove([0, 1, 2, 3, 4])), isNull, reason: 'nothing left to roll');
      expect(g.applyMove({'action': 'roll', 'keep': [5]}), isNull);
      expect(g.applyMove({'action': 'roll', 'keep': [1, 1]}), isNull);
      expect(g.applyMove({'action': 'roll', 'keep': ['1']}), isNull);
      expect(g.applyMove({'action': 'roll', 'keep': 1}), isNull);
      expect(g.applyMove({'action': 'roll', 'keep': [], 'x': 1}), isNull);
      expect(g.applyMove(DiceSheetGame.rollMove([0, 2])), isNotNull);
      expect(g.dice[0], first[0]);
      expect(g.dice[2], first[2]);
      expect(g.applyMove(DiceSheetGame.rollMove([1])), isNotNull);
      expect(g.rollsLeft, 0);
      expect(g.applyMove(DiceSheetGame.rollMove([1])), isNull, reason: 'three rolls used');
      expect(g.legalMoves.every((m) => m['action'] == 'score'), isTrue);
      expect(g.currentSeat, 0);
    });

    test('the draws do not depend on what was kept (no fishing after an undo)', () {
      final a = DiceSheetGame(seed: 9)..applyMove(DiceSheetGame.rollMove());
      final b = DiceSheetGame(seed: 9)..applyMove(DiceSheetGame.rollMove());
      a.applyMove(DiceSheetGame.rollMove([0, 1]));
      b.applyMove(DiceSheetGame.rollMove([3]));
      // Positions rolled in both get the same value.
      expect(a.dice[2], b.dice[2]);
      expect(a.dice[4], b.dice[4]);
    });

    test('same seed, same dice; legal moves before the first roll: one roll', () {
      final a = DiceSheetGame(seed: 4), b = DiceSheetGame(seed: 4);
      expect(a.legalMoves, [DiceSheetGame.rollMove()]);
      a.applyMove(DiceSheetGame.rollMove());
      b.applyMove(DiceSheetGame.rollMove());
      expect(a.dice, b.dice);
      expect(a.legalMoves.where((m) => m['action'] == 'roll'), hasLength(31));
      expect(a.legalMoves.where((m) => m['action'] == 'score'), hasLength(13));
    });

    test('a roll is the undo barrier, a scoring is not', () {
      expect(DiceSheetGame.isRoll(DiceSheetGame.rollMove()), isTrue);
      expect(DiceSheetGame.isRoll(DiceSheetGame.scoreMove(DiceBox.ones)), isFalse);
      expect(specById('dicesheet')!.undoBarrier!(DiceSheetGame.rollMove([1])), isTrue);
    });
  });

  group('scoring a box', () {
    test('fills one box, strikes with 0, passes the turn, refuses a filled box', () {
      final g = DiceSheetGame(seed: 2)..debugScriptRolls([
          [1, 2, 3, 4, 6],
          [6, 6, 6, 2, 2],
          [1, 2, 3, 4, 6],
        ]);
      g.applyMove(DiceSheetGame.rollMove());
      expect(g.scoreIfFilled(DiceBox.smallStraight), 30);
      expect(g.scoreIfFilled(DiceBox.fiveKind), 0);
      final e = g.applyMove(DiceSheetGame.scoreMove(DiceBox.fiveKind));
      expect(e!.payload, {'scored': 'fiveKind', 'seat': 0, 'points': 0});
      expect(g.entryOf(0, DiceBox.fiveKind), 0);
      expect(g.currentSeat, 1);
      expect(g.currentPlayer, Player.b);
      expect(g.dice, isEmpty);
      expect(g.rollsUsed, 0);
      g.applyMove(DiceSheetGame.rollMove());
      expect(g.applyMove(DiceSheetGame.scoreMove(DiceBox.fullHouse)), isNotNull);
      expect(g.entryOf(1, DiceBox.fullHouse), 25);
      g.applyMove(DiceSheetGame.rollMove());
      expect(g.applyMove(DiceSheetGame.scoreMove(DiceBox.fiveKind)), isNull, reason: 'already filled');
      expect(g.applyMove({'action': 'score', 'box': 'nope'}), isNull);
      expect(g.applyMove({'action': 'score', 'box': 'chance', 'x': 1}), isNull);
      expect(g.allowedBoxes, isNot(contains(DiceBox.fiveKind)));
      expect(g.scoreIfFilled(DiceBox.fiveKind), isNull);
    });

    test('the upper bonus: 35 at 63 or more', () {
      final g = DiceSheetGame(seed: 3);
      // Seat 0 scores three of each face in the upper boxes (= 63).
      for (var face = 1; face <= 6; face++) {
        g.debugScriptRolls([
          [face, face, face, face == 1 ? 2 : 1, face == 1 ? 2 : 1],
          [1, 2, 3, 4, 6],
        ]);
        g.applyMove(DiceSheetGame.rollMove());
        g.applyMove(DiceSheetGame.scoreMove(DiceBox.upperFor(face)));
        g.applyMove(DiceSheetGame.rollMove());
        g.applyMove(DiceSheetGame.scoreMove(DiceBox.upperFor(face)));
        expect(g.upperBonusOf(0), face == 6 ? 35 : 0);
      }
      expect(g.upperSumOf(0), 63);
      expect(g.totalOf(0), 98);
      expect(g.upperSumOf(1), 1 + 2 + 3 + 4 + 0 + 6, reason: 'seat 1 has its own sheet');
      expect(g.upperBonusOf(1), 0);
    });

    test('a full game for 2 seats: 13 rounds, totals, a winner or a shared win', () {
      for (var seed = 0; seed < 20; seed++) {
        final g = DiceSheetGame(seed: seed);
        final moves = botGame(g, seed);
        expect(g.isOver, isTrue);
        for (final s in [0, 1]) {
          expect(g.sheetFull(s), isTrue);
          expect(g.totalOf(s),
              g.upperSumOf(s) + g.upperBonusOf(s) + g.lowerSumOf(s));
        }
        final r = g.result;
        expect(r.code, GameEndReason.dicesheetAllFilled);
        expect(r.params, {'a': g.totalOf(0), 'b': g.totalOf(1)});
        expect(r.reason, contains('all sheets full'));
        final sr = g.seatResult;
        expect(sr.isOver, isTrue);
        expect(sr.code, 'dicesheet.allFilled');
        if (g.totalOf(0) == g.totalOf(1)) {
          expect(r.draw, isTrue);
          expect(sr.places, [1, 1]);
        } else {
          expect(r.winner, g.totalOf(0) > g.totalOf(1) ? Player.a : Player.b);
          expect(sr.winner, r.winner!.index);
        }
        expect(g.legalMoves, isEmpty);
        expect(g.applyMove(DiceSheetGame.rollMove()), isNull);
        // Replay gives the same state.
        final again = replay(GameConfig('dicesheet', seed: seed), moves)! as DiceSheetGame;
        expect(again.toJson(), g.toJson());
        expect(moves.where((m) => m['action'] == 'score'), hasLength(26));
      }
    });

    test('the bot scores reasonably (a sanity check for demos)', () {
      final totals = <int>[];
      for (var seed = 0; seed < 30; seed++) {
        final g = DiceSheetGame(seed: seed);
        botGame(g, seed);
        totals.addAll(g.totals);
      }
      final avg = totals.reduce((a, b) => a + b) / totals.length;
      expect(avg, greaterThan(130));
    });
  });

  group('seats', () {
    test('3 and 4 seats: turn order, currentPlayer throws for seat 2+, ranking with ties', () {
      for (final n in [3, 4]) {
        for (var seed = 0; seed < 10; seed++) {
          final g = DiceSheetGame(seed: seed, playerCount: n);
          botGame(g, seed);
          expect(g.isOver, isTrue);
          for (var s = 0; s < n; s++) {
            expect(g.sheetFull(s), isTrue);
          }
          final sr = g.seatResult;
          expect(sr.places, SeatResult.placesFor(g.totals));
          expect(sr.params['score${n - 1}'], g.totalOf(n - 1));
          expect(g.actorSeat, isNull);
        }
      }
      final g = DiceSheetGame(playerCount: 3);
      final seen = <int>[];
      for (var i = 0; i < 4; i++) {
        seen.add(g.actorSeat!);
        g.applyMove(DiceSheetGame.rollMove());
        g.applyMove(DiceSheetGame.scoreMove(g.allowedBoxes.first));
      }
      expect(seen, [0, 1, 2, 0]);
      final h = DiceSheetGame(playerCount: 3)
        ..applyMove(DiceSheetGame.rollMove())
        ..applyMove(DiceSheetGame.scoreMove(DiceBox.chance))
        ..applyMove(DiceSheetGame.rollMove())
        ..applyMove(DiceSheetGame.scoreMove(DiceBox.chance));
      expect(h.currentSeat, 2);
      expect(() => h.currentPlayer, throwsStateError);
      expect(h.seatOfMove(DiceSheetGame.rollMove()), 2);
    });

    test('a winner in seat 2+: playResult only says over (draw), seatResult names it', () {
      for (var seed = 0; seed < 40; seed++) {
        final g = DiceSheetGame(seed: seed, playerCount: 3);
        botGame(g, seed);
        final w = g.seatResult.winners;
        if (w.length == 1 && w.single == 2) {
          expect(g.result.draw, isTrue);
          expect(g.result.winner, isNull);
          expect(g.seatResult.ranking.first, 2);
          return;
        }
      }
      fail('no seed with seat 2 winning');
    });

    test('resign with 3–4 seats: the seat leaves, the others play on, last one in wins', () {
      final g = DiceSheetGame(seed: 5, playerCount: 4);
      g.applyMove(DiceSheetGame.rollMove());
      expect(g.applyMove({'action': 'resign', 'player': 'a'}), isNull, reason: 'seats name a seat');
      expect(g.applyMove(DiceSheetGame.resignSeatMove(4)), isNull);
      expect(g.seatOfMove(DiceSheetGame.resignSeatMove(2)), 2);
      // Seat 2 (not to move) leaves: seat 0 keeps its dice.
      final dice = g.dice;
      expect(g.applyMove(DiceSheetGame.resignSeatMove(2)), isNotNull);
      expect(g.applyMove(DiceSheetGame.resignSeatMove(2)), isNull, reason: 'already out');
      expect(g.isSeatOut(2), isTrue);
      expect(g.dice, dice);
      g.applyMove(DiceSheetGame.scoreMove(DiceBox.chance));
      expect(g.currentSeat, 1);
      // Seat 1 leaves on its own turn after rolling: the dice go, seat 3 is next.
      g.applyMove(DiceSheetGame.rollMove());
      g.applyMove(DiceSheetGame.resignSeatMove(1));
      expect(g.currentSeat, 3);
      expect(g.rollsUsed, 0);
      expect(g.isOver, isFalse);
      g.applyMove(DiceSheetGame.resignSeatMove(0));
      expect(g.isOver, isTrue);
      final sr = g.seatResult;
      expect(sr.code, 'common.resigned');
      expect(sr.winners, [3]);
      expect(sr.places, [2, 3, 4, 1]);
      expect(sr.params['seat'], 0);
      expect(g.result.code, GameEndReason.commonResigned);
      expect(g.legalMoves, isEmpty);
    });

    test('a seat that leaves in the last round can end the game by full sheets', () {
      final g = DiceSheetGame(seed: 6, playerCount: 3);
      botGame(g, 6, after: (g) => !(g.currentSeat == 2 && g.roundOf(2) == 13));
      expect(g.isOver, isFalse);
      expect(g.applyMove(DiceSheetGame.resignSeatMove(2)), isNotNull);
      expect(g.isOver, isTrue);
      expect(g.result.code, GameEndReason.dicesheetAllFilled);
      expect(g.seatResult.places[2], 3, reason: 'the seat that left is last');
    });

    test('two seats: the common resign ends the game', () {
      final g = DiceSheetGame(seed: 1)..applyMove(DiceSheetGame.rollMove());
      expect(g.applyMove(DiceSheetGame.resignSeatMove(1)), isNull);
      expect(g.applyMove(Game.resignMove(Player.b)), isNotNull);
      expect(g.result.winner, Player.a);
      expect(g.seatResult.places, [1, 2]);
      expect(g.seatResult.code, 'common.resigned');
    });

    test('2 to 4 seats only', () {
      expect(() => DiceSheetGame(playerCount: 1), throwsArgumentError);
      expect(() => DiceSheetGame(playerCount: 5), throwsArgumentError);
      expect(configProblem(const GameConfig('dicesheet', players: 4)), isNull);
      expect(configProblem(const GameConfig('dicesheet', players: 5)), contains('2–4'));
      expect((createGame(const GameConfig('dicesheet', players: 4)) as DiceSheetGame).playerCount, 4);
    });
  });

  group('house rule: extra fives', () {
    DiceSheetGame withFiveKind(int filled, {required bool extra}) {
      // Seat 0 fills five of a kind with [filled] (50 or 0), seat 1 chance.
      final g = DiceSheetGame(seed: 1, extraFives: extra)
        ..debugScriptRolls([
          filled == 50 ? [4, 4, 4, 4, 4] : [1, 2, 3, 4, 6],
          [1, 1, 2, 2, 3],
        ]);
      g
        ..applyMove(DiceSheetGame.rollMove())
        ..applyMove(DiceSheetGame.scoreMove(DiceBox.fiveKind))
        ..applyMove(DiceSheetGame.rollMove())
        ..applyMove(DiceSheetGame.scoreMove(DiceBox.chance));
      expect(g.entryOf(0, DiceBox.fiveKind), filled);
      return g;
    }

    test('off: another five of a kind is just its dice (no full house, no bonus)', () {
      final g = withFiveKind(50, extra: false)..debugScriptRolls([[3, 3, 3, 3, 3]]);
      g.applyMove(DiceSheetGame.rollMove());
      expect(g.isJoker, isFalse);
      expect(g.allowedBoxes, hasLength(12));
      expect(g.scoreIfFilled(DiceBox.fullHouse), 0);
      g.applyMove(DiceSheetGame.scoreMove(DiceBox.threeKind));
      expect(g.extraBonusOf(0), 0);
    });

    test('on, with 50: +100 and the upper box of the face first', () {
      final g = withFiveKind(50, extra: true)..debugScriptRolls([[3, 3, 3, 3, 3]]);
      g.applyMove(DiceSheetGame.rollMove());
      expect(g.isJoker, isTrue);
      expect(g.earnsExtraBonus, isTrue);
      expect(g.allowedBoxes, [DiceBox.threes]);
      expect(g.applyMove(DiceSheetGame.scoreMove(DiceBox.fullHouse)), isNull);
      final e = g.applyMove(DiceSheetGame.scoreMove(DiceBox.threes));
      expect((e!.payload as Map)['bonus'], 100);
      expect(g.entryOf(0, DiceBox.threes), 15);
      expect(g.extraBonusOf(0), 100);
      expect(g.totalOf(0), 50 + 15 + 100);
    });

    test('on: upper box taken → any lower box at full value; all lower taken → an upper box with 0', () {
      final g = withFiveKind(50, extra: true);
      // Seat 0 fills the twos; seat 1 always chance-like boxes.
      g.debugScriptRolls([
        [2, 2, 1, 1, 1],
        [1, 2, 3, 4, 6],
        [2, 2, 2, 2, 2],
      ]);
      g
        ..applyMove(DiceSheetGame.rollMove())
        ..applyMove(DiceSheetGame.scoreMove(DiceBox.twos))
        ..applyMove(DiceSheetGame.rollMove())
        ..applyMove(DiceSheetGame.scoreMove(DiceBox.ones))
        ..applyMove(DiceSheetGame.rollMove());
      expect(g.allowedBoxes.toSet(), {
        DiceBox.threeKind,
        DiceBox.fourKind,
        DiceBox.fullHouse,
        DiceBox.smallStraight,
        DiceBox.largeStraight,
        DiceBox.chance,
      });
      expect(g.scoreIfFilled(DiceBox.fullHouse), 25);
      expect(g.scoreIfFilled(DiceBox.smallStraight), 30);
      expect(g.scoreIfFilled(DiceBox.largeStraight), 40);
      expect(g.scoreIfFilled(DiceBox.fourKind), 10);
      g.applyMove(DiceSheetGame.scoreMove(DiceBox.largeStraight));
      expect(g.entryOf(0, DiceBox.largeStraight), 40);
      expect(g.extraBonusOf(0), 100);
    });

    test('on: upper box and every lower box taken → any upper box, with 0', () {
      final g = withFiveKind(50, extra: true);
      for (final box in [...DiceBox.lowerBoxes.where((b) => b != DiceBox.fiveKind), DiceBox.fives]) {
        g.debugScriptRolls([
          [1, 2, 3, 4, 6],
          [1, 2, 3, 4, 6],
        ]);
        g.applyMove(DiceSheetGame.rollMove());
        expect(g.applyMove(DiceSheetGame.scoreMove(box)), isNotNull, reason: '$box');
        g.applyMove(DiceSheetGame.rollMove());
        g.applyMove(DiceSheetGame.scoreMove(g.allowedBoxes.first));
      }
      g.debugScriptRolls([[5, 5, 5, 5, 5]]);
      g.applyMove(DiceSheetGame.rollMove());
      expect(g.allowedBoxes, [DiceBox.ones, DiceBox.twos, DiceBox.threes, DiceBox.fours, DiceBox.sixes]);
      expect(g.scoreIfFilled(DiceBox.ones), 0);
      g.applyMove(DiceSheetGame.scoreMove(DiceBox.ones));
      expect(g.extraBonusOf(0), 100);
    });

    test('on, five of a kind struck with 0: joker rule without the bonus', () {
      final g = withFiveKind(0, extra: true)..debugScriptRolls([[6, 6, 6, 6, 6]]);
      g.applyMove(DiceSheetGame.rollMove());
      expect(g.isJoker, isTrue);
      expect(g.earnsExtraBonus, isFalse);
      expect(g.allowedBoxes, [DiceBox.sixes]);
      g.applyMove(DiceSheetGame.scoreMove(DiceBox.sixes));
      expect(g.extraBonusOf(0), 0);
    });

    test('in the config only when on', () {
      const on = GameConfig('dicesheet', seed: 3, extraFives: true, players: 3);
      expect(on.toJson(), {'game': 'dicesheet', 'seed': 3, 'players': 3, 'extraFives': true});
      expect(GameConfig.fromJson(on.toJson()), on);
      expect(const GameConfig('dicesheet').toJson(), {'game': 'dicesheet', 'seed': 0});
      expect((createGame(on) as DiceSheetGame).extraFives, isTrue);
      expect(on.copyWith(seed: 4).extraFives, isTrue);
    });
  });

  group('debug console', () {
    test('parse / format round-trip and a full auto game', () {
      final t = DiceSheetText();
      expect(t.parse('roll'), {'action': 'roll', 'keep': []});
      expect(t.parse('roll 1 3 5'), {'action': 'roll', 'keep': [0, 2, 4]});
      expect(t.parse('fh'), DiceSheetGame.scoreMove(DiceBox.fullHouse));
      expect(t.parse('score 6s'), DiceSheetGame.scoreMove(DiceBox.sixes));
      expect(t.parse('score fullHouse'.toLowerCase()), DiceSheetGame.scoreMove(DiceBox.fullHouse));
      expect(t.parse('nonsense'), isNull);
      for (final m in [DiceSheetGame.rollMove([0, 4]), DiceSheetGame.scoreMove(DiceBox.chance)]) {
        expect(t.parse(t.format(m)), m);
      }
      final c = DebugConsole('dicesheet', 3);
      expect(c.screen, contains('Ausgewürfelt'));
      final out = c.handle('auto');
      expect(c.current.game.isOver, isTrue);
      expect(out, contains('total'));
      expect(c.handle('new'), contains('roll the dice'));
      expect(c.handle('roll'), contains('Anna rolls'));
    });
  });
}
