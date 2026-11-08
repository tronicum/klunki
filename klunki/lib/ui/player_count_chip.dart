import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import 'shell/screen_registry.dart';

/// How many play a game (KLD-124), as on a board-game box: a people icon
/// and "2" or "2–4" (en dash) in a small pill. The count comes from the
/// engine registry ([offeredPlayers]), never from the UI. The digits are
/// laid out left to right in every locale, so "2–4" does not turn into
/// "4–2" in ar/fa. Screen readers hear "2 Spieler" / "2 bis 4 Spieler".
///
/// Key: `player-count-<gameId>`.
class PlayerCountChip extends StatelessWidget {
  final GameSpec spec;
  const PlayerCountChip({super.key, required this.spec});

  /// The chip for [gameId], or nothing for an unknown id.
  static Widget forId(String gameId) {
    final spec = specById(gameId);
    return spec == null ? const SizedBox.shrink() : PlayerCountChip(spec: spec);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (:min, :max) = offeredPlayers(spec);
    final text = min == max ? '$min' : '$min–$max';
    final label = min == max ? l10n.playerCount(min) : l10n.playerCountRange(min, max);
    final fg = scheme.onSurface;
    return Semantics(
      key: Key('player-count-${spec.id}'),
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 8, 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_alt_outlined, size: 16, color: fg),
              const SizedBox(width: 4),
              Text(
                text,
                textDirection: TextDirection.ltr,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
