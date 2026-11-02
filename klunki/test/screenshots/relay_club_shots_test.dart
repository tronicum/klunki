// KLD-112 screenshots of the club code ("Clubcode") of a gated relay: the
// relay dialog with the new field, and the refusal sentences (wrong code,
// missing code) on "Raum beitreten", phone size (390×844), de and ar (RTL).
// Skipped unless KLUNKI_SHOTS=<dir> is set:
//
//   KLUNKI_SHOTS=/tmp/kld112 flutter test test/screenshots/relay_club_shots_test.dart
//   (or: KLUNKI_SHOTS=/tmp/kld112 flutter test test/screenshots --plain-name kld112)
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
import 'package:klunki/ui/pairing/web_join_screen.dart';
import 'package:klunki_net/klunki_net.dart';

import '../ui/pairing/pairing_test_utils.dart' show openAdvanced;

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
  await family('NotoSansSC', ['assets/fonts/NotoSansSC/NotoSansSC-Regular.ttf']);
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
final _relay = Uri.parse('ws://spiele.example:4749/relay');

Future<NetworkTransport> _noJoin(Uri url, {required String name}) => Future.error(StateError('unused'));

Future<void> _pump(WidgetTester tester, String locale, Object refusal, RelaySettings settings) async {
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
      home: WebJoinScreen(
        pageUrl: _page,
        deps: WebJoinDeps(
          joinTransport: _noJoin,
          relayJoin: (relay, code, {required name}) => Future.error(refusal),
          relaySettings: () => settings,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _join(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('room-code')), 'K7Q2M');
  final button = find.byKey(const Key('room-join-button'));
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
  await tester.pump();
  await tester.ensureVisible(find.byKey(const Key('room-error')));
  await tester.pumpAndSettle();
}

void main() {
  final skip = _out == null ? 'set KLUNKI_SHOTS=<dir> to write screenshots' : null;
  setUpAll(() async {
    if (skip == null) await _loadFonts();
  });

  group('kld112', () {
    for (final l in ['de', 'ar']) {
      testWidgets('kld112 dialog $l', skip: skip != null, (tester) async {
        final settings = RelaySettings.memory(_relay);
        await settings.setClubCode(_relay, 'K7QX-M2PA');
        await _pump(tester, l, const NetException('relay: club code not accepted'), settings);
        await openAdvanced(tester, 'web-join-advanced');
        final change = find.byKey(const Key('relay-change'));
        await tester.ensureVisible(change);
        await tester.pump();
        await tester.tap(change);
        await tester.pumpAndSettle();
        // No blinking cursor / keyboard focus noise in the picture.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await _shot(tester, 'kld112-dialog-$l-phone');
      });

      testWidgets('kld112 refused $l', skip: skip != null, (tester) async {
        final settings = RelaySettings.memory(_relay);
        await settings.setClubCode(_relay, 'K7QX-M2PA');
        await _pump(tester, l, const NetException('relay: club code not accepted'), settings);
        await _join(tester);
        await _shot(tester, 'kld112-refused-wrong-$l-phone');
      });

      testWidgets('kld112 missing $l', skip: skip != null, (tester) async {
        await _pump(tester, l, const NetException('relay: club code required'), RelaySettings.memory(_relay));
        await _join(tester);
        await _shot(tester, 'kld112-refused-missing-$l-phone');
      });
    }
  });
}
