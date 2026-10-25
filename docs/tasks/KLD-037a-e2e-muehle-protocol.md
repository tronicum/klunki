# KLD-037a — E2E: Android vs iOS Mühle over the local network (protocol level)

- **ID:** `KLD-037a`
- **Title:** Deterministic end-to-end test: iPad (iOS) and Pixel (Android) play the scripted Mühle demo over TCP via `klunki_net`
- **Milestone:** P3
- **Status:** DONE
- **Depends on:** KLD-030 (`klunki_net`), KLD-003 (Mühle engine + `MuehleText`)
- **Touched paths:**
  - `packages/klunki_net/test/e2e_muehle_test.dart` (new)
  - `packages/klunki_net/test/e2e_support.dart` (new)
  - `docs/tasks/KLD-037a-e2e-muehle-protocol.md`

## Goal
One command the user can run at any time shows that two "phones" play a full
Mühle game over the local network and end up in exactly the same state:

```
cd packages/klunki_net && dart test test/e2e_muehle_test.dart
KLUNKI_E2E_VERBOSE=1 dart test test/e2e_muehle_test.dart   # narrated transcript
```

The "iOS device" is `KlunkiHost.start(GameConfig('muehle'), name: 'iPad (iOS)')`
on 127.0.0.1 (ephemeral port) playing X; the "Android device" is
`KlunkiGuest.connect(..., name: 'Pixel (Android)')` playing O. Between them sits
`WifiProxy`, a TCP pass-through that delays each chunk by a seeded 5–20 ms
(order preserved) and can cut all connections without a `bye`. They play
`MuehleText().demoScript` (33 moves, "Zwickmühle", O wins). Each command goes
through `MuehleText.parse` and is submitted by the phone that owns the engine's
`currentPlayer` (host: `submitLocal`, guest: `submit`), so a mill and its
removal come from the same phone.

## Acceptance criteria
- [x] Main test: full script; after every accepted move both phones have identical `moves`, `game.board`, `currentPlayer`, `pendingRemoval` (plus `isOver`/result).
- [x] End: both report O as winner, reason `opponent has fewer than 3 pieces`, 33 moves; both logs equal each other and the parsed script; every `MoveAccepted` seen once, in order, on both sides; no `NetError`.
- [x] Narrated transcript (`[Android → iOS] #22 O 15-16 O moves from 15 to 16. Mill on 16-19-22! …`) from a shadow `MuehleText`, printed only with `KLUNKI_E2E_VERBOSE=1`.
- [x] (a) Wi-Fi drop: the proxy is cut while O owes a removal; a new guest instance rejoins with its token and the snapshot restores the pending removal. A second drop with X to move: the host plays while Android is offline, `reconnect()` resyncs (`Resynced(22)`). The game ends identically.
- [x] (b) Android's out-of-turn move (`not your turn`), illegal moves (occupied/nonexistent point, move while placing, place instead of the owed remove, remove own piece, remove empty point, non-adjacent move in the moving phase) and a move after the end (`game is over`) are rejected; the state on both phones is unchanged each time. The host is held to the same rules.
- [x] (c) Roles swapped: Pixel (Android) hosts as O (`hostPlayer: Player.b`), iPad (iOS) joins as X; same ending.
- [x] Per-test timeout 20 s; the file runs in about 3 s; 5 consecutive runs green; `dart analyze` and the full `dart test` in `packages/klunki_net` green.

## Constraints
- No changes to `lib/` of `klunki_net` or `klunki_engine`; no new dependencies.
- Deterministic: scripted moves, seeded latency; only scheduling varies, never the outcome.

## Hints / context
- `MuehleText` is imported from `package:klunki_engine/debug/muehle_text.dart`.
- `Device` (in `e2e_support.dart`) hides whether a phone is host or guest; `MuehleMatch.step()` plays one scripted move and checks both sides.

## Definition of done
`cd packages/klunki_net && dart analyze && dart test` green, including
`test/e2e_muehle_test.dart`.
