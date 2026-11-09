// KLD-121 step 2: Mäxchen for 3–4 players on one device and the rule
// variant "Unbegrenzte Leben". The seat shell with the handover cover before
// every player who takes the cup, players without lives greyed and skipped,
// the ranking by the order the players went out, the lives row with four
// players on an iPhone SE (also right to left), the tally of lost lives,
// "Spiel beenden" from the menu, and the start from the menu. Played through
// the real UI (taps, never `controller.submit`).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/ui/games/maexchen/maexchen_dice.dart';
import 'package:klunki/ui/rules/rules_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

List<int>? _tableDice(WidgetTester tester) => tester.widget<CupTable>(find.byType(CupTable)).dice;

MaexchenGame _game(GameController c) => c.game as MaexchenGame;

const _phone = Size(390, 844);
/// iPhone SE (2nd/3rd generation), as in maexchen_layout_test.dart.
const _se = Size(375, 667);

/// The bundled Roboto, so the widths are those of the real app (the test
/// font is wider).
Future<void> _loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Roboto/Roboto-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

Future<GameController> _start(WidgetTester tester,
    {int players = 4,
    int lives = 3,
    bool unlimited = false,
    List<List<int>> rolls = const [],
    Size size = _phone,
    Locale locale = testLocale}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(
      GameConfig('maexchen', seed: 3, players: players, lives: lives, maexchenUnlimited: unlimited));
  addTearDown(c.dispose);
  _game(c).debugScriptRolls(rolls);
  await tester.pumpWidget(localizedApp(buildGameScreen(c), locale: locale));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _rollAndAnnounce(WidgetTester tester, int value) async {
  await _tap(tester, 'maexchen-roll');
  await _tap(tester, 'maexchen-peek');
  await _tap(tester, 'maexchen-value-$value');
  await _tap(tester, 'maexchen-announce');
}

/// The cover is up for [name] (seat [seat]); "Weiter".
Future<void> _handOverTo(WidgetTester tester, String name, int seat) async {
  expect(_key('handover-cover'), findsOneWidget, reason: name);
  expect(find.text('Gib das Gerät an $name weiter'), findsOneWidget);
  expect(tester.widget<SeatToken>(_key('handover-seat')).seat, seat);
  expect(_key('maexchen-table').hitTestable(), findsNothing, reason: 'the table is covered');
  await tester.tap(_key('handover-continue'));
  await tester.pumpAndSettle();
}

/// Every lives cell lies on screen, side by side, none wider than a quarter.
void _expectCellsFit(WidgetTester tester, int players, Size size, {bool rtl = false}) {
  final rects = [for (var s = 0; s < players; s++) tester.getRect(_key('maexchen-lives-${'abcd'[s]}'))];
  for (final r in rects) {
    expect(r.left, greaterThanOrEqualTo(0));
    expect(r.right, lessThanOrEqualTo(size.width));
    expect(r.width, lessThanOrEqualTo(size.width / players));
  }
  for (var s = 1; s < players; s++) {
    // Seat order runs with the reading direction.
    if (rtl) {
      expect(rects[s].right, lessThanOrEqualTo(rects[s - 1].left + 0.5));
    } else {
      expect(rects[s].left, greaterThanOrEqualTo(rects[s - 1].right - 0.5));
    }
  }
}

void main() {
  setUpAll(_loadRoboto);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    ExtraSeatNames.debugReset();
    UndoSettings.debugReset();
  });

  testWidgets('4 players: the seat shell; the cover comes before every player who takes the cup', (tester) async {
    final c = await _start(tester, rolls: [[3, 1], [4, 1], [5, 1], [6, 1], [6, 2]]);
    expect(find.byType(SeatGameScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    for (final k in ['a', 'b', 'c', 'd']) {
      expect(_key('maexchen-heart-$k-2'), findsOneWidget);
    }
    await _rollAndAnnounce(tester, 31);
    final names = ['Ben', 'Cleo', 'Dani', 'Anna'];
    final dice = [[4, 1], [5, 1], [6, 1], [6, 2]];
    final say = [41, 51, 61, 62];
    for (final (n, name) in names.indexed) {
      final seat = (n + 1) % 4;
      await _handOverTo(tester, name, seat);
      expect(find.text('$name ist am Zug'), findsOneWidget);
      expect(_game(c).actorSeat, seat);
      expect(_tableDice(tester), isNull, reason: 'nobody sees the dice of the one before');
      await _tap(tester, 'maexchen-believe');
      await _tap(tester, 'maexchen-roll');
      await _tap(tester, 'maexchen-peek');
      expect(_tableDice(tester), dice[n], reason: '$name sees the own dice');
      await _tap(tester, 'maexchen-value-${say[n]}');
      await _tap(tester, 'maexchen-announce');
    }
    // Anna's 62 goes to Ben again.
    await _handOverTo(tester, 'Ben', 1);
    expect(find.text('Anna sagt 62. Glaubst du das?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a player without lives is greyed and skipped; the ranking goes by the order they went out',
      (tester) async {
    final c = await _start(tester, players: 3, lives: 1, rolls: [[3, 1], [3, 1], [3, 1]]);
    // Anna bluffs 65 over 31, Ben doubts: Anna is out, Ben starts.
    await _rollAndAnnounce(tester, 65);
    await _handOverTo(tester, 'Ben', 1);
    await _tap(tester, 'maexchen-doubt');
    expect(find.text('Geflunkert! Anna verliert ein Leben.'), findsWidgets);
    expect(_game(c).isSeatOut(0), isTrue);
    expect(_key('handover-cover'), findsNothing, reason: 'Ben holds the device and starts');
    expect(tester.widget<Opacity>(find.ancestor(of: _key('maexchen-lives-a'), matching: find.byType(Opacity)).first).opacity,
        0.5);
    expect(tester.widget<SeatToken>(find.descendant(of: _key('maexchen-lives-a'), matching: find.byType(SeatToken))).out,
        isTrue);
    // Ben to Cleo, Cleo believes and announces: the cup skips Anna.
    await _rollAndAnnounce(tester, 32);
    await _handOverTo(tester, 'Cleo', 2);
    await _tap(tester, 'maexchen-believe');
    await _rollAndAnnounce(tester, 41);
    await _handOverTo(tester, 'Ben', 1);
    await _tap(tester, 'maexchen-doubt');
    // Cleo bluffed (31 under the cup): out; Ben wins.
    expect(_key('result-dialog'), findsOneWidget);
    expect(find.text('Ben gewinnt!'), findsOneWidget);
    expect(find.text('Keine Leben mehr übrig'), findsOneWidget);
    final ranks = [for (final s in [1, 2, 0]) tester.getTopLeft(_key('result-rank-$s')).dy];
    expect(ranks, orderedEquals([...ranks]..sort()), reason: 'Ben, then Cleo (out last), then Anna');
    expect(find.descendant(of: _key('result-rank-1'), matching: find.text('noch 1 Leben')), findsOneWidget);
    expect(find.descendant(of: _key('result-rank-2'), matching: find.text('ausgeschieden')), findsOneWidget);
    expect(find.descendant(of: _key('result-rank-0'), matching: find.text('ausgeschieden')), findsOneWidget);
    expect(find.text('Falsches Mäxchen! Cleo verliert 2 Leben.'), findsNothing);
    expect(_key('maexchen-summary'), findsWidgets, reason: 'how the last life was lost');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a player resigns: out, the round starts again, the others play on', (tester) async {
    final c = await _start(tester, players: 3, rolls: [[6, 5], [4, 4]]);
    await _rollAndAnnounce(tester, 65);
    await _handOverTo(tester, 'Ben', 1);
    await _tap(tester, 'shell-resign');
    await _tap(tester, 'resign-seat-1');
    expect(_game(c).isSeatOut(1), isTrue);
    expect(_game(c).announced, isNull);
    await _handOverTo(tester, 'Cleo', 2);
    expect(find.text('Neue Runde: jede Zahl ist erlaubt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (locale, rtl) in [(testLocale, false), (const Locale('ar'), true)]) {
    for (final unlimited in [false, true]) {
      testWidgets('4 players on an iPhone SE (${locale.languageCode}, ${unlimited ? 'tally' : '5 hearts'}): '
          'the lives row fits', (tester) async {
        final c = await _start(tester, lives: 5, unlimited: unlimited, size: _se, locale: locale, rolls: [[3, 1]]);
        _expectCellsFit(tester, 4, _se, rtl: rtl);
        if (!unlimited) {
          for (final k in ['a', 'b', 'c', 'd']) {
            expect(_key('maexchen-heart-$k-4'), findsOneWidget);
            final heart = tester.getRect(_key('maexchen-heart-$k-4'));
            final cell = tester.getRect(_key('maexchen-lives-$k'));
            expect(cell.contains(heart.center), isTrue, reason: 'the fifth heart stays inside the cell');
          }
        }
        // A round: Anna bluffs, Ben doubts.
        await _rollAndAnnounce(tester, 65);
        await tester.tap(_key('handover-continue'));
        await tester.pumpAndSettle();
        await _tap(tester, 'maexchen-doubt');
        await tester.tap(_key('handover-continue'));
        await tester.pumpAndSettle();
        if (unlimited) {
          expect(tester.widget<Text>(_key('maexchen-lost-a')).data, '1');
          expect(tester.widget<Text>(_key('maexchen-lost-b')).data, '0');
          expect(_key('maexchen-heart-a-0'), findsNothing, reason: 'the tally replaces the hearts');
        } else {
          expect(tester.widget<Icon>(_key('maexchen-heart-a-4')).icon, Icons.favorite_border);
        }
        _expectCellsFit(tester, 4, _se, rtl: rtl);
        expect(_game(c).round, 2);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('"Unbegrenzte Leben", 4 players: nobody drops out; "Spiel beenden" ends it with a shared first place',
      (tester) async {
    final c = await _start(tester, lives: 3, unlimited: true, rolls: [[3, 1], [3, 1], [3, 1], [3, 1]]);
    // Anna bluffs four times, Ben catches her each time: 4 lives lost, she
    // is still in.
    for (var i = 0; i < 4; i++) {
      await _rollAndAnnounce(tester, 65);
      await _handOverTo(tester, 'Ben', 1);
      await _tap(tester, 'maexchen-doubt');
      expect(find.text('Geflunkert! Anna verliert ein Leben.'), findsWidgets);
      await _handOverTo(tester, 'Anna', 0);
    }
    expect(_game(c).lost, [4, 0, 0, 0]);
    expect(_game(c).isOver, isFalse);
    expect(_game(c).isSeatOut(0), isFalse);
    expect(tester.widget<Text>(_key('maexchen-lost-a')).data, '4');
    // "Spiel beenden" in the menu asks first.
    await _tap(tester, 'shell-menu');
    await _tap(tester, 'maexchen-end');
    expect(find.text('Spiel beenden?'), findsOneWidget);
    await _tap(tester, 'maexchen-end-cancel');
    expect(_game(c).isOver, isFalse);
    await _tap(tester, 'shell-menu');
    await _tap(tester, 'maexchen-end');
    await _tap(tester, 'maexchen-end-confirm');
    expect(_game(c).isOver, isTrue);
    expect(_key('result-dialog'), findsOneWidget);
    expect(find.descendant(of: _key('result-dialog'), matching: find.text('Gleichstand auf Platz 1!')), findsOneWidget);
    expect(find.text('Ihr habt das Spiel beendet. Wer am wenigsten Leben verloren hat, gewinnt.'), findsOneWidget);
    expect(find.descendant(of: _key('result-rank-0'), matching: find.text('4 Leben verloren')), findsOneWidget);
    expect(find.descendant(of: _key('result-rank-3'), matching: find.text('0 Leben verloren')), findsOneWidget);
    expect(find.descendant(of: _key('result-rank-1'), matching: find.byIcon(Icons.emoji_events)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Unbegrenzte Leben", 2 players: the tally, "Spiel beenden", the winner with the fewest lost',
      (tester) async {
    final c = await _start(tester, players: 2, unlimited: true, rolls: [[3, 1]]);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(tester.widget<Text>(_key('maexchen-lost-a')).data, '0');
    await _rollAndAnnounce(tester, 65);
    await tester.tap(_key('handover-continue'));
    await tester.pumpAndSettle();
    await _tap(tester, 'maexchen-doubt');
    await tester.tap(_key('handover-continue'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(_key('maexchen-lost-a')).data, '1');
    await _tap(tester, 'shell-menu');
    await _tap(tester, 'maexchen-end');
    await _tap(tester, 'maexchen-end-confirm');
    expect(c.game.result.winner, Player.b);
    expect(_key('result-dialog'), findsOneWidget);
    expect(find.text('Ben gewinnt!'), findsOneWidget);
    expect(_key('maexchen-tally'), findsOneWidget);
    expect(find.descendant(of: _key('maexchen-tally-row-0'), matching: find.text('1 Leben verloren')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Spiel beenden" only with "Unbegrenzte Leben"', (tester) async {
    await _start(tester, players: 3);
    await _tap(tester, 'shell-menu');
    expect(_key('maexchen-end'), findsNothing);
    expect(_key('shell-restart'), findsOneWidget);
  });

  testWidgets('start options: "Unbegrenzte Leben" greys the lives; with 4 players from "Wer spielt?"',
      (tester) async {
    await tester.pumpWidget(localizedApp(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(onPressed: () => openGameFromMenu(context, 'maexchen'), child: const Text('open')),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.widget<SegmentedButton<int>>(_key('maexchen-lives')).onSelectionChanged, isNotNull);
    await tester.tap(_key('maexchen-unlimited'));
    await tester.pumpAndSettle();
    expect(tester.widget<SegmentedButton<int>>(_key('maexchen-lives')).onSelectionChanged, isNull,
        reason: 'the lives do not matter');
    await tester.tap(_key('maexchen-options-next'));
    await tester.pumpAndSettle();
    expect(_key('hot-seat-pass-device-hint'), findsOneWidget);
    await tester.tap(_key('seat-players-4'));
    await tester.pumpAndSettle();
    await tester.tap(_key('hot-seat-names-ok'));
    await tester.pumpAndSettle();
    final c = controllerOf(tester);
    expect(c.config.players, 4);
    expect(c.config.maexchenUnlimited, isTrue);
    expect(find.byType(SeatGameScreen), findsOneWidget);
    expect(_key('maexchen-lost-d'), findsOneWidget);
    // The rules page lists the variant (the game is running with it on).
    await _tap(tester, 'shell-rules');
    expect(find.byType(RulesScreen), findsOneWidget);
    expect(_key('rules-house-unlimited'), findsOneWidget);
    expect(_key('rules-house-lives'), findsNothing);
    expect(_key('maexchen-rules-players'), findsOneWidget);
  });

  testWidgets('the rules page from the menu: "Unbegrenzte Leben" is not listed (off by default)', (tester) async {
    await tester.pumpWidget(localizedApp(const RulesScreen(gameId: 'maexchen')));
    await tester.pumpAndSettle();
    expect(_key('rules-house-unlimited'), findsNothing);
    expect(_key('rules-house-lives'), findsOneWidget);
  });

  test('the menu chip says 2–4', () {
    expect(offeredPlayers(specById('maexchen')!), (min: 2, max: 4));
    expect(playerCountGames, contains('maexchen'));
  });
}
