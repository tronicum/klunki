import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../games/property/property_screen.dart' show PropertyNames;
import '../rules_model.dart';

/// Baulöwe (KLD-060, KLD-123): goal, a turn (roll, buy or auction, rent,
/// doubles, Start), the rules (whole group, building, cards, the pause,
/// money trouble, mortgages) and the settings chosen before the game
/// ([GameConfig.property]): the board, a round limit and the house rules
/// that are on. Amounts come from the engine.
GameRules propertyRules(BuildContext context, AppLocalizations l10n, GameConfig config) {
  final o = config.property;
  final board = PropertyTheme.byId(o.theme) ?? PropertyTheme.berlin;
  String money(int a) => l10n.propertyMoney(a);
  final free = board.squares[20].name;
  final amount = o.freeAmount ?? PropertyGame.defaultFreeSquareAmount(o.free);
  return GameRules(
    goal: [
      ...ruleLines(l10n.rulesPropertyGoal),
    ],
    turn: [
      ...ruleLines(l10n.rulesPropertyTurn(money(PropertyGame.startSalary))),
    ],
    special: [
      ...ruleLines(l10n.rulesPropertySpecial(money(PropertyGame.bail))),
    ],
    houseRules: [
      HouseRule(
        id: 'theme',
        title: l10n.propertyOptionsBoard,
        text: PropertyNames.themeTitle(l10n, board),
        on: o.theme != null,
        lead: const Icon(Icons.map_outlined, size: 26),
      ),
      HouseRule(
        id: 'rounds',
        title: l10n.propertyOptionsRounds(o.rounds ?? 0),
        text: l10n.propertyOptionsRoundsExplain,
        on: o.rounds != null,
        lead: const Icon(Icons.timelapse, size: 26),
      ),
      HouseRule(
        id: 'free',
        title: l10n.propertyFreeTitle(free),
        text: switch (o.free) {
          PropertyFreeSquare.fixedBonus => l10n.propertyFreeBonusExplain(free, money(amount)),
          PropertyFreeSquare.potWithSeed => '${l10n.propertyFreePotSeed(money(amount))}. ${l10n.propertyFreeExplain}',
          _ => l10n.propertyFreeExplain,
        },
        on: o.free != PropertyFreeSquare.none,
        lead: const Icon(Icons.savings_outlined, size: 26),
      ),
      HouseRule(
        id: 'doubleStart',
        title: l10n.propertyRuleDoubleStart,
        text: l10n.propertyRuleDoubleStartExplain(money(2 * PropertyGame.startSalary)),
        on: o.doubleStart,
        lead: const Icon(Icons.flag_rounded, size: 26),
      ),
      HouseRule(
        id: 'noRentInPause',
        title: l10n.propertyRuleNoRentInPause,
        text: l10n.propertyRuleNoRentInPauseExplain,
        on: o.noRentInPause,
        lead: const Icon(Icons.pause_circle_outline, size: 26),
      ),
      HouseRule(
        id: 'bankruptAuction',
        title: l10n.propertyRuleBankruptAuction,
        text: l10n.propertyRuleBankruptAuctionExplain,
        on: o.bankruptAuction,
        lead: const Icon(Icons.gavel, size: 26),
      ),
    ],
    choosable: true,
  );
}
