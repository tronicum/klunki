import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/games/muehle_screen.dart';
import 'package:klunki/ui/games/schiffe/schiffe_describe.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import 'l10n_test_utils.dart';

const _en = Locale('en');

void main() {
  testWidgets('menu in English', (tester) async {
    await tester.pumpWidget(klunkiApp(locale: _en));
    await tester.pumpAndSettle();

    expect(find.text('Choose a game'), findsOneWidget);
    for (final title in ['Four in a Row', 'Mill', 'Quartett (Trumps)', 'Quartett (Sets)', 'Sink the Fleet', 'Wordsmith']) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('One device'), findsNWidgets(appGameSpecs.length));
    // Plus the debug preview games' links (none since KLD-094 step 7).
    expect(find.text('With others'),
        findsNWidgets(networkGameSpecs.length + previewGames.where((id) => !hotSeatOnlyGames.contains(id)).length));
    expect(find.text('Pass the device'), findsNothing);
    expect(find.text('Debug console'), findsOneWidget);
    expect(find.text('Wähle ein Spiel'), findsNothing);
    expect(find.text('4 Gewinnt'), findsNothing);
  });

  testWidgets('Four in a Row screen in English: shell, hint and history', (tester) async {
    await tester.pumpWidget(klunkiApp(locale: _en));
    await tester.tap(find.text('Four in a Row'));
    await tester.pumpAndSettle();
    expect(find.text('Who is playing?'), findsOneWidget);
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Four in a Row')), findsOneWidget);
    expect(find.text('Anna to move'), findsOneWidget);
    expect(find.text('Tap a column'), findsOneWidget);
    expect(find.byTooltip('Undo move'), findsOneWidget);
    expect(find.byTooltip('Moves'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shell-menu')));
    await tester.pumpAndSettle();
    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Player names'), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('c4-column-3')));
    await tester.pumpAndSettle();
    expect(find.text('Ben to move'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shell-history')));
    await tester.pumpAndSettle();
    expect(find.text('Anna: Column 4'), findsOneWidget);
  });

  testWidgets('Sink the Fleet setup in English', (tester) async {
    final c = GameController.hotSeat(const GameConfig('schiffe', seed: 1));
    addTearDown(c.dispose);
    await tester.pumpWidget(localizedApp(buildGameScreen(c), locale: _en));
    await tester.pump();
    await tester.pump();

    expect(find.text('Random'), findsOneWidget);
    expect(find.text('Horizontal'), findsOneWidget);
    expect(find.textContaining('Tap the sea to place the ship.'), findsOneWidget);
    expect(find.textContaining('Anna is placing'), findsOneWidget);
  });

  test('move descriptions follow the AppLocalizations passed in', () async {
    final c = GameController.hotSeat(const GameConfig('muehle'));
    addTearDown(c.dispose);
    await c.submit({'action': 'place', 'to': 5});
    expect(describeMuehleMove(enL10n, c.moves, c.moves.last), 'places on 5');
    expect(describeMuehleMove(deL10n, c.moves, c.moves.last), 'setzt auf 5');

    final s = GameController.hotSeat(const GameConfig('schiffe', seed: 1));
    addTearDown(s.dispose);
    await s.submit({'action': 'autoplace', 'seed': 7});
    expect(describeSchiffeMove(enL10n, s.moves.last), startsWith('places '));
    expect(describeSchiffeMove(deL10n, s.moves.last), startsWith('platziert '));
  });
}
