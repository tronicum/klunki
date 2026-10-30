# KLD-030 — `klunki_net`: host-authoritative TCP play

- **ID:** `KLD-030`
- **Title:** Pure-Dart network package: NDJSON protocol over TCP, host-authoritative session, replay sync
- **Milestone:** P3
- **Status:** DONE
- **Depends on:** none (uses the engine registry: `GameConfig`, `createGame`, `replay`)
- **Touched paths:**
  - `packages/klunki_net/**` (new package)
  - `docs/tasks/KLD-030-klunki-net.md`

## Goal
Two devices play any Klunki game (`gameSpecs`) over one TCP connection on a
local network. The package is pure Dart (`dart:io`, `dart:async`,
`dart:convert`, plus `klunki_engine` via path), so the very same code runs in
the terminal, on Android and on iOS. The host's engine is the single source of
truth; the guest runs its own engine but applies only moves the host accepted,
so the two states can't diverge. The app's `NetworkTransport` (KLD-032) and the
CLI (KLD-031) wrap `KlunkiHost` / `KlunkiGuest`.

## Protocol (version 1)
Full reference: `packages/klunki_net/PROTOCOL.md`. Summary:

- One TCP connection; UTF-8, **one JSON object per line** (`\n`-terminated).
- Every message has `type` (string) and `v` (int, protocol version, `1`).
- Handshake: guest → `hello {role: 'guest', name, protocol: 1, token?}`;
  host → `hello {role: 'host', name, protocol: 1}` then
  `welcome {config: GameConfig.toJson(), you: 'a'|'b', moves: [...], token, host}`.
  `you` is the guest's player (host chooses; default host = A, guest = B),
  `moves` is the full accepted move log (= snapshot), `token` identifies the
  guest on reconnect.
- Moves: guest → `move {index, move}` where `index` is the position the move
  would take in the log. Host validates with its engine:
  - `index == log length` and legal → host applies and sends
    `accepted {index, player, move}` (host emits it locally too);
  - otherwise `rejected {index, reason}` (`not your turn`, `illegal move`,
    `game is over`, `stale index`, `index ahead`). State never changes.
  - `index < log length` with the same move by the guest at that index
    (a resend) → the host repeats `accepted` for that index; the guest ignores
    `accepted` for indices it already has (idempotent).
- Host moves: the host applies them and sends `accepted`.
- Keepalive: either side sends `ping` every `pingInterval`; the other answers
  `pong`. Any received line counts as a sign of life; silence longer than
  `timeout` closes the connection (`timedOut`).
- `bye {reason}` ends the session politely; malformed input (not JSON, not an
  object, missing `type`, wrong `v`, unknown/unexpected type, bad fields) →
  `error {message}` and the connection is closed.
- Reconnect: the guest connects again with its `token` (or the same `name`),
  gets a fresh `welcome`, replays `replay(config, moves)` and checks that its own
  log is a prefix of the snapshot. `replay` returning null or a non-prefix log →
  divergence error. A new connection that authenticates replaces a stale one;
  any other second guest gets `error 'session full'`.

## Acceptance criteria
- [x] `packages/klunki_net` with `pubspec.yaml` (path dep on `klunki_engine`, dev dep `test` only), `lib/klunki_net.dart`, `PROTOCOL.md`.
- [x] `KlunkiHost.start(config, {port: 0, name, hostPlayer, address, moves, pingInterval, timeout})` → `port`, `events`, `accepted`, `game`, `moves`, `submitLocal(move)`, `close()`.
- [x] `KlunkiGuest.connect(host, port, {name, token, pingInterval, timeout})` → `config`, `me`, `game`, `moves`, `events`, `accepted`, `submit(move)`, `reconnect()`, `close()`.
- [x] Loopback tests (127.0.0.1, ephemeral ports): handshake; host + guest moves in order (Four in a Row, Schiffe versenken); out-of-turn / illegal rejected without state change; duplicate and stale index; a full random game per `gameSpecs` entry ends identically on both sides; guest disconnect + reconnect resumes from the snapshot; malformed line → `error` + close; ping timeout with a short timeout; second guest refused.
- [x] `dart analyze` and `dart test` green in `packages/klunki_net`; engine tests still green.

## Constraints
- No Flutter imports, no plugins; only `dart:io`/`dart:async`/`dart:convert`.
- Engine and app untouched.
- **Accepted PoC limitation (hidden information):** the welcome snapshot carries
  the seed and the whole move log, so a modified client could reconstruct the
  opponent's Quartett hand or Schiffe fleet. The UI never shows it; proper
  per-player views are post-PoC.
- No encryption or authentication beyond the reconnect token: local Wi-Fi only.

## Hints / context
- `replay(config, moves)` from `klunki_engine/registry.dart` is the sync model.
- `Connect4Game.legalMoves` returns column ints (`{'col': c}` moves); the other
  games return move maps.
- Moves are normalised through `jsonEncode`/`jsonDecode` on the host, so both
  logs hold identical maps.

## Definition of done
`cd packages/klunki_net && dart analyze && dart test` green;
`cd packages/klunki_engine && dart test` still green.
