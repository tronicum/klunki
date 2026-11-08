// KLD-058 insignia: every piece paints in every look, both armies, light
// and dark, at board and fight-card sizes, without exceptions; the app keeps
// the classic look until the maintainer chooses.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/ui/games/gostrategy/gostrategy_pieces.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';

void main() {
  test('the app keeps the classic look for now', () {
    expect(goPieceLook, GoPieceLook.classic);
  });

  for (final theme in [KlunkiTheme.light, KlunkiTheme.dark]) {
    testWidgets('all pieces, looks and armies paint (${theme.brightness.name})', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          Theme(
            data: theme,
            child: Material(
              child: Wrap(
                children: [
                  for (final look in GoPieceLook.values)
                    for (final owner in Player.values)
                      for (final size in [22.0, 31.0, 40.0, 64.0])
                        for (final number in [true, false]) ...[
                          for (final p in GoPiece.values)
                            GoPieceTile(
                              owner: owner,
                              piece: p,
                              size: size,
                              look: look,
                              rankNumber: number,
                              known: true,
                            ),
                          GoPieceTile(owner: owner, piece: null, size: size, look: look, moved: true),
                        ],
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(GoInsignia), findsNWidgets(3 * 2 * 4 * 2 * GoPiece.values.length));
    });
  }

  testWidgets('GoInsignia stands alone (rules pages) and the scope switches the look', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        Material(
          child: Column(
            children: [
              for (final p in GoPiece.values) GoInsignia(piece: p, color: Colors.black, size: 36),
              const GoPieceLookScope(
                look: GoPieceLook.insignia,
                child: GoPieceTile(owner: Player.a, piece: GoPiece.marshal, size: 40),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // 12 free-standing plus the one inside the scoped tile.
    expect(find.byType(GoInsignia), findsNWidgets(GoPiece.values.length + 1));
  });
}
