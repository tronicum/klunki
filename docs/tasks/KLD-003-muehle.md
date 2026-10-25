# KLD-003 — Mühle (Nine Men's Morris)

- **Milestone:** M0
- **Status:** DONE
- **Depends on:** KLD-001
- **Touched paths:** `packages/klunki_engine/lib/muehle.dart`, `packages/klunki_engine/test/muehle_test.dart`

## Goal
Standard German Mühle: 24 points in three nested squares, 32 adjacency edges,
16 mills (three points on one line). Two players with 9 pieces each. Phases per
player: placing → moving (adjacent) → flying (exactly 3 pieces left). Forming a
mill obliges a removal of an opponent piece. Win when the opponent has fewer
than 3 pieces or no legal move; draw after 50 moves without a removal.

## Acceptance criteria
- [ ] 24 points (0–23, documented with an ASCII diagram), static adjacency list,
      the 16 standard mills.
- [ ] `MuehlePhase { placing, moving, flying }` tracked per player:
      `placing` until that player placed all 9; then `moving` (one piece to an
      adjacent empty point); `flying` (any empty point) once that player has
      exactly 3 pieces on the board after placing.
- [ ] Removal is a separate step: forming a new mill sets `pendingRemoval`; the
      same player must remove an opponent piece before the turn passes. Pieces
      in a mill are protected unless all opponent pieces are in mills.
- [ ] Moves: `{'action':'place','to':p}`, `{'action':'move','from':a,'to':b}`
      (moving and flying), `{'action':'remove','at':p}`. Illegal move or any
      move after game over → `null`, no state change.
- [ ] Win when the opponent (after placing all pieces) has < 3 pieces, or has
      no legal move on their turn. Draw after 50 consecutive place/move
      actions (both players) without a removal.
- [ ] Getters: `board` (unmodifiable, length 24), `phaseOf`, `piecesInHand`,
      `piecesOnBoard`, `pendingRemoval`, `legalMoves`, `result` (with reason),
      `history`, `currentPlayer`, `isOver`.
- [ ] `GameEvent.payload`: `{'mill': true}` on a new mill, `{'removed': p}` on
      removal; `winner` / `draw` set on the event that ends the game.
- [ ] Tests: alternating placement, occupied point rejected, mill → removal →
      turn passes, protected mills + all-in-mills exception, transition to
      moving, adjacent-only moves, flying, win by < 3 pieces, win by blocking,
      50-move draw, adjacency symmetry and mill geometry.

## Definition of done
`dart test` and `dart analyze` for `klunki_engine` pass.
