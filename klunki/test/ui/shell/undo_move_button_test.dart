import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/handover_cover.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import 'shell_test_utils.dart';

/// KLD-117: "Zug zurücknehmen" sits in the game area for every game, no longer in
/// the app bar next to the whole-game controls.
void main() {
  // The one-time Bänkchen explanation (Wortgewandt) is seen, so it does not
  // come up over the board.
  setUp(() {
    UndoSettings.debugReset();
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
    SeenTips.shared.markFirst(SeenTips.maumauIntro);
    SeenTips.shared.markFirst(SeenTips.dicesheetIntro);
  });

  const undo = Key('shell-undo');
  // The label, or just the ↶ icon where a row is full (e.g. Ausgewürfelt
  // with the "Tipp" button on a phone).
  ({VoidCallback? onPressed}) button(WidgetTester tester) => switch (tester.widget(find.byKey(undo))) {
        TextButton b => (onPressed: b.onPressed),
        IconButton b => (onPressed: b.onPressed),
        final w => throw StateError('unexpected $w'),
      };

  // Games whose board places the button in its own control row, with a
  // control of that row.
  const ownRow = {'chess': Key('chess-flip'), 'wordtiles': Key('wordtiles-bench-toggle')};
  // Games whose board places the button in its own control panel, above
  // the action buttons (Mäxchen, KLD-121 follow-up).
  const ownPanel = {'maexchen': Key('maexchen-controls'), 'dicesheet': Key('dicesheet-controls')};

  for (final id in gameScreens.keys) {
    testWidgets('$id: "Zug zurücknehmen" in the game area, not in the app bar', (tester) async {
      final c = await pumpGame(tester, id);
      expect(find.byKey(undo), findsOneWidget);
      expect(find.descendant(of: find.byType(AppBar), matching: find.byKey(undo)), findsNothing);
      // The seat shell (KLD-119) has no handover cover: no secrets.
      expect(find.descendant(of: find.byType(HandoverCover), matching: find.byKey(undo)),
          seatGames.contains(id) ? findsNothing : findsOneWidget);
      // The label, or where a row is full just the ↶ icon with the label as
      // its tooltip (both carry it as the tooltip).
      expect(find.byTooltip('Zug zurücknehmen'), findsOneWidget);
      // The app bar keeps the whole-game controls; "Neues Spiel" (and the
      // names) in its "⋮" menu.
      for (final k in ['shell-menu', 'shell-resign', 'shell-history', 'shell-rules']) {
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
      var left = 0;
      if (id == 'dicesheet') {
        // KLD-119: a roll is final (the dice were seen); filling a box can
        // be taken back.
        expect(button(tester).onPressed, isNull);
        await c.submit(DiceSheetGame.scoreMove((c.game as DiceSheetGame).allowedBoxes.first));
        await tester.pump();
        left = 1;
      }
      expect(button(tester).onPressed, isNotNull);
      await tester.ensureVisible(find.byKey(undo)); // the word game's side panel scrolls
      await tester.pump();
      await tester.tap(find.byKey(undo));
      await tester.pump();
      expect(c.moves, hasLength(left));
    });
  }

  for (final id in ['quartett-trumpf', 'quartett-sets', 'schiffe', 'gostrategy']) {
    testWidgets('$id: while the device is passed on only the cover offers "Zug zurücknehmen"', (tester) async {
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
    expect(tester.widget<IconButton>(icon).tooltip, 'Zug zurücknehmen');
    expect(find.text('Zug zurücknehmen'), findsNothing);
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

  group('"Zug zurücknehmen erlauben" (KLD-117 follow-up)', () {
    testWidgets('on by default; off hides the button in the game and on the cover, for that game only', (tester) async {
      expect(UndoSettings.shared().allowed('schiffe'), isTrue);
      final c = await pumpGame(tester, 'schiffe');
      expect(find.byKey(undo), findsOneWidget);
      await UndoSettings.shared().setAllowed('schiffe', false);
      await tester.pump();
      expect(find.byKey(undo, skipOffstage: false), findsNothing);
      await playUntilHandover(tester);
      expect(find.byKey(undo, skipOffstage: false), findsNothing, reason: 'not on the handover cover either');
      expect(c.moves, isNotEmpty);
      expect(UndoSettings.shared().allowed('connect4'), isTrue, reason: 'one setting per game');
      // On again: back at once.
      await UndoSettings.shared().setAllowed('schiffe', true);
      await tester.pump();
      expect(find.byKey(undo, skipOffstage: false), findsWidgets);
    });

    testWidgets('"Wer spielt?" has the switch (for both players), stored with OK', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(KlunkiApp(
        localeController: LocaleController.memory(testLocale),
        playerNameController: PlayerNameController.memory(name: 'Anna'),
        hotSeatNames: HotSeatNamesController.memory(),
      ));
      await tester.ensureVisible(find.byKey(const Key('menu-connect4-local')));
      await tester.tap(find.byKey(const Key('menu-connect4-local')));
      await tester.pumpAndSettle();
      final sw = find.byKey(const Key('hot-seat-undo'));
      expect(tester.widget<SwitchListTile>(sw).value, isTrue);
      expect(find.text('Zug zurücknehmen erlauben'), findsOneWidget);
      await tester.tap(sw);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
      expect(UndoSettings.shared().allowed('connect4'), isFalse);
      expect(find.byKey(undo), findsNothing);
      await playMove(tester);
      expect(find.byKey(undo), findsNothing);
    });

    test('stored per game and read back; a choice before loading wins', () async {
      SharedPreferences.setMockInitialValues({'${UndoSettings.prefsPrefix}muehle': false});
      UndoSettings.debugReset(loaded: true);
      await UndoSettings.shared().setAllowed('chess', false);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(UndoSettings.shared().allowed('muehle'), isFalse);
      expect(UndoSettings.shared().allowed('chess'), isFalse);
      expect(UndoSettings.shared().allowed('connect4'), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${UndoSettings.prefsPrefix}chess'), isFalse);
      UndoSettings.debugReset(loaded: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(UndoSettings.shared().allowed('chess'), isFalse);
    });
  });
}
