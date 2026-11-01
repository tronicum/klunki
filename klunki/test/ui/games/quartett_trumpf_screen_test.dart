import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki/ui/games/quartett_card.dart';
import 'package:klunki/ui/games/quartett_trumpf_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../shell/shell_test_utils.dart';
import '../../l10n/l10n_test_utils.dart';

const reveal = Key('qt-reveal');
const cont = Key('qt-continue');
Key statKey(String id) => Key('qt-stat-$id');

QuartettGame fresh(int seed) => QuartettGame(QuartettMode.trumpf, seed: seed);

/// First (seed, stat) whose opening trick satisfies [test] (va = X, vb = O).
(int, QuartettStat) findOpening(bool Function(QuartettStat s, num va, num vb) test) {
  for (var seed = 1; seed < 5000; seed++) {
    final g = fresh(seed);
    final a = g.topCard(Player.a)!, b = g.topCard(Player.b)!;
    for (final s in QuartettDeck.cars.stats) {
      if (test(s, a.stats[s.id]!, b.stats[s.id]!)) return (seed, s);
    }
  }
  throw StateError('no matching seed');
}

Future<void> pick(WidgetTester tester, String statId) async {
  await tester.ensureVisible(find.byKey(statKey(statId)));
  await tester.tap(find.byKey(statKey(statId)));
  await tester.pump();
}

Future<void> tapContinue(WidgetTester tester) async {
  await tester.tap(find.byKey(cont));
  await tester.pump();
}

void main() {
  testWidgets('shows the top card with all stats, the hint and stack counts', (tester) async {
    final c = await pumpGame(tester, 'quartett-trumpf', seed: 1);
    await tester.pump(); // hint is set post-frame
    final g = c.game as QuartettGame;
    final top = g.topCard(Player.a)!;

    expect(find.text(top.id), findsOneWidget);
    expect(find.text(top.name), findsOneWidget);
    expect(find.text(QuartettDeck.cars.setNames[top.set]!), findsOneWidget);
    for (final s in QuartettDeck.cars.stats) {
      final row = find.byKey(statKey(s.id));
      expect(row, findsOneWidget);
      expect(find.descendant(of: row, matching: find.text(s.label)), findsOneWidget);
      expect(find.descendant(of: row, matching: find.text(formatQuartettValue(s, top.stats[s.id]!))), findsOneWidget);
      expect(find.descendant(of: row, matching: find.byIcon(s.higherWins ? Icons.arrow_upward : Icons.arrow_downward)),
          findsOneWidget);
    }
    expect(find.text('Wähle eine Eigenschaft deiner Karte'), findsOneWidget);
    expect(find.text('Anna: 16 Karten'), findsOneWidget);
    expect(find.text('Ben: 16 Karten'), findsOneWidget);
    expect(find.byKey(const Key('qt-pot')), findsNothing);
  });

  testWidgets('the opponent card is hidden before picking', (tester) async {
    final c = await pumpGame(tester, 'quartett-trumpf', seed: 1);
    final g = c.game as QuartettGame;
    final opp = g.topCard(Player.b)!;
    expect(find.text(opp.name, skipOffstage: false), findsNothing);
    expect(find.text(opp.id, skipOffstage: false), findsNothing);
    expect(find.byKey(const Key('qt-opponent-stack')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('qt-opponent-stack')), matching: find.text('16 Karten')),
        findsOneWidget);
    expect(find.byKey(reveal), findsNothing);
  });

  testWidgets("picking a stat reveals the trick with the engine's winner", (tester) async {
    final (seed, stat) = findOpening((s, va, vb) => s.beats(va, vb));
    final c = await pumpGame(tester, 'quartett-trumpf', seed: seed);
    final g = c.game as QuartettGame;
    final a = g.topCard(Player.a)!, b = g.topCard(Player.b)!;
    final expected = fresh(seed).applyMove({'action': 'pick', 'stat': stat.id})!.payload as Map;
    expect(expected['trickWinner'], 'a');

    await pick(tester, stat.id);
    expect(find.byKey(reveal), findsOneWidget);
    expect(c.moves, isEmpty, reason: 'the pick is submitted only on "Weiter"');
    expect(find.text('Anna gewinnt die Runde'), findsOneWidget);
    expect(find.text(a.name), findsOneWidget);
    expect(find.text(b.name), findsOneWidget);
    expect(find.text('Anna – gewinnt'), findsOneWidget);
    expect(find.text('Ben – verliert'), findsOneWidget);
    // The chosen stat is highlighted on both cards in the outcome colours.
    final aValue = find.descendant(
        of: find.byKey(const Key('qt-reveal-a')), matching: find.text(formatQuartettValue(stat, a.stats[stat.id]!)));
    final bValue = find.descendant(
        of: find.byKey(const Key('qt-reveal-b')), matching: find.text(formatQuartettValue(stat, b.stats[stat.id]!)));
    expect(tester.widget<Text>(aValue).style?.color, quartettOutcomeColor(QuartettOutcome.win));
    expect(tester.widget<Text>(bValue).style?.color, quartettOutcomeColor(QuartettOutcome.lose));
    // Stays until "Weiter".
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(reveal), findsOneWidget);

    await tapContinue(tester);
    expect(c.moves, hasLength(1));
    expect((c.lastEvent!.payload as Map)['trickWinner'], expected['trickWinner']);
    expect(find.byKey(reveal), findsNothing);
    expect(c.needsHandover, isFalse); // X won, X picks again
    expect(find.text('Anna: 17 Karten'), findsOneWidget);
    expect(find.text('Ben: 15 Karten'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shell-history')));
    await tester.pumpAndSettle();
    expect(find.text('Anna: wählt ${stat.label}'), findsOneWidget);
    expect(find.textContaining(a.name), findsNothing);
  });

  testWidgets('a tie puts both cards into the pot, same player again', (tester) async {
    final (seed, stat) = findOpening((s, va, vb) => va == vb);
    final c = await pumpGame(tester, 'quartett-trumpf', seed: seed);
    await pick(tester, stat.id);
    expect(find.text('Gleichstand – Stechen!'), findsOneWidget);
    expect(find.text('Anna – Gleichstand'), findsOneWidget);
    expect(find.text('Ben – Gleichstand'), findsOneWidget);
    final a = (c.game as QuartettGame).topCard(Player.a)!;
    final value = find.descendant(
        of: find.byKey(const Key('qt-reveal-a')), matching: find.text(formatQuartettValue(stat, a.stats[stat.id]!)));
    expect(tester.widget<Text>(value).style?.color, quartettOutcomeColor(QuartettOutcome.tie));

    await tapContinue(tester);
    expect((c.lastEvent!.payload as Map)['trickWinner'], isNull);
    expect(c.needsHandover, isFalse);
    expect(find.text('Topf: 2 Karten'), findsOneWidget);
    expect(find.text('Anna: 15 Karten'), findsOneWidget);
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    expect(find.byKey(statKey(stat.id)), findsOneWidget);
  });

  testWidgets('handover cover after the turn passes; next cards stay secret', (tester) async {
    final (seed, stat) = findOpening((s, va, vb) => s.beats(vb, va));
    final c = await pumpGame(tester, 'quartett-trumpf', seed: seed);
    await pick(tester, stat.id);
    expect(find.text('Ben gewinnt die Runde'), findsOneWidget);
    expect(find.byKey(handoverContinue), findsNothing, reason: 'both players watch the reveal');

    await tapContinue(tester);
    expect(c.needsHandover, isTrue);
    expect(find.text('Gib das Gerät an Ben weiter'), findsOneWidget);
    final g = c.game as QuartettGame;
    final oTop = g.topCard(Player.b)!, xTop = g.topCard(Player.a)!;
    expect(find.text(oTop.name), findsNothing);
    expect(find.text(xTop.name), findsNothing);

    await tester.tap(find.byKey(handoverContinue));
    await tester.pump();
    expect(find.text('Ben ist am Zug'), findsOneWidget);
    expect(find.text(oTop.name), findsOneWidget);
    expect(find.text(xTop.name, skipOffstage: false), findsNothing);
  });

  testWidgets('a full game of picks ends in the result dialog', (tester) async {
    final c = await pumpGame(tester, 'quartett-trumpf', seed: 3);
    for (var i = 0; i < 1500 && find.byKey(resultDialog).evaluate().isEmpty; i++) {
      if (find.byKey(handoverContinue).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(handoverContinue));
      } else if (find.byKey(cont).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(cont));
      } else {
        final s = QuartettDeck.cars.stats[i % QuartettDeck.cars.stats.length];
        await tester.ensureVisible(find.byKey(statKey(s.id)));
        await tester.tap(find.byKey(statKey(s.id)));
      }
      await tester.pump();
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(c.game.isOver, isTrue);
    expect(find.byKey(resultDialog), findsOneWidget);
    expect(find.text(localizedResultReason(deL10n, c.game.result)), findsOneWidget);
  });

  testWidgets('phone width: card, stack and reveal lay out without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpGame(tester, 'quartett-trumpf', seed: 1);
    expect(find.byKey(const Key('qt-opponent-stack')), findsOneWidget);
    await pick(tester, 'kmh');
    expect(find.byKey(reveal), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('who picks next (KLD-091)', () {
    String cue(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('qt-next-picker'))).data!;
    String button(WidgetTester tester) =>
        tester.widget<Text>(find.descendant(of: find.byKey(cont), matching: find.byType(Text))).data!;
    // KLD-092: while the result is shown (the pick is applied only on
    // "Weiter") the status line names the next picker like the cue, not the
    // live "X ist am Zug".
    String status(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('shell-status'))).data!;

    testWidgets('win: "Anna wählt noch einmal", no cover, Anna goes on', (tester) async {
      final (seed, stat) = findOpening((s, va, vb) => s.beats(va, vb));
      final c = await pumpGame(tester, 'quartett-trumpf', seed: seed);
      await pick(tester, stat.id);
      expect(find.text('Anna gewinnt die Runde'), findsOneWidget);
      expect(cue(tester), 'Anna wählt noch einmal');
      expect(button(tester), 'Weiter – Anna wählt');
      expect(status(tester), 'Anna wählt noch einmal');
      expect(find.text('Anna ist am Zug'), findsNothing);

      await tapContinue(tester);
      expect(c.needsHandover, isFalse);
      expect(find.byKey(const Key('handover-cover')), findsNothing, reason: 'nothing has to be passed');
      final top = (c.game as QuartettGame).topCard(Player.a)!;
      expect(find.text(top.name), findsOneWidget, reason: 'Anna picks again at once');
      expect(find.text('Anna ist am Zug'), findsOneWidget);
    });

    testWidgets('loss: "Ben wählt als Nächstes", then the cover names Ben and why', (tester) async {
      final (seed, stat) = findOpening((s, va, vb) => s.beats(vb, va));
      final c = await pumpGame(tester, 'quartett-trumpf', seed: seed);
      await pick(tester, stat.id);
      expect(find.text('Ben gewinnt die Runde'), findsOneWidget);
      expect(cue(tester), 'Ben wählt als Nächstes');
      expect(button(tester), 'Weiter – Ben wählt');
      expect(status(tester), 'Ben wählt als Nächstes');
      expect(find.text('Anna ist am Zug'), findsNothing, reason: 'no contradiction to the result');

      await tapContinue(tester);
      expect(c.needsHandover, isTrue);
      final cover = find.byKey(const Key('handover-cover'));
      expect(find.descendant(of: cover, matching: find.text('Gib das Gerät an Ben weiter')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('qt-handover-reason'))).data, 'Ben hat die Runde gewonnen');
      expect(find.descendant(of: cover, matching: find.text('Ich bin Ben – weiter')), findsOneWidget);
    });

    testWidgets('tie: "Gleichstand – Stechen!", "Karten in den Topf (jetzt 2), Anna wählt noch einmal", no cover',
        (tester) async {
      final (seed, stat) = findOpening((s, va, vb) => va == vb);
      final c = await pumpGame(tester, 'quartett-trumpf', seed: seed);
      await pick(tester, stat.id);
      expect(find.text('Gleichstand – Stechen!'), findsOneWidget);
      expect(cue(tester), 'Karten in den Topf (jetzt 2), Anna wählt noch einmal');
      expect(button(tester), 'Weiter – Anna wählt');
      expect(status(tester), 'Anna wählt noch einmal');
      await tapContinue(tester);
      expect(c.needsHandover, isFalse);
      expect(find.byKey(const Key('handover-cover')), findsNothing);
    });

    testWidgets('a streak and a switch: a cover only when the device has to change hands', (tester) async {
      final c = await pumpGame(tester, 'quartett-trumpf', seed: 5);
      var covers = 0, repeats = 0;
      for (var i = 0; i < 40; i++) {
        final g = c.game as QuartettGame;
        final picker = g.currentPlayer;
        final s = QuartettDeck.cars.stats[i % QuartettDeck.cars.stats.length];
        await pick(tester, s.id);
        await tapContinue(tester);
        final w = (c.lastEvent!.payload as Map)['trickWinner'];
        final next = w == null ? picker : Player.values.byName(w as String);
        final covered = find.byKey(const Key('handover-cover')).evaluate().isNotEmpty;
        expect(covered, next != picker, reason: 'trick $i: cover only when ${next.name} != ${picker.name}');
        if (covered) {
          covers++;
          final mark = testName(next);
          expect(find.text('Gib das Gerät an $mark weiter'), findsOneWidget);
          expect(tester.widget<Text>(find.byKey(const Key('qt-handover-reason'))).data, '$mark hat die Runde gewonnen');
          await tester.tap(find.byKey(handoverContinue));
          await tester.pump();
        } else {
          repeats++;
        }
        if (c.game.isOver) break;
      }
      expect(covers, greaterThan(0));
      expect(repeats, greaterThan(0));
    });
  });

  test('describeMove names only the stat', () async {
    final c = GameController.hotSeat(const GameConfig('quartett-trumpf', seed: 1));
    addTearDown(c.dispose);
    await c.submit({'action': 'pick', 'stat': 'kmh'});
    expect(QuartettTrumpfScreen.describeMove(deL10n, c.moves.single), 'wählt Höchstgeschwindigkeit');
  });
}
