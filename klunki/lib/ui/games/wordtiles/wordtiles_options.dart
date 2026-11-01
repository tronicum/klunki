import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game_titles.dart';
import 'word_list_loader.dart';

/// The start options of a Wortgewandt game (KLD-094 step 4).
typedef WordTilesOptions = ({String tiles, bool dictionary});

/// The tile language that follows the app language: German tiles for a
/// German UI, English tiles for every other language (for now).
String defaultWordTilesTiles(Locale locale) => locale.languageCode == 'de' ? TileSet.german.id : TileSet.english.id;

/// The tile languages, named by their endonyms (like the language picker).
const Map<String, String> wordTilesTileNames = {'de': 'Deutsch', 'en': 'English'};

/// Asks for the tile language and "Wörterbuch prüfen" before a Wortgewandt
/// game (on by default when a list exists for the chosen language); null
/// when cancelled. Keys: `wordtiles-options`, `wordtiles-tiles-<id>`,
/// `wordtiles-dict`, `wordtiles-options-next`, `wordtiles-options-cancel`.
Future<WordTilesOptions?> showWordTilesOptionsDialog(BuildContext context) => showDialog<WordTilesOptions>(
      context: context,
      builder: (_) => _WordTilesOptionsDialog(initialTiles: defaultWordTilesTiles(Localizations.localeOf(context))),
    );

class _WordTilesOptionsDialog extends StatefulWidget {
  final String initialTiles;
  const _WordTilesOptionsDialog({required this.initialTiles});

  @override
  State<_WordTilesOptionsDialog> createState() => _WordTilesOptionsDialogState();
}

class _WordTilesOptionsDialogState extends State<_WordTilesOptionsDialog> {
  late String _tiles = widget.initialTiles;
  late bool _dict = WordListLoader.available.contains(_tiles);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasList = WordListLoader.available.contains(_tiles);
    final dict = _dict && hasList;
    return AlertDialog(
      key: const Key('wordtiles-options'),
      title: Text(localizedGameTitle(l10n, 'wordtiles', fallback: 'Wortgewandt')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.wordtilesOptionTiles, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              for (final e in wordTilesTileNames.entries)
                ButtonSegment(value: e.key, label: Text(e.value, key: Key('wordtiles-tiles-${e.key}'))),
            ],
            selected: {_tiles},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() {
              _tiles = s.single;
              _dict = WordListLoader.available.contains(_tiles);
            }),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            key: const Key('wordtiles-dict'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.wordtilesOptionDictionary),
            value: dict,
            onChanged: hasList ? (v) => setState(() => _dict = v) : null,
          ),
          Text(
            dict ? l10n.wordtilesOptionDictionaryOn : l10n.wordtilesOptionDictionaryOff,
            key: const Key('wordtiles-dict-explain'),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('wordtiles-options-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.shellCancel),
        ),
        FilledButton(
          key: const Key('wordtiles-options-next'),
          onPressed: () => Navigator.of(context).pop((tiles: _tiles, dictionary: dict)),
          child: Text(l10n.wordtilesOptionsNext),
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
