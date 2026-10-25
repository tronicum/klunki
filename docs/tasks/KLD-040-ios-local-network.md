# KLD-040 — iOS local network (Bonjour keys, permission prompt, backgrounding)

- **ID:** `KLD-040`
- **Title:** iOS local network: `NSLocalNetworkUsageDescription`, `NSBonjourServices` (`_klunki._tcp`), permission prompt flow, backgrounding → reconnect
- **Milestone:** P3/P4. With the current devices (one Android phone, one iPhone, one iPad), **iPhone ↔ iPad is the first two-device demo**,
  so this card has priority. End of PoC = Android phone ↔ iPhone or iPad.
- **Status:** TODO
- **Depends on:** KLD-012 (iOS builds run on the iPhone and iPad, signing team set), KLD-033 (`bonsoir` discovery); for the end-to-end check
  also KLD-034 (pairing) and ideally KLD-036 (reconnect). 🧑 iPhone + iPad, permission taps.
- **Touched paths:**
  - `klunki/ios/**`
  - `docs/tasks/KLD-040-ios-local-network.md` (status only)

## Goal
On the iPhone and the iPad, the Klunki app can advertise and browse `_klunki._tcp` and open TCP connections on the local Wi-Fi.
The system "local network" prompt shows a clear German reason. The tested behaviour (prompt allowed/denied, app backgrounded or
device locked mid-game) is documented, and the gaps on the Dart side are reported.

## Context
- `klunki/ios/Runner/Info.plist` has `CFBundleDisplayName` = "Klunki" but **lacks** `NSLocalNetworkUsageDescription` and `NSBonjourServices`.
  Without `NSBonjourServices`, iOS 14+ silently returns no browse results and refuses to advertise. Without the usage description,
  local-network access fails.
- Bundle id `de.klunki.klunki`; deployment target 15.0; Swift Package Manager (no CocoaPods). Xcode 27.1 is installed.
- Signing: `DEVELOPMENT_TEAM` is set by KLD-012. A free Apple ID means 7-day profiles and max 3 apps per device.

## Acceptance criteria
- [ ] `Info.plist` contains:
  ```xml
  <key>NSLocalNetworkUsageDescription</key>
  <string>Klunki sucht Mitspieler im selben WLAN und verbindet sich mit ihnen.</string>
  <key>NSBonjourServices</key>
  <array>
      <string>_klunki._tcp</string>
  </array>
  ```
  Plus anything the `bonsoir` README (the version pinned in `klunki/pubspec.yaml`) requires for iOS. Quote it in your report.
- [ ] No multicast entitlement (`com.apple.developer.networking.multicast`) is requested: Bonjour via `NSBonjourServices` doesn't need it. If
      something turns out to need it, stop: it requires an Apple approval request (🧑).
- [ ] `cd klunki && flutter build ios --debug --no-codesign` and `flutter build ios --simulator` succeed.
- [ ] 🧑 Device protocol on **iPhone + iPad** (fresh install on both, so the prompt appears):
  1. First host or browse → the iOS prompt "„Klunki“ möchte Geräte in deinem lokalen Netzwerk finden …" appears with the text above → **Allow**.
  2. iPhone hosts, iPad joins via the list → Connect Four to the end. Then iPad hosts, iPhone joins.
  3. Manual `IP:port` join works.
  4. **Denied path:** on one device, Settings → Klunki → Lokales Netzwerk → off. Record what the app shows (expected today: an empty list
     and a connect timeout). The app should hint "Einstellungen → Klunki → Lokales Netzwerk". If it doesn't, report it as a Dart follow-up (KLD-034).
  5. **Backgrounding:** mid-game, lock the guest device for ~30 s, then unlock → record whether the game resumes (KLD-036) or what breaks.
     Then the same with the host locked (expected: iOS suspends the app and the socket dies; the host must be foreground to serve).
  Write the results (device models, iOS versions, Wi-Fi type) into your report.
- [ ] `cd klunki && flutter analyze && flutter test` green.

## Constraints
- **Board rule:** never install toolchains, download SDK components (device support files, simulator runtimes), accept licenses, sign up for
  accounts or publish anything without the user's explicit OK. No TestFlight or App Store.
- Only touch `klunki/ios/**`. The permission-denied hint and the reconnect behaviour are Dart code (KLD-034/036): report the gaps, don't edit them here.
- Don't commit unless asked.

## 🧑 Steps the user does personally
- Keep both devices unlocked, on the **same Wi-Fi** (not a guest network; or a phone hotspot). Developer Mode on, computer trusted, developer
  certificate trusted (Settings → General → VPN & Device Management), all from KLD-012.
- Tap **Allow** on the local-network prompt (and tap **Don't Allow** once on purpose for step 4, or toggle it in Settings).
- If the prompt never appears again after a deny: delete and reinstall the app. iOS remembers the choice per install.

## Hints / context
```bash
cd klunki
flutter build ios --simulator
flutter run --release -d <iphone-id>   # release = standalone, survives unplugging
flutter run --release -d <ipad-id>
dns-sd -B _klunki._tcp                 # on the Mac (same Wi-Fi): shows announced hosts
```
- The prompt is triggered by the first local-network activity (Bonjour browse/advertise or a connect to a LAN IP), not at app launch.
- The simulator uses the Mac's network stack and is not a reliable test for the local-network prompt. Test the prompt on real devices only.
  The macOS firewall can block simulator-hosted servers.
- Free-ID builds expire after 7 days. Re-run `flutter run` before a demo (see `docs/DEMO.md`).

## Definition of done
```bash
cd klunki
flutter analyze && flutter test
flutter build ios --simulator
flutter run --release -d <iphone-id> ; flutter run --release -d <ipad-id>   # 🧑 protocol above
```
Acceptance criteria ticked, protocol results reported, card status set to DONE.
