import 'dart:math';

import '../chess.dart';
import '../game.dart';
import 'text_game.dart';

/// Text adapter for [ChessGame]: board with White (upper case) at the
/// bottom; moves typed in long algebraic (`e2e4`, `e7e8q`, also `e2-e4`) or
/// SAN (`Nf3`, `exd5`, `O-O`, `e8=Q`).
class ChessText extends TextGame {
  /// [game] wraps an existing engine instance (e.g. a network session's).
  ChessText({ChessGame? game}) : game = game ?? ChessGame();

  @override
  final ChessGame game;

  @override
  String get id => 'chess';
  @override
  String get title => 'Schach';
  @override
  String get moveHelp => '<from><to>[q|r|b|n] or SAN, e.g. "e2e4", "e7e8q", "Nf3", "exd5", "O-O"';

  /// A fresh game from the same start position.
  @override
  ChessText restart() => ChessText(game: ChessGame.fromFen(game.startPosition));

  @override
  String mark(Player? p) => switch (p) {
        Player.a => 'White',
        Player.b => 'Black',
        null => '.',
      };

  @override
  String render() {
    final board = game.board;
    final b = StringBuffer();
    for (var r = 7; r >= 0; r--) {
      b.writeln('${r + 1}  ${[for (var f = 0; f < 8; f++) board[r * 8 + f]?.fen ?? '.'].join(' ')}');
    }
    b.write('   a b c d e f g h');
    if (game.isInCheck && !game.isOver) b.write('\n${mark(game.currentPlayer)} is in check.');
    return b.toString();
  }

  static final _coordinates = RegExp(r'^([a-h][1-8])-?([a-h][1-8])([qrbn])?$');

  @override
  Map<String, dynamic>? parse(String input) {
    final text = input.trim();
    final c = _coordinates.firstMatch(text.toLowerCase());
    if (c != null) {
      return {'action': 'move', 'from': c[1], 'to': c[2], if (c[3] != null) 'promotion': c[3]};
    }
    final want = _normalSan(text);
    if (want.isEmpty) return null;
    for (final m in game.legalMoves) {
      if (_normalSan(game.sanOf(m)!) == want) return m;
    }
    return null;
  }

  /// SAN without check marks, annotations and `=`, castling with letter O.
  static String _normalSan(String san) => san.replaceAll(RegExp(r'[+#!?=]'), '').replaceAll('0', 'O');

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  @override
  String format(Map<String, dynamic> move) => '${move['from']}${move['to']}${move['promotion'] ?? ''}';

  static const _names = {'p': 'pawn', 'n': 'knight', 'b': 'bishop', 'r': 'rook', 'q': 'queen', 'k': 'king'};

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final p = event.payload as Map<String, dynamic>;
    final me = mark(mover);
    var s = '$me plays ${p['san']}';
    if (p['castle'] != null) {
      s += ' (castles ${p['castle']})';
    } else {
      s += ' (${_names[p['piece']]} ${p['from']}-${p['to']}';
      if (p['capture'] != null) {
        s += ', takes the ${_names[p['capture']]}${p['enPassant'] == true ? ' en passant' : ''}';
      }
      if (p['promotion'] != null) s += ', promotes to a ${_names[p['promotion']]}';
      s += ')';
    }
    s += '.';
    if (event.winner != null) return '$s Checkmate: $me wins!';
    if (event.draw) return '$s Draw: ${game.result.reason}.';
    if (p['check'] == true) s += ' Check!';
    return s;
  }

  static const _value = {'p': 1, 'n': 3, 'b': 3, 'r': 5, 'q': 9};

  /// A mate in one if there is one, else a random capture or promotion
  /// (most valuable victim first), else a random move.
  @override
  Map<String, dynamic> autoMove(Random rng) {
    final legal = legalMoves;
    final mates = [for (final m in legal) if (game.sanOf(m)!.endsWith('#')) m];
    if (mates.isNotEmpty) return mates[rng.nextInt(mates.length)];
    int gain(Map<String, dynamic> m) =>
        (_value[game.pieceAt(m['to'] as String)?.type.letter] ?? 0) + (m['promotion'] == 'q' ? 8 : 0);
    final best = legal.map(gain).fold(0, max);
    final pick = best > 0 ? [for (final m in legal) if (gain(m) == best) m] : legal;
    return pick[rng.nextInt(pick.length)];
  }

  @override
  bool isHighlight(GameEvent event) =>
      super.isHighlight(event) || (event.payload is Map && (event.payload as Map)['castle'] != null);

  /// A famous short game from 1858: development, queenside castling, a rook
  /// sacrifice and mate on the back rank.
  @override
  List<String> get demoScript => const [
        'e4', 'e5', 'Nf3', 'd6', 'd4', 'Bg4', 'dxe5', 'Bxf3', 'Qxf3', 'dxe5', //
        'Bc4', 'Nf6', 'Qb3', 'Qe7', 'Nc3', 'c6', 'Bg5', 'b5', 'Nxb5', 'cxb5',
        'Bxb5+', 'Nbd7', 'O-O-O', 'Rd8', 'Rxd7', 'Rxd7', 'Rd1', 'Qe6', 'Bxd7+', 'Nxd7',
        'Qb8+', 'Nxb8', 'Rd8#',
      ];
}
