# KLD-038a — Simulator e2e: iOS Simulator app hosts, Android emulator app joins, both play Mühle

- **ID:** `KLD-038a`
- **Title:** Automated cross-platform e2e: the real app on the iOS Simulator vs the real app on the Android emulator, PASS/FAIL script
- **Milestone:** P4 — Android ↔ iOS (e2e test plan)
- **Status:** TODO
- **Depends on:** KLD-032 (`NetworkTransport`), KLD-037b (loopback e2e + `klunki/test/e2e/muehle_script.dart`),
  🧑 Android cmdline-tools installed and SDK licenses accepted (the same user step that blocks KLD-011)
- **Touched paths:**
  - `klunki/integration_test/**`
  - `tool/e2e_*` (repo root `tool/`, new)
  - `klunki/pubspec.yaml` (only `integration_test: {sdk: flutter}` under `dev_dependencies`; it ships with the Flutter SDK, no download)
  - a small test-mode hook in the app: decide the exact path when you start (suggestion: `klunki/lib/app/test_mode.dart`
    + one line in `klunki/lib/main.dart`); write the decision into this card and into `docs/tasks/BOARD.md` before coding
  - `docs/tasks/KLD-038a-simulator-e2e.md`

> **Update (KLD-038c):** the hook exists: `klunki/lib/app/test_mode.dart` (`E2eMode`), used by `PairingDeps.platform()`
> (fixed port + seed). The test is `klunki/integration_test/network_test.dart` (it drives the real pairing UI rather than
> bypassing it), and `tool/e2e_android_vs_ios.sh` is written; it stops with `BLOCKED` until the 🧑 steps below are done.
> The iOS-only variant `tool/e2e_ios_sims.sh` passes. See `KLD-038c-mobile-integration-tests.md`.

## Goal
`tool/e2e_android_vs_ios.sh` boots an iPhone simulator and the Android emulator, starts the app on both in a test mode,
the iOS app hosts Mühle on a fixed port, the Android app joins via `10.0.2.2` (the emulator's alias for the Mac's loopback),
both play the Mühle demo script automatically, each prints its final state, and the script compares them and prints **PASS** or **FAIL**.

## Repo context
- Existing AVD: **`Medium_Phone_API_37.0`** (`flutter emulators --launch Medium_Phone_API_37.0`). iOS simulators: iPhone 18 Pro, iPad Pro 11-inch (M5) (see KLD-012a).
- iOS Simulator apps share the Mac's network stack: a server bound on the simulator at `0.0.0.0:<port>` is reachable from the Mac
  at `127.0.0.1:<port>`, and from the Android emulator at `10.0.2.2:<port>`.
- Mühle move script: `klunki/test/e2e/muehle_script.dart` (KLD-037b). Network setup as in that test: `KlunkiHost.start(config, port: <fixed>)`,
  `KlunkiGuest.connect('10.0.2.2', <port>)`, wrapped in `NetworkTransport` (KLD-032), driven through `GameController`.
- KLD-034's pairing screen may not exist yet: the test mode bypasses UI pairing entirely.

## Acceptance criteria
- [ ] Test mode via `--dart-define`: `KLUNKI_E2E_ROLE=host|guest`, `KLUNKI_E2E_PORT=47123` (fixed default), `KLUNKI_E2E_HOST=10.0.2.2`
      (guest only), `KLUNKI_E2E_SEED=<n>`. Without these defines the app behaves exactly as before (hook is a no-op).
- [ ] `klunki/integration_test/e2e_muehle_test.dart` (`IntegrationTestWidgetsFlutterBinding`): in host or guest role, connects, plays
      the script to the end through `GameController`, then prints one line `E2E_RESULT {json}` with winner, draw, reason, move count and
      a hash of the move list.
- [ ] `tool/e2e_android_vs_ios.sh`: checks prerequisites (`xcrun simctl`, `flutter emulators`, `adb`) and exits with a clear message if
      Android tooling is missing; boots the simulator + emulator if not running; runs
      `flutter test integration_test/e2e_muehle_test.dart -d <ios-sim> --dart-define=KLUNKI_E2E_ROLE=host …` in the background, waits
      until the port is open, then runs the guest on `-d emulator-5554`; collects both `E2E_RESULT` lines; prints `PASS` (identical) or
      `FAIL` (diff shown) and exits 0/1. Total timeout 10 min.
- [ ] A second run with swapped roles is either supported (`--swap`: Android host, iOS guest; then the iOS guest needs
      `adb reverse`/`adb forward tcp:<port> tcp:<port>` and connects to `127.0.0.1`) or documented as out of scope in this card.
- [ ] `cd klunki && flutter analyze && flutter test` green; the script prints PASS on the Mac at least once (paste the output into the report).

## 🧑 Steps (the agent must not do these)
1. Install Android SDK command-line tools in Android Studio (Settings → Languages & Frameworks → Android SDK → SDK Tools → "Android SDK Command-line Tools").
2. Run `flutter doctor --android-licenses` and accept personally.
3. Confirm the emulator `Medium_Phone_API_37.0` boots once (Android Studio → Device Manager).
If any of this is missing, the agent stops and reports.

## Constraints
- Board rule: never install SDK components, system images or accept licenses without the user's explicit OK.
- No new pub.dev packages (`integration_test` is part of the Flutter SDK).
- The test-mode hook must not ship any behaviour in normal builds (only active when the defines are set).

## Definition of done
`flutter analyze` + `flutter test` green; `tool/e2e_android_vs_ios.sh` prints PASS; card status DONE; BOARD row ✅.
