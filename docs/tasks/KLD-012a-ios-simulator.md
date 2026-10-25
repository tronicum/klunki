# KLD-012a: iOS hello world on the Simulator

- **ID:** `KLD-012a`
- **Title:** Build the Klunki app and launch it on the iOS Simulator (iPhone + iPad)
- **Milestone:** Platform hello world
- **Status:** DONE
- **Depends on:** none (part of KLD-012)
- **Touched paths:**
  - `docs/tasks/KLD-012a-ios-simulator.md` (this card only; no code or project changes)

## Goal
Show that the unchanged Flutter app builds for the iOS Simulator and shows the menu
("Wähle ein Spiel", 4 Gewinnt / Mühle / Quartett, Debug-Konsole) on an iPhone and an iPad simulator.

## Acceptance criteria
- [x] `flutter build ios --simulator --debug` succeeds
- [x] App installs and launches on an iPhone simulator (iPhone 18 Pro, iOS 27.0)
- [x] App installs and launches on an iPad simulator (iPad Pro 11-inch (M5), iOS 27.0)
- [x] Screenshots show the Klunki menu on both
- [x] Simulators shut down again

## Environment (2026-10-25)
- Xcode 27.1 (build 27A9275) at `/Applications/Xcode.app`, Flutter 3.47.8 stable, Swift Package Manager (no CocoaPods)
- `xcode-select -p` still points to `/Library/Developer/CommandLineTools`.
  **The global switch is not needed:** Flutter and `xcrun` accept the env var
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. `flutter doctor` then reports Xcode 27.1 OK.
  The only warning is "CocoaPods not installed", which you can ignore while there are no native plugins.
  Optional convenience (needs sudo, only the user runs it): `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

## Working commands
```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd klunki

# Build (about 22 s wall time on a warm Flutter cache, Xcode part 13.9 s)
flutter build ios --simulator --debug
# -> build/ios/iphonesimulator/Runner.app

# Boot existing simulators (both booted in about 30 s)
xcrun simctl list devices available
IPHONE=743EBC93-DAA0-40F7-A13C-2E82130787A6   # iPhone 18 Pro, iOS 27.0
IPAD=66A98FDA-73E4-4DDB-A600-B33BFBB665A7     # iPad Pro 11-inch (M5), iOS 27.0
xcrun simctl boot $IPHONE; xcrun simctl boot $IPAD
xcrun simctl bootstatus $IPHONE; xcrun simctl bootstatus $IPAD

# Install, launch, screenshot
for d in $IPHONE $IPAD; do
  xcrun simctl install $d build/ios/iphonesimulator/Runner.app
  xcrun simctl launch  $d de.klunki.klunki
done
xcrun simctl io $IPHONE screenshot /tmp/klunki-ios-check/iphone18pro.png
xcrun simctl io $IPAD   screenshot /tmp/klunki-ios-check/ipadpro11.png

# Clean up
xcrun simctl shutdown $IPHONE $IPAD
```
For interactive development, `flutter run -d <udid>` also works (same `DEVELOPER_DIR`).

## Result
Both devices show the AppBar "Klunki", "Wähle ein Spiel", the three cards 4 Gewinnt / Mühle / Quartett and
the "Debug-Konsole" button. The iPad status bar shows the display name "Klunki" (`CFBundleDisplayName`).

## Remaining for real iPhones/iPads (KLD-012 / KLD-040, needs the user)
- Sign in with an Apple ID in Xcode (Settings > Accounts). A free Personal Team is enough for the demo, but the app expires after 7 days.
- Set `DEVELOPMENT_TEAM` for the Runner target (Xcode > Runner > Signing & Capabilities, "Automatically manage signing").
  It is not set yet in `project.pbxproj`. If the bundle ID `de.klunki.klunki` is already taken for the team, change it.
- On the device, turn on Developer Mode (Settings > Privacy & Security > Developer Mode, then restart) and connect it once by cable to trust the Mac.
- After the first install, trust the developer certificate (Settings > General > VPN & Device Management).
- Networking (KLD-040): add `NSLocalNetworkUsageDescription` and `NSBonjourServices` (`_klunki._tcp`) to
  `ios/Runner/Info.plist`. Neither is present yet. Without them, mDNS/TCP on the LAN is blocked or shows no prompt on a real device.
  The simulator uses the Mac's network and does not enforce the local network prompt, so test this on hardware.
- Deployment target is iOS 15.0 (fine for current devices).

## Definition of done
Build and launch on the simulator reproduced with the commands above. No repo files changed apart from this card.
