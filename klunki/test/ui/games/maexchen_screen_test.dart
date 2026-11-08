// KLD-121: the Mäxchen screen in hot-seat, played through the real UI
// (taps on the buttons, never `controller.submit`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/games/maexchen/maexchen_dice.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

/// The dice drawn on the table (null: none, the cup is down or empty).
List<int>? _tableDice(WidgetTester tester) => tester.widget<CupTable>(find.byType(CupTable)).dice;

Future<GameController> _pump(WidgetTester tester, {GameConfig config = const GameConfig('maexchen', seed: 3),
    List<List<int>> rolls = const []}) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  (c.game as MaexchenGame).debugScriptRolls(rolls);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

/// Rolls, peeks and announces [value] as the player to move.
Future<void> _rollAndAnnounce(WidgetTester tester, int value) async {
  await _tap(tester, 'maexchen-roll');
  await _tap(tester, 'maexchen-peek');
  await _tap(tester, 'maexchen-value-$value');
  await _tap(tester, 'maexchen-announce');
}

Future<void> _handOver(WidgetTester tester) async {
  expect(_key('handover-cover'), findsOneWidget);
  await tester.tap(_key('handover-continue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('roll, peek, announce: only the roller ever sees the dice', (tester) async {
    final c = await _pump(tester, rolls: [[3, 5], [6, 6]]);
    final game = c.game as MaexchenGame;
    expect(find.text('Neue Runde: jede Zahl ist erlaubt'), findsOneWidget);
    expect(find.text('Tippe auf Würfeln, dann schau heimlich unter den Becher.'), findsOneWidget);
    expect(_key('maexchen-heart-a-2'), findsOneWidget);

    await _tap(tester, 'maexchen-roll');
    expect(game.dice, [3, 5]);
    expect(_tableDice(tester), isNull, reason: 'the cup is still down');
    expect(_key('maexchen-announce'), findsOneWidget);
    expect(tester.widget<FilledButton>(_key('maexchen-announce')).onPressed, isNull, reason: 'nothing chosen yet');

    await _tap(tester, 'maexchen-peek');
    expect(_tableDice(tester), [5, 3], reason: 'high die first');
    await _tap(tester, 'maexchen-peek');
    expect(_tableDice(tester), isNull);

    await _tap(tester, 'maexchen-value-54');
    expect(find.text('54 ansagen'), findsOneWidget);
    await _tap(tester, 'maexchen-announce');

    // Ben gets the device: the cover tells the announcement, no dice.
    expect(_key('maexchen-handover-announced'), findsOneWidget);
    expect(find.text('Anna sagt 54'), findsWidgets);
    await _handOver(tester);
    expect(_tableDice(tester), isNull, reason: "Ben never sees Anna's dice");
    expect(find.text('Anna sagt 54. Glaubst du das?'), findsOneWidget);
    expect(_key('maexchen-peek'), findsNothing);

    // Ben believes, rolls and must announce more than 54.
    await _tap(tester, 'maexchen-believe');
    expect(find.text('Du glaubst 54. Würfle und sag mehr als 54 an.'), findsOneWidget);
    await _tap(tester, 'maexchen-roll');
    expect(_key('maexchen-value-54'), findsNothing);
    expect(_key('maexchen-value-53'), findsNothing);
    expect(_key('maexchen-value-61'), findsOneWidget);
    expect(_key('maexchen-value-21'), findsOneWidget);
    await _tap(tester, 'maexchen-peek');
    expect(_tableDice(tester), [6, 6]);
    await _tap(tester, 'maexchen-value-66');
    await _tap(tester, 'maexchen-announce');
    await _handOver(tester);
    expect(_tableDice(tester), isNull);
  });

  testWidgets('a bluff doubted: the cup lifts, the verdict shows, the bluffer loses a heart and starts', (tester) async {
    final c = await _pump(tester, rolls: [[4, 1]]);
    await _rollAndAnnounce(tester, 52);
    await _handOver(tester);
    await _tap(tester, 'maexchen-doubt');
    // Anna lost: the device goes back to her, the cover shows the verdict.
    expect(_key('maexchen-handover-summary'), findsOneWidget);
    expect(find.text('Geflunkert! Anna verliert ein Leben.'), findsWidgets);
    await _handOver(tester);
    expect(_tableDice(tester), [4, 1], reason: 'the dice lie open after a doubt');
    expect(find.text('Unter dem Becher: 41'), findsOneWidget);
    expect((c.game as MaexchenGame).livesOf(Player.a), 2);
    expect(tester.widget<Icon>(_key('maexchen-heart-a-2')).icon, Icons.favorite_border);
    expect(tester.widget<Icon>(_key('maexchen-heart-b-2')).icon, Icons.favorite);
    expect(c.game.currentPlayer, Player.a);
    // Rolling closes the cup again.
    await _tap(tester, 'maexchen-roll');
    expect(_tableDice(tester), isNull);
  });

  testWidgets('the truth doubted: the doubter loses, no handover', (tester) async {
    await _pump(tester, rolls: [[6, 5]]);
    await _rollAndAnnounce(tester, 65);
    await _handOver(tester);
    await _tap(tester, 'maexchen-doubt');
    expect(_key('handover-cover'), findsNothing, reason: 'Ben lost and starts the next round himself');
    expect(find.text('Stimmt! Ben verliert ein Leben.'), findsOneWidget);
    expect(_key('maexchen-roll'), findsOneWidget);
  });

  testWidgets('Mäxchen: give up or doubt; a real one doubted costs 2 hearts', (tester) async {
    final c = await _pump(tester, rolls: [[3, 1], [2, 1]]);
    await _rollAndAnnounce(tester, 21);
    await _handOver(tester);
    expect(_key('maexchen-believe'), findsNothing);
    expect(find.text('Anna sagt Mäxchen! Höher geht es nicht: anzweifeln oder ein Leben abgeben?'), findsOneWidget);
    await _tap(tester, 'maexchen-giveup');
    expect(find.text('Ben gibt ein Leben ab. Der Becher bleibt zu.'), findsOneWidget);
    expect(_tableDice(tester), isNull, reason: 'giving up shows no dice');
    final game = c.game as MaexchenGame;
    expect(game.livesOf(Player.b), 2);

    // Ben starts, rolls a real Mäxchen; Anna doubts it and loses 2.
    await _rollAndAnnounce(tester, 21);
    await _handOver(tester);
    await _tap(tester, 'maexchen-doubt');
    expect(find.text('Echtes Mäxchen! Anna verliert 2 Leben.'), findsWidgets);
    expect(game.livesOf(Player.a), 1);
  });

  testWidgets('a fake Mäxchen caught costs the bluffer 2 hearts', (tester) async {
    final c = await _pump(tester, rolls: [[6, 6]]);
    await _rollAndAnnounce(tester, 21);
    await _handOver(tester);
    await _tap(tester, 'maexchen-doubt');
    expect(find.text('Falsches Mäxchen! Anna verliert 2 Leben.'), findsWidgets);
    await _handOver(tester);
    expect(_tableDice(tester), [6, 6]);
    expect((c.game as MaexchenGame).livesOf(Player.a), 1);
    expect(tester.widget<Icon>(_key('maexchen-heart-a-1')).icon, Icons.favorite_border);
  });

  group('"Zug zurück" never goes back across a doubt or a given-up life (decision 2026-11-06)', () {
    const undo = Key('shell-undo');
    VoidCallback? undoPressed(WidgetTester tester) =>
        tester.widget<TextButton>(find.byKey(undo).first).onPressed;

    testWidgets('after an announcement undo works, after the doubt it is off', (tester) async {
      final c = await _pump(tester, rolls: [[4, 1], [4, 1]]);
      await _rollAndAnnounce(tester, 52);
      // On the handover cover: the announcement can still be taken back.
      expect(c.canUndo, isTrue);
      expect(undoPressed(tester), isNotNull);
      await _handOver(tester);
      await _tap(tester, 'maexchen-doubt');
      // The dice are revealed: no way back, on the cover nor on the board.
      expect(c.canUndo, isFalse);
      expect(_key('handover-cover'), findsOneWidget);
      expect(undoPressed(tester), isNull);
      await _handOver(tester);
      expect(undoPressed(tester), isNull);
      // The next round's roll can be taken back again, but only down to it.
      await _tap(tester, 'maexchen-roll');
      expect(c.canUndo, isTrue);
      c.undo();
      await tester.pumpAndSettle();
      expect(c.canUndo, isFalse);
      // (Undo replays from the seed, so the scripted dice are gone here; the
      // doubt itself stays in the log.)
      expect(c.moves.last.move['action'], 'doubt', reason: 'the doubt stays');
      expect(c.moves, hasLength(3));
    });

    testWidgets('giving up a life cannot be taken back', (tester) async {
      final c = await _pump(tester, rolls: [[2, 1]]);
      await _rollAndAnnounce(tester, 21);
      await _handOver(tester);
      await _tap(tester, 'maexchen-giveup');
      expect(c.canUndo, isFalse);
      expect(undoPressed(tester), isNull);
      expect((c.game as MaexchenGame).livesOf(Player.b), 2);
    });
  });

  testWidgets('a whole game through the UI ends with the result dialog', (tester) async {
    final c = await _pump(tester, config: const GameConfig('maexchen', seed: 11));
    final game = c.game as MaexchenGame;
    var turns = 0;
    while (_key('result-dialog').evaluate().isEmpty) {
      expect(++turns, lessThan(400), reason: 'the game should end');
      if (_key('handover-continue').evaluate().isNotEmpty) {
        await _handOver(tester);
      } else if (_key('maexchen-roll').evaluate().isNotEmpty) {
        await _tap(tester, 'maexchen-roll');
      } else if (_key('maexchen-picker').evaluate().isNotEmpty) {
        await _tap(tester, 'maexchen-peek');
        final real = MaexchenGame.valueOf(_tableDice(tester)![0], _tableDice(tester)![1]);
        expect(real, game.diceValue);
        final options = MaexchenGame.valuesAbove(game.announced);
        // Tell the truth when it is enough, else bluff the lowest value.
        await _tap(tester, 'maexchen-value-${options.contains(real) ? real : options.first}');
        await _tap(tester, 'maexchen-announce');
      } else if (_key('maexchen-doubt').evaluate().isNotEmpty) {
        // Doubt high announcements, believe low ones.
        final high = MaexchenGame.rankOf(game.announced!) >= 9;
        await _tap(tester, high || _key('maexchen-believe').evaluate().isEmpty ? 'maexchen-doubt' : 'maexchen-believe');
      } else {
        fail('nothing to do on turn $turns');
      }
    }
    expect(game.isOver, isTrue);
    expect(game.result.code, GameEndReason.maexchenNoLives);
    final loser = game.result.winner == Player.a ? Player.b : Player.a;
    expect(game.livesOf(loser), 0);
    expect(find.text('Keine Leben mehr übrig'), findsOneWidget);
    expect(find.descendant(of: _key('result-dialog'), matching: _key('maexchen-summary')), findsOneWidget);
  });

  testWidgets('start options: 5 lives and "Mäxchen doppelt" off reach the game', (tester) async {
    await tester.pumpWidget(localizedApp(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(onPressed: () => openGameFromMenu(context, 'maexchen'), child: const Text('open')),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(_key('maexchen-options'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(_key('maexchen-double')).value, isTrue);
    await tester.tap(_key('maexchen-lives-5'));
    await tester.pumpAndSettle();
    await tester.tap(_key('maexchen-double'));
    await tester.pumpAndSettle();
    await tester.tap(_key('maexchen-options-next'));
    await tester.pumpAndSettle();
    final c = controllerOf(tester);
    expect(c.config.lives, 5);
    expect(c.config.maexchenDouble, isFalse);
    expect((c.game as MaexchenGame).startLives, 5);
    expect(_key('maexchen-heart-a-4'), findsOneWidget);
    // "Nochmal" / restart keeps the options.
    c.restart(seed: 2);
    expect(c.config.lives, 5);
    expect(c.config.maexchenDouble, isFalse);
  });

  testWidgets('cancelling the options starts nothing', (tester) async {
    await tester.pumpWidget(localizedApp(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(onPressed: () => openGameFromMenu(context, 'maexchen'), child: const Text('open')),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(_key('maexchen-options-cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(_key('maexchen-board'), findsNothing);
  });
}
