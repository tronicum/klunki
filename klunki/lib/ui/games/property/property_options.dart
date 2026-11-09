import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' show PropertyFreeSquare, PropertyGame, PropertyOptions, PropertyTheme;

import '../../../profile/undo_settings.dart';
import '../../game_titles.dart';
import 'property_screen.dart' show PropertyNames;

/// The start options of a Baulöwe game (KLD-060): the board (Berlin or
/// Fantasiestadt), the game length (30 rounds by default in the app until
/// players can trade, see [propertyAppDefaults]; 20 / 40 rounds or "bis nur
/// noch einer übrig ist"), the rule variants (free square:
/// nothing / pot / pot + 500 / fixed 200; "Doppeltes Startgeld", "Keine
/// Miete in der Pause", "Versteigerung bei Pleite", all off by default) and
/// the device setting "Zug zurücknehmen erlauben". Then "Wer spielt?" asks
/// for the player count (2–4) and the names.
///
/// Keys: `property-options`, `property-theme-<id>`, `property-rounds-<0|20|30|40>`,
/// `property-free-<rule>`, `property-double-start`, `property-no-rent-in-pause`,
/// `property-bankrupt-auction`, `property-undo`, `property-options-next`,
/// `property-options-cancel`.
Future<PropertyOptions?> showPropertyOptionsDialog(BuildContext context) => showDialog<PropertyOptions>(
      context: context,
      builder: (_) => const _PropertyOptionsDialog(),
    );

/// The round limits offered next to "until one is left" (maintainer
/// decision, KLD-060).
const List<int> propertyRoundChoices = [20, 30, 40];

/// What the app starts with (maintainer decision 2026-11-09): 30 rounds,
/// because without a trade screen (KLD-060 step 3b) the players rarely get a
/// whole group, and a game until one is left can go on for hours. The engine
/// default stays "until one is left" (no round limit). The rules page shows
/// these from the menu.
const PropertyOptions propertyAppDefaults = PropertyOptions(rounds: 30);

class _PropertyOptionsDialog extends StatefulWidget {
  const _PropertyOptionsDialog();

  @override
  State<_PropertyOptionsDialog> createState() => _PropertyOptionsDialogState();
}

class _PropertyOptionsDialogState extends State<_PropertyOptionsDialog> {
  String _theme = PropertyTheme.defaultId;
  int? _rounds = propertyAppDefaults.rounds;
  PropertyFreeSquare _free = PropertyFreeSquare.none;
  bool _doubleStart = false;
  bool _noRentInPause = false;
  bool _bankruptAuction = false;

  PropertyOptions get _options => PropertyOptions(
        theme: _theme == PropertyTheme.defaultId ? null : _theme,
        rounds: _rounds,
        free: _free,
        doubleStart: _doubleStart,
        noRentInPause: _noRentInPause,
        bankruptAuction: _bankruptAuction,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String money(int a) => l10n.propertyMoney(a);
    final board = PropertyTheme.byId(_theme)!;
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(text, style: theme.textTheme.titleSmall),
        );
    Widget choice(Key key, String label, bool selected, VoidCallback onTap, {IconData? icon}) => ListTile(
          key: key,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          selected: selected,
          selectedTileColor: theme.colorScheme.secondaryContainer,
          leading: icon == null ? null : Icon(icon),
          title: Text(label),
          trailing: selected ? const Icon(Icons.check_circle) : const Icon(Icons.circle_outlined),
          onTap: onTap,
        );
    Widget toggle(Key key, String title, String explain, bool value, ValueChanged<bool> onChanged) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: key,
              contentPadding: EdgeInsets.zero,
              title: Text(title),
              value: value,
              onChanged: onChanged,
            ),
            Text(explain, style: theme.textTheme.bodySmall),
          ],
        );
    return AlertDialog(
      key: const Key('property-options'),
      title: Text(localizedGameTitle(l10n, 'property', fallback: 'Baulöwe')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading(l10n.propertyOptionsBoard),
          // Two boards side by side.
          SegmentedButton<String>(
            segments: [
              for (final t in PropertyTheme.builtIn)
                ButtonSegment(
                    value: t.id,
                    label: Text(PropertyNames.themeTitle(l10n, t), key: Key('property-theme-${t.id}'))),
            ],
            selected: {_theme},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _theme = s.single),
          ),
          const SizedBox(height: 4),
          Text(l10n.propertyThemeGermanNote, style: theme.textTheme.bodySmall),
          heading(l10n.propertyOptionsLength),
          choice(const Key('property-rounds-0'), l10n.propertyOptionsUntilEnd, _rounds == null,
              () => setState(() => _rounds = null),
              icon: Icons.all_inclusive),
          for (final r in propertyRoundChoices)
            choice(Key('property-rounds-$r'), l10n.propertyOptionsRounds(r), _rounds == r, () => setState(() => _rounds = r),
                icon: Icons.timelapse),
          const SizedBox(height: 4),
          Text(l10n.propertyOptionsRoundsExplain, style: theme.textTheme.bodySmall),
          heading(l10n.propertyOptionsVariants),
          Text(l10n.propertyFreeTitle(board.squares[20].name), style: theme.textTheme.labelLarge),
          for (final (rule, label) in [
            (PropertyFreeSquare.none, l10n.propertyFreeNone),
            (PropertyFreeSquare.pot, l10n.propertyFreePot),
            (PropertyFreeSquare.potWithSeed,
                l10n.propertyFreePotSeed(money(PropertyGame.defaultFreeSquareAmount(PropertyFreeSquare.potWithSeed)))),
            (PropertyFreeSquare.fixedBonus,
                l10n.propertyFreeBonus(money(PropertyGame.defaultFreeSquareAmount(PropertyFreeSquare.fixedBonus)))),
          ])
            choice(Key('property-free-${rule.name}'), label, _free == rule, () => setState(() => _free = rule)),
          if (_free == PropertyFreeSquare.pot || _free == PropertyFreeSquare.potWithSeed)
            Text(l10n.propertyFreeExplain, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          toggle(const Key('property-double-start'), l10n.propertyRuleDoubleStart,
              l10n.propertyRuleDoubleStartExplain(money(2 * PropertyGame.startSalary)), _doubleStart,
              (v) => setState(() => _doubleStart = v)),
          toggle(const Key('property-no-rent-in-pause'), l10n.propertyRuleNoRentInPause, l10n.propertyRuleNoRentInPauseExplain,
              _noRentInPause, (v) => setState(() => _noRentInPause = v)),
          toggle(const Key('property-bankrupt-auction'), l10n.propertyRuleBankruptAuction,
              l10n.propertyRuleBankruptAuctionExplain, _bankruptAuction, (v) => setState(() => _bankruptAuction = v)),
          const SizedBox(height: 12),
          // KLD-117 follow-up: "Zug zurücknehmen erlauben" (stored at once).
          ListenableBuilder(
            listenable: UndoSettings.shared(),
            builder: (context, _) => SwitchListTile(
              key: const Key('property-undo'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.undo),
              title: Text(l10n.undoAllowedSetting),
              value: UndoSettings.shared().allowed('property'),
              onChanged: (v) => UndoSettings.shared().setAllowed('property', v),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('property-options-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.shellCancel),
        ),
        FilledButton(
          key: const Key('property-options-next'),
          onPressed: () => Navigator.of(context).pop(_options),
          child: Text(l10n.maexchenOptionsNext),
        ),
      ],
    );
  }
}
