// KLD-094 (bug from the maintainer, 2026-11-09): "Trotzdem zulassen" in
// hot-seat. Before, the request and the agreement went in at once; the
// other player could only refuse through "Zug zurücknehmen" on the cover,
// and the cover then named the placer while the other player had to answer
// (the controller followed `currentPlayer`, not the player who has to act),
// so after the refusal the device seemed stuck on the cover. Now the request
// hands the device to the player who answers (cover, then the answer dialog
// over their own rack), a refusal hands it back to the placer (tiles on the
// rack, still their turn), an agreement lets the answerer play on. With 3–4
// at one device the same, the next seat still in answers (KLD-125, the
// maintainer on 2026-11-15; before, the table agreed together at once).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/games/wordtiles/word_list_loader.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_board.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';

Finder _key(String k) => find.byKey(Key(k));
const _continue = Key('handover-continue');

const _racks = [
  ['H', 'A', 'U', 'S', 'E', 'N', 'T'],
  ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
  ['L', 'A', 'M', 'P', 'E', 'R', 'S'],
];

Future<GameController> _start(WidgetTester tester, {int players = 2}) async {
  await tester.runAsync(() => WordListLoader.ensure('de'));
  addTearDown(WordListLoader.reset);
  tester.view.physicalSize = const Size(1180, 820) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  // Seed 18 deals H, S and A to Anna and no blank (KLD-072): undo replays the log from the dealt racks.
  final c = GameController.hotSeat(GameConfig('wordtiles', seed: 18, dictionary: true, players: players));
  addTearDown(c.dispose);
  (c.game as WordTilesGame).debugSetup(racks: _racks.take(players).toList(), bag: List.filled(40, 'E'));
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// "Zug zurücknehmen", then "Zurücknehmen" in the question (KLD-094).
Future<void> _undo(WidgetTester tester) async {
  await _tap(tester, _key('shell-undo'));
  expect(_key('undo-dialog'), findsOneWidget);
  await _tap(tester, _key('undo-confirm'));
}

/// Anna lays "HSA" (not in the list) and asks "Trotzdem zulassen".
Future<void> _askHsa(WidgetTester tester) async {
  for (final (i, col) in [(0, 7), (3, 8), (1, 9)]) {
    await _tap(tester, _key('wordtiles-rack-$i'));
    await _tap(tester, _key('wordtiles-sq-7-$col'));
  }
  await _tap(tester, _key('wordtiles-play'));
  expect(_key('wordtiles-unknown'), findsOneWidget);
  expect(find.text('Du kannst die Steine zurücknehmen oder Ben fragen, ob es trotzdem zählt.'), findsOneWidget);
  await _tap(tester, _key('wordtiles-unknown-allow'));
}

/// The rack on screen holds [letters] (in rack order).
void _expectRack(List<String> letters) {
  for (final (i, l) in letters.indexed) {
    expect(find.descendant(of: _key('wordtiles-rack-$i'), matching: find.text(l)), findsWidgets, reason: 'rack $i');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
    ExtraSeatNames.debugReset();
  });

  testWidgets('2 players: Ben gets the device, refuses; the device goes back to Anna, tiles on her rack',
      (tester) async {
    final c = await _start(tester);
    final g = c.game as WordTilesGame;
    await _askHsa(tester);
    // The device goes to Ben: the cover names him and says what he is asked.
    expect([for (final m in c.moves) m.move['action']], [WordTilesGame.requestAllow]);
    expect(find.text('Gib das Gerät an Ben weiter'), findsOneWidget);
    expect(find.text('Anna möchte „HSA“ zulassen (6 Punkte).'), findsOneWidget);
    expect(_key('wordtiles-allow-dialog'), findsNothing, reason: 'not over the cover');
    await _tap(tester, find.byKey(_continue));
    // Ben answers over his own rack, never Anna's.
    expect(_key('wordtiles-allow-dialog'), findsOneWidget);
    expect(find.text('Anna möchte „HSA“ zulassen – einverstanden?'), findsOneWidget);
    _expectRack(_racks[1]);
    expect(find.text('Ben entscheidet…'), findsOneWidget);
    await _tap(tester, _key('wordtiles-allow-decline'));
    // Back to Anna: the cover names her, then her turn goes on.
    expect([for (final m in c.moves) m.move['action']], [WordTilesGame.requestAllow, WordTilesGame.declineAllow]);
    expect(find.text('Gib das Gerät an Anna weiter'), findsOneWidget);
    await _tap(tester, find.byKey(_continue));
    expect(find.byKey(_continue), findsNothing, reason: 'no longer stuck on the cover');
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    expect(find.text('Ben lehnt „HSA“ ab.'), findsOneWidget);
    expect(g.currentSeat, 0);
    expect(g.rackOf(0), _racks[0]);
    _expectRack(_racks[0]);
    expect(g.tileAt(7, 7), isNull, reason: 'the tiles left the board');
    // Anna plays on: the same word cannot be asked again, "HAUS" can be laid.
    await _askAgainRefused(tester);
    for (final (i, col) in [(0, 7), (1, 8), (2, 9), (3, 10)]) {
      await _tap(tester, _key('wordtiles-rack-$i'));
      await _tap(tester, _key('wordtiles-sq-7-$col'));
    }
    await _tap(tester, _key('wordtiles-play'));
    expect(g.scoreOf(0), 8);
    expect(find.text('Gib das Gerät an Ben weiter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('2 players: Ben agrees; his turn at once (he holds the device), no cover', (tester) async {
    final c = await _start(tester);
    final g = c.game as WordTilesGame;
    await _askHsa(tester);
    await _tap(tester, find.byKey(_continue));
    await _tap(tester, _key('wordtiles-allow-accept'));
    expect([for (final m in c.moves) m.move['action']], [WordTilesGame.requestAllow, WordTilesGame.acceptAllow]);
    expect(find.byKey(_continue), findsNothing);
    expect(find.text('Ben ist am Zug'), findsOneWidget);
    expect(g.scoreOf(0), 6);
    expect(g.turns.single.allowed, ['HSA']);
    _expectRack(_racks[1]);
    expect(find.text('Anna: HSA für 6 Punkte (zugelassen: HSA)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('2 players: "Zug zurücknehmen" on Ben\'s cover takes the request back to Anna', (tester) async {
    final c = await _start(tester);
    await _askHsa(tester);
    await _undo(tester);
    expect(c.moves, isEmpty);
    expect(_key('wordtiles-allow-dialog'), findsNothing);
    expect(find.text('Gib das Gerät an Anna weiter'), findsOneWidget);
    await _tap(tester, find.byKey(_continue));
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    // (Undo replays the log from the seed: the dealt rack, not the test's.)
    _expectRack((c.game as WordTilesGame).rackOf(0));
  });

  testWidgets('3 players: Ben (the next player) gets the device behind the cover, agrees and plays on',
      (tester) async {
    final c = await _start(tester, players: 3);
    final g = c.game as WordTilesGame;
    expect(find.byType(SeatGameScreen), findsOneWidget);
    // As with two (maintainer, 2026-11-15): the next player is asked.
    await _askHsa(tester);
    expect([for (final m in c.moves) (m.move['action'], m.seat)], [(WordTilesGame.requestAllow, 0)]);
    expect(find.text('Gib das Gerät an Ben weiter'), findsOneWidget);
    expect(find.text('Anna möchte „HSA“ zulassen (6 Punkte).'), findsOneWidget);
    expect(tester.widget<SeatToken>(_key('handover-seat')).seat, 1);
    expect(_key('wordtiles-allow-dialog'), findsNothing, reason: 'not over the cover');
    await _tap(tester, find.byKey(_continue));
    expect(_key('wordtiles-allow-dialog'), findsOneWidget);
    expect(find.text('Anna möchte „HSA“ zulassen – einverstanden?'), findsOneWidget);
    _expectRack(_racks[1]);
    expect(find.text('Ben ist am Zug'), findsOneWidget, reason: 'the seat pill names who acts');
    expect(tester.widget<SeatToken>(find.descendant(of: _key('shell-turn'), matching: find.byType(SeatToken))).seat, 1);
    await _tap(tester, _key('wordtiles-allow-accept'));
    expect([for (final m in c.moves) (m.move['action'], m.seat)],
        [(WordTilesGame.requestAllow, 0), (WordTilesGame.acceptAllow, 1)]);
    // Ben holds the device already: his turn, no cover.
    expect(find.byKey(_continue), findsNothing);
    expect(find.text('Ben ist am Zug'), findsOneWidget);
    expect(g.currentSeat, 1);
    expect(g.scoreOf(0), 6);
    _expectRack(_racks[1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('3 players: Ben refuses; the device goes back to Anna, tiles on her rack', (tester) async {
    final c = await _start(tester, players: 3);
    final g = c.game as WordTilesGame;
    await _askHsa(tester);
    await _tap(tester, find.byKey(_continue));
    await _tap(tester, _key('wordtiles-allow-decline'));
    expect([for (final m in c.moves) (m.move['action'], m.seat)],
        [(WordTilesGame.requestAllow, 0), (WordTilesGame.declineAllow, 1)]);
    expect(find.text('Gib das Gerät an Anna weiter'), findsOneWidget);
    expect(tester.widget<SeatToken>(_key('handover-seat')).seat, 0);
    await _tap(tester, find.byKey(_continue));
    expect(find.byKey(_continue), findsNothing);
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    expect(find.text('Ben lehnt „HSA“ ab.'), findsOneWidget);
    expect(g.currentSeat, 0);
    _expectRack(_racks[0]);
    expect(g.tileAt(7, 7), isNull);
    await _askAgainRefused(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('3 players, Ben resigned: Anna\'s request goes to the next seat still in (seat 3)', (tester) async {
    final c = await _start(tester, players: 3);
    final g = c.game as WordTilesGame;
    await tester.runAsync(() => c.resignSeat(1));
    await tester.pumpAndSettle();
    expect(g.isSeatOut(1), isTrue);
    expect(g.currentSeat, 0);
    final third = wordTilesSeatName(tester.element(find.byType(SeatGameScreen)), g, 2);
    for (final (i, col) in [(0, 7), (3, 8), (1, 9)]) {
      await _tap(tester, _key('wordtiles-rack-$i'));
      await _tap(tester, _key('wordtiles-sq-7-$col'));
    }
    await _tap(tester, _key('wordtiles-play'));
    expect(find.text('Du kannst die Steine zurücknehmen oder $third fragen, ob es trotzdem zählt.'), findsOneWidget);
    await _tap(tester, _key('wordtiles-unknown-allow'));
    expect(g.allowRequestAnswerer, 2);
    expect(find.text('Gib das Gerät an $third weiter'), findsOneWidget);
    expect(tester.widget<SeatToken>(_key('handover-seat')).seat, 2);
    await _tap(tester, find.byKey(_continue));
    expect(_key('wordtiles-allow-dialog'), findsOneWidget);
    _expectRack(_racks[2]);
    await _tap(tester, _key('wordtiles-allow-decline'));
    expect(c.moves.last.seat, 2);
    expect(find.text('Gib das Gerät an Anna weiter'), findsOneWidget);
    await _tap(tester, find.byKey(_continue));
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    _expectRack(_racks[0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('3 players: "Zug zurücknehmen" on Ben\'s request cover takes the request back to Anna',
      (tester) async {
    final c = await _start(tester, players: 3);
    await _askHsa(tester);
    await _undo(tester);
    expect(c.moves, isEmpty);
    expect(_key('wordtiles-allow-dialog'), findsNothing);
    expect(find.text('Gib das Gerät an Anna weiter'), findsOneWidget);
    await _tap(tester, find.byKey(_continue));
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('2 players: the old refusal path (undo on Ben\'s cover after an agreement) no longer sticks',
      (tester) async {
    final c = await _start(tester);
    await _askHsa(tester);
    await _tap(tester, find.byKey(_continue));
    await _tap(tester, _key('wordtiles-allow-accept'));
    // Ben has the device; he takes his agreement back and refuses.
    await _undo(tester);
    expect(find.byKey(_continue), findsNothing);
    expect(_key('wordtiles-allow-dialog'), findsOneWidget);
    await _tap(tester, _key('wordtiles-allow-decline'));
    expect(find.text('Gib das Gerät an Anna weiter'), findsOneWidget);
    await _tap(tester, find.byKey(_continue));
    expect(find.byKey(_continue), findsNothing);
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    expect((c.game as WordTilesGame).currentSeat, 0);
  });
}

/// Asking for "HSA" again in the same turn offers only "Zurücknehmen".
Future<void> _askAgainRefused(WidgetTester tester) async {
  for (final (i, col) in [(0, 7), (3, 8), (1, 9)]) {
    await _tap(tester, _key('wordtiles-rack-$i'));
    await _tap(tester, _key('wordtiles-sq-7-$col'));
  }
  await _tap(tester, _key('wordtiles-play'));
  expect(find.text('Ben hat das schon abgelehnt. Nimm die Steine zurück.'), findsOneWidget);
  expect(_key('wordtiles-unknown-allow'), findsNothing);
  await _tap(tester, _key('wordtiles-unknown-withdraw'));
  _expectRack(_racks[0]);
}
