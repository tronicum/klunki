# KLD-123: Rules page per game, "Regeln" entry, shake consent card

- **ID:** `KLD-123`
- **Title:** A "Spielregeln" page for every game behind one "Regeln" button; the browser's motion prompt explained first
- **Milestone:** M5 (polish for the external test)
- **Status:** DONE
- **Depends on:** KLD-094 (Wortgewandt "So geht's"), KLD-107 (`SeenTips`), KLD-118 (Mau-Mau tour), KLD-121 (Mäxchen, shake to roll)
- **Touched paths:**
  - `klunki/lib/ui/rules/` (new: `rules_model.dart`, `rules_screen.dart`, `rules_registry.dart`, `games/*_rules.dart`)
  - `klunki/lib/ui/shell/game_screen.dart`, `klunki/lib/ui/menu_screen.dart`
  - `klunki/lib/ui/games/maumau/maumau_screen.dart`, `klunki/lib/ui/games/wordtiles/wordtiles_board.dart`
    (`wordtiles_help.dart` removed: folded into the rules page)
  - `klunki/lib/profile/seen_tips.dart`, `klunki/lib/main.dart`
  - `klunki/lib/platform/{shake,accelerometer_web,accelerometer_io,accelerometer_stub}.dart`,
    `klunki/lib/ui/games/shake_to_roll.dart`, `klunki/lib/ui/games/maexchen/maexchen_board.dart`
  - `klunki/lib/l10n/**`, `klunki/assets/fonts/NotoSansSC/*` (subset rebuilt), `site/privacy/index.html`,
    `klunki/assets/legal/privacy.json`
  - tests: `test/ui/rules/rules_page_test.dart`, `test/ui/games/shake_consent_test.dart`,
    `test/screenshots/rules_shots_test.dart`, updated Wortgewandt and Mau-Mau tests

## Goal

Maintainer decisions of 2026-11-08:

**A.** Every game gets a rules page with the same parts: **Ziel**, **So läuft ein Zug**, **Besondere Regeln**
and the **house rules that are on** (of the running game; from the menu the defaults). Short sentences, small
pictures drawn in Flutter (the existing painters). One labelled "Regeln" button in the same place in every
game replaces Mau-Mau's "?" and Wortgewandt's help icon; a "Regeln" link on each menu tile; a "Neu hier? So
geht's" line for new players; Mau-Mau's first-time tour ends at the "Regeln" button.

**B.** In the browser on iOS, Safari shows a fixed motion permission prompt on the first "Würfeln" tap. A
one-time card explains it first ("Würfeln durch Schütteln?"); never in the native apps. The privacy page says
what the motion sensor is used for.

## Design

- **Entry point: the app bar, last action** (`RulesButton`, key `shell-rules`): a book icon with the word
  "Regeln" under it, one app-bar button wide. Why there: the app bar is the one place every game screen shares
  (the `GameScreen` frame), it is visible in every phase, also over the hot-seat handover cover (rules are no
  secret), it costs the boards no height, and as the last action it stays in the same spot whatever other
  actions a mode shows (hot-seat names/restart, network confirm toggle). The title gets less room: it starts
  closer to the back arrow (`titleSpacing: 4`), shrinks to at most 75 % of its size, and only then is cut with
  "…" ("Quarte…", "Schiffe ve…" on a 390 px phone in hot-seat; see open questions).
- **"Neu hier? So geht's ›"** (`shell-rules-intro`) in the status row (next to the turn pill where there is
  room, on a phone on a line of its own under it): shown while the rules page of this
  game was never opened (`SeenTips.rulesOpened(id)`) and for the first 3 games of it on this device
  (`SeenTips.gamesStarted(id)`, counted at screen start and on "Neues Spiel"/"Nochmal"); not once the game is
  over. `SeenTips` got small persisted counters (prefs key `tipCounts`); `main()` loads the tips at start.
- **Rules page** (`RulesScreen`, `openRules(context, id, config: ...)`): the game's menu illustration on its
  accent, then the four parts (keys `rules-goal`, `rules-turn`, `rules-special`, `rules-house`). The house rules
  part lists only the ones that are on (`rules-house-<id>`), says so when none is on or the game has none, and
  from the menu adds "So ist es vorgeschlagen. Vor dem Spiel könnt ihr die Hausregeln ändern." for games that
  choose them at the start.
- **A new game adds its rules in one line**: a `RulesBuilder` in `lib/ui/rules/games/<game>_rules.dart` and
  one entry in `gameRules` (`rules_registry.dart`); button, menu link and "Neu hier?" follow from it. The test
  `every game of the app has a rules page` fails until a new `appGameSpecs` game has one.
- **Content per game** (checked against the engines): 4 Gewinnt (7×6, four in any direction, full board =
  draw), Mühle (place 9, move, jump with 3, mills protected unless all are, 50 moves without taking = draw),
  Quartett Trumpf (16 cards, higher/lower per property, Stechen into the pot, 200 rounds; house rule "3 or
  fewer cards: choose"), Quartett Sets (8 cards + pile, ask again after a hit, quartets laid down at once,
  4:4 draw), Schiffe (10×10, fleet from `SchiffeGame.defaultFleet`, no touching, shoot again after a hit),
  GoStrategy (setup, fights, a table of all 12 pieces with rank and count from `GoPiece`, spy only when
  attacking, miner defuses, scout runs and is revealed, back-and-forth limit 3, 200 moves without a fight),
  chess (every piece with its picture, check, mate, castling, en passant, promotion with choice, stalemate,
  too few pieces, threefold repetition, 75-move rule, agreed draw), Wortgewandt (the old "So geht's" folded in:
  premium legend, bingo, blank, swap, pass, dictionary/challenge in the game's order, end and rack deduction
  incl. the scoreless end; house rules "Wörterbuch prüfen" and "Joker tauschen"), Mau-Mau (jack always; 7,
  7 auf 7, 8, Bube auf Bube, Ass, Mau as house rules with their cards), Mäxchen (value order with dice,
  bluffing, announced Mäxchen only doubted or given up, loser starts; lives and "Mäxchen doppelt").
- **Consent card** (`ShakeConsentCard`, keys `shake-consent(-yes|-no)`): `ShakeToRoll.rollFromTap` shows it
  before the first roll when shaking is on, `Motion.permissionPending` (web: `DeviceMotionEvent.requestPermission`
  exists and was not called yet; always false in the apps) and it was not answered before
  (`SeenTips.shakeConsent`). "Ja, Schütteln erlauben" calls `requestPermission` synchronously in its own tap,
  "Nein, nur tippen" turns "Schütteln zum Würfeln" off; the dice are rolled after either answer. Fakes for
  tests: `Motion.debugPermissionPending`, `Motion.debugPermissionRequests`.

## Acceptance criteria

- [x] Rules page for all 10 games, same four parts, opened from the game and from the menu
- [x] The house rules that are on in the running game; defaults from the menu
- [x] "Regeln" (icon + word) in the same place in every game; Mau-Mau's "?" and Wortgewandt's help icon gone
- [x] "Regeln" link on every menu tile
- [x] "Neu hier?" line until the page was opened once or after 3 games (persisted)
- [x] Mau-Mau tour ends with "Alle Regeln findest du hier." at the "Regeln" button
- [x] 7 locales (fr/es/zh/ar/fa machine translation, marked for review as before), Chinese font subset rebuilt
- [x] Shake consent card: yes and no paths, not in the apps; privacy page (de, en) and its in-app export
- [x] Widget tests, screenshots `kld123`

## Open questions

- Hot-seat on a phone has five app-bar actions now: long game titles are cut ("Quarte…"). If that bothers,
  "Spielernamen" and "Neues Spiel" could move into a "⋮" menu.
- The "Neu hier?" line costs one line of height on a phone in the first 3 games (Wortgewandt's board shrinks
  a little then, its bench may start closed). Layout tests of steady play mark the rules page as seen.
- Translations need a native-speaker look like the rest (notes from the translation pass: fr "chevalet", es
  "atril" for the rack; ar chess terms; fa keeps a Latin "L" for the knight).
