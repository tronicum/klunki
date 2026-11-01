// Screenshot captures of the app look (KLD-062). Skipped unless
// KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots
//
// Renders with the real bundled fonts (and the SDK's Material icons font),
// so the PNGs show real text instead of the test font's boxes. Captures the
// menu, every game mid-game, the result dialog and pairing in light and
// dark at phone (390×844) and tablet (1180×820) size, plus Arabic.
//
// The App Store set (group "appstore", exact Apple pixel sizes) is skipped
// unless KLUNKI_APPSTORE=<output dir> is set; see docs/APPSTORE.md:
//
//   KLUNKI_APPSTORE=/tmp/appstore flutter test test/screenshots --plain-name appstore
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/net/join_payload.dart' show klunkiDefaultPort, klunkiDefaultWebSocketPort;
import 'package:klunki/ui/games/schiffe/schiffe_grid.dart';
import 'package:klunki/ui/menu_screen.dart' show menuShowsDebugConsole;
import 'package:klunki/profile/quartett_deck_settings.dart';
import 'package:klunki/ui/games/quartett_deck_picker.dart';
import 'package:klunki/ui/games/quartett_gallery.dart';
import 'package:klunki/ui/games/quartett_media.dart';
import 'package:klunki/ui/games/quartett_media_data.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/pairing/relay_host_screen.dart';
import 'package:klunki/ui/player_name_dialog.dart';
import 'package:klunki/ui/shell/game_screen.dart' show PlayerLabels, PlayerLabelsScope;
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_net/relay_server.dart';

import '../ui/pairing/pairing_test_utils.dart';

final String? _out = Platform.environment['KLUNKI_SHOTS'];
final String? _appstoreOut = Platform.environment['KLUNKI_APPSTORE'];
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

/// [webFonts]: the bundled fallback fonts as on the web (KLD-093), so Arabic,
/// Persian and Chinese text renders here too.
Widget _themed(Widget home, {Locale locale = const Locale('de'), bool webFonts = false}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: withAppFonts(KlunkiTheme.light, web: webFonts),
      darkTheme: withAppFonts(KlunkiTheme.dark, web: webFonts),
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

/// Decodes the bundled Quartett photos (KLD-082) outside the fake clock, so
/// the shot shows them instead of an empty band.
Future<void> _precachePhotos(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final deck in quartettMediaData.values) {
      for (final m in deck.values) {
        if (m.image case final img?) await precacheImage(AssetImage(img.asset), context);
      }
    }
  });
  await tester.pumpAndSettle();
}

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

/// Schiffe setup: "Zufällig", then the first ship cell (row-major) tapped so
/// that ship is selected. Returns that cell.
Future<(int, int)> _schiffeSetup(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('sv-random')));
  await tester.pump();
  for (var r = 0; r < 10; r++) {
    for (var c = 0; c < 10; c++) {
      final cell = find.byKey(Key('sv-own-$r-$c'));
      if (find.descendant(of: cell, matching: find.byKey(svShipMarkerKey)).evaluate().isNotEmpty) {
        await tester.tap(cell);
        await tester.pump();
        return (r, c);
      }
    }
  }
  throw StateError('no ship');
}

void main() {
  final skip = _out == null ? 'set KLUNKI_SHOTS=<dir> to capture screenshots' : null;
  setUpAll(() async {
    if (_out != null || _appstoreOut != null) await _loadFonts();
  });

  _appStore();


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

      // KLD-059: chess after the "Fried Liver" attack: White's queen gives
      // check (badge, red king square, last move), both sides have captured,
      // the board is turned to Black, the king is selected with its targets.
      testWidgets('chess $tag', skip: skip != null, (tester) async {
        await _setup(tester, size, b);
        final c = await _game(tester, 'chess', 0);
        for (final m in ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', 'f3g5', 'd7d5', 'e4d5', 'f6d5', 'g5f7', 'e8f7', 'd1f3']) {
          c.submit({'action': 'move', 'from': m.substring(0, 2), 'to': m.substring(2)});
        }
        await tester.pump();
        await tester.tap(find.byKey(const Key('chess-sq-f7')));
        await tester.pump();
        await _shot(tester, 'chess-$tag');
      });

      if (size == phone) {
        // KLD-068: placement with the whole fleet at random, one ship
        // selected (accent outline) and the harbour list.
        testWidgets('schiffe setup $tag', skip: skip != null, (tester) async {
          await _setup(tester, size, b);
          await _game(tester, 'schiffe', 0);
          await _schiffeSetup(tester);
          await _shot(tester, 'schiffe-setup-$tag');
        });

        // A ship being dragged: green footprint where it fits, red where not.
        for (final fits in [true, false]) {
          testWidgets('schiffe drag ${fits ? 'valid' : 'invalid'} $tag', skip: skip != null, (tester) async {
            await _setup(tester, size, b);
            await _game(tester, 'schiffe', 0);
            final (r, c) = await _schiffeSetup(tester);
            final g = await tester.startGesture(tester.getCenter(find.byKey(Key('sv-own-$r-$c'))));
            await tester.pump();
            Finder cell(int r, int c) => find.byKey(Key('sv-own-$r-$c'));
            if (fits) {
              // Drag across the sea until the footprint shows green.
              search:
              for (var r = 9; r >= 0; r--) {
                for (var c = 0; c < 10; c++) {
                  await g.moveTo(tester.getCenter(cell(r, c)));
                  await tester.pump();
                  if (tester.widget<SchiffeCellView>(cell(r, c)).preview == SvPreview.valid) break search;
                }
              }
            } else {
              await g.moveTo(tester.getCenter(cell(9, 9)));
              await tester.pump();
            }
            await _shot(tester, 'schiffe-drag-${fits ? 'valid' : 'invalid'}-$tag');
            await g.up();
            await tester.pump(const Duration(seconds: 1));
          });
        }
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

  // KLD-081: the setup on the real board for X and O, and the same armies
  // on the play board after "Fertig" (phone light; O after one X move).
  testWidgets('kld081 setup and board', skip: skip != null, (tester) async {
    await _setup(tester, phone, Brightness.light);
    final c = await _game(tester, 'gostrategy', 0);
    Future<void> again(String name) async {
      await _shot(tester, name);
      debugDisableShadows = false; // [_shot] reset it
    }

    await tester.tap(find.byKey(const Key('go-cell-62')));
    await tester.pump();
    await again('kld081-setup-X-phone-light');
    await tester.tap(find.byKey(const Key('go-cell-62')));
    await tester.pump();
    c.submit(GoStrategyGame.setupMove(GoStrategyGame.randomSetup(c.config.seed * 2)));
    c.acknowledgeHandover();
    await tester.pump();
    await again('kld081-setup-O-phone-light');
    c.submit(GoStrategyGame.setupMove(GoStrategyGame.randomSetup(c.config.seed * 2 + 1)));
    c.acknowledgeHandover();
    await tester.pump();
    await again('kld081-board-X-phone-light');
    final g = c.game as GoStrategyGame;
    c.submit(g.legalMoves.first);
    c.acknowledgeHandover();
    await tester.pump();
    await _shot(tester, 'kld081-board-O-phone-light');
  });

  // KLD-069: a card of every deck, the card gallery and the deck picker,
  // phone light and dark.
  for (final b in Brightness.values) {
    final tag = _tag(phone, b);
    for (final (deck, card) in [('cars', 'B2'), ('trains', 'C4'), ('rockets', 'A1'), ('planes', 'C1')]) {
      testWidgets('kld069 card $deck $tag', skip: skip != null, (tester) async {
        await _setup(tester, phone, b);
        final d = QuartettDeck.byId(deck)!;
        await tester.pumpWidget(_wrap(_themed(
            QuartettCardPagerScreen(deck: d, initialIndex: d.cards.indexOf(d.cardById(card)!)))));
        await _shot(tester, 'kld069-card-$deck-$tag');
      });
    }
    testWidgets('kld069 gallery $tag', skip: skip != null, (tester) async {
      await _setup(tester, phone, b);
      await tester.pumpWidget(_wrap(_themed(const QuartettGalleryScreen())));
      await _shot(tester, 'kld069-gallery-$tag');
    });
    testWidgets('kld069 deck gallery $tag', skip: skip != null, (tester) async {
      await _setup(tester, phone, b);
      await tester.pumpWidget(_wrap(_themed(QuartettDeckGalleryScreen(deck: QuartettDeck.rockets))));
      await _shot(tester, 'kld069-deck-rockets-$tag');
    });
    testWidgets('kld069 picker $tag', skip: skip != null, (tester) async {
      await _setup(tester, phone, b);
      await tester.pumpWidget(_wrap(_themed(Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('go'),
              onPressed: () => showQuartettDeckPicker(context, settings: QuartettDeckSettings.memory('trains')),
              child: const Text('go'),
            ),
          ),
        ),
      ))));
      await tester.tap(find.byKey(const Key('go')));
      await tester.pumpAndSettle();
      await _shot(tester, 'kld069-picker-$tag');
    });
    testWidgets('kld069 trumpf trains $tag', skip: skip != null, (tester) async {
      await _setup(tester, phone, b);
      final c = GameController.hotSeat(const GameConfig('quartett-trumpf', seed: 7, deck: 'trains'));
      addTearDown(c.dispose);
      await tester.pumpWidget(_wrap(_themed(buildGameScreen(c))));
      await _shot(tester, 'kld069-trumpf-trains-$tag');
    });
  }

  // KLD-083: "Spiel hosten" in a PWA opened as localhost: the notice under
  // the QR and link, collapsed and with "Wie finde ich die Adresse?" open.
  testWidgets('kld083 localhost waiting phone-light', skip: skip != null, (tester) async {
    await _setup(tester, phone, Brightness.light);
    final server = (await tester.runAsync(() => Zone.root.run(
        () => RelayServer.start(port: 0, address: InternetAddress.loopbackIPv4, pingInterval: null))))!;
    final created = CreatedTransports();
    final page = Uri.parse('http://localhost:${server.port}/');
    await tester.pumpWidget(_wrap(_themed(RelayHostScreen(
      hostTransport: (config, r, {required name}) => relayHost(created, config, r, name: name),
      defaultRelay: relayUriForPage(page),
      pageUrl: page,
      seed: () => 7,
      deviceName: () => 'Anna',
    ))));
    await tester.pump();
    await tester.tap(find.byKey(const Key('relay-host-start')));
    await pumpUntil(tester, () => find.byKey(const Key('relay-host-waiting')).evaluate().isNotEmpty, what: 'waiting');
    await tester.ensureVisible(find.byKey(const Key('relay-host-loopback')));
    await _shot(tester, 'kld083-localhost-waiting-phone-light', settle: const Duration(milliseconds: 300));
    debugDisableShadows = false;
    await tester.tap(find.byKey(const Key('loopback-how')).first);
    await tester.pump(const Duration(milliseconds: 400)); // a spinner: never settles
    await tester.ensureVisible(find.byKey(const Key('loopback-how-relay')));
    await _shot(tester, 'kld083-localhost-help-phone-light', settle: const Duration(milliseconds: 300));
    await unmountAndSettleSockets(tester, created);
    await tester.pump(const Duration(seconds: 6));
    await tester.runAsync(server.close);
  });

  // KLD-082: rocket cards with Commons photos (gallery grid, full card) and
  // the photo credit, phone light and dark.
  for (final b in Brightness.values) {
    final tag = _tag(phone, b);
    testWidgets('kld082 deck rockets $tag', skip: skip != null, (tester) async {
      await _setup(tester, phone, b);
      await tester.pumpWidget(_wrap(_themed(QuartettDeckGalleryScreen(deck: QuartettDeck.rockets))));
      await _precachePhotos(tester);
      await _shot(tester, 'kld082-deck-rockets-$tag');
    });
    for (final card in ['A1', 'B3', 'G3']) {
      testWidgets('kld082 card rockets $card $tag', skip: skip != null, (tester) async {
        await _setup(tester, phone, b);
        final d = QuartettDeck.rockets;
        await tester.pumpWidget(
            _wrap(_themed(QuartettCardPagerScreen(deck: d, initialIndex: d.cards.indexOf(d.cardById(card)!)))));
        await _precachePhotos(tester);
        await _shot(tester, 'kld082-card-rockets-$card-$tag');
      });
    }
    testWidgets('kld082 credit dialog $tag', skip: skip != null, (tester) async {
      await _setup(tester, phone, b);
      final d = QuartettDeck.rockets;
      await tester.pumpWidget(_wrap(_themed(QuartettCardPagerScreen(deck: d, initialIndex: d.cards.indexOf(d.cardById('H4')!)))));
      await _precachePhotos(tester);
      await tester.tap(find.byKey(const Key('quartett-photo-info')));
      await tester.pumpAndSettle();
      await _shot(tester, 'kld082-credit-dialog-$tag');
    });
    testWidgets('kld082 image credits $tag', skip: skip != null, (tester) async {
      await _setup(tester, phone, b);
      await tester.pumpWidget(_wrap(_themed(const QuartettImageCreditsScreen())));
      await _precachePhotos(tester);
      await _shot(tester, 'kld082-image-credits-$tag');
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

  // KLD-091: Quartett (Trumpf) says who picks next. Hot-seat: the result
  // with the cue, a tie, the handover cover with its reason; network: the
  // status line following an older trick, with "noch 2 Runden".
  group('kld091', () {
    final opening = _qtOpening;
    final hotSeat = _qtHotSeat;

    for (final locale in const [Locale('de'), Locale('ar')]) {
      final l = locale.languageCode == 'de' ? '' : '-${locale.languageCode}';
      testWidgets('kld091 result and cover$l', skip: skip != null, (tester) async {
        await _setup(tester, phone, Brightness.light);
        final (seed, stat) = opening((s, va, vb) => s.beats(vb, va));
        await hotSeat(tester, seed, stat, locale);
        await _shot(tester, 'kld091-hotseat-result-next$l-phone-light', settle: const Duration(milliseconds: 300));
        debugDisableShadows = false;
        await tester.tap(find.byKey(const Key('qt-continue')));
        await tester.pump();
        await _shot(tester, 'kld091-hotseat-cover$l-phone-light', settle: const Duration(milliseconds: 300));
      });
      testWidgets('kld091 tie$l', skip: skip != null, (tester) async {
        await _setup(tester, phone, Brightness.light);
        final (seed, stat) = opening((s, va, vb) => va == vb);
        await hotSeat(tester, seed, stat, locale);
        await _shot(tester, 'kld091-hotseat-tie$l-phone-light', settle: const Duration(milliseconds: 300));
      });
      testWidgets('kld091 network badge$l', skip: skip != null, (tester) async {
        await _setup(tester, phone, Brightness.light);
        // X wins twice and picks a third time while O still looks at the
        // first trick.
        final ids = [for (final s in QuartettDeck.cars.stats) s.id];
        late int seed;
        late List<String> picks;
        search:
        for (seed = 1; seed < 5000; seed++) {
          for (final s1 in ids) {
            for (final s2 in ids) {
              final g = QuartettGame(QuartettMode.trumpf, seed: seed);
              final w1 = (g.applyMove({'action': 'pick', 'stat': s1})!.payload as Map)['trickWinner'];
              if (w1 != 'a') continue;
              final w2 = (g.applyMove({'action': 'pick', 'stat': s2})!.payload as Map)['trickWinner'];
              if (w2 != 'a') continue;
              picks = [s1, s2, s1];
              break search;
            }
          }
        }
        final t = _GuestTransport(GameConfig('quartett-trumpf', seed: seed));
        final c = GameController(t);
        addTearDown(c.dispose);
        await tester.pumpWidget(_wrap(_themed(
          PlayerLabelsScope(
            labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}, local: Player.b),
            child: buildGameScreen(c),
          ),
          locale: locale,
        )));
        await tester.pump();
        t.remote(picks[0]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1500));
        t.remote(picks[1]);
        t.remote(picks[2]);
        await tester.pump();
        await tester.pump();
        await _shot(tester, 'kld091-network-badge$l-phone-light', settle: const Duration(milliseconds: 1));
      });
    }
  });

  // KLD-092: Quartett (Trumpf) wording ("Runde", "Stechen", "Vorige Runde"),
  // the hot-seat status line under a result and long stat labels with
  // hyphens at phone width.
  group('kld092', () {
    testWidgets('kld092 hot-seat result with status', skip: skip != null, (tester) async {
      await _setup(tester, phone, Brightness.light);
      final (seed, stat) = _qtOpening((s, va, vb) => s.beats(vb, va));
      await _qtHotSeat(tester, seed, stat, const Locale('de'));
      await _shot(tester, 'kld092-hotseat-result-status-phone-light', settle: const Duration(milliseconds: 300));
    });
    testWidgets('kld092 tie-break', skip: skip != null, (tester) async {
      await _setup(tester, phone, Brightness.light);
      final (seed, stat) = _qtOpening((s, va, vb) => va == vb);
      await _qtHotSeat(tester, seed, stat, const Locale('de'));
      await _shot(tester, 'kld092-hotseat-stechen-phone-light', settle: const Duration(milliseconds: 300));
    });
    testWidgets('kld092 previous round overlay', skip: skip != null, (tester) async {
      await _setup(tester, phone, Brightness.light);
      // X wins (no cover), then "Vorige Runde".
      final (seed, stat) = _qtOpening((s, va, vb) => s.beats(va, vb));
      await _qtHotSeat(tester, seed, stat, const Locale('de'));
      await tester.tap(find.byKey(const Key('qt-continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(find.byKey(const Key('qt-last-trick')), -200,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(find.byKey(const Key('qt-last-trick')));
      await tester.pump();
      await _shot(tester, 'kld092-vorige-runde-overlay-phone-light', settle: const Duration(milliseconds: 500));
    });
    for (final deck in ['cars', 'planes']) {
      testWidgets('kld092 card with Höchstgeschwindigkeit $deck', skip: skip != null, (tester) async {
        await _setup(tester, phone, Brightness.light);
        final c = GameController.hotSeat(GameConfig('quartett-trumpf', seed: 7, deck: deck));
        addTearDown(c.dispose);
        await tester.pumpWidget(_wrap(_themed(buildGameScreen(c))));
        await tester.pump();
        await _precachePhotos(tester);
        await tester.ensureVisible(find.byKey(const Key('qt-stat-kmh')));
        await tester.pump();
        await _shot(tester, 'kld092-card-kmh-$deck-phone-light', settle: const Duration(milliseconds: 300));
        // The two narrow cards of the result.
        await tester.tap(find.byKey(const Key('qt-stat-kmh')));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('qt-reveal-a')));
        await tester.pump();
        await _shot(tester, 'kld092-reveal-kmh-$deck-phone-light', settle: const Duration(milliseconds: 300));
      });
    }
  });

  // KLD-099: resign and leave confirmations in a running network game.
  group('kld099', () {
    for (final (locale, b) in [
      (const Locale('de'), Brightness.light),
      (const Locale('de'), Brightness.dark),
      (const Locale('ar'), Brightness.light),
      (const Locale('fa'), Brightness.light),
    ]) {
      for (final leave in [false, true]) {
        final name = 'kld099-${leave ? 'leave' : 'resign'}-${locale.languageCode}-phone-${b.name}';
        testWidgets(name, skip: skip != null, (tester) async {
          await _setup(tester, phone, b);
          final t = _GuestTransport(const GameConfig('connect4', seed: 7));
          final c = GameController(t);
          addTearDown(c.dispose);
          await tester.pumpWidget(_wrap(_themed(
            Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => PlayerLabelsScope(
                        labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}, local: Player.b),
                        child: buildGameScreen(c),
                      ),
                    )),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
            locale: locale,
            webFonts: true,
          )));
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          // Anna (X) and Ben (O) each dropped a disc.
          await c.submit({'col': 3});
          await c.submit({'col': 3});
          await tester.pumpAndSettle();
          if (leave) {
            await tester.tap(find.byType(BackButton));
          } else {
            await tester.tap(find.byKey(const Key('shell-resign')));
          }
          await tester.pumpAndSettle();
          await _shot(tester, name, settle: const Duration(milliseconds: 1));
        });
      }
    }
  });

  // KLD-102: default player names (Anna / Ben, regional per locale) instead
  // of X / O. "Wer spielt?" at the start of a hot-seat game, the Quartett
  // (Trumpf) status line, a 4 Gewinnt status, and RTL sentences with names.
  group('kld102', () {
    for (final locale in const [Locale('de'), Locale('ar')]) {
      final l = locale.languageCode;
      testWidgets('kld102 start dialog $l', skip: skip != null, (tester) async {
        await _setup(tester, phone, Brightness.light);
        if (l == 'de') {
          await tester.pumpWidget(_wrap(KlunkiApp(localeController: LocaleController.memory(locale))));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('menu-connect4')));
        } else {
          // The bundled Arabic font needs the web fallback here (KLD-093).
          await tester.pumpWidget(_wrap(_themed(
            PlayerNameScope(
              controller: PlayerNameController.memory(),
              hotSeat: HotSeatNamesController.memory(),
              child: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => openGameFromMenu(context, 'connect4'),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
            locale: locale,
            webFonts: true,
          )));
          await tester.tap(find.text('open'));
        }
        await tester.pumpAndSettle();
        await _shot(tester, 'kld102-start-dialog-$l-phone-light', settle: const Duration(milliseconds: 1));
      });
      testWidgets('kld102 trumpf status $l', skip: skip != null, (tester) async {
        await _setup(tester, phone, Brightness.light);
        final (seed, stat) = _qtOpening((s, va, vb) => s.beats(vb, va));
        await _qtHotSeat(tester, seed, stat, locale, webFonts: true);
        await _shot(tester, 'kld102-trumpf-status-$l-phone-light', settle: const Duration(milliseconds: 300));
      });
    }
    testWidgets('kld102 connect4 de', skip: skip != null, (tester) async {
      await _setup(tester, phone, Brightness.light);
      final c = await _game(tester, 'connect4', 3);
      await tester.pump();
      expect(c.game.currentPlayer, Player.b);
      await _shot(tester, 'kld102-connect4-de-phone-light');
    });
    // A typed Latin name in a Persian sentence, the other player keeps the
    // Persian default name.
    testWidgets('kld102 connect4 fa mixed', skip: skip != null, (tester) async {
      await _setup(tester, phone, Brightness.light);
      final c = GameController.hotSeat(const GameConfig('connect4', seed: 7));
      addTearDown(c.dispose);
      _play(c, 4);
      await tester.pumpWidget(_wrap(_themed(
        PlayerLabelsScope(labels: const PlayerLabels(names: {Player.a: 'Lena'}), child: buildGameScreen(c)),
        locale: const Locale('fa'),
        webFonts: true,
      )));
      await tester.pump();
      await _shot(tester, 'kld102-connect4-fa-mixed-phone-light');
    });
  });
  // KLD-100: "3 or fewer cards: choose". The low picker's cards face-up, the
  // defender's handover cover naming the stat, the defender's choice with
  // the stat highlighted, and the round it decides.
  group('kld100', () {
    Player other(Player p) => p == Player.a ? Player.b : Player.a;
    // A small iPhone (SE: 375×667), a large one (Pro Max: 430×932), a
    // tablet; light and dark.
    const sizes = {'small': Size(375, 667), 'large': Size(430, 932), 'tablet': tablet};
    /// All choose cards on screen at once, without scrolling.
    void expectAllCardsFit(WidgetTester tester, Size size) {
      final cards = find.byWidgetPredicate((w) {
        final k = w.key;
        return k is ValueKey<String> && k.value.startsWith('qt-choose-') && k.value != 'qt-choose-hint';
      });
      expect(cards.evaluate().length, inInclusiveRange(2, 3));
      expect(tester.state<ScrollableState>(find.byType(Scrollable).last).position.pixels, 0);
      for (final e in cards.evaluate()) {
        final box = e.renderObject! as RenderBox;
        final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
        expect(bottom, lessThanOrEqualTo(size.height), reason: 'card bottom at $bottom on ${size.height}');
      }
    }

    for (final (name, size, b) in [
      for (final MapEntry(key: name, value: size) in sizes.entries)
        for (final b in Brightness.values) (name, size, b),
    ]) {
      final tag = '$name-${b.name}';
      testWidgets('kld100 picker chooses $tag', skip: skip != null, (tester) async {
        await _setup(tester, size, b);
        final (seed, moves) = _qtMovesTo((g) =>
            g.announcedStat == null && g.mustChoose && g.stackSize(g.picker) == 3 && !g.choosesCard(other(g.picker)));
        await _qtHotSeatAt(tester, seed, moves);
        await tester.pump(const Duration(milliseconds: 300));
        expectAllCardsFit(tester, size);
        await _shot(tester, 'kld100-picker-choose-$tag', settle: const Duration(milliseconds: 300));
      });
      testWidgets('kld100 defender chooses $tag', skip: skip != null, (tester) async {
        await _setup(tester, size, b);
        final (seed, moves) = _qtMovesTo((g) =>
            g.announcedStat == null &&
            !g.mustChoose &&
            !g.choosesCard(g.picker) &&
            g.stackSize(other(g.picker)) == 3);
        final c = await _qtHotSeatAt(tester, seed, moves);
        await tester.ensureVisible(find.byKey(const Key('qt-stat-kmh')));
        await tester.tap(find.byKey(const Key('qt-stat-kmh')));
        await tester.pump();
        expect(c.needsHandover, isTrue);
        await _shot(tester, 'kld100-defender-cover-$tag', settle: const Duration(milliseconds: 300));
        debugDisableShadows = false;
        await tester.tap(find.byKey(const Key('handover-continue')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expectAllCardsFit(tester, size);
        await _shot(tester, 'kld100-defender-choose-$tag', settle: const Duration(milliseconds: 300));
        debugDisableShadows = false;
        final g = c.game as QuartettGame;
        final card = g.stackOf(g.currentPlayer).first;
        await tester.ensureVisible(find.byKey(Key('qt-choose-${card.id}')));
        await tester.tap(find.byKey(Key('qt-choose-${card.id}')));
        await tester.pump();
        await tester.scrollUntilVisible(find.byKey(const Key('qt-continue')), -200,
            scrollable: find.byType(Scrollable).last);
        await _shot(tester, 'kld100-defender-result-$tag', settle: const Duration(milliseconds: 300));
      });
    }
  });
}

/// KLD-100: the moves of a rule-on Quartett (Trumpf) game (random legal
/// moves, first matching seed) up to the first position satisfying [stop].
(int, List<Map<String, dynamic>>) _qtMovesTo(bool Function(QuartettGame g) stop) {
  for (var seed = 1; seed < 500; seed++) {
    final g = createGame(GameConfig('quartett-trumpf', seed: seed)) as QuartettGame;
    final rng = Random(seed);
    final moves = <Map<String, dynamic>>[];
    while (!g.isOver && !stop(g)) {
      final legal = g.legalMoves;
      moves.add(legal[rng.nextInt(legal.length)]);
      g.applyMove(moves.last);
    }
    if (!g.isOver) return (seed, moves);
  }
  throw StateError('no game');
}

/// KLD-100: a hot-seat game (Anna = X, Ben = O) of [seed] with [moves]
/// played, on screen.
Future<GameController> _qtHotSeatAt(WidgetTester tester, int seed, List<Map<String, dynamic>> moves,
    {Locale locale = const Locale('de')}) async {
  final t = HotSeatTransport(GameConfig('quartett-trumpf', seed: seed));
  for (final m in moves) {
    t.submitSync(m);
  }
  final c = GameController(t);
  addTearDown(c.dispose);
  await tester.pumpWidget(_wrap(_themed(
    PlayerLabelsScope(
      labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}),
      child: buildGameScreen(c),
    ),
    locale: locale,
  )));
  await tester.pump();
  await _precachePhotos(tester);
  return c;
}

/// First (seed, stat) of the cars deck whose opening trick satisfies [ok].
(int, String) _qtOpening(bool Function(QuartettStat s, num va, num vb) ok) {
  for (var seed = 1; seed < 5000; seed++) {
    final g = QuartettGame(QuartettMode.trumpf, seed: seed);
    final a = g.topCard(Player.a)!, b = g.topCard(Player.b)!;
    for (final s in QuartettDeck.cars.stats) {
      if (ok(s, a.stats[s.id]!, b.stats[s.id]!)) return (seed, s.id);
    }
  }
  throw StateError('no seed');
}

/// A hot-seat Quartett (Trumpf) game of [seed] with [stat] picked: the
/// result is on screen, "Weiter" scrolled into view.
Future<GameController> _qtHotSeat(WidgetTester tester, int seed, String stat, Locale locale,
    {bool webFonts = false}) async {
  final c = GameController.hotSeat(GameConfig('quartett-trumpf', seed: seed));
  addTearDown(c.dispose);
  await tester.pumpWidget(_wrap(_themed(buildGameScreen(c), locale: locale, webFonts: webFonts)));
  await tester.pump();
  await _precachePhotos(tester);
  await tester.ensureVisible(find.byKey(Key('qt-stat-$stat')));
  await tester.tap(find.byKey(Key('qt-stat-$stat')));
  await tester.pump();
  await tester.scrollUntilVisible(find.byKey(const Key('qt-continue')), -200, scrollable: find.byType(Scrollable).last);
  return c;
}

/// One device of a network game for player O: X's picks come from [remote].
class _GuestTransport implements GameTransport {
  _GuestTransport(GameConfig config) : _inner = HotSeatTransport(config);
  final HotSeatTransport _inner;

  @override
  bool get fullInformation => false;
  @override
  GameConfig get config => _inner.config;
  @override
  Set<Player> get localPlayers => const {Player.b};
  @override
  Game get game => _inner.game;
  @override
  List<AcceptedMove> get moves => _inner.moves;
  @override
  Stream<AcceptedMove> get accepted => _inner.accepted;
  @override
  Future<SubmitResult> submit(Map<String, dynamic> move) async => _inner.submitSync(move);

  void remote(String stat) => _inner.submitSync({'action': 'pick', 'stat': stat});

  @override
  void dispose() => _inner.dispose();
}

// ---------------------------------------------------------------------------
// App Store screenshots (docs/APPSTORE.md). Exact pixel sizes of Apple's
// "Screenshot specifications": logical size × device pixel ratio. Light
// mode, German and English, games set up deterministically mid-game. The
// PNGs are RGB without an alpha channel (App Store Connect rejects alpha).

/// Folder name → (logical portrait size, device pixel ratio).
const _appStoreDevices = <String, (Size, double)>{
  'iphone-6.9': (Size(440, 956), 3), // 1320 × 2868
  'iphone-6.3': (Size(402, 874), 3), // 1206 × 2622
  'ipad-13': (Size(1032, 1376), 2), // 2064 × 2752
};

void _appStore() {
  final out = _appstoreOut;
  final skip = out == null;

  Future<void> setup(WidgetTester tester, Size size, double dpr) async {
    tester.view.physicalSize = size * dpr;
    tester.view.devicePixelRatio = dpr;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    debugDisableShadows = false;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }

  Future<void> shot(WidgetTester tester, String path, Size size, double dpr,
      {Duration settle = const Duration(seconds: 2)}) async {
    await tester.pump(settle);
    await tester.pump();
    final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
    await tester.runAsync(() async {
      final ui.Image img = await ro.toImage(pixelRatio: dpr);
      final w = (size.width * dpr).round(), h = (size.height * dpr).round();
      expect((img.width, img.height), (w, h), reason: path);
      final rgba = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      final f = File('$out/$path.png');
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync(_pngRgb(rgba!.buffer.asUint8List(), w, h));
    });
    debugDisableShadows = true;
  }

  Future<GameController> game(WidgetTester tester, GameConfig config, Locale locale) async {
    final c = GameController.hotSeat(config);
    addTearDown(c.dispose);
    await tester.pumpWidget(_wrap(_themed(buildGameScreen(c), locale: locale)));
    return c;
  }

  void handover(GameController c) {
    if (c.needsHandover) c.acknowledgeHandover();
  }

  // Each scene builds its screen and returns a cleanup (sockets) or null.
  final scenes = <String, Future<Future<void> Function()?> Function(WidgetTester, Locale)>{
    '01-menu': (tester, locale) async {
      menuShowsDebugConsole = false; // as in a release build
      addTearDown(() => menuShowsDebugConsole = true);
      await tester.pumpWidget(_wrap(KlunkiApp(localeController: LocaleController.memory(locale))));
      return null;
    },
    '02-quartett': (tester, locale) async {
      final c = await game(tester, const GameConfig('quartett-trumpf', seed: 7, deck: 'rockets'), locale);
      _play(c, 3);
      await tester.pump();
      await _precachePhotos(tester);
      return null;
    },
    '03-quartett-gallery': (tester, locale) async {
      await tester.pumpWidget(_wrap(_themed(QuartettDeckGalleryScreen(deck: QuartettDeck.rockets), locale: locale)));
      await _precachePhotos(tester);
      return null;
    },
    '04-schiffe': (tester, locale) async {
      final c = await game(tester, const GameConfig('schiffe', seed: 7), locale);
      _play(c, 60);
      await tester.pump();
      return null;
    },
    '05-gostrategy': (tester, locale) async {
      final c = await game(tester, const GameConfig('gostrategy', seed: 7), locale);
      c.submit(GoStrategyGame.setupMove(GoStrategyGame.randomSetup(14)));
      handover(c);
      c.submit(GoStrategyGame.setupMove(GoStrategyGame.randomSetup(15)));
      handover(c);
      final g = c.game as GoStrategyGame;
      // Quiet moves (no fights) so both armies stay on the board.
      for (var i = 0; i < 30; i++) {
        final quiet = [
          for (final m in g.legalMoves)
            if (m['action'] == 'move' && g.board[m['to'] as int].owner == null) m
        ];
        if (quiet.isEmpty) break;
        c.submit(quiet[(i * 7 + 3) % quiet.length]);
        handover(c);
      }
      await tester.pump();
      return null;
    },
    '06-chess': (tester, locale) async {
      final c = await game(tester, const GameConfig('chess', seed: 7), locale);
      // An Italian opening; White to move, the knight on f3 selected.
      for (final m in ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5', 'c2c3', 'g8f6', 'd2d3', 'd7d6', 'e1g1', 'e8g8']) {
        c.submit({'action': 'move', 'from': m.substring(0, 2), 'to': m.substring(2)});
        handover(c);
      }
      await tester.pump();
      await tester.tap(find.byKey(const Key('chess-sq-f3')));
      await tester.pump();
      return null;
    },
    '07-play-together': (tester, locale) async {
      final created = CreatedTransports();
      final deps = testDeps(
        discovery: FakeDiscovery(),
        created: created,
        name: 'Anna',
        addresses: const ['192.168.1.20'],
        preferredPort: klunkiDefaultPort,
        preferredWsPort: klunkiDefaultWebSocketPort,
      );
      await tester.pumpWidget(_wrap(_themed(PairingScreen(deps: deps), locale: locale)));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pair-host-start')));
      await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty, what: 'waiting');
      return () => unmountAndSettleSockets(tester, created);
    },
    '08-muehle': (tester, locale) async {
      final c = await game(tester, const GameConfig('muehle', seed: 7), locale);
      _play(c, 13);
      await tester.pump();
      return null;
    },
  };

  group('appstore', () {
    for (final MapEntry(key: device, value: (size, dpr)) in _appStoreDevices.entries) {
      for (final locale in const [Locale('de'), Locale('en')]) {
        for (final MapEntry(key: name, value: build) in scenes.entries) {
          final path = '$device/${locale.languageCode}/$name';
          testWidgets(path, skip: skip, (tester) async {
            await setup(tester, size, dpr);
            final cleanup = await build(tester, locale);
            await shot(tester, path, size, dpr,
                settle: cleanup == null ? const Duration(seconds: 2) : const Duration(milliseconds: 300));
            await cleanup?.call();
          });
        }
      }
    }
  });
}

/// An RGB PNG (colour type 2, no alpha) of [rgba]; pixels are composited on
/// white, the screens are opaque anyway.
Uint8List _pngRgb(Uint8List rgba, int w, int h) {
  final raw = Uint8List(h * (w * 3 + 1));
  var o = 0;
  for (var y = 0; y < h; y++) {
    raw[o++] = 0; // filter: none
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      final a = rgba[i + 3];
      for (var k = 0; k < 3; k++) {
        raw[o++] = a == 255 ? rgba[i + k] : (rgba[i + k] * a + 255 * (255 - a)) ~/ 255;
      }
    }
  }
  final b = BytesBuilder();
  void chunk(String type, List<int> data) {
    final t = type.codeUnits;
    b.add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List());
    b.add(t);
    b.add(data);
    b.add((ByteData(4)..setUint32(0, _crc32([...t, ...data]))).buffer.asUint8List());
  }

  b.add(const [137, 80, 78, 71, 13, 10, 26, 10]);
  chunk(
      'IHDR',
      (ByteData(13)
            ..setUint32(0, w)
            ..setUint32(4, h)
            ..setUint8(8, 8)
            ..setUint8(9, 2))
          .buffer
          .asUint8List());
  chunk('IDAT', ZLibCodec(level: 6).encode(raw));
  chunk('IEND', const []);
  return b.toBytes();
}

final List<int> _crcTable = List.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final x in bytes) {
    c = _crcTable[(c ^ x) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
