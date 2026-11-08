import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' show Player;

import '../../game/game_controller.dart';
import '../../profile/confirm_move_settings.dart';

export '../../profile/confirm_move_settings.dart';

/// Games whose boards offer "Zug bestätigen" (KLD-122). Only chess so far;
/// another board joins by keeping its chosen move as pending (shown, not
/// submitted) while [confirmMoveFor] is on, showing a [ConfirmMoveBar] and
/// submitting on "Ziehen", and by being listed here (the start dialog and
/// the shell then show the setting).
const Set<String> confirmMoveGames = {'chess'};

/// Whether [mover]'s move in [controller]'s game waits for "Ziehen": on a
/// network device the device's choice, in hot-seat the seat's.
bool confirmMoveFor(BuildContext context, GameController controller, Player mover) =>
    confirmMoveGames.contains(controller.spec.id) &&
    ConfirmMoveScope.of(context)
        .confirmFor(mover, onNetwork: controller.transport.localPlayers.length == 1);

/// "✗ Zurück" and "✓ Ziehen" under a board with a pending move (KLD-122).
/// Keys `confirm-move-bar`, `confirm-move-back`, `confirm-move-commit`.
class ConfirmMoveBar extends StatelessWidget {
  final VoidCallback onCommit;
  final VoidCallback onBack;

  const ConfirmMoveBar({super.key = const Key('confirm-move-bar'), required this.onCommit, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            key: const Key('confirm-move-back'),
            onPressed: onBack,
            icon: const Icon(Icons.close),
            label: Text(l10n.confirmMoveBack),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            key: const Key('confirm-move-commit'),
            onPressed: onCommit,
            icon: const Icon(Icons.check),
            label: Text(l10n.confirmMoveCommit),
          ),
        ],
      ),
    );
  }
}

/// The device's "Zug bestätigen" for network games as a switch with its
/// explanation (KLD-122): on "Raum starten" when the chosen game offers it.
class ConfirmMoveSwitch extends StatelessWidget {
  final bool enabled;

  const ConfirmMoveSwitch({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ConfirmMoveScope.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SwitchListTile(
        key: const Key('confirm-move-network'),
        contentPadding: EdgeInsetsDirectional.zero,
        value: settings.network,
        onChanged: enabled ? settings.setNetwork : null,
        title: Text(l10n.confirmMoveSetting),
        subtitle: Text(l10n.confirmMoveHelper),
      ),
    );
  }
}

/// App-bar toggle of a network game (KLD-122): turns this device's "Zug
/// bestätigen" on or off during the game and says so in a snack bar. Key
/// `shell-confirm-move`.
class ConfirmMoveToggle extends StatelessWidget {
  const ConfirmMoveToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ConfirmMoveScope.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => IconButton(
        key: const Key('shell-confirm-move'),
        tooltip: l10n.confirmMoveSetting,
        isSelected: settings.network,
        icon: const Icon(Icons.check_circle_outline),
        selectedIcon: const Icon(Icons.check_circle),
        onPressed: () {
          final on = !settings.network;
          settings.setNetwork(on);
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              key: const Key('confirm-move-snack'),
              content: Text(on ? l10n.confirmMoveOn : l10n.confirmMoveOff),
              duration: const Duration(seconds: 2),
            ));
        },
      ),
    );
  }
}
