import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

import '../../game/game_controller.dart';
import '../shell/game_screen.dart';
import 'connect4/connect4_board.dart';

/// 4 Gewinnt screen: a blue 7×6 board inside the shared [GameScreen].
/// Tap a column to drop a piece (X = red, O = yellow); the winning four is
/// highlighted once the game is over. See [Connect4Board].
///
/// Contract (keep it): the public class name `Connect4Screen` and the constructor
/// `const Connect4Screen({super.key, required this.controller})`. The screen is
/// built by `ui/shell/screen_registry.dart` and renders a [GameScreen].
class Connect4Screen extends StatelessWidget {
  final GameController controller;

  const Connect4Screen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      controller: controller,
      // The shell prefixes the player mark: "X: Spalte 4".
      describeMove: (l10n, m) => l10n.connect4Column((m.move['col'] as int) + 1),
      boardBuilder: (context, controller) {
        GameScreen.of(context).setHint(controller.canAct ? AppLocalizations.of(context).connect4HintTapColumn : null);
        return Connect4Board(controller: controller);
      },
    );
  }
}
