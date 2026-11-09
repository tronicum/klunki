// KLD-060: whole Baulöwe games played through the real hot-seat UI, like
// players at one table would: the greedy bot (`PropertyBot`) decides, but
// every move is a tap on the screen ("Würfeln", "Kaufen", "Nicht kaufen",
// a bid, "Aussteigen", "Zug beenden", "Meine Straßen" → "Bauen" / "Verkaufen"
// / "Beleihen" / "Auslösen", "Pleite erklären"). After every move the screen
// is checked against the engine: the status names the seat that must move,
// every chip shows that seat's money, every token stands on its square, and
// the history has one line per move. Ends at the result dialog with the
// ranking.
//
//   flutter test test/e2e/live_ui/property_live_test.dart
//   KLUNKI_LIVE_UI_FULL=1 … also plays a long 3-player game
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';

final bool _verbose = Platform.environment['KLUNKI_LIVE_UI_VERBOSE'] == '1';
final bool _full = Platform.environment['KLUNKI_LIVE_UI_FULL'] == '1';

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  expect(_key(key), findsOneWidget, reason: key);
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<GameController> _pump(WidgetTester tester, GameConfig config) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

const _names = ['Anna', 'Ben', 'Cleo', 'Dani'];

/// The screen shows what the engine says.
void _checkScreen(WidgetTester tester, GameController c) {
  final g = c.game as PropertyGame;
  if (!g.isOver) expect(find.text('${_names[g.actor!]} ist am Zug'), findsOneWidget);
  for (var s = 0; s < g.playerCount; s++) {
    final cash = tester.widget<Text>(_key('property-cash-$s')).data!;
    final st = g.seats[s];
    if (st.out) {
      expect(cash, 'ausgeschieden');
      continue;
    }
    expect(cash, startsWith('${st.cash} Taler · '), reason: 'seat $s');
    expect(
        find.descendant(
            of: _key('property-square-${st.pos}'), matching: find.byWidgetPredicate((w) => w is SeatToken && w.seat == s)),
        findsOneWidget,
        reason: 'token of seat $s on ${st.pos}');
  }
}

/// Makes the bot's next move by tapping, returns its action.
Future<String> _playOne(WidgetTester tester, GameController c, PropertyBot bot) async {
  final g = c.game as PropertyGame;
  var m = bot.choose(g);
  // Trades have no screen yet (a later step): the bot plays on instead.
  if (m['action'] == 'tradeOffer') {
    m = g.legalMoves.firstWhere((x) => x['action'] == 'endTurn' || x['action'] == 'roll');
  }
  final action = m['action'] as String;
  final before = c.moves.length;
  switch (action) {
    case 'roll':
      await _tap(tester, 'property-roll');
    case 'buy':
      await _tap(tester, 'property-buy');
    case 'decline':
      await _tap(tester, 'property-decline');
    case 'bid':
      final offered = [for (final x in g.legalMoves) if (x['action'] == 'bid') x['amount'] as int];
      final i = offered.indexOf(m['amount'] as int);
      await _tap(tester, 'property-bid-${i < 0 ? 0 : i}');
    case 'pass':
      await _tap(tester, 'property-pass');
    case 'endTurn':
      await _tap(tester, 'property-end');
    case 'payBail':
      await _tap(tester, 'property-pay-bail');
    case 'useCard':
      await _tap(tester, 'property-use-card');
    case 'bankrupt':
      await _tap(tester, 'property-bankrupt');
    case 'build' || 'sell' || 'mortgage' || 'unmortgage':
      await _tap(tester, 'property-manage');
      // A long list is built lazily: scroll to the street like a player.
      final button = 'property-manage-$action-${m['square']}';
      await tester.scrollUntilVisible(_key(button), 120,
          scrollable: find.descendant(of: _key('property-manage-sheet'), matching: find.byType(Scrollable)).first);
      await _tap(tester, button);
      // Close the sheet (a tap above it).
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
    default:
      fail('no button for $m');
  }
  expect(c.moves.length, before + 1, reason: 'the tap on $action made one move');
  if (_verbose) {
    // ignore: avoid_print
    print('${c.moves.last.seat}: ${c.moves.last.move}');
  }
  return action;
}

Future<void> _playGame(WidgetTester tester, GameConfig config, {int maxMoves = 3000}) async {
  final c = await _pump(tester, config);
  final bot = PropertyBot(Random(config.seed));
  final seen = <String>{};
  var n = 0;
  while (!(c.game as PropertyGame).isOver) {
    expect(++n, lessThan(maxMoves), reason: 'the game should end');
    seen.add(await _playOne(tester, c, bot));
    if (!(c.game as PropertyGame).isOver) _checkScreen(tester, c);
    expect(tester.takeException(), isNull);
  }
  final g = c.game as PropertyGame;
  // The result dialog with every seat ranked.
  expect(_key('result-dialog'), findsOneWidget);
  final r = g.seatResult;
  for (var s = 0; s < g.playerCount; s++) {
    expect(_key('result-rank-$s'), findsOneWidget);
    final score = tester.widget<Text>(_key('result-score-$s')).data!;
    expect(score, g.isSeatOut(s) ? 'ausgeschieden' : '${r.params['worth$s']} Taler');
  }
  // The history lists every move.
  expect(c.moves.length, g.history.length);
  expect(seen, containsAll(['roll', 'endTurn']));
  if (_verbose) {
    // ignore: avoid_print
    print('${config.players} players, ${c.moves.length} moves, ${g.rounds} rounds: ${r.code} places ${r.places}; $seen');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.propertyIntro);
    ExtraSeatNames.debugReset();
    UndoSettings.debugReset();
  });

  testWidgets('2 players, 25 rounds, house rules on', (tester) async {
    await _playGame(
        tester,
        const GameConfig('property',
            seed: 7,
            property: PropertyOptions(rounds: 25, free: PropertyFreeSquare.pot, doubleStart: true, bankruptAuction: true)));
  });

  testWidgets('4 players, 12 rounds, Fantasiestadt', (tester) async {
    await _playGame(tester, const GameConfig('property', seed: 11, players: 4, property: PropertyOptions(theme: 'fantasie', rounds: 12)));
  });

  // Without trades (no screen yet) the bots rarely get a whole group, so a
  // game without a round limit can go on for ever: a long one instead.
  testWidgets('3 players, 80 rounds, pot with seed money, no rent in the pause', (tester) async {
    await _playGame(
        tester,
        const GameConfig('property',
            seed: 5,
            players: 3,
            property: PropertyOptions(rounds: 80, free: PropertyFreeSquare.potWithSeed, noRentInPause: true)),
        maxMoves: 20000);
  }, skip: !_full);
}
