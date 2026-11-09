// KLD-094 step 6: Wortgewandt over the network. Hidden information (racks,
// bag order, the seed), so the redacted protocol of KLD-064: the host is the
// referee, the guest holds only its own view. The start options (tile set,
// word list) travel in the public config; the word lists' identities are in
// the fingerprint. "Trotzdem zulassen" is a request the other player answers
// (requestAllow / acceptAllow / declineAllow, rules version 3), like the
// chess draw offer.
@Timeout(Duration(seconds: 90))
library;

import 'dart:convert';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:test/test.dart';

import 'support.dart';

const _ping = Duration(milliseconds: 50);
const _timeout = Duration(seconds: 3);

/// A word list the test can extend while the game runs (host and guest share
/// it through [WordLists], as two devices with the same list would).
class _Words extends WordValidator {
  final Set<String> known = {};
  @override
  bool isWord(String word) => known.contains(word);
}

/// Every message the host sends to the guest, captured through the test hook.
class _Wire {
  final List<(String, Map<String, dynamic>)> messages = [];
  void attach(KlunkiHost host) => host.debugRewriteOutgoing = (type, fields) {
        messages.add((type, jsonDecode(jsonEncode(fields)) as Map<String, dynamic>));
        return fields;
      };
}

typedef _Setup = Future<(KlunkiHost, KlunkiGuest, _Wire, Future<void> Function())> Function(GameConfig config);

/// Every way a guest can reach a host: direct TCP, WebSocket, relay. The
/// hook is set before the guest joins, so the `welcome` is captured too.
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

WordTilesGame _hostGame(KlunkiHost h) => h.game as WordTilesGame;
WordTilesGame _guestView(KlunkiGuest g) => g.game as WordTilesGame;

/// The keys a guest's view may have (anything else would be a leak).
const _viewKeys = {
  'viewer', 'tileSet', 'players', 'check', 'scorelessLimit', 'board', 'rack', 'racks', 'bag', 'scores', //
  'penalties', 'seat', 'scoreless', 'open', 'endPending', 'allowRequest', 'declined', 'turns', 'end', 'resigned',
};

/// After every move: the guest's view is its own and nothing of the host's
/// rack, the bag or the seed reached the guest before the game ended.
void _expectSecret(KlunkiHost host, KlunkiGuest guest, _Wire wire) {
  final h = _hostGame(host), v = _guestView(guest);
  expect(guest.redacted, isTrue);
  expect(v, isA<WordTilesView>());
  expect(v.rackOf(1), h.rackOf(1), reason: 'the guest sees its own rack');
  expect(v.rackOf(0), isEmpty, reason: "the host's rack is hidden");
  expect(v.rackSizeOf(0), h.rackSizeOf(0));
  expect(v.bagCount, h.bagCount);
  expect(v.seed, 0);
  expect(v.scores, h.scores);
  expect(v.currentSeat, h.currentSeat);
  expect(v.allowRequest?.allow, h.allowRequest?.allow);
  for (final (type, m) in wire.messages) {
    if (type == 'reveal') continue;
    final view = m['view'];
    if (view is Map<String, dynamic>) {
      expect(_viewKeys.containsAll(view.keys), isTrue, reason: 'view keys ${view.keys}');
      expect(view['viewer'], 'b');
      expect(view['bag'], isA<int>(), reason: 'the bag is a count');
      expect(view['racks'], everyElement(isA<int>()));
    }
    if (type == 'welcome') {
      expect((m['config'] as Map).containsKey('seed'), isFalse, reason: 'the seed decides the bag');
      expect(m['seedCommit'], isA<String>());
    }
    if (type == 'accepted' && m['player'] == 'a') {
      final move = m['move'] as Map;
      if (move['action'] == 'exchange') {
        expect(move.containsKey('tiles'), isFalse, reason: 'a host exchange shows only how many');
        expect(m['commit'], isA<String>());
      }
    }
  }
}

/// A placement the mover of [game] can lay with rack tiles (no blanks) that
/// fits the board (words not checked), avoiding the words in [avoid].
List<PlacedTile> _findPlacement(WordTilesGame game, int seat, {Set<String> avoid = const {}}) {
  final rack = [for (final t in game.rackOf(seat)) if (t != TileSet.blank) t];
  bool fits(List<PlacedTile> tiles) {
    final move = WordTilesGame.placeMove(tiles);
    final c = game.checkPlacement(move, checkWords: false);
    return c.ok && !c.words.any((w) => avoid.contains(w.word));
  }

  if (game.boardEmpty) {
    for (var i = 0; i < rack.length; i++) {
      for (var j = 0; j < rack.length; j++) {
        if (i == j) continue;
        final tiles = [PlacedTile(7, 7, rack[i]), PlacedTile(7, 8, rack[j])];
        if (fits(tiles)) return tiles;
      }
    }
  }
  for (var r = 0; r < WordTilesGame.size; r++) {
    for (var c = 0; c < WordTilesGame.size; c++) {
      for (final t in rack.toSet()) {
        final tiles = [PlacedTile(r, c, t)];
        if (fits(tiles)) return tiles;
      }
    }
  }
  fail('no placement for seat $seat');
}

/// [n] more entries in both logs.
Future<void> _synced(KlunkiHost host, KlunkiGuest guest, int n) =>
    until(() => host.moves.length == n && guest.moves.length == n);

Future<void> _hostMove(KlunkiHost host, KlunkiGuest guest, Map<String, dynamic> move) async {
  final n = host.moves.length;
  expect(host.submitLocal(move), isNull, reason: '$move');
  await _synced(host, guest, n + 1);
}

Future<void> _guestMove(KlunkiHost host, KlunkiGuest guest, Map<String, dynamic> move) async {
  final n = host.moves.length;
  expect(await guest.submit(move), isNull, reason: '$move');
  await _synced(host, guest, n + 1);
}

/// Ends the game by six passes (scoreless turns), checking after each.
Future<void> _passToEnd(KlunkiHost host, KlunkiGuest guest, _Wire wire) async {
  while (!host.game.isOver) {
    if (_hostGame(host).currentSeat == 0) {
      await _hostMove(host, guest, const {'action': 'pass'});
    } else {
      await _guestMove(host, guest, const {'action': 'pass'});
    }
    _expectSecret(host, guest, wire);
  }
  expect(_hostGame(host).result.code, GameEndReason.wordtilesScoreless);
}

Future<void> _expectVerified(KlunkiHost host, KlunkiGuest guest) async {
  expect(guest.game.isOver, isTrue);
  expect(guest.game.result.winner, host.game.result.winner);
  expect(guest.game.result.draw, host.game.result.draw);
  expect(_guestView(guest).scores, _hostGame(host).scores);
  await until(() => guest.verification != Verification.pending);
  expect(guest.verificationError, isNull);
  expect(guest.verification, Verification.verified);
}

void main() {
  late _Words words;
  setUp(() {
    words = _Words();
    WordLists.register('de', words);
    WordLists.register('en', words);
  });
  tearDown(WordLists.clear);

  test('the word tile game is redacted with a secret seed; rules 5 and the word lists in the fingerprint', () {
    final spec = specById('wordtiles')!;
    expect(spec.redaction, isA<WordTilesRedaction>());
    expect(spec.redaction!.secretSeed, isTrue);
    expect(fingerprintOf(const GameConfig('wordtiles'))!.rules, 5);
    expect(WordTilesGame.gameplayData().last, everyElement(contains('sha256:')));
  });

  for (final MapEntry(key: name, value: setup) in _transports.entries) {
    group('over $name', () {
      test('dictionary on: a request declined, one accepted, a known word, an exchange, the end verified', () async {
        const config = GameConfig('wordtiles', seed: 7, tiles: 'en', dictionary: true);
        final (host, guest, wire, close) = await setup(config);
        addTearDown(close);
        addTearDown(host.close);
        addTearDown(guest.close);

        // The options travel (host → guest) and are the same game.
        expect(guest.config.tiles, 'en');
        expect(guest.config.dictionary, isTrue);
        expect(_guestView(guest).tileSet, TileSet.english);
        expect(_guestView(guest).check, WordCheck.dictionary);
        _expectSecret(host, guest, wire);

        // 1. Anna (host) lays a word the list does not know and asks; Ben declines.
        final first = _findPlacement(_hostGame(host), 0);
        final unknown = _hostGame(host).unknownWords(WordTilesGame.placeMove(first));
        expect(unknown, isNotEmpty);
        await _hostMove(host, guest, WordTilesGame.requestAllowMove(Player.a, first, unknown));
        _expectSecret(host, guest, wire);
        expect(_guestView(guest).allowRequest!.allow, unknown);
        expect(_guestView(guest).allowRequestAnswerer, 1);
        expect(guest.entries.last.player, Player.a);
        // Ben cannot lay anything meanwhile; Anna cannot answer for him.
        expect(await guest.submit(const {'action': 'pass'}), 'not your turn');
        expect(host.submitLocal(WordTilesGame.acceptAllowMove(Player.a)), isNotNull);
        expect(await guest.submit(WordTilesGame.acceptAllowMove(Player.a)), 'not your turn');
        await _guestMove(host, guest, WordTilesGame.declineAllowMove(Player.b));
        _expectSecret(host, guest, wire);
        expect(_hostGame(host).currentSeat, 0, reason: 'still Anna');
        expect(_hostGame(host).boardEmpty, isTrue);
        // The same request again is refused this turn.
        expect(host.submitLocal(WordTilesGame.requestAllowMove(Player.a, first, unknown)), 'illegal move');

        // 2. Another word, asked for again; Ben agrees.
        final second = _findPlacement(_hostGame(host), 0, avoid: unknown.toSet());
        final unknown2 = _hostGame(host).unknownWords(WordTilesGame.placeMove(second));
        // A place with `allow` alone, without Ben, is refused.
        expect(host.submitLocal(WordTilesGame.placeMove(second, allow: unknown2)), 'illegal move');
        await _hostMove(host, guest, WordTilesGame.requestAllowMove(Player.a, second, unknown2));
        await _guestMove(host, guest, WordTilesGame.acceptAllowMove(Player.b));
        _expectSecret(host, guest, wire);
        expect(_guestView(guest).turns.single.allowed, unknown2);
        expect(_guestView(guest).currentSeat, 1);
        expect(guest.entries.last.event?.payload, containsPair('agreed', 1));

        // 3. Ben lays a word the list knows (checked on his own device with
        // the same list): no request needed.
        final third = _findPlacement(_guestView(guest), 1);
        final move3 = WordTilesGame.placeMove(third);
        words.known.addAll(_guestView(guest).unknownWords(move3));
        expect(_guestView(guest).unknownWords(move3), isEmpty);
        // An `allow` naming a known word is refused by the host's own check.
        expect(await guest.submit(WordTilesGame.requestAllowMove(Player.b, third, const ['ZZZ'])), 'illegal move');
        await _guestMove(host, guest, move3);
        _expectSecret(host, guest, wire);

        // 4. Anna swaps two tiles: Ben sees only how many.
        await _hostMove(host, guest, {
          'action': 'exchange',
          'tiles': _hostGame(host).rackOf(0).take(2).toList(),
        });
        _expectSecret(host, guest, wire);
        expect(guest.moves.last, {'action': 'exchange', 'count': 2});

        // 5. Ben asks to allow a word; Anna (the host's player) agrees.
        final fifth = _findPlacement(_guestView(guest), 1, avoid: words.known);
        final unknown5 = _guestView(guest).unknownWords(WordTilesGame.placeMove(fifth));
        expect(unknown5, isNotEmpty);
        expect(await guest.submit(WordTilesGame.placeMove(fifth, allow: unknown5)), 'illegal move',
            reason: 'no allow without the other player');
        await _guestMove(host, guest, WordTilesGame.requestAllowMove(Player.b, fifth, unknown5));
        expect(_hostGame(host).allowRequest!.seat, 1);
        expect(_guestView(guest).allowRequest!.seat, 1, reason: 'Ben waits for Anna');
        await _hostMove(host, guest, WordTilesGame.acceptAllowMove(Player.a));
        _expectSecret(host, guest, wire);
        expect(_hostGame(host).turns.last.allowed, unknown5);

        await _passToEnd(host, guest, wire);
        await _expectVerified(host, guest);
        final reveal = wire.messages.where((m) => m.$1 == 'reveal').single.$2;
        expect(reveal['seed'], 7);
        expect((reveal['secrets'] as List).map((s) => (s as Map)['index']), [5],
            reason: 'only the exchange was secret');
      });

      test('dictionary off: Ben challenges on his device, the placement is withdrawn', () async {
        const config = GameConfig('wordtiles', seed: 3);
        final (host, guest, wire, close) = await setup(config);
        addTearDown(close);
        addTearDown(host.close);
        addTearDown(guest.close);
        expect(guest.config.tiles, isNull);
        expect(guest.config.dictionary, isFalse);
        expect(_guestView(guest).check, WordCheck.challenge);

        final first = _findPlacement(_hostGame(host), 0);
        await _hostMove(host, guest, WordTilesGame.placeMove(first));
        _expectSecret(host, guest, wire);
        expect(_guestView(guest).canChallenge, isTrue);
        expect(_guestView(guest).challengeable!.tiles.length, 2);
        await _guestMove(host, guest, const {'action': 'challenge'});
        _expectSecret(host, guest, wire);
        expect(_hostGame(host).boardEmpty, isTrue);
        expect(_guestView(guest).turns.first.withdrawn, isTrue);
        expect(_guestView(guest).currentSeat, 1, reason: 'the challenger plays on');

        final second = _findPlacement(_guestView(guest), 1);
        await _guestMove(host, guest, WordTilesGame.placeMove(second));
        expect(_hostGame(host).canChallenge, isTrue);
        await _hostMove(host, guest, const {'action': 'accept'});
        _expectSecret(host, guest, wire);
        await _passToEnd(host, guest, wire);
        await _expectVerified(host, guest);
      });
    });
  }

  test('a rejoining guest gets the open request back and answers it', () async {
    const config = GameConfig('wordtiles', seed: 21, dictionary: true);
    final host = await startHost(config);
    addTearDown(host.close);
    final proxy = await Proxy.start(host.port);
    addTearDown(proxy.close);
    final guest = await KlunkiGuest.connect(loopback, proxy.port, name: 'Ben', pingInterval: _ping, timeout: _timeout);
    addTearDown(guest.close);

    final tiles = _findPlacement(_hostGame(host), 0);
    final unknown = _hostGame(host).unknownWords(WordTilesGame.placeMove(tiles));
    proxy.cut();
    await until(() => !host.guestConnected && !guest.connected);
    // The request is made while Ben is away.
    expect(host.submitLocal(WordTilesGame.requestAllowMove(Player.a, tiles, unknown)), isNull);

    await guest.reconnect();
    expect(_guestView(guest).allowRequest!.allow, unknown);
    expect(guest.moves.single['action'], 'requestAllow');

    // A fresh app instance with the token gets it too.
    final again = await KlunkiGuest.connect(loopback, host.port,
        name: 'Ben', token: guest.token, pingInterval: _ping, timeout: _timeout);
    addTearDown(again.close);
    expect(_guestView(again).allowRequest!.tiles.length, tiles.length);
    expect(await again.submit(WordTilesGame.acceptAllowMove(Player.b)), isNull);
    expect(_hostGame(host).turns.single.allowed, unknown);
    expect(_guestView(again).currentSeat, 1);
  });

  test('a guest whose own request is open sees it after rejoining (it waits for the host)', () async {
    const config = GameConfig('wordtiles', seed: 5, dictionary: true);
    final host = await startHost(config);
    addTearDown(host.close);
    final guest = await KlunkiGuest.connect(loopback, host.port, name: 'Ben', pingInterval: _ping, timeout: _timeout);
    addTearDown(guest.close);
    await _hostMove(host, guest, const {'action': 'pass'});
    final tiles = _findPlacement(_guestView(guest), 1);
    final unknown = _guestView(guest).unknownWords(WordTilesGame.placeMove(tiles));
    await _guestMove(host, guest, WordTilesGame.requestAllowMove(Player.b, tiles, unknown));
    final again = await KlunkiGuest.connect(loopback, host.port,
        name: 'Ben', token: guest.token, pingInterval: _ping, timeout: _timeout);
    addTearDown(again.close);
    expect(_guestView(again).allowRequest!.seat, 1);
    expect(_guestView(again).legalMoves, isEmpty, reason: 'Ben waits');
    final n = host.moves.length;
    expect(host.submitLocal(WordTilesGame.declineAllowMove(Player.a)), isNull);
    await until(() => again.moves.length == n + 1);
    expect(_guestView(again).allowRequest, isNull);
    expect(_guestView(again).currentSeat, 1, reason: 'still Ben');
  });

  test('a guest with another word list (fingerprint) is refused', () async {
    const config = GameConfig('wordtiles', seed: 1, dictionary: true);
    final host = await startHost(config);
    addTearDown(host.close);
    final refused = <IncompatiblePeer>[];
    host.events.listen((e) {
      if (e is IncompatiblePeer) refused.add(e);
    });
    final mine = fingerprintOf(config)!;
    final other = BuildCompat(build: '1.0.0+1', games: {
      ...allFingerprints(),
      'wordtiles': GameFingerprint(rules: mine.rules, revision: mine.revision, content: 'f' * 32),
    });
    await expectLater(
      KlunkiGuest.connect(loopback, host.port, name: 'Ben', compat: other, timeout: _timeout),
      throwsA(isA<NetException>().having((e) => e.mismatch?.kind, 'kind', Incompatibility.content)),
    );
    await until(() => refused.isNotEmpty);
    expect(refused.single.mismatch.kind, Incompatibility.content);
    expect(host.guestConnected, isFalse);

    // A build with the word tile rules 2 (no request moves) is refused as well.
    final old = BuildCompat(games: {
      ...allFingerprints(),
      'wordtiles': GameFingerprint(rules: 2, revision: mine.revision, content: mine.content),
    });
    await expectLater(
      KlunkiGuest.connect(loopback, host.port, name: 'Ben', compat: old, timeout: _timeout),
      throwsA(isA<NetException>().having((e) => e.mismatch?.kind, 'kind', Incompatibility.rules)),
    );
  });

  test('a guest without the list loaded still joins; the config names it; an unknown tile set is refused', () async {
    WordLists.clear();
    // The host has its list (registered just for creating the game).
    WordLists.register('de', words);
    const config = GameConfig('wordtiles', seed: 9, dictionary: true);
    final host = await startHost(config);
    addTearDown(host.close);
    WordLists.clear(); // the guest's "device" has not loaded it yet
    final guest = await KlunkiGuest.connect(loopback, host.port, name: 'Ben', pingInterval: _ping, timeout: _timeout);
    addTearDown(guest.close);
    expect(guest.config, const GameConfig('wordtiles', dictionary: true));
    expect(configProblem(guest.config), isNotNull, reason: 'the app loads it now');
    expect(configProblem(guest.config, wordList: false), isNull);
    expect(_guestView(guest).unknownWords(WordTilesGame.placeMove([const PlacedTile(7, 7, 'A')])), isEmpty);
    expect(configProblem(const GameConfig('wordtiles', tiles: 'xx'), wordList: false), isNotNull);
  });

  test('a 3–4 player word tile game is one-device only for now (KLD-088): the host refuses it', () async {
    for (final n in [3, 4]) {
      final config = GameConfig('wordtiles', seed: 1, players: n);
      expect(configProblem(config), isNull);
      await expectLater(KlunkiHost.start(config, wsPort: null), throwsArgumentError);
    }
  });
}
