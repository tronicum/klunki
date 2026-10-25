// End-to-end story: an iPad (iOS) and a Pixel (Android) play Mühle against
// each other over the local network, at the protocol level.
//
//   cd packages/klunki_net && dart test test/e2e_muehle_test.dart
//   KLUNKI_E2E_VERBOSE=1 dart test test/e2e_muehle_test.dart   # narrated
//
// Both "phones" are real KlunkiHost / KlunkiGuest instances in this process,
// talking NDJSON over TCP on 127.0.0.1 through a proxy that adds a seeded
// 5–20 ms delay per chunk (local Wi-Fi). They play the engine's scripted
// 33-move "Zwickmühle" demo (MuehleText.demoScript): X = iOS, O = Android,
// and O wins because X is ground down to 2 pieces. After every accepted move
// both phones must hold the same move log, board, turn and pending removal.
@Timeout(Duration(seconds: 20))
library;

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:test/test.dart';

import 'e2e_support.dart';
import 'support.dart';

void main() {
  late MuehleMatch match;
  tearDown(() => match.close());

  test('iPad (iOS) hosts, Pixel (Android) joins: the Zwickmühle game ends identically', () async {
    match = await MuehleMatch.start();
    expect(match.ios.role, 'host');
    expect(match.android.role, 'guest');

    await match.playUntil();

    match.assertFinished();
  });

  test('(a) Android loses Wi-Fi twice mid-game, rejoins with its token, same ending', () async {
    match = await MuehleMatch.start(seed: 7);
    final ios = match.ios, android = match.android;
    final host = ios.host!;

    // Drop 1: right after O closed the mill 6-11-15 (#12), so the Pixel still
    // owes the removal "x16" when the connection dies.
    await match.playUntil(13);
    expect(android.game.pendingRemoval, isTrue);
    expect(match.nextMover, android);
    final token = android.guest!.token!;
    match.proxy.cut();
    match.log('[net] -- Wi-Fi drop: proxy cut, no bye --');
    await until(() => !host.guestConnected && !android.guest!.connected);
    expect(ios.events.whereType<PeerDisconnected>(), hasLength(1));
    expect(await android.guest!.submit(match.scriptMoves[13]), 'not connected');
    expect(host.moves, hasLength(13), reason: 'nothing sneaked through');

    // The app restarts: a brand-new guest instance rejoins with the token.
    await android.guest!.close();
    android.attach(await KlunkiGuest.connect(loopback, match.proxy.port,
        name: android.name, token: token, pingInterval: pingInterval, timeout: netTimeout));
    await until(() => host.guestConnected);
    expect(ios.events.whereType<PeerConnected>().last.reconnect, isTrue);
    expect(android.guest!.token, token);
    match.assertInSync('after rejoin 1');
    expect(android.game.pendingRemoval, isTrue, reason: 'the snapshot restores the owed removal');
    match.log('[net] ${android.name} rejoined with token ${token.substring(0, 6)}…, '
        'snapshot of ${android.moves.length} moves replayed');

    // Drop 2: in the moving phase, with X to move. The host keeps playing
    // while the Pixel is away; reconnect() then resyncs the missed move.
    await match.playUntil(21);
    expect(match.nextMover, ios);
    match.proxy.cut();
    match.log('[net] -- Wi-Fi drop: proxy cut, no bye --');
    await until(() => !host.guestConnected && !android.guest!.connected);
    await match.step(); // #21 X 21-9 while Android is offline
    expect(android.moves, hasLength(21));
    await android.guest!.reconnect();
    await until(() => host.guestConnected && android.events.whereType<Resynced>().isNotEmpty);
    expect(android.events.whereType<Resynced>().single.moves, 22);
    match.assertInSync('after rejoin 2');
    match.log('[net] ${android.name} reconnected, resynced to ${android.moves.length} moves');

    await match.playUntil();
    match.assertFinished();
    expect(ios.events.whereType<PeerDisconnected>(), hasLength(2));
    expect(ios.events.whereType<PeerConnected>().map((e) => e.reconnect), [false, true, true]);
    expect(match.proxy.connections, 3);
  });

  test('(b) Android tries out-of-turn and illegal moves: rejected, nothing changes', () async {
    match = await MuehleMatch.start(seed: 99);
    final ios = match.ios, android = match.android;
    final guest = android.guest!;
    var rejections = 0;

    Future<void> refused(Map<String, dynamic> move, String reason, String why) async {
      final before = (ios.state, android.state);
      expect(await guest.submit(move), reason, reason: why);
      rejections++;
      await until(() => ios.events.whereType<MoveRejected>().length == rejections);
      expect(ios.events.whereType<MoveRejected>().last.reason, reason);
      expect(android.events.whereType<MoveRejected>().last.reason, reason);
      expect(ios.state, before.$1, reason: 'iOS unchanged after: $why');
      expect(android.state, before.$2, reason: 'Android unchanged after: $why');
      match.assertInSync('after rejected $move');
      match.log('[Android → iOS] rejected ${match.text.format(move).padRight(5)} '
          '"$reason" ($why); state unchanged on both phones');
    }

    await match.playUntil(2); // X to move
    expect(match.nextMover, ios);
    await refused({'action': 'place', 'to': 3}, 'not your turn', 'O places while it is X\'s turn');

    await match.playUntil(3); // O to move; X sits on 21 and 16
    await refused({'action': 'place', 'to': 21}, 'illegal move', 'point 21 is taken');
    await refused({'action': 'place', 'to': 24}, 'illegal move', 'there is no point 24');
    await refused({'action': 'move', 'from': 15, 'to': 11}, 'illegal move', 'O is still placing');

    await match.playUntil(8); // O just closed 1-4-7 and owes a removal
    expect(android.game.pendingRemoval, isTrue);
    await refused({'action': 'place', 'to': 9}, 'illegal move', 'must remove, not place');
    await refused({'action': 'remove', 'at': 4}, 'illegal move', 'cannot remove an own piece');
    await refused({'action': 'remove', 'at': 0}, 'illegal move', 'point 0 is empty');

    await match.playUntil(22); // moving phase, O to move
    expect(android.game.phaseOf(Player.b), MuehlePhase.moving);
    final o = [for (var p = 0; p < 24; p++) if (android.game.board[p] == Player.b) p];
    final far = [for (var p = 0; p < 24; p++) if (android.game.board[p] == null) p]
        .firstWhere((p) => !MuehleGame.adjacency[o.first].contains(p));
    await refused({'action': 'move', 'from': o.first, 'to': far}, 'illegal move', 'not adjacent and O cannot fly yet');
    expect(ios.host!.submitLocal({'action': 'move', 'from': 9, 'to': 0}), 'not your turn',
        reason: 'the host is held to the same rules');
    match.assertInSync('after the host\'s refused move');

    await match.playUntil();
    match.assertFinished();
    await refused({'action': 'move', 'from': 15, 'to': 16}, 'game is over', 'the game has ended');
    expect(ios.host!.submitLocal({'action': 'move', 'from': 0, 'to': 1}), 'game is over');
    expect(ios.moves, hasLength(33));
  });

  test('(c) roles swapped: Pixel (Android) hosts as O, iPad (iOS) joins as X, same ending', () async {
    match = await MuehleMatch.start(androidHosts: true, seed: 11);
    expect(match.android.role, 'host');
    expect(match.ios.role, 'guest');
    expect(match.ios.guest!.hostName, 'Pixel (Android)');

    await match.playUntil();

    match.assertFinished();
  });
}
