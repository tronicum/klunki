import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

import '../profile/player_name_controller.dart';
import '../profile/seat_names.dart';
import 'player_name_dialog.dart' show playerNameInputFormatters;
import 'shell/seat_labels.dart';

/// "Wer spielt?" for a game of 2–4 players on one device (KLD-119): how many
/// play (2 · 3 · 4, starting with the last choice) and a name per player,
/// prefilled with the names in use (the last typed ones, else the regional
/// default names). Players 1 and 2 are saved to the two-player store
/// ([PlayerNameScope.hotSeat]), players 3 and 4 and the count to
/// [ExtraSeatNames]; a field left empty or holding the default name stores
/// no name. Completes with the player count, or null when cancelled.
///
/// [players] fixed: the in-game "Spielernamen" dialog of a running game (no
/// count choice, OK / Cancel).
///
/// [reorder] (KLD-119 follow-up, "Reihenfolge festlegen"): arrows beside
/// each name move it up or down; the order of the names is the seat order
/// (seat 1 starts). [randomStart]: the first name is not said to start.
///
/// Keys as the two-player dialog (`hot-seat-start-dialog` /
/// `hot-seat-names-dialog`, `hot-seat-names-ok`, `hot-seat-names-cancel`),
/// plus `seat-players-<n>`, `seat-name-<seat>`, `seat-up-<seat>` and
/// `seat-down-<seat>`.
Future<int?> showSeatPlayersDialog(
  BuildContext context, {
  int? players,
  bool reorder = false,
  bool randomStart = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final two = PlayerNameScope.maybeOf(context)?.hotSeat;
  final extra = ExtraSeatNames.shared();
  final current = [two?.value.x, two?.value.o, extra.nameOf(2), extra.nameOf(3)];
  final result = await showDialog<({int players, List<String> names})>(
    context: context,
    builder: (_) => _SeatPlayersDialog(
      names: [for (var s = 0; s < 4; s++) current[s] ?? defaultSeatName(l10n, s)],
      players: players ?? extra.players,
      fixed: players != null,
      reorder: reorder,
      randomStart: randomStart,
    ),
  );
  if (result == null) return null;
  // The default name is not stored: it follows the app language.
  String? typed(int seat) {
    final s = sanitizePlayerName(result.names[seat]);
    return s.isEmpty || s == defaultSeatName(l10n, seat) ? null : s;
  }

  await two?.setNames(typed(0), typed(1));
  await extra.set(
    third: result.players > 2 ? typed(2) : extra.nameOf(2),
    fourth: result.players > 3 ? typed(3) : extra.nameOf(3),
    players: players == null ? result.players : null,
  );
  return result.players;
}

class _SeatPlayersDialog extends StatefulWidget {
  final List<String> names;
  final int players;
  final bool fixed;
  final bool reorder;
  final bool randomStart;
  const _SeatPlayersDialog({
    required this.names,
    required this.players,
    required this.fixed,
    this.reorder = false,
    this.randomStart = false,
  });

  @override
  State<_SeatPlayersDialog> createState() => _SeatPlayersDialogState();
}

class _SeatPlayersDialogState extends State<_SeatPlayersDialog> {
  late final List<TextEditingController> _fields = [for (final n in widget.names) TextEditingController(text: n)];
  late int _players = widget.players;

  @override
  void dispose() {
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  /// Swaps the names of [seat] and [other] (the arrows).
  void _swap(int seat, int other) => setState(() {
    final t = _fields[seat].text;
    _fields[seat].text = _fields[other].text;
    _fields[other].text = t;
  });

  void _ok() => Navigator.of(context).pop((players: _players, names: [for (final f in _fields) f.text]));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    Widget arrow(int seat, int other, IconData icon, String key, String tip) => IconButton(
      key: Key('$key-$seat'),
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon),
      onPressed: other < 0 || other >= _players ? null : () => _swap(seat, other),
    );
    Widget field(int seat) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: input(seat)),
          if (widget.reorder) ...[
            arrow(seat, seat - 1, Icons.arrow_upward, 'seat-up', l10n.seatMoveUp),
            arrow(seat, seat + 1, Icons.arrow_downward, 'seat-down', l10n.seatMoveDown),
          ],
        ],
      ),
    );
    return _dialog(context, l10n, material, theme, field);
  }

  Widget input(int seat) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      key: Key('seat-name-$seat'),
      controller: _fields[seat],
      inputFormatters: playerNameInputFormatters,
      decoration: InputDecoration(
        labelText: l10n.hotSeatNameLabel(seat + 1),
        helperText: seat == 0 ? (widget.randomStart ? l10n.seatRandomStartHint : l10n.hotSeatStartsHint) : null,
        hintText: defaultSeatName(l10n, seat),
        isDense: true,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: SeatToken(seat: seat, size: 24),
        ),
      ),
      textInputAction: seat == _players - 1 ? TextInputAction.done : TextInputAction.next,
      onSubmitted: seat == _players - 1 ? (_) => _ok() : null,
    );
  }

  Widget _dialog(
    BuildContext context,
    AppLocalizations l10n,
    MaterialLocalizations material,
    ThemeData theme,
    Widget Function(int) field,
  ) {
    return AlertDialog(
      key: Key(widget.fixed ? 'hot-seat-names-dialog' : 'hot-seat-start-dialog'),
      title: Text(widget.fixed ? l10n.hotSeatNamesTitle : l10n.hotSeatStartTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.fixed) ...[
            Text(l10n.seatPlayerCount, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                for (final n in const [2, 3, 4])
                  ButtonSegment(
                    value: n,
                    icon: const Icon(Icons.person_outline),
                    label: Text('$n', key: Key('seat-players-$n')),
                  ),
              ],
              selected: {_players},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _players = s.single),
            ),
            const SizedBox(height: 16),
          ],
          for (var s = 0; s < _players; s++) field(s),
          const SizedBox(height: 4),
          if (widget.reorder) ...[
            Text(l10n.seatOrderHint, key: const Key('seat-order-hint'), style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
          ],
          Text(l10n.hotSeatNamesHelper, style: theme.textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('hot-seat-names-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('hot-seat-names-ok'),
          onPressed: _ok,
          child: Text(widget.fixed ? material.okButtonLabel : l10n.hotSeatStartPlay),
        ),
      ],
    );
  }
}
