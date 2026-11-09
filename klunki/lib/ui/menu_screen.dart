import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klunki/app/build_info.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/app/web_channel.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/net/room_link.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/ui/about_screen.dart';
import 'package:klunki/ui/debug_console_screen.dart';
import 'package:klunki/ui/game_titles.dart';
import 'package:klunki/ui/game_visuals.dart';
import 'package:klunki/ui/games/quartett_gallery.dart';
import 'package:klunki/ui/language_picker.dart';
import 'package:klunki/ui/ltr.dart';
import 'package:klunki/ui/pairing/network_unavailable.dart';
import 'package:klunki/ui/pairing/pairing_entry.dart';
import 'package:klunki/ui/player_count_chip.dart';
import 'package:klunki/ui/player_name_dialog.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart' show WebJoinDeps, WebJoinScreen;
import 'package:klunki/ui/rules/rules_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

/// Whether the menu links the debug console: only outside release builds.
/// The App Store screenshots (debug-mode tests) switch it off.
@visibleForTesting
bool menuShowsDebugConsole = !kReleaseMode;

/// The game-selection menu: a tile per game in `appGameSpecs` order (drawn
/// illustration on the game's accent colour, title, one-liner; see
/// `game_visuals.dart`), then "Mit anderen Geräten spielen" (KLD-098: the
/// two room buttons, "Raum starten" and "Raum beitreten"). Tapping a game
/// (or its "An einem Gerät" link) starts a hot-seat game with a fresh random
/// seed (see [openGameFromMenu]); its "Mit anderen" link (KLD-105) asks
/// "Raum starten" (with that game chosen) or "Raum beitreten" (KLD-111).
///
/// [initialJoinLink] (the PWA's `?join=` URL parameter, KLD-055) opens the
/// browser join screen on top of the menu and connects right away, so "back"
/// from there lands in the menu. [initialRoom] (`?room=CODE`, KLD-057b) does
/// the same for a relay room: the join screen with the code filled in, joined
/// right away when the code is valid.
///
/// KLD-108: on a browser page that can't reach any relay
/// ([browserCannotPlayOnline]: https without a `wss://` relay in the relay
/// settings) the "Mit anderen" links and the room buttons stay visible but
/// greyed out; tapping one explains why ([showNetworkUnavailableSheet]).
/// They come back as soon as a usable relay is chosen. The GitHub Pages
/// build ([isPagesBeta]) shows a "Beta" badge next to the title.
class MenuScreen extends StatefulWidget {
  final String? initialJoinLink;
  final RoomLink? initialRoom;
  final Uri? pageUrl;

  /// Test hook for the `?join=` flow (default: the real WebSocket join).
  final WebJoinDeps? webJoinDeps;

  /// The relay settings that decide whether an https page can play over the
  /// network (KLD-108). Default: the app's shared settings on an https page,
  /// none otherwise.
  final RelaySettings? relaySettings;

  const MenuScreen({
    super.key,
    this.initialJoinLink,
    this.initialRoom,
    this.pageUrl,
    this.webJoinDeps,
    this.relaySettings,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  /// A game tile's start is running (dialogs, then the pushed route): a
  /// second tap (double tap, the other link) starts nothing (KLD-105).
  bool _launching = false;

  Future<void> _launch(Future<void> Function() start) async {
    if (_launching) return;
    _launching = true;
    try {
      await start();
    } finally {
      _launching = false;
    }
  }

  /// Null where the relay can't matter (native, http pages).
  late final RelaySettings? _relaySettings =
      widget.relaySettings ?? (widget.pageUrl?.scheme == 'https' ? RelaySettings.shared() : null);

  /// KLD-111: a game's "Mit anderen" (tile or preview link): a sheet with
  /// the game's name asks "Raum starten" (the room screen with this game
  /// chosen, KLD-105) or "Raum beitreten" (the join screen as in the room
  /// section: the host decides the game). Without a join screen: straight
  /// to "Raum starten".
  Future<void> _withOthers(String id, Widget Function(String) startFor, WidgetBuilder? join) => _launch(() async {
    WidgetBuilder? next = (_) => startFor(id);
    if (join != null) {
      final accent = KlunkiPalette.of(context).accent(id);
      final l10n = AppLocalizations.of(context);
      final title = localizedGameTitle(l10n, id, fallback: specById(id)?.title ?? id);
      final choice = await showModalBottomSheet<_RoomChoice>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _RoomChoiceSheet(title: title, accent: accent),
      );
      if (!mounted) return;
      next = switch (choice) {
        _RoomChoice.start => next,
        _RoomChoice.join => join,
        null => null,
      };
    }
    if (next == null) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: next));
  });

  /// KLD-108: network play can't work on this page (see [MenuScreen]).
  bool get _networkBlocked => browserCannotPlayOnline(pageUrl: widget.pageUrl, chosenRelay: _relaySettings?.value);

  void _onRelayChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _relaySettings?.removeListener(_onRelayChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _relaySettings?.addListener(_onRelayChanged);
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
    final start = roomStartScreenBuilder, join = roomJoinScreenBuilder;
    final startFor = roomStartForGameBuilder;
    final blocked = _networkBlocked;
    void explain() => showNetworkUnavailableSheet(context);
    return Scaffold(
      // KLD-097: one slim row (48 instead of 56): the app icon (c5-zoom-b-fill,
      // as on the home screen) and "Klunki Spielesammlung" ([_MenuTitle]), so
      // the game tiles start higher on phones.
      appBar: AppBar(
        backgroundColor: palette.backgroundTop,
        toolbarHeight: 48,
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KlunkiAppIcon(key: Key('menu-app-icon'), size: 30),
            const SizedBox(width: 8),
            const Flexible(child: _MenuTitle()),
            if (isPagesBeta) ...[const SizedBox(width: 8), const _BetaBadge()],
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
                    // KLD-097: a slim label like the network section's
                    // instead of a big headline.
                    _SectionLabel(icon: Icons.casino_outlined, text: l10n.menuChooseGame),
                    const SizedBox(height: 8),
                    // KLD-105: every tile starts its game on this device (the
                    // tile, "An einem Gerät") or a room for it ("Mit anderen").
                    _GameGrid(
                      specs: appGameSpecs,
                      onLocal: (id) => _launch(() => openGameFromMenu(context, id)),
                      onNetwork: startFor == null
                          ? null
                          : blocked
                          ? (_) => explain()
                          : (id) => _withOthers(id, startFor, join),
                      networkBlocked: blocked,
                    ),
                    // KLD-098: "Mit anderen Geräten spielen": start or join a
                    // room (native: on this device or through the relay; web:
                    // through the relay, KLD-034/055/057b).
                    if (start != null && join != null) ...[
                      const SizedBox(height: 16),
                      _SectionLabel(icon: Icons.devices_outlined, text: l10n.menuSectionNetwork),
                      const SizedBox(height: 8),
                      _RoomButtons(
                        accent: palette.networkAccent,
                        blocked: blocked,
                        onStart: blocked
                            ? explain
                            : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: start)),
                        onJoin: blocked
                            ? explain
                            : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: join)),
                      ),
                    ],
                    // Text frontend for engine testing; hidden in release builds.
                    if (menuShowsDebugConsole)
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
                    // Games not in the app yet (`previewGames`, none since
                    // KLD-094 step 7), debug builds only; "Mit anderen" like a
                    // game tile's link unless the game is hot-seat only.
                    if (menuShowsDebugConsole)
                      for (final id in previewGames)
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextButton.icon(
                              key: Key('menu-preview-$id'),
                              icon: const Icon(Icons.science_outlined, size: 18),
                              label: Text(l10n.menuPreviewGame(
                                  localizedGameTitle(l10n, id, fallback: specById(id)?.title ?? id))),
                              onPressed: () => _launch(() => openGameFromMenu(context, id)),
                            ),
                            if (startFor != null && !hotSeatOnlyGames.contains(id))
                              KeyedSubtree(
                                key: Key('menu-preview-$id-network'),
                                child: Greyed(
                                  blocked: blocked,
                                  child: TextButton.icon(
                                    icon: Icon(blocked ? Icons.wifi_off : Icons.devices_outlined, size: 18),
                                    label: Text(l10n.menuPlayWithOthers),
                                    onPressed: blocked
                                        ? explain
                                        : () => _withOthers(id, startFor, join),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    // KLD-102: "Über Klunki" (privacy policy, Impressum,
                    // support, licences) right above the version line: out
                    // of the way of the games, where people look for it.
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: TextButton.icon(
                          key: const Key('menu-about'),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: Text(l10n.aboutTitle),
                          onPressed: () => openAboutScreen(context),
                        ),
                      ),
                    ),
                    // KLD-085/KLD-116: version and commit ("1.1.0 (b8752a9)");
                    // build number, protocol and game data are on the About screen.
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.menuVersion(bidiLtr(context, appVersionLine)),
                        key: const Key('menu-version'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
  final void Function(String id) onLocal;

  /// Null: no network play on this platform.
  final void Function(String id)? onNetwork;

  /// KLD-108: the "Mit anderen" links are greyed out.
  final bool networkBlocked;
  const _GameGrid({required this.specs, required this.onLocal, required this.onNetwork, this.networkBlocked = false});

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
                        child: k < row.length ? _tile(row[k]) : const SizedBox(),
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

  Widget _tile(GameSpec spec) {
    final network = onNetwork;
    return _GameTile(
      spec: spec,
      onLocal: () => onLocal(spec.id),
      onNetwork: network == null || hotSeatOnlyGames.contains(spec.id) ? null : () => network(spec.id),
      networkBlocked: networkBlocked,
    );
  }
}

/// One game (KLD-105): illustration on the game's accent, title and
/// one-liner (tapping them starts the game on this device, as before), then
/// the two ways to play as links: "An einem Gerät" (the same) and "Mit
/// anderen" (a room for this game; not for [hotSeatOnlyGames]).
class _GameTile extends StatelessWidget {
  final GameSpec spec;
  final VoidCallback onLocal;
  final VoidCallback? onNetwork;
  final bool networkBlocked;
  const _GameTile({required this.spec, required this.onLocal, required this.onNetwork, this.networkBlocked = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final palette = KlunkiPalette.of(context);
    final accent = palette.accent(spec.id);
    final visuals = visualsOf(spec.id);
    final description = visuals.description?.call(l10n);
    final muted = theme.colorScheme.onSurfaceVariant;
    final network = onNetwork;
    return Card(
      key: Key('menu-${spec.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              key: Key('menu-${spec.id}-tile'),
              onTap: onLocal,
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
                    // KLD-124: how many play, in the box's top corner.
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ExcludeSemantics(child: CustomPaint(painter: visuals.illustration(palette))),
                        ),
                        PositionedDirectional(top: -2, end: -2, child: PlayerCountChip(spec: spec)),
                        // KLD-069: the view-only card gallery of a game with
                        // decks, in the box's lower corner (the tile's foot
                        // has no room next to "Regeln" on a phone).
                        if (spec.usesDeck)
                          PositionedDirectional(
                            bottom: -4,
                            end: -4,
                            child: _CardsLink(
                              key: Key('menu-${spec.id}-cards'),
                              accent: accent,
                              label: l10n.menuCards,
                              onPressed: () => Navigator.of(context)
                                  .push(MaterialPageRoute<void>(builder: (_) => const QuartettGalleryScreen())),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PlayLink(
                  key: Key('menu-${spec.id}-local'),
                  accent: accent,
                  icon: Icons.smartphone,
                  label: l10n.menuPlayOnOneDevice,
                  onTap: onLocal,
                ),
                if (network != null) ...[
                  const SizedBox(height: 6),
                  _PlayLink(
                    key: Key('menu-${spec.id}-network'),
                    accent: accent,
                    icon: Icons.wifi,
                    label: l10n.menuPlayWithOthers,
                    onTap: network,
                    blocked: networkBlocked,
                  ),
                ],
                // KLD-123: the game's rules page, with the defaults.
                if (hasRules(spec.id))
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: Key('menu-${spec.id}-rules'),
                      onPressed: () => openRules(context, spec.id),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: accent.onSurface(theme.brightness),
                        padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 8, 0),
                      ),
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: Text(l10n.rulesButton),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A play-mode link at the bottom of a game tile (KLD-105): a tinted,
/// outlined button (≥48 px high) with the mode's icon, its label and a
/// chevron, so it reads as tappable and apart from the tile body. The
/// chevron follows the text direction.
class _PlayLink extends StatelessWidget {
  final GameAccent accent;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Greyed out (KLD-108); a tap still calls [onTap] (the explanation).
  final bool blocked;
  const _PlayLink({
    super.key,
    required this.accent,
    required this.icon,
    required this.label,
    required this.onTap,
    this.blocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final fg = dark ? theme.colorScheme.onSurface : Color.lerp(accent.color, Colors.black, 0.25)!;
    final iconColor = accent.onSurface(theme.brightness);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: accent.color.withValues(alpha: dark ? 0.7 : 0.45)),
    );
    final link = Material(
      color: dark ? accent.container : accent.container.withValues(alpha: 0.55),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 2, 6),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    );
    return Greyed(blocked: blocked, child: link);
  }
}

/// KLD-098: "Raum starten" and "Raum beitreten", two equal buttons side by
/// side (stacked on very narrow screens), the same height.
class _RoomButtons extends StatelessWidget {
  final GameAccent accent;
  final VoidCallback onStart;
  final VoidCallback onJoin;
  final bool blocked;
  const _RoomButtons({required this.accent, required this.onStart, required this.onJoin, this.blocked = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final start = _RoomButton(
      key: const Key('menu-room-start'),
      accent: accent,
      icon: Icons.meeting_room_outlined,
      title: l10n.roomStart,
      subtitle: l10n.roomStartSubtitle,
      onTap: onStart,
      blocked: blocked,
    );
    final join = _RoomButton(
      key: const Key('menu-room-join'),
      accent: accent,
      icon: Icons.qr_code_scanner,
      title: l10n.roomJoin,
      subtitle: l10n.roomJoinSubtitle,
      onTap: onJoin,
      blocked: blocked,
    );
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [start, const SizedBox(height: 12), join],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: start), const SizedBox(width: 12), Expanded(child: join)],
          ),
        );
      },
    );
  }
}

enum _RoomChoice { start, join }

/// KLD-111: the sheet behind a game's "Mit anderen": the game's name, then
/// "Raum starten" (prominent, filled in the game's accent) above "Raum
/// beitreten" (outlined, secondary), both full width. Pops the chosen
/// [_RoomChoice].
class _RoomChoiceSheet extends StatelessWidget {
  final String title;
  final GameAccent accent;
  const _RoomChoiceSheet({required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final nav = Navigator.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('menu-room-choice'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              key: const Key('menu-room-choice-title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.menuSectionNetwork,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _RoomChoiceButton(
              key: const Key('menu-room-choice-start'),
              accent: accent,
              icon: Icons.meeting_room_outlined,
              title: l10n.roomStart,
              subtitle: l10n.roomStartSubtitle,
              primary: true,
              onTap: () => nav.pop(_RoomChoice.start),
            ),
            const SizedBox(height: 12),
            _RoomChoiceButton(
              key: const Key('menu-room-choice-join'),
              accent: accent,
              icon: Icons.qr_code_scanner,
              title: l10n.roomJoin,
              subtitle: l10n.roomJoinSubtitle,
              primary: false,
              onTap: () => nav.pop(_RoomChoice.join),
            ),
          ],
        ),
      ),
    );
  }
}

/// One full-width entry of the [_RoomChoiceSheet]: icon disc, title and
/// subtitle, chevron (mirrored in RTL). [primary]: filled with the accent
/// colour; otherwise outlined in it on the sheet's surface.
class _RoomChoiceButton extends StatelessWidget {
  final GameAccent accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool primary;
  final VoidCallback onTap;
  const _RoomChoiceButton({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final fg = primary ? accent.onColor : theme.colorScheme.onSurface;
    final muted = primary ? accent.onColor.withValues(alpha: 0.85) : theme.colorScheme.onSurfaceVariant;
    final outline = primary ? accent.color : accent.onSurface(theme.brightness);
    return Material(
      color: primary ? accent.color : (dark ? accent.container : theme.colorScheme.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: outline, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(14, primary ? 16 : 12, 8, primary ? 16 : 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary ? accent.onColor.withValues(alpha: 0.18) : accent.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent.onColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: (primary ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)
                          ?.copyWith(fontWeight: FontWeight.w700, color: fg),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: primary ? accent.onColor : outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomButton extends StatelessWidget {
  final GameAccent accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool blocked;
  const _RoomButton({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.blocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: accent.color, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: accent.color, shape: BoxShape.circle),
                child: Icon(icon, color: accent.onColor),
              ),
              const SizedBox(height: 10),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
    return Greyed(blocked: blocked, child: card);
  }
}

/// KLD-108: [child] greyed out (no colour, faded) when [blocked]: visible
/// and still tappable (the tap explains why it doesn't work here).
@visibleForTesting
class Greyed extends StatelessWidget {
  final bool blocked;
  final Widget child;
  const Greyed({super.key, required this.blocked, required this.child});

  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    if (!blocked) return child;
    return Opacity(opacity: 0.5, child: ColorFiltered(colorFilter: _greyscale, child: child));
  }
}

/// KLD-108: "Beta" next to "Klunki" in the GitHub Pages build.
class _BetaBadge extends StatelessWidget {
  const _BetaBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const Key('menu-beta-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Text(
        AppLocalizations.of(context).webBetaBadge,
        style: theme.textTheme.labelMedium?.copyWith(color: scheme.onTertiaryContainer, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// "Klunki Spielesammlung" in the menu's app bar: on one line when it fits,
/// else "Klunki" with "Spielesammlung" smaller below (never cut). Keys
/// `menu-title`, `menu-title-sub` (the second line).
class _MenuTitle extends StatelessWidget {
  const _MenuTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final base = DefaultTextStyle.of(context).style;
    final bold = base.copyWith(fontWeight: FontWeight.w700);
    final light = base.copyWith(fontWeight: FontWeight.w500);
    return LayoutBuilder(builder: (context, box) {
      final line = TextSpan(children: [
        TextSpan(text: l10n.appTitle, style: bold),
        TextSpan(text: ' ${l10n.appSubtitle}', style: light),
      ]);
      final painter = TextPainter(
        text: line,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout(maxWidth: box.maxWidth);
      final fits = !painter.didExceedMaxLines && painter.width <= box.maxWidth;
      painter.dispose();
      if (fits) return Text.rich(line, key: const Key('menu-title'), maxLines: 1, softWrap: false);
      final size = base.fontSize ?? 22;
      return Column(
        key: const Key('menu-title'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.appTitle, maxLines: 1, style: bold.copyWith(fontSize: size * 0.82, height: 1.1)),
          Text(l10n.appSubtitle,
              key: const Key('menu-title-sub'),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: light.copyWith(fontSize: size * 0.56, height: 1.15)),
        ],
      );
    });
  }
}

/// "Karten" in the lower corner of a game tile's picture box: a link in
/// the tile's accent colour like "Regeln", on a light pill so it reads on
/// the picture.
class _CardsLink extends StatelessWidget {
  final GameAccent accent;
  final String label;
  final VoidCallback onPressed;
  const _CardsLink({super.key, required this.accent, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, 30),
        foregroundColor: accent.onSurface(theme.brightness),
        backgroundColor: scheme.surface.withValues(alpha: 0.88),
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 10, 0),
      ),
      icon: const Icon(Icons.style_outlined, size: 18),
      label: Text(label),
    );
  }
}
