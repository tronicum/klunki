import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../shell/game_screen.dart';
import 'maexchen_board.dart';

/// Mäxchen screen (KLD-121): the dice bluffing game, hot-seat. The board
/// (`maexchen_board.dart`) has the lives, the announcement, the table with
/// the cup and the actions; the shell adds status, hint, history, "Zug
/// zurück" and the handover cover, which shows the announcement (or how
/// the round ended) to the next player before the device is handed over.
///
/// Contract: `const MaexchenScreen({super.key, required this.controller})`,
/// built by `ui/shell/screen_registry.dart`.
class MaexchenScreen extends StatelessWidget {
  final GameController controller;

  const MaexchenScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      controller: controller,
      describeMove: describeMaexchenMove,
      // The board names both players with their lives.
      showPlayersLegend: false,
      handoverDetail: (context) => MaexchenHandoverDetail(controller: controller),
      resultDetail: (context) {
        final game = controller.game as MaexchenGame;
        final last = game.lastRound;
        if (last == null || game.resignedBy != null) return const SizedBox.shrink();
        return MaexchenRoundSummary(end: last);
      },
      // "Zug zurücknehmen" sits in the board's control row, next to the actions.
      boardPlacesUndo: true,
      boardBuilder: (context, controller) => MaexchenBoard(controller: controller),
    );
  }
}

/// The value [v] as shown: the number ("54"), or the name of the highest
/// one ("Mäxchen").
String maexchenValueLabel(AppLocalizations l10n, int v) => v == MaexchenGame.maexchen ? l10n.maexchenMaexchenName : '$v';

/// History text of a Mäxchen move ("würfelt", "sagt 54", …).
String describeMaexchenMove(AppLocalizations l10n, AcceptedMove move) => switch (move.move['action']) {
      'roll' => l10n.maexchenMoveRoll,
      'announce' => l10n.maexchenMoveAnnounce(maexchenValueLabel(l10n, move.move['value'] as int)),
      'believe' => l10n.maexchenMoveBelieve,
      'doubt' => l10n.maexchenMoveDoubt,
      'giveUp' => l10n.maexchenMoveGiveUp,
      _ => move.move.toString(),
    };
