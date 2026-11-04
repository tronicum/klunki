// One side of a session in its own process, so a test can freeze it with
// SIGSTOP like a phone that locks (KLD-120). Not a test file itself.
//
//   dart test/suspend_peer.dart host lan
//   dart test/suspend_peer.dart host relay ws://127.0.0.1:P/relay
//   dart test/suspend_peer.dart guest lan PORT
//   dart test/suspend_peer.dart guest relay ws://127.0.0.1:P/relay CODE
//
// Prints one JSON object per line: {"e":"ready",...} once, then
// {"e":"event","kind":...,"text":...} for every NetEvent. Reads commands on
// stdin: `move {"col":3}`, `reconnect`, `resume`, `quit`.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';

const _ping = Duration(milliseconds: 100);
const _timeout = Duration(milliseconds: 800);

void _say(Map<String, Object?> m) => stdout.writeln(jsonEncode(m));

Future<void> main(List<String> args) async {
  final config = const GameConfig('connect4');
  final loopback = InternetAddress.loopbackIPv4;
  KlunkiHost? host;
  KlunkiGuest? guest;
  switch (args) {
    case ['host', 'lan']:
      host = await KlunkiHost.start(config,
          address: loopback, wsPort: null, name: 'Ada', pingInterval: _ping, timeout: _timeout);
    case ['host', 'relay', final url]:
      host = await KlunkiHost.startRelay(config, Uri.parse(url), name: 'Ada', pingInterval: _ping, timeout: _timeout);
    case ['guest', 'lan', final port]:
      guest = await KlunkiGuest.connect(loopback, int.parse(port), name: 'Bea', pingInterval: _ping, timeout: _timeout);
    case ['guest', 'relay', final url, final code]:
      guest = await KlunkiGuest.connectRelay(Uri.parse(url), code, name: 'Bea', pingInterval: _ping, timeout: _timeout);
    default:
      stderr.writeln('bad arguments: $args');
      exit(64);
  }
  final events = host?.events ?? guest!.events;
  events.listen((e) => _say({
        'e': 'event',
        'kind': e.runtimeType.toString(),
        'text': '$e',
        'moves': host?.moves.length ?? guest!.moves.length,
      }));
  _say({'e': 'ready', 'port': host?.port, 'code': host?.roomCode});
  await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    final space = line.indexOf(' ');
    final cmd = space < 0 ? line : line.substring(0, space);
    final rest = space < 0 ? '' : line.substring(space + 1);
    switch (cmd) {
      case 'move':
        final move = jsonDecode(rest) as Map<String, dynamic>;
        final reason = host != null ? host.submitLocal(move) : await guest!.submit(move);
        _say({'e': 'move', 'reason': reason});
      case 'reconnect':
        try {
          await guest!.reconnect();
          _say({'e': 'reconnect', 'ok': true});
        } catch (e) {
          _say({'e': 'reconnect', 'ok': false, 'error': '$e'});
        }
      case 'resume':
        await host?.resume(away: Duration(milliseconds: int.tryParse(rest) ?? 0));
        _say({'e': 'resumed'});
      case 'quit':
        await host?.close();
        await guest?.close();
        exit(0);
    }
  }
}
