import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/net/room_link.dart';
import 'package:klunki/ui/debug_console_screen.dart';
import 'package:klunki/ui/game_titles.dart';
import 'package:klunki/ui/language_picker.dart';
import 'package:klunki/ui/pairing/pairing_entry.dart';
import 'package:klunki/ui/player_name_dialog.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart' show WebJoinDeps, WebJoinScreen;
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

/// The game-selection menu: every game in `appGameSpecs` order. Tapping one
/// starts a hot-seat game with a fresh random seed (see [openGame]).
///
/// [initialJoinLink] (the PWA's `?join=` URL parameter, KLD-055) opens the
/// browser join screen on top of the menu and connects right away, so "back"
/// from there lands in the menu. [initialRoom] (`?room=CODE`, KLD-057b) does
/// the same for a relay room: the join screen with the code filled in, joined
/// right away when the code is valid.
class MenuScreen extends StatefulWidget {
  final String? initialJoinLink;
  final RoomLink? initialRoom;
  final Uri? pageUrl;

  /// Test hook for the `?join=` flow (default: the real WebSocket join).
  final WebJoinDeps? webJoinDeps;

  const MenuScreen({super.key, this.initialJoinLink, this.initialRoom, this.pageUrl, this.webJoinDeps});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    final room = widget.initialRoom;
    final link = widget.initialJoinLink;
    if (room != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => WebJoinScreen(initialRoom: room, pageUrl: widget.pageUrl, deps: widget.webJoinDeps),
        ));
      });
    } else if (link != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => webJoinScreenFor(link, pageUrl: widget.pageUrl, deps: widget.webJoinDeps),
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle), actions: const [PlayerNameButton(), LanguageButton()]),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.menuChooseGame, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 24),
                for (final spec in appGameSpecs)
                  Card(
                    key: Key('menu-${spec.id}'),
                    child: ListTile(
                      title: Text(localizedGameTitle(l10n, spec.id, fallback: spec.title)),
                      subtitle: spec.hiddenInformation ? Text(l10n.menuPassDevice) : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openGame(context, spec.id),
                    ),
                  ),
                // Native: host or join (KLD-034); web: join a native host (KLD-055).
                if (pairingScreenBuilder case final pairing?)
                  Card(
                    key: const Key('menu-network'),
                    child: ListTile(
                      leading: const Icon(Icons.wifi),
                      title: Text(l10n.menuPlayOverWifi),
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
                      label: Text(l10n.menuDebugConsole),
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
