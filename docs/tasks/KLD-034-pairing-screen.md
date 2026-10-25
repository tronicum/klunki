# KLD-034 — Pairing screen (host / join)

- **ID:** `KLD-034`
- **Title:** Pairing screen: host (shows name, IP, QR) / join (list + manual entry), then start the chosen game over `NetworkTransport`
- **Milestone:** P3 — two devices on the same Wi-Fi (first real devices: iPhone ↔ iPad)
- **Status:** TODO
- **Depends on:** KLD-021 (shell, game routes), KLD-032 (`NetworkTransport`), KLD-033 (`DiscoveryService`, `join_payload`, `local_ip`)
- **Touched paths:**
  - `klunki/lib/ui/pairing/**`
  - `klunki/test/ui/pairing/**`
  - `klunki/lib/ui/menu_screen.dart` (add the entry point to the pairing screen, e.g. a "Zu zweit über WLAN" button)
  - `docs/tasks/KLD-034-pairing-screen.md` (status only)

## Goal
On device 1 you pick "Spiel hosten" + a game. The screen shows the device name, `IP:port` and a QR code, and waits.
On device 2 you pick "Spiel beitreten", tap the host in the list (or type `IP:port`). Both devices then open the
game's screen (KLD-022…026) with a `GameController` on a `NetworkTransport`.

## Repo context — read these first
- `klunki/lib/ui/shell/**` (KLD-021): `GameScreen`, `HandoverCover`, and the single routing helper (e.g. `screenFor(controller)`).
- `klunki/lib/transport/network_transport.dart` (KLD-032), `klunki/lib/game/**` (KLD-020 `GameController`).
- `klunki/lib/net/**` (KLD-033): `DiscoveryService` (`advertise`, `browse`, …), `createDiscovery()` (null on web), `KlunkiHostInfo`,
  join payload `encode`/`tryParse`, local IP helper. A fake discovery for tests.
- `packages/klunki_net/lib/**` (KLD-030): host/guest session creation, default port, `hello {protocol, game, mode, seed}`.
- Engine: `gameSpecs` (id/title) + `GameConfig(gameId, seed:)` from `package:klunki_engine/klunki_engine.dart` (`hide Card`).
- Names may differ from this card. Adapt to the real code, and report contract gaps instead of editing those files.

## Actual API after KLD-020/021 (verified against main @ `c10573c`; overrides the expected contract above)
- `GameScreen(controller:, boardBuilder: (context, controller) => …, describeMove:, title:)`; there is no `board:` parameter.
  Set the hint line with `GameScreen.of(context).setHint('…')` (safe from `build`; `null` hides it).
- `controller.submit(move)` returns `Future<SubmitResult>` (`isAccepted`, `event`, `reason`), not `GameEvent?`.
  `controller.moves` is `List<AcceptedMove>` (`index`, `player`, `move`, `event`). Restart is `controller.restart(seed:)`; there is no `newGame()`.
  Also: `canAct`, `canUndo`, `undo()`, `needsHandover`, `acknowledgeHandover()`, `config`, `transport`.
- Status line text is "X ist am Zug"; result dialog buttons are "Nochmal" / "Menü"; handover button is "Ich bin O – weiter".
  `HandoverCover` keeps the board mounted but `Offstage` (use `skipOffstage: false` only if you need to find offstage widgets).
- Routing: `klunki/lib/ui/shell/screen_registry.dart` (`gameScreens`, `buildGameScreen(controller)`, `openGame(context, id, seed:)`); there is no `screenFor`.
- Stable keys: `shell-status`, `shell-hint`, `shell-undo`, `shell-restart`, `shell-history`, `history-sheet`, `result-dialog`,
  `handover-cover`, `handover-continue`, `menu-<gameId>`. Full list: `docs/tasks/KLD-021-ui-shell.md`.
- Transport interface (`klunki/lib/transport/game_transport.dart`): `config`, `Set<Player> localPlayers`, `game`, `moves`,
  `Stream<AcceptedMove> accepted`, `Future<SubmitResult> submit(move)`, `dispose()`; `RejectReason {notYourTurn, illegal, gameOver, disconnected}`.

## Acceptance criteria
- [ ] `lib/ui/pairing/pairing_screen.dart`: `PairingScreen` with two tabs or buttons, **"Hosten"** and **"Beitreten"**.
- [ ] Host flow: pick a game from `gameSpecs` → random seed → start the `klunki_net` host session on the default port (fall back to port 0
      and show the actual port) → `advertise` → show device name, every candidate IP with port, a QR of the join payload, and "Warte auf Mitspieler…".
      When the guest connects: stop advertising and open `screenFor(GameController(spec, NetworkTransport.host(...)))`. Cancel = close everything.
- [ ] Join flow: a live list from `browse()` (name, game title if in TXT, IP). Tap → connect. A text field accepts `IP`, `IP:port` or a pasted
      `klunki://join?...` payload (via `tryParse`). Connecting shows a spinner and a timeout (10 s), with an error text that has hints
      (same Wi-Fi? guest network? iOS: local network permission allowed?). On `hello`: create `GameConfig` from it and open the game screen.
- [ ] Host = X (`Player.a`), guest = O, unless 030/032 define otherwise. The status line of each device shows "Du bist X/O".
- [ ] Back/leave from the game screen sends `bye` (`dispose()`), and the other side sees "Gegner hat das Spiel verlassen". The full
      disconnect/reconnect UX is KLD-036.
- [ ] Web: `PairingScreen` shows "Netzwerkspiel ist im Browser nicht verfügbar" (`createDiscovery()` == null / `kIsWeb`) and imports nothing from `dart:io`.
- [ ] Widget tests `klunki/test/ui/pairing/`: with the fake discovery and an injected session factory (or real loopback sockets via `tester.runAsync`):
      the host shows IP + QR widget; join lists a fake host; tapping it navigates to the Connect Four screen on both sides; invalid manual input
      shows an error; a timeout shows the hint text.
- [ ] `cd klunki && flutter analyze && flutter test` green; `flutter build web` still compiles.

## Constraints
- Board rules: never install toolchains, download SDK components, accept licenses, sign up for accounts or publish anything without the user's OK.
  No new pub.dev packages here (QR rendering comes from KLD-033's dependency).
- Only touch the paths above. **Entry point:** a menu button "Über WLAN spielen" in `klunki/lib/ui/menu_screen.dart` is needed, but that file is
  **not in this card's paths**. Report the exact snippet (a `Navigator.push` to `PairingScreen`) as a follow-up, or do it only if the caller
  explicitly extends your paths.
- Don't commit unless asked.

## Hints / context
- Device name: there's no plugin for it here. Use `Platform.localHostname` (iOS returns e.g. `Stefans-iPhone.local`) and strip `.local`.
- Inject the dependencies into `PairingScreen` (discovery, session factory) with defaults, so the tests need no platform channels.
- 🧑 Real-device check (after KLD-035/040): iPhone hosts and iPad joins, then swap; later Android ↔ iPhone/iPad. See `docs/DEMO.md`.

## Definition of done
```bash
cd klunki
flutter analyze
flutter test test/ui/pairing/
flutter test
flutter build web
```
All green; card status set to DONE.
