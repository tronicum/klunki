import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../games/maexchen/maexchen_dice.dart' show DieFace;
import '../rules_model.dart';

/// Rauswurf (KLD-131): goal, a turn, the special rules and the four house
/// rules of [GameConfig.ludo] (on by default; not chosen in the app yet).
GameRules ludoRules(BuildContext context, AppLocalizations l10n, GameConfig config) {
  final r = config.ludo;
  return GameRules(
    goal: ruleLines(l10n.rulesLudoGoal),
    turn: ruleLines(l10n.rulesLudoTurn),
    special: ruleLines(l10n.rulesLudoSpecial),
    houseRules: [
      HouseRule(
          id: 'tries',
          title: l10n.ludoRuleTries,
          text: l10n.rulesLudoTries,
          on: r.threeTries,
          lead: const DieFace(value: 6, size: 26)),
      HouseRule(
          id: 'capture',
          title: l10n.ludoRuleCapture,
          text: l10n.rulesLudoCapture,
          on: r.mustCapture,
          lead: const Icon(Icons.home_outlined, size: 26)),
      HouseRule(
          id: 'start',
          title: l10n.ludoRuleStart,
          text: l10n.rulesLudoStart,
          on: r.clearStart,
          lead: const Icon(Icons.flag_outlined, size: 26)),
      HouseRule(
          id: 'six',
          title: l10n.ludoRuleSix,
          text: l10n.rulesLudoSix,
          on: r.sixAgain,
          lead: const Icon(Icons.replay, size: 26)),
    ],
  );
}
