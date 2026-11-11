// KLD-126 screenshots of the chess clock (de, phone 390×844 and iPad
// 820×1180): the choice in "Wer spielt?" and "Raum starten", two running
// clocks, the last ten seconds (red, tenths), the pause cover and the result
// after the flag fell. The clock reads a fake time. Skipped unless
// KLUNKI_SHOTS=<dir> is set:
//
//   KLUNKI_SHOTS=/tmp/kld126 flutter test test/screenshots/chess_clock_shots_test.dart
//   (or: KLUNKI_SHOTS=/tmp/kld126 flutter test test/screenshots --plain-name kld126)
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
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/profile/chess_clock_settings.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/player_name_dialog.dart';
import 'package:klunki/ui/shell/confirm_move.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../ui/pairing/pairing_test_utils.dart';

final String? _out = Platform.environment['KLUNKI_SHOTS'];
const _boundary = Key('shot-boundary');
const _phone = Size(390, 844);
const _ipad = Size(820, 1180);

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

Future<void> _shot(WidgetTester tester, String name, {Key boundary = _boundary}) async {
  debugDisableShadows = false;
  await tester.pump(const Duration(milliseconds: 400)); // animations end (the clock's time is fake)
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(boundary));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

Widget _app(Widget home, {String locale = 'de', bool dark = false}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: withAppFonts(KlunkiTheme.light, web: true),
      darkTheme: withAppFonts(KlunkiTheme.dark, web: true),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void _phoneView(WidgetTester tester, [Size size = _phone]) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pump();
  await tester.pump();
}

const _opening = ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6'];

void main() {
  final skip = _out == null ? 'set KLUNKI_SHOTS=<dir> to write screenshots' : null;
  setUpAll(() async {
    if (skip == null) await _loadFonts();
  });
  setUp(ChessClockSettings.debugReset);

  group('kld126', () {
    for (final (tag, size) in const [('phone', _phone), ('ipad', _ipad)]) {
      testWidgets('kld126 "Wer spielt?" with the clock $tag', skip: skip != null, (tester) async {
        _phoneView(tester, size);
        await ChessClockSettings.shared().setControl(const ChessTimeControl(10 * 60000));
        await tester.pumpWidget(RepaintBoundary(
          key: _boundary,
          child: ConfirmMoveScope(
            settings: ConfirmMoveSettings.memory(),
            child: PlayerNameScope(
              controller: PlayerNameController.memory(name: 'Anna'),
              hotSeat: HotSeatNamesController.memory(),
              child: _app(Scaffold(
                body: Builder(
                  builder: (context) => Center(
                    child: FilledButton(
                      key: const Key('open'),
                      onPressed: () => showHotSeatNamesDialog(context, gameId: 'chess', start: true),
                      child: const Text('open'),
                    ),
                  ),
                ),
              )),
            ),
          ),
        ));
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();
        await _shot(tester, 'kld126-options-hot-seat-de-$tag');
      });

      testWidgets('kld126 "Raum starten" with the clock $tag', skip: skip != null, (tester) async {
        _phoneView(tester, size);
        await ChessClockSettings.shared().setControl(const ChessTimeControl(15 * 60000, 10000));
        final created = CreatedTransports();
        final deps = testDeps(discovery: FakeDiscovery(), created: created, name: 'Anna');
        await tester.pumpWidget(RepaintBoundary(
          key: _boundary,
          child: ConfirmMoveScope(
            settings: ConfirmMoveSettings.memory(),
            child: _app(
                PairingScreen(deps: deps, nameController: PlayerNameController.memory(name: 'Anna'), gameId: 'chess')),
          ),
        ));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('pair-chess-clock')));
        await tester.pump();
        await _shot(tester, 'kld126-options-room-start-de-$tag');
        await unmountAndSettleSockets(tester, created);
      });

      testWidgets('kld126 running, last ten seconds, pause, flag $tag', skip: skip != null, (tester) async {
        _phoneView(tester, size);
        var now = 0;
        final config = const GameConfig('chess', chessClock: ChessTimeControl(5 * 60000));
        final c = GameController(HotSeatTransport(config, clockNow: () => now),
            transportFactory: (cfg) => HotSeatTransport(cfg, clockNow: () => now));
        addTearDown(c.dispose);
        await tester.pumpWidget(RepaintBoundary(
          key: _boundary,
          child: ConfirmMoveScope(
            settings: ConfirmMoveSettings.memory(hotSeatA: false, hotSeatB: false),
            child: _app(buildGameScreen(c)),
          ),
        ));
        await tester.pump();
        Future<void> advance(int ms) async {
          now += ms;
          await tester.pump(Duration(milliseconds: ms));
          await tester.pump();
        }

        for (final m in _opening) {
          await advance(23000);
          await c.submit({'action': 'move', 'from': m.substring(0, 2), 'to': m.substring(2)});
          await tester.pump();
        }
        await advance(41000);
        await _shot(tester, 'kld126-running-de-$tag');
        // White thinks long: the last ten seconds.
        await advance(300000 - 3 * 23000 - 41000 - 7600);
        await _shot(tester, 'kld126-last-seconds-de-$tag');
        await _tap(tester, find.byKey(const Key('chess-pause')));
        await _shot(tester, 'kld126-pause-cover-de-$tag');
        await _tap(tester, find.byKey(const Key('chess-resume')));
        await advance(8000);
        await tester.pump(const Duration(milliseconds: 500));
        expect(c.game.result.code, GameEndReason.chessTimeout);
        await _shot(tester, 'kld126-flag-result-de-$tag');
        c.transport.dispose();
      });
    }
  });
}
