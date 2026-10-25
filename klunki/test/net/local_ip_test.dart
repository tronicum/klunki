import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/local_ip.dart';

void main() {
  test('drops loopback, link-local, unspecified, garbage and duplicates', () {
    final result = rankLocalIPv4(const [
      LocalInterface('lo0', ['127.0.0.1']),
      LocalInterface('en5', ['169.254.12.3', '0.0.0.0', 'fe80::1', 'nope']),
      LocalInterface('en0', ['192.168.1.20', '192.168.1.20']),
    ]);
    expect(result, ['192.168.1.20']);
  });

  test('prefers en0/wlan0, then private ranges, then the rest', () {
    final result = rankLocalIPv4(const [
      LocalInterface('pdp_ip0', ['100.64.3.9']),
      LocalInterface('bridge100', ['172.20.10.1']),
      LocalInterface('utun3', ['10.8.0.2']),
      LocalInterface('wlan0', ['192.168.178.44']),
      LocalInterface('eth1', ['172.32.0.1']), // not 172.16/12
      LocalInterface('en0', ['192.168.1.20']),
    ]);
    expect(result, ['192.168.178.44', '192.168.1.20', '172.20.10.1', '10.8.0.2', '100.64.3.9', '172.32.0.1']);
  });

  test('empty input', () => expect(rankLocalIPv4(const []), isEmpty));

  test('parseIPv4', () {
    expect(parseIPv4('192.168.0.1'), [192, 168, 0, 1]);
    expect(parseIPv4('256.0.0.1'), isNull);
    expect(parseIPv4('1.2.3'), isNull);
    expect(parseIPv4('1.2.3.x'), isNull);
    expect(parseIPv4('1..2.3'), isNull);
  });

  test('localIPv4Addresses on this machine never lists loopback', () async {
    final list = await localIPv4Addresses();
    expect(list.where((a) => a.startsWith('127.')), isEmpty);
  });
}
