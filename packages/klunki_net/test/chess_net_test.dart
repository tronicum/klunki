// KLD-059 step 3: chess over the network. Open information, so the plain
// protocol (no redaction): the host (White) validates every move, the guest
// (Black) replays the accepted log on its own engine. Promotions travel in
// the move map; the draw offer is three ordinary moves that name their
// player, like a resign (rules version 2, no protocol change).
@Timeout(Duration(seconds: 60))
library;

import 'dart:convert';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:test/test.dart';

import 'support.dart';

const _chess = GameConfig('chess');
const _ping = Duration(milliseconds: 50);
const _timeout = Duration(seconds: 3);

/// Every way a guest can reach a host: direct TCP, WebSocket, relay.
final _transports = <String, Future<(KlunkiHost, KlunkiGuest, Future<void> Function())> Function()>{
  'tcp': () async {
    final host = await startHost(_chess);
    final guest = await joinHost(host.port);
    return (host, guest, () async {});
  },
  'ws': () async {
    final host = await startHost(_chess);
    final guest = await KlunkiGuest.connectWebSocket(webSocketUri(loopback.address, host.wsPort!),
        pingInterval: _ping, timeout: _timeout);
    return (host, guest, () async {});
  },
  'relay': () async {
    final relay = await RelayServer.start(port: 0, address: loopback);
    final url = Uri.parse('ws://${loopback.address}:${relay.port}/relay');
    final host = await KlunkiHost.startRelay(_chess, url, pingInterval: _ping, timeout: _timeout);
    final guest = await KlunkiGuest.connectRelay(url, host.roomCode!, pingInterval: _ping, timeout: _timeout);
    await until(() => host.guestConnected);
    return (host, guest, relay.close);
  },
};

/// Plays [san] alternately from the start: White on the host, Black on the
/// guest, each parsed on the mover's own engine. Every move must be
/// accepted and reach the other side.
Future<void> _play(KlunkiHost host, KlunkiGuest guest, List<String> san) async {
  for (final s in san) {
    final white = host.game.currentPlayer == Player.a;
    final game = (white ? host.game : guest.game) as ChessGame;
    final move = ChessText(game: game).parse(s);
    expect(move, isNotNull, reason: 'parse $s');
    final n = host.moves.length;
    final error = white ? host.submitLocal(move!) : await guest.submit(move!);
    expect(error, isNull, reason: '$s by ${white ? 'host' : 'guest'}');
    await until(() => host.moves.length == n + 1 && guest.moves.length == n + 1);
  }
}

/// Host and guest hold the same log, position and result.
void _expectSame(KlunkiHost host, KlunkiGuest guest) {
  expect(guest.redacted, isFalse);
  expect(jsonEncode(guest.moves), jsonEncode(host.moves));
  final h = host.game as ChessGame, g = guest.game as ChessGame;
  expect(g.fen, h.fen);
  expect(g.sanHistory, h.sanHistory);
  expect(g.drawOfferBy, h.drawOfferBy);
  expect(g.result.code, h.result.code);
  expect(g.result.winner, h.result.winner);
  expect(g.result.draw, h.result.draw);
  expect([for (final e in guest.entries) e.player], [for (final e in host.entries) e.player]);
}

void main() {
  test('chess is a plain game: no redaction, rules version 2 in the fingerprint', () {
    final spec = specById('chess')!;
    expect(spec.hiddenInformation, isFalse);
    expect(spec.redaction, isNull);
    expect(spec.rulesVersion, 2);
    expect(fingerprintOf(_chess)!.rules, 2);
  });

  for (final MapEntry(key: name, value: open) in _transports.entries) {
    group(name, () {
      test("fool's mate: the guest (Black) mates the host, both sides agree", () async {
        final (host, guest, cleanup) = await open();
        expect(host.me, Player.a, reason: 'the host plays White');
        expect(guest.me, Player.b);
        await _play(host, guest, ['f3', 'e5', 'g4', 'Qh4#']);
        _expectSame(host, guest);
        expect(host.game.result.code, GameEndReason.chessCheckmate);
        expect(host.game.result.winner, Player.b);
        expect(host.submitLocal({'action': 'move', 'from': 'a2', 'to': 'a3'}), 'game is over');
        await guest.close();
        await host.close();
        await cleanup();
      });

      test('promotion: the host (White) promotes to a knight, the piece travels in the move map', () async {
        final (host, guest, cleanup) = await open();
        await _play(host, guest, ['a4', 'b5', 'axb5', 'a6', 'bxa6', 'Bb7', 'axb7', 'Nc6']);
        // Without the piece, or with a wrong one: refused, nothing changes.
        expect(host.submitLocal({'action': 'move', 'from': 'b7', 'to': 'a8'}), 'illegal move');
        expect(host.submitLocal({'action': 'move', 'from': 'b7', 'to': 'a8', 'promotion': 'k'}), 'illegal move');
        await _play(host, guest, ['bxa8=N']);
        expect(host.moves.last, {'action': 'move', 'from': 'b7', 'to': 'a8', 'promotion': 'n'});
        expect((guest.game as ChessGame).pieceAt('a8')?.fen, 'N');
        expect((guest.game as ChessGame).sanHistory.last, 'bxa8=N');
        _expectSame(host, guest);
        await guest.close();
        await host.close();
        await cleanup();
      });

      test('promotion: the guest (Black) captures en passant and promotes to a queen', () async {
        final (host, guest, cleanup) = await open();
        await _play(host, guest, ['h3', 'a5', 'h4', 'a4', 'b4', 'axb3', 'Bb2', 'bxa2', 'Bc3']);
        expect(host.entries[5].move, {'action': 'move', 'from': 'a4', 'to': 'b3'});
        expect(await guest.submit({'action': 'move', 'from': 'a2', 'to': 'b1'}), 'illegal move');
        await _play(host, guest, ['axb1=Q']);
        expect(host.moves.last, {'action': 'move', 'from': 'a2', 'to': 'b1', 'promotion': 'q'});
        expect((host.game as ChessGame).pieceAt('b1')?.fen, 'q');
        _expectSame(host, guest);
        await guest.close();
        await host.close();
        await cleanup();
      });

      test('stalemate (the 10-move stalemate from the start position) ends drawn on both sides', () async {
        final (host, guest, cleanup) = await open();
        await _play(host, guest, [
          'e3', 'a5', 'Qh5', 'Ra6', 'Qxa5', 'h5', 'h4', 'Rah6', 'Qxc7', 'f6', //
          'Qxd7+', 'Kf7', 'Qxb7', 'Qd3', 'Qxb8', 'Qh7', 'Qxc8', 'Kg6', 'Qe6',
        ]);
        _expectSame(host, guest);
        expect(guest.game.result.code, GameEndReason.chessStalemate);
        expect(guest.game.result.draw, isTrue);
        await guest.close();
        await host.close();
        await cleanup();
      });

      test('draw offer: declined, then offered again after a move and accepted', () async {
        final (host, guest, cleanup) = await open();
        await _play(host, guest, ['e4', 'e5']);
        // Off turn nobody offers.
        expect(await guest.submit(ChessGame.offerDrawMove(Player.b)), 'illegal move');
        // The host (White, to move) offers; the guest declines.
        expect(host.submitLocal(ChessGame.offerDrawMove(Player.a)), isNull);
        await until(() => guest.moves.length == 3);
        expect((guest.game as ChessGame).drawOfferBy, Player.a);
        expect(guest.entries.last.player, Player.a);
        expect(host.submitLocal({'action': 'move', 'from': 'g1', 'to': 'f3'}), 'illegal move',
            reason: 'the offerer waits for the answer');
        expect(await guest.submit(ChessGame.acceptDrawMove(Player.a)), 'not your turn',
            reason: 'the guest cannot answer for the host');
        expect(await guest.submit(ChessGame.declineDrawMove(Player.b)), isNull);
        await until(() => host.moves.length == 4);
        expect((host.game as ChessGame).drawOfferBy, isNull);
        // No second offer in the same position.
        expect(host.submitLocal(ChessGame.offerDrawMove(Player.a)), 'illegal move');
        await _play(host, guest, ['Nf3']);
        // Now the guest (to move) offers and the host accepts.
        expect(await guest.submit(ChessGame.offerDrawMove(Player.b)), isNull);
        expect(host.submitLocal(ChessGame.acceptDrawMove(Player.a)), isNull);
        await until(() => guest.moves.length == host.moves.length);
        _expectSame(host, guest);
        for (final g in [host.game, guest.game]) {
          expect(g.isOver, isTrue);
          expect(g.result.draw, isTrue);
          expect(g.result.code, GameEndReason.chessDrawAgreed);
        }
        expect(host.moves.sublist(2), [
          {'action': 'offerDraw', 'player': 'a'},
          {'action': 'declineDraw', 'player': 'b'},
          {'action': 'move', 'from': 'g1', 'to': 'f3'},
          {'action': 'offerDraw', 'player': 'b'},
          {'action': 'acceptDraw', 'player': 'a'},
        ]);
        expect(await guest.submit(ChessGame.offerDrawMove(Player.b)), 'game is over');
        await guest.close();
        await host.close();
        await cleanup();
      });

      test('the guest resigns off turn with an open offer; both sides agree', () async {
        final (host, guest, cleanup) = await open();
        await _play(host, guest, ['d4', 'd5']);
        expect(host.submitLocal(ChessGame.offerDrawMove(Player.a)), isNull); // White to move offers
        await until(() => guest.moves.length == 3);
        expect(await guest.submit(Game.resignMove(Player.b)), isNull);
        await until(() => host.moves.length == 4);
        _expectSame(host, guest);
        for (final g in [host.game, guest.game]) {
          expect(g.result.code, GameEndReason.commonResigned);
          expect(g.result.winner, Player.a);
        }
        await guest.close();
        await host.close();
        await cleanup();
      });
    });
  }

  test('a rejoining guest gets the open draw offer back from the snapshot', () async {
    final host = await startHost(_chess);
    final guest = await joinHost(host.port);
    await _play(host, guest, ['e4', 'c5']);
    expect(host.submitLocal(ChessGame.offerDrawMove(Player.a)), isNull); // White to move offers
    await until(() => guest.moves.length == 3);
    final token = guest.token;
    await guest.close();
    await until(() => !host.guestConnected);
    final again = await joinHost(host.port, token: token);
    await until(() => again.moves.length == 3);
    expect((again.game as ChessGame).drawOfferBy, Player.a);
    expect(await again.submit(ChessGame.acceptDrawMove(Player.b)), isNull);
    await until(() => host.game.isOver);
    expect(host.game.result.code, GameEndReason.chessDrawAgreed);
    await again.close();
    await host.close();
  });

  test('a guest with the old chess rules (version 1, no draw offer) is refused', () async {
    final mine = fingerprintOf(_chess)!;
    final old = GameFingerprint(rules: 1, revision: mine.revision, content: mine.content);
    final host = await KlunkiHost.start(_chess,
        address: loopback, name: 'Ada', pingInterval: _ping, timeout: _timeout, compat: BuildCompat());
    final refused = <IncompatiblePeer>[];
    host.events.listen((e) {
      if (e is IncompatiblePeer) refused.add(e);
    });
    final games = Map.of(allFingerprints())..['chess'] = old;
    await expectLater(
        KlunkiGuest.connect(loopback, host.port,
            name: 'Bea', pingInterval: _ping, timeout: _timeout, compat: BuildCompat(build: '', games: games)),
        throwsA(isA<NetException>()
            .having((e) => e.mismatch?.kind, 'kind', Incompatibility.rules)
            .having((e) => e.mismatch?.peer, 'peer', PeerAge.newer)));
    await until(() => refused.isNotEmpty);
    expect(refused.single.mismatch.kind, Incompatibility.rules);
    expect(refused.single.mismatch.peer, PeerAge.older);
    expect(host.guestConnected, isFalse);
    await host.close();
  });
}
