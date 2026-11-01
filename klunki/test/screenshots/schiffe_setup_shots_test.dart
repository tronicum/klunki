// KLD-107 screenshots of the Sink the Fleet setup: the start with the
// next-ship preview, the preview turned, the ghost (valid and invalid) while
// the finger is down, the first placed ship with its tip, a selected ship
// with the ↻ badge and the complete fleet, on a small iPhone (375×667), a
// large iPhone (430×932) and an iPad (1024×1366 portrait, 1366×1024
// landscape), plus dark and Arabic. Skipped unless KLUNKI_SHOTS=<dir> is set:
//
//   KLUNKI_SHOTS=/tmp/schiffe flutter test test/screenshots/schiffe_setup_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/fonts.dart';
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

Future<void> _shot(WidgetTester tester, String name, {Duration settle = const Duration(milliseconds: 600)}) async {
  debugDisableShadows = false;
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

Future<GameController> _pump(WidgetTester tester, Size size,
    {Locale locale = const Locale('de'), Brightness brightness = Brightness.light}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(const GameConfig('schiffe', seed: 7));
  addTearDown(c.dispose);
  final theme = brightness == Brightness.dark ? KlunkiTheme.dark : KlunkiTheme.light;
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: withAppFonts(theme, web: locale.languageCode != 'de'),
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

Finder _own(int r, int c) => find.byKey(Key('sv-own-$r-$c'));

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pump();
  await tester.pump();
}

/// The whole setup story, one shot per step, names prefixed with [tag].
Future<void> _story(WidgetTester tester, String tag, {bool all = true}) async {
  await _shot(tester, '$tag-1-start');
  await _tap(tester, find.byKey(const Key('sv-rotate')));
  await _shot(tester, '$tag-2-preview-rotated');
  await _tap(tester, _own(0, 0)); // Schlachtschiff A1–E1 (vertical)
  await _shot(tester, '$tag-3-first-placed');
  if (!all) return;
  // Kreuzer, vertical: finger down on C5 (fits), then onto B2 (touches).
  final g = await tester.startGesture(tester.getCenter(_own(2, 4)));
  await tester.pump();
  await _shot(tester, '$tag-4-ghost-valid', settle: Duration.zero);
  await g.moveTo(tester.getCenter(_own(1, 1)));
  await tester.pump();
  await _shot(tester, '$tag-5-ghost-invalid', settle: Duration.zero);
  await g.cancel();
  await tester.pump();
  await _tap(tester, _own(2, 0)); // select the Schlachtschiff
  await _shot(tester, '$tag-6-selected');
  await _tap(tester, find.byKey(const Key('sv-random')));
  await _shot(tester, '$tag-7-ready');
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  for (final (name, size) in [
    ('iphone-small', const Size(375, 667)),
    ('iphone-large', const Size(430, 932)),
    ('ipad-portrait', const Size(1024, 1366)),
    ('ipad-landscape', const Size(1366, 1024)),
  ]) {
    testWidgets(name, skip: skip, (tester) async {
      await _pump(tester, size);
      await _story(tester, name);
    });
  }

  testWidgets('iphone-small dark', skip: skip, (tester) async {
    await _pump(tester, const Size(375, 667), brightness: Brightness.dark);
    await _story(tester, 'iphone-small-dark');
  });

  testWidgets('iphone-small arabic', skip: skip, (tester) async {
    await _pump(tester, const Size(375, 667), locale: const Locale('ar'));
    await _story(tester, 'iphone-small-ar', all: false);
  });
}
