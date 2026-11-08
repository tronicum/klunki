import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../rules_model.dart';

/// Quartett (Trumpf) (KLD-123), with its house rule "3 or fewer cards:
/// choose" (KLD-100, [GameConfig.pickLowCards], on in every app game).
GameRules quartettTrumpfRules(BuildContext context, AppLocalizations l10n, GameConfig config) => GameRules(
      goal: ruleLines(l10n.rulesTrumpfGoal),
      turn: ruleLines(l10n.rulesTrumpfTurn),
      special: ruleLines(l10n.rulesTrumpfSpecial),
      houseRules: [
        HouseRule(
          id: 'pickLow',
          title: l10n.rulesTrumpfPickLow,
          text: l10n.rulesTrumpfPickLowText,
          on: config.pickLowCards,
        ),
      ],
    );

/// Quartett (Sets) (KLD-123): no house rules.
GameRules quartettSetsRules(BuildContext context, AppLocalizations l10n, GameConfig config) => GameRules(
      goal: ruleLines(l10n.rulesSetsGoal),
      turn: ruleLines(l10n.rulesSetsTurn),
      special: ruleLines(l10n.rulesSetsSpecial),
    );
