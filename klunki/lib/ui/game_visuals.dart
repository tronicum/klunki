import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' show ChessColor, ChessPiece, ChessPieceType, GameConfig, Player;

import '../app/theme.dart';
import 'game_illustrations.dart';
import 'games/chess/chess_pieces.dart';
import 'games/connect4/connect4_board.dart' show Connect4Piece;
import 'games/maexchen/maexchen_dice.dart' show MaexchenIllustration;
import 'games/wordtiles/wordtiles_tiles.dart';

/// Per-game visuals (KLD-062): menu illustration, one-line description and
/// the player token colours shown in the shell's turn indicator. The accent
/// colour itself lives in the theme ([KlunkiPalette.accent]) so presets can
/// change it.
///
/// Adding a game: add an entry to [gameVisuals] (and an
/// accent to the palettes in `app/theme.dart`). Games without an entry get
/// [GameVisuals.fallback]: a die illustration, no description, no tokens.
@immutable
class GameVisuals {
  /// The menu illustration.
  final CustomPainter Function(KlunkiPalette palette) illustration;

  /// One-line description for the menu tile (null = none).
  final String Function(AppLocalizations l10n)? description;

  /// Colour of a player's piece (null = the game has no piece colours).
  ///
  /// This is the per-game hook for the turn colour (KLD-067): the shell's
  /// status pill, turn edge, player tokens and the network bar all use
  /// [playerColor], which returns this colour when set. A game with
  /// coloured pieces (GoStrategy: black / white stones) sets it so the turn
  /// colour matches the board; without it player A takes the game accent and
  /// player B [KlunkiPalette.secondPlayer].
  final Color? Function(KlunkiPalette palette, Player player)? token;

  /// The game's own player token (null = a disc in [token]'s colour with
  /// the player number "1" / "2", KLD-106). Games whose token is a game
  /// piece show the piece without a letter: chess the side's king, 4 Gewinnt
  /// the disc (yellow with its inner ring), Mühle the light / dark stone.
  /// Each stays distinguishable without colour (shape or lightness).
  final Widget Function(BuildContext context, Player player, double size)? tokenIcon;

  const GameVisuals({required this.illustration, this.description, this.token, this.tokenIcon});

  static final fallback = GameVisuals(
    illustration: (p) => DefaultGameIllustration(p, p.defaultAccent.color),
  );
}

/// `GameSpec.id` → visuals.
final Map<String, GameVisuals> gameVisuals = {
  'connect4': GameVisuals(
    illustration: Connect4Illustration.new,
    description: (l) => l.menuDescConnect4,
    token: (p, player) => player == Player.a ? p.connect4.red : p.connect4.yellow,
    tokenIcon: _connect4Token,
  ),
  'muehle': GameVisuals(
    illustration: MuehleIllustration.new,
    description: (l) => l.menuDescMuehle,
    token: (p, player) => player == Player.a ? p.muehle.light : p.muehle.dark,
    tokenIcon: _muehleToken,
  ),
  'quartett-trumpf': GameVisuals(
    illustration: (p) => QuartettIllustration(p, sets: const ['F', 'E', 'A']),
    description: (l) => l.menuDescQuartettTrumpf,
  ),
  'quartett-sets': GameVisuals(
    illustration: (p) => QuartettIllustration(p, sets: const ['B', 'B', 'B']),
    description: (l) => l.menuDescQuartettSets,
  ),
  'schiffe': GameVisuals(
    illustration: SchiffeIllustration.new,
    description: (l) => l.menuDescSchiffe,
  ),
  'gostrategy': GameVisuals(
    illustration: GoStrategyIllustration.new,
    description: (l) => l.menuDescGoStrategy,
    token: (p, player) => p.gostrategy.army(player == Player.a),
  ),
  'chess': GameVisuals(
    illustration: ChessIllustration.new,
    description: (l) => l.menuDescChess,
    token: (p, player) => player == Player.a ? p.chess.whiteToken : p.chess.blackToken,
    tokenIcon: _chessToken,
  ),
  'wordtiles': GameVisuals(
    illustration: (p) =>
        WordTilesIllustration(p.background.computeLuminance() < 0.2 ? Brightness.dark : Brightness.light),
    description: (l) => l.menuDescWordTiles,
  ),
  'maexchen': GameVisuals(
    illustration: MaexchenIllustration.new,
    description: (l) => l.menuDescMaexchen,
  ),
};

/// 4 Gewinnt token (KLD-106): the board's piece, red for A, yellow with the
/// embossed inner ring for B (shape, not only colour, UX-REVIEW 2.10).
Widget _connect4Token(BuildContext context, Player player, double size) {
  final c = KlunkiPalette.of(context).connect4;
  return Connect4Piece(color: player == Player.a ? c.red : c.yellow, ringed: player == Player.b);
}

/// Mühle token (KLD-106): the board's stone, light for A and dark for B
/// (told apart by lightness, not hue).
Widget _muehleToken(BuildContext context, Player player, double size) {
  final m = KlunkiPalette.of(context).muehle;
  final light = player == Player.a;
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: light ? m.lightEdge : m.darkEdge, width: size * 0.06),
      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 2, offset: Offset(0.5, 1))],
      gradient: RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: light
            ? [Colors.white, m.light, m.lightShade]
            : [m.darkShine, m.dark, Color.lerp(m.dark, Colors.black, 0.5)!],
      ),
    ),
  );
}

/// Chess token: the side's king on a light square disc (A's token is the
/// white king; see [tokenSidesOf] for a game where B plays White).
Widget _chessToken(BuildContext context, Player player, double size) {
  final c = KlunkiPalette.of(context).chess;
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: c.lightSquare,
      border: Border.all(color: Colors.black26, width: size * 0.08),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
    ),
    child: ChessPieceIcon(
        piece: ChessPiece(player == Player.a ? ChessColor.white : ChessColor.black, ChessPieceType.king), size: size),
  );
}

GameVisuals visualsOf(String gameId) => gameVisuals[gameId] ?? GameVisuals.fallback;

/// [PlayerLabels.tokens] for a game started with [config]: in chess the
/// tokens show the colours (A's token is the white king), so when B plays
/// White (KLD-059 step 4a, [GameConfig.chessWhite]) the two swap. Empty for
/// every other game.
Map<Player, Player> tokenSidesOf(GameConfig config) => config.gameId == 'chess' && config.chessWhite == Player.b
    ? const {Player.a: Player.b, Player.b: Player.a}
    : const {};

/// The colour of [player] in [gameId] (KLD-067): the piece colour where the
/// game has one ([GameVisuals.token]: 4 Gewinnt red / yellow, Mühle light /
/// dark stones, GoStrategy red / blue), otherwise the game accent for A and
/// [KlunkiPalette.secondPlayer] for B.
Color playerColor(KlunkiPalette palette, String gameId, Player player) =>
    visualsOf(gameId).token?.call(palette, player) ??
    (player == Player.a ? palette.accent(gameId).color : palette.secondPlayer);
