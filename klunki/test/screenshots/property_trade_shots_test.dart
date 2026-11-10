// KLD-060 step 3b screenshots of trades in Baulöwe: the trade sheet (with
// a street that cannot be traded), an offer that is not valid yet, the
// handover to the partner, the partner's answer and the handover back; de
// phone light, iPad, ar on a small phone (RTL). Skipped unless
// KLUNKI_SHOTS=<output dir> is set; into <KLUNKI_SHOTS>/trade:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/property_trade_shots_test.dart
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
import 'package:klunki/profile/beginner_settings.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

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
    final f = File('$_out/trade/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

const _names = {
  'de': ['Anna', 'Ben', 'Cleo', 'Dani'],
  'ar': ['سارة', 'عمر', 'ليلى', 'يوسف'],
};

/// A game in the middle: Anna owns one street of the cheapest group and a
/// station, Ben the other street of that group, a whole group with
/// buildings (not tradable) and a utility.
Future<GameController> _game(WidgetTester tester, {required String lang, required Size size, EdgeInsets safe = EdgeInsets.zero}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  final pad = FakeViewPadding(left: safe.left * 2, top: safe.top * 2, right: safe.right * 2, bottom: safe.bottom * 2);
  tester.view.padding = pad;
  tester.view.viewPadding = pad;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(const GameConfig('property', seed: 4, players: 3));
  addTearDown(c.dispose);
  final g = c.game as PropertyGame;
  g
    ..debugSetSquare(1, 0)
    ..debugSetSquare(5, 0)
    ..debugSetSquare(11, 0, mortgaged: true)
    ..debugSetSquare(3, 1)
    ..debugSetSquare(6, 1, houses: 2)
    ..debugSetSquare(8, 1, houses: 2)
    ..debugSetSquare(9, 1, houses: 1)
    ..debugSetSquare(12, 1)
    ..debugSetSquare(16, 2)
    ..debugSetCash(0, 1240)
    ..debugSetCash(1, 870);
  final names = _names[lang]!;
  ExtraSeatNames.debugReset();
  await ExtraSeatNames.shared().set(third: names[2], fourth: names[3], players: 4);
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: PlayerNameScope(
      controller: PlayerNameController.memory(),
      hotSeat: HotSeatNamesController.memory(HotSeatNames(x: names[0], o: names[1])),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: withAppFonts(KlunkiTheme.light, web: true),
        locale: Locale(lang),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: buildGameScreen(c),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BeginnerSettings.debugReset();
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.propertyIntro);
    ExtraSeatNames.debugReset();
  });

  for (final (dev, lang, size, safe) in [
    ('phone', 'de', const Size(390, 844), const EdgeInsets.only(top: 47, bottom: 34)),
    ('ipad', 'de', const Size(820, 1180), const EdgeInsets.only(top: 24, bottom: 20)),
    ('se', 'ar', const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    testWidgets('trade $dev $lang', skip: skip, (tester) async {
      final name = '$dev-$lang';
      await _game(tester, lang: lang, size: size, safe: safe);
      await _tap(tester, 'property-trade');
      // Not valid yet: no partner, nothing chosen.
      await _shot(tester, '$name-01-sheet-empty');
      await _tap(tester, 'property-trade-partner-1');
      await _shot(tester, '$name-02-invalid-empty-offer');
      await _tap(tester, 'property-trade-give-5');
      await _tap(tester, 'property-trade-give-money-plus-100');
      await _tap(tester, 'property-trade-give-money-plus-50');
      await _tap(tester, 'property-trade-get-3');
      await _shot(tester, '$name-03-sheet-offer');
      await tester.drag(find.byKey(const Key('property-trade-get')), const Offset(0, -400));
      await tester.pumpAndSettle();
      await _shot(tester, '$name-04-sheet-scrolled');
      await _tap(tester, 'property-trade-offer');
      await _shot(tester, '$name-05-handover');
      await _tap(tester, 'property-trade-handover');
      await tester.ensureVisible(find.byKey(const Key('property-trade-accept')));
      await tester.pumpAndSettle();
      await _shot(tester, '$name-06-answer');
      await _tap(tester, 'property-trade-accept');
      await _shot(tester, '$name-07-back');
      await _tap(tester, 'property-trade-back');
      await _shot(tester, '$name-08-after');
    });
  }
}
