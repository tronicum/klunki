# KLD-012 — iOS hello world (simulator, iPhone, iPad)

- **ID:** `KLD-012`
- **Title:** iOS: build + run on the simulator, the user's iPhone and iPad; display name "Klunki"; signing team
- **Milestone:** Platform hello world (side quest; **iOS has priority**: the first two-device demo is iPhone ↔ iPad)
- **Status:** Simulator part DONE (see `KLD-012a-ios-simulator.md`); device part BLOCKED (🧑 Apple ID in Xcode + Developer Mode on iPhone and iPad)
- **Depends on:** iOS audit (done, facts below); 🧑 `xcode-select` switch, Apple ID in Xcode, device trust (see below)
- **Touched paths:**
  - `klunki/ios/**`
  - `docs/tasks/KLD-012-ios-hello-world.md` (status only)

## Goal
The Klunki app builds and runs on an iOS simulator, on the user's **iPhone** and on the user's **iPad**
from `flutter run`. The home screen shows "Klunki", and the project carries the user's signing team.

## Context (audit, 2026-10-25)
- Xcode 27.1 is installed, with the iOS 27.0/27.1 simulator runtimes. The Xcode license is accepted.
- **CocoaPods is not needed:** the project uses Swift Package Manager. Don't install CocoaPods.
- **Blocker:** the active developer directory points to the CommandLineTools. The user must run
  `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` themselves (needs sudo).
- `klunki/ios/Runner/Info.plist`: `CFBundleDisplayName` is already **"Klunki"** (`CFBundleName` is `klunki`, which is fine).
- Bundle id `de.klunki.klunki` (tests: `de.klunki.klunki.RunnerTests`); `IPHONEOS_DEPLOYMENT_TARGET = 15.0`.
- `DEVELOPMENT_TEAM` is **unset** in `klunki/ios/Runner.xcodeproj/project.pbxproj`.
- `NSLocalNetworkUsageDescription` / `NSBonjourServices` are missing. That's KLD-040's job, not this card's.

## Acceptance criteria
- [ ] `flutter doctor -v` shows ✓ Xcode (after the user's `xcode-select` switch). Paste it into your report.
- [ ] `cd klunki && flutter build ios --simulator --debug` succeeds.
- [ ] `flutter run -d <simulator-id>` starts the app on an iPhone simulator: the menu shows, and the Debug-Konsole runs `demo connect4`.
- [ ] `DEVELOPMENT_TEAM = <team id>` is set for the Runner target (Debug/Release/Profile) in `project.pbxproj`,
      with automatic signing. If the bundle id `de.klunki.klunki` is already taken for a free team,
      stop and ask the user which unique id to use (e.g. `de.klunki.klunki.<suffix>`), then change it consistently.
- [ ] 🧑 `flutter run -d <iphone-id>` installs and starts the app on the **iPhone**, and the label reads "Klunki".
- [ ] 🧑 the same on the **iPad** (the app must launch and lay out usably in portrait and landscape; no iPad-specific UI work).
- [ ] `cd klunki && flutter analyze && flutter test` are green.

## Constraints
- **Board rule:** never install toolchains, download SDK components (e.g. extra simulator runtimes, device
  support files Xcode offers to download), accept licenses, sign up for accounts or publish anything without
  the user's explicit OK. If Xcode asks to download something, stop and ask.
- No CocoaPods. Only edit `klunki/ios/**`. Don't commit unless asked.
- Don't add the local-network keys here (KLD-040 owns them; same paths, later wave).
- Never put Apple ID credentials or certificates into the repo. Only the team id goes into `project.pbxproj`.

## 🧑 Steps the user does personally
1. `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
2. Xcode → Settings → **Accounts** → "+" → Apple ID. A **free Apple ID works**: profiles expire after
   **7 days** (re-run `flutter run` to re-sign), and at most **3 apps** per device.
3. Open `klunki/ios/Runner.xcworkspace` in Xcode → Runner target → Signing & Capabilities →
   tick "Automatically manage signing", pick the **Team**. (Or tell the agent the team id.)
4. **iPhone and iPad**, each: connect by USB (or the same Wi-Fi after the first pairing), unlock, tap
   **"Trust This Computer"** and enter the passcode.
   Turn on **Developer Mode**: Settings → Privacy & Security → Developer Mode → On → restart → confirm.
5. After the first install: on the device, Settings → General → **VPN & Device Management** → the developer
   certificate (Apple ID) → **Trust**. Until then the app won't open ("Untrusted Developer").
6. (Later, KLD-040) Allow the **local network** prompt when the app first searches for peers.

## Hints / context
```bash
xcode-select -p                     # must print /Applications/Xcode.app/Contents/Developer
flutter doctor -v
xcrun simctl list devices available # pick an iPhone simulator (iOS 27.x)
open -a Simulator
cd klunki
flutter build ios --simulator --debug
flutter run -d <simulator-id>
flutter devices                     # iPhone/iPad appear once trusted + Developer Mode on
flutter run -d <iphone-id>
flutter run -d <ipad-id>
```
- The team id is the 10-character id shown in Xcode's Accounts pane, or in `project.pbxproj`
  after the user picked the team in Xcode. Setting it in Xcode edits `project.pbxproj` for you.
- "Could not find Developer Disk Image" or "device support" errors: Xcode wants to download device
  support. That's a download, so ask the user first.
- First launch from `flutter run` on iOS 14+ in debug mode needs the device to stay unlocked. Debug
  builds don't launch from the home screen after the cable is pulled. For the demo use `flutter run --release`
  (or `--profile`), which installs a standalone build.
- Wireless: in Xcode → Window → Devices and Simulators, tick "Connect via network". After that
  `flutter run` finds the device over Wi-Fi.

## Definition of done
```bash
cd klunki
flutter analyze && flutter test
flutter build ios --simulator --debug
flutter run -d <simulator-id>   # app starts
flutter run -d <iphone-id>      # 🧑 app starts, label "Klunki"
flutter run -d <ipad-id>        # 🧑 app starts
```
Acceptance criteria ticked, card status set to DONE.
