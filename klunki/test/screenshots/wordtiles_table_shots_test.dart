// KLD-088 step 4 screenshots (group `kld088net`): Wortgewandt for 3 players
// over the network, three phones side by side (host Anna through the real
// "Raum starten" screen, guests Ben and Cleo, real NetworkTransports on
// 127.0.0.1): the player count in the room setup, the lobby on the host and
// on a guest, the game in the middle from each device's own seat, and the
// pause while a guest is away. Skipped unless KLUNKI_SHOTS=<output dir>:
//
//   KLUNKI_SHOTS=/tmp/kld088net flutter test test/screenshots/wordtiles_table_shots_test.dart
//   KLUNKI_SHOTS=/tmp/kld088net flutter test test/screenshots --plain-name kld088net
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
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../e2e/e2e_support.dart' show WifiProxy;
import '../ui/pairing/pairing_test_utils.dart';

final String? _out = Platform.environment['KLUNKI_SHOTS'];
const _devices = [Key('device-anna'), Key('device-ben'), Key('device-cleo')];
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

Finder _on(int device, Finder f) => find.descendant(of: find.byKey(_devices[device]), matching: f);
bool _has(int device, Finder f) => _on(device, f).evaluate().isNotEmpty;

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pump();
  await tester.pump();
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Captures one device's screen as `<name>.png`.
Future<void> _shot(WidgetTester tester, int device, String name) async {
  debugDisableShadows = false;
  await _frames(tester);
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_devices[device]));
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

GameController _controller(WidgetTester tester, int device) =>
    tester.widget<SeatGameScreen>(_on(device, find.byType(SeatGameScreen))).controller;

/// A placement of rack tiles (no blanks) for [seat] that fits the board
/// (words not checked), as (rack index, row, column).
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

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  testWidgets('kld088net: room for 3, lobby on host and guest, mid-game per seat, a guest away', skip: skip,
      (tester) async {
    tester.view.physicalSize = const Size(3 * 390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final created = CreatedTransports();
    final deps = testDeps(discovery: FakeDiscovery(), created: created, name: 'Anna');
    final names = PlayerNameController.memory(name: 'Anna');
    final guests = <NetworkTransport?>[null, null];
    WifiProxy? proxy;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      for (final g in guests) {
        g?.dispose();
      }
      await unmountAndSettleSockets(tester, created);
      await tester.runAsync(() async => proxy?.close());
    });
    final anna = PairingScreen(deps: deps, nameController: names, gameId: 'wordtiles');
    Widget device(int i) => Expanded(
          child: RepaintBoundary(
            key: _devices[i],
            child: i == 0
                ? _app(anna)
                : guests[i - 1] == null
                    ? const ColoredBox(color: Color(0xFF202020))
                    : _app(NetworkGameSession(transport: guests[i - 1]!)),
          ),
        );
    Future<void> show() => tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [for (var i = 0; i < 3; i++) device(i)]),
        ));

    // "Raum starten": Wortgewandt for 3.
    await show();
    await tester.pump();
    await _tap(tester, _on(0, find.byKey(const Key('pair-players-3'))));
    await tester.drag(_on(0, find.byType(Scrollable).first), const Offset(0, -200));
    await _shot(tester, 0, '01-room-players');
    // Without the word list: any word goes (no download in a test).
    await _tap(tester, _on(0, find.byKey(const Key('pair-wordtiles-dict'))));
    await _tap(tester, _on(0, find.byKey(const Key('pair-host-start'))));
    await pumpUntil(tester, () => _has(0, find.byKey(const Key('table-lobby'))), what: 'the lobby');
    final host = created.hosts.single;
    expect(host.table, isTrue);
    await tester.ensureVisible(_on(0, find.byKey(const Key('table-lobby'))));
    await _shot(tester, 0, '02-host-lobby-empty');

    // Ben sits down.
    guests[0] = await tester.runAsync(() => NetworkTransport.join(InternetAddress.loopbackIPv4, host.port!,
        name: 'Ben', pingInterval: _ping, timeout: _timeout));
    await show();
    await pumpUntil(tester, () => _has(0, find.text('Ben')) && _has(1, find.byKey(const Key('table-waiting'))),
        what: 'Ben in the lobby');
    await tester.ensureVisible(_on(0, find.byKey(const Key('table-lobby'))));
    await _shot(tester, 0, '03-host-lobby-ben');
    await _shot(tester, 1, '04-guest-lobby');

    // Cleo (behind a proxy that can cut her off) completes the table.
    proxy = await tester.runAsync(() => WifiProxy.start(host.port!, seed: 1));
    guests[1] = await tester.runAsync(() => NetworkTransport.join(InternetAddress.loopbackIPv4, proxy!.port,
        name: 'Cleo', pingInterval: _ping, timeout: _timeout));
    await show();
    await pumpUntil(tester, () => [0, 1, 2].every((d) => _has(d, find.byType(SeatGameScreen))), what: 'the game');

    // A few turns: Anna lays, Ben accepts and lays, Cleo accepts.
    final engine = host.game as WordTilesGame;
    Future<void> act(Future<void> Function(int seat) body) async {
      final n = host.moves.length;
      final seat = engine.actorSeat!;
      await body(seat);
      await pumpUntil(
          tester, () => host.moves.length > n && guests.every((g) => g!.moves.length == host.moves.length),
          what: 'move ${n + 1} everywhere');
      await _frames(tester);
    }

    Future<void> lay(int seat) async {
      // The bench explanation on a device's first turn: read to the end.
      if (_has(seat, find.byKey(const Key('wordtiles-coach')))) {
        while (_has(seat, find.byKey(const Key('wordtiles-coach-next')))) {
          await _tap(tester, _on(seat, find.byKey(const Key('wordtiles-coach-next'))));
        }
        await _tap(tester, _on(seat, find.byKey(const Key('wordtiles-coach-done'))));
        await _frames(tester);
      }
      final g = _controller(tester, seat).game as WordTilesGame;
      for (final (i, r, c) in _placement(g, seat)) {
        await _tap(tester, _on(seat, find.byKey(Key('wordtiles-rack-$i'))));
        await _tap(tester, _on(seat, find.byKey(Key('wordtiles-sq-$r-$c'))));
      }
      await _frames(tester); // the board zooms in on the first tile
      await _tap(tester, _on(seat, find.byKey(const Key('wordtiles-play'))));
    }

    Future<void> accept(int seat) => _tap(tester, _on(seat, find.byKey(const Key('wordtiles-accept'))));
    await act(lay);
    await act(accept);
    await act(lay);
    await act(accept);
    expect(engine.actorSeat, 2);
    await _shot(tester, 2, '05-cleo-her-turn');
    await _shot(tester, 1, '06-ben-mid-game');
    await _shot(tester, 0, '07-anna-mid-game');

    // Cleo's connection breaks: the table pauses.
    proxy!.refuse = true;
    await tester.runAsync(() async => proxy!.cut());
    await pumpUntil(tester, () => host.paused && _has(0, find.byKey(const Key('table-let-leave-2'))),
        what: 'the pause');
    await pumpUntil(tester, () => _has(1, find.byKey(const Key('net-banner'))), what: 'Ben sees the pause');
    await _shot(tester, 0, '08-host-paused');
    await _shot(tester, 1, '09-guest-paused');
  });
}
