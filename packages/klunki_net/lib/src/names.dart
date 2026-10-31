import 'package:klunki_engine/klunki_engine.dart';

/// Longest player name, in Unicode code points (after [sanitizePlayerName]).
const int maxPlayerNameLength = 20;

/// Cleans a player name (a handle typed by a user, or received from the
/// other side of a session), so it is safe to show inside a sentence:
///
///  * whitespace of any kind (tabs, line breaks, no-break and ideographic
///    spaces, U+2028/U+2029) becomes a single space; leading and trailing
///    space is trimmed;
///  * other control characters (C0, DEL, C1), bidi controls (LRM, RLM, ALM,
///    LRE/RLE/PDF/LRO/RLO, LRI/RLI/FSI/PDI), the BOM, lone surrogates and
///    the noncharacters U+FFFE/U+FFFF are dropped (ZWJ/ZWNJ stay: Persian
///    and emoji need them);
///  * the result is cut to [maxLength] code points.
///
/// Any script is fine. Returns `''` when nothing is left; callers pick the
/// fallback (the host uses the player mark, "X" or "O").
String sanitizePlayerName(String? raw, {int maxLength = maxPlayerNameLength}) {
  if (raw == null) return '';
  final out = <int>[];
  var space = false;
  for (final r in raw.runes) {
    if (_isSpace(r)) {
      space = out.isNotEmpty;
      continue;
    }
    if (_isDropped(r)) continue;
    if (space) {
      if (out.length + 1 >= maxLength) break; // no trailing space
      out.add(0x20);
      space = false;
    }
    if (out.length >= maxLength) break;
    out.add(r);
  }
  return String.fromCharCodes(out);
}

/// [sanitizePlayerName], or the mark of [player] ("X" for A, "O" for B) when
/// nothing is left.
String playerNameOr(String? raw, Player player) {
  final s = sanitizePlayerName(raw);
  return s.isEmpty ? markOf(player) : s;
}

/// The player mark the apps and the CLI show: A is "X", B is "O".
String markOf(Player p) => p == Player.a ? 'X' : 'O';

bool _isSpace(int r) =>
    r == 0x20 ||
    (r >= 0x09 && r <= 0x0D) ||
    r == 0x85 ||
    r == 0xA0 ||
    r == 0x1680 ||
    (r >= 0x2000 && r <= 0x200A) ||
    r == 0x2028 ||
    r == 0x2029 ||
    r == 0x202F ||
    r == 0x205F ||
    r == 0x3000;

bool _isDropped(int r) =>
    r < 0x20 || // remaining C0 controls
    (r >= 0x7F && r <= 0x9F) || // DEL + C1
    r == 0x061C || // ALM
    r == 0x200E ||
    r == 0x200F || // LRM, RLM
    (r >= 0x202A && r <= 0x202E) || // LRE RLE PDF LRO RLO
    (r >= 0x2066 && r <= 0x2069) || // LRI RLI FSI PDI
    r == 0xFEFF || // BOM / zero-width no-break space
    (r >= 0xD800 && r <= 0xDFFF) || // lone surrogates
    r == 0xFFFE ||
    r == 0xFFFF;
