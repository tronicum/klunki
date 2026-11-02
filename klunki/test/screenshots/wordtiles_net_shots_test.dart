// KLD-094 step 6 screenshots: Wortgewandt over the network. "Raum starten"
// with the game and its start options (tile language, word list), the
// waiting room naming them, then two phones side by side (host Anna, guest
// Ben, real NetworkTransports on 127.0.0.1): mid-game with each device's own
// rack, "Trotzdem zulassen" on both sides (asked by the host, then by the
// guest), and the result. Skipped unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/wordtiles-net flutter test test/screenshots/wordtiles_net_shots_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_board.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../ui/pairing/pairing_test_utils.dart';

final String? _out = Platform.environment['KLUNKI_SHOTS'];
const _hostKey = Key('device-host');
const _guestKey = Key('device-guest');
const _roomKey = Key('device-room');
const _ping = Duration(milliseconds: 100);
const _timeout = Duration(seconds: 30);

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }

  await family('Roboto', [
    'assets/fonts/Roboto/Roboto-Regular.ttf',
    'assets/fonts/Roboto/Roboto-Medium.ttf',
    'assets/fonts/Roboto/Roboto-Bold.ttf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
}

Finder _on(Key device, Finder f) => find.descendant(of: find.byKey(device), matching: f);

Future<void> _until(WidgetTester tester, bool Function() condition, String what) async {
  for (var round = 0;; round++) {
    await tester.pump();
    if (condition()) {
      await tester.pump();
      await tester.pump();
      return;
    }
    if (round > 2000) fail('condition not met: $what');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pump();
  await tester.pump();
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Captures one device's screen (its RepaintBoundary) as `<name>.png`.
Future<void> _shot(WidgetTester tester, Key device, String name) async {
  debugDisableShadows = false;
  await _frames(tester);
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(device));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

Widget _app(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: KlunkiTheme.light,
      locale: const Locale('de'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

SortedWordListValidator _list(List<String> words) =>
    SortedWordListValidator.fromUtf8(Uint8List.fromList(utf8.encode('${(words.toList()..sort()).join('\n')}\n')));

GameController _controller(WidgetTester tester, Key device) =>
    tester.widget<GameScreen>(_on(device, find.byType(GameScreen))).controller;

WordTilesGame _game(WidgetTester tester, Key device) => _controller(tester, device).game as WordTilesGame;

Future<void> _start(WidgetTester tester, GameConfig config) async {
  tester.view.physicalSize = const Size(2 * 390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final (host, guest) = (await tester.runAsync(() async {
    final h = await NetworkTransport.host(config,
        name: 'Anna', address: InternetAddress.loopbackIPv4, wsPort: null, pingInterval: _ping, timeout: _timeout);
    final g = await NetworkTransport.join(InternetAddress.loopbackIPv4, h.port!,
        name: 'Ben', pingInterval: _ping, timeout: _timeout);
    return (h, g);
  }))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    guest.dispose();
    host.dispose();
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
  });
  Widget device(Key key, NetworkTransport t) =>
      Expanded(child: RepaintBoundary(key: key, child: _app(NetworkGameSession(transport: t))));
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Row(children: [device(_hostKey, host), device(_guestKey, guest)]),
  ));
  await _until(tester, () => _on(_guestKey, find.byType(WordTilesBoard)).evaluate().isNotEmpty, 'guest board');
  await _until(tester, () => _on(_hostKey, find.byType(WordTilesBoard)).evaluate().isNotEmpty, 'host board');
}

/// A placement of rack tiles (no blanks) for [seat] that fits the board
/// (words not checked): two tiles through the centre, else one tile next
/// to the words laid. As (rack index, row, column).
List<(int, int, int)> _placement(WordTilesGame g, int seat) {
  final rack = g.rackOf(seat);
  bool fits(List<PlacedTile> tiles) => g.checkPlacement(WordTilesGame.placeMove(tiles), checkWords: false).ok;
  for (var i = 0; i < rack.length; i++) {
    if (rack[i] == TileSet.blank) continue;
    if (g.boardEmpty) {
      for (var j = 0; j < rack.length; j++) {
        if (i == j || rack[j] == TileSet.blank) continue;
        if (fits([PlacedTile(7, 7, rack[i]), PlacedTile(7, 8, rack[j])])) return [(i, 7, 7), (j, 7, 8)];
      }
      continue;
    }
    for (var r = 0; r < WordTilesGame.size; r++) {
      for (var c = 0; c < WordTilesGame.size; c++) {
        if (fits([PlacedTile(r, c, rack[i])])) return [(i, r, c)];
      }
    }
  }
  fail('no placement for seat $seat');
}

Future<void> _lay(WidgetTester tester, Key device, List<(int, int, int)> tiles) async {
  for (final (i, r, c) in tiles) {
    await _tap(tester, _on(device, find.byKey(Key('wordtiles-rack-$i'))));
    await _tap(tester, _on(device, find.byKey(Key('wordtiles-sq-$r-$c'))));
  }
}

/// [placer] lays a word the list lacks and asks; the other device's dialog opens.
Future<void> _ask(WidgetTester tester, Key placer, Key other) async {
  final seat = placer == _hostKey ? 0 : 1;
  await _lay(tester, placer, _placement(_game(tester, placer), seat));
  await _tap(tester, _on(placer, find.byKey(const Key('wordtiles-play'))));
  await _frames(tester);
  await _tap(tester, _on(placer, find.byKey(const Key('wordtiles-unknown-allow'))));
  await _until(tester, () => _on(other, find.byKey(const Key('wordtiles-allow-dialog'))).evaluate().isNotEmpty,
      'the request reaches the other device');
}

Future<void> _answer(WidgetTester tester, Key device, String button) async {
  final n = _controller(tester, _hostKey).moves.length;
  await _tap(tester, _on(device, find.byKey(Key(button))));
  await _until(
      tester,
      () => _controller(tester, _hostKey).moves.length == n + 1 && _controller(tester, _guestKey).moves.length == n + 1,
      'the answer on both devices');
  await _frames(tester);
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });
  setUp(() => WordLists.register('de', _list(['ZZZZZZZZ'])));
  tearDown(WordLists.clear);

  testWidgets('kld094 step 6 room: "Raum starten" with Wortgewandt and its options', skip: skip, (tester) async {
    tester.view.physicalSize = const Size(390, 1100) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final created = CreatedTransports();
    final deps = testDeps(discovery: FakeDiscovery(), created: created, name: 'Anna');
    final names = PlayerNameController.memory(name: 'Anna');
    await tester.pumpWidget(RepaintBoundary(
        key: _roomKey, child: _app(PairingScreen(deps: deps, nameController: names, gameId: 'wordtiles'))));
    await tester.pump();
    await _shot(tester, _roomKey, '01-room-start-options');
    await tester.tap(find.byKey(const Key('pair-host-start')));
    await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty);
    await _shot(tester, _roomKey, '02-room-waiting-options');
    await tester.tap(find.byKey(const Key('pair-host-cancel')));
    await tester.pump();
    await unmountAndSettleSockets(tester, created);
  });

  testWidgets('kld094 step 6 game: own racks, allow on both sides, result', skip: skip, (tester) async {
    await _start(tester, const GameConfig('wordtiles', seed: 4, tiles: 'de', dictionary: true));
    await _shot(tester, _hostKey, '03-host-start');
    await _shot(tester, _guestKey, '04-guest-start');

    // The host asks; the guest decides.
    await _ask(tester, _hostKey, _guestKey);
    await _shot(tester, _hostKey, '05-host-waits-for-ben');
    await _shot(tester, _guestKey, '06-guest-allow-dialog');
    await _answer(tester, _guestKey, 'wordtiles-allow-accept');

    // The guest asks; the host declines.
    await _ask(tester, _guestKey, _hostKey);
    await _shot(tester, _hostKey, '07-host-allow-dialog');
    await _shot(tester, _guestKey, '08-guest-waits-for-anna');
    await _answer(tester, _hostKey, 'wordtiles-allow-decline');
    await _shot(tester, _guestKey, '09-guest-declined');

    // Mid-game: the guest lays tiles (the preview on its own device only).
    await _lay(tester, _guestKey, _placement(_game(tester, _guestKey), 1));
    await _shot(tester, _hostKey, '10-host-mid-game');
    await _shot(tester, _guestKey, '11-guest-mid-game');
    await _tap(tester, _on(_guestKey, find.byKey(const Key('wordtiles-recall'))));

    // Six passes end the game.
    while (!_game(tester, _hostKey).isOver) {
      final d = _game(tester, _hostKey).currentSeat == 0 ? _hostKey : _guestKey;
      final n = _controller(tester, _hostKey).moves.length;
      await _tap(tester, _on(d, find.byKey(const Key('wordtiles-pass'))));
      await _frames(tester);
      await _tap(tester, _on(d, find.byKey(const Key('wordtiles-pass-confirm'))));
      await _until(
          tester,
          () =>
              _controller(tester, _hostKey).moves.length == n + 1 && _controller(tester, _guestKey).moves.length == n + 1,
          'pass');
      await _frames(tester);
    }
    await _until(
        tester,
        () => _on(_guestKey, find.byKey(const Key('result-dialog'))).evaluate().isNotEmpty &&
            _on(_hostKey, find.byKey(const Key('result-dialog'))).evaluate().isNotEmpty,
        'result on both');
    await _shot(tester, _hostKey, '12-host-result');
    await _shot(tester, _guestKey, '13-guest-result');
  });
}
