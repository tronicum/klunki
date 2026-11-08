import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../games/connect4/connect4_board.dart';
import '../rules_model.dart';

/// 4 Gewinnt (KLD-123): a small board with four in a diagonal row.
GameRules connect4Rules(BuildContext context, AppLocalizations l10n, GameConfig config) => GameRules(
      goal: [RuleItem(l10n.rulesConnect4Goal, lead: const _Four())],
      turn: ruleLines(l10n.rulesConnect4Turn),
      special: ruleLines(l10n.rulesConnect4Special),
    );

/// 4×4 holes: player 1's four on the diagonal, player 2's discs under it.
class _Four extends StatelessWidget {
  const _Four();

  @override
  Widget build(BuildContext context) {
    const cell = 10.0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: Connect4Colors.of(context).board, borderRadius: BorderRadius.circular(4)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < 4; r++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var c = 0; c < 4; c++)
                    Connect4Cell(owner: c == 3 - r ? Player.a : (r + c > 3 ? Player.b : null), size: cell),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
