# KLD-111 — "Mit anderen": start or join from a game tile

- **ID:** `KLD-111`
- **Title:** Mit anderen: start or join from a game tile
- **Status:** DONE (waiting for the maintainer's screenshot review, step-by-step UX)
- **Depends on:** KLD-098 (room flow), KLD-105 (tile links), KLD-108 (blocked network on https)
- **Touched paths:**
  - `klunki/lib/ui/menu_screen.dart` (`_withOthers`, `_RoomChoiceSheet`, `_RoomChoiceButton`)
  - tests: `klunki/test/ui/menu_modes_test.dart`, `klunki/test/ui/web_beta_test.dart`,
    `klunki/test/screenshots/menu_modes_shots_test.dart` (group `kld111`)

## Why

Maintainer feedback: a tile's "Mit anderen" (KLD-105) went straight to "Raum starten" with the game
chosen. Someone whose friend has already started, say, a chess room taps "Mit anderen" on Schach and
ends up starting a room of their own; joining was only possible in the "Mit anderen Geräten spielen"
section further down.

## What changed

- "Mit anderen" on a tile (and the debug preview's "Mit anderen" for Wortgewandt) opens a bottom sheet:
  the game's name, "Mit anderen Geräten spielen" under it, and two full-width entries in the game's
  accent colour (maintainer review 1: start on top and prominent, join below and secondary; the room
  section further down keeps its two side-by-side cards):
  - **"Raum starten"** (filled in the accent, larger title; "Andere kommen mit dem Raumcode dazu", `menu-room-choice-start`): the room
    screen with this game chosen, as before (KLD-105).
  - **"Raum beitreten"** (outlined in the accent; "Code scannen oder eintippen", `menu-room-choice-join`): the same join screen
    as the room section (native: scanner first; web: room code). The game is not passed on: the
    host decides it. No protocol change.
- Closing the sheet (swipe, tap outside, back) goes nowhere; the double-start guard covers the sheet.
- KLD-108: on https without a usable `wss://` relay the link stays greyed out and shows the
  explanation sheet, not the choice.
- The tile tap and "Ein Gerät" (hot-seat, one tap) are unchanged.
- No new strings: the sheet reuses `roomStart`, `roomStartSubtitle`, `roomJoin`, `roomJoinSubtitle`,
  `menuSectionNetwork` and the game titles.

## Acceptance criteria

- [x] Tile "Mit anderen" → sheet titled with the game → "Raum starten" opens the room screen with the game.
- [x] → "Raum beitreten" opens the join screen (no game passed).
- [x] Blocked (https, no wss relay) → explanation sheet, no choice.
- [x] Hot-seat start from the tile unchanged.
- [x] Widget tests; screenshots `KLUNKI_SHOTS=… flutter test test/screenshots/menu_modes_shots_test.dart --plain-name kld111`
  (menu and sheet, de light/dark and ar, 375×667 and 430×932).
