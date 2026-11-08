import 'package:flutter/widgets.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart';

/// One entry of a rules section (KLD-123): a short [text] with an optional
/// small picture in front ([lead]; a dot without one), a sub-heading
/// ([RuleItem.heading]) or a full-width widget such as a table
/// ([RuleItem.widget]).
@immutable
class RuleItem {
  final String? text;
  final Widget? lead;
  final Widget? child;
  final bool heading;
  final Key? key;

  const RuleItem(String this.text, {this.lead, this.key})
      : child = null,
        heading = false;

  const RuleItem.heading(String this.text, {this.key})
      : lead = null,
        child = null,
        heading = true;

  const RuleItem.widget(Widget this.child, {this.key})
      : text = null,
        lead = null,
        heading = false;
}

/// The lines of [text] (one ARB string, lines separated by "\n") as items.
List<RuleItem> ruleLines(String text) => [
      for (final line in text.split('\n'))
        if (line.trim().isNotEmpty) RuleItem(line.trim()),
    ];

/// A house rule or game setting and whether it is on in the game shown.
/// Only the ones that are [on] are listed ([id] makes the key
/// `rules-house-<id>`).
@immutable
class HouseRule {
  final String id;
  final String title;
  final String text;
  final bool on;
  final Widget? lead;
  const HouseRule({required this.id, required this.title, required this.text, required this.on, this.lead});
}

/// The rules page of one game: the same four parts for every game.
@immutable
class GameRules {
  /// "Ziel": how to win.
  final List<RuleItem> goal;

  /// "So läuft ein Zug".
  final List<RuleItem> turn;

  /// "Besondere Regeln".
  final List<RuleItem> special;

  /// The game's house rules and settings (empty: the game has none).
  final List<HouseRule> houseRules;

  /// The players choose the house rules before a game (from the menu the
  /// page then says these are the suggested ones).
  final bool choosable;

  const GameRules({
    required this.goal,
    required this.turn,
    required this.special,
    this.houseRules = const [],
    this.choosable = false,
  });
}

/// Builds the rules of a game for [config]: the config of the running game,
/// or the defaults (`GameConfig(id)`) when opened from the menu.
typedef RulesBuilder = GameRules Function(BuildContext context, AppLocalizations l10n, GameConfig config);
