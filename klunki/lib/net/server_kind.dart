import 'room_link.dart' show isLoopbackHost;

/// What kind of server (relay) an address names (KLD-113), so the app can
/// say it in plain words instead of asking for it in a separate setting.
enum ServerKind {
  /// A computer at home: a private or link-local IP address, a `.local`
  /// name, a name without a dot (`spielerechner`) or this device itself.
  /// "Server im WLAN (ein Rechner, auf dem „klunki relay“ läuft)".
  lan,

  /// Anything else, typically `wss://spiele.example`: "Server im Internet".
  internet,
}

/// The [ServerKind] of [relay]: the host decides, not the scheme
/// (`wss://192.168.1.5` is still at home, `ws://spiele.example` is not).
ServerKind serverKindOf(Uri relay) => isLocalNetworkHost(relay.host) ? ServerKind.lan : ServerKind.internet;

/// Whether [host] is only reachable at home (see [ServerKind.lan]).
bool isLocalNetworkHost(String host) {
  var h = host.trim().toLowerCase();
  if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
  if (h.endsWith('.')) h = h.substring(0, h.length - 1);
  if (h.isEmpty || isLoopbackHost(h)) return true;
  if (h.endsWith('.local') || h.endsWith('.lan') || h.endsWith('.home.arpa') || h.endsWith('.fritz.box')) {
    return true;
  }
  if (h.startsWith('::ffff:')) h = h.substring(7);
  final v4 = _ipv4.firstMatch(h);
  if (v4 != null) {
    final a = int.parse(v4.group(1)!), b = int.parse(v4.group(2)!);
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 169 && b == 254) ||
        (a == 100 && b >= 64 && b <= 127); // carrier-grade NAT / VPN at home
  }
  if (h.contains(':')) {
    try {
      final bytes = Uri.parseIPv6Address(h);
      // fc00::/7 (unique local) and fe80::/10 (link-local).
      return (bytes[0] & 0xfe) == 0xfc || (bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80);
    } on FormatException {
      return false;
    }
  }
  // A plain name without a dot is a computer on the home network.
  return !h.contains('.');
}

final RegExp _ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.\d{1,3}\.\d{1,3}$');
