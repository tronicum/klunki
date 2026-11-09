// KLD-121 step 2: Mäxchen for 3 and 4 players on one device, played to the
// end through the real UI like a table of players: whoever is to move takes
// the device behind the handover cover (which names them, with their seat
// token), shakes the cup with "Würfeln", lifts it with "Nachschauen" (and
// checks that the dice shown are the own ones), picks a value from the grid
// (the truth when it beats the announcement, else a bluff) and announces
// it; the next player believes, doubts or, after a Mäxchen, gives up a
// life. A third game uses "Unbegrenzte Leben" and is ended by the players
// with "Spiel beenden" from the "⋮" menu.
//
// Checks after every step: the status pill names the seat to move, the seat
// to move always got the device through a cover (nobody acts on another
// player's device), the dice are never on the table for anyone but their
// roller (until a doubt lifts the cup), the hearts (or the tally) on
// screen are the engine's, a player without lives never moves again. At the
// end the ranking lists every seat in the order the players went out (or by
// lives lost).
//
//   cd klunki && flutter test test/e2e/live_ui/maexchen_seats_live_test.dart
//   KLUNKI_LIVE_UI_VERBOSE=1 flutter test test/e2e/live_ui/maexchen_seats_live_test.dart
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/games/maexchen/maexchen_dice.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import '../../support/test_run.dart';
import 'live_ui_driver.dart';

const _names = ['Anna', 'Ben', 'Cleo', 'Dani'];

String? _textOf(WidgetTester tester, Key k) {
  final f = find.byKey(k);
  return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
}

/// The hearts (or the tally) on screen are the engine's.
void _checkLives(WidgetTester tester, MaexchenGame g) {
  for (var s = 0; s < g.playerCount; s++) {
    final k = 'abcd'[s];
    if (g.unlimitedLives) {
      expect(_textOf(tester, Key('maexchen-lost-$k')), '${g.lostOf(s)}', reason: 'tally of ${_names[s]}');
    } else {
      for (var i = 0; i < g.startLives; i++) {
        expect(tester.widget<Icon>(find.byKey(Key('maexchen-heart-$k-$i'))).icon,
            i < g.livesOfSeat(s) ? Icons.favorite : Icons.favorite_border,
            reason: 'heart $i of ${_names[s]}');
      }
    }
  }
}

/// Plays [config] through the UI; with [endAfterRounds] ("Unbegrenzte
/// Leben") the players end the game from the menu after that many rounds.
Future<GameController> _play(WidgetTester tester, GameConfig config, Random rng,
    {int? endAfterRounds, int maxSteps = 6000}) async {
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pump();
  await tester.pump();
  expect(find.byType(SeatGameScreen), findsOneWidget);
  final d = UiDevice('hot-seat');
  final alive = testRunGuard(tester);
  final log = <String>[];
  final covers = <int>{};
  var holder = 0; // the seat holding the device
  final tapped = <String, int>{};
  for (var step = 0; step < maxSteps; step++) {
    alive();
    if (d.resultShown()) break;
    final g = c.game as MaexchenGame;
    if (d.hasKey(const Key('handover-cover'))) {
      final seat = g.actorSeat!;
      expect(g.isSeatOut(seat), isFalse);
      expect(find.text(deL10n.shellHandoverPass(_names[seat])), findsOneWidget, reason: 'cover for seat $seat');
      expect(tester.widget<SeatToken>(find.byKey(const Key('handover-seat'))).seat, seat);
      expect(find.byKey(const Key('maexchen-table')).hitTestable(), findsNothing, reason: 'the table is covered');
      covers.add(seat);
      log.add('cover ${_names[seat]}');
      await d.tapKey(tester, const Key('handover-continue'));
      await tester.pumpAndSettle();
      holder = seat;
      continue;
    }
    final seat = g.actorSeat!;
    expect(seat, holder, reason: '${_names[seat]} acts without the device\n${log.join('\n')}');
    expect(g.isSeatOut(seat), isFalse, reason: 'a player who is out never moves');
    expect(_textOf(tester, const Key('shell-status')), deL10n.shellToMove(_names[seat]));
    _checkLives(tester, g);
    final onTable = tester.widget<CupTable>(find.byType(CupTable)).dice;
    if (onTable != null) {
      // Open dice: the last round's after a doubt, never a closed cup's.
      expect(g.roller, isNull);
      expect(g.lastRound?.dice, isNotNull);
    }
    if (endAfterRounds != null && g.round > endAfterRounds && g.phase == MaexchenPhase.roll && g.roller == null) {
      log.add('${_names[seat]}: Spiel beenden');
      await d.tapKey(tester, const Key('shell-menu'));
      await tester.pumpAndSettle();
      await d.tapKey(tester, const Key('maexchen-end'));
      await tester.pumpAndSettle();
      expect(find.text(deL10n.maexchenEndGameTitle), findsOneWidget);
      await d.tapKey(tester, const Key('maexchen-end-confirm'));
      await tester.pumpAndSettle();
      tapped['end'] = 1;
      continue;
    }
    switch (g.phase) {
      case MaexchenPhase.roll:
        await d.tapKey(tester, const Key('maexchen-roll'));
        tapped.update('roll', (v) => v + 1, ifAbsent: () => 1);
        log.add('${_names[seat]} rolls');
      case MaexchenPhase.announce:
        // Lift the cup: the dice shown are the own ones (high die first).
        await d.tapKey(tester, const Key('maexchen-peek'));
        await tester.pumpAndSettle();
        final dice = g.dice!;
        final shown = tester.widget<CupTable>(find.byType(CupTable)).dice;
        expect(shown, dice[0] >= dice[1] ? dice : [dice[1], dice[0]]);
        final real = g.diceValue!;
        final above = MaexchenGame.valuesAbove(g.announced);
        final truth = above.contains(real) && rng.nextInt(4) > 0;
        final value = truth ? real : above[min(above.length - 1, rng.nextInt(3))];
        await d.tapKey(tester, Key('maexchen-value-$value'));
        await d.tapKey(tester, const Key('maexchen-announce'));
        tapped.update(truth ? 'truth' : 'bluff', (v) => v + 1, ifAbsent: () => 1);
        log.add('${_names[seat]} says $value (rolled $real)');
      case MaexchenPhase.respond:
        final maexchen = g.announced == MaexchenGame.maexchen;
        final doubt = rng.nextInt(10) < (maexchen ? 5 : 4);
        final key = doubt ? 'maexchen-doubt' : (maexchen ? 'maexchen-giveup' : 'maexchen-believe');
        await d.tapKey(tester, Key(key));
        tapped.update(key, (v) => v + 1, ifAbsent: () => 1);
        log.add('${_names[seat]} taps $key');
    }
    await tester.pumpAndSettle();
    final after = c.game as MaexchenGame;
    if ((after.lastRound?.round ?? 0) == g.round && after.round == g.round + 1) {
      // The round just ended: the verdict names the loser.
      final end = after.lastRound!;
      log.add('round ${end.round}: ${_names[end.loser]} loses ${end.lost}');
      expect(find.textContaining(_names[end.loser]), findsWidgets);
    }
  }
  final g = c.game as MaexchenGame;
  expect(g.isOver, isTrue, reason: 'did not end in $maxSteps steps\n${log.join('\n')}');
  await tester.pumpAndSettle();
  expect(covers, containsAll([for (var s = 1; s < g.playerCount; s++) s]), reason: 'every player had the device');
  expect(tapped['bluff'] ?? 0, greaterThan(0), reason: '$tapped');
  expect(tapped['maexchen-doubt'] ?? 0, greaterThan(0), reason: '$tapped');
  debugPrint('maexchen ${g.playerCount} players${g.unlimitedLives ? ', unlimited' : ''}: $tapped, '
      '${c.moves.length} moves, ${g.round - 1} rounds, out ${g.outSeats}, lost ${g.lost}');
  if (liveUiVerbose) debugPrint(log.join('\n'));
  return c;
}

/// The ranking: every seat in place order with its text.
void _checkResult(WidgetTester tester, GameController c) {
  final g = c.game as MaexchenGame;
  final r = g.seatResult;
  expect(find.byKey(const Key('result-dialog')), findsOneWidget);
  final w = r.winner;
  expect(find.descendant(of: find.byKey(const Key('result-dialog')), matching: find.text(w == null ? deL10n.seatSharedFirst : deL10n.shellWins(_names[w]))),
      findsOneWidget);
  final order = r.ranking;
  for (var i = 1; i < order.length; i++) {
    expect(tester.getTopLeft(find.byKey(Key('result-rank-${order[i - 1]}'))).dy,
        lessThan(tester.getTopLeft(find.byKey(Key('result-rank-${order[i]}'))).dy));
  }
  for (var s = 0; s < g.playerCount; s++) {
    final text = g.unlimitedLives
        ? deL10n.maexchenResultLost(g.lostOf(s))
        : g.isSeatOut(s)
            ? deL10n.maexchenResultOut
            : deL10n.maexchenResultLives(g.livesOfSeat(s));
    expect(find.descendant(of: find.byKey(Key('result-rank-$s')), matching: find.text(text)), findsOneWidget,
        reason: _names[s]);
  }
  if (g.unlimitedLives) {
    expect(r.code, GameEndReason.maexchenEnded.code);
    expect(_textOf(tester, const Key('result-reason')), deL10n.engineReasonMaexchenEnded);
    for (var i = 1; i < order.length; i++) {
      expect(g.lostOf(order[i - 1]), lessThanOrEqualTo(g.lostOf(order[i])));
    }
  } else {
    expect(r.code, GameEndReason.maexchenNoLives.code);
    // Out in reverse order: the one who went out last is second.
    expect(order.skip(1).toList(), g.outSeats.reversed.toList());
  }
}

Future<void> _loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Roboto/Roboto-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadRoboto);
  // Only taps a finger could make: a tap on something covered fails.
  setUp(() {
    WidgetController.hitTestWarningShouldBeFatal = true;
    SharedPreferences.setMockInitialValues({});
    ExtraSeatNames.debugReset();
    SeenTips.debugReset();
  });
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  void phone(WidgetTester tester, Size size) {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('3 players, 3 lives: a whole game to the last one with lives; "Nochmal" keeps 3', (tester) async {
    phone(tester, const Size(393, 852));
    final c = await _play(tester, const GameConfig('maexchen', seed: 5, players: 3), Random(5));
    _checkResult(tester, c);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('result-again')));
    await tester.pumpAndSettle();
    expect((c.game as MaexchenGame).playerCount, 3);
    expect(c.moves, isEmpty);
  }, timeout: liveUiTimeout);

  testWidgets('4 players, 5 lives, "Mäxchen doppelt", iPhone SE: a whole game', (tester) async {
    phone(tester, const Size(375, 667));
    final c = await _play(tester, const GameConfig('maexchen', seed: 9, players: 4, lives: 5), Random(9));
    _checkResult(tester, c);
    expect((c.game as MaexchenGame).outSeats, hasLength(3));
    expect(tester.takeException(), isNull);
  }, timeout: liveUiTimeout);

  testWidgets('"Unbegrenzte Leben", 4 players: nobody drops out; the players end it after 12 rounds',
      (tester) async {
    phone(tester, const Size(393, 852));
    final c = await _play(
        tester, const GameConfig('maexchen', seed: 4, players: 4, lives: 1, maexchenUnlimited: true), Random(4),
        endAfterRounds: 12);
    final g = c.game as MaexchenGame;
    expect(g.ended, isTrue);
    expect(g.outSeats, isEmpty, reason: 'with 1 life each, still nobody dropped out');
    expect(g.round, 13);
    expect(g.lost.fold<int>(0, (a, b) => a + b), greaterThanOrEqualTo(12));
    _checkResult(tester, c);
    expect(tester.takeException(), isNull);
  }, timeout: liveUiTimeout);
}
