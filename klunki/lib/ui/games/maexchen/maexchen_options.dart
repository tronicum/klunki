import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../platform/shake.dart';
import '../../../profile/shake_settings.dart';
import '../../game_titles.dart';

/// The start options of a Mäxchen game (KLD-121): lives per player (3 or 5)
/// and the house rule "Mäxchen doppelt" (on by default). On a device that
/// may have a motion sensor the dialog also shows the device setting
/// "Schütteln zum Würfeln" ([ShakeSettings], stored at once, not part of the
/// game's config).
typedef MaexchenOptions = ({int lives, bool double});

const MaexchenOptions defaultMaexchenOptions = (lives: MaexchenGame.defaultLives, double: true);

/// Asks for the lives and "Mäxchen doppelt" before a game; null when
/// cancelled. Keys: `maexchen-options`, `maexchen-lives-<n>`,
/// `maexchen-double`, `maexchen-shake`, `maexchen-options-next`,
/// `maexchen-options-cancel`.
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
          Text(l10n.maexchenOptionLives, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              for (final n in MaexchenGame.livesOptions)
                ButtonSegment(
                  value: n,
                  icon: const Icon(Icons.favorite, color: Color(0xFFD32F2F)),
                  label: Text('$n', key: Key('maexchen-lives-$n')),
                ),
            ],
            selected: {_options.lives},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _options = (lives: s.single, double: _options.double)),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            key: const Key('maexchen-double'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.maexchenOptionDouble),
            value: _options.double,
            onChanged: (v) => setState(() => _options = (lives: _options.lives, double: v)),
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
