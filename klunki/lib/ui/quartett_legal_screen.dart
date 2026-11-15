import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

import 'games/quartett_media.dart' show QuartettImageCreditsScreen;
import 'shell/game_screen.dart' show ShellMenuEntry;

// "Rechtliche Hinweise" of the Quartett cards (KLD-127): the cards name real
// manufacturers and products, which may be trademarks. A short, generic
// notice (valid for every deck), reachable where people browse the cards
// (deck picker, card gallery), from the game's "⋮" menu and from "Über
// Klunki". Stored in the app, readable offline.

/// Opens [QuartettLegalScreen].
void openQuartettLegalNotice(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QuartettLegalScreen()));

/// "Rechtliche Hinweise" in the "⋮" menu of a Quartett game (hot-seat and
/// network), so the notice is reachable during a game without a link on
/// every card. Key `quartett-legal-menu`.
ShellMenuEntry quartettLegalMenuEntry(BuildContext context) => ShellMenuEntry(
  key: const Key('quartett-legal-menu'),
  icon: Icons.gavel_outlined,
  label: AppLocalizations.of(context).quartettLegalTitle,
  onSelected: () => openQuartettLegalNotice(context),
);

/// The notice: names only identify, may be trademarks, no connection to the
/// manufacturers; where the photos come from and that the small pictures
/// are our own drawings. "Bildnachweise" opens the photo credits.
class QuartettLegalScreen extends StatelessWidget {
  const QuartettLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quartettLegalTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const Key('quartett-legal-text'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                for (final (key, text) in [
                  ('quartett-legal-trademarks', l10n.quartettLegalTrademarks),
                  ('quartett-legal-photos', l10n.quartettLegalPhotos),
                  ('quartett-legal-drawings', l10n.quartettLegalDrawings),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(text, key: Key(key), style: theme.textTheme.bodyLarge),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const Key('quartett-legal-credits'),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.quartettImageCreditsTitle),
                    onPressed: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => const QuartettImageCreditsScreen())),
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

/// The small, unobtrusive text link "Rechtliche Hinweise" under the deck
/// list (deck picker, card gallery). Key `quartett-legal-link`.
class QuartettLegalLink extends StatelessWidget {
  const QuartettLegalLink({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: TextButton(
        key: const Key('quartett-legal-link'),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          textStyle: theme.textTheme.bodySmall?.copyWith(decoration: TextDecoration.underline),
          visualDensity: VisualDensity.compact,
        ),
        onPressed: () => openQuartettLegalNotice(context),
        child: Text(AppLocalizations.of(context).quartettLegalTitle),
      ),
    );
  }
}
