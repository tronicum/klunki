// KLD-108 screenshots: the web beta on GitHub Pages ("Beta" badge, greyed-out
// network entries, the "not in the browser yet" sheet, the About line) next
// to the relay-served http build where network play works.
// Skipped unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/web-beta flutter test test/screenshots/web_beta_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/app/web_channel.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/ui/menu_screen.dart';
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
  await family('NotoSansSC', ['assets/fonts/NotoSansSC/NotoSansSC-Regular.ttf']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
}

Future<void> _setup(WidgetTester tester, Size size, Brightness b) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.platformBrightnessTestValue = b;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

/// Real shadows only while capturing; the binding checks that the test
/// leaves `debugDisableShadows` as it found it.
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

/// The app's tree with the bundled fallback fonts as on the web, the menu
/// as served from [page].
Future<void> _pumpApp(WidgetTester tester, Locale locale, Uri page) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: PlayerNameScope(
        controller: PlayerNameController.memory(name: 'Anna'),
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
            home: MenuScreen(pageUrl: page, relaySettings: RelaySettings.memory()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

final _pages = Uri.parse('https://tronicum.github.io/klunki/');
final _lan = Uri.parse('http://192.168.1.20:8081/');

Future<void> _tap(WidgetTester tester, Key key) async {
  final f = find.byKey(key);
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
  setUp(() => appWebChannel = pagesBetaChannel);
  tearDown(() {
    appWebChannel = '';
    appIosBetaUrl = '';
    appAndroidUrl = '';
  });

  const web = Size(1280, 800);
  const phone = Size(390, 844);

  for (final b in Brightness.values) {
    testWidgets('pages web ${b.name}', skip: skip, (tester) async {
      await _setup(tester, web, b);
      await _pumpApp(tester, const Locale('de'), _pages);
      await _shot(tester, 'web-pages-menu-${b.name}');
      await _tap(tester, const Key('menu-room-start'));
      await _shot(tester, 'web-pages-sheet-${b.name}');
    });
  }

  testWidgets('pages web: menu scrolled to the rooms, links configured, About', skip: skip, (tester) async {
    await _setup(tester, web, Brightness.light);
    await _pumpApp(tester, const Locale('de'), _pages);
    await tester.ensureVisible(find.byKey(const Key('menu-room-join')));
    await tester.pumpAndSettle();
    await _shot(tester, 'web-pages-menu-rooms');
    appIosBetaUrl = 'https://beta.example.org/klunki';
    appAndroidUrl = 'https://example.org/klunki.apk';
    await _tap(tester, const Key('menu-room-join'));
    await _shot(tester, 'web-pages-sheet-with-links');
    Navigator.of(tester.element(find.byKey(const Key('network-unavailable-sheet')))).pop();
    await tester.pumpAndSettle();
    await _tap(tester, const Key('menu-about'));
    await _shot(tester, 'web-pages-about');
  });

  testWidgets('relay-served http build on the LAN: no badge, network play on', skip: skip, (tester) async {
    appWebChannel = '';
    await _setup(tester, web, Brightness.light);
    await _pumpApp(tester, const Locale('de'), _lan);
    await _shot(tester, 'web-lan-menu');
  });

  testWidgets('pages phone', skip: skip, (tester) async {
    await _setup(tester, phone, Brightness.light);
    await _pumpApp(tester, const Locale('de'), _pages);
    await _shot(tester, 'phone-pages-menu');
    await _tap(tester, const Key('menu-connect4-network'));
    await _shot(tester, 'phone-pages-sheet');
  });

  for (final locale in const [Locale('en'), Locale('ar'), Locale('zh'), Locale('fa')]) {
    testWidgets('pages phone ${locale.languageCode}', skip: skip, (tester) async {
      await _setup(tester, phone, Brightness.light);
      await _pumpApp(tester, locale, _pages);
      await _shot(tester, 'phone-pages-menu-${locale.languageCode}');
      appIosBetaUrl = 'https://beta.example.org/klunki';
      appAndroidUrl = 'https://example.org/klunki.apk';
      await _tap(tester, const Key('menu-room-start'));
      await _shot(tester, 'phone-pages-sheet-${locale.languageCode}');
    });
  }
}
