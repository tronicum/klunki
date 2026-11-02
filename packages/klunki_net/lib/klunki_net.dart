/// Host-authoritative network play for Klunki. Pure Dart, no Flutter. See
/// `PROTOCOL.md`.
///
/// Guests join over TCP (newline-delimited JSON) or WebSocket (one JSON
/// message per text frame); the host accepts both. Importing this library is
/// web-safe (`dart:io` is only reached through conditional imports): in a
/// browser [KlunkiGuest.connectWebSocket] works, hosting and TCP do not.
/// `package:klunki_net/guest_web.dart` exports only the guest side.
///
/// Browser vs browser goes through a relay (`klunki relay`, see PROTOCOL.md,
/// "Relay"): [KlunkiHost.startRelay] opens a room and shows its
/// [KlunkiHost.roomCode]; [KlunkiGuest.connectRelay] joins it. Both are
/// web-safe. The relay server itself is `package:klunki_net/relay_server.dart`
/// (`dart:io`).
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
        NetException,
        GameVerified,
        VerificationFailed,
        Verification,
        IncompatiblePeer,
        Incompatibility,
        PeerAge,
        VersionMismatch;
export 'src/compat.dart' show BuildCompat, compareBuilds;
export 'src/guest.dart' show KlunkiGuest;
export 'src/relay/relay_protocol.dart'
    show
        relayPath,
        defaultRelayPort,
        roomCodeLength,
        roomCodeAlphabet,
        normalizeRoomCode,
        parseRelayUrl,
        relayUriForPage,
        normalizeClubCode,
        newClubCode,
        relayClubMissingText,
        relayClubWrongText;
export 'src/names.dart' show maxPlayerNameLength, sanitizePlayerName, playerNameOr;
export 'src/host.dart' show KlunkiHost;
