/// The Klunki relay server (`klunki relay`): room codes that pair one host
/// with one guest and forward their protocol lines unchanged, plus static
/// serving of the built PWA. Server only: imports `dart:io`, so a browser
/// build must not import this library (use `klunki_net.dart` for the
/// clients: `KlunkiHost.startRelay`, `KlunkiGuest.connectRelay`).
///
///     final relay = await RelayServer.start(port: 8080, webRoot: Directory('klunki/build/web'));
///
/// See PROTOCOL.md, "Relay".
library;

export 'src/relay/relay_protocol.dart'
    show
        relayPath,
        defaultRelayPort,
        roomCodeLength,
        roomCodeAlphabet,
        normalizeRoomCode,
        parseRelayUrl,
        relayUriForPage;
export 'src/relay/relay_server.dart' show RelayServer, mimeTypeFor;
