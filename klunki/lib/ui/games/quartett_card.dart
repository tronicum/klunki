import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' as qe show Card, QuartettGame, QuartettStat;

/// Shared Quartett card widgets (Trumpf screen KLD-024, Sets screen KLD-025).
///
/// The engine's `Card` clashes with Flutter's `Card`, so this file imports the
/// engine with the `qe` prefix; callers pass a `qe.Card` (any import style
/// works, it is the same type).

/// Header colour of a set letter `A`–`H` (grey for anything else).
Color quartettSetColor(String set) => switch (set) {
      'A' => const Color(0xFFC62828), // red
      'B' => const Color(0xFF6A1B9A), // purple
      'C' => const Color(0xFF8D6E63), // brown
      'D' => const Color(0xFFEF6C00), // orange
      'E' => const Color(0xFF2E7D32), // green
      'F' => const Color(0xFF1565C0), // blue
      'G' => const Color(0xFF00838F), // teal
      'H' => const Color(0xFFAD1457), // pink
      _ => const Color(0xFF616161),
    };

/// Display name of a set letter (e.g. `B` → "Hypercars").
String quartettSetName(String set) => qe.QuartettGame.setNames[set] ?? set;

/// A stat value with unit and the decimal separator of [locale] (default
/// German, decimal comma): `2,7 s`, `650 PS`. The unit comes from the engine.
///
/// Digits are always Western (0–9), like every other number in the app
/// (I18N-04): a locale whose default digits are not Western (fa: `۲٫۷`) falls
/// back to English formatting, so ints and decimals on one card match.
String formatQuartettValue(qe.QuartettStat stat, num value, {String locale = 'de'}) {
  var f = NumberFormat('0.0', locale);
  if (f.symbols.ZERO_DIGIT != '0') f = NumberFormat('0.0', 'en');
  final v = value is double ? f.format(value) : '$value';
  return '$v ${stat.unit}';
}

/// How a highlighted stat row came out in a trick.
enum QuartettOutcome { win, lose, tie }

/// Colour used for an outcome (green / red / grey).
Color quartettOutcomeColor(QuartettOutcome o) => switch (o) {
      QuartettOutcome.win => const Color(0xFF2E7D32),
      QuartettOutcome.lose => const Color(0xFFC62828),
      QuartettOutcome.tie => const Color(0xFF757575),
    };

/// A Quartett card, face-up ([QuartettCard.new]) or face-down
/// ([QuartettCard.back]).
///
/// Face-up: coloured header per set with the id badge ("B3"), set name and car
/// name, then one row per [qe.QuartettGame.stats] entry (label, value + unit,
/// ↑ "higher wins" / ↓ "lower wins").
///
/// * [onStatTap] makes the stat rows tappable (null = read-only); rows are
///   disabled again when [enabled] is false.
/// * [statKeyPrefix] gives each row the key `<prefix><statId>` (e.g.
///   `qt-stat-` → `qt-stat-ps`).
/// * [highlightStat] + [outcome] tint that row green/red/grey (trick reveal);
///   [highlightStat] alone tints it with the set colour (selection).
/// * [dense] uses smaller text for side-by-side layouts.
///
/// Face-down: patterned back with an optional [count] ("15 Karten") and
/// [label] (e.g. "O").
class QuartettCard extends StatelessWidget {
  final qe.Card? card;
  final void Function(qe.QuartettStat stat)? onStatTap;
  final bool enabled;
  final String? statKeyPrefix;
  final String? highlightStat;
  final QuartettOutcome? outcome;
  final bool dense;

  /// Back side only: number shown on the back ("15 Karten").
  final int? count;

  /// Back side only: caption on the back, e.g. the owner's mark.
  final String? label;

  /// Face-up card.
  const QuartettCard({
    super.key,
    required qe.Card this.card,
    this.onStatTap,
    this.enabled = true,
    this.statKeyPrefix,
    this.highlightStat,
    this.outcome,
    this.dense = false,
  })  : count = null,
        label = null;

  /// Face-down card (back side). Never reveals a card.
  const QuartettCard.back({super.key, this.count, this.label, this.dense = false})
      : card = null,
        onStatTap = null,
        enabled = false,
        statKeyPrefix = null,
        highlightStat = null,
        outcome = null;

  bool get isFaceDown => card == null;

  @override
  Widget build(BuildContext context) {
    final c = card;
    return c == null ? _buildBack(context) : _buildFront(context, c);
  }

  Widget _buildFront(BuildContext context, qe.Card c) {
    final theme = Theme.of(context);
    final color = quartettSetColor(c.set);
    final onColor = Colors.white;
    final text = theme.textTheme;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color,
            padding: EdgeInsets.all(dense ? 8 : 12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: 4),
                  decoration: BoxDecoration(color: onColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    c.id,
                    style: (dense ? text.titleSmall : text.titleMedium)
                        ?.copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: dense ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quartettSetName(c.set),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium?.copyWith(color: onColor.withValues(alpha: 0.85)),
                      ),
                      Text(
                        c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: (dense ? text.titleSmall : text.titleMedium)
                            ?.copyWith(color: onColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final s in qe.QuartettGame.stats) _statRow(context, c, s, color),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, qe.Card c, qe.QuartettStat s, Color setColor) {
    final theme = Theme.of(context);
    final text = dense ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium;
    final highlighted = highlightStat == s.id;
    final o = outcome;
    final tint = !highlighted ? null : (o == null ? setColor : quartettOutcomeColor(o));
    final value = c.stats[s.id];
    final tap = onStatTap;
    final row = Container(
      constraints: BoxConstraints(minHeight: dense ? 36 : 44),
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: 4),
      decoration: BoxDecoration(
        color: tint?.withValues(alpha: 0.18),
        border: BorderDirectional(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
          start: BorderSide(color: tint ?? Colors.transparent, width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text?.copyWith(fontWeight: highlighted ? FontWeight.bold : null),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value == null ? '–' : formatQuartettValue(s, value, locale: Localizations.localeOf(context).languageCode),
            style: text?.copyWith(fontWeight: FontWeight.bold, color: tint),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: s.higherWins ? AppLocalizations.of(context).quartettHigherWins : AppLocalizations.of(context).quartettLowerWins,
            child: Icon(
              s.higherWins ? Icons.arrow_upward : Icons.arrow_downward,
              size: dense ? 14 : 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    final key = statKeyPrefix == null ? null : Key('$statKeyPrefix${s.id}');
    if (tap == null) return KeyedSubtree(key: key, child: row);
    return InkWell(key: key, onTap: enabled ? () => tap(s) : null, child: row);
  }

  Widget _buildBack(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return AspectRatio(
      aspectRatio: 0.7,
      child: Material(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        color: scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.onPrimary.withValues(alpha: 0.6), width: 2),
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.onPrimary.withValues(alpha: 0.5)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.tertiary],
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label != null)
                      Text(label!, style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onPrimary)),
                    Icon(Icons.directions_car, size: dense ? 28 : 40, color: scheme.onPrimary),
                    Text(l10n.quartettCardBack,
                        style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimary, letterSpacing: 2)),
                    if (count != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.quartettCards(count!),
                        style: theme.textTheme.titleSmall?.copyWith(color: scheme.onPrimary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
