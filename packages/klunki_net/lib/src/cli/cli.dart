import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';

import '../addresses.dart';
import '../events.dart';
import '../guest.dart';
import '../host.dart';
import '../relay/relay_protocol.dart';
import '../relay/relay_server.dart';
import 'open_urls.dart';

/// TCP port `host` listens on unless `--port` is given.
const int defaultPort = defaultTcpPort;

/// WebSocket port `host` listens on unless `--ws-port` is given.
const int defaultWsPort = defaultWebSocketPort;

/// Exit code for bad arguments (`EX_USAGE`).
const int usageExit = 64;

String get usage => '''
Klunki over the network: two terminals play each other.

Run from the repo root (inside packages/klunki_net, `dart run klunki_net:klunki` works too).

Usage:
  dart run packages/klunki_net/bin/klunki.dart host <game> [--port N] [--ws-port N] [--seed S] [--deck D] [--color C] [--name NAME]
  dart run packages/klunki_net/bin/klunki.dart join <ip>[:port] [port] [--name NAME]
  dart run packages/klunki_net/bin/klunki.dart join ws://<ip>[:port] [--name NAME]

Through a relay (browser vs browser, or terminals that cannot reach each other):
  dart run packages/klunki_net/bin/klunki.dart relay [--port N] [--web DIR]
  dart run packages/klunki_net/bin/klunki.dart host <game> --relay ws://<relay>[:port] [--seed S] [--deck D] [--color C] [--name NAME]
  dart run packages/klunki_net/bin/klunki.dart join --relay ws://<relay>[:port] --room CODE [--name NAME]

Games: ${gameSpecs.map((s) => s.id).join(', ')}
Quartett decks (--deck, default ${QuartettDeck.defaultId}): ${QuartettDeck.all.map((d) => d.id).join(', ')}
Chess (--color): the host's colour, white (default), black or random; White moves first.
Default ports: $defaultPort (TCP), $defaultWsPort (WebSocket, for browsers); 0 picks a free one
(--port 0 alone frees both).
The host accepts TCP and WebSocket guests. The host plays X and moves first
(chess: White moves first, see --color).
relay: pairs a host and a guest by a 5-character room code and forwards their
messages (WebSocket at /relay, default port $defaultRelayPort). --web DIR also serves a
built PWA (klunki/build/web), so browsers use the same address. Ctrl+C stops it.
host --relay prints the room code; join --relay --room CODE joins that room
(the code is case-insensitive). The relay address may omit the path (/relay).
In the game: type a move on your turn; "board", "moves", "resign", "help", "quit".''';

/// Runs the `klunki` network CLI. Returns the exit code.
///
/// [input] is the user's typed lines (default: stdin), [out] receives
/// everything the user sees (default: stdout), [err] the usage text on bad
/// arguments (default: stderr). [bindAddress] restricts where `host` listens
/// (default: all IPv4 interfaces). [relayStop] ends `relay` (default:
/// Ctrl+C / SIGTERM).
Future<int> runCli(
  List<String> args, {
  Stream<String>? input,
  StringSink? out,
  StringSink? err,
  Object? bindAddress,
  Duration pingInterval = const Duration(seconds: 2),
  Duration timeout = const Duration(seconds: 10),
  Future<void>? relayStop,
}) async {
  out ??= stdout;
  err ??= stderr;
  if (args.isNotEmpty && args.first == 'relay') {
    final relayArgs = _parseRelay(args);
    if (relayArgs == null) {
      err.writeln(usage);
      return usageExit;
    }
    return _runRelay(relayArgs, out, bindAddress, relayStop);
  }
  final parsed = _parse(args);
  if (parsed == null) {
    err.writeln(usage);
    return usageExit;
  }
  input ??= stdin.transform(utf8.decoder).transform(const LineSplitter());

  if (parsed.command == 'host' && parsed.relay != null) {
    final relay = parsed.relay!;
    final config = _config(parsed);
    final KlunkiHost host;
    try {
      host = await KlunkiHost.startRelay(config, relay,
          name: parsed.name ?? 'Host', pingInterval: pingInterval, timeout: timeout);
    } on NetException catch (e) {
      out.writeln('Cannot open a room on the relay $relay: ${e.message}');
      return 1;
    }
    final title = _title(config);
    out
      ..writeln('Room code: ${host.roomCode}')
      ..writeln('Hosting $title in relay room ${host.roomCode} on $relay — waiting for a guest…')
      ..writeln('Game config: ${jsonEncode(config.toJson())} (${_sides(config, Player.a)})')
      ..writeln('Join from another terminal with:')
      ..writeln('  dart run packages/klunki_net/bin/klunki.dart join --relay $relay --room ${host.roomCode}');
    return _Play.host(host, input, out).run();
  }

  if (parsed.command == 'host') {
    final config = _config(parsed);
    final port = parsed.port ?? defaultPort;
    // `--port 0` without `--ws-port`: both ports are picked freely.
    final wsPort = parsed.wsPort ?? (port == 0 ? 0 : defaultWsPort);
    final KlunkiHost host;
    try {
      host = await KlunkiHost.start(config,
          port: port,
          wsPort: wsPort,
          name: parsed.name ?? 'Host',
          address: bindAddress,
          pingInterval: pingInterval,
          timeout: timeout);
    } on SocketException catch (e) {
      out.writeln('Cannot listen on port $port (TCP) / $wsPort (WebSocket): ${e.message}');
      return 1;
    }
    final title = _title(config);
    final ips = await _addresses(bindAddress);
    out
      ..writeln('Hosting $title on ${ips.map((ip) => '$ip:${host.port}').join(', ')} — waiting for a guest…')
      ..writeln('Game config: ${jsonEncode(config.toJson())} (${_sides(config, Player.a)})')
      ..writeln('Join from another terminal with:');
    for (final ip in ips) {
      out.writeln('  dart run packages/klunki_net/bin/klunki.dart join $ip ${host.port}'
          '${ip == InternetAddress.loopbackIPv4.address ? '   (same machine)' : ''}');
    }
    if (host.wsPort case final wsPort?) {
      out.writeln('Browsers and WebSocket guests join at ${ips.map((ip) => webSocketUri(ip, wsPort)).join(', ')}');
    }
    return _Play.host(host, input, out).run();
  }

  final ws = parsed.webSocket;
  final relay = parsed.relay;
  final where = relay != null
      ? 'room ${parsed.room} on $relay'
      : ws?.toString() ?? '${parsed.target}:${parsed.port ?? defaultPort}';
  final KlunkiGuest guest;
  try {
    guest = relay != null
        ? await KlunkiGuest.connectRelay(relay, parsed.room!,
            name: parsed.name ?? 'Guest', pingInterval: pingInterval, timeout: timeout)
        : ws != null
            ? await KlunkiGuest.connectWebSocket(ws,
                name: parsed.name ?? 'Guest', pingInterval: pingInterval, timeout: timeout)
            : await KlunkiGuest.connect(parsed.target, parsed.port ?? defaultPort,
                name: parsed.name ?? 'Guest', pingInterval: pingInterval, timeout: timeout);
  } on NetException catch (e) {
    out.writeln('Could not join $where: ${e.message}');
    if (e.message.contains('session full')) {
      // KLD-071: a seat is only reclaimed with its session token, which a
      // new terminal does not have.
      out.writeln('The seat is taken: only the player who joined first can rejoin this game.');
    }
    return 1;
  }
  final title = _title(guest.config);
  out
    ..writeln("Joined ${guest.hostName ?? 'the host'}'s game: $title on $where")
    ..writeln('Game config: ${jsonEncode(guest.config.toJson())} (${_sides(guest.config, guest.me)})');
  return _Play.guest(guest, input, out).run();
}

/// "you play X, the other plays O"; chess names the colours (KLD-059
/// step 4a: the host may play Black, then the guest moves first).
String _sides(GameConfig config, Player me) {
  String mark(Player p) => config.gameId == 'chess'
      ? (p == config.chessWhite ? 'White' : 'Black')
      : (p == Player.a ? 'X' : 'O');
  final other = me == Player.a ? Player.b : Player.a;
  return 'you play ${mark(me)}, the ${me == Player.a ? 'guest' : 'host'} plays ${mark(other)}';
}

/// Game title, with the Quartett deck when it is not the default (KLD-069).
String _title(GameConfig config) {
  final spec = specById(config.gameId);
  final title = spec?.title ?? config.gameId;
  final deck = spec != null && spec.usesDeck ? QuartettDeck.byId(config.deck) : null;
  return deck == null || deck.id == QuartettDeck.defaultId ? title : '$title – ${deck.name}';
}

/// The game config of `host`: a random seed unless `--seed`, the deck, and
/// for chess the colours (`--color random`: decided by the seed, the config
/// carries the result).
GameConfig _config(_Args parsed) {
  final seed = parsed.seed ?? Random().nextInt(1 << 30);
  final choice = ChessColorChoice.values.byName(parsed.color ?? 'white');
  return GameConfig(parsed.target, seed: seed, deck: parsed.deck, chessWhite: choice.whitePlayer(seed));
}

class _Args {
  final String command, target;
  final int? port, wsPort, seed;
  final String? name;

  /// `host --deck`: the Quartett deck id (KLD-069).
  final String? deck;

  /// `host chess --color`: `white`, `black` or `random` (KLD-059 step 4a).
  final String? color;

  /// `join ws://…`: the WebSocket URL (then [target] / [port] are unused).
  final Uri? webSocket;

  /// `--relay`: the relay endpoint (`ws://host:port/relay`).
  final Uri? relay;

  /// `join --room`: the normalised room code.
  final String? room;
  _Args(this.command, this.target, this.port, this.seed, this.name,
      {this.wsPort, this.webSocket, this.relay, this.room, this.deck, this.color});
}

_Args? _parse(List<String> args) {
  if (args.isEmpty || (args.first != 'host' && args.first != 'join')) return null;
  final command = args.first;
  final positional = <String>[];
  int? port, wsPort, seed;
  String? name;
  Uri? relay;
  String? room;
  String? deck;
  String? color;
  for (var i = 1; i < args.length; i++) {
    final a = args[i];
    if (a == '--port' || a == '--ws-port' || a == '--seed' || a == '--name' || a == '--relay' || a == '--room' || a == '--deck' ||
        a == '--color') {
      if (i + 1 >= args.length) return null;
      final v = args[++i];
      switch (a) {
        case '--relay':
          relay = parseRelayUrl(v);
          if (relay == null) return null;
        case '--room':
          room = normalizeRoomCode(v);
          if (room == null || command != 'join') return null;
        case '--port':
          port = int.tryParse(v);
          if (port == null || port < 0 || port > 65535) return null;
        case '--ws-port':
          wsPort = int.tryParse(v);
          if (wsPort == null || wsPort < 0 || wsPort > 65535 || command != 'host') return null;
        case '--deck':
          deck = v;
          if (QuartettDeck.byId(v) == null || command != 'host') return null;
        case '--color':
          color = v;
          if (!const {'white', 'black', 'random'}.contains(v) || command != 'host') return null;
        case '--seed':
          seed = int.tryParse(v);
          if (seed == null || command != 'host') return null;
        default:
          name = v;
      }
    } else if (a.startsWith('--')) {
      return null;
    } else {
      positional.add(a);
    }
  }
  if (command == 'host') {
    if (positional.length != 1 || specById(positional.first) == null) return null;
    if (relay != null && (port != null || wsPort != null)) return null;
    if (deck != null && !specById(positional.first)!.usesDeck) return null;
    if (color != null && positional.first != 'chess') return null;
    return _Args(command, positional.first, port, seed, name,
        wsPort: wsPort, relay: relay, deck: deck, color: color);
  }
  if (relay != null || room != null) {
    // `join --relay URL --room CODE`: both, and nothing else.
    if (relay == null || room == null || positional.isNotEmpty || port != null) return null;
    return _Args(command, relay.host, null, null, name, relay: relay, room: room);
  }
  if (positional.isEmpty || positional.length > 2) return null;
  var target = positional.first;
  if (RegExp(r'^wss?://', caseSensitive: false).hasMatch(target)) {
    // `ws://ip[:port]` (port defaults to the WebSocket port); no extra port.
    final uri = Uri.tryParse(target);
    if (uri == null || uri.host.isEmpty || positional.length > 1 || port != null) return null;
    final url = uri.hasPort ? uri : uri.replace(port: defaultWsPort);
    if (url.port < 1 || url.port > 65535) return null;
    return _Args(command, url.host, url.port, null, name, webSocket: url);
  }
  if (target.contains('://')) return null;
  // `ip:port` (IPv4 or a host name; a bare IPv6 address has several colons).
  if (':'.allMatches(target).length == 1) {
    final p = int.tryParse(target.split(':').last);
    if (p == null || port != null || positional.length > 1) return null;
    port = p;
    target = target.split(':').first;
  }
  if (positional.length == 2) {
    final p = int.tryParse(positional[1]);
    if (p == null || port != null) return null;
    port = p;
  }
  if (port != null && (port < 1 || port > 65535)) return null;
  return _Args(command, target, port, null, name);
}

class _RelayArgs {
  final int port;
  final String? web;
  _RelayArgs(this.port, this.web);
}

_RelayArgs? _parseRelay(List<String> args) {
  var port = defaultRelayPort;
  String? web;
  for (var i = 1; i < args.length; i++) {
    final a = args[i];
    if ((a != '--port' && a != '--web') || i + 1 >= args.length) return null;
    final v = args[++i];
    if (a == '--port') {
      final p = int.tryParse(v);
      if (p == null || p < 0 || p > 65535) return null;
      port = p;
    } else {
      web = v;
    }
  }
  return _RelayArgs(port, web);
}

Future<int> _runRelay(_RelayArgs args, StringSink out, Object? bindAddress, Future<void>? stop) async {
  Directory? web;
  if (args.web case final dir?) {
    web = Directory(dir);
    if (!web.existsSync()) {
      out.writeln('No such directory: $dir (build the PWA first: cd klunki && flutter build web)');
      return 1;
    }
    if (!File('${web.path}/index.html').existsSync()) {
      out.writeln('Warning: $dir has no index.html; is it a web build?');
    }
  }
  final RelayServer relay;
  try {
    relay = await RelayServer.start(port: args.port, address: bindAddress, webRoot: web);
  } on SocketException catch (e) {
    out.writeln('Cannot listen on port ${args.port}: ${e.message}');
    return 1;
  }
  final ips = await _addresses(bindAddress);
  out.writeln('Klunki relay listening on port ${relay.port}: '
      '${ips.map((ip) => 'ws://$ip:${relay.port}$relayPath').join(', ')}');
  if (web != null) {
    out.writeln('Serving the PWA from ${web.path}: ${ips.map((ip) => 'http://$ip:${relay.port}/').join(', ')}');
    out.writeln('In the browser: "Spiel hosten" uses this relay automatically; the guest enters the room code.');
  }
  // KLD-083: the addresses to open elsewhere (not localhost): LAN IPs and
  // the Bonjour/mDNS name. Only when listening on every interface.
  if (bindAddress == null) {
    final lines = openOnOtherDevices(
      port: relay.port,
      lan: lanAddresses(await systemAddresses()),
      mdns: systemMdnsName(),
      web: web != null,
    );
    for (final l in lines) {
      out.writeln(l);
    }
  }
  out
    ..writeln('Terminals:')
    ..writeln('  dart run packages/klunki_net/bin/klunki.dart host connect4 --relay ws://${ips.first}:${relay.port}')
    ..writeln('  dart run packages/klunki_net/bin/klunki.dart join --relay ws://${ips.first}:${relay.port} --room CODE')
    ..writeln('Press Ctrl+C to stop.');
  await (stop ?? _interrupted());
  await relay.close();
  out.writeln('Relay stopped.');
  return 0;
}

/// Completes on Ctrl+C (SIGINT) or SIGTERM.
Future<void> _interrupted() {
  final done = Completer<void>();
  final subs = <StreamSubscription<ProcessSignal>>[];
  void stop(ProcessSignal _) {
    for (final s in subs) {
      s.cancel();
    }
    if (!done.isCompleted) done.complete();
  }

  subs.add(ProcessSignal.sigint.watch().listen(stop));
  if (!Platform.isWindows) subs.add(ProcessSignal.sigterm.watch().listen(stop));
  return done.future;
}

/// Addresses a guest can use to reach this host: every non-loopback IPv4
/// address, then loopback (same machine).
Future<List<String>> _addresses(Object? bindAddress) async {
  final loopback = InternetAddress.loopbackIPv4.address;
  if (bindAddress != null) {
    final a = bindAddress is InternetAddress ? bindAddress.address : '$bindAddress';
    if (a != InternetAddress.anyIPv4.address) return [a];
  }
  final ips = <String>[];
  try {
    for (final nic in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
      for (final a in nic.addresses) {
        if (!a.isLoopback) ips.add(a.address);
      }
    }
  } on SocketException {
    // no interface list: loopback only
  }
  return [...ips, loopback];
}

/// The interactive game loop shared by host and guest.
///
/// It keeps its own copy of the game (built from the session's [GameConfig],
/// so seeded deals match) and applies every accepted move to it; that gives
/// the [GameEvent] the text adapter needs for the narration. A guest of a
/// hidden-information game has no full game (KLD-064): it shows the view the
/// host sent ([KlunkiGuest.game]) and narrates the redacted events, and at
/// the end it waits for the host's reveal and prints the verification.
class _Play {
  final KlunkiHost? _host;
  final KlunkiGuest? _guest;
  final Stream<String> _input;
  final StringSink _out;
  final _done = Completer<int>();
  StreamSubscription<NetEvent>? _eventSub;
  StreamSubscription<String>? _inputSub;

  late final GameConfig _config;
  late final Player _me;
  late TextGame _view;
  int _applied = 0;
  bool _opponentHere;
  bool _askingReconnect = false;
  bool _reconnecting = false;
  bool _submitting = false;
  bool _finishing = false;
  bool _awaitingVerification = false;

  _Play.host(KlunkiHost host, this._input, this._out)
      : _host = host,
        _guest = null,
        _opponentHere = false {
    _config = host.config;
    _me = host.me;
    _rebuild(host.moves);
  }

  _Play.guest(KlunkiGuest guest, this._input, this._out)
      : _host = null,
        _guest = guest,
        _opponentHere = true {
    _config = guest.config;
    _me = guest.me;
    _rebuild(guest.moves);
  }

  Stream<NetEvent> get _events => _host?.events ?? _guest!.events;
  List<Map<String, dynamic>> get _sessionMoves => _host?.moves ?? _guest!.moves;
  Player get _opponent => otherPlayer(_me);
  String get _meMark => _view.mark(_me);
  String get _oppMark => _view.mark(_opponent);
  String get _oppName => _view.playerName(_opponent);

  /// Both handles once known (KLD-103): the narration names the players.
  Map<Player, String> get _names {
    final own = _host?.name ?? _guest!.name;
    final peer = _host != null ? _host.guestName : _guest!.hostName;
    return {
      if (own.isNotEmpty) _me: own,
      if (peer != null && peer.isNotEmpty) _opponent: peer,
    };
  }

  /// Shows [view] with the players' names.
  set _shown(TextGame view) => _view = view..names = _names;
  bool get _hidden => specById(_config.gameId)!.hiddenInformation;
  String get _leftReason => _host != null ? 'host left' : 'guest left';
  bool get _myTurn => !_view.game.isOver && _view.game.currentPlayer == _me;

  Future<int> run() {
    _eventSub = _events.listen(_onEvent);
    _inputSub = _input.listen(_onLine, onDone: () => _quit(_leftReason));
    if (_guest != null) _showTurn();
    return _done.future;
  }

  /// A guest of a hidden-information game: views only, no replay.
  bool get _redactedGuest => _guest?.redacted ?? false;

  void _rebuild(List<Map<String, dynamic>> moves) {
    if (_redactedGuest) {
      _shown = DebugConsole.forGame(_config.gameId, _guest!.game);
      _applied = _guest.entries.length;
      return;
    }
    final game = replay(_config, [for (final m in moves) _copy(m)]) ?? createGame(_config);
    _shown = DebugConsole.forGame(_config.gameId, game);
    _applied = moves.length;
  }

  static Map<String, dynamic> _copy(Map<String, dynamic> m) => jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

  // ---------------------------------------------------------------- network

  void _onEvent(NetEvent e) {
    if (_finishing) return;
    switch (e) {
      case PeerConnected(:final name, :final reconnect):
        _opponentHere = true;
        _view.names = _names;
        _out.writeln(reconnect ? '$name rejoined.' : '$name joined: you are $_meMark, $name is $_oppMark.');
        _showTurn();
      case MoveAccepted():
        _onAccepted(e);
      case PeerDisconnected(:final reason):
        _onDisconnected(reason);
      case Resynced(:final moves):
        if (_applied != moves) _rebuild(_sessionMoves);
        _out.writeln('Reconnected ($moves moves so far).');
        _showTurn();
      case NetError(:final message):
        _out.writeln('Network error: $message');
        if (_host?.roomCode != null && message.startsWith('relay')) {
          _out.writeln('The relay room is gone; the game cannot continue.');
          _finish(1, 'relay room closed');
        }
      case IncompatiblePeer(:final mismatch):
        _out.writeln('A guest was refused: ${mismatch.message}');
      case MoveRejected():
        break; // the guest's submit() reports it; the host has nothing to show
      case GameVerified() || VerificationFailed():
        if (_awaitingVerification) {
          _reportVerification();
          _finish(0, 'game over');
        }
    }
  }

  void _onAccepted(MoveAccepted e) {
    if (e.index < _applied) return;
    if (_redactedGuest) return _onRedactedAccepted(e);
    if (e.index > _applied) _rebuild(_sessionMoves.take(e.index).toList());
    final mover = _view.game.playerOf(e.move);
    final event = _view.game.applyMove(_copy(e.move));
    if (event == null) {
      // Cannot happen while both run the same engine; resync from the log.
      _rebuild(_sessionMoves);
      _out.writeln('(resynced the local board from the move log)');
    } else {
      _applied++;
      _out.writeln(_narrate(mover, e.move, event));
    }
    _afterMove();
  }

  /// A guest of a hidden-information game: the view comes from the host.
  void _onRedactedAccepted(MoveAccepted e) {
    _shown = DebugConsole.forGame(_config.gameId, _guest!.game);
    _applied = e.index + 1;
    final event = e.event;
    if (event != null) _out.writeln(_narrate(e.player, e.move, event));
    _afterMove();
  }

  void _afterMove() {
    if (_view.game.isOver) {
      if (!_hidden) {
        _out
          ..writeln()
          ..writeln(_view.render());
      }
      _out
        ..writeln(_result())
        ..writeln('Game over.');
      final guest = _guest;
      if (guest != null && guest.verification != Verification.pending) _reportVerification();
      if (guest != null && guest.verification == Verification.pending) {
        // The host reveals its secrets right after the last move.
        _awaitingVerification = true;
        Future<void>.delayed(guest.timeout, () {
          if (_finishing) return;
          _out.writeln('The host did not reveal its hidden data; the game could not be verified.');
          _finish(0, 'game over');
        });
        return;
      }
      _finish(0, 'game over');
    } else if (_reconnecting) {
      // replaying missed moves; Resynced shows the turn
    } else {
      _showTurn();
    }
  }

  /// The end-of-game check of a hidden-information game (guest only).
  void _reportVerification() {
    switch (_guest?.verification) {
      case Verification.verified:
        _out.writeln("Verified: the host's hidden data matches its commitments and the game replays as reported.");
      case Verification.failed:
        _out.writeln('Could not verify the game record: ${_guest!.verificationError}');
      default:
        break;
    }
  }

  String _result() {
    final r = _view.game.result;
    final you = r.winner == null ? '' : (r.winner == _me ? ' — you win!' : ' — you lose.');
    return '${_view.status()}$you';
  }

  /// Narration without the opponent's secrets: in Schiffe the opponent's ship
  /// placements are not shown, in GoStrategy not the opponent's setup seed.
  String _narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final game = _view.game;
    if (Game.resignerOf(move) != null) {
      return mover == _me ? 'You resign. ${_view.playerName(event.winner)} wins.' : '$_oppName resigns. You win!';
    }
    if (mover != _me && game is GoStrategyGame && move['action'] != 'move') {
      final m = _view.playerName(mover);
      return game.phase == GoStrategyPhase.play
          ? '$m has set up their army. Both armies are ready: ${_view.playerName(Player.a)} moves first.'
          : '$m has set up their army.';
    }
    if (mover != _me && game is SchiffeGame && move['action'] != 'fire') {
      final m = _view.playerName(mover);
      var s = move['action'] == 'place' ? '$m places a ship.' : '$m places the rest of their fleet.';
      if (game.nextShipIndex(mover) == null) {
        s += game.phase == SchiffePhase.battle
            ? ' Both fleets are ready: the battle begins, ${_view.playerName(Player.a)} fires first.'
            : " $m's fleet is ready.";
      }
      return s;
    }
    return _view.narrate(mover, move, event);
  }

  void _onDisconnected(String reason) {
    final left = reason.startsWith('peer left');
    if (_awaitingVerification) {
      _out.writeln('The host left before revealing its hidden data; the game could not be verified.');
      _finish(0, 'game over');
      return;
    }
    if (_host != null) {
      _opponentHere = false;
      if (left) {
        _out.writeln('Opponent left (${_reasonText(reason)}).');
        _finish(0, 'opponent left');
      } else {
        _out.writeln('Lost the connection to ${_host.guestName ?? 'the guest'} (${_reasonText(reason)}). '
            'Waiting for them to rejoin… (type "quit" to end)');
      }
      return;
    }
    if (left) {
      _out.writeln('Opponent left (${_reasonText(reason)}).');
      _finish(0, 'opponent left');
      return;
    }
    _out.writeln('Connection to the host lost (${_reasonText(reason)}).');
    _askReconnect();
  }

  static String _reasonText(String reason) =>
      reason.startsWith('peer left: ') ? reason.substring('peer left: '.length) : reason;

  void _askReconnect() {
    _askingReconnect = true;
    _out.write('Reconnect? [Y/n] ');
  }

  Future<void> _reconnect() async {
    final guest = _guest!;
    _askingReconnect = false;
    _reconnecting = true;
    _out.writeln('Reconnecting to ${guest.address}…');
    try {
      await guest.reconnect();
      _reconnecting = false; // Resynced (emitted during reconnect) shows the turn
    } on NetException catch (e) {
      _reconnecting = false;
      if (_finishing) return;
      _out.writeln('Reconnect failed: ${e.message}');
      _askReconnect();
    }
  }

  // ------------------------------------------------------------------ input

  Future<void> _onLine(String raw) async {
    if (_finishing) return;
    final line = raw.trim();
    if (_askingReconnect) {
      if (line.toLowerCase() case 'n' || 'no' || 'quit' || 'exit') return _quit(_leftReason);
      return _reconnect();
    }
    if (_reconnecting) return _out.writeln('Still reconnecting…');
    switch (line.toLowerCase()) {
      case 'quit' || 'exit':
        return _quit(_leftReason);
      case 'help' || '?':
        _out.writeln(_help());
        return _prompt();
      case 'moves':
        if (!_myTurn) return _notYourTurn();
        final legal = _view.legalMoves.map(_view.format).toList();
        final shown = legal.length > 60 ? [...legal.take(60), '… (${legal.length} total)'] : legal;
        _out.writeln('Your legal moves: ${shown.join(' ')}');
        return _prompt();
      case '' || 'board':
        return _showTurn();
    }
    // Either player may resign at any time, also off turn (KLD-065).
    final resign = line.toLowerCase() == 'resign';
    final move = resign ? Game.resignMove(_me) : _view.parse(line);
    if (move == null) {
      _out.writeln('Unknown command "$line". Type "help".');
      return _prompt();
    }
    if (!_opponentHere) {
      _out.writeln(_host!.guestName == null
          ? 'No opponent yet — waiting for a guest to join.'
          : 'Your opponent is disconnected — waiting for them to rejoin.');
      return;
    }
    if (!_myTurn && !(resign && !_view.game.isOver)) return _notYourTurn();
    if (_submitting) return _out.writeln('Your last move is still on its way…');
    final String? reason;
    if (_host != null) {
      reason = _host.submitLocal(move);
    } else {
      _submitting = true;
      reason = await _guest!.submit(move);
      _submitting = false;
    }
    if (reason != null && !_finishing && reason != 'disconnected') {
      _out.writeln('Illegal move "$line" ($reason).');
      _prompt();
    }
  }

  void _notYourTurn() {
    if (_view.game.isOver) {
      _out.writeln('The game is over.');
    } else {
      _out.writeln('Not your turn — waiting for $_oppName.');
    }
  }

  void _prompt() {
    if (_myTurn && _opponentHere) _out.write('> ');
  }

  /// On your turn: board (your private view) + status + prompt. Otherwise a
  /// waiting line, plus the board for games without hidden information.
  void _showTurn() {
    if (_view.game.isOver) {
      _out.writeln(_result());
      return;
    }
    if (!_opponentHere) {
      _out.writeln(_host?.guestName == null ? 'Waiting for a guest to join…' : 'Waiting for the guest to rejoin…');
      return;
    }
    if (_myTurn) {
      _out
        ..writeln()
        ..writeln(_view.render())
        ..writeln('Your turn ($_meMark). ${_view.status()}')
        ..write('> ');
    } else {
      if (!_hidden) {
        _out
          ..writeln()
          ..writeln(_view.render());
      }
      _out.writeln('Waiting for $_oppName…');
    }
  }

  String _help() => '''
${_view.title} — you are $_meMark.
Moves: ${_view.moveHelp}
Commands:
  board   show the board (your own view)
  moves   list your legal moves (on your turn)
  resign  give up (any time, also on the opponent's turn); the opponent wins
  help    this text
  quit    leave the game''';

  // ------------------------------------------------------------------- exit

  void _quit(String reason) {
    if (_finishing) return;
    _out.writeln('Bye.');
    _finish(0, reason);
  }

  /// Says `bye` (with [reason]), closes the session, then completes [run].
  Future<void> _finish(int code, String reason) async {
    if (_finishing) return;
    _finishing = true;
    unawaited(_eventSub?.cancel());
    unawaited(_inputSub?.cancel());
    try {
      await (_host?.close(reason: reason) ?? _guest!.close(reason: reason));
    } finally {
      _done.complete(code);
    }
  }
}
