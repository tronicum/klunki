// GoStrategy over the network (KLD-058b): host (X) and guest (O) as two
// NetworkGameSessions side by side, real NetworkTransports on 127.0.0.1
// (ephemeral ports). Both set up through the editor, play by taps, see the
// fight reveal, never a handover cover, and only their own view: the guest's
// board is turned (own army at the bottom) and shows X's pieces as backs.
//
// The screen renders from `viewFor(me)` plus the fight payload only; the
// guest holds a `GoStrategyView` and redacted events (protocol v2, KLD-064).
@Timeout(Duration(seconds: 90))
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/gostrategy/gostrategy_board.dart';
import 'package:klunki/ui/games/gostrategy/gostrategy_pieces.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_net/klunki_net.dart' show Verification;

import '../../l10n/l10n_test_utils.dart';

const _hostKey = Key('device-host');
const _guestKey = Key('device-guest');
const _ping = Duration(milliseconds: 100);
const _timeout = Duration(seconds: 2);

Finder _on(Key device, Finder f) => find.descendant(of: find.byKey(device), matching: f);
Finder _cell(Key device, int sq) => _on(device, find.byKey(Key('go-cell-$sq')));

GameController _controller(WidgetTester tester, Key device) =>
    tester.widget<GameScreen>(_on(device, find.byType(GameScreen))).controller;

GoSquareView _square(WidgetTester tester, Key device, int sq) => tester.widget<GoSquareView>(_cell(device, sq));

/// Pumps (fake time) and waits a little real time until [condition] holds.
Future<void> _until(WidgetTester tester, bool Function() condition, String what) async {
  // Counted rounds, not a Stopwatch: about 20 s of real waiting at most
  // (more under the load of the full suite).
  for (var round = 0;; round++) {
    await tester.pump();
    if (condition()) {
      await tester.pump(); // post-frame hint
      return;
    }
    if (round > 2000) fail('condition not met: $what');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('host vs guest: setups, a move by taps, the fight reveal on both, private views', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (host, guest) = (await tester.runAsync(() async {
      final h = await NetworkTransport.host(const GameConfig('gostrategy', seed: 11),
          name: 'Anna', address: InternetAddress.loopbackIPv4, wsPort: null, pingInterval: _ping, timeout: _timeout);
      final g = await NetworkTransport.join(InternetAddress.loopbackIPv4, h.port!,
          name: 'Ben', pingInterval: _ping, timeout: _timeout);
      return (h, g);
    }))!;
    addTearDown(() async {
      // Unmounting disposes both controllers and transports (bye); give the
      // sockets a moment to close for real (as in pairing_test_utils).
      await tester.pumpWidget(const SizedBox());
      guest.dispose();
      host.dispose();
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();
      }
    });

    Widget device(Key key, NetworkTransport t) => Expanded(
          child: KeyedSubtree(key: key, child: localizedApp(NetworkGameSession(transport: t))),
        );
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [device(_hostKey, host), device(_guestKey, guest)]),
    ));
    await _until(tester, () => _on(_guestKey, find.text('Stelle deine Armee auf (O)')).evaluate().isNotEmpty,
        'guest shows its setup editor');

    // Both see their own editor at once. X sets up first; the guest may
    // arrange meanwhile but "Fertig" waits.
    expect(_on(_hostKey, find.text('Stelle deine Armee auf (X)')), findsOneWidget);
    expect(_on(_guestKey, find.text('Anna (X) stellt zuerst auf – du kannst schon vorbereiten.')), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(_on(_guestKey, find.byKey(const Key('go-done')))).onPressed, isNull);
    await _tap(tester, _on(_guestKey, find.byKey(const Key('go-shuffle'))));

    await _tap(tester, _on(_hostKey, find.byKey(const Key('go-done'))));
    await _until(tester, () => _controller(tester, _guestKey).moves.length == 1, 'guest receives X setup');
    expect(_on(_hostKey, find.text('Warte, bis Ben (O) aufgestellt hat …')), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(_on(_guestKey, find.byKey(const Key('go-done')))).onPressed, isNotNull);
    await _tap(tester, _on(_guestKey, find.byKey(const Key('go-done'))));
    await _until(tester, () => _controller(tester, _hostKey).moves.length == 2, 'host receives O setup');

    for (final d in [_hostKey, _guestKey]) {
      expect(_on(d, find.byKey(const Key('handover-cover'), skipOffstage: false)), findsNothing);
    }
    expect(_on(_hostKey, find.text('Du bist am Zug (X)')), findsOneWidget);
    expect(_on(_guestKey, find.text('Warte auf Anna (X)…')), findsOneWidget);

    // Orientation: each device has its own army at the bottom.
    expect(tester.getCenter(_cell(_hostKey, 99)).dy, greaterThan(tester.getCenter(_cell(_hostKey, 0)).dy));
    expect(tester.getCenter(_cell(_guestKey, 0)).dy, greaterThan(tester.getCenter(_cell(_guestKey, 99)).dy));

    void expectPrivate(Key d, Player me) {
      final g = _controller(tester, d).game as GoStrategyGame;
      for (var sq = 0; sq < 100; sq++) {
        final v = _square(tester, d, sq);
        expect(v.cell, g.viewFor(me)[sq], reason: 'square $sq on $d');
        if (v.cell.owner != null && v.cell.owner != me && !v.cell.revealed) expect(v.cell.piece, isNull);
      }
    }

    expectPrivate(_hostKey, Player.a);
    expectPrivate(_guestKey, Player.b);
    // The guest cannot select anything while X moves.
    await _tap(tester, _cell(_guestKey, 39));
    expect(_square(tester, _guestKey, 39).selected, isFalse);

    // X moves by taps; the guest's board follows.
    final hostGame = _controller(tester, _hostKey).game as GoStrategyGame;
    final first = hostGame.legalMoves.firstWhere((m) => hostGame.board[m['to'] as int].isEmpty);
    await _tap(tester, _cell(_hostKey, first['from'] as int));
    expect(_square(tester, _hostKey, first['to'] as int).target, isTrue);
    await _tap(tester, _cell(_hostKey, first['to'] as int));
    await _until(tester, () => _controller(tester, _guestKey).moves.length == 3, 'guest receives the move');
    expect(_square(tester, _guestKey, first['to'] as int).cell.moved, isTrue);
    expect(_square(tester, _guestKey, first['to'] as int).lastMove, isTrue);
    expectPrivate(_guestKey, Player.b);

    // Quiet moves through the controllers until someone can attack, then
    // the attack by taps: both devices show the reveal.
    for (var i = 0; i < 400; i++) {
      final mover = _controller(tester, _hostKey).canAct ? _hostKey : _guestKey;
      final c = _controller(tester, mover);
      final g = c.game as GoStrategyGame;
      final legal = g.legalMoves;
      final attack = legal.where((m) => g.board[m['to'] as int].owner != null).firstOrNull;
      if (attack != null) {
        final count = c.moves.length;
        await _tap(tester, _cell(mover, attack['from'] as int));
        expect(_square(tester, mover, attack['from'] as int).selected, isTrue, reason: 'select $attack');
        expect(_square(tester, mover, attack['to'] as int).target, isTrue, reason: 'target $attack');
        await _tap(tester, _cell(mover, attack['to'] as int));
        await _until(
            tester,
            () =>
                _controller(tester, _hostKey).moves.length == count + 1 &&
                _controller(tester, _guestKey).moves.length == count + 1,
            'attack on both');
        final fight = GoFight.fromMove(_controller(tester, _guestKey).moves.last)!;
        final text = goFightText(deL10n, fight);
        for (final d in [_hostKey, _guestKey]) {
          expect(_on(d, find.byKey(const Key('go-reveal'))), findsOneWidget, reason: '$d shows the reveal');
          expect(_on(d, find.text(text)), findsWidgets);
          expect(_on(d, find.byKey(const Key('handover-cover'), skipOffstage: false)), findsNothing);
        }
        expect(_on(_hostKey, find.text('Angriff von ${mover == _hostKey ? 'Anna (X)' : 'Ben (O)'}')), findsOneWidget);
        break;
      }
      final count = c.moves.length;
      // Not awaited: a guest's submit completes over the real socket, which
      // only runs between the _until rounds below.
      unawaited(c.submit(legal[(i * 7) % legal.length]));
      await _until(
          tester,
          () =>
              _controller(tester, _hostKey).moves.length == count + 1 &&
              _controller(tester, _guestKey).moves.length == count + 1,
          'move $i on both');
      expect(g.isOver, isFalse, reason: 'no fight before the end');
    }
    await tester.pump(goRevealDuration + const Duration(milliseconds: 500));
    await tester.pump();
    expectPrivate(_hostKey, Player.a);
    expectPrivate(_guestKey, Player.b);
    // Protocol v2 (KLD-064): the guest holds only its own view, and the
    // host's setup reaches it redacted; every later move is public.
    final hostC = _controller(tester, _hostKey), guestC = _controller(tester, _guestKey);
    expect(guestC.transport.fullInformation, isFalse);
    expect(guestC.game, isA<GoStrategyView>());
    final hostMoves = hostC.moves.map((m) => m.move).toList();
    final guestMoves = guestC.moves.map((m) => m.move).toList();
    expect(guestMoves.first, {'action': 'setup'});
    expect(hostMoves.first['pieces'], isNotNull);
    expect(guestMoves.skip(1).toList(), hostMoves.skip(1).toList());
    // The redacted event still carries the public fight (both ranks), the
    // same as on the host, and so does the view's lastFight.
    final hostFight = GoFight.fromMove(hostC.moves.last)!, guestFight = GoFight.fromMove(guestC.moves.last)!;
    expect(
        [guestFight.attackerPlayer, guestFight.attacker, guestFight.defender, guestFight.outcome, guestFight.from, guestFight.to],
        [hostFight.attackerPlayer, hostFight.attacker, hostFight.defender, hostFight.outcome, hostFight.from, hostFight.to]);
    expect(jsonSafe((guestC.game as GoStrategyGame).lastFight), jsonSafe(hostGame.lastFight));
    // The guest's view (moved / revealed flags included) is exactly what the
    // host's engine says O may know, and that is what its board shows.
    final guestView = (guestC.game as GoStrategyGame).viewFor(Player.b);
    for (var sq = 0; sq < 100; sq++) {
      expect(guestView[sq], hostGame.viewFor(Player.b)[sq], reason: 'square $sq');
      expect(_square(tester, _guestKey, sq).cell, guestView[sq], reason: 'square $sq');
    }
  });

  // KLD-065 with KLD-064: a resign during the setup (the host, before its
  // army is placed) and mid-game (the guest, off turn). The guest holds a
  // GoStrategyView; both devices end with the result, and the host's reveal
  // verifies the game on the guest.
  for (final midGame in [false, true]) {
    testWidgets(midGame ? 'resign mid-game: the guest gives up on X\'s turn' : 'resign during the setup: the host gives up',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (host, guest) = (await tester.runAsync(() async {
        final h = await NetworkTransport.host(const GameConfig('gostrategy', seed: 4),
            name: 'Anna', address: InternetAddress.loopbackIPv4, wsPort: null, pingInterval: _ping, timeout: _timeout);
        final g = await NetworkTransport.join(InternetAddress.loopbackIPv4, h.port!,
            name: 'Ben', pingInterval: _ping, timeout: _timeout);
        return (h, g);
      }))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        guest.dispose();
        host.dispose();
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump();
        }
      });
      Widget device(Key key, NetworkTransport t) => Expanded(
            child: KeyedSubtree(key: key, child: localizedApp(NetworkGameSession(transport: t))),
          );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [device(_hostKey, host), device(_guestKey, guest)]),
      ));
      await _until(tester, () => _on(_guestKey, find.text('Stelle deine Armee auf (O)')).evaluate().isNotEmpty,
          'guest shows its setup editor');
      expect(_controller(tester, _guestKey).game, isA<GoStrategyView>());

      var count = 0;
      if (midGame) {
        await _tap(tester, _on(_hostKey, find.byKey(const Key('go-done'))));
        await _until(tester, () => _controller(tester, _guestKey).moves.length == 1, 'guest receives X setup');
        await _tap(tester, _on(_guestKey, find.byKey(const Key('go-done'))));
        await _until(tester, () => _controller(tester, _hostKey).moves.length == 2, 'host receives O setup');
        final hostC = _controller(tester, _hostKey);
        final g = hostC.game as GoStrategyGame;
        unawaited(hostC.submit(g.legalMoves.firstWhere((m) => g.board[m['to'] as int].isEmpty)));
        await _until(tester, () => _controller(tester, _guestKey).moves.length == 3, 'guest receives X move');
        // O moves, then X is to move again: O resigns off turn.
        final guestC = _controller(tester, _guestKey);
        // Not awaited: the reply arrives over the real socket (see _until).
        unawaited(guestC.submit((guestC.game as GoStrategyGame).legalMoves.first));
        await _until(tester, () => _controller(tester, _hostKey).moves.length == 4, 'host receives O move');
        count = 4;
      }
      final (resigner, other) = midGame ? (_guestKey, _hostKey) : (_hostKey, _guestKey);
      final (resignerName, otherName) = midGame ? ('Ben (O)', 'Anna (X)') : ('Anna (X)', 'Ben (O)');
      final loser = midGame ? Player.b : Player.a;
      expect(_controller(tester, _hostKey).game.currentPlayer, Player.a);

      await tester.tap(_on(resigner, find.byKey(const Key('shell-resign'))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_on(resigner, find.text('Die Partie endet sofort, $otherName gewinnt.')), findsOneWidget);
      await tester.tap(_on(resigner, find.byKey(const Key('resign-confirm'))));
      await _until(
          tester,
          () =>
              _controller(tester, _hostKey).moves.length == count + 1 &&
              _controller(tester, _guestKey).moves.length == count + 1 &&
              guest.verification.value == Verification.verified,
          'resign on both, game verified');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      for (final d in [_hostKey, _guestKey]) {
        final c = _controller(tester, d);
        expect(c.game.isOver, isTrue);
        expect(c.game.resignedBy, loser);
        expect(c.moves.last.move, {'action': 'resign', 'player': loser.name});
        expect(_on(d, find.byKey(const Key('handover-cover'), skipOffstage: false)), findsNothing);
        expect(_on(d, find.text('Spielverlauf konnte nicht bestätigt werden')), findsNothing);
        // The setup editor is gone; nothing of the other army is shown.
        expect(_on(d, find.byKey(const Key('go-done'))), findsNothing);
      }
      Finder result(Key d, String text) =>
          _on(d, find.descendant(of: find.byKey(const Key('result-dialog')), matching: find.text(text)));
      expect(result(other, 'Du gewinnst!'), findsOneWidget);
      expect(result(other, '$resignerName hat aufgegeben'), findsOneWidget);
      expect(result(resigner, '$otherName gewinnt!'), findsOneWidget);
      expect(result(resigner, 'Du hast aufgegeben'), findsOneWidget);
      if (midGame) {
        // The guest's board still shows only O's view.
        final g = _controller(tester, _guestKey).game as GoStrategyGame;
        for (var sq = 0; sq < 100; sq++) {
          final v = _square(tester, _guestKey, sq);
          expect(v.cell, g.viewFor(Player.b)[sq]);
          if (v.cell.owner == Player.a && !v.cell.revealed) expect(v.cell.piece, isNull);
        }
      }
    });
  }
}
