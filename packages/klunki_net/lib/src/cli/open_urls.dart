/// What `klunki relay` prints at startup so other devices find it (KLD-083):
/// the LAN IPv4 addresses and the Bonjour/mDNS `.local` name.
library;

import 'dart:io';

/// One IPv4 address of a network interface ([NetworkInterface] in short,
/// so tests can inject interfaces).
typedef NicAddress = ({String interface, String address});

/// Interface names of virtual networks other devices can't reach: Docker,
/// VM bridges, VPN tunnels, Apple's AirDrop/peer-to-peer links.
final RegExp _virtualInterface = RegExp(
    r'^(docker|br-|veth|virbr|vmnet|vboxnet|vnic|utun|tun|tap|awdl|llw|anpi|ap\d|bridge|lxc|lxd|podman|cni|flannel|cali|vEthernet)',
    caseSensitive: false);

/// The addresses other devices on the LAN can use, in order: no loopback,
/// no link-local `169.254.x.x`, no recognisable virtual interface, no
/// duplicates.
List<NicAddress> lanAddresses(Iterable<NicAddress> all) {
  final seen = <String>{};
  return [
    for (final a in all)
      if (!a.address.startsWith('127.') &&
          !a.address.startsWith('169.254.') &&
          !a.address.contains(':') &&
          !_virtualInterface.hasMatch(a.interface) &&
          seen.add(a.address))
        a,
  ];
}

/// The Bonjour/mDNS name for [hostname]: `my-computer` →
/// `my-computer.local`; a DNS name (`pc.fritz.box`) → its first label
/// (`pc.local`, as Avahi and Windows announce it); `….local` stays; empty or
/// `localhost` → null.
String? mdnsName(String hostname) {
  final h = hostname.trim();
  if (h.toLowerCase().endsWith('.local')) return h;
  final first = h.split('.').first;
  if (first.isEmpty || first.toLowerCase() == 'localhost') return null;
  return '$first.local';
}

/// The machine's mDNS name: on macOS the Bonjour name from
/// `scutil --get LocalHostName` (`Platform.localHostname` there is often
/// the router's DNS name), otherwise from `Platform.localHostname`.
String? systemMdnsName() {
  if (Platform.isMacOS) {
    try {
      final r = Process.runSync('scutil', ['--get', 'LocalHostName']);
      final name = '${r.stdout}'.trim();
      if (r.exitCode == 0 && name.isNotEmpty) return mdnsName(name);
    } on ProcessException {
      // fall through
    }
  }
  return mdnsName(Platform.localHostname);
}

/// The "Open on other devices" block: one line per LAN address, then the
/// mDNS name, with the URL column aligned. [web]: the relay serves the PWA
/// (`http://…/`), otherwise the relay address (`ws://…/relay`). Empty when
/// there is nothing to show.
List<String> openOnOtherDevices({
  required int port,
  required List<NicAddress> lan,
  String? mdns,
  bool web = true,
}) {
  String url(String host) => web ? 'http://$host:$port/' : 'ws://$host:$port/relay';
  final rows = <(String, String)>[
    for (final a in lan) (url(a.address), '(Wi-Fi/LAN, ${a.interface})'),
    if (mdns != null) (url(mdns), '(Bonjour/mDNS name)'),
  ];
  if (rows.isEmpty) return const [];
  final width = rows.map((r) => r.$1.length).reduce((a, b) => a > b ? a : b);
  return [
    web ? 'Open on other devices:' : 'Relay address for other devices:',
    for (final (u, label) in rows) '  ${u.padRight(width)}  $label',
    if (mdns != null)
      '  (.local names work on Apple devices and most recent Windows, Android and Linux with Avahi; '
          'if not, use the IP address.)',
  ];
}

/// The machine's IPv4 addresses with their interface names (none if the
/// list is unavailable).
Future<List<NicAddress>> systemAddresses() async {
  try {
    return [
      for (final nic in await NetworkInterface.list(type: InternetAddressType.IPv4))
        for (final a in nic.addresses) (interface: nic.name, address: a.address),
    ];
  } on SocketException {
    return const [];
  }
}
