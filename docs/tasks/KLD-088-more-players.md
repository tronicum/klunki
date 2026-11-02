# KLD-088: More than two players (3–4 seats)

- **ID:** `KLD-088`
- **Title:** 3–4 players: seats next to `Player {a, b}`, first for Wortgewandt on one device, network later
- **Milestone:** Long-term games
- **Status:** IN_PROGRESS: step 1 ✅ (design + seat interface + Wortgewandt engine for 2–4 seats); next: step 2
  (hot-seat UI for 3–4 players in Wortgewandt)
- **Depends on:** KLD-094 (Wortgewandt), KLD-060 (Baulöwe engine, the first n-seat engine), KLD-064 (redaction),
  KLD-085 (fingerprint), KLD-103 (player names)
- **Touched paths (step 1):**
  - `packages/klunki_engine/lib/seats.dart` (new: `SeatGame`, `SeatResult`), `lib/klunki_engine.dart` (export)
  - `packages/klunki_engine/lib/word_tiles.dart`, `word_tiles_view.dart` (seats, seat resign, seat views)
  - `packages/klunki_engine/lib/registry.dart` (`GameConfig.players`, `GameSpec.maxPlayers`, `configProblem`)
  - `packages/klunki_engine/test/word_tiles_seats_test.dart` (new)
  - `packages/klunki_net/lib/src/{host,guest}.dart` (refuse `players != 2`), `test/wordtiles_net_test.dart`,
    `PROTOCOL.md`
  - `docs/tasks/KLD-094-word-tiles.md`, `docs/tasks/BOARD.md`

## Goal
Families are often more than two. Games that work with more players (first **Wortgewandt**, later Baulöwe and
maybe Quartett) can be played by 3 or 4 people: first on **one device** (hot-seat, the handover cover between
every player), later **over the network** (a host and up to 3 guests). Every 2-player game, the 2-player
protocol and old builds stay exactly as they are.

## Design

### Player model: seats next to `Player`
`enum Player { a, b }` is everywhere: `Game.currentPlayer`, `GameResult.winner`, `GameEvent.winner`, the resign
move (`'player': 'a'|'b'`), `GameEndReason` params (`a`, `b`), the redaction (`view(game, Player viewer)`), the
network session (host = A, guest = B, `you`), the shell (pill, legend, result dialog, resign "who?"),
`PlayerLabels`, the names store (`HotSeatNames(x, o)`), `HotSeatTransport.localPlayers`. Widening the enum (or
replacing it by an int) would touch every game, the protocol and the app in one go, and break the wire format.

So, as Baulöwe did in KLD-060: **seats are ints `0 … n-1` in turn order**, and an n-player game implements
**`SeatGame`** (`seats.dart`) *in addition to* `Game`:

| `SeatGame` | meaning |
|---|---|
| `playerCount` | seats, fixed for the game |
| `actorSeat` | the seat expected to move now (the player to move, or who must answer first); null once over |
| `seatOfMove(move)` | who makes a move (a resign or an answer names its seat) |
| `isSeatOut(seat)` | the seat resigned: skipped in the turn order, ranked behind the others |
| `seatResult` | `SeatResult`: `places` per seat (1 = best, ties share: 1, 1, 3, 4), `winners`, `ranking`, `code`, `params`, `reason` |

Seat 0 is `Player.a`, seat 1 `Player.b`. With **two seats nothing changes** (the game is driven through `Game`
as before; `SeatGame` is just a second view of it). With 3–4 seats the app (and later the network) drives the
game through the seat API; `currentPlayer` throws for seat 2+, and `playResult` only says "over" when the
winner cannot be named as a `Player` (`draw: true` then; use `seatResult`).

Why not a `SeatGame` that *replaces* `Game`: then every 2-player screen, transport and test would move at
once. Later, when all games run through seats, `Player` can become a thin alias for seats 0/1.

Baulöwe (`PropertyGame`) has `currentSeat`, `actor`, `seatOf(move)` and `PropertyResult` already; it can
implement `SeatGame` in its step 2 with a few getters (not done here, to keep this step to Wortgewandt).

### Config
- **`GameConfig.players`** (JSON `players`, written **only when not 2**; absent = 2). So every existing config,
  every `welcome` and every fingerprint stays byte-identical.
- **`GameSpec.maxPlayers`** (2 for every game, 4 for `wordtiles`); `minPlayers` is 2. `configProblem` refuses a
  player count outside the range ("\"chess\" is for 2 players, not 3").
- **Names are not config** (as today): the app keeps a list of up to 4 names per device (see UI).
- Not in the fingerprint: a 2-player game is the same on both sides; n-player network games will bump the
  protocol anyway (below).

### Turn order and moves
- Seats move in order `0, 1, …, n-1, 0`, skipping seats that left. Who starts: seat 0 (as A today); a random
  start seat could come from the seed later.
- Moves that name a player (resign, the "Trotzdem zulassen" answers, the chess draw offer) name a **seat**
  with 3+ seats: `{'action': 'resign', 'seat': 2}`. With two seats they keep `'player': 'a'|'b'`.
- **Resign with 3+ seats** does not end the game: that seat leaves (any time), the others play on; when one
  seat is left it wins (`common.resigned`, `params.seat` = the last to leave). A seat that left ranks behind
  everyone still in, the later it left the better. With 2 seats resign is unchanged.
- The hot-seat "Spiel beenden" (quit) stays what it is: the whole table stops, no result.

### Results and ranking
`SeatResult.places`: by final score for games with scores (ties share a place, the next is skipped), seats
that left behind. The result dialog shows the ranking (1., 2., 3., 4. with names and points), "gemeinsam
Erster" for a shared first place. `GameEndReason` stays the code list; its params for n seats use `seat` /
`score0…score3` in `SeatResult.params` (the `a`/`b` params stay for two seats).

### Hot-seat shell (step 2, Wortgewandt first)
What needs to change (all keyed by seat instead of `Player`, 2-player paths untouched):
1. **Start:** a player-count choice for games with `maxPlayers > 2` ("2 · 3 · 4 Spieler", default 2) next to the
   tile language / word list pickers; `GameConfig(players: n)`.
2. **Names dialog** ("Wer spielt?") with n fields; defaults per locale for seats 3/4 (new ARB keys
   `playerDefaultNameC/D`, e.g. de Cleo/Dani); store: a list of names (the 2-name store stays readable).
3. **Handover cover between every player** (`hiddenInformation`): already names "the player to move"; it needs
   the seat's name and colour instead of `Player`.
4. **Turn pill / turn edge colour / legend:** a colour and token per seat (4 colours that stay apart in light
   and dark and for colour-blind players; `PlayerLabels` / `PlayerToken` by seat).
5. **Score bar for 4:** four compact cells (name initial or colour dot, points, rack count), the active seat
   highlighted; on small phones in two rows of two. The Wortgewandt board already loops over `playerCount`.
6. **Result dialog:** ranking list instead of "X wins" / "draw".
7. **Resign:** "Wer gibt auf?" over the seats still in; the game goes on (see above).
8. **Transport/controller:** `HotSeatTransport` with `localSeats = {0…n-1}`; `GameController` by seat
   (`actorSeat`, `seatOfMove`) for `SeatGame`s, by `Player` otherwise.
9. **"Trotzdem zulassen"** on one device: the next seat agrees (it is at the table); the dialog names that seat.
10. Live-UI test: a full 4-player hot-seat game through the real UI; screenshots (`KLUNKI_SHOTS`), 7 locales.

### Network (later step)
- **Session:** the host plus up to 3 guests, one seat each. Lobby in the room: guests join, the host sees the
  seats fill (names), starts when all are in (or with fewer: the player count is fixed at start). Seats are
  assigned in join order (host = seat 0), a later step may let the host reorder.
- **Protocol (bump `protocolVersion`):** `welcome` gets `seat` (int) next to/instead of `you`; `move` messages
  are relayed host → every guest; `accepted` carries `seat`; a lobby message lists seats and names; keepalive and
  rejoin tokens per guest. A 2-player room stays 2-player on the wire (`you: "a"|"b"`), so a new host can still
  play with an old guest in 2-player games (KLD-085 compat by fingerprint as today).
- **Redaction per viewer:** `Redaction.view(game, viewer)` gets a seat variant (`seatViewJson(seat)` exists for
  Wortgewandt); `redactMove(move, moverSeat, viewerSeat)`; each guest gets its own redacted step.
- **Commitments:** the host commits per guest to the hidden parts of each redacted move (as KLD-064 today, now
  one salt/commit set per viewer) and reveals them all at the end; each guest verifies the replay
  (`verifyRedactedGame` with a seat).
- **Relay:** a relay room with more than one guest (the relay pairs one host with one guest today).
- **Disconnects:** a missing guest pauses the game for everyone; after a timeout the host can let the seat
  leave (counts as resign).
- Until then: `KlunkiHost.start` / `startRelay` refuse `players != 2`, a guest refuses such a `welcome`
  (PROTOCOL.md).

### Which games
| game | seats | notes |
|---|---|---|
| **Wortgewandt** | 2–4 | step 1 done (engine); hot-seat next |
| **Baulöwe** (KLD-060) | 2–6 | engine has seats; network only by design, so it needs the network step |
| Quartett (Sets) | 2–4 | classic "ask anyone for a card": natural for 3–4, needs a target seat in `ask` moves |
| Quartett (Trumpf) | 2–4 | possible (highest value wins the round), deck of 32 splits unevenly for 3 |
| Schiffe, GoStrategy, Schach, 4 Gewinnt, Mühle | 2 | no |

### Recommended order
1. ✅ Step 1: this design, `SeatGame`/`SeatResult`, `GameConfig.players`, Wortgewandt engine for 2–4 seats.
2. Step 2: **hot-seat 3–4 players for Wortgewandt** (shell by seat, names, cover, score bar, result ranking).
3. Step 3: Baulöwe implements `SeatGame`, registry entry (`maxPlayers: 6`).
4. Step 4: n-player network (lobby, protocol bump, per-seat redaction and commitments, relay rooms with
   several guests); Wortgewandt and Baulöwe over the network.
5. Later: Quartett (Sets) for 3–4.

## Step 1 (done): engine
- `seats.dart`: `SeatGame`, `SeatResult` (`placesFor(scores, out:)`: competition ranking, seats that left last).
- `GameConfig.players` / `GameSpec.maxPlayers` / `configProblem` as above; `wordtiles` has `maxPlayers: 4`.
- **Wortgewandt** (`WordTilesGame implements SeatGame`): the engine already ran 2–4 seats internally since
  KLD-094 step 1; now also:
  - the registry creates `GameConfig.players` seats;
  - **tiles:** 100 per set; 4 × 7 = 28 dealt, 72 in the bag. That is the usual size for 4 players.
  - **scoreless limit** `defaultScorelessLimit(n) = max(6, 2n)`: 6 for 2 and 3 seats (unchanged for 2), 8 for 4,
    so every player has passed or exchanged twice in a row;
  - **end:** bag empty and one player out (the others subtract their rack, the one who went out adds the sum), or
    the scoreless limit (everyone subtracts their rack): both as before, now for n seats;
  - **ranking:** `seatResult.places` by final score, ties share; `winnerSeats` only counts seats still in;
  - **resign with 3–4 seats:** `{'action': 'resign', 'seat': n}`; the rack goes back into the bag at random
    places (seeded, deterministic); an open request by that seat is dropped; if the placer of a challengeable
    placement or its challenger leaves, the placement stands (and ends the game if the placer went out); one
    seat left → it wins (`common.resigned`); the resign is in `history` and the turn log (`resign`);
  - **"Trotzdem zulassen"** with 3–4 seats: `requestAllow` / `acceptAllow` / `declineAllow` name a `seat`
    (`requestAllowMoveFor(seat, …)` etc. pick the right form for the player count); the **next seat still in**
    answers;
  - **challenge:** only the next seat (as before);
  - **views per seat:** `seatViewJson(seat)`; with two seats it is exactly `viewJson(Player)`; with 3–4 it has
    `viewerSeat` (`viewer` only for seats 0/1) and `out`. `WordTilesView.viewerSeat` (`viewer` throws for 2+).
- Tests (`word_tiles_seats_test.dart`): config round-trip and refusals, deal for 4, turn order, both ends with
  penalties, ties and places, challenge and allow requests by seat, resign cases, per-seat views (only the own
  rack, round-trip), and bot games with 3 and 4 seats in both modes (some with resigns) to the end, checking
  after every move that all 100 tiles are accounted for, that a seat that placed or exchanged holds 7 tiles
  unless the bag is empty, and that the replay gives the same views and result.

### Rules version impact
None. With two seats every move, view, event and result is byte-identical (all existing tests, replays and
compat goldens unchanged); the only new things are the `players` config key (absent for 2), seat moves that are
refused with two seats, and the views of seats 2–3. Wortgewandt stays at rules 3, the fingerprint is unchanged,
no protocol bump (3–4 seats never go on the wire yet).

## Acceptance criteria
- [x] Step 1: design in this card; `SeatGame` / `SeatResult`; `GameConfig.players`; Wortgewandt engine 2–4 seats
      with tests; 2-player behaviour, goldens and protocol unchanged; network refuses 3–4.
- [ ] Step 2: hot-seat 3–4 players for Wortgewandt through the real UI (live-UI game, screenshots, 7 locales).
- [ ] Step 3: Baulöwe as `SeatGame` in the registry.
- [ ] Step 4: n-player network (protocol bump, lobby, per-seat redaction and commitments).

## Open questions (🧑)
1. **Team play 2 vs 2** (partners sit opposite, scores added)? Not planned; would be a config flag on top of seats.
2. **Who starts:** always seat 0 (the first name), or a random seat (from the seed), or "draw a tile, closest to
   A starts" as at a real table?
3. **Scoreless limit for 4:** 8 (everyone twice, implemented) or the plain 6?
4. **Resign with 3–4:** rack back into the bag (implemented) or set aside? Should a seat that left keep its points
   on the result list (implemented: yes, but ranked last)?
5. **"Trotzdem zulassen" with 3–4:** the next player agrees (implemented), or all others / a majority?
6. **Challenge with 3–4:** only the next player (implemented), or anyone at the table?
7. **Colours for seats 3 and 4** and default names (de Cleo/Dani? per locale like Anna/Ben).
