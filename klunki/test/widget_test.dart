// Basic Klunki smoke test: build the root widget and assert the menu
// lists all three games.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klunki/app/klunki_app.dart';

void main() {
  testWidgets('Klunki app shows its menu', (WidgetTester tester) async {
    await tester.pumpWidget(const KlunkiApp());

    expect(find.text('4 Gewinnt'), findsOneWidget);
    expect(find.text('Mühle'), findsOneWidget);
    expect(find.text('Quartett'), findsOneWidget);
  });

  testWidgets('debug console plays a Connect Four move', (WidgetTester tester) async {
    await tester.pumpWidget(const KlunkiApp());
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
    await tester.pumpWidget(const KlunkiApp());
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
