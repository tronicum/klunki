/// Host-authoritative network play for Klunki. Pure Dart, no Flutter. See
/// `PROTOCOL.md`.
///
/// Guests join over TCP (newline-delimited JSON) or WebSocket (one JSON
/// message per text frame); the host accepts both. Importing this library is
/// web-safe (`dart:io` is only reached through conditional imports): in a
/// browser [KlunkiGuest.connectWebSocket] works, hosting and TCP do not.
/// `package:klunki_net/guest_web.dart` exports only the guest side.
library;

export 'src/addresses.dart' show defaultTcpPort, defaultWebSocketPort, webSocketUri;
export 'src/events.dart'
    show
        protocolVersion,
        NetEvent,
        PeerConnected,
        PeerDisconnected,
        MoveAccepted,
        MoveRejected,
        Resynced,
        NetError,
        NetException;
export 'src/guest.dart' show KlunkiGuest;
export 'src/names.dart' show maxPlayerNameLength, sanitizePlayerName, playerNameOr;
export 'src/host.dart' show KlunkiHost;
