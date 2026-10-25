// Basic Klunki smoke test: build the root widget and assert the menu
// lists all three games.
import 'package:flutter_test/flutter_test.dart';

import 'package:klunki/app/klunki_app.dart';

void main() {
  testWidgets('Klunki app shows its menu', (WidgetTester tester) async {
    await tester.pumpWidget(const KlunkiApp());

    expect(find.text('4 Gewinnt'), findsOneWidget);
    expect(find.text('Mühle'), findsOneWidget);
    expect(find.text('Quartett'), findsOneWidget);
  });
}
