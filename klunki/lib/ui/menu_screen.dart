import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klunki/ui/debug_console_screen.dart';
import 'package:klunki/ui/language_picker.dart';
import 'package:klunki/ui/pairing/pairing_entry.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

/// The game-selection menu: every game in `gameSpecs` order. Tapping one
/// starts a hot-seat game with a fresh random seed (see [openGame]).
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Klunki'), actions: const [LanguageButton()]),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                Text('Wähle ein Spiel', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 24),
                for (final spec in gameSpecs)
                  Card(
                    key: Key('menu-${spec.id}'),
                    child: ListTile(
                      title: Text(spec.title),
                      subtitle: spec.hiddenInformation ? const Text('Gerät weitergeben') : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openGame(context, spec.id),
                    ),
                  ),
                // Network play needs sockets: hidden on web (KLD-034).
                if (pairingScreenBuilder case final pairing?)
                  Card(
                    key: const Key('menu-network'),
                    child: ListTile(
                      leading: const Icon(Icons.wifi),
                      title: const Text('Über WLAN spielen'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: pairing)),
                    ),
                  ),
                // Text frontend for engine testing; hidden in release builds.
                if (!kReleaseMode)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.terminal),
                      label: const Text('Debug-Konsole'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DebugConsoleScreen()),
                      ),
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
