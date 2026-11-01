# KLD-103 — Default player names Anna / Ben instead of X / O

- **ID:** `KLD-103`
- **Title:** Players are named in every text ("Anna ist am Zug"); regional default names per locale; own names at the hot-seat start
- **Status:** DONE (waiting for the user's step-by-step review)
- **Depends on:** KLD-056 (player names), KLD-091/092 (Trumpf hot-seat texts)
- **Touched paths:**
  - `klunki/lib/l10n/**` (new `playerDefaultNameA`, `playerDefaultNameB`, `hotSeatStartTitle`,
    `hotSeatStartPlay`; reworded `hotSeatNamesHelper`, `quartettSetsScore` (now `{nameA}` / `{nameB}`),
    en `shellToMove` / `quartettTrumpfOpponentStack`, 19 ar strings, 11 fr strings; descriptions)
  - `klunki/assets/fonts/NotoSansSC/*` (web subset re-cut for 小红 / 小明)
  - `klunki/lib/ui/shell/{player_labels,game_screen,screen_registry}.dart`, `klunki/lib/ui/player_name_dialog.dart`,
    `klunki/lib/ui/engine_l10n.dart`, `klunki/lib/profile/player_name_controller.dart`
  - `klunki/lib/ui/games/{quartett_trumpf_screen,quartett_sets_screen}.dart`, `klunki/lib/ui/games/muehle/muehle_board.dart`,
    `klunki/lib/ui/games/gostrategy/gostrategy_board.dart`, `klunki/lib/ui/games/schiffe/{schiffe_board,schiffe_setup}.dart`
  - `klunki/lib/ui/pairing/{pairing_screen,relay_host_screen,web_join_screen}.dart`
  - `packages/klunki_engine/lib/{game,word_tiles}.dart`, `packages/klunki_engine/lib/debug/**`
  - `packages/klunki_net/lib/src/cli/cli.dart`
  - tests: `klunki/test/**`, `packages/klunki_engine/test/**`, `packages/klunki_net/test/cli_test.dart`
  - `docs/tasks/BOARD.md`

## Report

"X wählt … O gewinnt die Runde" confused the user in Quartett (Trumpf)
hot-seat. Decided with the user (2026-10-31): player A is **Anna**, player B
is **Ben** by default; players can type their own names.

## What it does

| | Before | Now |
|---|---|---|
| Hot-seat status line | "X ist am Zug" (names only if typed: "Anna (X) ist am Zug") | "Anna ist am Zug" |
| Quartett (Trumpf) result | "X gewinnt die Runde · O wählt als Nächstes" | "Anna gewinnt die Runde · Ben wählt als Nächstes" |
| Network | "Warte auf Ben (O)…" | "Warte auf Ben…" (the connection bar still shows "Du (Anna, X) · Gegner: Ben (O)") |
| Chess | "Anna (Weiß) ist am Zug" | unchanged: the side stays, it carries meaning |
| Hot-seat start | game starts at once | "Wer spielt?" with two name fields "Spieler 1" (hint "beginnt") / "Spieler 2" (token, prefilled), "Spielen"; Quartett: after the deck |
| CLI / debug console / engine reasons | "X drops into column 3", "O resigned" | "Anna drops into column 3", "Ben resigned"; the network CLI uses the session's handles ("Bea drops …") |

### Default names (translatable, regional)

| Locale | A | B |
|---|---|---|
| de, en | Anna | Ben |
| fr | Anne | Hugo |
| es | Ana | Beto |
| zh | 小红 | 小明 |
| ar | أمل (Amal) | باسم (Bassem) |
| fa | آرزو (Arezoo) | بابک (Babak) |

آنا / بن are avoided in ar/fa (they read as أنا "I" and بن "son of").
fr and es got regional names on 2026-11-01 (maintainer's choice; before: fr
Anna/Ben, es Ana/Ben). Both fr names start with a vowel or a silent h
("d'Hugo"), so no fr sentence may put "de", "que", "le" or "la" right before
`{player}`; checked again for Anne/Hugo: no fr string does (the earlier
rewording already covers it), so no fr text changed.

**Field labels "Spieler 1" / "Spieler 2"** (2026-11-01, user feedback: "Spieler X /
Spieler O" was confusing). `hotSeatNameLabel` now takes the number (all 7
locales: Player / Joueur / Jugador / 玩家 / اللاعب / بازیکن), for chess too (was
"Spieler Weiß / Schwarz"; the token still shows the side). Player 1 gets the
helper "beginnt" (`hotSeatStartsHint`; en starts, fr commence, es empieza, zh 先走,
ar الدور الأول (a noun phrase, no gendered verb), fa شروع می‌کند): player A makes
the first move in every game (engines start with `Player.a`: Connect Four, Mühle,
both Quartetts, Schiffe placement and first shot, GoStrategy setup and first
move, chess White, word tiles seat 0; the app never swaps the starter). The
token in the field stays the visual cue. Other places that still show X/O
(different strings, unchanged): "Du bist am Zug (X)" (`shellYourTurn`, network),
the connection bar "Du (Anna, X) · Gegner: Ben (O)" (`pairingStatus`),
`playerLabel` for equal names "Anna (X)", GoStrategy "Deine Armee (X)"
(`goArmyOwn`). The network name field ("Dein Name") has no mark.

### Rules

- **Names are data.** Every sentence keeps its `{player}` placeholder;
  `PlayerLabels.label` fills in the name. A player without a typed name gets
  `defaultPlayerName(l10n, p)`; the default is never stored, so it follows
  the app language.
- **The mark joins the name only when it carries meaning or is needed:**
  chess ("Anna (Weiß)") and two players with the same name ("Anna (X)" /
  "Anna (O)", e.g. two devices that both kept "Anna").
- **Colour and symbol stay as the second cue:** the players legend (token
  with X/O + name), the coloured turn pill, the pieces; the name fields in
  "Wer spielt?" carry the player's token; the card back in Quartett keeps
  the mark.
- **Own names:** hot-seat at the start ("Wer spielt?") and through the app
  bar "Spielernamen" during the game; both saved via `HotSeatNamesController`
  (`shared_preferences`, keys unchanged). Network: the existing "Dein Name"
  field; its suggestion is now the regional default name ("Anna" when
  starting a room, "Ben" when joining) instead of the device name.
- **Sentence check (any name):** German sentences use the name as subject
  or after "von" ("Stapel von Ben"), no genitive endings. English drops the
  name possessives ("{player} to move", "Stack of {player}"). Arabic verbs
  agree with the subject's gender (أمل is female, باسم male), so 19 ar
  strings now use noun phrases ("الجولة لصالح {player}", "الاختيار التالي
  لـ{player}", "استسلام {player}"; Trumpf card headers "أمل – فوز" /
  "باسم – خسارة"). French avoids elision before a vowel-initial name
  ("de Anna", "que Anna"): "À {player} de jouer", "On attend {player}…",
  "Pile adverse ({player})", "Chez {name} : {game}", "Placement en cours :
  {player} …", "Attaque par {player}". fa, zh and es needed no change.
- **RTL:** names stay bidi-isolated (`bidiName`, FSI … PDI) inside
  sentences, so a Latin name in a Persian sentence keeps its place (see the
  `kld103-connect4-fa-mixed` shot).

### Protocol and compatibility

Unchanged. The engine and the protocol still know `a` / `b`; names are
presentation. The compat fingerprint does not hash texts. The engine's
English resign reason ("Anna resigned") is display text only (the app
localizes by `GameEndReason`).

## Tests

- `klunki/test/ui/player_names_test.dart`: defaults per locale (all 7), the
  start dialog (prefill, custom names saved, default not stored, cancel
  starts nothing, Quartett deck first), custom names persist through prefs.
- Updated expectations in the game, shell, l10n and pairing tests (X/O →
  Anna/Ben; helper `testName` in `test/l10n/l10n_test_utils.dart`), engine
  debug console / resign / chess tests, net CLI test (handles Ada / Bea).
- The glyph coverage test caught 红 / 明 missing from the NotoSansSC web
  subset; re-cut with `tool/update_web_fonts.py subset` (620 code points).

## Screenshots

`klunki/test/screenshots/screenshots_test.dart`, group `kld103`:
`kld103-start-dialog-{de,ar}`, `kld103-trumpf-status-{de,ar}`,
`kld103-connect4-de`, `kld103-connect4-fa-mixed` (all phone, light).
