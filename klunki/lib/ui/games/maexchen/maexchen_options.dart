import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../platform/shake.dart';
import '../../../profile/shake_settings.dart';
import '../../game_titles.dart';

/// The start options of a Mäxchen game (KLD-121): lives per player (3 or 5),
/// right under it the rule variant "Unbegrenzte Leben" (off by default,
/// KLD-121 step 2; while on, the lives cannot be chosen: nobody drops out),
/// and the house rule "Mäxchen doppelt" (on by default). On a device that
/// may have a motion sensor the dialog also shows the device setting
/// "Schütteln zum Würfeln" ([ShakeSettings], stored at once, not part of the
/// game's config).
typedef MaexchenOptions = ({int lives, bool double, bool unlimited});

const MaexchenOptions defaultMaexchenOptions = (lives: MaexchenGame.defaultLives, double: true, unlimited: false);

/// Asks for the lives, "Unbegrenzte Leben" and "Mäxchen doppelt" before a
/// game; null when cancelled. Keys: `maexchen-options`,
/// `maexchen-lives-<n>`, `maexchen-unlimited`, `maexchen-double`,
/// `maexchen-shake`, `maexchen-options-next`, `maexchen-options-cancel`.
Future<MaexchenOptions?> showMaexchenOptionsDialog(BuildContext context) => showDialog<MaexchenOptions>(
      context: context,
      builder: (_) => const _MaexchenOptionsDialog(),
    );

class _MaexchenOptionsDialog extends StatefulWidget {
  const _MaexchenOptionsDialog();

  @override
  State<_MaexchenOptionsDialog> createState() => _MaexchenOptionsDialogState();
}

class _MaexchenOptionsDialogState extends State<_MaexchenOptionsDialog> {
  MaexchenOptions _options = defaultMaexchenOptions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('maexchen-options'),
      title: Text(localizedGameTitle(l10n, 'maexchen', fallback: 'Mäxchen')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.maexchenOptionLives,
            style: theme.textTheme.titleSmall?.copyWith(
              color: _options.unlimited ? theme.colorScheme.onSurface.withValues(alpha: 0.45) : null,
            ),
          ),
          const SizedBox(height: 8),
          // "Unbegrenzte Leben" on: nobody drops out, the count does not
          // matter (shown greyed, not chosen).
          SegmentedButton<int>(
            key: const Key('maexchen-lives'),
            segments: [
              for (final n in MaexchenGame.livesOptions)
                ButtonSegment(
                  value: n,
                  icon: Icon(
                    Icons.favorite,
                    color: _options.unlimited ? theme.colorScheme.outline : const Color(0xFFD32F2F),
                  ),
                  label: Text('$n', key: Key('maexchen-lives-$n')),
                ),
            ],
            selected: {_options.lives},
            showSelectedIcon: false,
            onSelectionChanged: _options.unlimited
                ? null
                : (s) => setState(() => _options = (lives: s.single, double: _options.double, unlimited: false)),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('maexchen-unlimited'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.all_inclusive),
            title: Text(l10n.maexchenOptionUnlimited),
            value: _options.unlimited,
            onChanged: (v) => setState(() => _options = (lives: _options.lives, double: _options.double, unlimited: v)),
          ),
          Text(l10n.maexchenOptionUnlimitedExplain, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          SwitchListTile(
            key: const Key('maexchen-double'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.maexchenOptionDouble),
            value: _options.double,
            onChanged: (v) =>
                setState(() => _options = (lives: _options.lives, double: v, unlimited: _options.unlimited)),
          ),
          Text(l10n.maexchenOptionDoubleExplain, style: theme.textTheme.bodySmall),
          if (Motion.maybeAvailable) ...[
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: ShakeSettings.shared(),
              builder: (context, _) => SwitchListTile(
                key: const Key('maexchen-shake'),
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.vibration),
                title: Text(l10n.shakeToRollSetting),
                value: ShakeSettings.shared().enabled,
                onChanged: (v) {
                  // A tap: the web on iOS may ask for motion access now.
                  if (v) Motion.askPermission();
                  ShakeSettings.shared().setEnabled(v);
                },
              ),
            ),
            Text(l10n.shakeToRollExplain, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('maexchen-options-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.shellCancel),
        ),
        FilledButton(
          key: const Key('maexchen-options-next'),
          onPressed: () => Navigator.of(context).pop(_options),
          child: Text(l10n.maexchenOptionsNext),
        ),
      ],
    );
  }
}
