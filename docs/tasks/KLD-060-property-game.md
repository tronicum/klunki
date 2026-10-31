# KLD-060: Immobilien-Spiel (property-trading game)

- **ID:** `KLD-060`
- **Title:** A property-trading dice board game in the style of the well-known real-estate classic (working
  title "Immobilien-Spiel", id `property`; the user may rename it)
- **Milestone:** long-term games
- **Status:** TODO (backlog stub, nothing implemented)
- **Depends on:** multiplayer beyond 2 players needs protocol/lobby work (see below)

Keep it generic: never write the brand name of the original game anywhere, use own street names and card texts.

## Goal
2–n players move around a board of properties with two dice, buy streets, collect rent, build houses/hotels,
draw event cards, and go bankrupt; the last solvent player wins.

## Rough scope (large)
- Engine: board (squares, groups, prices, rents), dice from the seed, buying, auctions (or not), rent with
  houses/hotels, mortgages, event/community cards, jail, bankruptcy, end condition or turn limit.
- Moves as maps (`roll`, `buy`, `decline`, `build`, `mortgage`, `trade`, `endTurn`, …); deterministic dice
  from `GameConfig.seed` so the move log stays a full replay.
- Text adapter for the CLI demo, then a UI (board, players' money, property cards, trade dialog).
- **More than 2 players:** `Player` is `{a, b}` today and the network session is host + one guest. Needs a
  player model for n players, a lobby with seats, and protocol changes (several guests, turn order).
- Shares much with KLD-061 (hotel game): dice track, money, rent, bankruptcy, 2–4 players. A shared
  "board-economy" engine core could serve both.

## Open questions
- Which house rules (free parking, auctions, trades between players)?
- Hot-seat with hidden information? (Money and cards are public in the classic, so probably not.)
- Game length: a turn or time limit for demos?
