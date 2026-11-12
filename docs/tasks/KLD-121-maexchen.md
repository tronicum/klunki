# KLD-121: Mäxchen (dice bluffing game)

- **ID:** `KLD-121`
- **Title:** Mäxchen (also called Meiern; en "Mia"), id `maexchen`: two dice under a cup, announce, bluff, believe or
  doubt; lives; hot-seat in the app, engine ready for the network and for more seats later
- **Milestone:** long-term games
- **Status:** step 1 DONE (engine, redaction, CLI, hot-seat UI, 7 locales, screenshots); rules decided 2026-11-06
  (see Decisions); follow-up 2026-11-08 DONE (actions always on screen, shake to roll, zh font subset rebuilt);
  step 2 DONE 2026-11-09 (3–4 players on one device, rule variant "Unbegrenzte Leben", rules 2); network step
  DONE 2026-11-11 (2 players in the app, LAN and relay); network decisions DONE 2026-11-12 (ending by agreement,
  rules 3; shake switch in the ⋮ menu; room rules line only with non-default rules); next: tune the shake
  threshold on devices
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
  - `klunki/lib/transport/hot_seat_transport.dart` (undo barrier)
  - `docs/tasks/BOARD.md`, `CHANGELOG.md`
  - Step 2: `packages/klunki_engine/lib/{maexchen,maexchen_view,game,registry}.dart`, `lib/debug/maexchen_text.dart`,
    `test/{maexchen_seats (new),maexchen,compat,word_tiles_seats}_test.dart`; `packages/klunki_net/lib/src/{guest.dart,
    secrecy/secrecy.dart}`, `test/maexchen_net_test.dart`; `klunki/lib/ui/games/maexchen/**`,
    `klunki/lib/ui/rules/games/maexchen_rules.dart`, `klunki/lib/ui/shell/{game_screen,seat_game_screen,
    screen_registry}.dart`, `klunki/lib/ui/engine_l10n.dart`, `klunki/lib/l10n/**`;
    `klunki/test/ui/games/{maexchen_seats (new),maexchen_layout,maexchen_screen,maexchen_shake}_test.dart`,
    `klunki/test/e2e/live_ui/maexchen_seats_live_test.dart` (new), `klunki/test/screenshots/maexchen_seats_shots_test.dart`
    (new); `AGENTS.md`

## Goal
A family bluffing game with two dice: roll secretly under a cup, announce a value (true or not), the next player
believes it (and must top it) or doubts it. Best with 3+ players; ships for 2 players on one device now.

## Rules as built
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
- **Toggle "Mäxchen doppelt"** (on by default, config `maexDouble`): everything about an announced Mäxchen counts
  double. A doubted Mäxchen that is real costs the doubter 2 lives; a bluffed Mäxchen that is caught costs the
  announcer 2 lives ("Falsches Mäxchen!"). Only when Mäxchen was *announced*; a real 21 announced as something
  lower costs 1. Off: every doubt costs 1.
- **No undo across a doubt or a give-up:** hot-seat "Zug zurücknehmen" never takes back `doubt` or `giveUp` (the dice
  were shown, or a life was given). Engine hook `GameSpec.undoBarrier` (`MaexchenGame.endsRound`), enforced in
  `HotSeatTransport.canUndo`; the moves of the next round can be taken back down to the barrier.
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

## Decisions (maintainer, 2026-11-06)
- No undo after a doubt: once "Anzweifeln" or "Leben abgeben" is played, "Zug zurücknehmen" does not go back across it.
- The announced value shown as two dice in the banner stays as it is.
- A caught bluffed Mäxchen costs the bluffer 2 lives, under the "Mäxchen doppelt" toggle ("everything about
  Mäxchen counts double"); the option's explanation says so in all 7 locales. Unreleased, so rules version stays 1
  (the compat golden is unchanged: the rule lives in the config, the hash covers the value order).
- "Leben abgeben" stays only after a Mäxchen.
- Chinese uses natural wording (吹牛骰子, 骰子, 杯子, 怀疑, 命, 王牌 for Mäxchen). The bundled Noto Sans SC subset
  lacks 19 of these characters (住 倍 假 偷 吹 怀 抓 报 摇 条 杯 牛 疑 盖 真 眼 破 识 骰): the two zh glyph tests are
  red on this branch until `python3 -I tool/update_web_fonts.py subset` runs once after the Mau-Mau and Mäxchen
  merges (approved by the maintainer). Rebuilt 2026-11-08 in the follow-up (also 掷 盅 for the shake texts).

## Decisions (maintainer, 2026-11-10, step 2)
- "Spiel beenden" stays in the "⋮" menu only (with a confirmation), no button on the table.
- A resign with 3–4 players drops a round under way (no loser) and the round starts again: as built.
- The tally with "Unbegrenzte Leben" (a broken heart and the number of lives lost) stays.
- Mäxchen network play in the app comes later (2 players first; 3–4 need the n-player network of KLD-088).

## Open questions for the maintainer
- English/French/Spanish title "Mia" (the international name of the game).
- Variants not built: "Mäxchen-Pasch"/special 31 rules, "drunter bleiben" (keep the dice without rolling), passing
  the cup without looking as an explicit option, a round-loser penalty other than a life.

## Step 2 (2026-11-09): 3–4 players on one device, "Unbegrenzte Leben"
Built on the n-player infrastructure of KLD-119 / KLD-125 (branch `integrate-1109`).
- **Engine** (`maexchen.dart`, now a `SeatGame`): 2–4 seats. The cup passes to the next seat still in; a seat
  without lives is out and skipped; the last one with lives wins; the others rank by the order they went out
  (out last = 2nd). The existing rules read the same with n seats: the loser starts the next round (the next
  seat in when the loser is out), "Leben abgeben" only after an announced Mäxchen, a caught fake Mäxchen costs 2
  lives under "Mäxchen doppelt", no undo across doubt / give-up. With 3–4 seats a resign names a seat
  (`{'action': 'resign', 'seat': n}`): that seat is out, a round under way is dropped (no loser) and starts again
  with the same seat to move (the next one if the leaver was to move); the others play on.
- **"Unbegrenzte Leben"** (`GameConfig.maexchenUnlimited`, JSON `maexUnlimited: true` only when on, off by
  default; `MaexchenGame.unlimitedLives`): nobody drops out, every lost life is counted (`lostOf`, the event and
  view carry `lost`), the round still ends with "<player> verliert ein Leben" (2 with "Mäxchen doppelt" for a
  caught fake Mäxchen), and the game goes on until the players end it with the `end` move (any time, not in
  `legalMoves`, like a resign); fewest lives lost wins, equal counts share a place
  (`GameEndReason.maexchenEnded`, params `a`/`b` = lives lost, `SeatResult` `lost0…`).
- **Compatibility:** two seats without the variant are byte-identical to rules 1 (moves, rolls, events, both
  views, results; compared over 300 seeds × lives 1/3/5 × "Mäxchen doppelt", and a transcript hash is a test).
  The content hash is unchanged; the rules version goes to **2** because an older build would ignore
  `maexUnlimited` and play such a game with lives (AGENTS.md: a config the old build reads differently). The
  network stays 2-player; the guest passes the variant to its end-of-game check (`klunki_net`), a loopback test
  ends an unlimited game from the guest.
- **App:** "Wer spielt?" with 2 · 3 · 4 (`playerCountGames`), menu chip "2–4". 2 players keep `GameScreen`,
  3–4 play in `SeatGameScreen` with the handover cover before every player who takes the cup (the cover shows
  the announcement or the round's verdict). Lives row with four cells (seat token and name, hearts shrunk to one
  line; a player who is out is greyed); with the variant a broken heart and the count of lives lost. Start
  options: "Unbegrenzte Leben" under the lives (the lives greyed while on). "Spiel beenden" in the "⋮" menu (asks
  first; `GameScreen` got `menuEntries` for it). Ranking: "noch 2 Leben" / "ausgeschieden" / "4 Leben verloren"
  (the seat shell's custom score now takes its own width before the name). Rules page: 2–4 players line, goal
  and the variant only when on. Room info: Mäxchen is not offered over the network in the app, so nothing there.
- **Tests:** engine `maexchen_seats_test.dart` (3/4 seats, elimination and skipping, resign, random games and
  replay, two-seat transcript hash, variant: tally, never ending, `end`, JSON round trip and omission, views);
  net `maexchen_net_test.dart` (variant over the network); widget `test/ui/games/maexchen_seats_test.dart`
  (cover before every seat, greyed and skipped seat, ranking, resign, lives row / tally on an iPhone SE in de
  and ar, "Spiel beenden" with 2 and 4 players, options and "Wer spielt?", rules page, chip);
  `maexchen_layout_test.dart` also with 4 players (5 lives, and with the tally); live UI
  `test/e2e/live_ui/maexchen_seats_live_test.dart` (whole games with 3 and 4 players, an unlimited game ended by
  the players). Screenshots `test/screenshots/maexchen_seats_shots_test.dart --plain-name kld121-4p`
  (`<KLUNKI_SHOTS>/maexchen-4p-shots/`). The zh web font subset was re-run; the new strings needed no new glyphs.

## Network step (2026-11-11): 2 players over the network in the app

- `maexchen` is out of `hotSeatOnlyGames`: the menu tile has "Mit anderen", "Raum starten" offers it (on this
  device and through the relay). 3–4 players stay on one device (the room is 2-player; KLD-088).
- The host chooses the lives (3/5), "Unbegrenzte Leben" and "Mäxchen doppelt" on "Raum starten": the start
  dialog's switches are now `MaexchenOptionsPicker` (`maexchen_options.dart`; keys `<prefix>lives-<n>`,
  `<prefix>unlimited`, `<prefix>double`; in the room `pair-maexchen-*` / `relay-maexchen-*`), used through
  `RoomRulesPicker` (`ui/pairing/room_rules.dart`, shared with Mau-Mau). "Schütteln zum Würfeln" stays a device
  setting of the start dialog. The options travel in the public config (`lives`, `maexDouble`,
  `maexUnlimited`) and show as one line ("3 Leben · Mäxchen doppelt", new string `maexchenSummaryLives`, 7
  locales, no new zh glyph) in the waiting room and on both boards before the first move
  (`maexchen-net-options`).
- Guest: the board is the `MaexchenView` (dice only of its own roll, until a doubt lifts the cup), no cover, no
  "Zug zurücknehmen"; roll by tap or by shaking the phone, "Nachschauen", announce, believe / doubt / "Leben
  abgeben" all on the own device. "Spiel beenden" ("Unbegrenzte Leben") is in the "⋮" menu of the player to
  move only (the `end` move is that player's); the menu follows the turn.
- No engine, rules version or protocol change (the engine redacted for the network since step 1; the guest's
  end-of-game check takes the whole public config since KLD-118 step 3).
- Tests: engine (`maexchen_test.dart`: no hidden die in any view or redacted step over whole games with every
  option set, give-ups never show the dice); net (`maexchen_net_test.dart`: TCP / WebSocket / relay × default, 5
  lives without "Mäxchen doppelt", "Unbegrenzte Leben", wire captured, verification); app
  (`pairing_screen_test.dart`, `menu_modes_test.dart`, live UI `maexchen_network_live_test.dart`: whole games
  over TCP with the Wi-Fi proxy, WebSocket and the relay, the unlimited one ended with "Spiel beenden", the guest
  rolls by shaking). Screenshots `network_games_shots_test.dart --plain-name kld121`.

## Network decisions (maintainer, 2026-11-12) ✅
The three proposals of the network step, approved and built:
1. **"Spiel beenden" over the network needs the other player** ("Unbegrenzte Leben"). Engine (rules 3, compat
   golden): `endRequest` / `endAgree` / `endRefuse` name their player like a resign (`playerOf`), so either
   player may ask at any time while no request is open; the game goes on meanwhile; the view carries an open
   request (`endRequest`, also after a rejoin). Hot-seat keeps the plain `end` after the confirm dialog; a host
   rejects `end` from the guest ("ending needs the other player"); `PROTOCOL.md` documents it, no
   `protocolVersion` bump (gated by the rules version, as KLD-126). App: "Spiel beenden" is in the ⋮ menu on both
   devices (not only the player to move), the confirm dialog sends the request; the other device shows
   „{player} möchte das Spiel beenden.“ (`maexchen-end-ask`, the ranking line under it) with „Weiterspielen“ /
   „Beenden“; the asker sees „Angefragt – {player} entscheidet.“ and after a no „{player} möchte
   weiterspielen.“ (until the next move). A request or a no leaves the table as it is (the peeking roller keeps
   the cup lifted, the chosen value stays). History: „möchte das Spiel beenden“, „Weiterspielen“, „Spiel
   beenden“.
2. **"Schütteln zum Würfeln" in the ⋮ menu of a network game** (both devices, a check box; key `shake-menu`,
   `shakeMenuEntry` in `shake_to_roll.dart`; the same stored `ShakeSettings`). Only on devices that may have a
   sensor. Mäxchen is the only network game with shaking (the five-dice game and Baulöwe are hot-seat only).
3. **The room rules line names only non-default rules** (Mäxchen and Mau-Mau, `roomRulesSummary`): a rule
   switched on by its name, one switched off as „ohne …“ (new string `roomRuleOff`), "5 Leben", "Unbegrenzte
   Leben"; no line at all with the defaults (as Mau-Mau already showed nothing without rules). The same line at
   the start of the game on both boards.
- Tests: engine (`maexchen_test.dart` "end by agreement"), net (`maexchen_net_test.dart`: guest asks, host
  declines, play goes on; host asks, guest agrees, over on both and verified; plain `end` from the guest
  rejected; the transport matrix ends by agreement), app (`test/ui/pairing/room_rules_test.dart`: the line, the
  menu check box; `pairing_screen_test.dart`), live UI (`maexchen_network_live_test.dart`: ask → "Weiterspielen"
  → note, game goes on → the other device asks → "Beenden" → over on both; the guest switches shaking off and on
  in the ⋮ menu; `maumau_network_live_test.dart`: the line only with non-default rules).

## Follow-up 2026-11-08 (testing build 2026110806 on an iPhone 15 Pro)
1. **The "ansagen" button was below the fold.** Now the board is the table part (lives, announcement, felt with
   the cup; it scrolls only when even its minimum does not fit) plus the controls pinned under it (beside it when
   the screen is wide and low, e.g. a phone in landscape); on a tablet a phone-wide column (600 px, 1100 px in
   landscape). The values are a grid of 8 per row with a wide "Mäxchen!" as the last cell (3 rows instead of 5),
   "Nachschauen" and "Zug zurücknehmen" (icon only on narrow phones; the board places it, `boardPlacesUndo`) share a
   small row above the grid, the value order help text sits under the grid and scrolls away first. While
   announcing the table keeps 240 px (the lifted cup and the dice stay visible), otherwise 170 px. The announce
   button says "Wähle eine Zahl" (disabled) until a value is chosen. The cup may grow to 340 px on tablets.
   `test/ui/games/maexchen_layout_test.dart` asserts every action button is fully inside the safe area and
   tappable without scrolling in every phase on iPhone SE (375×667) and iPhone 15 Pro (393×852), each at text
   100 % and 130 %, both phones in landscape, iPad portrait and landscape (Roboto loaded for real metrics).
   Screenshots `--plain-name kld121`, `16-<device>-<phase>`.
2. **"Schütteln zum Würfeln"** (shake to roll), reusable for the coming five-dice game:
   - Platform: own event channel `klunki/accelerometer`, no package: iOS CoreMotion (`AppDelegate.swift`,
     `KlunkiAccelerometer`, 50 Hz, no permission needed), Android SensorManager `TYPE_ACCELEROMETER`
     (`MainActivity.kt`, `SENSOR_DELAY_GAME`), both send `[x, y, z, ms]` in g while listened to; the web uses
     `devicemotion` (`accelerationIncludingGravity`) via `dart:js_interop`
     (`lib/platform/accelerometer_web.dart`); Safari on iOS needs `DeviceMotionEvent.requestPermission()`,
     asked once from the first "Würfeln" tap (or switching the setting on); denied or missing = silently no shake.
   - Dart: `lib/platform/shake.dart` (`ShakeDetector`: 2 jolts above 2.2 g total within 900 ms, then 1.5 s
     debounce; constants to tune on devices; `Motion` = the platform source with a test hook),
     `lib/ui/games/shake_to_roll.dart` (`ShakeToRoll`: listens only while a roll is allowed, the setting is on,
     the app is in the foreground and the game's route is on top; fires once until the roll is made),
     `lib/profile/shake_settings.dart` (shared_preferences `shakeToRoll`, default on; switch in the Mäxchen
     options dialog when the device may have a sensor).
   - Mäxchen: a shake rolls like the button (the cup wobbles), `HapticFeedback.mediumImpact()` when the dice
     land (every roll), "oder schüttle das Handy" next to "Zug zurücknehmen" once samples arrive.
   - Tests: `test/platform/shake_test.dart` (detector), `test/ui/games/maexchen_shake_test.dart` (fake sensor:
     rolls once, ignored while announcing/responding/covered/under a dialog, setting off, failing sensor, the
     option stored).
   - Not yet verified on real devices: the threshold (2.2 g) and the Android/web paths (the iOS app compiles).

## Acceptance criteria
- [x] Engine with ranking, announce-higher, believe/doubt/giveUp, Mäxchen rules, lives, end; replay determinism;
  illegal moves rejected without state change (`maexchen_test.dart`).
- [x] Redaction: dice only for the roller; network loopback test with verification.
- [x] Registered (rules 1), compat golden, CLI text adapter.
- [x] Hot-seat screen, options (lives 3/5, "Mäxchen doppelt"), menu tile with "Ein Gerät" only, 7 locales.
- [x] A whole game played through the real UI in a widget test; screenshots (`--plain-name kld121`).
- [x] Follow-up 2026-11-08: actions always on screen (layout test on SE/15 Pro/130 % text/landscape/iPad), shake to
  roll with a fake-sensor test; on-device tuning of the threshold open.
- [x] Decisions 2026-11-06: no undo across doubt/giveUp (engine + app tests), fake Mäxchen caught = 2 lives with the
  toggle, option text in 7 locales, natural zh texts (font subset rebuild pending after merge).
- [x] Step 2: 3–4 players on one device (engine seats, seat shell, cover before every player, elimination order
  ranking), two players unchanged (transcript hash), rules 2 with the compat golden.
- [x] Step 2: "Unbegrenzte Leben" (option, tally, "Spiel beenden", ranking by lives lost, rules page), 7 locales.
- [x] Step 2: engine, net, widget, layout and live-UI tests; screenshots `--plain-name kld121-4p`.
- [x] Network step: 2 players in the app (room options, guest view, shake on the guest, "Spiel beenden" for the
  player to move), engine / net / live-UI network tests, screenshots.
- [x] Network decisions 2026-11-12: "Spiel beenden" by agreement over the network (rules 3), shake switch in the
  ⋮ menu, room rules line only with non-default rules; engine / net / widget / live-UI tests.
