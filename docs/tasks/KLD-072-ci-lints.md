# KLD-072: Minimal CI, stricter lints, loopback tests without flakes

- **ID:** `KLD-072`
- **Title:** Minimal CI, stricter lints, loopback tests without flakes
- **Priority:** high
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** –
- **Touched paths:** `.github/workflows/ci.yml`, `packages/*/analysis_options.yaml`, `klunki/analysis_options.yaml`, `klunki/test/ui/pairing/pairing_test_utils.dart`, `klunki/tool/update_web_fonts.py` (`--check`)

## Goal
Every push runs what the review ran by hand (REVIEW T1, T4, C8).

## Acceptance criteria
- [ ] CI runs `dart test` and `dart analyze` in both packages, `flutter analyze`, `flutter test`, `flutter build web --release` with `pwa_finalize.py`, a check that the font subset is current, and a check for unused ARB keys.
- [ ] Stricter lints: strict-casts, strict-inference, strict-raw-types, `unawaited_futures`, `cancel_subscriptions`, `close_sinks`, `avoid_dynamic_calls` and `only_throw_errors`. The findings are fixed (about 190 on a trial run).
- [ ] The loopback widget tests use a large `netTimeout` (or an injected clock), so real-time timeouts can't fire during fake-async stretches.
- [ ] 🧑 OK needed for the GitHub Actions minutes and the runner choice.

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.
