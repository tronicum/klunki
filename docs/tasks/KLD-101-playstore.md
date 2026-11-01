# KLD-101 — Google Play Store distribution

- **ID:** `KLD-101`
- **Title:** Prepare the Android app for Google Play: build setup, screenshots and a submission guide
- **Milestone:** release
- **Status:** IN_PROGRESS (agent part done; the rest is 🧑: account, keys, uploads, policy decisions)
- **Depends on:** KLD-053 (signing via `key.properties`), KLD-070 (CI), KLD-096 (privacy page), KLD-097 (app icon)
- **Touched paths:**
  - `docs/PLAYSTORE.md` (new), `docs/BUILDING.md`, `docs/tasks/BOARD.md`, `docs/tasks/KLD-101-playstore.md`
  - `.github/workflows/build.yml` (app bundle artifact `klunki-android-aab`)
  - `klunki/test/screenshots/screenshots_test.dart` (group `playstore`, `KLUNKI_PLAYSTORE`)

## Goal

The developer can create the Play Console app and upload a signed `.aab` by following `docs/PLAYSTORE.md`, with
the store texts, screenshots and policy answers ready. No secrets in git, no uploads by agents.

## Done (agent)

- Signing: already in place since KLD-070/KLD-053. `build.gradle.kts` reads `klunki/android/key.properties` (or
  `KLUNKI_KEYSTORE_*` env), falls back to the debug key; `klunki/android/.gitignore` ignores `key.properties`,
  `*.jks`, `*.keystore`. The `keytool` command for the upload key is in PLAYSTORE.md.
- Checked: `applicationId` `de.klunki.klunki` (same as the iOS bundle id), versionCode/versionName from
  `pubspec.yaml`, compileSdk/targetSdk 36, minSdk 24, NDK 28.2 (Flutter 3.47.8 defaults). Permissions listed with
  reasons (INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, CHANGE_WIFI_MULTICAST_STATE, CAMERA; RECORD_AUDIO
  and WRITE_EXTERNAL_STORAGE removed; camera features optional).
- CI: `build.yml` also builds `flutter build appbundle --release` and uploads `klunki-android-aab` (debug-signed
  without the secrets; Play rejects those, so it is a build check).
- Screenshots: group `playstore` renders the App Store scenes at Play sizes (phone 1080 × 1920, 7" tablet
  1200 × 1920, 10" tablet 1600 × 2560; de + en; RGB without alpha).
- `docs/PLAYSTORE.md`: account types, Play App Signing, tracks, de/en listing texts, graphics, data safety,
  content rating, target audience / Families policy, checklist.

## Not verified

- **The local `flutter build appbundle` did not finish on the agent machine:** Gradle started installing missing
  SDK parts (the NDK 28.2 install completed before the build was stopped; the Android SDK Platform 36 is also
  missing, only `android-37.0` is installed). Per the rules the build was stopped there. 🧑 runs it once with the
  SDK parts in place.
- The merged release manifest (final permission list) was derived from the plugin manifests, not from a build.

## 🧑 Steps

1. Choose the account type (organization with D-U-N-S, or personal with the 12 testers / 14 days closed test).
2. Create the upload key (`keytool`, PLAYSTORE.md), back it up, fill in `klunki/android/key.properties`.
3. Install Android SDK Platform 36 (SDK Manager) and build: `flutter build appbundle --release --dart-define=KLUNKI_BUILD=<sha>`.
4. Decide data safety ("No data collected" vs. declaring the player name) and the target audience (13+ vs. under 13
   with the Families policy).
5. Final icon (KLD-097) → 512 px Play icon and Android launcher icons; then the feature graphic (1024 × 500).
6. Follow the checklist in `docs/PLAYSTORE.md`.

## Acceptance criteria

- [x] No secret in git; release builds fall back to the debug key without `key.properties`.
- [x] `docs/PLAYSTORE.md` covers account, signing, tracks, texts (≤ 30 / ≤ 80 / ≤ 4000), graphics, app content, checklist.
- [x] `KLUNKI_PLAYSTORE=<dir> flutter test test/screenshots --plain-name playstore` writes 48 PNGs at the right sizes.
- [ ] 🧑 Signed `.aab` built locally and accepted by an internal testing release.

## Definition of done

The app is live on an internal testing track with the listing complete; card DONE, BOARD row ✅.
