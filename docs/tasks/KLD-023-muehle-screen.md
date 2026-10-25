# KLD-023 — Mühle screen

- **ID:** `KLD-023`
- **Title:** Mühle screen: board painter, tap to place/move/fly/remove, mill highlight, phase hints
- **Milestone:** P2
- **Status:** DONE
- **Depends on:** KLD-021
- **Touched paths:**
  - `klunki/lib/ui/games/muehle_screen.dart`
  - `klunki/lib/ui/games/muehle/**`
  - `klunki/test/ui/games/muehle*`
  - `docs/tasks/KLD-023-muehle-screen.md`

## Goal
Replace the KLD-021 placeholder with a real Mühle board that you can play
fully by tapping, in hot-seat, inside the shared `GameScreen`.

## Acceptance criteria
- [x] `CustomPainter` draws the three squares and the connecting lines; the 24 points are tappable (`muehle-point-<p>`). X = light stones, O = dark stones.
- [x] Placing: tap an empty point. Moving: tap an own stone (it and its targets from `legalMoves` light up), tap a target; tap the stone again to deselect. Flying: same flow, every empty point is a target.
- [x] After a mill (`pendingRemoval`), the removable opponent stones are marked (red ring + ×); tap one to remove it.
- [x] The newly formed mill line(s) flash (amber, ~1.4 s).
- [x] Player panels show stones in hand / on board / captured ("Geschlagen") and the phase (Setzen / Ziehen / Springen). They sit above the board in portrait and on either side of it in landscape.
- [x] Hints via `setHint`: "Setze einen Stein", "Wähle einen Stein zum Ziehen" / "… zum Springen", "Wähle ein Ziel …", "Mühle! Entferne einen Stein von O"; no hint when the player can't act.
- [x] `describeMove`: "X setzt auf 5", "O zieht 15→16", "X springt 20→9", "O entfernt Stein auf 8".
- [x] Board ignores input when `!controller.canAct`.
- [x] Widget tests: alternate placing, occupied no-op, mill → removal, select/deselect/move, full console `demoScript` by taps → "O gewinnt!".
- [x] Whole `flutter test` green (shell tests fixed in the integration commit; they now drive games via the controller). Previously blocked: two tests in `test/ui/shell/game_screen_test.dart` (outside this card's paths) rely on the placeholder:
  - `menu … opens each` expects `Key('legal-move-0')` in every game screen,
  - `boards can set the hint line` expects the Mühle placeholder hint text.
  Suggested fix (shell owner): skip the `firstMove` check for games with a real screen (or check for a per-game key such as `muehle-point-0`), and test the hint line with another placeholder game or with `'Setze einen Stein'`.

## Design notes
- `muehle/muehle_geometry.dart`: places the points on a 7×7 lattice (derived from the console's `_xs`/`_ys`).
- `muehle/muehle_painter.dart`: board, lines, point dots and the mill flash.
- `muehle/muehle_board.dart`: stateful board (selection, flash `AnimationController`, listens to the controller), `_Point` widgets, `_PlayerPanel`.
- Test keys: `muehle-stone-<p>-X|O`, `muehle-selected-<p>`, `muehle-target-<p>`, `muehle-removable-<p>`, `muehle-panel-X|O`, `muehle-phase-X|O`.
- `describeMuehleMove` tells flying from moving by counting the mover's stones lost before that move (9 − lost == 3).
- The shell applies `setHint` from `build` after the frame, so tests pump twice after a tap.
