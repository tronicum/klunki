import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'fonts.dart';

/// Application look (KLD-062): colour scheme, component shapes and every
/// board/game colour, bundled as **presets** so a later theme picker
/// (KLD-063) only has to choose one.
///
/// * [KlunkiPreset]: a named look = seed colour + a light and a dark
///   [KlunkiPalette]. [KlunkiPreset.classic] ("Spieltisch": warm paper,
///   wooden board, classic piece colours) is the current and only preset.
/// * [KlunkiPalette]: a [ThemeExtension] with the background, the per-game
///   accents and the board materials (4 Gewinnt, Mühle, Schiffe, Quartett,
///   GoStrategy).
///   Widgets read it with [KlunkiPalette.of]; no board colour is hard-coded
///   in a widget.
/// * [KlunkiTheme.build] turns a preset + brightness into [ThemeData]
///   (text keeps the bundled fonts, see `fonts.dart`).
class KlunkiTheme {
  static ThemeData get light => build(KlunkiPreset.classic, Brightness.light);

  static ThemeData get dark => build(KlunkiPreset.classic, Brightness.dark);

  static ThemeData build(KlunkiPreset preset, Brightness brightness) {
    final palette = preset.palette(brightness);
    final scheme = ColorScheme.fromSeed(
      seedColor: preset.seed,
      brightness: brightness,
      surface: palette.surface,
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      extensions: [palette],
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: shape,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 2,
        centerTitle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: _ReducedMotionTransitions(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.fuchsia: _ReducedMotionTransitions(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.linux: _ReducedMotionTransitions(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.windows: _ReducedMotionTransitions(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.iOS: _ReducedMotionTransitions(CupertinoPageTransitionsBuilder()),
        TargetPlatform.macOS: _ReducedMotionTransitions(CupertinoPageTransitionsBuilder()),
      }),
    );
    return withAppFonts(base);
  }
}

/// Delegates to [inner], but shows the page at once when the platform asks
/// for reduced motion (`MediaQuery.disableAnimations`).
class _ReducedMotionTransitions extends PageTransitionsBuilder {
  final PageTransitionsBuilder inner;
  const _ReducedMotionTransitions(this.inner);

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return inner.buildTransitions(route, context, animation, secondaryAnimation, child);
  }
}

/// WCAG 2 contrast ratio of two colours (1–21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

/// Black or white, whichever has the higher contrast on [fill]: at least
/// 4.58:1 for any colour (KLD-067: text on a player-coloured status pill).
Color inkOn(Color fill) {
  final l = fill.computeLuminance();
  return (l + 0.05) / 0.05 >= 1.05 / (l + 0.05) ? Colors.black : Colors.white;
}

/// True when animations should be skipped (reduced motion).
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// A named look: seed colour plus light and dark palettes.
class KlunkiPreset {
  final String id;
  final Color seed;
  final KlunkiPalette lightPalette;
  final KlunkiPalette darkPalette;

  const KlunkiPreset({required this.id, required this.seed, required this.lightPalette, required this.darkPalette});

  KlunkiPalette palette(Brightness b) => b == Brightness.dark ? darkPalette : lightPalette;

  /// "Spieltisch": warm amber seed, cream paper (light) / walnut table (dark).
  static const classic = KlunkiPreset(
    id: 'classic',
    seed: Color(0xFFC9772B),
    lightPalette: KlunkiPalette.classicLight,
    darkPalette: KlunkiPalette.classicDark,
  );

  /// All presets; a settings picker (KLD-063) lists these.
  static const all = [classic];
}

/// Colours of one game: [color] for the app bar and tile header (with
/// [onColor] text, WCAG AA), [container] as a soft tile background.
@immutable
class GameAccent {
  final Color color;
  final Color onColor;
  final Color container;

  const GameAccent(this.color, this.container, {this.onColor = Colors.white});

  /// [color] for icons/text on the app surface: lightened in dark themes so
  /// it keeps ≥3:1 there.
  Color onSurface(Brightness b) => b == Brightness.dark ? Color.lerp(color, Colors.white, 0.5)! : color;
}

/// 4 Gewinnt board colours.
@immutable
class Connect4Palette {
  final Color board, boardShade, red, yellow, hole, highlight;
  const Connect4Palette({
    required this.board,
    required this.boardShade,
    required this.red,
    required this.yellow,
    required this.hole,
    this.highlight = Colors.white,
  });
}

/// Mühle board ("wood") and stone colours.
@immutable
class MuehlePalette {
  final Color board, boardLight, grain, boardEdge, line;
  final Color light, lightEdge, lightShade, dark, darkEdge, darkShine;
  final Color mill, target, remove, select;
  const MuehlePalette({
    required this.board,
    required this.boardLight,
    required this.grain,
    required this.boardEdge,
    required this.line,
    required this.light,
    required this.lightEdge,
    required this.lightShade,
    required this.dark,
    required this.darkEdge,
    required this.darkShine,
    required this.mill,
    required this.target,
    required this.remove,
    required this.select,
  });
}

/// Schiffe versenken grid colours ("sea").
@immutable
class SchiffePalette {
  final Color water, waterDeep, gridLine, ship, shipEdge, hit, hitBg, onHit, miss, sunk, onSunk;
  final Color previewValid, previewInvalid;
  const SchiffePalette({
    required this.water,
    required this.waterDeep,
    required this.gridLine,
    required this.ship,
    required this.shipEdge,
    required this.hit,
    required this.hitBg,
    required this.onHit,
    required this.miss,
    required this.sunk,
    required this.onSunk,
    required this.previewValid,
    required this.previewInvalid,
  });
}

/// Quartett card colours: header colour per set letter, outcome colours for
/// the trick reveal, the card back.
@immutable
class QuartettPalette {
  final Map<String, Color> sets;
  final Color otherSet, win, lose, tie, backA, backB, onBack, cardFace;

  /// Lighten set colours when used as text on the surface (dark themes).
  final double setTextLighten;

  const QuartettPalette({
    required this.sets,
    required this.otherSet,
    required this.win,
    required this.lose,
    required this.tie,
    required this.backA,
    required this.backB,
    required this.onBack,
    required this.cardFace,
    this.setTextLighten = 0,
  });

  /// Header colour of a set letter `A`–`H` (white text on it is AA).
  Color set(String s) => sets[s] ?? otherSet;

  /// The set colour for text on the app surface.
  Color setText(String s) => setTextLighten == 0 ? set(s) : Color.lerp(set(s), Colors.white, setTextLighten)!;
}

/// GoStrategy board and army colours (KLD-058b). Lakes use the Schiffe
/// water colours ([SchiffePalette.water] / [SchiffePalette.waterDeep]).
@immutable
class GoStrategyPalette {
  /// Land squares (two shades in a checker), grid lines and the board edge.
  final Color land, landAlt, line, edge;

  /// Army colours: player A (X) and player B (O), text/icons on them.
  final Color red, blue, onPiece;

  /// Selected piece outline, legal-target dots, attack ring, last-move tint.
  final Color select, target, attack, lastMove;

  const GoStrategyPalette({
    required this.land,
    required this.landAlt,
    required this.line,
    required this.edge,
    required this.red,
    required this.blue,
    required this.onPiece,
    required this.select,
    required this.target,
    required this.attack,
    required this.lastMove,
  });

  /// The army colour of a player (A red, B blue).
  Color army(bool playerA) => playerA ? red : blue;
}

/// Chess board and piece colours (KLD-059). The board keeps its classic
/// wood tones in both themes (a little darker in dark), so white and black
/// pieces read the same everywhere.
@immutable
class ChessPalette {
  /// Light and dark squares, board edge, coordinates on the edge band.
  final Color lightSquare, darkSquare, edge;

  /// Piece fill and outline per side; [blackDetail] draws the inner lines
  /// of the black pieces (light on dark).
  final Color whiteFill, whiteLine, blackFill, blackLine, blackDetail;

  /// Turn colours (status pill, turn edge): White and Black.
  final Color whiteToken, blackToken;

  /// Selection ring, legal-move dots / capture rings, last-move tint, the
  /// king in check.
  final Color select, target, lastMove, check;

  const ChessPalette({
    required this.lightSquare,
    required this.darkSquare,
    required this.edge,
    required this.whiteFill,
    required this.whiteLine,
    required this.blackFill,
    required this.blackLine,
    required this.blackDetail,
    required this.whiteToken,
    required this.blackToken,
    required this.select,
    required this.target,
    required this.lastMove,
    required this.check,
  });
}

/// The board/game colours of the app, as a [ThemeExtension].
@immutable
class KlunkiPalette extends ThemeExtension<KlunkiPalette> {
  /// Scaffold colour and the two ends of the soft page gradient.
  final Color background, backgroundTop, backgroundBottom;

  /// Card/dialog surface and app surface (passed to the colour scheme).
  final Color card, surface;

  /// Accent per `GameSpec.id`; unknown ids get [defaultAccent].
  final Map<String, GameAccent> accents;
  final GameAccent defaultAccent;

  /// Accent of the room buttons ("Raum starten", "Raum beitreten").
  final GameAccent networkAccent;

  /// Trophy colour (result dialog, status pill of a finished game).
  final Color trophy;

  /// Colour of player B (O) in games without piece colours of their own;
  /// player A (X) takes the game accent (KLD-067, see `playerColor` in
  /// `ui/game_visuals.dart`).
  final Color secondPlayer;

  final Connect4Palette connect4;
  final MuehlePalette muehle;
  final SchiffePalette schiffe;
  final QuartettPalette quartett;
  final GoStrategyPalette gostrategy;
  final ChessPalette chess;

  const KlunkiPalette({
    required this.background,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.card,
    required this.surface,
    required this.accents,
    required this.defaultAccent,
    required this.networkAccent,
    required this.trophy,
    required this.secondPlayer,
    required this.connect4,
    required this.muehle,
    required this.schiffe,
    required this.quartett,
    required this.gostrategy,
    required this.chess,
  });

  /// The palette of the current theme; the classic preset when the theme
  /// has none (e.g. a bare `MaterialApp` in tests).
  static KlunkiPalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<KlunkiPalette>() ?? KlunkiPreset.classic.palette(theme.brightness);
  }

  GameAccent accent(String gameId) => accents[gameId] ?? defaultAccent;

  // Shared by both classic palettes: printed card colours (white text AA).
  static const _sets = {
    'A': Color(0xFFC62828), // red
    'B': Color(0xFF6A1B9A), // purple
    'C': Color(0xFF795548), // brown
    'D': Color(0xFFBF5300), // orange
    'E': Color(0xFF2E7D32), // green
    'F': Color(0xFF1565C0), // blue
    'G': Color(0xFF00727D), // teal
    'H': Color(0xFFAD1457), // pink
  };

  static const classicLight = KlunkiPalette(
    background: Color(0xFFFBF4E8),
    backgroundTop: Color(0xFFFDF8EF),
    backgroundBottom: Color(0xFFF3E4CB),
    card: Color(0xFFFFFCF6),
    surface: Color(0xFFFFF8F0),
    accents: {
      'connect4': GameAccent(Color(0xFF1C5DB8), Color(0xFFD6E4FA)),
      'muehle': GameAccent(Color(0xFF8A5527), Color(0xFFF1DEC4)),
      'quartett-trumpf': GameAccent(Color(0xFFB3261E), Color(0xFFF9DAD5)),
      'quartett-sets': GameAccent(Color(0xFF6E3C96), Color(0xFFEADCF5)),
      'schiffe': GameAccent(Color(0xFF00707A), Color(0xFFCCEDEF)),
      'gostrategy': GameAccent(Color(0xFF4E6B2F), Color(0xFFDDE8C8)),
      'chess': GameAccent(Color(0xFF5B4636), Color(0xFFEADFD3)),
      'wordtiles': GameAccent(Color(0xFF2F6B4F), Color(0xFFD5E8DC)),
      'maumau': GameAccent(Color(0xFF9C2D5A), Color(0xFFF6D9E4)),
      'maexchen': GameAccent(Color(0xFF8E3B2E), Color(0xFFF6DDD3)),
      'dicesheet': GameAccent(Color(0xFF3B5BA9), Color(0xFFDCE4F6)),
    },
    defaultAccent: GameAccent(Color(0xFF5D5A52), Color(0xFFE8E2D6)),
    networkAccent: GameAccent(Color(0xFF8C4A00), Color(0xFFFFE0C2)),
    trophy: Color(0xFFC98A00),
    secondPlayer: Color(0xFF4A5560), // slate
    connect4: Connect4Palette(
      board: Color(0xFF1C5DB8),
      boardShade: Color(0xFF134A96),
      red: Color(0xFFD32F2F),
      yellow: Color(0xFFFFC107),
      hole: Color(0xFFFBF4E8),
    ),
    muehle: MuehlePalette(
      board: Color(0xFFE2BC7E),
      boardLight: Color(0xFFF0D3A0),
      grain: Color(0xFF9C6A35),
      boardEdge: Color(0xFFA87638),
      line: Color(0xFF4E3016),
      light: Color(0xFFFAF7F0),
      lightEdge: Color(0xFF8C8270),
      lightShade: Color(0xFFD9D0BC),
      dark: Color(0xFF2B2B2E),
      darkEdge: Color(0xFF000000),
      darkShine: Color(0xFF5E5E66),
      mill: Color(0xFFFFB300),
      target: Color(0xFF2E7D32),
      remove: Color(0xFFC62828),
      select: Color(0xFF1565C0),
    ),
    schiffe: SchiffePalette(
      water: Color(0xFFBFE0F2),
      waterDeep: Color(0xFF9ACBE6),
      gridLine: Color(0xFF7FB3D3),
      ship: Color(0xFF55606B),
      shipEdge: Color(0xFF39424B),
      hit: Color(0xFFC62828),
      hitBg: Color(0xFFFFCDD2),
      onHit: Colors.white,
      miss: Color(0xFFFFFFFF),
      sunk: Color(0xFF8E1B1B),
      onSunk: Colors.white,
      previewValid: Color(0x9943A047),
      previewInvalid: Color(0x99E53935),
    ),
    quartett: QuartettPalette(
      sets: _sets,
      otherSet: Color(0xFF616161),
      win: Color(0xFF2E7D32),
      lose: Color(0xFFC62828),
      tie: Color(0xFF757575),
      backA: Color(0xFF8C3B1F),
      backB: Color(0xFFC9772B),
      onBack: Color(0xFFFFF3E0),
      cardFace: Color(0xFFFFFDF8),
    ),
    gostrategy: GoStrategyPalette(
      land: Color(0xFFE6D7AE),
      landAlt: Color(0xFFDDCB9C),
      line: Color(0xFFB59F69),
      edge: Color(0xFF7A6638),
      red: Color(0xFFB3261E),
      blue: Color(0xFF1F4F9E),
      onPiece: Colors.white,
      select: Color(0xFFFFB300),
      target: Color(0xFF2E7D32),
      attack: Color(0xFFD50000),
      lastMove: Color(0x557A6638),
    ),
    chess: ChessPalette(
      lightSquare: Color(0xFFF0D9B5),
      darkSquare: Color(0xFFB58863),
      edge: Color(0xFF6B4A2E),
      whiteFill: Color(0xFFFFFDF7),
      whiteLine: Color(0xFF26211C),
      blackFill: Color(0xFF26211C),
      blackLine: Color(0xFF0E0C0A),
      blackDetail: Color(0xFFE8DFD0),
      whiteToken: Color(0xFFF7F3EA),
      blackToken: Color(0xFF2B2B2E),
      select: Color(0xFFFFB300),
      target: Color(0xFF2E7D32),
      lastMove: Color(0x80E5C534),
      check: Color(0xFFE53935),
    ),
  );

  static const classicDark = KlunkiPalette(
    background: Color(0xFF1F1A16),
    backgroundTop: Color(0xFF26201B),
    backgroundBottom: Color(0xFF17130F),
    card: Color(0xFF2E2721),
    surface: Color(0xFF1F1A16),
    accents: {
      'connect4': GameAccent(Color(0xFF184C96), Color(0xFF1E2C44)),
      'muehle': GameAccent(Color(0xFF6E4320), Color(0xFF3A2C1F)),
      'quartett-trumpf': GameAccent(Color(0xFF9A2A22), Color(0xFF42221F)),
      'quartett-sets': GameAccent(Color(0xFF5E3382), Color(0xFF33243F)),
      'schiffe': GameAccent(Color(0xFF00636B), Color(0xFF18363A)),
      'gostrategy': GameAccent(Color(0xFF3F5726), Color(0xFF2A3320)),
      'chess': GameAccent(Color(0xFF4E3B2D), Color(0xFF342A22)),
      'wordtiles': GameAccent(Color(0xFF285A43), Color(0xFF1F3329)),
      'maumau': GameAccent(Color(0xFF84264C), Color(0xFF3D2230)),
      'maexchen': GameAccent(Color(0xFF7A3226), Color(0xFF3D2420)),
      'dicesheet': GameAccent(Color(0xFF34508F), Color(0xFF232C40)),
    },
    defaultAccent: GameAccent(Color(0xFF4F4B44), Color(0xFF34302B)),
    networkAccent: GameAccent(Color(0xFF7A4100), Color(0xFF3F2C1A)),
    trophy: Color(0xFFFFC233),
    secondPlayer: Color(0xFFB4C0CC), // light slate
    connect4: Connect4Palette(
      board: Color(0xFF184C96),
      boardShade: Color(0xFF0F3570),
      red: Color(0xFFE53935),
      yellow: Color(0xFFFFCA28),
      hole: Color(0xFF1F1A16),
    ),
    muehle: MuehlePalette(
      board: Color(0xFFB98A52),
      boardLight: Color(0xFFCB9F68),
      grain: Color(0xFF6E4520),
      boardEdge: Color(0xFF7A5228),
      line: Color(0xFF3A230F),
      light: Color(0xFFFAF7F0),
      lightEdge: Color(0xFF8C8270),
      lightShade: Color(0xFFD9D0BC),
      dark: Color(0xFF2B2B2E),
      darkEdge: Color(0xFF000000),
      darkShine: Color(0xFF5E5E66),
      mill: Color(0xFFFFC233),
      target: Color(0xFF2E7D32),
      remove: Color(0xFFC62828),
      select: Color(0xFF1565C0),
    ),
    schiffe: SchiffePalette(
      water: Color(0xFF1D4E6E),
      waterDeep: Color(0xFF163E59),
      gridLine: Color(0xFF2D6A91),
      ship: Color(0xFFA5B1BC),
      shipEdge: Color(0xFF6F7C88),
      hit: Color(0xFFFF6B60),
      hitBg: Color(0xFF6B1F1F),
      onHit: Colors.white,
      miss: Color(0xFFE3F2FD),
      sunk: Color(0xFFB3261E),
      onSunk: Colors.white,
      previewValid: Color(0x9943A047),
      previewInvalid: Color(0x99E53935),
    ),
    quartett: QuartettPalette(
      sets: _sets,
      otherSet: Color(0xFF616161),
      win: Color(0xFF81C784),
      lose: Color(0xFFEF9A9A),
      tie: Color(0xFFBDBDBD),
      backA: Color(0xFF6B2C17),
      backB: Color(0xFFA35F22),
      onBack: Color(0xFFFFF3E0),
      cardFace: Color(0xFF2E2721),
      setTextLighten: 0.5,
    ),
    gostrategy: GoStrategyPalette(
      land: Color(0xFF5B5140),
      landAlt: Color(0xFF524937),
      line: Color(0xFF3B3326),
      edge: Color(0xFF2A241A),
      red: Color(0xFFC62828),
      blue: Color(0xFF2E63BE),
      onPiece: Colors.white,
      select: Color(0xFFFFC233),
      target: Color(0xFF81C784),
      attack: Color(0xFFFF5252),
      lastMove: Color(0x66FFF3D6),
    ),
    chess: ChessPalette(
      lightSquare: Color(0xFFD9C29C),
      darkSquare: Color(0xFF9C7350),
      edge: Color(0xFF4A3320),
      whiteFill: Color(0xFFFFFDF7),
      whiteLine: Color(0xFF26211C),
      blackFill: Color(0xFF26211C),
      blackLine: Color(0xFF0E0C0A),
      blackDetail: Color(0xFFE8DFD0),
      whiteToken: Color(0xFFF7F3EA),
      blackToken: Color(0xFF3A3A3E),
      select: Color(0xFFFFC233),
      target: Color(0xFF1B5E20),
      lastMove: Color(0x80E5C534),
      check: Color(0xFFFF5252),
    ),
  );

  @override
  KlunkiPalette copyWith() => this;

  @override
  KlunkiPalette lerp(KlunkiPalette? other, double t) => other == null || t < 0.5 ? this : other;
}

/// The soft page background (paper / table gradient) behind [child].
class KlunkiBackground extends StatelessWidget {
  final Widget child;
  const KlunkiBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = KlunkiPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.backgroundTop, p.backgroundBottom],
        ),
      ),
      child: child,
    );
  }
}
