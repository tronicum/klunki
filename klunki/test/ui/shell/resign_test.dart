// KLD-065: "Aufgeben" in the shared game shell. Hot-seat (who resigns?),
// cancel, the handover cover, undo, and a network game where the opponent
// sees the resigner's name.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../e2e/e2e_support.dart' show loopback, pingInterval, widgetNetTimeout, until;
import '../../l10n/l10n_test_utils.dart';
import 'shell_test_utils.dart';

const _resign = Key('shell-resign');
const _dialog = Key('resign-dialog');

Finder _inResult(String text) => find.descendant(of: find.byKey(resultDialog), matching: find.text(text));

Future<void> _openResign(WidgetTester tester) async {
  await tester.tap(find.byKey(_resign));
  await tester.pumpAndSettle();
  expect(find.byKey(_dialog), findsOneWidget);
  expect(find.text('Wirklich aufgeben?'), findsOneWidget);
}

void main() {
  group('hot-seat', () {
    for (final id in appGameSpecs.map((s) => s.id)) {
      testWidgets('$id: the flag asks who resigns; O resigns on X\'s turn', (tester) async {
        final c = await pumpGame(tester, id);
        expect(c.game.currentPlayer, Player.a);
        await _openResign(tester);
        expect(find.text('Wer gibt auf? Die Partie endet sofort, die andere Seite gewinnt.'), findsOneWidget);
        expect(find.text('X gibt auf'), findsOneWidget);
        await tester.tap(find.byKey(const Key('resign-b')));
        await tester.pumpAndSettle();

        expect(c.game.isOver, isTrue);
        expect(c.game.result.code, GameEndReason.commonResigned);
        expect(c.moves.single.move, {'action': 'resign', 'player': 'b'});
        expect(c.moves.single.player, Player.b);
        expect(_inResult('X gewinnt!'), findsOneWidget);
        expect(_inResult('O hat aufgegeben'), findsOneWidget);
        await tester.tap(find.text('Menü'));
        await tester.pumpAndSettle();
        expect(find.byKey(_resign), findsNothing, reason: 'no resign once the game is over');
        expect(tester.widget<Text>(find.byKey(const Key('shell-status'))).data, 'X hat gewonnen');
      });
    }

    testWidgets('cancel keeps the game running', (tester) async {
      final c = await pumpGame(tester, 'connect4');
      await playMove(tester);
      await _openResign(tester);
      await tester.tap(find.byKey(const Key('resign-cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(_dialog), findsNothing);
      expect(c.game.isOver, isFalse);
      expect(c.moves, hasLength(1));
      expect(find.byKey(resultDialog), findsNothing);
    });

    testWidgets('names show in the dialog, the result and the history', (tester) async {
      final c = GameController.hotSeat(const GameConfig('muehle'));
      addTearDown(c.dispose);
      await tester.pumpWidget(localizedApp(PlayerLabelsScope(
        labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}),
        child: buildGameScreen(c),
      )));
      await tester.pump();
      await playMove(tester);
      await _openResign(tester);
      expect(find.text('Anna (X) gibt auf'), findsOneWidget);
      expect(find.text('Ben (O) gibt auf'), findsOneWidget);
      await tester.tap(find.text('Anna (X) gibt auf'));
      await tester.pumpAndSettle();
      expect(_inResult('Ben (O) gewinnt!'), findsOneWidget);
      expect(_inResult('Anna (X) hat aufgegeben'), findsOneWidget);
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shell-history')));
      await tester.pumpAndSettle();
      expect(find.text('Anna (X): Aufgeben'), findsOneWidget);
    });

    testWidgets('resigning while the handover cover is up ends the game and drops the cover', (tester) async {
      final c = await pumpGame(tester, 'schiffe');
      await playUntilHandover(tester);
      expect(c.needsHandover, isTrue);
      final waiting = c.game.currentPlayer;
      await _openResign(tester);
      await tester.tap(find.byKey(Key('resign-${waiting.name}')));
      await tester.pumpAndSettle();
      expect(c.game.resignedBy, waiting);
      expect(c.needsHandover, isFalse);
      expect(find.byKey(handoverContinue), findsNothing);
      expect(find.byKey(resultDialog), findsOneWidget);
    });
  });

  test('hot-seat undo takes a resign back', () async {
    final c = GameController.hotSeat(const GameConfig('connect4'));
    addTearDown(c.dispose);
    await c.submit({'col': 3});
    expect(c.canResign, {Player.a, Player.b});
    expect((await c.resign(Player.a)).isAccepted, isTrue);
    expect(c.game.isOver, isTrue);
    expect(c.canResign, isEmpty);
    expect((await c.resign(Player.b)).reason.toString(), 'RejectReason.gameOver');
    expect(c.undo(), isTrue);
    expect(c.game.isOver, isFalse);
    expect(c.game.currentPlayer, Player.b);
    expect(c.moves, hasLength(1));
  });

  testWidgets('network: the guest resigns off turn, the host sees the name', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final (host, guest) = (await tester.runAsync(() async {
      final host = await NetworkTransport.host(const GameConfig('connect4'),
          name: 'Ada', address: loopback, pingInterval: pingInterval, timeout: widgetNetTimeout);
      final guest = await NetworkTransport.join(loopback, host.port!,
          name: 'Bea', pingInterval: pingInterval, timeout: widgetNetTimeout);
      await until(() => host.connection.value == NetConnectionState.connected, what: 'host sees the guest');
      return (host, guest);
    }))!;
    // As in the e2e tests: the controllers live outside the widgets; unmount
    // first, then dispose and close in the real zone (where the sockets are).
    final hostC = GameController(host), guestC = GameController(guest);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        hostC.dispose();
        guestC.dispose();
        await guest.close();
        await host.close();
      });
    });

    const hostKey = Key('device-host'), guestKey = Key('device-guest');
    Widget phone(Key key, NetworkTransport t, GameController c) => Expanded(
        child: KeyedSubtree(
            key: key,
            child: localizedApp(PlayerLabelsScope(labels: networkLabels(t), child: buildGameScreen(c)))));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [phone(hostKey, host, hostC), phone(guestKey, guest, guestC)]),
    ));
    await tester.pump();
    Finder on(Key device, Finder f) => find.descendant(of: find.byKey(device), matching: f);

    // X (the host) is to move; O resigns anyway.
    expect(host.game.currentPlayer, Player.a);
    await tester.tap(on(guestKey, find.byKey(_resign)));
    await tester.pumpAndSettle();
    expect(on(guestKey, find.text('Die Partie endet sofort, Ada (X) gewinnt.')), findsOneWidget);
    expect(on(guestKey, find.byKey(const Key('resign-a'))), findsNothing, reason: 'one local player: no choice');
    await tester.tap(on(guestKey, find.byKey(const Key('resign-confirm'))));
    await tester.runAsync(() => until(() => host.moves.length == 1 && guest.moves.length == 1, what: 'resign travels'));
    await tester.pumpAndSettle();

    for (final t in [host, guest]) {
      expect(t.game.isOver, isTrue);
      expect(t.game.resignedBy, Player.b);
      expect(t.moves.single.player, Player.b);
    }
    Finder result(Key device, String text) =>
        on(device, find.descendant(of: find.byKey(resultDialog), matching: find.text(text)));
    expect(result(hostKey, 'Du gewinnst!'), findsOneWidget);
    expect(result(hostKey, 'Bea (O) hat aufgegeben'), findsOneWidget);
    expect(result(guestKey, 'Ada (X) gewinnt!'), findsOneWidget);
    expect(result(guestKey, 'Du hast aufgegeben'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
