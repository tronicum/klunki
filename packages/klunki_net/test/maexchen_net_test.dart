import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:test/test.dart';

import 'support.dart';

const _ping = Duration(milliseconds: 50);
const _timeout = Duration(seconds: 3);

/// Every message the host sends to the guest, captured through the test hook.
class _Wire {
  final List<(String, Map<String, dynamic>)> messages = [];
  void attach(KlunkiHost host) => host.debugRewriteOutgoing = (type, fields) {
        messages.add((type, jsonDecode(jsonEncode(fields)) as Map<String, dynamic>));
        return fields;
      };
}

typedef _Setup = Future<(KlunkiHost, KlunkiGuest, _Wire, Future<void> Function())> Function(GameConfig config);

/// Every way a guest reaches a host (KLD-121 network step): TCP, WebSocket,
/// relay; the hook is set before the guest joins.
final _transports = <String, _Setup>{
  'tcp': (config) async {
    final host = await startHost(config);
    final wire = _Wire()..attach(host);
    final guest = await KlunkiGuest.connect(loopback, host.port, name: 'Ben', pingInterval: _ping, timeout: _timeout);
    return (host, guest, wire, () async {});
  },
  'ws': (config) async {
    final host = await startHost(config);
    final wire = _Wire()..attach(host);
    final guest = await KlunkiGuest.connectWebSocket(webSocketUri(loopback.address, host.wsPort!),
        name: 'Ben', pingInterval: _ping, timeout: _timeout);
    return (host, guest, wire, () async {});
  },
  'relay': (config) async {
    final relay = await RelayServer.start(port: 0, address: loopback);
    final url = Uri.parse('ws://${loopback.address}:${relay.port}/relay');
    final host = await KlunkiHost.startRelay(config, url, name: 'Anna', pingInterval: _ping, timeout: _timeout);
    final wire = _Wire()..attach(host);
    final guest =
        await KlunkiGuest.connectRelay(url, host.roomCode!, name: 'Ben', pingInterval: _ping, timeout: _timeout);
    await until(() => host.guestConnected);
    return (host, guest, wire, relay.close);
  },
};

/// No die of the host's reached the guest before a doubt lifted the cup:
/// a view holds dice only while the guest itself rolled, a host roll
/// arrives as `{rolled: true}`, and only a doubt names dice in its event.
void _expectSecret(KlunkiHost host, KlunkiGuest guest, _Wire wire, int seed) {
  final h = host.game as MaexchenGame, g = guest.game as MaexchenGame;
  expect(g, isA<MaexchenView>());
  expect(g.dice, h.roller == Player.b ? h.dice : isNull);
  expect(g.lives, h.lives);
  expect(g.announced, h.announced);
  expect(g.phase, h.phase);
  for (final (type, m) in wire.messages) {
    if (type == 'reveal') continue;
    if (seed > 99999) expect(jsonEncode(m), isNot(contains('$seed')), reason: 'the seed decides the dice');
    if (type == 'welcome') {
      expect((m['config'] as Map).containsKey('seed'), isFalse);
      expect(m['seedCommit'], isA<String>());
    }
    final views = [
      if (m['view'] case final Map v) v,
    ];
    for (final v in views) {
      expect(v['viewer'], 'b');
      if (v.containsKey('dice')) expect(v['roller'], 1, reason: 'only the guest\'s own roll');
      final last = v['last'] as Map?;
      if (last != null && last['dice'] != null) expect(last['gaveUp'], isNot(true));
    }
    if (type == 'accepted') {
      final payload = (m['event'] as Map)['payload'];
      final action = (m['move'] as Map)['action'];
      if (m['player'] == 'a' && action == 'roll') expect(payload, {'rolled': true});
      if (payload is Map && payload.containsKey('dice')) {
        expect(action == 'doubt' || (action == 'roll' && m['player'] == 'b'), isTrue, reason: '$m');
      }
    }
    expect(m.containsKey('commit'), isFalse, reason: 'no move holds a secret; the seed is committed');
  }
}

/// KLD-121: Mäxchen over the network (2 players; the app offers it since
/// the network step, 3–4 stay on one device). The guest never sees the host's dice before a doubt
/// and verifies the whole game after the reveal, also with non-default
/// lives and house rule.
void main() {
  test('5 lives, "Mäxchen doppelt" off: the guest sees no foreign dice and verifies the game', () async {
    const config = GameConfig('maexchen', seed: 21, lives: 5, maexchenDouble: false);
    final host = await startHost(config);
    final guest = await joinHost(host.port);
    expect(guest.config, const GameConfig('maexchen', lives: 5, maexchenDouble: false), reason: 'seed stays secret');
    final rng = Random(4);
    var steps = 0;
    while (!host.game.isOver) {
      expect(++steps, lessThan(3000));
      final h = host.game as MaexchenGame, g = guest.game as MaexchenGame;
      // Only the roller's own view holds the dice.
      expect(g.dice, h.roller == Player.b ? h.dice : isNull);
      expect(g.lives, h.lives);
      if (h.currentPlayer == host.me) {
        final legal = h.legalMoves;
        expect(host.submitLocal(legal[rng.nextInt(legal.length)]), isNull);
        final n = host.moves.length;
        await until(() => guest.moves.length == n);
      } else {
        final legal = g.legalMoves;
        expect(await guest.submit(legal[rng.nextInt(legal.length)]), isNull);
      }
    }
    expect((host.game as MaexchenGame).startLives, 5);
    await until(() => guest.verification != Verification.pending);
    expect(guest.verificationError, isNull);
    expect(guest.verification, Verification.verified);
    expect(guest.game.result.winner, host.game.result.winner);
    await guest.close();
    await host.close();
  });

  test('"Unbegrenzte Leben": ending needs the other player (declined: the game goes on; agreed: over on both); '
      'the guest verifies it', () async {
    const config = GameConfig('maexchen', seed: 8, maexchenUnlimited: true);
    final host = await startHost(config);
    final guest = await joinHost(host.port);
    expect(guest.config.maexchenUnlimited, isTrue);
    final rng = Random(2);
    for (var steps = 0; steps < 120; steps++) {
      final h = host.game as MaexchenGame, g = guest.game as MaexchenGame;
      expect(g.lost, h.lost);
      expect(g.unlimitedLives, isTrue);
      if (h.currentPlayer == host.me) {
        final legal = h.legalMoves;
        expect(host.submitLocal(legal[rng.nextInt(legal.length)]), isNull);
        final n = host.moves.length;
        await until(() => guest.moves.length == n);
      } else {
        final legal = g.legalMoves;
        expect(await guest.submit(legal[rng.nextInt(legal.length)]), isNull);
      }
    }
    expect(host.game.isOver, isFalse, reason: 'nobody drops out');
    // KLD-121 network decisions: "Spiel beenden" needs the other player.
    // The plain `end` of one device is refused from the guest.
    expect(await guest.submit(MaexchenGame.endMove), isNotNull);
    expect(host.game.isOver, isFalse);
    // The guest asks (whoever is to move), the host declines: the game goes on.
    final h = host.game as MaexchenGame;
    expect(await guest.submit(MaexchenGame.endRequestMove(Player.b)), isNull);
    await until(() => (host.game as MaexchenGame).endRequestBy == Player.b);
    expect((guest.game as MaexchenGame).endRequestBy, Player.b, reason: 'the view carries the request');
    expect(host.submitLocal(MaexchenGame.endAnswerMove(Player.a, agree: false)), isNull);
    var n = host.moves.length;
    await until(() => guest.moves.length == n);
    expect(guest.entries.last.event!.payload, {'endRefused': 'a'});
    expect((guest.game as MaexchenGame).endRequestBy, isNull);
    expect(host.game.isOver, isFalse);
    expect(guest.game.isOver, isFalse);
    // Play on: one move by whoever is to move.
    if (h.currentPlayer == host.me) {
      expect(host.submitLocal(h.legalMoves.first), isNull);
    } else {
      expect(await guest.submit((guest.game as MaexchenGame).legalMoves.first), isNull);
    }
    n = host.moves.length;
    await until(() => guest.moves.length == n);
    // The host asks, the guest agrees: over on both devices.
    expect(host.submitLocal(MaexchenGame.endRequestMove(Player.a)), isNull);
    n = host.moves.length;
    await until(() => guest.moves.length == n && (guest.game as MaexchenGame).endRequestBy == Player.a);
    expect(host.game.isOver, isFalse);
    expect(await guest.submit(MaexchenGame.endAnswerMove(Player.b, agree: true)), isNull);
    await until(() => guest.game.isOver);
    expect(host.game.result.code, GameEndReason.maexchenEnded);
    await until(() => guest.verification != Verification.pending);
    expect(guest.verificationError, isNull);
    expect(guest.verification, Verification.verified);
    expect(guest.game.result.winner, host.game.result.winner);
    await guest.close();
    await host.close();
  });

  for (final (name, config) in [
    ('5 lives, "Mäxchen doppelt" off', const GameConfig('maexchen', seed: 4242001, lives: 5, maexchenDouble: false)),
    ('default', const GameConfig('maexchen', seed: 4242002)),
    ('"Unbegrenzte Leben"', const GameConfig('maexchen', seed: 4242003, maexchenUnlimited: true)),
  ]) {
    for (final MapEntry(key: transport, value: setup) in _transports.entries) {
      test('over $transport, $name: no host die before a doubt, the guest verifies the game', () async {
        final (host, guest, wire, close) = await setup(config);
        expect(guest.config, config.copyWith(seed: 0), reason: 'the options travel, the seed does not');
        final rng = Random(config.seed ^ transport.hashCode);
        final seen = <String>{};
        _expectSecret(host, guest, wire, config.seed);
        var steps = 0;
        while (!host.game.isOver) {
          expect(++steps, lessThan(3000));
          final h = host.game as MaexchenGame;
          var hostTurn = h.currentPlayer == host.me;
          final legal = (hostTurn ? h : guest.game as MaexchenGame).legalMoves;
          var move = legal[rng.nextInt(legal.length)];
          // "Unbegrenzte Leben": after a while the player to move asks to
          // end, the other one agrees (KLD-121 network decisions).
          if (config.maexchenUnlimited && steps > 150) {
            final asker = h.endRequestBy;
            if (asker == null) {
              move = MaexchenGame.endRequestMove(h.currentPlayer);
            } else {
              final other = asker == Player.a ? Player.b : Player.a;
              move = MaexchenGame.endAnswerMove(other, agree: true);
              hostTurn = other == host.me;
            }
          }
          seen.add('${move['action']}');
          final n = host.moves.length;
          if (hostTurn) {
            expect(host.submitLocal(move), isNull);
          } else {
            expect(await guest.submit(move), isNull);
          }
          await until(() => host.moves.length == n + 1 && guest.moves.length == n + 1);
          _expectSecret(host, guest, wire, config.seed);
        }
        expect(seen, containsAll(['roll', 'announce', 'believe', 'doubt']));
        await until(() => guest.verification != Verification.pending);
        expect(guest.verificationError, isNull);
        expect(guest.verification, Verification.verified);
        expect(guest.game.result.winner, host.game.result.winner);
        expect(wire.messages.where((m) => m.$1 == 'reveal').single.$2['seed'], config.seed);
        await guest.close();
        await host.close();
        await close();
      });
    }
  }
}
