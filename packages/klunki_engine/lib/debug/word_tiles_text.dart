import 'dart:math';

import '../game.dart';
import '../word_tiles.dart';
import 'text_game.dart';

/// Text adapter for [WordTilesGame]. Squares are named by column `a`–`o`
/// and row `1`–`15` (row 1 on top). A placement is the start square plus
/// the word: column first (`h8 HAUS`) runs across, row first (`8h HAUS`)
/// runs down. Letters already on the board are typed too and must match; a
/// lower-case letter is a blank. Also `pass`, `exchange QX?`, `challenge`,
/// `accept`. The board shows premiums as `*` triple word, `+` double word,
/// `^` triple letter, `:` double letter; blanks in lower case. The rack
/// shown is the one of the player to move (a debug view).
class WordTilesText extends TextGame {
  WordTilesText({WordTilesGame? game}) : game = game ?? WordTilesGame(seed: 1);

  @override
  final WordTilesGame game;

  @override
  String get id => 'wordtiles';
  @override
  String get title => 'Wortleger';
  @override
  String get moveHelp =>
      '"h8 HAUS" (across), "8h HAUS" (down; lower case = blank), "pass", "exchange QX?", "challenge", "accept"';

  @override
  WordTilesText restart() => WordTilesText(game: WordTilesGame(seed: game.seed, tileSet: game.tileSet));

  static const _cols = 'abcdefghijklmno';
  static String square(int row, int col) => '${_cols[col]}${row + 1}';

  @override
  String render() {
    const n = WordTilesGame.size;
    final b = StringBuffer('    ${[for (var c = 0; c < n; c++) _cols[c]].join(' ')}\n');
    for (var r = 0; r < n; r++) {
      final cells = [
        for (var c = 0; c < n; c++) game.tileAt(r, c)?.toString() ?? WordTilesGame.premiumAt(r, c).symbol,
      ];
      b.writeln('${'${r + 1}'.padLeft(2)}  ${cells.join(' ')}');
    }
    b.writeln([for (var s = 0; s < game.playerCount; s++) '${_seatMark(s)} ${game.scoreOf(s)}'].join('  ') +
        '   bag ${game.bagCount}');
    if (!game.isOver) {
      b.write('${_seatMark(game.currentSeat)} rack: ${game.rackOf(game.currentSeat).join(' ')}');
      final open = game.challengeable;
      if (open != null) b.write('\n${_seatMark(open.seat)}\'s ${open.words.join(', ')} can be challenged.');
    }
    return b.toString().trimRight();
  }

  String _seatMark(int seat) => mark(WordTilesGame.playerOfSeat(seat)) == '.' ? 'P${seat + 1}' : mark(WordTilesGame.playerOfSeat(seat));

  static final _place = RegExp(r'^(?:([a-o])(\d{1,2})|(\d{1,2})([a-o]))\s+(\S+)$');

  @override
  Map<String, dynamic>? parse(String input) {
    final text = input.trim();
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    switch (words.first) {
      case 'pass':
        return words.length == 1 ? {'action': 'pass'} : null;
      case 'challenge':
        return words.length == 1 ? {'action': 'challenge'} : null;
      case 'accept':
        return words.length == 1 ? {'action': 'accept'} : null;
      case 'exchange' || 'swap':
        if (words.length != 2) return null;
        return {'action': 'exchange', 'tiles': text.split(RegExp(r'\s+'))[1].toUpperCase().split('')};
    }
    final m = _place.firstMatch(text.replaceFirstMapped(RegExp(r'^\S+'), (x) => x[0]!.toLowerCase()));
    if (m == null) return null;
    final across = m[1] != null;
    final col = _cols.indexOf(across ? m[1]! : m[4]!);
    final row = int.parse(across ? m[2]! : m[3]!) - 1;
    if (row < 0 || row >= WordTilesGame.size) return null;
    final tiles = <PlacedTile>[];
    final letters = m[5]!.split('');
    for (var i = 0; i < letters.length; i++) {
      final r = across ? row : row + i, c = across ? col + i : col;
      if (r >= WordTilesGame.size || c >= WordTilesGame.size) return null;
      final ch = letters[i];
      final upper = game.tileSet.normalize(ch);
      final onBoard = game.tileAt(r, c);
      if (onBoard != null) {
        if (onBoard.letter != upper) return null;
        continue;
      }
      tiles.add(ch == upper ? PlacedTile(r, c, upper) : PlacedTile(r, c, TileSet.blank, upper));
    }
    if (tiles.isEmpty) return null;
    return WordTilesGame.placeMove(tiles);
  }

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  @override
  String format(Map<String, dynamic> move) {
    switch (move['action']) {
      case 'place':
        final tiles = [for (final t in move['tiles'] as List) t as Map];
        final rows = {for (final t in tiles) t['row'] as int}, cols = {for (final t in tiles) t['col'] as int};
        final across = rows.length == 1;
        final row = rows.reduce(min), col = cols.reduce(min);
        final end = across ? cols.reduce(max) : rows.reduce(max);
        final b = StringBuffer();
        for (var i = across ? col : row; i <= end; i++) {
          final r = across ? row : i, c = across ? i : col;
          final t = tiles.where((t) => t['row'] == r && t['col'] == c).firstOrNull;
          if (t == null) {
            b.write(game.tileAt(r, c)?.letter ?? '?');
          } else {
            b.write(t['tile'] == TileSet.blank ? (t['letter'] as String).toLowerCase() : t['tile']);
          }
        }
        final start = across ? square(row, col) : '${row + 1}${_cols[col]}';
        return '$start $b';
      case 'exchange':
        final tiles = move['tiles'];
        return tiles is List ? 'exchange ${tiles.join()}' : 'exchange ${move['count']}';
      default:
        return '${move['action']}';
    }
  }

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final p = event.payload as Map;
    final who = _seatMark(p['seat'] as int);
    final text = switch (p['action']) {
      'place' => '$who lays ${[for (final w in p['words'] as List) '${(w as Map)['word']} (${w['score']})'].join(', ')}'
          '${p['bingo'] == true ? ' with all tiles (+${WordTilesGame.bingoBonus})' : ''}: ${p['score']} points.',
      'exchange' => '$who exchanges ${p['count']} tile${p['count'] == 1 ? '' : 's'}.',
      'pass' => '$who passes.',
      'accept' => '$who accepts.',
      'challenge' => p['withdrawn'] == true
          ? '$who challenges: ${_seatMark(p['placer'] as int)}\'s placement is withdrawn.'
          : '$who challenges, but the words stand; $who loses the turn.',
      _ => '$who moves.',
    };
    final r = game.result;
    if (!r.isOver) return text;
    return '$text ${r.draw ? 'Draw' : '${mark(r.winner)} wins'} (${r.reason}).';
  }

  /// Accepts open placements, else the best-scoring legal placement, else
  /// exchanges, else passes.
  @override
  Map<String, dynamic> autoMove(Random rng) {
    final legal = legalMoves;
    if (legal.any((m) => m['action'] == 'accept')) return {'action': 'accept'};
    Map<String, dynamic>? best;
    var bestScore = -1;
    for (final m in legal) {
      if (m['action'] != 'place') continue;
      final s = game.checkPlacement(m).score;
      if (s > bestScore) {
        best = m;
        bestScore = s;
      }
    }
    return best ?? legal.firstWhere((m) => m['action'] == 'exchange', orElse: () => legal.last);
  }
}
