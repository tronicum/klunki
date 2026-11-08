// KLD-058 insignia: every piece paints for both armies, light and dark, at
// the sizes used in the app, without exceptions; badges can be left out.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/ui/games/gostrategy/gostrategy_pieces.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';

Finder _insignias() => find.byWidgetPredicate((w) => w is CustomPaint && w.painter is GoInsigniaPainter);

void main() {
  for (final theme in [KlunkiTheme.light, KlunkiTheme.dark]) {
    testWidgets('all pieces and armies paint (${theme.brightness.name})', (tester) async {
      const sizes = [22.0, 24.0, 31.0, 40.0, 64.0];
      await tester.pumpWidget(
        localizedApp(
          Theme(
            data: theme,
            child: Material(
              child: SingleChildScrollView(
                child: Wrap(
                  children: [
                    for (final owner in Player.values)
                      for (final size in sizes) ...[
                        for (final p in GoPiece.values) GoPieceTile(owner: owner, piece: p, size: size, known: true),
                        GoPieceTile(owner: owner, piece: null, size: size, moved: true),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(_insignias(), findsNWidgets(2 * sizes.length * GoPiece.values.length));
      // Rank badges on the ten ranked pieces, eye badges on all twelve.
      expect(find.byKey(goRankBadgeKey), findsNWidgets(2 * sizes.length * 10));
      expect(find.byKey(goKnownMarkerKey), findsNWidgets(2 * sizes.length * 12));
    });
  }

  testWidgets('the small legend tiles leave the badges out', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        const Row(
          children: [
            GoPieceTile(owner: Player.a, piece: GoPiece.marshal, size: 22, known: true, badges: false),
            GoPieceTile(owner: Player.a, piece: GoPiece.marshal, size: 26, known: true),
          ],
        ),
      ),
    );
    expect(find.byKey(goRankBadgeKey), findsOneWidget);
    expect(find.byKey(goKnownMarkerKey), findsOneWidget);
  });

  testWidgets('GoInsignia stands alone (rules pages)', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        Material(
          child: Column(
            children: [for (final p in GoPiece.values) GoInsignia(piece: p, color: Colors.black, size: 36)],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(_insignias(), findsNWidgets(GoPiece.values.length));
  });
}
