// KLD-088 step 4: a table of 3–4 players over the network (Wortgewandt).
// The host is seat 0, up to three guests sit down in join order. Each guest
// gets only its own rack; another seat's exchange reaches it as a count with
// a commitment, revealed and checked at the end. A guest that is away pauses
// everyone. Two-player sessions keep protocol 3 on the wire.
@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:test/test.dart';

import 'support.dart';

const _ping = Duration(milliseconds: 50);
const _timeout = Duration(seconds: 3);

/// The countdown before a full table starts, fast (5 steps of it).
const _tick = Duration(milliseconds: 5);

/// A word list that knows nothing: every placement needs "Trotzdem zulassen".
class _NoWords extends WordValidator {
  @override
  bool isWord(String word) => false;
}

/// Every message the host sent to each table seat.
class _Wire {
  final Map<int, List<(String, Map<String, dynamic>)>> bySeat = {};
  final List<String> leaks = [];

  /// Captures and checks every message as it is sent (the host's game is
  /// then already past the move it reports).
  void attach(KlunkiHost host) => host.debugTableOutgoing = (seat, type, fields) {
        final m = jsonDecode(jsonEncode(fields)) as Map<String, dynamic>;
        bySeat.putIfAbsent(seat, () => []).add((type, m));
        if (type == 'reveal') return;
        final game = host.game as WordTilesGame;
        final view = m['view'];
        if (view is Map<String, dynamic>) {
          if (view['viewerSeat'] != seat) leaks.add('seat $seat got the view of ${view['viewerSeat']}');
          if (jsonEncode(view['rack']) != jsonEncode(game.rackOf(seat))) leaks.add('seat $seat: rack ${view['rack']}');
          if (view['bag'] is! int || (view['racks'] as List).any((r) => r is! int)) leaks.add('seat $seat: bag/racks');
          for (final key in view.keys) {
            if (!_viewKeys.contains(key)) leaks.add('seat $seat: view key $key');
          }
        }
        if (type == 'welcome' && (m['config'] as Map).containsKey('seed')) leaks.add('seat $seat got the seed');
        if (type == 'accepted' || type == 'welcome') {
          final moves = type == 'accepted'
              ? [(m['seat'] as int, m['move'] as Map, m['commit'])]
              : [for (final s in (m['log'] as List).cast<Map>()) (s['seat'] as int, s['move'] as Map, s['commit'])];
          for (final (mover, move, commit) in moves) {
            if (mover != seat && move['action'] == 'exchange') {
              if (move.containsKey('tiles')) leaks.add('seat $seat saw the tiles of seat $mover');
              if (commit is! String) leaks.add('seat $seat: exchange of $mover without commitment');
            }
          }
        }
      };
}

const _viewKeys = {
  'viewer', 'viewerSeat', 'tileSet', 'players', 'check', 'scorelessLimit', 'board', 'rack', 'racks', 'bag', //
  'scores', 'penalties', 'seat', 'scoreless', 'open', 'endPending', 'allowRequest', 'declined', 'turns', 'end', //
  'resigned', 'out', 'jokerSwap', 'rackPenalty',
};

/// A table: the host and its guests (index = seat - 1).
class _Table {
  final KlunkiHost host;
  final List<KlunkiGuest> guests;
  final _Wire wire;
  _Table(this.host, this.guests, this.wire);

  WordTilesGame get game => host.game as WordTilesGame;
  WordTilesGame viewOf(int seat) => (seat == 0 ? host.game : guests[seat - 1].game) as WordTilesGame;

  Future<void> synced() => until(() => guests.every((g) => g.moves.length == host.moves.length));

  /// Plays [move] for [seat] (host or guest); null when accepted.
  Future<String?> play(int seat, Map<String, dynamic> move) async {
    final n = host.moves.length;
    final reason = seat == 0 ? host.submitLocal(move) : await guests[seat - 1].submit(move);
    if (reason == null) {
      expect(host.moves.length, n + 1);
      await synced();
    }
    return reason;
  }

  Future<void> close() async {
    for (final g in guests) {
      await g.close();
    }
    await host.close();
  }
}

/// Starts a table of [players] and lets its guests join, alternating TCP
/// and WebSocket, or all through the relay at [relay].
Future<_Table> _startTable(GameConfig config, {Uri? relay}) async {
  final host = relay != null
      ? await KlunkiHost.startRelay(config, relay,
          name: 'Anna', pingInterval: _ping, timeout: _timeout, countdownTick: _tick)
      : await KlunkiHost.start(config,
          address: loopback, name: 'Anna', pingInterval: _ping, timeout: _timeout, countdownTick: _tick);
  final wire = _Wire()..attach(host);
  const names = ['Ben', 'Cleo', 'Dani'];
  final guests = <KlunkiGuest>[];
  for (var i = 0; i < config.players - 1; i++) {
    guests.add(relay != null
        ? await KlunkiGuest.connectRelay(relay, host.roomCode!, name: names[i], pingInterval: _ping, timeout: _timeout)
        : i.isEven
            ? await KlunkiGuest.connect(loopback, host.port, name: names[i], pingInterval: _ping, timeout: _timeout)
            : await KlunkiGuest.connectWebSocket(webSocketUri(loopback.address, host.wsPort!),
                name: names[i], pingInterval: _ping, timeout: _timeout));
    expect(guests.last.seat, i + 1);
  }
  final table = _Table(host, guests, wire);
  await until(() => host.started && guests.every((g) => g.started));
  return table;
}

/// A relay on loopback; closed after the test.
Future<Uri> _relay() async {
  final relay = await RelayServer.start(port: 0, address: loopback);
  addTearDown(relay.close);
  return Uri.parse('ws://${loopback.address}:${relay.port}/relay');
}

/// Placements that fit the board, whatever the words.
Iterable<List<PlacedTile>> _fits(WordTilesGame g, int seat) sync* {
  final rack = g.rackOf(seat).toSet().toList()..sort();
  PlacedTile tile(int r, int c, String x) => PlacedTile(r, c, x, x == TileSet.blank ? 'E' : null);
  bool ok(List<PlacedTile> t) => g.checkPlacement(WordTilesGame.placeMove(t), checkWords: false).ok;
  if (g.boardEmpty) {
    for (final x in rack) {
      for (final y in rack) {
        final t = [tile(7, 7, x), tile(7, 8, y)];
        if (ok(t)) yield t;
      }
    }
    return;
  }
  for (var i = 0; i < 225; i++) {
    for (final x in rack) {
      final t = [tile(i ~/ 15, i % 15, x)];
      if (ok(t)) yield t;
    }
  }
}

/// A bot that decides from its own view only (a guest knows nothing else).
/// Exchanges now and then (secrets for the others), challenges sometimes,
/// asks for "Trotzdem zulassen" in dictionary mode; passes after [calm]
/// moves so the game ends.
Map<String, dynamic> _bot(WordTilesGame view, int seat, Random rng, {required bool calm}) {
  if (view.allowRequestAnswerer == seat) {
    return rng.nextInt(3) == 0 ? view.declineAllowMoveFor(seat) : view.acceptAllowMoveFor(seat);
  }
  if (view.canChallenge) return rng.nextInt(5) == 0 ? const {'action': 'challenge'} : const {'action': 'accept'};
  if (calm) return const {'action': 'pass'};
  final rack = view.rackOf(seat);
  if (rng.nextInt(5) == 0 && view.canExchange && rack.isNotEmpty) {
    return {'action': 'exchange', 'tiles': rack.take(1 + rng.nextInt(rack.length)).toList()};
  }
  for (final tiles in _fits(view, seat).skip(rng.nextInt(3))) {
    final move = WordTilesGame.placeMove(tiles);
    if (view.check == WordCheck.challenge) return move;
    final unknown = view.unknownWords(move);
    if (unknown.isEmpty) return move;
    if (view.canRequestAllow(unknown)) return view.requestAllowMoveFor(seat, tiles, unknown);
  }
  return const {'action': 'pass'};
}

/// Plays the table's game to its end with [_bot]s; every guest must verify.
Future<void> _playToEnd(_Table t, int seed, {int calmAfter = 40}) async {
  final rng = Random(seed);
  var n = 0;
  while (!t.game.isOver) {
    expect(++n, lessThan(1000), reason: 'the game must end');
    final seat = t.game.actorSeat!;
    final view = t.viewOf(seat);
    expect(view.actorSeat, seat, reason: 'every device agrees whose turn it is');
    final move = _bot(view, seat, rng, calm: n > calmAfter);
    expect(await t.play(seat, move), isNull, reason: 'seat $seat: $move');
    // Everyone else is refused meanwhile ("not your turn").
    final other = (seat + 1 + rng.nextInt(t.host.config.players - 1)) % t.host.config.players;
    if (!t.game.isOver && other != t.game.actorSeat && other != 0) {
      expect(await t.guests[other - 1].submit(const {'action': 'pass'}), 'not your turn');
    }
    for (var s = 1; s < t.host.config.players; s++) {
      final v = t.viewOf(s);
      expect(v.rackOf(s), t.game.rackOf(s));
      for (var o = 0; o < t.host.config.players; o++) {
        if (o != s) expect(v.rackOf(o), isEmpty, reason: 'seat $s sees no rack of seat $o');
        expect(v.rackSizeOf(o), t.game.rackSizeOf(o));
      }
      expect(v.scores, t.game.scores);
      expect(v.bagCount, t.game.bagCount);
    }
    expect(t.wire.leaks, isEmpty);
  }
  for (final g in t.guests) {
    await until(() => g.verification != Verification.pending);
    expect(g.verificationError, isNull, reason: 'seat ${g.seat}');
    expect(g.verification, Verification.verified);
    expect((g.game as SeatGame).seatResult.places, t.game.seatResult.places);
  }
}

void main() {
  tearDown(WordLists.clear);

  for (final players in [3, 4]) {
    test('$players players: lobby, a whole game, every rack stays on its device, every guest verifies', () async {
      final config = GameConfig('wordtiles', seed: 11 + players, players: players);
      final host = await KlunkiHost.start(config,
          address: loopback, name: 'Anna', pingInterval: _ping, timeout: _timeout, countdownTick: _tick);
      final wire = _Wire()..attach(host);
      final lobby = <LobbyChanged>[];
      host.events.listen((e) {
        if (e is LobbyChanged) lobby.add(e);
      });
      expect(host.table, isTrue);
      expect(host.started, isFalse);
      expect(host.seats.first, const TableSeat('Anna', here: true));
      expect(host.seats.skip(1), everyElement(const TableSeat(null)));

      // Ben sits down: seat 1; the host cannot start yet.
      final ben = await KlunkiGuest.connect(loopback, host.port, name: 'Ben', pingInterval: _ping, timeout: _timeout);
      expect(ben.table, isTrue);
      expect(ben.seat, 1);
      expect(ben.config.players, players);
      expect(() => ben.me, returnsNormally, reason: 'seat 1 is B');
      await until(() => ben.seats.length == players);
      expect(ben.started, isFalse);
      expect(ben.seats[0].name, 'Anna');
      expect(ben.seats[1], const TableSeat('Ben', here: true));
      expect(host.submitLocal(const {'action': 'pass'}), 'waiting for players');
      expect(lobby.last.missing, players - 2);

      final guests = [ben];
      const names = ['Ben', 'Cleo', 'Dani'];
      for (var s = 2; s < players; s++) {
        guests.add(await KlunkiGuest.connectWebSocket(webSocketUri(loopback.address, host.wsPort!),
            name: names[s - 1], pingInterval: _ping, timeout: _timeout));
        expect(guests.last.seat, s);
      }
      await until(() => host.started && guests.every((g) => g.started && g.seats.every((s) => s.here)));
      expect([for (final s in ben.seats) s.name], ['Anna', ...names.take(players - 1)]);
      expect(lobby.last.started, isTrue);
      expect(lobby.last.complete, isTrue);
      // The full table counted down 5, 4, 3, 2, 1 before it started.
      expect([for (final e in lobby) if (e.countdown != null) e.countdown], [5, 4, 3, 2, 1]);
      expect(lobby.where((e) => e.countdown != null).every((e) => !e.started && e.complete), isTrue);
      // A latecomer finds the table full.
      await expectLater(KlunkiGuest.connect(loopback, host.port, name: 'Eve', timeout: _timeout),
          throwsA(isA<NetException>()));

      final t = _Table(host, guests, wire);
      addTearDown(t.close);
      // 3 players: to the natural end (the bag empty, someone out); 4: calm
      // down after 40 moves (the scoreless end).
      await _playToEnd(t, players, calmAfter: players == 3 ? 1000 : 40);
      expect(t.game.seatResult.code,
          players == 3 ? GameEndReason.wordtilesPlayedOut.code : GameEndReason.wordtilesScoreless.code);
      // Exchanges happened and were committed to the others, one salt each.
      final exchanges = [
        for (final e in host.entries)
          if (e.move['action'] == 'exchange') e,
      ];
      expect(exchanges, isNotEmpty);
      for (var s = 1; s < players; s++) {
        final reveal = wire.bySeat[s]!.where((m) => m.$1 == 'reveal').single.$2;
        expect(reveal['seed'], config.seed);
        expect([for (final x in reveal['secrets'] as List) (x as Map)['index']],
            [for (final e in exchanges) if (e.seat != s) e.index],
            reason: 'seat $s gets the exchanges of the others revealed, never its own');
      }
      final salts = {
        for (var s = 1; s < players; s++)
          for (final x in wire.bySeat[s]!.where((m) => m.$1 == 'reveal').single.$2['secrets'] as List) (x as Map)['salt'],
      };
      expect(salts.length, (players - 1) * exchanges.length - exchanges.where((e) => e.seat > 0).length,
          reason: 'a fresh salt per viewer');
    });
  }

  test('dictionary mode at a table of 4: "Trotzdem zulassen" is answered by the next seat on its device', () async {
    WordLists.register('de', _NoWords());
    final t = await _startTable(const GameConfig('wordtiles', seed: 5, players: 4, dictionary: true));
    addTearDown(t.close);
    // Anna asks; Ben (seat 1) answers on his device; Cleo cannot.
    final tiles = _fits(t.game, 0).first;
    final unknown = t.game.unknownWords(WordTilesGame.placeMove(tiles));
    expect(await t.play(0, t.game.requestAllowMoveFor(0, tiles, unknown)), isNull);
    expect(t.viewOf(2).allowRequestAnswerer, 1);
    expect(await t.guests[1].submit(t.viewOf(2).acceptAllowMoveFor(2)), 'illegal move');
    expect(await t.guests[1].submit(t.viewOf(2).acceptAllowMoveFor(1)), 'not your turn');
    expect(await t.play(1, t.viewOf(1).acceptAllowMoveFor(1)), isNull);
    expect(t.game.turns.single.allowed, unknown);
    expect(t.viewOf(3).currentSeat, 1);
    await _playToEnd(t, 99, calmAfter: 24);
    expect(t.game.turns.where((x) => x.allowed.isNotEmpty).length, greaterThan(1));
  });

  test('a guest that is away pauses everyone; it rejoins with its token, or the host lets it leave', () async {
    const config = GameConfig('wordtiles', seed: 3, players: 3);
    final host = await KlunkiHost.start(config,
        address: loopback, name: 'Anna', pingInterval: _ping, timeout: _timeout, countdownTick: _tick);
    final proxy = await Proxy.start(host.port);
    addTearDown(proxy.close);
    final ben = await KlunkiGuest.connect(loopback, host.port, name: 'Ben', pingInterval: _ping, timeout: _timeout);
    final cleo = await KlunkiGuest.connect(loopback, proxy.port, name: 'Cleo', pingInterval: _ping, timeout: _timeout);
    final t = _Table(host, [ben, cleo], _Wire()..attach(host));
    addTearDown(t.close);
    await until(() => host.started);
    expect(await t.play(0, WordTilesGame.placeMove(_fits(t.game, 0).first)), isNull);

    proxy.cut();
    await until(() => host.paused && ben.paused);
    expect(ben.seats[2], const TableSeat('Cleo'));
    expect(host.guestConnected, isFalse);
    // Nobody moves while Cleo is away: not Ben (on turn), not the host.
    expect(await ben.submit(const {'action': 'accept'}), 'waiting for players');
    expect(host.submitLocal(WordTilesGame.resignSeatMove(0)), 'waiting for players');
    // Someone else cannot take her seat.
    await expectLater(KlunkiGuest.connect(loopback, host.port, name: 'Eve', timeout: _timeout),
        throwsA(isA<NetException>()));

    // Cleo comes back (the app keeps the guest and reconnects).
    await cleo.reconnect();
    expect(cleo.seat, 2);
    await until(() => !host.paused && !ben.paused);
    expect(await t.play(1, const {'action': 'accept'}), isNull);
    expect(cleo.moves.length, host.moves.length);

    // Away again; this time the host lets her leave and the others play on.
    proxy.cut();
    await until(() => host.paused);
    expect(host.resignAwaySeat(1), isNotNull, reason: 'Ben is here');
    expect(host.resignAwaySeat(2), isNull);
    await until(() => ben.moves.length == host.moves.length);
    expect(host.paused, isFalse);
    expect(t.game.isSeatOut(2), isTrue);
    expect(await ben.submit(const {'action': 'pass'}), isNull);
    // She rejoins a game she has left: she sees it, and its end.
    final again = await KlunkiGuest.connect(loopback, host.port,
        name: 'Cleo', token: cleo.token, pingInterval: _ping, timeout: _timeout);
    addTearDown(again.close);
    expect(again.seat, 2);
    expect((again.game as WordTilesGame).isSeatOut(2), isTrue);
    expect(await again.submit(const {'action': 'pass'}), 'not your turn', reason: 'Anna and Ben play on');
  });

  test('in the lobby a guest that leaves frees its seat; the next one sits there', () async {
    const config = GameConfig('wordtiles', seed: 1, players: 4);
    final host = await KlunkiHost.start(config,
        address: loopback, name: 'Anna', pingInterval: _ping, timeout: _timeout, countdownTick: _tick);
    addTearDown(host.close);
    final ben = await KlunkiGuest.connect(loopback, host.port, name: 'Ben', pingInterval: _ping, timeout: _timeout);
    final cleo = await KlunkiGuest.connect(loopback, host.port, name: 'Cleo', pingInterval: _ping, timeout: _timeout);
    addTearDown(cleo.close);
    expect([ben.seat, cleo.seat], [1, 2]);
    await ben.close();
    await until(() => host.seats[1].free);
    await until(() => cleo.seats.length == 4 && cleo.seats[1].free);
    final dani = await KlunkiGuest.connect(loopback, host.port, name: 'Dani', pingInterval: _ping, timeout: _timeout);
    addTearDown(dani.close);
    expect(dani.seat, 1);
    expect(host.started, isFalse);
    final eve = await KlunkiGuest.connect(loopback, host.port, name: 'Eve', pingInterval: _ping, timeout: _timeout);
    addTearDown(eve.close);
    expect(eve.seat, 3);
    await until(() => host.started && cleo.started);
    expect([for (final s in host.seats) s.name], ['Anna', 'Dani', 'Cleo', 'Eve']);
  });

  test('a full table counts down on every device; no move before the start', () async {
    const config = GameConfig('wordtiles', seed: 6, players: 3);
    final host = await KlunkiHost.start(config,
        address: loopback, name: 'Anna', pingInterval: _ping, timeout: _timeout, countdownTick: _tick);
    addTearDown(host.close);
    final onWire = <int, List<Object?>>{};
    host.debugTableOutgoing = (seat, type, fields) {
      if (type == 'lobby') onWire.putIfAbsent(seat, () => []).add(fields['countdown']);
    };
    final refusedDuring = <String?>[];
    host.events.listen((e) {
      if (e is LobbyChanged && e.countdown != null) refusedDuring.add(host.submitLocal(const {'action': 'pass'}));
    });
    final ben = await KlunkiGuest.connect(loopback, host.port, name: 'Ben', pingInterval: _ping, timeout: _timeout);
    addTearDown(ben.close);
    final benSaw = <int?>[];
    ben.events.listen((e) {
      if (e is LobbyChanged) benSaw.add(e.countdown);
    });
    final cleo = await KlunkiGuest.connectWebSocket(webSocketUri(loopback.address, host.wsPort!),
        name: 'Cleo', pingInterval: _ping, timeout: _timeout);
    addTearDown(cleo.close);
    await until(() => host.started && ben.started && cleo.started);
    expect(refusedDuring, List.filled(5, 'waiting for players'), reason: 'the game starts after the countdown');
    expect(benSaw.whereType<int>(), [5, 4, 3, 2, 1], reason: 'the guest shows what the host counts');
    expect(benSaw.last, isNull);
    for (final seat in [1, 2]) {
      expect(onWire[seat]!.whereType<int>(), [5, 4, 3, 2, 1], reason: 'seat $seat');
      expect(onWire[seat]!.last, isNull, reason: 'started: no countdown');
    }
    expect([host.countdown, ben.countdown, cleo.countdown], [null, null, null]);
    expect(host.submitLocal(const {'action': 'pass'}), isNull);
  });

  test('a guest that leaves during the countdown stops it; the next one to sit down starts it again', () async {
    const config = GameConfig('wordtiles', seed: 6, players: 3);
    // A tick that never comes during the test: the countdown stands at 5.
    final host = await KlunkiHost.start(config,
        address: loopback,
        name: 'Anna',
        pingInterval: _ping,
        timeout: _timeout,
        countdownTick: const Duration(hours: 1));
    addTearDown(host.close);
    final ben = await KlunkiGuest.connect(loopback, host.port, name: 'Ben', pingInterval: _ping, timeout: _timeout);
    addTearDown(ben.close);
    expect(host.countdown, isNull, reason: 'one seat is free');
    final cleo = await KlunkiGuest.connect(loopback, host.port, name: 'Cleo', pingInterval: _ping, timeout: _timeout);
    await until(() => host.countdown == 5 && ben.countdown == 5 && cleo.countdown == 5);
    expect(host.started, isFalse);
    expect(await ben.submit(const {'action': 'pass'}), 'waiting for players');

    // Cleo leaves: the countdown stops everywhere, the lobby waits for one.
    await cleo.close();
    await until(() => host.seats[2].free && ben.seats[2].free);
    expect(host.countdown, isNull);
    expect(ben.countdown, isNull);
    expect(ben.started, isFalse);

    // Cleo comes back (her seat was freed: she sits down anew): from 5 again.
    final again = await KlunkiGuest.connect(loopback, host.port, name: 'Cleo', pingInterval: _ping, timeout: _timeout);
    addTearDown(again.close);
    expect(again.seat, 2);
    await until(() => host.countdown == 5 && ben.countdown == 5 && again.countdown == 5);
    expect(host.started, isFalse);
  });

  test('a cheating host: a guest exchange changed after the fact fails the check of the others', () async {
    const config = GameConfig('wordtiles', seed: 8, players: 3);
    final t = await _startTable(config);
    addTearDown(t.close);
    await t.play(0, const {'action': 'pass'});
    final rack = t.viewOf(1).rackOf(1);
    final other = rack.firstWhere((x) => x != rack.first);
    expect(await t.play(1, {'action': 'exchange', 'tiles': [rack.first]}), isNull);
    expect(t.guests[1].moves.last, {'action': 'exchange', 'count': 1});
    expect(t.host.debugReplaceMove(1, {'action': 'exchange', 'tiles': [other]}), isTrue);
    await _passes(t);
    await until(() => t.guests.every((g) => g.verification != Verification.pending));
    expect(t.guests[1].verification, Verification.failed, reason: 'Cleo was promised another exchange');
    expect(t.guests[1].verificationError, contains('commitment'));
  });

  test('a guest without the table protocol (an older build) is refused with incompatible-protocol', () async {
    const config = GameConfig('wordtiles', seed: 2, players: 3);
    final host = await KlunkiHost.start(config,
        address: loopback, name: 'Anna', pingInterval: _ping, timeout: _timeout, countdownTick: _tick);
    addTearDown(host.close);
    final refused = <IncompatiblePeer>[];
    host.events.listen((e) {
      if (e is IncompatiblePeer) refused.add(e);
    });
    final peer = await RawPeer.connect(host.port);
    addTearDown(peer.destroy);
    peer.send('hello', guestHello('Opa')); // protocol 3, no maxProtocol
    final error = await peer.next('error');
    expect(error['v'], protocolVersion, reason: 'in the version the old guest reads');
    expect(error['code'], 'incompatible-protocol');
    expect(error['protocol'], tableProtocolVersion);
    await until(() => refused.isNotEmpty);
    expect(refused.single.mismatch.peerName, 'Opa');
    expect(host.seats[1].free, isTrue);
  });

  test('the wire of a table speaks protocol 4 after the hello; a two-player session stays at 3', () async {
    const config = GameConfig('wordtiles', seed: 2, players: 3);
    final host = await KlunkiHost.start(config,
        address: loopback, name: 'Anna', pingInterval: _ping, timeout: _timeout, countdownTick: _tick);
    addTearDown(host.close);
    final peer = await RawPeer.connect(host.port);
    addTearDown(peer.destroy);
    peer.send('hello', {...guestHello('Ben'), 'maxProtocol': tableProtocolVersion});
    final hello = await peer.next('hello');
    expect(hello['v'], tableProtocolVersion);
    expect(hello['protocol'], tableProtocolVersion);
    final welcome = await peer.next('welcome');
    expect(welcome['seat'], 1);
    expect(welcome.containsKey('you'), isFalse);
    expect((welcome['config'] as Map)['players'], 3);
    final lobby = await peer.next('lobby');
    expect(lobby, {
      'type': 'lobby',
      'v': 4,
      'seats': [
        {'name': 'Anna', 'here': true},
        {'name': 'Ben', 'here': true},
        null,
      ],
      'started': false,
    });

    // Two players: the same guest offer, the old answer.
    final two = await KlunkiHost.start(const GameConfig('wordtiles', seed: 2), address: loopback, name: 'Anna');
    addTearDown(two.close);
    final peer2 = await RawPeer.connect(two.port);
    addTearDown(peer2.destroy);
    peer2.send('hello', {...guestHello('Ben'), 'maxProtocol': tableProtocolVersion});
    final hello2 = await peer2.next('hello');
    expect(hello2['v'], protocolVersion);
    expect(hello2['protocol'], protocolVersion);
    final welcome2 = await peer2.next('welcome');
    expect(welcome2['you'], 'b');
    expect(welcome2.containsKey('seat'), isFalse);
  });

  for (final players in [3, 4]) {
    test('$players players through a relay (a table room): a whole game, every guest verifies', () async {
      final url = await _relay();
      final t = await _startTable(GameConfig('wordtiles', seed: 40 + players, players: players), relay: url);
      addTearDown(t.close);
      expect(t.host.roomCode, isNotNull);
      // The room is full: a latecomer is refused by the relay already.
      await expectLater(KlunkiGuest.connectRelay(url, t.host.roomCode!, name: 'Eve', timeout: _timeout),
          throwsA(isA<NetException>().having((e) => e.message, 'message', contains('full'))));
      await _playToEnd(t, 7 * players, calmAfter: 30);
    });
  }

  test('through a relay a guest that drops pauses the table and rejoins its room seat', () async {
    final url = await _relay();
    final t = await _startTable(const GameConfig('wordtiles', seed: 4, players: 3), relay: url);
    addTearDown(t.close);
    expect(await t.play(0, const {'action': 'pass'}), isNull);
    final ben = t.guests[0];
    final token = ben.token;
    await ben.close();
    await until(() => t.host.paused && t.guests[1].paused);
    final again = await KlunkiGuest.connectRelay(url, t.host.roomCode!,
        name: 'Ben', token: token, pingInterval: _ping, timeout: _timeout);
    t.guests[0] = again;
    expect(again.seat, 1);
    expect(again.moves.length, 1);
    await until(() => !t.host.paused && !t.guests[1].paused);
    expect(await t.play(1, const {'action': 'pass'}), isNull);
  });

  test('a relay without table rooms (older) refuses to host a table', () async {
    // An old relay: answers ?create with relay.room but no `guests`.
    final server = await HttpServer.bind(loopback, 0);
    addTearDown(() => server.close(force: true));
    final queries = <String>[];
    server.listen((request) async {
      queries.add(request.uri.query);
      final ws = await WebSocketTransformer.upgrade(request);
      ws.add(jsonEncode({'t': 'relay.room', 'code': 'K7Q2M', 'key': 'a' * 32}));
      ws.listen((_) {}, onDone: () {});
    });
    final url = Uri.parse('ws://${loopback.address}:${server.port}/relay');
    await expectLater(
        KlunkiHost.startRelay(const GameConfig('wordtiles', players: 3), url, timeout: _timeout),
        throwsA(isA<NetException>().having((e) => e.message, 'message', contains('more than two players'))));
    expect(queries.single, 'create&guests=2');
  });

  test('a table needs a game that knows seats; the host is seat 0', () async {
    for (final config in [
      const GameConfig('maexchen', seed: 1, players: 3), // redacts for two players only
      const GameConfig('wordtiles', seed: 1, players: 5),
    ]) {
      await expectLater(KlunkiHost.start(config, wsPort: null), throwsArgumentError, reason: '$config');
    }
    await expectLater(
        KlunkiHost.start(const GameConfig('wordtiles', players: 3), wsPort: null, hostPlayer: Player.b),
        throwsArgumentError);
  });
}

/// Everybody passes until the game ends.
Future<void> _passes(_Table t) async {
  while (!t.game.isOver) {
    final seat = t.game.actorSeat!;
    final view = t.viewOf(seat);
    final move = view.canChallenge ? const {'action': 'accept'} : const {'action': 'pass'};
    expect(await t.play(seat, move), isNull);
  }
}
