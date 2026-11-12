// KLD-118 network step: whole Mau-Mau games over the network, played through
// the real UI on two phones side by side (host Anna, guest Ben; TCP through
// the Wi-Fi latency proxy, WebSocket, relay), like players would: tap a card
// (a jack: pick a suit), draw, keep a drawn card, press "Mau!" (or forget
// it and draw the penalty card). After every move both screens are checked:
// each device shows only its own hand (the engine's), the other hand as a
// count, the same top card, the 7 chain; a draw on one device shows the
// drawn cards framed there only. No handover cover, no "Zug zurücknehmen".
// At the end both devices show the result and the guest verifies the game.
//
//   flutter test test/e2e/live_ui/maumau_network_live_test.dart
@Timeout(Duration(minutes: 8))
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import 'live_ui_driver.dart';
import 'network_pair.dart';

/// The card ids [d] shows in its hand.
Set<String> _shownHand(UiDevice d) => {
      for (final e in d
          .on(find.byWidgetPredicate((w) =>
              w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('maumau-hand-')))
          .evaluate())
        (e.widget.key! as ValueKey<String>).value.substring('maumau-hand-'.length),
    };

/// Taps [card] in [d]'s hand where a finger would: its left edge, which the
/// next card in the fan leaves free.
Future<void> _tapCard(WidgetTester tester, UiDevice d, MauMauCard card) async {
  final f = d.on(find.byKey(Key('maumau-hand-${card.id}')));
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tapAt(tester.getTopLeft(f) + const Offset(10, 40));
  await tester.pump();
  await tester.pump();
}

/// Both screens against the host's engine.
void _checkScreens(NetPair p, String when) {
  final h = p.engine as MauMauGame;
  if (h.isOver) return; // the result dialog; the hands are gone
  for (final d in p.devices) {
    final me = d.me!;
    final g = p.controllerOf(d).game as MauMauGame;
    expect(_shownHand(d), {for (final c in h.handOf(me)) c.id}, reason: '$when: ${d.name} shows its own hand');
    expect(g.handCount(me == Player.a ? Player.b : Player.a), h.handCount(me == Player.a ? Player.b : Player.a));
    expect(g.topCard, h.topCard, reason: when);
    expect(g.penalty, h.penalty, reason: '$when: the 7 chain');
    expect(d.hasKey(const Key('handover-cover')), isFalse, reason: 'no cover over the network');
    expect(d.hasKey(const Key('shell-undo')), isFalse, reason: 'no undo over the network');
    if (h.penalty > MauMauGame.sevenPenalty) {
      expect(d.hasKey(Key('maumau-chain-${h.penalty ~/ MauMauGame.sevenPenalty}')), isTrue, reason: when);
    }
  }
  // The guest's device never holds a card of the host's hand.
  final guestTree = _shownHand(p.guestDevice);
  expect(guestTree.intersection({for (final c in h.handOf(Player.a)) c.id}), isEmpty, reason: when);
}

/// Plays one whole game; returns what happened ("Mau!", draws, …).
Future<Map<String, int>> _playGame(WidgetTester tester, GameConfig config, NetLink link, Random rng) async {
  final p = await NetPair.start(tester, config, link: link);
  final seen = <String, int>{};
  void count(String k) => seen[k] = (seen[k] ?? 0) + 1;
  final tapped = <String>[];
  // Before the first move the guest sees the host's house rules that differ
  // from the defaults; none with the defaults (network decisions 2026-11-12).
  expect(p.guestDevice.hasKey(const Key('maumau-net-options')), !config.mauMau.isDefault);
  _checkScreens(p, 'start');
  var steps = 0;
  while (!p.engine.isOver) {
    expect(++steps, lessThan(1500), reason: 'the game should end');
    final d = p.onTurn;
    final other = d == p.hostDevice ? p.guestDevice : p.hostDevice;
    final g = p.controllerOf(d).game as MauMauGame; // the device's own view
    final n = p.host.moves.length;
    // The other device has nothing to tap.
    expect(other.hasKey(const Key('maumau-draw')) && tester.widget<ButtonStyleButton>(other.on(find.byKey(const Key('maumau-draw')))).enabled,
        isFalse);
    final playable = g.playableCards;
    if (playable.isNotEmpty && (g.hasDrawn || g.mustPlayNow || rng.nextInt(5) > 0)) {
      if (g.hasDrawn && rng.nextInt(4) == 0) {
        await d.tapKey(tester, const Key('maumau-keep'));
        tapped.add('${d.me!.name} pass');
        count('keep');
      } else {
        final card = playable[rng.nextInt(playable.length)];
        var mau = false;
        if (g.mauDue) {
          if (rng.nextInt(3) > 0) {
            await d.tapKey(tester, const Key('maumau-mau'));
            mau = true;
            count('mau');
          } else {
            count('forgot');
          }
        }
        await _tapCard(tester, d, card);
        if (card.rank == MauMauRank.jack) {
          expect(d.hasKey(const Key('maumau-suit-picker')), isTrue);
          final suit = MauMauSuit.values[rng.nextInt(4)];
          await d.tapKey(tester, Key('maumau-suit-${suit.code}'));
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
        if (card.rank == MauMauRank.seven && g.penalty > 0) count('stacked');
        tapped.add('${d.me!.name} play ${card.id}${mau ? ' mau' : ''}');
      }
    } else if (g.canDraw) {
      await d.tapKey(tester, const Key('maumau-draw'));
      tapped.add('${d.me!.name} draw');
      count(d == p.hostDevice ? 'hostDraw' : 'guestDraw');
    } else if (g.hasDrawn) {
      await d.tapKey(tester, const Key('maumau-keep'));
      tapped.add('${d.me!.name} pass');
    } else {
      expect(g.canPass, isTrue);
      await d.tapKey(tester, const Key('maumau-pass'));
      tapped.add('${d.me!.name} pass');
    }
    await p.synced(n + 1, why: tapped.last);
    final last = p.host.moves.last;
    expect('${last.player.name} ${last.move['action']}${last.move['card'] == null ? '' : ' ${last.move['card']}'}'
        '${last.move['mau'] == true ? ' mau' : ''}', tapped.last, reason: 'the host applied the tapped move');
    // A draw that ended the turn: the drawn cards are framed on the
    // drawer's device only (the other sees a count).
    final payload = last.event.payload;
    if (last.move['action'] == 'draw' && !p.engine.isOver && p.engine.currentPlayer != last.player) {
      final drew = [for (final id in (payload as Map)['drew'] as List) '$id'];
      final drawer = last.player == Player.a ? p.hostDevice : p.guestDevice;
      final watcher = last.player == Player.a ? p.guestDevice : p.hostDevice;
      expect(_shownHand(drawer), containsAll(drew));
      expect(_shownHand(watcher).intersection(drew.toSet()), isEmpty);
      final watcherMove = p.controllerOf(watcher).moves.last;
      expect((watcherMove.event.payload as Map).containsKey('drew'), watcher == p.hostDevice,
          reason: 'the guest gets the host\'s draw as a count');
    }
    _checkScreens(p, 'after ${tapped.last}');
  }
  for (var i = 0; i < 50 && p.devices.any((d) => !d.resultShown()); i++) {
    await p.net();
  }
  for (final d in p.devices) {
    expect(d.resultShown(), isTrue, reason: d.name);
  }
  final h = p.engine as MauMauGame;
  expect(h.result.code, GameEndReason.maumauEmptyHand);
  expect(p.guestController.game.result.winner, h.result.winner);
  await p.expectVerified();
  // The guest's log is the host's, redacted.
  expect([for (final m in p.guestController.moves) m.move], [for (final m in p.hostController.moves) m.move]);
  return seen;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.shared.markFirst(SeenTips.maumauIntro);
    // Only taps a finger could make: a tap on something covered fails.
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final (name, rules, seed, link) in [
    ('default rules over TCP (Wi-Fi proxy)', const MauMauRules(), 3, NetLink.tcp),
    ('every house rule on over WebSocket', const MauMauRules(jackOnJack: true), 5, NetLink.ws),
    ('no 7, 8 or ace, drawing allowed, through the relay',
        const MauMauRules(sevenDraws: false, eightSkips: false, aceAgain: false, mustPlay: false), 6, NetLink.relay),
  ]) {
    testWidgets('a whole network game through the UI: $name', (tester) async {
      final seen = await _playGame(tester, GameConfig('maumau', seed: seed, mauMau: rules), link, Random(seed));
      debugPrint('maumau network $name: $seen');
      expect((seen['hostDraw'] ?? 0) + (seen['guestDraw'] ?? 0), greaterThan(0));
    }, timeout: liveUiTimeout);
  }
}
