import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../games/maumau/maumau_cards.dart';
import '../rules_model.dart';

/// Mau-Mau (KLD-123): the jack (always), the special cards as house rules
/// ([MauMauRules], chosen before the game), each with its card.
GameRules mauMauRules(BuildContext context, AppLocalizations l10n, GameConfig config) {
  final r = config.mauMau;
  Widget card(MauMauRank rank, [MauMauSuit suit = MauMauSuit.hearts]) =>
      ExcludeSemantics(child: MauMauCardFace(card: MauMauCard(suit, rank), width: 34));
  return GameRules(
    goal: ruleLines(l10n.rulesMaumauGoal),
    // "Legen, wenn möglich" on: drawing only when no card fits.
    turn: ruleLines(r.mustPlay ? l10n.rulesMaumauTurnMustPlay : l10n.rulesMaumauTurn),
    special: [
      RuleItem(l10n.rulesMaumauJack, lead: card(MauMauRank.jack, MauMauSuit.clubs)),
      ...ruleLines(l10n.rulesMaumauSpecial),
    ],
    houseRules: [
      HouseRule(
        id: 'seven',
        title: l10n.maumauOptionSeven,
        text: l10n.maumauOptionSevenExplain,
        on: r.sevenDraws,
        lead: card(MauMauRank.seven),
      ),
      HouseRule(
        id: 'stack7',
        title: l10n.maumauOptionStack,
        text: l10n.maumauOptionStackExplain,
        on: r.sevenDraws && r.stackSevens,
        lead: card(MauMauRank.seven, MauMauSuit.spades),
      ),
      HouseRule(
        id: 'eight',
        title: l10n.maumauOptionEight,
        text: l10n.maumauOptionEightExplain,
        on: r.eightSkips,
        lead: card(MauMauRank.eight, MauMauSuit.diamonds),
      ),
      HouseRule(
        id: 'jackOnJack',
        title: l10n.maumauOptionJackOnJack,
        text: l10n.maumauOptionJackOnJackExplain,
        on: r.jackOnJack,
        lead: card(MauMauRank.jack, MauMauSuit.spades),
      ),
      HouseRule(
        id: 'ace',
        title: l10n.maumauOptionAce,
        text: l10n.maumauOptionAceExplain,
        on: r.aceAgain,
        lead: card(MauMauRank.ace, MauMauSuit.clubs),
      ),
      HouseRule(
        id: 'mau',
        title: l10n.maumauOptionMau,
        text: l10n.maumauOptionMauExplain,
        on: r.mauCall,
        lead: const Icon(Icons.campaign_outlined, size: 28),
      ),
      HouseRule(
        id: 'mustPlay',
        title: l10n.maumauOptionMustPlay,
        text: l10n.maumauOptionMustPlayExplain,
        on: r.mustPlay,
        lead: const Icon(Icons.style_outlined, size: 28),
      ),
    ],
    choosable: true,
  );
}
