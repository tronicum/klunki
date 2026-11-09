// KLD-125: Wortgewandt for 3–4 players on one device. The seat shell with
// the handover cover between every two players (racks are secret), the
// score row with four seats on a small phone (right to left too), "Trotzdem
// zulassen" agreed by the table (logged as the next player's answer), the
// ranking with the rack deduction, the start from the menu with the player
// count, and two players staying on the two-player screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/ui/games/wordtiles/word_list_loader.dart';
import 'package:klunki/ui/games/wordtiles_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _key(String k) => find.byKey(Key(k));
Finder _sq(int r, int c) => _key('wordtiles-sq-$r-$c');
Finder _rack(int i) => _key('wordtiles-rack-$i');

WordTilesGame _game(GameController c) => c.game as WordTilesGame;

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await _pump(tester);
}

String _text(WidgetTester tester, Finder f) => tester.widget<Text>(f).data!;

const _racks = [
  ['H', 'A', 'U', 'S', 'E', 'N', '?'],
  ['T', 'O', 'R', 'E', 'N', 'D', 'I'],
  ['L', 'A', 'M', 'P', 'E', 'R', 'S'],
  ['B', 'R', 'O', 'T', 'E', 'I', 'N'],
];

Future<GameController> _start(WidgetTester tester,
    {int players = 4,
    Size size = const Size(1180, 820),
    Locale locale = testLocale,
    bool dictionary = false,
    int bag = 40}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(GameConfig('wordtiles', seed: 1, players: players, dictionary: dictionary));
  addTearDown(c.dispose);
  _game(c).debugSetup(racks: _racks.take(players).toList(), bag: List.filled(bag, 'E'));
  await tester.pumpWidget(localizedApp(buildGameScreen(c), locale: locale));
  await _pump(tester);
  return c;
}

Future<void> _pass(WidgetTester tester) async {
  await _tap(tester, _key('wordtiles-pass'));
  await _tap(tester, _key('wordtiles-pass-confirm'));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
    ExtraSeatNames.debugReset();
    UndoSettings.debugReset();
  });

  testWidgets('4 players: the seat shell, a cover before every player naming the next one', (tester) async {
    final c = await _start(tester);
    expect(find.byType(SeatGameScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    // Seat 0 lays HAUS over the centre.
    for (final (i, col) in [(0, 7), (1, 8), (2, 9), (3, 10)]) {
      await _tap(tester, _rack(i));
      await _tap(tester, _sq(7, col));
    }
    await _tap(tester, _key('wordtiles-play'));
    // Every seat in turn gets the cover with its name, its token and the
    // last turn; the rack stays hidden until "Weiter".
    final names = ['Ben', 'Cleo', 'Dani', 'Anna'];
    for (final (n, name) in names.indexed) {
      final seat = (n + 1) % 4;
      expect(find.byKey(handoverContinue), findsOneWidget, reason: name);
      expect(find.text('Gib das Gerät an $name weiter'), findsOneWidget);
      expect(tester.widget<SeatToken>(_key('handover-seat')).seat, seat);
      expect(_rack(0).hitTestable(), findsNothing, reason: 'the rack is covered');
      expect(_key('wordtiles-cover-turn'), findsOneWidget);
      if (n == 0) expect(_text(tester, _key('wordtiles-cover-turn')), 'Anna: HAUS für 8 Punkte');
      if (n > 0) expect(_text(tester, _key('wordtiles-cover-turn')), '${names[n - 1]}: gepasst');
      await _tap(tester, find.byKey(handoverContinue));
      expect(find.text('$name ist am Zug'), findsOneWidget);
      expect(_game(c).currentSeat, seat);
      // The rack on screen is the seat's own (Anna's changed after HAUS).
      if (seat != 0) expect(find.descendant(of: _rack(0), matching: find.text(_racks[seat][0])), findsWidgets);
      if (n < 3) await _pass(tester);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Zug zurücknehmen" on the cover takes the move back', (tester) async {
    final c = await _start(tester, players: 3);
    await _pass(tester);
    expect(find.text('Gib das Gerät an Ben weiter'), findsOneWidget);
    await _tap(tester, _key('shell-undo'));
    await tester.pumpAndSettle();
    expect(c.moves, isEmpty);
    // The turn went back to Anna: her cover (Ben may have seen nothing).
    expect(find.text('Gib das Gerät an Anna weiter'), findsOneWidget);
    await _tap(tester, find.byKey(handoverContinue));
    expect(find.text('Anna ist am Zug'), findsOneWidget);
  });

  for (final (name, size, locale) in [
    ('iPhone SE', const Size(375, 667), testLocale),
    ('320 px', const Size(320, 568), testLocale),
    ('iPhone SE, Arabic', const Size(375, 667), const Locale('ar')),
  ]) {
    testWidgets('$name: four seats in one score row, nothing overflows', (tester) async {
      final c = await _start(tester, size: size, locale: locale);
      final rows = [for (var s = 0; s < 4; s++) tester.getRect(_key('wordtiles-score-$s'))];
      for (var s = 1; s < 4; s++) {
        expect(rows[s].center.dy, closeTo(rows[0].center.dy, 1), reason: 'one line');
      }
      for (final r in rows) {
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(size.width));
      }
      // Each seat has its token (colour and number) and score.
      for (var s = 0; s < 4; s++) {
        expect(find.descendant(of: _key('wordtiles-score-$s'), matching: find.byType(SeatToken)), findsOneWidget);
      }
      // A turn later the next seat's rack is shown, still no overflow.
      await _pass(tester);
      await _tap(tester, find.byKey(handoverContinue));
      expect(_game(c).currentSeat, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scoreless end with 3 players: the ranking with rack deductions, the reason without a score',
      (tester) async {
    final c = await _start(tester, players: 3);
    // 6 scoreless turns end a 3-player game (defaultScorelessLimit).
    for (var i = 0; i < 6; i++) {
      await _pass(tester);
      if (i < 5) await _tap(tester, find.byKey(handoverContinue));
    }
    await tester.pumpAndSettle();
    final g = _game(c);
    expect(g.isOver, isTrue);
    // Anna 6 (H A U S E N ?), Ben 8 (T O R E N D I), Cleo 11 (L A M P E R S).
    expect(g.scores, [-6, -8, -11]);
    expect(find.byKey(resultDialog), findsOneWidget);
    expect(find.text('Anna gewinnt!'), findsOneWidget);
    expect(_text(tester, _key('result-reason')), '6 Züge ohne Punkte');
    for (final (s, pen) in [(0, 6), (1, 8), (2, 11)]) {
      expect(_text(tester, _key('result-rank-note-$s')), 'Reststeine: −$pen');
    }
    // In ranking order.
    expect(tester.getTopLeft(_key('result-rank-0')).dy, lessThan(tester.getTopLeft(_key('result-rank-1')).dy));
    expect(tester.getTopLeft(_key('result-rank-1')).dy, lessThan(tester.getTopLeft(_key('result-rank-2')).dy));
    // The summary under it has no second score list.
    expect(_key('wordtiles-result-score-0'), findsNothing);
    // "Nochmal" keeps the player count.
    await tester.tap(find.byKey(const Key('result-again')));
    await tester.pumpAndSettle();
    expect(c.moves, isEmpty);
    expect(_game(c).playerCount, 3);
  });

  testWidgets('3 players: two resign one after the other, the last one in wins', (tester) async {
    final c = await _start(tester, players: 3);
    // Anna resigns, then Ben: Cleo is left and wins.
    await c.resignSeat(0);
    await tester.pumpAndSettle();
    if (find.byKey(handoverContinue).evaluate().isNotEmpty) await _tap(tester, find.byKey(handoverContinue));
    await c.resignSeat(1);
    await tester.pumpAndSettle();
    expect(find.text('Cleo gewinnt!'), findsOneWidget);
    expect(find.text('aufgegeben'), findsNWidgets(2));
  });

  testWidgets('dictionary, 3 players: "Trotzdem zulassen" is agreed by the table, logged as the next player',
      (tester) async {
    await tester.runAsync(() => WordListLoader.ensure('de'));
    addTearDown(WordListLoader.reset);
    final c = await _start(tester, players: 3, dictionary: true);
    // "HSA" is no German word.
    for (final (i, col) in [(0, 7), (3, 8), (1, 9)]) {
      await _tap(tester, _rack(i));
      await _tap(tester, _sq(7, col));
    }
    await _tap(tester, _key('wordtiles-play'));
    await tester.pumpAndSettle();
    expect(_key('wordtiles-unknown'), findsOneWidget);
    expect(find.text('Ihr könnt die Steine zurücknehmen. Seid ihr euch einig, dass es trotzdem zählt, lasst es zu.'),
        findsOneWidget);
    await _tap(tester, _key('wordtiles-unknown-allow'));
    await tester.pumpAndSettle();
    final g = _game(c);
    expect([for (final m in c.moves) (m.move['action'], m.seat)],
        [(WordTilesGame.requestAllow, 0), (WordTilesGame.acceptAllow, 1)]);
    expect(g.turns.single.allowed, ['HSA']);
    expect(g.currentSeat, 1);
    expect(find.text('Gib das Gerät an Ben weiter'), findsOneWidget);
    expect(_key('wordtiles-allow-dialog'), findsNothing, reason: 'no second question in hot-seat');
  });

  for (final (n, seat) in [(4, true), (2, false)]) {
    testWidgets('menu: "Wer spielt?" with the count, "Zug zurücknehmen erlauben" and the pass-the-device hint; '
        '$n players open the ${seat ? 'seat shell' : 'two-player screen'}', (tester) async {
      await tester.pumpWidget(klunkiApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('menu-wordtiles-tile'));
      await tester.tap(_key('menu-wordtiles-tile'));
      await tester.pumpAndSettle();
      await tester.tap(_key('wordtiles-dict'));
      await tester.pumpAndSettle();
      await tester.tap(_key('wordtiles-options-next'));
      await tester.pumpAndSettle();
      expect(_key('hot-seat-start-dialog'), findsOneWidget);
      expect(_key('hot-seat-undo'), findsOneWidget);
      expect(_key('hot-seat-pass-device-hint'), findsOneWidget);
      await tester.tap(_key('seat-players-$n'));
      await tester.pumpAndSettle();
      expect(_key('seat-name-${n - 1}'), findsOneWidget);
      await tester.tap(_key('hot-seat-names-ok'));
      await tester.pumpAndSettle();
      expect(find.byType(WordTilesScreen), findsOneWidget);
      expect(_game(controllerOf(tester)).playerCount, n);
      expect(find.byType(SeatGameScreen), seat ? findsOneWidget : findsNothing);
      expect(find.byType(GameScreen), seat ? findsNothing : findsOneWidget);
      if (n == 4) {
        expect(find.descendant(of: _key('wordtiles-score-3'), matching: find.byType(SeatToken)), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  test('the fingerprint and the 2-player config do not change with the player count offered', () {
    // GameConfig writes `players` only when not 2: a 2-player network game
    // is the same config as before (KLD-125 changed no engine behaviour).
    expect(const GameConfig('wordtiles', seed: 3).toJson().containsKey('players'), isFalse);
    expect(const GameConfig('wordtiles', seed: 3, players: 4).toJson()['players'], 4);
  });
}
