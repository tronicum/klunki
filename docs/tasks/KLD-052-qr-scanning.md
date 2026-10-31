# KLD-052 — Join by scanning the host's QR code (+ clearer join screens)

- **ID:** `KLD-052`
- **Title:** QR scanning in the join flow (camera plugin + camera permissions on Android and iOS); join screens regrouped
- **Milestone:** P3/P4 polish
- **Status:** DONE (code, tests, iOS + web builds); scanning on the real iPhone/Android phone is a 🧑 check
- **Depends on:** KLD-033 (join payload, QR display), KLD-034 (join tab), KLD-055 (web join), KLD-057b (relay rooms)
- **Touched paths:**
  - `klunki/pubspec.yaml`, `klunki/pubspec.lock` (`mobile_scanner: 7.4.2`)
  - `klunki/lib/net/scanned_join_code.dart` (new, pure parser)
  - `klunki/lib/profile/relay_settings.dart` (new, the one relay setting)
  - `klunki/lib/ui/pairing/qr_scan_screen.dart`, `qr_scanner_mobile.dart`, `relay_line.dart` (new);
    `pairing_screen.dart`, `room_join.dart`, `relay_host_screen.dart`, `web_join_screen.dart`
  - `klunki/lib/l10n/*` (17 new strings in 7 ARB files + generated code), `klunki/assets/fonts/NotoSansSC/*` (re-subset)
  - `klunki/ios/Runner/Info.plist` (`NSCameraUsageDescription`), `klunki/android/app/src/main/AndroidManifest.xml`
    (`CAMERA`, `uses-feature camera required=false`)
  - `klunki/test/net/scanned_join_code_test.dart`, `klunki/test/ui/pairing/qr_scan_test.dart`, `relay_test.dart`
  - `docs/DEMO.md`, `docs/tasks/BOARD.md`

## Package choice
`mobile_scanner` **7.4.2** (published 2026-09-14; 7.4.3 from 2026-10-31 is too fresh). Since 7.0 its iOS/macOS side
is one Swift implementation on **Apple Vision + AVFoundation** with no pod dependencies (no Google MLKit pods), and
it ships a `Package.swift`, so it links through Flutter's SwiftPM integration like `bonsoir` (no Podfile, no
`project.pbxproj` change). Android uses CameraX + ML Kit barcode scanning (bundled model). Minimums: iOS 12,
Android API 23 (the app has iOS 15 / `flutter.minSdkVersion`).

**Web:** the package's web decoders (`zxing-wasm`, `@zxing/library`) load from jsDelivr/unpkg unless the
browser has `BarcodeDetector`, which breaks the offline PWA and the CSP. So the web build has **no scan button**
(the PWA user can scan with the phone's camera app; the room link opens the PWA). The plugin is never started on
the web, so nothing is fetched: `build/web` contains no jsDelivr/unpkg URL, and `tool/pwa_i18n_check.sh` passes in
`offline` mode.

## What the scanner understands (`parseScannedJoinCode`)
| QR content | result |
|---|---|
| `klunki://join?h=…&p=…&v=…&n=…&g=…&w=…` (native host) | direct TCP join `h:p` |
| `http(s)://host:port/?room=CODE&relay=…` (browser host) | room `CODE` on `relay` |
| `http(s)://host:port/?room=CODE` (no `relay`) | room on the link's own server (`relayUriForPage`; https → wss) |
| `http(s)://pwa/?join=<klunki:// link>` | direct join |
| anything else (plain text, `IP:port`, other URLs, bad code/host/port) | "Kein Klunki-Code", keeps scanning |

A scan joins right away through the same code paths as typing (names, progress, errors); a room link also becomes
the shared relay setting.

## Scanner screen
Full screen, camera preview (`BoxFit.cover`) with a viewfinder, hint text, cancel (X), torch toggle when the camera
reports a torch. Permission denied → "Klunki darf die Kamera nicht benutzen." + how to allow it in the system
settings + "Code eintippen" (back to the fields). No camera → "Die Kamera ist nicht verfügbar." + "Code eintippen".
"Einstellungen öffnen" as a button would need another package (`app_settings`/`url_launcher`), so it is a text hint.
The camera sits behind a small `QrScanner` interface; tests inject a fake (codes stream + state).

## Join screens regrouped (user feedback)
The relay address used to be in two places (an "Erweitert: Relay-Adresse" expander on "Spiel hosten" and another
one/field on the room-code join), next to an unrelated "Verbinden" for direct joins. Now:
1. **Über Relay spielen (Raumcode)**: the group heading plus **one** relay line "Relay: 192.168.1.5:8000 · ändern"
   for both "Spiel hosten" (PWA) and "Mit Raumcode beitreten". "ändern" opens a small dialog (address,
   "Übernehmen", on the PWA "Standard: <page>"). One shared `RelaySettings` (shared_preferences `relayAddress`): in the
   PWA the page origin until another relay is chosen; natively the last used one, "Kein Relay eingerichtet – Adresse
   eingeben" at first (joining then asks for it). The host setup shows the same line. No expanders anywhere.
   Unreachable relay → the existing "Kein Relay erreichbar unter …" + start hint.
2. **QR-Code scannen** (app only).
3. **Direkt mit einem Gerät verbinden** (secondary): helper "Für ein Handy, Tablet oder Terminal, das selbst hostet:
   Geräte-Adresse (IP) eingeben.", then (app) discovered games + address field, (PWA) the address field.

The app's join tab has no relay *hosting* (the app hosts directly in its "Hosten" tab). A `?room=…&relay=…` link
and a scanned room link set the shared relay. `tool/pwa_relay_e2e.sh` needed no label changes (PASS, ports
8765/8766). Strings no longer shown: `relayAddressAdvanced`, `webJoinDirectTitle`, `webJoinIntro` (left in the ARB
files to avoid conflicts with parallel ARB edits; can be removed later).

## 🧑 Device check
1. Install from this branch (iOS: no pod step; Xcode resolves the SwiftPM package).
2. Host on a second device (app "Hosten", or the PWA "Spiel hosten" from a `klunki relay --web` Mac).
3. iPhone: Über WLAN spielen → Beitreten → QR-Code scannen → allow the camera → point at the host's QR → the game starts.
4. Deny the camera once (Settings → Klunki → Kamera off) and check the message + "Code eintippen".

## Definition of done
- [x] Parser + widget tests (fake scanner, permission denied, not-a-Klunki code, room link → relay remembered)
- [x] `flutter analyze`, full `flutter test` green; `flutter build ios --release --no-codesign`, `flutter build web --release`
- [x] Web: no scan button, no CDN URLs, offline i18n check PASS; relay e2e PASS
- [ ] Scanning verified on the iPhone and an Android phone (🧑). Android build not run here (no cmdline-tools).
