# KLD-060: Baulöwe (property-trading game)

- **ID:** `KLD-060`
- **Title:** **Baulöwe**, a property-trading dice board game (id `property`; title chosen by the maintainer,
  2026-11-02; English working title **"Housing Corp"**, maintainer decision 2026-11-02)
- **Milestone:** long-term games
- **Status:** IN_PROGRESS: step 1 ✅ (engine); next: step 2 (n-player registry/protocol, with KLD-088)
- **Depends on:** n-player lobby and protocol (KLD-088, no card file yet) for network play
- **Touched paths (step 1):**
  - `packages/klunki_engine/lib/property.dart` (engine), `property_theme.dart` (theme format, validation),
    `property_themes.dart` (Berlin, Fantasiestadt), `property_bot.dart` (bots)
  - `packages/klunki_engine/lib/debug/property_text.dart`, `lib/debug.dart`, `lib/klunki_engine.dart` (exports),
    `bin/klunki.dart` (`property` command)
  - `packages/klunki_engine/test/property_test.dart`

Keep it generic: never write the brand name of the original game anywhere; own card texts, own selection of
streets. Kid-friendly tone: competition yes, nastiness no; no real people, real companies, real property
scandals or current controversies in texts.

## Goal
2–6 players, **each on their own device (network only, no hot-seat)**, move around a board of properties with
two dice, buy streets, collect rent, build, draw event cards and go bankrupt; the last solvent player wins, or
the richest after an optional round limit.

**Game length (maintainer decision):** by default the game runs **until only one player is left** (everybody else bankrupt or resigned); there is no round limit (`maxRounds` null, the engine default). A round limit stays an **optional** setting for people who do not want an endless game; the UI step should offer e.g. 20 / 30 / 40 rounds next to "bis zum Ende" (the default), and with a limit the richest player wins.

## Step plan
1. ✅ **Engine** (this step): pure Dart, deterministic, n seats, themes as data, bots, CLI, tests.
2. **n-player plumbing** (with KLD-088): registry entry, `GameConfig` keys, protocol/lobby with seats,
   redaction (secret seed and deck order), compat fingerprint (theme revision + content hash).
3. **UI**: board, money, property cards, building pieces per group (icons), auction and trade dialogs, debt
   screen; theme texts localised (see "Texts and localisation").
4. Polish: computer opponent from `PropertyBot`, pause/resume (KLD-079), timeouts for auction answers.
5. Later: edition editor (below).

## Decisions (step 1)

### n players without breaking the 2-player games
`Player` is `{a, b}`, the shared `Game` interface, `GameEvent.winner`, the resign move (`'player': 'a'|'b'`),
`GameEndReason`, the registry, the network session (host + one guest) and the compat check all assume two
players. Changing them would touch every game, the protocol and the app. So **`PropertyGame` stands alone**:
- Players are **seats** `0 … playerCount-1` (2–6). `currentSeat` is whose turn it is, `actor` who is expected
  to move now (the bidder in an auction, the trade partner, the debtor). A move may carry `'seat': n` (the
  sender): it is refused unless it is the actor, so the host can check senders later.
- Resign: `{'action': 'resign', 'seat': n}`, any time, by any seat still in (assets go back to the bank).
- Result: `PropertyResult` with `winner` (seat), `leaders` on a tie, codes `property.lastSolvent` and
  `property.roundLimit` (own strings, not in `GameEndReason` yet: that enum's params assume `a`/`b`).
- `PropertyGame.replay(playerCount, seed, moves, maxRounds:, theme:)` is the full replay.
- **Not registered** in `gameSpecs` yet: a `GameSpec` must create a `Game` (`currentPlayer` a/b), and the
  registry tests, debug console and compat goldens iterate all specs. Registering with a 2-player shim would be
  wrong for a network-only n-player game. Hence also no fingerprint change and no rules-version golden;
  `PropertyGame.rulesVersion = 1` is ready for step 2.
- **Adapter plan for step 2**: introduce a seat-based interface next to `Game` (e.g. `SeatGame` with
  `int? actor`, `int seatOf(move)`, `result.winner` as seat) and a `GameSpec.maxPlayers`/`minPlayers`; the
  existing two-player games keep `Game` and map `Player.a/b` to seats 0/1. `GameConfig` gains `players`,
  `rounds` and `theme` keys (public config; written only when set). The protocol assigns seats in the lobby.

### Turn model (one actor at a time)
`phase`: `roll` → (`buy` → optional `auction`) → `end`; `trade` and `debt` interrupt. Priority: debt > auction >
trade > turn phase. Moves (JSON maps, illegal → `null`, no state change): `roll`, `buy`, `decline`, `bid`
(`amount`), `pass`, `build` / `sell` / `mortgage` / `unmortgage` (`square`), `payBail`, `useCard`, `endTurn`,
`tradeOffer` (`to`, `give`, `get`: `{money, squares, cards}`), `tradeAccept`, `tradeDecline`, `bankrupt`, `resign`.
`legalMoves` lists the moves of the actor (bids as min / +50 / +100; trade offers are checked with
`tradeProblem` instead of listed). `applyMove` returns `PropertyEvent` with a list of JSON events (`rolled`,
`moved`, `salary`, `card`, `paid`, `bought`, `auction`, `bid`, …) for narration, animation and network steps.

### Rules as implemented
- Start 1500 Taler each, 200 for passing/landing on Start, two dice from `Random(seed)` (decks are shuffled from
  the same stream first; tests and demos can script dice and deck tops).
- Doubles: roll again; the third doubles in one turn send you to the pause square.
- Pause: leave by doubles (move, no extra roll), paying 50 (`payBail`, then a normal roll) or a free card
  (`useCard`); after the third failed try you pay 50 and move.
- Buy or decline; **auction on decline: open ascending bids in seat order**, starting after the decliner (who
  bids last); each `bid` beats the high bid (first ≥ 10) and fits the bidder's cash, `pass` drops out for good;
  the last bidder with the high bid buys, nobody → stays with the bank. Chosen because it fits the
  one-actor-at-a-time network turn model and needs no hidden information (sealed bids would need commitments
  or simultaneous moves).
- Rent: base, double for a whole unbuilt group (also with a mortgaged member), houses/hotel table, stations
  25/50/100/200, utilities dice × 4 / × 10. Mortgaged: no rent. Rent is due even when the owner sits in the pause.
- Building: whole group, nothing mortgaged in it, even building, 4 small then 1 big building; selling evenly
  for half the cost; mortgage only with no buildings in the group (value = half the price); lifting +10 %.
- Debts: an amount larger than the cash becomes a queued debt; the debtor (may be another seat, e.g. the
  birthday card) can only sell buildings or mortgage, and the debt is paid automatically once the cash suffices,
  or declares `bankrupt`. **Cash never goes negative.**
- Bankruptcy to a player: buildings go back to the bank for half, then cash, properties (mortgages included)
  and free cards to the creditor. To the bank: cash to the bank, properties back unmortgaged, free cards under
  their decks. Other debts of/to that seat lapse.
- **Trades**: only the current player offers, in `roll` / `end`, at most 3 offers per turn (a declined offer
  cannot block the game); the partner accepts or declines. Money, properties (no buildings in their group) and
  free cards; mortgaged properties move as they are.
- Default: no round limit, play until one is left. Optional `maxRounds`: after that many full rounds the highest net worth wins (cash + prices, mortgaged at
  half + building costs); equal leaders → draw.
- Simplified compared with the classic rules (open questions below): no building shortage (32/12), no auction
  of a bankrupt's properties to the bank, no 10 % fee on received mortgaged properties, no free-parking pot,
  the "nearest station" card charges normal rent.

### Hidden information (for the redaction step)
Money, properties and held cards are public. **Secret: the seed and the deck order** (`toJson` leaves out both,
only deck sizes; the seed must never go to guests per AGENTS.md). Guests cannot compute dice, so the host's
redacted step must carry the events (dice, drawn card id) and the public view; a guest gets the seed only after
the game (commitment check like KLD-064).

### Themes (local editions, maintainer decision)
The board is **theme data** (`PropertyTheme`): id, revision, title, currency, 8 colour groups (name, building
names singular/plural small and big, an icon key per building kind, a note), 40 squares (kind, name, price,
house cost, rents, tax amount) and two decks (title, cards with kind and numbers). Plain JSON
(`toJson` / `fromJson`, `format: 1`) and `validate()` (layout, group count, price and rent ranges, rising rents,
card actions and targets, unique card ids, text lengths, icon keys). `contentHash` (SHA-256 of the JSON) and
`revision` go into the compat fingerprint once the game is registered, like Quartett decks. The rules do not
depend on the theme; the **layout is fixed** (`propertyLayout`): same kinds of squares in the same places, so
the classic proportions and the engine stay valid (an editor could relax this later).

Built-in themes: **Berlin** (`berlin`, default) and **Fantasiestadt** (`fantasie`, made-up kid-friendly names,
for families elsewhere and as a neutral theme).

**Berlin** (rev 1), cheap → expensive:

| Group | Squares | Buildings (small → big) | Why the pair fits every square |
|---|---|---|---|
| Köpenick | Alt-Köpenick, Müggelheimer Straße | Haus → Hotel | old town and the road to the lakes |
| Wedding | Osloer Straße, Leopoldplatz, Müllerstraße | Haus → Hotel | busy residential streets and a square |
| Neukölln | Richardplatz, Weserstraße, Sonnenallee | Laden → Markthalle | shopping streets, a village square with markets |
| Flohmärkte | Arkonaplatz, Boxhagener Platz, Mauerpark | Trödelstand → Flohmarkt | all three have a weekend flea market |
| Friedrichshain | Revaler Straße, Alt-Stralau, Am Wriezener Bahnhof | Imbiss → Club | the streets of the well-known clubs |
| Prenzlauer Berg | Kollwitzplatz, Kastanienallee, Schönhauser Allee | Kindercafé → Spielplatz | the family-rich Kollwitzkiez |
| Charlottenburg | Olivaer Platz, Lietzensee, Kurfürstendamm | Haus → Hotel | elegant avenue, square, lakeside |
| Mitte | Museumsinsel, Unter den Linden | Galerie → Museum | the museum island and the avenue next to it |

- Stations: the Ring corners and the main station, in ring order around the board: **Südkreuz (5), Westkreuz
  (15), Hauptbahnhof (25), Ostkreuz (35)**.
- Utilities by place, no company names: **Wasserwerk Friedrichshagen** (12), **Fernsehturm** (28, as the
  broadcasting mast).
- Specials: Start, **Ersatzverkehr** (pause; you are stuck in the rail replacement service), **Späti-Pause**
  (free), **Weichenstörung!** (go to the pause), Bürgeramt-Gebühr (tax 200), Fahrradreparatur (tax 100); decks
  **Spree-Post** (surprise) and **Kiez-Karte** (neighbourhood).
- None of the classic German edition's street names is used (a test checks the list), and the selection is our
  own, not a city edition's. Hauptbahnhof is used as a generic word (maintainer decision).
- **Club culture nod**: the Friedrichshain group is made of the streets the famous clubs are on. Real club names
  were considered and replaced by their streets (business names, families as audience). Card winks are kid-safe:
  "Heute wird getanzt! Fahr zur Revaler Straße." and "Lange an der Tür angestanden und doch nicht reingekommen.
  Geh 3 Felder zurück." No alcohol, no drugs in any text.
- Cards: Berliner Schnauze for all ages (S-Bahn punctuality, Ringbahn Innenring/Außenring, Currywurst mit
  Pommes Schranke, Pfannkuchen, Schrippen, Kiezfest, Mauerpark karaoke, "Kiek mal", "Det Buch …").
- The "Bar → Kiezkneipe" pair for a Simon-Dach-Straße group was not used: no free group slot with a coherent
  area, and it centres on alcohol (for the maintainer to decide).

**For the maintainer to decide** (kept out on purpose; current controversies or close to them): jokes about the
new airport's long opening delay; the Tempelhofer Feld building debate; Görlitzer Park; anything about rents,
housing or expropriation referendums (especially touchy in a property game); waiting times for Bürgeramt
appointments (the tax square "Bürgeramt-Gebühr" is a mild nod: keep or rename?); S-Bahn disruption jokes are in
(Weichenstörung, Ersatzverkehr): acceptable?

### Texts and localisation
Theme texts are German first and live in the theme data (like Quartett card names). For the UI step: built-in
themes get their translations per theme (theme JSON with `de`/`en`/… text maps, or per-theme ARB files keyed by
square index / card id / group index); the engine only needs ids. Engine/CLI narration is English.

## Later: edition editor (do not build yet)
Families create a personal edition (own streets, prices, building names, card texts) and play it with friends.
- The theme is already the plain, validated JSON format above; the editor edits it and runs `validate()`.
- Network: the host sends the full theme JSON with the room config; guests validate it and compare its
  `contentHash` (the hash goes into the room/compat check instead of a build-time fingerprint; built-in themes
  keep revision + hash in the build fingerprint).
- Local-first: custom editions stay on the device (and travel peer to peer in the room); no server upload.
- Texts in custom editions are the families' own; the app shows them as they are (one language).

## Shared core with KLD-061 (hotel game)
Not extracted yet (no over-engineering): candidates once KLD-061 starts are the seeded dice, seats and turn
order, the debt queue with automatic payment, bankruptcy with asset transfer and the open-bid auction. They are
separate private helpers in `property.dart` so they can be moved into a shared "board-economy" file then.

## Acceptance criteria (step 1)
- [x] Pure-Dart engine, no Flutter, deterministic from seed + moves; replay matches.
- [x] 2–6 seats; moves as JSON maps; illegal → null without state change; `legalMoves` for UI/AI.
- [x] Own board (40 squares, 8 groups, 4 stations, 2 utilities, taxes, start, pause, free, go to pause), own
      prices/rents, two decks of 16 own cards shuffled from the seed; as validated theme data (Berlin, Fantasie).
- [x] Doubles, pause rules, buy/decline/auction, rent incl. whole-group double, even building, mortgages,
      debts, bankruptcy to bank or player, trades, resign, last solvent wins, optional round limit.
- [x] JSON view without seed and deck order.
- [x] CLI: `dart run klunki_engine:klunki property --players 4 --seed 7 'auto 50'` (`PropertyText`).
- [x] Bots (`PropertyBot`, greedy and random) play 80 full games (2–6 players) with invariants checked after
      every move: money conserved with the bank, no negative cash, out seats own nothing, even building; every
      game ends (round limit 60), replays match; refused moves leave the state unchanged.
- [x] `dart analyze --fatal-infos` and `dart test` green in `klunki_engine`; `klunki_net` and the app analyze clean.

Measured with greedy bots and no round limit (40 seeds each): median 72 rounds (2–3 players), 53 (4), 52 (6);
90 % within ~90–130 rounds; every game ended.

## Open questions
- ~~English title~~: decided: "Housing Corp" (working title).
- ~~Default game length~~: decided: until one player is left; round limit optional (20 / 30 / 40 in the UI).
- House rules: free-parking pot (off now)? building shortage 32/12 (off)? auction of a bankrupt's properties
  (off, they go back to the bank)? 10 % fee when receiving mortgaged properties (off)? double rent from the
  "nearest station" card (off)?
- Start money 1500 and salary 200 kept; currency "Taler" for Berlin too?
- Should non-current players be allowed to offer trades (needs a "pending offers" list instead of one actor)?
- Bankruptcy is allowed whenever in debt, even if selling could still pay: OK, or force selling first?
- Network: timeouts for auction bids and trade answers (step 2).
- The "for the maintainer to decide" Berlin ideas above.
