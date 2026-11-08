# KLD-119: Dice score-sheet game (five dice, working title)

- **ID:** `KLD-119`
- **Title:** A five-dice score-sheet game in the style of the well-known classic (working title, id `dicesheet`).
  Keep it generic: never use the brand names of the original games in code, ARB strings, docs, store texts or commits;
  say "dice score-sheet game" or "five-dice game". The title gets chosen by the maintainer later.
- **Milestone:** long-term games
- **Status:** TODO (backlog stub, nothing implemented; added 2026-11-02 by the maintainer)
- **Depends on:** KLD-088 (3–4 players) for more than 2 players

## Goal
Each turn a player rolls five dice up to three times, keeping any dice between rolls, then enters the result in one
free box of their score sheet (ones to sixes with an upper-section bonus; three/four of a kind, full house, small and
large straight, five of a kind, chance). After all boxes are filled, the highest total wins.

## Rough scope
- Engine: dice from the seed (deterministic replays), keep/roll moves, box scoring, bonus, the end and ranking.
- No hidden information; hot-seat is natural, network works with the existing protocol for 2 players.
- 2 players first, then 3–4 with KLD-088 (this game is great for families with more players).
- UI: five big dice to tap and keep, roll button with a short animation, score sheet with the possible points for
  every free box shown before choosing.
- Fits the die already in the app icon.

## Open questions
- Title (generic, German, kid-friendly).
- Variants: bonus rules for extra five-of-a-kind, "forced order" mode, short game for kids?

## WIP notes (2026-11-08, stopped before implementation)
Nothing implemented yet; design decided after reading the code, for whoever picks this up:
- **Names:** maintainer ideas "Ausgewürfelt" (recommended) or "Großer Wurf"; earlier proposals Würfelblatt,
  Fünf Würfel, Würfelglück (en: Dice Sheet, Five Dice). Title only in ARB `menuGameDiceSheet`, id `dicesheet`.
- **Engine** `packages/klunki_engine/lib/dice_sheet.dart`: `DiceSheetGame extends Game implements SeatGame`
  (2–4 seats, `maxPlayers: 4`, rules 1), dice from `Random(seed)` like the other engines; each roll draws
  all 5 values and uses only the re-rolled positions, so an undo plus a different keep choice cannot fish
  for better dice. Moves `{'action':'roll','keep':[i…]}` (die indices, empty on the first roll, max 3
  rolls) and `{'action':'score','box':'<id>'}` (boxes ones…sixes, threeKind, fourKind, fullHouse,
  smallStraight, largeStraight, fiveKind, chance; a roll is needed first). 3+ seats resign as
  `{'action':'resign','seat':n}` (as `WordTilesGame`); `currentPlayer` throws for seat 2+ (KLD-088).
  New `GameEndReason.dicesheetAllFilled` (needs a case in `klunki/lib/ui/engine_l10n.dart`).
- **House rule** (off): `GameConfig.extraFives` (JSON `extraFives`, only when on): +100 per extra five of a
  kind when the five-of-a-kind box holds 50, plus the forced joker rule (upper box of that face first,
  else any lower box at full value, else an upper box with 0). Off: five of a kind is not a full house.
- **App blockers found:** `HotSeatTransport.submitSync` (`playerOf`), `GameController` (`canAct`, `_toMove`,
  `undo`) and the whole `GameScreen` read `currentPlayer`, which throws for seat 2+. Plan: `AcceptedMove`
  gets an optional `seat`; transport and controller go by `actorSeat`/`seatOfMove` for `SeatGame`s with
  more than 2 seats (2-player paths unchanged); a new `klunki/lib/ui/shell/seat_game_screen.dart` (seat
  colours/tokens, turn pill, ranking result dialog, own undo button with key `shell-undo`, seat resign
  dialog) instead of widening `GameScreen`; a "Wer spielt?" dialog for 2–4 names (new ARB
  `playerDefaultNameC/D`, a list-based names store next to `HotSeatNamesController`).
- Tests that loop over every game (engine `resign_test`, `result_code_test`, `registry_test`,
  `debug_console_test`; app `game_screen_test`, `menu_modes_test`, `resign_test`, `confirm_quit_test`,
  `undo_move_button_test`, l10n `translations_test`/`rtl_test`) will need the new game considered.
