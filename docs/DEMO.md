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
| 2 | Hot-seat on one device | ✅ ready (KLD-020…026: real screens for all five games; verified by widget tests, manual check on device pending) | + simulator, or iPhone/iPad/Android/Chrome |
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

# narrated full game of every game (Four in a Row, Mühle, Quartett Trumpf, Quartett Sets, Schiffe versenken)
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
  Schiffe O wins in 98 (default fleet of 6 ships: 5, 4, 3, 3, 2, 2). (Deterministic, so the outcome is the same every run unless the engine changes.)
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

## 2. Hot-seat on one device ✅ (P2: KLD-020…026)

Two people take turns on one device. All five games have real screens; each one is played to the end by a scripted widget test.
(A manual run on a real device is still pending.)

### Prerequisites
- [ ] One of: iOS simulator (no 🧑 needed), iPhone/iPad (🧑 trusted, Developer Mode), Android phone (🧑 USB debugging), Chrome.
- [ ] `cd klunki && flutter test` is green.

### Commands
```bash
cd klunki
flutter devices
flutter run -d <simulator-id>          # e.g. iPhone simulator: xcrun simctl list devices available ; open -a Simulator
flutter run --release -d <iphone-id>   # standalone on device
flutter run -d chrome                  # web, hot-seat works there too
```

### Steps
1. The menu **Wähle ein Spiel** lists **4 Gewinnt**, **Mühle**, **Quartett (Trumpf)**, **Quartett (Sets)** and **Schiffe versenken**.
   The three hidden-information games carry the subtitle "Gerät weitergeben". Tap a game.
2. Play. The status line shows "X ist am Zug" (X always starts), with a hint line below it:
   - **4 Gewinnt:** tap a column. The disc drops, and the winning four are highlighted.
   - **Mühle:** "Setze einen Stein" (tap a point), then "Wähle einen Stein zum Ziehen" → "Wähle ein Ziel" ("… zum Springen" with three stones left).
     After a mill: "Mühle! Entferne einen Stein von O".
   - **Quartett (Trumpf):** tap a stat on your top card. The trick is revealed ("X wählt …", with the pot if there is a tie), then tap **Weiter**.
   - **Quartett (Sets):** your hand is grouped by set ("Deine Karten (X)"). "Tippe auf eine fehlende Karte, um danach zu fragen",
     then **Weiter** and pass the device. Completed quartets are shown per player.
   - **Schiffe versenken:** setup ("Schiff 1 von N · X stellt auf"): tap the sea to place each ship, toggle **Horizontal**/**Vertikal**,
     or use **Zufällig**. Battle: "Tippe auf ein unbekanntes Feld im Gegner-Meer, um zu schießen" ("Treffer! Nochmal …" after a hit).
3. **Handover (Quartett Trumpf, Quartett Sets, Schiffe):** whenever the turn passes to the other player, a full-screen cover
   "Gib das Gerät an O weiter" hides everything. The next player taps **Ich bin O – weiter**. The other player's cards or fleet are never visible.
4. At the end the result dialog shows "X gewinnt!" or "Unentschieden" plus the reason, with **Nochmal** (new game) or **Menü**.
   The app bar has **Zug zurück** (undo), **Neues Spiel** ("Neues Spiel?" → **Neu starten**) and **Züge** (move history).

### What the audience sees
- Suggested order (fast to slow): 4 Gewinnt → Mühle → Quartett (Trumpf) → Schiffe versenken (use **Zufällig** for setup) → Quartett (Sets).
- 4 Gewinnt and Mühle: both players on the same screen, no cover.
- Quartett and Schiffe: the handover cover between turns shows that the hidden information stays hidden.

### Troubleshooting
- Simulator slow on first launch → start it before the demo (`open -a Simulator`).
- Long game in front of an audience → **Neues Spiel**, or show the scripted run instead: `flutter test test/ui/games/<game>_screen_test.dart`.

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

### Warm-up: two terminals (optional, KLD-031 ✅)
Shows the same protocol without phones (same Mac, or two Macs on one Wi-Fi):
```bash
# terminal 1: the host plays X and moves first
cd packages/klunki_net && dart run klunki_net:klunki host connect4 --port 4747 --name Ada
# terminal 2: 127.0.0.1 on the same Mac, otherwise an IP printed by the host
cd packages/klunki_net && dart run klunki_net:klunki join <ip> 4747 --name Bea
```
- The host prints its IP addresses and a paste-ready `dart run klunki_net:klunki join <ip> <port>` line per address.
- `--seed S` (host only) fixes the deal for Quartett/Schiffe, e.g. `host quartett-trumpf --seed 42`. The guest gets the seed from the host.
- Details (in-game commands, reconnect): see section 1, "Two terminals over the network".

### Automated e2e (no devices)
```bash
# protocol level: "iOS" host vs "Android" guest play Mühle over TCP, incl. reconnect and swapped roles (KLD-037a)
cd packages/klunki_net && dart test test/e2e_muehle_test.dart
# app level: two GameControllers over NetworkTransport play Mühle on loopback, incl. the screens (KLD-037b)
cd klunki && flutter test test/e2e
```
Prefix either one with `KLUNKI_E2E_VERBOSE=1` to print every move, e.g. `KLUNKI_E2E_VERBOSE=1 flutter test test/e2e`.

### Automated tests on simulators (KLD-038c)
The real app on iOS simulators (headless is fine; Simulator.app isn't needed). `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` first.
```bash
cd klunki
# one device: menu, all five games hot-seat to the result dialog, language picker + restart, plugins (~1 min after the build)
flutter test integration_test/app_test.dart -d <sim-id>
#   + screenshots: --dart-define=KLUNKI_SCREENSHOT_DIR=$PWD/build/e2e_screenshots/iphone --dart-define=KLUNKI_SCREENSHOT_PREFIX=iphone
# two simulators: iPhone 18 Pro hosts Mühle, iPad Pro 11-inch (M5) joins by 127.0.0.1, both tap the scripted game → PASS/FAIL
../tool/e2e_ios_sims.sh            # --mdns: the iPad joins via the discovery list instead; --help for options
```
- Logs and screenshots of the two-simulator run: `klunki/build/e2e/` (`host.log`, `guest.log`, `screenshots/`).
- `tool/e2e_android_vs_ios.sh` (iOS host vs Android emulator guest via `10.0.2.2`) is ready but stops with `BLOCKED` until
  🧑 the Android cmdline-tools and licenses are installed (KLD-011/038a).
- `flutter test` (unit/widget) never runs `integration_test/`.

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

The web build plays hot-seat, and it can **join** a game hosted by the iOS/Android app or the `klunki` CLI over WebSocket on the LAN (KLD-054/055, see "Browser spielt gegen iPhone/Terminal" below). A browser cannot host, and browser ↔ browser play is not possible.

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
  → reload → the app still loads and plays (Debug-Konsole and hot-seat).

### Troubleshooting
- **Service worker / install button missing on a phone via `http://<mac-ip>:8080`:** service workers need a **secure context**
  (HTTPS or `localhost`). A LAN IP over HTTP won't register a service worker, so demo the PWA install on the Mac's Chrome at `localhost`.
  A phone install needs HTTPS hosting (🧑 a hosting decision; not part of the PoC).
- **Old version keeps loading:** DevTools → Application → "Clear site data", or bump the service-worker cache version (KLD-010).
- **Blank page:** the server must serve from `build/web` (base href `/`). Check the DevTools console.
- **Text missing or boxes (□) offline:** the web build bundles all fonts it needs (Roboto, Noto Sans Arabic, a
  Noto Sans SC subset, a symbol subset; I18N-07/08), so every locale renders offline, even on a first visit without
  internet. Boxes in Chinese after a string change: rerun `python3 -I tool/update_web_fonts.py subset` (the glyph
  test says so). See `docs/tasks/I18N-07-08-offline-fonts.md`.

### Language check (I18N-06)
With the server running, from the repo root (needs Node ≥ 22 and Firefox; nothing is installed):
```bash
klunki/tool/pwa_i18n_check.sh http://localhost:8080/ /tmp/pwa-i18n online        # all locales render?
klunki/tool/pwa_i18n_check.sh http://localhost:8080/ /tmp/pwa-i18n offline-warm  # installed PWA, then offline
klunki/tool/pwa_i18n_check.sh http://localhost:8080/ /tmp/pwa-i18n offline       # no internet at all
```
It prints `PASS`/`FAIL` per locale (FAIL = app did not boot, or an external request while offline) and writes
`<locale>-menu.png`, `-picker.png`, `-game.png` plus `report.json`. Look at the PNGs for □ boxes or missing text.
A single locale in the browser: `http://localhost:8080/?lang=fr` (not saved).

### Browser spielt gegen iPhone/Terminal (KLD-055)
The PWA joins a **native host** (iPhone/iPad/Android app or the `klunki` CLI) over `ws://` on the same Wi-Fi.
The host listens on TCP 4747 (apps, CLI) and WebSocket 4748 (browsers); a busy port falls back to a free one.

1. Serve the PWA over **http** on the LAN (not https: browsers block `ws://` from https pages):
   ```bash
   cd klunki && flutter build web --release && python3 build/web/pwa_finalize.py
   python3 -m http.server 8080 --bind 0.0.0.0 --directory build/web   # laptop: http://<mac-ip>:8080/
   ```
2. Start a host, either
   - **iPhone/iPad/Android:** Menu → **Über WLAN spielen** → **Hosten** → pick a game. Under
     "Im Browser beitreten" it shows `IP:wsPort` and the `klunki://join?…&w=<wsPort>` link (copy button), or
   - **Terminal:** `cd packages/klunki_net && dart run klunki_net:klunki host connect4` (prints
     `Browsers and WebSocket guests join at ws://<ip>:4748`).
3. In the browser: Menu → **Über WLAN spielen** (join-only: no host tab, no search list) → type `IP`
   (WebSocket port 4748), `IP:port` (the port is the **WebSocket** port), `ws://ip:port`, or paste the
   `klunki://` link → **Verbinden**. Device name defaults to "Browser".
4. Shortcut for links/QR codes: `http://<pwa>/?join=<urlencoded klunki:// link>` opens the join screen and
   connects right away, e.g.
   `http://192.168.1.5:8080/?join=klunki%3A%2F%2Fjoin%3Fh%3D192.168.1.20%26p%3D4747%26w%3D4748`.

What the audience sees: the browser switches to the game with the connection bar
("Du bist O · Gegner: …"); moves cross over instantly; if the host leaves, the browser shows the banner
with **Neu verbinden**.

Troubleshooting: the join error always lists the hints (same Wi-Fi, http not https, host needs a Klunki
version with browser support, i.e. one that shows "Im Browser beitreten" / prints a `ws://` line).
On an https page the join screen warns up front. The service worker does not register over
`http://<lan-ip>` (no secure context), so this mode needs the server reachable, not offline.

### Browser gegen Browser über das Relay (KLD-057)
Two browsers cannot connect to each other directly, so one computer on the Wi-Fi runs the **relay**, which
also serves the PWA. The host stays authoritative; the relay only forwards messages (see
`packages/klunki_net/PROTOCOL.md`, "Relay").

1. Build the PWA and start relay + web server in one process (any free port; 8080 is just an example):
   ```bash
   cd klunki && flutter build web --release && python3 build/web/pwa_finalize.py && cd ..
   cd packages/klunki_net && dart run klunki_net:klunki relay --port 8080 --web ../../klunki/build/web
   # prints: Klunki relay listening on port 8080: ws://<mac-ip>:8080/relay
   #         Serving the PWA from …: http://<mac-ip>:8080/
   ```
2. **Once the UI exists (KLD-057b, open):** browser A opens `http://<mac-ip>:8080/` → **Spiel hosten** →
   picks a game and shows a room code like `K7Q2M`; browser B opens the same address → enters the code →
   joins. The PWA uses its own origin as the relay (`ws://<location.host>/relay`).
3. **Today (CLI vs CLI through the relay):** in two more terminals
   ```bash
   cd packages/klunki_net
   dart run klunki_net:klunki host connect4 --relay ws://127.0.0.1:8080 --name Ada
   # prints: Room code: K7Q2M  and the join command
   dart run klunki_net:klunki join --relay ws://127.0.0.1:8080 --room k7q2m --name Bea
   ```
   The code is case-insensitive; the relay address may omit `/relay`. Without `--port`, the relay uses 4749.

What to check: the host terminal prints "Bea joined", moves cross over in both directions; quitting the
host closes the room ("Opponent left"). Stop the relay with Ctrl+C.

Troubleshooting: "relay: no room with code …" = typo or the host is gone (rooms also expire after
10 minutes without traffic); "relay: room … is full" = someone already joined (a guest whose Wi-Fi dropped
can rejoin after about 10 s). Use `http://`, not https, and keep the relay reachable (same Wi-Fi).

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
