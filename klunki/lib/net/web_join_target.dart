/// Where a browser guest connects (KLD-055): what the web join screen makes of
/// the typed text or the `?join=` URL parameter. Pure Dart (no Flutter, no
/// `dart:io`), so it is safe on the web.
///
/// Accepted forms (all end up as `ws://host:port`):
///
/// | input | WebSocket URL |
/// |---|---|
/// | `192.168.1.20` | `ws://192.168.1.20:4748` (default WebSocket port) |
/// | `192.168.1.20:5000` | `ws://192.168.1.20:5000` (the port **is** the WebSocket port) |
/// | `klunki://join?h=192.168.1.20&p=4747&w=4749` | `ws://192.168.1.20:4749` (`w`; without `w`: 4748) |
/// | `ws://192.168.1.20:4749` | itself (path and query dropped; no port: 4748) |
/// | `http://pwa/?join=<any of the above>` | what the `join` parameter says |
library;

import 'join_payload.dart';

/// URL query parameter of the PWA that opens the join flow directly:
/// `http://<pwa>/?join=<urlencoded klunki:// link>`.
const String joinQueryParameter = 'join';

class WebJoinTarget {
  /// `ws://host:port`.
  final Uri uri;

  /// The host's display name, if the input was a `klunki://` link with `n`.
  final String? name;

  /// The hosted game, if the input was a `klunki://` link with `g`.
  final String? gameId;

  const WebJoinTarget(this.uri, {this.name, this.gameId});

  String get host => uri.host;
  int get port => uri.port;

  /// `host:port` of the WebSocket endpoint.
  String get address => '$host:$port';

  /// What the UI calls the host while connecting: its name, else `host:port`.
  String get label => name ?? address;

  static Uri _ws(String host, int port) => Uri(scheme: 'ws', host: host, port: port);

  /// Parses any of the accepted forms; null for anything else (`wss://`,
  /// other schemes, bad hosts or ports, an unsupported protocol version).
  static WebJoinTarget? tryParse(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();

    if (lower.startsWith('$joinScheme:')) {
      final p = JoinPayload.tryParse(text);
      if (p == null || p.protocol != klunkiProtocolVersion) return null;
      return WebJoinTarget(_ws(p.host, p.wsPort ?? klunkiDefaultWebSocketPort), name: p.name, gameId: p.gameId);
    }

    if (lower.startsWith('ws://')) {
      final Uri uri;
      try {
        uri = Uri.parse(text);
      } on FormatException {
        return null;
      }
      if (!JoinPayload.isValidHost(uri.host)) return null;
      // Uri.port is 80 for ws:// without a port: use the Klunki default instead.
      final port = uri.hasPort ? uri.port : klunkiDefaultWebSocketPort;
      if (port < 1 || port > 65535) return null;
      return WebJoinTarget(_ws(uri.host, port));
    }

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      // A pasted PWA link with ?join=… (e.g. from a QR code).
      final Uri uri;
      try {
        uri = Uri.parse(text);
      } on FormatException {
        return null;
      }
      final inner = uri.queryParameters[joinQueryParameter];
      if (inner == null || inner.toLowerCase().startsWith('http')) return null;
      return tryParse(inner);
    }

    if (text.contains('://')) return null; // wss:// and other schemes

    // IP or IP:port; the port is the WebSocket port.
    final p = JoinPayload.tryParse(text);
    if (p == null) return null;
    final port = text.contains(':') ? p.port : klunkiDefaultWebSocketPort;
    return WebJoinTarget(_ws(p.host, port));
  }

  /// The `join` parameter of [pageUrl] (`?join=…`), or null if absent/empty.
  static String? joinParameter(Uri? pageUrl) {
    final v = pageUrl?.queryParameters[joinQueryParameter]?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  bool operator ==(Object other) =>
      other is WebJoinTarget && other.uri == uri && other.name == name && other.gameId == gameId;

  @override
  int get hashCode => Object.hash(uri, name, gameId);

  @override
  String toString() => 'WebJoinTarget($uri, name: $name, game: $gameId)';
}
