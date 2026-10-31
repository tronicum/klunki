// Screenshot captures of the app look (KLD-062). Skipped unless
// KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots
//
// Renders with the real bundled fonts (and the SDK's Material icons font),
// so the PNGs show real text instead of the test font's boxes. Captures the
// menu, every game mid-game, the result dialog and pairing in light and
// dark at phone (390×844) and tablet (1180×820) size, plus Arabic.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../ui/pairing/pairing_test_utils.dart';

final String? _out = Platform.environment['KLUNKI_SHOTS'];
const _boundary = Key('shot-boundary');

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
  await family('NotoSansArabic', [
    'assets/fonts/NotoSansArabic/NotoSansArabic-Regular.ttf',
    'assets/fonts/NotoSansArabic/NotoSansArabic-Bold.ttf',
  ]);
  await family('NotoSansMath', ['assets/fonts/NotoSansMath/NotoSansMath-Regular.ttf']);
  await family('NotoSansSC', ['assets/fonts/NotoSansSC/NotoSansSC-Regular.ttf']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
}

const phone = Size(390, 844);
const tablet = Size(1180, 820);

Future<void> _setup(WidgetTester tester, Size size, Brightness b) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.platformBrightnessTestValue = b;
  // Real shadows (the test binding draws outlines instead); [_shot] resets
  // it before the test ends, the binding checks that.
  debugDisableShadows = false;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

Widget _themed(Widget home, {Locale locale = const Locale('de')}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: KlunkiTheme.light,
      darkTheme: KlunkiTheme.dark,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

Future<void> _shot(WidgetTester tester, String name, {Duration settle = const Duration(seconds: 2)}) async {
  await tester.pump(settle);
  await tester.pump();
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

Widget _wrap(Widget app) => RepaintBoundary(key: _boundary, child: app);

String _tag(Size s, Brightness b) => '${s == phone ? 'phone' : 'tablet'}-${b.name}';

/// Plays [moves] (or the first legal move [n] times) in hot-seat.
void _play(GameController c, int n) {
  for (var i = 0; i < n && !c.game.isOver; i++) {
    if (c.needsHandover) c.acknowledgeHandover();
    final g = c.game;
    final List<Map<String, dynamic>> legal = g is Connect4Game
        ? [for (final col in g.legalMoves) {'col': col}]
        : ((g as dynamic).legalMoves as List).cast<Map<String, dynamic>>();
    c.submit(legal[(i * 7 + 3) % legal.length]);
  }
  if (c.needsHandover) c.acknowledgeHandover();
}

Future<GameController> _game(WidgetTester tester, String id, int moves, {Locale locale = const Locale('de')}) async {
  final c = GameController.hotSeat(GameConfig(id, seed: 7));
  addTearDown(c.dispose);
  _play(c, moves);
  await tester.pumpWidget(_wrap(_themed(buildGameScreen(c), locale: locale)));
  return c;
}

void main() {
  final skip = _out == null ? 'set KLUNKI_SHOTS=<dir> to capture screenshots' : null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });


  for (final size in [phone, tablet]) {
    for (final b in Brightness.values) {
      final tag = _tag(size, b);
      testWidgets('menu $tag', skip: skip != null, (tester) async {
        await _setup(tester, size, b);
        await tester.pumpWidget(_wrap(KlunkiApp(localeController: LocaleController.memory(const Locale('de')))));
        await _shot(tester, 'menu-$tag');
      });

      for (final (id, moves) in [
        ('connect4', 9),
        ('muehle', 11),
        ('quartett-trumpf', 4),
        ('quartett-sets', 3),
        ('schiffe', 60),
        ('gostrategy', 42),
      ]) {
        testWidgets('$id $tag', skip: skip != null, (tester) async {
          await _setup(tester, size, b);
          final c = await _game(tester, id, 0);
          _play(c, moves);
          await tester.pump();
          await _shot(tester, '$id-$tag');
        });
      }

      testWidgets('result $tag', skip: skip != null, (tester) async {
        await _setup(tester, size, b);
        final c = await _game(tester, 'connect4', 0);
        for (final col in [3, 2, 3, 2, 3, 2, 3]) {
          c.submit({'col': col});
        }
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await _shot(tester, 'result-$tag');
      });

      // KLD-067: a network game over loopback, from both sides: the host
      // ("Du bist am Zug") and the guest ("Warte auf Anna (X)…").
      testWidgets('network $tag', skip: skip != null, (tester) async {
        await _setup(tester, size, b);
        final created = CreatedTransports();
        final host = (await tester.runAsync(
            () => loopbackHost(created, const GameConfig('connect4', seed: 7), name: 'Anna', port: 0)))!;
        final guest = (await tester.runAsync(() => loopbackJoin(created, '127.0.0.1', host.port!, name: 'Ben')))!;
        await pumpUntil(tester, () => host.peerName != null && guest.peerName != null, what: 'connected');
        for (final (i, col) in [3, 3, 2].indexed) {
          final t = host.game.currentPlayer == host.me ? host : guest;
          final r = await tester.runAsync(() => t.submit({'col': col}));
          expect(r!.isAccepted, isTrue, reason: 'move $i');
          await pumpUntil(tester, () => host.moves.length == i + 1 && guest.moves.length == i + 1, what: 'move $i');
        }
        for (final (side, t) in [('waiting', host), ('myturn', guest)]) {
          await tester.pumpWidget(_wrap(_themed(NetworkGameSession(key: ValueKey(side), transport: t))));
          await tester.pump();
          await _shot(tester, 'network-$side-$tag');
          debugDisableShadows = false;
        }
        debugDisableShadows = true;
        await unmountAndSettleSockets(tester, created);
      });

      testWidgets('pairing $tag', skip: skip != null, (tester) async {
        await _setup(tester, size, b);
        final deps = testDeps(discovery: FakeDiscovery(), created: CreatedTransports(), name: 'Annas Tablet');
        await tester.pumpWidget(_wrap(_themed(PairingScreen(deps: deps))));
        await _shot(tester, 'pairing-$tag');
      });
    }
  }

  // GoStrategy (KLD-058b): setup, the cover after a fight and the fight
  // reveal, phone light/dark.
  for (final b in Brightness.values) {
    final tag = _tag(phone, b);
    testWidgets('gostrategy setup $tag', skip: skip != null, (tester) async {
      await _setup(tester, phone, b);
      await _game(tester, 'gostrategy', 0);
      await _shot(tester, 'gostrategy-setup-$tag');
    });

    testWidgets('gostrategy fight $tag', skip: skip != null, (tester) async {
      await _setup(tester, phone, b);
      final c = await _game(tester, 'gostrategy', 0);
      final g = c.game as GoStrategyGame;
      // Both setups, then quiet moves until the player to move can attack.
      Map<String, dynamic>? attack;
      for (var i = 0; i < 400 && attack == null && !g.isOver; i++) {
        if (c.needsHandover) c.acknowledgeHandover();
        final legal = g.legalMoves;
        attack = legal.where((m) => m['action'] == 'move' && g.board[m['to'] as int].owner != null).firstOrNull;
        if (attack == null) c.submit(legal[(i * 7 + 3) % legal.length]);
      }
      if (c.needsHandover) c.acknowledgeHandover();
      await tester.pump();
      c.submit(attack!);
      await tester.pump();
      if (c.needsHandover) await _shot(tester, 'gostrategy-cover-$tag', settle: const Duration(milliseconds: 100));
      debugDisableShadows = false; // [_shot] reset it
      c.acknowledgeHandover();
      await tester.pump();
      await tester.pump(); // the reveal starts on this frame
      await _shot(tester, 'gostrategy-fight-$tag', settle: const Duration(milliseconds: 900));
    });
  }

  testWidgets('menu ar', skip: skip != null, (tester) async {
    await _setup(tester, phone, Brightness.light);
    await tester.pumpWidget(_wrap(KlunkiApp(localeController: LocaleController.memory(const Locale('ar')))));
    await _shot(tester, 'menu-ar-phone-light');
  });

  testWidgets('muehle ar', skip: skip != null, (tester) async {
    await _setup(tester, phone, Brightness.dark);
    final c = await _game(tester, 'muehle', 0, locale: const Locale('ar'));
    _play(c, 11);
    await tester.pump();
    await _shot(tester, 'muehle-ar-phone-dark');
  });
}
