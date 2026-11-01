import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/src/secrecy/secrecy.dart';
import 'package:klunki_net/src/secrecy/sha256.dart';
import 'package:test/test.dart';

import 'support.dart';

/// KLD-064: hidden information stays with its owner. Every message the host
/// sends to the guest is tapped (`debugRewriteOutgoing`) and checked, and so
/// is the guest's in-memory state.
void main() {
  group('sha256', () {
    test('known vectors', () {
      expect(sha256Hex(''), 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
      expect(sha256Hex('abc'), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
      expect(sha256Hex('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),
          '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1');
      expect(sha256Hex('a' * 1000), '41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3');
      // The 55/56-byte padding boundary.
      expect(sha256Hex('x' * 55).length, 64);
      expect(sha256Hex('x' * 56), isNot(sha256Hex('x' * 55)));
    });

    test('commitments depend on salt, label and value', () {
      final c = commitment('s1', 'move:0', {'a': 1, 'b': 2});
      expect(commitment('s1', 'move:0', {'b': 2, 'a': 1}), c, reason: 'canonical JSON: key order does not matter');
      expect(commitment('s2', 'move:0', {'a': 1, 'b': 2}), isNot(c));
      expect(commitment('s1', 'move:1', {'a': 1, 'b': 2}), isNot(c));
      expect(commitment('s1', 'move:0', {'a': 1, 'b': 3}), isNot(c));
      expect(newSalt(), hasLength(32));
      expect(newSalt(), isNot(newSalt()));
    });
  });

  group('the guest never receives the host\'s secrets', () {
    test('Schiffe: no host ship square before it is hit, no placement in any message', () async {
      final t = await _Tapped.start(const GameConfig('schiffe'));
      // The host places its fleet ship by ship (each move has row/col/dir).
      final layout = SchiffeGame.randomLayout(42);
      for (var i = 0; i < layout.length; i++) {
        expect(t.host.submitLocal(layout[i].toMove(i)), isNull);
      }
      await until(() => t.guest.moves.length == layout.length);
      expect(await t.guest.submit({'action': 'autoplace', 'seed': 5}), isNull);
      final hostCells = {for (final p in layout) for (final c in p.cells) c[0] * 10 + c[1]};

      void checkGuest() {
        final view = t.guest.game as SchiffeGame;
        final shotAt = (t.host.game as SchiffeGame).targetGrid(Player.b);
        final known = view.ownGrid(Player.a);
        for (var r = 0; r < 10; r++) {
          for (var c = 0; c < 10; c++) {
            expect(known[r][c], isNot(SchiffeCell.ship));
            if (shotAt[r][c] == ShotMark.unknown) {
              expect(known[r][c], SchiffeCell.empty, reason: 'unshot square $r,$c');
              expect(view.targetGrid(Player.b)[r][c], ShotMark.unknown);
            }
          }
        }
        expect(view.placements(Player.a), isEmpty);
        // Nothing sent so far names a host square that was not shot yet.
        for (final m in t.beforeReveal) {
          final view = m['view'];
          if (view is Map) {
            final target = view['target'] as String;
            for (final cell in hostCells) {
              final r = cell ~/ 10, c = cell % 10;
              if (shotAt[r][c] == ShotMark.unknown) expect(target[cell], '0');
            }
          }
        }
        expect(t.beforeReveal.map(jsonEncode).join(), isNot(contains('"dir"')),
            reason: 'the host placed ships with "dir"; the guest autoplaced');
      }

      checkGuest();
      await _playOut(t, Random(1), check: checkGuest);
      expect(t.guest.verification, Verification.verified);
      // The reveal (after the game) is the first and only place the fleet appears.
      expect(jsonEncode(t.reveal), contains('"dir"'));
      await t.close();
    });

    test('Schiffe, guest as X: the guest\'s setup goes to the host only and is never sent back with host data',
        () async {
      final t = await _Tapped.start(const GameConfig('schiffe'), hostPlayer: Player.b);
      expect(t.guest.me, Player.a);
      final mine = SchiffeGame.randomLayout(7);
      for (var i = 0; i < mine.length; i++) {
        expect(await t.guest.submit(mine[i].toMove(i)), isNull);
      }
      expect(t.host.submitLocal({'action': 'autoplace', 'seed': 99}), isNull);
      await until(() => t.guest.moves.length == mine.length + 1);
      // Each ack of a guest placement is exactly the guest's own move: no
      // host data rides along, and the host's later setup is redacted.
      for (var i = 0; i < mine.length; i++) {
        final ack = t.beforeReveal.firstWhere((m) => m['type'] == 'accepted' && m['index'] == i);
        expect(ack['move'], mine[i].toMove(i));
        expect(ack.containsKey('commit'), isFalse);
        expect((ack['view'] as Map)['oppPlaced'], 0, reason: 'the host has not placed yet');
      }
      expect(t.guest.moves.last, {'action': 'autoplace'});
      await _playOut(t, Random(2));
      expect(t.guest.verification, Verification.verified);
      // The reveal holds the host's own committed move only, not the guest's fleet.
      final secrets = t.reveal!['secrets'] as List;
      expect([for (final s in secrets) s['index']], [mine.length]);
      expect(jsonEncode(t.reveal), isNot(contains('"place"')));
      await t.close();
    });

    test('GoStrategy: no rank of an unrevealed host piece, no setup in any message', () async {
      final t = await _Tapped.start(const GameConfig('gostrategy'));
      expect(t.host.submitLocal(GoStrategyGame.setupMove(GoStrategyGame.randomSetup(3))), isNull);
      await until(() => t.guest.moves.length == 1);
      expect(await t.guest.submit({'action': 'autosetup', 'seed': 4}), isNull);

      void checkGuest() {
        final view = t.guest.game as GoStrategyGame;
        final truth = (t.host.game as GoStrategyGame).board;
        for (var sq = 0; sq < 100; sq++) {
          final c = view.viewFor(Player.b)[sq];
          expect(view.board[sq], c, reason: 'a view has no "full truth"');
          if (truth[sq].owner == Player.a && !truth[sq].revealed) expect(c.piece, isNull, reason: 'square $sq');
        }
        for (final m in t.beforeReveal) {
          expect(jsonEncode(m), isNot(contains('"pieces"')));
          final cells = (m['view'] as Map?)?['cells'] as List?;
          for (final cell in cells ?? const []) {
            if (cell is Map && cell['o'] == 'a' && cell['p'] != null) expect(cell['r'], isTrue);
          }
        }
      }

      checkGuest();
      await _playOut(t, Random(3), check: checkGuest, every: 25);
      expect(t.guest.verification, Verification.verified);
      await t.close();
    });

    for (final id in ['quartett-trumpf', 'quartett-sets']) {
      test('$id: no seed, and no card the guest may not see', () async {
        final t = await _Tapped.start(GameConfig(id, seed: 123456));
        final cardId = RegExp(r'"([A-H][1-4])"');
        Set<String> ids(Object? x) => {for (final m in cardId.allMatches(jsonEncode(x))) m[1]!};

        void checkGuest() {
          for (final m in t.beforeReveal) {
            expect(jsonEncode(m), isNot(contains('123456')), reason: 'the seed');
            final view = m['view'] as Map<String, dynamic>?;
            final payload = (m['event'] as Map?)?['payload'] as Map?;
            final allowed = <String>{
              if (view?['top'] != null) view!['top'] as String,
              ...ids(view?['hand']),
              ...ids(payload?['cards']), // a Trumpf trick shows both cards
              if (payload?['card'] != null) payload!['card'] as String, // the card asked for
              if (payload?['drew'] is String) payload!['drew'] as String,
            };
            expect(ids(m).difference(allowed), isEmpty, reason: '${m['type']} #${m['index']}');
            if (payload?['drew'] is String) expect(m['player'], t.guest.me.name, reason: 'only the drawer sees it');
          }
          final view = t.guest.game as QuartettGame;
          final host = t.host.game as QuartettGame;
          expect(view.seed, 0);
          if (view.mode == QuartettMode.trumpf) {
            expect(view.topCard(Player.a), isNull);
            expect(view.stackOf(Player.a), isEmpty);
            expect(view.chosenCard(Player.a), isNull, reason: "the host's choice (KLD-100)");
            expect(view.chosenCard(Player.b), host.chosenCard(Player.b));
            // KLD-100: with 3 or fewer cards the guest sees its whole stack.
            expect(view.stackOf(Player.b),
                host.choosesCard(Player.b) ? host.stackOf(Player.b) : [if (host.topCard(Player.b) case final top?) top]);
          } else {
            expect(view.handOf(Player.a).every((c) => c.id == '?'), isTrue);
            expect(view.handOf(Player.a).length, host.handOf(Player.a).length);
            expect(view.handOf(Player.b), host.handOf(Player.b));
          }
        }

        final welcome = t.beforeReveal.firstWhere((m) => m['type'] == 'welcome');
        expect((welcome['config'] as Map).containsKey('seed'), isFalse);
        expect(welcome['seedCommit'], isA<String>());
        checkGuest();
        await _playOut(t, Random(4), check: checkGuest, every: id == 'quartett-trumpf' ? 1 : 10);
        expect(t.guest.verification, Verification.verified);
        expect(t.reveal!['seed'], 123456);
        if (id == 'quartett-trumpf') {
          // KLD-100 (on by default): both sides chose cards; the host's
          // choices reached the guest without the card and were committed.
          final chooses = [
            for (final (i, m) in t.host.moves.indexed)
              if (m['action'] == 'choose') i
          ];
          expect(chooses, isNotEmpty);
          for (final i in chooses) {
            final ack = t.beforeReveal.firstWhere((m) => m['type'] == 'accepted' && m['index'] == i);
            final mine = ack['player'] == t.guest.me.name;
            expect(ack['move'], mine ? t.host.moves[i] : {'action': 'choose'});
            expect(ack.containsKey('commit'), !mine);
          }
        }
        await t.close();
      });
    }
  });

  group('Quartett decks over the network (KLD-069)', () {
    for (final deck in QuartettDeck.all) {
      for (final id in ['quartett-trumpf', 'quartett-sets']) {
        test('$id with ${deck.id}: the deck is public config, the seed stays secret, the game verifies', () async {
          final t = await _Tapped.start(GameConfig(id, seed: 424242, deck: deck.id), hostPlayer: Player.b);
          final welcome = t.beforeReveal.firstWhere((m) => m['type'] == 'welcome');
          expect(welcome['config'], {'game': id, 'deck': deck.id});
          expect(t.guest.config, GameConfig(id, deck: deck.id));
          expect((t.guest.game as QuartettGame).deck, same(deck));
          await _playOut(t, Random(deck.id.hashCode ^ id.hashCode));
          expect(t.guest.verification, Verification.verified, reason: t.guest.verificationError);
          expect(t.reveal!['seed'], 424242);
          await t.close();
        });
      }
    }

    test('a host that swaps the deck in the reveal replay is caught', () async {
      // The guest replays with the deck it was told; a host that dealt from
      // another deck cannot match the start view.
      final error = verifyRedactedGame(
        gameId: 'quartett-trumpf',
        deck: 'rockets',
        me: Player.b,
        seed: 1,
        seedSalt: 's',
        seedCommit: commitment('s', 'seed', 1),
        startViewHash: viewHash(const QuartettRedaction().view(
            QuartettGame(QuartettMode.trumpf, seed: 1, deck: QuartettDeck.trains), Player.b)),
        steps: const [],
        secrets: const {},
      );
      expect(error, contains('start position'));
    });
  });

  group('commitments catch a cheating host', () {
    test('a host that swaps its fleet mid-game is detected', () async {
      final t = await _Tapped.start(const GameConfig('schiffe'));
      expect(t.host.submitLocal({'action': 'autoplace', 'seed': 1}), isNull);
      await until(() => t.guest.moves.length == 1);
      expect(await t.guest.submit({'action': 'autoplace', 'seed': 2}), isNull);
      final rng = Random(5);
      for (var i = 0; i < 6; i++) {
        await _step(t, rng);
      }
      // The guest has fired a few shots; now the host moves its fleet.
      expect(t.host.debugReplaceMove(0, {'action': 'autoplace', 'seed': 77}), isTrue);
      await _playOut(t, rng);
      expect(t.guest.verification, Verification.failed);
      expect(t.guest.verificationError, contains('commitment'));
      expect(t.guestEvents.whereType<VerificationFailed>(), hasLength(1));
      await t.close();
    });

    test('a misreported shot is detected', () async {
      final t = await _Tapped.start(const GameConfig('schiffe'));
      var lied = false;
      t.rewrite = (type, fields) {
        final payload = (fields['event'] as Map?)?['payload'];
        if (!lied && type == 'accepted' && fields['player'] == 'b' && payload is Map && payload['result'] == 'hit') {
          lied = true;
          return {
            ...fields,
            'event': {
              'payload': {...payload, 'result': 'miss'}
            },
          };
        }
        return fields;
      };
      expect(t.host.submitLocal({'action': 'autoplace', 'seed': 1}), isNull);
      await until(() => t.guest.moves.length == 1);
      expect(await t.guest.submit({'action': 'autoplace', 'seed': 2}), isNull);
      await _playOut(t, Random(6));
      expect(lied, isTrue);
      expect(t.guest.verification, Verification.failed);
      expect(t.guest.verificationError, contains('misreported'));
      await t.close();
    });

    test('a different Quartett seed in the reveal is detected', () async {
      final t = await _Tapped.start(const GameConfig('quartett-trumpf', seed: 9));
      t.rewrite = (type, fields) => type == 'reveal' ? {...fields, 'seed': 10} : fields;
      await _playOut(t, Random(7));
      expect(t.guest.verification, Verification.failed);
      expect(t.guest.verificationError, contains('seed'));
      await t.close();
    });

    test('an honest host is verified after a reconnect too', () async {
      final host = await startHost(const GameConfig('schiffe'));
      final proxy = await Proxy.start(host.port);
      final guest = await KlunkiGuest.connect(loopback, proxy.port);
      expect(host.submitLocal({'action': 'autoplace', 'seed': 1}), isNull);
      await until(() => guest.moves.length == 1);
      expect(await guest.submit({'action': 'autoplace', 'seed': 2}), isNull);
      proxy.cut();
      await until(() => !host.guestConnected && !guest.connected);
      expect(host.submitLocal({'action': 'fire', 'row': 0, 'col': 0}), isNull);
      await guest.reconnect();
      expect(guest.moves.length, 3);
      expect((guest.game as SchiffeGame).ownGrid(Player.a).expand((r) => r), isNot(contains(SchiffeCell.ship)));
      final rng = Random(8);
      while (!host.game.isOver) {
        if (host.game.currentPlayer == host.me) {
          final legal = legalMoves(host.game, rng);
          expect(host.submitLocal(legal[rng.nextInt(legal.length)]), isNull);
          final n = host.moves.length;
          await until(() => guest.moves.length == n);
        } else {
          final legal = legalMoves(guest.game, rng);
          expect(await guest.submit(legal[rng.nextInt(legal.length)]), isNull);
        }
      }
      await until(() => guest.verification != Verification.pending);
      expect(guest.verification, Verification.verified);
      await guest.close();
      await proxy.close();
      await host.close();
    });
  });
}

/// A host whose messages to the guest are recorded (and optionally
/// rewritten), plus its guest.
class _Tapped {
  final KlunkiHost host;
  late final KlunkiGuest guest;
  final List<Map<String, dynamic>> sent = [];
  final List<NetEvent> guestEvents = [];
  Map<String, dynamic>? Function(String type, Map<String, dynamic> fields)? rewrite;

  _Tapped(this.host) {
    host.debugRewriteOutgoing = (type, fields) {
      final out = rewrite == null ? fields : rewrite!(type, fields);
      if (out != null) sent.add(jsonDecode(jsonEncode({'type': type, ...out})) as Map<String, dynamic>);
      return out;
    };
  }

  static Future<_Tapped> start(GameConfig config, {Player hostPlayer = Player.a}) async {
    final host = await KlunkiHost.start(config,
        address: loopback, name: 'Host', hostPlayer: hostPlayer, pingInterval: const Duration(milliseconds: 50));
    final t = _Tapped(host);
    t.guest = await joinHost(host.port);
    t.guest.events.listen(t.guestEvents.add);
    return t;
  }

  /// Everything sent before the host revealed its secrets.
  List<Map<String, dynamic>> get beforeReveal => [for (final m in sent) if (m['type'] != 'reveal') m];

  Map<String, dynamic>? get reveal => sent.where((m) => m['type'] == 'reveal').firstOrNull;

  Future<void> close() async {
    await guest.close();
    await host.close();
  }
}

/// One move by whoever is to move (random legal).
Future<void> _step(_Tapped t, Random rng) async {
  final host = t.host, guest = t.guest;
  if (host.game.currentPlayer == host.me) {
    final legal = legalMoves(host.game, rng);
    expect(host.submitLocal(legal[rng.nextInt(legal.length)]), isNull);
    final n = host.moves.length;
    await until(() => guest.moves.length == n);
  } else {
    final legal = legalMoves(guest.game, rng);
    expect(legal, isNotEmpty);
    expect(await guest.submit(legal[rng.nextInt(legal.length)]), isNull);
  }
}

/// Plays random legal moves to the end ([check] every [every] moves and at
/// the end), then waits for the guest's verification event.
///
/// Waiting for [KlunkiGuest.verification] is not enough: it is set while the
/// `reveal` is handled, but the event goes out on an asynchronous stream,
/// one event per microtask behind the moves still queued for delivery. When
/// the last `accepted` and the `reveal` arrive in one read, the test resumes
/// (the last submit completes) before the event is delivered.
Future<void> _playOut(_Tapped t, Random rng, {void Function()? check, int every = 1}) async {
  var n = 0;
  while (!t.host.game.isOver) {
    expect(++n, lessThan(5000));
    await _step(t, rng);
    if (check != null && n % every == 0 && !t.host.game.isOver) check();
  }
  await until(() => t.guestEvents.any((e) => e is GameVerified || e is VerificationFailed));
  expect(t.guest.verification, isNot(Verification.pending));
  check?.call();
}
