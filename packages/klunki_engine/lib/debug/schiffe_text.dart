import 'dart:math';

import '../game.dart';
import '../schiffe.dart';
import 'text_game.dart';

/// Shows only what the player to move may see (hot-seat view): their own
/// fleet with incoming shots, and their shots at the opponent.
class SchiffeText extends TextGame {
  /// [game] wraps an existing engine instance (e.g. a network session's).
  SchiffeText({SchiffeGame? game}) : game = game ?? SchiffeGame();

  @override
  final SchiffeGame game;

  @override
  String get id => 'schiffe';
  @override
  String get title => 'Schiffe versenken';
  @override
  String get moveHelp => '<row A-J><col 1-10>[h|v]: place next ship ("B2h") or fire ("E5"); '
      '"fleet [seed]" places the rest of your fleet randomly';

  @override
  SchiffeText restart() => SchiffeText();

  static const _rows = 'ABCDEFGHIJ';

  static String cell(int row, int col) => '${_rows[row]}${col + 1}';

  @override
  String render() {
    final me = game.currentPlayer;
    final opp = _other(me);
    final own = game.ownGrid(me);
    final target = game.targetGrid(me);
    final header = [for (var c = 1; c <= SchiffeGame.size; c++) '$c'.padLeft(3)].join();
    final b = StringBuffer()
      ..writeln('    ${'${mark(me)}: own fleet'.padRight(35)}${mark(me)}: shots at ${mark(opp)}')
      ..writeln('  $header     $header');
    for (var r = 0; r < SchiffeGame.size; r++) {
      final left = own[r].map((c) => '  ${_ownSymbol[c.index]}').join();
      final right = target[r].map((c) => '  ${_shotSymbol[c.index]}').join();
      b.writeln('${_rows[r]} $left   ${_rows[r]} $right');
    }
    b.write('# ship  o miss  x hit  * sunk   |   ships left: '
        '${mark(me)} ${game.shipsRemaining(me)}, ${mark(opp)} ${game.shipsRemaining(opp)}');
    final next = game.nextShipIndex(me);
    if (!game.isOver && next != null) {
      final len = game.fleet[next];
      b.write('\n${mark(me)} places ship ${next + 1}/${game.fleet.length}: '
          '${SchiffeGame.shipName(len)} ($len), e.g. "A1h" or "fleet"');
    }
    return b.toString();
  }

  // Indexed by SchiffeCell / ShotMark.
  static const _ownSymbol = ['.', '#', 'o', 'x', '*'];
  static const _shotSymbol = ['.', 'o', 'x', '*'];

  @override
  Map<String, dynamic>? parse(String input) {
    final s = input.trim().toLowerCase();
    final fleet = RegExp(r'^fleet(?:\s+(\d+))?$').firstMatch(s);
    if (fleet != null) return {'action': 'autoplace', 'seed': int.parse(fleet[1] ?? '0')};
    final m = RegExp(r'^([a-j])\s*(10|[1-9])\s*([hv])?$').firstMatch(s);
    if (m == null) return null;
    final row = _rows.toLowerCase().indexOf(m[1]!);
    final col = int.parse(m[2]!) - 1;
    if (m[3] == null) return {'action': 'fire', 'row': row, 'col': col};
    final ship = game.nextShipIndex(game.currentPlayer);
    return ship == null ? null : {'action': 'place', 'ship': ship, 'row': row, 'col': col, 'dir': m[3]};
  }

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  @override
  String format(Map<String, dynamic> move) => switch (move['action']) {
        'fire' => cell(move['row'] as int, move['col'] as int),
        'place' => '${cell(move['row'] as int, move['col'] as int)}${move['dir']}',
        _ => 'fleet ${move['seed']}',
      };

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final me = mark(mover);
    final opp = _other(mover);
    final p = event.payload as Map;
    switch (move['action']) {
      case 'place':
        final len = p['length'] as int;
        return '$me places a ${SchiffeGame.shipName(len)} ($len) at ${cell(move['row'] as int, move['col'] as int)} '
            '${move['dir'] == 'h' ? 'horizontally' : 'vertically'}.${_setupDone(mover)}';
      case 'autoplace':
        return '$me places ${(p['autoplaced'] as List).length == game.fleet.length ? 'the whole' : 'the rest of the'} '
            'fleet at random (seed ${move['seed']}).${_setupDone(mover)}';
    }
    final at = cell(move['row'] as int, move['col'] as int);
    final name = p['ship'] == null ? '' : SchiffeGame.shipName(p['ship'] as int);
    final s = switch (p['result']) {
      'miss' => '$me fires at $at: miss.',
      'hit' => '$me fires at $at: hit on a $name!',
      _ => '$me fires at $at: $name sunk! (${mark(opp)} has ${game.shipsRemaining(opp)} ships left)',
    };
    if (event.winner != null) return '$s All of ${mark(opp)}\'s ships are sunk: $me wins!';
    if (p['result'] != 'miss' && game.currentPlayer == mover) return '$s $me fires again.';
    return s;
  }

  String _setupDone(Player mover) {
    if (game.nextShipIndex(mover) != null) return '';
    return game.phase == SchiffePhase.battle
        ? ' Both fleets are ready: the battle begins, X fires first.'
        : ' Now ${mark(_other(mover))} places their fleet (X looks away).';
  }

  /// Board when the battle starts and at the end; every shot would be too much.
  @override
  bool isHighlight(GameEvent event) =>
      super.isHighlight(event) || game.phase == SchiffePhase.battle && game.history.length == _setupMoves;

  int get _setupMoves => game.history.takeWhile((m) => m['action'] != 'fire').length;

  /// Random fleets, then "hunt and target": shoot next to unsunk hits (along
  /// the line once two are in a row), otherwise at random, skipping water
  /// that the no-touch rule reveals around sunk ships.
  @override
  Map<String, dynamic> autoMove(Random rng) {
    if (game.phase == SchiffePhase.setup) return {'action': 'autoplace', 'seed': rng.nextInt(1 << 31)};
    final t = game.targetGrid(game.currentPlayer);
    bool unknown(int r, int c) =>
        r >= 0 && r < SchiffeGame.size && c >= 0 && c < SchiffeGame.size && t[r][c] == ShotMark.unknown;
    final hits = [
      for (var r = 0; r < SchiffeGame.size; r++)
        for (var c = 0; c < SchiffeGame.size; c++)
          if (t[r][c] == ShotMark.hit) (r, c)
    ];
    var targets = <(int, int)>[];
    if (hits.isNotEmpty) {
      final rows = hits.map((h) => h.$1).toSet(), cols = hits.map((h) => h.$2).toSet();
      final dirs = hits.length > 1 && rows.length == 1
          ? const [(0, 1), (0, -1)]
          : hits.length > 1 && cols.length == 1
              ? const [(1, 0), (-1, 0)]
              : const [(0, 1), (0, -1), (1, 0), (-1, 0)];
      targets = [
        for (final (r, c) in hits)
          for (final (dr, dc) in dirs)
            if (unknown(r + dr, c + dc)) (r + dr, c + dc)
      ];
    }
    if (targets.isEmpty) {
      bool nextToSunk(int r, int c) => [
            for (var dr = -1; dr <= 1; dr++)
              for (var dc = -1; dc <= 1; dc++)
                if (r + dr >= 0 && r + dr < SchiffeGame.size && c + dc >= 0 && c + dc < SchiffeGame.size)
                  t[r + dr][c + dc] == ShotMark.sunk
          ].any((x) => x);
      targets = [
        for (var r = 0; r < SchiffeGame.size; r++)
          for (var c = 0; c < SchiffeGame.size; c++)
            if (t[r][c] == ShotMark.unknown && !nextToSunk(r, c)) (r, c)
      ];
    }
    if (targets.isEmpty) return super.autoMove(rng);
    final (r, c) = targets[rng.nextInt(targets.length)];
    return {'action': 'fire', 'row': r, 'col': c};
  }

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;
}
