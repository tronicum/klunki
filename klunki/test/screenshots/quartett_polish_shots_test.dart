// KLD-110 screenshots of the Quartett polish: thousands separators per
// locale (one card of every deck with values from 1000 on) and the Trumpf and
// Sets layouts on a phone (390×844), a large phone (430×932) and an iPad mini
// (744×1133 portrait, 1133×744 landscape), in de, en, fr and ar. Skipped
// unless KLUNKI_SHOTS=<dir> is set:
//
//   KLUNKI_SHOTS=/tmp/quartett flutter test test/screenshots/quartett_polish_shots_test.dart
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
import 'package:klunki/ui/games/quartett_media_data.dart';
import 'package:klunki/ui/shell/game_screen.dart' show PlayerLabels, PlayerLabelsScope;
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
  // Every part of the Chinese subset (NotoSansSC, NotoSansSC2, ...: tool/update_web_fonts.py).
  for (final f in chineseFontFamilies) {
    await family(f, ['assets/fonts/NotoSansSC/$f-Regular.ttf', 'assets/fonts/NotoSansSC/$f-Bold.ttf']);
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
}

const _sizes = {
  'phone': Size(390, 844),
  'phonel': Size(430, 932),
  'ipad': Size(744, 1133),
  'ipadland': Size(1133, 744),
};

Future<void> _shot(WidgetTester tester, String name) async {
  debugDisableShadows = false;
  await tester.pump(const Duration(milliseconds: 400));
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

/// A hot-seat game of [config] on screen (Anna / Ben), photos decoded.
Future<GameController> _pump(WidgetTester tester, Size size, GameConfig config, Locale locale) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: withAppFonts(KlunkiTheme.light, web: true),
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
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final deck in quartettMediaData.values) {
      for (final m in deck.values) {
        if (m.image case final img?) await precacheImage(AssetImage(img.asset), context);
      }
    }
  });
  await tester.pumpAndSettle();
  return c;
}

/// Seed 3 of every deck: a top card with values from 1000 on.
const _decks = ['cars', 'trains', 'rockets', 'planes'];

void main() {
  final skip = _out == null ? 'set KLUNKI_SHOTS=<dir> to write screenshots' : null;
  setUpAll(() async {
    if (skip == null) await _loadFonts();
  });

  group('kld110', () {
    // Thousands separators: one card per deck, every locale of the request.
    for (final l in ['de', 'en', 'fr', 'ar']) {
      for (final deck in _decks) {
        testWidgets('kld110 numbers $deck $l', skip: skip != null, (tester) async {
          await _pump(tester, _sizes['phone']!, GameConfig('quartett-trumpf', seed: 3, deck: deck), Locale(l));
          await _shot(tester, 'kld110-numbers-$deck-$l-phone');
        });
      }
    }

    // Layout: Trumpf table, Trumpf result, Sets hand per size.
    for (final MapEntry(key: tag, value: size) in _sizes.entries) {
      for (final l in tag == 'phone' || tag == 'phonel' ? ['de', 'en', 'fr', 'ar'] : ['de', 'ar']) {
        testWidgets('kld110 trumpf $tag $l', skip: skip != null, (tester) async {
          final c = await _pump(tester, size, const GameConfig('quartett-trumpf', seed: 3, deck: 'rockets'), Locale(l));
          await _shot(tester, 'kld110-trumpf-table-$tag-$l');
          final stat = (c.game as QuartettGame).deck.stats.first.id;
          await tester.ensureVisible(find.byKey(Key('qt-stat-$stat')));
          await tester.tap(find.byKey(Key('qt-stat-$stat')));
          await tester.pumpAndSettle();
          await _shot(tester, 'kld110-trumpf-result-$tag-$l');
          // Next round: "Vorige Runde" is enabled now.
          await tester.tap(find.byKey(const Key('qt-continue')));
          await tester.pumpAndSettle();
          if (c.needsHandover) {
            c.acknowledgeHandover();
            await tester.pumpAndSettle();
          }
          await _shot(tester, 'kld110-trumpf-round2-$tag-$l');
        });
        testWidgets('kld110 sets $tag $l', skip: skip != null, (tester) async {
          await _pump(tester, size, const GameConfig('quartett-sets', seed: 3, deck: 'trains'), Locale(l));
          await _shot(tester, 'kld110-sets-$tag-$l');
        });
      }
    }
  });
}
