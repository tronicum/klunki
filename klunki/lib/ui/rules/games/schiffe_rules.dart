import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../engine_l10n.dart';
import '../../games/schiffe/schiffe_grid.dart';
import '../rules_model.dart';

/// Schiffe versenken (KLD-123): the three shot results as grid cells, the
/// fleet from the engine ([SchiffeGame.defaultFleet]) as rows of ship cells.
GameRules schiffeRules(BuildContext context, AppLocalizations l10n, GameConfig config) {
  Widget cell(SvLook look) => ExcludeSemantics(
        child: SizedBox.square(dimension: 26, child: SchiffeCellView(look: look, semanticLabel: '')),
      );
  final counts = <int, int>{};
  for (final length in SchiffeGame.defaultFleet) {
    counts[length] = (counts[length] ?? 0) + 1;
  }
  return GameRules(
    goal: ruleLines(l10n.rulesSchiffeGoal),
    turn: [
      ...ruleLines(l10n.rulesSchiffeTurn),
      RuleItem(l10n.rulesSchiffeMiss, lead: cell(SvLook.miss)),
      RuleItem(l10n.rulesSchiffeHit, lead: cell(SvLook.hit)),
      RuleItem(l10n.rulesSchiffeSunk, lead: cell(SvLook.sunk)),
    ],
    special: [
      RuleItem.heading(l10n.rulesSchiffeFleet),
      for (final MapEntry(key: length, value: count) in counts.entries)
        RuleItem.widget(
          _ShipRow(length: length, text: l10n.rulesSchiffeShip(count, localizedShipName(l10n, length), length)),
          key: Key('rules-ship-$length'),
        ),
      ...ruleLines(l10n.rulesSchiffeSpecial),
    ],
  );
}

class _ShipRow extends StatelessWidget {
  final int length;
  final String text;
  const _ShipRow({required this.length, required this.text});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: [
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < length; i++)
                const SizedBox.square(dimension: 18, child: SchiffeCellView(look: SvLook.ship, semanticLabel: '')),
            ],
          ),
        ),
        Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
