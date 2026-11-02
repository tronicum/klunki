import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import 'wordtiles_tiles.dart';

/// The one-time explanation of the "Bänkchen" (KLD-094 step 8): three short
/// steps with a small picture each, "Weiter" / "Verstanden", and
/// "Überspringen" on every step. Shown the first time the bench is visible
/// on a player's own turn (open from the start on a large screen, KLD-094
/// step 8c, or opened by the player; in hot-seat after the handover cover;
/// [SeenTips.wordtilesBench], once per device); it shows only sample tiles,
/// never a rack.
///
/// Keys: `wordtiles-coach`, `wordtiles-coach-step-<1..3>`,
/// `wordtiles-coach-next`, `wordtiles-coach-done`, `wordtiles-coach-skip`.
Future<void> showBenchCoach(BuildContext context, TileSet tileSet) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BenchCoach(tileSet: tileSet),
    );

class BenchCoach extends StatefulWidget {
  final TileSet tileSet;

  /// The step to start with (1-based; screenshots).
  final int initialStep;

  const BenchCoach({super.key, required this.tileSet, this.initialStep = 1});

  static const int steps = 3;

  @override
  State<BenchCoach> createState() => _BenchCoachState();
}

class _BenchCoachState extends State<BenchCoach> {
  late int _step = widget.initialStep;

  /// A sample word on sample tiles (the tile set's language).
  String get _word => widget.tileSet.id == 'de' ? 'WORT' : 'WORD';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = WordTilesColors.of(context);
    final last = _step == BenchCoach.steps;
    final text = switch (_step) {
      1 => l10n.wordtilesCoachBench1,
      2 => l10n.wordtilesCoachBench2,
      _ => l10n.wordtilesCoachBench3,
    };
    final word = _word.split('');
    final score = word.fold(0, (a, l) => a + widget.tileSet.pointsOf(l));

    // The picture: a little bench row with the sample word; step 2 adds its
    // score, step 3 the "all back" button.
    final tiles = Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, l) in word.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            LetterTile(letter: l, points: widget.tileSet.pointsOf(l), size: 34),
          ],
          if (_step == 2) ...[
            const SizedBox(width: 10),
            Text('$score', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ],
      ),
    );
    final picture = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.board.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.tileEdge.withValues(alpha: 0.35)),
      ),
      child: _step == 3
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                tiles,
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.secondaryContainer),
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.vertical_align_bottom, color: theme.colorScheme.onSecondaryContainer),
                ),
              ],
            )
          : tiles,
    );

    return AlertDialog(
      key: const Key('wordtiles-coach'),
      title: Row(
        children: [
          Expanded(child: Text(l10n.wordtilesBench)),
          Text(
            l10n.wordtilesCoachStep(_step, BenchCoach.steps),
            key: Key('wordtiles-coach-step-$_step'),
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: picture),
          const SizedBox(height: 16),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
      actions: [
        if (!last)
          TextButton(
            key: const Key('wordtiles-coach-skip'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.wordtilesCoachSkip),
          ),
        FilledButton(
          key: Key(last ? 'wordtiles-coach-done' : 'wordtiles-coach-next'),
          onPressed: () => last ? Navigator.of(context).pop() : setState(() => _step++),
          child: Text(last ? l10n.wordtilesCoachDone : l10n.wordtilesCoachNext),
        ),
      ],
    );
  }
}
