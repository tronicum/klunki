// KLD-105: the play-mode links on the menu tiles. "Ein Gerät" (and the tile
// body) start the game on this device after "Wer spielt?"; "Mit anderen"
// opens "Raum starten" with the game chosen; games without network play
// only get "Ein Gerät"; no "Gerät weitergeben" on the tiles any more.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
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
    // The word tile game (debug preview, not a tile yet) is hot-seat only.
    expect(hotSeatOnlyGames, contains('wordtiles'));
    expect(_network('wordtiles'), findsNothing);
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

  testWidgets('"Mit anderen" opens "Raum starten" with the game chosen', (tester) async {
    await _pumpMenu(tester, size: const Size(800, 3000));
    for (final id in ['schiffe', 'quartett-sets']) {
      await tester.tap(_network(id));
      await tester.pumpAndSettle();
      // First visit: "Wie heißt du?" (KLD-056) comes first.
      if (find.byKey(const Key('player-name-ok')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('player-name-ok')));
        await tester.pumpAndSettle();
      }
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
}
