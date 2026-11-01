import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:klunki_engine/klunki_engine.dart';

import 'gunzip_web.dart' if (dart.library.io) 'gunzip_io.dart' as gz;

/// The word lists of Wortgewandt (KLD-094 step 4), one per tile set:
/// `assets/wordlists/<id>/words.txt.gz` (gzip, one normalized word per line,
/// sorted; built by `tool/build_word_lists.py`, sources and licences in
/// `SOURCE.txt` next to each). Loaded on demand, only when a game with
/// "Wörterbuch prüfen" starts: decompressed (natively in a background
/// isolate, on the web by the browser's `DecompressionStream`), indexed
/// into a [SortedWordListValidator] and registered in [WordLists] so that
/// `createGame` finds it. Loaded once per app run.
class WordListLoader {
  WordListLoader._();

  /// Tile set ids with a bundled list.
  static const Set<String> available = {'de', 'en'};

  static String assetOf(String tileSetId) => 'assets/wordlists/$tileSetId/words.txt.gz';

  static final Map<String, Future<WordValidator>> _loading = {};

  /// Test hook: the bundle to read from (default [rootBundle]).
  @visibleForTesting
  static AssetBundle? bundle;

  /// The last load's timings (for the KLD-094 measurements and debugging).
  static final Map<String, Duration> lastLoadTime = {};

  /// Loads, indexes and registers the list for [tileSetId] (once; later
  /// calls get the same future). A failed load can be retried.
  static Future<WordValidator> ensure(String tileSetId) {
    final known = WordLists.of(tileSetId);
    if (known != null) return SynchronousFuture(known);
    return _loading.putIfAbsent(tileSetId, () async {
      try {
        final sw = Stopwatch()..start();
        final data = await (bundle ?? rootBundle).load(assetOf(tileSetId));
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        final list = gz.gunzipInIsolate ? await compute(_decodeAndIndex, bytes) : await _decodeAndIndex(bytes);
        lastLoadTime[tileSetId] = sw.elapsed;
        WordLists.register(tileSetId, list);
        return list;
      } catch (_) {
        _loading.remove(tileSetId);
        rethrow;
      }
    });
  }

  /// Tests only: forget every loaded list.
  @visibleForTesting
  static void reset() {
    _loading.clear();
    lastLoadTime.clear();
    WordLists.clear();
  }
}

Future<SortedWordListValidator> _decodeAndIndex(Uint8List bytes) async {
  // A server may already have undone the gzip (Content-Encoding): only
  // decompress what still starts with the gzip magic bytes.
  final text = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b ? await gz.gunzipBytes(bytes) : bytes;
  return SortedWordListValidator.fromUtf8(text);
}
