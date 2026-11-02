// KLD-094 step 2: the hot-seat word tile screen, driven by taps and drags in
// the widget tree. Racks and bag are fixed with `debugSetup` so the tests
// know the tiles.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/games/wordtiles_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _sq(int r, int c) => find.byKey(Key('wordtiles-sq-$r-$c'));
Finder _rack(int i) => find.byKey(Key('wordtiles-rack-$i'));
const _play = Key('wordtiles-play');

WordTilesGame _game(GameController c) => c.game as WordTilesGame;

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(); // post-frame: hint, result dialog
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await _pump(tester);
}

/// A tablet-sized surface: squares big enough that the board does not zoom.
void _tablet(WidgetTester tester) {
  tester.view.physicalSize = const Size(1180, 820);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// A fresh game with known racks (A first) and a bag of E's.
Future<GameController> _start(WidgetTester tester,
    {List<String> a = const ['H', 'A', 'U', 'S', 'E', 'N', '?'],
    List<String> b = const ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
    int bag = 40,
    Locale locale = testLocale}) async {
  final c = GameController.hotSeat(const GameConfig('wordtiles', seed: 1));
  addTearDown(c.dispose);
  _game(c).debugSetup(racks: [a, b], bag: List.filled(bag, 'E'));
  await tester.pumpWidget(localizedApp(buildGameScreen(c), locale: locale));
  await _pump(tester);
  return c;
}

/// Lays rack tiles by tap: rack index → square.
Future<void> _lay(WidgetTester tester, List<(int, int, int)> tiles) async {
  for (final (i, r, col) in tiles) {
    await _tap(tester, _rack(i));
    await _tap(tester, _sq(r, col));
  }
}

String _text(WidgetTester tester, Key k) => tester.widget<Text>(find.byKey(k)).data!;

Future<void> _continue(WidgetTester tester) async {
  expect(find.byKey(handoverContinue), findsOneWidget);
  await _tap(tester, find.byKey(handoverContinue));
}

void main() {
  testWidgets('tap a rack tile, then a square; the preview scores the word; "Legen" plays it', (tester) async {
    _tablet(tester);
    final c = await _start(tester);
    expect(find.text('Das erste Wort muss über den Stern in der Mitte gehen.'), findsOneWidget, reason: 'hint');
    expect(find.byKey(_play), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(_play)).onPressed, isNull, reason: 'nothing laid yet');

    await _tap(tester, _rack(0));
    expect(find.text('Tippe ein freies Feld an.'), findsOneWidget);
    await _tap(tester, _sq(7, 7));
    expect(_rack(0), findsNothing, reason: 'the H left the rack');
    await _lay(tester, [(1, 7, 8), (2, 7, 9), (3, 7, 10)]);
    // H A U S on the centre (double word): (1+1+1+1)·2.
    expect(_text(tester, const Key('wordtiles-preview')), 'HAUS: 8 Punkte');

    // A laid tile goes back with a tap, and comes back by tap again.
    await _tap(tester, _sq(7, 10));
    expect(_rack(3), findsOneWidget);
    expect(_text(tester, const Key('wordtiles-preview')), 'HAU: 6 Punkte');
    await _lay(tester, [(3, 7, 10)]);

    await _tap(tester, find.byKey(_play));
    final g = _game(c);
    expect(g.scoreOf(0), 8);
    expect(g.tileAt(7, 7)?.letter, 'H');
    expect(g.rackOf(0), hasLength(7), reason: 'drew back up to 7');
    // Hot-seat: the cover hides B's rack and shows the public last turn.
    expect(find.byKey(handoverContinue), findsOneWidget);
    expect(_text(tester, const Key('wordtiles-cover-turn')), 'Anna: HAUS für 8 Punkte');
    await _continue(tester);
    expect(find.byKey(handoverContinue), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('wordtiles-score-0')), matching: find.text('8')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('wordtiles-bag')), matching: find.text('36')), findsOneWidget);
  });

  testWidgets('an invalid placement shows the reason in red and plays nothing', (tester) async {
    _tablet(tester);
    final c = await _start(tester);
    await _lay(tester, [(0, 7, 7), (1, 7, 9)]); // gap at 7-8
    expect(find.byKey(const Key('wordtiles-error')), findsNothing, reason: 'muted until "Legen"');
    expect(_text(tester, const Key('wordtiles-preview')), 'Zwischen den Steinen ist noch ein Feld frei.');
    await _tap(tester, find.byKey(_play));
    expect(_text(tester, const Key('wordtiles-error')), 'Zwischen den Steinen ist noch ein Feld frei.');
    expect(c.moves, isEmpty);
    expect(find.byKey(handoverContinue), findsNothing);

    // Off the centre.
    await _tap(tester, find.byKey(const Key('wordtiles-recall')));
    await _lay(tester, [(0, 3, 3), (1, 3, 4)]);
    await _tap(tester, find.byKey(_play));
    expect(_text(tester, const Key('wordtiles-error')), 'Das erste Wort muss über den Stern in der Mitte gehen.');
    expect(c.moves, isEmpty);
  });

  testWidgets('a blank asks for its letter; cancel puts it back on the rack', (tester) async {
    _tablet(tester);
    final c = await _start(tester);
    await _lay(tester, [(6, 7, 7)]);
    expect(find.byKey(const Key('wordtiles-blank-picker')), findsOneWidget);
    await _tap(tester, find.byKey(const Key('wordtiles-blank-cancel')));
    await tester.pumpAndSettle();
    expect(_rack(6), findsOneWidget);

    await _lay(tester, [(6, 7, 7)]);
    expect(find.byKey(const Key('wordtiles-blank-Ä')), findsOneWidget, reason: 'German set with umlauts');
    await _tap(tester, find.byKey(const Key('wordtiles-blank-E')));
    await tester.pumpAndSettle();
    await _lay(tester, [(5, 7, 8)]); // E N → "EN" (blank E scores 0)
    expect(_text(tester, const Key('wordtiles-preview')), 'EN: 2 Punkte');
    await _tap(tester, find.byKey(_play));
    expect(_game(c).tileAt(7, 7), const BoardTile('E', blank: true));
    expect(_game(c).scoreOf(0), 2);
  });

  testWidgets('drag a rack tile onto the board, and a laid tile back to the rack', (tester) async {
    _tablet(tester);
    await _start(tester);
    final from = tester.getCenter(_rack(0));
    final to = tester.getCenter(_sq(7, 7));
    await tester.dragFrom(from, to - from);
    await _pump(tester);
    expect(_rack(0), findsNothing);
    expect(find.descendant(of: _sq(7, 7), matching: find.text('H')), findsOneWidget);

    // Long-press drag back onto the rack.
    final g = await tester.startGesture(tester.getCenter(_sq(7, 7)));
    await tester.pump(const Duration(milliseconds: 600));
    await g.moveTo(tester.getCenter(find.byKey(const Key('wordtiles-rack'))));
    await tester.pump();
    await g.up();
    await _pump(tester);
    expect(_rack(0), findsOneWidget);
  });

  testWidgets('hot-seat challenge without a word list: the placement is withdrawn, the challenger plays on',
      (tester) async {
    _tablet(tester);
    final c = await _start(tester);
    await _lay(tester, [(0, 7, 7), (1, 7, 8), (2, 7, 9), (3, 7, 10)]);
    await _tap(tester, find.byKey(_play));
    await _continue(tester);
    expect(find.byKey(const Key('wordtiles-open')), findsOneWidget);
    expect(find.text('Anna legte HAUS für 8 Punkte.'), findsOneWidget);
    expect(find.text('Nimm das Wort an oder zweifle es an.'), findsOneWidget);

    await _tap(tester, find.byKey(const Key('wordtiles-challenge')));
    expect(find.byKey(const Key('wordtiles-challenge-dialog')), findsOneWidget);
    expect(find.textContaining('Ohne Wörterbuch zählt dein Einwand: Anna nimmt'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('wordtiles-challenge-confirm')));
    await tester.pumpAndSettle();
    final g = _game(c);
    expect(g.tileAt(7, 7), isNull);
    expect(g.scoreOf(0), 0);
    expect(g.currentSeat, 1, reason: 'the challenger plays on');
    expect(find.byKey(handoverContinue), findsNothing, reason: 'same player, no cover');
    expect(_text(tester, const Key('wordtiles-last-turn')), 'Ben: angezweifelt: HAUS zurückgenommen');
    expect(find.byKey(const Key('wordtiles-open')), findsNothing);
  });

  testWidgets('accept, swap and pass; the history lists the moves', (tester) async {
    _tablet(tester);
    final c = await _start(tester);
    await _lay(tester, [(0, 7, 7), (1, 7, 8)]);
    await _tap(tester, find.byKey(_play));
    await _continue(tester);
    await _tap(tester, find.byKey(const Key('wordtiles-accept')));
    expect(_text(tester, const Key('wordtiles-last-turn')), 'Ben: angenommen');

    // Swap two tiles.
    await _tap(tester, find.byKey(const Key('wordtiles-exchange')));
    expect(find.text('Wähle die Steine, die zurück in den Beutel sollen.'), findsOneWidget);
    await _tap(tester, _rack(0));
    await _tap(tester, _rack(1));
    expect(find.text('2 tauschen'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('wordtiles-exchange-confirm')));
    expect(_game(c).currentSeat, 0);
    expect(_text(tester, const Key('wordtiles-cover-turn')), 'Ben: 2 Steine getauscht');
    await _continue(tester);
    await _tap(tester, find.byKey(const Key('wordtiles-pass')));
    await _tap(tester, find.byKey(const Key('wordtiles-pass-confirm')));
    await _continue(tester);
    expect(_text(tester, const Key('wordtiles-last-turn')), 'Anna: gepasst');

    await _tap(tester, find.byKey(const Key('shell-history')));
    await tester.pumpAndSettle();
    for (final line in ['Anna: HA für 4 Punkte', 'Ben: angenommen', 'Ben: 2 Steine getauscht', 'Anna: gepasst']) {
      expect(find.descendant(of: find.byKey(const Key('history-sheet')), matching: find.text(line)), findsOneWidget,
          reason: line);
    }
  });

  testWidgets('swapping needs 7 tiles in the bag', (tester) async {
    _tablet(tester);
    final c = await _start(tester, bag: 6);
    await _tap(tester, find.byKey(const Key('wordtiles-exchange')));
    expect(_text(tester, const Key('wordtiles-error')),
        'Tauschen geht nur, solange mindestens 7 Steine im Beutel sind.');
    expect(find.byKey(const Key('wordtiles-exchange-confirm')), findsNothing);
    expect(c.moves, isEmpty);
  });

  testWidgets('six scoreless turns end the game: rack values come off, the result dialog says why', (tester) async {
    _tablet(tester);
    final c = await _start(tester);
    for (var i = 0; i < 6; i++) {
      await _tap(tester, find.byKey(const Key('wordtiles-pass')));
      await _tap(tester, find.byKey(const Key('wordtiles-pass-confirm')));
      if (i < 5) await _continue(tester);
    }
    await tester.pumpAndSettle();
    final g = _game(c);
    expect(g.isOver, isTrue);
    // A: H A U S E N ? = 1+1+1+1+1+1+0 = 6; B: T O R E N D I = 1+2+1+1+1+1+1 = 8.
    expect(g.scores, [-6, -8]);
    expect(find.byKey(resultDialog), findsOneWidget);
    expect(find.text('Anna gewinnt!'), findsOneWidget);
    expect(_text(tester, const Key('result-reason')), '6 Züge ohne Punkte, Endstand -6 : -8');
    expect(_text(tester, const Key('wordtiles-penalty-1')), '(−8)');
  });

  testWidgets('the last tile with an empty bag waits for the answer, accepting ends the game', (tester) async {
    _tablet(tester);
    final c = await _start(tester, a: const ['H', 'A'], bag: 0);
    await _lay(tester, [(0, 7, 7), (1, 7, 8)]);
    await _tap(tester, find.byKey(_play));
    await _continue(tester);
    expect(find.textContaining('hat alle Steine gelegt'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('wordtiles-pass'))).onPressed, isNull);
    await _tap(tester, find.byKey(const Key('wordtiles-accept')));
    await tester.pumpAndSettle();
    expect(_game(c).isOver, isTrue);
    // HA = (1+1)·2 = 4, plus B's rack (8); B loses 8.
    expect(_text(tester, const Key('result-reason')), 'Alle Steine gelegt, Endstand 12 : -8');
  });

  testWidgets('phone: the board zooms in on the first tile laid and out after the move', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _start(tester);
    double scale() =>
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!.value.getMaxScaleOnAxis();
    expect(scale(), 1);
    await _lay(tester, [(0, 7, 7)]);
    await tester.pumpAndSettle();
    expect(scale(), greaterThan(1.5));
    await tester.ensureVisible(_sq(7, 8));
    await _lay(tester, [(1, 7, 8)]);
    await tester.pumpAndSettle();
    expect(_text(tester, const Key('wordtiles-preview')), 'HA: 4 Punkte');
    await _tap(tester, find.byKey(_play));
    await _continue(tester);
    expect(scale(), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic: the board stays left-to-right', (tester) async {
    _tablet(tester);
    await _start(tester, locale: const Locale('ar'));
    expect(tester.getCenter(_sq(7, 0)).dx, lessThan(tester.getCenter(_sq(7, 14)).dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu: the Wortgewandt tile opens the word tile game (KLD-094 step 7: released)', (tester) async {
    await tester.pumpWidget(klunkiApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-preview-wordtiles')), findsNothing, reason: 'a tile now, no debug preview');
    await tester.ensureVisible(find.byKey(const Key('menu-wordtiles-tile')));
    await tester.tap(find.byKey(const Key('menu-wordtiles-tile')));
    await tester.pumpAndSettle();
    // KLD-094 step 4: the start options first (word list off here: the
    // loading is tested in wordtiles_dictionary_bench_test.dart).
    expect(find.byKey(const Key('wordtiles-options')), findsOneWidget);
    await tester.tap(find.byKey(const Key('wordtiles-dict')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wordtiles-options-next')));
    await tester.pumpAndSettle();
    if (find.byKey(const Key('hot-seat-names-ok')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
    }
    expect(find.byType(WordTilesScreen), findsOneWidget);
    expect(controllerOf(tester).config.dictionary, isFalse);
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Wortgewandt')), findsOneWidget);
    expect(controllerOf(tester).config.gameId, 'wordtiles');
    expect(find.byType(GameScreen), findsOneWidget);
  });
}
