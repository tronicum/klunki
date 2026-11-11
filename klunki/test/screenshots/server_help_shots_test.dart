// KLD-113 screenshots: one "Server" setting (the server line with its kind,
// the dialog for a server im WLAN and one im Internet with a saved club
// code), the club code asked for only when the server needs it, and the help
// screen "So spielt ihr zusammen"; phone size (390×844), de and ar (RTL).
// Skipped unless KLUNKI_SHOTS=<dir> is set:
//
//   KLUNKI_SHOTS=/tmp/kld113 flutter test test/screenshots/server_help_shots_test.dart
//   (or: KLUNKI_SHOTS=/tmp/kld113 flutter test test/screenshots --plain-name kld113)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/help_screen.dart';
import 'package:klunki/ui/pairing/relay_line.dart';
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
  // Every part of the Chinese subset (NotoSansSC, NotoSansSC2, ...: tool/update_web_fonts.py).
  for (final f in chineseFontFamilies) {
    await family(f, ['assets/fonts/NotoSansSC/$f-Regular.ttf', 'assets/fonts/NotoSansSC/$f-Bold.ttf']);
  }
  // The fallback chain names NotoSansMath before the Chinese parts: unloaded,
  // the test font would draw some Chinese characters as boxes.
  await family('NotoSansMath', ['assets/fonts/NotoSansMath/NotoSansMath-Regular.ttf']);
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

final _page = Uri.parse('http://192.168.1.5:8000/');
final _lan = Uri.parse('ws://192.168.1.20:4749/relay');
final _internet = Uri.parse('wss://spiele.example/relay');

Future<NetworkTransport> _noJoin(Uri url, {required String name}) => Future.error(StateError('unused'));

Future<void> _pump(WidgetTester tester, String locale, Widget home) async {
  tester.view.physicalSize = _phone * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: withAppFonts(KlunkiTheme.light, web: true),
      locale: Locale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
}

Widget _plainPage(List<Widget> children) => Scaffold(
      appBar: AppBar(),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: children)),
    );

/// The server line on a plain page, then its dialog opened.
Future<void> _dialog(WidgetTester tester, String locale, RelaySettings settings) async {
  await _pump(tester, locale, _plainPage([RelayLine(settings: settings)]));
  await tester.tap(find.byKey(const Key('relay-change')));
  await tester.pumpAndSettle();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  final skip = _out == null ? 'set KLUNKI_SHOTS=<dir> to write screenshots' : null;
  setUpAll(() async {
    if (skip == null) await _loadFonts();
  });

  group('kld113', () {
    for (final l in ['de', 'ar']) {
      testWidgets('kld113 server line $l', skip: skip != null, (tester) async {
        await _pump(
            tester,
            l,
            _plainPage([
              RelayLine(settings: RelaySettings.memory(_lan)),
              const Divider(height: 32),
              RelayLine(settings: RelaySettings.memory(_internet)),
            ]));
        await _shot(tester, 'kld113-server-line-$l-phone');
      });

      testWidgets('kld113 dialog wlan $l', skip: skip != null, (tester) async {
        await _dialog(tester, l, RelaySettings.memory(_lan));
        await _shot(tester, 'kld113-dialog-wlan-$l-phone');
      });

      testWidgets('kld113 dialog internet with saved club code $l', skip: skip != null, (tester) async {
        final settings = RelaySettings.memory(_internet);
        await settings.setClubCode(_internet, 'K7QX-M2PA');
        await _dialog(tester, l, settings);
        await _shot(tester, 'kld113-dialog-internet-club-$l-phone');
      });

      testWidgets('kld113 club code prompt $l', skip: skip != null, (tester) async {
        final settings = RelaySettings.memory(_internet);
        await _pump(
            tester,
            l,
            WebJoinScreen(
              pageUrl: _page,
              deps: WebJoinDeps(
                joinTransport: _noJoin,
                relayJoin: (relay, code, {required name}) =>
                    Future.error(const NetException('relay: $relayClubMissingText')),
                relaySettings: () => settings,
              ),
            ));
        await tester.enterText(find.byKey(const Key('room-code')), 'K7Q2M');
        final button = find.byKey(const Key('room-join-button'));
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await tester.pump();
        await tester.pump();
        await tester.enterText(find.byKey(const Key('room-club-field')), 'K7QX-M2PA');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('room-club-retry')));
        await tester.pumpAndSettle();
        await _shot(tester, 'kld113-club-prompt-$l-phone');
      });

      testWidgets('kld113 help $l', skip: skip != null, (tester) async {
        await _pump(tester, l, const HelpScreen());
        await _shot(tester, 'kld113-help-1-$l-phone');
        final list = find.byKey(const Key('help-text'));
        await tester.dragUntilVisible(find.byKey(const Key('help-OwnServer-title')), list, const Offset(0, -200));
        await tester.pumpAndSettle();
        await _shot(tester, 'kld113-help-2-$l-phone');
        await tester.drag(list, const Offset(0, -5000));
        await tester.pumpAndSettle();
        await _shot(tester, 'kld113-help-3-$l-phone');
      });
    }
  });
}
