// KLD-119: Ausgewürfelt in hot-seat for 2–4 players, played through the real
// UI (taps on the dice, "Würfeln" and the sheet; never `controller.submit`).
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/beginner_settings.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/shake_settings.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<GameController> _pump(WidgetTester tester, GameConfig config, {List<List<int>> rolls = const []}) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  (c.game as DiceSheetGame).debugScriptRolls(rolls);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

/// Plays one turn through the UI like a careful player: rolls, keeps the
/// most common face (taps those dice), rolls again while that helps, then
/// taps the best box on the sheet.
Future<void> _playTurn(WidgetTester tester, GameController c, Random rng) async {
  final g = c.game as DiceSheetGame;
  final seat = g.currentSeat;
  await _tap(tester, 'dicesheet-roll');
  while (g.rollsLeft > 0 && rng.nextInt(3) > 0) {
    final counts = List.filled(7, 0);
    for (final d in g.dice) {
      counts[d]++;
    }
    var face = 6;
    for (var f = 6; f >= 1; f--) {
      if (counts[f] > counts[face]) face = f;
    }
    if (counts[face] == 5) break;
    for (var i = 0; i < 5; i++) {
      final kept = find.descendant(of: _key('dicesheet-die-$i'), matching: find.text('behalten')).evaluate().isNotEmpty;
      if ((g.dice[i] == face) != kept) await _tap(tester, 'dicesheet-die-$i');
    }
    final before = g.dice;
    await _tap(tester, 'dicesheet-roll');
    for (var i = 0; i < 5; i++) {
      if (before[i] == face) expect(g.dice[i], face, reason: 'a kept die stays');
    }
  }
  final allowed = g.allowedBoxes;
  final best = allowed.reduce((a, b) => g.scoreIfFilled(b)! > g.scoreIfFilled(a)! ? b : a);
  final points = g.scoreIfFilled(best)!;
  final scoreKey = 'dicesheet-score-${best.id}';
  expect(_key(scoreKey), findsOneWidget);
  await _tap(tester, scoreKey);
  expect(g.entryOf(seat, best), points);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ShakeSettings.debugReset();
    BeginnerSettings.debugReset();
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.dicesheetIntro);
    ExtraSeatNames.debugReset();
  });

  testWidgets('roll, keep, fill: the sheet shows what each box would score', (tester) async {
    final c = await _pump(tester, const GameConfig('dicesheet', seed: 1), rolls: [
      [3, 3, 5, 1, 6],
      [2, 4, 3, 2, 3],
    ]);
    var g = c.game as DiceSheetGame;
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    expect(find.text('Tippe auf Würfeln.'), findsOneWidget);
    expect(find.text('Würfeln (noch 3)'), findsOneWidget);
    expect(_key('dicesheet-score-chance'), findsNothing, reason: 'nothing to fill before the first roll');
    expect(find.text('Runde 1/13'), findsOneWidget);

    await _tap(tester, 'dicesheet-roll');
    expect(g.dice, [3, 3, 5, 1, 6]);
    expect(find.text('Würfeln (noch 2)'), findsOneWidget);
    // Suggestions in Anna's column only.
    expect(find.descendant(of: _key('dicesheet-score-threes'), matching: find.text('6')), findsOneWidget);
    expect(find.descendant(of: _key('dicesheet-score-chance'), matching: find.text('18')), findsOneWidget);
    expect(find.descendant(of: _key('dicesheet-score-fullHouse'), matching: find.text('0')), findsOneWidget);
    expect(find.descendant(of: _key('dicesheet-cell-1-chance'), matching: find.byType(InkWell)), findsNothing);

    // Keep both threes: framed, "behalten", stay after the roll.
    await _tap(tester, 'dicesheet-die-0');
    await _tap(tester, 'dicesheet-die-1');
    expect(find.text('behalten'), findsNWidgets(2));
    await _tap(tester, 'dicesheet-die-1');
    expect(find.text('behalten'), findsOneWidget, reason: 'a second tap lets it go');
    await _tap(tester, 'dicesheet-die-1');
    await _tap(tester, 'dicesheet-roll');
    // Kept 0 and 1 (3, 3); the others from the second draw.
    expect(g.dice, [3, 3, 3, 2, 3]);
    expect(find.text('behalten'), findsNWidgets(2), reason: 'still kept for the third roll');
    expect(find.descendant(of: _key('dicesheet-score-fourKind'), matching: find.text('14')), findsOneWidget);

    // Mis-tap on "Einser" (strikes it with 0), take it back, fill four of a kind.
    await _tap(tester, 'dicesheet-score-ones');
    expect(g.entryOf(0, DiceBox.ones), 0);
    expect(find.text('Ben ist am Zug'), findsOneWidget);
    expect(find.textContaining('Anna: 0 bei Einser.'), findsOneWidget);
    await _tap(tester, 'shell-undo');
    // Undo replays the log on a fresh engine.
    g = c.game as DiceSheetGame;
    expect(g.entryOf(0, DiceBox.ones), isNull);
    expect(g.currentSeat, 0);
    expect(find.text('behalten'), findsNWidgets(2), reason: 'the kept dice come back with the undo');
    // (The replay rolls from the seed: the scripted dice were test-only.)
    final four = g.scoreIfFilled(DiceBox.fourKind)!;
    await _tap(tester, 'dicesheet-score-fourKind');
    expect(g.entryOf(0, DiceBox.fourKind), four);
    expect(tester.widget<Text>(find.descendant(of: _key('dicesheet-total-0'), matching: find.byType(Text))).data, '$four');

    // A roll is final: no undo after it.
    await _tap(tester, 'dicesheet-roll');
    expect(c.canUndo, isFalse);
    final undo = find.descendant(of: _key('dicesheet-controls'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    expect(undo, findsWidgets);
  });

  testWidgets('three rolls at most, then only the sheet', (tester) async {
    final c = await _pump(tester, const GameConfig('dicesheet', seed: 2));
    final g = c.game as DiceSheetGame;
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-roll');
    expect(g.rollsLeft, 0);
    expect(find.text('Feld im Blatt wählen'), findsOneWidget);
    expect(tester.widget<FilledButton>(_key('dicesheet-roll')).onPressed, isNull);
    // Tipps (on by default at first): the tip says which box, no hint line.
    expect(_key('dicesheet-tip'), findsOneWidget);
    expect(find.text('Wähle ein Feld im Blatt.'), findsNothing);
    await BeginnerSettings.shared().setTips(false);
    await tester.pumpAndSettle();
    expect(_key('dicesheet-tip'), findsNothing);
    expect(find.text('Wähle ein Feld im Blatt.'), findsOneWidget);
    await _tap(tester, 'dicesheet-die-0');
    expect(find.text('behalten'), findsNothing, reason: 'nothing to keep after the last roll');
  });

  testWidgets('the bonus row: progress to 63, then +35', (tester) async {
    final rolls = <List<int>>[];
    for (var face = 1; face <= 6; face++) {
      rolls
        ..add([face, face, face, face == 1 ? 2 : 1, face == 1 ? 2 : 1])
        ..add([1, 2, 3, 4, 6]);
    }
    final c = await _pump(tester, const GameConfig('dicesheet', seed: 3), rolls: rolls);
    final g = c.game as DiceSheetGame;
    for (var face = 1; face <= 6; face++) {
      await _tap(tester, 'dicesheet-roll');
      await _tap(tester, 'dicesheet-score-${DiceBox.upperFor(face).id}');
      if (face == 3) expect(find.descendant(of: _key('dicesheet-bonus-0'), matching: find.text('18/63')), findsOneWidget);
      await _tap(tester, 'dicesheet-roll');
      await _tap(tester, 'dicesheet-score-${DiceBox.upperFor(face).id}');
    }
    expect(g.upperBonusOf(0), 35);
    expect(find.descendant(of: _key('dicesheet-bonus-0'), matching: find.text('+35')), findsOneWidget);
    expect(find.descendant(of: _key('dicesheet-bonus-1'), matching: find.text('16/63')), findsOneWidget);
    expect(find.descendant(of: _key('dicesheet-total-0'), matching: find.text('98')), findsOneWidget);
  });

  for (final players in [2, 4]) {
    testWidgets('$players players: a whole game through the UI to the ranking', (tester) async {
      final c = await _pump(tester, GameConfig('dicesheet', seed: 7 + players, players: players));
      final g = c.game as DiceSheetGame;
      expect(find.byType(SeatToken), findsAtLeastNWidgets(players));
      for (var s = 0; s < players; s++) {
        expect(_key('dicesheet-head-$s'), findsOneWidget);
      }
      expect(_key('dicesheet-head-$players'), findsNothing);
      final names = ['Anna', 'Ben', 'Cleo', 'Dani'];
      final rng = Random(players);
      for (var turn = 0; turn < 13 * players; turn++) {
        expect(find.text('${names[g.currentSeat]} ist am Zug'), findsOneWidget);
        await _playTurn(tester, c, rng);
        expect(tester.takeException(), isNull);
      }
      expect(g.isOver, isTrue);
      expect(_key('result-dialog'), findsOneWidget);
      expect(find.text('Alle Felder sind ausgefüllt'), findsOneWidget);
      final r = g.seatResult;
      final headline = r.winner == null ? 'Gleichstand auf Platz 1!' : '${names[r.winner!]} gewinnt!';
      expect(find.text(headline), findsOneWidget);
      for (var s = 0; s < players; s++) {
        expect(find.descendant(of: _key('result-rank-$s'), matching: find.text('${g.totalOf(s)} Punkte')), findsOneWidget);
        expect(find.descendant(of: _key('result-rank-$s'), matching: find.text('${r.places[s]}.')), findsOneWidget);
      }
      // Top of the ranking first.
      final tops = [for (final s in r.ranking) tester.getTopLeft(_key('result-rank-$s')).dy];
      expect(tops, [...tops]..sort());
      await tester.tap(_key('result-again'));
      await tester.pumpAndSettle();
      final fresh = c.game as DiceSheetGame;
      expect(fresh.playerCount, players, reason: '"Nochmal" keeps the player count');
      expect(fresh.rollsUsed, 0);
      expect(find.text('Anna ist am Zug'), findsOneWidget);
    });
  }

  testWidgets('4 players: a player gives up, the others play on', (tester) async {
    final c = await _pump(tester, const GameConfig('dicesheet', seed: 5, players: 4));
    final g = c.game as DiceSheetGame;
    await _tap(tester, 'shell-resign');
    expect(find.text('Wer gibt auf? Die anderen spielen weiter.'), findsOneWidget);
    for (var s = 0; s < 4; s++) {
      expect(_key('resign-seat-$s'), findsOneWidget);
    }
    await _tap(tester, 'resign-seat-2');
    expect(g.isSeatOut(2), isTrue);
    expect(g.isOver, isFalse);
    expect(_key('result-dialog'), findsNothing);
    await _tap(tester, 'shell-resign');
    expect(_key('resign-seat-2'), findsNothing);
    await _tap(tester, 'resign-seat-0');
    await _tap(tester, 'shell-resign');
    await _tap(tester, 'resign-seat-3');
    expect(g.isOver, isTrue);
    expect(_key('result-dialog'), findsOneWidget);
    expect(find.text('Ben gewinnt!'), findsOneWidget);
    expect(find.text('Alle anderen haben aufgegeben'), findsOneWidget);
    expect(find.text('aufgegeben'), findsNWidgets(3));
  });

  testWidgets('history names every seat', (tester) async {
    final c = await _pump(tester, const GameConfig('dicesheet', seed: 6, players: 3), rolls: [
      [6, 6, 6, 6, 6],
      [1, 2, 3, 4, 5],
      [2, 2, 3, 3, 3],
    ]);
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-score-fiveKind');
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-score-largeStraight');
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-score-fullHouse');
    expect(c.moves.map((m) => m.seat), [0, 0, 1, 1, 2, 2]);
    await _tap(tester, 'shell-history');
    expect(find.text('Anna: Fünferpasch: 50'), findsOneWidget);
    expect(find.text('Ben: Große Straße: 40'), findsOneWidget);
    expect(find.text('Cleo: Full House: 25'), findsOneWidget);
    expect(find.textContaining('Cleo: würfelt'), findsOneWidget);
  });

  testWidgets('rules page (KLD-123); the extra-fives row with the house rule', (tester) async {
    await _pump(tester, const GameConfig('dicesheet', seed: 1, extraFives: true));
    expect(_key('dicesheet-extra-0'), findsOneWidget);
    expect(find.descendant(of: find.byType(AppBar), matching: _key('shell-rules')), findsOneWidget);
    expect(_key('shell-rules-intro'), findsOneWidget);
    await _tap(tester, 'shell-rules');
    expect(_key('rules-page'), findsOneWidget);
    for (final b in ['fours', 'threeKind', 'fourKind', 'fullHouse', 'smallStraight', 'largeStraight', 'fiveKind', 'chance']) {
      expect(_key('rules-dicesheet-$b'), findsOneWidget, reason: b);
    }
    expect(find.descendant(of: _key('rules-dicesheet-fullHouse'), matching: find.text('= 25')), findsOneWidget);
    expect(_key('rules-house-extraFives'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
