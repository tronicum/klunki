// KLD-116 screenshots of the version: the menu footer ("Version 1.1.0
// (b8752a9)"), the About screen with the small print (build number,
// protocol, game data) and the version mismatch message that names who has
// which version. Phone size, de light (plus ar for RTL). Skipped unless
// KLUNKI_SHOTS=<dir> is set; pass a commit and build number to see CI's line:
//
//   KLUNKI_SHOTS=/tmp/kld116 flutter test test/screenshots/version_shots_test.dart \
//     --dart-define=KLUNKI_BUILD=b8752a9 --dart-define=KLUNKI_BUILD_NUMBER=2026110201
//   (or: KLUNKI_SHOTS=/tmp/kld116 flutter test test/screenshots --plain-name kld116)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/build_info.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart';
import 'package:klunki_net/klunki_net.dart';

final String? _out = Platform.environment['KLUNKI_SHOTS'];
const _boundary = Key('shot-boundary');
const _phone = Size(390, 844);

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
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
}

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

Future<NetworkTransport> _noJoin(Uri url, {required String name}) => Future.error(StateError('unused'));

/// The other device (Anna's) runs a newer build; this one is Ben's (the default guest name).
NetException _refusal() => NetException('incompatible versions …',
    mismatch: VersionMismatch(Incompatibility.rules, PeerAge.newer, 'rules',
        peerBuild: '1.1.0+2026120301 c3d4e5f', myBuild: appBuildLabel, myName: 'Ben', peerName: 'Anna'));

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (!skip) await _loadFonts();
  });

  group('kld116', () {
    for (final l in ['de', 'ar']) {
      testWidgets('kld116 menu and about $l', skip: skip, (tester) async {
        tester.view.physicalSize = _phone * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(RepaintBoundary(
            key: _boundary, child: KlunkiApp(localeController: LocaleController.memory(Locale(l)))));
        await tester.pump();
        final entry = find.byKey(const Key('menu-about'));
        await tester.scrollUntilVisible(entry, 300, scrollable: find.byType(Scrollable).first);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
        await tester.pumpAndSettle();
        await _shot(tester, 'kld116-menu-footer-$l-phone');
        await tester.tap(entry);
        await tester.pumpAndSettle();
        final icon = find.descendant(of: find.byKey(const Key('about-app-icon')), matching: find.byType(Image));
        await tester.runAsync(() => precacheImage(tester.widget<Image>(icon).image, tester.element(icon)));
        await tester.pump();
        await _shot(tester, 'kld116-about-$l-phone');
      });

      testWidgets('kld116 mismatch $l', skip: skip, (tester) async {
        tester.view.physicalSize = _phone * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(RepaintBoundary(
          key: _boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: withAppFonts(KlunkiTheme.light, web: true),
            locale: Locale(l),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: WebJoinScreen(
              pageUrl: Uri.parse('http://192.168.1.5:8000/'),
              deps: WebJoinDeps(
                joinTransport: _noJoin,
                relayJoin: (relay, code, {required name}) => Future.error(_refusal()),
                relaySettings: () => RelaySettings.memory(Uri.parse('ws://spiele.example:4749/relay')),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('room-code')), 'K7Q2M');
        final button = find.byKey(const Key('room-join-button'));
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await tester.pump();
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('room-error')));
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await _shot(tester, 'kld116-mismatch-$l-phone');
      });
    }
  });
}
