// KLD-094 step 5: performance checks for Wortgewandt on a phone-sized
// screen (375 × 667).
//
// * The dictionary load at game start: the "Wörterbuch wird geladen …"
//   dialog opens and closes again, and the UI isolate stays responsive while
//   the German list (590 558 words) is decompressed and indexed (that runs
//   in a background isolate): the longest gap between 4 ms timer ticks on
//   the UI isolate is measured.
// * A board with 50+ tiles: laying and recalling tiles rebuilds the board;
//   the time per frame (build, layout, paint; the test VM, debug mode, no
//   GPU) is measured.
//
// The numbers are printed; the asserts are generous (CI machines vary), they
// only catch a regression by an order of magnitude.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/games/wordtiles/word_list_loader.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_options.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';

class _Routes extends NavigatorObserver {
  final List<String> log = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => log.add('push ${route.runtimeType}');
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => log.add('pop ${route.runtimeType}');
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 667) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  tearDown(WordListLoader.reset);

  testWidgets('phone: the dictionary load dialog opens and closes; the UI isolate stays responsive', (tester) async {
    _phone(tester);
    final routes = _Routes();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: (localizedApp(const SizedBox()) as MaterialApp).localizationsDelegates,
      supportedLocales: (localizedApp(const SizedBox()) as MaterialApp).supportedLocales,
      locale: const Locale('de'),
      navigatorObservers: [routes],
      home: const Scaffold(body: SizedBox.expand()),
    ));
    final context = tester.element(find.byType(Scaffold));
    var maxGap = Duration.zero;
    var ticks = 0;
    late bool ok;
    final total = Stopwatch()..start();
    await tester.runAsync(() async {
      final gap = Stopwatch()..start();
      final timer = Timer.periodic(const Duration(milliseconds: 4), (_) {
        if (gap.elapsed > maxGap) maxGap = gap.elapsed;
        gap.reset();
        ticks++;
      });
      ok = await loadWordListWithProgress(context, 'de');
      timer.cancel();
    });
    total.stop();
    await tester.pumpAndSettle();
    expect(ok, isTrue);
    expect(WordLists.has('de'), isTrue);
    expect(routes.log.where((e) => e.startsWith('push DialogRoute')), hasLength(1), reason: '${routes.log}');
    expect(routes.log.where((e) => e.startsWith('pop DialogRoute')), hasLength(1), reason: '${routes.log}');
    expect(find.byKey(const Key('wordtiles-dict-loading')), findsNothing);
    // ignore: avoid_print
    print('dictionary load (de, test VM): total ${total.elapsedMilliseconds} ms, loader '
        '${WordListLoader.lastLoadTime['de']?.inMilliseconds} ms; UI isolate: $ticks ticks, '
        'longest gap ${maxGap.inMilliseconds} ms');
    expect(maxGap, lessThan(const Duration(milliseconds: 250)));
    // A second game: no dialog, no load.
    routes.log.clear();
    late bool again;
    await tester.runAsync(() async => again = await loadWordListWithProgress(context, 'de'));
    expect(again, isTrue);
    expect(routes.log, isEmpty);
  });

  testWidgets('phone: a board with 50+ tiles stays fast while laying and recalling', (tester) async {
    _phone(tester);
    const words = ['BAUMHAUS', 'STERNEN', 'WORTSPIEL', 'KLEINER', 'GARTEN', 'FENSTER', 'REGEN', 'TISCH'];
    final board = <(int, int), BoardTile>{};
    for (final (i, w) in words.indexed) {
      for (var k = 0; k < w.length; k++) {
        board[(1 + i * 2 - (i > 3 ? 1 : 0), 1 + k + (i % 2) * 3)] = BoardTile(w[k], blank: k == 3 && i == 2);
      }
    }
    expect(board.length, greaterThanOrEqualTo(50));
    final c = GameController.hotSeat(const GameConfig('wordtiles', seed: 1));
    addTearDown(c.dispose);
    (c.game as WordTilesGame).debugSetup(
      racks: const [
        ['E', 'N', 'D', 'E', 'R', 'S', 'T'],
        ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      ],
      bag: List.filled(40, 'E'),
      board: board,
    );
    await tester.pumpWidget(localizedApp(buildGameScreen(c)));
    await tester.pumpAndSettle();
    final frames = <int>[];
    Future<void> frame() async {
      final sw = Stopwatch()..start();
      await tester.pump();
      frames.add(sw.elapsedMicroseconds);
    }

    // Free squares in row 14 (bottom row, nothing laid there).
    for (var round = 0; round < 5; round++) {
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(Key('wordtiles-rack-$i')));
        await frame();
        await tester.tap(find.byKey(Key('wordtiles-sq-14-${3 + i}')), warnIfMissed: false);
        await frame();
        await tester.pump(const Duration(milliseconds: 400)); // zoom animation
        await frame();
      }
      await tester.tap(find.byKey(const Key('wordtiles-recall')));
      await frame();
      await tester.pumpAndSettle();
    }
    frames.sort();
    final avg = frames.reduce((a, b) => a + b) / frames.length / 1000;
    final p90 = frames[(frames.length * 0.9).floor()] / 1000;
    final worst = frames.last / 1000;
    // ignore: avoid_print
    print('board with ${board.length} tiles, ${frames.length} frames (test VM, debug, no GPU): '
        'avg ${avg.toStringAsFixed(1)} ms, p90 ${p90.toStringAsFixed(1)} ms, worst ${worst.toStringAsFixed(1)} ms');
    expect(avg, lessThan(60));
  });
}
