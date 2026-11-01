# KLD-094: Word tile game "Wortgewandt" (crossword-style)

- **ID:** `KLD-094`
- **Title:** A crossword-style letter tile game (id `wordtiles`)
- **Milestone:** long-term games
- **Status:** step 1 DONE (research, design, engine, text adapter, tests); step 2 DONE as a debug-menu preview
  (hot-seat screen, `appReady` still false until the 🧑 UX review; name decided: Wortgewandt); steps 3–5 open, see "Step plan"
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
seat 0/1 map to A/B, `currentPlayer` throws for seat 2+, and the registry creates 2 seats. KLD-088 (3–4 players)
widens `Player`, `GameResult` and the protocol; the engine then only needs its seat mapping opened up.

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
  scorelessLimit = 6})`; `debugSetup(racks:, bag:, board:)` for tests.
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

## Step plan
1. **Engine (done).** This card.
2. **Hot-seat UI:** board (premium colours of our own, not any product's), rack below with drag-to-board and
   tap-to-place, blank letter picker, live score preview and refusal reason from `checkPlacement`, "Legen",
   "Tauschen" (pick tiles), "Passen"; after a placement the next player sees "Anzweifeln / Akzeptieren"; the
   handover cover hides the rack; scores, bag count, turn log; localized end reasons (7 locales); menu tile and
   illustration; `appReady: true`.
3. **Network:** the redaction is ready and tested at engine/net level; app: host pickers, the guest's rack from
   its view, the challenge buttons over the network, an e2e test.
4. **Dictionary per language (🧑 approval first):** download and filter the approved list(s), build a compact
   asset per language, a lazy loader, `WordListValidator` on a sorted list (or DAWG); mode picker ("Anzweifeln" /
   "Wörterbuch"); recalibrate the tile sets on the list's letter frequencies (rules + compat bump).
5. **Pause/resume (KLD-079) and async play:** games last 20–60 minutes, so save and resume (the move log replays;
   the secret seed and salts are saved on the host) and later play-by-turns over the relay.

## Open questions (🧑)
1. ~~**Name**~~: decided, **Wortgewandt** (see "Naming and IP").
2. **Word list for German:** OK to download enz/german-wordlist (CC0) for a check of coverage and size? English
   SCOWL 70 (or ENABLE)?
3. **Challenge without a list:** should the challenger's call be final (current), or should the placer be able to
   insist (then a tie-break, e.g. the word stands and the challenger loses the turn)?
4. **Unsuccessful challenge penalty** (with a list): lose the turn (current) or a point penalty?
5. **Who may challenge with 3–4 players:** only the next player (current) or anyone?
6. **Exchange threshold:** at least 7 tiles in the bag (current) or at least as many as exchanged?
7. **Layout:** keep the layout above, or tune after playing it in step 2?
8. **Tile language per game:** follow the app locale, or pick it when starting a game (a German family may want
   English tiles for practice)?
9. **Score bar vs shell legend:** the shell's player legend (top right) and the score bar both show the names; drop the
   names from the score bar (token + score only) to save a line on phones?
10. **Premium labels:** "2W / 3W / 2B / 3B" (de) on the squares, colour-coded; enough, or a legend / long-press help?
11. **Auto-zoom on phones:** zoom in on the first tile laid (current), or only by pinch / the zoom button?
12. **"Passen" without a confirmation** (hot-seat undo exists): OK, or ask first?
13. **Blank tiles** show their letter in blue without points; clear enough?
