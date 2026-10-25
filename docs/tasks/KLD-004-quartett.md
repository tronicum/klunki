# KLD-004 — Quartett

- **Milestone:** M1 (or M2)
- **Status:** TODO
- **Depends on:** KLD-001
- **Touched paths:** `packages/klunki_engine/lib/quartett.dart`, test

## Goal
Classic German card-set game. Players ask each other for a card by a shared
attribute; a correct answer grants the card; when a set of 4 is completed the
player "quartettes" and deals again. Simplest implementation: one question at a
time, one ask, one answer.

## Acceptance criteria
- [ ] `Card`, `Attribute` (name + value per card).
- [ ] `Deck` has N cards, `Quartett` of four sharing a set id.
- [ ] A player may ask an opponent for a card by an attribute value.
- [ ] Correct answer → asker takes the card.
- [ ] If a set of 4 is completed, caller may deal again.
- [ ] Game ends when all cards distributed.
- [ ] Tests: at least one successful ask + one quartett + one full game.

## Definition of done
`dart test quartett_test.dart` passes.
