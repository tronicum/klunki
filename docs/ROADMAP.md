# Klunki — Roadmap

The PoC proves one engine runs everywhere: in a terminal, on one phone, and
between two phones (Android ↔ Android, then Android ↔ iOS). Each stage ends
with a demo you can watch.

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
- [ ] Typed transport matching `docs/ARCHITECTURE.md` (`Player` / move map /
      `GameEvent`); `HotSeatTransport` applies moves through the engine.
- [ ] A `GameController` (ChangeNotifier) that the screens and the transports share.
- [ ] Screens: Connect Four (tap a column), Mühle (tap to place/move/remove, mill
      highlight), Quartett Trumpf (card with stats, tap a stat), Quartett Sets
      (hand, pick a card to ask for), Schiffe versenken (fleet placement, own
      grid + target grid, tap to fire).
- [ ] Quartett and Schiffe versenken hide information: a "pass the phone to …"
      cover screen between turns.
- [ ] Shared result dialog (win/draw + reason), move history, "new game".
- [ ] Widget tests: one full scripted game per screen.
- **Exit / demo:** each game played to the end hot-seat on an Android emulator,
  an iOS simulator and Chrome.

## P3 — Android ↔ Android on the same Wi-Fi (was M3)
Goal: two Android phones play every game against each other.
- [ ] **`packages/klunki_net`** (pure Dart, `dart:io`): newline-delimited JSON over TCP.
  - Messages: `hello {protocol, game, mode, seed}`, `move`, `accepted`,
    `rejected`, `snapshot {moves}`, `ping`, `bye`.
  - **The host is authoritative:** the guest sends a move, the host validates it
    with the engine, then broadcasts `accepted`. Both sides apply accepted moves,
    so their states can't diverge.
  - Reconnect: the guest rejoins and gets a `snapshot` (seed + move list) and
    replays it, using the same replay idea as the console's `undo`.
- [ ] `NetworkTransport` on top of `klunki_net`, with the same interface as `HotSeatTransport`.
- [ ] CLI networking: `klunki host <game>` / `klunki join <ip>`, so two terminals
      can play over the network here before any phone is involved. Plus a
      loopback test with two transports in one `dart test`.
- [ ] Pairing screen:
  - The host advertises `_klunki._tcp` via mDNS (Flutter plugin `bonsoir`) and
    the guest picks it from a list.
  - Fallback: the host shows its IP:port and a QR code, and the guest types or scans it.
- [ ] Android: `INTERNET` permission in the main manifest (today only the debug
      manifest has it); multicast lock for discovery.
- [ ] Disconnect UX: "opponent left / reconnecting…", resume on reconnect.
- **PoC shortcut (accepted):** Quartett replays from the shared seed, so a modified
  client could see the opponent's hand. The UI never shows it. Proper per-player
  views are post-PoC.
- **Exit / demo:** two physical Android phones each play all four games to the
  end, with each phone acting as host at least once.

## P4 — Android ↔ iOS (end of PoC)
Goal: the same as P3, across platforms.
- [ ] iOS toolchain on a physical iPhone: Xcode, signing team (a free Apple ID
      works for 7-day dev builds).
- [ ] `Info.plist`: `NSLocalNetworkUsageDescription` and `NSBonjourServices`
      (`_klunki._tcp`); test the local-network permission prompt flow.
- [ ] Cross-platform checks: discovery both ways, iOS backgrounding/locking
      mid-game → reconnect.
- **Exit / end of PoC:** every game (Connect Four, Mühle, Quartett Trumpf,
  Quartett Sets, Schiffe versenken) played to the end Android ↔ iPhone, with each platform hosting
  at least once.

### Prerequisites for P3/P4
2 Android phones (USB debugging on), 1 iPhone plus a Mac with Xcode, and a Wi-Fi
network without client isolation (guest networks often block phone-to-phone
traffic; a phone hotspot works as a fallback).

## After the PoC
- Polish: theming, onboarding, settings, simple AI opponent.
- PWA build (`flutter build web`, offline service worker). The web build stays
  hot-seat only, since browsers can't open TCP sockets.
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
