import '../connect4.dart';
import '../game.dart';
import 'text_game.dart';

class Connect4Text extends TextGame {
  @override
  final Connect4Game game = Connect4Game();

  @override
  String get id => 'connect4';
  @override
  String get title => '4 Gewinnt';
  @override
  String get moveHelp => '<col 0-6>   drop a piece, e.g. "3"';

  @override
  Connect4Text restart() => Connect4Text();

  @override
  String render() {
    final b = StringBuffer(' ${[for (var c = 0; c < Connect4Game.cols; c++) c].join(' ')}\n');
    for (final row in game.toRenderRows()) {
      b.writeln('|${row.map(mark).join(' ')}|');
    }
    b.write('+${'-' * (Connect4Game.cols * 2 - 1)}+');
    return b.toString();
  }

  @override
  Map<String, dynamic>? parse(String input) {
    final col = int.tryParse(input.trim());
    return col == null ? null : {'col': col};
  }

  @override
  List<Map<String, dynamic>> get legalMoves => [for (final c in game.legalMoves) {'col': c}];

  @override
  String format(Map<String, dynamic> move) => '${move['col']}';

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final row = (game.history.last['row'] as int) + 1;
    final s = '${mark(mover)} drops into column ${move['col']} (lands in row $row from the bottom).';
    if (event.winner != null) return '$s Four in a row: ${mark(mover)} wins!';
    if (event.draw) return '$s The board is full: draw.';
    return s;
  }

  /// X builds a rising diagonal from column 3 to 6 while O misses the threat.
  @override
  List<String> get demoScript => ['3', '4', '4', '5', '5', '6', '5', '6', '6', '0', '6'];
}
