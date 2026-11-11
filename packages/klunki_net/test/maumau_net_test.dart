// KLD-118 network step: Mau-Mau over the network (2 players). Hidden
// information (hands, the draw pile, the seed), so the redacted protocol of
// KLD-064: the host is the referee and holds the deck; the guest gets its
// own hand, the top card and the counts. A card drawn by the other player
// reaches the guest as a count only; the house rules travel in the public
// config (`maumau`) and the guest replays the whole game with them after the
// reveal.
@Timeout(Duration(seconds: 120))
library;

import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:klunki_net/src/secrecy/secrecy.dart';
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

/// Every way a guest reaches a host: direct TCP, WebSocket, relay. The hook
/// is set before the guest joins, so the `welcome` is captured too.
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

final _cardId = RegExp(r'"([cshd](?:7|8|9|10|J|Q|K|A))"');
Set<String> _ids(Object? x) => {for (final m in _cardId.allMatches(jsonEncode(x))) m[1]!};

/// Nothing the guest may not know reached it: the seed is not on the wire,
/// a message names only cards the guest holds, the top card and the card
/// laid by the move; a card the host drew is a count.
void _expectSecret(KlunkiHost host, KlunkiGuest guest, _Wire wire, int seed) {
  final h = host.game as MauMauGame, v = guest.game as MauMauGame;
  expect(guest.redacted, isTrue);
  expect(v, isA<MauMauView>());
  expect(v.seed, 0);
  expect(v.handOf(Player.b), h.handOf(Player.b), reason: 'the guest sees its own hand');
  expect(v.handOf(Player.a), isEmpty, reason: "the host's hand is hidden");
  expect(v.handCount(Player.a), h.handCount(Player.a));
  expect(v.stockCount, h.stockCount);
  expect(v.discardCount, h.discardCount);
  expect(v.topCard, h.topCard);
  expect(v.wish, h.wish);
  expect(v.penalty, h.penalty, reason: 'the 7 chain');
  expect(v.isOver, h.isOver);
  if (!h.isOver) expect(v.currentPlayer, h.currentPlayer);
  for (final (type, m) in wire.messages) {
    if (type == 'reveal') continue;
    if (seed > 99999) expect(jsonEncode(m), isNot(contains('$seed')), reason: 'the seed decides the deal ($type)');
    if (type == 'welcome') {
      expect((m['config'] as Map).containsKey('seed'), isFalse);
      expect(m['seedCommit'], isA<String>());
    }
    final view = m['view'] as Map<String, dynamic>?;
    final move = m['move'] as Map<String, dynamic>?;
    final payload = (m['event'] as Map?)?['payload'] as Map?;
    final mine = m['player'] == 'b';
    final allowed = <String>{
      ..._ids(view?['hand']),
      if (view?['top'] case final String top) top,
      if (view?['drawn'] case final String d) d,
      if (move?['card'] case final String c) c,
      if (payload?['card'] case final String c) c,
      if (mine) ..._ids(payload?['drew']),
    };
    // The log of a welcome holds the past moves: laid cards are public.
    if (type == 'welcome') {
      for (final step in m['log'] as List? ?? const []) {
        final s = step as Map;
        allowed.addAll(_ids((s['move'] as Map)['card']));
        if (s['player'] == 'b') allowed.addAll(_ids((s['event'] as Map)['payload']));
        expect(((s['event'] as Map)['payload'] as Map?)?['fits'], s['player'] == 'b' ? anything : isNull);
      }
    }
    expect(_ids(m).difference(allowed), isEmpty, reason: '$type #${m['index']}: $m');
    if (!mine && payload != null) {
      expect(payload.containsKey('drew'), isFalse, reason: 'the host\'s draw is a count');
      expect(payload.containsKey('fits'), isFalse, reason: 'whether the host\'s card fits is the host\'s secret');
    }
    expect(m.containsKey('commit'), isFalse, reason: 'Mau-Mau moves hold no secret; the seed is committed');
  }
}

/// One random legal move for whoever is to move; a "Mau!" is sometimes
/// forgotten (the engine then deals the penalty card).
Future<void> _step(KlunkiHost host, KlunkiGuest guest, Random rng, Map<String, int> seen) async {
  final hostTurn = host.game.currentPlayer == host.me;
  final game = (hostTurn ? host.game : guest.game) as MauMauGame;
  final legal = game.legalMoves;
  expect(legal, isNotEmpty);
  // Lay a card most of the time.
  final plays = [for (final m in legal) if (m['action'] == 'play') m];
  var move = Map<String, dynamic>.of(plays.isNotEmpty && rng.nextInt(5) > 0
      ? plays[rng.nextInt(plays.length)]
      : legal[rng.nextInt(legal.length)]);
  if (move['mau'] == true && rng.nextInt(3) == 0) {
    move = Map.of(move)..remove('mau');
    seen['forgot'] = (seen['forgot'] ?? 0) + 1;
  }
  final card = MauMauCard.byId('${move['card']}');
  if (card?.rank == MauMauRank.seven && game.penalty > 0) seen['stacked'] = (seen['stacked'] ?? 0) + 1;
  if (move['action'] == 'draw') seen[hostTurn ? 'hostDraw' : 'guestDraw'] = (seen[hostTurn ? 'hostDraw' : 'guestDraw'] ?? 0) + 1;
  final n = host.moves.length;
  if (hostTurn) {
    expect(host.submitLocal(move), isNull, reason: '$move');
  } else {
    expect(await guest.submit(move), isNull, reason: '$move');
  }
  await until(() => host.moves.length == n + 1 && guest.moves.length == n + 1);
}

Future<void> _expectVerified(KlunkiHost host, KlunkiGuest guest) async {
  expect(guest.game.isOver, isTrue);
  expect(guest.game.result.winner, host.game.result.winner);
  expect(guest.game.result.code, GameEndReason.maumauEmptyHand);
  await until(() => guest.verification != Verification.pending);
  expect(guest.verificationError, isNull);
  expect(guest.verification, Verification.verified);
}

void main() {
  test('Mau-Mau is redacted with a secret seed and plays over the network', () {
    final spec = specById('maumau')!;
    expect(spec.redaction, isA<MauMauRedaction>());
    expect(spec.redaction!.secretSeed, isTrue);
    expect(spec.networkPlay, isTrue);
  });

  for (final (name, rules) in [
    ('default rules', const MauMauRules()),
    ('every house rule on', const MauMauRules(jackOnJack: true)),
    ('no 7, no 8, no ace, no "Mau!", drawing always allowed',
        const MauMauRules(sevenDraws: false, eightSkips: false, aceAgain: false, mauCall: false, mustPlay: false)),
    ('7s without stacking', const MauMauRules(stackSevens: false)),
  ]) {
    for (final MapEntry(key: transport, value: setup) in _transports.entries) {
      test('over $transport, $name: no hidden card reaches the guest; the guest verifies the game', () async {
        // Two seeds per case: different deals, different moves.
        for (final seed in [424242, 777001]) {
          final config = GameConfig('maumau', seed: seed, mauMau: rules);
          final (host, guest, wire, close) = await setup(config);
          expect(guest.config, GameConfig('maumau', mauMau: rules), reason: 'the rules travel, the seed does not');
          final rng = Random(seed ^ transport.hashCode);
          final seen = <String, int>{};
          _expectSecret(host, guest, wire, seed);
          var steps = 0;
          while (!host.game.isOver) {
            expect(++steps, lessThan(3000), reason: 'the game should end');
            await _step(host, guest, rng, seen);
            _expectSecret(host, guest, wire, seed);
          }
          await _expectVerified(host, guest);
          final reveal = wire.messages.where((m) => m.$1 == 'reveal').single.$2;
          expect(reveal['seed'], seed);
          expect(seen['hostDraw'] ?? 0, greaterThan(0), reason: '$seen');
          if (rules.mauCall) expect(host.game.history.any((m) => m['mau'] == true), isTrue, reason: '$seen');
          await guest.close();
          await host.close();
          await close();
        }
      });
    }
  }

  test('a forgotten "Mau!" and a stacked 7 chain reach the guest as counts and verify', () async {
    // Search a seed and moves where both happen (deterministic per seed).
    for (var seed = 900001; seed < 900060; seed++) {
      final config = GameConfig('maumau', seed: seed);
      final host = await startHost(config);
      final wire = _Wire()..attach(host);
      final guest = await joinHost(host.port);
      final rng = Random(seed);
      final seen = <String, int>{};
      while (!host.game.isOver) {
        await _step(host, guest, rng, seen);
        _expectSecret(host, guest, wire, seed);
      }
      await _expectVerified(host, guest);
      final forgot = host.moves.indexed.where((e) => e.$2['action'] == 'play' && e.$2['mau'] == null);
      final hostForgot = [
        for (final (i, _) in forgot)
          if (wire.messages.any((m) =>
              m.$1 == 'accepted' &&
              m.$2['index'] == i &&
              m.$2['player'] == 'a' &&
              ((m.$2['event'] as Map)['payload'] as Map)['forgotMau'] == true))
            i
      ];
      await guest.close();
      await host.close();
      if (hostForgot.isNotEmpty && (seen['stacked'] ?? 0) > 0) {
        // The host's penalty card arrived as a count.
        final m = wire.messages.firstWhere((m) => m.$1 == 'accepted' && m.$2['index'] == hostForgot.first).$2;
        final payload = (m['event'] as Map)['payload'] as Map;
        expect(payload['count'], 1);
        expect(payload.containsKey('drew'), isFalse);
        return;
      }
    }
    fail('no seed with a forgotten "Mau!" by the host and a stacked 7');
  });

  test('a guest that rejoins mid-game gets its hand back and still verifies', () async {
    const config = GameConfig('maumau', seed: 5150, mauMau: MauMauRules(jackOnJack: true));
    final host = await startHost(config);
    addTearDown(host.close);
    final proxy = await Proxy.start(host.port);
    addTearDown(proxy.close);
    final guest = await KlunkiGuest.connect(loopback, proxy.port, name: 'Ben', pingInterval: _ping, timeout: _timeout);
    addTearDown(guest.close);
    final rng = Random(3);
    final seen = <String, int>{};
    for (var i = 0; i < 12 && !host.game.isOver; i++) {
      await _step(host, guest, rng, seen);
    }
    proxy.cut();
    await until(() => !host.guestConnected && !guest.connected);
    // The host plays on while Ben is away (until it is Ben's turn).
    while (!host.game.isOver && host.game.currentPlayer == host.me) {
      final legal = (host.game as MauMauGame).legalMoves;
      expect(host.submitLocal(legal[rng.nextInt(legal.length)]), isNull);
    }
    await guest.reconnect();
    expect(guest.moves.length, host.moves.length);
    expect((guest.game as MauMauGame).handOf(Player.b), (host.game as MauMauGame).handOf(Player.b));
    expect(guest.config.mauMau.jackOnJack, isTrue);
    while (!host.game.isOver) {
      await _step(host, guest, rng, seen);
    }
    await _expectVerified(host, guest);
  });

  test('the guest replays with the whole public config: a host that lies about a house rule is caught', () {
    // The guest's own check, without sockets: a game played with "Bube auf
    // Bube" must not verify as one without it, and vice versa.
    const rules = MauMauRules(jackOnJack: true);
    final game = MauMauGame(seed: 9, rules: rules);
    const r = MauMauRedaction();
    final start = viewHash(r.view(game, Player.b));
    final steps = <RedactedStep>[];
    final rng = Random(1);
    while (!game.isOver) {
      final legal = game.legalMoves;
      final move = legal[rng.nextInt(legal.length)];
      final mover = game.currentPlayer;
      final e = game.applyMove(Map.of(move))!;
      final s = r.step(game, move, mover, e, Player.b);
      steps.add(RedactedStep(mover, s['move'] as Map<String, dynamic>, s['event'] as Map<String, dynamic>,
          viewHash(s['view'] as Map<String, dynamic>), null));
    }
    const salt = '00112233445566778899aabbccddeeff';
    final commit = commitment(salt, 'seed', 9);
    String? check(GameConfig c) => verifyRedactedGame(
        config: c,
        gameId: c.gameId,
        me: Player.b,
        seed: 9,
        seedSalt: salt,
        seedCommit: commit,
        startViewHash: start,
        steps: steps,
        secrets: const {});
    expect(check(const GameConfig('maumau', mauMau: rules)), isNull);
    expect(check(const GameConfig('maumau')), isNotNull, reason: 'the view names the rules');
  });
}
