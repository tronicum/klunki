# KLD-068: Better ship placement in Schiffe versenken

- **ID:** `KLD-068`
- **Title:** Editable fleet layout: "Zufällig" sets everything, then select, move, rotate, remove, reset;
  "Fertig" confirms
- **Milestone:** look & feel / games
- **Status:** DONE
- **Depends on:** KLD-026 (Schiffe screen), KLD-062 (look), KLD-064 (secrecy)
- **Touched paths:**
  - `packages/klunki_engine/lib/schiffe.dart` (helpers: `ShipPlacement.movedTo`, `.rotated(pivot:)`,
    `.indexOf`, `==`/`hashCode`; `SchiffeGame.fitsAmong`, `isValidLayout`, `completeLayout`),
    `packages/klunki_engine/test/schiffe_test.dart`
  - `klunki/lib/ui/games/schiffe/schiffe_setup.dart` (new: the placement screen),
    `schiffe_draft.dart` (new: the local editable layout), `schiffe_board.dart` (setup moved out),
    `schiffe_grid.dart` (`SchiffeCellView.onSemanticTap`, `selected`)
  - `klunki/lib/l10n/*.arb` (+ generated): one block of 15 `schiffe*` keys after `schiffeMoveFire`;
    `schiffeSetupProgress` replaced by `schiffeSetupCount`; Noto Sans SC subset regenerated
  - tests: `klunki/test/ui/games/schiffe_screen_test.dart`, `klunki/test/ui/pairing/pairing_flow_test.dart`,
    `klunki/test/l10n/rtl_test.dart`, `klunki/integration_test/app_test.dart`,
    `klunki/test/screenshots/screenshots_test.dart`

## Problem
Feedback after playing: switching between horizontal and vertical was awkward (a small toggle that only
applied to the *next* ship), and "Zufällig" committed the fleet at once with no way to rearrange it. Every
tap on the sea was already a submitted engine move, so nothing could be changed afterwards.

## Design
The layout is now edited **locally** in a `SchiffeDraft` (slot i = ship i of the fleet, null = still in the
harbour). Nothing is sent before "Fertig"; then the board submits the engine's existing `place` moves in
fleet order (awaiting each one). So the engine rules, the protocol and the KLD-064 redaction stay as they
were: over the network the host still only sees the guest's `place` moves, the guest only `{action: place,
ship: i}` of the host. (The UI no longer uses `autoplace`; the engine and CLI keep it.)

Interaction (`SchiffeSetup`):
- **Zufällig** places the whole fleet at once (all ships that are not locked), with `completeLayout`.
  Tapping it again rolls a new layout. Everything stays editable.
- **Select:** tap a ship (accent outline in the Schiffe teal, also via the harbour list).
- **Move:** drag the ship (it keeps the grabbed cell under the finger, snapping to cells), or tap a free cell
  to move the selected ship there (top-left cell). It stays selected after a move.
- **Rotate:** tap the selected ship again: it turns around the tapped cell; if that does not fit, the other
  cells of the ship are tried as the pivot. The **Drehen** button (↻, shows the current orientation) turns
  the selected ship around its first cell (then the other cells), or switches the orientation for the next
  ship from the harbour.
- **Remove** (anchor icon, "Zurück in den Hafen") puts the selected ship back into the harbour; it stays
  selected so a tap on the sea places it again. **Zurücksetzen** clears the board.
- **Harbour:** a list of all six ships with a small ship drawing; ticked when on the board. Tap one to
  select it. Without a selection the first ship in the harbour is the active one.
- **Live preview:** while hovering (mouse) or dragging, the footprint is green when it fits and red when it
  overlaps, touches or leaves the board.
- **Invalid** move/turn: the attempted footprint flashes red, the board shakes briefly (not with reduced
  motion) and the hint line says why ("Passt dort nicht …" / "Drehen geht hier nicht …").
- **Fertig** is enabled only when all 6 ships are on the board (every edit is validated, so the layout is
  valid) and it is the player's turn.

Modes:
- **Hot-seat:** the draft belongs to the player to move; the existing handover cover hides it after "Fertig".
  The setup widget is keyed by (viewer, transport), so O starts with an empty board and a restart resets.
  After an undo the ships the engine already accepted are **locked** (shown, not editable, kept by
  Zufällig/Zurücksetzen).
- **Network:** only the local player's fleet. The guest can already arrange while the host still places;
  "Fertig" becomes active when it is the guest's turn. A rejected submission shows a hint to tap "Fertig" again.

Look and accessibility: `KlunkiPalette` sea colours and the Schiffe accent; buttons and harbour items are
at least 48 px (the grid cells may be smaller on phones; drag snaps to cells). The grid stays LTR. Cells
read e.g. "A3 Schlachtschiff (5), ausgewählt" and can be tapped by screen readers; the rotate button reads
"Drehen, aktuell Horizontal"; the hint line is a live region.

Engine helpers (pure, tested): `ShipPlacement.movedTo/rotated/indexOf`, value equality,
`SchiffeGame.fitsAmong(p, others)`, `isValidLayout(layout)`, `completeLayout(partial, seed)`.

## Tests
- Engine: rotate pivots, `fitsAmong` (edges, overlap, diagonal touch), `isValidLayout` vs the engine
  accepting the moves, `completeLayout` keeps fixed ships.
- Widgets (`schiffe_screen_test.dart`): random fills all 6 without submitting, "Fertig" submits 6 moves and
  the cover hides X, O starts empty; harbour placement with red/green preview; select + move by tap; drag
  with green/red footprint and refused drop; rotate by second tap and by "Drehen", invalid turn flashes and
  explains; shake vs reduced motion; locked ships after undo; remove to harbour + reset; screen-reader
  labels and taps; phone layout with ≥ 48 px controls.
- Network (`pairing_flow_test.dart`): the guest arranges while the host places ("Fertig" disabled), the
  host confirms, the guest's draft survives, then confirms; the guest sees only redacted `place` moves.
- Screenshots: `KLUNKI_SHOTS=<dir> flutter test test/screenshots` → `schiffe-setup-phone-{light,dark}`,
  `schiffe-drag-{valid,invalid}-phone-{light,dark}`.
