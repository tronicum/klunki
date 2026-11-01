import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

/// Colours of the word tile game (KLD-094): our own, chosen to look like no
/// commercial product (word premiums in greens, letter premiums in ochre /
/// sand, cream tiles).
@immutable
class WordTilesColors {
  final Color board, line, edge;
  final Color doubleLetter, tripleLetter, doubleWord, tripleWord;
  final Color tile, tileEdge, tileInk, blankInk;

  /// Tiles laid this turn (not played yet), the selection ring, the last
  /// placement and an open (challengeable) placement.
  final Color pending, select, lastMove, open;

  const WordTilesColors({
    required this.board,
    required this.line,
    required this.edge,
    required this.doubleLetter,
    required this.tripleLetter,
    required this.doubleWord,
    required this.tripleWord,
    required this.tile,
    required this.tileEdge,
    required this.tileInk,
    required this.blankInk,
    required this.pending,
    required this.select,
    required this.lastMove,
    required this.open,
  });

  static const light = WordTilesColors(
    board: Color(0xFFEDE6D6),
    line: Color(0xFFCFC3A8),
    edge: Color(0xFF8C7A55),
    doubleLetter: Color(0xFFF2D684),
    tripleLetter: Color(0xFFC77B1E),
    doubleWord: Color(0xFF9CC9A8),
    tripleWord: Color(0xFF2F6B4F),
    tile: Color(0xFFFFF4D6),
    tileEdge: Color(0xFFB89B5E),
    tileInk: Color(0xFF2B2118),
    blankInk: Color(0xFF4F6A9A),
    pending: Color(0xFFFFE08A),
    select: Color(0xFF1565C0),
    lastMove: Color(0xFFFFE9B0),
    open: Color(0xFFC62828),
  );

  static const dark = WordTilesColors(
    board: Color(0xFF3A342B),
    line: Color(0xFF524939),
    edge: Color(0xFF1E1A14),
    doubleLetter: Color(0xFF7A6526),
    tripleLetter: Color(0xFFB06A12),
    doubleWord: Color(0xFF2F5A43),
    tripleWord: Color(0xFF3F8A66),
    tile: Color(0xFFF3E6C4),
    tileEdge: Color(0xFF9C8250),
    tileInk: Color(0xFF2B2118),
    blankInk: Color(0xFF4F6A9A),
    pending: Color(0xFFFFD866),
    select: Color(0xFF64B5F6),
    lastMove: Color(0xFFFFE3A0),
    open: Color(0xFFEF5350),
  );

  static WordTilesColors of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? dark : light;

  Color premium(Premium p) => switch (p) {
        Premium.none => board,
        Premium.doubleLetter => doubleLetter,
        Premium.tripleLetter => tripleLetter,
        Premium.doubleWord => doubleWord,
        Premium.tripleWord => tripleWord,
      };
}

/// The short label on a premium square ("2W", "3B", …), localized.
String premiumLabel(AppLocalizations l10n, Premium p) => switch (p) {
      Premium.none => '',
      Premium.doubleLetter => l10n.wordtilesPremiumDoubleLetter,
      Premium.tripleLetter => l10n.wordtilesPremiumTripleLetter,
      Premium.doubleWord => l10n.wordtilesPremiumDoubleWord,
      Premium.tripleWord => l10n.wordtilesPremiumTripleWord,
    };

/// One letter tile: the letter, and its points in the corner (none for a
/// blank, whose letter is drawn in [WordTilesColors.blankInk]). Square,
/// [size] wide. [face] overrides the tile colour (pending, last move);
/// [ring] draws a selection ring.
class LetterTile extends StatelessWidget {
  /// The letter shown; empty for a blank on the rack.
  final String letter;
  final int points;
  final bool blank;
  final double size;
  final Color? face;
  final Color? ring;
  final bool lifted;

  const LetterTile({
    super.key,
    required this.letter,
    required this.points,
    this.blank = false,
    required this.size,
    this.face,
    this.ring,
    this.lifted = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = WordTilesColors.of(context);
    final showPoints = !blank && size >= 18;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: face ?? c.tile,
        borderRadius: BorderRadius.circular(size * 0.14),
        border: Border.all(color: ring ?? c.tileEdge, width: ring != null ? (size * 0.08).clamp(1.5, 3.5) : 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x55000000),
            blurRadius: lifted ? size * 0.2 : size * 0.04,
            offset: Offset(0, lifted ? size * 0.1 : size * 0.04),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              letter,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: size * 0.56,
                height: 1,
                fontWeight: blank ? FontWeight.w500 : FontWeight.w700,
                color: blank ? c.blankInk : c.tileInk,
              ),
            ),
          ),
          if (showPoints)
            Positioned(
              right: size * 0.07,
              bottom: size * 0.04,
              child: Text(
                '$points',
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: size * 0.24, height: 1, fontWeight: FontWeight.w600, color: c.tileInk),
              ),
            ),
        ],
      ),
    );
  }
}

/// The letter picker for a blank: every letter of [tileSet] as a button.
/// Pops the chosen letter (null when cancelled).
class BlankLetterDialog extends StatelessWidget {
  final TileSet tileSet;
  const BlankLetterDialog({super.key, required this.tileSet});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final letters = tileSet.letters;
    return AlertDialog(
      key: const Key('wordtiles-blank-picker'),
      title: Text(l10n.wordtilesBlankTitle),
      content: SingleChildScrollView(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final l in letters)
                InkWell(
                  key: Key('wordtiles-blank-$l'),
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Navigator.of(context).pop(l),
                  child: LetterTile(letter: l, points: 0, blank: true, size: 40),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('wordtiles-blank-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.shellCancel),
        ),
      ],
    );
  }
}

/// Menu illustration: a corner of the board with three tiles.
class WordTilesIllustration extends CustomPainter {
  final Brightness brightness;
  const WordTilesIllustration(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final c = brightness == Brightness.dark ? WordTilesColors.dark : WordTilesColors.light;
    final s = size.shortestSide * 0.86;
    final r = Rect.fromCenter(center: size.center(Offset.zero), width: s, height: s);
    const n = 4;
    final cell = r.width / n;
    final rr = RRect.fromRectAndRadius(r, Radius.circular(cell * 0.18));
    canvas.drawRRect(rr.shift(Offset(0, cell * 0.08)), Paint()..color = Colors.black.withValues(alpha: 0.18));
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(r, Paint()..color = c.board);
    const premiums = {(0, 0): Premium.tripleWord, (3, 1): Premium.doubleLetter, (1, 3): Premium.doubleWord};
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final cellRect = Rect.fromLTWH(r.left + col * cell, r.top + row * cell, cell, cell).deflate(cell * 0.04);
        final p = premiums[(row, col)];
        if (p != null) canvas.drawRect(cellRect, Paint()..color = c.premium(p));
      }
    }
    canvas.restore();
    void tile(int row, int col, String letter) {
      final t = Rect.fromLTWH(r.left + col * cell, r.top + row * cell, cell, cell).deflate(cell * 0.07);
      final tr = RRect.fromRectAndRadius(t, Radius.circular(cell * 0.14));
      canvas.drawRRect(tr.shift(Offset(0, cell * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.25));
      canvas.drawRRect(tr, Paint()..color = c.tile);
      canvas.drawRRect(
          tr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = c.tileEdge);
      final tp = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(color: c.tileInk, fontSize: cell * 0.55, fontWeight: FontWeight.w700, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, t.center - Offset(tp.width / 2, tp.height / 2));
    }

    // Two words crossing at the A.
    tile(1, 0, 'W');
    tile(1, 1, 'A');
    tile(1, 2, 'L');
    tile(2, 1, 'B');
    tile(0, 1, 'K');
  }

  @override
  bool shouldRepaint(WordTilesIllustration old) => old.brightness != brightness;
}
