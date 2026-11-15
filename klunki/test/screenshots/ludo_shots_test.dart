// KLD-131 screenshots of Rauswurf: the menu tile, a 4-player board at the
// start, mid-game boards (2 and 4 players, after captures, pawns glowing),
// the game end ranking, the same mid-game in dark mode and in Arabic, a
// landscape tablet and the rules page. Skipped unless KLUNKI_SHOTS=<output
// dir> is set:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/ludo_shots_test.dart --plain-name kld131
import 'dart:io';
import 'dart:math';
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
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/menu_screen.dart' show MenuScreen, menuShowsDebugConsole;
import 'package:klunki/ui/rules/rules_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/debug.dart' show LudoText;
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

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
  debugDisableShadows = false;
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/kld131/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

const _arNames = ['سارة', 'عمر', 'ليلى', 'يوسف'];
const _deNames = ['Anna', 'Ben', 'Cleo', 'Dani'];

Future<void> _pumpApp(WidgetTester tester, Widget home,
    {Locale locale = const Locale('de'), Brightness brightness = Brightness.light, Size size = _phone}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final theme = brightness == Brightness.dark ? KlunkiTheme.dark : KlunkiTheme.light;
  final names = locale.languageCode == 'ar' ? _arNames : _deNames;
  ExtraSeatNames.debugReset();
  await ExtraSeatNames.shared().set(third: names[2], fourth: names[3], players: 4);
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: PlayerNameScope(
      controller: PlayerNameController.memory(),
      hotSeat: HotSeatNamesController.memory(HotSeatNames(x: names[0], o: names[1])),
      child: LocaleScope(
        controller: LocaleController.memory(locale),
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
          home: home,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<GameController> _game(WidgetTester tester,
    {int players = 4,
    int seed = 7,
    Locale locale = const Locale('de'),
    Brightness brightness = Brightness.light,
    Size size = _phone}) async {
  final c = GameController.hotSeat(GameConfig('ludo', seed: seed, players: players));
  addTearDown(c.dispose);
  await _pumpApp(tester, buildGameScreen(c), locale: locale, brightness: brightness, size: size);
  return c;
}

/// Plays with the debug bot through the controller until [done] (set-up
/// for a screenshot, not the thing shown).
Future<void> _botUntil(WidgetTester tester, GameController c, bool Function(LudoGame g) done, {int seed = 3}) async {
  final rng = Random(seed);
  var n = 0;
  while (!c.game.isOver && !done(c.game as LudoGame) && n++ < 5000) {
    await c.submit(LudoText(game: c.game as LudoGame).autoMove(rng));
  }
  await tester.pumpAndSettle();
}

int _captures(LudoGame g) => g.history.where((m) => m['captured'] != null).length;

/// Mid-game: some captures behind, pawns on the track, and the player to
/// move choosing between at least [choices] glowing pawns.
bool Function(LudoGame g) _midGame({int captures = 2, int choices = 2, int moves = 80}) => (g) =>
    g.history.length >= moves &&
    _captures(g) >= captures &&
    g.die != null &&
    g.movablePawns.length >= choices;

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    ExtraSeatNames.debugReset();
  });

  group('kld131', () {
    testWidgets('menu tile', skip: skip, (tester) async {
      menuShowsDebugConsole = false;
      addTearDown(() => menuShowsDebugConsole = true);
      await _pumpApp(tester, const MenuScreen());
      await tester.ensureVisible(find.byKey(const Key('menu-ludo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('menu-ludo-local')), findsOneWidget);
      expect(find.byKey(const Key('menu-ludo-network')), findsNothing);
      await _shot(tester, '01-menu-tile');
    });

    testWidgets('4 players: the start', skip: skip, (tester) async {
      await _game(tester);
      await _shot(tester, '02-4p-start');
      // The first roll: no 6, two tries left.
      await tester.tap(find.byKey(const Key('ludo-die')));
      await tester.pumpAndSettle();
      await _shot(tester, '03-4p-first-roll');
    });

    testWidgets('2 players: mid-game after captures', skip: skip, (tester) async {
      final c = await _game(tester, players: 2, seed: 3);
      await _botUntil(tester, c, _midGame(moves: 60));
      await _shot(tester, '04-2p-midgame');
    });

    testWidgets('4 players: mid-game after captures', skip: skip, (tester) async {
      final c = await _game(tester);
      await _botUntil(tester, c, _midGame(captures: 4, moves: 200));
      await _shot(tester, '05-4p-midgame');
      // A capture just happened: the hint line tells whose pawn went home.
      await _botUntil(tester, c, (g) => c.moves.isNotEmpty && c.moves.last.event.payload is Map &&
          (c.moves.last.event.payload as Map)['captured'] != null);
      await _shot(tester, '06-4p-capture');
    });

    testWidgets('4 players: dark mode', skip: skip, (tester) async {
      final c = await _game(tester, brightness: Brightness.dark);
      await _botUntil(tester, c, _midGame(captures: 4, moves: 200));
      await _shot(tester, '07-4p-midgame-dark');
    });

    testWidgets('4 players: the end', skip: skip, (tester) async {
      final c = await _game(tester);
      await _botUntil(tester, c, (_) => false);
      await tester.pumpAndSettle();
      await _shot(tester, '08-4p-result');
    });

    testWidgets('3 players: Arabic', skip: skip, (tester) async {
      final c = await _game(tester, players: 3, seed: 5, locale: const Locale('ar'));
      await _botUntil(tester, c, _midGame(moves: 100));
      await _shot(tester, '09-3p-midgame-ar');
    });

    testWidgets('tablet landscape', skip: skip, (tester) async {
      final c = await _game(tester, size: const Size(1180, 820));
      await _botUntil(tester, c, _midGame(captures: 3, moves: 150));
      await _shot(tester, '10-4p-tablet-landscape');
    });

    testWidgets('rules page', skip: skip, (tester) async {
      await _pumpApp(tester, const RulesScreen(gameId: 'ludo', config: GameConfig('ludo')));
      await _shot(tester, '11-rules');
      await tester.scrollUntilVisible(find.byKey(const Key('rules-house-six')), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await _shot(tester, '12-rules-house-rules');
    });
  });
}
