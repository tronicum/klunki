# KLD-080 — QR scanner on open-source zxing-cpp (`flutter_zxing`) instead of `mobile_scanner`

- **ID:** `KLD-080`
- **Title:** Replace `mobile_scanner` (ML Kit on Android, Apple Vision on iOS) with `flutter_zxing` (zxing-cpp via FFI)
- **Milestone:** P3/P4 polish (licence hygiene)
- **Status:** DONE (code, tests, iOS + web builds); **Android scanner unverified until CI/device**
- **Depends on:** KLD-052 (scanner screen + `QrScanner` abstraction), KLD-070 (CI Android build)
- **Touched paths:**
  - `klunki/pubspec.yaml`, `klunki/pubspec.lock` (`flutter_zxing: 3.1.0`, `camera: 0.12.1`; `mobile_scanner` removed)
  - `klunki/lib/ui/pairing/qr_scanner_mobile.dart` (backend rewritten), `qr_scan_screen.dart` (doc comment)
  - `klunki/lib/app/third_party_licenses.dart` (new), `klunki/lib/main.dart`,
    `klunki/assets/licenses/zxing-cpp/LICENSE`, `klunki/assets/licenses/libzint/LICENSE` (new)
  - `klunki/android/app/src/main/AndroidManifest.xml` (camera plugin manifest entries trimmed)
  - `klunki/test/app/third_party_licenses_test.dart` (new)
  - `docs/tasks/KLD-052-qr-scanning.md`, `docs/tasks/BOARD.md`

## Decision
Klunki is AGPL-3.0. `mobile_scanner` links Google's proprietary **ML Kit** barcode model into the Android app and
uses Apple's closed **Vision** framework on iOS. The user chose **`flutter_zxing`**: zxing-cpp compiled from source
into the app and called through Dart FFI, on camera frames from the official `camera` plugin. The app now has no
proprietary barcode component on any platform.

Version: **`flutter_zxing` 3.1.0** (published 2026-09-25, bundles zxing-cpp 3.1.1). Transitive versions resolved
by pub that were younger than two weeks were held back in `pubspec.lock` (pub keeps locked versions): `camera`
0.12.1 (not 0.12.2), `camera_android_camerax` 0.7.5+1, `camera_avfoundation` 0.10.3+1, `camera_web` 0.3.5+6,
`image_picker_ios` 0.8.13+12, `file_selector_macos` 0.9.5+1, `posix` 6.5.2. A future `flutter pub upgrade` lifts
them.

## Licences
| Component | Licence | How it reaches the license page |
|---|---|---|
| `flutter_zxing` (Dart + C glue) | MIT | its package `LICENSE` (Flutter adds package licences automatically) |
| zxing-cpp (bundled C++ sources) | **Apache-2.0** | **not** in the published package → `assets/licenses/zxing-cpp/LICENSE`, registered by `registerNativeLicenses()` |
| libzint backend (zxing-cpp's barcode writer, compiled in) | BSD-3-Clause | same: `assets/licenses/libzint/LICENSE` (notice from `zint.h` + zint's licence note) |
| `camera`, `camera_android_camerax`, `camera_avfoundation`, `camera_web`, `camera_platform_interface` | BSD-3-Clause | package LICENSE |
| `image_picker` + platform packages, `file_selector_*`, `cross_file`, `flutter_plugin_android_lifecycle`, `http`, `http_parser`, `mime`, `stream_transform`, `typed_data` | BSD-3-Clause (image_picker files partly Apache-2.0) | package LICENSE |
| `image`, `archive`, `posix` | MIT | package LICENSE |
| Android libraries pulled by Gradle: AndroidX CameraX 1.6.2, AndroidX core/activity/exifinterface, Guava | Apache-2.0 | (as before for AndroidX) |

**Compatibility:** Apache-2.0 is compatible with GPLv3 and therefore AGPLv3 (FSF; one-way: Apache code may be
combined into a GPL/AGPL work). MIT and BSD-3-Clause are GPL-compatible too. Apache-2.0 §4 asks distributors to
give recipients a copy of the licence, which the license page now does.

## Platforms
- **iOS:** `flutter_zxing` ships a `Package.swift` (dynamic library product, iOS 13+), so it links through
  Flutter's **Swift Package Manager** integration like the other plugins. **No CocoaPods, no Podfile, no
  `project.pbxproj` change.** `camera_avfoundation` (iOS 13+) and `image_picker_ios` (iOS 15+) are SwiftPM too;
  the app targets iOS 15. `NSCameraUsageDescription` stays.
- **Android:** the plugin builds zxing-cpp with **CMake via the NDK** (`externalNativeBuild`, CMake ≥ 3.16;
  16 KB page sizes enabled). It does not pin an NDK, so AGP uses its default NDK for this module (the app uses
  `flutter.ndkVersion` 28.2.13676358); AGP downloads a missing NDK/CMake once the SDK licences are accepted. The
  `jni` plugin already builds C with CMake in this app, so the KLD-070 CI Android job (licences accepted, AGP
  auto-download) needs **no extra step**. minSdk 23 (`image_picker_android` 24 = `flutter.minSdkVersion`). Kotlin/
  Java code: none in flutter_zxing; CameraX + Guava from the camera plugin. No Google Play services / ML Kit.
  Manifest: `camera_android_camerax` declares `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE` (≤ API 28) and a
  **required** `android.hardware.camera.any`; the app manifest removes the two permissions (`tools:node="remove"`,
  the scanner opens the camera without audio) and makes the feature optional. `image_picker_android` adds an unused
  `FileProvider` and a disabled metadata `<service>` for the Play photo-picker backport (no GMS code).
- **Web:** unchanged: no scan button. The scanner code is not even in the web bundle (`pairing_entry.dart`'s
  conditional import keeps `pairing_screen.dart` native-only), and `flutter_zxing` is FFI-only anyway (web stub).
  The generated web plugin registrant now registers `camera_web` and `image_picker_for_web`; they are never
  started and fetch nothing.
- **No runtime downloads:** zxing-cpp is compiled in; zint is the bundled copy (`ZXING_USE_BUNDLED_ZINT=ON`), so
  CMake's `FetchContent` path is never taken.

## Implementation
`MobileQrScanner` (same class and file, behind the unchanged `QrScanner` interface) now builds flutter_zxing's
`ReaderWidget` with all its own buttons/overlays off (`Format.qrCode`, crop 80 % of the shorter side, 150 ms between
frames, inverted codes allowed). The scan screen keeps its viewfinder, torch button, cancel, permission-denied and
no-camera states and the "Kein Klunki-Code" hint; tests still inject a fake scanner (no test changes).
- **Status:** `onControllerCreated` → running; its `CameraException` codes `CameraAccessDenied`,
  `CameraAccessDeniedWithoutPrompt`, `CameraAccessRestricted` → permission denied, other errors → unavailable;
  `availableCameras()` empty → unavailable (ReaderWidget itself would just stay black).
- **Torch:** `camera` has no "has torch" query: shown for the back camera, toggled with
  `setFlashMode(torch/off)`, hidden if that fails. After app resume ReaderWidget reopens the camera (torch off).
- **Permission prompt:** the camera plugin asks on first use (iOS `NSCameraUsageDescription`, Android runtime
  `CAMERA`), as before.

## Results
- `flutter analyze`: no issues. `flutter test`: **513 passed, 46 skipped** (scan tests unchanged; +1 licence test).
- `flutter build ios --release --no-codesign`: OK (Runner.app 22.6 MB). `flutter-zxing.framework` is embedded
  and exports `_readBarcode`/`_readBarcodes`; the Runner links no Vision framework. SwiftPM only, no pods, no
  `project.pbxproj`/scheme change.
- `flutter build web --release` + `pwa_finalize.py`: OK; KLD-070's `tool/check_pwa_external_urls.py` passes (only
  the overridden engine defaults). The two licence text files are bundled (and precached) on the web too, but only
  registered on Android/iOS.
- Android: not built locally (no Android SDK on this Mac). Verified only by reasoning; CI (`build.yml`) and a
  phone must confirm.
- `docs/BUILDING.md` (KLD-070, not on main yet) should get one line: the Android build compiles zxing-cpp with
  CMake/NDK (auto-downloaded by AGP); iOS needs nothing new.

## Risks / follow-ups
- **Android unverified** until the CI APK job and a device scan. AGP 9.1 + `android.newDsl=false` accepts the
  plugin's Groovy DSL (`minSdkVersion 23`, `package=` in its manifest, like other plugins here).
- **APK size:** zxing-cpp adds a native `.so` per ABI (roughly 1–2 MB each); ML Kit's bundled model is gone.
- **App Store:** `camera_avfoundation` and `image_picker_ios` reference microphone/photo-library APIs. Apple's
  upload check (ITMS-90683) may ask for `NSMicrophoneUsageDescription` / `NSPhotoLibraryUsageDescription` even
  though the scanner never uses them; add them only if an upload complains.
- Scanning speed/robustness of zxing-cpp vs. ML Kit/Vision on real phones (small or angled codes): check on device.

## 🧑 Device check
Same as KLD-052: Über WLAN spielen → Beitreten → QR-Code scannen → allow the camera → point at a host's QR;
torch on/off; deny the camera once → message + "Code eintippen". On **Android** especially (first zxing build).
