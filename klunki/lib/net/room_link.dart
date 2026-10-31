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
  if (relay.scheme == 'ws' && relay.path == '/relay') {
    // IPv6 hosts in brackets (`[::1]:8081`), so the label parses back.
    final host = relay.host.contains(':') ? '[${relay.host}]' : relay.host;
    return relay.hasPort ? '$host:${relay.port}' : host;
  }
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

/// Whether [host] only reaches this machine (KLD-083): `localhost`,
/// `*.localhost`, `127.x.x.x`, `::1` (also bracketed or IPv4-mapped). Other
/// devices can't open a link or relay with such a host.
bool isLoopbackHost(String host) {
  var h = host.trim().toLowerCase();
  if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
  if (h.endsWith('.')) h = h.substring(0, h.length - 1);
  if (h == 'localhost' || h.endsWith('.localhost')) return true;
  if (h.startsWith('::ffff:')) h = h.substring(7);
  if (_loopbackV4.hasMatch(h)) return true;
  if (!h.contains(':')) return false;
  try {
    final bytes = Uri.parseIPv6Address(h);
    return bytes.take(15).every((b) => b == 0) && bytes[15] == 1;
  } on FormatException {
    return false;
  }
}

final RegExp _loopbackV4 = RegExp(r'^127\.\d{1,3}\.\d{1,3}\.\d{1,3}$');

/// The loopback host in the room link for [relay] (see [roomJoinLink]), or
/// null when other devices can reach it: the page's host in the browser,
/// else the relay's host (which is also in the link, as host or `&relay=`).
String? loopbackHostOf({required Uri relay, Uri? pageUrl}) {
  final page = pageUrl;
  if (page != null && (page.scheme == 'http' || page.scheme == 'https') && isLoopbackHost(page.host)) {
    return page.host;
  }
  return isLoopbackHost(relay.host) ? relay.host : null;
}

/// Generic LAN address in the localhost hint (a browser can't find out its
/// own LAN IP).
const String loopbackHintExample = 'http://192.168.x.x:8081';

/// Generic `.local` (Bonjour/mDNS) address in the localhost hint.
const String loopbackHintMdnsExample = 'http://my-computer.local:8081';
