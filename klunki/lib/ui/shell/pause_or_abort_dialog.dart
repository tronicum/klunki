import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

/// What leaving a saved hot-seat game does (KLD-079).
enum LeaveChoice {
  /// "Spiel pausieren": the save stays, the game is under "Weiterspielen".
  pause,

  /// "Spiel abbrechen": the save is deleted, the game is gone.
  abort,
}

/// "Spiel verlassen?" for a running hot-seat game that is saved (KLD-079,
/// maintainer feedback): pausing keeps the game for "Weiterspielen",
/// aborting deletes it. Pausing is the safe, primary choice; aborting is
/// styled as the destructive one. "Zurück zum Spiel" (and back or a tap
/// outside, answering null) stays in the game; there is no plain
/// "Abbrechen" button, it would read like "Spiel abbrechen".
class PauseOrAbortDialog extends StatelessWidget {
  const PauseOrAbortDialog({super.key = const Key('leave-dialog')});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: Text(l10n.shellLeaveTitle),
      content: Text(l10n.shellPauseOrAbortBody),
      // Three buttons rarely fit side by side on a phone: one under the
      // other, full width, the primary "Spiel pausieren" first.
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              key: const Key('leave-pause'),
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(LeaveChoice.pause),
              child: Text(l10n.shellPauseGame),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('leave-abort'),
              style: OutlinedButton.styleFrom(foregroundColor: error, side: BorderSide(color: error)),
              onPressed: () => Navigator.of(context).pop(LeaveChoice.abort),
              child: Text(l10n.shellAbortGame),
            ),
            const SizedBox(height: 4),
            TextButton(
              key: const Key('leave-cancel'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.shellBackToGame),
            ),
          ],
        ),
      ],
    );
  }
}
