import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

import '../../../platform/shake.dart';
import '../../../profile/beginner_settings.dart';
import '../../../profile/shake_settings.dart';
import '../../game_titles.dart';

/// The start options of an Ausgewürfelt game (KLD-119): the house rule
/// "Extra-Fünfer" (off by default) and, on a device that may have a motion
/// sensor, the device setting "Schütteln zum Würfeln" ([ShakeSettings],
/// stored at once, shared with Mäxchen), the device setting
/// "Anfängermodus" and "Tipps" ([BeginnerSettings], stored at once), and "Wer fängt an?"
/// ([DiceSheetStart]). Then "Wer spielt?" asks for the player count and the
/// names (with arrows to reorder them for [DiceSheetStart.order]).
typedef DiceSheetOptions = ({bool extraFives, DiceSheetStart start});

/// "Wer fängt an?" (KLD-119 follow-up): the first name of the list
/// (default), the players' own order (set in "Wer spielt?"), or chance
/// ([GameConfig.randomStart]).
enum DiceSheetStart { first, order, random }

/// Asks for the options before a game; null when cancelled. Keys:
/// `dicesheet-options`, `dicesheet-extra-fives`, `dicesheet-shake`, `dicesheet-beginner`,
/// `dicesheet-tips`, `dicesheet-options-next`, `dicesheet-options-cancel`, `dicesheet-start-<first|order|random>`.
Future<DiceSheetOptions?> showDiceSheetOptionsDialog(BuildContext context) => showDialog<DiceSheetOptions>(
      context: context,
      builder: (_) => const _DiceSheetOptionsDialog(),
    );

class _DiceSheetOptionsDialog extends StatefulWidget {
  const _DiceSheetOptionsDialog();

  @override
  State<_DiceSheetOptionsDialog> createState() => _DiceSheetOptionsDialogState();
}

class _DiceSheetOptionsDialogState extends State<_DiceSheetOptionsDialog> {
  bool _extraFives = false;
  DiceSheetStart _start = DiceSheetStart.first;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('dicesheet-options'),
      title: Text(localizedGameTitle(l10n, 'dicesheet', fallback: 'Ausgewürfelt')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const Key('dicesheet-extra-fives'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.dicesheetOptionExtraFives),
            value: _extraFives,
            onChanged: (v) => setState(() => _extraFives = v),
          ),
          Text(l10n.dicesheetOptionExtraFivesExplain, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: BeginnerSettings.shared(),
            builder: (context, _) => SwitchListTile(
              key: const Key('dicesheet-beginner'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.lightbulb_outline),
              title: Text(l10n.dicesheetBeginnerOption),
              value: BeginnerSettings.shared().enabled,
              onChanged: BeginnerSettings.shared().setEnabled,
            ),
          ),
          Text(l10n.dicesheetBeginnerExplain, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: BeginnerSettings.shared(),
            builder: (context, _) => SwitchListTile(
              key: const Key('dicesheet-tips'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.chat_bubble_outline),
              title: Text(l10n.dicesheetTipsOption),
              value: BeginnerSettings.shared().tips,
              onChanged: BeginnerSettings.shared().setTips,
            ),
          ),
          Text(l10n.dicesheetTipsExplain, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Text(l10n.dicesheetStartTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          // Three choices in a column: the labels are too long for a
          // segmented button on a phone.
          for (final (s, label, icon) in [
            (DiceSheetStart.first, l10n.dicesheetStartFirst, Icons.looks_one_outlined),
            (DiceSheetStart.order, l10n.dicesheetStartOrder, Icons.swap_vert),
            (DiceSheetStart.random, l10n.dicesheetStartRandom, Icons.casino_outlined),
          ])
            ListTile(
              key: Key('dicesheet-start-${s.name}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              selected: _start == s,
              selectedTileColor: theme.colorScheme.secondaryContainer,
              leading: Icon(icon),
              title: Text(label),
              trailing: _start == s ? const Icon(Icons.check_circle) : const Icon(Icons.circle_outlined),
              onTap: () => setState(() => _start = s),
            ),
          const SizedBox(height: 6),
          Text(
            switch (_start) {
              DiceSheetStart.first => l10n.dicesheetStartFirstExplain,
              DiceSheetStart.order => l10n.dicesheetStartOrderExplain,
              DiceSheetStart.random => l10n.dicesheetStartRandomExplain,
            },
            key: const Key('dicesheet-start-explain'),
            style: theme.textTheme.bodySmall,
          ),
          if (Motion.maybeAvailable) ...[
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: ShakeSettings.shared(),
              builder: (context, _) => SwitchListTile(
                key: const Key('dicesheet-shake'),
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
          key: const Key('dicesheet-options-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.shellCancel),
        ),
        FilledButton(
          key: const Key('dicesheet-options-next'),
          onPressed: () => Navigator.of(context).pop((extraFives: _extraFives, start: _start)),
          child: Text(l10n.maexchenOptionsNext),
        ),
      ],
    );
  }
}
