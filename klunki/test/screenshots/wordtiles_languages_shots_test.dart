// KLD-132 screenshots: the tile language picker (French, Arabic and Persian
// app language; Arabic and Persian with the reading-direction line) and a
// board in each new tile language (French, Spanish, Arabic, Persian) on a
// phone, with the language's word list; Arabic also dark.
// Skipped unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/wordtiles_languages_shots_test.dart
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
import 'package:klunki/ui/games/wordtiles/word_list_loader.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_options.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../support/asset_images.dart';

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
  await precacheShownImages(tester);
  debugDisableShadows = false;
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/kld132/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

Future<void> _pumpScreen(WidgetTester tester,
    {required Locale locale, Brightness brightness = Brightness.light, required Widget child}) async {
  final theme = brightness == Brightness.dark ? KlunkiTheme.dark : KlunkiTheme.light;
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      // The bundled fonts (Arabic and Persian glyphs) as on the web.
      theme: withAppFonts(theme, web: true),
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

/// One game per language: Anna's word across over the centre, Ben's word
/// down from one of its letters (both in the word list), then Anna to move.
/// Ar/fa: the word across starts in its rightmost square.
typedef _Lang = ({
  String id,
  Locale locale,
  List<String> anna,
  List<String> ben,
  List<(int, int, String)> first,
  List<(int, int, String)> second,
});

const List<_Lang> _langs = [
  (
    id: 'fr',
    locale: Locale('fr'),
    anna: ['M', 'A', 'I', 'S', 'O', 'N', 'E'],
    ben: ['O', 'T', 'E', 'R', 'U', 'L', 'C'],
    // MAISON, then NOTER down from its N.
    first: [(7, 3, 'M'), (7, 4, 'A'), (7, 5, 'I'), (7, 6, 'S'), (7, 7, 'O'), (7, 8, 'N')],
    second: [(8, 8, 'O'), (9, 8, 'T'), (10, 8, 'E'), (11, 8, 'R')],
  ),
  (
    id: 'es',
    locale: Locale('es'),
    anna: ['C', 'A', 'S', 'A', 'R', 'O', 'L'],
    ben: ['Ñ', 'O', 'L', 'E', 'T', 'I', 'S'],
    // CASA, then AÑO down from its last A.
    first: [(7, 5, 'C'), (7, 6, 'A'), (7, 7, 'S'), (7, 8, 'A')],
    second: [(8, 8, 'Ñ'), (9, 8, 'O')],
  ),
  (
    id: 'ar',
    locale: Locale('ar'),
    anna: ['ك', 'ت', 'ا', 'ب', 'م', 'ن', 'ر'],
    ben: ['ا', 'ب', 'ل', 'م', 'س', 'ي', 'و'],
    // كتاب from the right, then باب down from its ب.
    first: [(7, 8, 'ك'), (7, 7, 'ت'), (7, 6, 'ا'), (7, 5, 'ب')],
    second: [(8, 5, 'ا'), (9, 5, 'ب')],
  ),
  (
    id: 'fa',
    locale: Locale('fa'),
    anna: ['ک', 'ت', 'ا', 'ب', 'م', 'ن', 'ر'],
    ben: ['ا', 'د', 'ل', 'م', 'س', 'ی', 'و'],
    // کتاب from the right, then باد down from its ب.
    first: [(7, 8, 'ک'), (7, 7, 'ت'), (7, 6, 'ا'), (7, 5, 'ب')],
    second: [(8, 5, 'ا'), (9, 5, 'د')],
  ),
];

Future<void> _submit(WidgetTester tester, GameController c, List<(int, int, String)> tiles) async {
  final r = await c.submit(WordTilesGame.placeMove([for (final (r, col, t) in tiles) PlacedTile(r, col, t, null)]));
  expect(r.isAccepted, isTrue, reason: '$tiles: ${r.reason}');
  await tester.pumpAndSettle();
  if (find.byKey(const Key('handover-continue')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('handover-continue')));
    await tester.pumpAndSettle();
  }
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });
  setUp(() {
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
  });

  group('kld132', () {
    for (final (lang, scroll) in [('fr', false), ('ar', false), ('fa', false), ('en', true)]) {
      testWidgets('picker $lang', skip: skip, (tester) async {
        tester.view.physicalSize = const Size(390, 844) * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await _pumpScreen(tester, locale: Locale(lang), child: const Scaffold(body: SizedBox.expand()));
        showWordTilesOptionsDialog(tester.element(find.byType(Scaffold)));
        await tester.pumpAndSettle();
        if (scroll) {
          // English app language, Persian tiles chosen: the reading line.
          await tester.tap(find.byKey(const Key('wordtiles-tiles-fa')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('wordtiles-tiles-rtl')), findsOneWidget);
        }
        await _shot(tester, 'picker-$lang${scroll ? '-fa-tiles' : ''}');
      });
    }

    for (final l in _langs) {
      for (final dark in l.id == 'ar' ? [false, true] : [false]) {
        testWidgets('board ${l.id}${dark ? ' dark' : ''}', skip: skip, (tester) async {
          await tester.runAsync(() => WordListLoader.ensure(l.id));
          tester.view.physicalSize = const Size(390, 844) * 2;
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.reset);
          final c = GameController.hotSeat(GameConfig('wordtiles', seed: 1, tiles: l.id, dictionary: true));
          addTearDown(c.dispose);
          (c.game as WordTilesGame).debugSetup(racks: [l.anna, l.ben], bag: [...l.anna, ...l.ben, ...l.anna]);
          await _pumpScreen(tester,
              locale: l.locale, brightness: dark ? Brightness.dark : Brightness.light, child: buildGameScreen(c));
          await _submit(tester, c, l.first);
          await _submit(tester, c, l.second);
          await _shot(tester, 'board-${l.id}${dark ? '-dark' : ''}');
        });
      }
    }
  });
}
