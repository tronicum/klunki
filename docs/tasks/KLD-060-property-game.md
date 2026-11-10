# KLD-060: Baulöwe (property-trading game)

- **ID:** `KLD-060`
- **Title:** **Baulöwe**, a property-trading dice board game (id `property`; title chosen by the maintainer,
  2026-11-02; English working title **"Housing Corp"**, maintainer decision 2026-11-02)
- **Milestone:** long-term games
- **Status:** IN_PROGRESS: step 1 ✅ (engine); step 2a ✅ (registry entry, hot-seat only); step 3a ✅ (hot-seat
  UI, 2–4 players); next: 3b (trade screen), then network (step 2b, with KLD-088)
- **Depends on:** n-player lobby and protocol (KLD-088, no card file yet) for network play
- **Touched paths (step 1):**
  - `packages/klunki_engine/lib/property.dart` (engine), `property_theme.dart` (theme format, validation),
    `property_themes.dart` (Berlin, Fantasiestadt), `property_bot.dart` (bots)
  - `packages/klunki_engine/lib/debug/property_text.dart`, `lib/debug.dart`, `lib/klunki_engine.dart` (exports),
    `bin/klunki.dart` (`property` command)
  - `packages/klunki_engine/test/property_test.dart`
- **Touched paths (steps 2a, 3a):** `registry.dart` (`GameConfig.property`, `GameSpec.usesTheme`,
  `GameSpec.networkPlay`), `compat.dart` (fingerprint per theme), `game.dart` (two `GameEndReason`s);
  `klunki_net` host/guest (refuse `networkPlay: false`); app `lib/ui/games/property/` (screen, board, options,
  illustration), `lib/ui/rules/games/property_rules.dart`, the registries, l10n (all 7 locales), tests
  (`test/ui/games/property_screen_test.dart`, `test/e2e/live_ui/property_live_test.dart`,
  `test/screenshots/property_shots_test.dart`)

Keep it generic: never write the brand name of the original game anywhere; own card texts, own selection of
streets. Kid-friendly tone: competition yes, nastiness no; no real people, real companies, real property
scandals or current controversies in texts.

## Goal
2–6 players (hot-seat first, maintainer decision 2026-11-09; network later), move around a board of properties with
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

## Decisions (steps 2a and 3a: registry entry and hot-seat UI)
- **A normal `GameSpec`**, no separate seat-game registry: `PropertyGame extends Game implements SeatGame` like
  Ausgewürfelt (KLD-119). Seats 0/1 map to `Player.a/b` for the shared parts (common resign, `playerOf`);
  seats 2+ only through `SeatGame` (`actor`, `seatOfMove`, `seatResult`). `GameSpec('property', 'Baulöwe',
  maxPlayers: 6, rulesVersion: 1, undoBarrier: PropertyGame.isRoll)`.
- **Config** `GameConfig.property` (`PropertyOptions`): keys `theme`, `rounds`, `free`, `freeAmount`,
  `doubleStart`, `noRentInPause`, `bankruptAuction`, each written only when not the default; `configProblem`
  refuses an unknown theme or free rule.
- **Fingerprint** per theme: `property/berlin`, `property/fantasie` (revision = theme revision, the theme's
  content hash in the hash).
- **Network refused for now**: `GameSpec.networkPlay: false`; host and guest refuse such a game (protocol
  unchanged). The menu tile has only "Ein Gerät" (`hotSeatOnlyGames`).
- **2–4 players in the app** (`seatShellMaxPlayers = 4`, the "Wer spielt?" dialog and seat names of the shell);
  the engine keeps 2–6.
- **Undo**: "Zug zurücknehmen" (`undoAllowed.property`) back to the last roll: a roll reveals dice (and cards),
  so it is the barrier.
- **Screen** (`SeatGameScreen`): player chips (money, streets), the 11×11 board (Start bottom right,
  clockwise; group colour band, owner colour, buildings, lock when mortgaged, tokens), in the middle the board
  title, the dice, the square just reached and the pot; one action panel below ("Würfeln", "Kaufen" / "Nicht
  kaufen", bids +10/+50/+100 and "Aussteigen", "Kaution zahlen", "Freikarte nutzen", "Zug beenden", debt with
  "Pleite erklären"), "Meine Straßen" (build, sell, mortgage, redeem per street) and "Zug zurücknehmen". A tap
  on a square shows its card (price, rents, owner). The status line tells the last moves in words. Result:
  ranking with each player's wealth (or "ausgeschieden").
- **Start options** ("Baulöwe" dialog before "Wer spielt?"): board (Berlin / Fantasiestadt), game length (20 /
  **30, the app default** / 40 rounds, or until one is left), the free-square rule and the three switches under
  "Regelvarianten" (KLD-123 wording, never "Hausregeln"), undo.
- **30 rounds by default in the app** (maintainer decision 2026-11-09) until players can trade (step 3b):
  without trades whole groups are rare and a game until one is left can go on for hours. The engine default
  stays "until one is left"; the app's start values are `propertyAppDefaults`, and the rules page opened from
  the menu shows them (`rulesMenuConfig`).
- **History** (maintainer decision 2026-11-09): the narration names the players itself ("Anna würfelt 3 + 4 →
  …"), so the history shows it without the "Anna: " in front (`SeatGameScreen.historyNamesMover: false`); a
  move with nothing to tell shows the mover and the button ("Anna: Zug beenden").
- **Rules page**: Ziel, So läuft ein Zug, Regeln, Regelvarianten (board, round limit, free square, the three
  switches).
- **First game**: a short tour (coach marks, `SeenTips.propertyIntro`), again via "⋮" → "Kurz erklärt".
- **Theme texts** (street names, card texts, building names) stay German data in every locale for now
  (like the Quartett card names); the board title is translated.

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
  birthday card) can only sell buildings or mortgage, and the debt is paid automatically once the cash suffices.
  **Bankruptcy only when unavoidable** (maintainer decision): `bankrupt` is refused (and not in `legalMoves`)
  while selling every building and mortgaging everything could still pay the first debt (`raisable(seat)`,
  `canDeclareBankruptcy`). **Cash never goes negative.** (Resign stays possible at any time.)
- Bankruptcy to a player: buildings go back to the bank for half, then cash, properties (mortgages included)
  and free cards to the creditor. To the bank: cash to the bank, properties back unmortgaged, free cards under
  their decks. Other debts of/to that seat lapse.
- **Trades**: only the current player offers, in `roll` / `end`, at most 3 offers per turn (a declined offer
  cannot block the game); the partner accepts or declines. Money, properties (no buildings in their group) and
  free cards; mortgaged properties move as they are.
- Default: no round limit, play until one is left. Optional `maxRounds`: after that many full rounds the highest net worth wins (cash + prices, mortgaged at
  half + building costs); equal leaders → draw.
- Simplified compared with the classic rules (open questions below): no building shortage (32/12), no 10 %
  fee on received mortgaged properties, the "nearest station" card charges normal rent. The auction of a
  bankrupt's properties is an optional house rule (below).

### House rules (config options, theme-independent)
**Free square** (`freeSquare`, `freeSquareAmount`; Berlin: "Späti-Pause"), maintainer decision. German labels for
the later UI in brackets; config keys for step 2: `free` (name, absent = `none`) and `freeAmount`:

| `PropertyFreeSquare` | What happens | UI label (de) |
|---|---|---|
| `none` (default) | nothing (classic) | "Späti-Pause: nichts" |
| `pot` | taxes (tax squares) and card fines (`pay`, `repairs`) go into a pot in the middle instead of the bank; landing on the free square takes the pot | "Topf mit Steuern" |
| `potWithSeed` | like `pot`, but the pot starts with `freeSquareAmount` (default 500) from the bank and is refilled with it after every pick-up | "Topf + 500" |
| `fixedBonus` | landing there pays `freeSquareAmount` (default 200; e.g. 400) from the bank | "feste 200" |

Rent, bail and the cash of a bankruptcy to the bank never go into the pot. The pot is public (`pot` in the view)
and counts in the money invariant: Σ cash + bank balance + pot = players × 1500 (checked after every bot move,
with all four variants in the bot games).

**Further house rules, built as toggles (all off by default)**, maintainer decision; same config keys in step 2:

| Toggle | What happens | UI label (de) |
|---|---|---|
| `doubleStart` | landing exactly on Start pays 400 instead of 200 (also via a "Ab zum Start" card); passing pays 200 | "Doppeltes Startgeld auf Start" |
| `noRentInPause` | no rent is due for a property while its owner sits on the pause square | "Keine Miete in der Pause" |
| `bankruptAuction` | when a player goes bankrupt **to the bank**, their properties (unmortgaged) are auctioned one by one in board order among the remaining players (open bids from the next player on, `auction.landing == false`, `bankrupt: true` in the view; waiting squares in `pendingAuctions`); unsold ones stay with the bank. Not on a resign (those go back to the bank) and not on a bankruptcy to a player (the creditor gets them) | "Versteigerung bei Pleite" |

Each has a unit test (on and off) and the bot games run all three switched on in a third of the games with all
invariants green (bankruptcy auctions and pot pick-ups do occur there; the test checks it).

**Designed, not built:**
- **Building shortage** (32 small, 12 big buildings): counting is trivial, but selling a big building needs
  4 small ones from the bank; when they are short, the classic rule breaks the group down further, which
  clashes with even selling and with "bankrupt only when unavoidable" (a debtor could be left without a legal
  raise move). Needs its own design (e.g. sell a big building straight down to what the bank has, refunding
  each step) before it is built. UI label: "Begrenzte Häuser (32 / 12)".
- 10 % fee when receiving mortgaged properties; double rent from the "nearest station" card.

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

**Berlin** (rev 2: Späti and Simon-Dach-Straße groups replace Köpenick and Wedding; Boxhagener Platz left the
flea-market group so the Boxhagener Kiez group does not overlap), cheap → expensive:

| Group | Squares | Buildings (small → big) | Why the pair fits every square |
|---|---|---|---|
| Kreuzberg 36 | Skalitzer Straße, Schlesische Straße | Späti → Späti-Palast | two long streets with a Späti on nearly every corner |
| Boxhagener Kiez | Krossener Straße, Wühlischstraße, Simon-Dach-Straße | Bar → Kiezkneipe | the going-out streets around Simon-Dach-Straße |
| Neukölln | Richardplatz, Weserstraße, Sonnenallee | Laden → Markthalle | shopping streets, a village square with markets |
| Flohmärkte | Arkonaplatz, Straße des 17. Juni, Mauerpark | Trödelstand → Flohmarkt | all three host a well-known weekend flea market |
| Friedrichshain | Revaler Straße, Alt-Stralau, Am Wriezener Bahnhof | Imbiss → Club | the streets of the well-known clubs |
| Prenzlauer Berg | Kollwitzplatz, Kastanienallee, Schönhauser Allee | Kindercafé → Spielplatz | the family-rich Kollwitzkiez |
| Kunst und Kultur | Olivaer Platz, Lietzensee, Museumsinsel | Galerie → Museum | galleries in the west, the museum island |
| Prachtstraßen | Kurfürstendamm, Unter den Linden | Haus → Hotel | the grand avenues of West and East (maintainer 2026-11-10: Kurfürstendamm takes the most expensive group) |

- Stations: the Ring corners and the main station, in ring order around the board: **Südkreuz (5), Westkreuz
  (15), Hauptbahnhof (25), Ostkreuz (35)**.
- Utilities by place, no company names: **Wasserwerk Friedrichshagen** (12), **Fernsehturm** (28, as the
  broadcasting mast).
- Specials: Start, **Stau auf der A100** (pause; you are stuck in a traffic jam on the city motorway; was
  "Ersatzverkehr", renamed by the maintainer 2026-11-10), **Späti-Pause** (free), **Baustelle!** (go to the
  pause; was "Weichenstörung!", renamed with it), Bürgeramt-Gebühr (tax 200), Fahrradreparatur (tax 100); decks
  **Spree-Post** (surprise) and **Kiez-Karte** (neighbourhood).
- None of the classic German edition's street names is used (a test checks the list), and the selection is our
  own, not a city edition's. Hauptbahnhof is used as a generic word (maintainer decision).
- **Club culture nod**: the Friedrichshain group is made of the streets the famous clubs are on. Real club names
  were considered and replaced by their streets (business names, families as audience). Card winks are kid-safe:
  "Heute wird getanzt! Fahr zur Revaler Straße." and "Lange an der Tür angestanden und doch nicht reingekommen.
  Geh 3 Felder zurück." No alcohol, no drugs in any text.
- Cards: Berliner Schnauze for all ages (S-Bahn punctuality, Ringbahn Innenring/Außenring, Currywurst mit
  Pommes Schranke, Pfannkuchen, Schrippen, Mauerpark karaoke, "Kiek mal"). Maintainer-approved local jokes:
  **Bürgeramt** (tax square "Bürgeramt-Gebühr"; "Endlich ein Termin im Bürgeramt – für nächstes Jahr!", "Det
  Formular bitte dreifach!"), **S-Bahn disruptions** ("Die Ringbahn steht …", "Die S-Bahn fällt aus, du fährst Rad …") and one mild **airport-delay** card ("so lange
  auf die Eröffnung des neuen Flughafens gewartet, dass dein Sparschwein voll ist"), and the **A100 traffic jam**
  as the pause ("Baustelle auf der Stadtautobahn! Ab in den Stau auf der A100.", "Vollsperrung! …"); no blame, no real people
  or companies.
- Bar → Kiezkneipe (Boxhagener Kiez) and Späti → Späti-Palast (Kreuzberg 36) are maintainer decisions; they
  are building names only, card texts stay free of alcohol.

**Kept out** (maintainer decision): rents, housing or expropriation referendums, Görlitzer Park, the
Tempelhofer Feld building debate.

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

## Acceptance criteria (steps 2a, 3a)
- [x] Registered as `GameSpec` `property`; config keys round-trip; fingerprint goldens per theme; net refuses it.
- [x] Menu tile with its own picture and "2–4"; start options; "Wer spielt?" 2–4; hot-seat game on one device.
- [x] All moves except trades through the UI; tour; rules page; "⋮" menu; undo to the last roll.
- [x] l10n in all 7 locales (Chinese web font subset rebuilt).
- [x] Widget tests (`property_screen_test.dart`) and live UI: whole games through the real UI with the bot
      deciding and every tap checked against the engine (2 players / 25 rounds with rule variants, 4 players /
      12 rounds Fantasiestadt; `KLUNKI_LIVE_UI_FULL=1`: 3 players / 80 rounds).
- [x] Screenshots: `KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/property_shots_test.dart`.

## Next steps
- **3b trade screen (next, maintainer decision 2026-11-09)**: offer (money, streets, free card) to another player, the other answers on the same
  device (handover). Without trades, games without a round limit rarely end (bots seldom get a whole group).
- **Theme texts translated** (see "Texts and localisation"); German in every locale for now (maintainer
  decision 2026-11-09).
- **5–6 players** in the app (the shell stops at 4): later.
- **Building shortage** (see the open question): later.
- **Network (step 2b, with KLD-088), later**: redaction (secret seed and deck order), seats in the lobby, timeouts for
  auction bids and trade answers.
- Polish (step 4).

## Acceptance criteria (step 1)
- [x] Pure-Dart engine, no Flutter, deterministic from seed + moves; replay matches.
- [x] 2–6 seats; moves as JSON maps; illegal → null without state change; `legalMoves` for UI/AI.
- [x] Own board (40 squares, 8 groups, 4 stations, 2 utilities, taxes, start, pause, free, go to pause), own
      prices/rents, two decks of 16 own cards shuffled from the seed; as validated theme data (Berlin, Fantasie).
- [x] Doubles, pause rules, buy/decline/auction, rent incl. whole-group double, even building, mortgages,
      debts, bankruptcy (only when unavoidable) to bank or player, trades, resign, last solvent wins (default),
      optional round limit, free-square house rules (`none` / `pot` / `potWithSeed` / `fixedBonus`),
      toggles `doubleStart`, `noRentInPause`, `bankruptAuction` (off by default).
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
- ~~Free-parking pot~~: decided: free-square house rules as config, default nothing.
- ~~Bankruptcy while selling could still pay~~: decided: refused, sell and mortgage first.
- Building shortage: worth the design work (see above)? Later (2026-11-09).
- ~~Start money, currency~~: decided: 1500 Taler start, 200 salary.
- ~~Trades by other players~~: decided: only the player whose turn it is offers trades.
- Network: timeouts for auction bids and trade answers (step 2).
- ~~Titles in fr/es/zh/ar/fa and the accent colour~~: decided (2026-11-09): as proposed (Le Grand Bâtisseur, El
  Gran Constructor, 建筑大王, ملك البناء, سلطان ساخت‌وساز; ochre).
- ~~Default length in the app before trades~~: decided: 30 rounds (no limit still selectable).
