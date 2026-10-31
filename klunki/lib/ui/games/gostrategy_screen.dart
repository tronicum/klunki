import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../shell/game_screen.dart';
import 'gostrategy/gostrategy_board.dart';
import 'gostrategy/gostrategy_pieces.dart';

/// GoStrategy screen (KLD-058b): the hidden-rank capture-the-flag game.
/// Setup editor per player (shuffle, swap by tapping, "Fertig"), then the
/// 10×10 board turned so the own army is at the bottom, the armies panel and
/// a short fight reveal. The board lives in `gostrategy/gostrategy_board.dart`.
///
/// Hot-seat: the shell's handover cover hides everything between the
/// players and shows the last fight's outcome (public) on the cover.
class GoStrategyScreen extends StatelessWidget {
  final GameController controller;

  const GoStrategyScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      controller: controller,
      describeMove: describeGoStrategyMove,
      boardBuilder: (context, controller) => GoStrategyBoard(controller: controller),
      handoverDetail: (context) => GoLastFightOnCover(controller: controller),
    );
  }
}
