import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki/ui/menu_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import 'shell_test_utils.dart';
import '../../l10n/l10n_test_utils.dart';

void main() {
  // The one-time Bänkchen explanation is seen: where the bench starts open
  // (KLD-094 step 8c) it would come up over the first word tile turn.
  setUp(() => SeenTips.shared.markFirst(SeenTips.wordtilesBench));
  test('every game in appGameSpecs has a screen; the others are hidden from the app', () {
    expect(gameScreens.keys.toSet(), {for (final s in appGameSpecs) s.id, ...previewGames});
    expect(appGameSpecs.map((s) => s.id), contains('gostrategy'), reason: 'KLD-058b');
    for (final s in gameSpecs.where((s) => !s.appReady)) {
      expect(gameScreens.containsKey(s.id), previewGames.contains(s.id), reason: s.id);
    }
    // A preview game is a real engine game that the app does not list yet.
    for (final id in previewGames) {
      expect(specById(id)?.appReady, isFalse, reason: id);
    }
  });

  testWidgets('a game the app cannot show yet gets a placeholder', (tester) async {
    await tester.pumpWidget(localizedApp(const GameNotInAppScreen(gameId: 'future-game')));
    expect(find.text('future-game gibt es in der App noch nicht.'), findsOneWidget);
  });

  group('menu', () {
    testWidgets('lists all games in registry order and opens each', (tester) async {
      await tester.pumpWidget(klunkiApp());
      final tops = [for (final s in appGameSpecs) tester.getTopLeft(find.text(s.title)).dy];
      expect(tops, [...tops]..sort());
      expect(find.text('Debug-Konsole'), findsOneWidget);

      for (final spec in appGameSpecs) {
        await tester.tap(find.text(spec.title));
        await tester.pumpAndSettle();
        if (spec.usesDeck) {
          // Quartett asks for the deck first (KLD-069); the title names it.
          await tester.tap(find.byKey(const Key('quartett-deck-play')));
          await tester.pumpAndSettle();
        }
        if (spec.id == 'wordtiles') {
          // Wortgewandt asks for its start options first (KLD-094); without
          // the word list here (its loading is tested elsewhere).
          await tester.tap(find.byKey(const Key('wordtiles-dict')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('wordtiles-options-next')));
          await tester.pumpAndSettle();
        }
        // "Wer spielt?" (KLD-103), prefilled with the default names.
        await tester.tap(find.text('Spielen'));
        await tester.pumpAndSettle();
        expect(find.byType(GameScreen), findsOneWidget);
        expect(
            find.descendant(
                of: find.byType(AppBar),
                matching: find.text(spec.usesDeck ? '${spec.title} · Autos' : spec.title)),
            findsOneWidget);
        // Chess names the sides (KLD-059).
        expect(find.text(spec.id == 'chess' ? 'Anna (Weiß) ist am Zug' : 'Anna ist am Zug'), findsOneWidget);
        expect(controllerOf(tester).config.gameId, spec.id);

        await tester.tap(find.byType(BackButton)); // pageBack() looks for the English "Back" tooltip
        await tester.pumpAndSettle();
        expect(find.byType(GameScreen), findsNothing);
        expect(find.byType(MenuScreen), findsOneWidget);
      }
    });

    testWidgets('"Menü" in the result dialog returns to the menu', (tester) async {
      await tester.pumpWidget(klunkiApp());
      await tester.tap(find.text('4 Gewinnt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spielen'));
      await tester.pumpAndSettle();
      await playToEnd(tester);
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsNothing);
      expect(find.text('Wähle ein Spiel'), findsOneWidget);
    });
  });

  group('localized result reason (I18N-05)', () {
    for (final (locale, fourInARow, boardFull) in [
      (const Locale('de'), 'Vier in einer Reihe', 'Brett voll'),
      (const Locale('en'), 'Four in a row', 'Board full'),
    ]) {
      testWidgets('Four in a Row result dialog in ${locale.languageCode}', (tester) async {
        final c = await pumpGame(tester, 'connect4', locale: locale);
        await playToEnd(tester);
        final r = c.game.result;
        final expected = r.code == GameEndReason.connect4FourInARow ? fourInARow : boardFull;
        expect(find.descendant(of: find.byKey(resultDialog), matching: find.text(expected)), findsOneWidget);
        expect(find.text(r.reason), findsNothing, reason: 'not the engine text');
      });
    }

    testWidgets('Mühle result dialog with a parameter in en', (tester) async {
      final c = await pumpGame(tester, 'muehle', locale: const Locale('en'));
      await playToEnd(tester);
      final text = localizedResultReason(enL10n, c.game.result);
      expect(find.byKey(const Key('result-reason')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('result-reason'))).data, text);
    });
  });

  group('full games driven through the controller', () {
    testWidgets('Four in a Row ends with the result dialog; "Nochmal" restarts', (tester) async {
      final c = await pumpGame(tester, 'connect4');
      await playToEnd(tester);
      expect(c.game.isOver, isTrue);
      final r = c.game.result;
      final headline = r.winner == null ? 'Unentschieden' : '${testName(r.winner!)} gewinnt!';
      expect(find.text(headline), findsOneWidget);
      expect(find.text(localizedResultReason(deL10n, r)), findsOneWidget);

      final oldSeed = c.config.seed;
      await tester.tap(find.text('Nochmal'));
      await tester.pumpAndSettle();
      expect(find.byKey(resultDialog), findsNothing);
      expect(c.moves, isEmpty);
      expect(c.game.isOver, isFalse);
      expect(find.text('Anna ist am Zug'), findsOneWidget);
      // New game uses a fresh seed (matters for the seeded Quartett games).
      expect(c.config.seed, isNot(oldSeed));
    });

    for (final id in ['quartett-trumpf', 'schiffe']) {
      testWidgets('$id (hidden information) ends with the result dialog', (tester) async {
        final c = await pumpGame(tester, id);
        await playToEnd(tester);
        expect(c.game.isOver, isTrue);
        expect(find.text('Nochmal'), findsOneWidget);
        expect(find.text('Menü'), findsOneWidget);
        expect(find.text(localizedResultReason(deL10n, c.game.result)), findsOneWidget);
      });
    }
  });

  group('handover cover', () {
    for (final id in ['quartett-trumpf', 'quartett-sets', 'schiffe']) {
      testWidgets('$id: cover hides the board until Ben acknowledges', (tester) async {
        final c = await pumpGame(tester, id);
        expect(find.byKey(handoverContinue), findsNothing);

        await playUntilHandover(tester);
        expect(c.needsHandover, isTrue);
        expect(find.text('Gib das Gerät an Ben weiter'), findsOneWidget);
        expect(find.text('Ich bin Ben – weiter'), findsOneWidget);

        // Board area stays mounted but is neither visible nor hit-testable.
        const status = Key('shell-status');
        expect(find.byKey(status), findsNothing);
        expect(find.byKey(status, skipOffstage: false), findsOneWidget);
        expect(find.byKey(status, skipOffstage: false).hitTestable(), findsNothing);

        // Tapping anywhere on the board area hits the cover, not the board.
        final moves = c.moves.length;
        await tester.tapAt(tester.getCenter(find.byKey(const Key('handover-cover'))) + const Offset(0, -120));
        await tester.tapAt(const Offset(40, 140));
        await tester.pump();
        expect(c.moves.length, moves);
        expect(c.needsHandover, isTrue);

        await tester.tap(find.byKey(handoverContinue));
        await tester.pump();
        expect(c.needsHandover, isFalse);
        expect(find.byKey(handoverContinue), findsNothing);
        expect(find.byKey(status).hitTestable(), findsOneWidget);
        expect(find.text('Ben ist am Zug'), findsOneWidget);
      });
    }

    testWidgets('no cover for open-information games', (tester) async {
      final c = await pumpGame(tester, 'connect4');
      await playMove(tester);
      expect(c.game.currentPlayer, Player.b);
      expect(find.byKey(handoverContinue), findsNothing);
      expect(find.text('Ben ist am Zug'), findsOneWidget);
    });
  });

  group('app bar actions', () {
    testWidgets('undo takes back the last move', (tester) async {
      final c = await pumpGame(tester, 'connect4');
      final undo = find.byKey(const Key('shell-undo'));
      expect(tester.widget<IconButton>(undo).onPressed, isNull);

      await playMove(tester);
      expect(c.moves, hasLength(1));
      expect(tester.widget<IconButton>(undo).onPressed, isNotNull);

      await tester.tap(undo);
      await tester.pump();
      expect(c.moves, isEmpty);
      expect(find.text('Anna ist am Zug'), findsOneWidget);
      expect(tester.widget<IconButton>(undo).onPressed, isNull);
    });

    testWidgets('restart asks while a game is running, then starts fresh', (tester) async {
      final c = await pumpGame(tester, 'connect4');
      await playMove(tester);

      await tester.tap(find.byKey(const Key('shell-restart')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(c.moves, hasLength(1));

      await tester.tap(find.byKey(const Key('shell-restart')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neu starten'));
      await tester.pumpAndSettle();
      expect(c.moves, isEmpty);
      expect(find.text('Anna ist am Zug'), findsOneWidget);
    });

    testWidgets('history sheet lists moves readably', (tester) async {
      await pumpGame(tester, 'connect4');
      await tester.tap(find.byKey(const Key('shell-history')));
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Züge.'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10)); // dismiss
      await tester.pumpAndSettle();

      await playMove(tester); // X: column 1
      await playMove(tester, index: 3); // O: column 4

      await tester.tap(find.byKey(const Key('shell-history')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-sheet')), findsOneWidget);
      expect(find.text('Anna: Spalte 1'), findsOneWidget);
      expect(find.text('Ben: Spalte 4'), findsOneWidget);
    });

    testWidgets('history falls back to the move map', (tester) async {
      // A test-only board without describeMove.
      final c = GameController.hotSeat(const GameConfig('connect4', seed: 1));
      addTearDown(c.dispose);
      await tester.pumpWidget(localizedApp(_BareScreen(controller: c)));
      await playMove(tester);
      await tester.tap(find.byKey(const Key('shell-history')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Anna: {col: '), findsOneWidget);
    });
  });

  testWidgets('boards can set the hint line', (tester) async {
    await pumpGame(tester, 'quartett-sets');
    await tester.pump();
    expect(find.byKey(const Key('shell-hint')), findsOneWidget);
    expect(find.text('Tippe auf eine fehlende Karte, um danach zu fragen'), findsOneWidget);
  });
}

/// Minimal screen with no describeMove, for the history fallback test.
class _BareScreen extends StatelessWidget {
  final GameController controller;
  const _BareScreen({required this.controller});

  @override
  Widget build(BuildContext context) =>
      GameScreen(controller: controller, boardBuilder: (_, _) => const SizedBox.shrink());
}
