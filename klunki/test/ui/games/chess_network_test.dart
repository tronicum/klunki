// Chess over the network (KLD-059 step 3): host (White) and guest (Black)
// as two NetworkGameSessions side by side, real NetworkTransports on
// 127.0.0.1. Each device shows its own side at the bottom (the guest's board
// is turned, coordinates included), names the players ("Du bist am Zug",
// "Warte auf Anna (Weiß)…"), has no undo, restart or auto-turn, and plays
// by taps; the draw offer goes from one device to the other.
@Timeout(Duration(seconds: 90))
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/chess/chess_board.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import '../../support/test_run.dart';

const _hostKey = Key('device-host');
const _guestKey = Key('device-guest');
const _ping = Duration(milliseconds: 100);
const _timeout = Duration(seconds: 30);

Finder _on(Key device, Finder f) => find.descendant(of: find.byKey(device), matching: f);
Finder _sq(Key device, String s) => _on(device, find.byKey(Key('chess-sq-$s')));

GameController _controller(WidgetTester tester, Key device) =>
    tester.widget<GameScreen>(_on(device, find.byType(GameScreen))).controller;

String _text(WidgetTester tester, Key device, Key k) => tester.widget<Text>(_on(device, find.byKey(k))).data!;

/// Pumps (fake time) and waits a little real time until [condition] holds.
Future<void> _until(WidgetTester tester, bool Function() condition, String what) async {
  final alive = testRunGuard(tester); // KLD-109: stop once the test has ended
  for (var round = 0;; round++) {
    alive();
    await tester.pump();
    if (condition()) {
      await tester.pump(); // post-frame: hint, dialogs
      await tester.pump();
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

/// Lets dialog animations finish without a pumpAndSettle (the keepalive
/// timers never settle).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Starts host and guest and pumps both sessions side by side.
Future<(NetworkTransport, NetworkTransport)> _start(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (host, guest) = (await tester.runAsync(() async {
    final h = await NetworkTransport.host(const GameConfig('chess'),
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
  await _until(tester, () => _on(_guestKey, find.byType(ChessBoard)).evaluate().isNotEmpty, 'guest board');
  await _until(tester, () => _on(_hostKey, find.byType(ChessBoard)).evaluate().isNotEmpty, 'host board');
  return (host, guest);
}

/// [device] moves [from]→[to] by two taps; waits until both devices have it.
Future<void> _move(WidgetTester tester, Key device, String from, String to) async {
  final n = _controller(tester, _hostKey).moves.length;
  await _tap(tester, _sq(device, from));
  expect(tester.widget<ChessSquareView>(_sq(device, from)).selected, isTrue, reason: '$from selected on $device');
  await _tap(tester, _sq(device, to));
  await _until(
      tester,
      () => _controller(tester, _hostKey).moves.length == n + 1 && _controller(tester, _guestKey).moves.length == n + 1,
      '$from-$to on both devices');
}

void main() {
  testWidgets('host White at the bottom, guest Black turned; names, no undo; fool\'s mate by taps', (tester) async {
    await _start(tester);

    // Orientation: own side at the bottom, coordinates turned with the board.
    expect(_text(tester, _hostKey, const Key('chess-rank-0')), '8');
    expect(_text(tester, _hostKey, const Key('chess-file-0')), 'a');
    expect(_text(tester, _guestKey, const Key('chess-rank-0')), '1');
    expect(_text(tester, _guestKey, const Key('chess-file-0')), 'h');
    for (final (device, bottomLeft, topRight) in [(_hostKey, 'a1', 'h8'), (_guestKey, 'h8', 'a1')]) {
      final bl = tester.getCenter(_sq(device, bottomLeft)), tr = tester.getCenter(_sq(device, topRight));
      expect(bl.dx, lessThan(tr.dx), reason: '$device: $bottomLeft left of $topRight');
      expect(bl.dy, greaterThan(tr.dy), reason: '$device: $bottomLeft below $topRight');
    }
    // Names instead of marks (KLD-106): own turn / waiting for the other.
    expect(_text(tester, _hostKey, const Key('shell-status')), 'Du bist am Zug');
    expect(_text(tester, _guestKey, const Key('shell-status')), 'Warte auf Anna (Weiß)…');
    // No undo, restart or auto-turn on a network device; flip and draw offer stay.
    for (final d in [_hostKey, _guestKey]) {
      expect(_on(d, find.byKey(const Key('shell-undo'))), findsNothing);
      expect(_on(d, find.byKey(const Key('shell-restart'))), findsNothing);
      expect(_on(d, find.byKey(const Key('chess-auto-flip'))), findsNothing);
      expect(_on(d, find.byKey(const Key('chess-flip'))), findsOneWidget);
      expect(_on(d, find.byKey(const Key('chess-offer-draw'))), findsOneWidget);
    }
    // The guest cannot pick up a piece on the host's turn.
    await _tap(tester, _sq(_guestKey, 'e7'));
    expect(tester.widget<ChessSquareView>(_sq(_guestKey, 'e7')).selected, isFalse);

    await _move(tester, _hostKey, 'f2', 'f3');
    expect(_text(tester, _guestKey, const Key('shell-status')), 'Du bist am Zug');
    expect(_text(tester, _hostKey, const Key('shell-status')), 'Warte auf Ben (Schwarz)…');
    expect(tester.widget<ChessSquareView>(_sq(_guestKey, 'f3')).lastMove, isTrue);
    await _move(tester, _guestKey, 'e7', 'e5');
    await _move(tester, _hostKey, 'g2', 'g4');
    await _move(tester, _guestKey, 'd8', 'h4');
    final hc = _controller(tester, _hostKey), gc = _controller(tester, _guestKey);
    expect((gc.game as ChessGame).fen, (hc.game as ChessGame).fen);
    expect((hc.game as ChessGame).sanHistory, ['f3', 'e5', 'g4', 'Qh4#']);
    await _settle(tester);
    final hostResult = _on(_hostKey, find.byKey(const Key('result-dialog')));
    final guestResult = _on(_guestKey, find.byKey(const Key('result-dialog')));
    expect(find.descendant(of: hostResult, matching: find.text('Ben (Schwarz) gewinnt!')), findsOneWidget);
    expect(find.descendant(of: guestResult, matching: find.text('Du gewinnst!')), findsOneWidget);
    for (final r in [hostResult, guestResult]) {
      expect(find.descendant(of: r, matching: find.text('Schachmatt')), findsOneWidget);
    }
  });

  testWidgets('draw offer between the devices: declined, then offered by the guest and accepted', (tester) async {
    await _start(tester);
    final hc = _controller(tester, _hostKey);
    await _move(tester, _hostKey, 'e2', 'e4');
    // Off turn the button is off.
    expect(tester.widget<IconButton>(_on(_hostKey, find.byKey(const Key('chess-offer-draw')))).onPressed, isNull);
    await _move(tester, _guestKey, 'e7', 'e5');

    // The host offers on its turn.
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-offer-draw'))));
    await _settle(tester);
    expect(_on(_hostKey, find.text('Ben (Schwarz) kann annehmen oder ablehnen. Bei Annahme endet das Spiel unentschieden.')),
        findsOneWidget);
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-offer-confirm'))));
    await _until(tester, () => _on(_guestKey, find.byKey(const Key('chess-draw-offer-dialog'))).evaluate().isNotEmpty,
        'the offer reaches the guest');
    await _settle(tester);
    expect(_on(_guestKey, find.text('Anna (Weiß) bietet ein Remis an. Bei Annahme endet das Spiel unentschieden.')),
        findsOneWidget);
    expect(_text(tester, _hostKey, const Key('shell-hint')), 'Remis angeboten – Ben (Schwarz) entscheidet.');
    expect(tester.widget<IconButton>(_on(_hostKey, find.byKey(const Key('chess-offer-draw')))).onPressed, isNull);
    // The host's pieces wait for the answer.
    await _tap(tester, _sq(_hostKey, 'g1'));
    expect(tester.widget<ChessSquareView>(_sq(_hostKey, 'g1')).selected, isFalse);

    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-draw-decline'))));
    await _until(tester, () => hc.moves.length == 4, 'the decline reaches the host');
    await _settle(tester);
    expect(_on(_guestKey, find.byKey(const Key('chess-draw-offer-dialog'))), findsNothing);
    expect(_text(tester, _hostKey, const Key('shell-hint')), 'Ben (Schwarz) lehnt das Remis ab.');
    expect(tester.widget<IconButton>(_on(_hostKey, find.byKey(const Key('chess-offer-draw')))).onPressed, isNull,
        reason: 'no second offer in the same position');

    await _move(tester, _hostKey, 'g1', 'f3');
    // The guest offers on its turn; the host accepts.
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-offer-draw'))));
    await _settle(tester);
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-offer-confirm'))));
    await _until(tester, () => _on(_hostKey, find.byKey(const Key('chess-draw-offer-dialog'))).evaluate().isNotEmpty,
        'the offer reaches the host');
    await _settle(tester);
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-draw-accept'))));
    await _until(tester, () => _controller(tester, _guestKey).game.isOver, 'the guest sees the agreed draw');
    await _settle(tester);
    for (final d in [_hostKey, _guestKey]) {
      final r = _on(d, find.byKey(const Key('result-dialog')));
      expect(find.descendant(of: r, matching: find.text('Unentschieden')), findsOneWidget, reason: '$d');
      expect(find.descendant(of: r, matching: find.text('Remis vereinbart')), findsOneWidget, reason: '$d');
      expect(_controller(tester, d).game.result.code, GameEndReason.chessDrawAgreed);
    }
    expect([for (final m in hc.moves) m.move['action']],
        ['move', 'move', 'offerDraw', 'declineDraw', 'move', 'offerDraw', 'acceptDraw']);
  });

  testWidgets('the guest promotes through the picker; the host resigns with its offer open', (tester) async {
    await _start(tester);
    final hc = _controller(tester, _hostKey);
    for (final (d, from, to) in [
      (_hostKey, 'h2', 'h3'), (_guestKey, 'a7', 'a5'), (_hostKey, 'h3', 'h4'), (_guestKey, 'a5', 'a4'), //
      (_hostKey, 'b2', 'b4'), (_guestKey, 'a4', 'b3'), (_hostKey, 'c1', 'b2'), (_guestKey, 'b3', 'a2'),
      (_hostKey, 'b2', 'c3'),
    ]) {
      await _move(tester, d, from, to);
    }
    await _tap(tester, _sq(_guestKey, 'a2'));
    await _tap(tester, _sq(_guestKey, 'b1'));
    await _settle(tester);
    expect(_on(_guestKey, find.byKey(const Key('chess-promotion'))), findsOneWidget);
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-promote-q'))));
    await _until(tester, () => hc.moves.length == 10, 'the promotion reaches the host');
    expect(hc.moves.last.move, {'action': 'move', 'from': 'a2', 'to': 'b1', 'promotion': 'q'});
    expect(tester.widget<ChessSquareView>(_sq(_hostKey, 'b1')).piece, const ChessPiece(Player.b, ChessPieceType.queen));

    // The host offers, then resigns instead: the guest's offer dialog closes.
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-offer-draw'))));
    await _settle(tester);
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-offer-confirm'))));
    await _until(tester, () => _on(_guestKey, find.byKey(const Key('chess-draw-offer-dialog'))).evaluate().isNotEmpty,
        'the offer reaches the guest');
    await hc.resign(Player.a);
    await _until(tester, () => _controller(tester, _guestKey).game.isOver, 'the guest sees the resign');
    await _settle(tester);
    expect(_on(_guestKey, find.byKey(const Key('chess-draw-offer-dialog'))), findsNothing);
    expect(find.descendant(of: _on(_guestKey, find.byKey(const Key('result-dialog'))), matching: find.text('Du gewinnst!')),
        findsOneWidget);
  });
}
