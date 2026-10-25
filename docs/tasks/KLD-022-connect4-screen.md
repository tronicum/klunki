# KLD-022 — Connect Four screen

- **ID:** `KLD-022`
- **Title:** 4 Gewinnt screen: tap a column, drop animation, winning line highlight
- **Milestone:** P2
- **Status:** DONE
- **Depends on:** KLD-021
- **Touched paths:**
  - `klunki/lib/ui/games/connect4_screen.dart`
  - `klunki/lib/ui/games/connect4/**`
  - `klunki/test/ui/games/connect4*`
  - `docs/tasks/KLD-022-connect4-screen.md`

## Goal
Replace the KLD-021 placeholder with a real 4 Gewinnt board inside the shared
`GameScreen`. The public contract stays the same:
`Connect4Screen({super.key, required GameController controller})`.

## Acceptance criteria
- [x] Blue 7×6 board with round holes. X = red, O = yellow, with slightly adjusted colors in dark theme. Empty holes use the theme surface color.
- [x] Tapping anywhere in a column drops a piece. A full column, or `!controller.canAct`, is a no-op (the gesture is disabled).
- [x] Drop animation of about 250 ms (`connect4DropDuration`, easeIn) from above the board to the target row.
- [x] Column highlight while the mouse hovers over it or a finger presses it (only when input is enabled and the column is legal).
- [x] Last move marked with a small dark dot. After a win, the winning four get a white ring and glow and the other pieces fade. The line is computed in the UI (`connect4WinningCells`) from the last move and the board.
- [x] Hint "Tippe auf eine Spalte" while the local player can act, otherwise no hint.
- [x] `describeMove` returns "Spalte N" (1-based). The shell adds the mark, so the history reads "X: Spalte 4".
- [x] Responsive: the cell size fits the available box (max 96 px), and the board is centered.
- [x] Stable keys: `c4-column-<c>` and `c4-cell-<r>-<c>`, where **r is in engine coordinates (row 0 = bottom)**, matching history entries.
- [x] Widget tests in `klunki/test/ui/games/connect4_screen_test.dart`. `flutter analyze` and `flutter test` are green.

## Notes
- Shell compatibility: the temporary `legal-move-<i>` column keys were removed in the integration commit; the shell tests now drive games through the controller.
- Each hole is a public `Connect4Cell` widget (`owner`, `winning`, `lastMove`, `pending`, `faded`), so tests read state without goldens.
- The drop animation runs only when exactly one move was added. Undo and restart jump straight to the new position.
