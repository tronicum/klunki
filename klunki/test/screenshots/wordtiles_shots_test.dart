// KLD-094 step 2 screenshots of the word tile screen: start, mid-game with
// an open placement (challenge banner), tiles laid with the score preview,
// the blank letter picker and the game end, on an iPhone (390×844) and an
// iPad (1180×820 landscape, 820×1180 portrait), plus dark and Arabic.
// Skipped unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/wordtiles flutter test test/screenshots/wordtiles_shots_test.dart
import 'dart:async';
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
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/ui/games/wordtiles/word_list_loader.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_options.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/menu_screen.dart' show MenuScreen, menuShowsDebugConsole;
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

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

Future<GameController> _pump(WidgetTester tester, Size size,
    {Locale locale = const Locale('de'),
    Brightness brightness = Brightness.light,
    GameConfig config = const GameConfig('wordtiles', seed: 1),
    bool appFonts = false,
    List<List<String>> racks = const [
      ['H', 'A', 'U', 'S', 'E', 'N', '?'],
      ['T', 'E', 'R', 'N', 'O', 'D', 'I'],
    ]}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  (c.game as WordTilesGame).debugSetup(
    racks: racks,
    bag: [...List.filled(30, 'E'), 'L', 'K', 'M', 'A', 'I', 'R', 'B', 'Ü'],
  );
  await _pumpScreen(tester, locale: locale, brightness: brightness, appFonts: appFonts, child: buildGameScreen(c));
  return c;
}

Future<void> _pumpScreen(WidgetTester tester,
    {Locale locale = const Locale('de'),
    Brightness brightness = Brightness.light,
    bool appFonts = false,
    required Widget child}) async {
  final theme = brightness == Brightness.dark ? KlunkiTheme.dark : KlunkiTheme.light;
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      // The bundled fonts (Arabic glyphs) as on the web.
      theme: appFonts ? withAppFonts(theme, web: true) : theme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: PlayerLabelsScope(
        labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}),
        child: child,
      ),
    ),
  ));
  await tester.pump();
  await tester.pump();
}

Future<void> _submit(WidgetTester tester, GameController c, List<(int, int, String, String?)> tiles) async {
  final r = await c.submit(WordTilesGame.placeMove([for (final (r, col, t, l) in tiles) PlacedTile(r, col, t, l)]));
  expect(r.isAccepted, isTrue, reason: '$tiles');
  await tester.pump();
  await tester.pump();
  if (find.byKey(const Key('handover-continue')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('handover-continue')));
    await tester.pump();
  }
}

/// HAUS (Anna), STERN (Ben), BIRNE with a blank I (Anna, still open).
Future<void> _midGame(WidgetTester tester, GameController c) async {
  await _submit(tester, c, [(7, 5, 'H', null), (7, 6, 'A', null), (7, 7, 'U', null), (7, 8, 'S', null)]);
  await _submit(tester, c, [(8, 8, 'T', null), (9, 8, 'E', null), (10, 8, 'R', null), (11, 8, 'N', null)]);
  await _submit(tester, c, [(11, 5, 'B', null), (11, 6, '?', 'I'), (11, 7, 'R', null), (11, 9, 'E', null)]);
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pump();
  await tester.pump();
}

int _rackIndex(GameController c, String tile) => (c.game as WordTilesGame).rackOf((c.game as WordTilesGame).currentSeat).indexOf(tile);

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  // The one-time bench explanation is seen, except in kld094-bench.
  setUp(() {
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
  });

  const phone = Size(390, 844);
  const padLandscape = Size(1180, 820);
  const padPortrait = Size(820, 1180);

  for (final (name, size) in [('iphone', phone), ('ipad-landscape', padLandscape), ('ipad-portrait', padPortrait)]) {
    testWidgets(name, skip: skip, (tester) async {
      final c = await _pump(tester, size);
      await _shot(tester, '$name-1-start');

      // Anna lays HAUS by taps; the preview shows the score.
      for (final (t, col) in [('H', 5), ('A', 6), ('U', 7), ('S', 8)]) {
        await _tap(tester, find.byKey(Key('wordtiles-rack-${_rackIndex(c, t)}')));
        await tester.ensureVisible(find.byKey(Key('wordtiles-sq-7-$col')));
        await _tap(tester, find.byKey(Key('wordtiles-sq-7-$col')));
        await tester.pumpAndSettle();
      }
      await _shot(tester, '$name-2-laid-preview');
      await _tap(tester, find.byKey(const Key('wordtiles-recall')));
      await tester.pumpAndSettle();
      // Anna: the blank picker.
      await _tap(tester, find.byKey(Key('wordtiles-rack-${_rackIndex(c, '?')}')));
      await tester.ensureVisible(find.byKey(const Key('wordtiles-sq-7-7')));
      await _tap(tester, find.byKey(const Key('wordtiles-sq-7-7')));
      await tester.pumpAndSettle();
      await _shot(tester, '$name-6-blank-picker');
      await _tap(tester, find.byKey(const Key('wordtiles-blank-cancel')));
      await tester.pumpAndSettle();

      await _midGame(tester, c);
      await _shot(tester, '$name-3-mid-challenge');

      // Ben accepts and lays LOB down to the B.
      await _tap(tester, find.byKey(const Key('wordtiles-accept')));
      for (final (t, r) in [('L', 9), ('O', 10)]) {
        await _tap(tester, find.byKey(Key('wordtiles-rack-${_rackIndex(c, t)}')));
        await tester.ensureVisible(find.byKey(Key('wordtiles-sq-$r-5')));
        await _tap(tester, find.byKey(Key('wordtiles-sq-$r-5')));
        await tester.pumpAndSettle();
      }
      await _shot(tester, '$name-4-mid-preview');
      await _tap(tester, find.byKey(const Key('wordtiles-play')));
      await tester.pumpAndSettle();
      await _shot(tester, '$name-5-handover');
      await _tap(tester, find.byKey(const Key('handover-continue')));
      await tester.pumpAndSettle();


      // Six passes end the game.
      for (var i = 0; i < 6; i++) {
        await _tap(tester, find.byKey(const Key('wordtiles-pass')));
        await _tap(tester, find.byKey(const Key('wordtiles-pass-confirm')));
        await tester.pumpAndSettle();
        if (find.byKey(const Key('handover-continue')).evaluate().isNotEmpty) {
          await _tap(tester, find.byKey(const Key('handover-continue')));
          await tester.pumpAndSettle();
        }
      }
      expect(find.byKey(const Key('result-dialog')), findsOneWidget);
      await _shot(tester, '$name-7-end');
    });
  }

  testWidgets('iphone dark and Arabic', skip: skip, (tester) async {
    var c = await _pump(tester, phone, brightness: Brightness.dark);
    await _midGame(tester, c);
    await _shot(tester, 'iphone-dark-mid');
    c = await _pump(tester, phone, locale: const Locale('ar'));
    await _midGame(tester, c);
    await _shot(tester, 'iphone-ar-mid');
  });

  // KLD-094 step 4: the bench, the check at "Legen" with the real German
  // word list, and the start options (`--plain-name kld094-step4`).
  group('kld094-step4', () {
    const sizes = [
      ('iphone-se', Size(375, 667)),
      ('iphone-max', Size(430, 932)),
      ('ipad-portrait', Size(820, 1180)),
      ('ipad-landscape', Size(1180, 820)),
    ];
    const dict = GameConfig('wordtiles', seed: 1, dictionary: true);
    const anna = ['B', 'A', 'U', 'M', 'E', 'N', '?'];

    for (final (name, size) in sizes) {
      testWidgets('bench $name', skip: skip, (tester) async {
        await tester.runAsync(() => WordListLoader.ensure('de'));
        final c = await _pump(tester, size, config: dict, racks: const [anna, ['T', 'E', 'R', 'N', 'O', 'D', 'I']]);
        // Open the bench where it starts collapsed (small phones).
        if (find.byKey(const Key('wordtiles-bench-0-0')).evaluate().isEmpty) {
          await _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));
        }
        await _shot(tester, 'bench-$name-0-empty');
        // BAUM in row 0, NE in row 1 (tap a tile, then a slot).
        for (final (t, r, s) in [('B', 0, 1), ('A', 0, 2), ('U', 0, 3), ('M', 0, 4), ('N', 1, 2), ('E', 1, 3)]) {
          await _tap(tester, find.byKey(Key('wordtiles-rack-${_rackIndex(c, t)}')));
          await _tap(tester, find.byKey(Key('wordtiles-bench-$r-$s')));
        }
        await tester.pumpAndSettle();
        await _shot(tester, 'bench-$name-1-word-score');
        // BAUN on the board (from the bench), "Legen": not in the list.
        for (final (t, col) in [('U', 7), ('A', 6), ('B', 5), ('N', 8)]) {
          await _tap(tester, find.byKey(Key('wordtiles-rack-${_rackIndex(c, t)}')));
          await tester.ensureVisible(find.byKey(Key('wordtiles-sq-7-$col')));
          await _tap(tester, find.byKey(Key('wordtiles-sq-7-$col')));
          await tester.pumpAndSettle();
        }
        await _shot(tester, 'bench-$name-2-laid-preview');
        await _tap(tester, find.byKey(const Key('wordtiles-play')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('wordtiles-unknown')), findsOneWidget);
        await _shot(tester, 'bench-$name-3-unknown-word');
        await _tap(tester, find.byKey(const Key('wordtiles-unknown-allow')));
        await tester.pumpAndSettle();
        await _shot(tester, 'bench-$name-4-allowed-cover');
        await _tap(tester, find.byKey(const Key('handover-continue')));
        await tester.pumpAndSettle();
        await _tap(tester, find.byKey(const Key('shell-history')));
        await tester.pumpAndSettle();
        await _shot(tester, 'bench-$name-5-history');
      });
    }

    for (final (lang, locale) in [('de', Locale('de')), ('en', Locale('en'))]) {
      testWidgets('start options $lang', skip: skip, (tester) async {
        tester.view.physicalSize = const Size(375, 667) * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await _pumpScreen(tester, locale: locale, child: const Scaffold(body: SizedBox.expand()));
        showWordTilesOptionsDialog(tester.element(find.byType(Scaffold)));
        await tester.pumpAndSettle();
        await _shot(tester, 'options-$lang-1-default');
        await _tap(tester, find.byKey(const Key('wordtiles-dict')));
        await tester.pumpAndSettle();
        await _shot(tester, 'options-$lang-2-no-dictionary');
      });
    }
  });

  // KLD-094 step 8 (playtest): the bench below the actions, closed by
  // default (rack and actions right under the board); its one-time
  // explanation; tiles on the open bench leave gaps in the rack and come
  // back when it closes. Small and large phone in German, a phone in Arabic
  // (`--plain-name kld094-bench`).
  group('kld094-bench', () {
    const anna = ['B', 'A', 'U', 'M', 'E', 'N', '?'];
    for (final (name, size, locale) in [
      ('de-iphone-se', Size(375, 667), Locale('de')),
      ('de-iphone-max', Size(430, 932), Locale('de')),
      ('ar-iphone', Size(390, 844), Locale('ar')),
    ]) {
      testWidgets('layout $name', skip: skip, (tester) async {
        SeenTips.debugReset(); // a fresh install: the explanation shows
        final c = await _pump(tester, size, locale: locale, appFonts: true, racks: const [anna, ['T', 'E', 'R', 'N', 'O', 'D', 'I']]);
        await _shot(tester, 'kld094-bench/$name-1-start');
        await _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));
        await tester.pumpAndSettle();
        for (var step = 1; step <= 3; step++) {
          expect(find.byKey(Key('wordtiles-coach-step-$step')), findsOneWidget);
          await _shot(tester, 'kld094-bench/$name-2-coach-$step');
          await _tap(tester, find.byKey(Key(step < 3 ? 'wordtiles-coach-next' : 'wordtiles-coach-done')));
          await tester.pumpAndSettle();
        }
        await _shot(tester, 'kld094-bench/$name-3-bench-open');
        for (final (t, s) in [('B', 1), ('A', 2), ('U', 3), ('M', 4)]) {
          await tester.ensureVisible(find.byKey(Key('wordtiles-rack-${_rackIndex(c, t)}')));
          await _tap(tester, find.byKey(Key('wordtiles-rack-${_rackIndex(c, t)}')));
          await tester.ensureVisible(find.byKey(Key('wordtiles-bench-0-$s')));
          await _tap(tester, find.byKey(Key('wordtiles-bench-0-$s')));
        }
        await tester.pumpAndSettle();
        await _shot(tester, 'kld094-bench/$name-4-bench-tiles-gaps');
        await tester.ensureVisible(find.byKey(const Key('wordtiles-bench-toggle')));
        await _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));
        await tester.pumpAndSettle();
        await _shot(tester, 'kld094-bench/$name-5-bench-closed-full-rack');
      });
    }
  });

  // KLD-094 step 8b (layout): board right under the score row, rack and
  // actions right under the board, the open bench below them, the space
  // left over at the bottom; bench closed and open with tiles. Phones,
  // tablet portrait and landscape in German (`--plain-name kld094-layout`).
  group('kld094-layout', () {
    const anna = ['B', 'A', 'U', 'M', 'E', 'N', '?'];
    for (final (name, size) in [
      ('de-iphone-se', Size(375, 667)),
      ('de-iphone', Size(390, 844)),
      ('de-iphone-max', Size(430, 932)),
      ('de-ipad-portrait', Size(820, 1180)),
      ('de-ipad-landscape', Size(1180, 820)),
    ]) {
      testWidgets('layout $name', skip: skip, (tester) async {
        final c = await _pump(tester, size, appFonts: true, racks: const [anna, ['T', 'E', 'R', 'N', 'O', 'D', 'I']]);
        await _shot(tester, 'kld094-layout/$name-1-bench-closed');
        await _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));
        await tester.pumpAndSettle();
        for (final (t, s) in [('B', 1), ('A', 2), ('U', 3), ('M', 4)]) {
          await _tap(tester, find.byKey(Key('wordtiles-rack-${_rackIndex(c, t)}')));
          await tester.ensureVisible(find.byKey(Key('wordtiles-bench-0-$s')));
          await _tap(tester, find.byKey(Key('wordtiles-bench-0-$s')));
        }
        await tester.pumpAndSettle();
        await _shot(tester, 'kld094-layout/$name-2-bench-open');
      });
    }
  });

  // KLD-094 step 5 (hot-seat polish): score bar without names, the blank's
  // "0", the bench over the board on small phones, the pass confirmation,
  // "So geht's" and the result summary (`--plain-name kld094-step5`).
  group('kld094-step5', () {
    const sizes = [
      ('iphone-se', Size(375, 667)),
      ('iphone-se-landscape', Size(667, 375)),
      ('iphone', Size(390, 844)),
      ('ipad-landscape', Size(1180, 820)),
    ];
    const dict = GameConfig('wordtiles', seed: 1, dictionary: true);
    const anna = ['B', 'A', 'U', 'M', 'E', 'N', '?'];

    for (final (name, size) in sizes) {
      testWidgets('polish $name', skip: skip, (tester) async {
        await tester.runAsync(() => WordListLoader.ensure('de'));
        final c = await _pump(tester, size, config: dict, racks: const [anna, ['T', 'E', 'R', 'N', 'O', 'D', 'I']]);
        await _shot(tester, 'polish-$name-1-start');
        if (find.byKey(const Key('wordtiles-bench-0-0')).evaluate().isEmpty) {
          await _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));
          await tester.pumpAndSettle();
        }
        for (final (t, r, s) in [('B', 0, 1), ('A', 0, 2), ('U', 0, 3), ('M', 0, 4)]) {
          await tester.ensureVisible(find.byKey(Key('wordtiles-rack-${_rackIndex(c, t)}')));
          await _tap(tester, find.byKey(Key('wordtiles-rack-${_rackIndex(c, t)}')));
          await tester.ensureVisible(find.byKey(Key('wordtiles-bench-$r-$s')));
          await _tap(tester, find.byKey(Key('wordtiles-bench-$r-$s')));
        }
        await tester.pumpAndSettle();
        await _shot(tester, 'polish-$name-2-bench-open');
        // Lay U A M from the bench with the bench still open (squares under
        // the overlay are not reachable: lay where the board shows).
        for (final (t, col) in [('U', 7), ('A', 6), ('B', 5), ('M', 8)]) {
          await _tap(tester, find.byKey(Key('wordtiles-rack-${_rackIndex(c, t)}')));
          await tester.ensureVisible(find.byKey(Key('wordtiles-sq-7-$col')));
          await _tap(tester, find.byKey(Key('wordtiles-sq-7-$col')));
          await tester.pumpAndSettle();
        }
        await _shot(tester, 'polish-$name-3-laid-bench-open');
        await _tap(tester, find.byKey(const Key('wordtiles-bench-toggle')));
        await tester.pumpAndSettle();
        await _shot(tester, 'polish-$name-4-laid-bench-closed');
        await _tap(tester, find.byKey(const Key('wordtiles-recall')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('wordtiles-pass')));
        await _tap(tester, find.byKey(const Key('wordtiles-pass')));
        await tester.pumpAndSettle();
        await _shot(tester, 'polish-$name-5-pass-confirm');
        await _tap(tester, find.byKey(const Key('wordtiles-pass-cancel')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('wordtiles-help')));
        await _tap(tester, find.byKey(const Key('wordtiles-help')));
        await tester.pumpAndSettle();
        await _shot(tester, 'polish-$name-6-help');
        await tester.drag(find.byKey(const Key('wordtiles-help-sheet')), const Offset(0, -600));
        await tester.pumpAndSettle();
        await _shot(tester, 'polish-$name-7-help-scrolled');
      });
    }

    testWidgets('dictionary loading dialog', skip: skip, (tester) async {
      tester.view.physicalSize = const Size(375, 667) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      // A bundle that never answers: the dialog stays for the shot.
      WordListLoader.bundle = _NeverBundle();
      addTearDown(() {
        WordListLoader.bundle = null;
        WordListLoader.reset();
      });
      WordListLoader.reset();
      await _pumpScreen(tester, child: const Scaffold(body: SizedBox.expand()));
      unawaited(loadWordListWithProgress(tester.element(find.byType(Scaffold)), 'de'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('wordtiles-dict-loading')), findsOneWidget);
      await _shot(tester, 'polish-dictionary-loading');
    });

    for (final (name, size, locale) in [
      ('iphone-se', const Size(375, 667), const Locale('de')),
      ('iphone-se-en', const Size(375, 667), const Locale('en')),
      ('ipad-landscape', const Size(1180, 820), const Locale('de')),
    ]) {
      testWidgets('result $name', skip: skip, (tester) async {
        await tester.runAsync(() => WordListLoader.ensure('de'));
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final c = GameController.hotSeat(dict);
        addTearDown(c.dispose);
        (c.game as WordTilesGame).debugSetup(racks: const [
          ['H', 'A', 'U', 'S', 'Y'],
          ['I'],
        ], bag: const []);
        await _pumpScreen(tester, locale: locale, child: buildGameScreen(c));
        await _submit(tester, c, [(7, 4, 'H', null), (7, 5, 'A', null), (7, 6, 'U', null), (7, 7, 'S', null)]);
        // Ben's I makes HAUSI: not in the list, both allow it; Ben is out.
        final r = await c.submit(WordTilesGame.placeMove([const PlacedTile(7, 8, 'I')], allow: const ['HAUSI']));
        expect(r.isAccepted, isTrue);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('result-dialog')), findsOneWidget);
        expect(find.byKey(const Key('wordtiles-result-allowed')), findsOneWidget);
        await _shot(tester, 'polish-result-$name');
      });
    }
  });

  // KLD-094 step 7 (release): the menu with the Wortgewandt tile, as in a
  // release build, on a small and a large phone, German light and dark and
  // Arabic (RTL) (`--plain-name kld094release`).
  group('kld094release', () {
    for (final (device, size) in [('small-phone', Size(375, 667)), ('large-phone', Size(430, 932))]) {
      for (final (tag, locale, brightness) in [
        ('de-light', Locale('de'), Brightness.light),
        ('de-dark', Locale('de'), Brightness.dark),
        ('ar-light', Locale('ar'), Brightness.light),
      ]) {
        testWidgets('menu $device $tag', skip: skip, (tester) async {
          tester.view.physicalSize = size * 2;
          tester.view.devicePixelRatio = 2;
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
          menuShowsDebugConsole = false;
          addTearDown(() => menuShowsDebugConsole = true);
          debugDisableShadows = false; // real tile shadows, not the test outlines
          // The app's menu with the bundled fonts as on the web: the test
          // has no platform font cascade for Arabic (KLD-093).
          await tester.pumpWidget(RepaintBoundary(
            key: _boundary,
            child: PlayerNameScope(
              controller: PlayerNameController.memory(),
              hotSeat: HotSeatNamesController.memory(),
              child: LocaleScope(
                controller: LocaleController.memory(locale),
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: withAppFonts(KlunkiTheme.light, web: true),
                  darkTheme: withAppFonts(KlunkiTheme.dark, web: true),
                  locale: locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: const MenuScreen(),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const Key('menu-wordtiles')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('menu-wordtiles-local')), findsOneWidget);
          expect(find.byKey(const Key('menu-wordtiles-network')), findsOneWidget);
          await _shot(tester, 'kld094release/menu-$device-$tag');
        });
      }
    }
  });
}

class _NeverBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Completer<ByteData>().future;
}
