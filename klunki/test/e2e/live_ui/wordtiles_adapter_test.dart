// The Wortgewandt live-UI adapter reports every turn once, in order, even
// when two steps reach a network guest in one frame (KLD-094 step 6 under
// load: the echo of the guest's own move and the host's quick answer arrived
// between two looks of the driver; the screen line, which holds only the
// latest turn, skipped the guest's move and the guest's log ended one
// behind). The guest's history really holds both: the screen just never
// showed the first one on its last-turn line.
@Timeout(Duration(seconds: 90))
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  testWidgets('two steps in one frame on the guest: both turns reported, in order', (tester) async {
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
    final d = UiDevice('guest O', scope: _guestKey, me: Player.b);
    final alive = testRunGuard(tester);
    for (var i = 0; !d.has(find.byType(WordTilesBoard)); i++) {
      alive();
      if (i > 3000) fail('no guest board');
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    }
    final a = WordTilesAdapter();
    final c = d.controller(tester);
    final seen = <TurnRecord>[];
    void look() {
      final r = a.observe(tester, d, host.game, inSync: true);
      if (r != null && (seen.isEmpty || r != seen.last)) seen.add(r);
    }

    // Anna passes; the guest sees it.
    await tester.runAsync(() => host.submit(_pass));
    await _untilReal(tester, () => c.moves.length == 1, 'the first pass on the guest');
    await tester.pump();
    look();
    // Ben passes and Anna answers at once: both steps reach the guest
    // before its next frame.
    await tester.runAsync(() => guest.submit(_pass));
    await _untilReal(tester, () => host.moves.length == 2, 'the guest pass on the host');
    await tester.runAsync(() => host.submit(_pass));
    await _untilReal(tester, () => c.moves.length == 3, 'both steps on the guest');
    await tester.pump();
    final line = tester.widget<Text>(d.on(find.byKey(const Key('wordtiles-last-turn')))).data;
    expect(line, 'Anna: ${deL10n.wordtilesMovePass}', reason: 'the screen line shows only the latest turn');
    for (var i = 0; i < 3; i++) {
      look();
    }

    expect([for (final r in seen) '${playerMark(r.actor)} ${r.outcome}'], [
      'X ${deL10n.wordtilesMovePass}',
      'O ${deL10n.wordtilesMovePass}',
      'X ${deL10n.wordtilesMovePass}',
    ]);
    expect(seen, a.engineTurns(c));
    expect(a.historyReads, 1, reason: 'the guest\'s own pass came from its history, not the screen line');

    // No loss for the player: the guest's history sheet lists every move.
    expect([for (final m in c.moves) m.move], [for (final m in host.moves) m.move]);
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
}
