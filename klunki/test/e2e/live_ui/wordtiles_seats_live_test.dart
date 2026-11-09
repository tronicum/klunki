// KLD-125: Wortgewandt for 3 and 4 players on one device, played to the end
// through the real UI like a table of players: each player gets the device
// behind the handover cover (which names them, with their seat token, and
// shows the last turn), lays the best sample placement tile by tile (rack
// tile, then square), sometimes swaps, passes, parks tiles on the Bänkchen,
// answers or challenges the open placement (the adapter of the two-player
// live test, wordtiles_adapter.dart). The 3-player game uses the German word
// list with one "Trotzdem zulassen" (agreed by the table, logged as the next
// player's answer); the 4-player game runs on an iPhone SE (the board
// auto-zooms, four seats in the score row).
//
// Checks after every step: the status pill names the seat to move, the
// screen shows the latest turn (cover, challenge banner or last-turn line)
// as the engine has it, every seat gets a cover before its turn and never
// sees another seat's rack; at the end the ranking lists every seat with the
// rack deduction and "Nochmal" keeps the player count.
//
//   cd klunki && flutter test test/e2e/live_ui/wordtiles_seats_live_test.dart
//   KLUNKI_LIVE_UI_VERBOSE=1 flutter test test/e2e/live_ui/wordtiles_seats_live_test.dart
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/games/wordtiles/word_list_loader.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import '../../support/test_run.dart';
import 'live_ui_driver.dart';
import 'wordtiles_adapter.dart';

const _names = ['Anna', 'Ben', 'Cleo', 'Dani'];

String? _textOf(WidgetTester tester, Key k) {
  final f = find.byKey(k);
  return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
}

/// The text the screen shows for [t] (the last-turn line and the cover).
String _line(WordTilesTurn t) => '${_names[t.seat]}: ${turnText(deL10n, t)}';

/// Plays [config] to the end through the UI; returns the controller.
Future<GameController> _play(WidgetTester tester, WordTilesAdapter adapter, GameConfig config, Random rng,
    {int maxSteps = 4000}) async {
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pump();
  await tester.pump();
  expect(find.byType(SeatGameScreen), findsOneWidget);
  final d = UiDevice('hot-seat');
  final g = c.game as WordTilesGame;
  final alive = testRunGuard(tester);
  final shownTurns = <int>{};
  final covers = <int>[];
  var lastCoverMoves = -1;
  var turnSeat = g.currentSeat;
  final log = <String>[];
  for (var step = 0; step < maxSteps; step++) {
    alive();
    if (d.resultShown()) break;
    final game = c.game as WordTilesGame;
    if (d.hasKey(const Key('handover-cover'))) {
      // The cover names the seat to move, shows its token and the last turn.
      final seat = game.actorSeat!;
      expect(find.text(deL10n.shellHandoverPass(_names[seat])), findsOneWidget, reason: 'cover for seat $seat');
      expect(tester.widget<SeatToken>(find.byKey(const Key('handover-seat'))).seat, seat);
      expect(find.byKey(const Key('wordtiles-rack')).hitTestable(), findsNothing, reason: 'the rack is covered');
      if (game.turns.isNotEmpty) {
        expect(_textOf(tester, const Key('wordtiles-cover-turn')), _line(game.turns.last));
        shownTurns.add(game.turns.length - 1);
      }
      expect(c.moves.length, isNot(lastCoverMoves), reason: 'one cover per handover');
      lastCoverMoves = c.moves.length;
      covers.add(seat);
      log.add('cover ${_names[seat]}');
      await d.tapKey(tester, const Key('handover-continue'));
      turnSeat = seat;
      continue;
    }
    // A new seat to move always came through a cover.
    expect(game.currentSeat, turnSeat, reason: 'seat ${game.currentSeat} plays without a cover\n${log.join('\n')}');
    expect(_textOf(tester, const Key('shell-status')), deL10n.shellToMove(_names[game.currentSeat]));
    // The latest turn is on screen: the last-turn line or the banner.
    if (game.turns.isNotEmpty) {
      final t = game.turns.last;
      final line = _textOf(tester, const Key('wordtiles-last-turn'));
      if (line != null) {
        expect(line, _line(t));
      } else {
        expect(find.byKey(const Key('wordtiles-open')), findsOneWidget, reason: 'turn ${game.turns.length - 1}');
        expect(game.challengeable?.seat, t.seat);
        expect(
            find.descendant(
                of: find.byKey(const Key('wordtiles-open')), matching: find.textContaining('${_names[t.seat]} legte')),
            findsOneWidget);
      }
      shownTurns.add(game.turns.length - 1);
    }
    final m = await adapter.play(tester, d, rng);
    if (m == null) fail('nothing to do at step $step\n${log.join('\n')}');
    log.add('${_names[game.currentSeat]} taps ${m['action']}');
    await tester.pumpAndSettle();
  }
  final game = c.game as WordTilesGame;
  expect(game.isOver, isTrue, reason: 'did not end in $maxSteps steps');
  await tester.pumpAndSettle();
  // Every turn but the last (under the result dialog) was on screen.
  expect(shownTurns, containsAll(List.generate(game.turns.length - 1, (i) => i)));
  // Every seat had the device behind a cover.
  expect(covers.toSet(), containsAll(game.activeSeats.where((s) => s != 0)));
  if (liveUiVerbose) debugPrint(log.join('\n'));
  return c;
}

/// The result dialog: the ranking with every seat in place order, the
/// rack deduction where there is one, the reason without a score.
void _checkResult(WidgetTester tester, GameController c) {
  final g = c.game as WordTilesGame;
  final r = g.seatResult;
  expect(find.byKey(const Key('result-dialog')), findsOneWidget);
  final w = r.winner;
  expect(find.text(w == null ? deL10n.seatSharedFirst : deL10n.shellWins(_names[w])), findsOneWidget);
  for (var s = 0; s < g.playerCount; s++) {
    expect(find.byKey(Key('result-rank-$s')), findsOneWidget);
    expect(find.descendant(of: find.byKey(Key('result-rank-$s')), matching: find.text(deL10n.seatPoints(g.scoreOf(s)))),
        findsOneWidget);
    final pen = g.rackPenalties[s];
    expect(find.byKey(Key('result-rank-note-$s')), pen == 0 ? findsNothing : findsOneWidget);
  }
  final order = r.ranking;
  for (var i = 1; i < order.length; i++) {
    expect(tester.getTopLeft(find.byKey(Key('result-rank-${order[i - 1]}'))).dy,
        lessThan(tester.getTopLeft(find.byKey(Key('result-rank-${order[i]}'))).dy));
    expect(g.scoreOf(order[i - 1]), greaterThanOrEqualTo(g.scoreOf(order[i])));
  }
  final reason = tester.widget<Text>(find.byKey(const Key('result-reason'))).data;
  expect(reason, anyOf(deL10n.engineReasonWordtilesPlayedOutSeats, deL10n.engineReasonWordtilesScorelessSeats(g.scorelessLimit)));
  expect(find.byKey(const Key('wordtiles-result-best')), findsOneWidget);
}

/// The bundled Roboto, so the heights are those of the real app (the test
/// font is taller and wider; on an iPhone SE it squeezes the board).
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

  testWidgets('3 players, German word list, tablet: allow, swap, pass, to the end; "Nochmal" keeps 3', (tester) async {
    await tester.runAsync(() => WordListLoader.ensure('de'));
    addTearDown(WordListLoader.reset);
    tester.view.physicalSize = const Size(1180, 820) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final adapter = WordTilesDictionaryAdapter();
    final c = await _play(
        tester, adapter, const GameConfig('wordtiles', seed: 3, players: 3, dictionary: true), Random(3));
    final g = c.game as WordTilesGame;
    expect(adapter.tapped['allow'], 1, reason: '${adapter.tapped}');
    expect(adapter.tapped['place'] ?? 0, greaterThan(5), reason: '${adapter.tapped}');
    // "Trotzdem zulassen": seat 0 asked, the next seat (1) answered for the table.
    final ask = c.moves.indexWhere((m) => m.move['action'] == WordTilesGame.requestAllow);
    expect(c.moves[ask].seat, 0);
    expect(c.moves[ask + 1].move['action'], WordTilesGame.acceptAllow);
    expect(c.moves[ask + 1].seat, 1);
    expect(g.turns.expand((t) => t.allowed), isNotEmpty);
    _checkResult(tester, c);
    debugPrint('wordtiles 3 players: ${adapter.tapped}, ${c.moves.length} moves, ${g.seatResult.code}, '
        'scores ${g.scores}, rack ${g.rackPenalties}');
    await tester.tap(find.byKey(const Key('result-again')));
    await tester.pumpAndSettle();
    final again = c.game as WordTilesGame;
    expect(c.moves, isEmpty);
    expect(again.playerCount, 3);
    expect(again.check, WordCheck.dictionary);
  }, timeout: liveUiTimeout);

  testWidgets('4 players on an iPhone SE: a whole game, the board zooms, every seat behind its cover',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final adapter = WordTilesAdapter();
    final c = await _play(tester, adapter, const GameConfig('wordtiles', seed: 2, players: 4), Random(14));
    final g = c.game as WordTilesGame;
    expect(adapter.tapped['place'] ?? 0, greaterThan(5), reason: '${adapter.tapped}');
    expect(adapter.benchTiles, greaterThan(0));
    _checkResult(tester, c);
    expect(tester.takeException(), isNull);
    debugPrint('wordtiles 4 players: ${adapter.tapped}, ${c.moves.length} moves, ${g.seatResult.code}, '
        'scores ${g.scores}, rack ${g.rackPenalties}');
  }, timeout: liveUiTimeout);
}
