// KLD-120: the phone locks during a network game. The game session tells
// the transport about the app lifecycle; back in the foreground the guest
// reconnects by itself ("Verbindung wird wiederhergestellt …", no button),
// and the screen does not lock by itself while the game runs.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/screen_awake.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import '../../support/test_run.dart';

final _loopback = InternetAddress.loopbackIPv4;
const _ping = Duration(milliseconds: 100);
const _timeout = Duration(seconds: 1);

/// A TCP pass-through on a fixed port that can stop listening (the host's
/// phone unreachable) and listen again.
class _Proxy {
  ServerSocket? _server;
  final int target;
  final List<Socket> _sockets = [];
  int port = 0;
  _Proxy(this.target);

  Future<void> up() async {
    final server = _server = await ServerSocket.bind(_loopback, port);
    port = server.port;
    server.listen((client) async {
      final upstream = await Socket.connect(_loopback, target);
      _sockets.addAll([client, upstream]);
      for (final s in [client, upstream]) {
        s.done.catchError((_) {});
      }
      client.listen(upstream.add, onDone: upstream.destroy, onError: (_) => upstream.destroy());
      upstream.listen(client.add, onDone: client.destroy, onError: (_) => client.destroy());
    });
  }

  Future<void> down() async {
    for (final s in _sockets) {
      s.destroy();
    }
    _sockets.clear();
    await _server?.close();
    _server = null;
  }
}

/// Pumps with real time in between until [condition] holds.
Future<void> _until(WidgetTester tester, bool Function() condition, String what) async {
  final guard = testRunGuard(tester);
  final sw = Stopwatch()..start();
  for (var polls = 0; !condition(); polls++) {
    guard();
    if (sw.elapsed > const Duration(seconds: 15) && polls >= 200) fail('$what: not reached');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

void main() {
  testWidgets('locked and back: the guest reconnects by itself; the screen stays on while the game runs',
      (tester) async {
    ScreenAwake.debugCalls.clear();
    final (host, proxy, guest) = (await tester.runAsync(() async {
      final host = await NetworkTransport.host(const GameConfig('connect4'),
          name: 'Ada', address: _loopback, wsPort: null, pingInterval: _ping, timeout: _timeout);
      final proxy = _Proxy(host.port!);
      await proxy.up();
      final guest =
          await NetworkTransport.join(_loopback, proxy.port, name: 'Bea', pingInterval: _ping, timeout: _timeout);
      return (host, proxy, guest);
    }))!;
    // As in the other network widget tests: unmount, dispose, then let the
    // sockets close in real time (awaiting the closes here can hang).
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      guest.dispose();
      host.dispose();
      await tester.runAsync(proxy.down);
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();
      }
    });
    await tester.pumpWidget(localizedApp(NetworkGameSession(transport: guest)));
    await tester.pump();
    expect(ScreenAwake.debugCalls, [true]);
    expect(find.byKey(const Key('net-banner')), findsNothing);

    // The phone locks; meanwhile the host cannot be reached.
    // The lifecycle callbacks run in the real zone, like in the app (the
    // sockets and the retry timers live there).
    await tester.runAsync(() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await proxy.down();
      await Future<void>.delayed(_timeout);
    });
    // Unlocked: the guest tries by itself, no button to tap.
    await tester.runAsync(() async => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    await _until(tester, () => guest.connection.value == NetConnectionState.reconnecting, 'reconnecting');
    await tester.pump();
    expect(find.text('Verbindung wird wiederhergestellt …'), findsOneWidget);
    expect(find.byKey(const Key('net-reconnect')), findsNothing);

    await tester.runAsync(proxy.up);
    await _until(tester, () => guest.connection.value == NetConnectionState.connected, 'back');
    await tester.pump();
    expect(find.byKey(const Key('net-banner')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    expect(ScreenAwake.debugCalls, [true, false]);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
