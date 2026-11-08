import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../games/gostrategy/gostrategy_pieces.dart';
import '../rules_model.dart';

/// GoStrategy (KLD-123): who beats whom, and a table of every piece with
/// its tile (rank insignia, KLD-058), rank and count taken from the engine
/// ([GoPiece]).
GameRules goStrategyRules(BuildContext context, AppLocalizations l10n, GameConfig config) => GameRules(
      goal: ruleLines(l10n.rulesGoGoal),
      turn: ruleLines(l10n.rulesGoTurn),
      special: [
        RuleItem.heading(l10n.rulesGoFightTitle),
        ...ruleLines(l10n.rulesGoFight),
        RuleItem.heading(l10n.rulesGoPieces),
        const RuleItem.widget(_PieceTable(), key: Key('rules-go-table')),
        ...ruleLines(l10n.rulesGoSpecial),
      ],
    );

/// What a piece can do beyond "higher rank wins" (null: nothing more).
String? _ability(AppLocalizations l10n, GoPiece p) => switch (p) {
      GoPiece.marshal => l10n.rulesGoMarshal,
      GoPiece.scout => l10n.rulesGoScout,
      GoPiece.miner => l10n.rulesGoMiner,
      GoPiece.spy => l10n.rulesGoSpy,
      GoPiece.bomb => l10n.rulesGoBomb,
      GoPiece.flag => l10n.rulesGoFlag,
      _ => null,
    };

class _PieceTable extends StatelessWidget {
  const _PieceTable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      children: [
        for (final p in GoPiece.values)
          Container(
            key: Key('rules-go-${p.name}'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The tile as on the board (KLD-058): the rank insignia, the
                // rank number in its badge.
                SizedBox(
                  width: 48,
                  child: Center(child: GoPieceTile(owner: Player.a, piece: p, size: 44)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: goPieceName(l10n, p), style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (p.rank case final rank?) TextSpan(text: '  ·  ${l10n.rulesGoRank(rank)}'),
                        ]),
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (_ability(l10n, p) case final text?)
                        Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(l10n.rulesGoCount(p.count), style: theme.textTheme.titleSmall),
              ],
            ),
          ),
      ],
    );
  }
}
