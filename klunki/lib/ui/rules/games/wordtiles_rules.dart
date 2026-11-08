import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../games/wordtiles/wordtiles_tiles.dart';
import '../rules_model.dart';

/// Wortgewandt (KLD-123; was the "So geht's" sheet of KLD-094 step 5): the
/// premium squares, bingo, the blank, swapping, passing, the word check of
/// this game first (dictionary with "Trotzdem zulassen", or the challenge),
/// the end with the rack deduction. House rules: "Wörterbuch prüfen" and
/// "Joker tauschen" (KLD-094 step 9). Numbers come from the engine.
///
/// Keys: `wordtiles-help-premium-<name>` (the premium legend).
GameRules wordTilesRules(BuildContext context, AppLocalizations l10n, GameConfig config) {
  final c = WordTilesColors.of(context);
  final primary = Theme.of(context).colorScheme.primary;
  Widget icon(IconData i) => Icon(i, size: 26, color: primary);
  RuleItem premium(Premium p, String text) {
    final bg = c.premium(p);
    return RuleItem(
      text,
      key: Key('wordtiles-help-premium-${p.name}'),
      lead: Container(
        width: 40,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
        child: Text(
          premiumLabel(l10n, p),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: inkOn(bg)),
        ),
      ),
    );
  }

  final dict = config.dictionary;
  final scoreless = WordTilesGame.defaultScorelessLimit(config.players);
  final dictionary = RuleItem(l10n.wordtilesHelpDictionary, lead: icon(Icons.spellcheck));
  final challenge =
      RuleItem('${l10n.wordtilesHelpChallenge} ${l10n.rulesWordtilesChallengeAfter}', lead: icon(Icons.gavel_outlined));
  return GameRules(
    goal: [RuleItem(l10n.wordtilesHelpGoal), RuleItem(l10n.rulesWordtilesWin)],
    turn: [
      ...ruleLines(l10n.rulesWordtilesTurn),
      RuleItem.heading(l10n.wordtilesHelpPremium),
      premium(Premium.doubleLetter, l10n.wordtilesHelpDoubleLetter),
      premium(Premium.tripleLetter, l10n.wordtilesHelpTripleLetter),
      premium(Premium.doubleWord, l10n.wordtilesHelpDoubleWord),
      premium(Premium.tripleWord, l10n.wordtilesHelpTripleWord),
      RuleItem(l10n.wordtilesHelpPremiumOnce),
    ],
    special: [
      RuleItem(l10n.wordtilesHelpBingo(WordTilesGame.rackSize, WordTilesGame.bingoBonus), lead: icon(Icons.auto_awesome)),
      RuleItem(
        l10n.wordtilesHelpBlank,
        lead: const Directionality(
          textDirection: TextDirection.ltr,
          child: LetterTile(letter: '', points: 0, blank: true, size: 32),
        ),
      ),
      RuleItem(l10n.wordtilesHelpSwap(WordTilesGame.rackSize), lead: icon(Icons.swap_horiz)),
      RuleItem(l10n.wordtilesHelpPass(scoreless), lead: icon(Icons.skip_next_outlined)),
      if (dict) ...[dictionary, challenge] else ...[challenge, dictionary],
      RuleItem(l10n.wordtilesHelpEnd, lead: icon(Icons.flag_outlined)),
      RuleItem(l10n.rulesWordtilesScoreless),
      RuleItem(l10n.wordtilesHelpZoom, lead: icon(Icons.pinch_outlined)),
      RuleItem(l10n.wordtilesHelpBench, lead: icon(Icons.view_week_outlined)),
    ],
    houseRules: [
      HouseRule(
        id: 'dictionary',
        title: l10n.wordtilesOptionDictionary,
        text: l10n.wordtilesOptionDictionaryOn,
        on: dict,
        lead: icon(Icons.spellcheck),
      ),
      HouseRule(
        id: 'joker',
        title: l10n.wordtilesOptionJoker,
        text: l10n.wordtilesOptionJokerExplain,
        on: config.jokerSwap,
        lead: icon(Icons.published_with_changes),
      ),
    ],
    choosable: true,
  );
}
