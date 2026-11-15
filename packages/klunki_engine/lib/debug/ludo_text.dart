import 'dart:math';

import '../game.dart';
import '../ludo.dart';
import 'text_game.dart';

/// Text adapter for Rauswurf (KLD-131), the cross-and-circle race game.
/// Commands: `roll` (or `r`), then `move <pawn 1-4>` (or just the number).
class LudoText extends TextGame {
  LudoText({LudoGame? game}) : game = game ?? LudoGame();

  @override
  final LudoGame game;

  @override
  String get id => 'ludo';
  @override
  String get title => 'Rauswurf';
  @override
  String get moveHelp => 'roll | move <pawn 1-4> (or just the number)';

  @override
  LudoText restart() => LudoText(game: LudoGame(playerCount: game.playerCount, rules: game.rules));

  String _seatName(int s) => s < 2 ? playerName(Player.values[s]) : LudoGame.seatName(s);

  /// A pawn's place in words: H (house), T<field> (track field), L<n>
  /// (finish lane 1–4).
  static String place(LudoGame g, int seat, int progress) => progress == LudoGame.house
      ? 'H'
      : progress >= LudoGame.laneStart
          ? 'L${progress - LudoGame.laneStart + 1}'
          : 'T${g.trackFieldOf(seat, progress)}';

  @override
  String render() {
    final g = game;
    final b = StringBuffer();
    for (var s = 0; s < g.playerCount; s++) {
      final name = _seatName(s).padRight(6);
      if (g.isSeatOut(s)) {
        b.writeln('$name out');
        continue;
      }
      b.writeln('$name start T${g.trackFieldOf(s, 0)}: '
          '${[for (var i = 0; i < LudoGame.pawns; i++) '${i + 1}=${place(g, s, g.progressOf(s, i))}'].join(' ')}');
    }
    if (!g.isOver) {
      b.write('${_seatName(g.currentSeat)}: ');
      b.write(g.die == null
          ? 'roll the die${g.triesAllowed > 1 ? ' (try ${g.triesUsed + 1} of ${g.triesAllowed})' : ''}.'
          : 'die ${g.die}, move pawn ${g.movablePawns.map((p) => p + 1).join('/')}.');
    }
    return b.toString().trimRight();
  }

  @override
  Map<String, dynamic>? parse(String input) {
    final words = input.trim().toLowerCase().split(RegExp(r'\s+'));
    if (words.length == 1 && (words.first == 'roll' || words.first == 'r')) return LudoGame.rollMove;
    final n = int.tryParse(words.length == 2 && (words.first == 'move' || words.first == 'm') ? words[1] : words.first);
    if (n == null || (words.length > 1 && words.first != 'move' && words.first != 'm')) return null;
    return LudoGame.pawnMove(n - 1);
  }

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  @override
  String format(Map<String, dynamic> move) => switch (move['action']) {
        'roll' => 'roll',
        'move' => 'move ${(move['pawn'] as int) + 1}',
        final a => '$a',
      };

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final p = event.payload as Map;
    final who = _seatName(p['seat'] as int? ?? game.currentSeat);
    final s = switch (move['action']) {
      'roll' => '$who rolls ${p['rolled']}${p['passed'] == true ? ', no move.' : p['again'] == true ? ', rolls again.' : '.'}',
      'move' => '$who moves pawn ${(p['pawn'] as int) + 1} to '
          '${place(game, p['seat'] as int, p['to'] as int)}'
          '${p['captured'] is Map ? ' and sends ${_seatName((p['captured'] as Map)['seat'] as int)} home' : ''}.',
      _ => '$who: $move',
    };
    if (game.isOver) return '$s ${status()}';
    return s;
  }

  @override
  bool isHighlight(GameEvent event) => event.payload is Map && (event.payload as Map).containsKey('captured');

  /// A simple player: a capture first, then a pawn into the finish lane,
  /// then the pawn furthest behind that is not in the house.
  @override
  Map<String, dynamic> autoMove(Random rng) {
    final g = game;
    if (g.die == null) return LudoGame.rollMove;
    final options = g.options;
    final hit = options.where((o) => o.captures != null).firstOrNull;
    if (hit != null) return LudoGame.pawnMove(hit.pawn);
    final home = options.where((o) => o.to >= LudoGame.laneStart && o.from < LudoGame.laneStart).firstOrNull;
    if (home != null) return LudoGame.pawnMove(home.pawn);
    return LudoGame.pawnMove(options[rng.nextInt(options.length)].pawn);
  }
}
