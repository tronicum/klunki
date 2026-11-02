// KLD-059 step 3 screenshots: chess over the network, two phones side by side
// (host White, guest Black with the board turned), the draw offer on both
// devices and the results. Real NetworkTransports on 127.0.0.1. Skipped
// unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/chess-net flutter test test/screenshots/chess_net_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/chess/chess_board.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

final String? _out = Platform.environment['KLUNKI_SHOTS'];
const _hostKey = Key('device-host');
const _guestKey = Key('device-guest');
const _ping = Duration(milliseconds: 100);
const _timeout = Duration(seconds: 30);

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

Finder _on(Key device, Finder f) => find.descendant(of: find.byKey(device), matching: f);

Future<void> _until(WidgetTester tester, bool Function() condition, String what) async {
  for (var round = 0;; round++) {
    await tester.pump();
    if (condition()) {
      await tester.pump();
      await tester.pump();
      return;
    }
    if (round > 2000) fail('condition not met: $what');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pump();
  await tester.pump();
}

/// Captures one device's screen (its RepaintBoundary) as `<name>.png`.
Future<void> _shot(WidgetTester tester, Key device, String name) async {
  debugDisableShadows = false;
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(device));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

Future<void> _start(WidgetTester tester) async {
  tester.view.physicalSize = const Size(2 * 390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final (host, guest) = (await tester.runAsync(() async {
    final h = await NetworkTransport.host(const GameConfig('chess'),
        name: 'Anna', address: InternetAddress.loopbackIPv4, wsPort: null, pingInterval: _ping, timeout: _timeout);
    final g = await NetworkTransport.join(InternetAddress.loopbackIPv4, h.port!,
        name: 'Ben', pingInterval: _ping, timeout: _timeout);
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
  Widget device(Key key, NetworkTransport t) => Expanded(
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: KlunkiTheme.light,
            locale: const Locale('de'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: NetworkGameSession(transport: t),
          ),
        ),
      );
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Row(children: [device(_hostKey, host), device(_guestKey, guest)]),
  ));
  await _until(tester, () => _on(_guestKey, find.byType(ChessBoard)).evaluate().isNotEmpty, 'guest board');
  await _until(tester, () => _on(_hostKey, find.byType(ChessBoard)).evaluate().isNotEmpty, 'host board');
}

int _moves(WidgetTester tester) => tester.widget<GameScreen>(_on(_hostKey, find.byType(GameScreen))).controller.moves.length;

Future<void> _move(WidgetTester tester, Key device, String from, String to) async {
  final n = _moves(tester);
  await _tap(tester, _on(device, find.byKey(Key('chess-sq-$from'))));
  await _tap(tester, _on(device, find.byKey(Key('chess-sq-$to'))));
  await _until(tester, () => _moves(tester) == n + 1, '$from-$to');
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  await tester.pump();
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  testWidgets('kld059 network: host White, guest Black turned; draw offer; agreed draw', skip: skip, (tester) async {
    await _start(tester);
    for (final (d, from, to) in [
      (_hostKey, 'e2', 'e4'), (_guestKey, 'e7', 'e5'), (_hostKey, 'g1', 'f3'), (_guestKey, 'b8', 'c6'), //
      (_hostKey, 'f1', 'c4'), (_guestKey, 'f8', 'c5'), (_hostKey, 'c2', 'c3'),
    ]) {
      await _move(tester, d, from, to);
    }
    // The guest selects its knight: targets on the turned board.
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-sq-g8'))));
    await _shot(tester, _hostKey, '01-host-white');
    await _shot(tester, _guestKey, '02-guest-black-turned');
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-sq-f6'))));
    await _until(tester, () => _moves(tester) == 8, 'Nf6');

    // The host offers a draw.
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-offer-draw'))));
    await _shot(tester, _hostKey, '03-host-offer-confirm');
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-offer-confirm'))));
    await _until(tester, () => _on(_guestKey, find.byKey(const Key('chess-draw-offer-dialog'))).evaluate().isNotEmpty,
        'offer on the guest');
    await _shot(tester, _guestKey, '04-guest-draw-offer');
    await _shot(tester, _hostKey, '05-host-waiting-hint');
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-draw-decline'))));
    await _until(tester, () => _moves(tester) == 10, 'decline');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await _shot(tester, _hostKey, '06-host-declined-hint');

    // Later the guest offers and the host accepts.
    await _move(tester, _hostKey, 'd2', 'd3');
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-offer-draw'))));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await _tap(tester, _on(_guestKey, find.byKey(const Key('chess-offer-confirm'))));
    await _until(tester, () => _on(_hostKey, find.byKey(const Key('chess-draw-offer-dialog'))).evaluate().isNotEmpty,
        'offer on the host');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await _tap(tester, _on(_hostKey, find.byKey(const Key('chess-draw-accept'))));
    await _until(
        tester,
        () => _on(_guestKey, find.byKey(const Key('result-dialog'))).evaluate().isNotEmpty &&
            _on(_hostKey, find.byKey(const Key('result-dialog'))).evaluate().isNotEmpty,
        'result on both');
    await _shot(tester, _hostKey, '07-host-result-draw-agreed');
    await _shot(tester, _guestKey, '08-guest-result-draw-agreed');
  });

  testWidgets('kld059 network: checkmate result on both devices', skip: skip, (tester) async {
    await _start(tester);
    for (final (d, from, to) in [
      (_hostKey, 'e2', 'e4'), (_guestKey, 'e7', 'e5'), (_hostKey, 'f1', 'c4'), (_guestKey, 'b8', 'c6'), //
      (_hostKey, 'd1', 'h5'), (_guestKey, 'g8', 'f6'), (_hostKey, 'h5', 'f7'),
    ]) {
      await _move(tester, d, from, to);
    }
    await _until(
        tester,
        () => _on(_guestKey, find.byKey(const Key('result-dialog'))).evaluate().isNotEmpty &&
            _on(_hostKey, find.byKey(const Key('result-dialog'))).evaluate().isNotEmpty,
        'result on both');
    await _shot(tester, _hostKey, '09-host-result-mate');
    await _shot(tester, _guestKey, '10-guest-result-mated');
  });
}
