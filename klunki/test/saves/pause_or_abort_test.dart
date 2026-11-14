import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
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

/// KLD-079, maintainer feedback: leaving a running, saved hot-seat game asks
/// "Spiel pausieren" (keep it for "Weiterspielen") or "Spiel abbrechen"
/// (delete it); "Zurück zum Spiel", back or a tap outside stays.
Widget _app(SaveStore store) => KlunkiApp(
      key: UniqueKey(),
      localeController: LocaleController.memory(testLocale),
      hotSeatNames: HotSeatNamesController.memory(),
      savedGames: store,
    );

const _dialog = Key('leave-dialog');
const _pause = Key('leave-pause');
const _abort = Key('leave-abort');
const _stay = Key('leave-cancel');

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// System back (Android back, predictive back; the app bar back does the
/// same through the shell's PopScope).
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

bool get _inGame => find.byWidgetPredicate((w) => w is GameScreen || w is SeatGameScreen).evaluate().isNotEmpty;

/// Opens Four in a Row from the menu and plays [cols].
Future<void> _playConnect4(WidgetTester tester, List<int> cols) async {
  await tester.tap(find.byKey(const Key('menu-connect4-tile')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
  await tester.pumpAndSettle();
  for (final col in cols) {
    await tester.tap(find.byKey(Key('c4-column-$col')));
    await tester.pumpAndSettle();
  }
}

void main() {
  setUp(() => SeenTips.shared
    ..markFirst(SeenTips.wordtilesBench)
    ..markFirst(SeenTips.maumauIntro)
    ..markFirst(SeenTips.dicesheetIntro)
    ..markFirst(SeenTips.propertyIntro));

  testWidgets('the dialog: wording, pause is primary, abort destructive; staying keeps the game', (tester) async {
    final store = await SaveStore.load(prefs: await _prefs({}));
    await tester.pumpWidget(_app(store));
    await _playConnect4(tester, [3, 4, 3]);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    final dialog = find.byKey(_dialog);
    expect(dialog, findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('Spiel verlassen?')), findsOneWidget);
    expect(
        find.descendant(
            of: dialog,
            matching: find.text('Beim Pausieren merkt sich Klunki das Spiel. Später geht es unter „Weiterspielen“ weiter. '
                'Beim Abbrechen ist das Spiel vorbei und wird gelöscht.')),
        findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Spiel pausieren'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Spiel abbrechen'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Zurück zum Spiel'), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('Abbrechen')), findsNothing,
        reason: 'no plain "Abbrechen" next to "Spiel abbrechen"');
    final error = Theme.of(tester.element(dialog)).colorScheme.error;
    final abort = tester.widget<OutlinedButton>(find.byKey(_abort));
    expect(abort.style?.foregroundColor?.resolve({}), error, reason: 'destructive');

    // "Zurück zum Spiel", a tap outside and a second back all stay.
    await tester.tap(find.byKey(_stay));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(_inGame, isTrue);
    await _systemBack(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(_inGame, isTrue);
    await _systemBack(tester);
    expect(dialog, findsOneWidget);
    await _systemBack(tester);
    expect(dialog, findsNothing);
    expect(_inGame, isTrue);
    expect(store.entryFor('connect4')!.game!.moves, hasLength(3));
    // The game goes on.
    await tester.tap(find.byKey(const Key('c4-column-0')));
    await tester.pumpAndSettle();
    expect(store.entryFor('connect4')!.game!.moves, hasLength(4));
  });

  testWidgets('"Spiel pausieren" keeps the game under "Weiterspielen"', (tester) async {
    final prefs = await _prefs({});
    final store = await SaveStore.load(prefs: prefs);
    await tester.pumpWidget(_app(store));
    await _playConnect4(tester, [3, 4, 3]);
    await _systemBack(tester);
    await tester.tap(find.byKey(_pause));
    await tester.pumpAndSettle();
    expect(_inGame, isFalse);
    expect(find.byKey(const Key('menu-saved-games')), findsOneWidget);
    expect(find.text('1 angefangenes Spiel'), findsOneWidget);
    expect((await SaveStore.load(prefs: prefs)).entryFor('connect4')!.game!.moves, hasLength(3));
    await tester.tap(find.byKey(const Key('menu-saved-games')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saved-connect4')), findsOneWidget);
  });

  testWidgets('"Spiel abbrechen" deletes the game: no "Weiterspielen"', (tester) async {
    final prefs = await _prefs({});
    final store = await SaveStore.load(prefs: prefs);
    await tester.pumpWidget(_app(store));
    await _playConnect4(tester, [3, 4, 3]);
    expect(store.entryFor('connect4'), isNotNull);
    await _systemBack(tester);
    await tester.tap(find.byKey(_abort));
    await tester.pumpAndSettle();
    expect(_inGame, isFalse);
    expect(find.byKey(const Key('menu-connect4-tile')), findsOneWidget);
    expect(find.byKey(const Key('menu-saved-games')), findsNothing);
    expect(store.entryFor('connect4'), isNull);
    expect(prefs.getKeys().where((k) => k.startsWith(SaveStore.prefsPrefix)), isEmpty,
        reason: 'not written again when the screen closes');
  });

  testWidgets('no move yet: leaves without asking, an older save stays; one move: asks', (tester) async {
    final old = SavedGame.now(const GameConfig('connect4'), [
      {'col': 1}
    ]);
    final prefs = await _prefs({'${SaveStore.prefsPrefix}connect4': jsonEncode(old.toJson())});
    final store = await SaveStore.load(prefs: prefs);
    await tester.pumpWidget(_app(store));
    await tester.tap(find.byKey(const Key('menu-connect4-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saves-ask-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
    await tester.pumpAndSettle();
    expect(_inGame, isTrue);
    await _systemBack(tester);
    expect(find.byKey(_dialog), findsNothing);
    expect(_inGame, isFalse);
    expect(store.entryFor('connect4')!.game!.moves, old.moves, reason: 'the old game was not replaced');

    // A new game with one move holds the save: back asks.
    await tester.tap(find.byKey(const Key('menu-connect4-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saves-ask-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('c4-column-5')));
    await tester.pumpAndSettle();
    await _systemBack(tester);
    expect(find.byKey(_dialog), findsOneWidget);
    await tester.tap(find.byKey(_abort));
    await tester.pumpAndSettle();
    expect(store.entryFor('connect4'), isNull);
  });

  testWidgets('a finished game leaves without asking', (tester) async {
    final store = await SaveStore.load(prefs: await _prefs({}));
    await tester.pumpWidget(_app(store));
    await _playConnect4(tester, [0, 1, 0, 1, 0, 1, 0]);
    expect(controllerOf(tester).game.isOver, isTrue);
    await tester.tap(find.text('Menü'));
    await tester.pumpAndSettle();
    expect(_inGame, isFalse);
    expect(find.byKey(_dialog), findsNothing);
    expect(store.entryFor('connect4'), isNull);
  });

  testWidgets('seat shell for 3 and 4 players: Baulöwe aborted, Mäxchen paused', (tester) async {
    final values = <String, Object>{};
    for (final config in [
      const GameConfig('property', seed: 5, players: 3),
      const GameConfig('maexchen', seed: 3, players: 4),
    ]) {
      final t = HotSeatTransport(config);
      for (var i = 0; i < 6; i++) {
        t.submitSync(legalMovesOf(t.game).firstWhere((m) => m['action'] != 'resign'));
      }
      expect(t.game.isOver, isFalse);
      values['${SaveStore.prefsPrefix}${config.gameId}'] =
          jsonEncode(SavedGame.now(config, [for (final m in t.moves) m.move]).toJson());
    }
    final prefs = await _prefs(values);
    final store = await SaveStore.load(prefs: prefs);
    await tester.pumpWidget(_app(store));
    for (final (id, choice) in [('property', _abort), ('maexchen', _pause)]) {
      await tester.tap(find.byKey(const Key('menu-saved-games')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('saved-$id')));
      await tester.pumpAndSettle();
      expect(find.byType(SeatGameScreen), findsOneWidget);
      // A resumed game holds its save even before a new move.
      await _systemBack(tester);
      expect(find.byKey(_dialog), findsOneWidget, reason: id);
      expect(find.text('Spiel pausieren'), findsOneWidget);
      await tester.tap(find.byKey(choice));
      await tester.pumpAndSettle();
      expect(_inGame, isFalse);
    }
    expect(store.entryFor('property'), isNull);
    expect(store.entryFor('maexchen'), isNotNull);
    expect(prefs.getString('${SaveStore.prefsPrefix}property'), isNull);
  });

  testWidgets('chess with a clock: back from the pause cover asks too', (tester) async {
    var ms = 0;
    const config = GameConfig('chess', seed: 1, chessClock: ChessTimeControl(300000, 2000));
    final t = HotSeatTransport(config, clockNow: () => ms);
    ms += 3000;
    t.submitSync({'action': 'move', 'from': 'e2', 'to': 'e4'});
    final save = SavedGame.now(config, [for (final m in t.moves) m.move],
        clock: t.clock!.snapshot(ms), clockBefore: t.clockHistory);
    t.dispose();
    final prefs = await _prefs({'${SaveStore.prefsPrefix}chess': jsonEncode(save.toJson())});
    final store = await SaveStore.load(prefs: prefs);
    await tester.pumpWidget(_app(store));
    await tester.tap(find.byKey(const Key('menu-saved-games')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saved-chess')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chess-pause-cover')), findsOneWidget);
    await _systemBack(tester);
    expect(find.byKey(_dialog), findsOneWidget);
    await tester.tap(find.byKey(_stay));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chess-pause-cover')), findsOneWidget, reason: 'still paused');
    await _systemBack(tester);
    await tester.tap(find.byKey(_abort));
    await tester.pumpAndSettle();
    expect(_inGame, isFalse);
    expect(store.entryFor('chess'), isNull);
  });
}
