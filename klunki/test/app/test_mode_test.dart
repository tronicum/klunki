import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/test_mode.dart';
import 'package:klunki/net/join_payload.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';

// The e2e test-mode hook (KLD-038c) is off without --dart-define, so the
// pairing screen keeps its normal port and random seeds.
void main() {
  test('test mode is off by default', () {
    expect(E2eMode.role, isEmpty);
    expect(E2eMode.enabled, isFalse);
  });

  test('the platform pairing deps use the default port and random seeds', () {
    final deps = PairingDeps.platform();
    expect(deps.preferredPort, klunkiDefaultPort);
    final seeds = {for (var i = 0; i < 8; i++) deps.seed()};
    expect(seeds.length, greaterThan(1));
  });
}
