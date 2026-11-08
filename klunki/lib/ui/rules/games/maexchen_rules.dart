import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../games/maexchen/maexchen_dice.dart';
import '../rules_model.dart';

/// Mäxchen (KLD-123): the value order with dice pictures; lives and
/// "Mäxchen doppelt" ([GameConfig.lives], [GameConfig.maexchenDouble],
/// chosen before the game).
GameRules maexchenRules(BuildContext context, AppLocalizations l10n, GameConfig config) => GameRules(
      goal: ruleLines(l10n.rulesMaexchenGoal),
      turn: [
        ...ruleLines(l10n.rulesMaexchenTurn),
        RuleItem.heading(l10n.rulesMaexchenOrderTitle),
        const RuleItem.widget(_Order(), key: Key('rules-maexchen-order')),
        ...ruleLines(l10n.rulesMaexchenOrder),
      ],
      special: ruleLines(l10n.rulesMaexchenSpecial),
      houseRules: [
        HouseRule(
          id: 'lives',
          title: l10n.maexchenOptionLives,
          text: l10n.rulesMaexchenLives(config.lives),
          on: true,
          lead: const Icon(Icons.favorite, size: 26, color: Color(0xFFD32F2F)),
        ),
        HouseRule(
          id: 'double',
          title: l10n.maexchenOptionDouble,
          text: l10n.maexchenOptionDoubleExplain,
          on: config.maexchenDouble,
          lead: const ValueDice(value: MaexchenGame.maexchen, size: 18),
        ),
      ],
      choosable: true,
    );

/// Low to high: 31 < 65 < 11 < 66 < 21, left to right in every language.
class _Order extends StatelessWidget {
  const _Order();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget lt() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('<', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: muted)),
        );
    return ExcludeSemantics(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              for (final (i, v) in const [31, 65, 11, 66, MaexchenGame.maexchen].indexed) ...[
                if (i > 0) lt(),
                ValueDice(value: v, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
