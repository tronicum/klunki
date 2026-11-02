# KLD-116: Proper version numbers and release process

- **ID:** `KLD-116`
- **Title:** Proper version numbers and release process
- **Milestone:** release (first external TestFlight)
- **Status:** DONE
- **Depends on:** KLD-085 (version line, build label in the handshake), KLD-070 (CI builds), KLD-102 (About screen)
- **Touched paths:**
  - `klunki/lib/app/build_info.dart`, `klunki/lib/ui/menu_screen.dart`, `klunki/lib/ui/about_screen.dart`
  - `klunki/lib/ui/pairing/relay_errors.dart`, `klunki/lib/ui/pairing/refused_guest_notice.dart`
  - `klunki/lib/l10n/**` (`aboutBuildDetails`, `versionMismatchVersions`, `versionMismatchVersionsDevices`)
  - `packages/klunki_net/lib/src/{compat,events,host,guest}.dart`, `packages/klunki_net/lib/{klunki_net,guest_web}.dart`,
    `packages/klunki_net/PROTOCOL.md`
  - `tool/build_number.sh`, `tool/build_number_test.sh`, `.github/workflows/{build,ci}.yml`
  - `CHANGELOG.md`, `docs/RELEASING.md`, `AGENTS.md`, `docs/BUILDING.md`, `docs/APPSTORE.md`, `docs/PLAYSTORE.md`
  - tests: `klunki/test/app/build_info_test.dart`, `klunki/test/ui/about_screen_test.dart`,
    `klunki/test/ui/pairing/version_mismatch_test.dart`, `klunki/test/screenshots/version_shots_test.dart`,
    `packages/klunki_net/test/compat_test.dart`

## Goal

One clear version scheme for the stores and for people: `MAJOR.MINOR.PATCH` from `pubspec.yaml`, an always
increasing build number `YYYYMMDDNN` set by CI, "Version 1.0.0 (b8752a9)" in the app, a changelog and
written release steps. When two devices refuse each other, the message says who has which version.

## Scheme (agreed with the maintainer)

- **Version** `MAJOR.MINOR.PATCH`, single source `klunki/pubspec.yaml` (`version: 1.0.0+1`; `appVersion`
  mirrors it, a test keeps them equal). MINOR = new games/features, PATCH = fixes. First external TestFlight
  stays **1.0.0**; the next feature release is 1.1.0.
- **Build number** `YYYYMMDDNN`: commit date in UTC + `NN` = number of commits of that UTC day on the
  first-parent line up to the commit (`tool/build_number.sh`). Deterministic per commit, increasing along
  `main`, refuses >99 per day and shallow clones. iOS `CFBundleVersion`, Android `versionCode` (max
  2 100 000 000; the scheme's largest is 2 099 123 199). CI passes `--build-number` and
  `--dart-define=KLUNKI_BUILD_NUMBER` in every `build.yml` job (checkout with `fetch-depth: 0`). Local
  builds keep `+1`.
- **Display:** menu footer and About: `Version 1.0.0 (b8752a9)` (commit from `KLUNKI_BUILD`, `(dev)`
  without). About small print: `Build-Nummer 2026110201 · Protokoll 3 · Spieldaten 2699da15` (the KLD-085
  comparison data moved here from the menu footer).
- **Compatibility** stays on protocol and fingerprints. The handshake's existing `build` label is now
  `1.0.0+2026110201 b8752a9` (same shape as before, so older builds still compare it); `versionDisplay`
  turns it into `1.0.0 (b8752a9)`. The refusing `error` carries an optional informational `name` (no
  protocol bump: old builds ignore it). `VersionMismatch` carries `myBuild`, `myName`, `peerName`.
  The app adds a second line: "Anna hat 1.0.0 (b8752a9), Ben hat 1.1.0 (c3d4e5f)." (or "Dieses Gerät hat …,
  das andere Gerät hat …." without the other name; nothing when the other side sent no build label).
- **Releases:** annotated tag `vX.Y.Z` on `main` (maintainer only), `CHANGELOG.md` in English with a short
  German "Kurz:" line per release, steps in `docs/RELEASING.md`; tags could later drive GitHub Releases,
  relay packages, a container image and the website (pointers only).

## Acceptance criteria
- [x] `tool/build_number.sh` + `tool/build_number_test.sh` (UTC, per-day counter, merges, monotony, limits,
      shallow clone); CI job `tools` runs the test.
- [x] `build.yml` passes the build number to every build (web, APK, AAB, iOS check, Pages).
- [x] Version line `1.0.0 (b8752a9)` / `1.0.0 (dev)` in menu and About; build number etc. in About small
      print; tests with and without a commit (`buildLabel` / `versionDisplay`).
- [x] Mismatch message names both versions (and names); tests for join (names known / unknown / no label)
      and for the host's notice of a refused guest.
- [x] Handshake round trip of `name` and build labels in `klunki_net` tests over TCP, WebSocket and relay.
- [x] `PROTOCOL.md`, `CHANGELOG.md`, `docs/RELEASING.md`, `AGENTS.md`, `BUILDING.md`, `APPSTORE.md`,
      `PLAYSTORE.md` updated.
- [x] Screenshots: `KLUNKI_SHOTS=… flutter test test/screenshots/version_shots_test.dart
      --dart-define=KLUNKI_BUILD=b8752a9 --dart-define=KLUNKI_BUILD_NUMBER=2026110201` (de, ar).

## Notes
- No Xcode project change: `Info.plist` already uses `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)`.
- Do not build Android with `--split-per-abi` (Flutter adds `1000 × ABI` to the versionCode).
- Builds of non-main branches can repeat a number of main: only main/tag builds go to a store.
