// KLD-094 step 2: the word tile game played to the end through the real UI
// in hot-seat, like a user: rack tile then square (a blank through the
// letter picker), "Legen", sometimes a swap or a pass, and answering the
// open placement with "Annehmen" or (now and then) "Anzweifeln". Every turn
// must show up once on the device (handover cover, challenge banner or the
// last-turn line), in engine order.
//
//   cd klunki && flutter test test/e2e/live_ui/wordtiles_live_test.dart
//   KLUNKI_LIVE_UI_VERBOSE=1 flutter test test/e2e/live_ui/wordtiles_live_test.dart   # turn logs
@Timeout(Duration(minutes: 8))
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki/ui/games/wordtiles/word_list_loader.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import 'live_ui_driver.dart';
import 'wordtiles_adapter.dart';

void main() {
  // Only taps a finger could make: a tap on something covered fails.
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final seed in [1, 2]) {
    testWidgets('hot-seat seed $seed: a full game through the UI, every turn shown once, in order', (tester) async {
      // A tablet: squares big enough that the board does not auto-zoom.
      tester.view.physicalSize = const Size(1180, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final adapter = WordTilesAdapter();
      final log = await playHotSeat(tester, adapter, GameConfig('wordtiles', seed: seed), rng: Random(seed * 7));
      log.printIfVerbose();
      expect(adapter.tapped['place'] ?? 0, greaterThan(5), reason: '${adapter.tapped}');
      // The final turn shows in the result dialog: the engine's reason.
      final c = tester.widget<GameScreen>(find.byType(GameScreen)).controller;
      final game = c.game as WordTilesGame;
      expect(game.isOver, isTrue);
      expect(tester.widget<Text>(find.byKey(const Key('result-reason'))).data,
          localizedResultReason(deL10n, game.result, playerLabel: (p) => PlayerLabels.defaults.name(deL10n, p)));
      expect(game.result.code, anyOf(GameEndReason.wordtilesPlayedOut, GameEndReason.wordtilesScoreless));
    });
  }

  // KLD-094 step 5: with the German word list, on a tablet and on a small
  // phone (375 × 667, the board auto-zooms): one "Trotzdem zulassen", a
  // swap, a pass with its confirmation, the game end with the summary, and
  // "Nochmal" starts a new game with the word list still on.
  for (final (name, size, seed) in [('tablet', Size(1180, 820), 3), ('phone', Size(375, 667), 4)]) {
    testWidgets('hot-seat with the German word list ($name, seed $seed): allow, swap, pass, end, again',
        (tester) async {
      await tester.runAsync(() => WordListLoader.ensure('de'));
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final adapter = WordTilesDictionaryAdapter();
      final config = GameConfig('wordtiles', seed: seed, dictionary: true);
      final log = await playHotSeat(tester, adapter, config, rng: Random(seed));
      log.printIfVerbose();
      expect(adapter.tapped['allow'], 1, reason: '${adapter.tapped}');
      expect(adapter.tapped['exchange'], 1, reason: '${adapter.tapped}');
      expect(adapter.tapped['pass'] ?? 0, greaterThanOrEqualTo(1), reason: '${adapter.tapped}');
      expect(adapter.tapped['place'] ?? 0, greaterThan(5), reason: '${adapter.tapped}');
      final c = tester.widget<GameScreen>(find.byType(GameScreen)).controller;
      final game = c.game as WordTilesGame;
      expect(game.isOver, isTrue);
      final allowed = game.turns.expand((t) => t.allowed).toList();
      expect(allowed, isNotEmpty);
      // The summary: scores, best word, the allowed words.
      for (var s = 0; s < 2; s++) {
        expect(find.byKey(Key('wordtiles-result-score-$s')), findsOneWidget);
      }
      expect(find.byKey(const Key('wordtiles-result-best')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('wordtiles-result-allowed'))).data,
          deL10n.wordtilesResultAllowed(allowed.join(', ')));
      debugPrint('wordtiles dict $name: ${adapter.tapped}, ${c.moves.length} moves, '
          '${game.result.code}, scores ${game.scores}, allowed $allowed');
      // "Nochmal": a fresh game, the word list still on.
      await tester.tap(find.text(deL10n.shellPlayAgain));
      await tester.pumpAndSettle();
      final again = tester.widget<GameScreen>(find.byType(GameScreen)).controller;
      expect(again.moves, isEmpty);
      expect((again.game as WordTilesGame).check, WordCheck.dictionary);
    });
  }
}
