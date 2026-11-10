import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:klunki/ui/games/property/property_names.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

// The street names on the Baulöwe board (KLD-060). The test font draws
// every glyph as a square of the font size, so widths are easy to count.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('soft hyphens go before the street word of a compound', () {
    expect(propertyBreakable('Wühlischstraße'), 'Wühlisch­straße');
    expect(propertyBreakable('Revaler Straße'), 'Revaler Straße', reason: 'two words: no break inside');
  });

  test('a name breaks at spaces; a hyphen only when a word does not fit', () {
    const box = Size(60, 30);
    expect(propertyNameLayout('Revaler Straße', 6, box), 'Revaler Straße', reason: 'wraps at the space');
    // 14 letters at 6 = 84 > 60: split at the soft hyphen, with a visible "-".
    expect(propertyNameLayout(propertyBreakable('Wühlischstraße'), 6, box), 'Wühlisch-\nstraße');
    expect(propertyNameLayout(propertyBreakable('Wühlischstraße'), 4, box), 'Wühlischstraße', reason: 'fits in one');
  });

  test("a line may end after the name's own hyphen", () {
    // "Simon-Dach-" (11) and "Straße" fit 70 at 6; one word of 17 does not.
    expect(propertyBoardNameSize(['Simon-Dach-Straße'], const Size(70, 30), min: 2, max: 6), 6);
    expect(propertyBoardNameSize(['SimonxDachxStraße'], const Size(70, 30), min: 2, max: 6), lessThan(6));
  });

  test('one size for the whole board, set by the longest word, never by hyphens', () {
    const box = Size(60, 30);
    final size = propertyBoardNameSize(['Ponyhof', 'Wühlisch­straße'], box, min: 2, max: 12);
    expect(size, lessThanOrEqualTo(60 / 14));
    expect(size, greaterThan(60 / 14 - 0.5));
    expect(propertyBoardNameSize(['Ponyhof'], box, min: 2, max: 12), greaterThan(size));
    expect(propertyBoardNameSize(['Wühlischstraße'], box, min: 5, max: 12), 5, reason: 'never below the minimum');
  });

  test('every short name on the board is one the theme chose: no text rule', () {
    for (final theme in PropertyTheme.builtIn) {
      for (final sq in theme.squares) {
        if (sq.short case final short?) expect(short.contains('­'), isFalse, reason: '${theme.id} ${sq.index}');
      }
    }
  });
}
