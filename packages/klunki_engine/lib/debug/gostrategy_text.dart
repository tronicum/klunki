import 'dart:math';

import '../game.dart';
import '../gostrategy.dart';
import 'text_game.dart';

/// Shows only what the player to move may see (hot-seat view): their own
/// army, enemy pieces as `O?` / `X?` until revealed.
///
/// Squares are named like a chess board: files `a`–`j` left to right,
/// ranks `1`–`10` from X's back row (bottom) to O's back row (top).
class GoStrategyText extends TextGame {
  /// [game] wraps an existing engine instance (e.g. a network session's).
  GoStrategyText({GoStrategyGame? game}) : game = game ?? GoStrategyGame();

  @override
  final GoStrategyGame game;

  @override
  String get id => 'gostrategy';
  @override
  String get title => 'GoStrategy';
  @override
  String get moveHelp => '"setup [seed]" places your 40 pieces at random (seeded); '
      '<from> <to> moves or attacks, e.g. "a4 a5" or "a4-a5"';

  @override
  GoStrategyText restart() => GoStrategyText();

  static const _files = 'abcdefghij';

  /// Square name, e.g. 60 → `a4`.
  static String name(int square) =>
      '${_files[GoStrategyGame.colOf(square)]}${GoStrategyGame.size - GoStrategyGame.rowOf(square)}';

  /// Inverse of [name], or null.
  static int? parseSquare(String s) {
    final m = RegExp(r'^([a-j])(10|[1-9])$').firstMatch(s.trim().toLowerCase());
    if (m == null) return null;
    return GoStrategyGame.square(GoStrategyGame.size - int.parse(m[2]!), _files.indexOf(m[1]!));
  }

  /// Short code of a piece: rank number, `S` spy, `B` bomb, `F` flag.
  static String code(GoPiece p) => switch (p) {
        GoPiece.spy => 'S',
        GoPiece.bomb => 'B',
        GoPiece.flag => 'F',
        _ => '${p.rank}',
      };

  static String pieceName(GoPiece p) {
    final n = '${p.id[0].toUpperCase()}${p.id.substring(1)}';
    return p.rank == null ? n : '$n (${p.rank})';
  }

  @override
  String render() {
    final me = game.currentPlayer;
    final view = game.viewFor(me);
    final b = StringBuffer()
      ..writeln('     ${[for (var c = 0; c < GoStrategyGame.size; c++) _files[c].padLeft(4)].join()}');
    for (var r = 0; r < GoStrategyGame.size; r++) {
      final cells = [
        for (var c = 0; c < GoStrategyGame.size; c++)
          _symbol(view[GoStrategyGame.square(r, c)]).padLeft(4),
      ];
      b.writeln('${'${GoStrategyGame.size - r}'.padLeft(3)}  ${cells.join()}');
    }
    b.write('${playerName(me)} sees: own pieces, enemy ? until revealed. '
        '10–2 ranks, S spy, B bomb, F flag, ~ lake');
    if (game.phase == GoStrategyPhase.play) {
      final left = [for (final p in Player.values) '${playerName(p)} ${_count(p)}'].join(', ');
      b.write('\nPieces left: $left; moves without a capture: ${game.movesSinceCapture}');
    } else if (!game.isOver && !game.hasSetup(me)) {
      b.write('\n${playerName(me)} sets up 40 pieces on ranks ${me == Player.a ? '1–4' : '7–10'}: "setup" or "setup <seed>"');
    }
    return b.toString();
  }

  int _count(Player p) => game.remaining(p).values.fold(0, (a, b) => a + b);

  String _symbol(GoCell c) {
    if (c.lake) return '~';
    if (c.owner == null) return '.';
    return '${mark(c.owner)}${c.piece == null ? '?' : code(c.piece!)}';
  }

  @override
  Map<String, dynamic>? parse(String input) {
    final s = input.trim().toLowerCase();
    final setup = RegExp(r'^setup(?:\s+(\d+))?$').firstMatch(s);
    if (setup != null) return {'action': 'autosetup', 'seed': int.parse(setup[1] ?? '0')};
    final m = RegExp(r'^([a-j](?:10|[1-9]))\s*(?:-|\s)\s*([a-j](?:10|[1-9]))$').firstMatch(s);
    if (m == null) return null;
    return {'action': 'move', 'from': parseSquare(m[1]!), 'to': parseSquare(m[2]!)};
  }

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  @override
  String format(Map<String, dynamic> move) => switch (move['action']) {
        'move' => '${name(move['from'] as int)}-${name(move['to'] as int)}',
        'autosetup' => 'setup ${move['seed']}',
        _ => 'setup',
      };

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final me = playerName(mover);
    final opp = _other(mover);
    final p = event.payload as Map;
    if (move['action'] != 'move') {
      final how = move['action'] == 'autosetup' ? ' at random (seed ${move['seed']})' : '';
      return '$me sets up their army$how.${_afterSetup(event)}';
    }
    final from = name(move['from'] as int), to = name(move['to'] as int);
    final fight = p['fight'] as Map?;
    String s;
    if (fight == null) {
      s = p['scout'] == true ? "$me's Scout (2) runs $from-$to." : '$me moves $from-$to.';
    } else {
      final a = pieceName(GoPiece.fromId(fight['attacker'])!);
      final d = pieceName(GoPiece.fromId(fight['defender'])!);
      s = "$me's $a on $from attacks ${playerName(opp)}'s $d on $to: ${switch (fight['outcome']) {
        'attacker' => '$a wins.',
        'defender' => '$a is removed.',
        'both' => 'both are removed.',
        _ => 'the flag is captured!',
      }}";
    }
    return '$s${_ending(event, mover)}';
  }

  String _afterSetup(GameEvent event) {
    if (game.phase == GoStrategyPhase.setup) return ' Now ${playerName(Player.b)} sets up (${playerName(Player.a)} looks away).';
    return ' Both armies are ready: ${playerName(Player.a)} moves first.${_ending(event, Player.b)}';
  }

  String _ending(GameEvent event, Player mover) {
    final r = game.result;
    return switch (r.code) {
      GameEndReason.gostrategyFlagCaptured => ' ${playerName(mover)} wins!',
      GameEndReason.gostrategyNoMoves => ' ${playerName(_other(r.winner!))} cannot move: ${playerName(r.winner)} wins!',
      GameEndReason.gostrategyBothBlocked => ' Neither side can move: draw.',
      GameEndReason.gostrategyMoveLimit => ' ${r.params['moves']} moves without a capture: draw.',
      _ => '',
    };
  }

  /// Board when play starts and at the end; fights are too frequent.
  @override
  bool isHighlight(GameEvent event) =>
      super.isHighlight(event) || (event.payload as Map?)?['setup'] == Player.b;

  /// Random setups, then: capture the flag if known, attack known weaker
  /// pieces, avoid known stronger ones, probe unknown pieces with cheap
  /// pieces, otherwise advance (random tie-break). Uses only the mover's
  /// own view.
  @override
  Map<String, dynamic> autoMove(Random rng) {
    if (game.phase == GoStrategyPhase.setup) return {'action': 'autosetup', 'seed': rng.nextInt(1 << 31)};
    final me = game.currentPlayer;
    final view = game.viewFor(me);
    final forward = me == Player.a ? -1 : 1;
    Map<String, dynamic>? best;
    var bestScore = double.negativeInfinity;
    for (final m in game.legalMoves) {
      final from = m['from'] as int, to = m['to'] as int;
      final mine = view[from].piece!;
      final target = view[to];
      double score;
      if (target.owner == null) {
        score = (GoStrategyGame.rowOf(to) - GoStrategyGame.rowOf(from)) * forward * 3.0;
      } else if (target.piece != null) {
        score = switch (GoStrategyGame.fight(mine, target.piece!)) {
          GoFightOutcome.flagCaptured => 1000,
          GoFightOutcome.attackerWins => 50.0 + (target.piece!.rank ?? 5),
          GoFightOutcome.bothLose => 5,
          GoFightOutcome.defenderWins => -50,
        };
      } else {
        // Unknown enemy: cheap pieces probe; a moved one is no bomb.
        score = 20.0 - (mine.rank ?? 0) * 2 + (target.moved ? 5 : 0) + (mine == GoPiece.miner && !target.moved ? 5 : 0);
      }
      score += rng.nextDouble() * 2;
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best ?? super.autoMove(rng);
  }

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;
}
