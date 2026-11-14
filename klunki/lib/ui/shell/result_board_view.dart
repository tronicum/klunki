import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

/// "Brett ansehen" at the game end (KLD-094): the result dialog of a board
/// game closes for a look at the final board (the last move still marked by
/// the board), and a bar over the board ("Ergebnis anzeigen") opens it
/// again. Same wording as Baulöwe's look at the board during a trade
/// (KLD-060). Both shells ([GameScreen], [SeatGameScreen]) use it, in
/// hot-seat and over the network.
///
/// Games without a board (cards, dice) keep the plain dialog: the final
/// position of a board game is worth a look, a card table is not.
const Set<String> resultBoardGames = {
  'connect4',
  'muehle',
  'schiffe',
  'gostrategy',
  'chess',
  'wordtiles',
  'property',
};

/// What the result dialog was closed with.
enum ResultChoice { menu, again, board }

/// The "Brett ansehen" button of the result dialog (key `result-show-board`),
/// under the summary at the start edge.
class ResultShowBoardButton extends StatelessWidget {
  const ResultShowBoardButton({super.key});

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          key: const Key('result-show-board'),
          onPressed: () => Navigator.of(context).pop(ResultChoice.board),
          icon: const Icon(Icons.grid_view_rounded),
          label: Text(AppLocalizations.of(context).shellResultShowBoard),
        ),
      );
}

/// The bar over the final board after "Brett ansehen": "So endete das
/// Spiel." and "Ergebnis anzeigen" (key `result-show-result`) to open the
/// result dialog again. Key `result-board-bar`.
class ResultBoardBar extends StatelessWidget {
  final VoidCallback onShowResult;
  const ResultBoardBar({super.key, required this.onShowResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      key: const Key('result-board-bar'),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
        child: Row(children: [
          Icon(Icons.sports_score, size: 20, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.shellResultBoardNote,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            key: const Key('result-show-result'),
            onPressed: onShowResult,
            icon: const Icon(Icons.emoji_events_outlined),
            label: Text(l10n.shellResultShowResult),
          ),
        ]),
      ),
    );
  }
}
