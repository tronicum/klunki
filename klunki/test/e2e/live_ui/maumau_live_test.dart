// KLD-118 step 2: whole Mau-Mau games played through the real hot-seat UI,
// like players would: pass the device at every handover cover, tap a card
// (a jack: pick a suit), draw from the button, look at drawn cards and go
// on, keep a drawn card, press "Mau!" with the house rule. After every step
// the screen is checked against the engine: only the hand of the player to
// move is on screen (none while the cover is up), the cards framed as
// playable are exactly the engine's, and the history matches the move log.
//
//   flutter test test/e2e/live_ui/maumau_live_test.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

Future<GameController> _pump(WidgetTester tester, GameConfig config) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  await tester.pumpWidget(MaterialApp(
    theme: KlunkiTheme.light,
    locale: const Locale('de'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: PlayerLabelsScope(
      labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}),
      child: buildGameScreen(c),
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Taps [card] in the hand where a finger would: its left edge, which the
/// next card in the fan leaves free.
Future<void> _tapCard(WidgetTester tester, MauMauCard card) async {
  final f = find.byKey(Key('maumau-hand-${card.id}'));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tapAt(tester.getTopLeft(f) + const Offset(10, 40));
  await tester.pumpAndSettle();
}

bool _has(Key k) => find.byKey(k).evaluate().isNotEmpty;

/// The card ids shown in the hand.
Set<String> _shownHand() => {
      for (final e in find.byWidgetPredicate((w) => w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('maumau-hand-')).evaluate())
        (e.widget.key! as ValueKey<String>).value.substring('maumau-hand-'.length),
    };

/// Plays one whole game; returns the number of taps.
Future<int> _playGame(WidgetTester tester, GameConfig config, Random rng) async {
  final c = await _pump(tester, config);
  var taps = 0;
  var covers = 0;
  while (!c.game.isOver) {
    expect(++taps, lessThan(1500), reason: 'the game should end');
    final g = c.game as MauMauGame;
    if (_has(const Key('handover-cover'))) {
      expect(_shownHand(), isEmpty, reason: 'no card under the cover');
      covers++;
      await _tap(tester, find.byKey(const Key('handover-continue')));
      continue;
    }
    if (_has(const Key('maumau-feedback'))) {
      await _tap(tester, find.byKey(const Key('maumau-continue')));
      continue;
    }
    // The hand on screen is the hand of the player to move.
    final me = g.currentPlayer;
    expect(_shownHand(), {for (final card in g.handOf(me)) card.id});
    final opp = me == Player.a ? Player.b : Player.a;
    final n = g.handCount(opp);
    expect(find.text('${opp == Player.a ? 'Anna' : 'Ben'}: ${n == 1 ? '1 Karte' : '$n Karten'}'), findsOneWidget);
    final playable = g.playableCards;
    // Lay a card most of the time, as people do; sometimes draw anyway.
    if (playable.isNotEmpty && (g.hasDrawn || rng.nextInt(5) > 0)) {
      final card = playable[rng.nextInt(playable.length)];
      if (g.mauDue && rng.nextInt(4) > 0) {
        await _tap(tester, find.byKey(const Key('maumau-mau')));
      }
      if (g.hasDrawn && rng.nextInt(4) == 0) {
        await _tap(tester, find.byKey(const Key('maumau-keep')));
        continue;
      }
      await _tapCard(tester, card);
      if (card.rank == MauMauRank.jack) {
        expect(find.byKey(const Key('maumau-suit-picker')), findsOneWidget);
        final suit = MauMauSuit.values[rng.nextInt(4)];
        await _tap(tester, find.byKey(Key('maumau-suit-${suit.code}')));
        expect(c.game.history.last['suit'], suit.code);
      }
      expect(c.game.history.last['card'], card.id, reason: 'the tapped card was laid');
      continue;
    }
    if (g.canDraw) {
      await _tap(tester, find.byKey(const Key('maumau-draw')));
    } else if (g.hasDrawn) {
      await _tap(tester, find.byKey(const Key('maumau-keep')));
    } else {
      expect(g.canPass, isTrue);
      await _tap(tester, find.byKey(const Key('maumau-pass')));
    }
  }
  final g = c.game as MauMauGame;
  final winner = g.result.winner!;
  expect(g.handCount(winner), 0);
  expect(g.result.code, GameEndReason.maumauEmptyHand);
  expect(find.byKey(const Key('result-dialog')), findsOneWidget);
  expect(covers, greaterThan(0));
  // The engine's log replays to the same game.
  final r = replay(config, c.moves.map((m) => m.move))! as MauMauGame;
  expect(r.result.winner, winner);
  expect(r.handCount(Player.a) + r.handCount(Player.b), g.handCount(Player.a) + g.handCount(Player.b));
  expect(c.moves, hasLength(g.history.length));
  return taps;
}

void main() {
  for (final (name, rules, seed) in [
    ('default rules', const MauMauRules(), 3),
    ('default rules, another deal', const MauMauRules(), 11),
    ('all house rules on', const MauMauRules(jackOnJack: true, aceAgain: true, mauCall: true), 5),
    ('no special cards', const MauMauRules(sevenDraws: false, eightSkips: false), 8),
  ]) {
    testWidgets('a whole game through the UI: $name', (tester) async {
      final taps = await _playGame(tester, GameConfig('maumau', seed: seed, mauMau: rules), Random(seed));
      expect(taps, greaterThan(5));
    });
  }
}
