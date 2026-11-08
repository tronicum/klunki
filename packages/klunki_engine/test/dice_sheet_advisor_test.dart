import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-119 Anfängermodus: the box and keep advice of [DiceSheetAdvisor].
void main() {
  /// The options of [dice] with the boxes [open] (default all) empty.
  DiceSheetAdvice advise(List<int> dice, {Iterable<DiceBox>? open, int upperSum = 0, int rollsLeft = 0}) {
    final o = (open ?? DiceBox.values).toSet();
    return DiceSheetAdvisor.advise(
      dice: dice,
      options: {for (final b in o) b: DiceSheetGame.scoreFor(b, dice)},
      open: o,
      upperSum: upperSum,
      rollsLeft: rollsLeft,
    );
  }

  Iterable<DiceBox> without(List<DiceBox> filled) => DiceBox.values.where((b) => !filled.contains(b));

  group('which box', () {
    // (what, dice, open boxes, upper sum, box, points, reason, richer box)
    final cases = <(String, List<int>, Iterable<DiceBox>?, int, DiceBox, int, DiceTipReason, DiceBox?)>[
      ('three fives early: Fünfer for the bonus, though Dreierpasch gives more', [5, 5, 5, 2, 3], null, 0,
          DiceBox.fives, 15, DiceTipReason.bonus, DiceBox.threeKind),
      ('four threes: Dreier, above the bonus par', [3, 3, 3, 3, 1], null, 0, DiceBox.threes, 12, DiceTipReason.bonus,
          DiceBox.threeKind),
      ('full house', [3, 3, 3, 5, 5], null, 0, DiceBox.fullHouse, 25, DiceTipReason.fixed, null),
      ('large straight', [2, 3, 4, 5, 6], null, 0, DiceBox.largeStraight, 40, DiceTipReason.fixed, null),
      ('small straight', [1, 2, 3, 4, 6], null, 0, DiceBox.smallStraight, 30, DiceTipReason.fixed, null),
      ('five of a kind', [6, 6, 6, 6, 6], null, 0, DiceBox.fiveKind, 50, DiceTipReason.fixed, null),
      ('high three of a kind: every die counts', [6, 6, 6, 5, 4], null, 0, DiceBox.threeKind, 27,
          DiceTipReason.allDice, null),
      ('junk early: one in Einser loses the least, save the chance', [1, 2, 4, 5, 6], null, 0, DiceBox.ones, 1,
          DiceTipReason.leastLoss, DiceBox.chance),
      ('junk without a one, chance used: strike Einser', [2, 3, 4, 6, 6], without([DiceBox.chance]), 0, DiceBox.ones,
          0, DiceTipReason.strike, DiceBox.sixes),
      ('junk late: strike five of a kind', [1, 3, 4, 6, 6], [DiceBox.twos, DiceBox.fiveKind, DiceBox.fullHouse], 50,
          DiceBox.fiveKind, 0, DiceTipReason.strike, null),
      ('three fives once the bonus is reached: plain points', [5, 5, 5, 2, 3],
          [DiceBox.fives, DiceBox.threeKind, DiceBox.chance], 63, DiceBox.fives, 15, DiceTipReason.points,
          DiceBox.threeKind),
      ('last box: whatever it gives', [1, 2, 4, 5, 6], [DiceBox.sixes], 30, DiceBox.sixes, 6, DiceTipReason.points,
          null),
    ];
    for (final (what, dice, open, upper, box, points, reason, richer) in cases) {
      test(what, () {
        final a = advise(dice, open: open, upperSum: upper);
        expect((a.box, a.points, a.reason, a.richer), (box, points, reason, richer), reason: '$a');
        expect(a.keep, isNull, reason: 'no keep advice without rolls left');
        if (richer != null) expect(a.richerPoints, greaterThan(a.points));
      });
    }
  });

  group('which dice to keep', () {
    // (what, dice, open boxes, keep)
    final cases = <(String, List<int>, Iterable<DiceBox>?, List<int>)>[
      ('three fives: keep them', [5, 5, 5, 2, 3], null, [0, 1, 2]),
      ('a pair of sixes', [6, 1, 6, 3, 5], without([DiceBox.smallStraight, DiceBox.largeStraight]), [0, 2]),
      ('small straight with the large one open: keep the run', [1, 2, 3, 4, 6], null, [0, 1, 2, 3]),
      ('small straight with the large one filled: stop', [1, 2, 3, 4, 6], without([DiceBox.largeStraight]),
          [0, 1, 2, 3, 4]),
      ('full house: stop', [3, 5, 3, 5, 3], null, [0, 1, 2, 3, 4]),
      ('large straight: stop', [6, 2, 4, 3, 5], null, [0, 1, 2, 3, 4]),
      ('two pairs toward a full house', [2, 5, 2, 5, 1], null, [0, 1, 2, 3]),
      ('three in a row, no pair: toward a straight', [1, 2, 4, 5, 6], null, [2, 3, 4]),
      ('junk with the straights filled: roll all again', [1, 2, 4, 5, 6],
          without([DiceBox.smallStraight, DiceBox.largeStraight]), []),
    ];
    for (final (what, dice, open, keep) in cases) {
      test(what, () {
        final a = advise(dice, open: open, rollsLeft: 2);
        expect(a.keep, keep, reason: '$a');
        expect(a.stop, keep.length == 5);
      });
    }
  });

  test('par: the hard boxes are worth less the fewer turns are left', () {
    expect(DiceSheetAdvisor.parOf(DiceBox.fiveKind, 12), closeTo(16.9, 1e-9));
    expect(DiceSheetAdvisor.parOf(DiceBox.fiveKind, 2), lessThan(4));
    expect(DiceSheetAdvisor.parOf(DiceBox.chance, 2), 22.0);
    expect(DiceSheetAdvisor.parOf(DiceBox.chance, 0), 0);
    expect(DiceSheetAdvisor.parOf(DiceBox.largeStraight, 0), 0);
  });

  group('forGame', () {
    test('null before the first roll; then the advice for the seat to move', () {
      final g = DiceSheetGame(seed: 1)..debugScriptRolls([[5, 5, 5, 2, 3], [5, 5, 5, 2, 3]]);
      expect(DiceSheetAdvisor.forGame(g), isNull);
      g.applyMove(DiceSheetGame.rollMove());
      final a = DiceSheetAdvisor.forGame(g)!;
      expect((a.box, a.points), (DiceBox.fives, 15));
      expect(a.keep, [0, 1, 2]);
      g.applyMove(DiceSheetGame.scoreMove(DiceBox.fives));
      g.applyMove(DiceSheetGame.rollMove());
      // Seat 1 now; the same dice.
      expect(DiceSheetAdvisor.forGame(g)!.box, DiceBox.fives);
    });

    test('joker (extra fives): only the forced boxes', () {
      final g = DiceSheetGame(seed: 1, extraFives: true)
        ..debugScriptRolls([
          [4, 4, 4, 4, 4],
          [1, 2, 3, 5, 6],
          [4, 4, 4, 4, 4],
        ]);
      g
        ..applyMove(DiceSheetGame.rollMove())
        ..applyMove(DiceSheetGame.scoreMove(DiceBox.fiveKind))
        ..applyMove(DiceSheetGame.rollMove())
        ..applyMove(DiceSheetGame.scoreMove(DiceBox.ones))
        ..applyMove(DiceSheetGame.rollMove());
      expect(g.isJoker, isTrue);
      final a = DiceSheetAdvisor.forGame(g)!;
      expect((a.box, a.points, a.stop), (DiceBox.fours, 20, true));
    });

    test('a whole game following the advice: every advised box is allowed', () {
      for (var seed = 0; seed < 20; seed++) {
        final g = DiceSheetGame(seed: seed, playerCount: 3);
        var n = 0;
        while (!g.isOver && n++ < 1000) {
          if (g.rollsUsed == 0) {
            expect(g.applyMove(DiceSheetGame.rollMove()), isNotNull);
            continue;
          }
          final a = DiceSheetAdvisor.forGame(g)!;
          expect(g.allowedBoxes, contains(a.box));
          if (a.keep != null && !a.stop) {
            expect(g.applyMove(DiceSheetGame.rollMove(a.keep!)), isNotNull);
          } else {
            expect(g.applyMove(DiceSheetGame.scoreMove(a.box)), isNotNull);
          }
        }
        expect(g.isOver, isTrue);
      }
    });
  });
}
