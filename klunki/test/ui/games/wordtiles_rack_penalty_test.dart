// KLD-094 step 10: "Restpunkte abziehen" as an option (on by default): the
// switch in the start options, the game it starts, the rules page and the
// options line of a network game.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_options.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

WordTilesGame _game(GameController c) => c.game as WordTilesGame;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
  });

  testWidgets('start options: on by default; off starts a game without the deduction', (tester) async {
    tester.view.physicalSize = const Size(1180, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(klunkiApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('menu-wordtiles-tile')));
    await tester.tap(find.byKey(const Key('menu-wordtiles-tile')));
    await tester.pumpAndSettle();
    final rest = find.byKey(const Key('wordtiles-rest'));
    expect(tester.widget<SwitchListTile>(rest).value, isTrue);
    expect(find.text('Restpunkte abziehen'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('wordtiles-rest-explain'))).data, startsWith('Regelvariante'));
    // The word list off, so no list has to load.
    await tester.tap(find.byKey(const Key('wordtiles-dict')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(rest);
    await tester.tap(rest);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(rest).value, isFalse);
    await tester.tap(find.byKey(const Key('wordtiles-options-next')));
    await tester.pumpAndSettle();
    if (find.byKey(const Key('hot-seat-names-ok')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
    }
    final c = controllerOf(tester);
    expect(c.config.rackPenalty, isFalse);
    expect(_game(c).rackPenalty, isFalse);
  });

  for (final rest in [true, false]) {
    testWidgets('rules page with the option ${rest ? 'on' : 'off'}', (tester) async {
      tester.view.physicalSize = const Size(1180, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = GameController.hotSeat(GameConfig('wordtiles', seed: 1, rackPenalty: rest));
      addTearDown(c.dispose);
      await tester.pumpWidget(localizedApp(buildGameScreen(c)));
      await tester.pump();
      await tester.tap(find.byKey(const Key('shell-rules')));
      await tester.pumpAndSettle();
      // The usual rule is no variant; playing without it is.
      final house = find.byKey(const Key('rules-house-rest'));
      if (rest) {
        expect(house, findsNothing);
        expect(find.text(deL10n.wordtilesHelpEnd), findsOneWidget);
        expect(find.text(deL10n.rulesWordtilesScoreless), findsOneWidget);
      } else {
        expect(find.descendant(of: house, matching: find.text(deL10n.rulesWordtilesNoRest)), findsOneWidget);
        expect(find.text(deL10n.wordtilesHelpEndNoRest), findsOneWidget);
        expect(find.text(deL10n.wordtilesHelpEnd), findsNothing);
        expect(find.text(deL10n.rulesWordtilesScoreless), findsNothing);
      }
    });
  }

  test('the options line of a network game says when it is off', () {
    const on = GameConfig('wordtiles', tiles: 'de');
    const off = GameConfig('wordtiles', tiles: 'de', rackPenalty: false, jokerSwap: true);
    expect(wordTilesOptionsSummary(deL10n, on), isNot(contains('Restpunkte')));
    expect(wordTilesOptionsSummary(deL10n, off), 'Deutsch · ohne Wörterbuch · Joker tauschen · ohne Restpunkte');
  });
}
