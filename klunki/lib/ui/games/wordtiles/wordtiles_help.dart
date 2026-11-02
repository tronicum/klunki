import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import 'wordtiles_tiles.dart';

/// Opens the short rules sheet ("So geht's", KLD-094 step 5) from the help
/// button in the score bar (`wordtiles-help`).
Future<void> showWordTilesHelp(BuildContext context, WordTilesGame game) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => WordTilesHelpSheet(game: game),
);

/// The rules in short: premium squares legend (2B/3B/2W/3W), bingo bonus,
/// the blank (0 points), swapping, passing, the dictionary check with
/// "Trotzdem zulassen" (or the challenge without it; the mode of this game
/// comes first), the bench and the end. Numbers come from the engine.
///
/// Keys: `wordtiles-help-sheet`, `wordtiles-help-premium-<name>`.
class WordTilesHelpSheet extends StatelessWidget {
  final WordTilesGame game;
  const WordTilesHelpSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = WordTilesColors.of(context);
    final dict = game.check == WordCheck.dictionary;

    Widget item(Widget lead, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 40, child: Center(child: lead)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    Widget icon(IconData i) => Icon(i, size: 26, color: theme.colorScheme.primary);
    Widget premium(Premium p, String text) {
      final bg = c.premium(p);
      return Padding(
        key: Key('wordtiles-help-premium-${p.name}'),
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
              child: Text(
                premiumLabel(l10n, p),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: inkOn(bg)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }

    final dictionary = item(icon(Icons.menu_book_outlined), l10n.wordtilesHelpDictionary);
    final challenge = item(icon(Icons.gavel_outlined), l10n.wordtilesHelpChallenge);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          key: const Key('wordtiles-help-sheet'),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.wordtilesHelp, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.wordtilesHelpGoal, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 14),
              Text(l10n.wordtilesHelpPremium, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              premium(Premium.doubleLetter, l10n.wordtilesHelpDoubleLetter),
              premium(Premium.tripleLetter, l10n.wordtilesHelpTripleLetter),
              premium(Premium.doubleWord, l10n.wordtilesHelpDoubleWord),
              premium(Premium.tripleWord, l10n.wordtilesHelpTripleWord),
              const SizedBox(height: 4),
              Text(
                l10n.wordtilesHelpPremiumOnce,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              item(icon(Icons.auto_awesome), l10n.wordtilesHelpBingo(WordTilesGame.rackSize, WordTilesGame.bingoBonus)),
              item(
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: LetterTile(letter: '', points: 0, blank: true, size: 32),
                ),
                l10n.wordtilesHelpBlank,
              ),
              item(icon(Icons.swap_horiz), l10n.wordtilesHelpSwap(WordTilesGame.rackSize)),
              item(icon(Icons.skip_next_outlined), l10n.wordtilesHelpPass(game.scorelessLimit)),
              if (dict) ...[dictionary, challenge] else ...[challenge, dictionary],
              item(icon(Icons.view_week_outlined), l10n.wordtilesHelpBench),
              item(icon(Icons.flag_outlined), l10n.wordtilesHelpEnd),
            ],
          ),
        ),
      ),
    );
  }
}
