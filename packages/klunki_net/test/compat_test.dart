// KLD-085: build compatibility in the handshake. Two builds that disagree
// on the protocol, a game's rules or its data (e.g. an old PWA with the
// rocket deck from before KLD-082) must not start a game together; a hello
// without the fingerprint fields (a build from before KLD-085) counts as
// incompatible, in both directions.
@Timeout(Duration(seconds: 60))
library;

import 'dart:async';
import 'dart:io';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:klunki_net/src/compat.dart' show mismatchErrorFields, mismatchFromError;
import 'package:test/test.dart';

import 'relay_test.dart' show RelayPeer, openRoom, relayUrlOf;
import 'support.dart';

const _rockets = GameConfig('quartett-trumpf', seed: 7, deck: 'rockets');
const _rocketsKey = 'quartett-trumpf/rockets';
const _ping = Duration(milliseconds: 50);
const _timeout = Duration(seconds: 3);

/// This build's fingerprints with [key] replaced by [f] (removed if null).
BuildCompat _build(String build, {String? key, GameFingerprint? f, bool remove = false}) {
  final games = Map.of(allFingerprints());
  if (key != null) {
    if (remove) {
      games.remove(key);
    } else {
      games[key] = f!;
    }
  }
  return BuildCompat(build: build, games: games);
}

/// The rocket deck as a build from before KLD-082 had it: revision 1, other
/// data (year stats), with this build's rules.
final _oldRockets = GameFingerprint(rules: specById('quartett-trumpf')!.rulesVersion, revision: 1, content: '0' * 32);

/// Every way a guest can reach a host: direct TCP, WebSocket, relay.
enum Via { tcp, ws, relay }

class _Session {
  final KlunkiHost host;
  final RelayServer? relay;
  final List<NetEvent> hostEvents = [];
  _Session(this.host, this.relay) {
    host.events.listen(hostEvents.add);
  }

  static Future<_Session> start(Via via, GameConfig config, BuildCompat compat) async {
    if (via == Via.relay) {
      final relay = await RelayServer.start(port: 0, address: loopback);
      final host = await KlunkiHost.startRelay(config, relayUrlOf(relay),
          name: 'Ada', pingInterval: _ping, timeout: _timeout, compat: compat);
      return _Session(host, relay);
    }
    final host = await KlunkiHost.start(config,
        address: loopback, name: 'Ada', pingInterval: _ping, timeout: _timeout, compat: compat);
    return _Session(host, null);
  }

  Future<KlunkiGuest> join(Via via, BuildCompat compat) => switch (via) {
        Via.tcp => KlunkiGuest.connect(loopback, host.port,
            name: 'Bea', pingInterval: _ping, timeout: _timeout, compat: compat),
        Via.ws => KlunkiGuest.connectWebSocket(webSocketUri('127.0.0.1', host.wsPort!),
            name: 'Bea', pingInterval: _ping, timeout: _timeout, compat: compat),
        Via.relay => KlunkiGuest.connectRelay(relayUrlOf(relay!), host.roomCode!,
            name: 'Bea', pingInterval: _ping, timeout: _timeout, compat: compat),
      };

  Iterable<VersionMismatch> get refused => hostEvents.whereType<IncompatiblePeer>().map((e) => e.mismatch);

  Future<void> close() async {
    await host.close();
    await relay?.close();
  }
}

Matcher _mismatch(Incompatibility kind, PeerAge peer) => isA<NetException>()
    .having((e) => e.mismatch?.kind, 'kind', kind)
    .having((e) => e.mismatch?.peer, 'peer', peer)
    .having((e) => e.message, 'message', contains('reload'));

void main() {
  for (final via in Via.values) {
    group('over ${via.name}', () {
      test('matching builds play; the host announces its game fingerprint', () async {
        final s = await _Session.start(via, _rockets, BuildCompat(build: '1.0.0+2'));
        final guest = await s.join(via, BuildCompat(build: '1.0.0+2'));
        await until(() => s.host.guestConnected);
        expect(guest.config.deck, 'rockets');
        expect(s.refused, isEmpty);
        await guest.close();
        await s.close();
      });

      test('content mismatch (old rocket deck on the guest): refused, the guest is the older side', () async {
        final s = await _Session.start(via, _rockets, BuildCompat(build: '1.0.0+2'));
        await expectLater(s.join(via, _build('1.0.0+1', key: _rocketsKey, f: _oldRockets)),
            throwsA(_mismatch(Incompatibility.content, PeerAge.newer)));
        await until(() => s.refused.isNotEmpty);
        expect(s.refused.single.kind, Incompatibility.content);
        expect(s.refused.single.peer, PeerAge.older);
        expect(s.refused.single.peerBuild, '1.0.0+1');
        expect(s.host.guestConnected, isFalse);
        // The host keeps waiting for a guest that fits.
        final ok = await s.join(via, BuildCompat());
        await until(() => s.host.guestConnected);
        await ok.close();
        await s.close();
      });

      test('KLD-116: both sides know each other\'s name and build label (guest refused by the host)', () async {
        final s = await _Session.start(via, _rockets, BuildCompat(build: '1.1.0+2026110301 c3d4e5f'));
        final error = await s
            .join(via, _build('1.0.0+2026110201 b8752a9', key: _rocketsKey, f: _oldRockets))
            .then<Object?>((_) => null, onError: (Object e) => e);
        final mine = (error as NetException).mismatch!;
        expect((mine.myName, mine.myBuild), ('Bea', '1.0.0+2026110201 b8752a9'));
        expect((mine.peerName, mine.peerBuild), ('Ada', '1.1.0+2026110301 c3d4e5f'));
        expect((versionDisplay(mine.myBuild), versionDisplay(mine.peerBuild)), ('1.0.0 (b8752a9)', '1.1.0 (c3d4e5f)'));
        await until(() => s.refused.isNotEmpty);
        final host = s.refused.single;
        expect((host.myName, host.myBuild), ('Ada', '1.1.0+2026110301 c3d4e5f'));
        expect((host.peerName, host.peerBuild), ('Bea', '1.0.0+2026110201 b8752a9'));
        await s.close();
      });

      test('KLD-116: names and builds also when the guest refuses the host', () async {
        final s = await _Session.start(via, _rockets, _build('1.0.0+3 aaaaaaa', key: _rocketsKey, f: _oldRockets));
        final error = await s
            .join(via, BuildCompat(build: '1.0.0+4 bbbbbbb'))
            .then<Object?>((_) => null, onError: (Object e) => e);
        final mine = (error as NetException).mismatch!;
        expect((mine.myName, mine.peerName, mine.myBuild, mine.peerBuild), ('Bea', 'Ada', '1.0.0+4 bbbbbbb', '1.0.0+3 aaaaaaa'));
        await until(() => s.refused.isNotEmpty);
        final host = s.refused.single;
        expect((host.myName, host.peerName, host.myBuild, host.peerBuild), ('Ada', 'Bea', '1.0.0+3 aaaaaaa', '1.0.0+4 bbbbbbb'));
        await s.close();
      });

      test('content mismatch (old rocket deck on the host): refused, the host is the older side', () async {
        final s = await _Session.start(via, _rockets, _build('', key: _rocketsKey, f: _oldRockets));
        await expectLater(s.join(via, BuildCompat()), throwsA(_mismatch(Incompatibility.content, PeerAge.older)));
        await until(() => s.refused.isNotEmpty);
        expect(s.refused.single.peer, PeerAge.newer);
        await s.close();
      });

      test('rules mismatch: refused with incompatible-rules', () async {
        final mine = fingerprintOf(const GameConfig('muehle'))!;
        final newer = GameFingerprint(rules: mine.rules + 1, revision: mine.revision, content: mine.content);
        final s = await _Session.start(via, const GameConfig('muehle'), BuildCompat());
        await expectLater(
            s.join(via, _build('', key: 'muehle', f: newer)), throwsA(_mismatch(Incompatibility.rules, PeerAge.older)));
        await until(() => s.refused.isNotEmpty);
        expect(s.refused.single.kind, Incompatibility.rules);
        expect(s.refused.single.peer, PeerAge.newer);
        await s.close();
      });

      test('a guest that does not know the deck: content mismatch, the guest is older', () async {
        final s = await _Session.start(via, _rockets, BuildCompat());
        await expectLater(s.join(via, _build('', key: _rocketsKey, remove: true)),
            throwsA(_mismatch(Incompatibility.content, PeerAge.newer)));
        await s.close();
      });

      test('a content-only difference with the same revision: which side is older comes from the build label',
          () async {
        final mine = fingerprintOf(_rockets)!;
        final other = GameFingerprint(rules: mine.rules, revision: mine.revision, content: 'f' * 32);
        final s = await _Session.start(via, _rockets, BuildCompat(build: '1.2.0+5 abc'));
        await expectLater(s.join(via, _build('1.1.9+9 def', key: _rocketsKey, f: other)),
            throwsA(_mismatch(Incompatibility.content, PeerAge.newer)));
        await until(() => s.refused.isNotEmpty);
        expect(s.refused.single.peer, PeerAge.older);
        await s.close();
      });

      test('a photo-only update stays compatible (other build label, same fingerprints)', () async {
        final s = await _Session.start(via, _rockets, BuildCompat(build: '1.0.0+1'));
        final guest = await s.join(via, BuildCompat(build: '1.0.0+2'));
        await until(() => s.host.guestConnected);
        await guest.close();
        await s.close();
      });
    });
  }

  group('a guest from before KLD-085 (protocol 2, no fingerprint) is refused', () {
    test('over TCP: error in its own envelope version, readable by the old build', () async {
      final s = await _Session.start(Via.tcp, _rockets, BuildCompat());
      final old = await RawPeer.connect(s.host.port);
      old.send('hello', {'role': 'guest', 'name': 'Old', 'protocol': 2}, 2);
      final error = await old.next('error');
      expect(error['v'], 2);
      expect(error['code'], 'incompatible-protocol');
      expect(error['message'], contains('newer Klunki'));
      expect(error['message'], contains('reload'));
      await until(() => old.closed && s.refused.isNotEmpty);
      expect(s.refused.single.kind, Incompatibility.protocol);
      expect(s.refused.single.peer, PeerAge.older);
      expect(s.host.guestConnected, isFalse);
      await s.close();
    });

    test('over the relay', () async {
      final s = await _Session.start(Via.relay, _rockets, BuildCompat());
      final old = await RelayPeer.connect(s.relay!, 'join=${s.host.roomCode}');
      old.send('{"type":"hello","v":2,"role":"guest","name":"Old","protocol":2}');
      final error = await old.nextJson();
      expect(error['type'], 'error');
      expect(error['v'], 2);
      expect(error['code'], 'incompatible-protocol');
      await until(() => s.refused.isNotEmpty);
      expect(s.refused.single.peer, PeerAge.older);
      await old.close();
      await s.close();
    });

    test('a current envelope but no "games" in hello is refused too (missing = incompatible)', () async {
      final s = await _Session.start(Via.tcp, _rockets, BuildCompat());
      final peer = await RawPeer.connect(s.host.port);
      peer.send('hello', {'role': 'guest', 'name': 'Odd', 'protocol': protocolVersion});
      expect((await peer.next('error'))['code'], 'incompatible-protocol');
      await until(() => peer.closed);
      expect(s.refused.single.kind, Incompatibility.protocol);
      await s.close();
    });
  });

  group('a host from before KLD-085 is detected by the new guest', () {
    /// An old host (protocol 2): its connection refuses our envelope
    /// version the way protocol 2 did, with an error in v 2.
    Future<void> oldHostAnswer(void Function(String line) send) async =>
        send('{"type":"error","v":2,"message":"unsupported protocol version 3 (expected 2)"}');

    test('over TCP', () async {
      final fake = await ServerSocket.bind(loopback, 0);
      fake.listen((s) {
        final peer = RawPeer(s);
        peer.next('hello').then((_) => oldHostAnswer(peer.line));
      });
      await expectLater(KlunkiGuest.connect(loopback, fake.port, timeout: _timeout),
          throwsA(_mismatch(Incompatibility.protocol, PeerAge.older)));
      await fake.close();
    });

    test('over the relay', () async {
      final relay = await RelayServer.start(port: 0, address: loopback);
      final (host, code) = await openRoom(relay);
      unawaited(() async {
        expect(await host.nextJson(), {'t': 'relay.peer'});
        await host.next(); // the guest's hello
        await oldHostAnswer(host.send);
      }());
      await expectLater(KlunkiGuest.connectRelay(relayUrlOf(relay), code, timeout: _timeout),
          throwsA(_mismatch(Incompatibility.protocol, PeerAge.older)));
      await host.close();
      await relay.close();
    });

    test('an old host that answers in protocol 2 anyway (hello + welcome) is not played', () async {
      final fake = await ServerSocket.bind(loopback, 0);
      final peers = <RawPeer>[];
      fake.listen((s) {
        final peer = RawPeer(s);
        peers.add(peer);
        peer.next('hello').then((_) => peer
          ..send('hello', {'role': 'host', 'name': 'Old', 'protocol': 2}, 2)
          ..send('welcome', {
            'config': {'game': 'quartett-trumpf', 'deck': 'rockets'},
            'you': 'b',
            'token': 't',
            'host': 'Old',
          }, 2));
      });
      await expectLater(KlunkiGuest.connect(loopback, fake.port, timeout: _timeout),
          throwsA(_mismatch(Incompatibility.protocol, PeerAge.older)));
      // The guest told the old host why, in the old host's envelope version.
      final error = await peers.single.next('error');
      expect(error['v'], 2);
      expect(error['code'], 'incompatible-protocol');
      await fake.close();
    });

    test('a host hello without a fingerprint is refused (missing = incompatible)', () async {
      final fake = await ServerSocket.bind(loopback, 0);
      final peers = <RawPeer>[];
      fake.listen((s) {
        final peer = RawPeer(s);
        peers.add(peer);
        peer.next('hello').then((_) => peer
          ..send('hello', {'role': 'host', 'name': 'Odd', 'protocol': protocolVersion})
          ..send('welcome', {
            'config': {'game': 'connect4', 'seed': 0},
            'you': 'b',
            'moves': [],
            'token': 't',
          }));
      });
      await expectLater(KlunkiGuest.connect(loopback, fake.port, timeout: _timeout),
          throwsA(isA<NetException>().having((e) => e.mismatch?.kind, 'kind', Incompatibility.protocol)));
      expect((await peers.single.next('error'))['code'], 'incompatible-protocol');
      await fake.close();
    });

    test('the guest checks the host fingerprint against the deck in welcome', () async {
      final fake = await ServerSocket.bind(loopback, 0);
      fake.listen((s) {
        final peer = RawPeer(s);
        peer.next('hello').then((_) => peer
          // Claims the planes deck's fingerprint, then deals rockets.
          ..send('hello', hostHello(const GameConfig('quartett-trumpf', deck: 'planes'), name: 'Liar'))
          ..send('welcome', {
            'config': {'game': 'quartett-trumpf', 'deck': 'rockets'},
            'you': 'b',
            'token': 't',
            'host': 'Liar',
          }));
      });
      await expectLater(KlunkiGuest.connect(loopback, fake.port, timeout: _timeout),
          throwsA(isA<NetException>().having((e) => e.mismatch?.kind, 'kind', Incompatibility.content)));
      await fake.close();
    });
  });

  test('compareBuilds: by major.minor.patch+build, unknown when equal or unparsable', () {
    expect(compareBuilds('1.0.0+2', '1.0.0+1'), PeerAge.older);
    expect(compareBuilds('1.0.0+2', '1.1.0+1 abc'), PeerAge.newer);
    expect(compareBuilds('2.0.0', '1.9.9+99'), PeerAge.older);
    expect(compareBuilds('1.0.0+1 abc', '1.0.0+1 def'), PeerAge.unknown);
    expect(compareBuilds('', '1.0.0'), PeerAge.unknown);
    expect(compareBuilds('1.0.0', null), PeerAge.unknown);
  });

  group('KLD-116: versionDisplay', () {
    test('version and commit, "dev" without a commit', () {
      expect(versionDisplay('1.0.0+2026110201 b8752a9'), '1.0.0 (b8752a9)');
      expect(versionDisplay('1.1.0+2026110301 c3d4e5f0123456789'), '1.1.0 (c3d4e5f)');
      expect(versionDisplay('1.0.0+1'), '1.0.0 (dev)');
      expect(versionDisplay('2.3.4'), '2.3.4 (dev)');
      expect(versionDisplay(' 1.0.0 abc1234 '), '1.0.0 (abc1234)');
    });
    test('blank is null, anything else is shown as sent', () {
      expect(versionDisplay(null), isNull);
      expect(versionDisplay('  '), isNull);
      expect(versionDisplay('cli'), 'cli');
    });
  });

  group('KLD-116: the refusal error carries the name (informational)', () {
    test('round trip: mismatchErrorFields -> mismatchFromError', () {
      final mine = BuildCompat(build: '1.1.0+2026110301 c3d4e5f');
      final theirs = BuildCompat(build: '1.0.0+2026110201 b8752a9');
      const m = VersionMismatch(Incompatibility.protocol, PeerAge.older, 'x');
      final fields = mismatchErrorFields(m, mine, name: 'Ada');
      expect(fields['name'], 'Ada');
      final back = mismatchFromError(fields, theirs)!;
      expect((back.peerName, back.peerBuild, back.myBuild), ('Ada', '1.1.0+2026110301 c3d4e5f', '1.0.0+2026110201 b8752a9'));
      expect(back.peer, PeerAge.newer);
    });
    test('without a name (older builds) and with junk', () {
      final compat = BuildCompat(build: '1.0.0+1');
      final fields = {'code': 'incompatible-protocol', 'protocol': protocolVersion, 'build': '1.0.0+2'};
      expect(mismatchFromError(fields, compat)!.peerName, isNull);
      expect(mismatchFromError({...fields, 'name': 42}, compat)!.peerName, isNull);
      expect(mismatchFromError({...fields, 'name': '  '}, compat)!.peerName, isNull);
      expect(mismatchFromError({...fields, 'name': ' Bea\n'}, compat)!.peerName, 'Bea');
    });
  });
}
