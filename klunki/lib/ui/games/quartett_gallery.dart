import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_engine/klunki_engine.dart' as qe show Card;

import '../../app/theme.dart';
import '../engine_l10n.dart';
import 'quartett_card.dart';
import 'quartett_deck_picker.dart' show QuartettDeckPreview;
import 'quartett_pictograms.dart';

/// The view-only card gallery (KLD-069, "Karten ansehen"): browse the
/// Quartett decks without playing. Offline, read-only.
///
/// * [QuartettGalleryScreen]: every deck with preview, name and card count.
/// * [QuartettDeckGalleryScreen]: one deck, its 8 sets as sections (set
///   colour header) with 4 small cards each; "Top 5" per stat in the app bar.
/// * [QuartettCardPagerScreen]: the full card (the in-game [QuartettCard]),
///   swipe or step through the deck.

/// The list of decks.
class QuartettGalleryScreen extends StatelessWidget {
  const QuartettGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quartettGalleryTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final deck in QuartettDeck.all)
                  Card(
                    key: Key('gallery-deck-${deck.id}'),
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () =>
                          Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => QuartettDeckGalleryScreen(deck: deck))),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            QuartettDeckPreview(deck: deck, width: 56),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizedDeckName(l10n, deck.id),
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${l10n.quartettCards(deck.cards.length)} · '
                                    '${l10n.quartettDeckSets(deck.setNames.length)}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [for (final s in deck.setNames.keys) localizedSetName(l10n, s, deck.id)]
                                        .join(' · '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One deck: the 8 sets as sections, each with its 4 cards as small cards.
/// Tapping a card opens [QuartettCardPagerScreen] at that card.
class QuartettDeckGalleryScreen extends StatelessWidget {
  final QuartettDeck deck;
  const QuartettDeckGalleryScreen({super.key, required this.deck});

  void _open(BuildContext context, qe.Card card) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => QuartettCardPagerScreen(deck: deck, initialIndex: deck.cards.indexOf(card)),
    ),
  );

  Future<void> _showTop(BuildContext context, QuartettStat stat) {
    final l10n = AppLocalizations.of(context);
    final ranked = List.of(deck.cards)
      ..sort((x, y) {
        final a = x.stats[stat.id]!, b = y.stats[stat.id]!;
        return stat.higherWins ? b.compareTo(a) : a.compareTo(b);
      });
    final locale = Localizations.localeOf(context).languageCode;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            key: const Key('gallery-top'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.quartettGalleryTopTitle(localizedStatLabel(l10n, stat.id)),
                  style: Theme.of(sheet).textTheme.titleMedium,
                ),
              ),
              for (final (i, card) in ranked.take(5).indexed)
                ListTile(
                  key: Key('gallery-top-${card.id}'),
                  leading: CircleAvatar(
                    backgroundColor: quartettSetColor(card.set, KlunkiPalette.of(sheet).quartett),
                    foregroundColor: Colors.white,
                    child: Text('${i + 1}'),
                  ),
                  title: Text(card.name),
                  subtitle: Text(localizedSetName(l10n, card.set, deck.id)),
                  trailing: Text(
                    formatQuartettValue(
                      stat,
                      card.stats[stat.id]!,
                      locale: locale,
                      unit: localizedStatUnit(l10n, stat.id),
                    ),
                    style: Theme.of(sheet).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    _open(context, card);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = KlunkiPalette.of(context).quartett;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizedDeckName(l10n, deck.id)),
        actions: [
          PopupMenuButton<QuartettStat>(
            key: const Key('gallery-top-menu'),
            tooltip: l10n.quartettGalleryTopMenu,
            icon: const Icon(Icons.leaderboard_outlined),
            onSelected: (s) => _showTop(context, s),
            itemBuilder: (_) => [
              for (final s in deck.stats)
                PopupMenuItem(
                  key: Key('gallery-top-${s.id}'),
                  value: s,
                  child: Row(
                    children: [
                      Icon(s.higherWins ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
                      const SizedBox(width: 8),
                      Flexible(child: Text(localizedStatLabel(l10n, s.id))),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: LayoutBuilder(
              builder: (context, box) {
                final cols = box.maxWidth >= 560 ? 4 : 2;
                // Not lazy: 32 small cards, all built (tests, screen readers).
                return SingleChildScrollView(
                  key: const Key('gallery-sets'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final set in deck.setNames.keys) ...[
                        Semantics(
                          header: true,
                          child: Container(
                            key: Key('gallery-set-$set'),
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: palette.set(set), borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '$set  ${localizedSetName(l10n, set, deck.id)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        _grid(cols, [
                          for (final card in deck.cardsOf(set))
                            QuartettMiniCard(card: card, onTap: () => _open(context, card)),
                        ]),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// [children] in rows of [cols] (eager, rows share their height).
  static Widget _grid(int cols, List<Widget> children) {
    const gap = 10.0;
    return Column(
      children: [
        for (var i = 0; i < children.length; i += cols)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var k = 0; k < cols; k++) ...[
                    if (k > 0) const SizedBox(width: gap),
                    Expanded(child: i + k < children.length ? children[i + k] : const SizedBox()),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A small card for the gallery grid: set-colour header with the id and the
/// deck pictogram, then the name. One screen-reader label for the whole card.
class QuartettMiniCard extends StatelessWidget {
  final qe.Card card;
  final VoidCallback? onTap;
  const QuartettMiniCard({super.key, required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final p = KlunkiPalette.of(context).quartett;
    final color = p.set(card.set);
    final label = l10n.quartettCardSemantics(card.id, card.name, localizedSetName(l10n, card.set, card.deck));
    return Semantics(
      key: Key('gallery-card-${card.id}'),
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: p.cardFace,
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, Color.lerp(color, Colors.black, 0.18)!],
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        card.id,
                        style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox.expand(
                        child: CustomPaint(
                          painter: QuartettPictogram(card.deck, color: Colors.white, detail: color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Text(
                  card.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full-size card view: one page per card of [deck], swipe left/right
/// (follows the reading direction) or use the buttons. Shows every stat with
/// its unit and which way wins.
class QuartettCardPagerScreen extends StatefulWidget {
  final QuartettDeck deck;
  final int initialIndex;
  const QuartettCardPagerScreen({super.key, required this.deck, this.initialIndex = 0});

  @override
  State<QuartettCardPagerScreen> createState() => _QuartettCardPagerScreenState();
}

class _QuartettCardPagerScreenState extends State<QuartettCardPagerScreen> {
  late int _index = widget.initialIndex.clamp(0, widget.deck.cards.length - 1);
  late final PageController _pages = PageController(initialPage: _index);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.deck.cards.length) return;
    _pages.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cards = widget.deck.cards;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${localizedDeckName(l10n, widget.deck.id)} · ${l10n.quartettGalleryCardOf(_index + 1, cards.length)}',
          key: const Key('gallery-pager-title'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                key: const Key('gallery-pager'),
                controller: _pages,
                itemCount: cards.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: QuartettCard(key: Key('gallery-full-${cards[i].id}'), card: cards[i]),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('gallery-previous'),
                    tooltip: l10n.quartettGalleryPrevious,
                    onPressed: _index > 0 ? () => _go(-1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: [
                        for (final (icon, text) in [
                          (Icons.arrow_upward, l10n.quartettHigherWins),
                          (Icons.arrow_downward, l10n.quartettLowerWins),
                        ])
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 16, color: muted),
                              const SizedBox(width: 2),
                              Text(text, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('gallery-next'),
                    tooltip: l10n.quartettGalleryNext,
                    onPressed: _index < cards.length - 1 ? () => _go(1) : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
