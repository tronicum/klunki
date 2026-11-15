// KLD-128 screenshots of the animal deck "Tiere": the deck picker with five
// decks, the card gallery (decks and the animal sets), a full card, a Trumpf
// comparison, and a card in en and ar (translated animal names), with the
// Commons photos. Skipped unless
// KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/tiere flutter test test/screenshots/quartett_animals_shots_test.dart
import 'dart:io';
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
import 'package:klunki/profile/quartett_deck_settings.dart';
import 'package:klunki/ui/games/quartett_gallery.dart';
import 'package:klunki/ui/shell/game_screen.dart' show PlayerLabels, PlayerLabelsScope;
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

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
  for (final f in chineseFontFamilies) {
    await family(f, ['assets/fonts/NotoSansSC/$f-Regular.ttf', 'assets/fonts/NotoSansSC/$f-Bold.ttf']);
  }
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
    final f = File('$_out/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// [home] in a themed app with the bundled fonts, in [locale].
Widget _themed(Widget home, Locale locale) => RepaintBoundary(
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
        home: home,
      ),
    );

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  testWidgets('kld128 picker', skip: skip, (tester) async {
    SharedPreferences.setMockInitialValues({QuartettDeckSettings.prefsKey: 'animals'});
    _size(tester, const Size(390, 844));
    await tester.pumpWidget(RepaintBoundary(
        key: _boundary, child: KlunkiApp(localeController: LocaleController.memory(const Locale('de')))));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('menu-quartett-trumpf-local')));
    await _shot(tester, 'kld128-1-picker-de');
  });

  testWidgets('kld128 picker 360x640', skip: skip, (tester) async {
    SharedPreferences.setMockInitialValues({QuartettDeckSettings.prefsKey: 'animals'});
    _size(tester, const Size(360, 640));
    await tester.pumpWidget(RepaintBoundary(
        key: _boundary, child: KlunkiApp(localeController: LocaleController.memory(const Locale('fr')))));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('menu-quartett-trumpf-local')));
    await _shot(tester, 'kld128-1-picker-fr-360x640');
  });

  for (final l in ['de', 'en', 'ar']) {
    testWidgets('kld128 gallery $l', skip: skip, (tester) async {
      _size(tester, const Size(390, 844));
      await tester.pumpWidget(_themed(const QuartettGalleryScreen(), Locale(l)));
      await tester.pumpAndSettle();
      if (l == 'de') await _shot(tester, 'kld128-2-gallery-decks-de');
      await _tap(tester, find.byKey(const Key('gallery-deck-animals')));
      await _shot(tester, 'kld128-3-gallery-sets-$l');
      await tester.scrollUntilVisible(find.byKey(const Key('gallery-set-H')), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await _shot(tester, 'kld128-3-gallery-sets-end-$l');
    });
  }

  for (final (l, id) in [('de', 'D1'), ('de', 'H3'), ('en', 'D1'), ('ar', 'D1'), ('en', 'H4'), ('ar', 'H4')]) {
    testWidgets('kld128 card $id $l', skip: skip, (tester) async {
      _size(tester, const Size(390, 844));
      final deck = QuartettDeck.animals;
      final index = deck.cards.indexWhere((c) => c.id == id);
      await tester.pumpWidget(_themed(QuartettCardPagerScreen(deck: deck, initialIndex: index), Locale(l)));
      await tester.pumpAndSettle();
      await _shot(tester, 'kld128-4-card-$id-$l');
    });
  }

  for (final (l, size, tag) in [
    ('de', const Size(390, 844), 'phone'),
    ('en', const Size(390, 844), 'phone'),
    ('ar', const Size(390, 844), 'phone'),
    ('de', const Size(320, 640), '320'),
  ]) {
    testWidgets('kld128 trumpf $l $tag', skip: skip, (tester) async {
      _size(tester, size);
      final c = GameController.hotSeat(const GameConfig('quartett-trumpf', seed: 3, deck: 'animals'));
      addTearDown(c.dispose);
      await tester.pumpWidget(_themed(
          PlayerLabelsScope(
            labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}),
            child: buildGameScreen(c),
          ),
          Locale(l)));
      await tester.pumpAndSettle();
      await _shot(tester, 'kld128-5-trumpf-table-$l-$tag');
      // The last stat, "Tragzeit / Brutzeit": the longest label.
      final stat = (c.game as QuartettGame).deck.stats.last.id;
      await _tap(tester, find.byKey(Key('qt-stat-$stat')));
      await _shot(tester, 'kld128-6-trumpf-compare-$l-$tag');
    });
  }

  testWidgets('kld128 sets de', skip: skip, (tester) async {
    _size(tester, const Size(390, 844));
    final c = GameController.hotSeat(const GameConfig('quartett-sets', seed: 3, deck: 'animals'));
    addTearDown(c.dispose);
    await tester.pumpWidget(_themed(
        PlayerLabelsScope(
          labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}),
          child: buildGameScreen(c),
        ),
        const Locale('de')));
    await tester.pumpAndSettle();
    await _shot(tester, 'kld128-7-sets-de');
  });
}
