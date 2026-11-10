import 'package:flutter/material.dart';

/// Street names on the Baulöwe board (KLD-060, maintainer's pick of the two
/// tried variants: "one viewer"): every name reads from the bottom edge
/// (the top and bottom rows upright, both sides from bottom to top). Small
/// squares (a phone) show the theme's short form (`PropertySquare.shortName`),
/// big ones (a tablet, or the board pinched to zoom) the full name. One font
/// size for the whole board (the largest at which every name fits in two
/// lines broken at spaces, [propertyBoardNameSize]). The short forms are
/// chosen to fit that way (abbreviations read better than split words); only
/// a full name whose word does not fit even at the smallest size breaks at a
/// soft hyphen ([propertyBreakable]), with a visible "-".

/// A square at least this wide (logical pixels, after zoom) shows the full
/// name; smaller ones the short form.
const double propertyFullNameCell = 52;

/// The smallest name size on screen (logical pixels, after zoom).
const double propertyMinNameSize = 5;

/// The largest name size on screen.
const double propertyMaxNameSize = 12;

const _softHyphen = '­';

/// [name] with break points (soft hyphens) in long compound words:
/// "Kurfürstendamm" → "Kurfürsten­damm", "Wühlischstr." → "Wühlisch­str.".
String propertyBreakable(String name) => name.replaceAllMapped(
    RegExp(r'(\S{3,})(straße|str\.|platz|pl\.|allee|damm|weg|gasse|park|see|insel|wiese|feld|strand|kai|warte|hof|turm|werk|brücke|bahnhof)(?=$|\s)'),
    (m) => '${m[1]}$_softHyphen${m[2]}');

/// The ways [text] may be written in at most two lines: as its words wrap,
/// or broken at one of its soft hyphens with a visible "-".
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

/// Whether [layout] fits [box] at [size]: two lines at most, no word wider
/// than the box (it would be cut in the middle).
bool _fits(String layout, double size, Size box, TextStyle? base) {
  final style = propertyNameStyle(size, Colors.black, base);
  final p = TextPainter(
    text: TextSpan(text: layout, style: style),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 2,
  )..layout(maxWidth: box.width - 0.5); // a little room for rounding
  if (p.didExceedMaxLines || p.height > box.height) return false;
  for (final word in layout.split(RegExp(r'\s'))) {
    if (word.isEmpty) continue;
    final q = TextPainter(text: TextSpan(text: word, style: style), textDirection: TextDirection.ltr)..layout();
    if (q.width > box.width - 0.5) return false;
  }
  return true;
}

/// How [text] is written at [size] in [box]: the first layout that fits
/// (words before a hyphen break), else the plain text.
String propertyNameLayout(String text, double size, Size box, [TextStyle? base]) {
  final all = _layouts(text);
  return all.firstWhere((l) => _fits(l, size, box, base), orElse: () => all.first);
}

final Map<String, double> _sizes = {};

/// One name size for a whole board: the largest (0.25 steps, from [max]
/// down to [min]) at which every name in [names] fits [box] broken at
/// spaces only (soft hyphens are a last resort, not a reason for a bigger
/// size). Kept per board, names and box (the board is built every
/// animation frame).
double propertyBoardNameSize(Iterable<String> names, Size box,
    {required double min, required double max, TextStyle? base}) {
  final list = names.toList();
  final key = '${list.join('|')}#${box.width.toStringAsFixed(2)}x${box.height.toStringAsFixed(2)}#$min-$max'
      '#${base?.fontFamily}';
  return _sizes[key] ??= () {
    var size = max;
    while (size > min && !list.every((n) => _fits(n.replaceAll(_softHyphen, ''), size, box, base))) {
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
  const PropertyFieldName(
      {super.key,
      required this.text,
      required this.size,
      required this.box,
      required this.color,
      this.base,
      this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) {
    final base = this.base ?? DefaultTextStyle.of(context).style;
    return Align(
      alignment: alignment,
      child: Text(
        propertyNameLayout(text, size, box, base),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textScaler: TextScaler.noScaling,
        style: propertyNameStyle(size, color, base),
      ),
    );
  }
}
