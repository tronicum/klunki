# Task template (copy to a new file)

> One task card = one self-contained, agent-executable unit.
> An agent should be able to run this card end-to-end **from this file alone**.

- **ID:** `KLD-XXX`
- **Title:** (one line)
- **Milestone:** M?
- **Status:** TODO | IN_PROGRESS | DONE
- **Depends on:** (prior task IDs, or none)
- **Touched paths:**
  - `packages/klunki_engine/lib/...`
  - `klunki/lib/...`

## Goal
(Sentence-able outcome. What does "done" look like, demonstrably?)

## Acceptance criteria
- [ ] ...
- [ ] ...

## Constraints
- No Flutter imports in `klunki_engine`.
- Pure-deterministic engine.
- ...

## Hints / context
(Anything an agent needs that isn't obvious.)

## Definition of done
`dart test` for `klunki_engine` passes; the touched paths are green.
