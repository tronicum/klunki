import 'package:flutter/widgets.dart';

/// Helpers for text that must stay left-to-right inside an RTL locale (ar, fa):
/// IP addresses, `host:port`, board coordinates (I18N-04).

/// Wraps [s] in a Unicode LTR isolate (U+2066 … U+2069), so the bidi algorithm
/// keeps it in one LTR run when it is embedded in a (possibly RTL) sentence,
/// e.g. `"Gast · 192.168.1.20:4747"` or a translated "Connecting to {host}".
String ltrIsolate(String s) => '\u2066$s\u2069';

/// [ltrIsolate] when the ambient direction is RTL, [s] unchanged otherwise
/// (LTR locales need no marks, and their strings stay byte-identical).
String bidiLtr(BuildContext context, String s) =>
    Directionality.maybeOf(context) == TextDirection.rtl ? ltrIsolate(s) : s;

/// Wraps [s] in a first-strong isolate (U+2068 … U+2069): the text inside
/// takes the direction of its own first strong letter and is kept in one run,
/// whatever the surrounding sentence is. For user-typed names (KLD-056).
String nameIsolate(String s) => '\u2068$s\u2069';

final RegExp _rtlLetter = RegExp('[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');

/// A player name ready to be embedded in a sentence: [nameIsolate]d when the
/// ambient direction is RTL or the name contains right-to-left letters (an
/// Arabic name in a German sentence), unchanged otherwise (a Latin name in
/// an LTR locale stays byte-identical).
String bidiName(BuildContext context, String name) =>
    Directionality.maybeOf(context) == TextDirection.rtl || _rtlLetter.hasMatch(name) ? nameIsolate(name) : name;

/// A [Text] laid out left-to-right, but aligned to the *ambient* start edge
/// (right in RTL), so it sits where the surrounding text would.
class LtrText extends StatelessWidget {
  final String data;
  final TextStyle? style;

  const LtrText(this.data, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return Text(
      data,
      style: style,
      textDirection: TextDirection.ltr,
      textAlign: rtl ? TextAlign.right : TextAlign.left,
    );
  }
}

/// Forces left-to-right layout for a game board / grid, so column order,
/// `Positioned(left: …)` overlays and tap coordinates match the engine's
/// indices in every locale. Text *around* the board keeps the app direction.
class LtrBoard extends StatelessWidget {
  final Widget child;

  const LtrBoard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.ltr, child: child);
}
