// KLD-094 step 5 (hot-seat polish): the score bar without names, the pass
// confirmation, the blank's "0", "So geht's", the bench over the board on a
// small phone, and the result summary.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/games/wordtiles_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';

WordTilesGame _game(GameController c) => c.game as WordTilesGame;

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<GameController> _start(WidgetTester tester,
    {List<List<String>> racks = const [
      ['B', 'A', 'U', 'M', 'E', 'N', '?'],
      ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
    ],
    List<String>? bag}) async {
  final c = GameController.hotSeat(const GameConfig('wordtiles', seed: 1));
  addTearDown(c.dispose);
  _game(c).debugSetup(racks: racks, bag: bag ?? List.filled(40, 'E'));
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  // The one-time bench explanation is seen (wordtiles_playtest_test).
  setUp(() {
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
    SeenTips.shared.markFirst(SeenTips.rulesOpened('wordtiles')); // no "Neu hier?" line (KLD-123)
  });

  testWidgets('score bar: token, name and score (KLD-094 step 8g); the semantics label says it all', (tester) async {
    _size(tester, const Size(1180, 820));
    await _start(tester);
    final seat = find.byKey(const Key('wordtiles-score-0'));
    expect(find.descendant(of: seat, matching: find.text('Anna')), findsOneWidget);
    expect(find.byKey(const Key('shell-players')), findsNothing, reason: 'no second legend');
    expect(find.descendant(of: seat, matching: find.text('0')), findsOneWidget);
    expect(tester.getSemantics(seat).label, deL10n.wordtilesScore('Anna', 0));
  });

  testWidgets('"Passen" asks first; cancel keeps the turn, confirm passes', (tester) async {
    _size(tester, const Size(1180, 820));
    final c = await _start(tester);
    await _tap(tester, find.byKey(const Key('wordtiles-pass')));
    expect(find.byKey(const Key('wordtiles-pass-dialog')), findsOneWidget);
    expect(find.text(deL10n.wordtilesPassBody(1, 6)), findsOneWidget);
    await _tap(tester, find.byKey(const Key('wordtiles-pass-cancel')));
    expect(c.moves, isEmpty);
    await _tap(tester, find.byKey(const Key('wordtiles-pass')));
    await _tap(tester, find.byKey(const Key('wordtiles-pass-confirm')));
    expect(c.moves.single.move, {'action': 'pass'});
    // Ben's confirmation counts this pass.
    await _tap(tester, find.byKey(const Key('handover-continue')));
    await _tap(tester, find.byKey(const Key('wordtiles-pass')));
    expect(find.text(deL10n.wordtilesPassBody(2, 6)), findsOneWidget);
  });

  testWidgets('the blank shows a 0 on the rack and in the picker', (tester) async {
    _size(tester, const Size(1180, 820));
    final c = await _start(tester);
    final blank = find.byKey(Key('wordtiles-rack-${_game(c).rackOf(0).indexOf('?')}'));
    expect(find.descendant(of: blank, matching: find.text('0')), findsOneWidget);
    await _tap(tester, blank);
    await _tap(tester, find.byKey(const Key('wordtiles-sq-7-7')));
    expect(find.byKey(const Key('wordtiles-blank-score')), findsOneWidget);
    expect(find.text(deL10n.wordtilesBlankScore), findsOneWidget);
  });

  testWidgets('the rules page ("So geht\'s" before, KLD-123) opens from the app bar with the premium legend',
      (tester) async {
    _size(tester, const Size(1180, 820));
    await _start(tester);
    await _tap(tester, find.byKey(const Key('shell-rules')));
    expect(find.byKey(const Key('rules-page')), findsOneWidget);
    for (final p in ['doubleLetter', 'tripleLetter', 'doubleWord', 'tripleWord']) {
      expect(find.byKey(Key('wordtiles-help-premium-$p')), findsOneWidget);
    }
    expect(find.text(deL10n.wordtilesHelpBingo(7, 50)), findsOneWidget);
    expect(find.text(deL10n.wordtilesHelpPass(6)), findsOneWidget);
    // No dictionary in this game: the challenge comes first.
    expect(tester.getTopLeft(find.textContaining(deL10n.wordtilesHelpChallenge)).dy,
        lessThan(tester.getTopLeft(find.text(deL10n.wordtilesHelpDictionary)).dy));
  });

  testWidgets('small phone: the open bench lies over the board, which keeps its size', (tester) async {
    _size(tester, const Size(375, 667));
    await _start(tester);
    expect(find.byKey(const Key('wordtiles-bench-0-0')), findsNothing, reason: 'collapsed at first');
    final board = tester.getSize(find.byKey(const Key('wordtiles-sq-0-0')));
    // The collapsed bench is a slim bar between the board and the rack
    // (KLD-094 step 8f), not in the score row.
    final bar = find.byKey(const Key('wordtiles-bench-bar'));
    expect(find.descendant(of: bar, matching: find.byKey(const Key('wordtiles-bench-toggle'))), findsOneWidget);
    expect(
        find.descendant(
            of: find.ancestor(of: find.byKey(const Key('wordtiles-score-end')), matching: find.byType(Row)).at(1),
            matching: find.byKey(const Key('wordtiles-bench-toggle'))),
        findsNothing);
    await _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));
    final overlay = find.byKey(const Key('wordtiles-bench-overlay'));
    expect(overlay, findsOneWidget);
    expect(find.descendant(of: overlay, matching: find.byKey(const Key('wordtiles-bench-0-0'))), findsOneWidget);
    // Open, the same bar closes it (the overlay grows upwards from it).
    expect(find.descendant(of: bar, matching: find.byKey(const Key('wordtiles-bench-toggle'))), findsOneWidget);
    expect(find.descendant(of: overlay, matching: find.byKey(const Key('wordtiles-bench-toggle'))), findsNothing);
    expect(tester.getSize(find.byKey(const Key('wordtiles-sq-0-0'))), board, reason: 'the board did not shrink');
    // (The test font is wider than the real one; with the app font the
    // board is about 268 px, 6 px less since the bench's handle bar sits
    // between board and rack, KLD-094 step 8f.)
    expect(board.width * WordTilesBoardTestInfo.squares, greaterThan(212));
    // Tap a rack tile, then a slot: it moves onto the bench.
    await _tap(tester, find.byKey(const Key('wordtiles-rack-0')));
    await _tap(tester, find.byKey(const Key('wordtiles-bench-0-0')));
    expect(find.descendant(of: find.byKey(const Key('wordtiles-bench-0-0')), matching: find.text('B')), findsOneWidget);
    await _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));
    expect(find.byKey(const Key('wordtiles-bench-overlay')), findsNothing);
  });

  testWidgets('tablet: the bench stays in the panel (no overlay), below the actions', (tester) async {
    _size(tester, const Size(1180, 820));
    await _start(tester);
    expect(find.byKey(const Key('wordtiles-bench-0-0')), findsOneWidget, reason: 'open from the start (KLD-094 step 8c)');
    expect(tester.getTopLeft(find.byKey(const Key('wordtiles-bench'))).dy,
        greaterThan(tester.getBottomLeft(find.byKey(const Key('wordtiles-play'))).dy));
    expect(find.byKey(const Key('wordtiles-bench-overlay')), findsNothing);
  });

  testWidgets('result: final scores, rack penalties, the best word', (tester) async {
    _size(tester, const Size(1180, 820));
    final c = await _start(tester, racks: const [
      ['H', 'A', 'U', 'S', 'Y'],
      ['I'],
    ], bag: const []);
    await c.submit(WordTilesGame.placeMove(const [
      PlacedTile(7, 4, 'H'),
      PlacedTile(7, 5, 'A'),
      PlacedTile(7, 6, 'U'),
      PlacedTile(7, 7, 'S'),
    ]));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('handover-continue')));
    await _tap(tester, find.byKey(const Key('wordtiles-accept')));
    // Ben lays the I (HAUSI) and is out; Anna accepts: the game is over.
    await c.submit(WordTilesGame.placeMove(const [PlacedTile(7, 8, 'I')]));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('handover-continue')));
    await _tap(tester, find.byKey(const Key('wordtiles-accept')));
    final g = _game(c);
    expect(g.isOver, isTrue);
    expect(find.byKey(const Key('result-dialog')), findsOneWidget);
    expect(find.byKey(const Key('wordtiles-result')), findsOneWidget);
    final y = TileSet.german.pointsOf('Y');
    expect(find.text(deL10n.wordtilesResultRack('−$y')), findsOneWidget);
    expect(find.text(deL10n.wordtilesResultRack('+$y')), findsOneWidget);
    final (seat, word, score) = WordTilesResult.bestWord(c)!;
    expect(find.text(deL10n.wordtilesResultBestWord(word, seat == 0 ? 'Anna' : 'Ben', score)), findsOneWidget);
    expect(find.byKey(const Key('wordtiles-result-allowed')), findsNothing);
  });

  test('best word: a placement withdrawn after a challenge does not count', () {
    final c = GameController.hotSeat(const GameConfig('wordtiles', seed: 1));
    addTearDown(c.dispose);
    _game(c).debugSetup(racks: const [
      ['Q', 'U', 'A', 'X', 'E', 'E', 'E'],
      ['H', 'A', 'U', 'S', 'E', 'E', 'E'],
    ], bag: List.filled(40, 'E'));
    c.submit(WordTilesGame.placeMove(const [PlacedTile(7, 6, 'Q'), PlacedTile(7, 7, 'U'), PlacedTile(7, 8, 'A'), PlacedTile(7, 9, 'X')]));
    c.submit(const {'action': 'challenge'});
    c.submit(WordTilesGame.placeMove(const [PlacedTile(7, 7, 'H'), PlacedTile(7, 8, 'A')]));
    final best = WordTilesResult.bestWord(c);
    expect(best?.$2, 'HA');
    expect(best?.$1, 1);
  });
}

/// The board is 15 squares wide.
abstract final class WordTilesBoardTestInfo {
  static const int squares = WordTilesGame.size;
}
