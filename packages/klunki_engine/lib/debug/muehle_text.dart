import '../game.dart';
import '../muehle.dart';
import 'text_game.dart';

class MuehleText extends TextGame {
  @override
  final MuehleGame game = MuehleGame();

  @override
  String get id => 'muehle';
  @override
  String get title => 'Mühle';
  @override
  String get moveHelp => '<p> place, <a>-<b> move/fly, x<p> remove; e.g. "4", "4-7", "x13"';

  @override
  MuehleText restart() => MuehleText();

  // Grid position of each point (see the diagram in muehle.dart).
  static const _xs = [0, 12, 24, 4, 12, 20, 8, 12, 16, 0, 4, 8, 16, 20, 24, 8, 12, 16, 4, 12, 20, 0, 12, 24];
  static const _ys = [0, 0, 0, 2, 2, 2, 4, 4, 4, 6, 6, 6, 6, 6, 6, 8, 8, 8, 10, 10, 10, 12, 12, 12];

  /// Board with pieces on the left, point numbers on the right.
  @override
  String render() {
    final pieces = _draw((p) => mark(game.board[p]));
    final numbers = _draw((p) => '$p');
    final b = StringBuffer();
    for (var i = 0; i < pieces.length; i++) {
      b.writeln('${pieces[i].padRight(26)}    ${numbers[i]}');
    }
    for (final p in Player.values) {
      b.writeln('${mark(p)}: ${game.phaseOf(p).name}, '
          'hand ${game.piecesInHand(p)}, board ${game.piecesOnBoard(p)}');
    }
    if (game.pendingRemoval) b.writeln('Mill! ${mark(game.currentPlayer)} must remove a piece (x<p>).');
    return b.toString().trimRight();
  }

  List<String> _draw(String Function(int p) label) {
    final grid = List.generate(13, (_) => List.filled(26, ' '));
    for (var p = 0; p < MuehleGame.pointCount; p++) {
      for (final n in MuehleGame.adjacency[p].where((n) => n > p)) {
        if (_ys[p] == _ys[n]) {
          for (var x = _xs[p] + 2; x <= _xs[n]; x++) {
            grid[_ys[p]][x] = '-';
          }
        } else {
          for (var y = _ys[p] + 1; y < _ys[n]; y++) {
            grid[y][_xs[p] + 1] = '|';
          }
        }
      }
    }
    for (var p = 0; p < MuehleGame.pointCount; p++) {
      final s = label(p);
      if (s.length > 1) grid[_ys[p]][_xs[p]] = s[0];
      grid[_ys[p]][_xs[p] + 1] = s[s.length - 1];
    }
    return [for (final row in grid) row.join().trimRight()];
  }

  @override
  Map<String, dynamic>? parse(String input) {
    final s = input.trim().toLowerCase();
    if (s.startsWith('x')) {
      final at = int.tryParse(s.substring(1).trim());
      return at == null ? null : {'action': 'remove', 'at': at};
    }
    final parts = s.split('-');
    if (parts.length == 2) {
      final from = int.tryParse(parts[0].trim());
      final to = int.tryParse(parts[1].trim());
      return from == null || to == null ? null : {'action': 'move', 'from': from, 'to': to};
    }
    final to = int.tryParse(s);
    return to == null ? null : {'action': 'place', 'to': to};
  }

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  @override
  String format(Map<String, dynamic> move) => switch (move['action']) {
        'place' => '${move['to']}',
        'move' => '${move['from']}-${move['to']}',
        _ => 'x${move['at']}',
      };

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final opp = mover == Player.a ? Player.b : Player.a;
    final me = mark(mover);
    var s = switch (move['action']) {
      'place' => '$me places a piece on point ${move['to']} (${game.piecesInHand(mover)} left in hand).',
      'move' => '$me ${game.phaseOf(mover) == MuehlePhase.flying ? 'flies' : 'moves'} '
          'from ${move['from']} to ${move['to']}.',
      _ => '$me removes ${mark(opp)}\'s piece on point ${move['at']} '
          '(${mark(opp)} has ${game.piecesOnBoard(opp) + game.piecesInHand(opp)} left).',
    };
    if (event.payload case {'mill': true}) {
      final to = move['to'] as int;
      final line = MuehleGame.mills.firstWhere((m) => m.contains(to) && m.every((q) => game.board[q] == mover));
      s += ' Mill on ${line.join('-')}! $me may remove a piece.';
    }
    if (event.winner != null) s += ' $me wins: ${game.result.reason}.';
    if (event.draw) s += ' Draw: ${game.result.reason}.';
    return s;
  }

  @override
  bool isHighlight(GameEvent event) => super.isHighlight(event) || event.payload is Map && (event.payload as Map).containsKey('mill');

  /// O sets up a "Zwickmühle" (15 <-> 16 closes a mill both ways) and grinds X down.
  @override
  List<String> get demoScript => const [
        '21', '15', '16', '1', '8', '7', '5', '4', 'x8', '23', //
        '11', '20', '6', 'x16', '12', '8', 'x5', '10', '22', '17',
        '19', '21-9', '15-16', 'x10', '9-0', '16-15', 'x17', '12-13',
        '15-16', 'x23', '20-9', '16-15', 'x13',
      ];
}
