// KLD-114: the relay protocol vectors in relay_vectors.json, run against the
// real Dart relay over real sockets. The Cloudflare Worker port
// (deploy/cloudflare, `node --test`) runs the same file against its own
// implementation, so both relays answer every scenario the same way.
@Timeout(Duration(seconds: 60))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:klunki_net/relay_server.dart';
import 'package:klunki_net/src/relay/relay_protocol.dart';
import 'package:test/test.dart';

import 'support.dart';

Map<String, dynamic> _vectors() {
  // `dart test` runs with the package root as the working directory.
  final file = File('test/relay_vectors.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// A raw client: every frame it got, and how its connection ended.
class _Peer {
  final WebSocket ws;
  final List<String> lines = [];
  bool closed = false;
  int _cursor = 0;

  _Peer(this.ws) {
    ws.listen((f) => lines.add(f is String ? f : '<binary>'),
        onError: (_) => closed = true, onDone: () => closed = true);
  }

  Future<String> next(String who) async {
    await until(() => _cursor < lines.length || closed, limit: const Duration(seconds: 10));
    if (_cursor >= lines.length) fail('$who: connection closed, expected a message');
    return lines[_cursor++];
  }

  Future<void> expectClosed(String who, int? code) async {
    await until(() => closed, limit: const Duration(seconds: 10));
    expect(lines.length, _cursor, reason: '$who: unread messages ${lines.skip(_cursor).toList()}');
    if (code != null) expect(ws.closeCode, code, reason: '$who: close code');
  }
}

void main() {
  final vectors = _vectors();

  test('normalizeRoomCode', () {
    for (final v in vectors['normalizeRoomCode'] as List) {
      expect(normalizeRoomCode(v[0] as String), v[1], reason: '${v[0]}');
    }
  });

  test('normalizeClubCode', () {
    for (final v in vectors['normalizeClubCode'] as List) {
      expect(normalizeClubCode(v[0] as String), v[1], reason: '${v[0]}');
    }
  });

  test('parseRelayControl', () {
    for (final v in vectors['parseRelayControl'] as List) {
      expect(parseRelayControl(v[0] as String) != null, v[1], reason: '${v[0]}');
    }
  });

  test('codes file', () async {
    final dir = await Directory.systemTemp.createTemp('klunki_vectors_');
    addTearDown(() => dir.delete(recursive: true));
    final spec = vectors['clubCodesFile'] as Map<String, dynamic>;
    final file = File('${dir.path}/codes.txt')..writeAsStringSync(spec['text'] as String);
    final codes = await ClubCodes.load(file.path);
    expect(codes.codes.map((c) => c.code), spec['codes']);
  });

  for (final scenario in (vectors['scenarios'] as List).cast<Map<String, dynamic>>()) {
    test('scenario: ${scenario['name']}', () async {
      Directory? dir;
      ClubCodes? clubCodes;
      if (scenario['codes'] case final String text) {
        dir = await Directory.systemTemp.createTemp('klunki_vectors_');
        final file = File('${dir.path}/codes.txt')..writeAsStringSync(text);
        clubCodes = await ClubCodes.load(file.path);
      }
      final relay = await RelayServer.start(
          port: 0, address: loopback, random: Random(11), pingInterval: null, clubCodes: clubCodes);
      final peers = <String, _Peer>{};
      addTearDown(() async {
        for (final p in peers.values) {
          await p.ws.close().timeout(const Duration(seconds: 2), onTimeout: () {});
        }
        await relay.close();
        await dir?.delete(recursive: true);
      });

      String? room;
      String? key; // the room's host key (KLD-120)
      String fill(String s) {
        if (room != null) s = s.replaceAll('{roomLower}', room.toLowerCase()).replaceAll('{room}', room);
        return key == null ? s : s.replaceAll('{key}', key);
      }

      Object? fillJson(Object? v) => switch (v) {
            String s => fill(s),
            Map m => {for (final e in m.entries) e.key: fillJson(e.value)},
            _ => v,
          };

      final steps = (scenario['steps'] as List).cast<Map<String, dynamic>>();
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        final at = 'step ${i + 1} ${jsonEncode(step)}';
        if (step['open'] case final String who) {
          peers[who] =
              _Peer(await WebSocket.connect('ws://127.0.0.1:${relay.port}/relay?${fill(step['query'] as String)}'));
        } else if (step['room'] case final String who) {
          final msg = jsonDecode(await peers[who]!.next(at)) as Map<String, dynamic>;
          expect(msg['t'], 'relay.room', reason: at);
          room = msg['code'] as String;
          key = msg['key'] as String?;
          expect(normalizeRoomCode(room), room, reason: at);
        } else if (step['recv'] case final String who) {
          expect(jsonDecode(await peers[who]!.next(at)), fillJson(step['json']), reason: at);
        } else if (step['recvText'] case final String who) {
          expect(await peers[who]!.next(at), fill(step['text'] as String), reason: at);
        } else if (step['recvFill'] case final String who) {
          expect(await peers[who]!.next(at), 'x' * (step['length'] as int), reason: at);
        } else if (step['send'] case final String who) {
          peers[who]!.ws.add(step.containsKey('fill') ? 'x' * (step['fill'] as int) : fill(step['text'] as String));
        } else if (step['sendBinary'] case final String who) {
          peers[who]!.ws.add(utf8.encode('{"type":"ping","v":3}'));
        } else if (step['closed'] case final String who) {
          await peers[who]!.expectClosed(at, step['code'] as int?);
        } else if (step['close'] case final String who) {
          await peers[who]!.ws.close(step['code'] as int?);
        } else {
          fail('unknown step $at');
        }
      }
    });
  }
}
