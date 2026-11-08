import 'dart:math';

import '../dice_sheet.dart';
import '../game.dart';
import 'text_game.dart';

/// Text adapter for Ausgewürfelt (KLD-119), the five-dice score-sheet game.
/// Commands: `roll` (first roll), `roll 1 3 5` / `keep 1 3 5` (keep the
/// dice at those positions, 1–5, roll the others), `score <box>` or just
/// the box (`fullhouse`, `fh`, `6s`, …).
class DiceSheetText extends TextGame {
  DiceSheetText({DiceSheetGame? game}) : game = game ?? DiceSheetGame();

  @override
  final DiceSheetGame game;

  @override
  String get id => 'dicesheet';
  @override
  String get title => 'Ausgewürfelt';
  @override
  String get moveHelp =>
      'roll | roll <positions to keep, 1-5> (e.g. "roll 1 2 5") | score <box> (${_short.keys.join(', ')})';

  @override
  DiceSheetText restart() =>
      DiceSheetText(game: DiceSheetGame(playerCount: game.playerCount, extraFives: game.extraFives));

  /// Short names for typing and the sheet's first column.
  static const Map<String, DiceBox> _short = {
    '1s': DiceBox.ones,
    '2s': DiceBox.twos,
    '3s': DiceBox.threes,
    '4s': DiceBox.fours,
    '5s': DiceBox.fives,
    '6s': DiceBox.sixes,
    '3k': DiceBox.threeKind,
    '4k': DiceBox.fourKind,
    'fh': DiceBox.fullHouse,
    'ss': DiceBox.smallStraight,
    'ls': DiceBox.largeStraight,
    '5k': DiceBox.fiveKind,
    'ch': DiceBox.chance,
  };

  static String shortOf(DiceBox b) => _short.entries.firstWhere((e) => e.value == b).key;

  String _seatName(int s) => s < 2 ? playerName(Player.values[s]) : DiceSheetGame.seatName(s);

  @override
  String render() {
    final g = game;
    final n = g.playerCount;
    final b = StringBuffer();
    String cell(Object? v) => '${v ?? ''}'.padLeft(7);
    b.writeln('box   ${[for (var s = 0; s < n; s++) cell(_seatName(s).length > 7 ? _seatName(s).substring(0, 7) : _seatName(s))].join()}');
    for (final box in DiceBox.values) {
      b.writeln('${shortOf(box).padRight(6)}${[
        for (var s = 0; s < n; s++)
          cell(g.entryOf(s, box) ??
              (s == g.currentSeat && !g.isOver && g.scoreIfFilled(box) != null ? '(${g.scoreIfFilled(box)})' : '-'))
      ].join()}');
      if (box == DiceBox.sixes) {
        b.writeln('bonus ${[for (var s = 0; s < n; s++) cell('${g.upperSumOf(s)}/63')].join()}');
      }
    }
    if (g.extraFives) b.writeln('extra ${[for (var s = 0; s < n; s++) cell(g.extraBonusOf(s))].join()}');
    b.writeln('total ${[for (var s = 0; s < n; s++) cell(g.totalOf(s))].join()}');
    if (!g.isOver) {
      b.write('Round ${g.round}, ${_seatName(g.currentSeat)}: ');
      b.write(g.rollsUsed == 0
          ? 'roll the dice.'
          : 'dice ${g.dice.join(' ')} (${g.rollsLeft} roll${g.rollsLeft == 1 ? '' : 's'} left)'
              '${g.isJoker ? ', joker!' : ''}');
    }
    return b.toString().trimRight();
  }

  @override
  Map<String, dynamic>? parse(String input) {
    final words = input.trim().toLowerCase().split(RegExp(r'[\s,]+'));
    if (words.first == 'roll' || words.first == 'r' || words.first == 'keep' || words.first == 'k') {
      final keep = <int>[];
      for (final w in words.skip(1)) {
        final p = int.tryParse(w);
        if (p == null) return null;
        keep.add(p - 1);
      }
      return {'action': 'roll', 'keep': keep};
    }
    final name = words.first == 'score' || words.first == 's' ? (words.length == 2 ? words[1] : null) : (words.length == 1 ? words.first : null);
    if (name == null) return null;
    final box = _short[name] ?? DiceBox.values.where((b) => b.id.toLowerCase() == name).firstOrNull;
    return box == null ? null : DiceSheetGame.scoreMove(box);
  }

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  @override
  String format(Map<String, dynamic> move) => switch (move['action']) {
        'roll' => ['roll', for (final k in (move['keep'] as List? ?? const [])) '${(k as int) + 1}'].join(' '),
        'score' => 'score ${shortOf(DiceBox.byId(move['box'])!)}',
        final a => '$a',
      };

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final who = playerName(mover);
    final p = event.payload as Map;
    final s = switch (move['action']) {
      'roll' => '$who rolls ${(p['rolled'] as List).join(' ')}'
          '${(p['kept'] as List).isEmpty ? '' : ' (kept ${(p['kept'] as List).map((k) => k + 1).join(' ')})'}.',
      'score' => '$who writes ${p['points']} into ${move['box']}${p['bonus'] != null ? ' (+${p['bonus']} extra)' : ''}.',
      _ => '$who: $move',
    };
    if (game.isOver) return '$s ${status()}';
    return s;
  }

  @override
  bool isHighlight(GameEvent event) => event.payload is Map && (event.payload as Map).containsKey('scored');

  /// What a box is roughly worth on average, so the bot does not waste a
  /// good box on a poor roll.
  static const Map<DiceBox, int> _par = {
    DiceBox.threeKind: 18,
    DiceBox.fourKind: 10,
    DiceBox.fullHouse: 15,
    DiceBox.smallStraight: 18,
    DiceBox.largeStraight: 16,
    DiceBox.fiveKind: 12,
    DiceBox.chance: 22,
  };

  /// A simple player: goes for the most common face, keeps a run of four,
  /// takes a full house or a straight when it comes, and scores the box
  /// that beats its average the most.
  @override
  Map<String, dynamic> autoMove(Random rng) {
    final g = game;
    if (g.rollsUsed == 0) return DiceSheetGame.rollMove();
    final dice = g.dice;
    final allowed = g.allowedBoxes;
    int value(DiceBox b) => g.scoreIfFilled(b)! - (b.upper ? b.face * 3 : _par[b]!);
    final best = allowed.reduce((x, y) => value(y) > value(x) ? y : x);
    final fixed = [DiceBox.fiveKind, DiceBox.largeStraight, DiceBox.fullHouse];
    for (final b in fixed) {
      if (allowed.contains(b) && g.scoreIfFilled(b)! > 0) return DiceSheetGame.scoreMove(b);
    }
    if (g.rollsLeft > 0) {
      final counts = List.filled(7, 0);
      for (final d in dice) {
        counts[d]++;
      }
      // A run of four with a straight box free: keep the run.
      if (allowed.contains(DiceBox.largeStraight) || allowed.contains(DiceBox.smallStraight)) {
        for (final from in const [3, 2, 1]) {
          if ([for (var f = from; f < from + 4; f++) counts[f] > 0].every((x) => x)) {
            final keep = <int>[];
            for (var f = from; f < from + 4; f++) {
              keep.add(dice.indexOf(f));
            }
            if (allowed.contains(DiceBox.largeStraight) || g.scoreIfFilled(DiceBox.smallStraight) == 0) {
              return DiceSheetGame.rollMove(keep);
            }
          }
        }
      }
      var face = 6;
      for (var f = 6; f >= 1; f--) {
        if (counts[f] > counts[face]) face = f;
      }
      final keep = [for (var i = 0; i < dice.length; i++) if (dice[i] == face) i];
      if (keep.length < DiceSheetGame.diceCount && value(best) < 5) return DiceSheetGame.rollMove(keep);
    }
    return DiceSheetGame.scoreMove(best);
  }
}
