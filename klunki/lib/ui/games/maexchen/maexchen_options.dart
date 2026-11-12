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

/// The options that differ from the defaults (3 lives, "Mäxchen doppelt"
/// on) as one line ("5 Leben · ohne Mäxchen doppelt", "Unbegrenzte
/// Leben"); null with the defaults. The room of a network game and the
/// start of the game show what the host chose (KLD-121 network step; only
/// the changes since the network decisions 2026-11-12).
String? maexchenOptionsSummary(AppLocalizations l10n, GameConfig config) {
  final changed = [
    if (config.maexchenUnlimited)
      l10n.maexchenOptionUnlimited
    else if (config.lives != defaultMaexchenOptions.lives)
      l10n.maexchenSummaryLives(config.lives),
    if (config.maexchenDouble != defaultMaexchenOptions.double)
      config.maexchenDouble ? l10n.maexchenOptionDouble : l10n.roomRuleOff(l10n.maexchenOptionDouble),
  ];
  return changed.isEmpty ? null : changed.join(' · ');
}

/// The lives (3 or 5), "Unbegrenzte Leben" with its explanation and
/// "Mäxchen doppelt" with its explanation: in the start dialog and, for a
/// network game, on "Raum starten" (KLD-121 network step). Keys:
/// `<keyPrefix>lives`, `<keyPrefix>lives-<n>`, `<keyPrefix>unlimited`,
/// `<keyPrefix>double` (prefix `maexchen-` in the dialog).
class MaexchenOptionsPicker extends StatelessWidget {
  final MaexchenOptions value;
  final ValueChanged<MaexchenOptions> onChanged;
  final bool enabled;
  final String keyPrefix;

  const MaexchenOptionsPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.keyPrefix = 'maexchen-',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final o = value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.maexchenOptionLives,
          style: theme.textTheme.titleSmall?.copyWith(
            color: o.unlimited ? theme.colorScheme.onSurface.withValues(alpha: 0.45) : null,
          ),
        ),
        const SizedBox(height: 8),
        // "Unbegrenzte Leben" on: nobody drops out, the count does not
        // matter (shown greyed, not chosen).
        SegmentedButton<int>(
          key: Key('${keyPrefix}lives'),
          segments: [
            for (final n in MaexchenGame.livesOptions)
              ButtonSegment(
                value: n,
                icon: Icon(
                  Icons.favorite,
                  color: o.unlimited ? theme.colorScheme.outline : const Color(0xFFD32F2F),
                ),
                label: Text('$n', key: Key('${keyPrefix}lives-$n')),
              ),
          ],
          selected: {o.lives},
          showSelectedIcon: false,
          onSelectionChanged: o.unlimited || !enabled
              ? null
              : (s) => onChanged((lives: s.single, double: o.double, unlimited: false)),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: Key('${keyPrefix}unlimited'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.all_inclusive),
          title: Text(l10n.maexchenOptionUnlimited),
          value: o.unlimited,
          onChanged: enabled ? (v) => onChanged((lives: o.lives, double: o.double, unlimited: v)) : null,
        ),
        Text(l10n.maexchenOptionUnlimitedExplain, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        SwitchListTile(
          key: Key('${keyPrefix}double'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.maexchenOptionDouble),
          value: o.double,
          onChanged: enabled ? (v) => onChanged((lives: o.lives, double: v, unlimited: o.unlimited)) : null,
        ),
        Text(l10n.maexchenOptionDoubleExplain, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

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
          MaexchenOptionsPicker(value: _options, onChanged: (o) => setState(() => _options = o)),
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
