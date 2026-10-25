# KLD-037b — App-level e2e: two GameControllers over NetworkTransport on loopback play Mühle

- **ID:** `KLD-037b`
- **Title:** `flutter test` that runs a full Mühle game between two `GameController`s connected through `NetworkTransport` over `127.0.0.1`
- **Milestone:** P3 — iPhone ↔ iPad over Wi-Fi (e2e test plan)
- **Status:** DONE
- **Depends on:** KLD-032 (`klunki/lib/transport/network_transport.dart`), KLD-030 (`packages/klunki_net`, done)
- **Touched paths:**
  - `klunki/test/e2e/**`
  - `docs/tasks/KLD-037b-app-e2e-loopback.md` (status only)

## Goal
One test file proves the app's network stack end-to-end without any device: a host controller and a guest controller,
each with its own `NetworkTransport`, play a scripted Mühle game to the end over a real TCP socket on loopback, and both
end in the identical state. A second test drops the guest mid-game, rejoins, and finishes.

## Repo context — read first
- `klunki/lib/game/game_controller.dart`: `GameController(GameTransport transport)`, `submit(move)` → `Future<SubmitResult>`,
  `game`, `moves` (`List<AcceptedMove>`), `canAct`, `lastEvent`.
- `klunki/lib/transport/game_transport.dart` (interface) and `klunki/lib/transport/network_transport.dart` (KLD-032; read its
  constructors — expected something like `NetworkTransport.host(KlunkiHost)` / `NetworkTransport.guest(KlunkiGuest)`).
- `packages/klunki_net/lib/klunki_net.dart`: `KlunkiHost.start(GameConfig, port: 0, hostPlayer: Player.a)` (read `host.port`
  afterwards), `KlunkiGuest.connect('127.0.0.1', port, token: …)`. Wire messages: `hello`, `welcome {config, you, moves, token}`,
  `move`, `accepted`, `rejected`, `ping`/`pong`, `bye`. Rejoin = connect again with the `token` from the first `welcome`.
- Mühle moves come from `MuehleGame.legalMoves` (`package:klunki_engine/klunki_engine.dart`, `hide Card` is not needed in a pure test
  unless you import Material). A deterministic script: always pick the first legal move of the side to move (stops at the
  engine's 50-move draw at the latest), or reuse the scripted game from `packages/klunki_net/test/e2e_*` (KLD-037a) if present.

## Acceptance criteria
- [x] `klunki/test/e2e/muehle_network_e2e_test.dart`: host (`Player.a`) + guest (`Player.b`) controllers over loopback; each side
      submits only when `controller.canAct`; the test waits for the other side to receive each move (await the controller's
      notification or poll `moves.length` with a timeout, no fixed sleeps > 50 ms).
- [x] At the end: `host.game.isOver && guest.game.isOver`, equal `result.winner`/`draw`/`reason`, equal move lists
      (`moves.map((m) => m.move)`), equal `game.history.length`.
- [x] A submit by the side not on turn is rejected (`SubmitResult.reason == RejectReason.notYourTurn`) and changes nothing.
- [x] Reconnect test: after ~10 moves close the guest's socket, rejoin with the token, check the rebuilt guest state equals the host's, finish the game.
- [x] Everything closes cleanly in `tearDown` (no pending timers; the test finishes in < 10 s).
- [x] `cd klunki && flutter analyze && flutter test test/e2e` green, and the full `flutter test` stays green.

## Constraints
- Test-only card: no changes under `klunki/lib/**` or `packages/**`. If `NetworkTransport` lacks a hook you need, report the gap.
- Bind to `127.0.0.1` with port 0 (no fixed ports, tests run in parallel).
- No new dependencies.

## Hints / context
- `flutter test` runs on the host VM, so `dart:io` sockets work; use `tester.runAsync` only if you write it as a `testWidgets`. A plain `test()` is simpler here.
- KLD-038a later reuses the same move script on real apps; keep the script in a small helper `klunki/test/e2e/muehle_script.dart`
  (KLD-038a may copy it into `klunki/integration_test/`).

## Definition of done
```bash
cd klunki
flutter analyze
flutter test
```
Both green; acceptance criteria ticked; card status DONE.

## Result
Test-only; no `lib/**` or `packages/**` changes, no new dependencies.

- `klunki/test/e2e/muehle_script.dart`: the 33-move Zwickmühle demo (`MuehleText().demoScript`) as steps
  (command, move map, board points to tap); pure Dart so KLD-038a can copy it.
- `klunki/test/e2e/e2e_support.dart`: `AppStack` ("phone" = `GameController` + `NetworkTransport`), state snapshot,
  `expectInSync`, `until`, seeded `WifiProxy` (5–20 ms per chunk, `cut()` = Wi-Fi loss without `bye`).
- `klunki/test/e2e/muehle_network_e2e_test.dart` (controller layer, through the latency proxy):
  full scripted game (the off-turn device's submit is refused as `notYourTurn` before every move and changes nothing);
  Wi-Fi drop after 21 moves, the host plays #21 while the guest is away, `reconnect()` resyncs, game finishes;
  guest "app restart" after 13 moves (O owes a removal): a fresh `NetworkTransport.join(token:)` + new controller
  rebuilds the identical state and finishes.
- `klunki/test/e2e/muehle_screens_e2e_test.dart` (widget layer): the real `MuehleScreen` for both players side by side
  (two `MaterialApp`s in one tree, sockets in `tester.runAsync`); every move is tapped on `muehle-point-<p>` of the
  device to move; after each move both engines and both rendered boards/status lines are compared; "O gewinnt!" on both
  screens at the end. A second test taps the idle device in placing, removal and moving positions: ignored, nothing changes.

Run:
```bash
cd klunki
flutter test test/e2e
KLUNKI_E2E_VERBOSE=1 flutter test test/e2e   # narrated transcript
```
5 tests, ~3 s wall time per run (5/5 green in a row), each test with a 30 s timeout.
