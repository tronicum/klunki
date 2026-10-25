# KLD-027 — Rename the engine's `Card` to `QuartettCard`

- **ID:** `KLD-027`
- **Title:** Rename `Card` (Quartett) to `QuartettCard` in `klunki_engine` and drop every `hide Card` in the app
- **Milestone:** P2 cleanup (backlog)
- **Status:** TODO — **start only after the screen wave (KLD-022…026) is merged**; it touches many files those tasks own
- **Depends on:** KLD-022, 023, 024, 025, 026 merged
- **Touched paths:**
  - `packages/klunki_engine/lib/quartett.dart`, `packages/klunki_engine/lib/klunki_engine.dart`, `packages/klunki_engine/lib/debug/quartett_text.dart`
  - `packages/klunki_engine/test/**`
  - every `klunki/lib/**` and `klunki/test/**` file that imports the engine with `hide Card` (find them with the grep below)
  - `docs/ARCHITECTURE.md` (only if it mentions `Card`), `docs/tasks/KLD-027-rename-quartett-card.md`

## Goal
The engine exports `QuartettCard` instead of `Card`, so Flutter files can import `package:klunki_engine/klunki_engine.dart`
without `hide Card`, and Material's `Card` widget works everywhere. No behaviour change.

## Repo context
- `packages/klunki_engine/lib/quartett.dart`: `class Card { … }` (line ~33), used ~16 times in that file.
- `packages/klunki_engine/lib/klunki_engine.dart`: `export 'quartett.dart' show QuartettGame, QuartettMode, QuartettStat, Card;`
- Find all users: `grep -rnw Card packages klunki/lib klunki/test` and `grep -rn "hide Card" klunki`.
- If KLD-024 added a widget called `QuartettCard` (e.g. in `klunki/lib/ui/games/quartett_card.dart`), the widget keeps a different
  name (`QuartettCardView`); rename the widget first if it collides, and say so in the report.

## Acceptance criteria
- [ ] `class QuartettCard` in the engine; the export line names `QuartettCard`; no `Card` symbol left in `packages/klunki_engine`.
- [ ] No `hide Card` left under `klunki/` (`grep -rn "hide Card" klunki` is empty).
- [ ] JSON / wire format unchanged (cards are referenced by id like `B3`; check `quartett.dart` `toJson` if any).
- [ ] `cd packages/klunki_engine && dart analyze && dart test`, `cd packages/klunki_net && dart analyze && dart test`,
      `cd klunki && flutter analyze && flutter test` all green.

## Constraints
- Pure rename; no logic changes. Engine stays free of Flutter imports. One commit.

## Definition of done
All three packages analyze + test green; card status DONE; BOARD row ✅.
