// App-level e2e (KLD-037b), controller layer: an "iOS" app stack
// (GameController + NetworkTransport.host) and an "Android" app stack
// (GameController + NetworkTransport.join) play the scripted 33-move Mühle
// game over TCP on 127.0.0.1, through a seeded latency proxy (5–20 ms per
// chunk, like local Wi-Fi).
//
//   cd klunki && flutter test test/e2e
//   KLUNKI_E2E_VERBOSE=1 flutter test test/e2e    # narrated transcript
//
// The widget-level twin (both MuehleScreens, played by taps) is
// muehle_screens_e2e_test.dart.
@Timeout(Duration(seconds: 30))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki_engine/klunki_engine.dart';

import 'e2e_support.dart';
import 'muehle_script.dart';

class _Match {
  final AppStack ios, android;
  final WifiProxy proxy;
  int played = 0;
  int iosNotified = 0, androidNotified = 0;

  _Match(this.ios, this.android, this.proxy) {
    ios.controller.addListener(() => iosNotified++);
    android.controller.addListener(() => androidNotified++);
  }

  static Future<_Match> start({required int seed}) async {
    final ios = await AppStack.host();
    final proxy = await WifiProxy.start(ios.transport.port!, seed: seed);
    final android = await AppStack.join(proxy.port);
    await until(() => ios.online, what: 'host sees the guest');
    expect(ios.transport.me, Player.a, reason: 'iOS plays X');
    expect(android.transport.me, Player.b, reason: 'Android plays O');
    expect(android.transport.config, muehleConfig);
    expect(ios.transport.peerName, 'Pixel (Android)');
    expect(android.transport.peerName, 'iPad (iOS)');
    return _Match(ios, android, proxy);
  }

  AppStack owner(Player p) => p == Player.a ? ios : android;
  AppStack other(AppStack s) => identical(s, ios) ? android : ios;

  void log(String line) {
    if (verbose) print(line); // ignore: avoid_print
  }

  /// Plays the next scripted move from the device that owns the side to
  /// move; first proves the other device's submit is refused and changes
  /// nothing. With [peerOnline] false only the host plays and is checked.
  Future<void> step({bool peerOnline = true}) async {
    final s = muehleScript[played];
    final mover = owner(ios.game.currentPlayer);
    final peer = other(mover);
    expect(mover.controller.canAct, isTrue, reason: '${mover.name} may act at $s');

    if (peerOnline) {
      expect(peer.controller.canAct, isFalse, reason: '${peer.name} may not act at $s');
      final iosBefore = ios.state, androidBefore = android.state;
      final refused = await peer.controller.submit(s.move);
      expect(refused.reason, RejectReason.notYourTurn, reason: '${peer.name} out of turn at $s');
      expect(ios.state, iosBefore, reason: 'refused submit changed nothing on iOS at $s');
      expect(android.state, androidBefore, reason: 'refused submit changed nothing on Android at $s');
    }

    final r = await mover.controller.submit(s.move);
    expect(r.isAccepted, isTrue, reason: '${mover.name} plays $s: $r');
    expect(r.accepted!.index, s.index);
    expect(mover.controller.lastEvent, same(r.event));
    if (peerOnline) {
      await until(() => peer.moveCount == s.index + 1, what: '${peer.name} receives $s');
      expectInSync(ios, android, 'after $s');
    } else {
      expect(mover, same(ios), reason: 'only the host plays while the guest is away');
      expect(peer.moveCount, s.index, reason: 'the offline guest did not see $s');
    }
    log('[${mover.name} → ${peerOnline ? peer.name : '(offline)'}] $s');
    played++;
  }

  Future<void> playUntil([int count = muehleScriptLength]) async {
    while (played < count) {
      await step();
    }
  }

  void expectFinished() {
    expectInSync(ios, android, 'at the end');
    for (final d in [ios, android]) {
      expect(d.moveCount, muehleScriptLength, reason: d.name);
      expect([for (final m in d.controller.moves) m.move], [for (final s in muehleScript) s.move], reason: d.name);
      expect(d.game.isOver, isTrue, reason: d.name);
      expect(d.game.result.winner, muehleScriptWinner, reason: '${d.name}: O wins');
      expect(d.game.result.draw, isFalse);
      expect(d.game.result.reason, muehleScriptReason);
      expect(d.controller.lastEvent!.winner, muehleScriptWinner);
    }
    log('[end] O wins; ${proxy.chunks} chunks crossed the simulated Wi-Fi in ${proxy.connections} connection(s)');
  }

  Future<void> close() async {
    await android.close();
    await proxy.close();
    await ios.close();
  }
}

void main() {
  _Match? match;
  tearDown(() async {
    await match?.close();
    match = null;
  });

  test('iOS hosts, Android joins over a latency proxy: the scripted game ends identically', () async {
    final m = match = await _Match.start(seed: 2024);
    await m.playUntil();
    m.expectFinished();
    expect(m.iosNotified, muehleScriptLength, reason: 'one notification per accepted move');
    expect(m.androidNotified, muehleScriptLength, reason: 'one notification per accepted move');
    for (final d in [m.ios, m.android]) {
      expect((await d.controller.submit(const {'action': 'move', 'from': 0, 'to': 1})).reason, RejectReason.gameOver);
    }
    expect(m.ios.moveCount, muehleScriptLength);
    expect(m.proxy.connections, 1);
  });

  test('Wi-Fi drop mid-game: the host plays on, Android reconnects, resyncs and finishes', () async {
    final m = match = await _Match.start(seed: 7);
    final ios = m.ios, android = m.android;
    final states = <NetConnectionState>[];
    android.transport.connectionChanges.listen(states.add);
    final seen = <int>[];
    android.transport.accepted.listen((a) => seen.add(a.index));

    await m.playUntil(21); // X to move: "21-9"
    expect(ios.controller.canAct, isTrue);
    final before = android.game;

    m.proxy.cut();
    m.log('[net] -- Wi-Fi drop: proxy cut, no bye --');
    await until(() => !ios.online && !android.online, what: 'both sides notice the drop');
    expect(ios.transport.connection.value, NetConnectionState.peerMissing);
    expect(android.transport.connection.value, NetConnectionState.peerMissing);

    await m.step(peerOnline: false); // #21 X 21-9 while Android is offline
    expect(android.moveCount, 21);
    expect(android.controller.canAct, isFalse, reason: 'stale view: still X to move');
    expect((await android.controller.submit(muehleScript[22].move)).reason, RejectReason.notYourTurn);
    expect(ios.moveCount, 22, reason: 'nothing sneaked through');

    await android.transport.reconnect();
    await until(() => ios.online, what: 'host sees the guest again');
    expect(android.online, isTrue);
    expect(android.game, isNot(same(before)), reason: 'replayed instance after Resynced');
    expectInSync(ios, android, 'after reconnect');
    expect(android.controller.lastEvent, same(android.controller.moves.last.event));
    expect(android.controller.canAct, isTrue, reason: 'O to move: "15-16"');
    m.log('[net] ${android.name} reconnected, resynced to ${android.moveCount} moves');

    await m.playUntil();
    m.expectFinished();
    await pumpEventQueue(); // connectionChanges is asynchronous
    expect(states, [NetConnectionState.peerMissing, NetConnectionState.reconnecting, NetConnectionState.connected]);
    expect(seen, List.generate(muehleScriptLength, (i) => i), reason: 'every move emitted once, in order');
    expect(m.proxy.connections, 2);
  });

  test('Android app restart: a fresh transport rejoins with the token and finishes', () async {
    final m = match = await _Match.start(seed: 99);
    final ios = m.ios, android = m.android;

    await m.playUntil(13); // O closed 6-11-15 and still owes "x16"
    expect(android.game.pendingRemoval, isTrue);
    expect(android.controller.canAct, isTrue);
    final token = android.transport.token!;

    m.proxy.cut();
    await until(() => !ios.online && !android.online, what: 'both sides notice the drop');
    expect((await android.controller.submit(muehleScript[13].move)).reason, RejectReason.disconnected);
    expect(ios.moveCount, 13);

    await android.replace(await AppStack.joinTransport(m.proxy.port, token: token));
    android.controller.addListener(() => m.androidNotified++);
    await until(() => ios.online, what: 'host sees the rejoined guest');
    expect(android.transport.token, token);
    expect(android.controller.lastEvent, isNull, reason: 'fresh controller');
    expectInSync(ios, android, 'after rejoin');
    expect(android.game.pendingRemoval, isTrue, reason: 'the snapshot restores the owed removal');
    expect(android.controller.canAct, isTrue);

    await m.playUntil();
    m.expectFinished();
    expect(m.proxy.connections, 2);
  });
}
