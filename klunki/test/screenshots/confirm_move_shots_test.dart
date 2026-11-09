// KLD-122 screenshots of "Zug bestätigen" on a phone (390×844): a pending
// capture with "✗ Anders ziehen" / "✓ Ziehen" in hot-seat chess (de light, de dark,
// ar RTL), "Wer spielt?" with one switch per player, the switch on "Raum
// starten", and a network device with a pending move and the app-bar toggle.
// Skipped unless KLUNKI_SHOTS=<dir> is set:
//
//   KLUNKI_SHOTS=/tmp/kld122 flutter test test/screenshots/confirm_move_shots_test.dart
//   (or: KLUNKI_SHOTS=/tmp/kld122 flutter test test/screenshots --plain-name kld122)
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
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/chess/chess_board.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/player_name_dialog.dart';
import 'package:klunki/ui/shell/confirm_move.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../ui/pairing/pairing_test_utils.dart';

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
  await family('NotoSansMath', ['assets/fonts/NotoSansMath/NotoSansMath-Regular.ttf']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
}

Future<void> _shot(WidgetTester tester, String name, {Key boundary = _boundary}) async {
  debugDisableShadows = false;
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
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

/// Opening moves through the controller.
Future<void> _setup(WidgetTester tester, GameController c, List<String> moves) async {
  for (final m in moves) {
    await c.submit({'action': 'move', 'from': m.substring(0, 2), 'to': m.substring(2)});
  }
  await tester.pump();
  await tester.pump();
}

const _opening = ['e2e4', 'e7e5', 'g1f3', 'd7d6', 'd2d4', 'b8c6'];

void main() {
  final skip = _out == null ? 'set KLUNKI_SHOTS=<dir> to write screenshots' : null;
  setUpAll(() async {
    if (skip == null) await _loadFonts();
  });

  group('kld122', () {
    for (final (locale, dark) in const [('de', false), ('de', true), ('ar', false)]) {
      final tag = '$locale-${dark ? 'dark' : 'light'}';
      testWidgets('kld122 hot-seat pending capture $tag', skip: skip != null, (tester) async {
        _phoneView(tester);
        final c = GameController.hotSeat(const GameConfig('chess'));
        addTearDown(c.dispose);
        final names = locale == 'ar' ? const {Player.a: 'ليلى', Player.b: 'سامي'} : const {Player.a: 'Anna', Player.b: 'Ben'};
        await tester.pumpWidget(RepaintBoundary(
          key: _boundary,
          child: ConfirmMoveScope(
            settings: ConfirmMoveSettings.memory(hotSeatA: true),
            child: _app(
              PlayerLabelsScope(labels: PlayerLabels(names: names), child: buildGameScreen(c)),
              locale: locale,
              dark: dark,
            ),
          ),
        ));
        await tester.pump();
        await _setup(tester, c, _opening);
        await _tap(tester, find.byKey(const Key('chess-sq-d4')));
        await _tap(tester, find.byKey(const Key('chess-sq-e5')));
        expect(find.byKey(const Key('confirm-move-bar')), findsOneWidget);
        await _shot(tester, 'kld122-pending-$tag-phone');
      });
    }

    testWidgets('kld122 "Wer spielt?" with "Zug bestätigen" per player', skip: skip != null, (tester) async {
      _phoneView(tester);
      final confirm = ConfirmMoveSettings.memory();
      await tester.pumpWidget(RepaintBoundary(
        key: _boundary,
        child: ConfirmMoveScope(
          settings: confirm,
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
      await tester.tap(find.byKey(const Key('hot-seat-confirm-X')));
      await tester.pumpAndSettle();
      await _shot(tester, 'kld122-start-dialog-de-phone');
    });

    testWidgets('kld122 "Raum starten" with the switch', skip: skip != null, (tester) async {
      _phoneView(tester);
      final created = CreatedTransports();
      final deps = testDeps(discovery: FakeDiscovery(), created: created, name: 'Anna');
      await tester.pumpWidget(RepaintBoundary(
        key: _boundary,
        child: ConfirmMoveScope(
          settings: ConfirmMoveSettings.memory(),
          child: _app(PairingScreen(deps: deps, nameController: PlayerNameController.memory(name: 'Anna'), gameId: 'chess')),
        ),
      ));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('confirm-move-network')));
      await tester.pump();
      await _shot(tester, 'kld122-room-start-de-phone');
      await unmountAndSettleSockets(tester, created);
    });

    testWidgets('kld122 network: the guest\'s pending move, the app-bar toggle', skip: skip != null, (tester) async {
      _phoneView(tester, Size(2 * _phone.width, _phone.height));
      const hostKey = Key('device-host'), guestKey = Key('device-guest');
      final (host, guest) = (await tester.runAsync(() async {
        const ping = Duration(milliseconds: 100), timeout = Duration(seconds: 30);
        final h = await NetworkTransport.host(const GameConfig('chess'),
            name: 'Anna', address: InternetAddress.loopbackIPv4, wsPort: null, pingInterval: ping, timeout: timeout);
        final g = await NetworkTransport.join(InternetAddress.loopbackIPv4, h.port!,
            name: 'Ben', pingInterval: ping, timeout: timeout);
        return (h, g);
      }))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        guest.dispose();
        host.dispose();
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump();
        }
      });
      Finder on(Key d, Finder f) => find.descendant(of: find.byKey(d), matching: f);
      Future<void> until(bool Function() condition) async {
        for (var round = 0; round < 2000 && !condition(); round++) {
          await tester.pump();
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        }
        await tester.pump();
        await tester.pump();
      }

      Widget device(Key key, NetworkTransport t) => Expanded(
            child: RepaintBoundary(
              key: key,
              child: ConfirmMoveScope(settings: ConfirmMoveSettings.memory(), child: _app(NetworkGameSession(transport: t))),
            ),
          );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [device(hostKey, host), device(guestKey, guest)]),
      ));
      await until(() => on(guestKey, find.byType(ChessBoard)).evaluate().isNotEmpty);
      await until(() => on(hostKey, find.byType(ChessBoard)).evaluate().isNotEmpty);
      GameController ctl(Key d) => tester.widget<GameScreen>(on(d, find.byType(GameScreen))).controller;
      GameController hc() => ctl(hostKey);
      for (final (d, from, to) in [(hostKey, 'e2', 'e4'), (guestKey, 'e7', 'e5'), (hostKey, 'g1', 'f3')]) {
        final n = hc().moves.length;
        await _tap(tester, on(d, find.byKey(Key('chess-sq-$from'))));
        await _tap(tester, on(d, find.byKey(Key('chess-sq-$to'))));
        await _tap(tester, on(d, find.byKey(const Key('confirm-move-commit'))));
        await until(() => hc().moves.length == n + 1 && ctl(guestKey).moves.length == n + 1);
      }
      await _tap(tester, on(guestKey, find.byKey(const Key('chess-sq-b8'))));
      await _tap(tester, on(guestKey, find.byKey(const Key('chess-sq-c6'))));
      await _shot(tester, 'kld122-network-guest-pending-de-phone', boundary: guestKey);
    });
  });
}
