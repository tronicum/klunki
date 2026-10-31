/// The guest side of Klunki network play, for the browser (the PWA): join a
/// native host (app or `klunki host` CLI) over WebSocket on the local network.
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
        NetException;
export 'src/guest.dart' show KlunkiGuest;
