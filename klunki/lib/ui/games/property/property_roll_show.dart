import 'dart:math' as math;

import 'package:klunki_engine/klunki_engine.dart' hide Card;

/// How a roll is shown on the Baulöwe board (KLD-060, maintainer feedback on
/// build 2026110911): first the dice tumble, then the token walks square by
/// square to where it lands (passing Start on the way), and only then the
/// square's card, the buy question or the rent appear. The engine has
/// applied the move at once; this is presentation only, built from the
/// move's events and the position before it.
///
/// Times: [diceMs] for the dice, [stepMs] per square walked, a jump (to the
/// pause, "back to" cards) takes [jumpMs].
class PropertyRollShow {
  static const int diceMs = 750;
  static const int stepMs = 150;
  static const int jumpMs = 320;

  /// The seat that rolled.
  final int seat;

  /// The dice of the roll, or null (no roll in this move).
  final List<int>? dice;

  /// The squares the token stands on one after the other, the first the
  /// start; [jumps] marks the steps (index into [path]) that are a jump,
  /// not a walk.
  final List<int> path;
  final Set<int> jumps;

  PropertyRollShow({required this.seat, required this.dice, required this.path, this.jumps = const {}});

  /// The whole show in milliseconds.
  int get totalMs {
    var ms = dice == null ? 0 : diceMs;
    for (var i = 1; i < path.length; i++) {
      ms += jumps.contains(i) ? jumpMs : stepMs;
    }
    return ms;
  }

  Duration get duration => Duration(milliseconds: totalMs);

  /// Where the token is shown at [t] (0–1 of [totalMs]), and how high it
  /// hops (0–1, 0 on a square, 1 halfway between two).
  ({int square, double hop, bool rolling}) at(double t) {
    final ms = t.clamp(0.0, 1.0) * totalMs;
    final d = dice == null ? 0 : diceMs;
    if (ms < d) return (square: path.first, hop: 0, rolling: true);
    var left = ms - d;
    for (var i = 1; i < path.length; i++) {
      final step = jumps.contains(i) ? jumpMs : stepMs;
      if (left < step) {
        final f = left / step;
        // The token reaches the next square half way through its step.
        final sq = f < 0.5 ? path[i - 1] : path[i];
        return (square: sq, hop: jumps.contains(i) ? 0 : math.sin(f * math.pi), rolling: false);
      }
      left -= step;
    }
    return (square: path.last, hop: 0, rolling: false);
  }

  /// The square the walk ends on.
  int get target => path.last;

  /// The show of [move] (by [seat], who stood on [from] before it), or null
  /// when the move does not roll (buying, bids, building, …). [theme] tells
  /// which cards move back or jump.
  static PropertyRollShow? of({
    required int seat,
    required int from,
    required List<Map<String, dynamic>> events,
    required PropertyTheme theme,
  }) {
    List<int>? dice;
    final path = [from];
    final jumps = <int>{};
    PropertyCardKind? card;
    var cur = from;
    for (final e in events) {
      switch (e['type']) {
        case 'rolled':
          dice = (e['dice'] as List).cast<int>();
        case 'card':
          card = theme.card(e['id'])?.kind;
        case 'moved':
          final to = e['to'] as int;
          if (card == PropertyCardKind.backTo) {
            // "Zurück zu …": straight there, not once around the board.
            path.add(to);
            jumps.add(path.length - 1);
          } else if (card == PropertyCardKind.back) {
            for (var s = cur; s != to;) {
              s = (s + 39) % 40;
              path.add(s);
            }
          } else {
            for (var s = cur; s != to;) {
              s = (s + 1) % 40;
              path.add(s);
            }
          }
          cur = to;
          card = null;
        case 'toPause':
          if (cur != PropertyGame.pauseSquare) {
            path.add(PropertyGame.pauseSquare);
            jumps.add(path.length - 1);
            cur = PropertyGame.pauseSquare;
          }
      }
    }
    if (dice == null && path.length == 1) return null;
    return PropertyRollShow(seat: seat, dice: dice, path: path, jumps: jumps);
  }
}
