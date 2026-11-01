import 'dart:async';
import 'dart:io';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart' show Player, QuartettDeck;
import 'package:klunki_net/relay_server.dart';
import 'package:klunki_net/src/cli/cli.dart';
import 'package:klunki_net/src/cli/open_urls.dart';
import 'package:test/test.dart';

/// One terminal: typed lines in, everything printed collected.
class Terminal implements StringSink {
  final String label;
  final _input = StreamController<String>();
  final _text = StringBuffer();
  int _cursor = 0;
  late final Future<int> exitCode;

  Terminal(this.label, List<String> args) {
    exitCode = runCli(args,
        input: _input.stream,
        out: this,
        err: this,
        bindAddress: InternetAddress.loopbackIPv4,
        pingInterval: const Duration(milliseconds: 100),
        timeout: const Duration(seconds: 3));
  }

  String get text => _text.toString();

  /// Waits until [pattern] shows up after everything already waited for.
  Future<Match> waitFor(Pattern pattern, {Duration limit = const Duration(seconds: 5)}) async {
    final sw = Stopwatch()..start();
    while (true) {
      final m = pattern.allMatches(text, _cursor).firstOrNull;
      if (m != null) {
        _cursor = m.end;
        return m;
      }
      if (sw.elapsed > limit) {
        fail('$label: "$pattern" not seen in time. Output after cursor:\n${text.substring(_cursor)}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  void type(String line) {
    _text.writeln(line); // echo, like a terminal
    _input.add(line);
  }

  @override
  void write(Object? object) => _text.write(object);
  @override
  void writeln([Object? object = '']) => _text.writeln(object);
  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) => _text.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => _text.writeCharCode(charCode);
}

/// A loopback TCP relay whose connections can be cut without a `bye`.
class Proxy {
  final ServerSocket _server;
  final List<Socket> _sockets = [];
  Proxy._(this._server);

  static Future<Proxy> start(int targetPort) async {
    final proxy = Proxy._(await ServerSocket.bind(InternetAddress.loopbackIPv4, 0));
    proxy._server.listen((client) async {
      final upstream = await Socket.connect(InternetAddress.loopbackIPv4, targetPort);
      proxy._sockets.addAll([client, upstream]);
      for (final (from, to) in [(client, upstream), (upstream, client)]) {
        from.listen(to.add, onError: (_) {}, onDone: () => to.destroy());
        unawaited(to.done.catchError((_) {}));
      }
    });
    return proxy;
  }

  int get port => _server.port;

  void drop() {
    for (final s in _sockets) {
      s.destroy();
    }
    _sockets.clear();
  }

  Future<void> close() async {
    drop();
    await _server.close();
  }
}

/// The players of [hostAndJoin] (KLD-102: the narration uses their names).
const _names = {Player.a: 'Ada', Player.b: 'Bea'};

Future<(Terminal, Terminal)> hostAndJoin(List<String> hostArgs) async {
  final host = Terminal('host', ['host', ...hostArgs, '--port', '0', '--name', 'Ada']);
  final port = (await host.waitFor(RegExp(r'on 127\.0\.0\.1:(\d+) — waiting for a guest')))[1]!;
  final guest = Terminal('guest', ['join', '127.0.0.1', port, '--name', 'Bea']);
  await host.waitFor('Bea joined: you are X, Bea is O.');
  await guest.waitFor("Joined Ada's game");
  return (host, guest);
}

void main() {
  group('relay startup: "Open on other devices" (KLD-083)', () {
    test('LAN addresses skip loopback, link-local, virtual interfaces and duplicates', () {
      final all = <NicAddress>[
        (interface: 'lo0', address: '127.0.0.1'),
        (interface: 'en0', address: '192.168.1.20'),
        (interface: 'en5', address: '169.254.12.3'),
        (interface: 'docker0', address: '172.17.0.1'),
        (interface: 'br-1a2b', address: '172.18.0.1'),
        (interface: 'vmnet8', address: '192.168.56.1'),
        (interface: 'utun3', address: '100.64.0.2'),
        (interface: 'en1', address: '10.0.0.7'),
        (interface: 'en1', address: '10.0.0.7'),
      ];
      expect(lanAddresses(all), [
        (interface: 'en0', address: '192.168.1.20'),
        (interface: 'en1', address: '10.0.0.7'),
      ]);
    });

    test('the mDNS name: <first label>.local; localhost and empty give none', () {
      expect(mdnsName('my-computer'), 'my-computer.local');
      expect(mdnsName('pc.local'), 'pc.local');
      expect(mdnsName('pc.fritz.box'), 'pc.local');
      expect(mdnsName('localhost.localdomain'), isNull);
      expect(mdnsName('localhost'), isNull);
      expect(mdnsName(''), isNull);
    });

    test('the block aligns the URLs and names IP and mDNS', () {
      final lines = openOnOtherDevices(
        port: 8081,
        lan: [(interface: 'en0', address: '192.168.1.20')],
        mdns: 'my-computer.local',
      );
      expect(lines.take(3), [
        'Open on other devices:',
        '  http://192.168.1.20:8081/       (Wi-Fi/LAN, en0)',
        '  http://my-computer.local:8081/  (Bonjour/mDNS name)',
      ]);
      expect(lines.last, contains('.local names work on Apple devices'));
      expect(
          openOnOtherDevices(port: 4749, lan: [(interface: 'eth0', address: '10.0.0.2')], web: false),
          ['Relay address for other devices:', '  ws://10.0.0.2:4749/relay  (Wi-Fi/LAN, eth0)']);
      expect(openOnOtherDevices(port: 1, lan: const []), isEmpty);
    });
  });

  test('two terminals play Four in a Row to the end over loopback', () async {
    final (host, guest) = await hostAndJoin(['connect4']);
    await host.waitFor('Your turn (X). Ada to move\n> ');
    await guest.waitFor('Waiting for Ada…');

    // Out of turn: refused locally, nothing is sent.
    guest.type('1');
    await guest.waitFor('Not your turn — waiting for Ada.');
    // An illegal move on the host's own turn.
    host.type('9');
    await host.waitFor('Illegal move "9" (illegal move).');

    for (var i = 0; i < 3; i++) {
      host.type('0');
      await host.waitFor('Ada drops into column 0');
      await guest.waitFor('Ada drops into column 0');
      await guest.waitFor('Your turn (O).');
      if (i == 0) {
        // Rejected by the host over the wire (column 9 does not exist).
        guest.type('9');
        await guest.waitFor('Illegal move "9" (illegal move).');
      }
      guest.type('1');
      await guest.waitFor('Bea drops into column 1');
      await host.waitFor('Bea drops into column 1');
      await host.waitFor('Your turn (X).');
    }
    host.type('moves');
    await host.waitFor('Your legal moves: 0 1 2 3 4 5 6');
    host.type('0');

    for (final t in [host, guest]) {
      await t.waitFor('Four in a row: Ada wins!');
      await t.waitFor('Ada wins (four in a row)');
      await t.waitFor('Game over.');
    }
    expect(host.text, contains('you win!'));
    expect(guest.text, contains('you lose.'));
    expect(await host.exitCode, 0);
    expect(await guest.exitCode, 0);
  });

  test('quit ends the game for both sides', () async {
    final (host, guest) = await hostAndJoin(['muehle']);
    guest.type('help');
    await guest.waitFor('Mühle — you are O.');
    guest.type('quit');
    await guest.waitFor('Bye.');
    await host.waitFor('Opponent left (guest left).');
    expect(await guest.exitCode, 0);
    expect(await host.exitCode, 0);
  });

  test('networked Quartett renders the seeded deal and only your own cards', () async {
    final (host, guest) = await hostAndJoin(['quartett-trumpf', '--seed', '42']);
    await host.waitFor((QuartettTrumpfText(42)..names = _names).render());
    await host.waitFor('> ');
    await guest.waitFor('Waiting for Ada…');
    expect(guest.text, isNot(contains("Ada's top card")));
    host.type('quit');
    await guest.waitFor('Opponent left (host left).');
    expect(await host.exitCode, 0);
    expect(await guest.exitCode, 0);
  });

  test('a full Quartett game over the CLI: the guest verifies the host\'s deal at the end (KLD-064)', () async {
    final (host, guest) = await hostAndJoin(['quartett-trumpf', '--seed', '42']);
    final sw = Stopwatch()..start();
    while (!guest.text.contains('Game over.')) {
      expect(sw.elapsed, lessThan(const Duration(seconds: 60)));
      for (final t in [host, guest]) {
        if (t.text.indexOf('Your turn', t._cursor) >= 0) {
          await t.waitFor(RegExp(r'Your turn[^\n]*\n> ', multiLine: true));
          t.type('1');
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    await guest.waitFor("Verified: the host's hidden data matches its commitments");
    expect(guest.text, isNot(contains('Could not verify')));
    expect(await host.exitCode, 0);
    expect(await guest.exitCode, 0);
  });

  test('--deck trains: the host plays the train deck and the guest gets it with the config (KLD-069)', () async {
    final (host, guest) = await hostAndJoin(['quartett-sets', '--seed', '42', '--deck', 'trains']);
    expect(host.text, contains('Hosting Quartett (Sets) – Züge'));
    expect(host.text, contains('"deck":"trains"'));
    await host.waitFor((QuartettSetsText(42, 8, QuartettDeck.trains)..names = _names).render());
    expect(guest.text, contains("Joined Ada's game: Quartett (Sets) – Züge"));
    expect(guest.text, contains('"deck":"trains"'));
    expect(guest.text, isNot(contains('"seed":42')), reason: 'the seed stays secret');
    host.type('quit');
    await guest.waitFor('Opponent left (host left).');
    expect(await host.exitCode, 0);
    expect(await guest.exitCode, 0);
  });

  test('Schiffe: the opponent\'s ship placements are not narrated', () async {
    final (host, guest) = await hostAndJoin(['schiffe']);
    await host.waitFor('> ');
    host.type('A1h');
    await host.waitFor('Ada places a Schlachtschiff (5) at A1 horizontally.');
    await guest.waitFor('Ada places a ship.');
    host.type('fleet 3');
    await host.waitFor('fleet at random (seed 3).');
    await guest.waitFor("Ada places the rest of their fleet. Ada's fleet is ready.");
    await guest.waitFor('Your turn (O).');
    expect(guest.text, isNot(contains('at A1')));
    expect(guest.text, isNot(contains('seed 3')));
    guest.type('quit');
    await host.waitFor('Opponent left (guest left).');
    expect(await host.exitCode, 0);
  });

  test('GoStrategy: host and guest set up and fight; the setup seed stays private', () async {
    final (host, guest) = await hostAndJoin(['gostrategy']);
    await host.waitFor('> ');
    host.type('setup 3');
    await host.waitFor('Ada sets up their army at random (seed 3).');
    await guest.waitFor('Ada has set up their army.');
    await guest.waitFor('Your turn (O).');
    expect(guest.text, isNot(contains('seed 3')));
    expect(guest.text, contains('X?'), reason: "X's pieces render hidden for O");
    guest.type('setup 4');
    await guest.waitFor('Bea sets up their army at random (seed 4).');
    await host.waitFor('Bea has set up their army. Both armies are ready: Ada moves first.');
    await host.waitFor('Your turn (X).');
    expect(host.text, isNot(contains('seed 4')));
    guest.type('quit');
    await host.waitFor('Opponent left (guest left).');
    expect(await host.exitCode, 0);
  });

  test('resign: the guest gives up off turn during the Schiffe setup (KLD-065)', () async {
    final (host, guest) = await hostAndJoin(['schiffe']);
    await host.waitFor('> ');
    await guest.waitFor('Waiting for Ada…');
    guest.type('resign');
    for (final t in [host, guest]) {
      await t.waitFor('Ada wins (Bea resigned)');
      await t.waitFor('Game over.');
    }
    expect(guest.text, contains('You resign. Ada wins.'));
    expect(host.text, contains('Bea resigns. You win!'));
    expect(host.text, contains('you win!'));
    expect(guest.text, contains('you lose.'));
    expect(await host.exitCode, 0);
    expect(await guest.exitCode, 0);
  });

  test('resign: the host gives up on its turn (KLD-065)', () async {
    final (host, guest) = await hostAndJoin(['connect4']);
    await host.waitFor('> ');
    host.type('help');
    await host.waitFor('resign  give up');
    host.type('resign');
    for (final t in [host, guest]) {
      await t.waitFor('Bea wins (Ada resigned)');
      await t.waitFor('Game over.');
    }
    expect(guest.text, contains('Ada resigns. You win!'));
    expect(await host.exitCode, 0);
    expect(await guest.exitCode, 0);
  });

  test('KLD-071: a second terminal with the same name cannot take the seat', () async {
    final host = Terminal('host', ['host', 'connect4', '--port', '0', '--name', 'Ada']);
    final port = (await host.waitFor(RegExp(r'on 127\.0\.0\.1:(\d+) — waiting for a guest')))[1]!;
    final ben = Terminal('guest', ['join', '127.0.0.1', port, '--name', 'Ben']);
    await host.waitFor('Ben joined: you are X, Ben is O.');
    await ben.waitFor("Joined Ada's game");

    for (final name in ['Ben', 'O']) {
      final out = StringBuffer();
      expect(await runCli(['join', '127.0.0.1', port, '--name', name], out: out, input: const Stream.empty()), 1);
      expect(out.toString(), contains('session full'));
      expect(out.toString(), contains('The seat is taken'));
    }
    // The real Ben is still connected and plays on.
    await host.waitFor('> ');
    host.type('3');
    await ben.waitFor('Your turn (O).');
    ben.type('4');
    await host.waitFor('Ben drops into column 4');
    expect(host.text, isNot(contains('Lost the connection')));
    ben.type('quit');
    await host.waitFor('Opponent left (guest left).');
    expect(await ben.exitCode, 0);
    expect(await host.exitCode, 0);
  });

  test('a dropped connection is reported and the guest reconnects', () async {
    final host = Terminal('host', ['host', 'connect4', '--port', '0', '--name', 'Ada']);
    final port = int.parse((await host.waitFor(RegExp(r'on 127\.0\.0\.1:(\d+) — waiting')))[1]!);
    final proxy = await Proxy.start(port);
    final guest = Terminal('guest', ['join', '127.0.0.1:${proxy.port}', '--name', 'Bea']);
    await host.waitFor('Bea joined');
    await host.waitFor('> ');
    host.type('3');
    await guest.waitFor('Your turn (O).');

    proxy.drop(); // like Wi-Fi going away: no bye
    await guest.waitFor('Connection to the host lost');
    await guest.waitFor('Reconnect? [Y/n] ');
    await host.waitFor('Lost the connection to Bea');
    host.type('4');
    await host.waitFor('Your opponent is disconnected');

    guest.type('y');
    await guest.waitFor('Reconnected (1 moves so far).');
    await guest.waitFor('Your turn (O).');
    await host.waitFor('Bea rejoined.');
    guest.type('4');
    await host.waitFor('Bea drops into column 4');
    await host.waitFor('Your turn (X).');

    guest.type('quit');
    await host.waitFor('Opponent left (guest left).');
    expect(await guest.exitCode, 0);
    expect(await host.exitCode, 0);
    await proxy.close();
  });

  test('join ws://: a terminal plays as a WebSocket guest (KLD-054)', () async {
    final host = Terminal('host', ['host', 'connect4', '--port', '0', '--name', 'Ada']);
    final wsUrl = (await host.waitFor(RegExp(r'WebSocket guests join at (ws://127\.0\.0\.1:\d+)')))[1]!;
    final guest = Terminal('guest', ['join', wsUrl, '--name', 'Web']);
    await host.waitFor('Web joined: you are X, Web is O.');
    await guest.waitFor("Joined Ada's game: 4 Gewinnt on $wsUrl");
    await host.waitFor('> ');
    host.type('3');
    await guest.waitFor('Ada drops into column 3');
    await guest.waitFor('Your turn (O).');
    guest.type('4');
    await host.waitFor('Web drops into column 4');
    guest.type('quit');
    await host.waitFor('Opponent left (guest left).');
    expect(await guest.exitCode, 0);
    expect(await host.exitCode, 0);
  });

  test('join ws:// to nothing reports the failure', () async {
    final free = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = free.port;
    await free.close();
    final out = StringBuffer();
    expect(await runCli(['join', 'ws://127.0.0.1:$port'], out: out, input: const Stream.empty()), 1);
    expect(out.toString(), contains('Could not join ws://127.0.0.1:$port'));
  });

  test('relay: two terminals play through a relay room (KLD-057a)', () async {
    final relay = await RelayServer.start(port: 0, address: InternetAddress.loopbackIPv4);
    addTearDown(relay.close);
    final url = 'ws://127.0.0.1:${relay.port}';
    final host = Terminal('host', ['host', 'connect4', '--relay', url, '--name', 'Ada']);
    final code = (await host.waitFor(RegExp(r'Room code: ([A-Z0-9]{5})')))[1]!;
    await host.waitFor('Hosting 4 Gewinnt in relay room $code on $url/relay — waiting for a guest…');
    await host.waitFor('join --relay $url/relay --room $code');
    final guest = Terminal('guest', ['join', '--relay', '127.0.0.1:${relay.port}', '--room', code.toLowerCase(), '--name', 'Bea']);
    await host.waitFor('Bea joined: you are X, Bea is O.');
    await guest.waitFor("Joined Ada's game: 4 Gewinnt on room $code on $url/relay");
    await host.waitFor('> ');
    host.type('3');
    await guest.waitFor('Ada drops into column 3');
    guest.type('4');
    await host.waitFor('Bea drops into column 4');
    guest.type('quit');
    await host.waitFor('Opponent left (guest left).');
    expect(await guest.exitCode, 0);
    expect(await host.exitCode, 0);
  });

  test('relay: a wrong room code is reported; the relay command starts and stops', () async {
    final stop = Completer<void>();
    final out = StringBuffer();
    final relayExit = runCli(['relay', '--port', '0'],
        out: out, bindAddress: InternetAddress.loopbackIPv4, relayStop: stop.future);
    await until(() => out.toString().contains('Press Ctrl+C to stop.'));
    final port = RegExp(r'listening on port (\d+): ws://127\.0\.0\.1:\1/relay').firstMatch(out.toString())![1]!;
    final joinOut = StringBuffer();
    expect(
        await runCli(['join', '--relay', 'ws://127.0.0.1:$port', '--room', '22222'],
            out: joinOut, input: const Stream.empty()),
        1);
    expect(joinOut.toString(), contains('Could not join room 22222 on ws://127.0.0.1:$port/relay: relay: no room with code 22222'));
    stop.complete();
    expect(await relayExit, 0);
    expect(out.toString(), contains('Relay stopped.'));

    final missing = StringBuffer();
    expect(await runCli(['relay', '--port', '0', '--web', '/no/such/dir'], out: missing), 1);
    expect(missing.toString(), contains('No such directory'));
  });

  test('bad arguments print the usage text and exit 64', () async {
    for (final args in [
      <String>[],
      ['host'],
      ['host', 'backgammon'],
      ['host', 'connect4', '--port', 'x'],
      ['join'],
      ['join', '1.2.3.4', 'notaport'],
      ['join', 'ws://1.2.3.4:4748', '4748'],
      ['join', 'http://1.2.3.4:4748'],
      ['join', '1.2.3.4', '--ws-port', '1'],
      ['frobnicate'],
      ['relay', '--port'],
      ['relay', '--port', 'x'],
      ['relay', '--frob'],
      ['host', 'connect4', '--relay', 'ftp://x'],
      ['host', 'connect4', '--relay', 'ws://1.2.3.4', '--port', '1'],
      ['host', 'connect4', '--room', 'K7Q2M'],
      ['join', '--relay', 'ws://1.2.3.4'],
      ['join', '--room', 'K7Q2M'],
      ['join', '--relay', 'ws://1.2.3.4', '--room', 'K7Q2O'],
      ['join', '--relay', 'ws://1.2.3.4', '--room', 'K7Q2M', '1.2.3.4'],
      ['host', 'quartett-trumpf', '--deck', 'boats'],
      ['host', 'quartett-trumpf', '--deck'],
      ['host', 'connect4', '--deck', 'trains'],
      ['join', '1.2.3.4', '--deck', 'trains'],
    ]) {
      final err = StringBuffer();
      expect(await runCli(args, err: err, out: err, input: const Stream.empty()), usageExit, reason: '$args');
      expect(err.toString(), contains('Usage:'));
    }
  });

  test('bin/klunki.dart runs as a process (usage, exit 64)', () async {
    final p = await Process.run(Platform.resolvedExecutable, ['run', 'bin/klunki.dart']);
    expect(p.exitCode, usageExit);
    expect(p.stderr, contains('dart run packages/klunki_net/bin/klunki.dart host <game>'));
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<void> until(bool Function() condition, {Duration limit = const Duration(seconds: 5)}) async {
  final sw = Stopwatch()..start();
  while (!condition()) {
    if (sw.elapsed > limit) throw TimeoutException('condition not met', limit);
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
