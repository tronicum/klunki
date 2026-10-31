// KLD-062: theme presets, palette lookup, contrast of the accent colours.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/ui/game_visuals.dart';
import 'package:klunki_engine/klunki_engine.dart' show appGameSpecs;

import '../l10n/l10n_test_utils.dart';

/// WCAG 2 contrast ratio.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final preset in KlunkiPreset.all) {
    for (final b in Brightness.values) {
      final p = preset.palette(b);
      final label = '${preset.id} ${b.name}';

      test('$label: app bar / tile accents carry their text at AA (4.5:1)', () {
        for (final id in [for (final s in appGameSpecs) s.id]) {
          final a = p.accent(id);
          expect(p.accents.containsKey(id), isTrue, reason: 'no accent for $id');
          expect(contrast(a.color, a.onColor), greaterThanOrEqualTo(4.5), reason: id);
          // Chevron/icon on the card: non-text contrast 3:1.
          expect(contrast(a.onSurface(b), p.card), greaterThanOrEqualTo(3), reason: '$id on card');
        }
        expect(contrast(p.networkAccent.color, p.networkAccent.onColor), greaterThanOrEqualTo(4.5));
      });

      test('$label: Quartett set headers take white text at AA', () {
        for (final s in 'ABCDEFGH'.split('')) {
          expect(contrast(p.quartett.set(s), Colors.white), greaterThanOrEqualTo(4.5), reason: 'set $s');
          expect(contrast(p.quartett.setText(s), p.quartett.cardFace), greaterThanOrEqualTo(3), reason: 'set $s text');
        }
        for (final c in [p.quartett.win, p.quartett.lose]) {
          expect(contrast(c, p.card), greaterThanOrEqualTo(4.5));
        }
      });

      test('$label: Schiffe hit / sunk / miss are distinguishable', () {
        final s = p.schiffe;
        expect(contrast(s.hit, s.hitBg), greaterThanOrEqualTo(3));
        expect(contrast(s.onSunk, s.sunk), greaterThanOrEqualTo(4.5));
        expect(contrast(s.ship, s.water), greaterThanOrEqualTo(3));
      });

      test('$label: the theme carries the palette', () {
        final theme = KlunkiTheme.build(preset, b);
        expect(theme.extension<KlunkiPalette>(), same(p));
        expect(theme.brightness, b);
      });
    }
  }

  test('every game has visuals (illustration, description)', () {
    for (final s in appGameSpecs) {
      expect(gameVisuals.containsKey(s.id), isTrue, reason: s.id);
      expect(gameVisuals[s.id]!.description!(deL10n), isNotEmpty);
    }
    expect(visualsOf('unknown-game'), same(GameVisuals.fallback));
  });

  testWidgets('KlunkiPalette.of falls back to the classic preset without the extension', (tester) async {
    late KlunkiPalette got;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Builder(builder: (context) {
        got = KlunkiPalette.of(context);
        return const SizedBox();
      }),
    ));
    expect(got, same(KlunkiPalette.classicDark));
  });

  testWidgets('menu shows each game\'s one-liner', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(klunkiApp());
    await tester.pumpAndSettle();
    expect(find.text(deL10n.menuDescConnect4), findsOneWidget);
    expect(find.text(deL10n.menuDescSchiffe), findsOneWidget);
    expect(find.text(deL10n.menuSectionHotSeat), findsOneWidget);
  });
}
