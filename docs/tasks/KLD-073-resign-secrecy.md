# KLD-073: Resign in hidden-information network games (KLD-065 × KLD-064)

- **ID:** `KLD-073`
- **Title:** Resign in hidden-information network games (KLD-065 × KLD-064)
- **Priority:** high
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** KLD-065, KLD-064
- **Touched paths:** `packages/klunki_engine/lib/{game,*_view,secrecy}.dart`, `packages/klunki_net/lib/src/{host,guest}.dart`, `packages/klunki_net/lib/src/secrecy/**`, `packages/klunki_net/PROTOCOL.md`, tests

## Goal
A resign over the network ends a battleships, card or GoStrategy game on both sides, and the game verifies on the guest (REVIEW "Pending branches", C1). Best done as part of the KLD-065 merge.

## Acceptance criteria
- [ ] Views serialize and restore `resignedBy` (included in `viewHash`), and `isOver` is true after a resign.
- [ ] The guest uses `playerOf(move)` in `_onRedactedAccepted`, `_replaySnapshot` and `_onAccepted`, and the host in `_listen`.
- [ ] Resign moves go through `Redaction.step` unredacted and without a commitment.
- [ ] Tests: host and guest resign in each hidden game, a reconnect after a resign, and `GameVerified`.
- [ ] PROTOCOL.md says v2 and has a resign section. The zh font subset is regenerated, never merged.

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.
