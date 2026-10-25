# KLD-004 — Quartett (Trumpf + Sets modes)

- **Milestone:** P1
- **Status:** DONE
- **Depends on:** KLD-001
- **Touched paths:** `packages/klunki_engine/lib/quartett.dart`, `packages/klunki_engine/test/quartett_test.dart`

## Goal
One Quartett engine with two modes over a shared deck:
- **Trumpf** (Trumpf mode, compare stats): compare one stat of the two top cards; the better value takes both.
- **Sets** (classic Quartett): ask the opponent for specific cards to complete sets of 4.

## Acceptance criteria
- [ ] `Card` (id like `B3`, name, set, stats), built-in demo deck of 32 cards = 8 sets × 4, five numeric stats with a per-stat higher/lower-wins rule.
- [ ] `QuartettGame(QuartettMode mode, {int seed})` deals deterministically from the seed.
- [ ] Trumpf: `{'action':'pick','stat':id}`; the trick winner takes both cards to the bottom of their stack and picks next; a tie puts both cards in a pot that goes to the next trick's winner; a player with no cards loses; after 200 tricks the player with more cards wins, equal counts = draw.
- [ ] Sets: `{'action':'ask','card':id}` is legal only for a card the asker doesn't hold, from a set they hold at least one card of. A hit transfers the card and the asker continues; a miss passes the turn. Complete sets are laid down automatically. The game ends when all 8 sets are down; more quartets wins, 4:4 = draw.
- [ ] `handOf(player)`, `legalMoves`, `result` with reason, `history`; illegal moves return `null` and change nothing.
- [ ] Tests: deterministic deal, trick win/loss/tie + pot, lower-wins stat, end by no cards, trick limit; ask hit/miss, illegal asks, quartet laid down, full game to the end in each mode.

## Definition of done
`dart test` passes, including `game_contract_test.dart` extended with both modes.
