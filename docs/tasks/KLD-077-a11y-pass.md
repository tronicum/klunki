# KLD-077: Accessibility pass: screen reader, keyboard, contrast, target sizes

- **ID:** `KLD-077`
- **Title:** Accessibility pass: screen reader, keyboard, contrast, target sizes
- **Priority:** medium
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** KLD-068 (Schiffe placement), KLD-058b
- **Touched paths:** `klunki/lib/ui/games/**`, `klunki/lib/ui/shell/**`, `klunki/lib/app/theme.dart`, `klunki/lib/l10n/**`, tests

## Goal
Every game can be played to the end with a screen reader, and with a keyboard on the web (REVIEW X1–X8).

## Acceptance criteria
- [ ] Four in a Row: each column describes its contents, and there is a "Brett vorlesen" action.
- [ ] Mill game: selected, target and removable states, with a1–g7 coordinates.
- [ ] Opponent moves, reveals and hits are announced (live region or `SemanticsService.announce`).
- [ ] Cells take focus and react to Enter and Space; digit keys pick Four in a Row columns.
- [ ] Contrast fixes (mill accents in dark mode, the miss dot, the token border); battleship target cells are at least 32 dp on a 360×640 phone; nothing overflows at 2× text.

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.
