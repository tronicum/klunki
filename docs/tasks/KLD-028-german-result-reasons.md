# KLD-028 — German result reasons in the UI

- **ID:** `KLD-028`
- **Title:** Show `GameResult.reason` in German in the result dialog (engine reasons stay English)
- **Milestone:** P2 polish (backlog)
- **Status:** TODO
- **Depends on:** KLD-021 (done); best after KLD-022…026 are merged
- **Touched paths:**
  - `klunki/lib/ui/shell/result_text.dart` (new)
  - `klunki/lib/ui/shell/game_screen.dart` (one call site in `_showResult`)
  - `klunki/test/ui/shell/result_text_test.dart` (new)
  - `docs/tasks/KLD-028-german-result-reasons.md`

## Goal
The result dialog says e.g. "Vier in einer Reihe" instead of "four in a row". The engine and the text console keep their English
reasons (the console and tests depend on them); the translation lives only in the Flutter app.

## Repo context
- The dialog: `klunki/lib/ui/shell/game_screen.dart` → `_showResult()` shows `Text(r.reason)`.
- All engine reasons today (`grep -rn "_reason = \|reason:" packages/klunki_engine/lib`):
  - Connect Four (`connect4.dart`): `four in a row`, `board full`
  - Mühle (`muehle.dart`): `opponent has fewer than 3 pieces`, `opponent has no legal move`, `<n> moves without a removal` (n = `drawMoveLimit`)
  - Quartett (`quartett.dart`): `both stacks empty`, `opponent has no cards left`, `trick limit reached with equal stacks (a:b)`,
    `trick limit reached, more cards (a:b)`, `all quartets laid down, a:b`, `more quartets (a:b)`
  - Schiffe (`schiffe.dart`): `all ships sunk`

## Acceptance criteria
- [ ] `String germanReason(String reason)` in `result_text.dart`: exact matches plus regex for the parameterised ones (keep the numbers),
      e.g. `vier in einer Reihe`, `Brett voll`, `Gegner hat weniger als 3 Steine`, `Gegner kann nicht mehr ziehen`,
      `50 Züge ohne Schlagen`, `beide Stapel leer`, `Gegner hat keine Karten mehr`, `Stichlimit erreicht, gleich viele Karten (16:16)`,
      `Stichlimit erreicht, mehr Karten (18:14)`, `alle Quartette abgelegt, 4:4`, `mehr Quartette (5:3)`, `alle Schiffe versenkt`.
      Unknown reasons are returned unchanged (never empty, never throw).
- [ ] `_showResult` uses `germanReason(r.reason)`.
- [ ] Unit test covers every reason listed above plus one unknown string. A test that greps the engine sources for new `_reason = '…'`
      literals is optional.
- [ ] `cd klunki && flutter analyze && flutter test` green.

## Constraints
- Don't change the engine's strings (console output and engine tests rely on them). No i18n package for the PoC.

## Definition of done
Green analyze + tests; card status DONE; BOARD row ✅.
