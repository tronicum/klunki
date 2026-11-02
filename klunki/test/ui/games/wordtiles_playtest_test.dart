// KLD-094 step 8 (playtest fixes): the rack always shows every tile the
// engine holds. Before, tiles left on a collapsed Bänkchen (the default on
// a small phone) vanished from the screen: the rack looked short although
// the engine had refilled it to 7 from the bag.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _sq(int r, int c) => find.byKey(Key('wordtiles-sq-$r-$c'));
Finder _rack(int i) => find.byKey(Key('wordtiles-rack-$i'));
Finder _slot(int r, int s) => find.byKey(Key('wordtiles-bench-$r-$s'));
final _rackRow = find.byKey(const Key('wordtiles-rack'));
const _toggle = Key('wordtiles-bench-toggle');

WordTilesGame _game(GameController c) => c.game as WordTilesGame;

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await _pump(tester);
}

Future<GameController> _start(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(const GameConfig('wordtiles', seed: 1));
  addTearDown(c.dispose);
  _game(c).debugSetup(
      racks: [
        ['B', 'A', 'U', 'M', 'E', 'N', 'S'],
        ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
      ],
      bag: List.filled(40, 'E'));
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await _pump(tester);
  return c;
}

/// Every tile of the rack on screen is somewhere a finger reaches: in the
/// rack row or on the open bench, each exactly once.
void _expectWholeRack(WidgetTester tester, GameController c, {String reason = ''}) {
  final rack = _game(c).rackOf(_game(c).currentSeat);
  expect(rack.length == WordTilesGame.rackSize || _game(c).bagCount == 0, isTrue, reason: 'engine: $rack');
  for (var i = 0; i < rack.length; i++) {
    expect(_rack(i), findsOneWidget, reason: '$reason tile $i (${rack[i]}) not on screen');
  }
}

void main() {
  // A fresh install; the one-time bench explanation already seen, except
  // in its own group below.
  setUp(SeenTips.debugReset);
  setUp(() => SeenTips.shared.markFirst(SeenTips.wordtilesBench));

  for (final (name, size) in [('small phone', Size(375, 667)), ('large phone', Size(430, 932))]) {
    testWidgets('$name: tiles left on the bench come back into the rack when it is closed', (tester) async {
      final c = await _start(tester, size);
      await _tap(tester, find.byKey(_toggle));
      for (final (i, s) in [(2, 0), (3, 1)]) {
        await _tap(tester, _rack(i));
        await _tap(tester, _slot(0, s));
      }
      expect(find.descendant(of: _rackRow, matching: _rack(2)), findsNothing, reason: 'on the bench now');
      _expectWholeRack(tester, c);
      // Closed: the bench tiles are back in the rack row.
      await _tap(tester, find.byKey(_toggle));
      expect(_slot(0, 0), findsNothing);
      _expectWholeRack(tester, c, reason: 'bench closed:');
      expect(find.descendant(of: _rackRow, matching: _rack(2)), findsOneWidget);

      // Anna plays B A; Ben passes; Anna's next turn: a full rack on screen
      // (U M kept their places on the bench, which is closed).
      await _tap(tester, _rack(0));
      await _tap(tester, _sq(7, 7));
      await _tap(tester, _rack(1));
      await _tap(tester, _sq(7, 8));
      await _tap(tester, find.byKey(const Key('wordtiles-play')));
      expect(_game(c).rackOf(0), hasLength(7));
      await _tap(tester, find.byKey(handoverContinue));
      _expectWholeRack(tester, c, reason: 'Ben:');
      await _tap(tester, find.byKey(const Key('wordtiles-pass')));
      await _tap(tester, find.byKey(const Key('wordtiles-pass-confirm')));
      await _tap(tester, find.byKey(handoverContinue));
      _expectWholeRack(tester, c, reason: 'Anna again, bench closed:');
      for (var i = 0; i < 7; i++) {
        expect(find.descendant(of: _rackRow, matching: _rack(i)), findsOneWidget, reason: 'tile $i in the rack row');
      }
      // Open again: U M are still on the bench, the rack keeps their places.
      await _tap(tester, find.byKey(_toggle));
      expect(find.descendant(of: _slot(0, 0), matching: find.text('U')), findsOneWidget);
      expect(find.descendant(of: _slot(0, 1), matching: find.text('M')), findsOneWidget);
      _expectWholeRack(tester, c, reason: 'Anna again, bench open:');
      // Their places in the rack are gaps; a tap on one brings the tile back.
      final rack = _game(c).rackOf(0);
      final u = rack.indexOf('U'), m = rack.indexOf('M');
      expect(find.descendant(of: _rackRow, matching: find.byKey(Key('wordtiles-rack-gap-$u'))), findsOneWidget);
      expect(find.descendant(of: _rackRow, matching: find.byKey(Key('wordtiles-rack-gap-$m'))), findsOneWidget);
      await _tap(tester, find.byKey(Key('wordtiles-rack-gap-$m')));
      expect(find.descendant(of: _rackRow, matching: _rack(m)), findsOneWidget);
      expect(find.byKey(Key('wordtiles-rack-gap-$m')), findsNothing);
      _expectWholeRack(tester, c);
      expect(tester.takeException(), isNull);
    });
  }

  group('one-time bench explanation', () {
    setUp(SeenTips.debugReset); // nothing seen yet

    testWidgets('the first opening: three steps over the empty bench, then never again', (tester) async {
      final c = await _start(tester, const Size(375, 667));
      expect(find.byKey(const Key('wordtiles-coach')), findsNothing, reason: 'not before the bench is opened');
      await _tap(tester, find.byKey(_toggle));
      expect(find.byKey(const Key('wordtiles-coach')), findsOneWidget);
      expect(find.byKey(const Key('wordtiles-coach-step-1')), findsOneWidget);
      expect(find.text('1 von 3'), findsOneWidget);
      expect(find.text(deL10n.wordtilesCoachBench1), findsOneWidget);
      expect(find.byKey(const Key('wordtiles-bench-score-0')), findsNothing, reason: 'the bench is empty');
      expect(SeenTips.shared.has(SeenTips.wordtilesBench), isTrue);
      await _tap(tester, find.byKey(const Key('wordtiles-coach-next')));
      expect(find.text(deL10n.wordtilesCoachBench2), findsOneWidget);
      expect(find.text('2 von 3'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('wordtiles-coach-next')));
      expect(find.text(deL10n.wordtilesCoachBench3), findsOneWidget);
      expect(find.byKey(const Key('wordtiles-coach-skip')), findsNothing);
      await _tap(tester, find.byKey(const Key('wordtiles-coach-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wordtiles-coach')), findsNothing);
      // The bench works as before.
      await _tap(tester, _rack(0));
      await _tap(tester, _slot(0, 0));
      expect(find.descendant(of: _slot(0, 0), matching: _rack(0)), findsOneWidget);
      // Closed and opened again (and Ben's turn): no explanation.
      await _tap(tester, find.byKey(_toggle));
      await _tap(tester, find.byKey(_toggle));
      expect(find.byKey(const Key('wordtiles-coach')), findsNothing);
      await _tap(tester, find.byKey(const Key('wordtiles-pass')));
      await _tap(tester, find.byKey(const Key('wordtiles-pass-confirm')));
      await _tap(tester, find.byKey(handoverContinue));
      expect(_game(c).currentSeat, 1);
      expect(find.byKey(const Key('wordtiles-coach')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Überspringen" closes it on any step and counts as seen', (tester) async {
      await _start(tester, const Size(1180, 820));
      await _tap(tester, find.byKey(_toggle));
      expect(find.byKey(const Key('wordtiles-coach')), findsOneWidget);
      await _tap(tester, find.byKey(const Key('wordtiles-coach-skip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wordtiles-coach')), findsNothing);
      expect(_slot(0, 0), findsOneWidget, reason: 'the bench is open');
      await _tap(tester, find.byKey(_toggle));
      await _tap(tester, find.byKey(_toggle));
      expect(find.byKey(const Key('wordtiles-coach')), findsNothing);
    });
  });
}
