/// End-to-end test mode (KLD-038a/c): compile-time switches set with
/// `--dart-define` by `tool/e2e_*.sh` and `integration_test/network_test.dart`.
///
/// Without the defines [E2eMode.enabled] is false and nothing changes. With
/// `KLUNKI_E2E_ROLE=host|guest` the pairing screen hosts on the fixed
/// [E2eMode.port] (instead of 4747) and deals with the fixed [E2eMode.seed]
/// (instead of a random one), so two simulators can find each other at a
/// known address and replay the same game.
///
///   --dart-define=KLUNKI_E2E_ROLE=host|guest
///   --dart-define=KLUNKI_E2E_PORT=47123      (default 47123)
///   --dart-define=KLUNKI_E2E_HOST=127.0.0.1  (guest only; Android emulator: 10.0.2.2)
///   --dart-define=KLUNKI_E2E_SEED=1          (default 1)
library;

abstract final class E2eMode {
  /// `host`, `guest`, or empty (test mode off).
  static const String role = String.fromEnvironment('KLUNKI_E2E_ROLE');

  /// Fixed TCP port the host listens on and the guest connects to.
  static const int port = int.fromEnvironment('KLUNKI_E2E_PORT', defaultValue: 47123);

  /// Address the guest connects to.
  static const String host = String.fromEnvironment('KLUNKI_E2E_HOST', defaultValue: '127.0.0.1');

  /// Seed of the hosted game.
  static const int seed = int.fromEnvironment('KLUNKI_E2E_SEED', defaultValue: 1);

  /// Test mode is on (a valid role was defined).
  static const bool enabled = role == 'host' || role == 'guest';
}
