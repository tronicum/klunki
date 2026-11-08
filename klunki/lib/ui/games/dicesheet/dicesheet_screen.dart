import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../shell/seat_game_screen.dart';
import 'dicesheet_board.dart';

/// Ausgewürfelt (KLD-119): the five-dice score-sheet game for 2–4 players
/// on one device, in the seat shell ([SeatGameScreen]). The board
/// (`dicesheet_board.dart`) has the score sheet and the dice with "Würfeln";
/// the app bar adds the rules.
///
/// Contract: `const DiceSheetScreen({super.key, required this.controller})`,
/// built by `ui/shell/screen_registry.dart`.
class DiceSheetScreen extends StatelessWidget {
  final GameController controller;
  const DiceSheetScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SeatNamesBuilder(
      child: SeatGameScreen(
        controller: controller,
        describeMove: describeDiceSheetMove,
        actions: [
          IconButton(
            key: const Key('dicesheet-help'),
            tooltip: l10n.dicesheetHelpTitle,
            icon: const Icon(Icons.help_outline),
            onPressed: () => showDiceSheetHelp(context, extraFives: (controller.game as DiceSheetGame).extraFives),
          ),
        ],
        boardBuilder: (context, controller) => DiceSheetBoard(controller: controller),
      ),
    );
  }
}

/// The name of [box] on the sheet ("Einser", "Full House", …).
String diceBoxName(AppLocalizations l10n, DiceBox box) => switch (box) {
      DiceBox.ones => l10n.dicesheetBoxOnes,
      DiceBox.twos => l10n.dicesheetBoxTwos,
      DiceBox.threes => l10n.dicesheetBoxThrees,
      DiceBox.fours => l10n.dicesheetBoxFours,
      DiceBox.fives => l10n.dicesheetBoxFives,
      DiceBox.sixes => l10n.dicesheetBoxSixes,
      DiceBox.threeKind => l10n.dicesheetBoxThreeKind,
      DiceBox.fourKind => l10n.dicesheetBoxFourKind,
      DiceBox.fullHouse => l10n.dicesheetBoxFullHouse,
      DiceBox.smallStraight => l10n.dicesheetBoxSmallStraight,
      DiceBox.largeStraight => l10n.dicesheetBoxLargeStraight,
      DiceBox.fiveKind => l10n.dicesheetBoxFiveKind,
      DiceBox.chance => l10n.dicesheetBoxChance,
    };

/// History text of a move ("würfelt 3 3 5 1 6", "Full House: 25").
String describeDiceSheetMove(AppLocalizations l10n, AcceptedMove move) {
  final p = move.event.payload;
  switch (move.move['action']) {
    case 'roll':
      final dice = p is Map ? (p['rolled'] as List).join(' ') : '';
      final kept = p is Map ? (p['kept'] as List).length : 0;
      // Dice read left to right in every language.
      return kept == 0 ? l10n.dicesheetMoveRoll('\u2066$dice\u2069') : l10n.dicesheetMoveRollKeep('\u2066$dice\u2069', kept);
    case 'score':
      final box = DiceBox.byId(move.move['box']);
      final points = p is Map ? p['points'] as int : 0;
      final bonus = p is Map ? p['bonus'] as int? : null;
      final name = box == null ? '${move.move['box']}' : diceBoxName(l10n, box);
      return bonus == null ? l10n.dicesheetMoveScore(name, points) : l10n.dicesheetMoveScoreBonus(name, points, bonus);
  }
  return move.move.toString();
}

/// The rules in a dialog ("So geht's").
Future<void> showDiceSheetHelp(BuildContext context, {required bool extraFives}) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  Widget para(String text) =>
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: theme.textTheme.bodyMedium));
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('dicesheet-help-dialog'),
      title: Text(l10n.dicesheetHelpTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          para(l10n.dicesheetHelpTurn),
          para(l10n.dicesheetHelpUpper),
          para(l10n.dicesheetHelpLower),
          para(l10n.dicesheetHelpEnd),
          if (extraFives) para(l10n.dicesheetHelpExtraFives),
        ],
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(MaterialLocalizations.of(ctx).okButtonLabel)),
      ],
    ),
  );
}
