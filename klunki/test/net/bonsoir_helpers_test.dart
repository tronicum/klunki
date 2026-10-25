import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/bonsoir_discovery.dart';

// Only the pure helpers: real mDNS needs platform channels, which
// `flutter test` does not have.
void main() {
  group('uniqueServiceName', () {
    test('adds a 4-hex-digit suffix', () {
      expect(uniqueServiceName('Stefans iPhone', Random(1)), matches(RegExp(r'^Stefans iPhone #[0-9a-f]{4}$')));
    });

    test('two calls differ', () {
      final r = Random(42);
      expect(uniqueServiceName('iPad', r), isNot(uniqueServiceName('iPad', r)));
    });

    test('fits 63 bytes for long multi-byte names', () {
      final name = uniqueServiceName('Ü' * 80, Random(3));
      expect(utf8.encode(name).length, lessThanOrEqualTo(maxServiceNameBytes));
      expect(name, startsWith('ÜÜÜ'));
    });

    test('empty or control-only names get a default', () {
      expect(uniqueServiceName(' \u0001 ', Random(0)), startsWith('Klunki #'));
    });
  });

  test('pickHostAddress prefers IPv4', () {
    expect(pickHostAddress(['fe80::1%en0', '192.168.1.20']), '192.168.1.20');
    expect(pickHostAddress(['fe80::1']), 'fe80::1');
    expect(pickHostAddress([]), isNull);
  });
}
