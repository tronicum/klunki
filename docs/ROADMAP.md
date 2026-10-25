# Klunki — Roadmap

The PoC proves one engine runs everywhere: in a terminal, on one device, and
between two devices (iPhone ↔ iPad, then Android ↔ iOS). Each stage ends with
a demo you can watch.

**Test devices:** one Android phone, one iPhone, one iPad. The Android emulator
(AVD `Medium_Phone_API_37.0`) is used only for the automated simulator e2e (KLD-038a).

PoC games: **4 Gewinnt**, **Mühle**, **Quartett** (two modes: *Trumpf* and
*Sets*) and **Schiffe versenken**.

## Done — engine foundation
- [x] Monorepo scaffold: `packages/klunki_engine`, `klunki/` app, `docs/`.
- [x] Connect Four engine + tests (incl. gap-fill win and bottom-row-draw regressions).
- [x] Mühle engine + tests (24 points, 16 mills, placing → moving → flying, removal step, 50-move draw).
- [x] Shared `Game` contract test (`test/game_contract_test.dart`).
- [x] Text debug frontend: `DebugConsole` (pure Dart) used by the CLI
      (`dart run bin/klunki.dart`) and the in-app "Debug-Konsole" (non-release builds).

## P1 — Text demo of all games
Goal: every game playable to the end as text, in the terminal and in the app's Debug-Konsole.
- [x] **Quartett engine, both modes** (KLD-004), one shared deck:
  - Built-in demo deck: 32 cards = 8 sets × 4 (A1…H4), each card with 5 numeric
    stats and a per-stat "higher wins / lower wins" rule.
  - Seeded shuffle (`QuartettGame(mode, seed:)`) so a deal can be reproduced and replayed.
  - **Trumpf** (Auto-Quartett / Supertrumpf): both top cards meet, the active
    player picks a stat, the better value takes both cards. Tie → cards go to a
    pot, the same player picks again. Whoever wins the trick picks next. Lose
    when out of cards; after 200 tricks the player with more cards wins (or a draw).
    Move: `{'action': 'pick', 'stat': id}`.
  - **Sets** (classic Quartett): all cards are dealt. The active player asks for
    a specific card from a set they hold at least one card of. If the opponent
    has it, the card moves over and the player asks again; otherwise the turn
    passes. A complete set of 4 is laid down automatically. Ends when all 8 sets
    are down; more quartets wins, 4:4 is a draw.
    Move: `{'action': 'ask', 'card': 'B3'}`.
  - Both expose `handOf(player)` and the face-up state, so the UI can hide the
    opponent's cards (hot-seat handover, network view).
- [x] Text adapters `quartett-trumpf` and `quartett-sets` (Sets: 8 cards each plus a draw pile;
      with all 32 dealt every ask would hit and player B could never win). The console shows only
      the active player's hand and the opponent's card count.
- [x] **Schiffe versenken engine** (KLD-005): 10×10, fleet 5/4/4/3/3/3/2/2/2/2,
      ships may not touch, a hit earns another shot; setup phase with manual or
      seeded auto placement; `ownGrid` / `targetGrid` views hide the enemy fleet.
- [x] Console: plain-language commentary on every move, `legalMoves` on every
      `TextGame`, new commands `moves`, `auto [n]` (seeded) and `demo [games]`
      (narrated full game per game). Also in the in-app Debug-Konsole menu.
- [x] Remove the Quartett stub and its analyzer warnings.
- **Exit / demo:** `dart run bin/klunki.dart demo` prints a narrated full game of
  each game (Connect Four, Mühle, Quartett Trumpf, Quartett Sets, Schiffe versenken). The same
  works in the app's Debug-Konsole on Android, iOS and web.

## P2 — Hot-seat on one device (was M1)
Goal: all four games playable with real game screens by two people on one device.
- [x] Typed transport matching `docs/ARCHITECTURE.md` (`Player` / move map /
      `GameEvent`); `HotSeatTransport` applies moves through the engine (KLD-020).
- [x] A `GameController` (ChangeNotifier) that the screens and the transports share (KLD-020).
- [x] Shared UI shell: `GameScreen` frame, menu → game routing, placeholder screens that make every
      game playable through legal-move buttons (KLD-021).
- [ ] Screens (KLD-022…026, in progress; Sets after Trumpf): Connect Four (tap a column), Mühle (tap to place/move/remove, mill
      highlight), Quartett Trumpf (card with stats, tap a stat), Quartett Sets
      (hand, pick a card to ask for), Schiffe versenken (fleet placement, own
      grid + target grid, tap to fire).
- [x] Quartett and Schiffe versenken hide information: a "pass the phone to …"
      cover screen between turns — shell part done (`HandoverCover`, KLD-021); per-screen use comes with 024–026.
- [x] Shared result dialog (win/draw + reason), move history, undo, "new game" — shell part done (KLD-021).
      German reason texts: backlog KLD-028.
- [ ] Widget tests: one full scripted game per screen.
- **Exit / demo:** each game played to the end hot-seat on an iOS simulator, Chrome,
  and the Android emulator/phone once KLD-011 is unblocked.

## P3 — Two devices on the same Wi-Fi: iPhone ↔ iPad (was M3)
Goal: iPhone and iPad play every game against each other. iOS first because the
toolchain is ready (Xcode 27.1 installed); there is only one Android phone.
- [x] **`packages/klunki_net`** (pure Dart, `dart:io`, KLD-030): newline-delimited JSON over TCP
      (`KlunkiHost` / `KlunkiGuest`, loopback tests).
  - Messages as built: `hello {role, name, protocol}`, `welcome {config, you, moves, token}`, `move`,
    `accepted`, `rejected`, `ping`/`pong`, `bye`. (The planned separate `snapshot` message became the
    move log inside `welcome`.)
  - **The host is authoritative:** the guest sends a move, the host validates it
    with the engine, then broadcasts `accepted`. Both sides apply accepted moves,
    so their states can't diverge.
  - Reconnect: the guest rejoins with its `token` and gets `welcome` with the config (seed) + move list,
    and replays it, using the same replay idea as the console's `undo`.
- [ ] `NetworkTransport` on top of `klunki_net`, with the same interface as `HotSeatTransport` (KLD-032, in progress).
- [ ] CLI networking: `klunki host <game>` / `klunki join <ip>`, so two terminals
      can play over the network here before any phone is involved. Plus a
      loopback test with two transports in one `dart test`.
- [ ] Pairing screen:
  - The host advertises `_klunki._tcp` via mDNS (Flutter plugin `bonsoir`) and
    the guest picks it from a list.
  - Fallback: the host shows its IP:port and a QR code, and the guest types it in (KLD-033/034).
    Scanning the QR is backlog KLD-052 (camera permissions, needs the user's OK).
- [ ] iOS: `NSLocalNetworkUsageDescription` + `NSBonjourServices` (`_klunki._tcp`) in
      `Info.plist`, local-network permission prompt.
- [ ] Disconnect UX: "opponent left / reconnecting…", resume on reconnect.
- [x] Side quests done: PWA hello world, installable + offline (KLD-010); iOS Simulator hello world (KLD-012a).
- **E2E tests:**
  - [ ] KLD-037a: protocol-level Mühle e2e in `packages/klunki_net/test/e2e_*` — "iOS" host vs "Android" guest over TCP,
        incl. reconnect and swapped roles (in progress).
  - [ ] KLD-037b: app-level e2e in `klunki/test/e2e/**` — two `GameController`s over `NetworkTransport` on loopback play Mühle (after 032).
- **PoC shortcut (accepted):** Quartett replays from the shared seed, so a modified
  client could see the opponent's hand. The UI never shows it. Proper per-player
  views are post-PoC.
- **Exit / demo:** iPhone and iPad play every game to the end, each acting as
  host at least once.

## P4 — Android ↔ iOS (end of PoC)
Goal: the same as P3, across platforms: the Android phone against iPhone or iPad.
- [ ] Android toolchain: Android Studio (approved), one physical phone, no emulator.
- [ ] Android: `INTERNET` permission in the main manifest (today only the debug
      manifest has it); multicast lock + Wi-Fi permissions for discovery.
- [ ] Cross-platform checks: discovery both ways, iOS backgrounding/locking
      mid-game → reconnect.
- **E2E tests:**
  - [ ] KLD-038a: simulator e2e — iOS Simulator app hosts, Android emulator (`Medium_Phone_API_37.0`) joins via `10.0.2.2`,
        both play the Mühle script (`integration_test` + `--dart-define` test mode), `tool/e2e_android_vs_ios.sh` prints PASS/FAIL
        (after 032, 037b and the user's Android cmdline-tools + licenses).
  - [ ] KLD-038b: the same on real devices, iPhone/iPad ↔ Android phone over Wi-Fi, each platform hosting once (after 038a, 011, 012, 040, 035).
- **Exit / end of PoC:** every game (Connect Four, Mühle, Quartett Trumpf,
  Quartett Sets, Schiffe versenken) played to the end Android ↔ iPhone, with each platform hosting
  at least once.

### Prerequisites for P3/P4
iPhone + iPad (Developer Mode, Apple ID in Xcode), 1 Android phone (USB
debugging on), the Mac with Xcode, and a Wi-Fi network without client isolation (guest networks often block phone-to-phone
traffic; a phone hotspot works as a fallback).

## After the PoC
- Polish: theming, onboarding, settings, simple AI opponent.
- PWA: hello world done (KLD-010: installable, own offline service worker). The web build stays
  hot-seat only, since browsers can't open TCP sockets (until the relay, KLD-051).
- Android release signing with the user's own keystore (KLD-053).
- Bluetooth transport (stretch).

## Feature backlog (TODO)
- [ ] **Lobby / game-code discovery**: the host gets a short code (e.g. `KLNK-4821`),
      the guest types it in to join, with no IP or device list needed.
  - Step 1, local and no server: put the code in the mDNS TXT record, and the
    guest's code entry picks the matching host on the same Wi-Fi.
  - Step 2, internet: a small lobby/relay service maps code → session and relays
    the same `klunki_net` messages over WebSocket. This lets players on different
    networks join and makes the PWA/web build networkable too. Needs hosting and
    a privacy/abuse review (code expiry, rate limits).

## Game backlog (TODO)
- (empty; Schiffe versenken moved into the PoC)

---

### Dependency order
P1 → P2 → P3 → P4. Inside P1 the Quartett engine and the console commands can
run in parallel; in P2 the four screens can run in parallel once the controller
exists; `klunki_net` + CLI networking (P3) can start in parallel with P2.
