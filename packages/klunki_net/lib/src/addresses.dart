/// Default TCP port of a Klunki host (NDJSON guests: apps, the CLI).
const int defaultTcpPort = 4747;

/// Default WebSocket port of a Klunki host (browser guests, the PWA). Sent
/// as `w=` in the join payload and `ws` in the mDNS TXT record.
const int defaultWebSocketPort = 4748;

/// The URL a WebSocket guest connects to: `ws://host:port`.
Uri webSocketUri(String host, int port) => Uri(scheme: 'ws', host: host, port: port);
