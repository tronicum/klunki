# KLD-131 – Rauswurf (cross-and-circle race game)

- **ID:** `KLD-131`
- **Title:** Rauswurf: the classic race game with four pawns per player (id `ludo`, en "Ludo")
- **Milestone:** M5 (more games)
- **Status:** IN_PROGRESS (step 1 done: engine + hot-seat for 2–4)
- **Depends on:** KLD-088 (seats), KLD-119 (seat shell), KLD-123 (rules pages)
- **Touched paths:**
  - `packages/klunki_engine/lib/{ludo,registry,compat,game,klunki_engine,debug}.dart`, `lib/debug/{ludo_text,debug_console}.dart`
  - `packages/klunki_engine/test/{ludo_test,compat_test,result_code_test,word_tiles_seats_test}.dart`
  - `klunki/lib/ui/games/ludo/**`, `klunki/lib/ui/rules/games/ludo_rules.dart`, `klunki/lib/ui/{game_titles,game_visuals,engine_l10n}.dart`,
    `klunki/lib/ui/rules/rules_registry.dart`, `klunki/lib/ui/shell/screen_registry.dart`, `klunki/lib/app/theme.dart`, `klunki/lib/l10n/**`
  - `klunki/test/e2e/live_ui/ludo_live_test.dart`, `klunki/test/screenshots/ludo_shots_test.dart`, `klunki/test/ui/shell/undo_move_button_test.dart`

Generic names only: never the brand name of the German original (code, ARB, docs, commits).

## Goal
A new family game in the menu: "Rauswurf" for 2–4 players on one device. Tap the die, tap a glowing pawn;
the first with all four pawns in the finish lane wins. UX is iterated step by step with the maintainer.

## Steps
1. ✅ Engine, registry, fingerprint; hot-seat screen in the seat shell, rules page, 7 locales, live-UI games,
   screenshots `kld131`.
2. Maintainer feedback on the board and the rule decisions below; an options dialog for the house rules
   (the engine already has them as config); maybe a roll animation and a short tour.
3. Network (2 players first, later tables of 3–4 via KLD-088); needs `networkPlay: true` and a secret seed
   (the seed decides the dice, like Baulöwe).

## Rules (engine, `LudoGame`, rules version 1)
- Board: 40 track fields, start field of corner `c` at field `10·c`, a house of four and a finish lane of four
  per corner. Two players sit opposite (corners 0 and 2), three take corners 0–2.
- Progress of a pawn: -1 house, 0–39 track (from its own start), 40–43 finish lane.
- Moves: `{"action": "roll"}`, `{"action": "move", "pawn": 0–3}`; with 3–4 seats `{"action": "resign", "seat": n}`.
  A roll without a legal move is spent at once (another try or the next seat): no `pass` move.
- A 6 must bring a pawn out while pawns wait in the house and the own start field is free.
- Captures send the pawn home; never onto an own pawn; jumping over pawns on the track is allowed, never over
  a pawn in the finish lane; the finish lane needs the exact number.
- House rules (`GameConfig.ludo`, JSON key `ludo` with only the switches that differ; all on by default):
  `tries` – 3 tries for a 6 while no pawn can move without one (all in the house, or the rest stuck at the end
  of the finish lane); `capture` – Schlagzwang (a filter on the legal moves); `start` – Startfeld räumen (while
  pawns wait in the house, the pawn on the start field must move first; if its target holds an own pawn, that
  blocker must move, and so on along the chain; only if nobody in the chain can move do the normal moves
  apply – with a pawn in the house the chain has at most three pawns and always ends with one that can move);
  `six` – a 6 rolls again.
- Filter order: Startfeld räumen, then "bring out on a 6", then Schlagzwang among what is left.
- End: the first seat with all four pawns home wins; the others are ranked by pawns in the finish lane (equal
  counts share a place). Resign with 3–4: the seat's pawns leave the board, the others play on.
- A roll is the hot-seat undo barrier (`LudoGame.isRoll`); a pawn move can be taken back until the next roll.
- No hidden information; `networkPlay: false` for now.

### Decisions made in step 1
- ✅ confirmed (maintainer, 2026-11-15): A 6 rolls again even when it cannot be moved (and after it brought a
  pawn out). No limit on 6s in a row.
- After a winning move with a 6 the game ends (no extra roll).
- ✅ changed by the maintainer (2026-11-15) to the classic rule: a start pawn blocked by an own pawn makes the
  blocker move (along the chain), under the `start` switch; still rules version 1 (never shipped), the
  fingerprint is unchanged (the rule is code, not gameplay data).
- ✅ confirmed: Startfeld räumen, then bringing out on a 6, then Schlagzwang (a capture elsewhere does not
  override the first two).
- ✅ confirmed: the game ends with the first winner (no playing on for places).
- The die shows the last roll until the next one (also the previous player's roll at the start of a turn).

## Acceptance criteria
- [x] Engine with tests for every rule, 2/3/4 players, replays; fingerprint golden.
- [x] Menu tile, hot-seat for 2–4 ("Wer spielt?"), rules page, 7 locales.
- [x] Live-UI games through the real UI (`test/e2e/live_ui/ludo_live_test.dart`).
- [x] Screenshots `KLUNKI_SHOTS=… flutter test test/screenshots/ludo_shots_test.dart --plain-name kld131`.
- [ ] Maintainer feedback (step 2), options dialog, network (step 3).

## Definition of done
Engine, net and app tests green; screenshots looked at by the maintainer.
