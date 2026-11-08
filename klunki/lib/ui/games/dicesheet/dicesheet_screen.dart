import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../shell/game_screen.dart' show ShellMenuEntry;
import '../../shell/seat_game_screen.dart';
import 'dicesheet_board.dart';

/// Ausgewürfelt (KLD-119): the five-dice score-sheet game for 2–4 players
/// on one device, in the seat shell ([SeatGameScreen]). The board
/// (`dicesheet_board.dart`) has the score sheet and the dice with "Würfeln";
/// the rules are the shell's "Regeln" page (`rules/games/dicesheet_rules.dart`).
///
/// Contract: `const DiceSheetScreen({super.key, required this.controller})`,
/// built by `ui/shell/screen_registry.dart`.
class DiceSheetScreen extends StatefulWidget {
  final GameController controller;
  const DiceSheetScreen({super.key, required this.controller});

  @override
  State<DiceSheetScreen> createState() => _DiceSheetScreenState();
}

class _DiceSheetScreenState extends State<DiceSheetScreen> {
  /// "Kurz erklärt" in the "⋮" menu: the board shows the tour again.
  final _tour = DiceSheetTourRequest();

  @override
  void dispose() {
    _tour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SeatNamesBuilder(
      child: SeatGameScreen(
        controller: widget.controller,
        describeMove: describeDiceSheetMove,
        menuEntries: [
          ShellMenuEntry(
            key: const Key('dicesheet-tour'),
            icon: Icons.tour_outlined,
            label: l10n.dicesheetCoachReplay,
            onSelected: _tour.request,
          ),
        ],
        boardBuilder: (context, controller) => DiceSheetBoard(controller: controller, tour: _tour),
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
