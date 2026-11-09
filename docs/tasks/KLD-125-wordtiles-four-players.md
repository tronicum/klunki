# KLD-125: Wortgewandt for 3–4 players on one device

- **ID:** `KLD-125`
- **Title:** Wortgewandt (word tile game, id `wordtiles`) for 2–4 players hot-seat (KLD-088 step 2)
- **Milestone:** long-term games
- **Status:** DONE (2026-11-09): hot-seat 3–4 in the app, live-UI games with 3 and 4 players, screenshots `kld125`,
  7 locales. Open questions for the maintainer below.
- **Depends on:** KLD-094 (Wortgewandt), KLD-088 step 1 (engine for 2–4 seats), KLD-119 (seat shell, seat names,
  seat transport/controller), KLD-124 (player-count chip)
- **Touched paths:**
  - `klunki/lib/ui/games/wordtiles_screen.dart`, `klunki/lib/ui/games/wordtiles/wordtiles_board.dart`
  - `klunki/lib/ui/shell/{seat_game_screen,handover_cover,screen_registry}.dart`, `klunki/lib/ui/seat_players_dialog.dart`
  - `klunki/lib/ui/{engine_l10n,rules/games/wordtiles_rules}.dart`, `klunki/lib/l10n/**` (4 keys)
  - `klunki/test/ui/games/wordtiles_seats_test.dart` (new), `klunki/test/e2e/live_ui/wordtiles_seats_live_test.dart`
    (new), `klunki/test/e2e/live_ui/live_ui_driver.dart` (`UiDevice.controller` finds the seat shell),
    `klunki/test/screenshots/wordtiles_seats_shots_test.dart` (new), `klunki/test/ui/player_count_test.dart`
  - `docs/tasks/{KLD-125-wordtiles-four-players,KLD-088-more-players,BOARD}.md`, `CHANGELOG.md`

## Goal
Wortgewandt can be played by 3 or 4 people passing one device, with the racks kept secret by a cover between every
two players; 2 players play as before (the two-player screen, network included).

## As built
- **Start:** the menu asks "Wer spielt?" with "Wie viele spielen mit?" (2 · 3 · 4, starts with the last choice, shared
  with Ausgewürfelt) and a name field per player (`playerCountGames` in `screen_registry.dart`: Ausgewürfelt and
  Wortgewandt). For Wortgewandt the dialog also has "Zug zurücknehmen erlauben" (as the two-player dialog had,
  `undoFor`) and the pass-the-device hint (`passDevice`). The tile/word-list options come first, as before.
- **2 players** keep `GameScreen` (unchanged, identical to the network game). **3–4 players** play in the seat
  shell (`SeatGameScreen`): status pill and turn edge in the seat colour, "Wer gibt auf?" per seat (the others
  play on), history by seat, "⋮" → "Spielernamen" for the running player count, "Regeln".
- **Handover cover between every player** (`SeatGameScreen` puts the `HandoverCover` below the turn edge for a
  `hiddenInformation` game): "Gib das Gerät an Cleo weiter", the seat token (colour and number), the last turn
  ("Ben: HAUS für 14 Punkte"), "Ich bin Cleo – weiter", and "Zug zurücknehmen" for the player who just moved.
- **Score row:** token (seat colour and number), name and score per seat; when four names do not fit (every
  phone), tokens and scores only (the pill names the player to move; the semantics label keeps the names);
  scaled down only if even that does not fit. The rack deduction "(−7)" next to the score at the end.
- **"Trotzdem zulassen" (word list on), hot-seat with 3–4:** the whole table decides together at the device
  (the dialog already says "Seid ihr euch einig …"); the engine logs the agreement as the answer of the **next
  player still in** (`requestAllowMoveFor(seat)` + `acceptAllowMoveFor(allowRequestAnswerer)`, the engine's rule
  from KLD-088 step 1). No second dialog. Should a request ever be open on screen (e.g. after an undo), the
  answer dialog comes up for that seat on this device.
- **Anzweifeln (no word list):** only the next player may challenge (engine rule, unchanged); the rules page
  says so now ("Anzweifeln kann nur, wer als Nächstes dran ist.").
- **Result:** the seat shell's ranking (place, trophy, token, name, points; shared places; seats that resigned
  last) with the rack deduction under each name ("Reststeine: −2", digits kept LTR in ar/fa), then the best word
  and the words let stand (`WordTilesResult(scores: false)`); the reason without a score ("Alle Steine gelegt" /
  "8 Züge ohne Punkte", 2 new keys; the 2-player reason with "Endstand a : b" is unchanged). "Nochmal" keeps the
  player count and the options.
- **Rules page:** a line "Zu zweit, zu dritt oder zu viert an einem Gerät: Ihr seid reihum dran. In einem Raum
  spielt ihr zu zweit." and the challenge line; the pass limit shows the game's own limit (6, or 8 with 4).
- **Player-count chip** (KLD-124): "2–4" on the menu tile and the rules page.
- **Bench, zoom, joker swap, "Restpunkte abziehen", the bench coach:** per seat as before (the bench is kept per
  seat across turns); checked in the live-UI games (bench, zoom on an iPhone SE, challenges, swaps, passes).
- A board squeezed to nothing (huge text on a tiny phone) draws nothing instead of failing on negative sizes.

### Network stays 2 players
Rooms ("Raum starten", the relay host) never offer 3–4: they build `GameConfig` without `players` (2), the engine
and the protocol refuse 3–4 over the network (KLD-088 step 1). n-player network is KLD-088 step 4.

### Rules version / fingerprint
No engine change: `rulesVersion` stays 5, the fingerprint goldens are unchanged, and a 2-player config is the same
JSON as before (`players` is written only when not 2). 2-player network compatibility is untouched.

## Acceptance criteria
- [x] 3 and 4 players from the menu ("Wer spielt?" with the count), names for every seat, the handover cover
      before every player's turn.
- [x] Score row, turn pill, result ranking with ties and rack deduction, resign by seat, undo, zoom, bench, joker
      swap, "Trotzdem zulassen", challenge: checked with 3–4 seats on a phone (iPhone SE, 320 px) and in Arabic.
- [x] Live-UI: a 3-player game (German word list: allow, swap, pass, to the end, "Nochmal") and a 4-player game
      on an iPhone SE (zoom, bench, challenges) through the real UI.
- [x] Screenshots `kld125` (de phone light; SE, ar, dark for the checks).
- [x] 7 locales (4 new keys), no rules-version change, network stays 2-player.

## Tests
- `klunki/test/ui/games/wordtiles_seats_test.dart` (11): cover before every seat, undo on the cover, four seats in
  one row (SE, 320 px, ar), scoreless end with the ranking and rack notes, resign by seat, allow by the table,
  menu start with 4 and 2 players, config JSON.
- `klunki/test/e2e/live_ui/wordtiles_seats_live_test.dart` (2 whole games).
- Screenshots: `KLUNKI_SHOTS=<dir> flutter test test/screenshots/wordtiles_seats_shots_test.dart --plain-name kld125`.

## Open questions (🧑)
1. **"Trotzdem zulassen" with 3–4:** the whole table agrees at the device, logged as the next player's answer
   (built). Or should one named player decide (the next one, "Ben, lässt du es zu?"), or a majority?
2. **Score row with 4 on a phone:** tokens and scores only (built), or two rows of two with names?
3. **Rank note wording:** "Reststeine: −2" under each name (as the two-player summary), or a column?
