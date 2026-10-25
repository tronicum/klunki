# KLD-026 — Schiffe versenken screen

- **ID:** `KLD-026`
- **Title:** Schiffe versenken screen: fleet placement (preview, rotate, random), own + target grid, tap to fire, hot-seat handover
- **Milestone:** P2
- **Status:** DONE
- **Depends on:** KLD-021 (shell: `GameScreen`, `setHint`, `playerMark`, `HandoverCover`)
- **Touched paths:**
  - `klunki/lib/ui/games/schiffe_screen.dart`
  - `klunki/lib/ui/games/schiffe/**` (new: `schiffe_board.dart`, `schiffe_grid.dart`, `schiffe_describe.dart`)
  - `klunki/test/ui/games/schiffe*` (new: `schiffe_screen_test.dart`)
  - `docs/tasks/KLD-026-schiffe-screen.md`

## Goal
Replace the KLD-021 placeholder with a real two-phase Schiffe versenken board
that plugs into the shell (`GameScreen`) and keeps the public contract
`const SchiffeScreen({super.key, required this.controller})`.

## Acceptance criteria
- [x] **Setup** per player: labelled 10×10 grid (rows A–J, columns 1–10), next ship
      ("Kreuzer (4)", "Schiff 2 von 10"), rotate toggle (`sv-rotate`, Horizontal/Vertikal),
      preview under the finger/mouse — green if the anchor is in `legalMoves` of the next
      ship for the current orientation, red otherwise (overlap, touching, out of bounds);
      lifting the finger (tap or drag-and-release) places. "Zufällig" (`sv-random`) =
      `autoplace` with a random seed. Fleet list with placed / current / remaining status.
- [x] Handover cover (controller `needsHandover`) after X's setup and after O's setup.
- [x] **Battle:** "Gegner" target grid (unknown/miss dot/hit cross/sunk filled + outlined ship)
      and "Dein Meer" own grid (ships + incoming shots, own sunk ships outlined). Tap an
      unknown target cell to fire. "Treffer! Nochmal" banner when the extra shot applies,
      ships remaining for both players, the opponent's last shot.
- [x] Layout: width ≥ 600 → grids side by side (iPad/web); narrower (phone portrait) →
      target grid on top with flex 3, own grid below with flex 2. No vertical scrolling.
- [x] **Secrecy:** only `ownGrid(currentPlayer)` / `targetGrid(currentPlayer)` are rendered.
- [x] `describeMove`: "X schießt auf E5: Treffer" / "Wasser" / "<Schiff> versenkt";
      placements "X platziert ein Schiff", "X platziert 9 Schiffe zufällig" (no coordinates).
- [x] Hint line per phase; all input disabled when `!controller.canAct`.
- [x] Stable keys: `sv-own-<r>-<c>`, `sv-target-<r>-<c>` (on `SchiffeCellView`, which exposes
      `look`/`preview`/`onTap`), `sv-rotate`, `sv-random`; extra: `sv-next-ship`, `sv-fleet-<i>`,
      `sv-remaining`, `sv-extra-shot`, `sv-incoming`; own ship bodies carry `ValueKey('sv-ship')`.
- [x] Widget tests: manual placement (valid + invalid preview, rotate, drag), random placement,
      cover between setups, miss passes turn / hit keeps it, target grid never shows enemy ships,
      full game with random fleets + shots in order → result dialog, phone/wide layouts.
- [x] `flutter analyze` + `flutter test` green.

## Notes
- The shell tests (`test/ui/shell/**`, not touched here) drive every game via `legal-move-0`.
  To keep them green the board puts that key (as a `KeyedSubtree`) on the cell whose tap
  performs the first legal move: setup = anchor of the first valid placement in the current
  orientation, battle = the first unknown target cell. Can be dropped once the shell tests use
  per-game drivers.
- The shell's history sheet prefixes each line with the mark, so a line reads
  "X: X schießt auf E5: Treffer" (the describeMove text follows the spec literally).
