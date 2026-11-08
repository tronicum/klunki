import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/handover_cover.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import 'shell_test_utils.dart';

/// KLD-117: "Zug zurück" sits in the game area for every game, no longer in
/// the app bar next to the whole-game controls.
void main() {
  // The one-time Bänkchen explanation (Wortgewandt) is seen, so it does not
  // come up over the board.
  setUp(() {
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
  });

  const undo = Key('shell-undo');
  TextButton button(WidgetTester tester) => tester.widget<TextButton>(find.byKey(undo));

  // Games whose board places the button in its own control row, with a
  // control of that row.
  const ownRow = {'chess': Key('chess-flip'), 'wordtiles': Key('wordtiles-bench-toggle')};
  // Games whose board places the button in its own control panel, above
  // the action buttons (Mäxchen, KLD-121 follow-up).
  const ownPanel = {'maexchen': Key('maexchen-controls')};

  for (final id in gameScreens.keys) {
    testWidgets('$id: "Zug zurück" in the game area, not in the app bar', (tester) async {
      final c = await pumpGame(tester, id);
      expect(find.byKey(undo), findsOneWidget);
      expect(find.descendant(of: find.byType(AppBar), matching: find.byKey(undo)), findsNothing);
      expect(find.descendant(of: find.byType(HandoverCover), matching: find.byKey(undo)), findsOneWidget);
      expect(find.text('Zug zurück'), findsOneWidget);
      // The app bar keeps the whole-game controls (the names action needs
      // the app's name store, not here).
      for (final k in ['shell-restart', 'shell-resign', 'shell-history']) {
        expect(
          find.descendant(of: find.byType(AppBar), matching: find.byKey(Key(k))),
          findsOneWidget,
          reason: k,
        );
      }

      final row = ownRow[id];
      final panel = ownPanel[id];
      if (panel != null) {
        expect(find.byKey(const Key('shell-actions')), findsNothing);
        expect(find.descendant(of: find.byKey(panel), matching: find.byKey(undo)), findsOneWidget);
      } else if (row == null) {
        // The shell's row under the board.
        expect(find.descendant(of: find.byKey(const Key('shell-actions')), matching: find.byKey(undo)), findsOneWidget);
      } else {
        expect(find.byKey(const Key('shell-actions')), findsNothing);
        // Same row as the board's own controls.
        expect((tester.getCenter(find.byKey(undo)).dy - tester.getCenter(find.byKey(row)).dy).abs(), lessThan(4));
      }

      expect(button(tester).onPressed, isNull, reason: 'nothing to take back yet');
      await playMove(tester);
      if (find.byKey(handoverContinue).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(handoverContinue));
        await tester.pump();
      }
      expect(c.moves, hasLength(1));
      expect(button(tester).onPressed, isNotNull);
      await tester.ensureVisible(find.byKey(undo)); // the word game's side panel scrolls
      await tester.pump();
      await tester.tap(find.byKey(undo));
      await tester.pump();
      expect(c.moves, isEmpty);
    });
  }

  for (final id in ['quartett-trumpf', 'quartett-sets', 'schiffe', 'gostrategy']) {
    testWidgets('$id: while the device is passed on only the cover offers "Zug zurück"', (tester) async {
      final c = await pumpGame(tester, id);
      await playUntilHandover(tester);
      final moves = c.moves.length;
      final mover = c.moves.last.player;
      // The board's button is covered (offstage, not hit-testable); the
      // cover has its own one.
      expect(find.descendant(of: find.byKey(const Key('handover-cover')), matching: find.byKey(undo)), findsOneWidget);
      expect(find.byKey(undo, skipOffstage: false), findsNWidgets(2));
      expect(find.byKey(const Key('shell-status')).hitTestable(), findsNothing);

      // The player who just moved takes the move back before passing the
      // device: the board stays covered, now for that player.
      await tester.tap(find.byKey(undo));
      await tester.pump();
      expect(c.moves, hasLength(moves - 1));
      expect(c.game.currentPlayer, mover);
      expect(c.needsHandover, isTrue);
      expect(find.byKey(const Key('shell-status')).hitTestable(), findsNothing);
    });
  }

  testWidgets('right to left: the button sits at the start side and its arrow is mirrored', (tester) async {
    await pumpGame(tester, 'connect4', locale: const Locale('ar'));
    final icon = find.descendant(of: find.byKey(undo), matching: find.byType(Icon));
    expect(tester.widget<Icon>(icon).icon!.matchTextDirection, isTrue);
    expect(Directionality.of(tester.element(icon)), TextDirection.rtl);
    // centerEnd in RTL is the left side.
    final screen = tester.getSize(find.byType(GameScreen)).width;
    expect(tester.getCenter(find.byKey(undo)).dx, lessThan(screen / 2));
  });

  testWidgets('nothing to take back after a restart', (tester) async {
    final c = await pumpGame(tester, 'connect4');
    await playMove(tester);
    expect(button(tester).onPressed, isNotNull);
    c.restart(seed: 2);
    await tester.pump();
    expect(button(tester).onPressed, isNull);
    expect(c.game.currentPlayer, Player.a);
  });

  testWidgets('Wortgewandt on a small phone: just the ↶ icon in the actions row (KLD-117)', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = await pumpGame(tester, 'wordtiles');
    final icon = find.byKey(undo);
    expect(tester.widget(icon), isA<IconButton>());
    expect(tester.widget<IconButton>(icon).tooltip, 'Zug zurück');
    expect(find.text('Zug zurück'), findsNothing);
    expect(
      (tester.getCenter(icon).dy - tester.getCenter(find.byKey(const Key('wordtiles-shuffle'))).dy).abs(),
      lessThan(4),
    );
    expect(tester.widget<IconButton>(icon).onPressed, isNull);
    await playMove(tester);
    if (find.byKey(handoverContinue).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(handoverContinue));
      await tester.pump();
    }
    await tester.tap(icon);
    await tester.pump();
    expect(c.moves, isEmpty);
  });
}
