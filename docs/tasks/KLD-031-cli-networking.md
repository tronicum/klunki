# KLD-031 — Terminal networking: `host` / `join`

- **ID:** `KLD-031`
- **Title:** `klunki host <game>` / `klunki join <ip>`: two terminals play each other through the debug console's text adapters
- **Milestone:** P3 — two devices on the same Wi-Fi (first real devices: iPhone ↔ iPad)
- **Status:** TODO
- **Depends on:** KLD-030 (`packages/klunki_net`: NDJSON protocol, host-authoritative TCP session, replay)
- **Touched paths:**
  - `packages/klunki_net/bin/**`
  - `packages/klunki_net/test/cli*`
  - `docs/tasks/KLD-031-cli-networking.md` (status only)

## Goal
Before any phone is involved, two terminals (same Mac, or two Macs on one Wi-Fi) play any Klunki game against
each other over TCP using `klunki_net`. One runs `host`, the other `join`, and both see the board and the narration.

## Repo context
- Pure-Dart packages: `packages/klunki_engine` (rules, registry, debug console) and `packages/klunki_net` (KLD-030).
- **Read `packages/klunki_net/lib/**` and its tests first.** Expected contract (names may differ; adapt):
  - NDJSON over TCP, messages `hello {protocol, game, mode, seed}`, `move`, `accepted`, `rejected`, `snapshot {moves}`, `ping`, `bye`.
  - A host session (listens on a port, owns the authoritative engine, validates guest moves, broadcasts `accepted`) and a
    guest session (connects, sends `move`, applies `accepted`). Each exposes a stream of accepted moves/events, a way to submit
    the local move, and `close()`.
  - Which `Player` the host is (expected: host = `Player.a`, guest = `Player.b`): use 030's convention.
  - Default port constant: use 030's.
- Engine pieces to reuse (`package:klunki_engine/...`):
  - `registry.dart`: `GameConfig(gameId, seed:)`, `gameSpecs`, `specById`, `createGame`, `replay(config, moves)`
  - `debug.dart`: `DebugConsole.games` (id → `TextGame` factory). `TextGame` has `game`, `render()`, `status()`, `parse(input)`,
    `format(move)`, `narrate(mover, move, event)`, `legalMoves`, `moveHelp`, `mark(player)`.
  - Game ids: `connect4`, `muehle`, `quartett-trumpf`, `quartett-sets`, `schiffe`.
  - Caveat: the `DebugConsole` text adapters create their games with default seeds. For seeded games (Quartett), build the
    `TextGame` and make sure its `game` matches `createGame(config)`: e.g. replay the accepted moves on a fresh adapter, or add the
    seed in a way that stays inside your paths. If an engine change is unavoidable, stop and report it.
  - `game.history` entries contain a `Player` enum and are **not** JSON-safe. Send and keep the **submitted move maps**, not `history`.

## Acceptance criteria
- [ ] `packages/klunki_net/bin/klunki_net.dart` (or another name, documented in the usage text) with:
  - `dart run bin/klunki_net.dart host <game> [--port N] [--seed N]`: prints `Hosting <title> on <ip>:<port> — waiting for a guest…`
    with every non-loopback IPv4 address (`NetworkInterface.list()`);
  - `dart run bin/klunki_net.dart join <ip>[:port]`: connects and prints the game from `hello`;
  - an unknown game or bad args → usage text and exit code 64.
- [ ] Gameplay loop on both sides: on your turn, show `render()` + `status()` + prompt `> `; typed input goes through `TextGame.parse`
      and is sent as a move; `rejected` → "Illegal move" and re-prompt. On the opponent's turn, print "Waiting for <mark>…".
      Every accepted move prints the narration on both terminals.
- [ ] Hidden info: `TextGame.render()` shows the *current player's* private view (Quartett hand, Schiffe own fleet). Each terminal
      may only print the board **while it's that terminal's own turn**, or else a public view. Never print the opponent's hand or fleet.
- [ ] Commands `help`, `moves`, `quit` (sends `bye`; the other side prints "Opponent left" and exits 0).
- [ ] Test `packages/klunki_net/test/cli_test.dart`: starts host and join as `Process`es (or calls the CLI's `main`-level functions
      with injected stdin/stdout streams) on `localhost` with port 0 or a free port. It plays a short scripted Connect Four game to a win
      (host X: 0 0 0 0, guest O: 1 1 1). Both outputs contain "X wins". It also covers a rejected illegal move.
- [ ] `cd packages/klunki_net && dart analyze && dart test` are green.

## Constraints
- Board rules: `klunki_net` and `klunki_engine` stay **pure Dart** (no Flutter). Never install toolchains, download SDK components,
  accept licenses, sign up for accounts or publish anything without the user's OK. No new pub.dev dependencies without the user's OK
  (`args` is optional; plain parsing is fine).
- Only touch the paths above. Changes needed in `klunki_net/lib` or the engine → report them, don't make them.
- macOS may show a firewall prompt ("Allow incoming connections?") for `dart` when hosting on a LAN IP; that's a 🧑 click.
  Tests use loopback only. Don't commit unless asked.

## Hints / context
```bash
# terminal 1
cd packages/klunki_net && dart run bin/klunki_net.dart host connect4
# terminal 2
cd packages/klunki_net && dart run bin/klunki_net.dart join 127.0.0.1
```
- A `pubspec.yaml` `executables: {klunki: klunki_net}` entry would allow `dart run klunki_net:klunki host …`. But `pubspec.yaml` isn't in your
  paths: suggest it in your report.
- **Networked Quartett needs a seed hook:** both terminals must build the same deal. The host picks the seed (or takes `--seed <n>`) and sends it in `hello`; the guest must build its `DebugConsole`/`TextGame` from that seed instead of a random one. If `DebugConsole` has no way to inject the seed, add a small hook in `bin/**` (or report it as a contract gap in `packages/klunki_engine/lib/debug.dart`, which is not in your paths).
- Read stdin with `stdin.transform(utf8.decoder).transform(const LineSplitter())` (async), not `readLineSync`, so incoming network messages aren't blocked.

## Definition of done
```bash
cd packages/klunki_net
dart analyze
dart test
```
Both green; a manual two-terminal game to the end works; card status set to DONE.
