import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import 'chess_pieces.dart';

/// The colour a chess room starts with when the host does not choose
/// (KLD-059 step 4a): random, so neither the host nor the guest always
/// gets White (the first move); the maintainer can switch it to White.
const ChessColorChoice defaultChessColorChoice = ChessColorChoice.random;

/// The colour [player] plays in a chess game started with [config]
/// ([GameConfig.chessWhite]).
ChessColor chessColorIn(GameConfig config, Player player) =>
    player == config.chessWhite ? ChessColor.white : ChessColor.black;

/// "Deine Farbe": Weiß / Schwarz / Zufällig for the host of a chess room
/// (KLD-059 step 4a), with "Weiß beginnt. Bei „Zufällig“ wird ausgelost."
/// underneath. Shown on "Raum starten" like the Quartett deck and the
/// Wortgewandt options. Keys: `<keyPrefix>white|black|random` (the segment
/// labels) and `<keyPrefix>helper`.
class ChessColorPicker extends StatelessWidget {
  final ChessColorChoice value;
  final ValueChanged<ChessColorChoice> onChanged;
  final bool enabled;
  final String keyPrefix;

  const ChessColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.keyPrefix = 'chess-color-',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget king(ChessColor c) =>
        ExcludeSemantics(child: ChessPieceIcon(piece: ChessPiece(c, ChessPieceType.king), size: 22));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.chessColorLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ChessColorChoice>(
          segments: [
            ButtonSegment(
              value: ChessColorChoice.white,
              icon: king(ChessColor.white),
              label: Text(l10n.chessWhite, key: Key('${keyPrefix}white')),
            ),
            ButtonSegment(
              value: ChessColorChoice.black,
              icon: king(ChessColor.black),
              label: Text(l10n.chessBlack, key: Key('${keyPrefix}black')),
            ),
            ButtonSegment(
              value: ChessColorChoice.random,
              icon: const Icon(Icons.casino_outlined),
              label: Text(l10n.chessColorRandom, key: Key('${keyPrefix}random')),
            ),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: enabled ? (s) => onChanged(s.single) : null,
        ),
        const SizedBox(height: 6),
        Text(l10n.chessColorHelper, key: Key('${keyPrefix}helper'), style: theme.textTheme.bodySmall),
      ],
    );
  }
}
