// Basic Klunki smoke test: build the root widget and assert the menu
// lists every game.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klunki_engine/klunki_engine.dart' show gameSpecs;
import 'l10n/l10n_test_utils.dart';

void main() {
  testWidgets('Klunki app shows its menu', (WidgetTester tester) async {
    await tester.pumpWidget(klunkiApp());

    for (final spec in gameSpecs) {
      expect(find.text(spec.title), findsOneWidget);
    }
  });

  testWidgets('debug console plays a Connect Four move', (WidgetTester tester) async {
    await tester.pumpWidget(klunkiApp());
    await tester.tap(find.text('Debug-Konsole'));
    await tester.pumpAndSettle();

    expect(find.textContaining('X to move'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('debug-input')), '3');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('|. . . X . . .|'), findsOneWidget);
    expect(find.textContaining('O to move'), findsOneWidget);
  });

  testWidgets('debug console menu runs the narrated demo', (WidgetTester tester) async {
    await tester.pumpWidget(klunkiApp());
    await tester.tap(find.text('Debug-Konsole'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('debug-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo: alle Spiele'));
    await tester.pumpAndSettle();

    expect(find.textContaining('DEMO: 4 Gewinnt'), findsOneWidget);
    expect(find.textContaining('Four in a row: X wins!'), findsOneWidget);
  });
}
