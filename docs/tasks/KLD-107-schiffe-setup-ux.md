# KLD-107: Sink the Fleet setup: next-ship preview, dock and discoverable turning

- **ID:** `KLD-107`
- **Title:** Schiffe setup UX (step 1 of the maintainer's device feedback)
- **Milestone:** M4 (polish)
- **Status:** DONE (awaiting maintainer review of the screenshots)
- **Depends on:** KLD-068 (placement editor), KLD-103 (player names)
- **Touched paths:**
  - `klunki/lib/ui/games/schiffe/schiffe_setup.dart`, `klunki/lib/ui/games/schiffe/schiffe_grid.dart`
  - `klunki/lib/l10n/**` (5 new keys, 3 changed texts)
  - `klunki/test/ui/games/schiffe_screen_test.dart`, `klunki/test/l10n/english_ui_test.dart`
  - `klunki/test/screenshots/schiffe_setup_shots_test.dart` (new)

## Goal
Feedback from playing on a phone: it was unclear which ship comes next, what "Drehen" will do, which ships are
still missing, and that placed ships can be moved and turned at all (found only by accident). UI only: no engine,
rules-version or protocol change.

## How placement worked before (KLD-068, unchanged)
- Tap the sea: the active ship (first one in the harbour, or one picked in the harbour list) is placed with its
  top-left cell there, in the orientation of "Drehen". While the finger is down (or the mouse hovers) its
  footprint shows green (fits) or red; sliding the finger moves the footprint, lifting places it.
- Tap a placed ship: selects it (accent outline). Tap it **again**: it turns 90° around the tapped cell (other
  cells tried if that does not fit). "Drehen" turns the selected ship (or switches the orientation of the next
  harbour ship). Drag a placed ship to move it; with a ship selected, a tap on a free cell moves it there.
- Invalid: red flash, the board shakes (not with reduced motion), the reason in the hint line.
- "Zufällig" sets the whole fleet (still editable), anchor = back to the harbour, reset, "Fertig" submits.

## What changed
1. **Next-ship preview** ("next piece" box) left of the ship name: the active ship drawn in its current
   orientation; "Drehen" or a tap on the box turns it with a short quarter-turn animation (none with reduced
   motion); "×2" when more ships of that length wait; a tick once the fleet is complete. When a placed ship is
   selected the box shows that ship. Screen reader: "Vorschau: Kreuzer (4), Vertikal. Tippen dreht es."
2. **Ghost:** the footprint while the finger is down now draws a translucent ship body in green cells
   (red stays a plain tint). Tap-to-place itself is unchanged (no extra confirm tap).
3. **Discoverable turning/moving:**
   - hint line once a ship is placed: "Tippe aufs Meer für das nächste Schiff. Tippe ein gesetztes Schiff an,
     um es zu verschieben oder zu drehen."; selected: "… ziehe es oder tippe ein freies Feld … Tippe es nochmal
     an, um es zu drehen."; complete: "Flotte steht. Tippe ein Schiff an, um es zu verschieben oder zu drehen –
     oder „Fertig“."
   - a **↻ badge** on the middle cell of the selected ship only; tapping it is the existing "tap the selected
     ship again", so it turns the ship in place (around its middle); the badge spins a quarter on each turn; no
     room: unchanged, shake + "Drehen geht hier nicht – zu wenig Platz."
   - a **one-time tip bubble** ("Antippen: verschieben oder drehen") next to the first ship placed from the
     harbour, gone with the next touch; once per player and setup.
4. **Dock** (phone): all 6 ships as small shapes in one row (no scrolling), placed ones ticked and faded, the
   active one outlined; tap a waiting ship to make it the next one. Tablets keep the named list.
   **"Fertig"** says why it is off: second line "noch 3 Schiffe".
5. Hot-seat (cover) and network (private draft) unchanged; the board stays LTR in ar/fa as before.

## Acceptance criteria
- [x] Preview shows the next ship and its orientation; "Drehen" and a tap on the box turn it (animated).
- [x] Ghost green/red while the finger is down; tap still places.
- [x] Hint line, ↻ badge on the selected ship (turns in place; invalid: shake + reason), one-time tip.
- [x] Dock with placed/unplaced state, tap selects; "Fertig" disabled with the count.
- [x] 7 locales, RTL screenshot; zh only uses glyphs of the bundled subset (no font rebuild needed).
- [x] Widget tests; screenshots small/large iPhone, iPad portrait/landscape, dark, Arabic.

## Open questions (maintainer)
- Should the tip bubble be once per app install (saved) instead of once per setup?
- Two-step placement (first tap shows the ghost, second tap confirms) instead of tap-to-place + hold-to-preview?
- Should every tap on the selected ship turn around its middle (like ↻) instead of around the tapped cell?
- The phone header is ~14 px taller; the board on a 375×667 phone shrank a little.
