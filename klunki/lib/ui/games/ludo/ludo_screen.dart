import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../shell/seat_game_screen.dart';
import 'ludo_board.dart';

/// Rauswurf (KLD-131): the cross-and-circle race game for 2–4 players on
/// one device, in the seat shell ([SeatGameScreen]). The board
/// (`ludo_board.dart`) has the cross with the pawns and the die; the rules
/// are the shell's "Regeln" page (`rules/games/ludo_rules.dart`).
///
/// Contract: `const LudoScreen({super.key, required this.controller})`,
/// built by `ui/shell/screen_registry.dart`.
class LudoScreen extends StatelessWidget {
  final GameController controller;
  const LudoScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SeatNamesBuilder(
      child: Builder(
        builder: (context) {
          final labels = SeatLabelsScope.of(context);
          String name(AppLocalizations l10n, int seat) =>
              labels.label(context, l10n, seat, count: controller.config.players);
          return SeatGameScreen(
            controller: controller,
            describeMove: (l10n, move) => describeLudoMove(l10n, move, (s) => name(l10n, s)),
            resultScore: (l10n, result, seat) {
              final game = controller.game;
              if (game is LudoGame && game.isSeatOut(seat)) return null;
              final home = result.params['home$seat'];
              return home == null ? null : l10n.ludoResultHome(home);
            },
            boardBuilder: (context, controller) => LudoBoard(controller: controller),
          );
        },
      ),
    );
  }
}

/// History text of a move ("würfelt 6", "bringt eine Figur ins Spiel",
/// "zieht 4 Felder, wirft eine Figur von Ben raus"); [name] names a seat.
String describeLudoMove(AppLocalizations l10n, AcceptedMove move, String Function(int seat) name) {
  final p = move.event.payload;
  if (p is! Map) return move.move.toString();
  switch (move.move['action']) {
    case 'roll':
      final value = p['rolled'] as int;
      return p['passed'] == true || (p['again'] == true && p['pawns'] == null)
          ? l10n.ludoMoveRollNoMove(value)
          : l10n.ludoMoveRoll(value);
    case 'move':
      final from = p['from'] as int, to = p['to'] as int;
      final text = from == LudoGame.house
          ? l10n.ludoMoveOut
          : from < LudoGame.laneStart && to >= LudoGame.laneStart
              ? l10n.ludoMoveHome
              : l10n.ludoMoveStep(to - from);
      if (p['captured'] case {'seat': final int s}) return '$text, ${l10n.ludoMoveCapture(name(s))}';
      return text;
  }
  return move.move.toString();
}
