// Two real apps play Mühle over the network (KLD-038c, P3 check; the design
// of KLD-038a). One run of this file is ONE device: the role comes from
// `--dart-define=KLUNKI_E2E_ROLE=host|guest` (see lib/app/test_mode.dart).
//
// host:  menu → "Über WLAN spielen" → Hosten → Mühle (fixed port + seed from
//        the test mode) → waits for the guest → taps X's half of the
//        scripted 33-move game (test/e2e/muehle_script.dart).
// guest: menu → "Über WLAN spielen" → Beitreten → looks for the host in the
//        mDNS list (reported either way) → joins by the manual address
//        (or by the list entry with KLUNKI_E2E_JOIN=mdns) → taps O's half.
// Both then print `KLUNKI_IT E2E_RESULT {json}`; tool/e2e_ios_sims.sh compares
// the two lines and prints PASS/FAIL.
//
// Without a role every test here is skipped, so
// `flutter test integration_test -d <id>` still runs only app_test.dart.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/app/test_mode.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/muehle_screen.dart';
import 'package:klunki/ui/menu_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart' show playerMark;
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../test/e2e/muehle_script.dart';
import 'support.dart';

/// `mdns`: join by tapping the host in the discovery list (fails if it never
/// shows); anything else: join by the manual address [E2eMode.host].
const joinBy = String.fromEnvironment('KLUNKI_E2E_JOIN', defaultValue: 'manual');

/// How long the host waits for the guest (the guest app is built after the
/// host is up, so this covers a full build).
const guestWait = Duration(minutes: 12);

/// How long the guest keeps retrying the join (host still starting).
const joinWait = Duration(minutes: 5);

/// How long the guest looks at the mDNS list before deciding.
const mdnsWait = Duration(seconds: 20);

/// Player names (KLD-056), preset so the first-run name dialog is skipped.
const hostName = 'iPhone';
const guestName = 'iPad';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final isHost = E2eMode.role == 'host';
  final me = isHost ? Player.a : Player.b;
  final tag = isHost ? 'host' : 'guest';

  Future<void> openPairing(WidgetTester tester, String name) async {
    // German, like the widget tests; the run is independent of the
    // simulator language and of a saved choice.
    await tester.pumpWidget(KlunkiApp(
      localeController: LocaleController.memory(const Locale('de')),
      playerNameController: PlayerNameController.memory(name: name),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MenuScreen), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('menu-network')));
    expect(find.byKey(const Key('player-name-dialog')), findsNothing, reason: 'the name is already set');
  }

  Future<void> host(WidgetTester tester) async {
    await openPairing(tester, hostName);
    await tapAndSettle(tester, find.byKey(const Key('pair-game-muehle')));
    await tester.tap(find.byKey(const Key('pair-host-start')));
    await pumpUntilFound(tester, find.byKey(const Key('pair-host-waiting')), what: 'hosting');
    final address = tester
        .widget<Text>(find.descendant(of: find.byKey(const Key('pair-address-text-0')), matching: find.byType(Text)))
        .data!;
    expect(address, endsWith(':${E2eMode.port}'), reason: 'port ${E2eMode.port} was free (else the app fell back)');
    log('E2E_READY host $address port=${E2eMode.port}');
    await screenshot(binding, tester, 'net_host_waiting');
    await pumpUntilFound(tester, find.byType(MuehleScreen),
        timeout: guestWait, step: const Duration(milliseconds: 200), what: 'the guest joins');
  }

  Future<void> guest(WidgetTester tester) async {
    await openPairing(tester, guestName);
    // "Beitreten" (no settle: the "searching" spinner never stops).
    await tester.tap(find.byIcon(Icons.login));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // mDNS: does the host show up in the list? Reported either way.
    // The entry's title is "iPhone hostet Mühle" (KLD-056: the host's name).
    final entry = find.ancestor(of: find.text('$hostName hostet Mühle'), matching: find.byType(Card));
    final sw = Stopwatch()..start();
    while (entry.evaluate().isEmpty && sw.elapsed < mdnsWait) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    }
    final seen = entry.evaluate().isNotEmpty;
    String? listed;
    if (seen) {
      final key = tester.widget<Card>(entry.first).key;
      listed = key is ValueKey<String> ? key.value.replaceFirst('pair-host-', '') : '?';
    }
    log('E2E_MDNS seen=$seen${seen ? ' entry=$listed after=${sw.elapsed.inMilliseconds}ms' : ''}');
    await screenshot(binding, tester, 'net_guest_join');

    final joinSw = Stopwatch()..start();
    var attempts = 0;
    while (find.byType(MuehleScreen).evaluate().isEmpty) {
      if (joinSw.elapsed > joinWait) fail('could not join within ${joinWait.inMinutes} min');
      attempts++;
      if (joinBy == 'mdns') {
        expect(seen, isTrue, reason: 'KLUNKI_E2E_JOIN=mdns, but the host never showed in the list');
        await tester.tap(entry.first);
      } else {
        await tester.enterText(find.byKey(const Key('pair-manual')), '${E2eMode.host}:${E2eMode.port}');
        await tester.pump();
        await tester.tap(find.byKey(const Key('pair-manual-connect')));
      }
      await tester.pump();
      // Wait for the game, or for the failed attempt (then retry).
      await pumpUntil(
        tester,
        () =>
            find.byType(MuehleScreen).evaluate().isNotEmpty ||
            (find.byKey(const Key('pair-join-error')).evaluate().isNotEmpty &&
                find.byKey(const Key('pair-join-progress')).evaluate().isEmpty),
        timeout: const Duration(seconds: 30),
        what: 'join attempt $attempts',
      );
      if (find.byType(MuehleScreen).evaluate().isEmpty) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    log('E2E_JOINED by=$joinBy attempts=$attempts after=${joinSw.elapsed.inMilliseconds}ms');
  }

  testWidgets('Mühle over the network as the $tag', skip: !E2eMode.enabled, timeout: const Timeout(Duration(minutes: 20)),
      (tester) async {
    final total = Stopwatch()..start();
    if (isHost) {
      await host(tester);
    } else {
      await guest(tester);
    }
    await tester.pumpAndSettle();
    final c = controllerOf(tester);
    final transport = c.transport as NetworkTransport;
    expect(transport.me, me, reason: 'the host plays X, the guest O');
    expect(c.config.gameId, 'muehle');
    expect(c.config.seed, E2eMode.seed, reason: 'the fixed seed of the test mode');
    log('E2E_START $tag me=${playerMark(me)} seed=${c.config.seed}');

    // The connection bar shows both player names (KLD-056).
    final myName = isHost ? hostName : guestName;
    final peerName = isHost ? guestName : hostName;
    String status() => tester.widget<Text>(find.byKey(const Key('net-status'))).data ?? '';
    await pumpUntil(
        tester,
        () => find.byKey(const Key('net-status')).evaluate().isNotEmpty && status().contains('Gegner: $peerName'),
        what: 'the peer name in the connection bar');
    expect(status(), startsWith('Du ($myName, '));
    expect(status(), contains('Gegner: $peerName ('));
    log('E2E_NAMES $tag "${status()}"');

    final gameSw = Stopwatch()..start();
    for (final s in muehleScript) {
      // Wait until the previous move arrived and it is my turn, or until
      // the other device made this move.
      await pumpUntil(tester, () => c.moves.length >= s.index, timeout: const Duration(seconds: 60), what: 'sync before $s');
      // (Polling can miss intermediate states: the opponent may already be further.)
      if (c.moves.length == s.index && c.game.currentPlayer == me) {
        expect(c.canAct, isTrue, reason: 'my turn at $s');
        // The move may have arrived after the last frame: wait until the
        // rendered board accepts input again (it ignores taps off-turn).
        final first = find.byKey(Key('muehle-point-${s.taps.first}'));
        await pumpUntil(
          tester,
          () => !tester
              .widgetList<IgnorePointer>(find.ancestor(of: first, matching: find.byType(IgnorePointer)))
              .any((w) => w.ignoring),
          what: 'board enabled for $s',
        );
        for (final p in s.taps) {
          await tester.tap(find.byKey(Key('muehle-point-$p')));
          await tester.pump();
          await tester.pump();
        }
      }
      await pumpUntil(tester, () => c.moves.length > s.index,
          timeout: const Duration(seconds: 60), what: '$s accepted');
      expect(c.moves[s.index].move, s.move, reason: '$s');
      if (s.index == 16) await screenshot(binding, tester, 'net_${tag}_midgame');
    }

    final g = c.game as MuehleGame;
    await pumpUntilFound(tester, find.byKey(resultDialog), what: 'result dialog');
    await tester.pumpAndSettle();
    expect(g.isOver, isTrue);
    expect(g.result.winner, muehleScriptWinner);
    expect(g.result.reason, muehleScriptReason);
    // O (the guest) wins: the guest reads "Du gewinnst!", the host the
    // guest's name with its mark (KLD-056).
    final headline = me == muehleScriptWinner ? 'Du gewinnst!' : '$guestName (O) gewinnt!';
    expect(find.descendant(of: find.byKey(resultDialog), matching: find.text(headline)), findsOneWidget);
    await screenshot(binding, tester, 'net_${tag}_result');

    final moves = jsonEncode([for (final m in c.moves) m.move]);
    final result = {
      'game': c.config.gameId,
      'seed': c.config.seed,
      'moves': c.moves.length,
      'movesHash': fnv1a(moves),
      'board': [for (final o in g.board) o == null ? '.' : playerMark(o)].join(),
      'winner': g.result.winner == null ? null : playerMark(g.result.winner!),
      'draw': g.result.draw,
      'reason': g.result.reason,
    };
    log('E2E_RESULT ${jsonEncode(result)}');
    log('E2E_TIMING $tag game=${gameSw.elapsed.inMilliseconds}ms total=${total.elapsed.inMilliseconds}ms');

    if (isHost) {
      // Let the guest receive the last `accepted` and leave first.
      await pumpUntil(tester, () => transport.connection.value != NetConnectionState.connected,
          timeout: const Duration(minutes: 2), what: 'the guest leaves');
    } else {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    // Leaving the game closes the session (`bye`).
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
