import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../shell/game_screen.dart';
import 'schiffe_draft.dart';
import 'schiffe_grid.dart';

/// Width from which the setup is laid out side by side.
const _wideBreakpoint = 600.0;

/// Fleet placement of [viewer] (KLD-068). The layout is edited locally in a
/// [SchiffeDraft] and only submitted (as the engine's `place` moves, in
/// fleet order) when the player taps "Fertig":
///
/// * "Zufällig" sets the whole fleet; everything stays editable.
/// * Tap a ship to select it (outlined), tap it again to turn it around the
///   tapped cell (other cells are tried if that does not fit).
/// * Drag a ship to move it, or tap a free cell to move the selected ship
///   there. The footprint is previewed green (fits) or red.
/// * "Drehen" turns the selected ship, or switches the orientation of the
///   next ship from the harbour. "Entfernen" puts the selected ship back,
///   "Zurücksetzen" clears the board.
/// * An invalid move or turn flashes red, shakes the board (not with reduced
///   motion) and explains why in the hint line.
///
/// Over the network the player can arrange the fleet while the opponent is
/// still placing; "Fertig" works once it is their turn. In hot-seat the
/// shell's handover cover hides the board between the players.
class SchiffeSetup extends StatefulWidget {
  final GameController controller;
  final Player viewer;

  const SchiffeSetup({super.key, required this.controller, required this.viewer});

  @override
  State<SchiffeSetup> createState() => _SchiffeSetupState();
}

class _SchiffeSetupState extends State<SchiffeSetup> with SingleTickerProviderStateMixin {
  final Random _rng = Random();
  SchiffeDraft? _draft;

  /// Explicitly selected ship (placed or in the harbour). Without one, the
  /// first ship in the harbour is the active one.
  int? _selected;

  /// Orientation of a ship placed from the harbour.
  bool _horizontal = true;

  /// Cell under the finger / mouse (unclamped while dragging a ship).
  (int, int)? _hover;

  /// Ship being dragged, the index of the grabbed cell, the cell where the
  /// pointer went down and whether it left that cell.
  int? _dragShip;
  int _grab = 0;
  (int, int)? _down;
  bool _moved = false;

  /// Cells flashed red after an invalid action, and the explanation.
  Set<int> _flash = const {};
  String? _message;

  bool _submitting = false;
  bool _submitFailed = false;

  late final AnimationController _fx = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _flash = const {});
    });

  GameController get controller => widget.controller;
  SchiffeGame get game => controller.game as SchiffeGame;
  Player get me => widget.viewer;

  @override
  void dispose() {
    _fx.dispose();
    super.dispose();
  }

  /// The draft, rebuilt when the engine's placements no longer match it (an
  /// undo, or ships placed elsewhere); kept while "Fertig" submits.
  SchiffeDraft _syncDraft() {
    final committed = game.placements(me);
    final d = _draft;
    final ok = d != null &&
        d.fleet.length == game.fleet.length &&
        committed.length >= d.locked &&
        [for (var i = 0; i < committed.length; i++) committed[i] == d[i]].every((x) => x);
    if (ok) return d;
    _selected = null;
    return _draft = SchiffeDraft(game.fleet, committed);
  }

  /// The player can change the layout: own setup not submitted yet.
  bool get _editable => game.phase == SchiffePhase.setup && game.nextShipIndex(me) != null && !_submitting;

  int? _active(SchiffeDraft d) => _selected ?? d.firstUnplaced;

  // ------------------------------------------------------------ actions

  void _ok() {
    _message = null;
    _submitFailed = false;
  }

  void _invalid(Iterable<List<int>> cells, String message) {
    _flash = {
      for (final c in cells)
        if (c[0] >= 0 && c[1] >= 0 && c[0] < SchiffeGame.size && c[1] < SchiffeGame.size) c[0] * SchiffeGame.size + c[1],
    };
    _message = message;
    _fx.forward(from: 0);
  }

  /// A tap on cell ([r], [c]) (pointer or screen reader).
  void _tapCell(int r, int c, AppLocalizations l10n) {
    final d = _draft!;
    final s = d.shipAt(r, c);
    if (s != null && !d.isLocked(s)) {
      _tapShip(s, d[s]!.indexOf(r, c)!, l10n);
    } else {
      _moveActiveTo(r, c, l10n);
    }
  }

  void _tapShip(int s, int pivot, AppLocalizations l10n) {
    final d = _draft!;
    if (_selected != s) {
      _selected = s;
      _ok();
      return;
    }
    if (d.rotate(s, pivot: pivot)) {
      _ok();
    } else {
      _invalid(d[s]!.rotated(pivot: pivot).cells, l10n.schiffeInvalidRotate);
    }
  }

  /// Places the active ship (from the harbour) or moves the selected placed
  /// ship with its top-left cell at ([r], [c]).
  void _moveActiveTo(int r, int c, AppLocalizations l10n) {
    final d = _draft!;
    final a = _active(d);
    if (a == null) return;
    final cur = d[a];
    final p = cur?.movedTo(r, c) ?? ShipPlacement(length: d.fleet[a], row: r, col: c, horizontal: _horizontal);
    if (d.place(a, p)) {
      _ok();
      if (cur == null) _selected = null; // next ship from the harbour
    } else {
      _invalid(p.cells, l10n.schiffeInvalidPlace);
    }
  }

  void _rotate(AppLocalizations l10n) {
    final d = _draft!;
    final a = _active(d);
    setState(() {
      if (a != null && d[a] != null) {
        if (d.rotate(a)) {
          _ok();
        } else {
          _invalid(d[a]!.rotated().cells, l10n.schiffeInvalidRotate);
        }
      } else {
        _horizontal = !_horizontal;
        _ok();
      }
    });
  }

  void _random() => setState(() {
        _draft!.randomize(_rng.nextInt(1 << 31));
        _selected = null;
        _ok();
      });

  void _remove() => setState(() {
        _draft!.remove(_selected!);
        _ok();
      });

  void _reset() => setState(() {
        _draft!.reset();
        _selected = null;
        _ok();
      });

  void _select(int i) => setState(() {
        _selected = i;
        _ok();
      });

  Future<void> _done() async {
    final moves = _draft!.moves();
    setState(() {
      _submitting = true;
      _ok();
    });
    var failed = false;
    for (final m in moves) {
      final r = await controller.submit(m);
      if (!r.isAccepted) {
        failed = true;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitFailed = failed;
    });
  }

  // ------------------------------------------------------------ pointer

  (int, int) _rawCell(Offset p, double unit) => ((p.dy / unit).floor(), (p.dx / unit).floor());

  bool _onBoard((int, int) c) => c.$1 >= 0 && c.$2 >= 0 && c.$1 < SchiffeGame.size && c.$2 < SchiffeGame.size;

  void _pointerDown(Offset p, double unit) {
    final cell = _rawCell(p, unit);
    final d = _draft!;
    final s = _onBoard(cell) ? d.shipAt(cell.$1, cell.$2) : null;
    setState(() {
      _down = cell;
      _hover = cell;
      _moved = false;
      _dragShip = s != null && !d.isLocked(s) ? s : null;
      if (_dragShip != null) _grab = d[s!]!.indexOf(cell.$1, cell.$2)!;
    });
  }

  void _pointerMove(Offset p, double unit) {
    final cell = _rawCell(p, unit);
    if (cell == _hover) return;
    setState(() {
      _hover = cell;
      if (cell != _down) _moved = true;
    });
  }

  void _pointerUp(PointerEvent e, double unit, AppLocalizations l10n) {
    final cell = _rawCell(e.localPosition, unit);
    final d = _draft!;
    setState(() {
      final s = _dragShip;
      if (s != null && _moved) {
        final p = _dragTarget(d, s, cell);
        _selected = s;
        if (d.place(s, p)) {
          _ok();
        } else {
          _invalid(p.cells, l10n.schiffeInvalidPlace);
        }
      } else if (_onBoard(cell)) {
        _tapCell(cell.$1, cell.$2, l10n);
      }
      _dragShip = null;
      _down = null;
      _moved = false;
      if (e.kind != PointerDeviceKind.mouse) _hover = null;
    });
  }

  void _pointerCancel() => setState(() {
        _dragShip = null;
        _down = null;
        _moved = false;
        _hover = null;
      });

  void _mouseHover(Offset p, double unit) {
    if (_dragShip != null) return;
    final cell = _rawCell(p, unit);
    if (cell != _hover) setState(() => _hover = _onBoard(cell) ? cell : null);
  }

  ShipPlacement _dragTarget(SchiffeDraft d, int s, (int, int) cell) {
    final ship = d[s]!;
    return ship.horizontal ? ship.movedTo(cell.$1, cell.$2 - _grab) : ship.movedTo(cell.$1 - _grab, cell.$2);
  }

  /// The footprint under the pointer and whether it fits; null for none.
  (ShipPlacement, bool)? _preview(SchiffeDraft d) {
    final h = _hover;
    if (h == null || !_editable) return null;
    final s = _dragShip;
    if (s != null) {
      if (!_moved) return null;
      final p = _dragTarget(d, s, h);
      return (p, d.canPlace(s, p));
    }
    if (!_onBoard(h)) return null;
    final a = _active(d);
    if (a == null) return null;
    final onShip = d.shipAt(h.$1, h.$2);
    if (onShip != null && onShip != a) return null; // a tap there selects that ship
    if (onShip == a && d[a] != null) return null; // a tap there turns it
    final p = d[a]?.movedTo(h.$1, h.$2) ?? ShipPlacement(length: d.fleet[a], row: h.$1, col: h.$2, horizontal: _horizontal);
    return (p, d.canPlace(a, p));
  }

  // -------------------------------------------------------------- build

  String? _hint(AppLocalizations l10n, SchiffeDraft d, int? active, bool activePlaced, bool canAct, Player opp,
      String Function(int) shipLabel) {
    if (_submitFailed) return l10n.schiffeSubmitFailed;
    if (game.nextShipIndex(me) == null) {
      return game.phase == SchiffePhase.setup ? l10n.schiffeHintWaiting(playerMark(opp)) : null;
    }
    if (_submitting) return null;
    if (_message != null) return _message;
    if (!canAct) return l10n.schiffeHintEarly(playerMark(opp));
    if (active != null && activePlaced && _selected != null) return l10n.schiffeHintSelected(shipLabel(active));
    if (active != null) return l10n.schiffeHintSetup;
    return l10n.schiffeHintReady;
  }

  @override
  Widget build(BuildContext context) {
    final d = _syncDraft();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = KlunkiPalette.of(context);
    final accent = palette.accent('schiffe').onSurface(theme.brightness);
    final editable = _editable;
    if (!editable) {
      _dragShip = null;
      _hover = null;
    }
    final canAct = controller.canAct;
    final opp = me == Player.a ? Player.b : Player.a;
    final active = editable ? _active(d) : null;
    final activePlaced = active != null && d[active] != null;
    String shipLabel(int i) => l10n.schiffeShipWithLength(localizedShipName(l10n, d.fleet[i]), d.fleet[i]);

    GameScreen.of(context).setHint(_hint(l10n, d, active, activePlaced, canAct, opp, shipLabel));

    // ---- grid
    final preview = _preview(d);
    final previewCells = <int>{
      if (preview != null)
        for (final c in preview.$1.cells)
          if (_onBoard((c[0], c[1]))) c[0] * SchiffeGame.size + c[1],
    };
    final previewLook = preview == null ? null : (preview.$2 ? SvPreview.valid : SvPreview.invalid);
    final selectedShip = activePlaced && _selected != null ? d[active] : null;

    final grid = SchiffeGrid(
      outlines: [?selectedShip],
      outlineColor: accent,
      cellBuilder: (r, c) {
        final i = r * SchiffeGame.size + c;
        final s = d.shipAt(r, c);
        final look = s == null ? SvLook.water : SvLook.ship;
        final selected = s != null && d[s] == selectedShip;
        final what = s == null
            ? l10n.schiffeLookWater
            : selected
                ? '${shipLabel(s)}, ${l10n.schiffeSelected}'
                : shipLabel(s);
        return SchiffeCellView(
          key: Key('sv-own-$r-$c'),
          look: look,
          selected: selected,
          preview: _flash.contains(i) ? SvPreview.invalid : (previewCells.contains(i) ? previewLook : null),
          semanticLabel: l10n.schiffeCellLabel(svCellName(r, c), what),
          onSemanticTap: editable ? () => setState(() => _tapCell(r, c, l10n)) : null,
        );
      },
      wrapCells: editable
          ? (cells, unit) => Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _pointerDown(e.localPosition, unit),
                onPointerMove: (e) => _pointerMove(e.localPosition, unit),
                onPointerUp: (e) => _pointerUp(e, unit, l10n),
                onPointerCancel: (_) => _pointerCancel(),
                child: MouseRegion(
                  onHover: (e) => _mouseHover(e.localPosition, unit),
                  onExit: (_) {
                    if (_dragShip == null && _hover != null) setState(() => _hover = null);
                  },
                  child: cells,
                ),
              )
          : null,
    );
    final shaking = reduceMotion(context)
        ? grid
        : AnimatedBuilder(
            animation: _fx,
            builder: (context, child) {
              final t = _fx.value;
              final dx = _fx.isAnimating ? sin(t * pi * 6) * 8 * (1 - t) : 0.0;
              return Transform.translate(key: const Key('sv-shake'), offset: Offset(dx, 0), child: child);
            },
            child: grid,
          );

    // ---- title
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          active == null ? l10n.schiffeFleetComplete : shipLabel(active),
          key: const Key('sv-next-ship'),
          style: theme.textTheme.titleLarge,
        ),
        Text(l10n.schiffeSetupCount(d.placedCount, d.fleet.length, playerMark(me))),
      ],
    );

    // ---- buttons
    final horizontal = activePlaced ? d[active]!.horizontal : _horizontal;
    final orientation = horizontal ? l10n.schiffeHorizontal : l10n.schiffeVertical;
    final rotate = Semantics(
      label: l10n.schiffeRotateSemantics(orientation),
      excludeSemantics: true,
      button: true,
      enabled: editable && active != null,
      onTap: editable && active != null ? () => _rotate(l10n) : null,
      child: FilledButton.tonal(
        key: const Key('sv-rotate'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          backgroundColor: palette.accent('schiffe').container,
          foregroundColor: theme.brightness == Brightness.dark ? Colors.white : palette.accent('schiffe').color,
        ),
        onPressed: editable && active != null ? () => _rotate(l10n) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rotate_right),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.schiffeRotate, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    orientation,
                    key: const Key('sv-orientation'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(horizontal ? Icons.swap_horiz : Icons.swap_vert, size: 20),
          ],
        ),
      ),
    );
    final random = FilledButton.tonalIcon(
      key: const Key('sv-random'),
      style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
      onPressed: editable ? _random : null,
      icon: const Icon(Icons.casino_outlined),
      label: Text(l10n.schiffeRandom, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    final canRemove = editable && _selected != null && d[_selected!] != null && !d.isLocked(_selected!);
    final remove = IconButton.outlined(
      key: const Key('sv-remove'),
      tooltip: l10n.schiffeRemoveTooltip,
      onPressed: canRemove ? _remove : null,
      icon: const Icon(Icons.anchor),
    );
    final canReset = editable && d.placedCount > d.locked;
    final reset = IconButton.outlined(
      key: const Key('sv-reset'),
      tooltip: l10n.schiffeReset,
      onPressed: canReset ? _reset : null,
      icon: const Icon(Icons.restart_alt),
    );
    final done = FilledButton.icon(
      key: const Key('sv-done'),
      style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
      onPressed: editable && canAct && d.complete ? _done : null,
      icon: const Icon(Icons.check),
      label: Text(l10n.schiffeDone),
    );

    // ---- harbour (all ships; placed ones ticked)
    Widget trayItem(int i, {required bool dense}) => _TrayItem(
          key: Key('sv-fleet-$i'),
          length: d.fleet[i],
          label: shipLabel(i),
          placed: d.isPlaced(i),
          selected: editable && i == active,
          accent: accent,
          dense: dense,
          selectedLabel: l10n.schiffeSelected,
          placedLabel: l10n.schiffeShipPlaced(localizedShipName(l10n, d.fleet[i]), d.fleet[i]),
          onTap: editable && !d.isLocked(i) ? () => _select(i) : null,
        );

    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= _wideBreakpoint) {
          final panelTop = [
            title,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: rotate),
                const SizedBox(width: 8),
                Expanded(child: random),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [remove, const SizedBox(width: 8), reset]),
            const SizedBox(height: 12),
            Text(l10n.schiffeHarbour, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
          ];
          final tray = [for (var i = 0; i < d.fleet.length; i++) trayItem(i, dense: false)];
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: shaking),
                const SizedBox(width: 16),
                SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...panelTop, ...tray]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      done,
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: rotate),
                  const SizedBox(width: 8),
                  Expanded(child: random),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(child: shaking),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [for (var i = 0; i < d.fleet.length; i++) trayItem(i, dense: true)],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  remove,
                  const SizedBox(width: 8),
                  reset,
                  const SizedBox(width: 12),
                  Expanded(child: done),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One ship of the harbour list: a small ship drawing plus its name; ticked
/// when it is on the board, outlined in the accent when selected.
class _TrayItem extends StatelessWidget {
  final int length;
  final String label, placedLabel, selectedLabel;
  final bool placed, selected, dense;
  final Color accent;
  final VoidCallback? onTap;

  const _TrayItem({
    super.key,
    required this.length,
    required this.label,
    required this.placedLabel,
    required this.selectedLabel,
    required this.placed,
    required this.selected,
    required this.dense,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sea = KlunkiPalette.of(context).schiffe;
    final scheme = theme.colorScheme;
    final ship = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++)
          Container(
            width: 9,
            height: 12,
            margin: const EdgeInsets.only(right: 1.5),
            decoration: BoxDecoration(
              color: placed ? sea.ship.withValues(alpha: 0.35) : sea.ship,
              border: Border.all(color: sea.shipEdge, width: 0.8),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(i == 0 ? 5 : 1.5),
                right: Radius.circular(i == length - 1 ? 5 : 1.5),
              ),
            ),
          ),
      ],
    );
    final content = Row(
      mainAxisSize: dense ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Icon(
          placed ? Icons.check_circle : Icons.directions_boat_outlined,
          size: 18,
          color: placed ? Colors.green.shade600 : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        ship,
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: placed ? scheme.onSurfaceVariant : scheme.onSurface,
            ),
          ),
        ),
      ],
    );
    return Padding(
      padding: dense ? const EdgeInsetsDirectional.only(end: 6) : const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        button: true,
        selected: selected,
        label: selected ? '${placed ? placedLabel : label}, $selectedLabel' : (placed ? placedLabel : label),
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: selected ? accent.withValues(alpha: 0.16) : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: selected ? accent : Colors.transparent, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Align(alignment: AlignmentDirectional.centerStart, widthFactor: 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
