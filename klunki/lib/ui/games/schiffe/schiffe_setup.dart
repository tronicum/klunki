import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../../profile/seen_tips.dart';
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
/// * Tap a ship to select it (outlined, ↻ on its middle cell), tap it again
///   to turn it around its middle (other cells are tried if that does not
///   fit; KLD-107, before: around the tapped cell).
/// * Drag a ship to move it, or tap a free cell to move the selected ship
///   there. The footprint is previewed green (fits) or red.
/// * "Drehen" turns the selected ship, or switches the orientation of the
///   next ship from the harbour. "Entfernen" puts the selected ship back,
///   "Zurücksetzen" clears the board.
/// * An invalid move or turn flashes red, shakes the board (not with reduced
///   motion) and explains why in the hint line.
/// * KLD-107: a "next piece" preview box (tap = "Drehen"), a dock of all
///   ships, a ↻ badge on the selected ship and a one-time tip after the
///   first placement make these gestures discoverable.
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

class _SchiffeSetupState extends State<SchiffeSetup> with TickerProviderStateMixin {
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

  /// The first ship placed from the harbour gets a tip bubble ("tap it:
  /// move or turn", KLD-107) until the next interaction; once per install
  /// ([SeenTips.schiffeMove]).
  int? _coach;

  /// Next-ship preview: the ship it shows, its orientation and the quarter
  /// turns drawn (a turn of the same ship animates, another ship jumps).
  int? _pvShip;
  bool? _pvHorizontal;
  int _pvTurns = 0;

  /// Successful turns of a placed ship (spins the ↻ badge).
  int _spins = 0;

  /// The shake after an invalid action.
  late final AnimationController _fx = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  /// How long the reason banner and the red cells stay (KLD-107).
  static const reasonDuration = Duration(milliseconds: 2600);

  /// Reason banner over the board after an invalid action (KLD-107), at the
  /// top or bottom edge (away from the red cells); null when none.
  String? _reason;
  bool _reasonTop = false;
  late final AnimationController _reasonFx = AnimationController(vsync: this, duration: reasonDuration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() {
          _flash = const {};
          _reason = null;
        });
      }
    });

  /// Idle cue (KLD-107): after [idleDelay] without input the next ship in
  /// the dock and the preview pulse three times (the sea's edge too while
  /// it is still empty), then again every [idleRepeat]. Not with reduced
  /// motion (a static highlight instead), not once the fleet is complete.
  static const idleDelay = Duration(seconds: 4);
  static const idleRepeat = Duration(seconds: 8);
  Timer? _idle;
  late final AnimationController _cue = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        _cue.value = 0;
        _idle?.cancel();
        _idle = Timer(idleRepeat, _onIdle);
      }
    });

  /// Pulse strength 0..1 of the idle cue right now.
  double get _cuePulse => _cue.isAnimating ? sin(_cue.value * pi * 3).abs() : 0;

  /// Input: stop the cue and start counting the idle time again.
  void _poke() {
    _idle?.cancel();
    if (_cue.isAnimating) _cue.value = 0;
    _idle = Timer(idleDelay, _onIdle);
  }

  void _onIdle() {
    if (!mounted || !_editable || reduceMotion(context) || _dragShip != null || _down != null) return;
    final d = _draft;
    final a = d == null ? null : _active(d);
    if (a == null || d![a] != null) return; // complete, or a placed ship selected
    _cue.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _poke();
  }

  GameController get controller => widget.controller;
  SchiffeGame get game => controller.game as SchiffeGame;
  Player get me => widget.viewer;

  @override
  void dispose() {
    _idle?.cancel();
    _cue.dispose();
    _reasonFx.dispose();
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

  /// The player can change the layout: own setup not submitted yet, and
  /// the game not ended by a resign during the setup (KLD-065).
  bool get _editable =>
      !game.isOver && game.phase == SchiffePhase.setup && game.nextShipIndex(me) != null && !_submitting;

  int? _active(SchiffeDraft d) => _selected ?? d.firstUnplaced;

  // ------------------------------------------------------------ actions

  void _ok() {
    _message = null;
    _submitFailed = false;
    _coach = null;
    _poke();
  }

  /// Flashes [cells] red (with the shake), names the reason in the hint
  /// line and in a banner over the board for [reasonDuration].
  void _invalid(Iterable<List<int>> cells, String message) {
    _flash = {
      for (final c in cells)
        if (c[0] >= 0 && c[1] >= 0 && c[0] < SchiffeGame.size && c[1] < SchiffeGame.size) c[0] * SchiffeGame.size + c[1],
    };
    _message = message;
    _reason = message;
    final rows = [for (final i in _flash) i ~/ SchiffeGame.size];
    _reasonTop = rows.isNotEmpty && rows.reduce((a, b) => a + b) / rows.length >= SchiffeGame.size / 2;
    _fx.forward(from: 0);
    _reasonFx.forward(from: 0);
    _poke();
  }

  /// Cells of the other ships that [p] (for ship [s]) would touch or cover,
  /// diagonals included (the engine's rule: no contact at all).
  List<List<int>> _conflicts(SchiffeDraft d, int s, ShipPlacement p) => [
        for (var j = 0; j < d.fleet.length; j++)
          if (j != s && d[j] != null)
            for (final o in d[j]!.cells)
              if (p.cells.any((c) => (c[0] - o[0]).abs() <= 1 && (c[1] - o[1]).abs() <= 1)) o,
      ];

  /// Ship [s] does not fit at [p]: off the board, or touching another ship
  /// (whose cells flash too).
  void _invalidPlace(int s, ShipPlacement p, AppLocalizations l10n) {
    final off = p.cells.any((c) => !_onBoard((c[0], c[1])));
    final near = off ? const <List<int>>[] : _conflicts(_draft!, s, p);
    _invalid(
      [...p.cells, ...near],
      off ? l10n.schiffeInvalidOffBoard : (near.isNotEmpty ? l10n.schiffeInvalidTouch : l10n.schiffeInvalidPlace),
    );
  }

  /// A tap on cell ([r], [c]) (pointer or screen reader).
  void _tapCell(int r, int c, AppLocalizations l10n) {
    final d = _draft!;
    final s = d.shipAt(r, c);
    if (s != null && !d.isLocked(s)) {
      _tapShip(s, l10n);
    } else {
      _moveActiveTo(r, c, l10n);
    }
  }

  /// A tap on placed ship [s]: selects it, or turns it when it is selected.
  void _tapShip(int s, AppLocalizations l10n) {
    if (_selected != s) {
      _selected = s;
      _ok();
      return;
    }
    _turn(s, l10n);
  }

  /// Turns placed ship [s] in place (around its middle, else another cell);
  /// an invalid turn flashes where it would go and explains.
  void _turn(int s, AppLocalizations l10n) {
    final d = _draft!;
    if (d.rotate(s)) {
      _ok();
      _spins++;
    } else {
      final turned = d[s]!.rotated(pivot: SchiffeDraft.middle(d.fleet[s]));
      _invalid([...turned.cells, ..._conflicts(d, s, turned)], l10n.schiffeInvalidRotate);
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
      if (cur == null) {
        _selected = null; // next ship from the harbour
        if (SeenTips.shared.markFirst(SeenTips.schiffeMove)) _coach = a;
      }
    } else {
      _invalidPlace(a, p, l10n);
    }
  }

  void _rotate(AppLocalizations l10n) {
    final d = _draft!;
    final a = _active(d);
    setState(() {
      if (a != null && d[a] != null) {
        _turn(a, l10n);
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
        // A resign meanwhile ends the game: nothing failed (KLD-065).
        failed = !game.isOver;
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
    _poke();
    setState(() {
      _coach = null;
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
          _invalidPlace(s, p, l10n);
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
    if (game.isOver) return null; // resigned during the setup: the shell shows the result
    if (_submitFailed) return l10n.schiffeSubmitFailed;
    if (game.nextShipIndex(me) == null) {
      return game.phase == SchiffePhase.setup ? l10n.schiffeHintWaiting(playerName(context, opp)) : null;
    }
    if (_submitting) return null;
    if (_message != null) return _message;
    if (!canAct) return l10n.schiffeHintEarly(playerName(context, opp));
    if (active != null && activePlaced && _selected != null) return l10n.schiffeHintSelected(shipLabel(active));
    if (active != null && d.placedCount > 0) return l10n.schiffeHintSetupMore;
    if (active != null) return l10n.schiffeHintSetup;
    return l10n.schiffeHintReady;
  }

  /// [child] pulsing (scale and glow) with the idle cue when [on]; with
  /// [still] only the glow (or nothing; reduced motion).
  Widget _cued(bool on, Color accent, bool still, Widget child, {Key key = const Key('sv-cue')}) {
    if (!on) return child;
    return AnimatedBuilder(
      animation: _cue,
      child: child,
      builder: (context, child) {
        final p = _cuePulse;
        return Transform.scale(
          key: key,
          scale: still ? 1 : 1 + 0.07 * p,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (p > 0) BoxShadow(color: accent.withValues(alpha: 0.55 * p), blurRadius: 12 * p, spreadRadius: 2 * p),
              ],
            ),
            child: child,
          ),
        );
      },
    );
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
    final nextUnplaced = editable && active != null && !activePlaced ? active : null;
    final staticCue = reduceMotion(context);
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

    final dragging = _dragShip != null && _moved;
    final coachShip = _coach == null ? null : d[_coach!];
    final grid = SchiffeGrid(
      outlines: [?selectedShip],
      outlineColor: accent,
      overlays: (unit) => [
        // ↻ on the middle cell of the selected ship: tapping the selected
        // ship turns it around the tapped cell, so this turns it in place.
        if (selectedShip != null && editable && !dragging)
          _RotateBadge(ship: selectedShip, unit: unit, color: accent, spins: _spins),
        if (coachShip != null && editable && selectedShip == null && !dragging)
          _CoachBubble(ship: coachShip, unit: unit, text: l10n.schiffeCoachTap),
        // The empty sea invites the first tap (part of the idle cue).
        if (editable && d.placedCount == 0)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _cue,
                builder: (context, _) => _cuePulse == 0
                    ? const SizedBox.shrink()
                    : DecoratedBox(
                        key: const Key('sv-sea-cue'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: accent.withValues(alpha: 0.75 * _cuePulse), width: 4),
                          color: accent.withValues(alpha: 0.08 * _cuePulse),
                        ),
                      ),
              ),
            ),
          ),
        if (_reason != null)
          _ReasonBanner(
            key: const Key('sv-reason'),
            text: _reason!,
            top: _reasonTop,
            fade: _reasonFx,
            direction: Directionality.of(context), // the board itself is LTR
          ),
      ],
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

    // ---- next-ship preview (KLD-107) and title
    final horizontal = activePlaced ? d[active]!.horizontal : _horizontal;
    final orientation = horizontal ? l10n.schiffeHorizontal : l10n.schiffeVertical;
    if (active != _pvShip) {
      _pvTurns = horizontal ? 0 : 1;
    } else if (horizontal != _pvHorizontal) {
      _pvTurns++;
    }
    _pvShip = active;
    _pvHorizontal = horizontal;
    // Ships of the active one's length still in the harbour (itself included).
    final left = active == null || activePlaced
        ? 0
        : [for (var i = 0; i < d.fleet.length; i++) if (!d.isPlaced(i) && d.fleet[i] == d.fleet[active]) i].length;
    Widget previewBox(double size) => _ShipPreview(
          key: const Key('sv-preview'),
          ship: active,
          length: active == null ? null : d.fleet[active],
          turns: _pvTurns,
          left: left,
          size: size,
          accent: accent,
          semanticLabel: active == null
              ? l10n.schiffeFleetComplete
              : [
                  l10n.schiffePreviewSemantics(shipLabel(active), orientation),
                  if (left > 0) l10n.schiffePreviewLeft(left),
                ].join(', '),
          onTap: editable && active != null ? () => _rotate(l10n) : null,
        );
    Widget title(double previewSize) => Row(
          children: [
            _cued(nextUnplaced != null, accent, true, previewBox(previewSize), key: const Key('sv-preview-cue')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    active == null ? l10n.schiffeFleetComplete : shipLabel(active),
                    key: const Key('sv-next-ship'),
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l10n.schiffeSetupCount(d.placedCount, d.fleet.length, playerName(context, me)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

    // ---- buttons
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
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.schiffeDone, maxLines: 1, overflow: TextOverflow.ellipsis),
          // Why it is still disabled (KLD-107).
          if (editable && !d.complete)
            Text(
              l10n.schiffeDoneLeft(d.fleet.length - d.placedCount),
              key: const Key('sv-done-left'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
        ],
      ),
    );

    // ---- harbour (all ships; placed ones ticked)
    Widget trayItem(int i, {required bool dense}) => _cued(
          i == nextUnplaced,
          accent,
          staticCue,
          _TrayItem(
          key: Key('sv-fleet-$i'),
          emphasis: i == nextUnplaced && staticCue,
          length: d.fleet[i],
          label: shipLabel(i),
          placed: d.isPlaced(i),
          selected: editable && i == active,
          accent: accent,
          dense: dense,
          selectedLabel: l10n.schiffeSelected,
          placedLabel: l10n.schiffeShipPlaced(localizedShipName(l10n, d.fleet[i]), d.fleet[i]),
          onTap: editable && !d.isLocked(i) ? () => _select(i) : null,
        ),
        );

    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= _wideBreakpoint) {
          final panelTop = [
            title(84),
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
              title(64),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: rotate),
                  const SizedBox(width: 8),
                  Expanded(child: random),
                ],
              ),
              const SizedBox(height: 8),
              // The board as large as fits, the dock right under it; spare
              // height (a tall phone) goes above the action row, not into
              // gaps around the board (KLD-107).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, box) =>
                            SizedBox(height: min(box.maxWidth, box.maxHeight), child: shaking),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // The dock: every ship as a small shape, placed ones
                    // ticked and faded, the active one outlined (KLD-107).
                    Row(
                      children: [
                        for (var i = 0; i < d.fleet.length; i++) Expanded(child: trayItem(i, dense: true)),
                      ],
                    ),
                  ],
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

  /// Stronger static outline for the next ship (the idle cue with reduced
  /// motion, KLD-107).
  final bool emphasis;
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
    this.emphasis = false,
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
    // Dense (the phone dock): only the shape, scaled to the slot, with a
    // tick when it is on the board.
    final content = dense
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (placed) ...[
                  Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 3),
                ],
                ship,
              ],
            ),
          )
        : Row(
      mainAxisSize: MainAxisSize.max,
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
      padding: dense ? const EdgeInsets.symmetric(horizontal: 2) : const EdgeInsets.symmetric(vertical: 2),
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
            side: BorderSide(color: selected ? accent : Colors.transparent, width: emphasis ? 3.5 : 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: dense ? 4 : 10),
                child: dense
                    ? Center(child: content)
                    : Align(alignment: AlignmentDirectional.centerStart, widthFactor: 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One ship drawn horizontally as [length] cells of [cell] px.
Widget _shipShape(BuildContext context, int length, double cell) {
  final sea = KlunkiPalette.of(context).schiffe;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < length; i++)
        Container(
          width: cell,
          height: cell,
          margin: EdgeInsets.only(right: i == length - 1 ? 0 : cell * 0.08),
          decoration: BoxDecoration(
            border: Border.all(color: sea.shipEdge),
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(i == 0 ? cell * 0.45 : cell * 0.15),
              right: Radius.circular(i == length - 1 ? cell * 0.45 : cell * 0.15),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(sea.ship, Colors.white, 0.2)!, sea.ship],
            ),
          ),
        ),
    ],
  );
}

/// The "next piece" box of the setup (KLD-107): the active ship (next from
/// the harbour or the selected one) in its current orientation; tapping it
/// turns the ship, which the box shows as a short quarter turn. "×2" when
/// more ships of that length wait in the harbour; a tick once all are set.
class _ShipPreview extends StatelessWidget {
  final int? ship, length;
  final int turns, left;
  final double size;
  final Color accent;
  final String semanticLabel;
  final VoidCallback? onTap;

  const _ShipPreview({
    super.key,
    required this.ship,
    required this.length,
    required this.turns,
    required this.left,
    required this.size,
    required this.accent,
    required this.semanticLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sea = KlunkiPalette.of(context).schiffe;
    final n = length;
    final cell = (size - 16) / 5;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: sea.water,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: n == null ? sea.gridLine : accent, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              children: [
                Center(
                  child: n == null
                      ? Icon(Icons.check_circle, size: size * 0.5, color: Colors.green.shade600)
                      : KeyedSubtree(
                          key: ValueKey(ship),
                          child: AnimatedRotation(
                            key: const Key('sv-preview-ship'),
                            turns: turns / 4,
                            duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 280),
                            curve: Curves.easeOutBack,
                            child: _shipShape(context, n, cell),
                          ),
                        ),
                ),
                if (n != null && onTap != null)
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: Icon(Icons.rotate_right, size: size * 0.22, color: accent),
                  ),
                if (left > 1)
                  Positioned(
                    left: 4,
                    top: 3,
                    child: Text(
                      '×$left',
                      key: const Key('sv-preview-left'),
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: accent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The ↻ badge on the middle cell of the selected ship (KLD-107). Only a
/// picture: a tap anywhere on the selected ship turns it around this cell.
/// Spins a quarter on every turn.
class _RotateBadge extends StatelessWidget {
  final ShipPlacement ship;
  final double unit;
  final Color color;
  final int spins;

  const _RotateBadge({required this.ship, required this.unit, required this.color, required this.spins});

  @override
  Widget build(BuildContext context) {
    final k = SchiffeDraft.middle(ship.length);
    final r = ship.horizontal ? ship.row : ship.row + k;
    final c = ship.horizontal ? ship.col + k : ship.col;
    final inset = unit * 0.1;
    return Positioned(
      left: c * unit + inset,
      top: r * unit + inset,
      width: unit - 2 * inset,
      height: unit - 2 * inset,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedRotation(
            key: const Key('sv-rotate-badge'),
            turns: spins / 4,
            duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 280),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 1))],
              ),
              child: const FittedBox(
                child: Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.rotate_right, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-time tip bubble next to the first placed ship (KLD-107): below it,
/// or above when it sits low on the board. A picture only (the hint line
/// carries the same advice for screen readers).
class _CoachBubble extends StatelessWidget {
  final ShipPlacement ship;
  final double unit;
  final String text;

  const _CoachBubble({required this.ship, required this.unit, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const n = SchiffeGame.size;
    final width = min(unit * n - 8, max(unit * 8.5, 220.0));
    final bottomRow = ship.horizontal ? ship.row : ship.row + ship.length - 1;
    final below = bottomRow < n - 2;
    final left = (ship.col * unit).clamp(4.0, unit * n - width - 4);
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, size: 16, color: theme.colorScheme.onInverseSurface),
            const SizedBox(width: 4),
            Icon(Icons.rotate_right, size: 16, color: theme.colorScheme.onInverseSurface),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onInverseSurface),
              ),
            ),
          ],
        ),
      ),
    );
    return Positioned(
      key: const Key('sv-coach'),
      left: left,
      width: width,
      top: below ? (bottomRow + 1) * unit + 4 : null,
      bottom: below ? null : (n - ship.row) * unit + 4,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Align(alignment: Alignment.centerLeft, widthFactor: 1, child: bubble),
        ),
      ),
    );
  }
}

/// The reason after an invalid placement or turn (KLD-107): a banner over
/// the top or bottom edge of the sea, fading out at the end of [fade]. A
/// picture only: the hint line (a live region) says the same.
class _ReasonBanner extends StatelessWidget {
  final String text;
  final bool top;
  final Animation<double> fade;
  final TextDirection direction;

  const _ReasonBanner({
    super.key,
    required this.text,
    required this.top,
    required this.fade,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Positioned(
      left: 6,
      right: 6,
      top: top ? 6 : null,
      bottom: top ? null : 6,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: fade,
            builder: (context, child) =>
                Opacity(opacity: fade.value < 0.85 ? 1 : ((1 - fade.value) / 0.15).clamp(0.0, 1.0), child: child),
            child: Directionality(
              textDirection: direction,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.error, width: 1.5),
                  boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 16, color: scheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
