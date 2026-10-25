import 'local_ip_stub.dart' if (dart.library.io) 'local_ip_io.dart' as impl;

/// One network interface with its IPv4 addresses (a `dart:io`-free mirror of
/// `NetworkInterface`, so the ranking is testable and web-safe).
class LocalInterface {
  final String name;
  final List<String> addresses;

  const LocalInterface(this.name, this.addresses);
}

/// This device's candidate LAN IPv4 addresses, best first (for the host's
/// "join me at" line and the QR code). Empty on web or if listing fails.
Future<List<String>> localIPv4Addresses() async {
  try {
    return rankLocalIPv4(await impl.listInterfaces());
  } catch (_) {
    return const [];
  }
}

/// Interfaces that are usually the Wi-Fi: macOS/iOS `en0`, Android `wlan0`.
const List<String> preferredInterfaces = ['en0', 'wlan0'];

/// Filters and orders [interfaces]' IPv4 addresses: drops loopback
/// (127/8), link-local (169.254/16), unspecified and non-IPv4 entries and
/// duplicates; then ranks Wi-Fi interfaces ([preferredInterfaces]) first,
/// other private-range addresses (10/8, 172.16/12, 192.168/16) next, the rest
/// (e.g. a cellular `pdp_ip0`) last. Stable within a rank.
List<String> rankLocalIPv4(Iterable<LocalInterface> interfaces) {
  final ranked = <(int, int, String)>[];
  final seen = <String>{};
  var order = 0;
  for (final iface in interfaces) {
    for (final address in iface.addresses) {
      final octets = parseIPv4(address);
      if (octets == null || !seen.add(address)) continue;
      if (octets[0] == 127 || octets[0] == 0 || (octets[0] == 169 && octets[1] == 254)) continue;
      final rank = preferredInterfaces.contains(iface.name)
          ? 0
          : _isPrivate(octets)
              ? 1
              : 2;
      ranked.add((rank, order++, address));
    }
  }
  ranked.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
  return [for (final r in ranked) r.$3];
}

bool _isPrivate(List<int> o) =>
    o[0] == 10 || (o[0] == 172 && o[1] >= 16 && o[1] <= 31) || (o[0] == 192 && o[1] == 168);

/// The four octets of a dotted-quad IPv4 [address], or null.
List<int>? parseIPv4(String address) {
  final parts = address.split('.');
  if (parts.length != 4) return null;
  final octets = <int>[];
  for (final p in parts) {
    if (p.isEmpty || p.length > 3 || !RegExp(r'^\d+$').hasMatch(p)) return null;
    final v = int.parse(p);
    if (v > 255) return null;
    octets.add(v);
  }
  return octets;
}
