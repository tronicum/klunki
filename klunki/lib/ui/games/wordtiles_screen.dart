import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';
import '../../transport/game_transport.dart';
import '../shell/game_screen.dart';
import '../shell/seat_game_screen.dart';
import 'wordtiles/wordtiles_board.dart';

/// Word tile game screen (KLD-094 step 2, "Wortgewandt"): the
/// board, rack and actions of [WordTilesBoard] in the shared [GameScreen].
///
/// Hidden information (the racks): in hot-seat the shell's handover cover
/// hides the board between turns; the cover shows the last turn (public),
/// so the player who just moved sees it before passing the device. Over the
/// network (KLD-094 step 6) each device shows its own rack from its view;
/// "Trotzdem zulassen" asks the other device.
///
/// 3–4 players (KLD-125) play in the seat shell ([SeatGameScreen]): on one
/// device with its handover cover between every two players; at a network
/// table (KLD-088 step 4) each device shows its own rack, without a cover.
/// The ranking has the rack deduction per seat and this game's summary under
/// it; 2 players keep [GameScreen] (also over the network).
///
/// Contract (keep it): the public class name `WordTilesScreen` and the
/// constructor `const WordTilesScreen({super.key, required this.controller})`.
/// The screen is built by `ui/shell/screen_registry.dart`.
class WordTilesScreen extends StatelessWidget {
  final GameController controller;

  const WordTilesScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    if (game is WordTilesGame && game.playerCount > 2) {
      final screen = SeatGameScreen(
        controller: controller,
        describeMove: describeWordTilesMove,
        handoverDetail: (context) => WordTilesLastTurn(controller: controller),
        resultHeader: (context) => WordTilesEndLine(controller: controller),
        resultDetail: (context) => WordTilesResult(controller: controller, scores: false),
        rankingNote: (context, seat) => wordTilesRackNote(context, controller, seat),
        boardBuilder: (context, controller) => WordTilesBoard(controller: controller),
      );
      // A network table (KLD-088) names its seats from the room
      // ([NetworkGameSession]); one device from the app's name stores.
      return controller.localSeat != null ? screen : SeatNamesBuilder(child: screen);
    }
    return GameScreen(
      controller: controller,
      describeMove: describeWordTilesMove,
      handoverDetail: (context) => WordTilesLastTurn(controller: controller),
      resultDetail: (context) => WordTilesResult(controller: controller),
      boardBuilder: (context, controller) => WordTilesBoard(controller: controller),
      // "Zug zurücknehmen" under the actions, on the bench line (KLD-117).
      boardPlacesUndo: true,
      // The score row names the players next to their scores (KLD-094 step 8g).
      showPlayersLegend: false,
    );
  }
}

/// The game-end summary under the shell's result reason (KLD-094 step 5):
/// final score per player with the rack penalty (or the bonus of the player
/// who went out), the highest-scoring single word, and the words let stand
/// with "Trotzdem zulassen". "Nochmal spielen" is the shell's button.
///
/// [scores] false (3–4 players, KLD-125): only the best word and the
/// allowed words; the seat shell's ranking has the scores and the rack
/// deduction ([wordTilesRackNote]).
///
/// 2 players: [WordTilesEndLine] (the last word) on top; 3–4 players have
/// it above the ranking (`SeatGameScreen.resultHeader`).
///
/// Keys: `wordtiles-result`, `wordtiles-result-score-<seat>`,
/// `wordtiles-result-rack-<seat>`, `wordtiles-result-best`,
/// `wordtiles-result-allowed`.
class WordTilesResult extends StatelessWidget {
  final GameController controller;
  final bool scores;
  const WordTilesResult({super.key, required this.controller, this.scores = true});

  /// The highest-scoring word laid and kept (a placement withdrawn after a
  /// challenge does not count): (seat, word, score), or null.
  static (int, String, int)? bestWord(GameController controller) {
    final kept = <(int, List<(String, int)>)>[];
    for (final m in controller.moves) {
      final p = m.event.payload;
      if (p is! Map) continue;
      switch (m.move['action']) {
        case 'place' || WordTilesGame.acceptAllow:
          kept.add((
            p['seat'] as int? ?? 0,
            [
              for (final w in p['words'] as List? ?? const [])
                if (w is Map && w['word'] is String) (w['word'] as String, w['score'] as int? ?? 0),
            ],
          ));
        case 'challenge' when p['withdrawn'] == true && kept.isNotEmpty:
          kept.removeLast();
      }
    }
    (int, String, int)? best;
    for (final (seat, words) in kept) {
      for (final (w, s) in words) {
        if (best == null || s > best.$3) best = (seat, w, s);
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    if (game is! WordTilesGame) return const SizedBox();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String who(int seat) => wordTilesSeatName(context, game, seat);

    final penalties = game.rackPenalties;
    final top = game.scores.fold<int>(game.scores.first, (a, b) => b > a ? b : a);
    final best = bestWord(controller);
    final allowed = [
      for (final t in game.turns)
        if (t.action == 'place' && !t.withdrawn) ...t.allowed,
    ];
    return Column(
      key: const Key('wordtiles-result'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KLD-094: the summary comes right after the last move; name it.
        if (scores && WordTilesEndLine.textOf(context, game) != null) ...[
          WordTilesEndLine(controller: controller),
          const SizedBox(height: 8),
        ],
        for (var s = 0; s < game.playerCount && scores; s++)
          Padding(
            key: Key('wordtiles-result-score-$s'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                WordTilesSeatToken(game: game, seat: s, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(who(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                      if (penalties[s] != 0)
                        Text(
                          l10n.wordtilesResultRack(
                              penalties[s] > 0 ? '+${penalties[s]}' : '\u2212${-penalties[s]}'),
                          key: Key('wordtiles-result-rack-$s'),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${game.scoreOf(s)}',
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: game.scoreOf(s) == top ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (best != null) ...[
          if (scores) const Divider(height: 20),
          Text(
            l10n.wordtilesResultBestWord(best.$2, who(best.$1), best.$3),
            key: const Key('wordtiles-result-best'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (allowed.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            l10n.wordtilesResultAllowed(allowed.join(', ')),
            key: const Key('wordtiles-result-allowed'),
            style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}

/// How the game ended, as the first line of the summary (KLD-094): the
/// summary opens right after the last move, so the others never saw it.
/// After a player went out: the words of that final placement (main word
/// first), who laid them and the points of the move ("Letztes Wort: Anna
/// legt KATZE für 24 Punkte"). After the scoreless turns, if all of them
/// were passes: "Am Ende haben alle gepasst." Nothing after a resign or a
/// scoreless end with exchanges (the reason line says enough).
/// Key `wordtiles-result-last`.
class WordTilesEndLine extends StatelessWidget {
  final GameController controller;
  const WordTilesEndLine({super.key, required this.controller});

  /// The line for [game], or null when there is none.
  static String? textOf(BuildContext context, WordTilesGame game) {
    final l10n = AppLocalizations.of(context);
    final turns = game.turns;
    switch (game.playResult.code) {
      case GameEndReason.wordtilesPlayedOut:
        // The placement that emptied the rack; after it at most an
        // "accept" or a failed challenge.
        final last = turns.lastWhere((t) => t.action == 'place' && !t.withdrawn,
            orElse: () => const WordTilesTurn(-1, ''));
        if (last.seat < 0 || last.words.isEmpty) return null;
        return l10n.wordtilesResultLastWord(last.words.length, wordTilesSeatName(context, game, last.seat),
            wordList(context, last.words), last.score);
      case GameEndReason.wordtilesScoreless:
        final moves = [
          for (final t in turns)
            if (t.action != 'resign') t,
        ];
        if (moves.length < game.scorelessLimit) return null;
        final tail = moves.sublist(moves.length - game.scorelessLimit);
        return tail.every((t) => t.action == 'pass') ? l10n.wordtilesResultAllPassed : null;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final text = game is WordTilesGame ? textOf(context, game) : null;
    if (text == null) return const SizedBox.shrink();
    return Text(
      text,
      key: const Key('wordtiles-result-last'),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

/// The rack deduction (or bonus) of [seat] at the game end, for the seat
/// shell's ranking next to the points ("(−2)", "(+8)" for the player who
/// went out; as the score row), or null when there is none.
String? wordTilesRackNote(BuildContext context, GameController controller, int seat) {
  final game = controller.game;
  if (game is! WordTilesGame) return null;
  final pen = game.rackPenalties[seat];
  if (pen == 0) return null;
  return pen > 0 ? '(+$pen)' : '(\u2212${-pen})';
}

/// The last turn as a line ("Anna: HAUS für 14 Punkte"), for the
/// handover cover. Public information only.
class WordTilesLastTurn extends StatelessWidget {
  final GameController controller;
  const WordTilesLastTurn({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    if (game is! WordTilesGame) return const SizedBox();
    final l10n = AppLocalizations.of(context);
    // "Trotzdem zulassen" (KLD-094): the device goes to the player who
    // answers; the cover says what they are asked.
    final request = game.allowRequest;
    if (request != null) {
      return Text(
        l10n.wordtilesAllowLine(
            wordTilesSeatName(context, game, request.seat), wordList(context, request.allow), request.score),
        key: const Key('wordtiles-cover-allow'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      );
    }
    if (game.turns.isEmpty) return const SizedBox();
    final t = game.turns.last;
    final who = wordTilesSeatName(context, game, t.seat);
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
  final text = switch (m.move['action']) {
    // KLD-094 step 4: words the players let stand although the list lacks them.
    'place' when words(p['allowed']).isNotEmpty => l10n.wordtilesMovePlaceAllowed(
        words(p['words']).join(', '), p['score'] as int? ?? 0, words(p['allowed']).join(', ')),
    'place' => l10n.wordtilesMovePlace(words(p['words']).join(', '), p['score'] as int? ?? 0),
    'exchange' => l10n.wordtilesMoveExchange(p['count'] as int? ?? 0),
    'pass' => l10n.wordtilesMovePass,
    'challenge' => p['withdrawn'] == true
        ? l10n.wordtilesMoveChallengeWithdrawn(words(p['words']).join(', '))
        : l10n.wordtilesMoveChallengeFailed,
    'accept' => l10n.wordtilesMoveAccept,
    // KLD-094 step 6: "Trotzdem zulassen" asked, agreed or declined.
    WordTilesGame.requestAllow => l10n.wordtilesMoveAllowRequest(words(p['allow']).join(', '), p['score'] as int? ?? 0),
    WordTilesGame.acceptAllow =>
      l10n.wordtilesMoveAllowAccept(words(p['allowed']).join(', '), p['score'] as int? ?? 0),
    WordTilesGame.declineAllow => l10n.wordtilesMoveAllowDecline(words(p['allow']).join(', ')),
    _ => m.move.toString(),
  };
  // KLD-094 step 9: the placement came with "Joker tauschen".
  final swaps = p['swaps'];
  final placed = m.move['action'] == 'place' || m.move['action'] == WordTilesGame.acceptAllow;
  return placed && swaps is List && swaps.isNotEmpty ? l10n.wordtilesMoveJoker(text) : text;
}
