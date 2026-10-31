# KLD-061: Hotelspiel (hotel-building game)

- **ID:** `KLD-061`
- **Title:** A hotel-building dice board game (working title "Hotelspiel" / "Hotel-Tycoon", id `hotel`; the user
  may rename it)
- **Milestone:** long-term games
- **Status:** TODO (backlog stub, nothing implemented)
- **Depends on:** multiplayer beyond 2 players needs protocol/lobby work; possibly a shared core with KLD-060

Keep it generic: no publisher or brand name anywhere, own hotel names and artwork.

## Goal
Players move along a track with a die, buy hotel lots, build hotels (main building, annexes, extras) with a
building-permit die deciding whether building is allowed, and charge overnight fees from players who land on
their hotels; bankruptcy ends it.

## Rough scope (large)
- Engine: track, lots per hotel, building stages and costs, permit die (allowed / not / free / double price),
  overnight fees by dice roll and stage, entrances, bank, bankruptcy and the end condition.
- Deterministic dice from `GameConfig.seed`; map moves (`roll`, `buyLot`, `build`, `buyEntrance`, `endTurn`, …).
- Text adapter for the CLI demo, then a UI.
- Shares much with KLD-060 (property-trading game): dice track, money, rent, bankruptcy, 2–4 players. A shared
  "board-economy" engine core (track, dice, bank, payments, bankruptcy) could serve both.
- **More than 2 players** needs the same n-player model, lobby and protocol work as KLD-060.

## Open questions
- Which rule variant (number of hotels, entrance rules, fee table)?
- Build KLD-060 first and extract the shared core, or design the core up front?
