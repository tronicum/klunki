import 'dart:io';

import 'local_ip.dart';

/// Native: the IPv4 interfaces from `NetworkInterface.list()`.
Future<List<LocalInterface>> listInterfaces() async {
  final list = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLinkLocal: false);
  return [
    for (final i in list) LocalInterface(i.name, [for (final a in i.addresses) a.address]),
  ];
}
