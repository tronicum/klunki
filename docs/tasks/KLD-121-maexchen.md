# KLD-121: Mäxchen (dice bluffing game)

- **ID:** `KLD-121`
- **Title:** Mäxchen (also called Meiern; en "Mia"), id `maexchen`: two dice under a cup, announce, bluff, believe or
  doubt; lives; hot-seat in the app, engine ready for the network and for more seats later
- **Milestone:** long-term games
- **Status:** step 1 DONE (engine, redaction, CLI, hot-seat UI, 7 locales, screenshots); rules decided 2026-11-06
  (see Decisions); follow-up 2026-11-08 DONE (actions always on screen, shake to roll, zh font subset rebuilt);
  next: tune the shake threshold on devices, then network in the app and 3+ players (KLD-088)
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
- **No undo across a doubt or a give-up:** hot-seat "Zug zurück" never takes back `doubt` or `giveUp` (the dice
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
- No undo after a doubt: once "Anzweifeln" or "Leben abgeben" is played, "Zug zurück" does not go back across it.
- The announced value shown as two dice in the banner stays as it is.
- A caught bluffed Mäxchen costs the bluffer 2 lives, under the "Mäxchen doppelt" toggle ("everything about
  Mäxchen counts double"); the option's explanation says so in all 7 locales. Unreleased, so rules version stays 1
  (the compat golden is unchanged: the rule lives in the config, the hash covers the value order).
- "Leben abgeben" stays only after a Mäxchen.
- Chinese uses natural wording (吹牛骰子, 骰子, 杯子, 怀疑, 命, 王牌 for Mäxchen). The bundled Noto Sans SC subset
  lacks 19 of these characters (住 倍 假 偷 吹 怀 抓 报 摇 条 杯 牛 疑 盖 真 眼 破 识 骰): the two zh glyph tests are
  red on this branch until `python3 -I tool/update_web_fonts.py subset` runs once after the Mau-Mau and Mäxchen
  merges (approved by the maintainer). Rebuilt 2026-11-08 in the follow-up (also 掷 盅 for the shake texts).

## Open questions for the maintainer
- English/French/Spanish title "Mia" (the international name of the game).
- Variants not built: "Mäxchen-Pasch"/special 31 rules, "drunter bleiben" (keep the dice without rolling), passing
  the cup without looking as an explicit option, a round-loser penalty other than a life.
- Network in the app and 3–4 players (with KLD-088), where the game is much better.

## Follow-up 2026-11-08 (testing build 2026110806 on an iPhone 15 Pro)
1. **The "ansagen" button was below the fold.** Now the board is the table part (lives, announcement, felt with
   the cup; it scrolls only when even its minimum does not fit) plus the controls pinned under it (beside it when
   the screen is wide and low, e.g. a phone in landscape); on a tablet a phone-wide column (600 px, 1100 px in
   landscape). The values are a grid of 8 per row with a wide "Mäxchen!" as the last cell (3 rows instead of 5),
   "Nachschauen" and "Zug zurück" (icon only on narrow phones; the board places it, `boardPlacesUndo`) share a
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
     land (every roll), "oder schüttle das Handy" next to "Zug zurück" once samples arrive.
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
