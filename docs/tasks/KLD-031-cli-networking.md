# KLD-031 — Terminal networking: `host` / `join`

- **ID:** `KLD-031`
- **Title:** `klunki host <game>` / `klunki join <ip>`: two terminals play each other through the debug console's text adapters
- **Milestone:** P3 — two devices on the same Wi-Fi (first real devices: iPhone ↔ iPad)
- **Status:** DONE
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

## Result
Two-terminal demo (same Mac; on two Macs use an IP the host prints instead of `127.0.0.1`):
```bash
# terminal 1
cd packages/klunki_net && dart run klunki_net:klunki host connect4 --port 4747 --name Ada
# terminal 2
cd packages/klunki_net && dart run klunki_net:klunki join 127.0.0.1 4747 --name Bea
```
- Usage: `host <game> [--port N] [--seed S] [--name NAME]` (default port 4747, `--port 0` = free port, random seed unless given);
  `join <ip>[:port] [port] [--name NAME]`. Bad args → usage on stderr, exit 64. The host plays X (`Player.a`) and prints
  `Hosting <title> on <ip>:<port>, … — waiting for a guest…`, the game config JSON and ready-to-paste join commands.
- Files: `packages/klunki_net/bin/klunki.dart` (entry point), `packages/klunki_net/lib/src/cli/cli.dart` (`runCli` with
  injectable input/output, used by the tests), `packages/klunki_net/test/cli_test.dart`, `executables: {klunki:}` in
  `packages/klunki_net/pubspec.yaml`.
- Seed hook (engine, debug only): `DebugConsole.forGame(id, game)` wraps an existing `Game` (adapters got an optional
  `game:` parameter / `.forGame` constructor). The CLI keeps its own engine copy from `createGame(config)` and applies every
  accepted move to it, which gives the `GameEvent` for the narration and the exact seeded deal.
- Hidden information: the board is printed only on your own turn (public games also while waiting); `moves` only on your
  turn; the opponent's Schiffe placements are narrated as "X places a ship." without coordinates or the autoplace seed.
- Disconnect: `quit`/EOF → `bye`, the other side prints "Opponent left (…)" and exits 0. A dropped connection: the host
  waits for the guest to rejoin (moves refused meanwhile), the guest prints "Connection to the host lost (…)" and asks
  `Reconnect? [Y/n]`, then resumes via `KlunkiGuest.reconnect()`.
- Tests (in-process host + guest over loopback, plus one `Process.run` of the bin): Connect Four to an X win on both sides,
  out-of-turn refusal, host- and wire-rejected illegal moves, quit, seeded Quartett view, Schiffe redaction, reconnect through a
  TCP proxy that drops the connection, usage/exit 64.
