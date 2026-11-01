import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../app/theme.dart';
import '../game_titles.dart';
import '../game_visuals.dart';
import '../shell/screen_registry.dart' show networkGameSpecs;

/// The game of a room on "Raum starten" (app and relay screens).
///
/// Not [fixed]: "Spiel wählen" with a radio button per network game
/// (`<keyPrefix><id>`). [fixed] (KLD-105: the room was started from a game
/// tile's "Mit anderen" link): the chosen game only, as a small tile with its
/// illustration and one-liner (`<keyPrefix>fixed`); no choice to make.
class RoomGameChoice extends StatelessWidget {
  final String gameId;
  final bool fixed;
  final bool enabled;
  final String keyPrefix;
  final ValueChanged<String> onChanged;

  const RoomGameChoice({
    super.key,
    required this.gameId,
    required this.fixed,
    required this.enabled,
    required this.keyPrefix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (fixed) return _FixedGame(key: Key('${keyPrefix}fixed'), gameId: gameId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.pairingChooseGame, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: gameId,
          onChanged: (v) {
            if (v != null && enabled) onChanged(v);
          },
          child: Column(
            children: [
              for (final spec in networkGameSpecs)
                RadioListTile<String>(
                  key: Key('$keyPrefix${spec.id}'),
                  value: spec.id,
                  title: Text(localizedGameTitle(l10n, spec.id, fallback: spec.title)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FixedGame extends StatelessWidget {
  final String gameId;
  const _FixedGame({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final palette = KlunkiPalette.of(context);
    final accent = palette.accent(gameId);
    final visuals = visualsOf(gameId);
    final description = visuals.description?.call(l10n);
    return Card(
      margin: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 88,
              decoration: BoxDecoration(
                color: accent.container,
                border: BorderDirectional(end: BorderSide(color: accent.color, width: 3)),
              ),
              padding: const EdgeInsets.all(10),
              child: ExcludeSemantics(child: CustomPaint(painter: visuals.illustration(palette))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizedGameTitle(l10n, gameId, fallback: specById(gameId)?.title ?? gameId),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
