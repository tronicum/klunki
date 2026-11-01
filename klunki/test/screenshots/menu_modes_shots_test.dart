// KLD-105 screenshots: the play-mode links on the menu tiles ("An einem
// Gerät" -> "Ein Gerät" / "Mit anderen"), the room screen reached through "Mit anderen"
// (game preselected), and "Wer spielt?" for a hidden-information game.
// Skipped unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/menu-modes flutter test test/screenshots/menu_modes_shots_test.dart
//
// Phone frames in logical points (375×667 small iPhone, 430×932 large
// iPhone, 768×1024 iPad portrait); "-full" shots are as tall as the menu.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/ui/menu_screen.dart';

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

/// The app's tree (as `KlunkiApp`) with the bundled fallback fonts as on the
/// web, so Arabic, Persian and Chinese render here too.
Future<void> _pumpApp(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(RepaintBoundary(
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
          home: const MenuScreen(),
        ),
      ),
    ),
  ));
  await tester.pump();
}

/// Height of the whole menu (for the "-full" shots).
const double _fullHeight = 1640;

void main() {
  final skip = _out == null;
  final prefix = Platform.environment['KLUNKI_SHOTS_PREFIX'] ?? '';
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  const frames = <(String, Size)>[
    ('iphone-small', Size(375, 667)),
    ('iphone-large', Size(430, 932)),
  ];
  for (final (name, size) in frames) {
    for (final b in Brightness.values) {
      testWidgets('menu $name ${b.name}', skip: skip, (tester) async {
        await _setup(tester, size, b);
        await _pumpApp(tester, const Locale('de'));
        await _shot(tester, '$prefix$name-${b.name}');
        tester.view.physicalSize = Size(size.width, _fullHeight) * 2;
        await tester.pump();
        await _shot(tester, '$prefix$name-${b.name}-full');
      });
    }
  }

  testWidgets('menu ipad', skip: skip, (tester) async {
    await _setup(tester, const Size(768, 1024), Brightness.light);
    await _pumpApp(tester, const Locale('de'));
    await _shot(tester, '${prefix}ipad-portrait-light');
  });

  for (final locale in const [Locale('ar'), Locale('en'), Locale('fr'), Locale('es'), Locale('zh'), Locale('fa')]) {
    testWidgets('menu ${locale.languageCode}', skip: skip, (tester) async {
      await _setup(tester, const Size(375, _fullHeight), Brightness.light);
      await _pumpApp(tester, locale);
      await _shot(tester, '${prefix}iphone-small-${locale.languageCode}-full');
    });
  }

  if (prefix.isNotEmpty) return; // "before" run: the menu only

  testWidgets('room via "Mit anderen"', skip: skip, (tester) async {
    await _setup(tester, const Size(375, 900), Brightness.light);
    await _pumpApp(tester, const Locale('de'));
    for (final id in ['schiffe', 'quartett-trumpf']) {
      final link = find.byKey(Key('menu-$id-network'));
      await tester.ensureVisible(link);
      await tester.pump();
      await tester.tap(link);
      await tester.pumpAndSettle();
      await _shot(tester, 'room-with-others-$id');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('"Wer spielt?" for a hidden-information game', skip: skip, (tester) async {
    await _setup(tester, const Size(375, 667), Brightness.light);
    await _pumpApp(tester, const Locale('de'));
    final link = find.byKey(const Key('menu-schiffe-local'));
    await tester.ensureVisible(link);
    await tester.pump();
    await tester.tap(link);
    await tester.pumpAndSettle();
    await _shot(tester, 'who-plays-schiffe');
    await tester.tap(find.byKey(const Key('hot-seat-names-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-connect4-local')));
    await tester.pumpAndSettle();
    await _shot(tester, 'who-plays-connect4');
  });
}
