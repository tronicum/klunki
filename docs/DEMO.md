# Klunki — Demo runbook

How to run each demo, step by step: what to prepare, what to type, what the audience sees, and what to do when it breaks.
It's maintained by card `docs/tasks/KLD-041-demo-runbook.md` and updated as tasks land.

**Devices (current plan):** one Mac (Apple Silicon), **one Android phone**, **one iPhone**, **one iPad**.
There is no second Android phone, so there's **no Android ↔ Android demo**. The first two-device demo is **iPhone ↔ iPad**,
and the end of the PoC is **Android phone ↔ iPhone or iPad**.

Legend: 🧑 = the user does it personally (device, account, GUI click, password). ⏳ = not possible yet, waiting for the named task.

| # | Demo | Status | Needs |
|---|---|---|---|
| 1 | Text demo (terminal + in-app Debug-Konsole) | ✅ ready (terminal) | Mac with Flutter/Dart |
| 2 | Hot-seat on one device | 🟡 shell ready (KLD-020/021 done; every game playable via placeholder move buttons); real screens ⏳ KLD-022…026 | + simulator, or iPhone/iPad/Android/Chrome |
| 3 | iPhone ↔ iPad over Wi-Fi | ⏳ KLD-012 (device part), 032–034, 040 (030 done) (036 nice-to-have) | iPhone + iPad + Xcode |
| 4 | Android ↔ iOS over Wi-Fi (end of PoC) | ⏳ + KLD-011, 035 | + Android phone + Android Studio |
| 5 | PWA (web, offline) | ✅ ready (KLD-010) | Chrome on the Mac |

---

## Pre-demo checklist (one page)

Do this **the day before** and again **30 minutes before**.

**Mac**
- [ ] On power, notifications off (Focus mode), screen sleep off, terminal font large (⌘+), dark/light theme picked.
- [ ] `cd packages/klunki_engine && dart test` is green, and `dart run bin/klunki.dart demo connect4` prints a game.
- [ ] `cd klunki && flutter analyze && flutter test` is green.
- [ ] `flutter doctor -v`: Xcode ✓ (demos 3/4), Android toolchain ✓ (demo 4), Chrome ✓ (demo 5).
- [ ] `xcode-select -p` prints `/Applications/Xcode.app/Contents/Developer` (🧑 one-time `sudo xcode-select --switch …`).
- [ ] macOS firewall: if on, allow incoming connections for `dart` / the simulator when asked (🧑), or test before the audience arrives.

**Network**
- [ ] One Wi-Fi network that all devices join. **Not a guest network**, no "client isolation" / "AP isolation"
      (most office and hotel guest Wi-Fis block phone-to-phone traffic).
- [ ] Fallback ready: a **phone hotspot** (iPhone: Settings → Personal Hotspot, "Maximize Compatibility" on; or the Android phone).
      Note: the hotspot phone itself can play too, but its own Wi-Fi is off. The other devices join it.
- [ ] VPNs off on every device (VPNs often route LAN traffic away).

**iPhone + iPad** (demos 3/4)
- [ ] Charged (> 50 %), auto-lock set to "Never" for the demo, Do Not Disturb on, brightness up.
- [ ] Developer Mode on, "Trust This Computer" done, developer certificate trusted (Settings → General → VPN & Device Management) 🧑.
- [ ] **Free Apple ID builds expire after 7 days.** Reinstall within the last 7 days: `flutter run --release -d <device>` 🧑.
- [ ] Local-network permission for Klunki **allowed** (Settings → Klunki → Lokales Netzwerk = on) 🧑.
- [ ] A **release** build is installed (it starts from the home screen without the cable; debug builds don't).

**Android phone** (demo 4)
- [ ] Charged, screen timeout max, Do Not Disturb on.
- [ ] Developer options + USB debugging on; `adb devices` shows `device` (not `unauthorized`) 🧑.
- [ ] Release build installed: `flutter run --release -d <android-id>`.
- [ ] Battery saver **off** (it can throttle Wi-Fi and multicast).

**Dry run**
- [ ] Every networked demo played once end to end on **this** network, with each device hosting once.
- [ ] Write down each device's IP (Settings → Wi-Fi → (i)) for the manual-join fallback.

---

## 1. Text demo (terminal + in-app Debug-Konsole) ✅

Shows that all five games are fully playable as text: one engine, no UI needed.

### Prerequisites
- [ ] Mac with Flutter 3.47.8 (Homebrew, `/opt/homebrew/share/flutter`); `dart` on the `PATH`.
- [ ] Repo checked out; `cd packages/klunki_engine && dart pub get` done once.

### Commands
```bash
cd packages/klunki_engine

# narrated full game of every game (Connect Four, Mühle, Quartett Trumpf, Quartett Sets, Schiffe versenken)
dart run bin/klunki.dart demo

# one game at a time (better pacing for an audience)
dart run bin/klunki.dart demo connect4
dart run bin/klunki.dart demo muehle
dart run bin/klunki.dart demo quartett-trumpf
dart run bin/klunki.dart demo quartett-sets
dart run bin/klunki.dart demo schiffe

# pipe through less to scroll in front of people
dart run bin/klunki.dart demo muehle | less

# scripted: each argument is one console line
dart run bin/klunki.dart connect4 3 3 4 4

# interactive (default game: connect4)
dart run bin/klunki.dart muehle
```

Interactive commands (type `help` in any game):

| Command | Effect |
|---|---|
| `new [game]` | restart, or switch game (`connect4`, `muehle`, `quartett-trumpf`, `quartett-sets`, `schiffe`) |
| `moves` | list legal moves for the player on turn |
| `auto [n]` | play n random legal moves (seeded; default: to the end) |
| `undo` | take back the last move (replays the move list minus one) |
| `history` | list accepted moves |
| `demo [games]` | narrated full game of each (or the given) game |
| `help` / `quit` | help / exit |

Move syntax per game:
- **4 Gewinnt:** `3` (column 0–6)
- **Mühle:** `4` place, `4-7` move/fly, `x13` remove after a mill
- **Quartett Trumpf:** `1`…`5` or a stat id (`ps`, `kmh`, `ccm`, `kg`, `sec0to100`)
- **Quartett Sets:** a card id like `B3` (you must hold that set, not that card)
- **Schiffe versenken:** `B2h` / `B2v` place the next ship, `fleet [seed]` place the rest randomly, `E5` fire

### What the audience sees
- A banner `DEMO: 4 Gewinnt`, the empty board, then one plain-language line per move
  ("X drops into column 3 …"), the board again at highlights, and a result line, e.g.
  `Result: X wins (four in a row) after 11 moves.`
- The current seeds give: 4 Gewinnt X wins in 11, Mühle O wins in 33, Quartett Trumpf X wins in 62, Quartett Sets O wins 6:2 in 31,
  Schiffe O wins in 96. (Deterministic, so the outcome is the same every run unless the engine changes.)
- Quartett/Schiffe show only the player on turn's hand or fleet, plus the opponent's count. Hidden information works even in text.

### In-app Debug-Konsole (any platform that runs the app; debug/profile builds only)
- Menu → **Debug-Konsole** → ⋮ menu: "Neu: <game>", "Legale Züge", "Zu Ende spielen (zufällig)", **"Demo: alle Spiele"**.
- Or type the same commands as in the terminal into the input field.
- It's hidden in **release** builds (`kReleaseMode`). For a phone demo of the console use `flutter run` (debug) or `--profile`.

### Two terminals over the network (KLD-031)
Same Mac or two Macs on one Wi-Fi; the host plays X and moves first.
```bash
# terminal 1 (prints its IP addresses, the port and the game config)
cd packages/klunki_net && dart run klunki_net:klunki host connect4 --port 4747 --name Ada
# terminal 2 (use 127.0.0.1 on the same Mac, otherwise an IP printed by the host)
cd packages/klunki_net && dart run klunki_net:klunki join 127.0.0.1 4747 --name Bea
```
- Any game id works; seeded games take `--seed`, e.g. `host quartett-trumpf --seed 42` (the guest gets the seed from the host).
- Each terminal shows only its own player's view (Quartett hand, Schiffe fleet) and only on its turn; every move is narrated on both.
- In the game: a move on your turn, `board`, `moves`, `help`, `quit`. Out-of-turn input is refused.
- A dropped connection shows a message on both; the guest asks `Reconnect? [Y/n]` and resumes. `quit` ends it for both.
- 🧑 macOS may ask "Allow incoming connections?" for `dart` when hosting for another Mac.

### Troubleshooting
- `Could not find package "test"` / pub errors → `dart pub get` in `packages/klunki_engine` (needs network once).
- Output scrolls too fast → run single games or pipe to `less`.

---

## 2. Hot-seat on one device ⏳ (P2: KLD-020…026)

> **TODO (fill in when P2 lands):** exact menu labels, screenshots/expected screens per game, the handover cover text,
> and the result dialog wording. Update the status table at the top.

### Prerequisites
- [ ] P2 cards DONE: KLD-020 (controller), 021 (shell), 022–026 (screens).
- [ ] One of: iOS simulator (no 🧑 needed), iPhone/iPad (🧑 trusted, Developer Mode), Android phone (🧑 USB debugging), Chrome.

### Commands
```bash
cd klunki
flutter devices
flutter run -d <simulator-id>          # e.g. iPhone simulator: xcrun simctl list devices available ; open -a Simulator
flutter run --release -d <iphone-id>   # standalone on device
flutter run -d chrome                  # web, hot-seat works there too
```

### What the audience sees (TODO: verify)
- Menu "Wähle ein Spiel" with 4 Gewinnt, Mühle, Quartett (Trumpf), Quartett (Sets), Schiffe versenken.
- 4 Gewinnt / Mühle: two people take turns on the same screen; the result dialog appears at the end.
- Quartett / Schiffe: after each turn a full-screen cover "Gib das Gerät an O weiter" → "Ich bin O – weiter". The other player's cards/fleet are never visible.
- TODO: suggested demo order and the fastest scripted game per screen (reuse the widget-test scripts).

### Troubleshooting (TODO)
- Simulator slow on first launch → start it before the demo (`open -a Simulator`).

---

## 3. iPhone ↔ iPad over Wi-Fi ⏳ (first two-device demo)

Replaces the original "Android ↔ Android" demo (only one Android phone is available). Needs no Android toolchain.

### Prerequisites
- [ ] Cards DONE: KLD-012 (iOS builds on the devices), KLD-030 (`klunki_net`), 032 (`NetworkTransport`), 033 (discovery), 034 (pairing),
      **040 (iOS local network keys)**; 036 (reconnect) recommended.
- [ ] 🧑 `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` (one-time).
- [ ] 🧑 Apple ID in Xcode → Settings → Accounts (free ID ok: 7-day profiles, max 3 apps per device); team set (KLD-012).
- [ ] 🧑 iPhone and iPad: Trust This Computer, Developer Mode on, developer certificate trusted after the first install.
- [ ] 🧑 Both on the same Wi-Fi (no guest network), or one device's hotspot.

### Warm-up: two terminals (optional, after KLD-031)
Shows the same protocol without phones:
```bash
# terminal 1
cd packages/klunki_net && dart run bin/klunki_net.dart host connect4
# terminal 2
cd packages/klunki_net && dart run bin/klunki_net.dart join 127.0.0.1
```
> TODO (KLD-031): confirm the executable name and flags.

### Commands
```bash
cd klunki
flutter devices                         # both devices listed (USB or "Connect via network" in Xcode)
flutter run --release -d <iphone-id>    # install standalone build
flutter run --release -d <ipad-id>
```
Then on the devices (TODO: confirm the labels from KLD-034):
1. iPhone: Menu → **Über WLAN spielen** → **Hosten** → pick "4 Gewinnt". It shows name, `IP:port`, QR, "Warte auf Mitspieler…".
2. First time only: the iOS prompt "„Klunki“ möchte Geräte in deinem lokalen Netzwerk finden" → 🧑 **Erlauben** (on both devices).
3. iPad: **Über WLAN spielen** → **Beitreten** → tap the iPhone's entry (or type `IP:port`).
4. Play to the end. Then swap: the iPad hosts, the iPhone joins. Repeat for each game (Mühle, Quartett Trumpf, Quartett Sets, Schiffe).

### What the audience sees
- The iPad's join list shows the iPhone within a few seconds. After a tap, both screens switch to the game.
- A move on one device appears on the other almost instantly. Each device only lets its own player (X = host, O = guest) move.
- Quartett/Schiffe: each device shows only its owner's cards/fleet. **No handover cover** over the network.
- (With 036) Lock the iPad for a moment → "Verbindung verloren – verbinde neu…" → unlock → the game continues.

### Troubleshooting
- **List stays empty:**
  1. Local-network permission denied → Settings → Klunki → Lokales Netzwerk → on (or delete and reinstall to get the prompt again).
  2. Guest Wi-Fi / client isolation → switch to the hotspot fallback.
  3. Check from the Mac on the same Wi-Fi: `dns-sd -B _klunki._tcp`. If the Mac sees the host, the joining device's permission is the problem.
  4. Use manual join with the host's `IP:port` (shown on the host screen).
- **Manual join times out** → the network blocks peer traffic (isolation) or the host app went to the background. Keep the host in the foreground and unlocked.
- **App won't open: "Untrusted Developer"** → 🧑 Settings → General → VPN & Device Management → trust.
- **App crashes on launch / "unable to verify"** → the free-ID profile expired (7 days). Reinstall with `flutter run --release`.
- **Device not in `flutter devices`** → unlock it, re-plug, accept "Trust", check Developer Mode; for Wi-Fi debugging pair once by USB in Xcode → Devices and Simulators.

---

## 4. Android phone ↔ iPhone/iPad over Wi-Fi ⏳ (end of PoC)

### Prerequisites
- [ ] Everything from demo 3, plus cards DONE: **KLD-011** (Android toolchain + phone) and **KLD-035** (Android networking, release build).
- [ ] 🧑 Android Studio installed (approved) + setup wizard; SDK packages `platform-tools`, `platforms;android-36`, `build-tools;36.0.0`,
      `cmdline-tools;latest`; **licenses accepted personally**: `flutter doctor --android-licenses`. No emulator needed.
- [ ] 🧑 Android phone: Developer options → USB debugging on; "Allow USB debugging?" accepted (tick "Always allow").
- [ ] All devices on the same Wi-Fi.

### Commands
```bash
cd klunki
flutter doctor -v                         # Android toolchain ✓, Xcode ✓
adb devices                               # phone = "device"
flutter run --release -d <android-id>
flutter run --release -d <iphone-id>      # or <ipad-id>
```
Then (labels: see demo 3):
1. Android hosts "Mühle" → the iPhone joins from the list → play to the end.
2. iPhone hosts "Schiffe versenken" → Android joins → play to the end.
3. Repeat until every game has been played to the end, with each platform hosting at least once (the PoC exit criterion).

### What the audience sees
- The same as demo 3, but across platforms: the same engine on Android and iOS, and the same moves on both screens.

### Troubleshooting
- **Android doesn't see the iOS host (but iOS sees Android):** multicast lock or permissions missing (KLD-035). Check
  `adb logcat | grep -i -E "nsd|bonsoir|mdns"`. Battery saver off. Fallback: manual `IP:port`.
- **Works in debug, fails in release:** `INTERNET` missing in `android/app/src/main/AndroidManifest.xml` (release uses only the main manifest).
- **`adb devices` shows `unauthorized`:** unlock the phone, accept the RSA prompt; else `adb kill-server && adb start-server`, re-plug,
  and on the phone "Revoke USB debugging authorizations", then try again.
- **Android hotspot as fallback:** the iPhone/iPad join the Android hotspot. The Android phone's own IP is the gateway (often `192.168.x.1`,
  vendor-specific; shown on the host screen).
- **iPhone hotspot as fallback:** turn on "Maximize Compatibility" so older Android Wi-Fi sees it.

---

## 5. PWA (web, offline) ⏳ (KLD-010)

The web build is **hot-seat only** (browsers can't open TCP sockets; network play on the web needs the internet relay, KLD-051).

### Prerequisites
- [ ] KLD-010 DONE (Klunki branding in `manifest.json`/`index.html`, custom offline service worker).
- [ ] Chrome on the Mac.

### Commands
```bash
cd klunki
flutter build web --release
# serve locally (TODO: replace with the serve command KLD-010 documents)
python3 -m http.server 8080 --directory build/web
open -a "Google Chrome" http://localhost:8080
```

### What the audience sees
- Klunki loads in Chrome. The address bar shows the **install** icon → install → it opens as its own app window with the Klunki name and icon.
- Offline check: DevTools → Application → Service Workers shows it active. Then DevTools → Network → "Offline" (or stop the server)
  → reload → the app still loads and plays (Debug-Konsole / hot-seat once P2 lands).

### Troubleshooting
- **Service worker / install button missing on a phone via `http://<mac-ip>:8080`:** service workers need a **secure context**
  (HTTPS or `localhost`). A LAN IP over HTTP won't register a service worker, so demo the PWA install on the Mac's Chrome at `localhost`.
  A phone install needs HTTPS hosting (🧑 a hosting decision; not part of the PoC).
- **Old version keeps loading:** DevTools → Application → "Clear site data", or bump the service-worker cache version (KLD-010).
- **Blank page:** the server must serve from `build/web` (base href `/`). Check the DevTools console.

---

## General troubleshooting reference

| Symptom | Likely cause | Fix |
|---|---|---|
| Devices can't see or reach each other | guest Wi-Fi / client (AP) isolation | phone hotspot |
| Only the iOS device can't find hosts | local-network permission denied | Settings → Klunki → Lokales Netzwerk; reinstall to re-prompt |
| Only Android can't find hosts | multicast lock / permissions / battery saver | KLD-035; battery saver off; manual IP |
| Mac-hosted terminal/simulator unreachable from phones | macOS firewall | System Settings → Network → Firewall → allow `dart`/Simulator, or turn it off for the demo 🧑 |
| VPN on any device | LAN traffic routed into the tunnel | turn the VPN off |
| iOS app won't launch | profile expired (7 days) / untrusted developer | reinstall; trust the certificate |
| `adb` unauthorized | USB authorization not accepted | unlock + accept prompt; revoke and retry |
| Connection drops when a device locks | iOS suspends background apps | keep the host in the foreground; reconnect (KLD-036) |
