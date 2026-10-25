# KLD-037b — App-level e2e: two GameControllers over NetworkTransport on loopback play Mühle

- **ID:** `KLD-037b`
- **Title:** `flutter test` that runs a full Mühle game between two `GameController`s connected through `NetworkTransport` over `127.0.0.1`
- **Milestone:** P3 — iPhone ↔ iPad over Wi-Fi (e2e test plan)
- **Status:** TODO
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
- [ ] `klunki/test/e2e/muehle_network_e2e_test.dart`: host (`Player.a`) + guest (`Player.b`) controllers over loopback; each side
      submits only when `controller.canAct`; the test waits for the other side to receive each move (await the controller's
      notification or poll `moves.length` with a timeout, no fixed sleeps > 50 ms).
- [ ] At the end: `host.game.isOver && guest.game.isOver`, equal `result.winner`/`draw`/`reason`, equal move lists
      (`moves.map((m) => m.move)`), equal `game.history.length`.
- [ ] A submit by the side not on turn is rejected (`SubmitResult.reason == RejectReason.notYourTurn`) and changes nothing.
- [ ] Reconnect test: after ~10 moves close the guest's socket, rejoin with the token, check the rebuilt guest state equals the host's, finish the game.
- [ ] Everything closes cleanly in `tearDown` (no pending timers; the test finishes in < 10 s).
- [ ] `cd klunki && flutter analyze && flutter test test/e2e` green, and the full `flutter test` stays green.

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
