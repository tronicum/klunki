import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';


// "So spielt ihr zusammen" (KLD-113): a short help (FAQ) about playing with
// others, rooms, servers and club codes. Stored in the app (ARB strings),
// readable offline; reached from "Über Klunki" and from the server dialog
// ("Wie geht das?").
//
// The same texts are also meant for the website FAQ (generated from the ARB
// files): every help text is an ARB key starting with `help`, plain text,
// paragraphs separated by a blank line ("\n\n"), lines of a list by "\n".
// [helpSectionIds] is the one place that fixes the order of the sections.

/// The help sections in order: section `X` is the ARB keys
/// `helpSectionXTitle` and `helpSectionXBody` (after the page title
/// `helpTitle`). A site script follows the same order.
const List<String> helpSectionIds = ['Rooms', 'Wifi', 'Server', 'OwnServer', 'Coming', 'Club', 'Data'];

/// Title and body of section [id] (one of [helpSectionIds]).
(String, String) helpSection(AppLocalizations l10n, String id) => switch (id) {
      'Rooms' => (l10n.helpSectionRoomsTitle, l10n.helpSectionRoomsBody),
      'Wifi' => (l10n.helpSectionWifiTitle, l10n.helpSectionWifiBody),
      'Server' => (l10n.helpSectionServerTitle, l10n.helpSectionServerBody),
      'OwnServer' => (l10n.helpSectionOwnServerTitle, l10n.helpSectionOwnServerBody),
      'Coming' => (l10n.helpSectionComingTitle, l10n.helpSectionComingBody),
      'Club' => (l10n.helpSectionClubTitle, l10n.helpSectionClubBody),
      'Data' => (l10n.helpSectionDataTitle, l10n.helpSectionDataBody),
      _ => throw ArgumentError.value(id, 'id', 'unknown help section'),
    };

/// Opens the help screen.
Future<void> openHelpScreen(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HelpScreen()));

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const Key('help-text'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final id in helpSectionIds) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 4),
                    child: Semantics(
                      header: true,
                      child: Text(helpSection(l10n, id).$1,
                          key: Key('help-$id-title'), style: theme.textTheme.titleMedium),
                    ),
                  ),
                  for (final (i, p) in helpSection(l10n, id).$2.split('\n\n').indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(p, key: i == 0 ? Key('help-$id-body') : null, style: theme.textTheme.bodyMedium),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
