import 'package:flutter/material.dart';

/// Street names on the Baulöwe board (KLD-060, maintainer's pick of the two
/// tried variants: "one viewer"): every name reads from the bottom edge
/// (the top and bottom rows upright, both sides from bottom to top). Small
/// squares (a phone) show the theme's short form (`PropertySquare.shortName`),
/// big ones (a tablet, or the board pinched to zoom) the full name. One font
/// size for the whole board, the largest at which every name fits
/// ([propertyBoardNameSize]). Short forms: two lines broken at spaces (or
/// after the name's own hyphen); they are chosen to fit that way at 6 pt on
/// a phone (abbreviations read better than split words). Full names: up to
/// three lines, and a long word may break at a soft hyphen
/// ([propertyBreakable]) with a visible "-", so the size on a tablet is set
/// by the squares, not by the longest word (a name is only split when it
/// does not fit whole).

/// A square at least this wide (logical pixels, after zoom) shows the full
/// name; smaller ones the short form.
const double propertyFullNameCell = 52;

/// The smallest name size on screen (logical pixels, after zoom).
const double propertyMinNameSize = 5;

/// The largest name size on screen.
const double propertyMaxNameSize = 14;

const _softHyphen = '­';

/// [name] with break points (soft hyphens) in long compound words:
/// "Kurfürstendamm" → "Kurfürsten­damm", "Wühlischstr." → "Wühlisch­str.".
String propertyBreakable(String name) => name.replaceAllMapped(
    RegExp(r'(\S{3,})(straße|str\.|platz|pl\.|allee|damm|weg|gasse|park|see|insel|wiese|feld|strand|kai|warte|hof|turm|werk|brücke|bahnhof)(?=$|\s)'),
    (m) => '${m[1]}$_softHyphen${m[2]}');

/// The ways [text] may be written: as its words wrap, or broken at one of
/// its soft hyphens with a visible "-".
List<String> _layouts(String text) {
  final plain = text.replaceAll(_softHyphen, '');
  final out = [plain];
  for (var i = text.indexOf(_softHyphen); i >= 0; i = text.indexOf(_softHyphen, i + 1)) {
    out.add('${text.substring(0, i).replaceAll(_softHyphen, '')}-\n${text.substring(i + 1).replaceAll(_softHyphen, '')}');
  }
  return out;
}

/// The name style on [base] (the app's text style: its font is measured).
TextStyle propertyNameStyle(double size, Color color, [TextStyle? base]) => (base ?? const TextStyle())
    .merge(TextStyle(fontSize: size, height: 1.05, color: color, fontWeight: FontWeight.w600, letterSpacing: -0.1));

/// Whether [layout] fits [box] at [size]: [lines] at most, no word wider
/// than the box (it would be cut in the middle). A line may end at a space
/// or after a hyphen the name already has ("Simon-Dach-" / "Straße").
bool _fits(String layout, double size, Size box, TextStyle? base, int lines) {
  final style = propertyNameStyle(size, Colors.black, base);
  final p = TextPainter(
    text: TextSpan(text: layout, style: style),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: lines,
  )..layout(maxWidth: box.width - 0.5); // a little room for rounding
  if (p.didExceedMaxLines || p.height > box.height) return false;
  for (final word in layout.split(RegExp(r'\s|(?<=-)'))) {
    if (word.isEmpty) continue;
    final q = TextPainter(text: TextSpan(text: word, style: style), textDirection: TextDirection.ltr)..layout();
    if (q.width > box.width - 0.5) return false;
  }
  return true;
}

/// How [text] is written at [size] in [box]: the first layout that fits
/// (words before a hyphen break), else the plain text.
String propertyNameLayout(String text, double size, Size box, [TextStyle? base, int lines = 2]) {
  final all = _layouts(text);
  return all.firstWhere((l) => _fits(l, size, box, base, lines), orElse: () => all.first);
}

final Map<String, double> _sizes = {};

/// One name size for a whole board: the largest (0.25 steps, from [max]
/// down to [min]) at which every name in [names] fits [box] in [lines].
/// Without [hyphens] only at spaces (the short forms: a soft hyphen is no
/// reason for a bigger size); with them also split at a soft hyphen (the
/// full names). Kept per board, names and box (the board is built every
/// animation frame).
double propertyBoardNameSize(Iterable<String> names, Size box,
    {required double min, required double max, TextStyle? base, int lines = 2, bool hyphens = false}) {
  final list = names.toList();
  final key = '${list.join('|')}#${box.width.toStringAsFixed(2)}x${box.height.toStringAsFixed(2)}#$min-$max'
      '#${base?.fontFamily}#$lines#$hyphens';
  bool fits(String n, double size) => hyphens
      ? _layouts(n).any((l) => _fits(l, size, box, base, lines))
      : _fits(n.replaceAll(_softHyphen, ''), size, box, base, lines);
  return _sizes[key] ??= () {
    var size = max;
    while (size > min && !list.every((n) => fits(n, size))) {
      size -= 0.25;
    }
    return size < min ? min : size;
  }();
}

/// A name in a square's text area [box] at the board's [size], in the
/// style it was measured in ([base], else the surrounding one), placed at
/// [alignment] (the square's outer edge).
class PropertyFieldName extends StatelessWidget {
  final String text;
  final double size;
  final Size box;
  final Color color;
  final TextStyle? base;
  final Alignment alignment;

  /// At most this many lines (two for a short form, three for a full name).
  final int lines;
  const PropertyFieldName(
      {super.key,
      required this.text,
      required this.size,
      required this.box,
      required this.color,
      this.base,
      this.alignment = Alignment.center,
      this.lines = 2});

  @override
  Widget build(BuildContext context) {
    final base = this.base ?? DefaultTextStyle.of(context).style;
    // A board too small for the smallest size (an iPhone SE's) would cut
    // words in the middle: there only, a name that does not fit gets its
    // own smaller size.
    final size = _layouts(text).any((l) => _fits(l, this.size, box, base, lines))
        ? this.size
        : propertyBoardNameSize([text], box, min: 2, max: this.size, base: base, lines: lines, hyphens: true);
    return Align(
      alignment: alignment,
      child: Text(
        propertyNameLayout(text, size, box, base, lines),
        textAlign: TextAlign.center,
        maxLines: lines,
        overflow: TextOverflow.ellipsis,
        textScaler: TextScaler.noScaling,
        style: propertyNameStyle(size, color, base),
      ),
    );
  }
}
