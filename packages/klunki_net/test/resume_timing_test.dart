// KLD-120 follow-up: how long after unlocking the phone until the game goes
// on. One side runs in its own process (test/suspend_peer.dart) and is
// frozen with SIGSTOP like a suspended app; the other side runs here. Both
// sides follow the app's policy (test/app_policy.dart). Each case runs with
// the phone's sockets
// - kept: SIGSTOP alone; the kernel keeps them (and buffers);
// - dropped: a proxy resets them on the phone's side while it is locked,
//   the other end hears nothing (a socket the system takes from a suspended
//   app; the app sees the error at once after resuming);
// - silent: the proxy swallows everything from the lock on and closes
//   nothing, so the phone's old connection looks open until its own
//   keepalive gives up (what the maintainer saw: ~20 s to get back).
//
// "Ready" means: a guest move is accepted by the host.
//
// The regular run uses short keepalive values. KLUNKI_RESUME_MEASURE=1
// measures with the app's real values (ping 2 s, timeout 10 s, relay ping
// 20 s, locked KLUNKI_RESUME_LOCK_S, default 30 s) for the current policy
// and the one before, and prints a table (takes several minutes).
@TestOn('mac-os || linux')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:test/test.dart';

import 'app_policy.dart';
import 'support.dart';

class _Timing {
  final Duration ping, timeout, relayPing, locked;
  const _Timing(this.ping, this.timeout, this.relayPing, this.locked);
}

/// A TCP proxy for the phone's connections: [cut] drops them on the
/// phone's side and lets the other end hear nothing more.
class _Proxy {
  final ServerSocket server;
  final int targetPort;

  /// Whether the phone is the connecting side (else the accepting side).
  final bool phoneConnects;
  final List<(Socket, Socket, List<bool>)> _pairs = [];

  _Proxy._(this.server, this.targetPort, this.phoneConnects) {
    server.listen((inbound) async {
      final Socket outbound;
      try {
        outbound = await Socket.connect(loopback, targetPort);
      } catch (_) {
        inbound.destroy();
        return;
      }
      final cut = [false];
      _pairs.add((inbound, outbound, cut));
      // A reset connection is part of the game here, not a test error.
      inbound.done.ignore();
      outbound.done.ignore();
      inbound.listen((d) => cut[0] ? null : outbound.add(d),
          onDone: () => cut[0] ? null : outbound.destroy(), onError: (_) => cut[0] ? null : outbound.destroy());
      outbound.listen((d) => cut[0] ? null : inbound.add(d),
          onDone: () => cut[0] ? null : inbound.destroy(), onError: (_) => cut[0] ? null : inbound.destroy());
    });
  }

  static Future<_Proxy> start(int targetPort, {required bool phoneConnects}) async =>
      _Proxy._(await ServerSocket.bind(loopback, 0), targetPort, phoneConnects);

  int get port => server.port;

  void cut({bool silently = false}) {
    for (final (inbound, outbound, flag) in _pairs) {
      flag[0] = true;
      if (!silently) (phoneConnects ? inbound : outbound).destroy();
    }
    if (!silently) _pairs.clear();
  }

  Future<void> close() async {
    for (final (a, b, _) in _pairs) {
      a.destroy();
      b.destroy();
    }
    await server.close();
  }
}

class _Peer {
  final Process process;
  final List<Map<String, dynamic>> lines = [];
  _Peer._(this.process) {
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((l) {
      lines.add(jsonDecode(l) as Map<String, dynamic>);
    });
    process.stderr.transform(utf8.decoder).listen(stderr.write);
  }

  static Future<_Peer> start(List<String> args, _Timing t, String policy) async {
    final peer = _Peer._(await Process.start(Platform.resolvedExecutable, ['test/suspend_peer.dart', ...args],
        environment: {
          'KLUNKI_PEER_PING_MS': '${t.ping.inMilliseconds}',
          'KLUNKI_PEER_TIMEOUT_MS': '${t.timeout.inMilliseconds}',
          'KLUNKI_PEER_POLICY': policy,
        }));
    addTearDown(() {
      peer.process.kill(ProcessSignal.sigcont);
      peer.process.kill();
    });
    await peer.waitFor((m) => m['e'] == 'ready', limit: const Duration(seconds: 60));
    return peer;
  }

  Map<String, dynamic> get ready => lines.firstWhere((m) => m['e'] == 'ready');

  void send(String command) => process.stdin.writeln(command);

  Future<Map<String, dynamic>> waitFor(bool Function(Map<String, dynamic>) test,
      {Duration limit = const Duration(seconds: 10)}) async {
    await until(() => lines.any(test), limit: limit);
    return lines.lastWhere(test);
  }
}

/// Plays one locked-phone case; returns the time from unlocking to ready.
Future<Duration> _run(
    {required bool hostLocked, required bool viaRelay, required String sockets, required _Timing t, required String policy, Duration? seemsAway}) async {
  const config = GameConfig('connect4');
  final relay = await RelayServer.start(port: 0, address: loopback, pingInterval: t.relayPing);
  addTearDown(relay.close);
  final relayUrl = Uri.parse('ws://127.0.0.1:${relay.port}/relay');
  final limit = t.locked + t.timeout * 4 + const Duration(seconds: 30);

  // The phone's connections go through the proxy.
  _Proxy? proxy;
  late final _Peer peer;
  KlunkiHost? host;
  KlunkiGuest? guest;
  if (hostLocked) {
    if (viaRelay) {
      proxy = await _Proxy.start(relay.port, phoneConnects: true);
      peer = await _Peer.start(['host', 'relay', 'ws://127.0.0.1:${proxy.port}/relay'], t, policy);
      guest = await KlunkiGuest.connectRelay(relayUrl, peer.ready['code'] as String,
          name: 'Bea', pingInterval: t.ping, timeout: t.timeout);
    } else {
      peer = await _Peer.start(['host', 'lan'], t, policy);
      proxy = await _Proxy.start(peer.ready['port'] as int, phoneConnects: false);
      guest = await KlunkiGuest.connect(loopback, proxy.port, name: 'Bea', pingInterval: t.ping, timeout: t.timeout);
    }
  } else {
    host = viaRelay
        ? await KlunkiHost.startRelay(config, relayUrl, name: 'Ada', pingInterval: t.ping, timeout: t.timeout)
        : await KlunkiHost.start(config,
            address: loopback, wsPort: null, name: 'Ada', pingInterval: t.ping, timeout: t.timeout);
    proxy = await _Proxy.start(viaRelay ? relay.port : host.port, phoneConnects: true);
    peer = await _Peer.start(
        viaRelay
            ? ['guest', 'relay', 'ws://127.0.0.1:${proxy.port}/relay', host.roomCode!]
            : ['guest', 'lan', '${proxy.port}'],
        t,
        policy);
  }
  addTearDown(() async {
    await host?.close();
    await guest?.close();
    await proxy?.close();
  });
  final policyHere = AppPolicy.named(policy, timeout: t.timeout, host: host, guest: guest);
  addTearDown(policyHere.dispose);
  final here = <String>[];
  (host?.events ?? guest!.events).listen((e) => here.add('${DateTime.now().toIso8601String().substring(11)} $e'));
  addTearDown(() {
    if (Platform.environment['KLUNKI_RESUME_VERBOSE'] != '1') return;
    // ignore: avoid_print
    print('here:\n  ${here.join('\n  ')}\npeer:\n  ${peer.lines.join('\n  ')}');
  });

  // The host's first move reaches the guest.
  if (host != null) {
    await until(() => host!.guestConnected);
    expect(host.submitLocal({'col': 3}), isNull);
    await peer.waitFor((m) => m['e'] == 'event' && m['moves'] == 1);
  } else {
    peer.send('move {"col":3}');
    await until(() => guest!.moves.length == 1);
  }

  peer.process.kill(ProcessSignal.sigstop);
  if (sockets != 'kept') proxy.cut(silently: sockets == 'silent');
  await Future<void>.delayed(t.locked);
  final clock = Stopwatch()..start();
  peer.process.kill(ProcessSignal.sigcont);
  // [seemsAway]: the pause as the app measured it. The first KLD-120 build
  // read a Stopwatch, which may stand still while a phone sleeps.
  peer.send('resume ${(seemsAway ?? t.locked).inMilliseconds}');

  if (hostLocked) {
    while (true) {
      String? reason;
      try {
        reason = await guest!.submit({'col': 4});
      } catch (e) {
        reason = '$e';
      }
      if (reason == null) break;
      if (clock.elapsed > limit) fail('not ready after ${clock.elapsed}: $reason');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  } else {
    peer.send('play {"col":4}');
    await peer.waitFor((m) => m['e'] == 'played', limit: limit);
  }
  final ready = clock.elapsed;
  peer.send('quit');
  await peer.process.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => -1);
  return ready;
}

String _case(bool hostLocked, bool viaRelay, String sockets) =>
    '${hostLocked ? 'host' : 'guest'} locked, ${viaRelay ? 'relay' : 'LAN'}, '
    'sockets $sockets';

void main() {
  const short = _Timing(Duration(milliseconds: 100), Duration(milliseconds: 800), Duration(milliseconds: 300),
      Duration(seconds: 3));
  for (final hostLocked in [false, true]) {
    for (final viaRelay in [false, true]) {
      for (final sockets in ['kept', 'dropped', 'silent']) {
        test('${_case(hostLocked, viaRelay, sockets)}: ready within 3 s after unlocking', () async {
          final ready =
              await _run(hostLocked: hostLocked, viaRelay: viaRelay, sockets: sockets, t: short, policy: 'current');
          expect(ready, lessThan(const Duration(seconds: 3)));
        }, timeout: const Timeout(Duration(seconds: 90)));
      }
    }
  }

  // A relay host whose relay connection went quiet without the app noticing
  // the pause (here: the old policy and a pause that looked short) used to
  // wait forever: the relay dropped the quiet connection and told the guest
  // "host away", the host heard nothing. Its guest timeout brings it back.
  test('host locked, relay, sockets silent, pause not noticed: back after the keepalive timeout', () async {
    final ready = await _run(
        hostLocked: true, viaRelay: true, sockets: 'silent', t: short, policy: 'before', seemsAway: Duration.zero);
    expect(ready, lessThan(short.timeout + const Duration(seconds: 4)));
  }, timeout: const Timeout(Duration(seconds: 90)));

  final measure = Platform.environment['KLUNKI_RESUME_MEASURE'] == '1';
  final lockedFor = Duration(seconds: int.tryParse(Platform.environment['KLUNKI_RESUME_LOCK_S'] ?? '') ?? 30);
  // KLUNKI_RESUME_SEEMS_S: the pause as the build before measured it (a
  // monotonic clock that stood still while the phone slept); the current
  // build takes the wall clock too (PauseClock) and sees the real pause.
  final seems = int.tryParse(Platform.environment['KLUNKI_RESUME_SEEMS_S'] ?? '');
  final real = _Timing(const Duration(seconds: 2), const Duration(seconds: 10), const Duration(seconds: 20), lockedFor);
  group('measure with the app values', () {
    for (final hostLocked in [false, true]) {
      for (final viaRelay in [false, true]) {
        for (final sockets in ['kept', 'dropped', 'silent']) {
          for (final policy in ['before', 'current']) {
            test('${_case(hostLocked, viaRelay, sockets)}, $policy', () async {
              final ready =
                  await _run(hostLocked: hostLocked, viaRelay: viaRelay, sockets: sockets, t: real, policy: policy,
                  seemsAway: policy == 'before' && seems != null ? Duration(seconds: seems) : null);
              // ignore: avoid_print
              print('RESUME-TIMING | ${_case(hostLocked, viaRelay, sockets)} | $policy'
                  '${policy == 'before' && seems != null ? ' (pause seemed $seems s)' : ''} | '
                  '${(ready.inMilliseconds / 1000).toStringAsFixed(1)} s');
            }, timeout: const Timeout(Duration(minutes: 3)));
          }
        }
      }
    }
  }, skip: measure ? false : 'set KLUNKI_RESUME_MEASURE=1 to measure');
}
