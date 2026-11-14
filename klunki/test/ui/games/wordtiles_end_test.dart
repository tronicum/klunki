// KLD-094 (game end): the summary opens right after the last move, so the
// others never saw it. The summary names it ("Letztes Wort: …", or "Am Ende
// haben alle gepasst."), and "Brett ansehen" closes it for a look at the
// final board with the last move marked; "Ergebnis anzeigen" brings it
// back. 2 players (GameScreen) and 3 players (seat shell) on one device;
// "Brett ansehen" for the other board games too, not for card games. Over
// the network: test/e2e/live_ui/wordtiles_live_test.dart and
// wordtiles_table_network_live_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_tiles.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _key(String k) => find.byKey(Key(k));

WordTilesGame _game(GameController c) => c.game as WordTilesGame;

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, Finder f) => tester.widget<Text>(f).data!;

Future<GameController> _start(WidgetTester tester, {int players = 2, required List<List<String>> racks, List<String> bag = const []}) async {
  tester.view.physicalSize = const Size(1180, 820) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(GameConfig('wordtiles', seed: 1, players: players));
  addTearDown(c.dispose);
  _game(c).debugSetup(racks: racks, bag: bag);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

/// The ring of the tile on square ([r], [c]) of the board.
Color? _ring(WidgetTester tester, int r, int c) => tester
    .widget<LetterTile>(find.descendant(of: _key('wordtiles-sq-$r-$c'), matching: find.byType(LetterTile)))
    .ring;

/// "Brett ansehen", the final board with the bar, "Ergebnis anzeigen".
Future<void> _lookAtBoardAndBack(WidgetTester tester) async {
  expect(find.text('Brett ansehen'), findsOneWidget);
  await _tap(tester, _key('result-show-board'));
  expect(find.byKey(resultDialog), findsNothing);
  expect(_key('result-board-bar'), findsOneWidget);
  expect(find.text('So endete das Spiel.'), findsOneWidget);
  await _tap(tester, _key('result-show-result'));
  expect(find.byKey(resultDialog), findsOneWidget);
  expect(_key('result-board-bar'), findsNothing);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
    SeenTips.shared.markFirst(SeenTips.rulesOpened('wordtiles'));
    ExtraSeatNames.debugReset();
    UndoSettings.debugReset();
  });

  testWidgets('2 players: the summary names the last word; "Brett ansehen" shows it marked, then back', (tester) async {
    final c = await _start(tester, racks: const [
      ['H', 'A', 'U', 'S', 'Y'],
      ['I'],
    ]);
    await c.submit(WordTilesGame.placeMove(const [
      PlacedTile(7, 4, 'H'),
      PlacedTile(7, 5, 'A'),
      PlacedTile(7, 6, 'U'),
      PlacedTile(7, 7, 'S'),
    ]));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(handoverContinue));
    await _tap(tester, _key('wordtiles-accept'));
    // Ben lays the I (HAUSI) and is out; Anna accepts: the game is over.
    await c.submit(WordTilesGame.placeMove(const [PlacedTile(7, 8, 'I')]));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(handoverContinue));
    await _tap(tester, _key('wordtiles-accept'));
    final g = _game(c);
    expect(g.isOver, isTrue);
    expect(find.byKey(resultDialog), findsOneWidget);
    final last = g.turns.lastWhere((t) => t.action == 'place');
    expect(_text(tester, _key('wordtiles-result-last')), 'Letztes Wort: Ben legt HAUSI für ${last.score} Punkte');
    // On top of the summary, above the scores.
    expect(tester.getTopLeft(_key('wordtiles-result-last')).dy,
        lessThan(tester.getTopLeft(_key('wordtiles-result-score-0')).dy));

    await _tap(tester, _key('result-show-board'));
    expect(find.byKey(resultDialog), findsNothing);
    expect(_key('result-board-bar'), findsOneWidget);
    // The last placement (the I) stands out, the earlier word does not.
    expect(_ring(tester, 7, 8), WordTilesColors.light.lastRing);
    expect(_ring(tester, 7, 4), isNull);
    // Back to the summary, with everything as before.
    await _tap(tester, _key('result-show-result'));
    expect(find.byKey(resultDialog), findsOneWidget);
    expect(_key('wordtiles-result-last'), findsOneWidget);
    await _lookAtBoardAndBack(tester);
  });

  testWidgets('2 players: six passes end the game, "Am Ende haben alle gepasst."', (tester) async {
    final c = await _start(tester, racks: const [
      ['H', 'A', 'U', 'S', 'E', 'N', 'Y'],
      ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
    ], bag: List.filled(40, 'E'));
    for (var i = 0; i < 6; i++) {
      await c.submit(const {'action': 'pass'});
      await tester.pumpAndSettle();
      if (i < 5) await _tap(tester, find.byKey(handoverContinue));
    }
    expect(_game(c).playResult.code, GameEndReason.wordtilesScoreless);
    expect(find.byKey(resultDialog), findsOneWidget);
    expect(_text(tester, _key('wordtiles-result-last')), 'Am Ende haben alle gepasst.');
    await _lookAtBoardAndBack(tester);
  });

  testWidgets('2 players: no line after an exchange among the scoreless turns, none after a resign', (tester) async {
    final c = await _start(tester, racks: const [
      ['H', 'A', 'U', 'S', 'E', 'N', 'Y'],
      ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
    ], bag: List.filled(40, 'E'));
    await c.submit(const {
      'action': 'exchange',
      'tiles': ['Y'],
    });
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(handoverContinue));
    await c.resign(Player.b);
    await tester.pumpAndSettle();
    expect(find.byKey(resultDialog), findsOneWidget);
    expect(_key('wordtiles-result-last'), findsNothing);
    await _lookAtBoardAndBack(tester);
  });

  testWidgets('3 players (seat shell): the last word above the ranking; "Brett ansehen" and back', (tester) async {
    final c = await _start(tester, players: 3, racks: const [
      ['H', 'A', 'U', 'S'],
      ['T', 'O', 'R', 'E'],
      ['L', 'A', 'M', 'P'],
    ]);
    // Anna lays HAUS and is out; Ben (next) accepts.
    await c.submit(WordTilesGame.placeMove(const [
      PlacedTile(7, 4, 'H'),
      PlacedTile(7, 5, 'A'),
      PlacedTile(7, 6, 'U'),
      PlacedTile(7, 7, 'S'),
    ]));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(handoverContinue));
    await _tap(tester, _key('wordtiles-accept'));
    final g = _game(c);
    expect(g.isOver, isTrue);
    expect(find.byKey(resultDialog), findsOneWidget);
    expect(_text(tester, _key('wordtiles-result-last')), 'Letztes Wort: Anna legt HAUS für ${g.turns.first.score} Punkte');
    expect(tester.getTopLeft(_key('wordtiles-result-last')).dy, lessThan(tester.getTopLeft(_key('result-rank-0')).dy));
    await _tap(tester, _key('result-show-board'));
    expect(_key('result-board-bar'), findsOneWidget);
    expect(_ring(tester, 7, 4), WordTilesColors.light.lastRing);
    await _tap(tester, _key('result-show-result'));
    expect(find.byKey(resultDialog), findsOneWidget);
    expect(_key('wordtiles-result-last'), findsOneWidget);
  });

  testWidgets('3 players (seat shell): all passed', (tester) async {
    final c = await _start(tester, players: 3, racks: const [
      ['H', 'A', 'U', 'S', 'E', 'N', '?'],
      ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
      ['L', 'A', 'M', 'P', 'E', 'R', 'S'],
    ], bag: List.filled(40, 'E'));
    for (var i = 0; i < 6; i++) {
      await c.submit(const {'action': 'pass'});
      await tester.pumpAndSettle();
      if (i < 5) await _tap(tester, find.byKey(handoverContinue));
    }
    expect(find.byKey(resultDialog), findsOneWidget);
    expect(_text(tester, _key('wordtiles-result-last')), 'Am Ende haben alle gepasst.');
    await _lookAtBoardAndBack(tester);
  });

  testWidgets('another board game (Four in a Row): "Brett ansehen" too, no last-word line', (tester) async {
    await pumpGame(tester, 'connect4');
    await playToEnd(tester);
    expect(_key('wordtiles-result-last'), findsNothing);
    await _lookAtBoardAndBack(tester);
    // "Nochmal" still starts over.
    await _tap(tester, find.text('Nochmal'));
    expect(controllerOf(tester).moves, isEmpty);
    expect(_key('result-board-bar'), findsNothing);
  });

  testWidgets('a card game (Quartett) keeps the plain dialog', (tester) async {
    await pumpGame(tester, 'quartett-trumpf');
    await playToEnd(tester);
    expect(find.byKey(resultDialog), findsOneWidget);
    expect(_key('result-show-board'), findsNothing);
  });
}
