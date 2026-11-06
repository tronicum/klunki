# KLD-121: Mäxchen (dice bluffing game)

- **ID:** `KLD-121`
- **Title:** Mäxchen (also called Meiern; en "Mia"), id `maexchen`: two dice under a cup, announce, bluff, believe or
  doubt; lives; hot-seat in the app, engine ready for the network and for more seats later
- **Milestone:** long-term games
- **Status:** step 1 DONE (engine, redaction, CLI, hot-seat UI, 7 locales, screenshots); next: maintainer feedback on
  the rules proposals below, then network in the app and 3+ players (KLD-088)
- **Depends on:** KLD-064 (redaction), KLD-085 (fingerprint), KLD-088 (seats, later), KLD-103 (player names)
- **Touched paths:**
  - `packages/klunki_engine/lib/maexchen.dart`, `maexchen_view.dart` (new), `lib/debug/maexchen_text.dart` (new),
    `lib/{game,registry,compat,klunki_engine,debug}.dart`, `lib/debug/debug_console.dart`
  - `packages/klunki_engine/test/maexchen_test.dart` (new), `test/{compat,secrecy,result_code}_test.dart`
  - `packages/klunki_net/lib/src/{guest.dart,secrecy/secrecy.dart}` (lives and the house rule in the reveal check),
    `packages/klunki_net/test/maexchen_net_test.dart` (new)
  - `klunki/lib/ui/games/maexchen/**` (new), `klunki/lib/ui/shell/screen_registry.dart`, `klunki/lib/ui/{game_titles,
    game_visuals,engine_l10n}.dart`, `klunki/lib/app/theme.dart`, `klunki/lib/l10n/**`
  - `klunki/test/ui/games/maexchen_screen_test.dart`, `klunki/test/screenshots/maexchen_shots_test.dart` (new),
    `klunki/test/ui/menu_modes_test.dart`, `klunki/test/ui/shell/game_screen_test.dart`, `klunki/test/l10n/translations_test.dart`
  - `docs/tasks/BOARD.md`, `CHANGELOG.md`

## Goal
A family bluffing game with two dice: roll secretly under a cup, announce a value (true or not), the next player
believes it (and must top it) or doubts it. Best with 3+ players; ships for 2 players on one device now.

## Rules as built (proposals; the maintainer can change them)
- Two dice, read with the higher die first (5 and 3 = 53). Order low → high: 31, 32, 41, 42, 43, 51 … 54,
  61 … 65, then doubles ("Pasch") 11, 22 … 66, then 21 = **Mäxchen**, the highest.
- A turn: `roll` (only the roller sees the dice: lifts the cup with "Nachschauen"), then `announce {value}`. The
  value must beat the round's last announcement; any value starts a round. Lying is allowed. Announcing without
  looking works too (just don't peek).
- The next player answers: `believe` (takes the cup, rolls, must announce higher) or `doubt` ("Anzweifeln"): the
  dice are shown; lower than announced → the announcer loses a life ("Geflunkert!"), equal or higher → the doubter
  loses a life ("Stimmt!").
- An announced Mäxchen cannot be beaten: no `believe`; the next player doubts or gives up (`giveUp`, "Leben
  abgeben": one life, the dice stay hidden). `giveUp` exists only after a Mäxchen.
- **Toggle "Mäxchen doppelt"** (on by default, config `maexDouble`): a doubted Mäxchen that is real costs the
  doubter 2 lives. Only when Mäxchen was *announced*; a real 21 announced as something lower costs 1. A bluffed
  Mäxchen that is caught costs the announcer 1.
- After a doubt or a give-up a new round starts with the player who lost the life (next in turn if out).
- **Lives:** 3 by default, 5 as start option (config `lives`, engine accepts 1–9). No lives left → out; with 2
  players the other wins (`maexchen.noLives`, params `a`/`b` = lives left). Lives never go below 0.

## Engine
- `MaexchenGame` (pure Dart): phases `roll` / `announce` / `respond`, state per seat (lives list, seat turn order
  skipping players without lives) so 3+ seats are a constructor change plus `SeatGame`; `playerCount` is 2 now.
- Deterministic: dice from `Random(seed)`, two draws per `roll`. `debugScriptRolls` for tests/screenshots only.
- Moves: `roll`, `announce {value}`, `believe`, `doubt`, `giveUp` (+ the shared resign). Illegal moves return null
  and change nothing.
- Hidden information: `MaexchenRedaction` (secret seed); the view has the dice only for the roller; the `roll`
  event's dice are stripped for the other player; a doubt's dice are public (`lastRound`). Tested over a real
  network loopback (incl. the reveal check with non-default lives); the app does not offer network play yet
  (`hotSeatOnlyGames`).
- Registry: rules version 1; fingerprint content includes the value order. `MaexchenText` for the CLI/debug console
  (`klunki new maexchen`, `demo maexchen`).

## UI (hot-seat)
Lives row (names + hearts), announcement banner (value as two dice), green table with a cup drawn in code (shakes
on "Würfeln", lifts on "Nachschauen"), picker with only the values above the current one plus a big "Mäxchen!",
the value order as help text, "<Wert> ansagen"; "Glauben" / "Anzweifeln" (or "Leben abgeben" / "Anzweifeln").
After a doubt the cup lifts after a short pause and the verdict appears; the handover cover shows the
announcement (or the verdict) to the next player. The result dialog shows the last round.

## Open questions for the maintainer
- English/French/Spanish title "Mia" (the international name of the game), zh "点数大王" (limited by the bundled
  Chinese font subset: natural wording like 吹牛骰子 needs `tool/update_web_fonts.py subset`, which needs internet).
- "Mäxchen doppelt" also for a caught *bluffed* Mäxchen (announcer loses 2)? Common variants differ.
- Should `giveUp` ("Leben abgeben") be allowed for any announcement, not only Mäxchen?
- Variants not built: "Mäxchen-Pasch"/special 31 rules, "drunter bleiben" (keep the dice without rolling), passing
  the cup without looking as an explicit option, a round-loser penalty other than a life.
- Hot-seat "Zug zurück" after a doubt lets the doubter see the dice and take the doubt back; keep it, or disable
  undo for `doubt`?
- Network in the app and 3–4 players (with KLD-088), where the game is much better.

## Acceptance criteria
- [x] Engine with ranking, announce-higher, believe/doubt/giveUp, Mäxchen rules, lives, end; replay determinism;
  illegal moves rejected without state change (`maexchen_test.dart`).
- [x] Redaction: dice only for the roller; network loopback test with verification.
- [x] Registered (rules 1), compat golden, CLI text adapter.
- [x] Hot-seat screen, options (lives 3/5, "Mäxchen doppelt"), menu tile with "Ein Gerät" only, 7 locales.
- [x] A whole game played through the real UI in a widget test; screenshots (`--plain-name kld121`).
