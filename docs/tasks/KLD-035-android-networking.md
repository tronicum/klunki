# KLD-035 — Android networking for Android ↔ iOS

- **ID:** `KLD-035`
- **Title:** Android networking: multicast lock + Wi-Fi permissions for discovery, release-build networking check (Android phone ↔ iPhone/iPad)
- **Milestone:** P4 — Android ↔ iOS (end of PoC). There is only **one** Android phone, so there's no Android ↔ Android demo.
- **Status:** TODO
- **Depends on:** KLD-011 (Android toolchain, phone runs the app, `INTERNET` in main manifest), KLD-033 (`bonsoir` discovery); for the
  end-to-end check also KLD-034 (pairing) and KLD-040 (iOS side). 🧑 phone, and optionally release-keystore passwords.
- **Touched paths:**
  - `klunki/android/**`
  - `docs/tasks/KLD-035-android-networking.md` (status only)

## Goal
The Android phone can **host and join** network games with the iPhone/iPad on the same Wi-Fi, in a **release** build:
mDNS advertise and browse work in both directions, and TCP connects in both directions.

## Context (Android audit, 2026-10-25)
- `applicationId`/`namespace` `de.klunki.klunki`; compileSdk/targetSdk 36, minSdk 24; AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1.
- KLD-011 moved `INTERNET` into `src/main/AndroidManifest.xml` (verify; if it's still debug/profile-only, add it to main).
  Release builds use **only** the main manifest, so without it sockets fail in release only.
- The release build is still **signed with the debug keys** (`signingConfig = signingConfigs.getByName("debug")` in `app/build.gradle.kts`).
  That's fine for `flutter run --release` on the user's own phone.
- `gradlew`, the wrapper jar and `local.properties` are gitignored (generated).

## Acceptance criteria
- [ ] `src/main/AndroidManifest.xml` declares: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`.
      **Verify against the `bonsoir` README** (the version pinned in `klunki/pubspec.yaml` by KLD-033) and add whatever else it lists for the
      targetSdk 36 case. Quote the README lines in your report. Don't add location or `NEARBY_WIFI_DEVICES` unless the README requires them for mDNS.
- [ ] Multicast lock: if `bonsoir` acquires a `WifiManager.MulticastLock` itself (check its source/README), document that in your report and add
      nothing. Otherwise acquire it in `MainActivity.kt` (`klunki/android/app/src/main/kotlin/...`) while the app is in the foreground, and release it on pause/destroy.
- [ ] `cd klunki && flutter build apk --release` succeeds.
- [ ] 🧑 Release check on the phone: `flutter run --release -d <android-id>` (or `adb install build/app/outputs/flutter-apk/app-release.apk`), plus
      an iPhone/iPad running the KLD-040 build on the same Wi-Fi:
  - Android hosts → iOS sees it in the list, joins, and one Connect Four game is played to the end;
  - iOS hosts → Android sees it, joins, and plays;
  - manual `IP:port` join works both ways (fallback path).
  Record the results (device models, OS versions, Wi-Fi name type: home/hotspot) in the card's Hints section or your report.
- [ ] `cd klunki && flutter analyze && flutter test` green.

## Optional (only with 🧑 OK): release signing
Not required for the demo. If the user wants a properly signed release:
- 🧑 the user creates the keystore and picks the passwords:
  `keytool -genkey -v -keystore ~/klunki-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias klunki`
- `klunki/android/key.properties` (**gitignored, never committed**) with `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.
- `app/build.gradle.kts`: a `signingConfigs.create("release")` that reads `key.properties` if present, and otherwise falls back to debug signing so
  the build never breaks for others. Add `key.properties` and `*.jks` to `klunki/android/.gitignore`.

## Constraints
- **Board rule:** never install toolchains, download SDK components, accept licenses, sign up for accounts or publish anything without the
  user's explicit OK. No Play Store upload. The first release build may fetch Gradle/Maven artifacts: say so first.
- Only touch `klunki/android/**`. Dart-side issues (discovery or pairing bugs) → report them, don't fix them here. Don't commit unless asked.

## Hints / context
- Debugging discovery: `adb logcat | grep -i -E "nsd|bonsoir|mdns"`; on the Mac, `dns-sd -B _klunki._tcp` lists announcements on the same
  network (the Mac's Wi-Fi must be on that network).
- If the phone sees nothing but the Mac does, check the multicast lock and the permissions. If nobody sees anything, the network likely
  blocks multicast/peer traffic (guest Wi-Fi, client isolation). Use a phone hotspot as fallback.
  Note: on an **Android hotspot** the hotspot phone itself is the gateway, and its own IP is usually `192.168.x.1` (varies by vendor).
- Android 9+ blocks cleartext *HTTP* by default. Raw TCP sockets aren't affected, so no `networkSecurityConfig` is needed for `klunki_net`.

## Definition of done
```bash
cd klunki
flutter analyze && flutter test
flutter build apk --release
flutter run --release -d <android-id>   # 🧑 host + join with iPhone/iPad both ways
```
Acceptance criteria ticked, card status set to DONE.
