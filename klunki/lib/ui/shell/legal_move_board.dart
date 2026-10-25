import 'package:flutter/material.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';

/// Legal moves of [game] as move maps (Connect4's `legalMoves` are column
/// ints, the other engines return maps already).
List<Map<String, dynamic>> legalMovesOf(Game game) {
  if (game is Connect4Game) return [for (final c in game.legalMoves) {'col': c}];
  return ((game as dynamic).legalMoves as List).cast<Map<String, dynamic>>();
}

/// Temporary board used by the placeholder game screens: every legal move of
/// the current position as a button (keys `legal-move-<i>`). Makes each game
/// playable end-to-end in hot-seat before its real screen exists.
class LegalMoveBoard extends StatelessWidget {
  final GameController controller;

  /// Button label for a move; defaults to the move map's `toString()`.
  final String Function(Map<String, dynamic> move)? label;

  const LegalMoveBoard({super.key, required this.controller, this.label});

  @override
  Widget build(BuildContext context) {
    final moves = legalMovesOf(controller.game);
    final enabled = controller.canAct;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < moves.length; i++)
            OutlinedButton(
              key: Key('legal-move-$i'),
              onPressed: enabled ? () => controller.submit(moves[i]) : null,
              child: Text(label?.call(moves[i]) ?? moves[i].toString()),
            ),
        ],
      ),
    );
  }
}
