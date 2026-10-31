// KLD-089: Quartett (Trumpf) played to the end through the real UI, like a
// user: hot-seat (one device, handover covers) and network (host and guest
// side by side over real sockets through the Wi-Fi latency proxy, with
// dawdling, timed-out grace periods and "Letzter Stich" peeks). After every
// game each device's sequence of revealed tricks (picker, stat, winner, both
// cards) must equal the host engine's history, and the engine history must
// follow the rule: the trick winner picks next, after a tie the same player.
//
//   cd klunki && flutter test test/e2e/live_ui
//   KLUNKI_LIVE_UI_VERBOSE=1 flutter test test/e2e/live_ui   # trick logs
//   KLUNKI_LIVE_UI_FULL=1 flutter test test/e2e/live_ui      # all seeds/decks (~7 min)
//
// By default (CI) a smaller matrix runs: every deck in hot-seat, three
// network games.
@Timeout(Duration(minutes: 8))
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import 'live_ui_driver.dart';
import 'quartett_trumpf_adapter.dart';

void main() {
  final adapter = QuartettTrumpfAdapter();
  final full = Platform.environment['KLUNKI_LIVE_UI_FULL'] == '1';
  // Only taps a finger could make: a tap on something covered fails.
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final deck in QuartettDeck.all) {
    for (final seed in full ? [1, 2, 3, 4, 5, 6] : [1, 2]) {
      testWidgets('hot-seat ${deck.id} seed $seed: every trick revealed once, in order, by the right picker',
          (tester) async {
        final log = await playHotSeat(tester, adapter, GameConfig('quartett-trumpf', seed: seed, deck: deck.id),
            rng: Random(seed * 31 + deck.id.length));
        log.printIfVerbose();
      });
    }
  }

  for (final deck in full ? QuartettDeck.all : [QuartettDeck.cars]) {
    for (final seed in full ? [11, 12] : [11]) {
      testWidgets('network ${deck.id} seed $seed: both devices reveal every trick once, in order', (tester) async {
        final log = await playNetwork(tester, adapter, GameConfig('quartett-trumpf', seed: seed, deck: deck.id),
            rng: Random(seed * 17 + deck.id.length));
        log.printIfVerbose();
      });
    }
  }

  testWidgets('network, impatient players (no dawdling, no waiting): nothing skipped', (tester) async {
    final log = await playNetwork(tester, adapter, const GameConfig('quartett-trumpf', seed: 21),
        rng: Random(21), behaviour: const NetBehaviour(dawdle: 0, wait: 0, fidget: 0), proxy: false);
    log.printIfVerbose();
  });

  testWidgets('network, a slow guest (long queues behind the grace): nothing skipped', (tester) async {
    final log = await playNetwork(tester, adapter, const GameConfig('quartett-trumpf', seed: 22, deck: 'rockets'),
        rng: Random(22), behaviour: const NetBehaviour(dawdle: 0.7, wait: 0.4, fidget: 0.15));
    log.printIfVerbose();
  });
}
