# KLD-094: Word tile game "Wortgewandt" (crossword-style)

- **ID:** `KLD-094`
- **Title:** A crossword-style letter tile game (id `wordtiles`)
- **Milestone:** long-term games
- **Status:** step 1 DONE (research, design, engine, text adapter, tests); step 2 DONE as a debug-menu preview
  (hot-seat screen, `appReady` still false until the 🧑 UX review; name decided: Wortgewandt); step 4 DONE for
  hot-seat (word lists de + en, check at "Legen" with "Trotzdem zulassen", tile language per game, the bench
  "Bänkchen"); step 5 hot-seat polish DONE (see "Step 5"); step 6 network (2 devices) DONE (see "Step 6"); **step 7
  release DONE ✅** (`appReady: true`, a menu tile with "Ein Gerät" and "Mit anderen", see "Step 7"); **step 8
  playtest fixes DONE ✅** (rack bug, bench below the actions, one-time bench explanation, see "Step 8"); 3–4
  players assessed (see "3–4 players on one device")
- **Depends on:** none for the engine; the UI needs the shell (KLD-021); 3–4 players need KLD-088; long games
  profit from KLD-079 (pause/resume); dictionary mode needs 🧑 approval of a word list (step 4)
- **Touched paths (step 1):**
  - `packages/klunki_engine/lib/word_tiles.dart`, `lib/word_tiles_view.dart`, `lib/debug/word_tiles_text.dart`,
    `test/word_tiles_test.dart` (all new)
  - `packages/klunki_engine/lib/game.dart` (2 `wordtiles.*` `GameEndReason`s), `lib/registry.dart`
    (`GameSpec` with `appReady: false`), `lib/compat.dart` (tile sets + layout in the content hash),
    `lib/klunki_engine.dart`, `lib/debug.dart`, `lib/debug/debug_console.dart`
  - `packages/klunki_engine/test/{compat,game_contract,result_code,secrecy}_test.dart`
  - `klunki/lib/ui/engine_l10n.dart` (the exhaustive switch needs the new codes; English until step 2)

## Goal
The classic family game where players draw letter tiles from a bag and lay crossword-style words on a board with
premium squares, for 2 (later up to 4) players, hot-seat and over the network, with or without a dictionary.

## Naming and IP
No brand names anywhere (code, docs, UI): the engine says "word tiles", the id is `wordtiles`.
- **Name: Wortgewandt** (decided 2026-11-01, chosen by the maintainer; German for "eloquent, skilled with words").
  Display title only: the id `wordtiles`, the protocol and the compat fingerprint are unchanged. Per locale
  (`menuGameWordTiles`): en **Wordsmith**, fr **As des mots** (short, natural, invariable "as" = ace, no gender;
  "Virtuose des mots" is 17 characters and stiff on a menu tile), es **Palabrista** (short and playful; "Juego de
  palabras" means "pun"), zh **文字高手** ("master of words"; every glyph is already in the bundled Noto Sans SC
  subset, 妙笔生词 is not), ar **فصاحة** ("eloquence", a noun, so no gendered form), fa **سخنور** ("eloquent
  speaker", gender-neutral; واژه‌پرداز would read as "word processor").
- **Kept for future games:** WortSalat and KlunkerKombi (maintainer's other proposals).
- *Historical note:* the working title until 2026-11-01 was "Wortleger"; the other early proposals were
  Buchstabensalat, Kreuzwort and Letter Tiles.
- **Rules are not protected; trade dress may be.** We use the common rules (they are game mechanics) but our own
  board: the premium layout below is designed here, not copied. The tile counts and point values are derived by
  us from published letter-frequency facts (see "Tile sets"). No colours, fonts, logos or tile look of any
  commercial product.

## Rules we implement (step 1 engine)
- **Setup:** 15 × 15 board, a bag of 100 tiles (98 letters + 2 blanks), racks of 7, seats take turns from seat 0
  (`Player.a`). The bag is shuffled from the game's seed (`Random(seed)`, the engine's current convention; KLD-072
  will swap in an engine-owned PRNG for every game).
- **Placement** (`place`): 1–7 tiles from the rack, all in one row or one column, with no empty square between
  the first and the last (board tiles may fill the gaps). The first word covers the centre square and has at
  least 2 letters; every later placement touches a board tile. A blank names the letter it shows and scores 0.
- **Words:** the main word along the line, plus every cross word a new tile makes (2+ letters). A single tile
  goes across if it has a neighbour across, else down.
- **Scoring:** letter values; a premium square counts only for a tile laid in this move (letter ×2/×3 on that
  tile, word ×2/×3 on every word through it, multiplied when a word covers two); **+50** for laying all 7 tiles.
  The player then draws back up to 7.
- **Exchange** (`exchange`, the tiles listed): only while the bag holds at least 7 tiles; the new tiles are drawn
  first, the old ones go into the bag at random places. Scoreless turn.
- **Pass** (`pass`): scoreless turn.
- **Game end:**
  - a player empties the rack while the bag is empty: every other player loses the value of their rack, the
    player who went out gains the sum (`wordtiles.playedOut`, params `a`, `b` = final scores);
  - 6 consecutive scoreless turns (passes, exchanges, withdrawn or zero-point placements, failed challenges;
    `scorelessLimit`, default 6): every player loses their own rack value (`wordtiles.scorelessTurns`, params
    `turns`, `a`, `b`);
  - resign: the common move (KLD-065).
  - Highest score wins; equal top scores are a draw.
- **Word check, two modes (`WordCheck`):**
  - **challenge** ("Anzweifeln", the MVP, needs no word list): placements are not checked. The next player may
    answer the last placement with `challenge` before moving; anything else (a placement, exchange, pass, or an
    explicit `accept`) accepts it. **Without a validator the challenger's call is final**, as at a real table: the
    placement is withdrawn exactly (tiles back on the rack in the old order, the tiles drawn after it back on top
    of the bag, score removed, the turn counts as scoreless) and the challenger plays on. **With a validator**
    the words decide: an unknown word is withdrawn the same way, a valid one stands and the challenger loses the
    turn. A placement that ends the game (rack empty, bag empty) waits for the answer: only `challenge` or
    `accept` are legal until then.
  - **dictionary:** every word must pass the `WordValidator`; a placement with an unknown word is refused like any
    illegal move (the UI can say why via `checkPlacement`). No challenges.
- **Only the next player can challenge** (simple and fits the network turn model; with 3–4 seats a table might let
  anyone challenge, open question).

## Board layout (our own)
8 triple word (`*`), 17 double word (`+`, centre included), 12 triple letter (`^`), 24 double letter (`:`): the same
density as common boards (61 premium squares), symmetric on both axes and the diagonals, but a different
arrangement: no triple words in the corners or at the edge centres, no double-word diagonals, the centre lines
free of letter premiums. Defined as one octant in `WordTilesGame._octant`:

```
    a b c d e f g h i j k l m n o
 1  : . . * . . : . : . . * . . :
 2  . ^ . . . . . + . . . . . ^ .
 3  . . . . + . . . . . + . . . .
 4  * . . . . ^ : . : ^ . . . . *
 5  . . + . : . . . . . : . + . .
 6  . . . ^ . + . . . + . ^ . . .
 7  : . . : . . . . . . . : . . :
 8  . + . . . . . + . . . . . + .
 9  : . . : . . . . . . . : . . :
10  . . . ^ . + . . . + . ^ . . .
11  . . + . : . . . . . : . + . .
12  * . . . . ^ : . : ^ . . . . *
13  . . . . + . . . . . + . . . .
14  . ^ . . . . . + . . . . . ^ .
15  : . . * . . : . : . . * . . :
```
To check by playing (step 2): the long-word lanes to the triple words; it may be worth moving premiums around
before the layout is final (a change bumps `rulesVersion` and the compat golden).

## Tile sets (our own derivation)
**Counts:** 98 letter tiles; every letter gets one, the rest go one at a time to the letter with the highest
`f^0.9 / (n + 1)` (`f` = frequency in %, `n` = tiles so far: a highest-averages method, never fewer tiles for a more
frequent letter; the exponent 0.9 damps the commonest letters a little). **Points:** `fRef` = mean frequency of the
six commonest letters, `k = 7 / log2(fRef / fMin)`, band index `floor(max(0, log2(fRef / f)) · k)` into
1, 2, 3, 4, 5, 6, 8, 10 (the rarest letter gets 10). `test/word_tiles_test.dart` recomputes both sets from the
frequencies and pins them, so a change to the constants must change the documented derivation too.

| | Source of the frequencies |
|---|---|
| de | Karl-Heinz Best, "Buchstabenhäufigkeiten im Deutschen und Englischen", 2005 (as tabled on de.wikipedia.org "Buchstabenhäufigkeit", with Ä Ö Ü); a statistical fact table, not a game's data. ß (0.19 %) is folded into S twice. |
| en | The "Dictionaries" column of en.wikipedia.org "Letter frequency" (letters in dictionary words; the article marks the column "citation needed", so we treat it as a starting point). Text frequencies would over-weight H and T. |

- **de** (98 + 2 blanks): E 15×1, N 9×1, S 7×1, I 7×1, R 6×1, A 6×1, T 6×1, D 5×1, H 4×1, U 4×1, L 3×2, C 3×2,
  G 3×2, M 2×2, O 2×2, B 2×2, W 2×2, F 1×2, K 1×3, Z 1×3, P 1×3, V 1×3, Ü 1×4, Ä 1×4, Ö 1×4, J 1×5, Y 1×8, X 1×8,
  Q 1×10.
- **en** (98 + 2 blanks): E 10×1, S 8×1, I 8×1, A 8×1, R 7×1, N 7×1, T 6×1, O 6×1, L 5×1, C 4×2, D 4×2, U 3×2,
  G 3×2, P 3×3, M 3×3, H 2×3, B 2×3, Y 1×4, F 1×4, V 1×4, K 1×4, W 1×5, Z 1×6, X 1×8, J 1×8, Q 1×10.
- **Umlauts and ß:** Ä Ö Ü are tiles of their own (a German word list spells them, and "Häuser" ≠ "Hauser"). No ß
  tile: ß is written SS (`TileSet.normalize`: "Straße" → STRASSE), as in German upper case and in word games;
  the word list is normalized the same way.
- **Recalibrate** once the word list is approved (step 4): count letters in the list itself (word-game
  frequency, not running text) and feed them into the same derivation.

## Dictionary research (step 1: reading only, nothing downloaded)
Licences read on the projects' pages, 2026-11-01. "AGPL" = bundling with the app under AGPL-3.0 (KLD-076 has not
decided the app's licence yet), "MIT" = bundling with a permissive app (a CC BY-SA / MPL / LGPL list can then
ship as a separate, separately licensed data file).

**German (de)**

| Candidate | Licence | Size / forms | Inflected forms | Quality | AGPL | MIT |
|---|---|---|---|---|---|---|
| **enz/german-wordlist** (github.com/enz/german-wordlist) | **CC0-1.0** | `words` ≈ 8 MB (count unverified) | likely yes (built "roughly following the rules of" the classic game; to verify) | made for word games (Tanglet): no names, places, abbreviations, archaic or old spellings; blacklist; README: "incomplete, contains mistakes" | yes | yes |
| LanguageTool german-pos-dict (Morphy + D. Naber) | CC BY-SA 4.0 | full-form lexicon (count unverified) | yes, with lemma + tags | maintained; tags let us drop proper nouns / abbreviations | yes (share-alike for the derived list) | as a data file |
| igerman98 / Hunspell de_DE (j3e.de) | GPL-2.0 OR GPL-3.0 | `.dic` + `.aff` | must be expanded (unmunch) | 2006 spelling reform; contains proper nouns; frami additions unverified | yes | risky (GPL) |
| DEMorphy dictionaries | CC BY-SA 4.0 (LICENSE file; README says MIT) | unverified | yes | partly generated forms | yes | as data |
| Wiktionary via kaikki.org | CC BY-SA 4.0 + GFDL | de dump 2.9 GB | inflection tables | needs heavy filtering | yes | as data |
| Trennmuster "wortliste" | no licence found | – | partly | hyphenation database | unverified | unverified |
| davidak/wortliste | built from DWDS (CC BY-ND), Leipzig (CC BY), DeReWo (CC BY-NC) | 239,650 | – | NC/ND inputs | **no** | **no** |
| Leipzig Corpora | corpora CC BY, other data CC BY-NC (sources conflict) | – | frequency lists | noisy | unclear | unclear |
| DWDS lists, DWDSmor | CC BY-ND / GPL-2.0-only | – | – | – | **no** | **no** |
| dict.cc, commercial tournament lists | proprietary | – | – | – | **no** | **no** |

**English (en)**

| Candidate | Licence | Size | Inflected forms | Quality | AGPL | MIT |
|---|---|---|---|---|---|---|
| **SCOWL / ESDB** (github.com/en-wl/wordlist) | MIT-like (BSD-compatible sources) | sizes 35–95; 70 = large, 80 adds word-game words | yes | offensive/vulgar tags, spelling variants | yes | yes |
| ENABLE / ENABLE2K | public domain | ≈ 173 k | yes | made for word games; dated | yes | yes |
| dwyl/english-words | Unlicense, provenance unclear | ≈ 470 k | mixed | junk, proper nouns | no | no |
| commercial tournament lists | proprietary | – | – | – | no | no |

**Other app locales** (Hunspell, affix expansion needed): fr Grammalecte MPL-2.0; es RLA-ES GPL-3.0/LGPL-3.0/MPL-1.1;
nl OpenTaal BSD-3-Clause or CC BY 3.0; pl **SJP.PL word-game list** (published for word games) GPL-2.0 or CC BY 4.0;
it GPL-3.0 (AGPL app only); tr MIT (quality unverified).

**Legal note:** single words are facts, but a list can carry the EU database right (Directive 96/9/EC, § 87a UrhG)
when it took substantial investment: use licensed lists, never scraped ones.

**Recommendation:**
- **de:** enz/german-wordlist (CC0, made for games, works with any app licence). Before adopting: check the word
  count, that inflected forms are in ("Häuser", "lief", "gingen"), its case convention, and filter to words our
  tiles can spell (`TileSet.canSpell`). Fallback: LanguageTool german-pos-dict full forms, filtered by tag (the
  derived list stays CC BY-SA, with attribution on the licence page).
- **en:** SCOWL size 70 (or 80), offensive tags dropped. Fallback: ENABLE (public domain).
- **others later:** pl SJP.PL game list (CC BY 4.0), fr / es / nl from Hunspell (MPL / LGPL / BSD).
- **Bundle and lookup:** a de full-form list is a few MB raw, roughly a quarter to a third of that gzipped; ship
  it as a compressed asset loaded on demand (only when a dictionary game starts, never in the main PWA bundle), one
  per language. Lookup: a sorted, normalized list with binary search is enough (a few µs per word, ~20 compares);
  a DAWG / succinct trie would cut memory and size further and also allows move generation (computer player),
  later. The `WordValidator` interface hides the choice.
- **Until then:** challenge mode works with no list at all; that is the MVP.

## Players
The engine runs 2–4 seats (`playerCount`, `currentSeat`, `scoreOf`, `rackOf(seat)`, `winnerSeats`); turn order,
end-game penalties and the view are per seat. The shared `Game` interface knows `Player.a` / `Player.b` only, so
seat 0/1 map to A/B and `currentPlayer` throws for seat 2+. **KLD-088 step 1:** `WordTilesGame implements
SeatGame` (`actorSeat`, `seatOfMove`, `seatResult` with places, `isSeatOut`), the registry creates
`GameConfig.players` seats (2–4, `maxPlayers: 4`), seat resign and seat-named allow moves with 3–4 seats,
`seatViewJson(seat)`, scoreless limit `max(6, 2n)`. Two seats are byte-identical to before (rules 3 unchanged).
One device only for now (the network refuses `players != 2`). Details in `docs/tasks/KLD-088-more-players.md`.

## Secrecy (KLD-064 pattern)
Racks and the bag order are hidden: `WordTilesRedaction` (`secretSeed: true`, the seed decides the bag).
- **View** (`viewJson` / `WordTilesView.fromJson`): board, scores, penalties, rack sizes, bag size, turn log,
  open challenge, end state, and the viewer's own rack. Never another rack, the bag or the seed. A view is
  read-only (`applyMove` null); its `legalMoves` are the viewer's on its turn.
- **Moves:** placements are public (the tiles go face up); another player's `exchange` shows only
  `{'action': 'exchange', 'count': n}`, so the host commits to it and reveals it at the end (the KLD-064
  commitments happen automatically for every redacted move). Event payloads hold no hidden data (counts only).
- Hot-seat: `hiddenInformation: true`, so the shell's handover cover hides the rack between players.

## Engine API (for step 2)
- `WordTilesGame({seed, tileSet = TileSet.german, playerCount = 2, check = WordCheck.challenge, validator,
  scorelessLimit})` (null limit = `defaultScorelessLimit(playerCount)`: 6 for 2–3 seats, 8 for 4); `debugSetup(racks:, bag:, board:)` for tests.
- Moves: `{'action': 'place', 'tiles': [{'row', 'col', 'tile', 'letter'?}]}` (`WordTilesGame.placeMove`),
  `{'action': 'exchange', 'tiles': [...]}`, `{'action': 'pass'}`, `{'action': 'challenge'}`, `{'action': 'accept'}`,
  common resign.
- `checkPlacement(move)` → `PlacementCheck` (`error`: `PlacementError` gap / notInLine / notConnected /
  firstNotOnCentre / …, or `words` (`FormedWord` with score and position), `score`, `bingo`): live score preview
  and refusal reasons for the UI.
- State: `tileAt`, `board`, `premiumAt` (static), `rackOf`, `rackSizeOf`, `bagCount`, `scores`, `rackPenalties`,
  `scorelessTurns`, `currentSeat`, `canChallenge`, `challengeable`, `endPending`, `canExchange`, `turns`
  (public log), `history`, `winnerSeats`, `result`.
- `legalMoves`: a **sample** (challenge/accept, opening pairs through the centre or every one-tile placement,
  exchange all, pass), enough for random play and the shared tests; not a move generator.
- Events: `place` → `words`, `score`, `bingo`, `drew` (count); `exchange` → `count`; `challenge` → `withdrawn`,
  `words`, `placer`, `score`.
- `WordValidator` (`isWord(word)`, words upper case and normalized): `AcceptAllValidator`, `WordListValidator`.
- `TileSet.german` / `TileSet.english` (`counts`, `points`, `blanks`, `normalize`, `canSpell`).

## Text adapter
`WordTilesText` (`dart run packages/klunki_engine/bin/klunki.dart wordtiles`): board with premium symbols, scores,
bag, the rack of the player to move (debug), an open challenge. Input: `h8 HAUS` (column first: across), `8h HAUS`
(row first: down); board letters are typed too and must match; lower case = blank; `pass`, `exchange QX?`,
`challenge`, `accept`. `autoMove` accepts, else plays the best-scoring sample move.

## Tests
`test/word_tiles_test.dart` (37 tests): layout counts and symmetry; tile sets recomputed from the frequencies;
deal and replay determinism; scoring by hand (centre double word, blank, letter premiums only on new tiles,
word premium, one tile doubling two words, main + cross words, bingo); every illegal placement kind and malformed
moves without state change; exchange (bag < 7 refused), pass; both end conditions with penalties, draw; challenge
with and without a word list, implicit / explicit accept, end pending; dictionary mode; three seats; redaction
(rack hidden, exchange count only, view round-trip with an open challenge and after resign, malformed views);
text adapter notation. Shared tests now cover `wordtiles` too: contract, resign, result codes (25 auto games),
secrecy (views agree all game long), compat golden, and in `klunki_net` a full random network game with the
host's reveal verified by the guest.

## Step 2 (hot-seat UI): what was built
- **Touched paths:** `klunki/lib/ui/games/wordtiles_screen.dart`, `lib/ui/games/wordtiles/{wordtiles_board,wordtiles_tiles}.dart`
  (new); `lib/ui/shell/screen_registry.dart` (`gameScreens`, `previewGames = {'wordtiles'}`, `hotSeatOnlyGames`),
  `lib/ui/menu_screen.dart` (debug-only "Vorschau: Wortgewandt" button under the debug console), `lib/ui/game_titles.dart`,
  `lib/ui/game_visuals.dart` (illustration, one-liner), `lib/app/theme.dart` (accent), `lib/ui/engine_l10n.dart` (both end
  reasons localized), ARB keys `menuGameWordTiles`, `menuDescWordTiles`, `menuPreviewGame`, `wordtiles*`,
  `engineReasonWordtiles*` in all 7 locales (zh written with the characters the bundled Noto Sans SC subset already has:
  no font re-subset, which would need a download); tests `test/ui/games/wordtiles_screen_test.dart`,
  `test/e2e/live_ui/wordtiles_{adapter,live_test}.dart`, `test/screenshots/wordtiles_shots_test.dart`, `wordtiles` added
  to the per-game lists of `test/l10n/{translations,rtl}_test.dart`, `test/ui/shell/game_screen_test.dart` (preview games).
- **Screen** (`WordTilesBoard`): score bar (token, name, score, end penalties, bag count), the last turn as a line or, for
  the player who may answer it, the challenge banner ("Anna (X) legte BIRNE für 11 Punkte." + "Anzweifeln" / "Annehmen";
  the open tiles ringed red; the challenge asks for confirmation and says that without a word list the challenger's call
  is final). Board 15 × 15 in our premium colours (word premiums green, letter premiums ochre / sand, labels 2W/3W/2B/3B,
  localized; star in the centre), always LTR. Rack below: drag a tile onto a square, or tap a tile and then a square; a
  laid tile goes back with a tap or a long-press drag. Blank → letter picker (A–Z, Ä Ö Ü; no ß, as the engine). Line above
  the rack: live words + score (`checkPlacement`), or the reason a placement does not fit (muted, red after "Legen").
  Actions in one row: take back, shuffle, zoom, "Tauschen" (rack turns into a picker; refused with a reason below 7 bag
  tiles), "Passen", "Legen". Phone: squares under 30 px zoom in (×~2) on the first tile laid and back out after the move;
  pinch-zoom any time. Tablet landscape: board left, panel right.
- **Hot-seat:** `hiddenInformation` → the shell's handover cover hides the rack; the cover shows the public last turn.
  Names via `PlayerLabelsScope` (no hard-coded names). History sheet: "X: HAUS für 8 Punkte", "O: 2 Steine getauscht", ….
- **appReady stays false** (🧑 decides after trying it): the name is open, there is no word list, and the layout is still
  to be checked by playing. Debug builds open it from the menu; release builds do not show it.
- **Tests:** 12 widget tests (tap and drag placement, preview score, invalid placement error, blank picker with cancel,
  challenge withdraw, accept / swap / pass + history, swap refused, 6 scoreless turns → result dialog with penalties, last
  tile → end pending → accept ends, phone auto-zoom, Arabic board LTR, debug menu entry); live UI: two full hot-seat games
  through the real UI (taps only, covers, challenges, swaps, passes; every turn shown once, in engine order; the final
  turn checked in the result dialog). Screenshots: `KLUNKI_SHOTS=<dir> flutter test test/screenshots/wordtiles_shots_test.dart`.
- **Open UX questions (🧑):** see "Open questions" 9–13.

## Step 4 (word lists, check at "Legen", bench): what was built
Approved by the maintainer 2026-11-02 (German and English; downloads limited to the two sources below).

- **Touched paths:** engine `lib/word_tiles.dart` (`SortedWordListValidator`, `WordLists`, `allow`,
  `unknownWords`, `checkPlacement(checkWords:)`, `WordTilesTurn.allowed`), `lib/registry.dart` (`GameConfig.tiles` /
  `.dictionary`, `GameSpec.createFrom`, rules 2), tests `word_lists_test.dart`, `compat_test.dart`; app
  `assets/wordlists/{de,en}/` (new), `tool/build_word_lists.py` (new), `lib/ui/games/wordtiles/{word_list_loader,
  gunzip_io,gunzip_web,wordtiles_options}.dart` (new), `wordtiles_board.dart`, `wordtiles_screen.dart`,
  `lib/ui/shell/screen_registry.dart` (`openGame` / `openGameFromMenu`), `lib/ui/menu_screen.dart` (preview button
  through `openGameFromMenu`), `lib/app/third_party_licenses.dart`, `lib/main.dart`, `pubspec.yaml`,
  `web/pwa_finalize.py`, ARB files, tests `wordtiles_dictionary_bench_test.dart`, `wordtiles_screen_test.dart`,
  `screenshots/wordtiles_shots_test.dart`; `README.md`, `docs/legal/third-party-data.md` (new), `AGENTS.md` (games
  table), BOARD.md.

**Sources and licences** (details, commits, hashes, filters: `klunki/assets/wordlists/{de,en}/SOURCE.txt`; licence
texts next to them as `LICENSE`, shown on the app's licence page via `registerWordListLicenses` in
`lib/app/third_party_licenses.dart`):

| | Source | Commit | Licence | Words (2–15 letters) | Raw / gzip |
|---|---|---|---|---|---|
| de | enz/german-wordlist `words` (685,829 lines) | `1071d87` (2026-09-13) | CC0-1.0 | 590,558 | 6.93 MB / 1.44 MB |
| en | English Speller Database (ESDB, formerly SCOWL) `data/scowl-pre.txt`, size ≤ 80 | `1e5b7d3` (2026-06-24) | MIT-like (Kevin Atkinson; main notice only: no size > 80, no AU data) | 190,787 | 1.94 MB / 0.50 MB |

- **en size 80, not 70:** 70 has 130,169 words and lacks typical word-game words (ZA, QAT, ZAX); 80 is "the strange
  and unusual words people like to use in word games" (ESDB README). The project's GitHub releases only carry
  Hunspell/Aspell dictionaries, so we parse the database text `scowl-pre.txt` ourselves (no make, no project
  scripts run); the small corrections the project's build applies on top (`data/fixes`, `extra`, …) are therefore
  missing. Dropped: offensive-* / vulgar-* groups (61), proper nouns / abbreviations (upper case in the source, name
  classes, `<abbr>`), prefixes / suffixes / contractions, uncommon (`-`) and misspelt (`x`) variants, AU-only data,
  and vowel-less unit symbols that ENABLE does not list (CM, KG, ML; HM, SH, BRR, TSK stay). US + GB + CA spellings.
  ENABLE (the fallback) was not needed.
- **de:** the list has no names, places or abbreviations by its own rules; we only normalize (ß → SS, upper case)
  and drop words over 15 letters or with letters our tiles lack (accents: Abbé, Ångström). **Inflected forms are in:**
  HÄUSER, LIEF, GINGEN, SCHÖNSTEN, BÄUME, ÄRGERTEN, FÜSSE (checked by `tool/build_word_lists.py check` and the app test).
- **Tool:** `klunki/tool/build_word_lists.py` (stdlib only, `python3 -I`, reproducible: gzip mtime 0, sorted by code
  point). The raw downloads stay outside the repo.

**Assets and loading:** `assets/wordlists/<id>/words.txt.gz`, one normalized word per line, sorted. Loaded on demand
by `WordListLoader.ensure` (`lib/ui/games/wordtiles/word_list_loader.dart`) only when a game with "Wörterbuch
prüfen" starts (a "Wörterbuch wird geladen …" dialog), once per app run. Decompression: natively `dart:io` `gzip` in
a background isolate (`compute`); on the web the browser's `DecompressionStream('gzip')` through `dart:js_interop`
(SDK, no package; `package:archive` is only a transitive dependency, so not used). A response the server already
un-gzipped is detected by the magic bytes. **PWA:** `web/pwa_finalize.py` no longer precaches the two
`words.txt.gz` (≈ 1.9 MB; their `LICENSE` / `SOURCE.txt` stay precached for the licence page); the service worker caches them cache-first on first use, so a game with the
list works offline once it was loaded online.

**Lookup:** `SortedWordListValidator` (engine): the UTF-8 bytes plus an `Int32List` of line starts (4 bytes per
word, no string per word: ≈ 9.3 MB for de), binary search (~20 compares). Measured on the desktop (Apple Silicon,
AOT exe; JIT in parentheses): de gunzip 11 ms + index/sort check 30 ms = **≈ 42 ms** (50 ms), en ≈ 13 ms (15 ms),
a lookup 0.1 µs; the app path in the test VM including `compute` and the asset bundle: de 113 ms, en 17 ms.
Estimate for a mid-range phone (3–5× slower): de 150–300 ms, en < 100 ms, in the background isolate; on the web
(main thread, JS) roughly 0.2–0.5 s desktop and up to ~1 s on a phone, plus the 1.4 MB download the first time.

**Engine** (`word_tiles.dart`, `registry.dart`; `rulesVersion` 2 for `wordtiles`, compat golden updated):
- `GameConfig.tiles` (`tiles`, tile set id, null = de) and `GameConfig.dictionary` (`dict`, written only when on):
  public config, old configs read as before. `createGame` takes the list from `WordLists` (registered by the app;
  `configProblem` reports a missing one). `WordLists.revisions` (list id + commit per language) is part of the
  fingerprint data, so builds with different lists will refuse a network dictionary game.
- **With a list: the check at "Legen" replaces the challenge** (the maintainer's model): `WordCheck.dictionary`. A
  placement with words the list lacks is refused unless the move names exactly those words in `allow`
  (`{'action': 'place', 'tiles': […], 'allow': ['BAU']}`), the players' joint "Trotzdem zulassen". The event and the
  public turn log carry `allowed` (`WordTilesTurn.allowed`, in the view too). No challenge step in this mode.
  `unknownWords(move)` answers the UI at "Legen"; `checkPlacement(move, checkWords: false)` is the preview, which
  never consults the list. Network later: the guest's placement with `allow` needs the opponent's consent first
  (a confirm round trip before the host applies it); the move format already records it.
- **Without a list:** challenge mode unchanged (the challenger's call is final). The engine's "challenge decided by
  a validator" path stays (tested: a valid word stands and the challenger loses the turn) but the app no longer
  uses it.
- Not done (hot-seat only for now): `klunki_net` rebuilds configs field by field (`guest.dart`
  `verifyRedactedGame`, `secrecy.dart`), so `tiles` / `dict` must be passed through there in step 3.

**App:**
- **Start options** (`wordtiles_options.dart`, before "Wer spielt?"; the debug "Vorschau: Wortgewandt" now goes
  through `openGameFromMenu`): tile language Deutsch / English (endonyms; default from the app language: de →
  German, every other language → English), "Wörterbuch prüfen" (on by default when a list exists for that
  language) with a one-line explanation of both modes.
- **Check at "Legen":** unknown words → "„BAU“ steht nicht im Wörterbuch." + "Ihr könnt die Steine zurücknehmen.
  Seid ihr euch einig, dass es trotzdem zählt, lasst es zu." with **"Zurücknehmen"** (tiles back on the rack, no
  penalty, same turn) and **"Trotzdem zulassen"** (placement counts; history: "BAU für 8 Punkte (zugelassen: BAU)").
  No ✓/✗ anywhere before "Legen" (the maintainer: an indirect dictionary is cheating). No per-device house-rule word
  list (dropped by the maintainer: every "Trotzdem zulassen" is an ad-hoc decision).
- **Bänkchen** (bench): 2 practice rows × 9 slots between the rack and the actions, collapsible ("Bänkchen ▾",
  collapsed by default when the board area is under 560 px high, e.g. a 375 × 667 iPhone; open on larger phones and
  tablets). Drag rack tiles in (or tap a tile, then a slot), move them between slots (a tile in the way swaps or
  goes back to the rack), drag them back to the rack, or lay them straight from the bench on the board (drag, or
  tap + square). Each row shows the **base score** of its words (runs of 2+ tiles, letter points only: premium
  squares count only on the board) and nothing about whether it is a word. "Alle Steine vom Bänkchen zurück" clears
  it. The bench is UI state only: the engine rack is unchanged; each player's arrangement is kept as letters per
  seat and matched to the rack again every turn (laid or swapped tiles drop out), across the handover cover (which
  hides it with the rack, `Offstage`) and undo; a new game clears it.
- 16 new ARB keys in 7 locales (zh written with characters already in the font subset).

**Tests:** engine `test/word_lists_test.dart` (sorted list lookup incl. umlauts, SS, first/last word, no final line
feed, unsorted refused; check at "Legen": known word, unknown refused, `allow` exactly the unknown words, refused in
challenge mode, survives the view; config JSON / tile set / list registration / fingerprint); app
`test/ui/games/wordtiles_dictionary_bench_test.dart` (known word without a notice and no challenge, "Zurücknehmen",
"Trotzdem zulassen" + history, start options de/en and the default language, bench: tap and drag in/out, between
slots, score, clear, laying from the bench, private per player behind the cover and back next turn, collapsing,
375 × 667 fit; the bundled lists loaded through the real loader: inflections, umlauts, SS, en words, no proper nouns /
unit symbols). Screenshots: `KLUNKI_SHOTS=<dir> flutter test test/screenshots/wordtiles_shots_test.dart --plain-name
kld094-step4` (iPhone SE 375 × 667, iPhone Max 430 × 932, iPad portrait and landscape: empty bench, a word with its
score, tiles laid, the unknown-word notice, the cover after "Trotzdem zulassen", the history; start options de / en).

**Still open:** recalibrate the tile sets on the lists' letter frequencies (step 1 plan; a rules + compat bump),
network (step 3), the 🧑 UX review before `appReady`.

## Step 5 (hot-seat polish): what was built
Goal: Wortgewandt fully playable on one device before other features. `appReady` stays false (the maintainer
releases it). Decisions on the open UX points (each is a small, local change to revert):
- **Score bar without names** (question 9): token + score per player, the rack penalty in brackets after the end;
  the names are in the shell's legend right above. The semantics label still says "Anna: 12 Punkte". Change back:
  `_scoreBar` in `wordtiles_board.dart`.
- **Auto-zoom kept** (question 11): in the 375 × 667 screenshots the first tile zooms the board so that the next
  squares are a comfortable 40 px; the zoom button and pinch still work, and the full live-UI game on a 375 × 667
  phone plays through it (it zooms out by the button when a square is outside the view, like a user). The threshold
  is `WordTilesBoard.autoZoomBelow` (squares under 30 px); set it to 0 to make zoom manual only.
- **"Passen" asks first** (question 12): a light dialog ("Passen?" / "Dein Zug endet ohne Punkte. Züge ohne Punkte in
  Folge: 2 von 6. Bei 6 ist das Spiel aus.", Abbrechen / Passen), because a pass ends the turn and counts towards the
  six scoreless turns. Change back: `_pass` in `wordtiles_board.dart`.
- **Blanks show a blue "0"** (question 13) in the corner, on the rack, the board and the bench; the letter picker
  says "Der Joker zählt 0 Punkte."; "So geht's" explains it.
- **Premium labels** (question 10): kept on the squares; the legend is in "So geht's".
- **Small phones:** on a narrow screen whose board area is less than its width + 300 px high
  (`WordTilesBoard.benchOverlayMargin`; iPhone SE and 390 × 844 portrait), the collapsed bench is a "Bänkchen" button
  in the score row (no row of its own), and the open bench lies over the lower part of the board like a bottom sheet
  (`wordtiles-bench-overlay`); the board keeps its size: about 285 px wide at 375 × 667 (was about 225 px with the bench
  open), the board moves to the top while the bench is open. Larger screens keep the bench in place. **Phone
  landscape** (667 × 375) uses the side panel; the actions now come right under the rack and the bench below them,
  so "Legen" stays on screen when the bench opens (the panel scrolls).
- **Game end:** the shell's result dialog gets an optional `resultDetail` (additive param in `GameScreen`, null for
  every other game): final score per player with "Reststeine: −8" / "+8", the best single word ("Bestes Wort: HAUS
  (Anna, 8 Punkte)", a placement withdrawn after a challenge does not count), and "Trotzdem zugelassen: …" for fun;
  "Nochmal" is the shell's button (same options, the word list stays on).
- **"So geht's":** a help button (?) in the score row opens a sheet (`wordtiles_help.dart`): the idea, the premium
  legend 2B/3B/2W/3W with their colours, the 50-point bonus for all 7 tiles, the blank (0 points), swapping (bag ≥ 7),
  passing (6 scoreless turns end the game), the dictionary check with "Trotzdem zulassen" and the challenge without
  it (the mode of the running game first), the bench, the end and the rack penalties.

**Touched paths (step 5):**
- `klunki/lib/ui/games/wordtiles/wordtiles_board.dart` (score bar, help button, pass confirmation, bench overlay,
  landscape order), `wordtiles_tiles.dart` (blank "0", picker note), `wordtiles_help.dart` (new),
  `klunki/lib/ui/games/wordtiles_screen.dart` (`WordTilesResult`), `klunki/lib/ui/shell/game_screen.dart`
  (`resultDetail`, additive)
- `klunki/lib/l10n/app_*.arb` + generated (22 keys: pass confirmation, blank note, help texts, result lines; zh with
  existing glyphs only)
- Tests: `klunki/test/ui/games/wordtiles_polish_test.dart`, `wordtiles_perf_test.dart` (new);
  `test/e2e/live_ui/wordtiles_adapter.dart` + `wordtiles_live_test.dart` (pass confirmation; a dictionary adapter);
  `test/screenshots/wordtiles_shots_test.dart` (`--plain-name kld094-step5`); pass confirmation taps in the existing
  wordtiles tests.

**Tests and measurements:**
- Live UI, `test/e2e/live_ui/wordtiles_live_test.dart`: besides the two challenge-mode games, two full hot-seat games
  with the German word list through real taps: a tablet (1180 × 820, seed 3: 96 moves, 84 placements, 1 "Trotzdem
  zulassen" (RH), 1 swap, 10 passes, end by 6 scoreless turns, 231 : 271) and an iPhone SE (375 × 667, seed 4:
  83 moves, 70 placements, allowed OO, 1 swap, 11 passes, 189 : 223). Each checks every turn on screen in engine
  order, the result summary (scores, best word, allowed words) and that "Nochmal" starts a new game with the list.
- Performance (`wordtiles_perf_test.dart`, phone 375 × 667, test VM): the dictionary load dialog opens and closes
  once; loading de takes ~100 ms here and the UI isolate's longest pause during it was 13 ms (decompressing and
  indexing run in a background isolate); a board with 54 tiles while laying / recalling: avg 10 ms, p90 23 ms per
  frame (debug mode, build + layout + paint, no GPU; the asserts are generous).
- Screenshots (`kld094-step5`): iPhone SE portrait and landscape, 390 × 844, iPad landscape: start, bench open with a
  word, tiles laid with the bench open and closed, pass confirmation, help (top and scrolled), the result (de, en,
  iPad), the dictionary loading dialog.

## Step 6 (network, 2 devices): what was built
Goal: Wortgewandt between two devices (direct TCP, WebSocket, relay) with the same rules as on one device.
`appReady` stays false; the debug preview has a "Mit anderen" link next to "Vorschau: Wortgewandt", and
`hotSeatOnlyGames` is empty, so the menu tile gets "Mit anderen" once the game is released. Protocol details:
`packages/klunki_net/PROTOCOL.md`, "Wortgewandt".
- **Config and fingerprint:** `tiles` and `dict` travel in the `welcome` config (they were already in
  `GameConfig.publicJson`; now the guest's redacted verification passes them on too). Rules version 3. Each list's
  identity in `WordLists.revisions` now ends in the SHA-256 of the bundled `words.txt.gz` (an app test checks it
  against the assets), and the revisions are in the content hash, so builds with different lists refuse each other
  ("incompatible-content"). `GameSpec.configProblem(config, wordList: false)` lets a guest join before its list is
  loaded; `NetworkGameSession` loads it right after (with the usual progress dialog), and the guest's view looks the
  list up lazily (`WordLists.of`).
- **Secrecy (KLD-064):** unchanged redaction (`WordTilesRedaction`, secret seed): own rack only, rack sizes, bag
  count, a host exchange as a count with a commitment, reveal + replay at the end. Checked after every move in the
  net tests over TCP, WebSocket and relay.
- **"Trotzdem zulassen" needs the other player (rules 3):** three engine moves naming the player, like the chess
  draw offer: `requestAllow {player, tiles, allow}` (the tiles lie on the board, shown with an open ring on both
  devices; nobody can move), `acceptAllow {player}` (the placement counts, `allowed` recorded, the turn passes),
  `declineAllow {player}` (tiles back to the rack, still the placer's turn, the same words cannot be asked again this
  turn; "Ben hat das schon abgelehnt. Nimm die Steine zurück."). `place` with `allow` is refused everywhere, so
  the host never counts an unknown word without agreement. At most one open request; it is in the view, so a guest
  that rejoins gets its dialog back. On one device the request and the agreement go in back to back (both players are
  at the device), so hot-seat plays as before; the history shows both moves.
- **UI:** at "Legen" the unknown-word notice is local ("Du kannst die Steine zurücknehmen oder Ben fragen, ob es
  trotzdem zählt."); the placer's status "Ben entscheidet…", the answerer's "Du entscheidest" and a dialog
  "Trotzdem zulassen? Anna möchte „BAU“ zulassen – einverstanden?" (Ablehnen / Annehmen); a line above the board on
  both devices while open ("Anna möchte „BAU“ zulassen (8 Punkte).") and after a decline ("Ben lehnt „BAU“ ab.").
  Waiting texts follow the shell ("Warte auf Ben…"). The options of a network game: a chip in the score row ("DE"
  plus a book icon with the word list; tooltip "Deutsch · Wörterbuch prüfen") and the line above the board before
  the first turn. Room: "Raum starten" (direct and relay) shows the tile language and "Wörterbuch prüfen" pickers for
  Wortgewandt, loads the list before hosting, and the waiting room names the options. The bench stays per device.
  Without a word list the challenge buttons work over the network (the next player challenges on their device).
- **Handover in hot-seat** (`GameController`): the cover now comes when the player to move changes (it used to be
  "a move by another player"), so the agreement of the other player does not cover the board twice.
- **KLD-108:** the preview's "Mit anderen" link is greyed and explains like the other network entries on an https
  page without a relay (covered by `web_beta_test.dart`).

**Touched paths (step 6):**
- Engine: `word_tiles.dart` (request/accept/decline, rules 3, list hashes), `word_tiles_view.dart`, `registry.dart`
  (`configProblem(wordList:)`, rules 3), `compat.dart`; tests `word_lists_test.dart`, `compat_test.dart` (golden).
- Net: `lib/src/guest.dart`, `lib/src/secrecy/secrecy.dart` (tiles/dict in the verification), `PROTOCOL.md`,
  `test/wordtiles_net_test.dart` (new).
- App: `wordtiles_board.dart`, `wordtiles_options.dart` (`WordTilesOptionsPicker`, summary), `wordtiles_screen.dart`,
  `pairing_screen.dart`, `relay_host_screen.dart`, `network_game_session.dart`, `menu_screen.dart`,
  `screen_registry.dart`, `game_controller.dart`, `l10n/app_*.arb` (15 keys, zh with existing glyphs only).
- Tests: `test/ui/games/wordtiles_network_test.dart` (new), `wordtiles_dictionary_bench_test.dart`,
  `menu_modes_test.dart`, `web_beta_test.dart`, `l10n/english_ui_test.dart`, `e2e/live_ui/wordtiles_adapter.dart` +
  `wordtiles_live_test.dart` (a network game), `screenshots/wordtiles_net_shots_test.dart` (new).

**Tests:** engine (allow handshake, decline/no repeat, view round trip, replay, lazy list); net
(`wordtiles_net_test.dart`: a scripted game with the list over TCP, WebSocket and relay with requests declined and
accepted by both sides, redaction checks after every move, verified end; the challenge game; rejoin with an open
request; mismatched list / rules refused; a guest without its list joins); app widget tests (own rack, options,
request both ways, decline, the rejected second ask); a live-UI network game through the Wi-Fi proxy with the
German list (seed 3: 102 moves, one request declined, one accepted, verified) besides the hot-seat games.

**Fix after merge (2026-11-02, CI on main failed under load):** the live-UI network game failed with the guest's
log one turn behind ("# 31 X … expected # 31 O …"). Harness, not product: the adapter read only the screen's
last-turn line, and under load the echo of the guest's own move and the host's quick answer reached the guest in
one frame, so the line went from turn 30 to 32 between two looks. The guest's controller and history sheet held
every move (the driver's "N newer trick(s) already played" counted them). The adapter now reports turns in order
like the chess one: a turn already replaced on screen comes from the device's own history before the line on
screen. Regression: `test/e2e/live_ui/wordtiles_adapter_test.dart` (two steps in one guest frame; both reported;
the history sheet lists both). `tool/stress_test.sh -n 5` on the live test: 5/5 (before: 0/3).
Second gap (stress gate on main, 1 of 3): the guest's last pass and the host's game-ending pass in one frame; the
result dialog came over the line before it showed the pass, and the driver does not look under a dialog. The driver
now asks the adapter once the result dialog is up (`LiveUiAdapter.unseenAtEnd`, default none): Wortgewandt returns
the unseen turns from the device's history, chess the moves still in the move list under the dialog. Regression:
a second case in `wordtiles_adapter_test.dart`.

## Step 7 (release): what was built
The maintainer released Wortgewandt in the app (2026-11-02, for the first bigger TestFlight release).
- **Registry:** `GameSpec('wordtiles', …)` without `appReady: false`. `appReady` is not part of the compat
  fingerprint (`compat.dart` hashes rules version and gameplay data only), so the rules version (3) and the
  goldens in `compat_test.dart` are unchanged; old and new builds still play together.
- **Menu:** the game is in `appGameSpecs`, so it gets a tile in registry order (the last one, next to Schach) with
  the illustration, accent and one-liner it already had (`game_visuals.dart`, `theme.dart`, `menuDescWordTiles`
  in 7 locales) and both links: "Ein Gerät" (start options, "Wer spielt?") and "Mit anderen" (the KLD-111
  start/join sheet; the room pickers list it via `networkGameSpecs`). `previewGames` is empty now; the debug
  preview mechanism ("Vorschau: {game}" in debug builds) stays for the next game.
- **Word lists:** still on demand in the PWA (`pwa_finalize.py` `ON_DEMAND`); `tool/check_pwa_external_urls.py`
  now also fails if `klunki_sw.js` precaches a `words.txt.gz` or misses the list licences. The licence page
  lists both lists (`registerWordListLicenses`: de enz/german-wordlist CC0-1.0, en English Speller Database /
  SCOWL by Kevin Atkinson), now covered by `test/app/third_party_licenses_test.dart`; the licences are also in
  `docs/legal/third-party-data.md` and the README.
- **Store:** App Store / Play scene `09-wordtiles` (`screenshots_test.dart`, store language tiles), texts in
  `docs/APPSTORE.md` and `docs/PLAYSTORE.md` (eight games, a Wortgewandt line, keyword "wortspiel" / "word
  game"; Play takes 8 screenshots per device type, so one of the nine is left out there).
- **Tests:** menu, pairing, l10n and web-beta tests now expect the tile instead of the preview link.
- **Screenshots** (`--plain-name kld094release` in `wordtiles_shots_test.dart`): the menu scrolled to the
  Wortgewandt tile on a small (375 × 667) and a large phone (430 × 932), de light and dark, ar.

## Step 8 (playtest fixes): what was built
Maintainer playtest of the release (2026-11-02).
- **Bug "fewer tiles than a full rack while the bag still has tiles": a UI bug, not the engine.** Tiles on the
  Bänkchen were left out of the rack row, and the bench keeps its tiles across turns (by design, step 4). On a
  small phone the bench starts collapsed (a button in the score row), so tiles parked there and the bench closed
  again were nowhere on screen: after the next turn the engine had refilled the rack to 7, but the screen showed
  e.g. 5 tiles, and the player played on with the short rack. On larger screens the same happened once the bench
  was collapsed. The engine was checked on every path that changes a rack (place, request / decline / accept
  "Trotzdem zulassen", exchange, pass, challenge and its withdrawal, the views a guest gets): a new engine test
  plays 60 random games (challenge mode with and without a list, dictionary mode with requests answered both
  ways) and checks after every move that every seat holds 7 tiles unless the bag is empty and that every view
  shows the same rack sizes. It passed before the fix, so **no rules change, rules version stays 3**, goldens
  unchanged.
- **Fix** (`wordtiles_board.dart`): a closed bench hides nothing, its tiles are back in the rack (the
  arrangement is kept and returns when it opens). Open, a bench tile leaves a gap in the rack
  (`wordtiles-rack-gap-<i>`, a tap brings the tile back), so the rack always reads as 7. The tiles of an open
  "Trotzdem zulassen" request are matched to rack tiles off the bench first.
- **Layout:** the bench is below the actions ("Tauschen / Passen / Legen"), rack and actions right under the
  board, and closed by default on every screen (the "Bänkchen ▸" line). The small-phone overlay from step 5
  stays: there the closed bench is a button in the score row and the open one lies over the lower board.
- **One-time explanation** (`wordtiles_bench_coach.dart`): the first time a player opens the bench on their
  turn, three short steps with a small picture (sample tiles "WORT"/"WORD", their score, the ↓ button): "Das
  Bänkchen ist dein Notizzettel …", "Hier zählen nur die Punkte der Buchstaben …", "Mit diesem Knopf legst du
  alle Steine zurück. Dein Bänkchen siehst nur du." with "Weiter" / "Verstanden" and "Überspringen" on every
  step; once per device via `SeenTips.wordtilesBench` (KLD-107 mechanism). It opens over an empty bench and shows
  sample tiles only, so in hot-seat it reveals nothing (the handover cover is down, it is that player's turn).
  7 locales (zh in characters the web subset already has).
- **Tests:** engine `rack refill invariant` group; widget `wordtiles_playtest_test.dart` (written first, failed
  before the fix: tiles on a closed bench not on screen; small and large phone; the explanation's steps, skip,
  never again); bench / polish tests open the bench first; the live-UI adapter now parks unused tiles on the
  bench now and then (closing it again; on a small phone always) and checks before every turn that each seat
  holds min(7, tiles left) and that every rack tile is on screen (with the old rack code the phone game fails at
  once: "rack tile 4 of 7 not on screen").
- **Screenshots** (`--plain-name kld094-bench` in `wordtiles_shots_test.dart`): small (375 × 667) and large
  (430 × 932) phone in German, a phone in Arabic: start, the three explanation steps, the open bench, tiles on the
  bench with gaps in the rack, the bench closed with the full rack.

## Step 8b (layout: vertical space): what was built
Maintainer feedback on the step-8 screenshots: on a large phone (430 × 932) the board was centred in a flexible
area (about 50 px empty above it, 45 px below it) while the open Bänkchen ran to the bottom edge.
- **Portrait** (`wordtiles_board.dart`): score row, last-turn line (reserved, so the board never jumps), board,
  preview line, rack, actions, the bench, then the leftover space at the very bottom. The board is a `Flexible`
  (`wordtiles-board-area`), as wide as the screen; it only gets smaller when the rest does not fit.
- **Overlay or smaller board:** the open bench lies over the lower board (step 5) only on phones where the bench
  below would shrink the board by more than 15 % (`benchMinBoardShare`, `benchOverlayMargin` 325 px ≈ everything
  but the board with the bench open), e.g. 375 × 667, 360 × 760. 390 × 844 / 375 × 812 now give up 6–9 % of the
  board for the bench below the actions; 412 × 915 and 430 × 932 keep the full board. Tablets in portrait
  (≥ 600 px wide) never use the overlay: their board gets a little smaller.
- **Landscape** (board left, scrolling panel right) from 480 px wide instead of 640: a small phone in landscape
  (568 × 320) used to overflow the column layout.
- **Tests:** `wordtiles_layout_test.dart` (with the bundled Roboto, so heights match the app): board right under
  the score row, rack ≤ 32 px under the board, leftover below the controls, open bench fully visible on large and
  mid phones, overlay over the lower board on small phones, tablet portrait / landscape, no overflow on any size
  (failed on the old layout). Screenshots `--plain-name kld094-layout`: 375 × 667, 390 × 844, 430 × 932, iPad
  portrait and landscape, bench closed and open. No rules change.

## Step 8c (Bänkchen open by default where it fits): what was built
Maintainer: "why not have the Bänkchen open by default, if space allows it".
- **Start state** (`WordTilesBoard.benchOpenFits`): open when it fits below the controls without making the board
  smaller: in portrait the board area is at least its width + `benchOverlayMargin` (325 px) high (430 × 932,
  412 × 915, 402 × 874), in landscape the panel shows it without scrolling (`benchOpenPanelHeight` 380 px, e.g.
  1180 × 820). Tablets in portrait (≥ 600 px wide, e.g. 820 × 1180) start open too although their board gets about
  10 % smaller: the empty slots invite to use the bench (maintainer). Closed elsewhere: small phones (overlay),
  mid-size phones (390 × 844, 393 × 852, 375 × 812), whose board would shrink, and short landscape phones
  (932 × 430, 568 × 320).
- **The player's choice** (open or close by hand) holds for the rest of the game, for both players (contents stay per
  player and under the handover cover as before); a new game starts by screen size again. Not stored per device
  (kept simple).
- **Explanation** (`showBenchCoach`, `SeenTips.wordtilesBench`, once per device): the first time the bench is
  visible on a player's own turn, opened by hand or open from the start; in hot-seat only once the handover cover is
  gone, never over another dialog. Checked two frames later, so a first frame with a passing taller layout (seen in
  Arabic) does not trigger it under a closed bench.
- **Tests:** `wordtiles_playtest_test.dart` (now with Roboto): open at the start on 430 × 932, 412 × 915, 1180 × 820,
  820 × 1180, closed on 390 × 844, 375 × 667; the choice holds across turns; the explanation shows without a tap
  where the bench starts open, once, and waits for the handover cover; layout tests check the start state per size.
  Screenshots `--plain-name kld094-layout`: `-1-start` (open on 412 × 915, 430 × 932, iPad portrait and landscape;
  closed on 375 × 667, 390 × 844), `-2-bench-closed`, `-3-bench-open`. No rules change.

## Step 8d (move laid tiles by long-press): what was built
Maintainer playtest on an iPhone 15 Pro ("very nice: seamless zoom, scrollable board"): a tile laid this turn
should move by long-press and drag, besides tap to take it back.
- **Long-press and drag** a tile laid this turn (not yet "Legen"): onto a free square it moves there, the chosen
  letter of a blank goes with it (no second picker); onto another tile laid this turn the two **swap** places;
  onto the rack it goes back, onto the Bänkchen into that slot. Onto a tile of an earlier turn, or anywhere else,
  nothing happens and the tile stays on its square. Tiles of earlier turns never move. The preview line follows
  every move.
- **Gestures:** a tap still takes the tile back; a plain pan (no long press) still scrolls the zoomed board, pinch
  still zooms. The dragged tile is at least finger size and as big as on screen when zoomed in. The board is
  left-to-right in every locale, so the drop square is the one under the finger in RTL too.
- **Tests:** `wordtiles_move_tiles_test.dart` (tap removes, move, swap, back to rack and onto the bench, refused onto
  an earlier tile, blank keeps its letter, zoomed phone: drag moves and a pan scrolls, Arabic). Screenshots
  `--plain-name kld094-8d` (`-drag-de-phone` mid-drag, `-dropped-de-phone`). No rules change (UI only).

## Step 8e (Bänkchen tiles as big as the rack where there is room): what was built
Maintainer playtest in a desktop browser: "you pick a letter in big and it shrinks to an artificially smaller bench
size". Correction: on phones smaller bench tiles are fine (no scrolling); where there is room they should match.
- **Size:** the bench may use up to 600 px (`WordTilesBoard.benchMaxWidth`, the rack keeps 420) and its tiles grow up
  to the rack tile size (`tileMax` 54, `_rackTileSize`); wider than a phone (> 440 px) the slots sit a little closer
  (gap 3, score column 30). Bench tile / rack tile: 1440 × 900 and 1280 × 800 100 %, 820 × 1180 100 %, 1180 × 820 ≈ 90 %
  (the side panel next to the board); phones unchanged (390 × 844 ≈ 64 %, both rows without scrolling).
- **Tests:** `wordtiles_bench_size_test.dart` (bench tile ≤ rack tile everywhere, ≥ 90 % on tablets and browser widths,
  no overflow); layout tests unchanged and green. Screenshots `--plain-name kld094-8e` (`-bench-de-desktop-1280x800`,
  `-desktop-1440x900`, `-tablet-landscape`, `-tablet-portrait`, `-phone`). No rules change.

## Step 8f (the Bänkchen handle where the bench opens): what was built
Maintainer feedback (iPhone 15 Pro): on phones where the open bench lies over the lower board, the "› Bänkchen" link
sat in the score row above the board, far from where the bench appears.
- **Which phones:** every layout with the bench overlay, i.e. 320 × 568 to 375 × 667, 360 × 760, and also 393 × 852 /
  390 × 844 *with* their iOS safe areas (top 59 / 47, bottom 34): their board area is too short for the bench below
  the actions. Without safe areas 393 × 852 keeps the bench below the actions (unchanged).
- **Handle:** a slim bar (`wordtiles-bench-bar`, 26 px, `WordTilesBoard.benchBarHeight`) right under the board, above
  the score preview line and the rack: closed a tab "› Bänkchen" at the start side, open the full-width foot of the
  overlay ("⌄ Bänkchen", "clear" at the end), which grows upwards from it. The tap area (`wordtiles-bench-toggle`) is
  48 px high and the whole bar wide; it reaches down over the preview line (text only). The score row is now only as
  high as its buttons (32 instead of 48), so the board is ≈ 6 px smaller (375 × 667: 268 instead of 274 px). The ↶
  take-back stays icon-only in the actions row (KLD-117); cover and coach unchanged. Other layouts unchanged.
- **Tests:** `wordtiles_layout_test.dart` (handle between board bottom and rack top, ≥ 44 px tap area, opens and
  closes from the same spot, overlay on top of it, no overflow on 320 × 568, 360 × 640, 375 × 667, 360 × 760,
  393 × 852 and 390 × 844 with safe areas; RTL; no bar where the bench is below), `wordtiles_polish_test.dart`.
  Screenshots `--plain-name kld094-8f` in `undo_shots_test.dart` (`-open-`/`-closed-de-375x667`,
  `-de-393x852-safe`, `-ar-375x667`). No rules change.

## Step 8g (iPhone 15 Pro playtest of 0fb20a1): moving laid tiles, handle as wide as the board, names, zoom hint
- **Moving laid tiles did not work on the phone.** Cause: the tile was a `LongPressDraggable` with Flutter's default
  500 ms delay and no sign before it was over, inside the board's `InteractiveViewer`. A finger that rests "long" for
  0.3–0.45 s and then moves exceeds the touch slop before the half second: the drag recognizer gives up, the
  viewer's pan wins (zoomed: the board scrolls; unzoomed: nothing at all, the board cannot pan). The widget tests
  held exactly 600 ms without wobble, so they passed. On top of that the lifted tile used the default anchor: the
  unzoomed offset into a tile shown bigger, so it hung up to ≈ 14 px beside the finger and landed a square off from
  where it was shown on the unzoomed board. Not caused by the step 8f bar (hit tests over the whole board are
  clean). Fix: zoomed, a laid tile lifts after 250 ms (`laidTileHold`; a plain pan still scrolls); unzoomed after
  120 ms (`laidTileHoldUnzoomed`; two fingers starting on a tile still zoom); the lifted tile keeps the spot under
  the finger; the draggable follows the zoom (`ValueListenableBuilder` on the transformation).
- **Handle and open bench as wide as the board** on overlay phones: board and handle are laid out together
  (`_BoardWithHandle`, the board as big as width and height after the handle allow, both centred), so the bar, the
  closed tab and the overlay line up with the board's edges (RTL too). Before, they were ≈ 4–5 px wider per side
  on 393 × 852 with safe areas.
- **Names next to the scores:** "① Anna 8  ② Ben 0" in the score row (the player labels the shell uses, "Anna (1)" for
  same names); names ellipsize first, the row only scales down when even tokens and scores do not fit. The shell's
  players legend is off for this game (`GameScreen.showPlayersLegend: false`), other games keep it.
- **Two-finger zoom:** the hint line from the second word on adds "Mit zwei Fingern zoomst du." while the board is
  not zoomed (`wordtilesHintZoom`; not to the one-line first-word hint, which would wrap and shrink the board on the
  first turn); "So geht's" has a line on zoom and moving a laid tile (`wordtilesHelpZoom`). 7 locales.
- **Tests:** `wordtiles_move_tiles_test.dart` group "iPhone 15 Pro, a real finger" (393 × 852 with safe areas,
  frames of 16 ms, rest 160–700 ms with wobble, zoomed and unzoomed, anchor, pinch on a tile, tap, rack drag, bench;
  7 of them fail on 0fb20a1), `wordtiles_layout_test.dart` (edges), `wordtiles_score_names_test.dart` (320–430 px,
  long names, RTL, network names, same names, hint, help). Screenshots `--plain-name kld094-8g` in
  `undo_shots_test.dart`. No rules change.

## Step 9 (house rule "Joker tauschen"): what was built
Maintainer request (2026-11-04): the well-known house rule, as an option at game start, **off by default**.

**Rules as implemented (rules version 4):**
- A player who holds the letter that a laid blank stands for may, **on their turn and before laying**, put that
  letter on the blank's square and take the blank onto the rack. One or more swaps per turn (each needs its own
  letter on the rack; a square only once).
- The swap is **part of a placement**: the same turn must lay at least one tile ("simplest fair variant"). The
  blank taken may be laid in that placement (with any letter) or kept. No swap alone, none with "Tauschen"
  (exchange) or "Passen": those moves refuse a `swaps` key.
- The swap itself scores nothing and changes no score; the old word stays as it is. From then on the square is a
  real letter: a word laid through it (in this turn or later) counts its points, like any letter on the board.
- Withdrawn after a challenge (no word list): the blank goes back onto its square and the rack is restored, as for
  the tiles. "Trotzdem zulassen" (word list): the request carries the swaps; they happen only when the other player
  agrees.
- Public information: the board change and the swap are in the move, the view and the turn log (`swaps`: how many);
  the opponent learns that the blank went to the rack (as at a real table). Nothing else of the rack is revealed.

**Engine / protocol:**
- `GameConfig.jokerSwap` (JSON `joker: true`, written only when on, so every default config and the content hash are
  unchanged); `WordTilesGame(jokerSwap: …)`; the view has `jokerSwap: true` only when on.
- `place` (and `requestAllow`) take an optional non-empty `'swaps': [{'row', 'col', 'tile'}]` (`JokerSwap`,
  `WordTilesGame.placeMove(tiles, swaps: …)`); refused when the option is off, the square holds no blank or a blank
  for another letter, the letter is not on the rack, a square repeats, or the list is malformed. `checkPlacement`
  applies the swaps first (the blanks join the rack for the check); `canSwapJokerAt(row, col, letter)` for the UI.
  The event, the turn log (`WordTilesTurn.swaps`) and the open request (`allowRequest.swaps`) show them.
- **Rules version 3 → 4** (the move format changed: an old build would refuse a swap); the content hash is the same
  (`compat_test.dart` golden `(4, 1, 9cf165a9…)`). `protocolVersion` unchanged: the only new wire data are the
  optional `joker` config key and the `swaps` move field, and mismatched builds refuse each other by the rules
  version anyway. `PROTOCOL.md` documents both. `verifyRedactedGame` takes `jokerSwap`.
- Debug console: `h8 HAUS joker f7` (the blank on f7 is taken first), shown in `help` when the rule is on.

**UI:**
- Start options (and "Raum starten" for a network room, where the host picks): a "Joker tauschen" switch under
  "Wörterbuch prüfen" with a one-line explanation (`wordtiles-joker`, `wordtiles-joker-explain`); the room line /
  header summary adds "· Joker tauschen".
- In the game: drag a matching rack (or bench) tile onto a laid blank, or tap the tile and then the blank. The swap
  is **staged** until "Legen": the real letter shows on the square like a tile laid this turn
  (`wordtiles-swapped-<row>-<col>`, a tap takes the swap back, together with the freed blank wherever it lies),
  the blank appears at the end of the rack. With only a swap staged, "Legen" stays disabled and the line under the
  board says "Joker genommen. Lege jetzt noch Steine, sonst gilt der Tausch nicht." "Alle zurück", "Tauschen",
  "Zurücknehmen" (unknown word) drop the staged swaps.
- Hint line when a swap is possible: "Ziehe den passenden Buchstaben auf einen Joker auf dem Brett, um den Joker
  zu nehmen."; history "… (Joker getauscht)"; "So geht's" explains the rule and says whether it is on in this game.
  7 locales (Chinese reworded to stay inside the font subset: "自选玩法" for "house rule").
- **Tests:** `packages/klunki_engine/test/word_tiles_joker_test.dart` (config, valid swap and its score, the blank
  laid in the same turn, every refusal, no swap alone / with exchange / pass, several swaps, replay through JSON
  and from a config, redaction and view round trip, withdrawal after a challenge, "Trotzdem zulassen" with swaps,
  text adapter); `klunki/test/ui/games/wordtiles_joker_swap_test.dart` (tap and drag staging, undo by tap and by
  "Alle zurück", "Legen" sends the swap, option off, help, the start option through the menu). Live UI:
  `wordtiles_live_test.dart` "Joker tauschen" seeds 1 and 4 (`WordTilesJokerAdapter`: lays blanks when it can and
  swaps through the UI, rack tile then blank, whenever a letter matches; full hot-seat games, every turn shown once).
- Screenshots `--plain-name kld094-step9` in `wordtiles_shots_test.dart` (options de/en, hint, staged swap,
  placement, handover, help on 390 × 844 and 375 × 667).

**Open for the maintainer:** (a) swap allowed only with a placement (implemented) or also as a turn of its own?
(b) may a blank that was laid in the opponent's still challengeable placement be swapped (now yes; laying accepts
that placement anyway)? (c) the hint line shows every turn while a swap is possible: keep, or show once per game?

## 3–4 players on one device (assessment; engine part done in KLD-088 step 1, UI next)
The engine is ready (seats 0–3, turn order, penalties, view per seat, tested with 3 seats). Everything around it
assumes two:
- **Engine interface:** `enum Player { a, b }`; `GameResult.winner` is one `Player`; `Game.currentPlayer`,
  `playerOf(move)`, `resignMove(player)` and `WordTilesGame.playerOfSeat` (null beyond seat 1) are 2-player.
- **Shell (`game_screen.dart`):** the turn pill and turn edge colour by `Player`; `_PlayersLegend` loops over
  `Player.values`; the result dialog shows one winner token or "draw" (no ranking, no shared win of 2 of 3); resign
  asks "who?" over `Player.values` and names "the other" as winner; `PlayerLabels` / `PlayerToken` map `Player` to
  name, colour and symbol.
- **Names:** `HotSeatNames(x, o)` with two prefs keys; "Wer spielt?" has two fields; `defaultPlayerName` A/B only.
- **Handover cover:** fine as is (it names the player to move), once `currentPlayer` can be seat 2–3.
- **Transport/controller:** `HotSeatTransport.localPlayers = {a, b}`; `GameController` compares `Player`s.
- **Board:** already loops over `playerCount` (score bar, last turn); the bench is per seat.

**Effort:** a Wortgewandt-only mode that bypasses `Player` (seat ints inside the word screen, its own names
dialog with 2–4 fields, its own score/result sheet, the shell's pill and legend hidden for it) is about 2–3 days but
duplicates shell logic and has to be undone later; the protocol stays 2-player either way. Widening `Player` to
seats in KLD-088 (engine interface, results with ranking, shell legend/pill/result/resign, names store, protocol
and fingerprint) is ~1–2 weeks across all games, after which Wortgewandt needs about a day (lift `playerOfSeat`'s
limit, a player-count option). **Recommendation: wait for KLD-088.**

## Step plan
1. **Engine (done).** This card.
2. **Hot-seat UI:** board (premium colours of our own, not any product's), rack below with drag-to-board and
   tap-to-place, blank letter picker, live score preview and refusal reason from `checkPlacement`, "Legen",
   "Tauschen" (pick tiles), "Passen"; after a placement the next player sees "Anzweifeln / Akzeptieren"; the
   handover cover hides the rack; scores, bag count, turn log; localized end reasons (7 locales); menu tile and
   illustration; `appReady: true`.
3. **Network:** the redaction is ready and tested at engine/net level; app: host pickers, the guest's rack from
   its view, the challenge buttons over the network, an e2e test.
4. **Dictionary per language (done for hot-seat, see "Step 4"; tile recalibration still open):** download and filter the approved list(s), build a compact
   asset per language, a lazy loader, `WordListValidator` on a sorted list (or DAWG); mode picker ("Anzweifeln" /
   "Wörterbuch"); recalibrate the tile sets on the list's letter frequencies (rules + compat bump).
5. **Hot-seat polish (done, see "Step 5").**
6. **Network (done, see "Step 6").**
7. **Release (done, see "Step 7").**
8. **Playtest fixes (done, see "Step 8"; follow-ups "Step 8b" to "Step 8f").**
9. **House rule "Joker tauschen" (done, see "Step 9").**
10. **Pause/resume (KLD-079) and async play:** games last 20–60 minutes, so save and resume (the move log replays;
   the secret seed and salts are saved on the host) and later play-by-turns over the relay.

## Open questions (🧑)
1. ~~**Name**~~: decided, **Wortgewandt** (see "Naming and IP").
2. ~~**Word list**~~: approved 2026-11-02 (de enz/german-wordlist, en ESDB/SCOWL; size 80 chosen, see "Step 4").
3. **Challenge without a list:** should the challenger's call be final (current), or should the placer be able to
   insist (then a tie-break, e.g. the word stands and the challenger loses the turn)?
4. ~~**Unsuccessful challenge penalty**~~ (with a list): moot, with a list the check at "Legen" replaces the challenge (maintainer, 2026-11-02).
5. **Who may challenge with 3–4 players:** only the next player (current) or anyone? (moved to KLD-088)
6. **Exchange threshold:** at least 7 tiles in the bag (current) or at least as many as exchanged?
7. **Layout:** keep the layout above, or tune after playing it in step 2?
8. ~~**Tile language per game**~~: picked at game start, default from the app language (step 4).
9. ~~**Score bar vs shell legend**~~: names dropped from the score bar (step 5).
10. ~~**Premium labels**~~: kept, legend in "So geht's" (step 5).
11. ~~**Auto-zoom on phones**~~: kept (step 5; `autoZoomBelow` = 0 makes it manual).
12. ~~**"Passen" without a confirmation**~~: a light confirmation now (step 5).
13. ~~**Blank tiles**~~: a blue "0" on the tile and a note in the picker (step 5).
