import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../app/screen_awake.dart';
import '../../game/game_controller.dart';
import '../../transport/network_transport.dart';
import '../game_visuals.dart' show tokenSidesOf;
import '../games/wordtiles/wordtiles_options.dart' show loadWordListWithProgress;
import '../game_titles.dart';
import '../ltr.dart';
import 'relay_errors.dart';
import 'table_lobby.dart';
import '../shell/game_screen.dart';
import '../shell/screen_registry.dart';
import '../shell/seat_labels.dart';

/// Owns a [GameController] over a [NetworkTransport] and shows the game's
/// regular screen (through the shell registry) with a small connection bar
/// underneath: each player's token in their colour plus "Du: Anna" /
/// "Gegner: Ben" (KLD-067), plus a banner while the
/// other side is missing. The game shell names both players through a
/// [PlayerLabelsScope] (KLD-056, KLD-106): "Du bist am Zug", "Warte auf Ben…",
/// "Ben gewinnt!", "Ben: …" in the history.
///
/// KLD-120, a locked phone: the session tells the transport when the app
/// goes to the background and comes back ([NetworkTransport.appPaused],
/// [NetworkTransport.appResumed]); the guest then reconnects by itself
/// ("Verbindung wird wiederhergestellt …"), the host listens again or comes
/// back to its relay room. The guest's "Neu verbinden" button is the
/// fallback once the automatic reconnect gave up. While the game runs the
/// screen does not lock by itself ([ScreenAwake]).
///
/// A table of 3–4 players (KLD-088 step 4, [NetworkTransport.table]): a
/// guest sees the lobby ([TableLobby]) until every seat is taken, then the
/// seat game screen named from this device's seat ([tableSeatLabels]) and
/// the [TableConnectionBar].
///
/// One local player per device, so the controller never asks for a
/// handover. Leaving the route disposes the controller, which disposes the
/// transport (`bye` to the other side).
class NetworkGameSession extends StatefulWidget {
  final NetworkTransport transport;

  const NetworkGameSession({super.key, required this.transport});

  @override
  State<NetworkGameSession> createState() => _NetworkGameSessionState();
}

class _NetworkGameSessionState extends State<NetworkGameSession> with WidgetsBindingObserver {
  late final GameController _controller = GameController(
    widget.transport,
    transportFactory: (_) => throw UnsupportedError('a network game cannot be restarted locally'),
  );
  bool? _screenOn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_keepScreenOn);
    _keepScreenOn();
    // KLD-094 step 6: a guest of a Wortgewandt game with "Wörterbuch prüfen"
    // loads the same word list (the fingerprint made sure it is the same)
    // to check its own words at "Legen" and the host's game at the end.
    final config = widget.transport.config;
    final tiles = config.tiles ?? TileSet.german.id;
    if (config.gameId == 'wordtiles' && config.dictionary && !WordLists.has(tiles)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) loadWordListWithProgress(context, tiles);
      });
    }
  }

  /// The screen stays on while the game runs (KLD-120), not after it.
  void _keepScreenOn() {
    final on = !_controller.game.isOver;
    if (on == _screenOn) return;
    _screenOn = on;
    ScreenAwake.keepOn(on);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        widget.transport.appPaused();
      case AppLifecycleState.resumed:
        widget.transport.appResumed();
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break; // inactive: e.g. Control Center pulled down; the app still runs
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_keepScreenOn);
    if (_screenOn ?? false) ScreenAwake.keepOn(false);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transport;
    if (t.table) {
      return ListenableBuilder(
        listenable: t.changes,
        builder: (context, child) => t.started
            ? Scaffold(
                body: SeatLabelsScope(labels: tableSeatLabels(t), child: child!),
                bottomNavigationBar: TableConnectionBar(transport: t),
              )
            : _TableLobbyScreen(transport: t),
        child: buildGameScreen(_controller),
      );
    }
    return Scaffold(
      // The peer's name arrives with the handshake (and again on reconnect).
      body: ValueListenableBuilder<NetConnectionState>(
        valueListenable: t.connection,
        builder: (context, _, child) => PlayerLabelsScope(labels: networkLabels(t), child: child!),
        child: buildGameScreen(_controller),
      ),
      bottomNavigationBar: NetworkConnectionBar(transport: t),
    );
  }
}

/// Labels for a network game: this device's player is [NetworkTransport.me]
/// ("Du"), both players carry their names; the tokens follow the config
/// (chess with the host on Black, KLD-059 step 4a: [tokenSidesOf]).
PlayerLabels networkLabels(NetworkTransport t) {
  final peer = t.peerName;
  return PlayerLabels(
    local: t.me,
    names: {
      t.me: t.localName,
      _otherPlayer(t.me): ?peer,
    },
    tokens: tokenSidesOf(t.config),
  );
}

/// The other player.
Player _otherPlayer(Player p) => p == Player.a ? Player.b : Player.a;

/// "Du: Anna · Gegner: Ben" and, while the peer is missing, a banner.
class NetworkConnectionBar extends StatefulWidget {
  final NetworkTransport transport;

  const NetworkConnectionBar({super.key, required this.transport});

  @override
  State<NetworkConnectionBar> createState() => _NetworkConnectionBarState();
}

class _NetworkConnectionBarState extends State<NetworkConnectionBar> {
  String? _reconnectError;

  NetworkTransport get t => widget.transport;

  Future<void> _reconnect() async {
    setState(() => _reconnectError = null);
    try {
      await t.reconnect();
    } catch (e) {
      // KLD-085: the host was updated in between (or this app was).
      if (mounted) {
        setState(() =>
            _reconnectError = versionMismatchText(context, e) ?? AppLocalizations.of(context).pairingReconnectFailed);
      }
    }
  }

  String _missingText(AppLocalizations l10n, String peer) {
    final reason = t.lastDisconnectReason ?? '';
    if (reason.startsWith('peer left')) return l10n.pairingPeerLeft(peer);
    return l10n.pairingPeerLost(peer);
  }

  /// Relay games (KLD-057b): the room is gone (host left, expired, relay
  /// lost), so waiting or reconnecting is pointless; null otherwise.
  String? _roomClosedText(BuildContext context) {
    if (t.roomCode == null) return null;
    final lost = t.roomLost;
    if (t.role == NetRole.host) {
      if (lost == null) return null;
      final why = relayErrorText(context, lost, relay: t.relayUrl) ?? lost;
      return AppLocalizations.of(context).relayRoomLost(why);
    }
    final reason = t.lastDisconnectReason ?? '';
    // A relay host that says bye has closed its session, and with it the room.
    if (reason.startsWith('peer left')) return AppLocalizations.of(context).relayErrorRoomClosed;
    if (!relayRoomClosed(classifyRelayError(reason))) return null;
    return relayErrorText(context, reason, code: t.roomCode, relay: t.relayUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: t.changes,
      builder: (context, _) {
        final state = t.connection.value;
        final me = t.me;
        final gameId = t.config.gameId;
        final peerName = t.peerName;
        final peer = peerName == null ? l10n.pairingOpponent : bidiName(context, peerName);
        final missing = state == NetConnectionState.peerMissing;
        final reconnecting = state == NetConnectionState.reconnecting;
        final roomClosed = missing ? _roomClosedText(context) : null;
        // KLD-120: why the automatic reconnect gave up (the manual button's
        // own error wins).
        final autoError = t.reconnectError;
        final reconnectError = _reconnectError ??
            (autoError == null || roomClosed != null
                ? null
                : versionMismatchText(context, autoError) ??
                    relayErrorText(context, autoError, code: t.roomCode, relay: t.relayUrl) ??
                    (isSeatTaken(autoError) ? l10n.pairingSeatTaken : l10n.pairingReconnectFailed));
        return Material(
          key: const Key('net-bar'),
          color: theme.colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (missing || reconnecting)
                  Container(
                    key: const Key('net-banner'),
                    color: theme.colorScheme.errorContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        if (reconnecting)
                          const Padding(
                            padding: EdgeInsetsDirectional.only(end: 8),
                            child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        Expanded(
                          child: Text(
                            reconnecting
                                ? l10n.pairingReconnecting
                                : roomClosed ?? (t.role == NetRole.host
                                    ? l10n.pairingWaitForRejoin(_missingText(l10n, peer))
                                    : _missingText(l10n, peer)),
                            style: TextStyle(color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                        if (missing && t.role == NetRole.guest && roomClosed == null)
                          TextButton(
                            key: const Key('net-reconnect'),
                            onPressed: _reconnect,
                            child: Text(l10n.pairingReconnect),
                          ),
                      ],
                    ),
                  ),
                // KLD-064: the host's reveal did not confirm the game.
                if (t.verificationFailed)
                  Container(
                    key: const Key('net-verification-failed'),
                    color: theme.colorScheme.errorContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(l10n.networkVerificationFailed,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                  ),
                if (reconnectError != null && missing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(reconnectError,
                        key: const Key('net-reconnect-error'), style: TextStyle(color: theme.colorScheme.error)),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        state == NetConnectionState.connected ? Icons.wifi : Icons.wifi_off,
                        size: 18,
                        color: state == NetConnectionState.connected ? theme.colorScheme.primary : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      // Each player as token (colour + number or piece, KLD-067,
                      // KLD-106) and name; read out as "Du: Anna · Gegner: Ben".
                      Expanded(
                        // The bar sits outside the game's labels scope: its
                        // tokens need the same token sides.
                        child: PlayerLabelsScope(
                          labels: networkLabels(t),
                          child: Semantics(
                            key: const Key('net-status'),
                            label: l10n.pairingStatus(bidiName(context, t.localName), peer),
                            excludeSemantics: true,
                            child: Row(
                              children: [
                                PlayerToken(key: const Key('net-you-token'), gameId: gameId, player: me, size: 20),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    l10n.netBarYou(bidiName(context, t.localName)),
                                    key: const Key('net-you'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('·')),
                                PlayerToken(
                                    key: const Key('net-peer-token'),
                                    gameId: gameId,
                                    player: _otherPlayer(me),
                                    size: 20),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    l10n.netBarOpponent(peer),
                                    key: const Key('net-peer'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A guest's room before the game (KLD-088 step 4): the host's room, the
/// seats and "Warte auf noch 1 Mitspieler…"; back leaves the room.
class _TableLobbyScreen extends StatelessWidget {
  final NetworkTransport transport;
  const _TableLobbyScreen({required this.transport});

  @override
  Widget build(BuildContext context) {
    final t = transport;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gameId = t.config.gameId;
    final title = localizedGameTitle(l10n, gameId, fallback: specById(gameId)?.title ?? gameId);
    final host = t.seats.isEmpty ? null : t.seats.first.name;
    return Scaffold(
      key: const Key('table-lobby-screen'),
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (host != null)
                  Text(l10n.roomOfPlayer(bidiName(context, host), title),
                      key: const Key('table-lobby-room'),
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TableLobby(transport: t),
                const SizedBox(height: 24),
                OutlinedButton(
                  key: const Key('table-lobby-leave'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(l10n.pairingCancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The connection bar of a table (KLD-088 step 4): every seat as token and
/// name ("Du: Anna" for this device; a seat that is away greyed out), a
/// banner while the game waits for someone ("Pause: Warte auf Ben…") and, on
/// the host, "Ohne Ben weiterspielen" for each seat that is away. A guest
/// that lost the host sees the same banner and "Neu verbinden" as in a game
/// of two.
class TableConnectionBar extends StatefulWidget {
  final NetworkTransport transport;
  const TableConnectionBar({super.key, required this.transport});

  @override
  State<TableConnectionBar> createState() => _TableConnectionBarState();
}

class _TableConnectionBarState extends State<TableConnectionBar> {
  String? _reconnectError;

  NetworkTransport get t => widget.transport;

  Future<void> _reconnect() async {
    setState(() => _reconnectError = null);
    try {
      await t.reconnect();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _reconnectError = versionMismatchText(context, e) ?? AppLocalizations.of(context).pairingReconnectFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: t.changes,
      builder: (context, _) {
        final state = t.connection.value;
        final seats = t.seats;
        final labels = tableSeatLabels(t);
        String name(int seat) => labels.label(context, l10n, seat, count: seats.length);
        final host = t.role == NetRole.host;
        // A guest that lost the host itself: as in a game of two.
        final lostHost = !host && (state == NetConnectionState.peerMissing || state == NetConnectionState.reconnecting);
        final away = [
          for (var s = 0; s < seats.length; s++)
            if (s != t.seat && !seats[s].free && !seats[s].here) s
        ];
        final paused = !lostHost && away.isNotEmpty && !t.game.isOver;
        final reconnectError = lostHost
            ? _reconnectError ?? (t.reconnectError == null ? null : l10n.pairingReconnectFailed)
            : null;
        Widget banner(Key key, String text, {List<Widget> actions = const [], bool busy = false}) => Container(
              key: key,
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (busy)
                        const Padding(
                          padding: EdgeInsetsDirectional.only(end: 8),
                          child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      Expanded(child: Text(text, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
                    ],
                  ),
                  if (actions.isNotEmpty) Wrap(alignment: WrapAlignment.end, spacing: 8, children: actions),
                ],
              ),
            );
        return Material(
          key: const Key('net-bar'),
          color: theme.colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (lostHost)
                  banner(
                    const Key('net-banner'),
                    state == NetConnectionState.reconnecting
                        ? l10n.pairingReconnecting
                        : l10n.pairingPeerLost(name(0)),
                    busy: state == NetConnectionState.reconnecting,
                    actions: [
                      if (state == NetConnectionState.peerMissing)
                        TextButton(key: const Key('net-reconnect'), onPressed: _reconnect, child: Text(l10n.pairingReconnect)),
                    ],
                  )
                else if (paused)
                  banner(
                    const Key('net-banner'),
                    l10n.tablePaused(away.map(name).join(', ')),
                    busy: true,
                    actions: [
                      if (host)
                        for (final s in away)
                          TextButton(
                            key: Key('table-let-leave-$s'),
                            onPressed: () => t.resignAwaySeat(s),
                            child: Text(l10n.tableLetLeave(name(s))),
                          ),
                    ],
                  ),
                if (t.verificationFailed)
                  Container(
                    key: const Key('net-verification-failed'),
                    color: theme.colorScheme.errorContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(l10n.networkVerificationFailed,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                  ),
                if (reconnectError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(reconnectError,
                        key: const Key('net-reconnect-error'), style: TextStyle(color: theme.colorScheme.error)),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        lostHost ? Icons.wifi_off : Icons.wifi,
                        size: 18,
                        color: lostHost ? theme.colorScheme.error : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          key: const Key('net-status'),
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (var s = 0; s < seats.length; s++)
                              Row(
                                key: Key('net-seat-$s'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SeatToken(seat: s, size: 20, out: s != t.seat && !seats[s].here),
                                  const SizedBox(width: 6),
                                  Text(s == t.seat ? l10n.netBarYou(name(s)) : name(s),
                                      style: s == t.seat ? const TextStyle(fontWeight: FontWeight.w600) : null),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
