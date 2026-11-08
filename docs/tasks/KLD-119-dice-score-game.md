# KLD-119: Ausgewürfelt (five-dice score-sheet game)

- **ID:** `KLD-119`
- **Title:** **Ausgewürfelt** (en working title "Rolled Out"), id `dicesheet`: the five-dice score-sheet game for 2–4
  players on one device. Keep it generic: never use the brand names of the commercial games in code, ARB strings,
  docs, store texts or commits; say "dice score-sheet game" or "five-dice game".
- **Milestone:** long-term games
- **Status:** step 1 DONE (engine, n-player hot-seat shell, UI, 7 locales, screenshots; 2026-11-08). Next: maintainer
  feedback on the screenshots, then network for 2 (secret seed) and a kids' short game (open questions).
- **Depends on:** KLD-088 (seats, `SeatGame`), KLD-103 (player names), KLD-121 follow-up (`ShakeToRoll`, shake setting)
- **Touched paths:**
  - `packages/klunki_engine/lib/dice_sheet.dart` (new), `lib/debug/dice_sheet_text.dart` (new),
    `lib/{game,registry,compat,klunki_engine,debug}.dart`, `lib/debug/debug_console.dart`
  - `packages/klunki_engine/test/dice_sheet_test.dart` (new), `test/{compat,result_code,word_tiles_seats}_test.dart`
  - `klunki/lib/transport/{game_transport,hot_seat_transport}.dart`, `klunki/lib/game/game_controller.dart` (seats)
  - `klunki/lib/ui/shell/{seat_game_screen,seat_labels}.dart` (new), `klunki/lib/ui/seat_players_dialog.dart` (new),
    `klunki/lib/profile/seat_names.dart` (new), `klunki/lib/ui/shell/game_screen.dart` (`GameShellScope`)
  - `klunki/lib/ui/games/dicesheet/**` (new), `klunki/lib/ui/shell/screen_registry.dart`,
    `klunki/lib/ui/{game_titles,game_visuals,engine_l10n}.dart`, `klunki/lib/app/theme.dart`, `klunki/lib/l10n/**`,
    `klunki/assets/fonts/NotoSansSC/*` (subset regenerated for the new Chinese strings, maintainer OK)
  - `klunki/test/ui/games/dicesheet_{screen,layout}_test.dart`, `klunki/test/game/seat_controller_test.dart`,
    `klunki/test/screenshots/dicesheet_shots_test.dart` (new); `klunki/test/ui/{menu_modes_test,shell/*}.dart`,
    `klunki/test/l10n/translations_test.dart` (the new game in the loops)
  - `docs/tasks/KLD-088-more-players.md`, `docs/tasks/BOARD.md`, `CHANGELOG.md`

## Goal
Each turn a player rolls five dice up to three times, keeping any dice between rolls, then enters the result in one
free box of their score sheet. After 13 rounds the highest total wins. A family game: 2–4 players at one table, so
it is the first Klunki game with more than two players in the app.

## Rules as built (classic)
- **Turn:** up to 3 rolls. The first roll rolls all five dice; before the 2nd and 3rd the player taps dice to keep
  them (they stay, the others are rolled again). After at least one roll the player fills **exactly one empty box**
  with what the dice give there; a box the dice do not fit gets **0** (struck). Then the next player.
- **Upper section:** ones … sixes = the sum of the dice showing that face. **Bonus 35** once the upper boxes add up
  to **63** or more (three of each face).
- **Lower section:** three of a kind and four of a kind = sum of all dice; full house (3 + 2 of two faces) **25**;
  small straight (4 in a row) **30**; large straight (5 in a row) **40**; five of a kind **50**; chance = sum of all
  dice. Without the house rule, five of a kind is not a full house (and of course no straight).
- **End:** after 13 rounds every sheet is full; the highest total wins, equal totals share the place (1, 1, 3, …).
- **House rule "Extra-Fünfer"** (`GameConfig.extraFives`, JSON `extraFives`, written only when on; **off** by
  default): another five of a kind while the five-of-a-kind box holds 50 earns **+100**; and whenever five of a
  kind is rolled with that box already filled (50 or 0) it is a **joker** with a forced choice: the upper box of
  its face if that is empty, else any empty lower box at full value (full house 25, straights 30 / 40), else an
  upper box with 0. A struck five of a kind (0) gives the joker rule but no bonus.
- **Resign:** with 2 players the common resign (the other wins). With 3–4 `{'action': 'resign', 'seat': n}`: that
  seat leaves at any time, the others play on; one left → it wins (`common.resigned`). A seat that left ranks last.
- **Who starts:** seat 0 (the first name in "Wer spielt?").
- **"Zug zurück":** takes back a filled box (a mis-tap) until the next player rolls. A roll is final
  (`GameSpec.undoBarrier`: the dice were seen); undo back to a roll restores its kept dice.

## Engine (`dice_sheet.dart`)
- `DiceSheetGame extends Game implements SeatGame`, 2–4 seats, rules version **1**, registry `maxPlayers: 4`,
  `hiddenInformation: false`. `currentPlayer` throws for seats 2/3 (as the word tile game, KLD-088).
- Moves: `{'action': 'roll', 'keep': [i…]}` (die positions 0–4, sorted, empty on the first roll, not all five) and
  `{'action': 'score', 'box': '<id>'}` with the box ids `ones … sixes, threeKind, fourKind, fullHouse,
  smallStraight, largeStraight, fiveKind, chance`.
- **Deterministic:** dice from `Random(seed)`; every roll draws all five values and uses only those of the rolled
  positions, so the draws never depend on what was kept (an undo plus another keep choice cannot fish for dice).
- `scoreFor`, `allowedBoxes`, `scoreIfFilled` (joker aware), `upperSumOf`, `upperBonusOf`, `extraBonusOf`,
  `totalOf`, `seatResult` (places by total, `score0…3`), `legalMoves`, `toJson`, `debugScriptRolls` (tests and
  screenshots only; a replay rolls from the seed).
- `GameEndReason.dicesheetAllFilled` (`dicesheet.allFilled`, params `a`, `b`; the `SeatResult` has `score0…3`).
- Fingerprint: the box ids and all scores (`DiceSheetGame.gameplayData`) are in the content hash.
- CLI / debug console: `DiceSheetText` (`roll`, `roll 1 3 5` keeps positions 1-based, `score fh` / `fh` / `6s`),
  a simple bot for `auto` / `demo` (keeps the most common face or a run of four).
- Network: the engine plays for 2 seats over the existing protocol, but the app does not offer it
  (`hotSeatOnlyGames`): with the seed known to the guest the dice would be predictable (see open questions).

## App
### n-player hot-seat shell (generic, for the word tile game later)
- `AcceptedMove.seat` (optional; `player.index` by default, so every 2-player transport is unchanged).
- `HotSeatTransport` attributes moves by `SeatGame.seatOfMove` when a game has more than two seats (where
  `playerOf` would throw); `GameController` keeps its turn as an int (`actorSeat` for >2 seats, else the player's
  index): `canAct`, `undo` and the handover logic never call `currentPlayer` on seat 2/3. New `seatGame`,
  `canResignSeats`, `resignSeat(seat)`. Two-player paths unchanged.
- `ui/shell/seat_game_screen.dart` (`SeatGameScreen`): app bar (names, restart, resign "Wer gibt auf?" per seat,
  history by seat, game actions), leave confirmation, turn edge and status pill in the seat colour, hint line, the
  `GameShell` for boards (`GameShellScope` added to `game_screen.dart` so `UndoMoveButton` works), result dialog
  with the ranking (place, trophy, token, name, points, "aufgegeben"), "Nochmal" keeps the player count. No
  handover cover (games without secrets; a hidden-information game needs a seat cover first).
- `ui/shell/seat_labels.dart`: `SeatLabels` / `SeatLabelsScope` / `SeatNamesBuilder`, `seatColor` (blue, orange,
  green, purple after Okabe–Ito, lighter in dark mode), `SeatToken` (colour + number 1–4).
- `ui/seat_players_dialog.dart`: "Wer spielt?" with "Wie viele spielen mit?" (2 · 3 · 4, starts with the last
  choice) and a name field per player; players 1/2 are the two-player store, 3/4 and the count
  `profile/seat_names.dart` (`ExtraSeatNames`); new default names `playerDefaultNameC/D` (de Cleo/Dani, en
  Cleo/Dan, fr Chloé/Damien, es Carla/Diego, zh 小刚/小丽, ar سلمى/كريم, fa سارا/کاوه). The menu uses it for
  `seatGames` (`screen_registry.dart`).

### Ausgewürfelt screen (`ui/games/dicesheet/`)
- Start: options dialog ("Extra-Fünfer (Hausregel)", "Schütteln zum Würfeln") → "Wer spielt?" (count + names).
- Board: the **score sheet** on top as a table with a column per player (pinned header with token, name and
  "Runde 3/13"; pinned totals row; the boxes scroll). In the column of the player to move every empty box shows
  what it would score now as a framed number in the player's colour (a 0 quieter); a tap writes it. Upper boxes
  have a small die; the bonus row shows "41/63" with a progress bar, then "+35". The box filled last is
  highlighted until the next player rolls; the hint says "Anna: 25 bei Full House."
- Below, always on screen: **five dice drawn in Flutter** (shared painter with Mäxchen), tap to keep (lifted,
  framed in the player's colour, lock badge and "behalten"), a short tumble animation and a haptic knock; the
  "Zug zurück" button and the shake hint; the big filled **"Würfeln (noch 2)"** button with three pips (after the
  third roll it says "Feld im Blatt wählen", disabled). **Shake to roll** via `ShakeToRoll` with the shared setting.
- Wide screens (landscape, tablets in landscape): sheet left, dice and button right. Rules dialog ("So geht's").
- Menu tile with the one-device link only (`hotSeatOnlyGames`), own accent colour and illustration.

## Tests
- Engine (`dice_sheet_test.dart`, 27): every box's scoring, roll/keep validation, three rolls, draws independent of
  keep, undo barrier, scoring/striking/refusals, upper bonus, full 2/3/4-seat bot games with replay equality and
  ranking, a seat-2 winner, seat resigns (on/off turn, last one in, ending by full sheets), extra fives (off, on
  with 50, forced joker placement, all lower filled, struck 0), config JSON, debug console.
- App: `dicesheet_screen_test.dart` (roll / keep / un-keep / mis-tap + undo / final roll, three rolls, bonus row,
  **whole games through the real UI with 2 and 4 players** to the ranking and "Nochmal", resign with 4, history,
  rules), `dicesheet_layout_test.dart` (dice, "Würfeln", names and totals fully on screen and tappable without
  scrolling: iPhone SE and 15 Pro at 100 %/130 % text, landscape, iPad, 2 and 4 players),
  `seat_controller_test.dart` (transport/controller by seat, undo, resign), plus the loops over all games
  (menu, resign, quit, undo, l10n smoke in 5 locales).
- Screenshots: `KLUNKI_SHOTS=<dir> flutter test test/screenshots/dicesheet_shots_test.dart --plain-name kld119`.

## Open questions (🧑)
1. English/other titles: en "Rolled Out", fr "Coup de dés", es "A los dados", zh 掷骰计分, ar رمية النرد, fa
   تاس‌بازی (machine choices; native review).
2. Network play for 2: the guest would know the seed and so the dice to come. Use a secret seed with a reveal at the
   end (as Mäxchen) before offering it in the app?
3. Kids' variant: a short game (e.g. only the upper section, or 6 rounds)? "Forced order" mode?
4. Who starts: always the first name, or random from the seed?
5. Extra-Fünfer default off (as decided in the WIP notes): keep?

## Acceptance criteria
- [x] Engine with tests, rules version 1, fingerprint golden, CLI adapter.
- [x] n-player hot-seat shell (seat-based transport/controller, seat screen, names for 2–4) usable by other games.
- [x] UI: dice, keep, roll button with remaining rolls, shake to roll, sheet with suggestions, bonus progress,
      totals, ranking; actions on screen on small phones at 130 % text (layout test).
- [x] Whole games through the real UI with 2 and 4 players; 7 locales; screenshots (phone + tablet, dark, ar).
