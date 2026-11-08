// KLD-094 step 9: the house rule "Joker tauschen" in the UI. A rack tile
// dropped (or tapped, then the blank tapped) on a laid blank that stands for
// its letter stages the swap: the real letter shows on the square, the
// blank joins the rack. "Legen" sends the swap with the placement; a tap on
// the swapped square or "Alle zurück" undoes it. Off by default.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/games/wordtiles_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _sq(int r, int c) => find.byKey(Key('wordtiles-sq-$r-$c'));
Finder _rack(int i) => find.byKey(Key('wordtiles-rack-$i'));
final _swapped = find.byKey(const Key('wordtiles-swapped-7-7'));
const _play = Key('wordtiles-play');

WordTilesGame _game(GameController c) => c.game as WordTilesGame;

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await _pump(tester);
}

String _text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

/// HAUS across row 7 (cols 6–9) with the A a blank; Anna holds an A.
Future<GameController> _start(WidgetTester tester, {bool joker = true}) async {
  tester.view.physicalSize = const Size(1180, 820);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(GameConfig('wordtiles', seed: 1, jokerSwap: joker));
  addTearDown(c.dispose);
  _game(c).debugSetup(
    racks: const [
      ['A', 'N', 'B', 'C', 'D', 'R', 'T'],
      ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
    ],
    bag: List.filled(40, 'E'),
    board: const {
      (7, 6): BoardTile('H'),
      (7, 7): BoardTile('A', blank: true),
      (7, 8): BoardTile('U'),
      (7, 9): BoardTile('S'),
    },
  );
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await _pump(tester);
  return c;
}

/// Drags rack tile [i] onto [to] like a finger.
Future<void> _drag(WidgetTester tester, Finder from, Finder to) async {
  final start = tester.getCenter(from);
  final end = tester.getCenter(to);
  final g = await tester.startGesture(start);
  await tester.pump();
  for (var k = 1; k <= 6; k++) {
    await g.moveTo(Offset.lerp(start, end, k / 6)!);
    await tester.pump();
  }
  await g.up();
  await _pump(tester);
}

void main() {
  setUp(() {
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
  });

  testWidgets('tap the A, then the blank: staged; the blank is laid; "Legen" sends the swap', (tester) async {
    final c = await _start(tester);
    expect(find.text(deL10n.wordtilesHintJoker), findsOneWidget, reason: 'a swap is possible');
    await _tap(tester, _rack(0));
    await _tap(tester, _sq(7, 7));
    expect(_swapped, findsOneWidget);
    expect(_rack(0), findsNothing, reason: 'the A lies on the board');
    expect(_rack(7), findsOneWidget, reason: 'the blank joined the rack');
    expect(_text(tester, const Key('wordtiles-preview')), deL10n.wordtilesJokerStaged);
    expect(tester.widget<FilledButton>(find.byKey(_play)).onPressed, isNull, reason: 'a swap alone is no move');
    expect(_game(c).tileAt(7, 7)!.blank, isTrue, reason: 'only staged');
    // N and the blank (as E) below the A: ANE; the A now counts 1, N 1.
    await _tap(tester, _rack(1));
    await _tap(tester, _sq(8, 7));
    await _tap(tester, _rack(7));
    await _tap(tester, _sq(9, 7));
    await _tap(tester, find.byKey(const Key('wordtiles-blank-E')));
    expect(_text(tester, const Key('wordtiles-preview')), 'ANE: 2 Punkte');
    await _tap(tester, find.byKey(_play));
    await tester.pumpAndSettle();
    expect(c.moves.single.move['swaps'], [
      {'row': 7, 'col': 7, 'tile': 'A'},
    ]);
    expect(_game(c).tileAt(7, 7), const BoardTile('A'));
    expect(_game(c).tileAt(9, 7), const BoardTile('E', blank: true));
    expect(_game(c).scoreOf(0), 2);
    expect(describeWordTilesMove(deL10n, c.moves.single), 'ANE für 2 Punkte (Joker getauscht)');
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag the A onto the blank; a tap on the swapped square undoes it, the laid blank too', (tester) async {
    final c = await _start(tester);
    await _drag(tester, _rack(0), _sq(7, 7));
    expect(_swapped, findsOneWidget);
    await _tap(tester, _rack(7));
    await _tap(tester, _sq(8, 7));
    await _tap(tester, find.byKey(const Key('wordtiles-blank-E')));
    expect(find.descendant(of: _sq(8, 7), matching: find.text('E')), findsOneWidget);
    // Undo: the A goes back to the rack, its blank leaves the board.
    await _tap(tester, _swapped);
    expect(_swapped, findsNothing);
    expect(_rack(0), findsOneWidget);
    expect(_rack(7), findsNothing);
    expect(find.descendant(of: _sq(8, 7), matching: find.text('E')), findsNothing);
    expect(tester.widget<FilledButton>(find.byKey(_play)).onPressed, isNull);
    // The other letters cannot take it.
    await _drag(tester, _rack(1), _sq(7, 7));
    expect(_swapped, findsNothing);
    expect(c.moves, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the challenge banner says "(Joker getauscht)"; one point is "1 Punkt"', (tester) async {
    final c = await _start(tester);
    await _tap(tester, _rack(0));
    await _tap(tester, _sq(7, 7));
    // The blank as N below the A: AN, 1 point (the A).
    await _tap(tester, _rack(7));
    await _tap(tester, _sq(8, 7));
    await _tap(tester, find.byKey(const Key('wordtiles-blank-N')));
    expect(_text(tester, const Key('wordtiles-preview')), 'AN: 1 Punkt');
    await _tap(tester, find.byKey(_play));
    await tester.pumpAndSettle();
    if (find.byKey(const Key('handover-continue')).evaluate().isNotEmpty) {
      await _tap(tester, find.byKey(const Key('handover-continue')));
      await tester.pumpAndSettle();
    }
    expect(_game(c).canChallenge, isTrue);
    expect(
      find.descendant(
        of: find.byKey(const Key('wordtiles-open')),
        matching: find.text('Anna legte AN für 1 Punkt (Joker getauscht).'),
      ),
      findsOneWidget,
    );
    expect(describeWordTilesMove(deL10n, c.moves.single), 'AN für 1 Punkt (Joker getauscht)');
  });

  testWidgets('"Alle zurück" drops the staged swap; with the rule off nothing is staged', (tester) async {
    await _start(tester);
    await _tap(tester, _rack(0));
    await _tap(tester, _sq(7, 7));
    await _tap(tester, _rack(1));
    await _tap(tester, _sq(8, 7));
    await _tap(tester, find.byKey(const Key('wordtiles-recall')));
    expect(_swapped, findsNothing);
    expect(_rack(0), findsOneWidget);
    expect(_rack(1), findsOneWidget);
    expect(_rack(7), findsNothing);
  });

  testWidgets('off by default: no hint, the blank stays', (tester) async {
    final c = await _start(tester, joker: false);
    expect(find.text(deL10n.wordtilesHintJoker), findsNothing);
    await _tap(tester, _rack(0));
    await _tap(tester, _sq(7, 7));
    await _drag(tester, _rack(0), _sq(7, 7));
    expect(_swapped, findsNothing);
    expect(_rack(7), findsNothing);
    expect(c.moves, isEmpty);
  });

  testWidgets('the rules page lists the house rule as on (KLD-123)', (tester) async {
    final c = await _start(tester);
    await _tap(tester, find.byKey(const Key('shell-rules')));
    await tester.pumpAndSettle();
    final joker = find.byKey(const Key('rules-house-joker'));
    expect(find.descendant(of: joker, matching: find.text(deL10n.wordtilesOptionJokerExplain)), findsOneWidget);
    expect(_game(c).jokerSwap, isTrue);
  });

  testWidgets('start options: "Joker tauschen" is off by default and starts the game with it', (tester) async {
    await tester.pumpWidget(klunkiApp(locale: const Locale('en')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('menu-wordtiles-tile')));
    await tester.tap(find.byKey(const Key('menu-wordtiles-tile')));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('wordtiles-joker'))).value, isFalse);
    // The word list off, so no list has to load.
    await tester.tap(find.byKey(const Key('wordtiles-dict')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('wordtiles-joker')));
    await tester.tap(find.byKey(const Key('wordtiles-joker')));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('wordtiles-joker'))).value, isTrue);
    expect(_text(tester, const Key('wordtiles-joker-explain')), startsWith('House rule'));
    await tester.tap(find.byKey(const Key('wordtiles-options-next')));
    await tester.pumpAndSettle();
    if (find.byKey(const Key('hot-seat-names-ok')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
    }
    final config = controllerOf(tester).config;
    expect(config.jokerSwap, isTrue);
    expect(_game(controllerOf(tester)).jokerSwap, isTrue);
  });
}
