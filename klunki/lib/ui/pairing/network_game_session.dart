import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';
import '../../transport/network_transport.dart';
import '../games/wordtiles/wordtiles_options.dart' show loadWordListWithProgress;
import '../ltr.dart';
import 'relay_errors.dart';
import '../shell/game_screen.dart';
import '../shell/screen_registry.dart';

/// Owns a [GameController] over a [NetworkTransport] and shows the game's
/// regular screen (through the shell registry) with a small connection bar
/// underneath: each player's token in their colour plus "Du: Anna" /
/// "Gegner: Ben" (KLD-067), plus a banner while the
/// other side is missing. The game shell names both players through a
/// [PlayerLabelsScope] (KLD-056, KLD-106): "Du bist am Zug", "Warte auf Ben…",
/// "Ben gewinnt!", "Ben: …" in the history. The guest gets a "Neu verbinden" button there (the full
/// reconnect UX is KLD-036).
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

class _NetworkGameSessionState extends State<NetworkGameSession> {
  late final GameController _controller = GameController(
    widget.transport,
    transportFactory: (_) => throw UnsupportedError('a network game cannot be restarted locally'),
  );

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transport;
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
/// ("Du"), both players carry their names.
PlayerLabels networkLabels(NetworkTransport t) {
  final peer = t.peerName;
  return PlayerLabels(
    local: t.me,
    names: {
      t.me: t.localName,
      _otherPlayer(t.me): ?peer,
    },
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
                if (_reconnectError != null && missing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(_reconnectError!, style: TextStyle(color: theme.colorScheme.error)),
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
                                  key: const Key('net-peer-token'), gameId: gameId, player: _otherPlayer(me), size: 20),
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
