// KLD-094 step 4: Wortgewandt with a word list (the check at "Legen",
// "Zurücknehmen" / "Trotzdem zulassen"), the start options (tile language,
// "Wörterbuch prüfen") and the bench ("Bänkchen"), driven through the UI.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/games/wordtiles/word_list_loader.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_options.dart';
import 'package:klunki/ui/games/wordtiles_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_engine/sha256.dart';

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _sq(int r, int c) => find.byKey(Key('wordtiles-sq-$r-$c'));
Finder _rack(int i) => find.byKey(Key('wordtiles-rack-$i'));
Finder _slot(int r, int s) => find.byKey(Key('wordtiles-bench-$r-$s'));
const _play = Key('wordtiles-play');

WordTilesGame _game(GameController c) => c.game as WordTilesGame;

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await _pump(tester);
}

void _tablet(WidgetTester tester) {
  tester.view.physicalSize = const Size(1180, 820);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

SortedWordListValidator _list(List<String> words) =>
    SortedWordListValidator.fromUtf8(Uint8List.fromList(utf8.encode('${(words.toList()..sort()).join('\n')}\n')));

Future<GameController> _start(WidgetTester tester,
    {List<String> a = const ['B', 'A', 'U', 'M', 'E', 'N', '?'],
    List<String> b = const ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
    GameConfig config = const GameConfig('wordtiles', seed: 1)}) async {
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  _game(c).debugSetup(racks: [a, b], bag: List.filled(40, 'E'));
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await _pump(tester);
  return c;
}

Future<void> _lay(WidgetTester tester, List<(int, int, int)> tiles) async {
  for (final (i, r, col) in tiles) {
    await _tap(tester, _rack(i));
    await _tap(tester, _sq(r, col));
  }
}

String _text(WidgetTester tester, Key k) => tester.widget<Text>(find.byKey(k)).data!;

void main() {
  tearDown(WordListLoader.reset);

  group('check at "Legen" with a word list', () {
    const dict = GameConfig('wordtiles', seed: 1, dictionary: true);
    setUp(() => WordLists.register('de', _list(['BAUM', 'BAUMEN', 'TOR'])));

    testWidgets('a known word is played at once; the preview never tells whether a word is in the list',
        (tester) async {
      _tablet(tester);
      final c = await _start(tester, config: dict);
      expect(_game(c).check, WordCheck.dictionary);
      await _lay(tester, [(0, 7, 7), (1, 7, 8)]); // BA: not a word in the list
      expect(_text(tester, const Key('wordtiles-preview')), 'BA: 6 Punkte', reason: 'score only, no ✓/✗');
      expect(find.byIcon(Icons.check_circle), findsNothing);
      await _lay(tester, [(2, 7, 9), (3, 7, 10)]); // BAUM
      await _tap(tester, find.byKey(_play));
      expect(find.byKey(const Key('wordtiles-unknown')), findsNothing);
      expect(c.moves, hasLength(1));
      expect(_game(c).canChallenge, isFalse, reason: 'with a list, the check at "Legen" replaces the challenge');
      await _tap(tester, find.byKey(handoverContinue));
      expect(find.byKey(const Key('wordtiles-challenge')), findsNothing);
    });

    testWidgets('"Zurücknehmen": the tiles go back to the rack, nothing is played, the turn goes on', (tester) async {
      _tablet(tester);
      final c = await _start(tester, config: dict);
      await _lay(tester, [(0, 7, 7), (1, 7, 8), (2, 7, 9)]); // BAU
      await _tap(tester, find.byKey(_play));
      expect(find.byKey(const Key('wordtiles-unknown')), findsOneWidget);
      expect(find.text('„BAU“ steht nicht im Wörterbuch.'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('wordtiles-unknown-withdraw')));
      await tester.pumpAndSettle();
      expect(c.moves, isEmpty);
      expect(_game(c).boardEmpty, isTrue);
      for (var i = 0; i < 7; i++) {
        expect(_rack(i), findsOneWidget, reason: 'rack tile $i back');
      }
      expect(find.byKey(handoverContinue), findsNothing, reason: 'still the same player');
    });

    testWidgets('"Trotzdem zulassen": the placement counts and the history names the allowed word', (tester) async {
      _tablet(tester);
      final c = await _start(tester, config: dict);
      await _lay(tester, [(0, 7, 7), (1, 7, 8), (2, 7, 9)]); // BAU
      await _tap(tester, find.byKey(_play));
      await _tap(tester, find.byKey(const Key('wordtiles-unknown-allow')));
      await tester.pumpAndSettle();
      // KLD-094 step 6 (rules 3): on one device the request and the other
      // player's agreement go in back to back.
      expect(c.moves.map((m) => m.move['action']), [WordTilesGame.requestAllow, WordTilesGame.acceptAllow]);
      expect(c.moves.first.move['allow'], ['BAU']);
      expect(c.moves.last.move['player'], 'b');
      expect(_game(c).scoreOf(0), 8, reason: '(2+1+1)·2 on the centre');
      expect(_text(tester, const Key('wordtiles-cover-turn')), 'Anna: BAU für 8 Punkte (zugelassen: BAU)');
      expect(describeWordTilesMove(deL10n, c.moves.first), 'möchte BAU zulassen (8 Punkte)');
      expect(describeWordTilesMove(deL10n, c.moves.last), 'einverstanden: BAU zählt (8 Punkte)');
    });
  });

  group('start options', () {
    testWidgets('German app: German tiles and the word list on by default; the game starts with them',
        (tester) async {
      WordLists.register('de', _list(['BAUM']));
      await tester.pumpWidget(klunkiApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('menu-wordtiles-tile')));
      await tester.tap(find.byKey(const Key('menu-wordtiles-tile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wordtiles-options')), findsOneWidget);
      final seg = tester.widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));
      expect(seg.selected, {'de'});
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('wordtiles-dict'))).value, isTrue);
      expect(_text(tester, const Key('wordtiles-dict-explain')), startsWith('Jedes gelegte Wort wird nachgeschlagen.'));
      await tester.tap(find.byKey(const Key('wordtiles-options-next')));
      await tester.pumpAndSettle();
      if (find.byKey(const Key('hot-seat-names-ok')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
        await tester.pumpAndSettle();
      }
      final config = controllerOf(tester).config;
      expect(config.tiles, 'de');
      expect(config.dictionary, isTrue);
      expect(_game(controllerOf(tester)).tileSet, TileSet.german);
    });

    testWidgets('English app: English tiles by default; switching the language and the list off', (tester) async {
      await tester.pumpWidget(klunkiApp(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('menu-wordtiles-tile')));
      await tester.tap(find.byKey(const Key('menu-wordtiles-tile')));
      await tester.pumpAndSettle();
      expect(tester.widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>)).selected, {'en'});
      await tester.tap(find.byKey(const Key('wordtiles-tiles-de')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wordtiles-dict')));
      await tester.pumpAndSettle();
      expect(_text(tester, const Key('wordtiles-dict-explain')), startsWith('Without a dictionary'));
      await tester.tap(find.byKey(const Key('wordtiles-options-next')));
      await tester.pumpAndSettle();
      if (find.byKey(const Key('hot-seat-names-ok')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
        await tester.pumpAndSettle();
      }
      final config = controllerOf(tester).config;
      expect(config.tiles, 'de');
      expect(config.dictionary, isFalse);
      expect(_game(controllerOf(tester)).check, WordCheck.challenge);
    });

    test('the default tile language follows the app language', () {
      expect(defaultWordTilesTiles(const Locale('de')), 'de');
      for (final l in ['en', 'fr', 'es', 'zh', 'ar', 'fa']) {
        expect(defaultWordTilesTiles(Locale(l)), 'en');
      }
    });
  });

  group('bench ("Bänkchen")', () {
    // Closed at first (KLD-094 step 8); its one-time explanation is seen.
    setUp(() {
      SeenTips.debugReset();
      SeenTips.shared.markFirst(SeenTips.wordtilesBench);
    });
    Future<void> open(WidgetTester tester) => _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));

    testWidgets('tap a tile, then a slot; the row shows the base score; back to the rack by drag', (tester) async {
      _tablet(tester);
      await _start(tester);
      await open(tester);
      expect(find.byKey(const Key('wordtiles-bench')), findsOneWidget);
      expect(find.text('Zieh Steine hierher und probier Wörter aus.'), findsOneWidget);
      // B A U M into row 0.
      for (final (i, s) in [(0, 0), (1, 1), (2, 2), (3, 3)]) {
        await _tap(tester, _rack(i));
        await _tap(tester, _slot(0, s));
      }
      expect(find.descendant(of: _slot(0, 0), matching: _rack(0)), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('wordtiles-rack')), matching: _rack(0)), findsNothing);
      // B 2 + A 1 + U 1 + M 2 (letter points; premiums only count on the board).
      expect(_text(tester, const Key('wordtiles-bench-score-0')), '6');
      expect(find.byKey(const Key('wordtiles-bench-score-1')), findsNothing);
      expect(find.text('Zieh Steine hierher und probier Wörter aus.'), findsNothing);

      // Drag M from the bench back to the rack: BAU = 4.
      final from = tester.getCenter(_rack(3));
      final to = tester.getCenter(find.byKey(const Key('wordtiles-rack')));
      await tester.dragFrom(from, to - from);
      await _pump(tester);
      expect(find.descendant(of: find.byKey(const Key('wordtiles-rack')), matching: _rack(3)), findsOneWidget);
      expect(_text(tester, const Key('wordtiles-bench-score-0')), '4');

      // Drag a rack tile into row 1, then move it within the bench.
      var f = tester.getCenter(_rack(4));
      var t = tester.getCenter(_slot(1, 4));
      await tester.dragFrom(f, t - f);
      await _pump(tester);
      expect(find.descendant(of: _slot(1, 4), matching: _rack(4)), findsOneWidget);
      f = tester.getCenter(_rack(4));
      t = tester.getCenter(_slot(0, 3));
      await tester.dragFrom(f, t - f);
      await _pump(tester);
      expect(find.descendant(of: _slot(0, 3), matching: _rack(4)), findsOneWidget);
      expect(_text(tester, const Key('wordtiles-bench-score-0')), '5', reason: 'BAUE');

      // Clear: everything back on the rack.
      await _tap(tester, find.byKey(const Key('wordtiles-bench-clear')));
      expect(find.byKey(const Key('wordtiles-bench-score-0')), findsNothing);
      for (var i = 0; i < 7; i++) {
        expect(find.descendant(of: find.byKey(const Key('wordtiles-rack')), matching: _rack(i)), findsOneWidget);
      }
    });

    testWidgets('bench tiles are rack tiles: laid straight from the bench onto the board', (tester) async {
      _tablet(tester);
      final c = await _start(tester);
      await open(tester);
      for (final (i, s) in [(0, 0), (1, 1)]) {
        await _tap(tester, _rack(i));
        await _tap(tester, _slot(0, s));
      }
      // Tap on the bench tile selects it, then a square lays it.
      await _tap(tester, _rack(0));
      await _tap(tester, _sq(7, 7));
      // Drag the other one from the bench onto the board.
      final f = tester.getCenter(_rack(1));
      final t = tester.getCenter(_sq(7, 8));
      await tester.dragFrom(f, t - f);
      await _pump(tester);
      expect(find.byKey(const Key('wordtiles-bench-score-0')), findsNothing, reason: 'the bench is empty again');
      expect(_text(tester, const Key('wordtiles-preview')), 'BA: 6 Punkte');
      await _tap(tester, find.byKey(_play));
      expect(c.moves.single.move['tiles'], hasLength(2));
      expect(_game(c).rackOf(0), hasLength(7), reason: 'the engine rack model is unchanged');
    });

    testWidgets('each player keeps a private bench: hidden behind the cover, back on the next turn', (tester) async {
      _tablet(tester);
      final c = await _start(tester);
      await open(tester);
      // Anna puts U and M on her bench and plays B A.
      for (final (i, s) in [(2, 0), (3, 1)]) {
        await _tap(tester, _rack(i));
        await _tap(tester, _slot(0, s));
      }
      await _lay(tester, [(0, 7, 7), (1, 7, 8)]);
      await _tap(tester, find.byKey(_play));
      expect(c.moves, hasLength(1));
      // The cover is up: no bench (nor rack) visible.
      expect(find.byKey(handoverContinue), findsOneWidget);
      expect(find.byKey(const Key('wordtiles-bench')), findsNothing);
      expect(_slot(0, 0), findsNothing);
      await _tap(tester, find.byKey(handoverContinue));
      // Ben's bench is empty.
      expect(find.byKey(const Key('wordtiles-bench-score-0')), findsNothing);
      expect(find.text('Zieh Steine hierher und probier Wörter aus.'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('wordtiles-pass')));
      await _tap(tester, find.byKey(const Key('wordtiles-pass-confirm')));
      await _tap(tester, find.byKey(handoverContinue));
      // Anna's U M are still on her bench (her rack changed: B A were laid).
      final rack = _game(c).rackOf(0);
      final u = find.descendant(of: _slot(0, 0), matching: find.text('U'));
      final m = find.descendant(of: _slot(0, 1), matching: find.text('M'));
      expect(u, findsOneWidget);
      expect(m, findsOneWidget);
      expect(_text(tester, const Key('wordtiles-bench-score-0')), '3');
      expect(rack, containsAll(['U', 'M']));
    });

    testWidgets('collapsible: closed at first; "Bänkchen" shows and hides the rows; the rack stays', (tester) async {
      _tablet(tester);
      await _start(tester);
      expect(_slot(0, 0), findsNothing);
      await open(tester);
      expect(_slot(0, 0), findsOneWidget);
      await _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));
      expect(_slot(0, 0), findsNothing);
      expect(find.byKey(const Key('wordtiles-rack')), findsOneWidget);
      await open(tester);
      expect(_slot(0, 0), findsOneWidget);
    });

    testWidgets('small iPhone (375 × 667): board, rack, bench and actions fit without overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _start(tester);
      expect(tester.takeException(), isNull);
      // Collapsed by default on a small phone; opening it still fits.
      expect(_slot(0, 0), findsNothing);
      await _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));
      expect(_slot(0, 0), findsOneWidget);
      expect(tester.takeException(), isNull);
      final board = tester.getSize(find.byKey(const Key('wordtiles-board')));
      expect(board.width, greaterThan(150));
      expect(tester.getBottomLeft(find.byKey(_play)).dy, lessThanOrEqualTo(667));
    });
  });

  group('bundled word lists', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('load from the assets, register, and find inflected forms, umlauts and SS', () async {
      final de = await WordListLoader.ensure('de');
      final en = await WordListLoader.ensure('en');
      expect(WordLists.of('de'), same(de));
      // ignore: avoid_print
      print('word list load (test VM, asset → gunzip → index): de ${WordListLoader.lastLoadTime['de']}, '
          'en ${WordListLoader.lastLoadTime['en']}');
      final n = TileSet.german.normalize;
      for (final w in ['Häuser', 'lief', 'gingen', 'schönsten', 'Straße', 'Füße', 'Bäume', 'Öl', 'über']) {
        expect(de.isWord(n(w)), isTrue, reason: w);
      }
      for (final w in ['HAEUSER', 'STRAßE', 'XQZ', 'HÄUSERX']) {
        expect(de.isWord(w), isFalse, reason: w);
      }
      for (final w in ['HOUSES', 'RAN', 'WENT', 'NICEST', 'COLOR', 'COLOUR', 'QI', 'ZA', 'AA']) {
        expect(en.isWord(w), isTrue, reason: w);
      }
      for (final w in ['PARIS', 'NASA', 'KG', 'HÄUSER']) {
        expect(en.isWord(w), isFalse, reason: w);
      }
      expect((de as SortedWordListValidator).length, 590558);
      expect((en as SortedWordListValidator).length, 190787);
      // Every word fits its tile set.
      expect(identical(await WordListLoader.ensure('de'), de), isTrue, reason: 'loaded once');
    });

    // KLD-094 step 6: the list's identity is part of the network fingerprint
    // (WordLists.revisions); a new list must come with a new revision.
    test('the bundled files match the sha256 in WordLists.revisions', () async {
      for (final id in ['de', 'en']) {
        final data = await rootBundle.load(WordListLoader.assetOf(id));
        final hash = [
          for (final b in sha256(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)))
            b.toRadixString(16).padLeft(2, '0'),
        ].join();
        expect(WordLists.revisions[id], endsWith('sha256:$hash'), reason: id);
      }
    });
  });
}
