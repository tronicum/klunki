import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../shell/game_screen.dart';
import 'schiffe_grid.dart';
import 'schiffe_setup.dart';

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
      // Fresh placement state per player (hot-seat) and per game (restart).
      return SchiffeSetup(key: ValueKey((viewer, controller.transport)), controller: controller, viewer: viewer);
    }
    shell.setHint(_battleHint(l10n, g));
    return _Battle(state: this);
  }

  String? _battleHint(AppLocalizations l10n, SchiffeGame g) {
    if (g.isOver) return l10n.schiffeHintAllSunk;
    if (!controller.canAct) return l10n.schiffeHintWaiting(playerName(context, g.currentPlayer));
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

  void _fire(int row, int col) => controller.submit({'action': 'fire', 'row': row, 'col': col});
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
      l10n.schiffeRemaining(g.shipsRemaining(me), playerName(context, opp), g.shipsRemaining(opp)),
      key: const Key('sv-remaining'),
      style: theme.textTheme.bodyMedium,
    );
    final incoming = state._lastIncoming(g);
    final incomingText = incoming == null
        ? null
        : Text(
            l10n.schiffeIncoming(
              playerName(context, opp),
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
