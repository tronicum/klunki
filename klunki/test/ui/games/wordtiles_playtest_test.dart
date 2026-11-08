// KLD-094 step 8 (playtest fixes): the rack always shows every tile the
// engine holds. Before, tiles left on a collapsed Bänkchen (the default on
// a small phone) vanished from the screen: the rack looked short although
// the engine had refilled it to 7 from the bag.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

bool _benchShown() => _slot(0, 0).evaluate().isNotEmpty;

/// Opens the bench where it is closed (it starts open on a large phone,
/// KLD-094 step 8c).
Future<void> _openBench(WidgetTester tester) async {
  if (!_benchShown()) await _tap(tester, find.byKey(_toggle));
  expect(_benchShown(), isTrue);
}

Future<void> _pass(WidgetTester tester) async {
  await _tap(tester, find.byKey(const Key('wordtiles-pass')));
  await _tap(tester, find.byKey(const Key('wordtiles-pass-confirm')));
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

/// The bundled Roboto: the layout's heights (and so whether the bench
/// starts open, KLD-094 step 8c) are those of the real app.
Future<void> _loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Roboto/Roboto-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadRoboto);
  // A fresh install; the one-time bench explanation already seen, except
  // in its own group below.
  setUp(SeenTips.debugReset);
  setUp(() => SeenTips.shared.markFirst(SeenTips.wordtilesBench));
  // The steady layout: without the "Neu hier?" line of a new player (KLD-123).
  setUp(() => SeenTips.shared.markFirst(SeenTips.rulesOpened('wordtiles')));

  for (final (name, size) in [('small phone', Size(375, 667)), ('large phone', Size(430, 932))]) {
    testWidgets('$name: tiles left on the bench come back into the rack when it is closed', (tester) async {
      final c = await _start(tester, size);
      await _openBench(tester);
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
    setUp(() {
      SeenTips.debugReset(); // nothing seen yet
      SeenTips.shared.markFirst(SeenTips.rulesOpened('wordtiles')); // but the rules (KLD-123)
    });

    testWidgets('the first opening: three steps over the empty bench, then never again', (tester) async {
      final c = await _start(tester, const Size(375, 667));
      expect(find.byKey(const Key('wordtiles-coach')), findsNothing, reason: 'not before the bench is opened');
      await _tap(tester, find.byKey(_toggle));
      await tester.pumpAndSettle(); // it waits a frame for the layout to settle
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
      // Open from the start on the tablet: the explanation comes right away.
      expect(find.byKey(const Key('wordtiles-coach')), findsOneWidget);
      await _tap(tester, find.byKey(const Key('wordtiles-coach-skip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wordtiles-coach')), findsNothing);
      expect(_slot(0, 0), findsOneWidget, reason: 'the bench is open');
      await _tap(tester, find.byKey(_toggle));
      await _tap(tester, find.byKey(_toggle));
      expect(find.byKey(const Key('wordtiles-coach')), findsNothing);
    });

    for (final size in [const Size(430, 932), const Size(412, 915)]) {
      testWidgets('large phone $size: open from the start, the explanation without a tap, once', (tester) async {
        final c = await _start(tester, size);
        expect(_benchShown(), isTrue);
        expect(find.byKey(const Key('wordtiles-coach-step-1')), findsOneWidget);
        expect(SeenTips.shared.has(SeenTips.wordtilesBench), isTrue);
        await _tap(tester, find.byKey(const Key('wordtiles-coach-skip')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('wordtiles-coach')), findsNothing);
        // Ben's turn (bench open too): not again.
        await _pass(tester);
        await _tap(tester, find.byKey(handoverContinue));
        await tester.pumpAndSettle();
        expect(_game(c).currentSeat, 1);
        expect(_benchShown(), isTrue);
        expect(find.byKey(const Key('wordtiles-coach')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('hot-seat: not under the handover cover, right after it', (tester) async {
      // Anna on a small phone: closed, no explanation.
      final c = await _start(tester, const Size(375, 667));
      expect(_benchShown(), isFalse);
      await _pass(tester);
      expect(find.byKey(handoverContinue), findsOneWidget);
      // Now a large screen (e.g. the device turned): the bench is open under
      // the cover, but the explanation waits for Ben to continue.
      tester.view.physicalSize = const Size(430, 932);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wordtiles-coach')), findsNothing, reason: 'the cover is up');
      expect(SeenTips.shared.has(SeenTips.wordtilesBench), isFalse);
      await _tap(tester, find.byKey(handoverContinue));
      await tester.pumpAndSettle();
      expect(_game(c).currentSeat, 1);
      expect(find.byKey(const Key('wordtiles-coach')), findsOneWidget);
      expect(_benchShown(), isTrue);
    });
  });

  group('open or closed at the start (KLD-094 step 8c)', () {
    for (final (size, open) in [
      (const Size(430, 932), true),
      (const Size(412, 915), true),
      (const Size(1180, 820), true),
      (const Size(390, 844), false),
      (const Size(375, 667), false),
      (const Size(820, 1180), true), // a tablet in portrait: open, the board a little smaller
    ]) {
      testWidgets('$size: ${open ? 'open' : 'closed'}', (tester) async {
        await _start(tester, size);
        expect(_benchShown(), open);
        expect(find.byKey(const Key('wordtiles-bench-overlay')), findsNothing);
      });
    }

    for (final (size, open) in [(const Size(430, 932), true), (const Size(375, 667), false)]) {
      testWidgets('$size: the choice holds across turns', (tester) async {
        final c = await _start(tester, size);
        expect(_benchShown(), open);
        await _tap(tester, find.byKey(_toggle)); // the other way round
        expect(_benchShown(), !open);
        for (final seat in [1, 0, 1]) {
          await _pass(tester);
          await _tap(tester, find.byKey(handoverContinue));
          expect(_game(c).currentSeat, seat);
          expect(_benchShown(), !open, reason: 'seat $seat');
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
