import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/net/room_link.dart';
import 'package:klunki/ui/debug_console_screen.dart';
import 'package:klunki/ui/game_titles.dart';
import 'package:klunki/ui/game_visuals.dart';
import 'package:klunki/ui/language_picker.dart';
import 'package:klunki/ui/pairing/pairing_entry.dart';
import 'package:klunki/ui/player_name_dialog.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart' show WebJoinDeps, WebJoinScreen;
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

/// The game-selection menu: a tile per game in `appGameSpecs` order (drawn
/// illustration on the game's accent colour, title, one-liner; see
/// `game_visuals.dart`), then the network entry. Tapping a game starts a
/// hot-seat game with a fresh random seed (see [openGame]).
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
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WebJoinScreen(initialRoom: room, pageUrl: widget.pageUrl, deps: widget.webJoinDeps),
          ),
        );
      });
    } else if (link != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => webJoinScreenFor(link, pageUrl: widget.pageUrl, deps: widget.webJoinDeps),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final palette = KlunkiPalette.of(context);
    final pairing = pairingScreenBuilder;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: palette.backgroundTop,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: SizedBox.square(dimension: 30, child: CustomPaint(painter: KlunkiLogo())),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        actions: const [PlayerNameButton(), LanguageButton()],
      ),
      body: KlunkiBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              // Not a lazy ListView: every entry is built (tests, screen readers).
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.menuChooseGame,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    _SectionLabel(icon: Icons.people_alt_outlined, text: l10n.menuSectionHotSeat),
                    const SizedBox(height: 8),
                    _GameGrid(specs: appGameSpecs, onOpen: (id) => openGame(context, id)),
                    // Native: host or join (KLD-034); web: host via relay or join (KLD-055, KLD-057b).
                    if (pairing != null) ...[
                      const SizedBox(height: 16),
                      _SectionLabel(icon: Icons.devices_outlined, text: l10n.menuSectionNetwork),
                      const SizedBox(height: 8),
                      _NetworkCard(
                        accent: palette.networkAccent,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: pairing)),
                      ),
                    ],
                    // Text frontend for engine testing; hidden in release builds.
                    if (!kReleaseMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            icon: const Icon(Icons.terminal, size: 18),
                            label: Text(l10n.menuDebugConsole),
                            onPressed: () =>
                                Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (_) => const DebugConsoleScreen())),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text, style: theme.textTheme.titleSmall?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

/// Game tiles in rows: 2 columns on phones, up to 5 on wide screens. Rows
/// are built eagerly (no lazy grid), so every tile exists for tests and
/// screen readers; the tiles of a row share its height.
class _GameGrid extends StatelessWidget {
  final List<GameSpec> specs;
  final void Function(String id) onOpen;
  const _GameGrid({required this.specs, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = (box.maxWidth / 190).floor().clamp(2, 5);
        const gap = 12.0;
        final rows = <Widget>[];
        for (var i = 0; i < specs.length; i += cols) {
          final row = specs.sublist(i, (i + cols).clamp(0, specs.length));
          rows.add(
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var k = 0; k < cols; k++) ...[
                      if (k > 0) const SizedBox(width: gap),
                      Expanded(
                        child: k < row.length
                            ? _GameTile(spec: row[k], onTap: () => onOpen(row[k].id))
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
      },
    );
  }
}

/// One game: illustration on the game's accent, title, one-liner, and an
/// eye-off badge for hidden-information games (the device is passed).
class _GameTile extends StatelessWidget {
  final GameSpec spec;
  final VoidCallback onTap;
  const _GameTile({required this.spec, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final palette = KlunkiPalette.of(context);
    final accent = palette.accent(spec.id);
    final visuals = visualsOf(spec.id);
    final description = visuals.description?.call(l10n);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      key: Key('menu-${spec.id}'),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent.container, Color.lerp(accent.container, accent.color, 0.2)!],
                ),
                border: Border(bottom: BorderSide(color: accent.color, width: 3)),
              ),
              padding: const EdgeInsets.all(8),
              child: ExcludeSemantics(child: CustomPaint(painter: visuals.illustration(palette))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 6, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedGameTitle(l10n, spec.id, fallback: spec.title),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(description, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        if (spec.hiddenInformation) ...[
                          Tooltip(
                            message: l10n.menuHiddenInfo,
                            child: Icon(Icons.visibility_off_outlined, size: 16, color: muted),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              l10n.menuPassDevice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(color: muted),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        Icon(Icons.chevron_right, color: accent.onSurface(theme.brightness)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The network entry: host or join a game with a second device.
class _NetworkCard extends StatelessWidget {
  final GameAccent accent;
  final VoidCallback onTap;
  const _NetworkCard({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const Key('menu-network'),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: BorderDirectional(start: BorderSide(color: accent.color, width: 5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: accent.color, shape: BoxShape.circle),
                child: Icon(Icons.wifi, color: accent.onColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.menuPlayOverWifi,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      l10n.menuNetworkSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: accent.onSurface(theme.brightness)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app mark: three game pieces in the classic piece colours.
class KlunkiLogo extends CustomPainter {
  const KlunkiLogo();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final r = s * 0.27;
    const colors = [Color(0xFFD32F2F), Color(0xFFFFC107), Color(0xFF1C5DB8)];
    final centers = [Offset(s * 0.3, s * 0.64), Offset(s * 0.7, s * 0.64), Offset(s * 0.5, s * 0.3)];
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(centers[i] + Offset(0, s * 0.03), r, Paint()..color = const Color(0x33000000));
      canvas.drawCircle(centers[i], r, Paint()..color = colors[i]);
      canvas.drawCircle(
        centers[i],
        r * 0.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.03
          ..color = Colors.white.withValues(alpha: 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(KlunkiLogo old) => false;
}
