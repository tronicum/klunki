// KLD-126: the chess clock over the network, two NetworkGameSessions side
// by side on 127.0.0.1 (real sockets, real time for the clock): both
// devices show both clocks, a pause needs the other device's agreement
// (and so does going on), and a short clock flags the guest: the host
// calls time and both devices show "Zeit abgelaufen".
@Timeout(Duration(seconds: 90))
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/chess/chess_board.dart';
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

/// Pumps (fake time, [step]) and waits a little real time until
/// [condition] holds. The clock reads real time; its timers run in the
/// fake zone, so both have to move.
Future<void> _until(WidgetTester tester, bool Function() condition, String what,
    {Duration step = Duration.zero, int rounds = 2000}) async {
  final alive = testRunGuard(tester); // KLD-109: stop once the test has ended
  for (var round = 0;; round++) {
    alive();
    await tester.pump(step);
    if (condition()) {
      await tester.pump();
      await tester.pump();
      return;
    }
    if (round > rounds) fail('condition not met: $what');
    await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: step == Duration.zero ? 10 : 50)));
  }
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pump();
  await tester.pump();
}

Future<void> _start(WidgetTester tester, GameConfig config) async {
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
  Widget device(Key key, NetworkTransport t) => Expanded(
        child: KeyedSubtree(
          key: key,
          child: ConfirmMoveScope(
            settings: ConfirmMoveSettings.memory(network: false),
            child: localizedApp(NetworkGameSession(transport: t)),
          ),
        ),
      );
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Row(children: [device(_hostKey, host), device(_guestKey, guest)]),
  ));
  await _until(tester, () => _on(_guestKey, find.byType(ChessBoard)).evaluate().isNotEmpty, 'guest board');
  await _until(tester, () => _on(_hostKey, find.byType(ChessBoard)).evaluate().isNotEmpty, 'host board');
}

void main() {
  testWidgets('both clocks on both devices; a pause and going on need the other device', (tester) async {
    await _start(tester, const GameConfig('chess', chessClock: ChessTimeControl(10 * 60000)));
    for (final d in [_hostKey, _guestKey]) {
      for (final p in ['a', 'b']) {
        expect(_on(d, find.byKey(Key('chess-clock-$p'))), findsOneWidget, reason: '$d $p');
      }
    }
    final hc = _controller(tester, _hostKey), gc = _controller(tester, _guestKey);
    // The guest asks; the host's board shows the question.
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-pause'))));
    await _until(tester, () => _on(_hostKey, find.byKey(const Key('chess-clock-request'))).evaluate().isNotEmpty,
        'pause request on the host');
    expect(_on(_hostKey, find.textContaining(RegExp(r'^Ben.* möchte eine Pause machen\.$'))), findsOneWidget);
    expect(tester.widget<Text>(_on(_guestKey, find.byKey(const Key('shell-hint')))).data,
        startsWith('Angefragt – Anna'));
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-clock-agree'))));
    await _until(tester, () => (gc.game as ChessGame).clockPaused, 'paused on the guest');
    for (final d in [_hostKey, _guestKey]) {
      expect(_on(d, find.byKey(const Key('chess-pause-cover'))), findsOneWidget, reason: '$d');
    }
    expect((hc.transport as NetworkTransport).clock!.ticking, isFalse);
    // Going on: asked on the host, agreed on the guest.
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-resume'))));
    await _until(tester, () => _on(_guestKey, find.byKey(const Key('chess-clock-agree'))).evaluate().isNotEmpty,
        'resume request on the guest');
    expect(_on(_guestKey, find.textContaining(RegExp(r'^Anna.* möchte weiterspielen\.$'))), findsOneWidget);
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-clock-agree'))));
    await _until(tester, () => !(hc.game as ChessGame).clockPaused, 'running again');
    await _until(tester, () => _on(_guestKey, find.byKey(const Key('chess-pause-cover'))).evaluate().isEmpty,
        'cover gone on the guest');
    expect((hc.transport as NetworkTransport).clock!.ticking, isTrue);
  });

  testWidgets('a short clock flags the guest: the host calls time, both show "Zeit abgelaufen"', (tester) async {
    await _start(tester, const GameConfig('chess', chessClock: ChessTimeControl(2000)));
    final hc = _controller(tester, _hostKey);
    await _tap(tester, _sq(_hostKey, 'e2'));
    await _tap(tester, _sq(_hostKey, 'e4'));
    await _until(tester, () => _controller(tester, _guestKey).moves.length == 1, 'e4 on the guest');
    // The guest waits: 2 s and the 1 s lag credit later the host calls time.
    await _until(tester, () => _controller(tester, _guestKey).game.isOver, 'time out',
        step: const Duration(milliseconds: 50), rounds: 400);
    expect(hc.moves.last.move, ChessGame.timeoutMove(Player.b));
    expect(hc.game.result.code, GameEndReason.chessTimeout);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (final d in [_hostKey, _guestKey]) {
      final dialog = _on(d, find.byKey(const Key('result-dialog')));
      expect(find.descendant(of: dialog, matching: find.textContaining('Zeit abgelaufen bei Ben')), findsOneWidget,
          reason: '$d');
    }
    expect(tester.widget<Text>(_on(_guestKey, find.byKey(const Key('chess-clock-text-b')))).data, '0.0');
  });
}
