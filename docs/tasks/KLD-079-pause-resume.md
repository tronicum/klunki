# KLD-079: Pause and resume games (hot-seat auto-save, network resume)

- **ID:** `KLD-079`
- **Title:** Pause and resume games (hot-seat auto-save, network resume)
- **Priority:** long-term
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** KLD-071, KLD-072 (stable PRNG), KLD-074
- **Touched paths:** new `klunki/lib/saves/**`, `klunki/lib/ui/menu_screen.dart`, `packages/klunki_net/lib/src/{host,guest}.dart`, `packages/klunki_engine/lib/registry.dart`, `packages/klunki_net/PROTOCOL.md`

## Goal
"Im Zug oder keine Zeit mehr – später weiterspielen". This matters most for chess and the long property and hotel games.

## Acceptance criteria
- [ ] **Hot-seat:**
  - Auto-save `{format, rulesVersion, gameId, seed, moves, names, savedAt}` after every accepted move and on `AppLifecycleState.paused`.
  - A "Fortsetzen" entry in the menu lists the saved games (game, opponent names, date, move count), with delete and rename.
  - Resuming replays the save with `replay(config, moves)`.
- [ ] **Network:**
  - Both sides save the log.
  - To resume, the host hosts the saved game again (`KlunkiHost.start(moves:)` already exists) with the *same* token, and the guest rejoins with that token.
  - Room codes expire, so a relay needs a resumable room secret.
  - Optional `pause` / `pause-ok` messages let both sides agree. This needs a protocol version bump.
- [ ] **Secrecy (KLD-064):**
  - The host must save `_seedSalt`, the per-move salts and its guest log.
  - The guest saves `_steps`, `_startViewHash` and `_seedCommit`, so the end-of-game reveal still verifies.
- [ ] **Storage:**
  - Small JSON per game. `shared_preferences` is enough for short games (on the web it is localStorage, about 5 MB).
  - Long logs need files (`path_provider`, 🧑 OK) or IndexedDB.
  - A schema version and migrations. When the rules version changed and the log no longer replays, show "kann nicht fortgesetzt werden".
- [ ] **Engine gaps:**
  - A `rulesVersion` per `GameSpec`.
  - An engine-owned PRNG (KLD-072), so replays survive SDK updates.
  - Optionally, a cheap snapshot for very long games.
- [ ] What helps today: the deterministic move log plus `GameConfig`. What blocks it today: tokens and salts that live only in memory, relay rooms that expire, and `Random(seed)` stability.

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.
