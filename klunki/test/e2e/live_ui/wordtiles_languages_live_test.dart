// KLD-132: one whole hot-seat game per new tile language (French, Spanish,
// Arabic, Persian) through the real UI, with the language's word list on:
// one "Trotzdem zulassen", a swap, a pass, then the best sample placement
// the list accepts until the game ends (the adapter of
// wordtiles_live_test.dart). For Arabic and Persian the engine reads a word
// across from the right; the adapter lays the engine's placements square by
// square and checks the score preview, so the UI and the engine agree on
// that reading direction.
//
//   cd klunki && flutter test test/e2e/live_ui/wordtiles_languages_live_test.dart
@Timeout(Duration(minutes: 8))
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/ui/games/wordtiles/word_list_loader.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import 'live_ui_driver.dart';
import 'wordtiles_adapter.dart';

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final (id, seed) in [('fr', 1), ('es', 2), ('ar', 3), ('fa', 4)]) {
    testWidgets('hot-seat with the $id tiles and word list (seed $seed): a whole game', (tester) async {
      await tester.runAsync(() => WordListLoader.ensure(id));
      tester.view.physicalSize = const Size(1180, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final adapter = WordTilesDictionaryAdapter();
      final config = GameConfig('wordtiles', seed: seed, tiles: id, dictionary: true);
      final log = await playHotSeat(tester, adapter, config, rng: Random(seed));
      log.printIfVerbose();
      final c = tester.widget<GameScreen>(find.byType(GameScreen)).controller;
      final game = c.game as WordTilesGame;
      expect(game.tileSet.id, id);
      expect(game.isOver, isTrue);
      expect(adapter.tapped['agree'], 1, reason: '${adapter.tapped}');
      expect(adapter.tapped['place'] ?? 0, greaterThan(5), reason: '${adapter.tapped}');
      // Every word the game scored is in the list, or one the players let stand.
      final list = WordLists.of(id)!;
      final allowed = game.turns.expand((t) => t.allowed).toSet();
      final words = [for (final t in game.turns) if (!t.withdrawn) ...t.words];
      expect(words, isNotEmpty);
      for (final w in words) {
        expect(list.isWord(w) || allowed.contains(w), isTrue, reason: '$id: $w');
      }
      // Every run of tiles across on the final board, read in the set's
      // direction (ar/fa: from the right), is a word of the game.
      const n = WordTilesGame.size;
      var across = 0;
      for (var r = 0; r < n; r++) {
        var c0 = 0;
        while (c0 < n) {
          if (game.tileAt(r, c0) == null) {
            c0++;
            continue;
          }
          var c1 = c0;
          while (c1 < n && game.tileAt(r, c1) != null) {
            c1++;
          }
          if (c1 - c0 > 1) {
            final run = [for (var k = c0; k < c1; k++) game.tileAt(r, k)!.letter];
            final word = (game.tileSet.rtl ? run.reversed : run).join();
            expect(words, contains(word), reason: '$id: row $r, columns $c0–${c1 - 1}');
            across++;
          }
          c0 = c1;
        }
      }
      expect(across, greaterThan(0), reason: '$id: no word across');
      debugPrint('wordtiles $id: ${adapter.tapped}, ${c.moves.length} moves, ${game.result.code}, '
          'scores ${game.scores}, words ${words.take(12).join(' ')}');
    }, timeout: liveUiTimeout);
  }
}
