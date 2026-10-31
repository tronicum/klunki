import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

import '../../game/game_controller.dart';
import 'player_labels.dart';

/// Hides [child] behind an opaque full-size cover while
/// [GameController.needsHandover] is set (hidden-information games in
/// hot-seat): "Gib das Gerät an O weiter" plus a big button that calls
/// [GameController.acknowledgeHandover].
///
/// [detail] (optional) adds public information under the text, e.g. the
/// outcome of the last fight, so the player who just moved sees it before
/// passing the device.
///
/// While covered the child stays mounted (its state survives) but is
/// [Offstage]: not painted, not hit-testable, no semantics, tickers paused.
class HandoverCover extends StatelessWidget {
  final GameController controller;
  final Widget child;
  final WidgetBuilder? detail;

  const HandoverCover({super.key, required this.controller, required this.child, this.detail});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final covered = controller.needsHandover;
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: covered,
              child: TickerMode(
                enabled: !covered,
                child: ExcludeSemantics(excluding: covered, child: child),
              ),
            ),
            if (covered) _Cover(controller: controller, detail: detail),
          ],
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  final GameController controller;
  final WidgetBuilder? detail;
  const _Cover({required this.controller, this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // "Ben (O)" with hot-seat names, else just the mark (KLD-056).
    final mark = PlayerLabelsScope.of(context).label(context, l10n, controller.game.currentPlayer);
    return Material(
      key: const Key('handover-cover'),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        // Scrolls only when a [detail] does not fit (small phones).
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phonelink_lock, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(l10n.shellHandoverPass(mark), textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
              if (detail != null) ...[const SizedBox(height: 20), detail!(context)],
              const SizedBox(height: 32),
              FilledButton(
                key: const Key('handover-continue'),
                style: FilledButton.styleFrom(minimumSize: const Size(240, 72), textStyle: theme.textTheme.titleLarge),
                onPressed: controller.acknowledgeHandover,
                child: Text(l10n.shellHandoverContinue(mark)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
