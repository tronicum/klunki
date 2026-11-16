// KLD-131: whole Rauswurf games played through the real hot-seat UI, like
// players at one table would: a simple bot decides (a capture first, then
// a pawn into the finish lane, else at random), but every move is a tap on
// the screen (the die, then a glowing pawn). Now and then the pawn move is
// taken back ("Zug zurücknehmen") and made again. After every tap the
// screen is checked against the engine: the status names the seat to move,
// every pawn stands on its field, exactly the pawns that may move glow,
// the die shows the last roll. Ends at the result dialog with the ranking.
//
//   flutter test test/e2e/live_ui/ludo_live_test.dart
//   KLUNKI_LIVE_UI_FULL=1 … also plays more seeds
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/ui/games/ludo/ludo_board.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';

final bool _verbose = Platform.environment['KLUNKI_LIVE_UI_VERBOSE'] == '1';
final bool _full = Platform.environment['KLUNKI_LIVE_UI_FULL'] == '1';

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  expect(_key(key), findsOneWidget, reason: key);
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

const _names = ['Anna', 'Ben', 'Cleo', 'Dani'];

/// The screen shows what the engine says.
void _checkScreen(WidgetTester tester, GameController c) {
  final g = c.game as LudoGame;
  if (!g.isOver) expect(find.text('${_names[g.currentSeat]} ist am Zug'), findsOneWidget);
  final board = tester.getRect(_key('ludo-board'));
  final cell = board.width / LudoGrid.size;
  final movable = g.movablePawns.toSet();
  for (var s = 0; s < g.playerCount; s++) {
    for (var i = 0; i < LudoGame.pawns; i++) {
      final f = _key('ludo-pawn-$s-$i');
      if (g.isSeatOut(s)) {
        expect(f, findsNothing);
        continue;
      }
      final (cx, cy) = LudoGrid.cellOf(g, s, i);
      final want = board.topLeft + Offset((cx + 0.5) * cell, (cy + 0.5) * cell);
      expect((tester.getCenter(f) - want).distance, lessThan(1), reason: 'pawn $s/$i on ($cx, $cy)');
      final active = !g.isOver && s == g.currentSeat && movable.contains(i);
      expect(tester.widget<LudoPawn>(f).active, active, reason: 'pawn $s/$i glows');
    }
  }
}

/// The bot's pawn for the die on the table.
int _choose(LudoGame g, Random rng) {
  final options = g.options;
  final hit = options.where((o) => o.captures != null).firstOrNull;
  if (hit != null) return hit.pawn;
  final home = options.where((o) => o.to >= LudoGame.laneStart && o.from < LudoGame.laneStart).firstOrNull;
  if (home != null) return home.pawn;
  return options[rng.nextInt(options.length)].pawn;
}

Future<void> _playGame(WidgetTester tester, GameConfig config, {int maxTaps = 4000}) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  final rng = Random(config.seed);
  final seen = <String>{};
  var taps = 0, undos = 0;
  while (!(c.game as LudoGame).isOver) {
    expect(++taps, lessThan(maxTaps), reason: 'the game should end');
    final g = c.game as LudoGame;
    final before = c.moves.length;
    if (g.mustRoll) {
      await _tap(tester, 'ludo-die');
      final p = c.moves.last.event.payload as Map;
      if (p['passed'] == true) seen.add('passed');
      if (p['again'] == true) seen.add(p['rolled'] == 6 ? 'six' : 'try');
    } else {
      final pawn = _choose(g, rng);
      final seat = g.currentSeat;
      final from = g.progressOf(seat, pawn);
      await _tap(tester, 'ludo-pawn-$seat-$pawn');
      expect(c.moves.last.move, LudoGame.pawnMove(pawn), reason: 'the tapped pawn moved');
      final p = c.moves.last.event.payload as Map;
      if (from == LudoGame.house) seen.add('out');
      if (p['captured'] != null) seen.add('capture');
      if (p['again'] == true) seen.add('moveAgain');
      // Sometimes the move is taken back and made again (a roll is final).
      if (!(c.game as LudoGame).isOver && rng.nextInt(20) == 0) {
        await _tap(tester, 'shell-undo');
        expect(c.moves.length, before);
        expect((c.game as LudoGame).progressOf(seat, pawn), from);
        _checkScreen(tester, c);
        undos++;
        await _tap(tester, 'ludo-pawn-$seat-$pawn');
      }
    }
    expect(c.moves.length, before + 1, reason: 'one tap, one move');
    if (!(c.game as LudoGame).isOver) _checkScreen(tester, c);
    expect(tester.takeException(), isNull);
  }
  final g = c.game as LudoGame;
  expect(_key('result-dialog'), findsOneWidget);
  final r = g.seatResult;
  expect(g.homeCount(r.winner!), 4);
  expect(find.text('${_names[r.winner!]} gewinnt!'), findsOneWidget);
  for (var s = 0; s < g.playerCount; s++) {
    expect(_key('result-rank-$s'), findsOneWidget);
    expect(tester.widget<Text>(_key('result-score-$s')).data, '${g.homeCount(s)} im Ziel');
  }
  expect(c.moves.length, g.history.length);
  expect(seen, containsAll(['passed', 'out', 'capture', if (config.ludo.threeTries) 'try', if (config.ludo.sixAgain) 'moveAgain']));
  expect(undos, greaterThan(0));
  if (_verbose) {
    // ignore: avoid_print
    print('${config.players} players: ${c.moves.length} moves, $undos undos, places ${r.places}; $seen');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ExtraSeatNames.debugReset();
    UndoSettings.debugReset();
  });

  testWidgets('2 players', (tester) async {
    await _playGame(tester, const GameConfig('ludo', seed: 3));
  });

  testWidgets('4 players', (tester) async {
    await _playGame(tester, const GameConfig('ludo', seed: 7, players: 4));
  });

  testWidgets('3 players, house rules off', (tester) async {
    await _playGame(
        tester,
        const GameConfig('ludo',
            seed: 5,
            players: 3,
            ludo: LudoRules(threeTries: false, mustCapture: false, clearStart: false, sixAgain: false)));
  }, skip: !_full);
}
