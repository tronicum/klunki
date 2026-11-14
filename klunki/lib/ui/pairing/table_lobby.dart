import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_net/klunki_net.dart' show TableSeat;

import '../../app/theme.dart';
import '../../transport/network_transport.dart';
import '../ltr.dart';
import '../shell/seat_labels.dart';

/// Games that a room can hold for 3–4 players (KLD-088 step 4).
const tableGames = {'wordtiles'};

/// "Wie viele spielen mit?" 2 · 3 · 4 when starting a room (KLD-088 step 4),
/// keys `<keyPrefix>players-<n>`.
class RoomPlayerCountPicker extends StatelessWidget {
  final int value;
  final bool enabled;
  final String keyPrefix;
  final ValueChanged<int> onChanged;

  const RoomPlayerCountPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.keyPrefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.seatPlayerCount, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        SegmentedButton<int>(
          segments: [
            for (final n in const [2, 3, 4])
              ButtonSegment(
                value: n,
                icon: const Icon(Icons.person_outline),
                label: Text('$n', key: Key('${keyPrefix}players-$n')),
              ),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: enabled ? (s) => onChanged(s.single) : null,
        ),
      ],
    );
  }
}

/// The names of a table's seats for the game shell; this device's seat is
/// [SeatLabels.local] ("Du bist am Zug").
/// While the table waits for someone who is away, [SeatLabels.paused].
SeatLabels tableSeatLabels(NetworkTransport t) =>
    SeatLabels([for (final s in t.seats) s.name], t.seat, t.paused);

/// A table's lobby (KLD-088 step 4): every seat with its token and name
/// ("Du: Anna" for this device, "Platz frei", "nicht verbunden") and, until
/// every seat is taken, "Warte auf noch 2 Mitspieler…". Once it is full,
/// "Alle sind da!" and the host's countdown 5 … 1 above the seats
/// ([TableCountdown]). Rebuilds with the transport. Keys `table-lobby`,
/// `table-seat-<n>`, `table-waiting`.
class TableLobby extends StatelessWidget {
  final NetworkTransport transport;
  const TableLobby({super.key, required this.transport});

  @override
  Widget build(BuildContext context) {
    final t = transport;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: t.changes,
      builder: (context, _) {
        final seats = t.seats;
        final missing = seats.where((s) => s.free).length;
        return Column(
          key: const Key('table-lobby'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (t.countdown case final n? when !t.started) ...[
              TableCountdown(count: n),
              const SizedBox(height: 16),
            ],
            Text(l10n.tableLobbyTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (var i = 0; i < seats.length; i++) _row(context, l10n, theme, i, seats[i]),
            if (missing > 0 && !t.started) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Flexible(child: Text(l10n.tableWaitingFor(missing), key: const Key('table-waiting'))),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, AppLocalizations l10n, ThemeData theme, int seat, TableSeat s) {
    final name = s.name == null ? null : bidiName(context, s.name!);
    final mine = seat == transport.seat;
    final text = name == null
        ? l10n.tableSeatFree
        : mine
            ? l10n.netBarYou(name)
            : name;
    return Padding(
      key: Key('table-seat-$seat'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SeatToken(seat: seat, out: s.free || !s.here),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: s.free
                  ? theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                  : theme.textTheme.bodyLarge?.copyWith(fontWeight: mine ? FontWeight.w600 : null),
            ),
          ),
          if (!s.free && !s.here) ...[
            const SizedBox(width: 8),
            Text(l10n.tableSeatAway, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

/// "Alle sind da!" and the number of the countdown to the start of a table
/// (KLD-088), big and round in the room's colour; the number pops in at
/// every step. Keys `table-countdown`, `table-countdown-number`.
class TableCountdown extends StatelessWidget {
  /// The steps left, 5 … 1, as the host counts.
  final int count;
  const TableCountdown({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final still = reduceMotion(context);
    return Semantics(
      key: const Key('table-countdown'),
      liveRegion: true,
      label: '${l10n.tableAllHere} ${l10n.tableStartsIn} $count',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tableAllHere,
            key: const Key('table-all-here'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary),
          ),
          const SizedBox(height: 4),
          Text(l10n.tableStartsIn, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          Center(
            child: AnimatedSwitcher(
              duration: still ? Duration.zero : const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Container(
                key: ValueKey(count),
                width: 112,
                height: 112,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                child: Text(
                  '$count',
                  key: const Key('table-countdown-number'),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
