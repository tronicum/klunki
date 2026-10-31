import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../shell/game_screen.dart';
import 'schiffe_grid.dart';

/// Width from which setup and battle are laid out side by side.
const _wideBreakpoint = 600.0;

/// The Schiffe versenken board: fleet placement (setup) and the battle with
/// own + target grid. Only ever renders one player's view (`ownGrid` /
/// `targetGrid` of [_SchiffeBoardState.viewer]): over the network this
/// device's player, in hot-seat the player to move (the shell's handover
/// cover hides it between turns).
class SchiffeBoard extends StatefulWidget {
  final GameController controller;

  const SchiffeBoard({super.key, required this.controller});

  @override
  State<SchiffeBoard> createState() => _SchiffeBoardState();
}

class _SchiffeBoardState extends State<SchiffeBoard> {
  final Random _rng = Random();
  bool _horizontal = true;

  /// Cell under the finger / mouse (anchor of the preview ship).
  (int, int)? _preview;

  GameController get controller => widget.controller;
  SchiffeGame get game => controller.game as SchiffeGame;

  /// Whose ocean this device shows: the single local player (network), or
  /// (hot-seat) the player to move. Never the remote opponent's fleet.
  Player get viewer {
    final local = controller.transport.localPlayers;
    return local.length == 1 ? local.first : game.currentPlayer;
  }

  @override
  Widget build(BuildContext context) {
    final g = game;
    final shell = GameScreen.of(context);
    final l10n = AppLocalizations.of(context);
    if (g.phase == SchiffePhase.setup) {
      final next = g.nextShipIndex(g.currentPlayer);
      shell.setHint(
        !controller.canAct || next == null
            ? null
            : l10n.schiffeHintSetup,
      );
      return _Setup(state: this);
    }
    _preview = null;
    shell.setHint(_battleHint(l10n, g));
    return _Battle(state: this);
  }

  String? _battleHint(AppLocalizations l10n, SchiffeGame g) {
    if (g.isOver) return l10n.schiffeHintAllSunk;
    if (!controller.canAct) return l10n.schiffeHintWaiting(playerMark(g.currentPlayer));
    if (_extraShot(g) != null) return l10n.schiffeHintExtraShot;
    return l10n.schiffeHintFire;
  }

  /// The last shot of the player to move if it grants another shot.
  AcceptedMove? _extraShot(SchiffeGame g) {
    final moves = controller.moves;
    if (g.isOver || moves.isEmpty) return null;
    final last = moves.last;
    if (last.move['action'] != 'fire' || last.player != g.currentPlayer) return null;
    final p = last.event.payload;
    return p is Map && p['result'] != 'miss' ? last : null;
  }

  /// The opponent's most recent shot at the player to move.
  AcceptedMove? _lastIncoming(SchiffeGame g) {
    final me = viewer;
    for (final m in controller.moves.reversed) {
      if (m.move['action'] == 'fire' && m.player != me) return m;
    }
    return null;
  }

  void _setPreview((int, int)? cell) {
    if (cell != _preview) setState(() => _preview = cell);
  }

  void _toggleRotation() => setState(() => _horizontal = !_horizontal);

  void _autoplace() => controller.submit({'action': 'autoplace', 'seed': _rng.nextInt(1 << 31)});

  void _place(int ship, int row, int col) =>
      controller.submit({'action': 'place', 'ship': ship, 'row': row, 'col': col, 'dir': _horizontal ? 'h' : 'v'});

  void _fire(int row, int col) => controller.submit({'action': 'fire', 'row': row, 'col': col});
}

(int, int)? _cellAt(Offset p, double unit) {
  final r = (p.dy / unit).floor(), c = (p.dx / unit).floor();
  if (r < 0 || c < 0 || r >= SchiffeGame.size || c >= SchiffeGame.size) return null;
  return (r, c);
}

SvLook _ownLook(SchiffeCell c) => switch (c) {
  SchiffeCell.empty => SvLook.water,
  SchiffeCell.ship => SvLook.ship,
  SchiffeCell.miss => SvLook.miss,
  SchiffeCell.hit => SvLook.shipHit,
  SchiffeCell.sunk => SvLook.sunk,
};

SvLook _targetLook(ShotMark m) => switch (m) {
  ShotMark.unknown => SvLook.water,
  ShotMark.miss => SvLook.miss,
  ShotMark.hit => SvLook.hit,
  ShotMark.sunk => SvLook.sunk,
};

String _lookLabel(AppLocalizations l10n, SvLook l) => switch (l) {
  SvLook.water => l10n.schiffeLookWater,
  SvLook.ship => l10n.schiffeLookShip,
  SvLook.miss => l10n.schiffeLookMiss,
  SvLook.shipHit => l10n.schiffeLookShipHit,
  SvLook.hit => l10n.schiffeLookHit,
  SvLook.sunk => l10n.schiffeLookSunk,
};

Widget _section(BuildContext context, String title, Widget grid, {Key? key}) {
  return Column(
    key: key,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      Expanded(child: grid),
    ],
  );
}

// ------------------------------------------------------------------ setup

class _Setup extends StatelessWidget {
  final _SchiffeBoardState state;
  const _Setup({required this.state});

  @override
  Widget build(BuildContext context) {
    final g = state.game;
    final l10n = AppLocalizations.of(context);
    final me = state.viewer;
    final next = g.nextShipIndex(me);
    final canAct = state.controller.canAct && next != null;
    final len = next == null ? 0 : g.fleet[next];
    final dir = state._horizontal ? 'h' : 'v';

    // Valid anchors of the next ship in the current orientation, straight
    // from the engine's legal moves.
    final anchors = <int>{};
    for (final m in g.legalMoves) {
      if (m['action'] != 'place' || m['dir'] != dir) continue;
      final a = (m['row'] as int) * SchiffeGame.size + (m['col'] as int);
      anchors.add(a);
    }

    final previewCells = <int>{};
    SvPreview? previewLook;
    final pv = state._preview;
    if (pv != null && canAct) {
      final ship = ShipPlacement(length: len, row: pv.$1, col: pv.$2, horizontal: state._horizontal);
      for (final cell in ship.cells) {
        if (cell[0] < SchiffeGame.size && cell[1] < SchiffeGame.size) {
          previewCells.add(cell[0] * SchiffeGame.size + cell[1]);
        }
      }
      previewLook = anchors.contains(pv.$1 * SchiffeGame.size + pv.$2) ? SvPreview.valid : SvPreview.invalid;
    }

    final own = g.ownGrid(me);
    final grid = SchiffeGrid(
      cellBuilder: (r, c) {
        final look = _ownLook(own[r][c]);
        final i = r * SchiffeGame.size + c;
        return SchiffeCellView(
          key: Key('sv-own-$r-$c'),
          look: look,
          preview: previewCells.contains(i) ? previewLook : null,
          semanticLabel: l10n.schiffeCellLabel(svCellName(r, c), _lookLabel(l10n, look)),
        );
      },
      wrapCells: canAct
          ? (cells, unit) => Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => state._setPreview(_cellAt(e.localPosition, unit)),
              onPointerMove: (e) => state._setPreview(_cellAt(e.localPosition, unit)),
              onPointerCancel: (_) => state._setPreview(null),
              onPointerUp: (e) {
                final cell = _cellAt(e.localPosition, unit);
                if (cell != null && anchors.contains(cell.$1 * SchiffeGame.size + cell.$2)) {
                  state._place(next, cell.$1, cell.$2);
                }
                if (e.kind != PointerDeviceKind.mouse) state._setPreview(null);
              },
              child: MouseRegion(
                onHover: (e) => state._setPreview(_cellAt(e.localPosition, unit)),
                onExit: (_) => state._setPreview(null),
                child: cells,
              ),
            )
          : null,
    );

    final theme = Theme.of(context);
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          next == null ? l10n.schiffeFleetComplete : l10n.schiffeShipWithLength(localizedShipName(l10n, len), len),
          key: const Key('sv-next-ship'),
          style: theme.textTheme.titleLarge,
        ),
        if (next != null) Text(l10n.schiffeSetupProgress(next + 1, g.fleet.length, playerMark(me))),
      ],
    );
    final rotate = OutlinedButton.icon(
      key: const Key('sv-rotate'),
      onPressed: canAct ? state._toggleRotation : null,
      icon: Icon(state._horizontal ? Icons.swap_horiz : Icons.swap_vert),
      label: Text(state._horizontal ? l10n.schiffeHorizontal : l10n.schiffeVertical),
    );
    final random = FilledButton.tonalIcon(
      key: const Key('sv-random'),
      onPressed: canAct ? state._autoplace : null,
      icon: const Icon(Icons.casino_outlined),
      label: Text(l10n.schiffeRandom),
    );
    Widget fleetItem(int i, {required bool dense}) {
      final placed = next == null || i < next;
      final current = i == next;
      final l = g.fleet[i];
      return Padding(
        key: Key('sv-fleet-$i'),
        padding: dense ? const EdgeInsetsDirectional.only(end: 6) : const EdgeInsets.symmetric(vertical: 2),
        child: Chip(
          visualDensity: VisualDensity.compact,
          backgroundColor: current ? theme.colorScheme.primaryContainer : null,
          avatar: Icon(
            placed ? Icons.check_circle : (current ? Icons.arrow_right : Icons.radio_button_unchecked),
            size: 18,
            color: placed ? Colors.green.shade700 : null,
          ),
          label: Text(placed
              ? l10n.schiffeShipPlaced(localizedShipName(l10n, l), l)
              : l10n.schiffeShipWithLength(localizedShipName(l10n, l), l)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= _wideBreakpoint) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: grid),
                const SizedBox(width: 16),
                SizedBox(
                  width: 260,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: [rotate, random]),
                        const SizedBox(height: 16),
                        Text(l10n.schiffeFleet, style: theme.textTheme.titleSmall),
                        for (var i = 0; i < g.fleet.length; i++) fleetItem(i, dense: false),
                      ],
                    ),
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
              Wrap(spacing: 8, runSpacing: 8, children: [rotate, random]),
              const SizedBox(height: 8),
              Expanded(child: grid),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [for (var i = 0; i < g.fleet.length; i++) fleetItem(i, dense: true)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------- battle

class _Battle extends StatelessWidget {
  final _SchiffeBoardState state;
  const _Battle({required this.state});

  @override
  Widget build(BuildContext context) {
    final g = state.game;
    final me = state.viewer;
    final opp = me == Player.a ? Player.b : Player.a;
    final canAct = state.controller.canAct;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final target = g.targetGrid(me);
    final targetGrid = SchiffeGrid(
      outlines: sunkShips(target),
      outlineColor: theme.colorScheme.onSurface,
      cellBuilder: (r, c) {
        final mark = target[r][c];
        final look = _targetLook(mark);
        final tappable = canAct && mark == ShotMark.unknown;
        return SchiffeCellView(
          key: Key('sv-target-$r-$c'),
          look: look,
          semanticLabel: l10n.schiffeCellLabel(
            svCellName(r, c),
            mark == ShotMark.unknown ? l10n.schiffeLookUnknown : _lookLabel(l10n, look),
          ),
          onTap: tappable ? () => state._fire(r, c) : null,
        );
      },
    );

    final own = g.ownGrid(me);
    final ownSunk = [
      for (final p in g.placements(me))
        if (p.cells.every((cell) => own[cell[0]][cell[1]] == SchiffeCell.sunk)) p,
    ];
    final ownGrid = SchiffeGrid(
      outlines: ownSunk,
      outlineColor: theme.colorScheme.onSurface,
      cellBuilder: (r, c) {
        final look = _ownLook(own[r][c]);
        return SchiffeCellView(
          key: Key('sv-own-$r-$c'),
          look: look,
          semanticLabel: l10n.schiffeCellLabel(svCellName(r, c), _lookLabel(l10n, look)),
        );
      },
    );

    final extra = state._extraShot(g);
    final extraPayload = extra?.event.payload as Map?;
    final banner = extra == null
        ? null
        : Container(
            key: const Key('sv-extra-shot'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              extraPayload?['result'] == 'sunk'
                  ? l10n.schiffeExtraShotSunk(localizedShipName(l10n, extraPayload!['ship'] as int))
                  : l10n.schiffeExtraShot,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onTertiaryContainer),
            ),
          );
    final remaining = Text(
      l10n.schiffeRemaining(g.shipsRemaining(me), playerMark(opp), g.shipsRemaining(opp)),
      key: const Key('sv-remaining'),
      style: theme.textTheme.bodyMedium,
    );
    final incoming = state._lastIncoming(g);
    final incomingText = incoming == null
        ? null
        : Text(
            l10n.schiffeIncoming(
              playerMark(opp),
              svCellName(incoming.move['row'] as int, incoming.move['col'] as int),
              switch ((incoming.event.payload as Map)['result']) {
                'miss' => l10n.schiffeLookWater,
                'hit' => l10n.schiffeLookHit,
                _ => l10n.schiffeLookSunk,
              },
            ),
            key: const Key('sv-incoming'),
            style: theme.textTheme.bodySmall,
          );

    final info = Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [?banner, remaining, ?incomingText],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth >= _wideBreakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _section(context, l10n.schiffeTargetSection, targetGrid, key: const Key('sv-target-section'))),
                      const SizedBox(width: 16),
                      Expanded(child: _section(context, l10n.schiffeOwnSection, ownGrid, key: const Key('sv-own-section'))),
                    ],
                  ),
                ),
              ],
            );
          }
          // Phone portrait: big target grid, small own grid.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              info,
              const SizedBox(height: 6),
              Expanded(flex: 3, child: _section(context, l10n.schiffeTargetSection, targetGrid, key: const Key('sv-target-section'))),
              const SizedBox(height: 8),
              Expanded(flex: 2, child: _section(context, l10n.schiffeOwnSection, ownGrid, key: const Key('sv-own-section'))),
            ],
          );
        },
      ),
    );
  }
}
