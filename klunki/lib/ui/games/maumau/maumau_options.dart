import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' show MauMauRules;

import '../../game_titles.dart';

/// Asks for the Mau-Mau house rules before a game (KLD-118); null when
/// cancelled. Starts from [initial] (the defaults: 7 draws two, 7 on 7, 8
/// skips; no jack on a jack, no ace rule, no "Mau" call).
///
/// Keys: `maumau-options`, `maumau-rule-<name>` (switches: `seven`,
/// `stack`, `eight`, `jackOnJack`, `ace`, `mau`, `mustPlay`), `maumau-jack-info`,
/// `maumau-options-next`, `maumau-options-cancel`.
Future<MauMauRules?> showMauMauOptionsDialog(BuildContext context, {MauMauRules initial = const MauMauRules()}) =>
    showDialog<MauMauRules>(
      context: context,
      builder: (_) => _MauMauOptionsDialog(initial: initial),
    );

class _MauMauOptionsDialog extends StatefulWidget {
  final MauMauRules initial;
  const _MauMauOptionsDialog({required this.initial});

  @override
  State<_MauMauOptionsDialog> createState() => _MauMauOptionsDialogState();
}

class _MauMauOptionsDialogState extends State<_MauMauOptionsDialog> {
  late MauMauRules _rules = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      key: const Key('maumau-options'),
      title: Text(localizedGameTitle(l10n, 'maumau', fallback: 'Mau-Mau')),
      scrollable: true,
      content: MauMauOptionsPicker(value: _rules, onChanged: (r) => setState(() => _rules = r)),
      actions: [
        TextButton(
          key: const Key('maumau-options-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.shellCancel),
        ),
        FilledButton(
          key: const Key('maumau-options-next'),
          onPressed: () => Navigator.of(context).pop(_rules),
          child: Text(l10n.maumauOptionsNext),
        ),
      ],
    );
  }
}

/// The house-rule switches, each with a line that explains it, and the
/// fixed jack rule as a plain line.
class MauMauOptionsPicker extends StatelessWidget {
  final MauMauRules value;
  final ValueChanged<MauMauRules> onChanged;
  const MauMauOptionsPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget rule(String key, String title, String explain, bool on, ValueChanged<bool>? change) => SwitchListTile(
      key: Key('maumau-rule-$key'),
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(explain),
      value: on,
      onChanged: change,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.maumauOptionsIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        rule(
          'seven',
          l10n.maumauOptionSeven,
          l10n.maumauOptionSevenExplain,
          value.sevenDraws,
          (v) => onChanged(value.copyWith(sevenDraws: v)),
        ),
        rule(
          'stack',
          l10n.maumauOptionStack,
          l10n.maumauOptionStackExplain,
          value.sevenDraws && value.stackSevens,
          value.sevenDraws ? (v) => onChanged(value.copyWith(stackSevens: v)) : null,
        ),
        rule(
          'eight',
          l10n.maumauOptionEight,
          l10n.maumauOptionEightExplain,
          value.eightSkips,
          (v) => onChanged(value.copyWith(eightSkips: v)),
        ),
        Padding(
          key: const Key('maumau-jack-info'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(l10n.maumauOptionJackInfo, style: theme.textTheme.bodySmall),
        ),
        rule(
          'jackOnJack',
          l10n.maumauOptionJackOnJack,
          l10n.maumauOptionJackOnJackExplain,
          value.jackOnJack,
          (v) => onChanged(value.copyWith(jackOnJack: v)),
        ),
        rule(
          'ace',
          l10n.maumauOptionAce,
          l10n.maumauOptionAceExplain,
          value.aceAgain,
          (v) => onChanged(value.copyWith(aceAgain: v)),
        ),
        rule(
          'mau',
          l10n.maumauOptionMau,
          l10n.maumauOptionMauExplain,
          value.mauCall,
          (v) => onChanged(value.copyWith(mauCall: v)),
        ),
        rule(
          'mustPlay',
          l10n.maumauOptionMustPlay,
          l10n.maumauOptionMustPlayExplain,
          value.mustPlay,
          (v) => onChanged(value.copyWith(mustPlay: v)),
        ),
      ],
    );
  }
}
