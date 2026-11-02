// The Wortgewandt live-UI adapter reports every turn once, in order, even
// when two steps reach a network guest in one frame (KLD-094 step 6 under
// load: the echo of the guest's own move and the host's quick answer arrived
// between two looks of the driver; the screen line, which holds only the
// latest turn, skipped the guest's move and the guest's log ended one
// behind). The guest's history really holds both: the screen just never
// showed the first one on its last-turn line. The same at the end: the
// guest's last pass and the host's game-ending answer in one frame, the
// result dialog over the line before it showed the pass.
@Timeout(Duration(seconds: 90))
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_board.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import '../../support/test_run.dart';
import 'live_ui_driver.dart';
import 'wordtiles_adapter.dart';

const _hostKey = Key('device-host');
const _guestKey = Key('device-guest');
const _ping = Duration(milliseconds: 100);
const _timeout = Duration(seconds: 30);
const _pass = {'action': 'pass'};

/// Waits real time (no frame) until [condition] holds.
Future<void> _untilReal(WidgetTester tester, bool Function() condition, String what) async {
  final alive = testRunGuard(tester);
  for (var round = 0; !condition(); round++) {
    alive();
    if (round > 3000) fail('condition not met: $what');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
}

/// Host (Anna) and guest (Ben) side by side over 127.0.0.1, the guest's
/// screen as a [UiDevice] and a [look] that observes it like the driver
/// (the screen, or the history under the result dialog).
class _Net {
  final WidgetTester tester;
  final NetworkTransport host, guest;
  final UiDevice d = UiDevice('guest O', scope: _guestKey, me: Player.b);
  final WordTilesAdapter a = WordTilesAdapter();
  final List<TurnRecord> seen = [];
  _Net(this.tester, this.host, this.guest);

  GameController get c => d.controller(tester);

  void look() {
    if (d.dialogOpen) {
      if (d.resultShown()) seen.addAll(a.unseenAtEnd(tester, d, seen.length));
      return;
    }
    final r = a.observe(tester, d, host.game, inSync: true);
    if (r != null && (seen.isEmpty || r != seen.last)) seen.add(r);
  }

  /// [by] moves (no frame); then the guest gets it, one frame, a look.
  Future<void> step(NetworkTransport by, Map<String, dynamic> move) async {
    final n = c.moves.length;
    await tester.runAsync(() => by.submit(move));
    await _untilReal(tester, () => c.moves.length == n + 1, 'move ${n + 1} on the guest');
    await tester.pump();
    look();
  }

  /// The guest moves and the host answers at once: both steps reach the
  /// guest before its next frame.
  Future<void> bothInOneFrame(Map<String, dynamic> guestMove, Map<String, dynamic> hostMove) async {
    final n = c.moves.length;
    await tester.runAsync(() => guest.submit(guestMove));
    await _untilReal(tester, () => host.moves.length == n + 1, 'the guest move on the host');
    await tester.runAsync(() => host.submit(hostMove));
    await _untilReal(tester, () => c.moves.length == n + 2, 'both steps on the guest');
    await tester.pump();
  }
}

Future<_Net> _start(WidgetTester tester) async {
  tester.view.physicalSize = const Size(2000, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (host, guest) = (await tester.runAsync(() async {
    final h = await NetworkTransport.host(const GameConfig('wordtiles', seed: 4, tiles: 'de'),
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
  final net = _Net(tester, host, guest);
  final alive = testRunGuard(tester);
  for (var i = 0; !net.d.has(find.byType(WordTilesBoard)); i++) {
    alive();
    if (i > 3000) fail('no guest board');
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
  return net;
}

void main() {
  testWidgets('two steps in one frame on the guest: both turns reported, in order', (tester) async {
    final net = await _start(tester);
    final (d, a, c) = (net.d, net.a, net.c);

    await net.step(net.host, _pass); // Anna passes; the guest sees it
    await net.bothInOneFrame(_pass, _pass); // Ben passes, Anna answers at once
    final line = tester.widget<Text>(d.on(find.byKey(const Key('wordtiles-last-turn')))).data;
    expect(line, 'Anna: ${deL10n.wordtilesMovePass}', reason: 'the screen line shows only the latest turn');
    for (var i = 0; i < 3; i++) {
      net.look();
    }

    expect([for (final r in net.seen) '${playerMark(r.actor)} ${r.outcome}'], [
      'X ${deL10n.wordtilesMovePass}',
      'O ${deL10n.wordtilesMovePass}',
      'X ${deL10n.wordtilesMovePass}',
    ]);
    expect(net.seen, a.engineTurns(c));
    expect(a.historyReads, 1, reason: 'the guest\'s own pass came from its history, not the screen line');

    // No loss for the player: the guest's history sheet lists every move.
    expect([for (final m in c.moves) m.move], [for (final m in net.host.moves) m.move]);
    await tester.tap(d.on(find.byKey(const Key('shell-history'))));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final sheet = d.on(find.byKey(const Key('history-sheet')));
    expect(sheet, findsOneWidget);
    for (final (who, n) in [('Anna', 2), ('Ben', 1)]) {
      expect(find.descendant(of: sheet, matching: find.text(deL10n.shellHistoryEntry(who, deL10n.wordtilesMovePass))),
          findsNWidgets(n),
          reason: who);
    }
  });

  testWidgets('the guest\'s last turn and the game end in one frame: the turn under the result dialog is reported',
      (tester) async {
    final net = await _start(tester);
    final (d, a, c) = (net.d, net.a, net.c);
    final g = net.host.game as WordTilesGame;

    // Anna scores, then four passes one by one; Ben's pass is the fifth
    // scoreless turn, Anna's answer the sixth: it ends the game.
    await net.step(net.host, g.legalMoves.firstWhere((m) => m['action'] == 'place'));
    for (var i = 0; i < 4; i++) {
      await net.step(i.isEven ? net.guest : net.host, _pass);
    }
    expect(net.seen, hasLength(5));
    expect(g.isOver, isFalse);

    await net.bothInOneFrame(_pass, _pass); // Ben's last pass and Anna's game-ending one
    expect(c.game.isOver, isTrue);
    for (var i = 0; i < 20; i++) {
      net.look();
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(d.resultShown(), isTrue);

    // The final turn (Anna's) sits under the dialog, as in the driver; Ben's
    // pass before it never was on the line but is reported from the history.
    expect(net.seen, a.engineTurns(c));
    expect(net.seen, hasLength(6));
    expect('${playerMark(net.seen.last.actor)} ${net.seen.last.outcome}', 'O ${deL10n.wordtilesMovePass}');
    expect(a.historyReads, 1);
    expect(a.unseenAtEnd(tester, d, net.seen.length), isEmpty, reason: 'reported once');
  });
}
