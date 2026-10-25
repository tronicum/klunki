import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klunki/ui/debug_console_screen.dart';

/// The game-selection menu.
///
/// Wires each game to a [GameTransport] and navigates to its screen.
/// For M1/M2 this is always [HotSeatTransport].
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Klunki')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Wähle ein Spiel',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            _item(context, '4 Gewinnt', 'connect4'),
            _item(context, 'Mühle', 'muehle'),
            _item(context, 'Quartett', 'quartett'),
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
    );
  }

  Widget _item(BuildContext context, String label, String id) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: ListTile(
          title: Text(label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO(M1/M2): start <id> game with HotSeatTransport.
            Navigator.of(context).pop(); // placeholder navigation
          },
        ),
      ),
    );
  }
}
