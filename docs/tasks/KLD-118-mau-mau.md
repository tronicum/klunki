# KLD-118: Mau-Mau (shedding card game)

- **ID:** `KLD-118`
- **Title:** The classic shedding card game Mau-Mau (id `maumau`)
- **Milestone:** long-term games
- **Status:** TODO (backlog stub, nothing implemented; added 2026-11-02 by the maintainer)
- **Depends on:** KLD-088 (3–4 players) for more than 2 players

## Goal
Players take turns laying a card that matches the top card of the pile by suit or rank, or draw. The first player
without cards wins ("Mau" on the second-to-last card, "Mau-Mau" on the last). Plays with a standard 32-card deck.

## Rough scope
- Engine: 32-card deck (7–A in four suits), deal from the seed, draw pile, discard pile, reshuffle when empty.
  Common special cards as a configurable rule set (house rules vary a lot): 7 = next player draws 2 (stackable?),
  8 = skip, J = choose a suit (and can be played on anything?), A = play again; "Mau" call with a penalty when forgotten.
- Hidden hands: host redaction plus commitments (like Quartett), hot-seat with the handover cover.
- 2 players first, then 3–4 with KLD-088; hot-seat and network.
- UI: hand fan, pile, draw button, suit picker for the jack, "Mau!" button.

## Open questions
- Which special-card rules are the default, and which are house-rule toggles?
- Card faces: draw our own (no third-party card art).
- Name: Mau-Mau is a traditional generic name; check that it is fine as a title.
