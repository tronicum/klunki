// App-level e2e (KLD-037b), UI layer: the real MuehleScreen for BOTH
// players in one widget test. Left half: the "iOS" app (host, X); right
// half: the "Android" app (guest, O). Each half is its own MaterialApp (own
// Navigator, so each gets its own result dialog). The two app stacks talk
// over real TCP on 127.0.0.1.
//
// Every scripted move is tapped on the device whose player is to move
// (`muehle-point-<p>`); the other device's board must follow. After each
// move both engines and both rendered boards are compared.
//
//   cd klunki && flutter test test/e2e
//
// Real sockets inside testWidgets: the transports are created and awaited
// in `tester.runAsync`, so their sockets, ping timers and handlers live in
// the real zone; taps and pumps stay in the fake-async test zone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/ui/games/muehle_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import 'e2e_support.dart';
import 'muehle_script.dart';
import '../l10n/l10n_test_utils.dart';
import '../support/test_run.dart';

const _timeout = Timeout(Duration(seconds: 30));
const _iosKey = Key('device-ios');
const _androidKey = Key('device-android');

class _Devices {
  final AppStack ios, android;
  _Devices(this.ios, this.android);

  AppStack owner(Player p) => p == Player.a ? ios : android;
  AppStack other(AppStack s) => identical(s, ios) ? android : ios;
  Key keyOf(AppStack s) => identical(s, ios) ? _iosKey : _androidKey;
}

/// Starts both stacks over loopback and pumps both screens side by side.
Future<_Devices> _pumpBoth(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final devices = (await tester.runAsync(() async {
    final ios = await AppStack.host(timeout: widgetNetTimeout);
    final android = await AppStack.join(ios.transport.port!, timeout: widgetNetTimeout);
    await until(() => ios.online, what: 'host sees the guest');
    return _Devices(ios, android);
  }))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox()); // unmount the screens first
    await tester.runAsync(() async {
      await devices.android.close();
      await devices.ios.close();
    });
  });

  Widget phone(Key key, AppStack s) => Expanded(
        child: KeyedSubtree(
          key: key,
          child: localizedApp(MuehleScreen(controller: s.controller), debugShowCheckedModeBanner: false),
        ),
      );
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Row(children: [phone(_iosKey, devices.ios), phone(_androidKey, devices.android)]),
  ));
  await tester.pump();
  await tester.pump(); // hint is set post-frame by the shell
  return devices;
}

Finder _on(Key device, Finder f) => find.descendant(of: find.byKey(device), matching: f);
Finder _point(Key device, int p) => _on(device, find.byKey(Key('muehle-point-$p')));

/// The rendered board of [device]: point → 'X' / 'O' / null, from the
/// `muehle-stone-<p>-<mark>` widgets.
List<String?> _renderedBoard(Key device) => [
      for (var p = 0; p < MuehleGame.pointCount; p++)
        _on(device, find.byKey(Key('muehle-stone-$p-X'))).evaluate().isNotEmpty
            ? 'X'
            : _on(device, find.byKey(Key('muehle-stone-$p-O'))).evaluate().isNotEmpty
                ? 'O'
                : null,
    ];

String _status(WidgetTester tester, Key device) =>
    tester.widget<Text>(_on(device, find.byKey(const Key('shell-status')))).data!;

/// Both engines agree, and both screens render exactly the engine's board
/// and the same status line.
void _expectScreensInSync(WidgetTester tester, _Devices d, String when) {
  expectInSync(d.ios, d.android, when);
  final engine = [for (final o in d.ios.game.board) o == null ? null : playerMark(o)];
  expect(_renderedBoard(_iosKey), engine, reason: 'iOS screen shows the board $when');
  expect(_renderedBoard(_androidKey), engine, reason: 'Android screen shows the board $when');
  expect(_status(tester, _androidKey), _status(tester, _iosKey), reason: 'status lines equal $when');
}

/// Taps [p] on [device] and lets the frame (and the post-frame hint) settle.
Future<void> _tap(WidgetTester tester, Key device, int p, {bool warnIfMissed = true}) async {
  await tester.tap(_point(device, p), warnIfMissed: warnIfMissed);
  await tester.pump();
  await tester.pump();
}

/// Waits (real time) until [s] has [count] moves, then rebuilds.
Future<void> _waitFor(WidgetTester tester, AppStack s, int count, String what) async {
  final alive = testRunGuard(tester);
  await tester.runAsync(() => until(() => s.moveCount == count, what: what));
  alive();
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('both MuehleScreens play the scripted game by taps; boards follow; "Ben gewinnt!" on both',
      timeout: _timeout, (tester) async {
    final d = await _pumpBoth(tester);
    expect(_point(_iosKey, 0), findsOneWidget);
    expect(_point(_androidKey, 0), findsOneWidget);
    expect(_status(tester, _iosKey), 'Anna ist am Zug');
    _expectScreensInSync(tester, d, 'at the start');

    for (final s in muehleScript) {
      final mover = d.owner(d.ios.game.currentPlayer);
      final peer = d.other(mover);
      expect(mover.controller.canAct, isTrue, reason: '${mover.name} may act at $s');
      expect(peer.controller.canAct, isFalse, reason: '${peer.name} may not act at $s');
      for (final p in s.taps) {
        await _tap(tester, d.keyOf(mover), p);
      }
      // The host applies its own move at once; a guest move needs the host's
      // `accepted` round trip first.
      await _waitFor(tester, mover, s.index + 1, '${mover.name} applied $s from taps');
      expect(mover.controller.moves.last.move, s.move);
      await _waitFor(tester, peer, s.index + 1, '${peer.name} receives $s');
      _expectScreensInSync(tester, d, 'after $s');
    }

    await tester.pumpAndSettle(); // mill flash, dialog route transitions
    for (final key in [_iosKey, _androidKey]) {
      expect(_on(key, find.byKey(const Key('result-dialog'))), findsOneWidget, reason: '$key');
      expect(_on(key, find.text('Ben gewinnt!')), findsOneWidget, reason: '$key');
      expect(_on(key, find.text('Gegner hat weniger als 3 Steine')), findsOneWidget, reason: '$key');
    }
    for (final s in [d.ios, d.android]) {
      expect(s.game.result.winner, muehleScriptWinner);
      expect(s.moveCount, muehleScriptLength);
      expect([for (final m in s.controller.moves) m.move], [for (final x in muehleScript) x.move]);
    }
  });

  testWidgets('the device whose turn it is not ignores taps', timeout: _timeout, (tester) async {
    final d = await _pumpBoth(tester);

    Future<void> tapsIgnored(AppStack idle, List<int> points, String when) async {
      final ios = d.ios.state, android = d.android.state;
      for (final p in points) {
        await _tap(tester, d.keyOf(idle), p, warnIfMissed: false);
      }
      // Give a wrongly sent move real time to cross the socket.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(d.ios.state, ios, reason: 'iOS unchanged after ${idle.name} tapped $when');
      expect(d.android.state, android, reason: 'Android unchanged after ${idle.name} tapped $when');
      expect(_on(d.keyOf(idle), find.byKey(const Key('shell-hint'))), findsNothing,
          reason: 'no "your move" hint on ${idle.name}');
      final ignore = find.ancestor(of: _point(d.keyOf(idle), points.first), matching: find.byType(IgnorePointer));
      expect(tester.widgetList<IgnorePointer>(ignore).any((w) => w.ignoring), isTrue,
          reason: '${idle.name} board is input-disabled $when');
      _expectScreensInSync(tester, d, when);
    }

    Future<void> play(int count) async {
      for (final s in muehleScript.take(count).skip(d.ios.moveCount)) {
        final mover = d.owner(d.ios.game.currentPlayer);
        for (final p in s.taps) {
          await _tap(tester, d.keyOf(mover), p);
        }
        await _waitFor(tester, mover, s.index + 1, 'apply $s');
        await _waitFor(tester, d.other(mover), s.index + 1, 'sync $s');
      }
    }

    // X to move: Android taps empty points (would be legal placements for O).
    await tapsIgnored(d.android, [3, 15, 0], 'on Anna\'s turn (placing)');
    expect(_on(_iosKey, find.byKey(const Key('shell-hint'))), findsOneWidget, reason: 'iOS shows its hint');

    // O to move: iOS taps.
    await play(1);
    await tapsIgnored(d.ios, [16, 1], 'on Ben\'s turn (placing)');

    // O owes a removal after the mill 1-4-7 (#7): iOS taps its own stones.
    await play(8);
    expect(d.android.game.pendingRemoval, isTrue);
    await tapsIgnored(d.ios, [8, 21], 'while Ben owes a removal');

    // Moving phase, X to move ("21-9"): Android tries a select + move.
    await play(21);
    expect(d.ios.controller.canAct, isTrue);
    await tapsIgnored(d.android, [15, 16], 'on Anna\'s turn (moving)');
    expect(_on(_androidKey, find.byKey(const Key('muehle-selected-15'))), findsNothing);

    // The proper device can still play the very move that was ignored.
    await play(23);
    expect(d.android.moveCount, 23);
    _expectScreensInSync(tester, d, 'after the ignored taps');
    await tester.pumpAndSettle();
  });
}
