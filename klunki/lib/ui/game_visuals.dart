import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' show Player;

import '../app/theme.dart';
import 'game_illustrations.dart';

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

  const GameVisuals({required this.illustration, this.description, this.token});

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
  ),
  'muehle': GameVisuals(
    illustration: MuehleIllustration.new,
    description: (l) => l.menuDescMuehle,
    token: (p, player) => player == Player.a ? p.muehle.light : p.muehle.dark,
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
};

GameVisuals visualsOf(String gameId) => gameVisuals[gameId] ?? GameVisuals.fallback;

/// The colour of [player] in [gameId] (KLD-067): the piece colour where the
/// game has one ([GameVisuals.token]: 4 Gewinnt red / yellow, Mühle light /
/// dark stones, GoStrategy red X / blue O), otherwise the game accent for A and
/// [KlunkiPalette.secondPlayer] for B.
Color playerColor(KlunkiPalette palette, String gameId, Player player) =>
    visualsOf(gameId).token?.call(palette, player) ??
    (player == Player.a ? palette.accent(gameId).color : palette.secondPlayer);
