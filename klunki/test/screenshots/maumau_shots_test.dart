// KLD-118 step 2 screenshots of Mau-Mau (hot-seat) on a phone (390×844):
// the menu tile, the house-rule options, a hand in play, the jack's suit
// picker, the handover cover, the wish, a 7 to answer, the drawn cards, the
// game end; plus a hand in English, dark and Arabic. Skipped unless
// KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/maumau_shots_test.dart --plain-name kld118
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
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/games/maumau/maumau_options.dart';
import 'package:klunki/ui/menu_screen.dart' show MenuScreen, menuShowsDebugConsole;
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import '../support/asset_images.dart';

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

Future<void> _pumpScreen(WidgetTester tester, Widget child,
    {Locale locale = const Locale('de'), Brightness brightness = Brightness.light, Size size = _phone}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final theme = brightness == Brightness.dark ? KlunkiTheme.dark : KlunkiTheme.light;
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: withAppFonts(theme, web: true),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: PlayerLabelsScope(
        labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}),
        child: child,
      ),
    ),
  ));
  await tester.pump();
  await tester.pump();
}

/// A hot-seat game with a fixed deal: Anna holds a jack, two hearts, a
/// king and a 9; Ben a 7 to answer with.
Future<GameController> _pumpGame(WidgetTester tester,
    {Locale locale = const Locale('de'),
    Brightness brightness = Brightness.light,
    Size size = _phone,
    MauMauRules rules = const MauMauRules(),
    List<String> a = const ['h7', 'cJ', 'h10', 'sK', 'd9', 'hQ'],
    List<String> b = const ['d7', 's8', 'c9', 'dA', 'h8'],
    String top = 'hK',
    List<String> stock = const ['c7', 'sQ', 'dK', 's10', 'c10', 'cA', 'sA', 'd8', 'c8', 'dQ']}) async {
  final c = GameController.hotSeat(GameConfig('maumau', seed: 1, mauMau: rules));
  addTearDown(c.dispose);
  (c.game as MauMauGame).debugSetup(a: a, b: b, top: top, stock: stock);
  await _pumpScreen(tester, buildGameScreen(c), locale: locale, brightness: brightness, size: size);
  await tester.pumpAndSettle();
  return c;
}

/// The first seed whose deal satisfies [test].
int _seedWhere(bool Function(MauMauGame g) test) {
  for (var seed = 1;; seed++) {
    if (test(createGame(GameConfig('maumau', seed: seed)) as MauMauGame)) return seed;
  }
}

/// Whether the first card A would draw fits.
bool _drawFits(MauMauGame g) {
  final copy = createGame(GameConfig('maumau', seed: g.seed)) as MauMauGame;
  copy.applyMove({'action': 'draw'});
  return copy.currentPlayer == Player.a;
}

Future<GameController> _pumpSeeded(
  WidgetTester tester,
  int seed, {
  Locale locale = const Locale('de'),
  Brightness brightness = Brightness.light,
  Size size = _phone,
}) async {
  final c = GameController.hotSeat(GameConfig('maumau', seed: seed));
  addTearDown(c.dispose);
  await _pumpScreen(tester, buildGameScreen(c), locale: locale, brightness: brightness, size: size);
  await tester.pumpAndSettle();
  return c;
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _handover(WidgetTester tester) => _tap(tester, find.byKey(const Key('handover-continue')));

void main() {
  // The "how to play" tour (KLD-118) has its own test (maumau_coach_test).
  setUp(() => SeenTips.shared.markFirst(SeenTips.maumauIntro));
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  group('kld118', () {
    testWidgets('menu tile', skip: skip, (tester) async {
      tester.view.physicalSize = _phone * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      menuShowsDebugConsole = false;
      addTearDown(() => menuShowsDebugConsole = true);
      await tester.pumpWidget(RepaintBoundary(
        key: _boundary,
        child: PlayerNameScope(
          controller: PlayerNameController.memory(),
          hotSeat: HotSeatNamesController.memory(),
          child: LocaleScope(
            controller: LocaleController.memory(const Locale('de')),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: withAppFonts(KlunkiTheme.light, web: true),
              locale: const Locale('de'),
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
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('menu-maumau')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('menu-maumau-local')), findsOneWidget);
      expect(find.byKey(const Key('menu-maumau-network')), findsNothing);
      await _shot(tester, '01-menu-tile');
    });

    testWidgets('options', skip: skip, (tester) async {
      await _pumpScreen(tester, const Scaffold(body: SizedBox.expand()));
      showMauMauOptionsDialog(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();
      await _shot(tester, '02-options');
    });

    testWidgets('a game: hand, jack, cover, wish, 7, drawn cards', skip: skip, (tester) async {
      final c = await _pumpGame(tester);
      await _shot(tester, '03-hand');
      await _tap(tester, find.byKey(const Key('maumau-hand-cJ')));
      expect(find.byKey(const Key('maumau-suit-picker')), findsOneWidget);
      await _shot(tester, '04-jack-suit-picker');
      await _tap(tester, find.byKey(const Key('maumau-suit-d')));
      expect(find.byKey(const Key('handover-cover')), findsOneWidget);
      await _shot(tester, '05-handover-cover');
      await _handover(tester);
      expect(find.byKey(const Key('maumau-wish')), findsOneWidget);
      await _shot(tester, '06-wish');
      expect(c.game.currentPlayer, Player.b);
    });

    // Draws are previewed on a replayed copy, so these use a real deal
    // (a seed) instead of debugSetup.
    testWidgets('a 7 to answer, the drawn cards', skip: skip, (tester) async {
      final seed = _seedWhere((g) => g.playableCards.any((c) => c.rank == MauMauRank.seven));
      final c = await _pumpSeeded(tester, seed);
      final seven = (c.game as MauMauGame).playableCards.firstWhere((c) => c.rank == MauMauRank.seven);
      await _tap(tester, find.byKey(Key('maumau-hand-${seven.id}')));
      await _handover(tester);
      expect(find.byKey(const Key('maumau-penalty')), findsOneWidget);
      await _shot(tester, '07-seven-to-answer');
      await _tap(tester, find.byKey(const Key('maumau-draw')));
      expect(find.byKey(const Key('maumau-feedback')), findsOneWidget);
      await _shot(tester, '08-drew-penalty');
      await _tap(tester, find.byKey(const Key('maumau-continue')));
      expect(find.byKey(const Key('handover-cover')), findsOneWidget);
      await _shot(tester, '09-cover-after-penalty');
    });

    testWidgets('drawn card does not fit', skip: skip, (tester) async {
      final seed = _seedWhere((g) => !_drawFits(g));
      await _pumpSeeded(tester, seed);
      await _tap(tester, find.byKey(const Key('maumau-draw')));
      expect(find.byKey(const Key('maumau-feedback')), findsOneWidget);
      await _shot(tester, '11-drew-no-fit');
    });

    testWidgets('drawn card fits', skip: skip, (tester) async {
      final seed = _seedWhere(_drawFits);
      await _pumpSeeded(tester, seed);
      await _tap(tester, find.byKey(const Key('maumau-draw')));
      expect(find.byKey(const Key('maumau-keep')), findsOneWidget);
      await _shot(tester, '12-drawn-fits');
    });

    testWidgets('game end', skip: skip, (tester) async {
      await _pumpGame(tester, a: const ['h9'], b: const ['s8', 'c9'], top: 'hK', stock: const ['dK']);
      await _tap(tester, find.byKey(const Key('maumau-hand-h9')));
      expect(find.byKey(const Key('result-dialog')), findsOneWidget);
      await _shot(tester, '10-game-end');
    });

    testWidgets('"Mau!" (on by default)', skip: skip, (tester) async {
      await _pumpGame(tester, a: const ['h7', 'sK'], top: 'hK', stock: const ['dK']);
      await _shot(tester, '13-mau-hint');
      await _tap(tester, find.byKey(const Key('maumau-mau')));
      await _shot(tester, '14-mau-pressed');
    });

    // Decided 2026-11-06: an ace lets the same player lay again, and it
    // chains (ace after ace); no handover cover in between.
    testWidgets('ace chain', skip: skip, (tester) async {
      final c = await _pumpGame(tester, a: const ['hA', 'sA', 's9', 'c8', 'dQ'],
          b: const ['d7', 'c9', 'h10', 'dK', 'cK'],
          top: 'h9',
          stock: const ['c7', 'sQ', 's10', 'c10', 'd8', 'hQ']);
      await _tap(tester, find.byKey(const Key('maumau-hand-hA')));
      expect(find.byKey(const Key('handover-cover')), findsNothing);
      expect(c.game.currentPlayer, Player.a);
      await _shot(tester, '16-ace-again');
      await _tap(tester, find.byKey(const Key('maumau-hand-sA')));
      expect(c.game.currentPlayer, Player.a);
      await _shot(tester, '17-ace-chain');
      await _tap(tester, find.byKey(const Key('maumau-hand-s9')));
      expect(find.byKey(const Key('handover-cover')), findsOneWidget);
      await _shot(tester, '18-ace-chain-cover');
    });

    for (final (tag, locale, brightness) in [
      ('en', const Locale('en'), Brightness.light),
      ('de-dark', const Locale('de'), Brightness.dark),
      ('ar', const Locale('ar'), Brightness.light),
      ('many-cards', const Locale('de'), Brightness.light),
    ]) {
      testWidgets('hand $tag', skip: skip, (tester) async {
        await _pumpGame(tester,
            locale: locale,
            brightness: brightness,
            a: tag == 'many-cards'
                ? const ['h7', 'cJ', 'h10', 'sK', 'd9', 'hQ', 'c7', 's7', 'd8', 'c10', 'sA', 'cQ', 'c8', 'h9', 'sQ', 'dK']
                : const ['h7', 'cJ', 'h10', 'sK', 'd9', 'hQ'],
            stock: const ['dQ']);
        await _shot(tester, '15-hand-$tag');
      });
    }
    // KLD-118 follow-up: the buttons on the phones the maintainer uses and
    // a tablet: start of the turn, a drawn card that fits, "Mau!" due.
    for (final (tag, size) in [
      ('375x667', const Size(375, 667)),
      ('393x852', const Size(393, 852)),
      ('tablet', const Size(820, 1180)),
    ]) {
      testWidgets('buttons $tag', skip: skip, (tester) async {
        await _pumpGame(tester, size: size);
        await _shot(tester, '21-$tag-start');
        await _pumpGame(tester, size: size, a: const ['h7', 'sK'], top: 'hK', stock: const ['dK']);
        await _shot(tester, '21-$tag-mau-due');
        await _pumpSeeded(tester, _seedWhere(_drawFits), size: size);
        await _tap(tester, find.byKey(const Key('maumau-draw')));
        await _shot(tester, '21-$tag-drawn-fits');
      });
    }

    for (final (tag, locale, brightness) in [
      ('de-dark', const Locale('de'), Brightness.dark),
      ('ar', const Locale('ar'), Brightness.light),
    ]) {
      testWidgets('buttons $tag', skip: skip, (tester) async {
        await _pumpGame(
          tester,
          locale: locale,
          brightness: brightness,
          a: const ['h7', 'sK'],
          top: 'hK',
          stock: const ['dK'],
        );
        await _shot(tester, '22-$tag-mau-due');
        await _pumpSeeded(tester, _seedWhere(_drawFits), locale: locale, brightness: brightness);
        await _tap(tester, find.byKey(const Key('maumau-draw')));
        await _shot(tester, '22-$tag-drawn-fits');
        await _pumpSeeded(tester, _seedWhere((g) => g.playableCards.isEmpty), locale: locale, brightness: brightness);
        await _shot(tester, '22-$tag-only-draw');
      });
    }

    // The "how to play" tour the first time (phone, dark, Arabic).
    for (final (tag, locale, brightness) in [
      ('de', const Locale('de'), Brightness.light),
      ('de-dark', const Locale('de'), Brightness.dark),
      ('ar', const Locale('ar'), Brightness.light),
    ]) {
      testWidgets('tour $tag', skip: skip, (tester) async {
        SeenTips.debugReset();
        await _pumpGame(tester, locale: locale, brightness: brightness);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('maumau-coach')), findsOneWidget);
        await _shot(tester, '23-tour-$tag-1');
        await _tap(tester, find.byKey(const Key('maumau-coach-next')));
        await _shot(tester, '23-tour-$tag-2');
        await _tap(tester, find.byKey(const Key('maumau-coach-next')));
        await _shot(tester, '23-tour-$tag-3');
        await _tap(tester, find.byKey(const Key('maumau-coach-next')));
        await _shot(tester, '23-tour-$tag-4');
        await _tap(tester, find.byKey(const Key('maumau-coach-done')));
        expect(find.byKey(const Key('maumau-coach')), findsNothing);
      });
    }

    // A 7 chain builds up: 2, 4, 6 cards to draw, then the 6 cards arrive.
    testWidgets('7 chain', skip: skip, (tester) async {
      bool sevens(MauMauGame g, Player p, int n) => g.handOf(p).where((c) => c.rank == MauMauRank.seven).length >= n;
      final seed = _seedWhere(
        (g) =>
            sevens(g, Player.a, 2) && sevens(g, Player.b, 1) && g.playableCards.any((c) => c.rank == MauMauRank.seven),
      );
      final c = await _pumpSeeded(tester, seed);
      MauMauGame g() => c.game as MauMauGame;
      MauMauCard seven() => g().playableCards.firstWhere((c) => c.rank == MauMauRank.seven);
      await _tap(tester, find.byKey(Key('maumau-hand-${seven().id}')));
      await _shot(tester, '24-chain-2-cover');
      await _handover(tester);
      expect(g().penalty, 2);
      await _shot(tester, '24-chain-2');
      await _tap(tester, find.byKey(Key('maumau-hand-${seven().id}')));
      await _shot(tester, '24-chain-4-cover');
      await _handover(tester);
      expect(g().penalty, 4);
      await _shot(tester, '24-chain-4');
      await _tap(tester, find.byKey(Key('maumau-hand-${seven().id}')));
      await _handover(tester);
      expect(g().penalty, 6);
      expect(find.byKey(const Key('maumau-chain-3')), findsOneWidget);
      await _shot(tester, '24-chain-6');
      await _tap(tester, find.byKey(const Key('maumau-draw')));
      expect(find.byKey(const Key('maumau-feedback')), findsOneWidget);
      await _shot(tester, '24-chain-6-drawn');
    });
  });
}
