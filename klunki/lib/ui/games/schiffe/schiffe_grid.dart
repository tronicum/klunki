import 'dart:math';

import 'package:flutter/material.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../ltr.dart';

/// Row letters of the 10×10 grid (row 0 = A).
const svRows = 'ABCDEFGHIJ';

/// Human coordinate of a cell: row 4, col 4 → "E5".
String svCellName(int row, int col) => '${svRows[row]}${col + 1}';

/// Key of the body widget drawn for an own ship cell. Never appears on the
/// target grid (tests scan for it).
const svShipMarkerKey = ValueKey('sv-ship');

/// What a single cell shows.
enum SvLook {
  /// Plain water (own empty cell or unknown target cell).
  water,

  /// Own ship, not hit.
  ship,

  /// Shot into water: dot.
  miss,

  /// Own ship cell that was hit: ship body plus cross.
  shipHit,

  /// Hit on the target grid: cross only (the ship itself stays unknown).
  hit,

  /// Cell of a sunk ship: filled plus cross.
  sunk,
}

/// Placement preview tint.
enum SvPreview { valid, invalid }

/// One grid cell. Tests read [look] and [preview] through its key
/// (`sv-own-<r>-<c>` / `sv-target-<r>-<c>`).
class SchiffeCellView extends StatelessWidget {
  final SvLook look;
  final SvPreview? preview;
  final VoidCallback? onTap;
  final String semanticLabel;

  /// Screen-reader tap only (no gesture detector): for grids whose pointer
  /// input is handled by a surrounding listener (the setup, KLD-068).
  final VoidCallback? onSemanticTap;

  /// Part of the selected ship (screen-reader state).
  final bool selected;

  const SchiffeCellView({
    super.key,
    required this.look,
    required this.semanticLabel,
    this.preview,
    this.onTap,
    this.onSemanticTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = KlunkiPalette.of(context).schiffe;
    var bg = p.water;
    Widget? marker;
    Widget cross(Color c) => FractionallySizedBox(
      widthFactor: 0.8,
      heightFactor: 0.8,
      child: FittedBox(child: Icon(Icons.close, color: c)),
    );
    Widget shipBody() => Container(
      key: svShipMarkerKey,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: p.shipEdge),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(p.ship, Colors.white, 0.2)!, p.ship],
        ),
      ),
    );
    switch (look) {
      case SvLook.water:
        // Ghost of a ship that would fit here (setup preview, KLD-107).
        if (preview == SvPreview.valid) {
          marker = Opacity(
            key: const ValueKey('sv-ghost'),
            opacity: 0.55,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: p.shipEdge),
                color: p.ship,
              ),
            ),
          );
        }
      case SvLook.ship:
        marker = shipBody();
      case SvLook.miss:
        // A splash: white dot with a ring.
        marker = FractionallySizedBox(
          widthFactor: 0.34,
          heightFactor: 0.34,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.miss,
              shape: BoxShape.circle,
              border: Border.all(color: p.gridLine, width: 1.5),
            ),
          ),
        );
      case SvLook.shipHit:
        marker = Stack(
          fit: StackFit.expand,
          children: [
            shipBody(),
            Center(child: cross(p.hit)),
          ],
        );
      case SvLook.hit:
        bg = p.hitBg;
        marker = cross(p.hit);
      case SvLook.sunk:
        bg = p.sunk;
        marker = cross(p.onSunk);
    }
    Widget cell = Container(
      decoration: BoxDecoration(color: bg, border: Border.all(color: p.gridLine, width: 0.5)),
      foregroundDecoration: preview == null
          ? null
          : BoxDecoration(
              color: preview == SvPreview.valid ? p.previewValid : p.previewInvalid,
              borderRadius: BorderRadius.circular(2),
            ),
      alignment: Alignment.center,
      child: marker,
    );
    if (onTap != null) {
      cell = GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: cell);
    }
    return Semantics(
      label: semanticLabel,
      button: onTap != null || onSemanticTap != null,
      selected: selected ? true : null,
      onTap: onSemanticTap,
      child: cell,
    );
  }
}

/// A labelled 10×10 grid (columns 1–10 on top, rows A–J on the left) that
/// takes the largest square fitting its constraints.
class SchiffeGrid extends StatelessWidget {
  /// Widget of cell (r, c); normally a keyed [SchiffeCellView].
  final Widget Function(int row, int col) cellBuilder;

  /// Ships to outline (e.g. sunk ships).
  final List<ShipPlacement> outlines;
  final Color? outlineColor;

  /// Wraps the 10×10 cell area (not the labels); gets the cell size so
  /// pointer positions can be mapped to cells.
  final Widget Function(Widget cells, double unit)? wrapCells;

  /// Extra layers over the cells (e.g. [Positioned] badges), given the cell
  /// size; they get no pointer events (the setup maps taps itself).
  final List<Widget> Function(double unit)? overlays;

  const SchiffeGrid({
    super.key,
    required this.cellBuilder,
    this.outlines = const [],
    this.outlineColor,
    this.wrapCells,
    this.overlays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // LtrBoard: columns 1–10 run left to right and rows A–J sit on the left in
    // every locale, so taps, drag mapping and outlines match engine (row, col).
    return LtrBoard(child: LayoutBuilder(
      builder: (context, box) {
        final side = min(box.maxWidth, box.maxHeight);
        final unit = max(1.0, (side / 11).floorToDouble());
        final n = SchiffeGame.size;
        final labelStyle = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
        Widget label(String t) => SizedBox(
          width: unit,
          height: unit,
          child: Padding(
            padding: EdgeInsets.all(unit * 0.22),
            child: FittedBox(child: Text(t, style: labelStyle)),
          ),
        );
        final outlineWidth = max(2.0, unit * 0.09);
        final sea = KlunkiPalette.of(context).schiffe;
        Widget cells = Container(
          width: unit * n,
          height: unit * n,
          foregroundDecoration: BoxDecoration(
            border: Border.all(color: sea.gridLine, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
          child: Stack(
            children: [
              Column(
                children: [
                  for (var r = 0; r < n; r++)
                    Row(
                      children: [
                        for (var c = 0; c < n; c++) SizedBox(width: unit, height: unit, child: cellBuilder(r, c)),
                      ],
                    ),
                ],
              ),
              for (final o in outlines)
                Positioned(
                  left: o.col * unit,
                  top: o.row * unit,
                  width: (o.horizontal ? o.length : 1) * unit,
                  height: (o.horizontal ? 1 : o.length) * unit,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: outlineColor ?? theme.colorScheme.onSurface, width: outlineWidth),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              if (overlays != null) ...overlays!(unit),
            ],
          ),
        );
        if (wrapCells != null) cells = wrapCells!(cells, unit);
        return Center(
          child: SizedBox(
            width: unit * (n + 1),
            height: unit * (n + 1),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(width: unit, height: unit),
                    for (var c = 0; c < n; c++) label('${c + 1}'),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(children: [for (var r = 0; r < n; r++) label(svRows[r])]),
                    cells,
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ));
  }
}

/// Sunk ships visible on a target grid: connected groups of sunk cells
/// (ships never touch, so each group is one ship).
List<ShipPlacement> sunkShips(List<List<ShotMark>> grid) {
  final n = grid.length;
  final seen = List.generate(n, (_) => List.filled(n, false));
  final out = <ShipPlacement>[];
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      if (seen[r][c] || grid[r][c] != ShotMark.sunk) continue;
      final stack = [(r, c)];
      seen[r][c] = true;
      var minR = r, maxR = r, minC = c, maxC = c;
      while (stack.isNotEmpty) {
        final (cr, cc) = stack.removeLast();
        minR = min(minR, cr);
        maxR = max(maxR, cr);
        minC = min(minC, cc);
        maxC = max(maxC, cc);
        for (final (dr, dc) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
          final nr = cr + dr, nc = cc + dc;
          if (nr < 0 || nr >= n || nc < 0 || nc >= n) continue;
          if (seen[nr][nc] || grid[nr][nc] != ShotMark.sunk) continue;
          seen[nr][nc] = true;
          stack.add((nr, nc));
        }
      }
      final horizontal = maxC > minC;
      out.add(
        ShipPlacement(
          length: horizontal ? maxC - minC + 1 : maxR - minR + 1,
          row: minR,
          col: minC,
          horizontal: horizontal,
        ),
      );
    }
  }
  return out;
}
