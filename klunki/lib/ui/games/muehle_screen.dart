import 'package:flutter/material.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';
import '../../transport/game_transport.dart';
import '../shell/game_screen.dart';
import 'muehle/muehle_board.dart';

/// Mühle screen: painted board with tappable points (see [MuehleBoard]),
/// player panels, phase hints and readable move history.
///
/// Contract (keep it): the public class name `MuehleScreen` and the constructor
/// `const MuehleScreen({super.key, required this.controller})`. The screen is
/// built by `ui/shell/screen_registry.dart` and renders a [GameScreen].
class MuehleScreen extends StatelessWidget {
  final GameController controller;

  const MuehleScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      controller: controller,
      describeMove: (m) => describeMuehleMove(controller.moves, m),
      boardBuilder: (context, controller) => MuehleBoard(controller: controller),
    );
  }
}

/// German text for [m] without the player, which the shell's history sheet
/// prefixes ("setzt auf 5", "zieht 15→16", "springt 20→9",
/// "entfernt Stein auf 8"). [log] is the move log [m] belongs to; it is
/// used to tell flying from moving (the mover had exactly 3 stones left).
String describeMuehleMove(List<AcceptedMove> log, AcceptedMove m) {
  final move = m.move;
  switch (move['action']) {
    case 'place':
      return 'setzt auf ${move['to']}';
    case 'remove':
      return 'entfernt Stein auf ${move['at']}';
    default:
      // All stones are placed when moving, so stones left = 9 - stones lost.
      var lost = 0;
      for (final e in log) {
        if (e.index >= m.index) break;
        if (e.player != m.player && e.move['action'] == 'remove') lost++;
      }
      final flying = MuehleGame.piecesPerPlayer - lost == 3;
      return '${flying ? 'springt' : 'zieht'} ${move['from']}→${move['to']}';
  }
}
