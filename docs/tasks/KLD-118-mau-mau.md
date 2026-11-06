# KLD-118: Mau-Mau (shedding card game)

- **ID:** `KLD-118`
- **Title:** The classic shedding card game Mau-Mau (id `maumau`)
- **Milestone:** long-term games
- **Status:** IN_PROGRESS (step 1 engine ✅, step 2 hot-seat UI ✅; step 3 network later). Added 2026-11-02 by the
  maintainer.
- **Depends on:** KLD-064 (redaction), KLD-085 (fingerprints); KLD-088 (3–4 players) for more than 2 players
- **Touched paths:**
  - `packages/klunki_engine/lib/{mau_mau,mau_mau_view}.dart`, `lib/debug/mau_mau_text.dart`, `registry.dart`
    (`GameConfig.mauMau`, JSON `maumau`), `game.dart` (`GameEndReason.maumauEmptyHand`), tests
  - `klunki/lib/ui/games/maumau/{maumau_screen,maumau_cards,maumau_options}.dart`,
    `klunki/lib/ui/shell/screen_registry.dart`, `game_titles.dart`, `game_visuals.dart`, `engine_l10n.dart`,
    `app/theme.dart` (accent), `klunki/lib/l10n/**` (69 keys `maumau*`, `menuGameMauMau`, `menuDescMauMau`,
    `engineReasonMaumauEmptyHand`)
  - tests: `packages/klunki_engine/test/mau_mau_test.dart`, `klunki/test/e2e/live_ui/maumau_live_test.dart`,
    `klunki/test/screenshots/maumau_shots_test.dart` (group `kld118`)

## Goal
Players take turns laying a card that matches the top card of the pile by suit or rank, or draw. The first player
without cards wins. Plays with a standard 32-card deck. Hot-seat first, network later, 3–4 players with KLD-088.

## Steps
1. ✅ **Engine** (`mau_mau.dart`): deterministic (config + seed + moves = replay; the deal and every reshuffle come
   from the game's own `Random(seed)`), JSON moves, per-player view and redaction (`MauMauView`,
   `MauMauRedaction`: opponent's hand and the draw pile only as counts, drawn cards hidden, secret seed), text
   adapter for the debug console / CLI (`dart run klunki_engine:klunki maumau`), registered with rules version 1
   and its compat golden. The network layer already plays it end to end in `klunki_net`'s random-game test (the
   engine side is network-ready), but the app does not offer it over the network yet.
2. ✅ **Hot-seat UI** (`klunki/lib/ui/games/maumau/`): own card faces painted in Flutter (white card, rank and
   suit in two corners, big suit or letter in the middle, suits drawn as paths, no font glyphs, no third-party
   art), the hand as an overlapping row (one or two rows, sorted by suit and rank; playable cards lifted and
   framed, the others greyed), the other player's hand as backs with a count, draw pile with its count, discard
   pile with the wish badge or "2 Karten ziehen", a line saying what happened last, buttons "Karte ziehen" /
   "Behalten" / "Passen" / "Mau!", the suit picker after a jack, the shell's handover cover (with the top card
   and what happened last). Drawn cards that end the turn are shown to the drawer first ("Weiter"). Start
   options for the house rules before "Wer spielt?". Menu tile with only "Ein Gerät" (`hotSeatOnlyGames`).
3. **Network** (later): remove `maumau` from `hotSeatOnlyGames`, house rules on "Raum starten" (and the room
   summary), guest screen from `MauMauView` (the board already reads only `handOf(viewer)`, counts and the top
   card; a guest's draw has no preview, it shows the drawn cards from the accepted event), live-UI network game.

## Rules (proposal: the maintainer can change every default)

| Rule | Choice | Switch (`MauMauRules`, JSON key in `maumau`) |
|---|---|---|
| Deck | 32 cards, 7 8 9 10 J Q K A in clubs, spades, hearts, diamonds (French suits, "Kreuz Pik Herz Karo") | – |
| Hand | **5 cards each** (the usual German default; some play 6 or 7) | – (`MauMauGame.handSize`) |
| Start | next card face up starts the discard pile, A starts; **the start card has no effect** (start 7: nobody draws, start 8: nobody skips, start jack: its own suit counts, no wish) | – |
| Turn | lay a card of the same suit or rank, or draw one; a drawn card that fits may be laid at once ("Behalten" keeps it), one that does not fit ends the turn; drawing is allowed even with a fitting card | – |
| Draw pile empty | the discard pile without its top card is shuffled into a new draw pile; with nothing left to draw at all, a player who cannot lay passes | – |
| Win | first player without cards, also when the last card is a 7, 8 or jack | – |
| 7 | the next player draws 2 and **the turn ends** (no laying afterwards) | `sevenDraws` (on, `seven: false`) |
| 7 on 7 | instead of drawing, lay another 7: the next player draws 2 more (4, 6, …) | `stackSevens` (on, `stack7: false`) |
| 8 | the next player misses a turn (two players: the same player again) | `eightSkips` (on, `eight: false`) |
| Jack (Bube) | lies on anything except a jack, wishes a suit (also its own); the next card must have that suit; the wish stays until it is met | always on |
| Jack on jack | a jack may also lie on a jack | `jackOnJack` (**off**, `jackOnJack: true`) |
| Ace | the same player lays again (like the 8) | `aceAgain` (**off**, `ace: true`) |
| "Mau" | press "Mau!" before laying the second-to-last card; forgetting it costs one penalty card (drawn at once by the engine, no opponent has to notice) | `mauCall` (**off** for kids, `mau: true`) |

The "Mau-Mau" call on the last card is not modelled (the game ends anyway).

## Moves and views
- `{'action': 'play', 'card': 'h7'}`, a jack with `'suit': 'c'|'s'|'h'|'d'`, plus `'mau': true` on the
  second-to-last card with `mauCall`; `{'action': 'draw'}` (one card, or the whole 7 penalty);
  `{'action': 'pass'}` (keep the drawn card, or nothing to draw and nothing fits). Card ids: suit + rank
  (`h10`, `sJ`, `dA`). Payloads: `card`, `wish`, `penalty` (cards due), `again`, `mau` / `forgotMau`, `drew`
  (ids, hidden from the other player: only `count`), `fits`, `kept`, `reshuffled`.
- View (`viewJson`): own hand, both hand counts, top card, discard and draw pile counts, wish, penalty, whether the
  player to move has drawn (the drawn card only for the drawer), result, resign; the rules when not default.

## Acceptance criteria
- [x] Engine tests: legal plays, drawing (fit / no fit / keep), 7 chain (stack on and off), skip, jack wish (no jack
  on jack, house rule), ace, "Mau" (said / forgotten / off), reshuffle, nothing left to draw, win, replay
  determinism over 40 random games with mixed rules, illegal and malformed moves rejected without a state change,
  view and redaction.
- [x] Registry, compat golden (rules 1), result code, debug console and contract tests.
- [x] Hot-seat UI in 7 locales; whole games played through the real UI (`maumau_live_test.dart`: default rules,
  all house rules, no special cards).
- [x] Screenshots `--plain-name kld118`.
- [ ] Maintainer: rule defaults, card look, layout (step-by-step UX).
- [ ] Step 3: network.

## Open questions (for the maintainer)
- 7: does the turn end after drawing the 2 (current choice) or may that player lay a card afterwards?
- Should "Mau!" be on by default for older children, and should forgetting it be noticed by the other player
  instead of automatically (needs a "Mau vergessen!" button for the opponent)?
- 5 or 6 cards each? Ace rule wanted at all?
- Rank letters on the cards follow the language (de B/D/K/A, en J/Q/K/A, fr V/D/R/A, others J/Q/K/A).
- Name: Mau-Mau is a traditional generic name, used as the title in every language.
