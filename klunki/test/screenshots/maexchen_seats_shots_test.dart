// KLD-121 step 2 screenshots of Mäxchen for 3–4 players on one device and
// the rule variant "Unbegrenzte Leben": "Wer spielt?" with 4 players, the
// start options with the variant on, a 4-player game mid-way, the handover
// cover, a life lost with the tally of "Unbegrenzte Leben", and the results
// (by the order the players went out, and by lives lost), on a phone in
// German (light); plus an iPhone SE and Arabic (right to left) for the
// checks. Skipped unless KLUNKI_SHOTS=<output dir> is set; the pictures go
// to `<dir>/maexchen-4p-shots/`:
//
//   KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/maexchen_seats_shots_test.dart --plain-name kld121-4p
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
import 'package:klunki/ui/games/maexchen/maexchen_options.dart';
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
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pumpAndSettle();
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/maexchen-4p-shots/$name.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

const _names = {
  'ar': ['سارة', 'عمر', 'ليلى', 'يوسف'],
};
const _deNames = ['Anna', 'Ben', 'Cleo', 'Dani'];

Future<void> _pumpApp(WidgetTester tester, Widget home, {Locale locale = const Locale('de'), Size size = _phone}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
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
        theme: withAppFonts(KlunkiTheme.light, web: true),
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

Future<GameController> _game(WidgetTester tester, List<List<int>> rolls,
    {Locale locale = const Locale('de'), Size size = _phone, bool unlimited = false}) async {
  final c = GameController.hotSeat(GameConfig('maexchen', seed: 5, players: 4, maexchenUnlimited: unlimited));
  addTearDown(c.dispose);
  (c.game as MaexchenGame).debugScriptRolls(rolls);
  await _pumpApp(tester, buildGameScreen(c), locale: locale, size: size);
  return c;
}

/// Set-up through the controller (not what is shown): [moves] in order.
Future<void> _moves(WidgetTester tester, GameController c, List<Map<String, dynamic>> moves) async {
  for (final m in moves) {
    final r = await c.submit(m);
    expect(r.isAccepted, isTrue, reason: '$m');
  }
  await tester.pumpAndSettle();
  c.acknowledgeHandover();
  await tester.pumpAndSettle();
}

const _roll = MaexchenGame.rollMove;
const _believe = MaexchenGame.believeMove;
const _doubt = MaexchenGame.doubtMove;
Map<String, dynamic> _say(int v) => MaexchenGame.announceMove(v);

/// Three rounds and a half: Anna bluffs and Ben catches her; Ben bluffs a
/// 66 and Cleo catches it; Cleo doubts Ben's true 42 and loses; Cleo says
/// 43, Dani believes and rolls 64 (then says 64 to Anna).
const _rolls = [[3, 1], [5, 5], [6, 2], [4, 2], [4, 2], [6, 4]];
final _setup = [
  _roll, _say(65), _doubt, // Anna loses
  _roll, _say(55), _believe, _roll, _say(66), _doubt, // Ben loses (62 under the cup)
  _roll, _say(42), _doubt, // Cleo doubts the truth and loses
  _roll, _say(43), _believe, _roll, // Dani rolls 64
];

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    for (var i = 0; i < 4; i++) {
      SeenTips.shared.markFirst(SeenTips.rulesOpened('maexchen'));
    }
    ExtraSeatNames.debugReset();
    UndoSettings.debugReset();
  });

  group('kld121-4p', () {
    testWidgets('"Wer spielt?" with 4 players, options with "Unbegrenzte Leben"', skip: skip, (tester) async {
      await _pumpApp(tester, const Scaffold(body: SizedBox.expand()));
      showSeatPlayersDialog(tester.element(find.byType(Scaffold)), undoFor: 'maexchen', passDevice: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('seat-players-4')));
      await tester.pumpAndSettle();
      await _shot(tester, '01-who-plays-4');
      await tester.tap(find.byKey(const Key('hot-seat-names-cancel')));
      await tester.pumpAndSettle();
      showMaexchenOptionsDialog(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('maexchen-unlimited')));
      await tester.pumpAndSettle();
      await _shot(tester, '02-options-unlimited');
    });

    for (final (name, size, locale) in [
      ('phone', _phone, const Locale('de')),
      ('se', _se, const Locale('de')),
      ('se-ar', _se, const Locale('ar')),
    ]) {
      testWidgets('4 players $name: start, handover, mid-game, result', skip: skip, (tester) async {
        final c = await _game(tester, _rolls, locale: locale, size: size);
        if (name == 'phone') await _shot(tester, '03-start-4-players');
        await _moves(tester, c, _setup);
        await c.submit(_say(64));
        await tester.pumpAndSettle();
        await _shot(tester, '04-handover-$name');
        await tester.tap(find.byKey(const Key('handover-continue')));
        await tester.pumpAndSettle();
        await _shot(tester, '05-mid-game-$name');
        // To the end: the player to move doubts at once (set-up).
        var guard = 0;
        while (!c.game.isOver && guard++ < 500) {
          final g = c.game as MaexchenGame;
          await c.submit(switch (g.phase) {
            MaexchenPhase.roll => _roll,
            MaexchenPhase.announce => _say(MaexchenGame.valuesAbove(g.announced).first),
            MaexchenPhase.respond => _doubt,
          });
        }
        await tester.pumpAndSettle();
        expect(c.game.isOver, isTrue);
        await _shot(tester, '06-result-$name');
        expect(tester.takeException(), isNull);
      });

      testWidgets('"Unbegrenzte Leben" $name: a life lost with the tally, then "Spiel beenden"', skip: skip,
          (tester) async {
        final c = await _game(tester, [..._rolls, [3, 2]], locale: locale, size: size, unlimited: true);
        await _moves(tester, c, [..._setup, _say(64), _doubt]);
        // Anna doubted Dani's true 64 and lost; Anna starts, rolls 32, says
        // 53, Ben doubts: Anna loses another life (the cover shows it).
        await _moves(tester, c, [_roll]);
        await c.submit(_say(53));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('handover-continue')));
        await tester.pumpAndSettle();
        await c.submit(_doubt);
        await tester.pumpAndSettle();
        await _shot(tester, '07-unlimited-life-lost-cover-$name');
        await tester.tap(find.byKey(const Key('handover-continue')));
        await tester.pumpAndSettle();
        await _shot(tester, '08-unlimited-tally-$name');
        await tester.tap(find.byKey(const Key('shell-menu')));
        await tester.pumpAndSettle();
        if (name == 'phone') await _shot(tester, '09-unlimited-menu');
        await tester.tap(find.byKey(const Key('maexchen-end')));
        await tester.pumpAndSettle();
        if (name == 'phone') await _shot(tester, '10-unlimited-end-confirm');
        await tester.tap(find.byKey(const Key('maexchen-end-confirm')));
        await tester.pumpAndSettle();
        expect(c.game.isOver, isTrue);
        await _shot(tester, '11-unlimited-result-$name');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
