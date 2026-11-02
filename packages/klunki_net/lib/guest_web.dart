/// The guest side of Klunki network play, for the browser (the PWA): join a
/// native host (app or `klunki host` CLI) over WebSocket on the local network,
/// or a room on a relay ([KlunkiGuest.connectRelay]; browser vs browser).
///
///     final guest = await KlunkiGuest.connectWebSocket(
///         webSocketUri('192.168.1.20', defaultWebSocketPort), name: 'Bea');
///
/// Compiles without `dart:io` (checked by `test/web_compile_test.dart`); on
/// the VM the same API runs over `dart:io`'s WebSocket. No Flutter imports.
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
        IncompatiblePeer,
        Incompatibility,
        PeerAge,
        VersionMismatch;
export 'src/compat.dart' show BuildCompat, compareBuilds, versionDisplay;
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
