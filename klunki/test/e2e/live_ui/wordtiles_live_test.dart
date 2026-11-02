// KLD-094 step 2: the word tile game played to the end through the real UI
// in hot-seat, like a user: rack tile then square (a blank through the
// letter picker), "Legen", sometimes a swap or a pass, and answering the
// open placement with "Annehmen" or (now and then) "Anzweifeln". Every turn
// must show up once on the device (handover cover, challenge banner or the
// last-turn line), in engine order. KLD-094 step 8: before every turn the
// racks are full (unless the bag is empty) and every rack tile is on screen,
// with tiles parked on the Bänkchen now and then (the adapter).
//
//   cd klunki && flutter test test/e2e/live_ui/wordtiles_live_test.dart
//   KLUNKI_LIVE_UI_VERBOSE=1 flutter test test/e2e/live_ui/wordtiles_live_test.dart   # turn logs
@Timeout(Duration(minutes: 8))
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki_net/klunki_net.dart' show Verification;
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
      // KLD-094 step 8: tiles were parked on the bench and stayed reachable.
      expect(adapter.benchTiles, greaterThan(0));
      // The final turn shows in the result dialog: the engine's reason.
      final c = tester.widget<GameScreen>(find.byType(GameScreen)).controller;
      final game = c.game as WordTilesGame;
      expect(game.isOver, isTrue);
      expect(tester.widget<Text>(find.byKey(const Key('result-reason'))).data,
          localizedResultReason(deL10n, game.result, playerLabel: (p) => PlayerLabels.defaults.name(deL10n, p)));
      expect(game.result.code, anyOf(GameEndReason.wordtilesPlayedOut, GameEndReason.wordtilesScoreless));
    });
  }

  // KLD-094 step 6: over the network (host Anna, guest Ben side by side over
  // real sockets through the Wi-Fi latency proxy), with the German word
  // list: the first "Trotzdem zulassen" is declined on the other device, the
  // second accepted; each device plays from its own rack only. The driver
  // checks that the host applied exactly the tapped moves and that the
  // guest's log is the redacted one; the guest verifies the game at the end.
  testWidgets('network with the German word list: allow declined, then accepted; to the end on both devices',
      (tester) async {
    await tester.runAsync(() => WordListLoader.ensure('de'));
    final adapter = WordTilesNetAdapter();
    final log = await playNetwork(tester, adapter, const GameConfig('wordtiles', seed: 3, dictionary: true),
        rng: Random(3), behaviour: const NetBehaviour(dawdle: 0.3, wait: 0, fidget: 0));
    log.printIfVerbose();
    expect(adapter.tapped['decline'], 1, reason: '${adapter.tapped}');
    expect(adapter.tapped['agree'], 1, reason: '${adapter.tapped}');
    expect(adapter.tapped['place'] ?? 0, greaterThan(3), reason: '${adapter.tapped}');
    final host = UiDevice('host', scope: const Key('device-host'), me: Player.a);
    final guest = UiDevice('guest', scope: const Key('device-guest'), me: Player.b);
    final hc = host.controller(tester), gc = guest.controller(tester);
    final hg = hc.game as WordTilesGame, gg = gc.game as WordTilesGame;
    expect(hg.isOver, isTrue);
    expect(gg.isOver, isTrue);
    expect(gg.scores, hg.scores);
    expect(gg.result.code, hg.result.code);
    expect(hg.turns.expand((t) => t.allowed), hasLength(1));
    for (final d in [host, guest]) {
      expect(d.resultShown(), isTrue, reason: d.name);
    }
    // KLD-064: the guest checked the host's reveal.
    final verification = (gc.transport as NetworkTransport).verification;
    for (var i = 0; i < 500 && verification.value == Verification.pending; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump();
    }
    expect(verification.value, Verification.verified);
    expect(guest.hasKey(const Key('net-verification-failed')), isFalse);
    debugPrint('wordtiles network: ${adapter.tapped}, ${hc.moves.length} moves, ${hg.result.code}, scores ${hg.scores}');
  }, timeout: liveUiTimeout);

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
      expect(adapter.benchTiles, greaterThan(0));
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
