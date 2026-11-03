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
