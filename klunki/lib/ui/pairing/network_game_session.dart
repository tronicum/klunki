import 'package:flutter/material.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';
import '../../transport/network_transport.dart';
import '../shell/game_screen.dart';
import '../shell/screen_registry.dart';

/// Owns a [GameController] over a [NetworkTransport] and shows the game's
/// regular screen (through the shell registry) with a small connection bar
/// underneath: "Du bist X · Gegner: NAME", plus a banner while the other
/// side is missing. The guest gets a "Neu verbinden" button there (the full
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildGameScreen(_controller),
      bottomNavigationBar: NetworkConnectionBar(transport: widget.transport),
    );
  }
}

/// "Du bist X · Gegner: iPad (O)" and, while the peer is missing, a banner.
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
      if (mounted) setState(() => _reconnectError = 'Neu verbinden fehlgeschlagen. Ist der Host noch im Spiel?');
    }
  }

  String _missingText() {
    final reason = t.lastDisconnectReason ?? '';
    if (reason.startsWith('peer left')) return 'Gegner hat das Spiel verlassen';
    return 'Verbindung zum Gegner unterbrochen';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<NetConnectionState>(
      valueListenable: t.connection,
      builder: (context, state, _) {
        final me = t.me;
        final peer = t.peerName ?? 'Gegner';
        final missing = state == NetConnectionState.peerMissing;
        final reconnecting = state == NetConnectionState.reconnecting;
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
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        Expanded(
                          child: Text(
                            reconnecting
                                ? 'Verbinde neu…'
                                : t.role == NetRole.host
                                    ? '${_missingText()}. Warte, bis er wieder beitritt…'
                                    : _missingText(),
                            style: TextStyle(color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                        if (missing && t.role == NetRole.guest)
                          TextButton(
                            key: const Key('net-reconnect'),
                            onPressed: _reconnect,
                            child: const Text('Neu verbinden'),
                          ),
                      ],
                    ),
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
                      Expanded(
                        child: Text(
                          'Du bist ${playerMark(me)} · Gegner: $peer (${playerMark(me == Player.a ? Player.b : Player.a)})',
                          key: const Key('net-status'),
                          overflow: TextOverflow.ellipsis,
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
