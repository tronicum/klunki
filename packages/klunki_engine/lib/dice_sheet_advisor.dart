import 'dart:math';

import 'dice_sheet.dart';

/// Why [DiceSheetAdvisor] recommends a box; the app turns it into one short
/// sentence a child understands.
enum DiceTipReason {
  /// An upper box with at least three of its face: on the way to the bonus.
  bonus,

  /// Three or four of a kind, or chance: every die counts.
  allDice,

  /// Full house, a straight or five of a kind: fixed points.
  fixed,

  /// Plain points (e.g. an upper box once the bonus is decided).
  points,

  /// Nothing fits well: this box loses the least (it still gets points).
  leastLoss,

  /// Nothing fits: strike this box (0), it is worth the least later.
  strike,
}

/// The advice for the current roll: the box to fill ([box], [points],
/// [reason]); maybe a box that would give more now but is worth more later
/// ([richer], [richerPoints]); and while rolls are left which dice to keep
/// ([keep], positions 0–4; all five = stop rolling, empty = roll all again).
class DiceSheetAdvice {
  final DiceBox box;
  final int points;
  final DiceTipReason reason;
  final DiceBox? richer;
  final int? richerPoints;
  final List<int>? keep;

  const DiceSheetAdvice(
      {required this.box, required this.points, required this.reason, this.richer, this.richerPoints, this.keep});

  /// The dice are good enough: score now instead of rolling again.
  bool get stop => keep != null && keep!.length == DiceSheetGame.diceCount;

  @override
  String toString() => 'DiceSheetAdvice($box $points ${reason.name}'
      '${richer == null ? '' : ', richer $richer $richerPoints'}${keep == null ? '' : ', keep $keep'})';
}

/// The "Anfängermodus" of Ausgewürfelt (KLD-119): a simple, explainable
/// heuristic, no search. Deterministic and pure.
///
/// **Which box.** Every allowed box gets `points now − what the box is
/// usually worth later` ([parOf]): the averages of good play (ones 1.9 …
/// sixes 19.2, three of a kind 21.7, four of a kind 13.1, full house 22.6,
/// small straight 29.5, large straight 32.7, five of a kind 16.9, chance
/// 22). The hard boxes (four of a kind, full house, straights, five of a
/// kind) are worth less the fewer turns are left, by the chance to still
/// roll them ([_perTurn]). While the upper bonus is open and reachable, an
/// upper box also gets `points − 3 × face` (three of a face is the bonus
/// par: above it helps, below it hurts). The highest value wins; on a tie the
/// first box of the sheet.
///
/// **Which dice to keep** (rolls left): stop with a made full house, large
/// straight, five of a kind (or small straight when the large one is filled)
/// whose box is open; else a run of four (or three without a pair) toward an
/// open straight; else two pairs toward an open full house; else the most
/// common face (the higher on a tie) when it shows twice or more and an
/// upper or "of a kind" box can use it; else roll all again.
class DiceSheetAdvisor {
  DiceSheetAdvisor._();

  /// The advice for the seat to move in [game], or null when it cannot
  /// fill a box now (before the first roll, game over).
  static DiceSheetAdvice? forGame(DiceSheetGame game) {
    if (!game.canScore) return null;
    final seat = game.currentSeat;
    return advise(
      dice: game.dice,
      options: {for (final b in game.allowedBoxes) b: game.scoreIfFilled(b)!},
      open: {for (final b in DiceBox.values) if (!game.isFilled(seat, b)) b},
      upperSum: game.upperSumOf(seat),
      rollsLeft: game.rollsLeft,
    );
  }

  /// The advice for [dice] when the player may fill the boxes of [options]
  /// (box → points) and has [open] boxes empty in all (default: the
  /// options), [upperSum] in the upper section and [rollsLeft] rolls left.
  static DiceSheetAdvice advise({
    required List<int> dice,
    required Map<DiceBox, int> options,
    Set<DiceBox>? open,
    int upperSum = 0,
    int rollsLeft = 0,
  }) {
    if (options.isEmpty) throw ArgumentError.value(options, 'options', 'no box to fill');
    final empty = open ?? options.keys.toSet();
    final future = max(0, empty.length - 1);
    final bonusOpen = _bonusOpen(upperSum, empty);
    double value(DiceBox b) => valueOf(b, options[b]!, future: future, bonusOpen: bonusOpen);

    DiceBox? best;
    var bestValue = double.negativeInfinity;
    for (final b in DiceBox.values) {
      if (!options.containsKey(b)) continue;
      final v = value(b);
      if (v > bestValue + 1e-9) {
        best = b;
        bestValue = v;
      }
    }
    final box = best!;
    final points = options[box]!;

    final DiceTipReason reason;
    if (points == 0) {
      reason = DiceTipReason.strike;
    } else if (bestValue < -2) {
      reason = DiceTipReason.leastLoss;
    } else if (box.upper) {
      reason = bonusOpen && points >= 3 * box.face ? DiceTipReason.bonus : DiceTipReason.points;
    } else {
      reason = switch (box) {
        DiceBox.threeKind || DiceBox.fourKind || DiceBox.chance => DiceTipReason.allDice,
        _ => DiceTipReason.fixed,
      };
    }

    // A box that would give more points right now (the first one of the
    // sheet with the most): the reason for "fewer points now, but smarter".
    DiceBox? richer;
    for (final b in DiceBox.values) {
      final p = options[b];
      if (p == null || p <= points) continue;
      if (richer == null || p > options[richer]!) richer = b;
    }

    return DiceSheetAdvice(
      box: box,
      points: points,
      reason: reason,
      richer: richer,
      richerPoints: richer == null ? null : options[richer],
      keep: rollsLeft > 0 ? _keep(dice, options, empty, box) : null,
    );
  }

  /// The heuristic value of filling [box] with [points] when [future]
  /// turns are left after this one and the upper bonus is still open
  /// ([bonusOpen]).
  static double valueOf(DiceBox box, int points, {required int future, required bool bonusOpen}) {
    var v = points - parOf(box, future);
    if (box.upper && bonusOpen) v += points - 3 * box.face;
    return v;
  }

  /// What [box] is usually worth when kept for later, with [future] turns
  /// left to fill it.
  static double parOf(DiceBox box, int future) {
    final full = _par[box]!;
    final q = _perTurn[box];
    if (q == null) return future == 0 ? 0 : full;
    // The chance to still roll it in [future] turns, relative to a whole
    // game (12 turns after this one).
    double reach(int n) => 1 - pow(1 - q, n).toDouble();
    return full * min(1.0, reach(future) / reach(12));
  }

  static const Map<DiceBox, double> _par = {
    DiceBox.ones: 1.9,
    DiceBox.twos: 5.3,
    DiceBox.threes: 8.6,
    DiceBox.fours: 12.2,
    DiceBox.fives: 15.7,
    DiceBox.sixes: 19.2,
    DiceBox.threeKind: 21.7,
    DiceBox.fourKind: 13.1,
    DiceBox.fullHouse: 22.6,
    DiceBox.smallStraight: 29.5,
    DiceBox.largeStraight: 32.7,
    DiceBox.fiveKind: 16.9,
    DiceBox.chance: 22.0,
  };

  /// About how likely a turn that goes for the box rolls it (the hard
  /// boxes only).
  static const Map<DiceBox, double> _perTurn = {
    DiceBox.fourKind: 0.3,
    DiceBox.fullHouse: 0.37,
    DiceBox.smallStraight: 0.6,
    DiceBox.largeStraight: 0.26,
    DiceBox.fiveKind: 0.046,
  };

  /// The upper bonus is still undecided and reachable with the open upper
  /// boxes (five of each face at best).
  static bool _bonusOpen(int upperSum, Set<DiceBox> open) {
    if (upperSum >= DiceSheetGame.upperBonusAt) return false;
    final most = open.where((b) => b.upper).fold(0, (a, b) => a + 5 * b.face);
    return upperSum + most >= DiceSheetGame.upperBonusAt;
  }

  static List<int> _keep(List<int> dice, Map<DiceBox, int> options, Set<DiceBox> open, DiceBox best) {
    final all = [for (var i = 0; i < dice.length; i++) i];
    final counts = List.filled(7, 0);
    for (final d in dice) {
      counts[d]++;
    }
    final most = counts.reduce(max);
    // A made big box: stop.
    for (final b in [DiceBox.fiveKind, DiceBox.largeStraight, DiceBox.fullHouse]) {
      if ((options[b] ?? 0) > 0) return all;
    }
    if ((options[DiceBox.smallStraight] ?? 0) > 0 && !open.contains(DiceBox.largeStraight)) return all;
    if (most == 5 && best.upper && (options[best] ?? 0) > 0) return all; // e.g. a joker
    // Toward a straight: the longest run of different faces.
    final straights = open.contains(DiceBox.smallStraight) || open.contains(DiceBox.largeStraight);
    if (straights) {
      var run = <int>[];
      var cur = <int>[];
      for (var f = 1; f <= 6; f++) {
        if (counts[f] > 0) {
          cur = [...cur, f];
          if (cur.length > run.length) run = cur;
        } else {
          cur = [];
        }
      }
      if (run.length >= 4 || (run.length == 3 && most == 1 && open.contains(DiceBox.smallStraight))) {
        return _positions(dice, run);
      }
    }
    // Toward a full house: two pairs.
    final pairs = [for (var f = 6; f >= 1; f--) if (counts[f] == 2) f];
    if (open.contains(DiceBox.fullHouse) && pairs.length == 2) {
      return [for (var i = 0; i < dice.length; i++) if (pairs.contains(dice[i])) i];
    }
    // The most common useful face (the higher on a tie).
    final ofAKind = open.any((b) => b == DiceBox.threeKind || b == DiceBox.fourKind || b == DiceBox.fiveKind);
    for (var f = 6; f >= 1; f--) {
      if (counts[f] == most && most >= 2 && (ofAKind || open.contains(DiceBox.upperFor(f)))) {
        return [for (var i = 0; i < dice.length; i++) if (dice[i] == f) i];
      }
    }
    if (most >= 2) {
      // The highest pair whose upper box is still open.
      for (var f = 6; f >= 1; f--) {
        if (counts[f] >= 2 && open.contains(DiceBox.upperFor(f))) {
          return [for (var i = 0; i < dice.length; i++) if (dice[i] == f) i];
        }
      }
    }
    return const [];
  }

  /// One position per face of [faces] (the first die showing it).
  static List<int> _positions(List<int> dice, List<int> faces) {
    final out = <int>[];
    for (final f in faces) {
      out.add(dice.indexOf(f));
    }
    return out..sort();
  }
}
