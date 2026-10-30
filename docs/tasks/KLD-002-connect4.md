# KLD-002 — Four in a Row engine

- **Milestone:** M0
- **Status:** DONE
- **Depends on:** KLD-001
- **Touched paths:** `packages/klunki_engine/lib/connect4.dart`, `packages/klunki_engine/test/connect4_test.dart`

## Goal
7×6 board, players drop in a column; first 4-in-a-row wins. Detect win / draw.

## Acceptance criteria
- [ ] State tracks `board[7][6]`, current player, full move history.
- [ ] `applyMove(col)` is legal iff column not full.
- [ ] Win detection in all directions (row, col, both diagonals).
- [ ] Draw detection when no move possible.
- [ ] Tests: at least one win per direction, column-full, and draw case.

## Definition of done
`dart test connect4_test.dart` passes.
