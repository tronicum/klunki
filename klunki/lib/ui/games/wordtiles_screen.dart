import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';
import '../../transport/game_transport.dart';
import '../shell/game_screen.dart';
import 'wordtiles/wordtiles_board.dart';

/// Word tile game screen (KLD-094 step 2, "Wortgewandt"): the
/// board, rack and actions of [WordTilesBoard] in the shared [GameScreen].
///
/// Hidden information (the racks): in hot-seat the shell's handover cover
/// hides the board between turns; the cover shows the last turn (public),
/// so the player who just moved sees it before passing the device.
///
/// Contract (keep it): the public class name `WordTilesScreen` and the
/// constructor `const WordTilesScreen({super.key, required this.controller})`.
/// The screen is built by `ui/shell/screen_registry.dart`.
class WordTilesScreen extends StatelessWidget {
  final GameController controller;

  const WordTilesScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      controller: controller,
      describeMove: describeWordTilesMove,
      handoverDetail: (context) => WordTilesLastTurn(controller: controller),
      boardBuilder: (context, controller) => WordTilesBoard(controller: controller),
    );
  }
}

/// The last turn as a line ("Anna: HAUS für 14 Punkte"), for the
/// handover cover. Public information only.
class WordTilesLastTurn extends StatelessWidget {
  final GameController controller;
  const WordTilesLastTurn({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    if (game is! WordTilesGame || game.turns.isEmpty) return const SizedBox();
    final l10n = AppLocalizations.of(context);
    final labels = PlayerLabelsScope.of(context);
    final t = game.turns.last;
    final p = WordTilesGame.playerOfSeat(t.seat);
    final who = p == null ? '${t.seat + 1}' : labels.label(context, l10n, p);
    return Text(
      l10n.shellHistoryEntry(who, describeWordTilesTurn(context, l10n, t)),
      key: const Key('wordtiles-cover-turn'),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

/// A move for the history sheet (the shell puts the player in front), from
/// the move and its event.
String describeWordTilesMove(AppLocalizations l10n, AcceptedMove m) {
  final payload = m.event.payload;
  final p = payload is Map ? payload : const {};
  List<String> words(Object? raw) => [
        for (final w in raw is List ? raw : const [])
          if (w is Map && w['word'] is String) w['word'] as String else if (w is String) w,
      ];
  return switch (m.move['action']) {
    'place' => l10n.wordtilesMovePlace(words(p['words']).join(', '), p['score'] as int? ?? 0),
    'exchange' => l10n.wordtilesMoveExchange(p['count'] as int? ?? 0),
    'pass' => l10n.wordtilesMovePass,
    'challenge' => p['withdrawn'] == true
        ? l10n.wordtilesMoveChallengeWithdrawn(words(p['words']).join(', '))
        : l10n.wordtilesMoveChallengeFailed,
    'accept' => l10n.wordtilesMoveAccept,
    _ => m.move.toString(),
  };
}
