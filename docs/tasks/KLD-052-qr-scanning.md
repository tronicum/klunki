# KLD-052 — Join by scanning the host's QR code

- **ID:** `KLD-052`
- **Title:** QR scanning in the join flow (camera plugin + camera permissions on Android and iOS)
- **Milestone:** P3/P4 polish (backlog)
- **Status:** TODO — needs 🧑 OK for the plugin and the permissions first
- **Depends on:** KLD-033 (join payload `encode`/`tryParse`, QR display), KLD-034 (join screen); KLD-011/012 for device testing
- **Touched paths:**
  - `klunki/pubspec.yaml` (one scanner package, e.g. `mobile_scanner`)
  - `klunki/lib/ui/pairing/qr_scan*.dart` (new) + the "Scannen" button in the join flow (`klunki/lib/ui/pairing/**`)
  - `klunki/ios/Runner/Info.plist` (`NSCameraUsageDescription`)
  - `klunki/android/app/src/main/AndroidManifest.xml` (`android.permission.CAMERA`, `uses-feature android.hardware.camera` with `required="false"`)
  - `klunki/test/ui/pairing/qr_scan*`
  - `docs/tasks/KLD-052-qr-scanning.md`

## Goal
On the join screen a "QR scannen" button opens the camera; scanning the host's QR (KLD-033's `klunki://join?...` payload) connects
directly, the same as typing `IP:port`. The host side is unchanged (it already shows the QR).

## 🧑 Steps (before any code)
1. Confirm the package (proposal: `mobile_scanner`, check the current version and its iOS/Android minimums against
   `IPHONEOS_DEPLOYMENT_TARGET = 15.0` and Android `minSdk 24`).
2. Confirm adding camera permissions on both platforms (German usage text, e.g. "Klunki nutzt die Kamera, um den QR-Code eines Mitspielers zu scannen.").
3. On device: allow camera access when asked.

## Acceptance criteria
- [ ] Scanner page parses with KLD-033's `tryParse`; invalid codes show "Kein Klunki-Code" and keep scanning; a valid code pops with the
      parsed host info and the join flow connects.
- [ ] Permission denied → message with a hint to the system settings; manual entry still works.
- [ ] Web build: the button is hidden (no camera flow on the PWA) and `flutter build web` still succeeds.
- [ ] Widget test with the scanner behind a small interface (fake emits a payload) → join flow receives it.
- [ ] `cd klunki && flutter analyze && flutter test` green; scanning verified once on the iPhone and the Android phone (🧑).

## Constraints
- No dependency or permission change before the 🧑 OK. Don't touch signing.

## Definition of done
Green analyze + tests, device check done; card status DONE; BOARD row ✅.
