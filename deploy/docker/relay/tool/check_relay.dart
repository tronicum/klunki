import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Checks a running Klunki relay from the outside (KLD-114): the Docker
/// image, a Cloudflare Worker deployment or a plain `klunki relay`.
///
///   dart run tool/check_relay.dart ws://127.0.0.1:4749/relay [CLUBCODE]
///   dart run tool/check_relay.dart wss://relay.example.org/relay K7QX-M2PA
///
/// With CLUBCODE it expects a gated relay: no code → `club-missing`, a wrong
/// code → `club-wrong` (two wrong attempts count towards the relay's limit
/// of 10 per 10 minutes). Then, with the code (or without one on an open
/// relay), it opens a room, joins it, sends one `ping` each way, leaves as
/// the guest (`relay.left`) and closes the room. Prints one line per step;
/// exit code 0 = all fine. The club code is never printed.
Future<void> main(List<String> args) async {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln('usage: dart run tool/check_relay.dart ws[s]://HOST[:PORT]/relay [CLUBCODE]');
    exit(64);
  }
  final ok = await checkRelay(Uri.parse(args[0]), args.length > 1 ? args[1] : null, stdout.writeln);
  exit(ok ? 0 : 1);
}

Future<bool> checkRelay(Uri relay, String? club, void Function(String) say) async {
  final clubQuery = club == null ? '' : '&club=${Uri.encodeQueryComponent(club)}';
  try {
    if (club != null) {
      await _expectRefusal(relay, 'create', 'club-missing', say);
      await _expectRefusal(relay, 'create&club=WRONG-CODE', 'club-wrong', say);
      await _expectRefusal(relay, 'join=22222&club=WRONG-CODE', 'club-wrong', say);
    }
    final host = await _Peer.connect(relay, 'create$clubQuery');
    final room = await host.next();
    if (room['t'] != 'relay.room') throw StateError('create: expected relay.room, got $room');
    final code = room['code'] as String;
    say('ok: room $code opened');
    final guest = await _Peer.connect(relay, 'join=${code.toLowerCase()}$clubQuery');
    _expect(await host.next(), {'t': 'relay.peer'}, 'host sees the guest');
    say('ok: guest joined');
    const ping = '{"type":"ping","v":3}';
    const pong = '{"type":"pong","v":3}';
    guest.ws.add(ping);
    if (await host.nextRaw() != ping) throw StateError('guest → host: line changed');
    host.ws.add(pong);
    if (await guest.nextRaw() != pong) throw StateError('host → guest: line changed');
    say('ok: lines forwarded both ways, unchanged');
    await guest.ws.close();
    final left = await host.next();
    if (left['t'] != 'relay.left') throw StateError('guest left: expected relay.left, got $left');
    say('ok: host told that the guest left (${left['reason']})');
    await host.ws.close();
    say('ok: room closed. The relay works.');
    return true;
  } catch (e) {
    say('FAILED: $e');
    return false;
  }
}

Future<void> _expectRefusal(Uri relay, String query, String error, void Function(String) say) async {
  final peer = await _Peer.connect(relay, query);
  final msg = await peer.next();
  if (msg['t'] != 'relay.error' || msg['error'] != error) {
    throw StateError('expected relay.error $error, got $msg');
  }
  await peer.done();
  say('ok: refused with $error (${query.startsWith('join') ? 'join' : 'create'})');
}

void _expect(Map<String, dynamic> got, Map<String, Object?> want, String what) {
  if (jsonEncode(got) != jsonEncode(want)) throw StateError('$what: expected $want, got $got');
}

class _Peer {
  final WebSocket ws;
  final _lines = StreamController<String>();
  final _closed = Completer<void>();
  late final StreamIterator<String> _it = StreamIterator(_lines.stream);

  _Peer(this.ws) {
    ws.listen((f) => _lines.add('$f'), onDone: () {
      _lines.close();
      if (!_closed.isCompleted) _closed.complete();
    }, onError: (_) {});
  }

  static Future<_Peer> connect(Uri relay, String query) async =>
      _Peer(await WebSocket.connect('${relay.replace(query: query)}').timeout(const Duration(seconds: 10)));

  Future<String> nextRaw() async {
    if (!await _it.moveNext().timeout(const Duration(seconds: 10))) throw StateError('connection closed');
    return _it.current;
  }

  Future<Map<String, dynamic>> next() async => jsonDecode(await nextRaw()) as Map<String, dynamic>;

  Future<void> done() => _closed.future.timeout(const Duration(seconds: 10));
}
