# KLD-003 — Mühle (Nine Men's Morris)

- **Milestone:** M0
- **Status:** TODO
- **Depends on:** KLD-001
- **Touched paths:** `packages/klunki_engine/lib/muehle.dart`, test

## Goal
Standard 3x3 grid of nine intersections (12 points), 3 phases
(placement, flight, end) with mill (3-in-a-row) capture. Win when opponent
drops below 3 pieces. Standard German variant: 3 pieces per player is the
minimum to keep playing.

## Acceptance criteria
- [ ] 12 named points, 16 edges (lines through 3 points = mills).
- [ ] Placement phase: put 9 (one each per turn) on empty points.
- [ ] Mill detection and capture (opponent removes one non-milling piece).
- [ ] Flight phase: pieces may move to any empty point.
- [ ] End phase: pieces may only move to *adjacent* empty points.
- [ ] Win when opponent < 3 pieces; stalemate if no legal moves in end phase.
- [ ] Tests: at least one mill + capture, one flight, one draw.

## Definition of done
`dart test muehle_test.dart` passes.
