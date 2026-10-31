/// What a scanned QR code means for the join tab (KLD-052). Pure Dart (no
/// Flutter, no `dart:io`).
///
/// Understands every QR code a Klunki host shows:
///
/// | QR content | result |
/// |---|---|
/// | `klunki://join?h=192.168.1.20&p=4747&w=4748&n=…&g=…` (native host, KLD-033) | [ScannedDirectJoin] (TCP `h:p`) |
/// | `http(s)://host:port/?room=K7Q2M&relay=…` (browser host, KLD-057b) | [ScannedRoomJoin] (room on `relay`) |
/// | `http(s)://host:port/?room=K7Q2M` (no `relay`) | [ScannedRoomJoin] on the link's own server ([relayUriForPage]) |
/// | `http(s)://pwa/?join=<klunki:// link>` (KLD-055 page link) | [ScannedDirectJoin] |
///
/// Anything else (plain text, other URLs, a bad code, host or port) is null:
/// "not a Klunki code". Plain `IP:port` text is deliberately not accepted
/// (any word would be a "host name"); no host encodes it.
library;

import 'package:klunki_net/guest_web.dart' show normalizeRoomCode, parseRelayUrl, relayUriForPage;

import 'join_payload.dart';
import 'room_link.dart';
import 'web_join_target.dart' show joinQueryParameter;

/// A scanned code the app can join.
sealed class ScannedJoin {
  const ScannedJoin();
}

/// Join a native host directly over the LAN (TCP `host:port`).
final class ScannedDirectJoin extends ScannedJoin {
  final JoinPayload payload;

  const ScannedDirectJoin(this.payload);

  @override
  bool operator ==(Object other) => other is ScannedDirectJoin && other.payload == payload;

  @override
  int get hashCode => payload.hashCode;

  @override
  String toString() => 'ScannedDirectJoin($payload)';
}

/// Join relay room [code] (normalised) on [relay] (`ws(s)://host:port/relay`).
final class ScannedRoomJoin extends ScannedJoin {
  final String code;
  final Uri relay;

  const ScannedRoomJoin(this.code, this.relay);

  @override
  bool operator ==(Object other) => other is ScannedRoomJoin && other.code == code && other.relay == relay;

  @override
  int get hashCode => Object.hash(code, relay);

  @override
  String toString() => 'ScannedRoomJoin($code, $relay)';
}

/// Parses the text of a scanned QR code; null if it is not a Klunki code.
ScannedJoin? parseScannedJoinCode(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final lower = text.toLowerCase();

  if (lower.startsWith('$joinScheme:')) {
    final p = JoinPayload.tryParse(text);
    return p == null ? null : ScannedDirectJoin(p);
  }

  if (!lower.startsWith('http://') && !lower.startsWith('https://')) return null;
  final Uri uri;
  try {
    uri = Uri.parse(text);
  } on FormatException {
    return null;
  }
  if (!JoinPayload.isValidHost(uri.host)) return null;

  // Browser host through the relay: `?room=CODE[&relay=…]`.
  final room = uri.queryParameters[roomQueryParameter]?.trim();
  if (room != null && room.isNotEmpty) {
    final code = normalizeRoomCode(room);
    if (code == null) return null;
    final relayText = uri.queryParameters[relayQueryParameter]?.trim();
    final relay =
        relayText == null || relayText.isEmpty ? relayUriForPage(uri) : parseRelayUrl(relayText);
    return relay == null ? null : ScannedRoomJoin(code, relay);
  }

  // A PWA link with `?join=<klunki:// link>`: the app joins its TCP side.
  final inner = uri.queryParameters[joinQueryParameter]?.trim();
  if (inner != null && inner.toLowerCase().startsWith('$joinScheme:')) {
    final p = JoinPayload.tryParse(inner);
    return p == null ? null : ScannedDirectJoin(p);
  }
  return null;
}
