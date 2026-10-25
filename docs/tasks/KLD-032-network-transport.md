# KLD-032 — `NetworkTransport` in the app

- **ID:** `KLD-032`
- **Title:** `NetworkTransport` on top of `klunki_net`, same interface as `HotSeatTransport`
- **Milestone:** P3 — two devices on the same Wi-Fi (first real devices: iPhone ↔ iPad)
- **Status:** IN_PROGRESS (an agent is working on it, 2026-10-25)
- **Depends on:** KLD-020 (`GameTransport`, `HotSeatTransport`, `GameController`), KLD-030 (`packages/klunki_net`)
- **Touched paths:**
  - `klunki/lib/transport/network_transport.dart`
  - `klunki/test/transport/network*`
  - `klunki/pubspec.yaml` (only to add the `klunki_net` path dependency: `klunki_net: {path: ../packages/klunki_net}`; KLD-033 edits this file later, sequentially)
  - `docs/tasks/KLD-032-network-transport.md` (status only)

## Goal
A `GameController` (KLD-020) works unchanged whether it gets a `HotSeatTransport` or a `NetworkTransport`. Two
controllers connected via `NetworkTransport` over localhost play a full game in a `flutter test`.

## Repo context
- **Read first:** `klunki/lib/transport/**` and `klunki/lib/game/**` (KLD-020), `packages/klunki_net/lib/**` (KLD-030).
- Expected KLD-020 contract, which may differ slightly (adapt to the real code): typed `GameTransport` matching `docs/ARCHITECTURE.md`:
  ```dart
  abstract class GameTransport {
    Player get self;                      // the local player (hot-seat: whoever is on turn / both)
    Stream<…> get moves;                  // moves/events coming from elsewhere (opponent)
    Future<GameEvent?> submitMove(Map<String, dynamic> move); // null = rejected
    void dispose();
  }
  ```
  `GameController` listens to the transport and exposes `game`, `canAct`, `submit`, `lastEvent`, `moves`, `needsHandover` (false over the network).
- Expected `klunki_net` contract (KLD-030; adapt): host session (authoritative engine; validates guest moves; broadcasts
  `accepted`/`rejected`) and guest session (sends `move`, applies `accepted`). Messages `hello {protocol, game, mode, seed}`, `move`, `accepted`,
  `rejected`, `snapshot {moves}`, `ping`, `bye`. Host = `Player.a` unless 030 says otherwise.
- Engine: `package:klunki_engine/klunki_engine.dart` (`hide Card` in Flutter files) has `GameConfig`, `createGame`, `replay`, `specById`.
  `game.history` contains `Player` enums and is **not JSON-safe**: the wire carries the submitted move maps.

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
- [ ] `NetworkTransport implements GameTransport` with two named constructors or factories, e.g. `NetworkTransport.host(session)` and
      `NetworkTransport.guest(session)`, wrapping 030's sessions. It doesn't open sockets itself; pairing (KLD-034) creates the sessions.
- [ ] `self` is the local player. Local `submitMove` on the host validates with the host engine; on the guest it sends `move` and completes
      with the event when `accepted` arrives, or `null` on `rejected`. A timeout (e.g. 10 s) → error/`null` plus a connection-state signal.
- [ ] Opponent moves arrive on the transport's incoming stream in order. The local engine copy (via the controller) stays in sync:
      after every accepted move both sides' `game.history.length` match.
- [ ] Exposes a simple connection state (`connected` / `disconnected` / `closed`, as a `ValueListenable` or `Stream`) for KLD-034/036.
      No reconnect logic here (that's KLD-036).
- [ ] Moves submitted out of turn are rejected locally without a network round trip.
- [ ] Tests `klunki/test/transport/network_transport_test.dart`, over real loopback sockets (`InternetAddress.loopbackIPv4`, port 0):
  - Connect Four full game host vs guest through two `GameController`s, both see the same winner;
  - Quartett Trumpf with a fixed seed: both sides' `topCard(...)` identical after N moves (same seed + moves = same state);
  - a guest's illegal move → `null`, state unchanged on both sides;
  - `dispose()` sends `bye` and the other side's state goes to `closed`.
  In `testWidgets` use `tester.runAsync` for real sockets; plain `test()` is simpler.
- [ ] `cd klunki && flutter analyze && flutter test` are green.

## Constraints
- Board rules: never install toolchains, download SDK components, accept licenses, sign up for accounts or publish anything without
  the user's OK. `klunki_net` stays pure Dart. Adding `klunki_net` as a **path dependency** in `klunki/pubspec.yaml` is required, but
  `pubspec.yaml` is **not** in this card's paths (KLD-033 owns it in a later wave). If it isn't there yet, report it as a blocker
  (one line: `klunki_net: {path: ../packages/klunki_net}`). Don't edit it yourself.
- Only touch the paths above; don't edit 020/030 code (report gaps). Web: `dart:io` sockets don't exist in browsers. Keep
  `network_transport.dart` out of the web import graph (KLD-034 imports it behind a non-web check), and say so in a doc comment.
- Don't commit unless asked.

## Hints / context
- The host processes its own local moves the same way it processes guest moves. That keeps a single path for "accepted" → apply → notify.
- The controller shouldn't apply the move twice: decide which side applies (the transport's session engine or the controller's `game`),
  following 020's design. Read how `HotSeatTransport` does it and mirror it.

## Definition of done
```bash
cd klunki
flutter analyze
flutter test test/transport/
flutter test
```
All green; card status set to DONE.
