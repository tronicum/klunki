import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../../transport/hot_seat_transport.dart';
import '../../shell/game_screen.dart';
import '../../shell/seat_game_screen.dart';
import 'maexchen_board.dart';

/// Mäxchen screen (KLD-121): the dice bluffing game, hot-seat and (network
/// step, 2 players) one player per device: no cover, the guest's board is
/// the [MaexchenView] (its own dice only while it rolled). The board
/// (`maexchen_board.dart`) has the lives, the announcement, the table with
/// the cup and the actions; the shell adds status, hint, history, "Zug
/// zurück" and the handover cover, which shows the announcement (or how
/// the round ended) to the next player before the device is handed over.
///
/// 3–4 players (KLD-121 step 2, one device only) play in the seat shell
/// ([SeatGameScreen]) with the cover before every player who takes the cup
/// and a ranking by the order the players went out; 2 players keep
/// [GameScreen] (as over the network).
///
/// Rule variant "Unbegrenzte Leben": "Spiel beenden" in the "⋮" menu
/// (key `maexchen-end`) asks first, then ends the game; the ranking goes by
/// the lives lost.
///
/// Contract: `const MaexchenScreen({super.key, required this.controller})`,
/// built by `ui/shell/screen_registry.dart`.
class MaexchenScreen extends StatelessWidget {
  final GameController controller;

  const MaexchenScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final game = controller.game as MaexchenGame;
    if (game.playerCount > 2) {
      return SeatNamesBuilder(
        child: SeatGameScreen(
          controller: controller,
          describeMove: describeMaexchenMove,
          handoverDetail: (context) => MaexchenHandoverDetail(controller: controller),
          menuEntries: _menuEntries(context, game),
          resultScore: (l10n, r, seat) => maexchenRankingText(l10n, controller.game as MaexchenGame, seat),
          resultDetail: (context) => _lastRoundDetail(),
          boardBuilder: (context, controller) => MaexchenBoard(controller: controller),
        ),
      );
    }
    if (controller.transport is! HotSeatTransport) {
      // Over the network "Spiel beenden" follows whose turn it is.
      return ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _twoPlayers(context, controller.game as MaexchenGame),
      );
    }
    return _twoPlayers(context, game);
  }

  Widget _twoPlayers(BuildContext context, MaexchenGame game) {
    return GameScreen(
      controller: controller,
      describeMove: describeMaexchenMove,
      // The board names both players with their lives.
      showPlayersLegend: false,
      handoverDetail: (context) => MaexchenHandoverDetail(controller: controller),
      menuEntries: _menuEntries(context, game),
      resultDetail: (context) {
        final game = controller.game as MaexchenGame;
        if (game.ended) return MaexchenTally(game: game);
        return _lastRoundDetail();
      },
      // "Zug zurücknehmen" sits in the board's control row, next to the actions.
      boardPlacesUndo: true,
      boardBuilder: (context, controller) => MaexchenBoard(controller: controller),
    );
  }

  /// How the game's last round ended (the last life lost); nothing after a
  /// resign or an ended "Unbegrenzte Leben" game.
  Widget _lastRoundDetail() {
    final game = controller.game as MaexchenGame;
    final last = game.lastRound;
    if (last == null || game.resignedBy != null || game.ended) return const SizedBox.shrink();
    // 3–4 players: only when the last life was lost (not after the others
    // resigned).
    if (game.playerCount > 2 && game.seatResult.code != GameEndReason.maexchenNoLives.code) {
      return const SizedBox.shrink();
    }
    return MaexchenRoundSummary(game: game, end: last);
  }

  /// "Spiel beenden" for "Unbegrenzte Leben": on one device always; over
  /// the network (KLD-121 network step) on the device of the player to move,
  /// who submits the `end` move.
  List<ShellMenuEntry> _menuEntries(BuildContext context, MaexchenGame game) {
    if (!game.unlimitedLives || game.isOver) return const [];
    if (controller.transport is! HotSeatTransport && !controller.canAct) return const [];
    final l10n = AppLocalizations.of(context);
    return [
      ShellMenuEntry(
        key: const Key('maexchen-end'),
        icon: Icons.sports_score,
        label: l10n.maexchenEndGame,
        onSelected: () => confirmMaexchenEnd(context, controller),
      ),
    ];
  }
}

/// Asks "Spiel beenden?" and ends an "Unbegrenzte Leben" game on yes.
/// Keys: `maexchen-end-dialog`, `maexchen-end-cancel`, `maexchen-end-confirm`.
Future<void> confirmMaexchenEnd(BuildContext context, GameController controller) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('maexchen-end-dialog'),
      icon: const Icon(Icons.sports_score, size: 36),
      title: Text(l10n.maexchenEndGameTitle),
      content: Text(l10n.maexchenEndGameBody),
      actions: [
        TextButton(
          key: const Key('maexchen-end-cancel'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.shellCancel),
        ),
        FilledButton(
          key: const Key('maexchen-end-confirm'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.maexchenEndGameConfirm),
        ),
      ],
    ),
  );
  if (ok == true && !controller.game.isOver) await controller.submit(MaexchenGame.endMove);
}

/// What the seat shell's ranking shows behind [seat]'s name: the lives lost
/// ("Unbegrenzte Leben"), the lives left, "ausgeschieden" for a player who
/// lost them all; null (the shell's "aufgegeben") for a player who resigned.
String? maexchenRankingText(AppLocalizations l10n, MaexchenGame game, int seat) {
  if (game.isSeatOut(seat)) {
    return game.livesOfSeat(seat) == 0 && !game.unlimitedLives ? l10n.maexchenResultOut : null;
  }
  return game.unlimitedLives
      ? l10n.maexchenResultLost(game.lostOf(seat))
      : l10n.maexchenResultLives(game.livesOfSeat(seat));
}

/// The lives lost per player after an "Unbegrenzte Leben" game (the
/// two-player result dialog; the seat shell's ranking shows them itself).
/// Keys: `maexchen-tally`, `maexchen-tally-row-<seat>`.
class MaexchenTally extends StatelessWidget {
  final MaexchenGame game;
  const MaexchenTally({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final order = [for (var s = 0; s < game.playerCount; s++) s]..sort((x, y) => game.lostOf(x) - game.lostOf(y));
    return Column(
      key: const Key('maexchen-tally'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in order)
          Padding(
            key: Key('maexchen-tally-row-$s'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                MaexchenSeatToken(game: game, seat: s, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    maexchenSeatName(context, game, s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.heart_broken, size: 18, color: theme.colorScheme.error),
                const SizedBox(width: 4),
                // A narrow dialog (a network game's result) wraps the count.
                Flexible(child: Text(l10n.maexchenResultLost(game.lostOf(s)), style: theme.textTheme.titleSmall)),
              ],
            ),
          ),
      ],
    );
  }
}

/// The value [v] as shown: the number ("54"), or the name of the highest
/// one ("Mäxchen").
String maexchenValueLabel(AppLocalizations l10n, int v) =>
    v == MaexchenGame.maexchen ? l10n.maexchenMaexchenName : '$v';

/// History text of a Mäxchen move ("würfelt", "sagt 54", …).
String describeMaexchenMove(AppLocalizations l10n, AcceptedMove move) => switch (move.move['action']) {
  'roll' => l10n.maexchenMoveRoll,
  'announce' => l10n.maexchenMoveAnnounce(maexchenValueLabel(l10n, move.move['value'] as int)),
  'believe' => l10n.maexchenMoveBelieve,
  'doubt' => l10n.maexchenMoveDoubt,
  'giveUp' => l10n.maexchenMoveGiveUp,
  'end' => l10n.maexchenEndGame,
  _ => move.move.toString(),
};
