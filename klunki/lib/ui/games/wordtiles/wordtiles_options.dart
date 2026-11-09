import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game_titles.dart';
import 'word_list_loader.dart';

/// The start options of a Wortgewandt game (KLD-094 step 4); [joker]: the
/// house rule "Joker tauschen" (step 9, off by default); [rest]:
/// "Restpunkte abziehen" (step 10, on by default).
typedef WordTilesOptions = ({String tiles, bool dictionary, bool joker, bool rest});

/// The tile language that follows the app language: German tiles for a
/// German UI, English tiles for every other language (for now).
String defaultWordTilesTiles(Locale locale) => locale.languageCode == 'de' ? TileSet.german.id : TileSet.english.id;

/// The default options for [locale]: its tile language, the word list on
/// when one exists for it.
WordTilesOptions defaultWordTilesOptions(Locale locale) {
  final tiles = defaultWordTilesTiles(locale);
  return (tiles: tiles, dictionary: WordListLoader.available.contains(tiles), joker: false, rest: true);
}

/// The tile languages, named by their endonyms (like the language picker).
const Map<String, String> wordTilesTileNames = {'de': 'Deutsch', 'en': 'English'};

/// The options of a game as one line ("English · Wörterbuch prüfen" /
/// "Deutsch · ohne Wörterbuch", plus "· Joker tauschen" when on and "· ohne
/// Restpunkte" when "Restpunkte abziehen" is off): the room
/// and the game header of a network game show what the host chose (KLD-094
/// step 6).
String wordTilesOptionsSummary(AppLocalizations l10n, GameConfig config) {
  final tiles = config.tiles ?? TileSet.german.id;
  final name = wordTilesTileNames[tiles] ?? tiles;
  final summary = config.dictionary ? l10n.wordtilesOptionsSummaryDict(name) : l10n.wordtilesOptionsSummaryFree(name);
  final joker = config.jokerSwap ? l10n.wordtilesOptionsSummaryJoker(summary) : summary;
  return config.rackPenalty ? joker : l10n.wordtilesOptionsSummaryNoRest(joker);
}

/// Asks for the tile language and "Wörterbuch prüfen" before a Wortgewandt
/// game (on by default when a list exists for the chosen language); null
/// when cancelled. Keys: `wordtiles-options`, `wordtiles-tiles-<id>`,
/// `wordtiles-dict`, `wordtiles-joker`, `wordtiles-rest`, `wordtiles-options-next`,
/// `wordtiles-options-cancel`.
Future<WordTilesOptions?> showWordTilesOptionsDialog(BuildContext context) => showDialog<WordTilesOptions>(
      context: context,
      builder: (_) => _WordTilesOptionsDialog(initial: defaultWordTilesOptions(Localizations.localeOf(context))),
    );

class _WordTilesOptionsDialog extends StatefulWidget {
  final WordTilesOptions initial;
  const _WordTilesOptionsDialog({required this.initial});

  @override
  State<_WordTilesOptionsDialog> createState() => _WordTilesOptionsDialogState();
}

class _WordTilesOptionsDialogState extends State<_WordTilesOptionsDialog> {
  late WordTilesOptions _options = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      key: const Key('wordtiles-options'),
      title: Text(localizedGameTitle(l10n, 'wordtiles', fallback: 'Wortgewandt')),
      scrollable: true,
      content: WordTilesOptionsPicker(value: _options, onChanged: (o) => setState(() => _options = o)),
      actions: [
        TextButton(
          key: const Key('wordtiles-options-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.shellCancel),
        ),
        FilledButton(
          key: const Key('wordtiles-options-next'),
          onPressed: () => Navigator.of(context).pop(_options),
          child: Text(l10n.wordtilesOptionsNext),
        ),
      ],
    );
  }
}

/// The tile language (segmented, endonyms) and the "Wörterbuch prüfen"
/// switch with a line that explains the chosen mode, then the house rule
/// "Joker tauschen" (KLD-094 step 9, off by default) with its explanation:
/// in the start dialog and, for a network game, on "Raum starten" (KLD-094
/// step 6). Keys: `<keyPrefix>tiles-<id>`, `<keyPrefix>dict`,
/// `<keyPrefix>dict-explain`, `<keyPrefix>joker`, `<keyPrefix>joker-explain`,
/// `<keyPrefix>rest`, `<keyPrefix>rest-explain`
/// (prefix `wordtiles-` in the dialog).
class WordTilesOptionsPicker extends StatelessWidget {
  final WordTilesOptions value;
  final ValueChanged<WordTilesOptions> onChanged;
  final bool enabled;
  final String keyPrefix;

  const WordTilesOptionsPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.keyPrefix = 'wordtiles-',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasList = WordListLoader.available.contains(value.tiles);
    final dict = value.dictionary && hasList;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.wordtilesOptionTiles, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            for (final e in wordTilesTileNames.entries)
              ButtonSegment(value: e.key, label: Text(e.value, key: Key('${keyPrefix}tiles-${e.key}'))),
          ],
          selected: {value.tiles},
          showSelectedIcon: false,
          onSelectionChanged: enabled
              ? (s) => onChanged(
                  (
                    tiles: s.single,
                    dictionary: WordListLoader.available.contains(s.single),
                    joker: value.joker,
                    rest: value.rest,
                  ))
              : null,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          key: Key('${keyPrefix}dict'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.wordtilesOptionDictionary),
          value: dict,
          onChanged: hasList && enabled
              ? (v) => onChanged((tiles: value.tiles, dictionary: v, joker: value.joker, rest: value.rest))
              : null,
        ),
        Text(
          dict ? l10n.wordtilesOptionDictionaryOn : l10n.wordtilesOptionDictionaryOff,
          key: Key('${keyPrefix}dict-explain'),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: Key('${keyPrefix}joker'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.wordtilesOptionJoker),
          value: value.joker,
          onChanged: enabled
              ? (v) => onChanged((tiles: value.tiles, dictionary: value.dictionary, joker: v, rest: value.rest))
              : null,
        ),
        Text(
          l10n.wordtilesOptionJokerExplain,
          key: Key('${keyPrefix}joker-explain'),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        // KLD-094 step 10: "Restpunkte abziehen", on by default.
        SwitchListTile(
          key: Key('${keyPrefix}rest'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.wordtilesOptionRest),
          value: value.rest,
          onChanged: enabled
              ? (v) => onChanged((tiles: value.tiles, dictionary: value.dictionary, joker: value.joker, rest: v))
              : null,
        ),
        Text(
          l10n.wordtilesOptionRestExplain,
          key: Key('${keyPrefix}rest-explain'),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Loads the word list for [tiles] with a small "Wörterbuch wird geladen …"
/// dialog; false (after a snack bar) if it failed.
Future<bool> loadWordListWithProgress(BuildContext context, String tiles) async {
  if (WordLists.has(tiles)) return true;
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final navigator = Navigator.of(context);
  var open = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        key: const Key('wordtiles-dict-loading'),
        content: Row(
          children: [
            const SizedBox.square(dimension: 28, child: CircularProgressIndicator()),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.wordtilesDictLoading)),
          ],
        ),
      ),
    ),
  ).whenComplete(() => open = false);
  var ok = true;
  try {
    await WordListLoader.ensure(tiles);
  } catch (_) {
    ok = false;
  }
  if (open) navigator.pop();
  if (!ok) messenger?.showSnackBar(SnackBar(content: Text(l10n.wordtilesDictLoadFailed)));
  return ok;
}
