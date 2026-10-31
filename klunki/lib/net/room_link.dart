/// Room codes and join links for browser vs browser through the relay
/// (KLD-057b). Pure Dart (no Flutter, no `dart:io`), safe on the web.
///
/// The host shows `<page>/?room=K7Q2M` (plus `&relay=host:port` when the
/// relay is not the page's own server); opening that link starts the PWA on
/// the room-code join and connects.
library;

import 'package:klunki_net/guest_web.dart' show normalizeRoomCode, parseRelayUrl, relayUriForPage;

/// URL query parameter with the room code: `http://<pwa>/?room=K7Q2M`.
const String roomQueryParameter = 'room';

/// URL query parameter with a relay address other than the page's own
/// server (`host:port` or `ws://…`).
const String relayQueryParameter = 'relay';

/// How the relay is started (shown when a page is not served by a relay).
const String relayStartCommand = 'dart run packages/klunki_net/bin/klunki.dart relay --web klunki/build/web';

/// `K7Q2M` → `K7Q 2M` (3 + 2, easier to read out and type). Anything that is
/// not a valid code is returned unchanged.
String formatRoomCode(String code) {
  final c = normalizeRoomCode(code);
  if (c == null) return code;
  return '${c.substring(0, 3)} ${c.substring(3)}';
}

/// `ws://192.168.1.20:8000/relay` → `192.168.1.20:8000` (what the relay
/// address field shows); other paths and `wss` stay a full URL.
String relayAddressLabel(Uri relay) {
  if (relay.scheme == 'ws' && relay.path == '/relay') return relay.hasPort ? '${relay.host}:${relay.port}' : relay.host;
  return relay.toString();
}

/// A `?room=` link: the room [code] (normalised; null when the parameter is
/// not a valid code) and an explicit [relay] (null: the page's own server).
class RoomLink {
  /// The parameter as given (for prefilling the field when it is invalid).
  final String raw;
  final String? code;
  final Uri? relay;

  const RoomLink(this.raw, this.code, this.relay);

  /// The `room` (and `relay`) parameters of [pageUrl], or null without a
  /// non-empty `room`.
  static RoomLink? fromPage(Uri? pageUrl) {
    final raw = pageUrl?.queryParameters[roomQueryParameter]?.trim();
    if (raw == null || raw.isEmpty) return null;
    final relayText = pageUrl!.queryParameters[relayQueryParameter]?.trim();
    final relay = relayText == null || relayText.isEmpty ? null : parseRelayUrl(relayText);
    return RoomLink(raw, normalizeRoomCode(raw), relay);
  }

  @override
  bool operator ==(Object other) => other is RoomLink && other.raw == raw && other.code == code && other.relay == relay;

  @override
  int get hashCode => Object.hash(raw, code, relay);

  @override
  String toString() => 'RoomLink($raw, code: $code, relay: $relay)';
}

/// The link the host shows for room [code] on [relay]:
/// - in the browser ([pageUrl] set): the page itself with `?room=CODE`, plus
///   `&relay=…` when [relay] is not the page's own server;
/// - otherwise the relay's origin over http(s) (a relay started with `--web`
///   serves the PWA there).
Uri roomJoinLink({required String code, required Uri relay, Uri? pageUrl}) {
  final page = pageUrl;
  if (page != null && (page.scheme == 'http' || page.scheme == 'https') && page.host.isNotEmpty) {
    final own = relayUriForPage(page);
    return Uri(
      scheme: page.scheme,
      host: page.host,
      port: page.hasPort ? page.port : null,
      path: page.path.isEmpty ? '/' : page.path,
      queryParameters: {roomQueryParameter: code, if (own != relay) relayQueryParameter: relayAddressLabel(relay)},
    );
  }
  return Uri(
    scheme: relay.scheme == 'wss' ? 'https' : 'http',
    host: relay.host,
    port: relay.hasPort ? relay.port : null,
    path: '/',
    queryParameters: {roomQueryParameter: code},
  );
}
