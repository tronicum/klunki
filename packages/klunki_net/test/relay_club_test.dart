// KLD-112: club codes (server access codes) for a self-hosted relay
// (`klunki relay --codes FILE`). Without the file the relay is open, exactly
// as before; with it, every WebSocket must carry a current code.
@Timeout(Duration(seconds: 60))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:klunki_net/src/cli/cli.dart';
import 'package:klunki_net/src/relay/relay_protocol.dart' show relayCreateUri, relayJoinUri;
import 'package:test/test.dart';

import 'support.dart';

const _ping = Duration(milliseconds: 50);
const _timeout = Duration(seconds: 3);

/// A raw WebSocket client: the frames it got, and whether it was closed.
class _Peer {
  final WebSocket ws;
  final List<String> lines = [];
  bool closed = false;
  int _cursor = 0;

  _Peer(this.ws) {
    ws.listen((f) => lines.add(f as String), onError: (_) => closed = true, onDone: () => closed = true);
  }

  static Future<_Peer> connect(RelayServer relay, String query) async =>
      _Peer(await WebSocket.connect('ws://127.0.0.1:${relay.port}/relay?$query'));

  Future<Map<String, dynamic>> nextJson() async {
    await until(() => _cursor < lines.length);
    return jsonDecode(lines[_cursor++]) as Map<String, dynamic>;
  }

  Future<void> close() => ws.close();
}

Uri _url(RelayServer relay) => Uri.parse('ws://127.0.0.1:${relay.port}/relay');

const _missing = {'t': 'relay.error', 'error': 'club-missing', 'message': 'club code required'};
const _wrong = {'t': 'relay.error', 'error': 'club-wrong', 'message': 'club code not accepted'};

void main() {
  late Directory dir;
  late File file;
  late List<String> log;
  RelayServer? relay;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('klunki_club_');
    file = File('${dir.path}/codes.txt');
    log = [];
  });
  tearDown(() async {
    await relay?.close();
    relay = null;
    await dir.delete(recursive: true);
  });

  Future<RelayServer> gated(String codes, {ClubStrikes? strikes}) async {
    await file.writeAsString(codes);
    return relay = await RelayServer.start(
        port: 0,
        address: loopback,
        random: Random(7),
        clubCodes: await ClubCodes.load(file.path, log: log.add),
        clubStrikes: strikes);
  }

  Future<KlunkiHost> host(String? club) => KlunkiHost.startRelay(const GameConfig('connect4'), _url(relay!),
      name: 'Ada', pingInterval: _ping, timeout: _timeout, clubCode: club);
  Future<KlunkiGuest> guest(String code, String? club, {String? token}) => KlunkiGuest.connectRelay(_url(relay!), code,
      name: 'Bea', token: token, pingInterval: _ping, timeout: _timeout, clubCode: club);
  Matcher refused(String text) => throwsA(isA<NetException>().having((e) => e.message, 'message', 'relay: $text'));

  test('open relay: unchanged, a club code is ignored', () async {
    relay = await RelayServer.start(port: 0, address: loopback);
    expect(relay!.clubCodes, isNull);
    final h = await host('K7QX-M2PA');
    final g = await guest(h.roomCode!, null);
    await until(() => h.guestConnected);
    expect(h.submitLocal({'col': 3}), isNull);
    await until(() => g.moves.length == 1);
    await g.close();
    await h.close();
  });

  test('gated relay: valid codes (any of them, case and dashes ignored) play a game', () async {
    await gated('K7QX-M2PA  # Familie Müller\n# comment only\n\nMNPQ-RSTU\n');
    final h = await host('k7qx m2pa');
    final g = await guest(h.roomCode!, 'MNPQRSTU');
    await until(() => h.guestConnected);
    expect(h.submitLocal({'col': 3}), isNull);
    await until(() => g.moves.length == 1);
    expect(await g.submit({'col': 4}), isNull);
    await g.close();
    await h.close();
  });

  test('missing and wrong codes: distinct refusals, the same for any room (no room-existence leak)', () async {
    await gated('K7QX-M2PA\n');
    final h = await host('K7QX-M2PA');
    final code = h.roomCode!;
    final other = code == '22222' ? '33333' : '22222';
    for (final (query, reply) in [
      ('create', _missing),
      ('join=$code', _missing),
      ('join=$other', _missing),
      ('', _missing),
      ('create&club=', _missing),
      ('create&club=WRONG-CODE', _wrong),
      ('join=$code&club=WRONG-CODE', _wrong),
      ('join=$other&club=WRONG-CODE', _wrong),
      ('join=$code&club=K7Q', _wrong), // too short to be a code at all
    ]) {
      final p = await _Peer.connect(relay!, query);
      expect(await p.nextJson(), reply, reason: query);
      await until(() => p.closed);
    }
    expect(h.guestConnected, isFalse, reason: 'no refused client reached the room');
    await expectLater(host(null), refused('club code required'));
    await expectLater(host('ZZZZ-ZZZZ'), refused('club code not accepted'));
    await expectLater(guest(code, 'ZZZZ-ZZZZ'), refused('club code not accepted'));
    await h.close();
  });

  test('revocation by editing the file: new connections refused at once, the running game finishes', () async {
    await gated('K7QX-M2PA  # Ada\nMNPQ-RSTU  # Bea\n');
    final h = await host('K7QX-M2PA');
    final g = await guest(h.roomCode!, 'MNPQ-RSTU');
    await until(() => h.guestConnected);

    await file.writeAsString('K7QX-M2PA  # Ada\n'); // Bea's line removed, no restart
    await expectLater(guest(h.roomCode!, 'MNPQ-RSTU'), refused('club code not accepted'));
    await expectLater(host('MNPQ-RSTU'), refused('club code not accepted'));
    // The room opened before keeps going.
    expect(h.submitLocal({'col': 3}), isNull);
    await until(() => g.moves.length == 1);
    expect(await g.submit({'col': 4}), isNull);

    // Added again: accepted again.
    await file.writeAsString('K7QX-M2PA  # Ada\nMNPQ-RSTU  # Bea again\n');
    final h2 = await host('MNPQ-RSTU');
    expect(h2.roomCode, isNotNull);

    // An unreadable file refuses everyone (fail closed) until it is back.
    await file.delete();
    await expectLater(host('K7QX-M2PA'), refused('club code not accepted'));
    await file.writeAsString('K7QX-M2PA\n');
    final h3 = await host('K7QX-M2PA');
    await g.close();
    for (final x in [h, h2, h3]) {
      await x.close();
    }
  });

  test('too many wrong codes from one address: refused like a wrong code, even with a valid one', () async {
    await gated('K7QX-M2PA\n', strikes: ClubStrikes(limit: 3));
    for (final wrong in ['BADD-BAD2', 'BADD-BAD3', 'BADD-BAD4']) {
      await expectLater(host(wrong), refused('club code not accepted'));
    }
    await expectLater(host('K7QX-M2PA'), refused('club code not accepted'));
    final p = await _Peer.connect(relay!, 'create&club=K7QX-M2PA');
    expect(await p.nextJson(), {..._wrong, 'message': 'too many wrong club codes, try again later'});
    await until(() => p.closed);
    expect(relay!.roomCount, 0);
  });

  test('ClubStrikes: per address, and forgotten after the window', () async {
    final strikes = ClubStrikes(limit: 2, window: const Duration(milliseconds: 100));
    strikes.strike('a');
    expect(strikes.blocked('a'), isFalse);
    strikes.strike('a');
    expect(strikes.blocked('a'), isTrue);
    expect(strikes.blocked('b'), isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 150)); // a lower bound only: safe under load
    expect(strikes.blocked('a'), isFalse);
    strikes.prune();
  });

  test('the log names labels or a short hash, never a code', () async {
    await gated('K7QX-M2PA  # Familie Müller\nMNPQ-RSTU\nnot a code!\n');
    final codes = relay!.clubCodes!;
    expect(codes.codes.map((c) => c.code), ['K7QXM2PA', 'MNPQRSTU']);
    expect(codes.codes.map((c) => c.label), ['Familie Müller', '']);
    expect(codes.codes.last.logName, matches(RegExp(r'^#[0-9a-f]{6}$')));
    await file.writeAsString('MNPQ-RSTU\n');
    await expectLater(host('K7QX-M2PA'), refused('club code not accepted'));
    final all = log.join('\n');
    expect(all, contains('Familie Müller'));
    expect(all, contains('line 3'));
    expect(all, contains('reloaded'));
    for (final secret in ['K7QX', 'M2PA', 'MNPQ', 'RSTU']) {
      expect(all, isNot(contains(secret)));
    }
  });

  test('codes: normalise, generate, URLs', () {
    expect(normalizeClubCode(' k7qx-m2pa '), 'K7QXM2PA');
    expect(normalizeClubCode('abc'), isNull);
    expect(normalizeClubCode('K7QX_M2PA'), isNull);
    expect(normalizeClubCode('Ä123'), isNull);
    final code = newClubCode(Random(1));
    expect(code, matches(RegExp('^[$roomCodeAlphabet]{4}-[$roomCodeAlphabet]{4}\$')));
    expect(normalizeClubCode(code), code.replaceAll('-', ''));
    final r = Uri.parse('ws://h:1/relay');
    expect(relayCreateUri(r).toString(), 'ws://h:1/relay?create');
    expect(relayCreateUri(r, clubCode: 'K7QX M2PA').toString(), 'ws://h:1/relay?create&club=K7QX+M2PA');
    expect(relayJoinUri(r, 'ABCDE', clubCode: 'K7QXM2PA').queryParameters, {'join': 'ABCDE', 'club': 'K7QXM2PA'});
  });

  test('CLI: relay-code new, relay --codes, host/join --club', () async {
    final out = StringBuffer();
    expect(await runCli(['relay-code', 'new', '--label', 'Familie Müller'], out: out), 0);
    expect(out.toString().trim(), matches(RegExp(r'^[2-9A-Z]{4}-[2-9A-Z]{4}  # Familie Müller$')));
    final err = StringBuffer();
    for (final args in [
      ['relay-code'],
      ['relay-code', 'new', '--label'],
      ['relay', '--codes'],
      ['host', 'connect4', '--club', 'K7QX-M2PA'], // --club only with --relay
      ['host', 'connect4', '--relay', 'ws://1.2.3.4', '--club', 'x'],
      ['join', '1.2.3.4', '--club', 'K7QX-M2PA'],
    ]) {
      expect(await runCli(args, err: err, out: err, input: const Stream.empty()), usageExit, reason: '$args');
    }
    final missing = StringBuffer();
    expect(await runCli(['relay', '--port', '0', '--codes', '${dir.path}/nope.txt'], out: missing), 1);
    expect(missing.toString(), contains('Cannot read the club codes file'));

    await file.writeAsString('K7QX-M2PA  # Ada\n');
    final stop = Completer<void>();
    final relayOut = StringBuffer();
    final relayExit = runCli(['relay', '--port', '0', '--codes', file.path],
        out: relayOut, bindAddress: InternetAddress.loopbackIPv4, relayStop: stop.future);
    await until(() => relayOut.toString().contains('Press Ctrl+C to stop.'));
    expect(relayOut.toString(), contains('Club codes required'));
    expect(relayOut.toString(), contains('Club codes loaded from ${file.path}: 1 (Ada)'));
    final port = RegExp(r'listening on port (\d+)').firstMatch(relayOut.toString())![1]!;
    final joinOut = StringBuffer();
    expect(
        await runCli(['join', '--relay', 'ws://127.0.0.1:$port', '--room', '22222', '--club', 'WRNG-CODE'],
            out: joinOut, input: const Stream.empty()),
        1);
    expect(joinOut.toString(), contains('relay: club code not accepted'));
    final joinOut2 = StringBuffer();
    expect(
        await runCli(['join', '--relay', 'ws://127.0.0.1:$port', '--room', '22222', '--club', 'K7QX-M2PA'],
            out: joinOut2, input: const Stream.empty()),
        1);
    expect(joinOut2.toString(), contains('relay: no room with code 22222'), reason: 'a valid code gets past the gate');
    stop.complete();
    expect(await relayExit, 0);
  });
}
