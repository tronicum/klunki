// Screenshots of the network step of Mau-Mau (KLD-118) and Mäxchen
// (KLD-121): "Raum starten" with the house rules, the waiting room, and a
// game in progress on the host and on the guest (two phones side by side,
// real NetworkTransports on 127.0.0.1). German, phone size. Skipped unless
// KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/net flutter test test/screenshots/network_games_shots_test.dart
//   KLUNKI_SHOTS=/tmp/net flutter test test/screenshots/network_games_shots_test.dart --plain-name kld118
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/pairing/pairing_test_utils.dart';

final String? _out = Platform.environment['KLUNKI_SHOTS'];
const _hostKey = Key('device-host');
const _guestKey = Key('device-guest');
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

/// Captures one device's screen (its RepaintBoundary) as `<name>.png`.
Future<void> _shot(WidgetTester tester, Key device, String name) async {
  debugDisableShadows = false;
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
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

/// Two phones side by side playing [config]; returns both transports.
Future<(NetworkTransport, NetworkTransport)> _start(WidgetTester tester, GameConfig config) async {
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
  await _until(
      tester,
      () =>
          _on(_guestKey, find.byType(GameScreen)).evaluate().isNotEmpty &&
          _on(_hostKey, find.byType(GameScreen)).evaluate().isNotEmpty,
      'both screens');
  return (host, guest);
}

/// Plays [moves] chosen by [pick] (from the mover's own view) through the
/// transports, as the screens would submit them.
Future<void> _play(WidgetTester tester, NetworkTransport host, NetworkTransport guest, int moves,
    Map<String, dynamic>? Function(Game view, Random rng) pick, {int seed = 1}) async {
  final rng = Random(seed);
  for (var i = 0; i < moves && !host.game.isOver; i++) {
    final t = host.game.currentPlayer == Player.a ? host : guest;
    final move = pick(t.game, rng);
    if (move == null) break;
    final n = host.moves.length;
    await tester.runAsync(() => t.submit(move));
    await _until(tester, () => host.moves.length == n + 1 && guest.moves.length == n + 1, 'move $i');
  }
}

/// "Raum starten" for [gameId] (fixed, from its tile), with [setUp] taps,
/// then the waiting room.
Future<void> _room(WidgetTester tester, String gameId, String prefix, Future<void> Function() setUp) async {
  tester.view.physicalSize = const Size(390, 1500) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final created = CreatedTransports();
  final deps = testDeps(discovery: FakeDiscovery(), created: created, name: 'Anna');
  final names = PlayerNameController.memory(name: 'Anna');
  await tester.pumpWidget(
      RepaintBoundary(key: _hostKey, child: _app(PairingScreen(deps: deps, nameController: names, gameId: gameId))));
  await tester.pump();
  await setUp();
  await _shot(tester, _hostKey, '$prefix-room-start');
  await tester.ensureVisible(find.byKey(const Key('pair-host-start')));
  await tester.tap(find.byKey(const Key('pair-host-start')));
  await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty);
  await _shot(tester, _hostKey, '$prefix-room-waiting');
  await unmountAndSettleSockets(tester, created);
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.shared.markFirst(SeenTips.maumauIntro);
  });

  testWidgets('kld118 network: "Raum starten" with the house rules, the waiting room', skip: skip, (tester) async {
    await _room(tester, 'maumau', 'kld118-01', () async {
      await tester.tap(find.byKey(const Key('pair-maumau-rule-jackOnJack')));
      await tester.pump();
    });
  });

  testWidgets('kld118 network: a game in progress on the host and the guest', skip: skip, (tester) async {
    final (host, guest) = await _start(tester, const GameConfig('maumau', seed: 3));
    await _shot(tester, _guestKey, 'kld118-02-guest-start-rules');
    // Lay a card when one fits (a jack wishes hearts), else draw or pass.
    await _play(tester, host, guest, 4, (view, rng) {
      final g = view as MauMauGame;
      final legal = g.legalMoves;
      final plays = [for (final m in legal) if (m['action'] == 'play') m];
      return plays.isNotEmpty ? plays.first : legal.first;
    });
    await _shot(tester, _hostKey, 'kld118-03-host-mid-game');
    await _shot(tester, _guestKey, 'kld118-04-guest-mid-game');
  });

  testWidgets('kld121 network: "Raum starten" with the lives and the house rule, the waiting room', skip: skip,
      (tester) async {
    await _room(tester, 'maexchen', 'kld121-01', () async {
      await tester.tap(find.byKey(const Key('pair-maexchen-lives-5')));
      await tester.pump();
    });
  });

  testWidgets('kld121 network: a game in progress on the host and the guest', skip: skip, (tester) async {
    final (host, guest) = await _start(tester, const GameConfig('maexchen', seed: 4));
    await _shot(tester, _guestKey, 'kld121-02-guest-start-options');
    // Anna rolls and says the truth (or the lowest value above), Ben
    // believes and rolls: Ben looks under his cup, Anna waits.
    await _play(tester, host, guest, 4, (view, rng) {
      final g = view as MaexchenGame;
      return switch (g.phase) {
        MaexchenPhase.roll => MaexchenGame.rollMove,
        MaexchenPhase.announce => MaexchenGame.announceMove(
            MaexchenGame.valuesAbove(g.announced).contains(g.diceValue)
                ? g.diceValue!
                : MaexchenGame.valuesAbove(g.announced).first),
        MaexchenPhase.respond => MaexchenGame.believeMove,
      };
    });
    await tester.tap(_on(_guestKey, find.byKey(const Key('maexchen-peek'))));
    await _shot(tester, _guestKey, 'kld121-03-guest-peeks');
    await _shot(tester, _hostKey, 'kld121-04-host-waits');
  });
}
