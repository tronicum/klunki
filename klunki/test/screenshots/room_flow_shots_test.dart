// KLD-098 room flow screenshots: "Mit anderen Geräten spielen" in the menu,
// "Raum starten" and "Raum beitreten" in the app and the PWA, each with its
// "Erweitert" section open. Skipped unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/room-flow flutter test test/screenshots/room_flow_shots_test.dart
//
// Tall phone frames (390 wide) so a whole screen fits in one PNG.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/net/discovery.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/net/join_payload.dart' show klunkiProtocolVersion;
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart';
import 'package:klunki_net/relay_server.dart';

import '../l10n/l10n_test_utils.dart';
import '../ui/pairing/pairing_test_utils.dart';
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
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
}

Future<void> _setup(WidgetTester tester, {double height = 1500}) async {
  tester.view.physicalSize = Size(390, height) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
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

Widget _wrap(Widget w, {Locale locale = testLocale}) => RepaintBoundary(
      key: _boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: KlunkiTheme.light,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: w,
      ),
    );

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    testWidgets('menu ${locale.languageCode}', skip: skip, (tester) async {
      await _setup(tester);
      await tester.pumpWidget(
          RepaintBoundary(key: _boundary, child: KlunkiApp(localeController: LocaleController.memory(locale))));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('menu-room-start')));
      await _shot(tester, locale.languageCode == 'de' ? '01-menu' : '11-menu-en');
    });
  }

  testWidgets('app', skip: skip, (tester) async {
    await _setup(tester);
    final created = CreatedTransports();
    final discovery = FakeDiscovery();
    final deps = testDeps(discovery: discovery, created: created, name: 'Anna');
    final names = PlayerNameController.memory(name: 'Anna');
    await tester.pumpWidget(_wrap(PairingScreen(deps: deps, nameController: names)));
    await tester.pump();
    await _shot(tester, '02-app-start');
    await tester.tap(find.byKey(const Key('pair-game-quartett-trumpf')));
    await tester.pump();
    await _shot(tester, '03-app-start-quartett-deck');
    await openAdvanced(tester, 'pair-start-advanced');
    await _shot(tester, '03b-app-start-advanced');
    await tester.tap(find.byKey(const Key('pair-via-relay')));
    await tester.pump();
    await _shot(tester, '03c-app-start-advanced-relay');
    await tester.tap(find.byKey(const Key('pair-via-relay')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pair-host-start')));
    await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty);
    await _shot(tester, '04-app-start-waiting');
    await openAdvanced(tester, 'pair-waiting-advanced');
    await _shot(tester, '04b-app-start-waiting-advanced');
    await tester.tap(find.byKey(const Key('pair-host-cancel')));
    await tester.pump();

    await tester.pumpWidget(_wrap(PairingScreen(
        key: const Key('join'), deps: deps, nameController: names, mode: RoomMode.join)));
    await tester.pump();
    discovery.addHost(const KlunkiHostInfo(
        name: 'Ben', host: '192.168.0.20', port: 4747, protocol: klunkiProtocolVersion, gameId: 'connect4'));
    await tester.pump();
    await _shot(tester, '05-app-join');
    await openAdvanced(tester, 'pair-join-advanced');
    await _shot(tester, '05b-app-join-advanced');
    await unmountAndSettleSockets(tester, created);
  });

  for (final https in [false, true]) {
    testWidgets('pwa${https ? ' https' : ''}', skip: skip, (tester) async {
      await _setup(tester, height: 1700);
      final server = (await tester.runAsync(() => Zone.root.run(
          () => RelayServer.start(port: 0, address: InternetAddress.loopbackIPv4, pingInterval: null))))!;
      final created = CreatedTransports();
      final page = Uri.parse(https ? 'https://example.org/klunki/' : 'http://192.168.1.5:${server.port}/');
      final names = PlayerNameController.memory(name: 'Ben');
      final deps = WebJoinDeps(
        joinTransport: (url, {required name}) => loopbackWebJoin(created, url, name: name),
        relayHost: (config, r, {required name}) =>
            relayHost(created, config, relayUriForPage(Uri.parse('http://127.0.0.1:${server.port}/'))!, name: name),
        seed: () => 7,
      );
      await tester.pumpWidget(_wrap(WebJoinScreen(pageUrl: page, nameController: names, deps: deps)));
      await tester.pump();
      final p = https ? '10-pwa-https' : '09-pwa';
      await _shot(tester, '$p-join');
      if (!https) {
        await openAdvanced(tester, 'web-join-advanced');
        await _shot(tester, '09b-pwa-join-advanced');
        await tester.pumpWidget(_wrap(webRoomStartScreen(pageUrl: page, deps: deps, nameController: names)));
        await tester.pump();
        await _shot(tester, '06-pwa-start');
        await tester.tap(find.byKey(const Key('relay-game-quartett-trumpf')));
        await tester.pump();
        await openAdvanced(tester, 'relay-host-advanced');
        await _shot(tester, '07-pwa-start-quartett-deck-advanced');
        await tester.ensureVisible(find.byKey(const Key('relay-host-start')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('relay-host-start')));
        await pumpUntil(tester, () => find.byKey(const Key('relay-host-waiting')).evaluate().isNotEmpty);
        await tester.pump();
        await _shot(tester, '08-pwa-start-waiting');
      }
      await unmountAndSettleSockets(tester, created);
      await tester.pump(const Duration(seconds: 6));
      await tester.runAsync(server.close);
    });
  }
}
