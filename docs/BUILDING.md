# Building Klunki yourself

This guide covers building, testing and installing Klunki from source on Android, iOS and the web (PWA), plus what
CI does. For running the demos see [`DEMO.md`](DEMO.md). For the network protocol see
[`packages/klunki_net/PROTOCOL.md`](../packages/klunki_net/PROTOCOL.md).

Commands are run from the **repo root** unless a block starts with `cd`.

## Contents
1. [Prerequisites](#1-prerequisites)
2. [Repo layout: where to run what](#2-repo-layout-where-to-run-what)
3. [Tests](#3-tests)
4. [Android](#4-android)
5. [iOS / Xcode](#5-ios--xcode)
6. [PWA (web)](#6-pwa-web)
7. [CI (GitHub Actions)](#7-ci-github-actions)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

| Tool | Version | Needed for |
|---|---|---|
| **Flutter** | **3.47.8** (stable), which ships **Dart 3.13.7** | everything. `klunki/pubspec.yaml` requires Dart `^3.13.7`, and CI pins exactly 3.47.8 |
| Xcode | 27.x (the project is developed with 27.1), plus the iOS platform from Xcode › Settings › Components | iOS builds (macOS only) |
| Android Studio or the Android **cmdline-tools** | current; SDK platform 36, build-tools, NDK 28.2 (Gradle downloads missing SDK parts itself once the licences are accepted) | Android builds |
| Java (JDK) | **17 or newer** (Android Studio's bundled JBR works) | Android builds (AGP 9.1, Gradle 9.3.1, Kotlin 2.4) |
| Python 3 | any 3.x, stdlib only | PWA finalize script, PWA external-URL check, font subset tool |
| Chrome or Firefox | current | running the PWA |

Check your setup with:
```bash
flutter --version     # Flutter 3.47.8 • channel stable … Dart 3.13.7
flutter doctor -v
```
A different Flutter version may work, but it's the first thing to rule out when something breaks. With
[fvm](https://fvm.app): `fvm install 3.47.8 && fvm use 3.47.8`.

Node.js is **not** needed to build. Only the optional browser end-to-end scripts in `klunki/tool/*.sh` use it.

## 2. Repo layout: where to run what

There is **no `pubspec.yaml` in the repo root**. Each of the three Dart projects has its own:

| Directory | What | Commands |
|---|---|---|
| `packages/klunki_engine/` | pure-Dart game logic (no Flutter) | `dart pub get`, `dart analyze`, `dart test`, `dart run bin/klunki.dart` (text debug console) |
| `packages/klunki_net/` | pure-Dart networking: TCP/WebSocket host and guest, relay, CLI | `dart pub get`, `dart analyze`, `dart test` |
| `klunki/` | the Flutter app (iOS, Android, web) | `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`, `flutter build …` |

The network CLI can be run from the root, because `dart run` with a file path finds the package itself:
```bash
dart run packages/klunki_net/bin/klunki.dart host connect4            # LAN host (TCP 4747, WebSocket 4748)
dart run packages/klunki_net/bin/klunki.dart join 192.168.1.20         # LAN guest
dart run packages/klunki_net/bin/klunki.dart relay --port 8081 --web klunki/build/web   # relay + PWA server
```
`flutter …` commands, on the other hand, must run inside `klunki/` (see [Troubleshooting](#8-troubleshooting):
"Found no pubspec.yaml").

## 3. Tests

```bash
(cd packages/klunki_engine && dart pub get && dart analyze && dart test)
(cd packages/klunki_net    && dart pub get && dart analyze && dart test)
(cd klunki                 && flutter pub get && flutter analyze && flutter test)
```
- `klunki_net`'s `test/web_compile_test.dart` compiles a small browser guest with `dart compile js` (dart2js, part of
  the Dart SDK). It needs no browser.
- The network tests use real sockets on `127.0.0.1` with free ports. A firewall prompt for `dart` /
  `flutter_tester` on macOS can be allowed or denied; loopback works either way.
- `klunki/test/e2e` plays whole games between two app stacks over loopback TCP. `KLUNKI_E2E_VERBOSE=1` prints a
  transcript.
- The screenshot harness (`klunki/test/screenshots`) is skipped unless `KLUNKI_SHOTS` is set.
- On-device tests: `cd klunki && flutter test integration_test -d <device>`.

## 4. Android

> Status: CI builds a release APK on every push to main (`build.yml`). The first Android build of this repo
> happens on GitHub, so treat the Android setup as **unverified until that first run is green**.

Project facts: `applicationId` / namespace `de.klunki.klunki`; `minSdk` 24 (Flutter's default);
`compileSdk`/`targetSdk` 36; AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1 (the wrapper jar and
`gradlew` are not committed: `flutter build` adds them from the Flutter SDK).
Permissions in `klunki/android/app/src/main/AndroidManifest.xml`: `INTERNET`, `ACCESS_NETWORK_STATE`,
`ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE` (mDNS discovery), `CAMERA` (QR scanning, optional).
No cleartext/network-security config is needed: the app talks over `dart:io` sockets and WebSockets, which
Android's cleartext-HTTP policy does not cover. (`ws://` to a LAN host or relay therefore works.)
The QR scanner (`flutter_zxing`, KLD-080) compiles zxing-cpp natively via CMake and the NDK; AGP downloads
CMake/NDK on the first Android build if they are missing (licences accepted).

### 4.1 SDK, cmdline-tools and licences
1. Install Android Studio (or just the cmdline-tools) and in **SDK Manager** install: Android SDK Platform 36,
   Android SDK Build-Tools, **Android SDK Command-line Tools (latest)**, Android SDK Platform-Tools.
2. Tell Flutter where things are, if `flutter doctor` doesn't find them:
   ```bash
   flutter config --android-sdk ~/Library/Android/sdk     # macOS default location
   flutter config --jdk-dir "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
   ```
3. Accept the licences (interactive, answer `y`):
   ```bash
   flutter doctor --android-licenses
   flutter doctor -v    # "Android toolchain" should be ✓
   ```

### 4.2 Emulator or phone
- **Emulator:** Android Studio › Device Manager › Create device (e.g. Pixel, API 36, arm64 image on Apple
  Silicon) › start it. Or from the terminal: `flutter emulators` and `flutter emulators --launch <id>`.
  Note: emulators sit behind their own NAT (10.0.2.x). They can join a host on the Mac via `10.0.2.2`, but mDNS
  discovery and hosting for other devices won't work from an emulator.
- **Phone:** Settings › About phone › tap "Build number" 7 times › Developer options › **USB debugging** on. Plug
  it in and allow the computer. `adb devices` must say `device` (not `unauthorized`).

### 4.3 Run and build
```bash
cd klunki
flutter devices                                  # find the device id
flutter run -d <android-id>                      # debug, hot reload
flutter run --release -d <android-id>            # release (what you'd ship; needed for network demos)
flutter build apk --release                      # -> build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release                # -> build/app/outputs/bundle/release/app-release.aab (Play Store)
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 4.4 Your own keystore and signing
Without a keystore, release builds are signed with the **debug key** (Gradle prints a warning). That's fine for
your own devices, but not for a store, and an APK signed with a different key can't update it in place.

1. Create a keystore **outside the repo** and back it up together with its passwords:
   ```bash
   keytool -genkey -v -keystore ~/keys/klunki-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `klunki/android/key.properties` (ignored by git; never commit it):
   ```properties
   storePassword=…
   keyPassword=…
   keyAlias=upload
   storeFile=/Users/<you>/keys/klunki-upload.jks
   ```
   (`storeFile` may also be relative to `klunki/android/app/`.)
3. `flutter build apk --release`, then check the signer:
   ```bash
   keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk   # your name, not "Android Debug"
   ```
Instead of `key.properties`, the build also reads the environment variables `KLUNKI_KEYSTORE_FILE`,
`KLUNKI_KEYSTORE_PASSWORD`, `KLUNKI_KEY_ALIAS` and `KLUNKI_KEY_PASSWORD` (that's how CI signs, see §7). If you
publish under your own name, also change `applicationId` in `klunki/android/app/build.gradle.kts`.

### 4.5 Android troubleshooting
- **"Android sdkmanager not found" / licences not accepted:** install "Android SDK Command-line Tools (latest)"
  in the SDK Manager, then `flutter doctor --android-licenses`.
- **"Unsupported class file major version" / Gradle can't start:** wrong Java. Use JDK 17+ and point Flutter at
  it with `flutter config --jdk-dir …`.
- **NDK download or "NDK not configured":** let Gradle install it (SDK Manager › SDK Tools › NDK 28.2) after the
  licences are accepted.
- **Gradle runs out of memory:** `klunki/android/gradle.properties` asks for an 8 GB heap. On a small machine,
  override it in `~/.gradle/gradle.properties` with `org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g`.
- **Stale build after changing plugins:** `cd klunki && flutter clean && flutter pub get`.
- **Phone not listed:** a different USB cable/port, unlock the phone, re-allow USB debugging, `adb kill-server`.
- **Discovery finds nothing:** same Wi-Fi, no guest network/client isolation, battery saver off. Manual
  `IP:port` join always works.
- **INSTALL_FAILED_UPDATE_INCOMPATIBLE:** the installed app has a different signature (debug vs your key):
  `adb uninstall de.klunki.klunki` and install again.

## 5. iOS / Xcode

Needs a Mac with Xcode 27.x. Bundle id: `de.klunki.klunki`, deployment target iOS 15.0. Plugins are linked via
Swift Package Manager; there is no Podfile and no CocoaPods.

1. **Open `klunki/ios/Runner.xcworkspace`**, not `Runner.xcodeproj`:
   ```bash
   open klunki/ios/Runner.xcworkspace
   ```
   Run `cd klunki && flutter pub get` first, so the Flutter config files exist.
2. **Signing:** Xcode › Settings › **Accounts** › `+` › sign in with your Apple ID. Then select the **Runner**
   target › **Signing & Capabilities** › check "Automatically manage signing" and choose your **Team**.
   With a free "Personal Team", installed apps **expire after 7 days**: just reinstall them.
3. **"Bundle identifier is not available":** someone else (or another team) already has `de.klunki.klunki`.
   Change it in the same tab (e.g. `de.<yourname>.klunki`) and keep the change local.
4. **On the iPhone/iPad:**
   - Settings › Privacy & Security › **Developer Mode** on (the device restarts and asks once more).
   - Connect it by cable and confirm "Trust This Computer".
   - After the first install: Settings › General › **VPN & Device Management** › your developer certificate ›
     **Trust**. Until then, the app won't launch.
5. **Install with Flutter, not with Xcode's Run button:**
   ```bash
   cd klunki
   flutter devices
   flutter run --release -d <device-id>
   ```
   A **debug** build that Xcode launches shows a **white screen** when started from the home screen without the
   debugger (debug Flutter builds need the tool attached), and an attached Xcode debugger can block later
   installs. If an install hangs, stop the Xcode run (⌘.) or quit Xcode. Release builds start from the home screen
   on their own.
6. **"xcrun: error: unable to find utility devicectl" / Flutter can't see devices:** the active developer dir is
   the Command Line Tools. Either `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` once, or
   per shell:
   ```bash
   export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
   ```
7. **Permissions:** on first use iOS asks for **Local Network** (hosting, joining and discovery on the Wi-Fi;
   `NSLocalNetworkUsageDescription`, Bonjour service `_klunki._tcp`) and the **Camera** (QR scanning). If one was
   denied: Settings › Klunki › Local Network / Camera. Without Local Network permission, LAN games silently fail.
8. **Simulators:** `open -a Simulator`, then `flutter run -d <simulator-id>` (debug is fine there). Simulators share
   the Mac's network, so two simulators, or a simulator and the CLI, can play each other; see
   `tool/e2e_ios_sims.sh`. A simulator has no camera, so the QR scan shows its "no camera" state.

## 6. PWA (web)

### 6.1 Build and finalize
```bash
cd klunki
flutter build web --release
python3 build/web/pwa_finalize.py        # fills the service worker's build hash + precache list (once per build)
python3 -I tool/check_pwa_external_urls.py build/web   # optional: no CDN URLs (what CI checks)
```
`pwa_finalize.py` refuses to run twice on the same output. Rebuild first if you need to run it again.
Optional: `--dart-define=KLUNKI_BUILD=<commit>` (any `flutter build`; CI passes the commit) puts the
commit into the version line of the menu footer and into the network handshake's `build` label
(KLD-085), e.g. `1.0.0+1 · abc1234 · P3 · ba13a678`. Two devices whose lines differ in the protocol
(`P3`) or the last code (game data) cannot play together.
CanvasKit and all fonts are served from the app's own origin; nothing is loaded from a CDN.

### 6.2 Serve it through the relay
The relay serves the PWA **and** relays browser-vs-browser games on the same port, from the repo root:
```bash
dart run packages/klunki_net/bin/klunki.dart relay --port 8081 --web klunki/build/web
# Klunki relay listening on port 8081: ws://<ip>:8081/relay
# Serving the PWA from …: http://<ip>:8081/
# Open on other devices:
#   http://192.168.178.105:8081/        (Wi-Fi/LAN, en0)
#   http://Stefans-MacBook.local:8081/  (Bonjour/mDNS name)
```
Open `http://localhost:8081/` on this computer, or `http://<ip>:8081/` on other devices in the same Wi-Fi. Use
`http`, not `https`: browsers block `ws://` connections from https pages. Any free port works (the default is
4749). A plain static server (`python3 -m http.server`) also serves the app, but then relay games need a relay
address set by hand ("Relay: … · ändern"). The relay listens dual-stack (IPv6 and IPv4), so the `.local` name
works too when it resolves to an IPv6 address first (macOS/iOS do that).

**Host from the LAN address, not `localhost`.** The page uses its own address for the room link and QR code. If
you host from `http://localhost:8081/` (or `127.0.0.1`, `[::1]`), the link points to `localhost`, which other
devices can't reach; the app warns about that under the QR code and on the relay line (KLD-083). Hosting still
works for two tabs on the same computer. For other devices, open the page via the Wi-Fi IP or the `.local` name.

#### Finding this computer's address
The `klunki relay` console prints both at startup ("Open on other devices"). Otherwise:

| OS | Wi-Fi IP address | `.local` (Bonjour/mDNS) name |
|---|---|---|
| macOS | System Settings › Wi-Fi › Details… › IP address, or `ipconfig getifaddr en0` | System Settings › General › Sharing ("Local hostname") |
| Windows | Settings › Network & internet › Wi-Fi › properties (IPv4 address), or `ipconfig` in cmd ("IPv4 Address" of the Wi-Fi adapter) | `<computer name>.local` on Windows 10/11 |
| Linux | `hostname -I` or `ip -4 addr show`, or Settings › Network › Wi-Fi › details | `<hostname>.local` if Avahi runs |

`.local` names work on Apple devices and most recent Windows, Android and Linux (with Avahi) devices, but not
everywhere; the IP address always works on the same network.

### 6.3 One relay, not two
Run **one** relay and open the page from it. The page uses its own origin as the relay, and rooms exist only
inside the relay process that created them. A host on `:8081` and a guest that loaded the page from a second
relay on `:8000` will never find each other's room ("Kein Raum mit dem Code …"). Each origin (port) also has its
own service worker, cache and saved settings. If you restart on another port, reopen the page from that port.

### 6.4 Offline and updates
- The service worker (`klunki_sw.js`) only registers in a **secure context**: `http://localhost:<port>`, or
  https. On `http://<lan-ip>:<port>` the app works but is not installable or offline-capable.
- Install it from Chrome's address bar (install icon). After one online visit it starts offline.
- **After a new build:** every build changes the worker's bytes, so the browser installs the new worker on the
  next visit; it activates at once and drops the old cache. The page that is already open keeps the old code
  until you **reload once** (or close and reopen the installed app). DevTools › Application › Service Workers ›
  "Update on reload" helps while developing.

### 6.5 Fonts (after new Chinese strings)
The app bundles subset fonts so every language renders offline. After ARB strings change (especially `zh`), run
the subset tool (it downloads from the Google Fonts API, so it needs the internet):
```bash
cd klunki
python3 -I tool/update_web_fonts.py subset
flutter test test/l10n
```
`test/l10n/glyph_coverage_test.dart` fails with this hint when a glyph is missing. Commit the regenerated TTFs.

## 7. CI (GitHub Actions)

Workflows are in `.github/workflows/`. Flutter is pinned to **3.47.8** in both; every action is pinned to a commit
SHA.

| Workflow | Trigger | Jobs |
|---|---|---|
| `ci.yml` | push to `main`, every pull request | **engine** (`dart analyze --fatal-infos`, `dart test`), **net** (same, including the dart2js web compile test), **app** (l10n up to date, `flutter analyze`, `flutter test`) |
| `build.yml` | push to `main`, tags `v*`, manual (**Run workflow**) | **pwa** (build + finalize + no-external-URL check → artifact `klunki-pwa`), **android** (release APK → artifact `klunki-android-apk`), **ios** (manual runs only: `flutter build ios --release --no-codesign` as a compile check, no artifact) |

All jobs run on ubuntu, except iOS (macOS, only on manual runs because macOS minutes are expensive in a private
repo). Nothing is deployed. A GitHub Pages job is present but disabled (`if: false`) until the owner decides.

**Downloading artifacts:** Actions tab › the "Build" run › **Artifacts** at the bottom, or with the GitHub CLI:
```bash
gh run list --workflow build.yml --limit 5
gh run download <run-id> --name klunki-android-apk     # app-release.apk
gh run download <run-id> --name klunki-pwa --dir web  # serve with the relay: --web web
```
Artifacts are kept for 30 days.

**Optional signing secrets** (Settings › Secrets and variables › Actions). Without them, the CI APK is signed
with the runner's throwaway debug key, which differs on every run, so CI APKs can't update each other in place:

| Secret | Content |
|---|---|
| `KEYSTORE_BASE64` | the `.jks` file, base64: `base64 -i ~/keys/klunki-upload.jks \| pbcopy` |
| `KEYSTORE_PASSWORD` | store password |
| `KEYSTORE_KEY_ALIAS` | key alias, e.g. `upload` |
| `KEYSTORE_KEY_PASSWORD` | key password |

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| **"Found no `pubspec.yaml` file in … or parent directories"** / `Expected to find project root in current working directory` / `Test directory "test" not found` | `dart pub get`, `flutter …` or `flutter test` run in the repo root, which has no pubspec | `cd klunki` (app) or `cd packages/<name>`. Only `dart run packages/klunki_net/bin/klunki.dart …` works from the root |
| `Because klunki requires SDK version ^3.13.7, version solving failed` | Flutter too old | install Flutter 3.47.8 |
| Lots of analyzer errors in `packages/*` right after cloning | no `dart pub get` in that package yet | `dart pub get` in the package |
| `flutter test` fails in only one network test under heavy load | real-socket timing | rerun it alone (`flutter test <file> --plain-name "<name>"`); report it if it fails alone |
| iOS app shows a white screen | debug build started without the tool | `flutter run --release -d <device>` (§5.5) |
| iOS install hangs / "device is busy" | Xcode debugger still attached | ⌘. in Xcode or quit Xcode, then rerun |
| `unable to find utility "devicectl"` | Command Line Tools selected | `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (§5.6) |
| iOS app can't find or join anyone | Local Network permission denied | Settings › Klunki › Local Network |
| Free-team app won't open after a week | 7-day provisioning expired | reinstall with `flutter run --release` |
| Android: licences / sdkmanager errors | cmdline-tools missing | §4.1 |
| Android: Gradle/Java version errors | JDK < 17 | §4.5 |
| PWA: "Kein Relay erreichbar unter …" | page not served by `klunki relay` | §6.2 |
| PWA: "Kein Raum mit dem Code …" | host and guest on different relays/ports, a typo, or the room expired (10 min idle) | §6.3 |
| PWA shows the old version after a rebuild | old page still open | reload once (§6.4) |
| PWA: `ws://` blocked | page served over https | serve over http on the LAN (§6.2) |
| `pwa_finalize.py`: refuses to run | already finalized | `flutter build web --release` again, then finalize |
| Chinese text shows □ boxes | new characters not in the font subset | §6.5 |
| Port already in use (relay, host) | another relay/host still running | pick another `--port`; hosts fall back to a free port by themselves |
