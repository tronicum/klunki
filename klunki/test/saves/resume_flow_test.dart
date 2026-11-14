import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/saves/save_store.dart';
import 'package:klunki/saves/saved_game.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/legal_move_board.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n_test_utils.dart';
import '../ui/shell/shell_test_utils.dart';

/// KLD-079 through the real UI: play, leave, "restart" the app (a new store
/// over the same preferences), "Weiterspielen", play on.
Widget _app(SaveStore store, {HotSeatNamesController? names}) => KlunkiApp(
      key: UniqueKey(),
      localeController: LocaleController.memory(testLocale),
      hotSeatNames: names ?? HotSeatNamesController.memory(),
      savedGames: store,
    );

String _status(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('shell-status'))).data!;

Future<void> _back(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await tester.pumpAndSettle();
}

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  testWidgets('play Four in a Row, close the app, resume from the menu, play on', (tester) async {
    final prefs = await _prefs({});
    await tester.pumpWidget(_app(await SaveStore.load(prefs: prefs), names: HotSeatNamesController.memory()));
    expect(find.byKey(const Key('menu-saved-games')), findsNothing, reason: 'no card without saves');

    await tester.tap(find.byKey(const Key('menu-connect4-tile')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('hot-seat-name-X')), 'Mia');
    await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
    await tester.pumpAndSettle();
    for (final col in [3, 4, 3]) {
      await tester.tap(find.byKey(Key('c4-column-$col')));
      await tester.pumpAndSettle();
    }
    expect(_status(tester), 'Ben ist am Zug');
    final before = [for (final m in controllerOf(tester).moves) m.move];
    await _back(tester);
    expect(find.byKey(const Key('menu-saved-games')), findsOneWidget);
    expect(find.text('1 angefangenes Spiel'), findsOneWidget);

    // App restart: a fresh store and fresh name stores over the same data.
    await tester.pumpWidget(_app(await SaveStore.load(prefs: prefs)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-saved-games')));
    await tester.pumpAndSettle();
    expect(find.text('Weiterspielen'), findsOneWidget);
    final tile = find.byKey(const Key('saved-connect4'));
    expect(find.descendant(of: tile, matching: find.text('4 Gewinnt')), findsOneWidget);
    expect(find.descendant(of: tile, matching: find.text('Mia · Ben')), findsOneWidget);
    expect(find.descendant(of: tile, matching: find.textContaining('3 Züge')), findsOneWidget);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(_status(tester), 'Ben ist am Zug');
    expect([for (final m in controllerOf(tester).moves) m.move], before);
    await tester.tap(find.byKey(const Key('c4-column-0')));
    await tester.pumpAndSettle();
    expect(_status(tester), 'Mia ist am Zug', reason: 'the saved name is back');
    expect((await SaveStore.load(prefs: prefs)).entryFor('connect4')!.game!.moves, hasLength(4));

    // Back leads to the menu (the list was replaced by the game).
    await _back(tester);
    expect(find.byKey(const Key('menu-connect4-tile')), findsOneWidget);
  });

  testWidgets('a finished game deletes its save; undo to the start too', (tester) async {
    final prefs = await _prefs({});
    final store = await SaveStore.load(prefs: prefs);
    await tester.pumpWidget(_app(store));
    await tester.tap(find.byKey(const Key('menu-connect4-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spielen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('c4-column-0')));
    await tester.pumpAndSettle();
    expect(store.entryFor('connect4'), isNotNull);
    controllerOf(tester).undo();
    await tester.pumpAndSettle();
    expect(store.entryFor('connect4'), isNull, reason: 'back at the start: nothing to resume');
    for (final col in [0, 1, 0, 1, 0, 1]) {
      await tester.tap(find.byKey(Key('c4-column-$col')));
      await tester.pumpAndSettle();
    }
    expect(store.entryFor('connect4'), isNotNull);
    await tester.tap(find.byKey(const Key('c4-column-0'))); // four in a row
    await tester.pumpAndSettle();
    expect(store.entryFor('connect4'), isNull);
    expect(prefs.getKeys().where((k) => k.startsWith(SaveStore.prefsPrefix)), isEmpty);
  });

  testWidgets('a hidden-information game resumes behind the handover cover', (tester) async {
    const config = GameConfig('maumau', seed: 7);
    final t = HotSeatTransport(config);
    for (var i = 0; i < 3; i++) {
      t.submitSync(legalMovesOf(t.game).first);
    }
    final save = SavedGame.now(config, [for (final m in t.moves) m.move], names: ['Mia', 'Leo']);
    final prefs = await _prefs({'${SaveStore.prefsPrefix}maumau': jsonEncode(save.toJson())});
    await tester.pumpWidget(_app(await SaveStore.load(prefs: prefs)));
    await tester.tap(find.byKey(const Key('menu-saved-games')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saved-maumau')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('handover-cover')), findsOneWidget);
    final next = t.game.currentPlayer == Player.a ? 'Mia' : 'Leo';
    expect(find.text('Gib das Gerät an $next weiter'), findsOneWidget);
    await tester.tap(find.byKey(const Key('handover-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('handover-cover')), findsNothing);
  });

  testWidgets('Baulöwe for 3 resumes in the seat shell with its names; Wortgewandt for 3 behind the cover',
      (tester) async {
    final prefs = <String, Object>{};
    final logs = <String, List<Map<String, dynamic>>>{};
    for (final (config, n) in [
      (const GameConfig('property', seed: 5, players: 3), 20),
      (const GameConfig('wordtiles', seed: 9, players: 3), 3),
    ]) {
      final t = HotSeatTransport(config);
      for (var i = 0; i < n; i++) {
        t.submitSync(legalMovesOf(t.game).firstWhere((m) => m['action'] != 'resign'));
      }
      logs[config.gameId] = [for (final m in t.moves) m.move];
      prefs['${SaveStore.prefsPrefix}${config.gameId}'] =
          jsonEncode(SavedGame.now(config, logs[config.gameId]!, names: ['Mia', null, 'Ole']).toJson());
    }
    final p = await _prefs(prefs);
    for (final id in ['property', 'wordtiles']) {
      final names = HotSeatNamesController.memory();
      await tester.pumpWidget(_app(await SaveStore.load(prefs: p), names: names));
      await tester.tap(find.byKey(const Key('menu-saved-games')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byKey(Key('saved-$id')), matching: find.text('Mia · Ben · Ole')), findsOneWidget);
      await tester.tap(find.byKey(Key('saved-$id')));
      await tester.pumpAndSettle();
      expect(find.byType(SeatGameScreen), findsOneWidget);
      expect([for (final m in controllerOf(tester).moves) m.move], logs[id]);
      expect(names.value, const HotSeatNames(x: 'Mia'));
      expect(find.byKey(const Key('handover-cover')), id == 'wordtiles' ? findsOneWidget : findsNothing);
      await _back(tester);
    }
  });

  testWidgets('the app going to the background saves the chess clock', (tester) async {
    final prefs = await _prefs({});
    final store = await SaveStore.load(prefs: prefs);
    await tester.pumpWidget(_app(store));
    await tester.tap(find.byKey(const Key('menu-chess-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spielen'));
    await tester.pumpAndSettle();
    await controllerOf(tester).submit({'action': 'move', 'from': 'e2', 'to': 'e4'});
    await tester.pumpAndSettle();
    final first = store.entryFor('chess')!.game!;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final second = store.entryFor('chess')!.game!;
    expect(second.moves, first.moves);
    expect(identical(first, second), isFalse, reason: 'written again on pause');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  });

  testWidgets('an outdated save cannot be resumed and can be deleted', (tester) async {
    final save = SavedGame.now(const GameConfig('muehle'), [
      {'action': 'place', 'to': 0}
    ]);
    final prefs = await _prefs({
      '${SaveStore.prefsPrefix}muehle': jsonEncode({...save.toJson(), 'rulesVersion': 99}),
    });
    await tester.pumpWidget(_app(await SaveStore.load(prefs: prefs)));
    await tester.tap(find.byKey(const Key('menu-saved-games')));
    await tester.pumpAndSettle();
    expect(find.text('Kann nicht fortgesetzt werden'), findsOneWidget);
    await tester.tap(find.byKey(const Key('saved-muehle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saves-cannot-resume')), findsOneWidget);
    await tester.tap(find.byKey(const Key('saves-cannot-resume-delete')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saves-empty')), findsOneWidget);
    expect(prefs.getString('${SaveStore.prefsPrefix}muehle'), isNull);
  });

  testWidgets('delete asks first', (tester) async {
    final save = SavedGame.now(const GameConfig('connect4'), [
      {'col': 3}
    ]);
    final prefs = await _prefs({'${SaveStore.prefsPrefix}connect4': jsonEncode(save.toJson())});
    await tester.pumpWidget(_app(await SaveStore.load(prefs: prefs)));
    await tester.tap(find.byKey(const Key('menu-saved-games')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saved-connect4-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Spiel löschen?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saved-connect4')), findsOneWidget);
    await tester.tap(find.byKey(const Key('saved-connect4-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saves-delete-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saves-empty')), findsOneWidget);
    await _back(tester);
    expect(find.byKey(const Key('menu-saved-games')), findsNothing);
  });
}
