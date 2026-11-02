import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' as qe show Card, QuartettDeck, QuartettStat;

import '../../app/theme.dart';
import '../engine_l10n.dart';
import 'hyphenated_label.dart';
import 'quartett_media.dart';
import 'quartett_pictograms.dart';

/// Shared Quartett card widgets (Trumpf screen KLD-024, Sets screen KLD-025).
///
/// The engine's `Card` clashes with Flutter's `Card`, so this file imports the
/// engine with the `qe` prefix; callers pass a `qe.Card` (any import style
/// works, it is the same type).

/// Header colour of a set letter `A`–`H` (grey for anything else), from
/// [palette] (default: the classic light palette; widgets pass
/// `KlunkiPalette.of(context).quartett`). White text on it is WCAG AA.
Color quartettSetColor(String set, [QuartettPalette? palette]) =>
    (palette ?? KlunkiPalette.classicLight.quartett).set(set);

/// Localized display name of a set letter of [deck] (e.g. `B` → "Hypercars"
/// in the car deck, the default).
String quartettSetName(AppLocalizations l10n, String set, [String deck = qe.QuartettDeck.defaultId]) =>
    localizedSetName(l10n, set, deck);

/// The deck of [card] (the car deck for an unknown id).
qe.QuartettDeck quartettDeckOf(qe.Card card) => qe.QuartettDeck.byId(card.deck) ?? qe.QuartettDeck.cars;

/// A stat value with unit and the decimal separator of [locale] (default
/// German, decimal comma): `2,7 s`, `650 PS`. [unit] defaults to the engine's
/// unit; pass `localizedStatUnit(l10n, stat.id)` for the current language.
///
/// Digits are always Western (0–9), like every other number in the app
/// (I18N-04): a locale whose default digits are not Western (fa: `۲٫۷`) falls
/// back to English formatting, so ints and decimals on one card match.
///
/// The number of decimals comes from the stat ([qe.QuartettStat.decimals]),
/// never from the runtime type: on the web every number is a double, which
/// once printed years as "1999,0" (KLD-082). Years print as bare ASCII
/// digits without grouping ("1990"). Every other value gets the locale's
/// thousands separator (KLD-110): "35.100 kN" in de, "35,100 kN" in en, zh, ar
/// and fa, "35 100 kN" with a narrow no-break space (U+202F) in fr; es groups
/// from five digits on, as CLDR and the RAE do ("1640 kg", "10.000 kN").
/// Percentages use the locale's percent format ("99 %" in de, "99%" in en;
/// the [unit] is ignored for them).
String formatQuartettValue(qe.QuartettStat stat, num value, {String locale = 'de', String? unit}) {
  // Western digits only: fall back to English for e.g. fa (I18N-04).
  final loc = NumberFormat.decimalPattern(locale).symbols.ZERO_DIGIT == '0' ? locale : 'en';
  // The engine rounds to the stat's decimals (plain ASCII, never grouped).
  final plain = stat.formatNumber(value);
  if (stat.isPercent) {
    final f = NumberFormat.percentPattern(loc)
      ..minimumFractionDigits = stat.fixedDecimals ? stat.decimals : 0
      ..maximumFractionDigits = stat.decimals;
    return f.format(num.parse(plain) / 100);
  }
  if (stat.isYear) return plain;
  final rounded = num.parse(plain);
  final f = NumberFormat.decimalPattern(loc)
    ..minimumFractionDigits = stat.fixedDecimals ? stat.decimals : 0
    ..maximumFractionDigits = stat.decimals;
  // intl ignores CLDR's minimumGroupingDigits: Spanish keeps four-digit
  // numbers whole ("1640", but "10.000").
  if (_minimumGroupingDigits(loc) > 1 && rounded.abs() < 10000) f.turnOffGrouping();
  final v = f.format(rounded);
  final u = unit ?? stat.unit;
  return u.isEmpty ? v : '$v $u';
}

/// CLDR `minimumGroupingDigits` of [locale]: 2 for Spanish, 1 for the app's
/// other locales.
int _minimumGroupingDigits(String locale) => locale.split(RegExp('[-_]')).first == 'es' ? 2 : 1;

/// How a highlighted stat row came out in a trick.
enum QuartettOutcome { win, lose, tie }

/// Colour used for an outcome (green / red / grey), from [palette] (default:
/// the classic light palette).
Color quartettOutcomeColor(QuartettOutcome o, [QuartettPalette? palette]) {
  final p = palette ?? KlunkiPalette.classicLight.quartett;
  return switch (o) {
    QuartettOutcome.win => p.win,
    QuartettOutcome.lose => p.lose,
    QuartettOutcome.tie => p.tie,
  };
}

/// A Quartett card, face-up ([QuartettCard.new]) or face-down
/// ([QuartettCard.back]).
///
/// Face-up: coloured header per set with the id badge ("B3"), set name, card
/// name and the deck's pictogram (KLD-069), then one row per stat of the
/// card's deck (label, value + unit, ↑ "higher wins" / ↓ "lower wins").
///
/// * [onStatTap] makes the stat rows tappable (null = read-only); rows are
///   disabled again when [enabled] is false.
/// * [statKeyPrefix] gives each row the key `<prefix><statId>` (e.g.
///   `qt-stat-` → `qt-stat-ps`).
/// * [highlightStat] + [outcome] tint that row green/red/grey (trick reveal);
///   [highlightStat] alone tints it with the set colour (selection).
/// * [dense] uses smaller text for side-by-side layouts.
/// * [compact] (KLD-100, the choose view: 2–3 cards that must fit a phone
///   screen together) is denser still: one-line header without the set
///   name, a low photo band, tight stat rows. Every stat stays visible; with
///   a [highlightStat] the other rows use a smaller font.
/// * KLD-082: a card with a bundled photo shows it in a band between the
///   header and the stats (the stat rows are unchanged); without one the
///   header pictogram stands alone. [showLinks] (full-size views only, not
///   in a running trick) adds the "ⓘ" credit button on the photo and
///   "Auf Wikipedia lesen" below the stats.
///
/// Face-down: patterned back with the [deck]'s pictogram, an optional [count]
/// ("15 Karten") and [label] (e.g. the owner's player number "2").
class QuartettCard extends StatelessWidget {
  final qe.Card? card;
  final void Function(qe.QuartettStat stat)? onStatTap;
  final bool enabled;
  final String? statKeyPrefix;
  final String? highlightStat;
  final QuartettOutcome? outcome;
  final bool dense;
  final bool compact;

  /// Photo credit button and Wikipedia link (KLD-082).
  final bool showLinks;

  /// Back side only: number shown on the back ("15 Karten").
  final int? count;

  /// Back side only: caption on the back, e.g. the owner's player number.
  final String? label;

  /// Back side only: the deck id, for its pictogram (default: cars).
  final String? deck;

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
    this.compact = false,
    this.showLinks = false,
  }) : count = null,
       label = null,
       deck = null;

  /// Face-down card (back side). Never reveals a card.
  const QuartettCard.back({super.key, this.count, this.label, this.deck, this.dense = false})
    : card = null,
      compact = false,
      onStatTap = null,
      enabled = false,
      statKeyPrefix = null,
      highlightStat = null,
      outcome = null,
      showLinks = false;

  bool get isFaceDown => card == null;

  @override
  Widget build(BuildContext context) {
    final c = card;
    return c == null ? _buildBack(context) : _buildFront(context, c);
  }

  Widget _buildFront(BuildContext context, qe.Card c) {
    final theme = Theme.of(context);
    final palette = KlunkiPalette.of(context).quartett;
    final color = quartettSetColor(c.set, palette);
    final onColor = Colors.white;
    final text = theme.textTheme;
    final media = quartettMediaOf(c);
    return Material(
      color: palette.cardFace,
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, Color.lerp(color, Colors.black, 0.18)!],
              ),
            ),
            padding: EdgeInsets.all(compact ? 5 : (dense ? 8 : 12)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 4 : (dense ? 6 : 8), vertical: compact ? 1 : 4),
                  decoration: BoxDecoration(color: onColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    c.id,
                    style: (compact ? text.labelLarge : (dense ? text.titleSmall : text.titleMedium))?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 6 : (dense ? 8 : 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!compact)
                        Text(
                          quartettSetName(AppLocalizations.of(context), c.set, c.deck),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelMedium?.copyWith(color: onColor.withValues(alpha: 0.85)),
                        ),
                      Text(
                        c.name,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: (compact ? text.labelLarge : (dense ? text.titleSmall : text.titleMedium))?.copyWith(
                          color: onColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: compact ? 4 : (dense ? 6 : 8)),
                ExcludeSemantics(
                  child: Container(
                    width: compact ? 28 : (dense ? 40 : 52),
                    height: compact ? 18 : (dense ? 28 : 36),
                    padding: EdgeInsets.all(compact ? 2 : 3),
                    decoration: BoxDecoration(color: onColor, borderRadius: BorderRadius.circular(6)),
                    child: CustomPaint(
                      key: Key('quartett-pictogram-${c.deck}'),
                      painter: QuartettPictogram(c.deck, color: color, detail: onColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (media?.image case final img?)
            QuartettCardPhoto(
              key: Key('quartett-photo-${c.deck}-${c.id}'),
              credit: img,
              height: compact ? 38 : (dense ? 72 : 132),
              onInfo: showLinks ? () => showQuartettPhotoCredit(context, img) : null,
            ),
          for (final s in quartettDeckOf(c).stats) _statRow(context, c, s, color),
          if (showLinks && media != null)
            Container(
              alignment: AlignmentDirectional.centerEnd,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: QuartettWikipediaButton(media: media),
            ),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, qe.Card c, qe.QuartettStat s, Color setColor) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final highlighted = highlightStat == s.id;
    final text = compact
        ? (highlightStat != null && !highlighted ? theme.textTheme.labelSmall : theme.textTheme.bodySmall)
        : (dense ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium);
    final o = outcome;
    final palette = KlunkiPalette.of(context).quartett;
    final tint = !highlighted
        ? null
        : (o == null
              ? (theme.brightness == Brightness.dark ? palette.setText(c.set) : setColor)
              : quartettOutcomeColor(o, palette));
    final value = c.stats[s.id];
    final tap = onStatTap;
    final row = Container(
      constraints: BoxConstraints(minHeight: compact ? 0 : (dense ? 36 : 44)),
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : (dense ? 8 : 12), vertical: compact ? 1.5 : 4),
      decoration: BoxDecoration(
        color: tint?.withValues(alpha: 0.18),
        border: BorderDirectional(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
          start: BorderSide(color: tint ?? Colors.transparent, width: 4),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final rowWidth = box.maxWidth;
          return Row(
            children: [
              // KLD-092: a long label ("Höchstgeschwindigkeit") breaks at
              // its soft hyphens with a "-" and shrinks a little, never in
              // the middle of a word without one.
              Expanded(
                child: HyphenatedLabel(
                  localizedStatLabelHyphenated(l10n, s.id),
                  style: text?.copyWith(fontWeight: highlighted ? FontWeight.bold : null),
                ),
              ),
              const SizedBox(width: 8),
              // A long value ("1.500 Stk." on a narrow trick card) shrinks
              // instead of overflowing; the label keeps at least ~40 %.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rowWidth * 0.6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    value == null
                        ? '–'
                        : formatQuartettValue(
                            s,
                            value,
                            locale: Localizations.localeOf(context).languageCode,
                            unit: localizedStatUnit(l10n, s.id),
                          ),
                    maxLines: 1,
                    style: text?.copyWith(fontWeight: FontWeight.bold, color: tint),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: s.higherWins ? l10n.quartettHigherWins : l10n.quartettLowerWins,
                child: Icon(
                  s.higherWins ? Icons.arrow_upward : Icons.arrow_downward,
                  size: compact ? 12 : (dense ? 14 : 18),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
    final key = statKeyPrefix == null ? null : Key('$statKeyPrefix${s.id}');
    if (tap == null) return KeyedSubtree(key: key, child: row);
    return InkWell(key: key, onTap: enabled ? () => tap(s) : null, child: row);
  }

  Widget _buildBack(BuildContext context) {
    final theme = Theme.of(context);
    final p = KlunkiPalette.of(context).quartett;
    final on = p.onBack;
    final l10n = AppLocalizations.of(context);
    return AspectRatio(
      aspectRatio: 0.7,
      child: Material(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        color: p.backA,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: on.withValues(alpha: 0.7), width: 2),
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: on.withValues(alpha: 0.5)),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.backA, p.backB]),
          ),
          child: CustomPaint(
            painter: _BackPattern(on.withValues(alpha: 0.12)),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (label != null) Text(label!, style: theme.textTheme.headlineSmall?.copyWith(color: on)),
                      ExcludeSemantics(
                        child: SizedBox(
                          width: dense ? 44 : 64,
                          height: dense ? 28 : 40,
                          child: CustomPaint(
                            painter: QuartettPictogram(deck ?? qe.QuartettDeck.defaultId, color: on, detail: p.backA),
                          ),
                        ),
                      ),
                      Text(
                        l10n.quartettCardBack,
                        style: theme.textTheme.labelSmall?.copyWith(color: on, letterSpacing: 2),
                      ),
                      if (count != null) ...[
                        const SizedBox(height: 6),
                        Text(l10n.quartettCards(count!), style: theme.textTheme.titleSmall?.copyWith(color: on)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diamond lattice on the card back.
class _BackPattern extends CustomPainter {
  final Color color;
  const _BackPattern(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const step = 14.0;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_BackPattern old) => old.color != color;
}
