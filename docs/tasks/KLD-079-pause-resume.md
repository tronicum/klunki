# KLD-079: Pause and resume games (hot-seat auto-save, network resume)

- **ID:** `KLD-079`
- **Title:** Pause and resume games (hot-seat auto-save, network resume)
- **Priority:** long-term
- **Status:** step 1 (hot-seat) DONE ✅ · step 2 (network resume) TODO
- **Depends on:** KLD-071, KLD-072 (stable PRNG), KLD-074
- **Touched paths:** new `klunki/lib/saves/**`, `klunki/lib/ui/menu_screen.dart`, `klunki/lib/ui/shell/screen_registry.dart`,
  `klunki/lib/transport/hot_seat_transport.dart`, `klunki/lib/game/game_controller.dart`, `klunki/lib/app/klunki_app.dart`,
  `klunki/lib/main.dart`; step 2: `packages/klunki_net/lib/src/{host,guest}.dart`, `packages/klunki_engine/lib/registry.dart`,
  `packages/klunki_net/PROTOCOL.md`

## Goal
"Im Zug oder keine Zeit mehr – später weiterspielen". This matters most for chess and the long property and hotel games.

## Step 1: hot-seat (done)

What the players see: as soon as a hot-seat game has a move, it is saved. The menu then shows a
**"Weiterspielen"** card above "Wähle ein Spiel" ("2 angefangene Spiele"); it is not there without saves. The card
opens a list: game, player names, date and time, number of moves. Tapping a game goes on where it stopped; the
bin deletes it after "Spiel löschen?". Back from a resumed game leads to the menu.

Design decisions:
- **One save per game** (the simplest model a child understands): `shared_preferences` key `savedGame.<game id>`,
  so at most one per menu tile (12 today), small JSON. A new game of the same kind takes the slot over **with its
  first move**: opening a game and leaving it without a move keeps the old save. A finished game (win, draw, resign,
  time-out) deletes its save; undoing back to the start deletes it too. The list's footer says so in plain words.
- **Ask instead of silently replacing** (maintainer, step 1 review): starting a hot-seat game ("Ein Gerät") of a
  kind with a resumable save first asks **"Angefangenes Spiel"**: the game, the saved names, date and moves,
  "Weiterspielen oder ein neues Spiel anfangen? Ein neues Spiel ersetzt das angefangene beim ersten Zug." with
  **"Neues Spiel"** and **"Weiterspielen"**; back or a tap outside cancels (nothing starts). "Weiterspielen" resumes
  the save exactly like the list does (on top of the menu, so back leads to the menu). "Neues Spiel" goes on to the
  deck / options / "Wer spielt?" as before, and the save is still replaced **with the first move** (kept, not
  replaced at once: it is the existing rule, needs no second code path, and backing out of a later dialog or leaving
  the new game without a move cannot lose the old game). A save that **cannot be resumed** does not ask (there is
  nothing to choose; it shows in the list as "Kann nicht fortgesetzt werden" and the new game replaces it with its
  first move). The list's footer now says: "Klunki merkt sich von jedem Spiel das zuletzt angefangene. Startest du
  dasselbe Spiel neu, fragt Klunki: weiterspielen oder neues Spiel? Ein neues Spiel ersetzt das alte beim ersten
  Zug." Network games ("Mit anderen") never ask: they are not saved.
- **Pause or abort** (maintainer, after testing on the iPhone: "das hat das Spiel-Abbrechen ausgehebelt"): with
  the save, leaving a hot-seat game could no longer end it, it always came back under "Weiterspielen". Leaving a
  running game that holds the save (from its first move on, or resumed) now asks **"Spiel verlassen?"** — "Beim
  Pausieren merkt sich Klunki das Spiel. Später geht es unter „Weiterspielen“ weiter. Beim Abbrechen ist das Spiel
  vorbei und wird gelöscht." — with **"Spiel pausieren"** (primary, keeps the save), **"Spiel abbrechen"** (red
  outline, deletes the save, nothing is written when the screen closes) and **"Zurück zum Spiel"** (also back or a
  tap outside; no plain "Abbrechen", it would read like "Spiel abbrechen"). The buttons stand one under the other,
  full width. Both shells ask (`GameScreen`, the seat shell for 3–4 players), so every game does, also chess
  behind the clock's pause cover, Baulöwe and Mäxchen; the shells get the autosave through `GameSaveScope`
  (`GameSession`). No move yet (also after "Neues Spiel" in the game): leaves as before, an older save stays. A
  finished game leaves without asking. Without a save store, and over the network, the KLD-099 dialog is
  unchanged. Going to the background or the app being closed still saves (an implicit pause). The list's footer
  now says the game is kept "bis es fertig ist oder abgebrochen wird".
- "Weiterspielen" is both the menu card / dialog button and the Mäxchen refuse button ("Spiel beenden?"): fine
  (maintainer).
- **When it saves:** after every accepted move and every undo, when the app goes to the background
  (`AppLifecycleState.paused` / `hidden`) and when the game screen closes (back to the menu). Only
  `GameSession` (the hot-seat route) saves, through `GameAutosave`, and only with a `HotSeatTransport`: **network
  games are never saved** and never listed. The store comes from `SavedGamesScope` (set by `KlunkiApp` from
  `main()`); without it nothing is saved, so the widget tests are unchanged.
- **Format 1:** `{format, gameId, rulesVersion, fingerprint, config, moves, names, savedAt, clock?, clockBefore?}`.
  `config` is `GameConfig.toJson()` (seed, deck, tile set, word list, house rules, player count, colours, clock);
  `names` are the typed hot-seat names per seat (null = the default name of the app language, as in the name
  stores); `fingerprint` is `fingerprintOf(config)` (rules version, deck/theme revision, content hash).
- **Resume** replays the moves into a fresh engine (`HotSeatTransport(config, log: …)`, which submits every
  logged move; a refused move throws). The saved names go back into the hot-seat name stores (they are the last
  names again, as if typed in "Wer spielt?"; confirmed by the maintainer). A Wortgewandt game with "Wörterbuch
  prüfen" loads its word list first.
- **Cannot resume:** a save whose `rulesVersion` or fingerprint differs from this build, an unknown game, a newer
  format, damaged JSON or a log that no longer replays shows **"Kann nicht fortgesetzt werden"** (in the list and in
  a dialog on tap) with "Löschen"; nothing throws.
- **Hidden information:** a resumed game with secrets (Quartett, Schiffe, GoStrategy, Wortgewandt, Mau-Mau,
  Mäxchen) starts **behind the handover cover** ("Gib das Gerät an … weiter", `GameController(covered: true)`),
  also in the seat shell for 3–4 players, so whoever picks the phone up does not see the hand, rack, fleet or dice
  of the player to move. Baulöwe, Ausgewürfelt, chess, Mühle and 4 Gewinnt have nothing to hide and open directly.
- **Chess clock:** the save holds the clock at the moment of saving (both times, whose turn, time spent in this
  turn) and the clock before every move (for "Zug zurücknehmen" after resuming). A resumed game with a clock starts
  **paused, behind the chess pause cover**: time away from the app never counts, and nobody loses seconds while the
  players sit down again; "Weiter" starts the clock of the player to move.
- **Rename** is left out: the list already names the game, the players and the date, and with one save per game
  there is nothing to tell apart. Easy to add later if wanted.
- **RNG:** the dice, deals and tile bags come from the engine's own PRNG (`GameRandom`, KLD-072, done before the
  first release with saves), so a save replays the same deal after an SDK update and on the web. The save format
  records nothing extra: the rules versions bumped with KLD-072 (in the save and the fingerprint) already mark saves
  of the earlier build as "Kann nicht fortgesetzt werden".

Tests: `klunki/test/saves/save_store_test.dart` (round trip through the store for chess, Quartett, Mau-Mau,
Wortgewandt 2 and 3 players, Baulöwe 3 players; chess clock resume and undo; outdated and damaged saves; one slot
per game), `klunki/test/saves/resume_flow_test.dart` (through the real UI: play 4 Gewinnt, leave, restart the app
over the same preferences, "Weiterspielen", play on; finished game and undo delete the save; Mau-Mau and
Wortgewandt for 3 resume behind the cover; Baulöwe for 3 in the seat shell with its names; app pause saves;
outdated save; delete asks first; starting a saved game from the menu asks: cancel starts nothing, "Weiterspielen"
resumes with the saved names (also as the last names, the store had others), "Neues Spiel" opens "Wer spielt?" with
those names and replaces the save with the first move, an outdated save does not ask), `klunki/test/saves/pause_or_abort_test.dart` (the leave dialog: wording, styles, stay;
pause keeps the save and the card; abort removes it from the store and the preferences; no move yet does not ask;
a finished game does not ask; Baulöwe for 3 and Mäxchen for 4 in the seat shell; chess behind the clock pause
cover), `klunki/test/ui/shell/confirm_quit_test.dart` (every app game with a save asks from its first move, abort
deletes). Screenshots (with the question, `kld079-ask-*`, and the leave dialog, `kld079-leave-*`): `KLUNKI_SHOTS=… flutter test test/screenshots --plain-name kld079`.

## Acceptance criteria
- [x] **Hot-seat:**
  - Auto-save after every accepted move and on `AppLifecycleState.paused` (format above).
  - A "Weiterspielen" entry in the menu lists the saved games (game, names, date, move count), with delete
    (rename left out, see above).
  - Resuming replays the save.
- [ ] **Network (step 2):**
  - Both sides save the log.
  - To resume, the host hosts the saved game again (`KlunkiHost.start(moves:)` already exists) with the *same* token, and the guest rejoins with that token.
  - Room codes expire, so a relay needs a resumable room secret.
  - Optional `pause` / `pause-ok` messages let both sides agree. This needs a protocol version bump.
- [ ] **Secrecy (KLD-064, step 2):**
  - The host must save `_seedSalt`, the per-move salts and its guest log.
  - The guest saves `_steps`, `_startViewHash` and `_seedCommit`, so the end-of-game reveal still verifies.
- [x] **Storage (hot-seat):** small JSON per game in `shared_preferences` (web: localStorage, about 5 MB; one save
  per game keeps it small). A `format` field for migrations; a changed rules version or fingerprint shows "kann nicht
  fortgesetzt werden". Long network logs may still need files (`path_provider`, 🧑 OK) or IndexedDB.
- [ ] **Engine gaps:**
  - [x] A `rulesVersion` per `GameSpec` (KLD-085).
  - [x] An engine-owned PRNG (KLD-072), so replays survive SDK updates.
  - [ ] Optionally, a cheap snapshot for very long games (not needed so far: a 30-move Baulöwe replays instantly).

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.
