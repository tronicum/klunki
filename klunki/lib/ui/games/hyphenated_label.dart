import 'package:flutter/widgets.dart';

import '../engine_l10n.dart' show softHyphen;

/// A short label (a Quartett stat name) that never breaks a word in the
/// middle without a hyphen (KLD-092).
///
/// Flutter's line breaker cuts a word that is wider than the line anywhere
/// ("Höchstgesch / windigkeit") and does not draw a hyphen at a soft hyphen.
/// This widget lays the label out itself, in this order of preference:
///
/// 1. at full size, breaking only between words;
/// 2. at full size, also at the soft hyphens ([softHyphen]) of [text], with
///    a visible "-" at the end of the line ("Höchst- / geschwindigkeit");
/// 3. the same at 90 % and then [minScale] (modest scale-down);
/// 4. at [minScale] with any number of lines, shrinking further until every
///    piece fits (a word without soft hyphens that is still too wide).
///
/// 1–3 use at most [maxLines] lines. Text with CJK characters (which break
/// between any two characters anyway) is shown as is. The semantics label is
/// always the plain text without soft hyphens.
class HyphenatedLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final double minScale;

  const HyphenatedLabel(this.text, {super.key, this.style, this.maxLines = 2, this.minScale = 0.8});

  static final _cjk = RegExp(r'[\u2E80-\u9FFF\uAC00-\uD7AF\uF900-\uFAFF\uFF00-\uFFEF]');

  @override
  Widget build(BuildContext context) {
    final plain = text.replaceAll(softHyphen, '');
    final base = DefaultTextStyle.of(context).style.merge(style);
    if (_cjk.hasMatch(plain)) {
      return Text(plain, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final fit = layoutHyphenated(
          text,
          base,
          box.maxWidth,
          scaler: scaler,
          direction: direction,
          maxLines: maxLines,
          minScale: minScale,
        );
        return Text(
          fit.lines.join('\n'),
          semanticsLabel: plain,
          style: base.copyWith(fontSize: (base.fontSize ?? 14) * fit.scale),
          softWrap: false,
          overflow: TextOverflow.clip,
        );
      },
    );
  }
}

/// Result of [layoutHyphenated]: the lines (a hyphenated line ends in "-")
/// and the font scale they fit at.
typedef HyphenatedFit = ({List<String> lines, double scale});

/// Lays [text] (words separated by spaces, soft hyphens as optional breaks)
/// out into lines no wider than [maxWidth] with [style]; see
/// [HyphenatedLabel] for the order of preference.
HyphenatedFit layoutHyphenated(
  String text,
  TextStyle style,
  double maxWidth, {
  TextScaler scaler = TextScaler.noScaling,
  TextDirection direction = TextDirection.ltr,
  int maxLines = 2,
  double minScale = 0.8,
}) {
  final words = text.split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty || !maxWidth.isFinite) {
    return (lines: [text.replaceAll(softHyphen, '')], scale: 1.0);
  }
  final painter = TextPainter(textDirection: direction, textScaler: scaler, maxLines: 1);
  final size = style.fontSize ?? 14;
  double width(String s, double scale) {
    painter.text = TextSpan(
      text: s,
      style: style.copyWith(fontSize: size * scale),
    );
    painter.layout();
    return painter.width;
  }

  // A little slack against rounding: the Text below must not wrap again.
  final limit = maxWidth - 0.5;
  List<String>? fill(double scale, {required bool hyphenate, required int? lineLimit}) {
    bool fits(String s) => width(s, scale) <= limit;
    final lines = <String>[];
    var line = '';
    for (final word in words) {
      final candidate = line.isEmpty ? word.replaceAll(softHyphen, '') : '$line ${word.replaceAll(softHyphen, '')}';
      if (fits(candidate)) {
        line = candidate;
        continue;
      }
      var pieces = word.split(softHyphen);
      if (!hyphenate || pieces.length == 1) {
        // The word goes on a new line as a whole.
        if (line.isNotEmpty) lines.add(line);
        line = word.replaceAll(softHyphen, '');
        if (!fits(line)) return null;
        continue;
      }
      // Hyphenate: as many pieces as fit (plus "-") on the current line, the
      // rest on the next lines.
      while (pieces.isNotEmpty) {
        final rest = pieces.join();
        final joined = line.isEmpty ? rest : '$line $rest';
        if (fits(joined)) {
          line = joined;
          break;
        }
        var taken = 0;
        for (var k = pieces.length - 1; k >= 1; k--) {
          final head = pieces.take(k).join();
          if (fits(line.isEmpty ? '$head-' : '$line $head-')) {
            taken = k;
            break;
          }
        }
        if (taken == 0) {
          if (line.isEmpty) return null; // not even the first piece fits
          lines.add(line);
          line = '';
          continue;
        }
        final head = pieces.take(taken).join();
        lines.add(line.isEmpty ? '$head-' : '$line $head-');
        line = '';
        pieces = pieces.sublist(taken);
      }
    }
    if (line.isNotEmpty) lines.add(line);
    if (lineLimit != null && lines.length > lineLimit) return null;
    return lines;
  }

  final scales = <double>{1.0, if (minScale < 0.9) 0.9, minScale};
  for (final scale in scales) {
    for (final hyphenate in [false, true]) {
      final lines = fill(scale, hyphenate: hyphenate, lineLimit: maxLines);
      if (lines != null) return (lines: lines, scale: scale);
    }
  }
  // Last resort: more lines, then smaller still until every piece fits.
  for (var scale = minScale; scale > 0.3; scale -= 0.05) {
    final lines = fill(scale, hyphenate: true, lineLimit: null);
    if (lines != null) return (lines: lines, scale: scale);
  }
  return (lines: [text.replaceAll(softHyphen, '')], scale: minScale);
}
