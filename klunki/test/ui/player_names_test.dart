// KLD-056: player names in the UI. First-run dialog, menu edit, the pairing
// field, hot-seat names, and how the shell shows names (status line, result
// dialog, history, handover cover, bidi).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/player_name_dialog.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n_test_utils.dart';
import 'pairing/pairing_test_utils.dart';
import 'shell/shell_test_utils.dart';

const _fsi = '\u2068';
const _pdi = '\u2069';

Widget _app({PlayerNameController? name, HotSeatNamesController? hotSeat, Locale locale = testLocale}) => KlunkiApp(
      localeController: LocaleController.memory(locale),
      playerNameController: name ?? PlayerNameController.memory(name: 'Anna'),
      hotSeatNames: hotSeat ?? HotSeatNamesController.memory(),
    );

/// The launcher of the pairing tests, inside a [PlayerNameScope].
Widget _scopedLauncher(PairingDeps deps, PlayerNameController name) => PlayerNameScope(
      controller: name,
      hotSeat: HotSeatNamesController.memory(),
      child: launcherApp(deps),
    );

/// A hot-seat game screen with the given labels (network-style when [local]).
Future<GameController> _pumpLabelled(WidgetTester tester, String id, PlayerLabels labels,
    {Locale locale = testLocale, int seed = 1}) async {
  final c = GameController.hotSeat(GameConfig(id, seed: seed));
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(PlayerLabelsScope(labels: labels, child: buildGameScreen(c)), locale: locale));
  await tester.pump();
  return c;
}

String _status(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('shell-status'))).data!;

void main() {
  group('first-run dialog', () {
    testWidgets('appears once on "Raum starten", prefilled with the device name', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final created = CreatedTransports();
      final name = PlayerNameController.memory(suggestion: () => 'unused');
      final deps = testDeps(discovery: FakeDiscovery(), created: created, name: 'Stefans iPhone');
      await tester.pumpWidget(_scopedLauncher(deps, name));

      await tester.tap(find.byKey(const Key('open-pairing')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('player-name-dialog')), findsOneWidget);
      expect(find.text('Wie heißt du?'), findsOneWidget);
      expect(find.byKey(const Key('player-name-cancel')), findsNothing, reason: 'first run: OK only');
      expect(tester.widget<TextField>(find.byKey(const Key('player-name-field'))).controller!.text, 'Stefans iPhone');

      // Empty (after cleaning) cannot be confirmed.
      await tester.enterText(find.byKey(const Key('player-name-field')), ' \u202E ');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('player-name-ok'))).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('player-name-field')), '  Anna ');
      await tester.pump();
      await tester.tap(find.byKey(const Key('player-name-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('player-name-dialog')), findsNothing);
      expect(name.value, 'Anna');
      // The field is "Dein Name", bound to the controller.
      expect(find.text('Dein Name'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('pair-name'))).controller!.text, 'Anna');

      // Second visit: no dialog.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-pairing')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('player-name-dialog')), findsNothing);
      expect(tester.widget<TextField>(find.byKey(const Key('pair-name'))).controller!.text, 'Anna');
      await unmountAndSettleSockets(tester, created);
    });

    testWidgets('a saved name skips the dialog; editing the field saves it', (tester) async {
      final created = CreatedTransports();
      final name = PlayerNameController.memory(name: 'Anna');
      await tester.pumpWidget(_scopedLauncher(testDeps(discovery: FakeDiscovery(), created: created), name));
      await tester.tap(find.byKey(const Key('open-pairing')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('player-name-dialog')), findsNothing);

      await tester.enterText(find.byKey(const Key('pair-name')), 'Ben ');
      await tester.pump();
      expect(name.value, 'Ben');
      await tester.enterText(find.byKey(const Key('pair-name')), '');
      await tester.pump();
      expect(name.value, 'Ben', reason: 'an empty field does not clear the name');
      await unmountAndSettleSockets(tester, created);
    });

    testWidgets('the host advertises and shows the player name', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final created = CreatedTransports();
      final discovery = FakeDiscovery();
      await tester.pumpWidget(_scopedLauncher(
          testDeps(discovery: discovery, created: created), PlayerNameController.memory(name: 'Anna')));
      await tester.tap(find.byKey(const Key('open-pairing')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pair-host-start')));
      await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty,
          what: 'host waiting view');
      expect(find.text('Raum von Anna: 4 Gewinnt'), findsOneWidget);
      expect(discovery.advertised?.name, 'Anna');
      expect(tester.widget<SelectableText>(find.byKey(const Key('pair-link'), skipOffstage: false)).data,
          contains('n=Anna'));
      await unmountAndSettleSockets(tester, created);
    });
  });

  group('menu', () {
    testWidgets('the person button edits the name; cancel keeps it', (tester) async {
      final name = PlayerNameController.memory(name: 'Anna');
      await tester.pumpWidget(_app(name: name));
      await tester.tap(find.byKey(const Key('player-name-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('player-name-dialog')), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('player-name-field'))).controller!.text, 'Anna');

      await tester.enterText(find.byKey(const Key('player-name-field')), 'Bea');
      await tester.tap(find.byKey(const Key('player-name-cancel')));
      await tester.pumpAndSettle();
      expect(name.value, 'Anna');

      await tester.tap(find.byKey(const Key('player-name-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('player-name-field')), 'Bea');
      await tester.tap(find.byKey(const Key('player-name-ok')));
      await tester.pumpAndSettle();
      expect(name.value, 'Bea');
    });

    testWidgets('without a saved name the button suggests the default name (KLD-103)', (tester) async {
      await tester.pumpWidget(_app(name: PlayerNameController.memory(suggestion: () => 'Pixel 7')));
      await tester.tap(find.byKey(const Key('player-name-button')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const Key('player-name-field'))).controller!.text, 'Anna');
    });
  });

  group('room name suggestion (KLD-103)', () {
    for (final (key, expected) in [('open-pairing', 'Anna'), ('open-join', 'Ben')]) {
      testWidgets('$key suggests "$expected"', (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final created = CreatedTransports();
        final name = PlayerNameController.memory(suggestion: () => 'unused');
        final deps = testDeps(discovery: FakeDiscovery(), created: created, name: null);
        await tester.pumpWidget(_scopedLauncher(deps, name));
        // The join screen keeps a progress indicator running: no pumpAndSettle.
        await tester.tap(find.byKey(Key(key)));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(find.byKey(const Key('player-name-dialog')), findsOneWidget);
        expect(tester.widget<TextField>(find.byKey(const Key('player-name-field'))).controller!.text, expected);
        await tester.tap(find.byKey(const Key('player-name-ok')));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(name.value, expected);
        await unmountAndSettleSockets(tester, created);
      });
    }
  });

  group('default names per locale (KLD-103)', () {
    const defaults = {
      'de': ('Anna', 'Ben'),
      'en': ('Anna', 'Ben'),
      'fr': ('Anna', 'Ben'),
      'es': ('Ana', 'Ben'),
      'zh': ('小红', '小明'),
      'ar': ('أمل', 'باسم'),
      'fa': ('آرزو', 'بابک'),
    };
    for (final MapEntry(key: code, value: (a, b)) in defaults.entries) {
      testWidgets('$code: $a / $b in the status line', (tester) async {
        await _pumpLabelled(tester, 'connect4', PlayerLabels.defaults, locale: Locale(code));
        final context = tester.element(find.byType(GameScreen));
        final l10n = AppLocalizations.of(context);
        expect(l10n.playerDefaultNameA, a);
        expect(l10n.playerDefaultNameB, b);
        expect(_status(tester), contains(a));
        expect(_status(tester), isNot(contains('X')));
        await playMove(tester);
        expect(_status(tester), contains(b));
      });
    }
  });

  group('network labels in the shell', () {
    const labels = PlayerLabels(local: Player.a, names: {Player.a: 'Anna', Player.b: 'Ben'});

    testWidgets('status line: "Du bist am Zug" / "Warte auf Ben…"', (tester) async {
      await _pumpLabelled(tester, 'connect4', labels);
      expect(_status(tester), 'Du bist am Zug (X)');
      await playMove(tester);
      expect(_status(tester), 'Warte auf Ben…');
    });

    testWidgets('result dialog: "Du gewinnst!" for the local winner, the name otherwise', (tester) async {
      for (final (local, expectWin) in [(Player.a, true), (Player.b, false)]) {
        final c = await _pumpLabelled(
            tester, 'connect4', PlayerLabels(local: local, names: const {Player.a: 'Anna', Player.b: 'Ben'}));
        await playToEnd(tester);
        final w = c.game.result.winner;
        if (w == null) continue; // a draw: nothing to check
        final mine = w == local;
        final headline = mine ? 'Du gewinnst!' : '${w == Player.a ? 'Anna' : 'Ben'} gewinnt!';
        expect(find.descendant(of: find.byKey(resultDialog), matching: find.text(headline)), findsOneWidget,
            reason: 'local $local, winner $w, expected win $expectWin');
        expect(_status(tester), mine ? 'Du hast gewonnen' : '${w == Player.a ? 'Anna' : 'Ben'} hat gewonnen');
        await tester.tap(find.text('Menü'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('history entries carry the names', (tester) async {
      await _pumpLabelled(tester, 'connect4', labels);
      await playMove(tester);
      await playMove(tester);
      await tester.tap(find.byKey(const Key('shell-history')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Anna: '), findsOneWidget);
      expect(find.textContaining('Ben: '), findsOneWidget);
    });

    testWidgets('an RTL name in the German UI is isolated', (tester) async {
      await _pumpLabelled(tester, 'connect4', const PlayerLabels(local: Player.a, names: {Player.b: 'علی'}));
      await playMove(tester);
      expect(_status(tester), 'Warte auf $_fsiعلی$_pdi…');
    });

    testWidgets('an LTR name in the Arabic UI is isolated', (tester) async {
      await _pumpLabelled(tester, 'connect4', const PlayerLabels(local: Player.b, names: {Player.a: 'Anna'}),
          locale: const Locale('ar'));
      expect(_status(tester), contains('$_fsi' 'Anna$_pdi'));
      expect(_status(tester), startsWith('في انتظار'));
    });

    testWidgets('a Latin name in the German UI stays as typed (no marks)', (tester) async {
      await _pumpLabelled(tester, 'connect4', const PlayerLabels(names: {Player.a: 'Lena'}));
      expect(_status(tester), 'Lena ist am Zug');
      await playMove(tester);
      expect(_status(tester), 'Ben ist am Zug', reason: 'B without a name: the default name');
    });

    testWidgets('two players with the same name are told apart by the mark', (tester) async {
      await _pumpLabelled(tester, 'connect4', const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'anna'}));
      expect(_status(tester), 'Anna (X) ist am Zug');
      await playMove(tester);
      expect(_status(tester), 'anna (O) ist am Zug');
    });
  });

  group('hot-seat names', () {
    testWidgets('"Wer spielt?" opens first, prefilled with Anna / Ben; defaults are not stored', (tester) async {
      final hotSeat = HotSeatNamesController.memory();
      await tester.pumpWidget(_app(hotSeat: hotSeat));
      await tester.tap(find.byKey(const Key('menu-connect4-tile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hot-seat-start-dialog')), findsOneWidget);
      expect(find.text('Wer spielt?'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('hot-seat-name-X'))).controller!.text, 'Anna');
      expect(tester.widget<TextField>(find.byKey(const Key('hot-seat-name-O'))).controller!.text, 'Ben');
      // The player tokens (colour and symbol) sit next to the fields.
      expect(find.descendant(of: find.byKey(const Key('hot-seat-start-dialog')), matching: find.byType(PlayerToken)),
          findsNWidgets(2));
      await tester.tap(find.text('Spielen'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);
      expect(_status(tester), 'Anna ist am Zug');
      expect(hotSeat.value, HotSeatNames.none, reason: 'the default follows the app language');
    });

    testWidgets('cancel in "Wer spielt?" starts nothing', (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.byKey(const Key('menu-connect4-tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hot-seat-names-cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsNothing);
    });

    testWidgets('names typed at the start show in status, history and result; "Nochmal" keeps them',
        (tester) async {
      final hotSeat = HotSeatNamesController.memory();
      await tester.pumpWidget(_app(hotSeat: hotSeat));
      await tester.tap(find.byKey(const Key('menu-connect4-tile')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('hot-seat-name-X')), ' Lena ');
      await tester.enterText(find.byKey(const Key('hot-seat-name-O')), 'Max\u202E');
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
      expect(hotSeat.value, const HotSeatNames(x: 'Lena', o: 'Max'));

      expect(_status(tester), 'Lena ist am Zug');
      await playMove(tester);
      expect(_status(tester), 'Max ist am Zug');
      await tester.tap(find.byKey(const Key('shell-history')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lena: '), findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      await playToEnd(tester);
      final w = controllerOf(tester).game.result.winner;
      if (w != null) {
        expect(find.text('${w == Player.a ? 'Lena' : 'Max'} gewinnt!'), findsOneWidget);
      }
      await tester.tap(find.text('Nochmal'));
      await tester.pumpAndSettle();
      expect(_status(tester), 'Lena ist am Zug');

      // The next game from the menu offers the last pair.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-muehle-tile')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const Key('hot-seat-name-X'))).controller!.text, 'Lena');
      expect(tester.widget<TextField>(find.byKey(const Key('hot-seat-name-O'))).controller!.text, 'Max');
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
      expect(_status(tester), 'Lena ist am Zug');
    });

    testWidgets('typed names are saved in the preferences and come back', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final hotSeat = await HotSeatNamesController.load();
      await tester.pumpWidget(_app(hotSeat: hotSeat));
      await tester.tap(find.byKey(const Key('menu-connect4-tile')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('hot-seat-name-X')), 'Lena');
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(HotSeatNamesController.prefsKeyX), 'Lena');
      expect(prefs.containsKey(HotSeatNamesController.prefsKeyO), isFalse, reason: 'Ben is the default');
      expect((await HotSeatNamesController.load()).value, const HotSeatNames(x: 'Lena'));
    });

    testWidgets('empty names in the game fall back to the default names', (tester) async {
      final hotSeat = HotSeatNamesController.memory(const HotSeatNames(x: 'Lena', o: 'Max'));
      await tester.pumpWidget(_app(hotSeat: hotSeat));
      await tester.tap(find.byKey(const Key('menu-connect4-tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
      expect(_status(tester), 'Lena ist am Zug');
      await tester.tap(find.byKey(const Key('shell-names')));
      await tester.pumpAndSettle();
      expect(find.text('Spielernamen'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('hot-seat-name-X')), '');
      await tester.enterText(find.byKey(const Key('hot-seat-name-O')), '  ');
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
      expect(hotSeat.value, HotSeatNames.none);
      expect(_status(tester), 'Anna ist am Zug');
    });

    testWidgets('Quartett: deck first, then "Wer spielt?"; the handover cover uses the name', (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.byKey(const Key('menu-quartett-trumpf-tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quartett-deck-play'))); // deck picker (KLD-069)
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hot-seat-start-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
      await playUntilHandover(tester);
      expect(find.text('Gib das Gerät an Ben weiter'), findsOneWidget);
      expect(find.text('Ich bin Ben – weiter'), findsOneWidget);
    });

    testWidgets('no names button over the network (or without the app scope)', (tester) async {
      await pumpGame(tester, 'connect4');
      expect(find.byKey(const Key('shell-names')), findsNothing);
    });
  });
}
