// Chess over the network (KLD-059 step 3): host (White) and guest (Black)
// as two NetworkGameSessions side by side, real NetworkTransports on
// 127.0.0.1. Each device shows its own side at the bottom (the guest's board
// is turned, coordinates included), names the players ("Du bist am Zug",
// "Warte auf Anna (Weiß)…"), has no undo, restart or auto-turn, and plays
// by taps; the draw offer goes from one device to the other.
// Step 4a: the host may play Black (GameConfig.chessWhite): then the guest
// is White, moves first and sees its board un-turned, the host's is turned.
// KLD-122: "Zug bestätigen" is on by default on both devices: every tapped
// move waits for "Ziehen" and only then reaches the host ([_move] checks);
// one test sets it per device and plays "Anders ziehen", drag and the in-game toggle.
@Timeout(Duration(seconds: 90))
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/chess/chess_board.dart';
import 'package:klunki/ui/games/chess/chess_pieces.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/confirm_move.dart';
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
Future<(NetworkTransport, NetworkTransport)> _start(WidgetTester tester,
    [GameConfig config = const GameConfig('chess'), ConfirmMoveSettings? hostConfirm, ConfirmMoveSettings? guestConfirm]) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (host, guest) = (await tester.runAsync(() async {
    final h = await NetworkTransport.host(config,
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
  // Each device its own "Zug bestätigen" (KLD-122), the default: on.
  Widget device(Key key, NetworkTransport t, ConfirmMoveSettings? confirm) => Expanded(
        child: KeyedSubtree(
          key: key,
          child: ConfirmMoveScope(
            settings: confirm ?? ConfirmMoveSettings.memory(),
            child: localizedApp(NetworkGameSession(transport: t)),
          ),
        ),
      );
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Row(children: [device(_hostKey, host, hostConfirm), device(_guestKey, guest, guestConfirm)]),
  ));
  await _until(tester, () => _on(_guestKey, find.byType(ChessBoard)).evaluate().isNotEmpty, 'guest board');
  await _until(tester, () => _on(_hostKey, find.byType(ChessBoard)).evaluate().isNotEmpty, 'host board');
  return (host, guest);
}

/// With "Zug bestätigen" (KLD-122) the move just chosen on [device] waits:
/// nothing has reached the host after a few real-time rounds; then "Ziehen".
Future<void> _commitIfPending(WidgetTester tester, Key device) async {
  final bar = _on(device, find.byKey(const Key('confirm-move-bar')));
  if (bar.evaluate().isEmpty) return;
  final n = _controller(tester, _hostKey).moves.length;
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
  expect(_controller(tester, _hostKey).moves, hasLength(n), reason: 'a pending move stays on $device');
  await _tap(tester, _on(device, find.byKey(const Key('confirm-move-commit'))));
}

/// [device] moves [from]→[to] by two taps (and "Ziehen" when it asks);
/// waits until both devices have it.
Future<void> _move(WidgetTester tester, Key device, String from, String to) async {
  final n = _controller(tester, _hostKey).moves.length;
  await _tap(tester, _sq(device, from));
  expect(tester.widget<ChessSquareView>(_sq(device, from)).selected, isTrue, reason: '$from selected on $device');
  await _tap(tester, _sq(device, to));
  await _commitIfPending(tester, device);
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
    await _settle(tester);
    // KLD-122: the chosen queen waits on b1 for "Ziehen".
    expect(tester.widget<ChessSquareView>(_sq(_guestKey, 'b1')).piece,
        const ChessPiece(ChessColor.black, ChessPieceType.queen));
    expect(tester.widget<ChessSquareView>(_sq(_guestKey, 'b1')).pendingCapture,
        const ChessPiece(ChessColor.white, ChessPieceType.knight));
    await _commitIfPending(tester, _guestKey);
    await _until(tester, () => hc.moves.length == 10, 'the promotion reaches the host');
    expect(hc.moves.last.move, {'action': 'move', 'from': 'a2', 'to': 'b1', 'promotion': 'q'});
    expect(tester.widget<ChessSquareView>(_sq(_hostKey, 'b1')).piece,
        const ChessPiece(ChessColor.black, ChessPieceType.queen));

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

  testWidgets('host plays Black (step 4a): the guest (White) opens, boards turned to each own colour; host mates',
      (tester) async {
    await _start(tester, const GameConfig('chess', chessWhite: Player.b));
    // Orientation follows the own colour: the host (Black) is turned now.
    expect(_text(tester, _hostKey, const Key('chess-rank-0')), '1');
    expect(_text(tester, _hostKey, const Key('chess-file-0')), 'h');
    expect(_text(tester, _guestKey, const Key('chess-rank-0')), '8');
    expect(_text(tester, _guestKey, const Key('chess-file-0')), 'a');
    for (final (device, bottomLeft, topRight) in [(_hostKey, 'h8', 'a1'), (_guestKey, 'a1', 'h8')]) {
      final bl = tester.getCenter(_sq(device, bottomLeft)), tr = tester.getCenter(_sq(device, topRight));
      expect(bl.dx, lessThan(tr.dx), reason: '$device: $bottomLeft left of $topRight');
      expect(bl.dy, greaterThan(tr.dy), reason: '$device: $bottomLeft below $topRight');
    }
    // "Du spielst …" until the first move; the status texts stay name-based.
    expect(_text(tester, _hostKey, const Key('shell-hint')), 'Du spielst Schwarz.');
    expect(_text(tester, _guestKey, const Key('shell-hint')), 'Du spielst Weiß.');
    expect(_text(tester, _guestKey, const Key('shell-status')), 'Du bist am Zug');
    expect(_text(tester, _hostKey, const Key('shell-status')), 'Warte auf Ben (Weiß)…');
    // The tokens are the kings of the own colour (connection bar).
    ChessPiece token(Key device, String key) => tester
        .widget<ChessPieceIcon>(find.descendant(of: _on(device, find.byKey(Key(key))), matching: find.byType(ChessPieceIcon)))
        .piece;
    expect(token(_hostKey, 'net-you-token'), const ChessPiece(ChessColor.black, ChessPieceType.king));
    expect(token(_hostKey, 'net-peer-token'), const ChessPiece(ChessColor.white, ChessPieceType.king));
    expect(token(_guestKey, 'net-you-token'), const ChessPiece(ChessColor.white, ChessPieceType.king));
    // The host cannot pick up a piece before White has moved.
    await _tap(tester, _sq(_hostKey, 'e7'));
    expect(tester.widget<ChessSquareView>(_sq(_hostKey, 'e7')).selected, isFalse);

    await _move(tester, _guestKey, 'f2', 'f3');
    expect(_text(tester, _hostKey, const Key('shell-status')), 'Du bist am Zug');
    expect(_text(tester, _hostKey, const Key('shell-hint')), 'Tippe eine Figur an, um sie zu ziehen.');
    expect(_on(_guestKey, find.text('Du spielst Weiß.')), findsNothing);
    await _move(tester, _hostKey, 'e7', 'e5');
    await _move(tester, _guestKey, 'g2', 'g4');
    await _move(tester, _hostKey, 'd8', 'h4');
    final hc = _controller(tester, _hostKey), gc = _controller(tester, _guestKey);
    expect((gc.game as ChessGame).fen, (hc.game as ChessGame).fen);
    expect(hc.moves.first.player, Player.b, reason: 'the guest moved first');
    await _settle(tester);
    final hostResult = _on(_hostKey, find.byKey(const Key('result-dialog')));
    final guestResult = _on(_guestKey, find.byKey(const Key('result-dialog')));
    expect(find.descendant(of: hostResult, matching: find.text('Du gewinnst!')), findsOneWidget);
    expect(find.descendant(of: guestResult, matching: find.text('Anna (Schwarz) gewinnt!')), findsOneWidget);
  });

  testWidgets('host plays Black: the guest (White) offers a draw on its first turn, the host accepts', (tester) async {
    await _start(tester, const GameConfig('chess', chessWhite: Player.b));
    expect(tester.widget<IconButton>(_on(_hostKey, find.byKey(const Key('chess-offer-draw')))).onPressed, isNull);
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-offer-draw'))));
    await _settle(tester);
    expect(_on(_guestKey, find.text('Anna (Schwarz) kann annehmen oder ablehnen. Bei Annahme endet das Spiel unentschieden.')),
        findsOneWidget);
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-offer-confirm'))));
    await _until(tester, () => _on(_hostKey, find.byKey(const Key('chess-draw-offer-dialog'))).evaluate().isNotEmpty,
        'the offer reaches the host');
    await _settle(tester);
    expect(_on(_hostKey, find.text('Ben (Weiß) bietet ein Remis an. Bei Annahme endet das Spiel unentschieden.')),
        findsOneWidget);
    expect(_text(tester, _guestKey, const Key('shell-hint')), 'Remis angeboten – Anna (Schwarz) entscheidet.');
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-draw-accept'))));
    await _until(tester, () => _controller(tester, _guestKey).game.isOver, 'the guest sees the agreed draw');
    for (final d in [_hostKey, _guestKey]) {
      expect(_controller(tester, d).game.result.code, GameEndReason.chessDrawAgreed);
    }
    expect([for (final m in _controller(tester, _hostKey).moves) (m.player, m.move['action'])],
        [(Player.b, 'offerDraw'), (Player.a, 'acceptDraw')]);
  });

  testWidgets('KLD-122: the guest\'s move waits for "Ziehen", "Anders ziehen" restores; host turns it on in the game',
      (tester) async {
    final hostConfirm = ConfirmMoveSettings.memory(network: false);
    final guestConfirm = ConfirmMoveSettings.memory();
    await _start(tester, const GameConfig('chess'), hostConfirm, guestConfirm);
    final hc = _controller(tester, _hostKey), gc = _controller(tester, _guestKey);
    // The toggle sits in each device's app bar, showing its own setting.
    bool toggle(Key d) => tester.widget<IconButton>(_on(d, find.byKey(const Key('shell-confirm-move')))).isSelected!;
    expect(toggle(_hostKey), isFalse);
    expect(toggle(_guestKey), isTrue);

    // Host: off, the move goes at once.
    await _tap(tester, _sq(_hostKey, 'e2'));
    await _tap(tester, _sq(_hostKey, 'e4'));
    expect(_on(_hostKey, find.byKey(const Key('confirm-move-bar'))), findsNothing);
    await _until(tester, () => gc.moves.length == 1, 'e4 on the guest');

    // Guest: on. The pawn stands on e5, nothing is sent.
    await _tap(tester, _sq(_guestKey, 'e7'));
    await _tap(tester, _sq(_guestKey, 'e5'));
    expect(_on(_guestKey, find.byKey(const Key('confirm-move-bar'))), findsOneWidget);
    ChessSquareView view(Key d, String s) => tester.widget<ChessSquareView>(_sq(d, s));
    expect(view(_guestKey, 'e5').piece, const ChessPiece(ChessColor.black, ChessPieceType.pawn));
    expect(view(_guestKey, 'e5').pendingTo, isTrue);
    expect(view(_guestKey, 'e7').piece, isNull);
    expect(view(_guestKey, 'e7').pendingFrom, const ChessPiece(ChessColor.black, ChessPieceType.pawn));
    expect(_text(tester, _guestKey, const Key('shell-hint')), 'Passt der Zug? Tippe auf „Ziehen“ oder „Anders ziehen“.');
    // Other pieces cannot be picked up meanwhile.
    await _tap(tester, _sq(_guestKey, 'g8'));
    expect(view(_guestKey, 'g8').selected, isFalse);
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(hc.moves, hasLength(1), reason: 'the host has not seen the pending move');
    expect(gc.moves, hasLength(1));
    expect(view(_hostKey, 'e7').piece, const ChessPiece(ChessColor.black, ChessPieceType.pawn));

    // "Anders ziehen": the board as before.
    await _tap(tester, _on(_guestKey, find.byKey(const Key('confirm-move-back'))));
    expect(_on(_guestKey, find.byKey(const Key('confirm-move-bar'))), findsNothing);
    expect(view(_guestKey, 'e7').piece, const ChessPiece(ChessColor.black, ChessPieceType.pawn));
    expect(view(_guestKey, 'e5').piece, isNull);
    expect(view(_guestKey, 'e7').pendingFrom, isNull);

    // Drag d7→d5 instead, then "Ziehen".
    await tester.drag(_sq(_guestKey, 'd7'), tester.getCenter(_sq(_guestKey, 'd5')) - tester.getCenter(_sq(_guestKey, 'd7')));
    await tester.pump();
    await tester.pump();
    expect(view(_guestKey, 'd5').pendingTo, isTrue);
    expect(hc.moves, hasLength(1));
    await _tap(tester, _on(_guestKey, find.byKey(const Key('confirm-move-commit'))));
    await _until(tester, () => hc.moves.length == 2, 'd5 reaches the host');
    expect(hc.moves.last.move, {'action': 'move', 'from': 'd7', 'to': 'd5'});
    expect(_on(_guestKey, find.byKey(const Key('confirm-move-bar'))), findsNothing);

    // The host turns it on during the game: its capture now waits.
    await _tap(tester, _on(_hostKey, find.byKey(const Key('shell-confirm-move'))));
    expect(hostConfirm.network, isTrue);
    expect(guestConfirm.network, isTrue, reason: 'each device its own');
    await _settle(tester);
    expect(_on(_hostKey, find.text('Zug bestätigen ist an.')), findsOneWidget);
    // The snack bar goes away by itself.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(_on(_hostKey, find.text('Zug bestätigen ist an.')), findsNothing);
    await _tap(tester, _sq(_hostKey, 'e4'));
    await _tap(tester, _sq(_hostKey, 'd5'));
    expect(view(_hostKey, 'd5').piece, const ChessPiece(ChessColor.white, ChessPieceType.pawn));
    expect(view(_hostKey, 'd5').pendingCapture, const ChessPiece(ChessColor.black, ChessPieceType.pawn));
    expect(hc.moves, hasLength(2));
    await _commitIfPending(tester, _hostKey);
    await _until(tester, () => gc.moves.length == 3, 'exd5 on the guest');
    expect((gc.game as ChessGame).sanHistory, ['e4', 'd5', 'exd5']);
    expect((gc.game as ChessGame).fen, (hc.game as ChessGame).fen);
  });

  testWidgets('KLD-122: a draw offer or a resign drops the pending move', (tester) async {
    await _start(tester);
    final hc = _controller(tester, _hostKey), gc = _controller(tester, _guestKey);
    await _move(tester, _hostKey, 'e2', 'e4');
    await _tap(tester, _sq(_guestKey, 'e7'));
    await _tap(tester, _sq(_guestKey, 'e5'));
    expect(_on(_guestKey, find.byKey(const Key('confirm-move-bar'))), findsOneWidget);
    // The guest offers a draw instead: the pending move is gone.
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-offer-draw'))));
    await _settle(tester);
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-offer-confirm'))));
    await _until(tester, () => hc.moves.length == 2, 'the offer reaches the host');
    expect(_on(_guestKey, find.byKey(const Key('confirm-move-bar'))), findsNothing);
    expect(tester.widget<ChessSquareView>(_sq(_guestKey, 'e7')).piece,
        const ChessPiece(ChessColor.black, ChessPieceType.pawn));
    expect(hc.moves.last.move['action'], 'offerDraw');
    await _settle(tester);
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-draw-decline'))));
    await _until(tester, () => gc.moves.length == 3, 'the decline reaches the guest');
    await _settle(tester);

    // Pending again; then the host resigns: the game ends, nothing is left.
    await _tap(tester, _sq(_guestKey, 'e7'));
    await _tap(tester, _sq(_guestKey, 'e5'));
    expect(_on(_guestKey, find.byKey(const Key('confirm-move-bar'))), findsOneWidget);
    await hc.resign(Player.a);
    await _until(tester, () => gc.game.isOver, 'the guest sees the resign');
    expect(_on(_guestKey, find.byKey(const Key('confirm-move-bar'))), findsNothing);
    expect([for (final m in hc.moves) m.move['action']], ['move', 'offerDraw', 'declineDraw', 'resign']);
  });
}
