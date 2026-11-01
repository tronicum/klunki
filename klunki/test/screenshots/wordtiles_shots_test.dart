// KLD-094 step 2 screenshots of the word tile screen: start, mid-game with
// an open placement (challenge banner), tiles laid with the score preview,
// the blank letter picker and the game end, on an iPhone (390×844) and an
// iPad (1180×820 landscape, 820×1180 portrait), plus dark and Arabic.
// Skipped unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/wordtiles flutter test test/screenshots/wordtiles_shots_test.dart
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
    {Locale locale = const Locale('de'), Brightness brightness = Brightness.light}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(const GameConfig('wordtiles', seed: 1));
  addTearDown(c.dispose);
  (c.game as WordTilesGame).debugSetup(
    racks: const [
      ['H', 'A', 'U', 'S', 'E', 'N', '?'],
      ['T', 'E', 'R', 'N', 'O', 'D', 'I'],
    ],
    bag: [...List.filled(30, 'E'), 'L', 'K', 'M', 'A', 'I', 'R', 'B', 'Ü'],
  );
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? KlunkiTheme.dark : KlunkiTheme.light,
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
        child: buildGameScreen(c),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump();
  return c;
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
}
