# KLD-038c — Mobile integration tests: the real app on iOS simulators (Android-ready)

- **ID:** `KLD-038c`
- **Title:** `integration_test` suite that runs the real app on iOS simulators (and later Android): all games, language picker, plugins, and two simulators playing each other
- **Milestone:** P3 — iPhone ↔ iPad (e2e test plan); prepares P4 (KLD-038a)
- **Status:** DONE (iOS); the Android run is waiting for 🧑 cmdline-tools + licenses
- **Depends on:** KLD-021…026 (screens), KLD-034 (pairing), KLD-037b (`klunki/test/e2e/muehle_script.dart`), I18N-01…04 (language picker)
- **Touched paths:**
  - `klunki/integration_test/**` (new: `app_test.dart`, `network_test.dart`, `support.dart`)
  - `klunki/lib/app/test_mode.dart` (new, the test-mode hook) + 3 lines in `klunki/lib/ui/pairing/pairing_screen.dart` (`PairingDeps.platform()`)
  - `klunki/test/app/test_mode_test.dart` (the hook is off by default)
  - `klunki/pubspec.yaml` / `pubspec.lock` (`integration_test: {sdk: flutter}` under `dev_dependencies` only; no download, all packages were in the pub cache)
  - `tool/e2e_ios_sims.sh`, `tool/e2e_android_vs_ios.sh` (repo root, new)
  - `docs/DEMO.md` (section 3, "Automated tests on simulators")

## Goal
"Also write tests for the mobile versions": the real app, built for iOS/Android, driven on a simulator/emulator.
One suite checks a single device; a second one lets two simulators play Mühle against each other over TCP.

## Test-mode hook (the KLD-038a design)
`klunki/lib/app/test_mode.dart`, `E2eMode`, compile-time constants only:

| `--dart-define` | Default | Effect |
|---|---|---|
| `KLUNKI_E2E_ROLE=host\|guest` | empty = off | turns the test mode on; the integration test reads the role |
| `KLUNKI_E2E_PORT` | `47123` | the pairing screen hosts on this port (instead of 4747) |
| `KLUNKI_E2E_HOST` | `127.0.0.1` | address the guest test types into the manual-join field (Android emulator: `10.0.2.2`) |
| `KLUNKI_E2E_SEED` | `1` | seed of the hosted game (instead of a random one) |

Only `PairingDeps.platform()` reads it (port + seed). Without the defines nothing changes (`test/app/test_mode_test.dart`).
Test-only defines (read in `integration_test/` only): `KLUNKI_E2E_JOIN=manual|mdns`, `KLUNKI_SCREENSHOT_DIR`, `KLUNKI_SCREENSHOT_PREFIX`.

## What the tests cover
**`integration_test/app_test.dart`** (one device, 8 tests):
1. App start through the real `main()`: the menu lists all 5 games (`menu-<id>`), Wi-Fi play and the language button.
2. Hot-seat to the result dialog, opened from the menu:
   - 4 Gewinnt by real taps on the columns (X wins in 7).
   - Mühle: the scripted 33-move demo game by real taps on the points (O wins).
   - Quartett (Trumpf), Quartett (Sets), Schiffe versenken: moves through the `GameController`, tapping the handover cover each time
     (Schiffe: both fleets via the **Zufällig** button first). The headline in the result dialog matches the engine result; **Menü** goes back.
3. Language picker: English → restart → still English; Arabic → RTL → restart → still Arabic; System → the saved key is removed → restart.
   "Restart" = unmount the app and start it again with `LocaleController.load()` on the device's real shared_preferences.
4. Platform channels: shared_preferences round trip; `localIPv4Addresses()` is not empty; the pairing host screen lists the address
   (`<ip>:<port>`), shows the QR and does **not** report an mDNS advertising failure (bonsoir works natively).

**`integration_test/network_test.dart`** (one run = one device; skipped without a role):
- host: menu → Über WLAN spielen → name "Klunki E2E Host" → Mühle → Hosten (port 47123, seed 1) → waits for the guest → taps X's half.
- guest: menu → Über WLAN spielen → Beitreten → logs whether the host shows in the mDNS list → joins by the manual address
  (or by tapping the list entry with `KLUNKI_E2E_JOIN=mdns`), retrying while the host is still starting → taps O's half.
- Both assert seed, roles, every move against the script, winner O and the reason, and the result dialog, then print
  `KLUNKI_IT E2E_RESULT {game, seed, moves, movesHash (FNV-1a of the move list), board, winner, draw, reason}`.
  The guest leaves first; the host waits for it.

**`tool/e2e_ios_sims.sh`** boots both simulators (headless), starts the host test, waits until the Mac sees the port on
127.0.0.1 (simulators share the Mac's network), then starts the guest test, compares the two `E2E_RESULT` lines and prints
**PASS/FAIL** (logs and screenshots in `klunki/build/e2e/`). The guest is started after the host's build on purpose:
two `xcodebuild`s in one build directory collide, and the second build is incremental anyway (only the dart-defines differ).

## Results (2026-10-31, Mac, Xcode, Flutter 3.47.8)
| Run | Result | Time |
|---|---|---|
| `app_test` on iPhone 18 Pro | 8/8 pass | 70 s incl. incremental build (tests 43 s) |
| `app_test` on iPad Pro 11-inch (M5) | 8/8 pass | 70 s incl. incremental build (tests 46 s) |
| `e2e_ios_sims.sh` (manual 127.0.0.1) | PASS, identical results (`movesHash f0dc1023`) | 42 s total (host up after 18–19 s; game ≈ 4 s); first cold run: host up after 48 s |
| `e2e_ios_sims.sh --mdns` | PASS (iPad joined via the list entry) | 42 s |

mDNS between two simulators on one Mac: the host shows up in the guest's list immediately (both use the Mac's mDNSResponder),
resolved to `127.0.0.1:47123`. Stable in all 3 runs, but it's still optional (`--mdns`); the default joins by address,
and the guest always logs `E2E_MDNS seen=…`.

## Findings
- No app bug found. Two test-harness issues were fixed while writing it:
  - `pumpAndSettle` never returns on screens with a spinner (pairing "waiting for guest", join "searching").
    The helpers only settle after a tap, and screenshots don't settle.
  - Network play: polling can miss intermediate states (the peer answers within one poll interval), and a move that just arrived
    may not be rendered yet. The test waits for `moves.length > i` and for the board's `IgnorePointer` to be off before tapping.

## Screenshots
`integration_test` plugin (`binding.takeScreenshot`); written to `KLUNKI_SCREENSHOT_DIR` (on an iOS simulator a Mac path works),
otherwise to the app's temp dir (path printed as `KLUNKI_IT SCREENSHOT …`). Never fails a test.
- `klunki/build/e2e_screenshots/{iphone,ipad}/<prefix>_{menu,connect4_result,muehle_midgame,muehle_result,quartett-trumpf_result,quartett-sets_result,handover_cover,schiffe_battle,schiffe_result,menu_arabic,pairing_host}.png`
- `klunki/build/e2e/screenshots/{host_net_host_waiting,host_net_host_midgame,host_net_host_result,guest_net_guest_join,guest_net_guest_midgame,guest_net_guest_result}.png`

## Android (prepared, not run)
- The tests are platform-neutral (`convertFlutterSurfaceToImage()` before screenshots on Android; the guest uses `KLUNKI_E2E_HOST=10.0.2.2`).
- `tool/e2e_android_vs_ios.sh`: iOS simulator hosts, AVD `Medium_Phone_API_37.0` (`emulator-5554`) joins `10.0.2.2:47123`. It checks
  adb, cmdline-tools (`sdkmanager`), the SDK licenses and the AVD, and stops with `BLOCKED: …` (exit 3) when one is missing.
- 🧑 Needed first: Android SDK Command-line Tools (Android Studio → SDK Tools), `flutter doctor --android-licenses`, one manual boot of the AVD.
- Then: `flutter test integration_test/app_test.dart -d emulator-5554` for the single-device suite. Screenshots stay in the app's temp dir on the
  emulator (pull them with `adb shell run-as de.klunki.klunki …` if needed). `--mdns` from the emulator needs KLD-035 (multicast lock)
  and probably doesn't work through the emulator's NAT. Use the manual address.
- Swapped roles (Android host, iOS guest) need `adb forward tcp:47123 tcp:47123`; not wired up yet.

## How to run
```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd klunki
flutter test integration_test/app_test.dart -d <sim-id>      # + --dart-define=KLUNKI_SCREENSHOT_DIR=$PWD/build/e2e_screenshots/iphone
../tool/e2e_ios_sims.sh [--mdns] [--host-sim <udid>] [--guest-sim <udid>]
```
`flutter test` (unit/widget) only runs `test/`, so `integration_test/` never runs there; `flutter analyze` covers it.

## Definition of done
- [x] `flutter analyze` clean, `flutter test` green (285 tests).
- [x] `app_test` passes on iPhone 18 Pro and iPad Pro 11-inch (M5) simulators.
- [x] `tool/e2e_ios_sims.sh` prints PASS (manual and `--mdns`).
- [ ] Android: run after the 🧑 steps (`tool/e2e_android_vs_ios.sh`, KLD-038a).
