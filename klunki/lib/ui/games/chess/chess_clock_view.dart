import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../transport/game_clock.dart';

/// Short name of a time control: "Ohne Uhr", "5 Min", "15 Min + 10 s"
/// (KLD-126).
String chessClockName(AppLocalizations l10n, ChessTimeControl? control) {
  if (control == null) return l10n.chessClockNone;
  final minutes = control.baseMs ~/ 60000;
  final seconds = control.incrementMs ~/ 1000;
  return seconds == 0 ? l10n.chessClockMinutes(minutes) : l10n.chessClockMinutesIncrement(minutes, seconds);
}

/// What a clock shows for [ms]: `m:ss` (`h:mm:ss` from an hour on), under
/// 10 s seconds with tenths (`9.4`), never below `0.0`.
String formatChessClock(int ms) {
  if (ms <= 0) return '0.0';
  if (ms < 10000) return '${ms ~/ 1000}.${(ms % 1000) ~/ 100}';
  final total = (ms + 999) ~/ 1000; // a started second still shows
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// "Schachuhr": Ohne Uhr / 5 Min / 10 Min / 15 Min + 10 s / 30 Min as chips
/// (KLD-126), for "Wer spielt?" and "Raum starten". Keys:
/// `<keyPrefix>none` and `<keyPrefix><id>` (e.g. `chess-clock-900+10`).
class ChessClockPicker extends StatelessWidget {
  final ChessTimeControl? value;
  final ValueChanged<ChessTimeControl?> onChanged;
  final bool enabled;
  final String keyPrefix;

  const ChessClockPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.keyPrefix = 'chess-clock-',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget chip(ChessTimeControl? c) => ChoiceChip(
          key: Key('$keyPrefix${c?.id ?? 'none'}'),
          avatar: c == null ? null : const Icon(Icons.timer_outlined, size: 18),
          label: Text(chessClockName(l10n, c)),
          selected: value == c,
          onSelected: enabled ? (_) => onChanged(c) : null,
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.chessClockLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [chip(null), for (final c in ChessTimeControl.presets) chip(c)],
        ),
        const SizedBox(height: 4),
        Text(l10n.chessClockHelper, key: Key('${keyPrefix}helper'), style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// One player's clock next to the board (KLD-126): the remaining time,
/// highlighted while it runs, red with tenths under 10 s, a pause sign
/// while the clocks stand still. Repaints by itself while it runs (each
/// second, each tenth under 10 s). Key `chess-clock-<a|b>`.
class ChessClockFace extends StatefulWidget {
  final ClockedTransport transport;
  final Player player;

  /// The player's name for screen readers.
  final String playerLabel;

  const ChessClockFace({super.key, required this.transport, required this.player, required this.playerLabel});

  @override
  State<ChessClockFace> createState() => _ChessClockFaceState();
}

class _ChessClockFaceState extends State<ChessClockFace> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    widget.transport.clockChanges.addListener(_changed);
  }

  @override
  void didUpdateWidget(ChessClockFace old) {
    super.didUpdateWidget(old);
    if (!identical(old.transport, widget.transport)) {
      old.transport.clockChanges.removeListener(_changed);
      widget.transport.clockChanges.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    widget.transport.clockChanges.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  /// Sets the timer for the next change of the shown text.
  void _schedule(ChessClock clock, int ms) {
    _tick?.cancel();
    _tick = null;
    if (!clock.ticking || clock.running != widget.player || ms <= 0) return;
    final step = ms <= 10000 ? (ms % 100 == 0 ? 100 : ms % 100) : (ms % 1000 == 0 ? 1000 : ms % 1000);
    _tick = Timer(Duration(milliseconds: step), _changed);
  }

  @override
  Widget build(BuildContext context) {
    final clock = widget.transport.clock;
    if (clock == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ms = clock.remainingOf(widget.player, widget.transport.clockNow());
    _schedule(clock, ms);
    final running = clock.running == widget.player;
    final low = ms < 10000;
    final stopped = running && !clock.ticking;
    final background = running ? (low ? scheme.error : scheme.primary) : scheme.surfaceContainerHighest;
    final foreground = running ? (low ? scheme.onError : scheme.onPrimary) : (low ? scheme.error : scheme.onSurface);
    final text = formatChessClock(ms);
    return Semantics(
      label: l10n.chessClockSemantics(widget.playerLabel, text),
      excludeSemantics: true,
      child: AnimatedContainer(
        key: Key('chess-clock-${widget.player.name}'),
        duration: const Duration(milliseconds: 150),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: running ? null : Border.all(color: low ? scheme.error : scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            Icon(stopped ? Icons.pause : Icons.timer_outlined, size: 16, color: foreground),
            const SizedBox(width: 4),
            Text(
              text,
              key: Key('chess-clock-text-${widget.player.name}'),
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
