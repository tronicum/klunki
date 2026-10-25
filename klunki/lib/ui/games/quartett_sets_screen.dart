import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../shell/game_screen.dart';
import '../shell/legal_move_board.dart';

/// Quartett (Sets) screen. PLACEHOLDER (KLD-021): shows the legal moves as buttons
/// so the game is playable end-to-end in hot-seat; KLD-025 replaces the body
/// of this file with the real board.
///
/// Contract (keep it): the public class name `QuartettSetsScreen` and the constructor
/// `const QuartettSetsScreen({super.key, required this.controller})`. The screen is
/// built by `ui/shell/screen_registry.dart` and must render a [GameScreen]
/// (which provides the app bar, status/hint line, handover cover, result
/// dialog and move history).
class QuartettSetsScreen extends StatelessWidget {
  final GameController controller;

  const QuartettSetsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      controller: controller,
      boardBuilder: (context, controller) {
        GameScreen.of(context).setHint('Platzhalter: wähle einen legalen Zug.');
        return LegalMoveBoard(controller: controller);
      },
    );
  }
}
