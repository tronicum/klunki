/// Host-authoritative network play for Klunki: newline-delimited JSON over
/// one TCP connection. Pure Dart (`dart:io`), so it runs in the terminal, on
/// Android and on iOS. See `PROTOCOL.md`.
library;

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
export 'src/host.dart' show KlunkiHost;
