// KLD-056: player names in the UI. First-run dialog, menu edit, the pairing
// field, hot-seat names, and how the shell shows names (status line, result
// dialog, history, handover cover, bidi).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/player_name_dialog.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

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

    testWidgets('without a saved name the button suggests the device name', (tester) async {
      await tester.pumpWidget(_app(name: PlayerNameController.memory(suggestion: () => 'Pixel 7')));
      await tester.tap(find.byKey(const Key('player-name-button')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const Key('player-name-field'))).controller!.text, 'Pixel 7');
    });
  });

  group('network labels in the shell', () {
    const labels = PlayerLabels(local: Player.a, names: {Player.a: 'Anna', Player.b: 'Ben'});

    testWidgets('status line: "Du bist am Zug" / "Warte auf Ben (O)…"', (tester) async {
      await _pumpLabelled(tester, 'connect4', labels);
      expect(_status(tester), 'Du bist am Zug (X)');
      await playMove(tester);
      expect(_status(tester), 'Warte auf Ben (O)…');
    });

    testWidgets('result dialog: "Du gewinnst!" for the local winner, the name otherwise', (tester) async {
      // Find a seed where X wins and one where O wins by playing first moves.
      for (final (local, expectWin) in [(Player.a, true), (Player.b, false)]) {
        final c = await _pumpLabelled(
            tester, 'connect4', PlayerLabels(local: local, names: const {Player.a: 'Anna', Player.b: 'Ben'}));
        await playToEnd(tester);
        final w = c.game.result.winner;
        if (w == null) continue; // a draw: nothing to check
        final mine = w == local;
        final headline = mine ? 'Du gewinnst!' : '${w == Player.a ? 'Anna (X)' : 'Ben (O)'} gewinnt!';
        expect(find.descendant(of: find.byKey(resultDialog), matching: find.text(headline)), findsOneWidget,
            reason: 'local $local, winner $w, expected win $expectWin');
        expect(_status(tester), mine ? 'Du hast gewonnen' : '${w == Player.a ? 'Anna (X)' : 'Ben (O)'} hat gewonnen');
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
      expect(find.textContaining('Anna (X): '), findsOneWidget);
      expect(find.textContaining('Ben (O): '), findsOneWidget);
    });

    testWidgets('an RTL name in the German UI is isolated', (tester) async {
      await _pumpLabelled(tester, 'connect4', const PlayerLabels(local: Player.a, names: {Player.b: 'علی'}));
      await playMove(tester);
      expect(_status(tester), 'Warte auf $_fsiعلی$_pdi (O)…');
    });

    testWidgets('an LTR name in the Arabic UI is isolated', (tester) async {
      await _pumpLabelled(tester, 'connect4', const PlayerLabels(local: Player.b, names: {Player.a: 'Anna'}),
          locale: const Locale('ar'));
      expect(_status(tester), contains('$_fsi' 'Anna$_pdi (X)'));
      expect(_status(tester), startsWith('في انتظار'));
    });

    testWidgets('a Latin name in the German UI stays as typed (no marks)', (tester) async {
      await _pumpLabelled(tester, 'connect4', const PlayerLabels(names: {Player.a: 'Anna'}));
      expect(_status(tester), 'Anna (X) ist am Zug');
    });
  });

  group('hot-seat names', () {
    testWidgets('without names the game shows X/O and starts with one tap', (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.byKey(const Key('menu-connect4')));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);
      expect(_status(tester), 'X ist am Zug');
    });

    testWidgets('names entered in the game show in status, history and result; "Nochmal" keeps them',
        (tester) async {
      final hotSeat = HotSeatNamesController.memory();
      await tester.pumpWidget(_app(hotSeat: hotSeat, name: PlayerNameController.memory(name: 'Anna')));
      await tester.tap(find.byKey(const Key('menu-connect4')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shell-names')));
      await tester.pumpAndSettle();
      expect(find.text('Spielernamen'), findsOneWidget);
      // X is prefilled with the player name, O is empty.
      expect(tester.widget<TextField>(find.byKey(const Key('hot-seat-name-X'))).controller!.text, 'Anna');
      expect(tester.widget<TextField>(find.byKey(const Key('hot-seat-name-O'))).controller!.text, '');
      await tester.enterText(find.byKey(const Key('hot-seat-name-O')), ' Ben\u202E ');
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
      expect(hotSeat.value, const HotSeatNames(x: 'Anna', o: 'Ben'));

      expect(_status(tester), 'Anna (X) ist am Zug');
      await playMove(tester);
      expect(_status(tester), 'Ben (O) ist am Zug');
      await tester.tap(find.byKey(const Key('shell-history')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Anna (X): '), findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      await playToEnd(tester);
      final w = controllerOf(tester).game.result.winner;
      if (w != null) {
        expect(find.text('${w == Player.a ? 'Anna (X)' : 'Ben (O)'} gewinnt!'), findsOneWidget);
      }
      await tester.tap(find.text('Nochmal'));
      await tester.pumpAndSettle();
      expect(_status(tester), 'Anna (X) ist am Zug');

      // The next game from the menu starts with the last pair.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-muehle')));
      await tester.pumpAndSettle();
      expect(_status(tester), 'Anna (X) ist am Zug');
    });

    testWidgets('empty names fall back to X/O', (tester) async {
      final hotSeat = HotSeatNamesController.memory(const HotSeatNames(x: 'Anna', o: 'Ben'));
      await tester.pumpWidget(_app(hotSeat: hotSeat));
      await tester.tap(find.byKey(const Key('menu-connect4')));
      await tester.pumpAndSettle();
      expect(_status(tester), 'Anna (X) ist am Zug');
      await tester.tap(find.byKey(const Key('shell-names')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('hot-seat-name-X')), '');
      await tester.enterText(find.byKey(const Key('hot-seat-name-O')), '  ');
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
      expect(hotSeat.value, HotSeatNames.none);
      expect(_status(tester), 'X ist am Zug');
    });

    testWidgets('the handover cover uses the name', (tester) async {
      final hotSeat = HotSeatNamesController.memory(const HotSeatNames(x: 'Anna', o: 'Ben'));
      await tester.pumpWidget(_app(hotSeat: hotSeat));
      await tester.tap(find.byKey(const Key('menu-quartett-trumpf')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quartett-deck-play'))); // deck picker (KLD-069)
      await tester.pumpAndSettle();
      await playUntilHandover(tester);
      expect(find.text('Gib das Gerät an Ben (O) weiter'), findsOneWidget);
      expect(find.text('Ich bin Ben (O) – weiter'), findsOneWidget);
    });

    testWidgets('no names button over the network (or without the app scope)', (tester) async {
      await pumpGame(tester, 'connect4');
      expect(find.byKey(const Key('shell-names')), findsNothing);
    });
  });
}
