# KLD-107: Sink the Fleet setup: next-ship preview, dock and discoverable turning

- **ID:** `KLD-107`
- **Title:** Schiffe setup UX (step 1 of the maintainer's device feedback)
- **Milestone:** M4 (polish)
- **Status:** DONE (awaiting maintainer review of the screenshots)
- **Depends on:** KLD-068 (placement editor), KLD-103 (player names)
- **Touched paths:**
  - `klunki/lib/ui/games/schiffe/{schiffe_setup,schiffe_grid,schiffe_draft}.dart`
  - `klunki/lib/profile/seen_tips.dart` (new: one-time tips per install)
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
   - short hint lines (at most 2 lines on a 375 pt phone): "Tippe aufs Meer, um das Schiff zu setzen." /
     "Tippe aufs Meer für das nächste Schiff. Schiff antippen zum Verschieben oder Drehen." / selected:
     "Kreuzer (4) ausgewählt: ziehen zum Verschieben, nochmal antippen zum Drehen." / complete: "Flotte steht.
     Schiff antippen zum Verschieben oder Drehen – oder „Fertig“." (No ↻ character in the texts: U+21BB is in
     none of the bundled fonts and the subset rebuild needs a download.)
   - a **↻ badge** on the middle cell of the selected ship only. Every tap on the selected ship (badge or any
     other cell) and "Drehen" now turn it **around its middle** (before: around the tapped cell / the first
     cell); other cells are still tried if the middle does not fit. The badge spins a quarter on each turn;
     no room: unchanged, shake + "Drehen geht hier nicht – zu wenig Platz."
   - a **one-time tip bubble** ("Antippen: verschieben oder drehen") next to the first ship placed from the
     harbour, gone with the next touch; **once per install** (`SeenTips`, shared_preferences key `seenTips`).
4. **Dock** (phone): all 6 ships as small shapes in one row (no scrolling), placed ones ticked and faded, the
   active one outlined; tap a waiting ship to make it the next one, right under the board (spare height on
   tall phones goes above the action row instead of around the board). Tablets keep the named list.
   **"Fertig"** says why it is off: second line "noch 3 Schiffe".
5. Hot-seat (cover) and network (private draft) unchanged; the board stays LTR in ar/fa as before.

## Acceptance criteria
- [x] Preview shows the next ship and its orientation; "Drehen" and a tap on the box turn it (animated).
- [x] Ghost green/red while the finger is down; tap still places.
- [x] Hint line, ↻ badge on the selected ship (turns in place; invalid: shake + reason), one-time tip.
- [x] Dock with placed/unplaced state, tap selects; "Fertig" disabled with the count.
- [x] 7 locales, RTL screenshot; zh only uses glyphs of the bundled subset (no font rebuild needed).
- [x] Widget tests; screenshots small/large iPhone, iPad portrait/landscape, dark, Arabic.

## Maintainer decisions (review 1)
- Tip once per install; keep one-tap placement (no confirm tap); every turn around the middle; the smaller
  board on a 375×667 phone is fine; hints at most 2 lines; no gap around the board on tall phones.
