import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../app/theme.dart';
import '../../game/game_controller.dart';
import '../../profile/quartett_deck_settings.dart';
import '../engine_l10n.dart';
import '../game_titles.dart';
import 'quartett_gallery.dart';
import 'quartett_pictograms.dart';

/// Deck choice for Quartett (KLD-069): the deck tiles shared by the hot-seat
/// picker sheet ([showQuartettDeckPicker]) and the network host setup, the
/// small deck preview card, and the game screen title naming the deck.

/// App bar title of a Quartett game: the game and its deck, so both players
/// see which deck is in play ("Quartett (Trumpf) · Züge").
String quartettScreenTitle(BuildContext context, GameController controller) {
  final l10n = AppLocalizations.of(context);
  final spec = controller.spec;
  final game = controller.game;
  final deck = game is QuartettGame ? game.deck.id : (controller.config.deck ?? QuartettDeck.defaultId);
  return '${localizedGameTitle(l10n, spec.id, fallback: spec.title)} · ${localizedDeckName(l10n, deck)}';
}

/// The set whose colour stands for [deck] on its preview card.
String _previewSet(QuartettDeck deck) => 'ACEG'[QuartettDeck.all.indexOf(deck).clamp(0, 3)];

/// A small card standing for a whole deck: the deck's pictogram on a set
/// colour, like the top of a card. Decorative (no semantics).
class QuartettDeckPreview extends StatelessWidget {
  final QuartettDeck deck;
  final double width;
  const QuartettDeckPreview({super.key, required this.deck, this.width = 44});

  @override
  Widget build(BuildContext context) {
    final p = KlunkiPalette.of(context).quartett;
    final color = p.set(_previewSet(deck));
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: width / 0.7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(width * 0.14),
            border: Border.all(color: color, width: 1.5),
            color: p.cardFace,
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
          ),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(width * 0.12)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, Color.lerp(color, Colors.black, 0.18)!],
                    ),
                  ),
                  padding: EdgeInsets.all(width * 0.1),
                  child: CustomPaint(painter: QuartettPictogram(deck.id, color: Colors.white, detail: color)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.14, vertical: width * 0.08),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Container(height: width * 0.04, color: color.withValues(alpha: 0.35)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tile per deck (preview card, localized name, card and set count);
/// the [selected] tile is marked. Keys: `<keyPrefix><deckId>`.
class QuartettDeckChooser extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String keyPrefix;
  const QuartettDeckChooser({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.keyPrefix = 'quartett-deck-',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final deck in QuartettDeck.all)
          Builder(builder: (context) {
            final on = deck.id == selected;
            final name = localizedDeckName(l10n, deck.id);
            final info = '${l10n.quartettCards(deck.cards.length)} · ${l10n.quartettDeckSets(deck.setNames.length)}';
            return Semantics(
              selected: on,
              inMutuallyExclusiveGroup: true,
              child: InkWell(
                key: Key('$keyPrefix${deck.id}'),
                borderRadius: BorderRadius.circular(12),
                onTap: enabled ? () => onChanged(deck.id) : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 12, 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: on ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.5),
                      width: on ? 2 : 1,
                    ),
                    color: on ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
                  ),
                  child: Row(
                    children: [
                      QuartettDeckPreview(deck: deck, width: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            Text(info,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Icon(
                        on ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: on ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

/// Asks for the deck before a hot-seat Quartett game: a bottom sheet with
/// the decks (the last choice preselected), "Karten ansehen" (the gallery of
/// the selected deck) and "Spielen". Returns the chosen deck id (also saved
/// in [settings]) or null if dismissed.
Future<String?> showQuartettDeckPicker(BuildContext context, {QuartettDeckSettings? settings}) {
  final s = settings ?? QuartettDeckSettings.shared();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _DeckPickerSheet(settings: s),
  );
}

class _DeckPickerSheet extends StatefulWidget {
  final QuartettDeckSettings settings;
  const _DeckPickerSheet({required this.settings});

  @override
  State<_DeckPickerSheet> createState() => _DeckPickerSheetState();
}

class _DeckPickerSheetState extends State<_DeckPickerSheet> {
  late String _deck = widget.settings.value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              key: const Key('quartett-deck-picker'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(l10n.quartettDeckPickerTitle, style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: 8),
                QuartettDeckChooser(selected: _deck, onChanged: (d) => setState(() => _deck = d)),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      key: const Key('quartett-deck-gallery'),
                      icon: const Icon(Icons.style_outlined),
                      label: Text(l10n.quartettGalleryOpen),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => QuartettDeckGalleryScreen(deck: QuartettDeck.byId(_deck)!),
                      )),
                    ),
                    FilledButton.icon(
                      key: const Key('quartett-deck-play'),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.quartettDeckPlay),
                      onPressed: () {
                        widget.settings.set(_deck);
                        Navigator.of(context).pop(_deck);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
