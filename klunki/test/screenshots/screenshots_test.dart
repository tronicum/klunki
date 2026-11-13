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
//
// That includes Apple's creative assets (group "appstore creative": product
// page header, search results, universal image) in <dir>/creative/.
//
// The Google Play set (group "playstore", the same scenes at Play's sizes)
// needs KLUNKI_PLAYSTORE=<output dir> instead; see docs/PLAYSTORE.md:
//
//   KLUNKI_PLAYSTORE=/tmp/playstore flutter test test/screenshots --plain-name playstore
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
import 'package:klunki/profile/beginner_settings.dart';
import 'package:klunki/profile/chess_clock_settings.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/shake_settings.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/net/join_payload.dart' show klunkiDefaultPort, klunkiDefaultWebSocketPort;
import 'package:klunki/ui/game_visuals.dart' show visualsOf;
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
import 'package:klunki_engine/debug.dart' show DiceSheetText;
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_net/relay_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/asset_images.dart';
import '../ui/pairing/pairing_test_utils.dart';

final String? _out = Platform.environment['KLUNKI_SHOTS'];
final String? _appstoreOut = Platform.environment['KLUNKI_APPSTORE'];
final String? _playstoreOut = Platform.environment['KLUNKI_PLAYSTORE'];
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
  // Every part of the Chinese subset (NotoSansSC, NotoSansSC2, ...: tool/update_web_fonts.py).
  for (final f in chineseFontFamilies) {
    await family(f, ['assets/fonts/NotoSansSC/$f-Regular.ttf', 'assets/fonts/NotoSansSC/$f-Bold.ttf']);
  }
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
  await precacheShownImages(tester);
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
  // The one-time Bänkchen explanation is seen: where the bench starts open
  // (KLD-094 step 8c) it would come up over the first word tile turn.
  setUp(() => SeenTips.shared.markFirst(SeenTips.wordtilesBench));
  final skip = _out == null ? 'set KLUNKI_SHOTS=<dir> to capture screenshots' : null;
  setUpAll(() async {
    if (_out != null || _appstoreOut != null || _playstoreOut != null) await _loadFonts();
  });

  _storeShots('appstore', _appstoreOut, _appStoreDevices);
  _storeShots('playstore', _playstoreOut, _playStoreDevices, maxScenes: 8);
  _featureGraphic(_playstoreOut);
  _creativeAssets(_appstoreOut);


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
      // ("Du bist am Zug") and the guest ("Warte auf Anna…").
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

  // KLD-103: default player names (Anna / Ben, regional per locale) instead
  // of X / O. "Wer spielt?" at the start of a hot-seat game, the Quartett
  // (Trumpf) status line, a 4 Gewinnt status, and RTL sentences with names.
  group('kld103', () {
    for (final locale in const [Locale('de'), Locale('ar')]) {
      final l = locale.languageCode;
      testWidgets('kld103 start dialog $l', skip: skip != null, (tester) async {
        await _setup(tester, phone, Brightness.light);
        if (l == 'de') {
          await tester.pumpWidget(_wrap(KlunkiApp(localeController: LocaleController.memory(locale))));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('menu-connect4-tile')));
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
        await _shot(tester, 'kld103-start-dialog-$l-phone-light', settle: const Duration(milliseconds: 1));
      });
      testWidgets('kld103 trumpf status $l', skip: skip != null, (tester) async {
        await _setup(tester, phone, Brightness.light);
        final (seed, stat) = _qtOpening((s, va, vb) => s.beats(vb, va));
        await _qtHotSeat(tester, seed, stat, locale, webFonts: true);
        await _shot(tester, 'kld103-trumpf-status-$l-phone-light', settle: const Duration(milliseconds: 300));
      });
    }
    testWidgets('kld103 connect4 de', skip: skip != null, (tester) async {
      await _setup(tester, phone, Brightness.light);
      final c = await _game(tester, 'connect4', 3);
      await tester.pump();
      expect(c.game.currentPlayer, Player.b);
      await _shot(tester, 'kld103-connect4-de-phone-light');
    });
    // A typed Latin name in a Persian sentence, the other player keeps the
    // Persian default name.
    testWidgets('kld103 connect4 fa mixed', skip: skip != null, (tester) async {
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
      await _shot(tester, 'kld103-connect4-fa-mixed-phone-light');
    });
  });
  // KLD-106: no X / O in the UI. Network games from the guest's view: 4 Gewinnt
  // after the host's first disc ("Du bist am Zug", "Du: Ben · Gegner: Anna"),
  // also in Arabic; Quartett (Trumpf) after the first round (the card back
  // shows "1"). Two players with the same name ("Anna (1)").
  group('kld106', () {
    for (final (l, id, host, guest) in const [
      ('de', 'connect4', 'Anna', 'Ben'),
      ('ar', 'connect4', 'أمل', 'باسم'),
      ('de', 'quartett-trumpf', 'Anna', 'Ben'),
    ]) {
      testWidgets('kld106 network guest $id $l', skip: skip != null, (tester) async {
        await _setup(tester, phone, Brightness.light);
        final created = CreatedTransports();
        final h = (await tester.runAsync(() => loopbackHost(created, GameConfig(id, seed: 7), name: host, port: 0)))!;
        final g = (await tester.runAsync(() => loopbackJoin(created, '127.0.0.1', h.port!, name: guest)))!;
        await pumpUntil(tester, () => h.peerName != null && g.peerName != null, what: 'connected');
        expect(g.me, Player.b);
        final Map<String, dynamic> first =
            id == 'connect4' ? {'col': 3} : ((h.game as dynamic).legalMoves as List).cast<Map<String, dynamic>>().first;
        await tester.runAsync(() => h.submit(first));
        await pumpUntil(tester, () => g.moves.isNotEmpty, what: 'first move');
        await tester.pumpWidget(
            _wrap(_themed(NetworkGameSession(transport: g), locale: Locale(l), webFonts: l != 'de')));
        await tester.pump();
        if (id == 'quartett-trumpf') await _precachePhotos(tester);
        await _shot(tester, 'kld106-network-guest-$id-$l-phone-light', settle: const Duration(milliseconds: 300));
        await unmountAndSettleSockets(tester, created);
      });
    }
    testWidgets('kld106 same name', skip: skip != null, (tester) async {
      await _setup(tester, phone, Brightness.light);
      final c = GameController.hotSeat(const GameConfig('connect4', seed: 7));
      addTearDown(c.dispose);
      _play(c, 3);
      await tester.pumpWidget(_wrap(_themed(
        PlayerLabelsScope(labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Anna'}), child: buildGameScreen(c)),
      )));
      await tester.pump();
      await _shot(tester, 'kld106-same-name-phone-light');
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

// Google Play screenshots (docs/PLAYSTORE.md): PNG or JPEG without alpha,
// each side 320–3840 px (10" tablets: 1080–7680 px), the long side at most
// twice the short one, so Apple's 19.5:9 iPhone sets don't fit. The phone set
// is 9:16 at 1080 × 1920, as Play recommends for promoted listings.
const _playStoreDevices = <String, (Size, double)>{
  'phone': (Size(1080 / 2.625, 1920 / 2.625), 2.625), // 1080 × 1920 (411 × 731 dp)
  'tablet-7': (Size(600, 960), 2), // 1200 × 1920
  'tablet-10': (Size(800, 1280), 2), // 1600 × 2560
};

/// The store screenshot set [name] (the test group) at [devices], written
/// below [out]; skipped when [out] is null. [maxScenes]: the first scenes
/// only (Google Play takes at most 8 per device type).
void _storeShots(String name, String? out, Map<String, (Size, double)> devices, {int maxScenes = 10}) {
  final skip = out == null;

  Future<void> shot(WidgetTester tester, String path, Size size, double dpr,
      {Duration settle = const Duration(seconds: 2)}) async {
    await precacheShownImages(tester);
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

  final scenes = _storeScenes();

  group(name, () {
    setUp(_storeReset);
    for (final MapEntry(key: device, value: (size, dpr)) in devices.entries) {
      for (final locale in const [Locale('de'), Locale('en')]) {
        for (final MapEntry(key: name, value: build) in scenes.entries.take(maxScenes)) {
          final path = '$device/${locale.languageCode}/$name';
          testWidgets(path, skip: skip, (tester) async {
            await _storeView(tester, size, dpr);
            final cleanup = await build(tester, locale);
            await shot(tester, path, size, dpr,
                settle: cleanup == null ? const Duration(seconds: 2) : const Duration(milliseconds: 300));
            await cleanup?.call();
          });
        }
      }
    }

    // A contact sheet per language: one row per device, the scenes in
    // order, from the files written above (`<out>/overview-<lang>.png`).
    for (final lang in const ['de', 'en']) {
      testWidgets('overview-$lang', skip: skip, (tester) async {
        await tester.runAsync(() => _contactSheet(out!, [for (final d in devices.keys) '$d/$lang'], 'overview-$lang'));
      });
    }
  });
}

/// Light mode at [size] × [dpr] with real shadows (the capture resets them).
Future<void> _storeView(WidgetTester tester, Size size, double dpr) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
  debugDisableShadows = false;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

/// A fresh install that has seen the tours and opened the rules (no
/// "Neu hier?" line), default player names per language.
void _storeReset() {
  SharedPreferences.setMockInitialValues({});
  SeenTips.debugReset();
  for (final tip in [
    SeenTips.wordtilesBench,
    SeenTips.maumauIntro,
    SeenTips.dicesheetIntro,
    SeenTips.propertyIntro,
    for (final spec in gameSpecs) SeenTips.rulesOpened(spec.id),
  ]) {
    SeenTips.shared.markFirst(tip);
  }
  ExtraSeatNames.debugReset();
  ChessClockSettings.debugReset();
  ShakeSettings.debugReset();
  BeginnerSettings.debugReset();
  UndoSettings.debugReset();
}

/// The store scenes by file name.
Map<String, Future<Future<void> Function()?> Function(WidgetTester, Locale)> _storeScenes() {
  Future<GameController> game(WidgetTester tester, GameConfig config, Locale locale) async {
    final c = GameController.hotSeat(config);
    addTearDown(c.dispose);
    // The bundled fallback fonts: symbols such as → as on a device.
    await tester.pumpWidget(_wrap(_themed(buildGameScreen(c), locale: locale, webFonts: true)));
    return c;
  }

  void handover(GameController c) {
    if (c.needsHandover) c.acknowledgeHandover();
  }

  // Each scene builds its screen and returns a cleanup (sockets, clock) or
  // null. Set-up moves go through the controller; what is shown is the
  // screen of the player to move, without a handover cover.
  return <String, Future<Future<void> Function()?> Function(WidgetTester, Locale)>{
    // The release menu: "Klunki Spielesammlung", all tiles, "Karten" on the
    // Quartett tiles.
    '01-menu': (tester, locale) async {
      menuShowsDebugConsole = false; // as in a release build
      addTearDown(() => menuShowsDebugConsole = true);
      await tester.pumpWidget(_wrap(KlunkiApp(localeController: LocaleController.memory(locale))));
      await tester.pumpAndSettle();
      return null;
    },
    // KLD-060: Baulöwe, Berlin (the street names are German in every
    // language), 4 players mid-game (bot moves, seed 11: round 16, ten
    // houses): a player has landed on someone else's street with houses,
    // its deed card in the centre with the rent paid.
    '02-property': (tester, locale) async {
      final c = await game(tester, const GameConfig('property', seed: 11, players: 4), locale);
      final bot = PropertyBot(Random(3));
      for (var i = 0; i < 1500 && !c.game.isOver; i++) {
        final g = c.game as PropertyGame;
        final actor = g.actor;
        if (actor != null && g.phase == PropertyPhase.end) {
          final seat = g.seats[actor];
          final houses = [for (var s = 0; s < 40; s++) g.housesOn(s)].fold(0, (a, b) => a + b);
          if (houses >= 4 &&
              !seat.inPause &&
              g.theme.squares[seat.pos].kind == PropertyKind.street &&
              g.housesOn(seat.pos) > 0 &&
              g.ownerOf(seat.pos) != actor) {
            break;
          }
        }
        final m = bot.choose(g);
        // Trades have their own shots (property_trade_shots_test.dart).
        await c.submit(m['action'] == 'tradeOffer'
            ? g.legalMoves.firstWhere((x) => x['action'] == 'endTurn' || x['action'] == 'roll')
            : m);
      }
      expect((c.game as PropertyGame).phase, PropertyPhase.end);
      handover(c);
      await tester.pumpAndSettle();
      return null;
    },
    // Quartett (Trumpf), rockets deck: a round result with photos.
    '03-quartett': (tester, locale) async {
      final c = await game(tester, const GameConfig('quartett-trumpf', seed: 7, deck: 'rockets'), locale);
      _play(c, 3);
      await tester.pump();
      await _precachePhotos(tester);
      return null;
    },
    // KLD-094: Wortgewandt for 3, three crossing words in the store
    // language (de HAUS / STERN / BIRNE, en GAME / EARTH / LIGHT), the last
    // one accepted: Anna's rack and the score row of three.
    '04-wordtiles': (tester, locale) async {
      final de = locale.languageCode == 'de';
      final c = await game(tester, GameConfig('wordtiles', seed: 7, players: 3, tiles: de ? 'de' : 'en'), locale);
      final (w1, w2, w3) = de ? ('HAUS', 'STERN', 'BIRNE') : ('GAME', 'EARTH', 'LIGHT');
      (c.game as WordTilesGame).debugSetup(
        racks: de
            ? const [
                ['H', 'A', 'U', 'S', 'E', 'I', 'N'],
                ['T', 'E', 'R', 'N', 'O', 'D', 'L'],
                ['B', 'I', 'R', 'E', 'K', 'A', 'M'],
              ]
            : const [
                ['G', 'A', 'M', 'E', 'L', 'I', 'T'],
                ['A', 'R', 'T', 'H', 'O', 'S', 'N'],
                ['L', 'I', 'G', 'T', 'E', 'R', 'D'],
              ],
        bag: [
          ...List.filled(30, 'E'),
          ...['S', 'O', 'N', 'P', 'R', 'T', 'A'],
          if (de) ...['B', 'R', 'K', 'D'] else ...['G', 'B', 'K', 'D'],
        ],
      );
      Future<void> submit(Map<String, dynamic> move) async {
        expect((await c.submit(move)).isAccepted, isTrue, reason: '$move');
        handover(c);
      }

      // Row 7 from column 5; down column 8 from row 7; row 11 from column 5.
      await submit(WordTilesGame.placeMove([for (var i = 0; i < 4; i++) PlacedTile(7, 5 + i, w1[i])]));
      await submit(WordTilesGame.placeMove([for (var i = 1; i < 5; i++) PlacedTile(7 + i, 8, w2[i])]));
      await submit(WordTilesGame.placeMove([
        for (var i = 0; i < 5; i++)
          if (i != 3) PlacedTile(11, 5 + i, w3[i])
      ]));
      await submit(const {'action': 'accept'});
      await tester.pump();
      return null;
    },
    // KLD-118: Mau-Mau a few cards in: the own hand (the fitting cards
    // lifted), the discard pile.
    '05-maumau': (tester, locale) async {
      // Three plain cards laid (no 7, 8 or jack: no penalty, skip or wish);
      // the first seed where the player to move then holds 4+ cards, 2–3 of
      // them fitting.
      List<Map<String, dynamic>> plain(MauMauGame g) => [
            for (final m in g.legalMoves)
              if (m['action'] == 'play' &&
                  !const [MauMauRank.seven, MauMauRank.eight, MauMauRank.jack]
                      .contains(MauMauCard.byId(m['card'] as String)!.rank))
                m
          ];
      for (var seed = 1; seed < 500; seed++) {
        final g = createGame(GameConfig('maumau', seed: seed)) as MauMauGame;
        final moves = <Map<String, dynamic>>[];
        while (moves.length < 3 && plain(g).isNotEmpty) {
          moves.add(plain(g).first);
          g.applyMove(moves.last);
        }
        final fitting = g.playableCards.length;
        if (moves.length < 3 || g.handOf(g.currentPlayer).length < 4 || fitting < 2 || fitting > 3) continue;
        final c = await game(tester, GameConfig('maumau', seed: seed), locale);
        for (final m in moves) {
          expect((await c.submit(m)).isAccepted, isTrue);
          handover(c);
        }
        await tester.pumpAndSettle();
        return null;
      }
      throw StateError('no Mau-Mau deal');
    },
    // KLD-121: Mäxchen for 4: lives lost, Dani says 64 to Anna, who has to
    // believe or doubt.
    '06-maexchen': (tester, locale) async {
      final c = await game(tester, const GameConfig('maexchen', seed: 5, players: 4), locale);
      (c.game as MaexchenGame).debugScriptRolls(const [
        [3, 1],
        [5, 5],
        [6, 2],
        [4, 2],
        [4, 2],
        [6, 4],
      ]);
      const roll = MaexchenGame.rollMove, believe = MaexchenGame.believeMove, doubt = MaexchenGame.doubtMove;
      Map<String, dynamic> say(int v) => MaexchenGame.announceMove(v);
      for (final m in [
        roll, say(65), doubt, // Anna loses a life
        roll, say(55), believe, roll, say(66), doubt, // Ben loses one
        roll, say(42), doubt, // Cleo doubts the truth and loses one
        roll, say(43), believe, roll, say(64), // Dani rolled 64 and says so
      ]) {
        expect((await c.submit(m)).isAccepted, isTrue, reason: '$m');
        handover(c);
      }
      await tester.pumpAndSettle();
      return null;
    },
    // KLD-119: Ausgewürfelt for 4, six rounds in (Anna has the upper
    // bonus), Anna's first roll of round 7.
    '07-dicesheet': (tester, locale) async {
      final c = await game(tester, const GameConfig('dicesheet', seed: 11, players: 4), locale);
      final g = c.game as DiceSheetGame;
      final rng = Random(5);
      for (var round = 1; round <= 6; round++) {
        g.debugScriptRolls([
          [round, round, round, round, round == 6 ? 1 : 6],
        ]);
        await c.submit(DiceSheetGame.rollMove());
        await c.submit(DiceSheetGame.scoreMove(DiceBox.upperFor(round)));
        for (var s = 1; s < g.playerCount; s++) {
          while (true) {
            final m = DiceSheetText(game: g).autoMove(rng);
            await c.submit(m);
            if (m['action'] == 'score') break;
          }
        }
      }
      g.debugScriptRolls(const [
        [5, 5, 2, 5, 3],
      ]);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('dicesheet-roll')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dicesheet-roll')));
      await tester.pumpAndSettle();
      return null;
    },
    // KLD-126: chess with a 10-minute clock, an Italian opening, both sides
    // castled; White's knight on f3 selected with its targets.
    '08-chess': (tester, locale) async {
      var now = 0;
      const config = GameConfig('chess', chessClock: ChessTimeControl(10 * 60000));
      final c = GameController(HotSeatTransport(config, clockNow: () => now),
          transportFactory: (cfg) => HotSeatTransport(cfg, clockNow: () => now));
      addTearDown(c.dispose);
      await tester.pumpWidget(_wrap(_themed(buildGameScreen(c), locale: locale, webFonts: true)));
      await tester.pump();
      const opening = ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'f8c5', 'c2c3', 'g8f6', 'd2d3', 'd7d6', 'e1g1', 'e8g8'];
      const thinking = [9, 14, 21, 12, 33, 18, 47, 26, 39, 52, 31, 44]; // seconds per move
      for (final (i, m) in opening.indexed) {
        now += thinking[i] * 1000;
        await tester.pump(Duration(seconds: thinking[i]));
        final r = await c.submit({'action': 'move', 'from': m.substring(0, 2), 'to': m.substring(2)});
        expect(r.isAccepted, isTrue, reason: m);
        handover(c);
        await tester.pump();
      }
      now += 17000;
      await tester.pump(const Duration(seconds: 17));
      await tester.tap(find.byKey(const Key('chess-sq-f3')));
      await tester.pump();
      return () async => c.transport.dispose();
    },
    // Schiffe versenken: 60 shots in, hits, misses, the own fleet.
    '09-schiffe': (tester, locale) async {
      final c = await game(tester, const GameConfig('schiffe', seed: 7), locale);
      _play(c, 60);
      await tester.pump();
      return null;
    },
    // "Raum starten": waiting for a guest with the QR code (a made-up LAN
    // address, the default name).
    '10-play-together': (tester, locale) async {
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
  };
}

/// Writes `<out>/<name>.png`: the PNGs of each folder in [rows] (below
/// [out], sorted by name) scaled to one height, side by side, a row per
/// folder. RGB without alpha like the shots.
Future<void> _contactSheet(String out, List<String> rows, String name) async {
  const cellHeight = 560.0, gap = 16.0;
  final images = <List<ui.Image>>[];
  for (final row in rows) {
    final dir = Directory('$out/$row');
    if (!dir.existsSync()) continue;
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final decoded = <ui.Image>[];
    for (final f in files) {
      final codec = await ui.instantiateImageCodec(f.readAsBytesSync(), targetHeight: cellHeight.round());
      decoded.add((await codec.getNextFrame()).image);
    }
    images.add(decoded);
  }
  if (images.isEmpty) return;
  final width = images.map((r) => r.fold<double>(gap, (w, i) => w + i.width + gap)).reduce(max).ceil();
  final height = (gap + images.length * (cellHeight + gap)).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = const Color(0xFF5A4636));
  var y = gap;
  for (final row in images) {
    var x = gap;
    for (final img in row) {
      canvas.drawImage(img, Offset(x, y), Paint()..filterQuality = FilterQuality.medium);
      x += img.width + gap;
    }
    y += cellHeight + gap;
  }
  final sheet = await recorder.endRecording().toImage(width, height);
  final rgba = await sheet.toByteData(format: ui.ImageByteFormat.rawRgba);
  File('$out/$name.png').writeAsBytesSync(_pngRgb(rgba!.buffer.asUint8List(), width, height));
}

/// The store subtitle per language, as on the Play feature graphic.
const _storeSubtitles = [('de', 'Brett-, Karten- & Würfelspiele'), ('en', 'Board, card & dice games')];

/// The Spieltisch amber of the app icon, lit from the upper left.
const _storeTable = BoxDecoration(
  gradient: RadialGradient(
    center: Alignment(-0.35, -0.3),
    radius: 1.3,
    colors: [Color(0xFFF2B266), Color(0xFFE59A48), Color(0xFFA9531F)],
    stops: [0, 0.45, 1],
  ),
);

/// The store brand block at the feature graphic's scale (about 764 × 220):
/// the app icon, "Klunki", [subtitle] and a row of the menu's game pictures;
/// [stacked]: the icon above the text (about 504 × 520).
Widget _storeBrand(String subtitle, Widget icon, {bool stacked = false}) {
  const palette = KlunkiPalette.classicLight;
  const games = ['connect4', 'chess', 'maumau', 'maexchen', 'quartett-trumpf', 'property'];
  Widget picture(String id) => Container(
        width: 74,
        height: 74,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.accent(id).container,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: CustomPaint(painter: visualsOf(id).illustration(palette)),
      );

  final iconBox = DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(50),
      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: SizedBox(width: 220, height: 220, child: icon),
    ),
  );
  final align = stacked ? CrossAxisAlignment.center : CrossAxisAlignment.start;
  final text = [
    const Text('Klunki',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          fontSize: 112,
          height: 1,
          color: Color(0xFFFFF8EC),
          shadows: [Shadow(color: Color(0x80000000), blurRadius: 10, offset: Offset(0, 4))],
        )),
    const SizedBox(height: 10),
    Text(subtitle,
        style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500, fontSize: 30, color: Color(0xFF3B2412))),
    const SizedBox(height: 26),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, id) in games.indexed) ...[
          if (i > 0) const SizedBox(width: 12),
          picture(id),
        ],
      ],
    ),
  ];
  if (stacked) {
    return Column(mainAxisSize: MainAxisSize.min, children: [iconBox, const SizedBox(height: 30), ...text]);
  }
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      iconBox,
      const SizedBox(width: 40),
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: align, children: text),
    ],
  );
}

/// Captures the [_boundary] at pixel ratio 1 and writes it to [path] as an
/// RGB PNG without alpha, checking the size.
Future<void> _writeCanvas(WidgetTester tester, String path, Size size) async {
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 1);
    final w = size.width.round(), h = size.height.round();
    expect((img.width, img.height), (w, h), reason: path);
    final rgba = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(_pngRgb(rgba!.buffer.asUint8List(), w, h));
  });
}

/// The Google Play feature graphic (docs/PLAYSTORE.md "Graphics"): 1024 ×
/// 500, no alpha. The app icon, "Klunki" and the store subtitle on the
/// Spieltisch amber of the icon, a row of the menu's game pictures; all of
/// it inside the middle so a cropped or overlaid edge loses nothing.
/// `<out>/feature-graphic.png` (German) and `feature-graphic-en.png`.
void _featureGraphic(String? out) {
  const size = Size(1024, 500);
  for (final (lang, subtitle) in _storeSubtitles) {
    final file = lang == 'de' ? 'feature-graphic' : 'feature-graphic-$lang';
    testWidgets('playstore $file', skip: out == null, (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      debugDisableShadows = false;
      await tester.pumpWidget(RepaintBoundary(
        key: _boundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DecoratedBox(
            decoration: _storeTable,
            child: Center(child: _storeBrand(subtitle, Image.asset('assets/icon/app_icon.png', width: 220, height: 220))),
          ),
        ),
      ));
      await precacheShownImages(tester);
      await tester.pump();
      await _writeCanvas(tester, '$out/$file.png', size);
      debugDisableShadows = true;
    });
  }
}

/// Apple's creative asset images (docs/APPSTORE.md "Creative assets"):
/// file name → (canvas, art safe area, box of the brand block inside it,
/// brand stacked), canvas and safe area from "Creative assets
/// specifications". Everything outside the safe area is "auxiliary art"
/// that some devices and orientations crop.
const _creativeFormats = <String, (Size, Rect, Rect, bool)>{
  // Product page header, 21:9.
  'header': (Size(3840, 1646), Rect.fromLTWH(1097, 493, 1646, 661), Rect.fromLTWH(1150, 520, 1540, 607), false),
  // Search results, 3:2 at the maximum size; the brand narrower than the
  // safe area, so the game screens beside it stay uncovered.
  'search': (Size(3840, 2560), Rect.fromLTWH(836, 765, 2168, 1030), Rect.fromLTWH(1090, 800, 1660, 960), false),
  // Both placements, 16:9, PNG only; the safe area is narrow and sits high.
  'universal': (Size(5244, 2950), Rect.fromLTWH(1921, 660, 1402, 962), Rect.fromLTWH(1981, 690, 1282, 902), true),
};

/// A scene card: store scene, centre (in canvas pixels), height, angle in
/// degrees. Listed back to front.
typedef _CreativeCard = (String scene, Offset centre, double height, double degrees);

/// The game screens beside the brand, in the auxiliary area (mirrored left /
/// right), per format.
const _creativeCards = <String, List<_CreativeCard>>{
  'header': [
    ('03-quartett', Offset(260, 860), 1440, -7),
    ('06-maexchen', Offset(3580, 860), 1440, 7),
    ('02-property', Offset(700, 800), 1500, 3),
    ('08-chess', Offset(3140, 800), 1500, -3),
  ],
  'search': [
    ('03-quartett', Offset(110, 1330), 1900, -6),
    ('06-maexchen', Offset(3730, 1330), 1900, 6),
    ('02-property', Offset(540, 1260), 2000, 3),
    ('08-chess', Offset(3300, 1260), 2000, -3),
  ],
  'universal': [
    ('03-quartett', Offset(560, 1500), 2250, -6),
    ('06-maexchen', Offset(4684, 1500), 2250, 6),
    ('02-property', Offset(1290, 1430), 2420, 3),
    ('08-chess', Offset(3954, 1430), 2420, -3),
  ],
};

/// Apple's creative assets (header 21:9, search results 3:2, universal
/// 16:9), de and en: the brand block of the feature graphic inside the art
/// safe area, real game screens (the store scenes at iPhone 6.9" size) as
/// tilted cards in the auxiliary area. RGB PNGs without alpha in
/// `<out>/creative/<lang>/<format>.png`, plus `<format>-safezones.png` with
/// the safe area drawn in (for review, not for upload).
void _creativeAssets(String? out) {
  const phoneSize = Size(440, 956), phoneDpr = 3.0;
  final scenes = _storeScenes();
  // The 1024 px marketing icon (the bundled asset has 384 px only).
  const iconFile = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png';

  Widget card(ui.Image image, double height) {
    final width = height * image.width / image.height;
    final radius = BorderRadius.circular(height * 0.035);
    return Container(
      width: width,
      height: height,
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFFFF8EC), width: height * 0.006),
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: const Color(0x73000000), blurRadius: height * 0.035, offset: Offset(0, height * 0.012))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: RawImage(image: image, width: width, height: height, fit: BoxFit.cover, filterQuality: FilterQuality.high),
      ),
    );
  }

  group('appstore creative', () {
    setUp(_storeReset);
    for (final (lang, subtitle) in _storeSubtitles) {
      testWidgets(lang, skip: out == null, (tester) async {
        final locale = Locale(lang);
        // The game screens, rendered once.
        final shots = <String, ui.Image>{};
        final wanted = {for (final cards in _creativeCards.values) for (final c in cards) c.$1};
        for (final name in wanted) {
          await _storeView(tester, phoneSize, phoneDpr);
          final cleanup = await scenes[name]!(tester, locale);
          await precacheShownImages(tester);
          await tester.pump(cleanup == null ? const Duration(seconds: 2) : const Duration(milliseconds: 300));
          await tester.pump();
          final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
          shots[name] = (await tester.runAsync(() => ro.toImage(pixelRatio: phoneDpr)))!;
          await cleanup?.call();
        }
        await tester.pumpWidget(const SizedBox());
        final icon = (await tester.runAsync(() async {
          final codec = await ui.instantiateImageCodec(File(iconFile).readAsBytesSync());
          return (await codec.getNextFrame()).image;
        }))!;

        for (final MapEntry(key: format, value: (size, safe, brand, stacked)) in _creativeFormats.entries) {
          for (final guides in [false, true]) {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            debugDisableShadows = false;
            await tester.pumpWidget(RepaintBoundary(
              key: _boundary,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: DecoratedBox(
                  decoration: _storeTable,
                  child: Stack(
                    children: [
                      for (final (scene, centre, height, degrees) in _creativeCards[format]!)
                        Positioned(
                          left: centre.dx - height * shots[scene]!.width / shots[scene]!.height / 2,
                          top: centre.dy - height / 2,
                          child: Transform.rotate(angle: degrees * pi / 180, child: card(shots[scene]!, height)),
                        ),
                      Positioned.fromRect(
                        rect: brand,
                        child: FittedBox(
                          child: _storeBrand(subtitle, RawImage(image: icon, filterQuality: FilterQuality.high),
                              stacked: stacked),
                        ),
                      ),
                      if (guides) Positioned.fill(child: CustomPaint(painter: _SafeAreaPainter(safe))),
                    ],
                  ),
                ),
              ),
            ));
            await tester.pump();
            await _writeCanvas(tester, '$out/creative/$lang/$format${guides ? '-safezones' : ''}.png', size);
            debugDisableShadows = true;
          }
        }
        for (final image in [...shots.values, icon]) {
          image.dispose();
        }
      });
    }
  });
}

/// The review overlay of a creative asset: the auxiliary area dimmed, the
/// art safe area outlined and labelled with its size.
class _SafeAreaPainter extends CustomPainter {
  _SafeAreaPainter(this.safe);

  final Rect safe;

  @override
  void paint(Canvas canvas, Size size) {
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(safe);
    canvas.drawPath(outside, Paint()..color = const Color(0x8C000000));
    final stroke = size.shortestSide / 200;
    canvas.drawRect(
        safe,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = const Color(0xFF00E5FF));
    final label = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'Art safe area ${safe.width.round()} × ${safe.height.round()} at '
            '(${safe.left.round()}, ${safe.top.round()}) · canvas ${size.width.round()} × ${size.height.round()}'
            ' · dimmed: auxiliary art, may be cropped',
        style: TextStyle(fontFamily: 'Roboto', fontSize: size.shortestSide / 45, color: const Color(0xFF00E5FF)),
      ),
    )..layout(maxWidth: size.width - 40 * stroke);
    final at = Offset(10 * stroke, size.height - label.height - 10 * stroke);
    canvas.drawRRect(RRect.fromRectAndRadius((at & label.size).inflate(3 * stroke), Radius.circular(3 * stroke)),
        Paint()..color = const Color(0xE6000000));
    label.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_SafeAreaPainter old) => old.safe != safe;
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
