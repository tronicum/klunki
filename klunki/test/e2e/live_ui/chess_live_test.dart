// KLD-059 step 3: chess played to the end through the real UI, like a user:
// over the network (host White and guest Black side by side over real
// sockets, through the Wi-Fi latency proxy, with dawdling and board flips)
// and once in hot-seat. Pieces are moved by tapping squares, promotions
// through the picker, draw offers through the handshake button and the
// answer dialog. Each device must show every board move once, in order,
// and match its engine; the host must have applied exactly the tapped
// moves (draw offers included), by the device that tapped them. Step 4a: one
// network game with the host on Black (the guest opens).
//
//   cd klunki && flutter test test/e2e/live_ui/chess_live_test.dart
//   KLUNKI_LIVE_UI_VERBOSE=1 flutter test test/e2e/live_ui/chess_live_test.dart   # move logs
//   KLUNKI_LIVE_UI_FULL=1 flutter test test/e2e/live_ui/chess_live_test.dart      # more network seeds
//
// The network games use [liveUiTimeout] (KLD-109).
@Timeout(Duration(minutes: 8))
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import 'chess_adapter.dart';
import 'live_ui_driver.dart';

/// The result dialog on [device] gives the engine's reason.
void _expectResult(WidgetTester tester, UiDevice device, Game game) {
  final reason = device.on(find.byKey(const Key('result-reason')));
  final chess = game as ChessGame;
  String label(Player p) =>
      '${p == Player.a ? 'Anna' : 'Ben'} (${chess.colorOf(p) == ChessColor.white ? 'Weiß' : 'Schwarz'})';
  expect(tester.widget<Text>(reason).data, localizedResultReason(deL10n, game.result, playerLabel: label),
      reason: device.name);
}

void main() {
  // Only taps a finger could make: a tap on something covered fails.
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  final adapter = ChessAdapter();
  final ends = <GameEndReason?>[];
  // A network game takes about a minute; KLUNKI_LIVE_UI_FULL=1 plays more.
  final seeds = Platform.environment['KLUNKI_LIVE_UI_FULL'] == '1' ? [3, 4, 7, 8] : [3];

  for (final seed in seeds) {
    testWidgets('network seed $seed: both devices show every move once, in order, and the same end', (tester) async {
      final log = await playNetwork(tester, adapter, GameConfig('chess', seed: seed),
          rng: Random(seed * 13), behaviour: const NetBehaviour(dawdle: 0.3, wait: 0.1, fidget: 0.03));
      log.printIfVerbose();
      final host = UiDevice('host', scope: const Key('device-host'), me: Player.a);
      final guest = UiDevice('guest', scope: const Key('device-guest'), me: Player.b);
      final hc = host.controller(tester), gc = guest.controller(tester);
      expect((gc.game as ChessGame).fen, (hc.game as ChessGame).fen);
      expect(gc.game.result.code, hc.game.result.code);
      expect(hc.game.isOver, isTrue);
      for (final d in [host, guest]) {
        expect(d.resultShown(), isTrue, reason: d.name);
        _expectResult(tester, d, hc.game);
      }
      ends.add(hc.game.result.code);
    }, timeout: liveUiTimeout);
  }

  testWidgets('network, the host plays Black (step 4a): the guest opens, every move once, the same end',
      (tester) async {
    final black = ChessAdapter();
    final log = await playNetwork(tester, black, const GameConfig('chess', seed: 9, chessWhite: Player.b),
        rng: Random(9 * 13), behaviour: const NetBehaviour(dawdle: 0.3, wait: 0.1, fidget: 0.03));
    log.printIfVerbose();
    final host = UiDevice('host', scope: const Key('device-host'), me: Player.a);
    final guest = UiDevice('guest', scope: const Key('device-guest'), me: Player.b);
    final hc = host.controller(tester), gc = guest.controller(tester);
    expect((hc.game as ChessGame).whitePlayer, Player.b);
    expect((gc.game as ChessGame).whitePlayer, Player.b);
    expect(hc.moves.first.player, Player.b, reason: 'the guest (White) moved first');
    expect((gc.game as ChessGame).fen, (hc.game as ChessGame).fen);
    expect(hc.game.isOver, isTrue);
    for (final d in [host, guest]) {
      expect(d.resultShown(), isTrue, reason: d.name);
      _expectResult(tester, d, d.controller(tester).game);
    }
    expect(black.tapped['move'] ?? 0, greaterThan(10), reason: '${black.tapped}');
    expect(black.boardChecks, greaterThan(5));
  }, timeout: liveUiTimeout);

  testWidgets('network, an eager peacemaker: draw offers until one is accepted', (tester) async {
    final eager = ChessAdapter(offerRate: 0.5, acceptRate: 0.3, minDeclines: 2);
    final log = await playNetwork(tester, eager, const GameConfig('chess', seed: 5),
        rng: Random(5), behaviour: const NetBehaviour(dawdle: 0.2, wait: 0, fidget: 0), proxy: false);
    log.printIfVerbose();
    final hc = UiDevice('host', scope: const Key('device-host'), me: Player.a).controller(tester);
    expect(eager.tapped['offer'] ?? 0, greaterThan(0), reason: '${eager.tapped}');
    expect(eager.tapped['decline'] ?? 0, greaterThan(0), reason: '${eager.tapped}');
    expect(hc.game.result.code, GameEndReason.chessDrawAgreed, reason: '${eager.tapped}');
    expect(eager.boardChecks, greaterThan(0));
  }, timeout: liveUiTimeout);

  testWidgets('hot-seat: a full game through the UI, every move shown once, in order', (tester) async {
    tester.view.physicalSize = const Size(1180, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final hotSeat = ChessAdapter(offerRate: 0.02, acceptRate: 0);
    final log = await playHotSeat(tester, hotSeat, const GameConfig('chess', seed: 6), rng: Random(6));
    log.printIfVerbose();
    final c = tester.widget<GameScreen>(find.byType(GameScreen)).controller;
    expect(c.game.isOver, isTrue);
    _expectResult(tester, UiDevice('hot-seat'), c.game);
  });

  test('the network games were played on the board and checked against the engine', () {
    expect(ends, hasLength(seeds.length));
    expect(adapter.tapped['move'] ?? 0, greaterThan(20), reason: '${adapter.tapped}');
    expect(adapter.boardChecks, greaterThan(10));
  });
}
