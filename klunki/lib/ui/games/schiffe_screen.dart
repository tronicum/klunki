import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../shell/game_screen.dart';
import 'schiffe/schiffe_board.dart';
import 'schiffe/schiffe_describe.dart';

/// Schiffe versenken screen (KLD-026, placement KLD-068): editable fleet
/// placement (`schiffe/schiffe_setup.dart`) with preview, rotate, move
/// and random placement, then the battle with the target grid ("Gegner") and
/// the own grid ("Dein Meer"). The board lives in `schiffe/schiffe_board.dart`.
///
/// Contract: the public class name `SchiffeScreen` and the constructor
/// `const SchiffeScreen({super.key, required this.controller})`. The screen is
/// built by `ui/shell/screen_registry.dart` and renders a [GameScreen]
/// (app bar, status/hint line, handover cover, result dialog, move history).
class SchiffeScreen extends StatelessWidget {
  final GameController controller;

  const SchiffeScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      controller: controller,
      describeMove: describeSchiffeMove,
      boardBuilder: (context, controller) => SchiffeBoard(controller: controller),
    );
  }
}
