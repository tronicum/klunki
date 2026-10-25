# KLD-005 — Schiffe versenken engine

- **Milestone:** P1
- **Status:** DONE
- **Depends on:** KLD-001
- **Touched paths:** `packages/klunki_engine/lib/schiffe.dart`, `packages/klunki_engine/test/schiffe_test.dart`

## Goal
Classic German Schiffe versenken for 2 players: each player has a 10×10 grid
and a fleet (default 1×5 Schlachtschiff, 1×4 Kreuzer, 2×3 Zerstörer, 2×2 U-Boot = 6 ships, 19 cells; `fleet` stays configurable).
Ships are straight, on the board, no overlap, and must not touch (not even
diagonally). Setup (A then B), then battle (A first); hit/sunk grants another
shot (configurable), miss passes the turn. Sinking all opposing ships wins.

## Acceptance criteria
- [x] `SchiffeGame extends Game` with configurable `fleet` and `extraShotOnHit`; `defaultFleet` and `shipNames` exposed.
- [x] Setup: `place` moves in fleet order (`nextShipIndex`); illegal placements (bounds, overlap, touching) → `null` without state change.
- [x] `autoplace` with a seed fills the remaining fleet deterministically and validly; `SchiffeGame.randomLayout(seed)` helper.
- [x] Battle: `fire` → miss / hit / sunk payload; re-firing a cell → `null`; win when all ships sunk (`reason: 'all ships sunk'`).
- [x] Hidden-information views: `ownGrid(Player)` (`SchiffeCell`) and `targetGrid(Player)` (`ShotMark`), `shipsRemaining`, `phase`.
- [x] `legalMoves`: valid placements of the next ship during setup, unshot cells during battle, empty when over.
- [x] Tests: placement validity, setup order, autoplace determinism/validity, turn rules (both flag values), sunk/win, hidden info, random full games.

## Definition of done
`dart test test/schiffe_test.dart` passes and `dart analyze lib test` reports no issues in the new files.
