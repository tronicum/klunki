// KLD-117 screenshots of "Zug zurück" in the game area (no longer in the app
// bar): chess (next to the flip buttons), Wortgewandt (its control row),
// 4 Gewinnt and Schiffe versenken (the shell's row under the board) and the
// handover cover, hot-seat on a phone (390×844), de light plus 4 Gewinnt
// and chess in ar (RTL). Skipped unless KLUNKI_SHOTS=<dir> is set:
//
//   KLUNKI_SHOTS=/tmp/kld117 flutter test test/screenshots/undo_shots_test.dart
//   (or: KLUNKI_SHOTS=/tmp/kld117 flutter test test/screenshots --plain-name kld117)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/fonts.dart' show withAppFonts;
import 'package:klunki/app/theme.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/legal_move_board.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

final String? _out = Platform.environment['KLUNKI_SHOTS'];
const _boundary = Key('shot-boundary');
const _phone = Size(390, 844);
const _continue = Key('handover-continue');

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
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
}

Future<void> _shot(WidgetTester tester, String name) async {
  debugDisableShadows = false;
  await tester.pump(const Duration(milliseconds: 500));
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

/// [safe]: the top and bottom safe areas of an iPhone (logical pixels).
Future<GameController> _pump(WidgetTester tester, String id, String locale,
    {Size size = _phone, (double, double) safe = (0, 0)}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.view.padding = FakeViewPadding(top: safe.$1 * 2, bottom: safe.$2 * 2);
  tester.view.viewPadding = FakeViewPadding(top: safe.$1 * 2, bottom: safe.$2 * 2);
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(GameConfig(id, seed: 3));
  addTearDown(c.dispose);
  final names = locale == 'ar' ? const {Player.a: 'ليلى', Player.b: 'سامي'} : const {Player.a: 'Anna', Player.b: 'Ben'};
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: withAppFonts(KlunkiTheme.light, web: true),
        locale: Locale(locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayerLabelsScope(
          labels: PlayerLabels(names: names),
          child: buildGameScreen(c),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return c;
}

/// Plays [n] legal moves through the controller, passing the device on
/// after each (except, with [keepCover], the last one).
Future<void> _play(WidgetTester tester, GameController c, int n, {bool keepCover = false}) async {
  for (var i = 0; i < n; i++) {
    final moves = legalMovesOf(c.game);
    await c.submit(moves[moves.length ~/ 2]);
    await tester.pump();
    await tester.pump();
    if (keepCover && i == n - 1) break;
    if (find.byKey(_continue).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(_continue));
      await tester.pump();
    }
  }
}

void main() {
  final skip = _out == null ? 'set KLUNKI_SHOTS=<dir> to write screenshots' : null;
  setUpAll(() async {
    if (skip == null) await _loadFonts();
  });

  group('kld117', () {
    for (final l in ['de', 'ar']) {
      testWidgets('kld117 chess $l', skip: skip != null, (tester) async {
        final c = await _pump(tester, 'chess', l);
        await _play(tester, c, 2);
        await _shot(tester, 'kld117-chess-$l-phone');
      });
      testWidgets('kld117 connect4 $l', skip: skip != null, (tester) async {
        final c = await _pump(tester, 'connect4', l);
        await _play(tester, c, 3);
        await _shot(tester, 'kld117-connect4-$l-phone');
      });
    }
    testWidgets('kld117 connect4 start de', skip: skip != null, (tester) async {
      await _pump(tester, 'connect4', 'de');
      await _shot(tester, 'kld117-connect4-start-de-phone');
    });
    for (final (tag, size) in [('phone', _phone), ('small', const Size(375, 667))]) {
      testWidgets('kld117 wordtiles de $tag', skip: skip != null, (tester) async {
        final c = await _pump(tester, 'wordtiles', 'de', size: size);
        (c.game as WordTilesGame).debugSetup(
          racks: const [
            ['H', 'A', 'U', 'S', 'E', 'N', '?'],
            ['T', 'E', 'R', 'N', 'O', 'D', 'I'],
          ],
          bag: [...List.filled(30, 'E'), 'L', 'K', 'M', 'A', 'I', 'R', 'B'],
        );
        // HAUS by Anna: Ben's turn, with something to take back.
        final r = await c.submit(
          WordTilesGame.placeMove([
            for (final (col, t) in [(5, 'H'), (6, 'A'), (7, 'U'), (8, 'S')]) PlacedTile(7, col, t, null),
          ]),
        );
        expect(r.isAccepted, isTrue);
        await tester.pump();
        await tester.pump();
        await tester.tap(find.byKey(_continue));
        await tester.pump();
        await _shot(tester, 'kld117-wordtiles-de-$tag');
      });
    }
    testWidgets('kld117 schiffe de', skip: skip != null, (tester) async {
      final c = await _pump(tester, 'schiffe', 'de');
      await _play(tester, c, 2);
      await _shot(tester, 'kld117-schiffe-de-phone');
    });
    testWidgets('kld117 schiffe cover de', skip: skip != null, (tester) async {
      final c = await _pump(tester, 'schiffe', 'de');
      await _play(tester, c, 20, keepCover: true);
      await _shot(tester, 'kld117-schiffe-cover-de-phone');
    });
  });

  // KLD-094 step 8d: a tile laid this turn dragged by long-press to another
  // square, on a phone with the board zoomed in.
  group('kld094-8d', () {
    testWidgets('kld094-8d drag de', skip: skip != null, (tester) async {
      SeenTips.debugReset();
      SeenTips.shared.markFirst(SeenTips.wordtilesBench);
      final c = await _pump(tester, 'wordtiles', 'de');
      (c.game as WordTilesGame).debugSetup(
        racks: const [
          ['H', 'A', 'U', 'S', 'E', 'N', '?'],
          ['T', 'E', 'R', 'N', 'O', 'D', 'I'],
        ],
        bag: List.filled(40, 'E'),
      );
      await tester.pump();
      Finder sq(int r, int col) => find.byKey(Key('wordtiles-sq-$r-$col'));
      for (final (i, col) in [(0, 7), (1, 8), (2, 9)]) {
        await tester.tap(find.byKey(Key('wordtiles-rack-$i')));
        await tester.pump();
        await tester.tap(sq(7, col));
        await tester.pumpAndSettle();
      }
      final from = tester.getCenter(sq(7, 9));
      final to = tester.getCenter(sq(9, 8));
      final g = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 600));
      for (var i = 1; i <= 4; i++) {
        await g.moveTo(Offset.lerp(from, to, i / 5)!);
        await tester.pump();
      }
      await _shot(tester, 'kld094-8d-drag-de-phone');
      await g.moveTo(to);
      await tester.pump();
      await g.up();
      await tester.pump();
      await tester.pump();
      await _shot(tester, 'kld094-8d-dropped-de-phone');
    });
  });

  // KLD-094 step 8e: bench tiles as big as the rack tiles where there is
  // room (browser, tablet), smaller on a phone; three tiles on the bench.
  group('kld094-8e', () {
    for (final (tag, size) in [
      ('desktop-1280x800', const Size(1280, 800)),
      ('desktop-1440x900', const Size(1440, 900)),
      ('tablet-landscape', const Size(1180, 820)),
      ('tablet-portrait', const Size(820, 1180)),
      ('phone', _phone),
    ]) {
      testWidgets('kld094-8e bench $tag', skip: skip != null, (tester) async {
        SeenTips.debugReset();
        SeenTips.shared.markFirst(SeenTips.wordtilesBench);
        final c = await _pump(tester, 'wordtiles', 'de', size: size);
        (c.game as WordTilesGame).debugSetup(
          racks: const [
            ['H', 'A', 'U', 'S', 'E', 'N', '?'],
            ['T', 'E', 'R', 'N', 'O', 'D', 'I'],
          ],
          bag: List.filled(40, 'E'),
        );
        await tester.pump();
        if (find.byKey(const Key('wordtiles-bench-0-0')).evaluate().isEmpty) {
          await tester.tap(find.byKey(const Key('wordtiles-bench-toggle')));
          await tester.pump();
          await tester.pump();
        }
        for (final (i, s) in [(0, 0), (1, 1), (2, 2), (3, 3)]) {
          await tester.ensureVisible(find.byKey(Key('wordtiles-rack-$i')));
          await tester.tap(find.byKey(Key('wordtiles-rack-$i')));
          await tester.pump();
          await tester.ensureVisible(find.byKey(Key('wordtiles-bench-0-$s')));
          await tester.tap(find.byKey(Key('wordtiles-bench-0-$s')));
          await tester.pump();
        }
        await _shot(tester, 'kld094-8e-bench-de-$tag');
      });
    }
  });

  // KLD-094 step 8f: on phones where the open bench lies over the lower
  // board, its handle is a slim bar between the board and the rack (no
  // longer a link in the score row); closed and open, two tiles on it.
  group('kld094-8f', () {
    for (final (tag, locale, size, safe) in [
      ('de-375x667', 'de', const Size(375, 667), (20.0, 0.0)),
      ('de-393x852-safe', 'de', const Size(393, 852), (59.0, 34.0)),
      ('ar-375x667', 'ar', const Size(375, 667), (20.0, 0.0)),
    ]) {
      testWidgets('kld094-8f bench bar $tag', skip: skip != null, (tester) async {
        SeenTips.debugReset();
        SeenTips.shared.markFirst(SeenTips.wordtilesBench);
        final c = await _pump(tester, 'wordtiles', locale, size: size, safe: safe);
        (c.game as WordTilesGame).debugSetup(
          racks: const [
            ['H', 'A', 'U', 'S', 'E', 'N', '?'],
            ['T', 'E', 'R', 'N', 'O', 'D', 'I'],
          ],
          bag: List.filled(40, 'E'),
        );
        await tester.pump();
        expect(find.byKey(const Key('wordtiles-bench-bar')), findsOneWidget);
        Future<void> toggle() async {
          await tester.tap(find.byKey(const Key('wordtiles-bench-toggle')));
          await tester.pump();
          await tester.pump();
        }

        await toggle();
        for (final (i, s) in [(0, 0), (1, 1)]) {
          await tester.tap(find.byKey(Key('wordtiles-rack-$i')));
          await tester.pump();
          await tester.tap(find.byKey(Key('wordtiles-bench-0-$s')));
          await tester.pump();
        }
        await _shot(tester, 'kld094-8f-open-$tag');
        await toggle();
        await _shot(tester, 'kld094-8f-closed-$tag');
      });
    }
  });

  // KLD-094 step 8g (iPhone 15 Pro playtest): names next to the scores (no
  // players legend at the top), the Bänkchen bar and the open bench as wide
  // as the board, the hint about two-finger zoom, a laid tile dragged after
  // a short hold, "So geht's" with the zoom line.
  group('kld094-8g', () {
    for (final locale in ['de', 'ar']) {
      testWidgets('kld094-8g $locale', skip: skip != null, (tester) async {
        SeenTips.debugReset();
        SeenTips.shared.markFirst(SeenTips.wordtilesBench);
        final c = await _pump(tester, 'wordtiles', locale, size: const Size(393, 852), safe: (59.0, 34.0));
        (c.game as WordTilesGame).debugSetup(
          racks: const [
            ['H', 'A', 'U', 'S', 'E', 'N', '?'],
            ['T', 'E', 'R', 'N', 'O', 'D', 'I'],
          ],
          bag: List.filled(40, 'E'),
        );
        await tester.pump();
        Future<void> tap(String key) async {
          await tester.tap(find.byKey(Key(key)));
          await tester.pumpAndSettle();
        }

        // Anna lays HAUS, Ben accepts: Ben's turn, "① Anna 7  ② Ben 0".
        for (final (i, col) in [(0, 7), (1, 8), (2, 9), (3, 10)]) {
          await tap('wordtiles-rack-$i');
          await tap('wordtiles-sq-7-$col');
        }
        await tap('wordtiles-play');
        await tap('handover-continue');
        await tap('wordtiles-accept');
        await _shot(tester, 'kld094-8g-closed-$locale-393x852-safe');
        await tap('wordtiles-bench-toggle');
        for (final (i, s) in [(0, 0), (1, 1)]) {
          await tap('wordtiles-rack-$i');
          await tap('wordtiles-bench-0-$s');
        }
        await _shot(tester, 'kld094-8g-open-$locale-393x852-safe');
        await tap('wordtiles-bench-toggle');
        if (locale != 'de') return;
        // A laid tile (zoomed in), held a moment and dragged.
        await tap('wordtiles-rack-2');
        await tap('wordtiles-sq-8-8');
        Finder sq(int r, int col) => find.byKey(Key('wordtiles-sq-$r-$col'));
        final from = tester.getCenter(sq(8, 8));
        final to = tester.getCenter(sq(9, 8));
        final g = await tester.startGesture(from);
        await tester.pump(const Duration(milliseconds: 300));
        for (var i = 1; i <= 4; i++) {
          await g.moveTo(Offset.lerp(from, to, i / 5)!);
          await tester.pump();
        }
        await _shot(tester, 'kld094-8g-drag-de-393x852-safe');
        await g.moveTo(to);
        await tester.pump();
        await g.up();
        await tester.pumpAndSettle();
        await tap('shell-rules');
        await tester.ensureVisible(find.byIcon(Icons.pinch_outlined));
        await tester.pumpAndSettle();
        await _shot(tester, 'kld094-8g-help-de-393x852-safe');
      });
    }
  });
}
