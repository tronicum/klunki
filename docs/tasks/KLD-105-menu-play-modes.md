# KLD-105 — Clearer play modes on the menu tiles: "Ein Gerät" / "Mit anderen"

- **ID:** `KLD-105`
- **Title:** Two direct links per game tile (hot-seat / room for this game); no "Gerät weitergeben" claim on the tiles
- **Status:** DONE (waiting for the maintainer's screenshot review, step-by-step UX)
- **Depends on:** KLD-062 (menu tiles), KLD-098 (room flow), KLD-103 ("Wer spielt?")
- **Touched paths:**
  - `klunki/lib/ui/menu_screen.dart` (`_GameTile` links, `_PlayLink`, double-start guard; the "Zu zweit an einem Gerät" label above the tiles is gone)
  - `klunki/lib/ui/pairing/pairing_entry*.dart` (`roomStartForGameBuilder`)
  - `klunki/lib/ui/pairing/room_game_choice.dart` (new: game radio list or the fixed game)
  - `klunki/lib/ui/pairing/{pairing_screen,relay_host_screen,web_join_screen}.dart` (`gameId` / `fixedGame`)
  - `klunki/lib/ui/player_name_dialog.dart` (pass-the-device line for hidden-information games)
  - `klunki/lib/l10n/**` (3 new keys after `menuSectionNetwork`; `menuPassDevice`, `menuHiddenInfo`, `menuSectionHotSeat` removed)
  - tests: `test/ui/menu_modes_test.dart` (new), `test/screenshots/menu_modes_shots_test.dart` (new),
    `test/ui/pairing/{pairing_screen,relay}_test.dart`, `test/ui/player_names_test.dart`, `test/l10n/{rtl,english_ui}_test.dart`,
    `test/app/theme_test.dart`, `test/screenshots/screenshots_test.dart`, `integration_test/app_test.dart`

## Why

User feedback: tapping a tile started a hot-seat game right away, and the hidden-information tiles said
"Gerät weitergeben". It was not clear that most games also work with other devices; the "Mit anderen
Geräten spielen" section further down did not connect to the tiles.

## What changed

- Every game tile ends with two links, tinted in the game's accent, outlined, ≥ 48 px high, with an
  icon and a chevron (mirrored in RTL):
  - **"Ein Gerät"** (phone icon, `menu-<id>-local`): the hot-seat start as before (Quartett: deck
    picker, then "Wer spielt?"). Tapping the tile body (`menu-<id>-tile`) does the same: still one click.
  - **"Mit anderen"** (Wi-Fi icon, `menu-<id>-network`): "Raum starten" with this game chosen. Native:
    `PairingScreen(mode: start, gameId: id)`, which shows the game as a small tile instead of the radio
    list (Quartett still picks its deck); with "Raum über ein Relay öffnen" on, the hand-over to
    `RelayHostScreen` keeps the game fixed (`fixedGame`). Web/PWA: `webRoomStartScreen(gameId: id)`, the
    relay room screen with the game fixed. Not shown for `hotSeatOnlyGames` (chess, word tiles).
- The "Mit anderen Geräten spielen" section (Raum starten / Raum beitreten) stays; its "Raum starten"
  still asks for the game.
- No "Gerät weitergeben" and no eye-off badge on the tiles. Instead "Wer spielt?" shows, for
  hidden-information games only, one line: "Ihr gebt das Gerät weiter – was verdeckt ist, bleibt
  geheim." (the handover cover during the game was already there).
- The section label "Zu zweit an einem Gerät" above the tiles was removed: the tiles now offer both ways.
- No double start: while a start runs (dialogs, then the pushed route) further taps on any tile link
  do nothing.

## Wording

"An einem Gerät" wraps to two lines on a 375 pt phone tile (two columns; the label has ~95 px), so the
link says **"Ein Gerät"** / **"Mit anderen"**. en "One device" / "With others", fr "Un appareil" /
"Avec d’autres", es "Un dispositivo" / "Con otros", zh 一台设备 / 和其他人一起 (only characters already in the bundled SC font subset), ar على جهاز واحد / مع الآخرين,
fa روی یک دستگاه / با دیگران. "Un dispositivo" and "Con otros" fit on one line at 375 pt too.

## Acceptance criteria

- [x] Both links on network-capable tiles, only "Ein Gerät" on chess (and word tiles when it becomes a tile).
- [x] "Mit anderen" opens the room flow with the right game (native, relay hand-over, web).
- [x] Tile body tap still starts the local game; "Wer spielt?" first.
- [x] No "Gerät weitergeben" on the tiles; pass-the-device line in "Wer spielt?" for hidden-info games.
- [x] 7 locales, RTL mirrored (icons on the right, chevrons on the left), touch targets ≥ 48 px.
- [x] Screenshots: `KLUNKI_SHOTS=<dir> flutter test test/screenshots/menu_modes_shots_test.dart`
  (small/large iPhone light+dark, iPad, ar and the other locales, room via "Mit anderen", "Wer spielt?").
- [ ] Maintainer review of the screenshots.
