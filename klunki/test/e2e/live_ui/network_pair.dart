// Two phones side by side for a network game played through the real UI
// (KLD-118 / KLD-121 network step): host Anna (A) and guest Ben (B), each
// in its own NetworkGameSession over real sockets, as in [playNetwork] of
// live_ui_driver.dart, but for games whose screen shows only the latest move
// (Mau-Mau, Mäxchen): the test taps for whoever is on and waits until both
// devices hold the move, checking each screen in between.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_net/klunki_net.dart' show Verification;
import 'package:klunki_net/relay_server.dart';

import '../../l10n/l10n_test_utils.dart';
import '../../support/test_run.dart';
import '../e2e_support.dart';
import 'live_ui_driver.dart';

/// How the guest reaches the host: TCP through the seeded Wi-Fi latency
/// proxy, WebSocket (the browser's way), or a relay room.
enum NetLink { tcp, ws, relay }

class NetPair {
  final NetworkTransport host;
  final NetworkTransport guest;
  final UiDevice hostDevice = UiDevice('host A', scope: const Key('device-host'), me: Player.a);
  final UiDevice guestDevice = UiDevice('guest B', scope: const Key('device-guest'), me: Player.b);
  final WidgetTester tester;
  final void Function() _alive;

  NetPair._(this.tester, this.host, this.guest) : _alive = testRunGuard(tester);

  /// Starts [config] over [link] and shows both devices ([size] each).
  static Future<NetPair> start(WidgetTester tester, GameConfig config,
      {NetLink link = NetLink.tcp, Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = Size(size.width * 2, size.height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (host, guest, close) = (await tester.runAsync(() async {
      switch (link) {
        case NetLink.tcp:
          final h = await NetworkTransport.host(config,
              name: 'Anna', address: loopback, wsPort: null, pingInterval: pingInterval, timeout: widgetNetTimeout);
          final p = await WifiProxy.start(h.port!, seed: config.seed);
          final g = await NetworkTransport.join(loopback, p.port,
              name: 'Ben', pingInterval: pingInterval, timeout: widgetNetTimeout);
          return (h, g, p.close);
        case NetLink.ws:
          final h = await NetworkTransport.host(config,
              name: 'Anna', address: loopback, pingInterval: pingInterval, timeout: widgetNetTimeout);
          final g = await NetworkTransport.joinWebSocket(Uri.parse('ws://${loopback.address}:${h.wsPort}'),
              name: 'Ben', pingInterval: pingInterval, timeout: widgetNetTimeout);
          return (h, g, () async {});
        case NetLink.relay:
          final relay = await RelayServer.start(port: 0, address: loopback);
          final url = Uri.parse('ws://${loopback.address}:${relay.port}/relay');
          final h = await NetworkTransport.hostRelay(config, url,
              name: 'Anna', pingInterval: pingInterval, timeout: widgetNetTimeout);
          final g = await NetworkTransport.joinRelay(url, h.roomCode!,
              name: 'Ben', pingInterval: pingInterval, timeout: widgetNetTimeout);
          return (h, g, relay.close);
      }
    }))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      guest.dispose();
      host.dispose();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await close();
      });
    });
    Widget phone(Key key, NetworkTransport t) => Expanded(
          child: KeyedSubtree(
              key: key, child: localizedApp(NetworkGameSession(transport: t), debugShowCheckedModeBanner: false)),
        );
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [phone(const Key('device-host'), host), phone(const Key('device-guest'), guest)]),
    ));
    final pair = NetPair._(tester, host, guest);
    for (var i = 0; i < 3000 && pair.devices.any((d) => !d.has(find.byType(GameScreen))); i++) {
      await pair.net();
    }
    return pair;
  }

  List<UiDevice> get devices => [hostDevice, guestDevice];

  GameController controllerOf(UiDevice d) => d.controller(tester);
  GameController get hostController => controllerOf(hostDevice);
  GameController get guestController => controllerOf(guestDevice);

  /// The authoritative game (the host's engine).
  Game get engine => host.game;

  /// The device of the player to move.
  UiDevice get onTurn => engine.currentPlayer == Player.a ? hostDevice : guestDevice;

  /// Lets the sockets run, then two frames (the shell sets hints post-frame).
  Future<void> net() async {
    _alive();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
    await tester.pump();
    await tester.pump();
  }

  /// Waits until both devices hold [n] moves (and the frames settled).
  /// Fails only after 2000 rounds *and* a minute of wall clock (a busy
  /// machine runs few rounds per second; KLD-109).
  Future<void> synced(int n, {String why = ''}) async {
    final clock = Stopwatch()..start();
    for (var i = 0; i < 2000 || clock.elapsed < const Duration(minutes: 1); i++) {
      if (host.moves.length == n && guest.moves.length == n) {
        await net();
        return;
      }
      await net();
    }
    fail('devices not in sync at $n moves ($why): host ${host.moves.length}, guest ${guest.moves.length}');
  }

  /// After the game: the guest checked the host's reveal (KLD-064).
  Future<void> expectVerified() async {
    for (var i = 0; i < 3000 && guest.verification.value == Verification.pending; i++) {
      await net();
    }
    expect(guest.verification.value, Verification.verified);
    expect(guestDevice.hasKey(const Key('net-verification-failed')), isFalse);
  }
}
