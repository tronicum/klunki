// KLD-119: Ausgewürfelt's Anfängermodus (the tip which box to fill and
// which dice to keep, [DiceSheetAdvisor]), the "each box only once" look of
// the sheet, and the first-game tour. Played through the real UI.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/beginner_settings.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/shake_settings.dart';
import 'package:klunki/ui/games/dicesheet/dicesheet_options.dart';
import 'package:klunki/ui/games/maexchen/maexchen_dice.dart' show DieFace;
import 'package:klunki/ui/shell/screen_registry.dart';
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

Future<GameController> _pump(WidgetTester tester,
    {int seed = 1, List<List<int>> rolls = const [], Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(GameConfig('dicesheet', seed: seed));
  addTearDown(c.dispose);
  (c.game as DiceSheetGame).debugScriptRolls(rolls);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

String _tipText(WidgetTester tester) => tester.widget<Text>(_key('dicesheet-tip-text')).data!;

/// The tip ring sits on the box [id] and that box is on screen in the sheet.
void _pointsAt(WidgetTester tester, String id) {
  expect(find.descendant(of: _key('dicesheet-score-$id'), matching: _key('dicesheet-tip-ring')), findsOneWidget);
  expect(_key('dicesheet-tip-ring'), findsOneWidget, reason: 'one box only');
  final viewport = tester.getRect(_key('dicesheet-sheet-scroll'));
  final cell = tester.getRect(_key('dicesheet-score-$id'));
  expect(viewport.contains(cell.center), isTrue, reason: 'the recommended box is scrolled into view: $cell in $viewport');
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

  testWidgets('three fives after the last roll: Fünfer, with why and what else', (tester) async {
    final c = await _pump(tester, rolls: List.filled(3, [5, 5, 5, 2, 3]));
    await _tap(tester, 'dicesheet-roll');
    expect(_key('dicesheet-tip'), findsNothing, reason: 'rolls left: no box tip by itself');
    expect(_key('dicesheet-tip-button'), findsOneWidget);
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-roll');
    expect(_key('dicesheet-tip-button'), findsNothing);
    expect(_key('dicesheet-tip'), findsOneWidget);
    expect(_tipText(tester), 'Tipp: Fünfer – 15 Punkte helfen dir beim Bonus (63).');
    expect(find.text('Dreierpasch gäbe jetzt 20 Punkte, ist aber später mehr wert.'), findsOneWidget);
    expect(find.text('Jedes Feld gibt es nur einmal – auch die Chance.'), findsOneWidget, reason: 'first turn');
    _pointsAt(tester, 'fives');
    expect(tester.takeException(), isNull);

    // Advice only: another box is fine, the tip goes.
    await _tap(tester, 'dicesheet-score-threeKind');
    expect((c.game as DiceSheetGame).entryOf(0, DiceBox.threeKind), 20);
    expect(_key('dicesheet-tip'), findsNothing);
    expect(_key('dicesheet-tip-ring'), findsNothing);
  });

  testWidgets('the recommended box further down is scrolled into view', (tester) async {
    await _pump(tester, rolls: List.filled(3, [3, 2, 6, 4, 5]));
    for (var i = 0; i < 3; i++) {
      await _tap(tester, 'dicesheet-roll');
    }
    expect(_tipText(tester), 'Tipp: Große Straße – das gibt 40 Punkte. Nimm sie!');
    _pointsAt(tester, 'largeStraight');
    await _tap(tester, 'dicesheet-score-largeStraight');
  });

  testWidgets('"Tipp" while rolls are left: which dice to keep; a big box: stop', (tester) async {
    await _pump(tester, rolls: [
      [6, 1, 6, 3, 6],
      [2, 3, 4, 5, 6],
    ]);
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-tip-button');
    expect(_tipText(tester), 'Tipp: Behalte diese Würfel und würfle die anderen noch mal:');
    expect(find.descendant(of: _key('dicesheet-tip-keep'), matching: find.byType(DieFace)), findsNWidgets(3));
    expect(_key('dicesheet-tip-ring'), findsNothing, reason: 'no box tip yet');
    await _tap(tester, 'dicesheet-tip-button');
    expect(_key('dicesheet-tip'), findsNothing, reason: 'a second tap hides it');
    await _tap(tester, 'dicesheet-tip-button');
    // Rolling again hides it; the large straight is a tip of its own.
    await _tap(tester, 'dicesheet-roll');
    expect(_key('dicesheet-tip'), findsOneWidget, reason: 'made: shown by itself');
    expect(find.text('Super Wurf! Du musst nicht mehr würfeln.'), findsOneWidget);
    _pointsAt(tester, 'largeStraight');
  });

  testWidgets('a strike tip: nothing fits, Einser loses the least', (tester) async {
    final c = await _pump(tester, rolls: [
      [6, 5, 4, 3, 1],
      [1, 1, 2, 2, 3],
      ...List.filled(3, [2, 3, 4, 6, 6]),
    ]);
    // Anna fills Chance, Ben Einser; Anna rolls junk three times.
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-score-chance');
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-score-ones');
    for (var i = 0; i < 3; i++) {
      await _tap(tester, 'dicesheet-roll');
    }
    expect(_tipText(tester), 'Tipp: Kein gutes Feld? Streich Einser, da verlierst du am wenigsten.');
    expect(find.text('Sechser gäbe jetzt 12 Punkte, ist aber später mehr wert.'), findsOneWidget);
    expect(find.text('Jedes Feld gibt es nur einmal – auch die Chance.'), findsOneWidget);
    _pointsAt(tester, 'ones');
    await _tap(tester, 'dicesheet-score-ones');
    expect((c.game as DiceSheetGame).entryOf(0, DiceBox.ones), 0);
  });

  /// The app's instance with storage (the default one in tests is memory only).
  Future<void> withStorage(WidgetTester tester) async {
    BeginnerSettings.debugReset(loaded: true);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  }

  testWidgets('"Tipps ausschalten" turns the tips off, says so and persists; the ring stays', (tester) async {
    await withStorage(tester);
    await _pump(tester, rolls: List.filled(3, [5, 5, 5, 2, 3]));
    for (var i = 0; i < 3; i++) {
      await _tap(tester, 'dicesheet-roll');
    }
    await _tap(tester, 'dicesheet-tips-end');
    expect(find.text('Tipps aus. Du kannst sie in den Optionen wieder einschalten.'), findsOneWidget);
    expect(_key('dicesheet-tip'), findsNothing);
    expect(_key('dicesheet-tip-ring'), findsOneWidget, reason: 'the Anfängermodus is a setting of its own');
    expect(BeginnerSettings.shared().tips, isFalse);
    expect(BeginnerSettings.shared().enabled, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(BeginnerSettings.prefsKeyTips), isFalse);
    expect(prefs.getBool(BeginnerSettings.prefsKey), isNull, reason: 'no choice made for the Anfängermodus');
    // A fresh start reads it back.
    BeginnerSettings.debugReset(loaded: true);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    expect(BeginnerSettings.shared().tips, isFalse);
  });

  testWidgets('a short screen: the folded tip has a close button that turns the tips off', (tester) async {
    await _pump(tester, rolls: List.filled(3, [5, 5, 5, 2, 3]), size: const Size(375, 667));
    for (var i = 0; i < 3; i++) {
      await _tap(tester, 'dicesheet-roll');
    }
    expect(_key('dicesheet-tip-more'), findsOneWidget, reason: 'folded');
    expect(_key('dicesheet-tips-end'), findsNothing);
    await _tap(tester, 'dicesheet-tips-close');
    expect(_key('dicesheet-tip'), findsNothing);
    expect(BeginnerSettings.shared().tips, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('both off: no tips at all', (tester) async {
    await BeginnerSettings.shared().setEnabled(false);
    await BeginnerSettings.shared().setTips(false);
    await _pump(tester, rolls: List.filled(3, [5, 5, 5, 2, 3]));
    await _tap(tester, 'dicesheet-roll');
    expect(_key('dicesheet-tip-button'), findsNothing);
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-roll');
    expect(_key('dicesheet-tip'), findsNothing);
    expect(_key('dicesheet-tip-ring'), findsNothing);
    expect(find.text('Wähle ein Feld im Blatt.'), findsOneWidget, reason: 'the hint line is back');
  });

  testWidgets('second game: no ring (Anfängermodus off), the tip bubble still there', (tester) async {
    BeginnerSettings.debugReset(games: 1);
    await _pump(tester, rolls: List.filled(3, [5, 5, 5, 2, 3]));
    await _tap(tester, 'dicesheet-roll');
    expect(_key('dicesheet-tip-button'), findsOneWidget);
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-roll');
    expect(_key('dicesheet-tip'), findsOneWidget);
    expect(_tipText(tester), 'Tipp: Fünfer – 15 Punkte helfen dir beim Bonus (63).');
    expect(_key('dicesheet-tip-ring'), findsNothing);
  });

  testWidgets('sixth game: neither, unless turned on in the options', (tester) async {
    BeginnerSettings.debugReset(games: 5);
    await _pump(tester, rolls: List.filled(3, [5, 5, 5, 2, 3]));
    for (var i = 0; i < 3; i++) {
      await _tap(tester, 'dicesheet-roll');
    }
    expect(_key('dicesheet-tip'), findsNothing);
    expect(_key('dicesheet-tip-ring'), findsNothing);
    await BeginnerSettings.shared().setEnabled(true);
    await BeginnerSettings.shared().setTips(true);
    await tester.pumpAndSettle();
    expect(_key('dicesheet-tip'), findsOneWidget);
    expect(_key('dicesheet-tip-ring'), findsOneWidget);
  });

  testWidgets('a game that ends (here: given up) counts; the next one starts without the ring', (tester) async {
    final c = await _pump(tester);
    expect(BeginnerSettings.shared().gamesPlayed, 0);
    await c.resign(Player.a);
    await tester.pumpAndSettle();
    expect(c.game.isOver, isTrue);
    expect(BeginnerSettings.shared().gamesPlayed, 1);
    expect(BeginnerSettings.shared().enabled, isFalse);
    expect(BeginnerSettings.shared().tips, isTrue);
    // Rebuilds of the finished game do not count it again.
    await tester.pumpAndSettle();
    expect(BeginnerSettings.shared().gamesPlayed, 1);
  });

  testWidgets('the start options: both switches, on at first, stored at once', (tester) async {
    await withStorage(tester);
    await tester.pumpWidget(localizedApp(const Scaffold(body: SizedBox.expand())));
    showDiceSheetOptionsDialog(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(_key('dicesheet-beginner')).value, isTrue);
    expect(tester.widget<SwitchListTile>(_key('dicesheet-tips')).value, isTrue);
    await _tap(tester, 'dicesheet-beginner');
    expect(tester.widget<SwitchListTile>(_key('dicesheet-beginner')).value, isFalse);
    expect(BeginnerSettings.shared().enabled, isFalse);
    expect((await SharedPreferences.getInstance()).getBool(BeginnerSettings.prefsKey), isFalse);
    await _tap(tester, 'dicesheet-tips');
    expect(tester.widget<SwitchListTile>(_key('dicesheet-tips')).value, isFalse);
    expect((await SharedPreferences.getInstance()).getBool(BeginnerSettings.prefsKeyTips), isFalse);
  });

  testWidgets('the start options after 5 games: both off, can be turned back on', (tester) async {
    BeginnerSettings.debugReset(games: 5);
    await tester.pumpWidget(localizedApp(const Scaffold(body: SizedBox.expand())));
    showDiceSheetOptionsDialog(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(_key('dicesheet-beginner')).value, isFalse);
    expect(tester.widget<SwitchListTile>(_key('dicesheet-tips')).value, isFalse);
    await _tap(tester, 'dicesheet-tips');
    expect(BeginnerSettings.shared().tips, isTrue);
  });

  testWidgets('the sheet: used boxes look done, the header counts the free ones', (tester) async {
    await _pump(tester, rolls: [
      [5, 5, 5, 2, 3],
    ]);
    expect(find.text('noch 13 Felder frei'), findsOneWidget);
    expect(find.descendant(of: _key('dicesheet-cell-1-fives'), matching: find.byType(Container)), findsWidgets,
        reason: 'an open slot');
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-score-fives');
    // Ben to move now; Anna's Fünfer is used: the number and a check.
    expect(find.descendant(of: _key('dicesheet-cell-0-fives'), matching: find.text('15')), findsOneWidget);
    expect(find.descendant(of: _key('dicesheet-cell-0-fives'), matching: find.byIcon(Icons.check)), findsOneWidget);
    expect(find.text('noch 13 Felder frei'), findsOneWidget, reason: "Ben's sheet");
    await _tap(tester, 'dicesheet-roll');
    await _tap(tester, 'dicesheet-score-chance');
    expect(find.text('noch 12 Felder frei'), findsOneWidget, reason: "Anna's sheet");
  });

  group('tour', () {
    setUp(SeenTips.debugReset);

    testWidgets('before the first roll, once; five steps on the real elements; "Kurz erklärt" again', (tester) async {
      final c = await _pump(tester);
      expect(_key('dicesheet-coach'), findsOneWidget);
      expect(find.text('Du hast bis zu 3 Würfe pro Runde.'), findsOneWidget);
      for (final text in [
        'Tippe Würfel an, die liegen bleiben sollen.',
        'Dann trägst du den Wurf in ein Feld ein. Die Zahl zeigt, wie viele Punkte es gibt.',
        'Jedes Feld nur einmal – 13 Felder, 13 Runden. Am meisten Punkte gewinnt.',
        'Alle Regeln findest du hier.',
      ]) {
        await tester.tap(_key('dicesheet-coach-next'));
        await tester.pumpAndSettle();
        expect(find.text(text), findsOneWidget);
      }
      await tester.tap(_key('dicesheet-coach-done'));
      await tester.pumpAndSettle();
      expect(_key('dicesheet-coach'), findsNothing);
      expect(SeenTips.shared.has(SeenTips.dicesheetIntro), isTrue);

      // Play on: no tour again in this or the next game.
      await _tap(tester, 'dicesheet-roll');
      expect(_key('dicesheet-coach'), findsNothing);
      expect(c.moves, hasLength(1));

      // "⋮" → "Kurz erklärt" shows it again.
      await _tap(tester, 'shell-menu');
      await _tap(tester, 'dicesheet-tour');
      expect(_key('dicesheet-coach'), findsOneWidget);
      await tester.tap(_key('dicesheet-coach-skip'));
      await tester.pumpAndSettle();
      expect(_key('dicesheet-coach'), findsNothing);
    });

    testWidgets('not in a game already under way', (tester) async {
      final c = GameController.hotSeat(const GameConfig('dicesheet', seed: 1));
      addTearDown(c.dispose);
      await c.submit(DiceSheetGame.rollMove());
      await c.submit(DiceSheetGame.scoreMove(DiceBox.chance));
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(localizedApp(buildGameScreen(c)));
      await tester.pumpAndSettle();
      expect(_key('dicesheet-coach'), findsNothing);
    });
  });

  testWidgets('rules page: each box only once, the Anfängermodus and the tips', (tester) async {
    await _pump(tester);
    await _tap(tester, 'shell-rules');
    expect(find.text('Jedes Feld füllst du nur einmal. 13 Felder, 13 Runden.'), findsOneWidget);
    await tester.ensureVisible(_key('rules-dicesheet-beginner'));
    expect(find.textContaining('Anfängermodus (im ersten Spiel an)'), findsOneWidget);
    expect(find.textContaining('Tipps (in den ersten 5 Spielen an)'), findsOneWidget);
  });
}
