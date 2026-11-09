// KLD-105: the play-mode links on the menu tiles. "Ein Gerät" (and the tile
// body) start the game on this device after "Wer spielt?"; "Mit anderen"
// asks "Raum starten" (with the game chosen) or "Raum beitreten" (KLD-111);
// games without network play only get "Ein Gerät"; no "Gerät weitergeben"
// on the tiles any more.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' show appGameSpecs;

import '../l10n/l10n_test_utils.dart';

Future<void> _pumpMenu(WidgetTester tester, {Size size = const Size(375, 3000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(klunkiApp());
  await tester.pumpAndSettle();
}

Finder _local(String id) => find.byKey(Key('menu-$id-local'));
Finder _network(String id) => find.byKey(Key('menu-$id-network'));
final _choice = find.byKey(const Key('menu-room-choice'));
final _choiceStart = find.byKey(const Key('menu-room-choice-start'));
final _choiceJoin = find.byKey(const Key('menu-room-choice-join'));

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// "Mit anderen" (tile or preview link) shows the choice sheet titled with
/// [title]; then [button] in it.
Future<void> _withOthers(WidgetTester tester, Finder link, String title, Finder button) async {
  await tester.ensureVisible(link);
  await tester.tap(link);
  await tester.pumpAndSettle();
  expect(_choice, findsOneWidget);
  expect(tester.widget<Text>(find.byKey(const Key('menu-room-choice-title'))).data, title);
  expect(find.descendant(of: _choiceStart, matching: find.text('Raum starten')), findsOneWidget);
  expect(find.descendant(of: _choiceStart, matching: find.text('Andere kommen mit dem Raumcode dazu')), findsOneWidget);
  expect(find.descendant(of: _choiceJoin, matching: find.text('Raum beitreten')), findsOneWidget);
  expect(find.descendant(of: _choiceJoin, matching: find.text('Code scannen oder eintippen')), findsOneWidget);
  // "Raum starten" first and prominent, "Raum beitreten" below, both full width.
  final start = tester.getRect(_choiceStart), join = tester.getRect(_choiceJoin);
  expect(start.bottom, lessThanOrEqualTo(join.top));
  expect(start.width, join.width);
  expect(start.width, greaterThan(tester.getSize(_choice).width - 40));
  await tester.tap(button);
  // Not pumpAndSettle: the join screen keeps a progress indicator running.
  await _frames(tester);
  expect(_choice, findsNothing);
  if (find.byKey(const Key('player-name-ok')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('player-name-ok')));
    await _frames(tester);
  }
}

void main() {
  setUp(() => SeenTips.shared
    ..markFirst(SeenTips.maumauIntro)
    ..markFirst(SeenTips.dicesheetIntro)
    ..markFirst(SeenTips.propertyIntro));
  testWidgets('network games (chess too) get both links, hot-seat-only games only "Ein Gerät"', (tester) async {
    await _pumpMenu(tester);
    for (final spec in appGameSpecs) {
      final tile = find.byKey(Key('menu-${spec.id}'));
      expect(find.descendant(of: tile, matching: _local(spec.id)), findsOneWidget, reason: spec.id);
      expect(find.descendant(of: _local(spec.id), matching: find.text('Ein Gerät')), findsOneWidget);
      expect(find.descendant(of: _local(spec.id), matching: find.byIcon(Icons.smartphone)), findsOneWidget);
      final online = !hotSeatOnlyGames.contains(spec.id);
      expect(_network(spec.id), online ? findsOneWidget : findsNothing, reason: spec.id);
      if (online) {
        expect(find.descendant(of: _network(spec.id), matching: find.text('Mit anderen')), findsOneWidget);
        expect(find.descendant(of: _network(spec.id), matching: find.byIcon(Icons.wifi)), findsOneWidget);
      }
    }
    // KLD-059 step 3: chess plays over the network too.
    expect(_local('chess'), findsOneWidget);
    expect(_network('chess'), findsOneWidget);
    expect(hotSeatOnlyGames, isNot(contains('chess')));
    // KLD-094 step 6: the word tile game plays over the network too; step
    // 7: released, a tile with both links.
    expect(_local('wordtiles'), findsOneWidget);
    expect(_network('wordtiles'), findsOneWidget);
    expect(hotSeatOnlyGames, isNot(contains('wordtiles')));
    // KLD-118: Mau-Mau and KLD-121: Mäxchen are one device only for now.
    expect(_local('maexchen'), findsOneWidget);
    expect(_network('maexchen'), findsNothing);
    // KLD-119: Ausgewürfelt is for 2–4 players at one table.
    expect(_network('dicesheet'), findsNothing);
    expect(_network('property'), findsNothing);
    expect(hotSeatOnlyGames, {'maumau', 'maexchen', 'dicesheet', 'property'});
  });

  testWidgets('no "Gerät weitergeben" claim and no eye-off badge on the tiles', (tester) async {
    await _pumpMenu(tester);
    expect(find.text('Gerät weitergeben'), findsNothing);
    expect(find.textContaining('weiter'), findsNothing);
    for (final spec in appGameSpecs) {
      expect(find.descendant(of: find.byKey(Key('menu-${spec.id}')), matching: find.byIcon(Icons.visibility_off_outlined)),
          findsNothing, reason: spec.id);
    }
    // The room section stays.
    expect(find.text('Mit anderen Geräten spielen'), findsOneWidget);
    expect(find.byKey(const Key('menu-room-start')), findsOneWidget);
    expect(find.byKey(const Key('menu-room-join')), findsOneWidget);
  });

  testWidgets('links are at least 48 px high and lie inside their tile', (tester) async {
    await _pumpMenu(tester);
    for (final spec in appGameSpecs) {
      final tile = tester.getRect(find.byKey(Key('menu-${spec.id}')));
      for (final link in [_local(spec.id), _network(spec.id)]) {
        if (link.evaluate().isEmpty) continue;
        final r = tester.getRect(link);
        expect(r.height, greaterThanOrEqualTo(48), reason: '${spec.id} $link');
        expect(tile.contains(r.topLeft) && tile.contains(r.bottomRight - const Offset(1, 1)), isTrue);
      }
    }
  });

  testWidgets('"Mit anderen" -> "Raum starten" opens the room screen with the game chosen', (tester) async {
    await _pumpMenu(tester, size: const Size(800, 3000));
    for (final (id, title) in [('schiffe', 'Schiffe versenken'), ('quartett-sets', 'Quartett (Sets)')]) {
      await _withOthers(tester, _network(id), title, _choiceStart);
      final screen = tester.widget<PairingScreen>(find.byType(PairingScreen));
      expect(screen.mode, RoomMode.start);
      expect(screen.gameId, id);
      // The game is shown, not asked for.
      expect(find.byKey(const Key('pair-game-fixed')), findsOneWidget);
      expect(find.byKey(const Key('pair-game-connect4')), findsNothing);
      expect(find.text('Spiel wählen'), findsNothing);
      expect(find.byKey(const Key('pair-deck')), id == 'quartett-sets' ? findsOneWidget : findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
    // "Raum starten" in the section below still asks for the game.
    await tester.tap(find.byKey(const Key('menu-room-start')));
    await tester.pumpAndSettle();
    expect(tester.widget<PairingScreen>(find.byType(PairingScreen)).gameId, isNull);
    expect(find.byKey(const Key('pair-game-connect4')), findsOneWidget);
    expect(find.byKey(const Key('pair-game-fixed')), findsNothing);
  });

  testWidgets('KLD-111: "Mit anderen" -> "Raum beitreten" opens the join screen (the host picks the game)',
      (tester) async {
    await _pumpMenu(tester, size: const Size(800, 3000));
    await _withOthers(tester, _network('chess'), 'Schach', _choiceJoin);
    // The camera scanner opens on top of it right away (KLD-098).
    final joinScreen = find.byType(PairingScreen, skipOffstage: false);
    final screen = tester.widget<PairingScreen>(joinScreen);
    expect(screen.mode, RoomMode.join);
    expect(screen.gameId, isNull);
    Navigator.of(tester.element(joinScreen)).popUntil((r) => r.isFirst);
    await _frames(tester);
    expect(find.byKey(const Key('menu-chess')), findsOneWidget);
    // Wortgewandt's tile too (KLD-094 step 7).
    await _withOthers(tester, _network('wordtiles'), 'Wortgewandt', _choiceJoin);
    expect(tester.widget<PairingScreen>(joinScreen).mode, RoomMode.join);
  });

  testWidgets('KLD-111: closing the choice sheet goes nowhere; the menu works again', (tester) async {
    await _pumpMenu(tester, size: const Size(800, 3000));
    await tester.tap(_network('connect4'));
    await tester.pumpAndSettle();
    expect(_choice, findsOneWidget);
    await tester.tapAt(const Offset(400, 20)); // the barrier above the sheet
    await tester.pumpAndSettle();
    expect(_choice, findsNothing);
    expect(find.byType(PairingScreen), findsNothing);
    await _withOthers(tester, _network('connect4'), '4 Gewinnt', _choiceStart);
    expect(tester.widget<PairingScreen>(find.byType(PairingScreen)).gameId, 'connect4');
  });

  testWidgets('Wortgewandt tile: "Mit anderen" -> "Raum starten" with the game and its start options',
      (tester) async {
    await _pumpMenu(tester, size: const Size(800, 3000));
    expect(find.byKey(const Key('menu-preview-wordtiles-network')), findsNothing);
    final link = _network('wordtiles');
    expect(link, findsOneWidget);
    expect(find.descendant(of: link, matching: find.text('Mit anderen')), findsOneWidget);
    await _withOthers(tester, link, 'Wortgewandt', _choiceStart);
    final screen = tester.widget<PairingScreen>(find.byType(PairingScreen));
    expect(screen.mode, RoomMode.start);
    expect(screen.gameId, 'wordtiles');
    expect(find.byKey(const Key('pair-game-fixed')), findsOneWidget);
    // The host chooses tile language and word list, as on one device.
    expect(find.byKey(const Key('pair-wordtiles')), findsOneWidget);
    expect(find.byKey(const Key('pair-wordtiles-tiles-de')), findsOneWidget);
    expect(find.byKey(const Key('pair-wordtiles-tiles-en')), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('pair-wordtiles-dict'))).value, isTrue);
    await tester.tap(find.byKey(const Key('pair-wordtiles-dict')));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('pair-wordtiles-dict'))).value, isFalse);
  });

  testWidgets('"Ein Gerät" and the tile body start the game after "Wer spielt?"', (tester) async {
    await _pumpMenu(tester);
    for (final key in ['menu-connect4-local', 'menu-connect4-tile']) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hot-seat-start-dialog')), findsOneWidget, reason: key);
      await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shell-status')), findsOneWidget, reason: key);
      expect(find.text('Anna ist am Zug'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('menu-connect4')), findsOneWidget);
    }
  });

  testWidgets('a double tap starts one game only', (tester) async {
    await _pumpMenu(tester);
    // Taps that arrive before the dialog is on screen (the callbacks
    // directly: a test tap would already hit the new route's barrier).
    VoidCallback onTap(Finder link) =>
        tester.widget<InkWell>(find.descendant(of: link, matching: find.byType(InkWell), matchRoot: true).first).onTap!;
    onTap(_local('connect4'))();
    onTap(_local('connect4'))();
    onTap(find.byKey(const Key('menu-connect4-tile')))();
    onTap(_network('connect4'))();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hot-seat-start-dialog')), findsOneWidget);
    expect(find.byType(PairingScreen), findsNothing);
    await tester.tap(find.byKey(const Key('hot-seat-names-cancel')));
    await tester.pumpAndSettle();
    // Cancelled: the menu works again.
    await tester.tap(_local('connect4'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hot-seat-start-dialog')), findsOneWidget);
  });

  testWidgets('"Wer spielt?" explains passing the device for hidden-information games only', (tester) async {
    await _pumpMenu(tester);
    for (final spec in appGameSpecs) {
      await tester.tap(_local(spec.id));
      await tester.pumpAndSettle();
      if (spec.usesDeck) {
        // Quartett asks for the deck first.
        await tester.tap(find.byKey(const Key('quartett-deck-play')));
        await tester.pumpAndSettle();
      }
      if (spec.id == 'wordtiles') {
        // Wortgewandt: its start options first (KLD-094).
        await tester.tap(find.byKey(const Key('wordtiles-options-next')));
        await tester.pumpAndSettle();
      }
      if (spec.id == 'maumau') {
        // Mau-Mau: its house rules first (KLD-118).
        await tester.tap(find.byKey(const Key('maumau-options-next')));
        await tester.pumpAndSettle();
      }
      if (spec.id == 'maexchen') {
        // Mäxchen: lives and "Mäxchen doppelt" first (KLD-121).
        await tester.tap(find.byKey(const Key('maexchen-options-next')));
        await tester.pumpAndSettle();
      }
      if (spec.id == 'dicesheet') {
        // Ausgewürfelt: the house rule first (KLD-119).
        await tester.tap(find.byKey(const Key('dicesheet-options-next')));
        await tester.pumpAndSettle();
      }
      if (spec.id == 'property') {
        // Baulöwe: board, length and house rules first (KLD-060).
        await tester.tap(find.byKey(const Key('property-options-next')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('hot-seat-start-dialog')), findsOneWidget, reason: spec.id);
      expect(find.byKey(const Key('hot-seat-pass-device-hint')), spec.hiddenInformation ? findsOneWidget : findsNothing,
          reason: spec.id);
      if (spec.hiddenInformation) {
        expect(find.text('Ihr gebt das Gerät weiter – was verdeckt ist, bleibt geheim.'), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('hot-seat-names-cancel')));
      await tester.pumpAndSettle();
    }
  });

  // KLD-097: the header shows the app icon (c5-zoom-b-fill, the bundled PNG as
  // on the About screen) next to "Klunki" in one slim row, and the games
  // start right below it.
  testWidgets('slim header with the app icon; the first game tile starts high up', (tester) async {
    await _pumpMenu(tester, size: const Size(375, 667));
    final icon = find.descendant(of: find.byKey(const Key('menu-app-icon')), matching: find.byType(Image));
    expect((tester.widget<Image>(icon).image as AssetImage).assetName, 'assets/icon/app_icon.png');
    expect(tester.getSize(icon), const Size.square(30));
    // "Klunki Spielesammlung" does not fit next to the buttons here (the
    // wide test font): "Klunki" with "Spielesammlung" smaller below, whole.
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Klunki')), findsOneWidget);
    expect(find.byKey(const Key('menu-title-sub')), findsOneWidget);
    expect(find.text('Spielesammlung'), findsOneWidget);
    expect(tester.getRect(find.byKey(const Key('menu-title-sub'))).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(AppBar)).bottom));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppBar)).height, 48);
    expect(find.text('Wähle ein Spiel'), findsOneWidget);
    // Was 136 (test font) with the big headline and the 56 px app bar.
    expect(tester.getTopLeft(find.byKey(Key('menu-${appGameSpecs.first.id}'))).dy, lessThanOrEqualTo(82));
  });

  testWidgets('a wide screen: "Klunki Spielesammlung" on one line', (tester) async {
    await _pumpMenu(tester, size: const Size(1200, 900));
    expect(find.text('Klunki Spielesammlung', findRichText: true), findsOneWidget);
    expect(find.byKey(const Key('menu-title-sub')), findsNothing);
  });
}
