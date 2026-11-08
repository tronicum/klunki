import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../games/dicesheet/dicesheet_screen.dart' show diceBoxName;
import '../../games/maexchen/maexchen_dice.dart';
import '../rules_model.dart';

/// Ausgewürfelt (KLD-119, KLD-123): a turn with up to three rolls, every box
/// of the sheet with an example throw whose points come from the engine
/// ([DiceSheetGame.scoreFor]), the upper bonus, and the house rule
/// "Extra-Fünfer" ([GameConfig.extraFives], chosen before the game).
///
/// Keys: `rules-dicesheet-<box>` (one per example row).
GameRules diceSheetRules(BuildContext context, AppLocalizations l10n, GameConfig config) {
  RuleItem box(DiceBox b, String text, List<int> dice) =>
      RuleItem.widget(_BoxExample(name: diceBoxName(l10n, b), text: text, dice: dice, points: DiceSheetGame.scoreFor(b, dice)),
          key: Key('rules-dicesheet-${b.id}'));
  return GameRules(
    goal: ruleLines(l10n.rulesDicesheetGoal),
    turn: [
      ...ruleLines(l10n.rulesDicesheetTurn),
      RuleItem(l10n.rulesDicesheetStart, lead: const Icon(Icons.casino_outlined, size: 26)),
      RuleItem.heading(l10n.rulesDicesheetUpperTitle),
      box(DiceBox.fours, l10n.rulesDicesheetUpper, const [4, 4, 4, 2, 6]),
      RuleItem(l10n.rulesDicesheetBonus(DiceSheetGame.upperBonusAt, DiceSheetGame.upperBonus),
          lead: const Icon(Icons.star_outline, size: 26, color: Color(0xFFD9A441))),
      RuleItem.heading(l10n.rulesDicesheetLowerTitle),
      box(DiceBox.threeKind, l10n.rulesDicesheetThreeKind, const [3, 3, 3, 5, 1]),
      box(DiceBox.fourKind, l10n.rulesDicesheetFourKind, const [6, 6, 6, 6, 2]),
      box(DiceBox.fullHouse, l10n.rulesDicesheetFullHouse(DiceSheetGame.fullHouseScore), const [2, 2, 5, 5, 5]),
      box(DiceBox.smallStraight, l10n.rulesDicesheetSmallStraight(DiceSheetGame.smallStraightScore),
          const [1, 2, 3, 4, 6]),
      box(DiceBox.largeStraight, l10n.rulesDicesheetLargeStraight(DiceSheetGame.largeStraightScore),
          const [2, 3, 4, 5, 6]),
      box(DiceBox.fiveKind, l10n.rulesDicesheetFiveKind(DiceSheetGame.fiveKindScore), const [4, 4, 4, 4, 4]),
      box(DiceBox.chance, l10n.rulesDicesheetChance, const [6, 5, 3, 2, 1]),
    ],
    special: ruleLines(l10n.rulesDicesheetSpecial),
    houseRules: [
      HouseRule(
        id: 'extraFives',
        title: l10n.dicesheetOptionExtraFives,
        text: l10n.rulesDicesheetExtraFives(DiceSheetGame.extraFivesBonus),
        on: config.extraFives,
        lead: const DieFace(value: 5, size: 26),
      ),
    ],
    choosable: true,
  );
}

/// One box of the sheet: its name and rule, then an example throw (five
/// small dice, left to right in every language) and what it scores there.
class _BoxExample extends StatelessWidget {
  final String name;
  final String text;
  final List<int> dice;
  final int points;
  const _BoxExample({required this.name, required this.text, required this.dice, required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text(text, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  for (final (i, d) in dice.indexed) ...[
                    if (i > 0) const SizedBox(width: 4),
                    DieFace(value: d, size: 22),
                  ],
                  const SizedBox(width: 10),
                  Text('= $points', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
