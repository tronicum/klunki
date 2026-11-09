// KLD-125 screenshots of Wortgewandt for 3–4 players on one device: "Wer
// spielt?" with 4 players, a 4-player game mid-way (score row with four
// seats), the handover cover, the result with the ranking, on a phone in
// German (light); plus an iPhone SE, Arabic (right to left) and dark mode
// for the checks. The German word list makes the bot lay real words.
// Skipped unless KLUNKI_SHOTS=<output dir> is set:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/wordtiles_seats_shots_test.dart --plain-name kld125
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
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/ui/games/wordtiles/word_list_loader.dart';
import 'package:klunki/ui/seat_players_dialog.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

final String? _out = Platform.environment['KLUNKI_SHOTS'];
const _boundary = Key('shot-boundary');
const _phone = Size(390, 844);
const _se = Size(375, 667);

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
    final f = File('$_out/kld125/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

const _names = {
  'ar': ['سارة', 'عمر', 'ليلى', 'يوسف'],
};
const _deNames = ['Anna', 'Ben', 'Cleo', 'Dani'];

Future<void> _pumpApp(WidgetTester tester, Widget home,
    {Locale locale = const Locale('de'), Brightness brightness = Brightness.light, Size size = _phone}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final theme = brightness == Brightness.dark ? KlunkiTheme.dark : KlunkiTheme.light;
  final names = _names[locale.languageCode] ?? _deNames;
  ExtraSeatNames.debugReset();
  await ExtraSeatNames.shared().set(third: names[2], fourth: names[3], players: 4);
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: PlayerNameScope(
      controller: PlayerNameController.memory(),
      hotSeat: HotSeatNamesController.memory(HotSeatNames(x: names[0], o: names[1])),
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
  ));
  await tester.pumpAndSettle();
}

Future<GameController> _game(WidgetTester tester,
    {Locale locale = const Locale('de'), Brightness brightness = Brightness.light, Size size = _phone}) async {
  final c = GameController.hotSeat(const GameConfig('wordtiles', seed: 5, players: 4, dictionary: true));
  addTearDown(c.dispose);
  await _pumpApp(tester, buildGameScreen(c), locale: locale, brightness: brightness, size: size);
  return c;
}

/// Plays [moves] turns through the controller (set-up, not what is shown):
/// the best-scoring sample placement, else a pass.
Future<void> _bot(WidgetTester tester, GameController c, int moves) async {
  for (var i = 0; i < moves && !c.game.isOver; i++) {
    final g = c.game as WordTilesGame;
    Map<String, dynamic>? best;
    var score = -1;
    for (final m in g.legalMoves) {
      if (m['action'] != 'place') continue;
      final s = g.checkPlacement(m).score;
      if (s > score) (best, score) = (m, s);
    }
    final r = await c.submit(best ?? const {'action': 'pass'});
    expect(r.isAccepted, isTrue);
  }
  await tester.pumpAndSettle();
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('handover-continue')));
  await tester.pumpAndSettle();
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.wordtilesBench);
    SeenTips.shared.markFirst(SeenTips.rulesOpened('wordtiles'));
    ExtraSeatNames.debugReset();
    UndoSettings.debugReset();
  });

  group('kld125', () {
    testWidgets('"Wer spielt?" with 4 players', skip: skip, (tester) async {
      await _pumpApp(tester, const Scaffold(body: SizedBox.expand()));
      showSeatPlayersDialog(tester.element(find.byType(Scaffold)), undoFor: 'wordtiles', passDevice: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('seat-players-4')));
      await tester.pumpAndSettle();
      await _shot(tester, '01-who-plays-4');
    });

    for (final (name, size, locale, brightness) in [
      ('phone', _phone, const Locale('de'), Brightness.light),
      ('se', _se, const Locale('de'), Brightness.light),
      ('se-ar', _se, const Locale('ar'), Brightness.light),
      ('phone-dark', _phone, const Locale('de'), Brightness.dark),
    ]) {
      testWidgets('4 players $name: mid-game, handover, result', skip: skip, (tester) async {
        await tester.runAsync(() => WordListLoader.ensure('de'));
        addTearDown(WordListLoader.reset);
        final c = await _game(tester, locale: locale, brightness: brightness, size: size);
        if (name == 'phone') await _shot(tester, '02-start-4-players');
        await _bot(tester, c, 9);
        await _shot(tester, '03-handover-$name');
        await _continue(tester);
        await _shot(tester, '04-mid-game-$name');
        await _bot(tester, c, 400);
        expect(c.game.isOver, isTrue);
        await _shot(tester, '05-result-$name');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
