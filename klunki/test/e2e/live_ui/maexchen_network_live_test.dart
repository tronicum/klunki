// KLD-121 network step: whole Mäxchen games over the network, played through
// the real UI on two phones side by side (host Anna, guest Ben; TCP through
// the Wi-Fi latency proxy, WebSocket, relay): roll by tapping "Würfeln" or by
// shaking the phone (a fake motion sensor; on the guest too), lift the cup
// with "Nachschauen" (the dice shown are the own ones), announce the truth
// or a bluff, believe, doubt or, after a Mäxchen, "Leben abgeben". After
// every move both screens are checked: the dice under a closed cup are on
// no table but their roller's (and only while peeking), the hearts (or the
// tally) are the host's, no cover, no "Zug zurücknehmen". The "Unbegrenzte
// Leben" game is ended with "Spiel beenden" by the player to move. At the end
// both devices show the result and the guest verifies the game.
//
//   flutter test test/e2e/live_ui/maexchen_network_live_test.dart
@Timeout(Duration(minutes: 8))
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/platform/shake.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/shake_settings.dart';
import 'package:klunki/ui/games/maexchen/maexchen_dice.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import 'live_ui_driver.dart';
import 'network_pair.dart';

late StreamController<AccelSample> _sensor;
var _t = 0.0;

/// Frames for the cup's animations (shake, lift) without settling: the
/// sockets keep timers running.
Future<void> _frames(WidgetTester tester, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Shakes the fake phone (two jolts of 3 g).
Future<void> _shake(WidgetTester tester) async {
  _t += ShakeDetector.debounce.inMilliseconds + 100;
  for (final g in [3.0, 1.0, 3.2, 1.0]) {
    _t += 120;
    _sensor.add(AccelSample(0, 0, g, _t));
  }
  await tester.pump();
  await tester.pump();
}

List<int>? _tableDice(WidgetTester tester, UiDevice d) => tester.widget<CupTable>(d.on(find.byType(CupTable))).dice;

/// Both screens against the host's engine.
void _checkScreens(WidgetTester tester, NetPair p, String when) {
  final h = p.engine as MaexchenGame;
  if (h.isOver) return;
  for (final d in p.devices) {
    final g = p.controllerOf(d).game as MaexchenGame;
    expect(g.lives, h.lives, reason: '$when: ${d.name}');
    if (h.unlimitedLives) expect(g.lost, h.lost, reason: when);
    expect(d.hasKey(const Key('handover-cover')), isFalse, reason: 'no cover over the network');
    expect(d.hasKey(const Key('shell-undo')), isFalse, reason: 'no undo over the network');
    final shown = _tableDice(tester, d);
    if (shown != null) {
      // Open dice: the last round's after a doubt, or the own roll while
      // peeking; never a closed cup of the other player.
      final ownRoll = h.roller == d.me && h.dice != null;
      expect(ownRoll || (h.roller == null && h.lastRound?.dice != null), isTrue, reason: '$when: ${d.name} sees $shown');
    }
  }
  // The guest's view never holds the host's dice.
  final gv = p.guestController.game as MaexchenGame;
  if (h.roller == Player.a) expect(gv.dice, isNull, reason: when);
}

Future<Map<String, int>> _playGame(WidgetTester tester, GameConfig config, NetLink link, Random rng,
    {int endAfterRounds = 0}) async {
  final p = await NetPair.start(tester, config, link: link);
  final tapped = <String, int>{};
  void count(String k) => tapped[k] = (tapped[k] ?? 0) + 1;
  for (final d in p.devices) {
    expect(d.hasKey(const Key('maexchen-net-options')), isTrue, reason: 'the host\'s options at the start');
  }
  var steps = 0;
  while (!p.engine.isOver) {
    expect(++steps, lessThan(3000), reason: 'the game should end');
    final d = p.onTurn;
    final g = p.controllerOf(d).game as MaexchenGame; // the device's own view
    final n = p.host.moves.length;
    var what = '';
    if (endAfterRounds > 0 && g.round > endAfterRounds && g.phase == MaexchenPhase.roll && g.roller == null) {
      // "Spiel beenden" on the device of the player to move only.
      final other = d == p.hostDevice ? p.guestDevice : p.hostDevice;
      if (other.hasKey(const Key('shell-menu'))) {
        await other.tapKey(tester, const Key('shell-menu'));
        await _frames(tester, 4);
        expect(other.hasKey(const Key('maexchen-end')), isFalse, reason: 'not on the other device');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await _frames(tester, 4);
      }
      await d.tapKey(tester, const Key('shell-menu'));
      await _frames(tester, 4);
      await d.tapKey(tester, const Key('maexchen-end'));
      await _frames(tester, 4);
      await d.tapKey(tester, const Key('maexchen-end-confirm'));
      count('end');
      what = 'end';
    } else {
      switch (g.phase) {
        case MaexchenPhase.roll:
          // The sensor reports a quiet phone: "oder schüttle das Handy".
          _sensor.add(AccelSample(0, 0, 1, _t += 10));
          await _frames(tester, 2);
          expect(d.hasKey(const Key('maexchen-shake-hint')), isTrue, reason: 'shake to roll on ${d.name}');
          if (rng.nextBool()) {
            await _shake(tester);
            count(d == p.guestDevice ? 'guestShake' : 'hostShake');
          } else {
            await d.tapKey(tester, const Key('maexchen-roll'));
            count('roll');
          }
          what = 'roll';
        case MaexchenPhase.announce:
          await d.tapKey(tester, const Key('maexchen-peek'));
          await _frames(tester, 6);
          final dice = g.dice!;
          expect(_tableDice(tester, d), dice[0] >= dice[1] ? dice : [dice[1], dice[0]], reason: 'the own dice');
          final other = d == p.hostDevice ? p.guestDevice : p.hostDevice;
          expect(_tableDice(tester, other), isNull, reason: 'the other table stays closed');
          final real = g.diceValue!;
          final above = MaexchenGame.valuesAbove(g.announced);
          final truth = above.contains(real) && rng.nextInt(4) > 0;
          final value = truth ? real : above[min(above.length - 1, rng.nextInt(3))];
          await d.tapKey(tester, Key('maexchen-value-$value'));
          await d.tapKey(tester, const Key('maexchen-announce'));
          count(truth ? 'truth' : 'bluff');
          what = 'announce';
        case MaexchenPhase.respond:
          final maexchen = g.announced == MaexchenGame.maexchen;
          final doubt = rng.nextInt(10) < (maexchen ? 5 : 4);
          final key = doubt ? 'maexchen-doubt' : (maexchen ? 'maexchen-giveup' : 'maexchen-believe');
          await d.tapKey(tester, Key(key));
          count(key);
          what = key.substring('maexchen-'.length).replaceAll('giveup', 'giveUp');
      }
    }
    await p.synced(n + 1, why: what);
    final last = p.host.moves.last;
    expect(last.player, d.me, reason: 'the move came from the device of the player on turn');
    expect(last.move['action'], what);
    await _frames(tester, 10);
    _checkScreens(tester, p, 'after ${d.name} $what');
  }
  for (var i = 0; i < 50 && p.devices.any((d) => !d.resultShown()); i++) {
    await p.net();
  }
  for (final d in p.devices) {
    expect(d.resultShown(), isTrue, reason: d.name);
  }
  final h = p.engine as MaexchenGame;
  expect(p.guestController.game.result.winner, h.result.winner);
  await p.expectVerified();
  final redaction = specById('maexchen')!.redaction!;
  expect([for (final m in p.guestController.moves) m.move],
      [for (final m in p.hostController.moves) redaction.redactMove(m.move, m.player, Player.b)]);
  return tapped;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.shared.markFirst(SeenTips.shakeConsent);
    ShakeSettings.debugReset();
    Motion.debugReset();
    _sensor = StreamController<AccelSample>.broadcast();
    Motion.debugSamples = () => _sensor.stream;
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDown(() {
    WidgetController.hitTestWarningShouldBeFatal = false;
    Motion.debugReset();
    _sensor.close();
  });

  for (final (name, config, link, endAfter) in [
    ('default (3 lives, "Mäxchen doppelt") over TCP (Wi-Fi proxy)', const GameConfig('maexchen', seed: 5), NetLink.tcp, 0),
    ('5 lives, "Mäxchen doppelt" off over WebSocket',
        const GameConfig('maexchen', seed: 6, lives: 5, maexchenDouble: false), NetLink.ws, 0),
    ('"Unbegrenzte Leben" through the relay, ended with "Spiel beenden"',
        const GameConfig('maexchen', seed: 7, maexchenUnlimited: true), NetLink.relay, 8),
  ]) {
    testWidgets('a whole network game through the UI: $name', (tester) async {
      final tapped = await _playGame(tester, config, link, Random(config.seed), endAfterRounds: endAfter);
      debugPrint('maexchen network $name: $tapped');
      expect(tapped['maexchen-doubt'] ?? 0, greaterThan(0), reason: '$tapped');
      expect(tapped['bluff'] ?? 0, greaterThan(0), reason: '$tapped');
      if (endAfter > 0) expect(tapped['end'], 1);
      expect((tapped['hostShake'] ?? 0) + (tapped['guestShake'] ?? 0), greaterThan(0), reason: '$tapped');
      expect(deL10n.maexchenEndGame, isNotEmpty);
    }, timeout: liveUiTimeout);
  }

  testWidgets('the guest shakes to roll', (tester) async {
    final p = await NetPair.start(tester, const GameConfig('maexchen', seed: 9));
    // Anna rolls and says 31, Ben believes: Ben rolls by shaking his phone.
    Future<void> step(UiDevice d, Key k) async {
      final n = p.host.moves.length;
      await d.tapKey(tester, k);
      await p.synced(n + 1);
      await _frames(tester);
    }

    await step(p.hostDevice, const Key('maexchen-roll'));
    await p.hostDevice.tapKey(tester, const Key('maexchen-value-31'));
    final n = p.host.moves.length;
    await p.hostDevice.tapKey(tester, const Key('maexchen-announce'));
    await p.synced(n + 1);
    await _frames(tester);
    await step(p.guestDevice, const Key('maexchen-believe'));
    _sensor.add(AccelSample(0, 0, 1, _t));
    await _frames(tester, 2);
    expect(p.guestDevice.hasKey(const Key('maexchen-shake-hint')), isTrue);
    expect(p.hostDevice.hasKey(const Key('maexchen-shake-hint')), isFalse);
    final before = p.host.moves.length;
    await _shake(tester);
    await p.synced(before + 1);
    expect(p.host.moves.last.player, Player.b);
    expect(p.host.moves.last.move['action'], 'roll');
    expect((p.guestController.game as MaexchenGame).dice, (p.engine as MaexchenGame).dice);
    expect((p.hostController.game as MaexchenGame).roller, Player.b);
  }, timeout: liveUiTimeout);
}
