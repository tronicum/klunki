# KLD-081 — GoStrategy: setup on the real board

- **ID:** `KLD-081`
- **Title:** The setup happens on the real 10×10 board (same widget and orientation as play)
- **Milestone:** P3 polish (user feedback from a browser game)
- **Status:** step 1 DONE (code, tests, screenshots); steps 2 and 3 parked, see "Next steps"
- **Depends on:** KLD-058b (GoStrategy screen), KLD-064 (secrecy; the setup move's wire format is unchanged)
- **Touched paths:**
  - `packages/klunki_engine/lib/gostrategy.dart` (`isHome`, `setupIndexOf`, `setupFromSquares`, `setupToSquares`)
  - `packages/klunki_engine/test/gostrategy_test.dart`
  - `klunki/lib/ui/games/gostrategy/gostrategy_board.dart` (setup editor on the board, `GoBoardFrame`, selection ring)
  - `klunki/lib/l10n/*.arb` + generated `app_localizations*.dart` (`goSetupHint`, `goSetupSelected` reworded; `goSetupInvalid` new)
  - `klunki/test/ui/games/gostrategy_screen_test.dart`, `gostrategy_network_test.dart`, `gostrategy_setup_utils.dart` (new),
    `klunki/test/screenshots/screenshots_test.dart`

## User report
"The setup board is different from the game board": pieces arranged in the setup did not seem to appear in the same
place on the board. The user wants the setup on a real board, "so you can already think roughly about game moves".

## Root cause
**No mapping bug.** Verified in code, by a widget probe for X and O, and (separately) in the browser: every piece
lands exactly where the old editor showed it. The chain was consistent:
- old editor (`gostrategy_board.dart`, KLD-058b version, lines 289–294): 4×10 grid, editor row 0 at the top,
  index `i = row * 10 + col`;
- engine `GoStrategyGame.setupSquare` (`gostrategy.dart:177`): A `i → 60 + i`, B `i → 39 − i`, applied in `_setup`
  (`:428`);
- play board turned by 180° for O (`gostrategy_board.dart:560–562`).
For A, editor row 0 is board row 6 (front row) and columns match; for B, index 0 is square 39 (row 3, col 9), which
the turned board draws at display row 6, column 0, the same place as in the editor.

The impression came from the **presentation**: a separate 4×10 strip with a different tile size, no lakes, no
neutral rows, no enemy half, no coordinates and nothing marking the front row, so it could not be related to the
board. A second issue: the selection highlight was drawn **underneath** the piece tile (a border of a box the tile
fills), so a selected piece was nearly invisible, in the setup and in play.

## What changed (step 1)
- **Setup on the board:** `_Setup` now draws the same `GoBoardFrame` and `GoSquareView`s as play, turned for O, with
  the lakes, the neutral rows and the enemy's four rows dimmed and empty (never the enemy setup, also not in
  hot-seat or over the network). Cell keys are the play keys `go-cell-<square>`.
- **Editing:** tap two pieces to swap; **drag & drop** (`Draggable` / `DragTarget`) onto another square of the own
  rows swaps; a valid target lights up green while dragging, anything outside the own four rows (neutral rows,
  lakes, enemy rows) is refused and shown red (and the hint says "Nur deine vier Reihen unten nehmen Figuren
  auf."). "Neu mischen" as before; "Fertig" only when all 40 squares are filled (always true without a tray, kept
  as a guard). Counts/legend panel kept.
- **Single source of truth:** the draft is `Map<int, GoPiece>` keyed by **engine squares**; the setup move is built
  with the new `GoStrategyGame.setupFromSquares(player, placement)` (inverse of `setupSquare` via
  `setupIndexOf`). Wire format unchanged (`{'action': 'setup', 'pieces': [40 ids in setup order]}`), so the KLD-064
  commitments are untouched. A setup taken back by undo returns to the editor with its draft.
- **Coordinates:** files a–j under the board and ranks 1–10 on the left, in setup and play, turned with the board
  (O sees `j…a` and `1` at the top), the same names as `goSquareName` / the move history. Visual only (excluded from
  semantics; every square's label already names it).
- **Selection on top:** a thick amber ring with a dark inner line and a glow drawn **above** the tile, in setup and
  play.

## Rules check (no deviations found, no rule changes)
- Lakes: `{42, 43, 46, 47, 52, 53, 56, 57}` = 0-based rows 4–5, columns 2–3 and 6–7.
- Moves: one step orthogonally onto an empty square or an enemy; no diagonals.
- Scouts: straight any distance over empty squares, stop before lakes and pieces, may attack the piece at the end
  of the line in the same move (engine and UI tests, also on the remote `GoStrategyView`).
- Bombs and the flag never move; the spy beats the marshal only when attacking; only a miner defuses a bomb (and
  takes its square), any other attacker dies; equal ranks both removed; attacking the flag wins.
- Enemy ranks hidden until revealed (fight; house rule kept: a scout that runs more than one square is revealed,
  because the run gives it away).
- Attacking works (user confirmed it "just looks odd"): tapping an own piece, then an adjacent hidden enemy fights;
  regression tests for X, for O on the turned board and for a scout line attack, plus an engine test that
  `targetsFrom` includes hidden enemies on the game and on the redacted view.

## Tests
- Engine: `setupIndexOf`/`isHome`, `setupFromSquares` round trip with a recognisable setup for A and B (flag in the
  corner, bomb beside it, scout on the front right) on exactly the drafted squares, rejection of non-home and
  incomplete placements, unchanged wire format; hidden-enemy targets on game and view.
- Widget (hot-seat): setup on the board (100 squares, lakes, dimmed enemy rows), shuffle, tap swap, refused
  targets, Fertig; drag & drop (valid swap, refused onto neutral/lake/enemy); O's editor shows nothing of X;
  **X and O: every piece on the same displayed cell and engine square after Fertig** (O after one X move on the
  turned board); O's turned coordinates and mirrored squares; selection ring above the tile; attacks on hidden
  pieces (O, scout line).
- Network (two devices over loopback): both arrange a recognisable setup on the board, Fertig, and each device shows
  every piece on the same displayed cell; the host's engine has them on the drafted squares.
- Screenshots (`KLUNKI_SHOTS`): `kld081-setup-X-phone-light`, `kld081-setup-O-phone-light`,
  `kld081-board-X-phone-light`, `kld081-board-O-phone-light`, plus the existing `gostrategy-*` shots.

## Next steps (parked, user wants to go step by step)
- **Step 2: figurative piece art.** Every kind gets its own drawn figure (upright block seen from the player's side,
  a character with headgear and the item it carries: crown for the marshal, sabres for officers, pickaxe for the
  miner, spyglass for the scout, mask for the spy; bomb and flag kept), with the rank as a clearly readable badge
  (never a bare number), the enemy as the block's back with a subtle emblem, shading/bevel like KLD-062; behind one
  `GoPieceArt` abstraction so an external (e.g. CC-BY) set can be swapped in later; the same art on the board, in
  the setup, the armies panel, the fight card and the legend; a "Figuren" legend dialog (name, rank, ability);
  semantics with the localized name and rank; readable at ~30 px; screenshots incl. a legend close-up, light/dark.
- **Step 3: attack marker and preview → confirm.** A distinct attack marker (crosshair / crossed swords plus outline;
  the current red ring is the same red as X's army), "Angriff auf ?" in the hint; then the turn flow: select piece
  and target → preview (ghost piece, arrow, attack crosshair; nothing applied or sent, no fight resolved) → bar
  "Zug bestätigen" / "Abbrechen" → on confirm the move is applied/sent and animates (slide, then the fight
  reveal; reduced motion respected) → hot-seat: the result stays briefly or until "Weiter", then the handover cover
  with the public outcome; network: the turn passes. No undo after execution. Built in the shared shell/handover
  code so Schiffe and Quartett can opt in. Tests: cancel changes nothing and sends nothing, confirm applies,
  attack confirm reveals, network sends nothing before confirm, the hot-seat cover only after confirm, reduced
  motion.
- Optional for step 1 later: a tray ("Leeren" + place piece by piece) on top of the square-keyed draft.
