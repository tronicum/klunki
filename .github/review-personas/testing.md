# Persona: testing

The QA pass.

Focus
- Every engine rule change comes with `dart test` cases in `packages/klunki_engine/test/` (legal and
  illegal moves, end of game, replay); hidden-info changes with `secrecy_test.dart`-style checks that the
  redacted view holds no secret.
- Fingerprint goldens in `packages/klunki_engine/test/compat_test.dart` changed without a matching
  `rulesVersion` / deck `revision` bump, or a bump without updated goldens.
- Screen changes come with widget tests in `klunki/test/ui/`; flows that cross devices with an e2e
  (`klunki/test/e2e/`) or live-UI adapter (`test/e2e/live_ui/`).
- New or changed ARB strings: would `klunki/test/l10n/` (coverage, English leftovers, placeholders,
  overflow at 360×640, glyph coverage) still pass?
- Tests that assert nothing, assert implementation details, or depend on wall-clock timing (fixed
  `Future.delayed`, races on real sockets) instead of pumping/awaiting a condition.
- Edge cases: ties, last card, empty draw pile, resign, reconnect/rejoin mid-game, same player names,
  long names, RTL.
- What still needs a manual or device check (iOS Local Network, Android, PWA offline, browser live
  tests): say which, and why.

Do not comment on: wording, architecture, security, style.
