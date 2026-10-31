# KLD-090 — Live UI tests for every game: per-game adapters

- **ID:** `KLD-090`
- **Title:** Play every game to the end through the real UI (hot-seat and network, widget tests and real browsers) with per-game adapters on the KLD-089 driver
- **Status:** TODO
- **Depends on:** KLD-089 (driver + Quartett Trumpf adapter)
- **Touched paths:**
  - `klunki/test/e2e/live_ui/**` (one `<game>_adapter.dart` + `<game>_live_test.dart` per game; driver changes only if a game needs a new hook)
  - `klunki/tool/browser_live/**` (one `<game>.mjs` adapter per game; `live.mjs` gets `--game`)
  - app code only for a bug found on the way (fix at the root, keep the failing test)

## Goal

The user wants real live UI tests for all games: Connect Four, Mühle,
Quartett (Trumpf) ✅ (KLD-089), Quartett (Sets), Schiffe versenken and
GoStrategy, each **hot-seat and network**, each played to the end by taps,
with a turn log per device checked against the engine history.

## The framework (from KLD-089)

- Widget level, `klunki/test/e2e/live_ui/live_ui_driver.dart`:
  `playHotSeat` / `playNetwork` (host + guest `NetworkGameSession`s over
  127.0.0.1 through the seeded Wi-Fi proxy, random device order, dawdling,
  fake-clock jumps, side actions). A `LiveUiAdapter` implements:
  `observe` (the turn result the device shows now, plus checks of the table
  against the engine), `dismiss` (leave a result), `play` (choose a move
  from what the device shows and tap it), optional `tidy` / `fidget`,
  `engineTurns` (authoritative list from the accepted log) and the turn rule
  (`TurnRecord.nextActor`). Only results on an uncovered screen count; a
  hit-test miss is fatal (`hitTestWarningShouldBeFatal`), so every tap is one
  a finger could make.
- Browser, `klunki/tool/browser_live/`: `browser.mjs` (Firefox over BiDi,
  semantics nodes, taps, host/join), `live.mjs` (loops, logs, checks),
  adapter module reading semantics labels (German UI).

Moves may be chosen with the engine's `TextGame.autoMove` / `legalMoves`
(`packages/klunki_engine/lib/debug/*_text.dart`), but must be *tapped* on
what the screen offers (a move the screen does not offer is a bug).

## Per game: what the adapter needs

- **Connect Four** (`connect4`): one tap per move on a column
  (`Spalte N` in semantics; widget keys in `connect4/`). Turn rule: strict
  alternation. Result: last move + "X gewinnt!" / draw. No hidden info, no
  handover cover. Easiest one; do it first to shake out the driver for a
  game without reveals (turn log = the move history).
- **Mühle** (`muehle`): taps `muehle-point-<p>` (see
  `test/e2e/muehle_screens_e2e_test.dart`). Three phases: placing (one tap),
  moving (two taps: from, to; flying with 3 stones), and the **removal step**
  after a mill: the same player taps an opponent stone, so the turn does
  *not* pass (`pendingRemoval`). Turn rule: alternation except after a mill.
  Check the rendered board (`muehle-stone-<p>-X/O`) against the engine after
  every move on both devices.
- **Quartett (Sets)** (`quartett-sets`): ask for a card
  (`qs-set-<set>` → `qs-ask-<card>`), feedback (`qs-feedback`,
  `qs-feedback-text`, `qs-drawn-card`), "Weiter" (`qs-continue`), handover
  cover in hot-seat. Turn rule: a hit keeps the turn, a miss passes it
  (with a stock: draw, then pass). Quartets laid down automatically
  (`qs-quartets-<p>`). Hidden info: the own hand only (`qs-hand-<card>`);
  check the shown hand against the engine view, never the opponent's.
- **Schiffe versenken** (`schiffe`): **setup** first, per player (fleet of 6,
  see memory): `sv-random` + `sv-done` (or place `sv-ship` / `sv-rotate` /
  `sv-own-r-c` for a real placing pass), hot-seat with a cover between the
  two setups, network both at once. Then shots on `sv-target-<r>-<c>`;
  a hit gives an extra shot (`sv-extra-shot`), so the turn rule is "hit →
  same player, miss → other". Incoming shots on the own board
  (`sv-incoming`). Hidden info: never see the opponent's ships before the
  end.
- **GoStrategy** (`gostrategy`): **setup** editor on the board
  (`go-shuffle`, `go-done`, drag/swap via `go-cell-<sq>`), then moves by two
  taps (piece `go-cell-<sq>` → target `go-target-dot` / `go-target-attack`);
  fights show a reveal (`go-reveal`, `go-reveal-text`, `go-fight-card`;
  on the hot-seat cover `go-cover-fight`). Hidden info: enemy ranks only
  after a fight (`go-known-marker`); assert no unrevealed enemy rank is ever
  on screen (`gostrategy_screen_test.dart` has a model of this). Rules the
  adapter must respect when choosing: two-square rule, immobile pieces, move
  limit (`go-move-limit`). Turn rule: alternation; the log entry for a fight
  is attacker, defender ranks and the outcome.
- **Quartett (Trumpf)**: done in KLD-089; in the browser, add `--game` to
  `live.mjs` and move the hard-wired import into a map.

## Acceptance criteria

- [ ] One adapter per game in `test/e2e/live_ui/`; hot-seat and network
      games to the end for each, every device's turn log equal to the engine
      history, turn rule checked, hidden information never on screen.
- [ ] A small default matrix in CI (a couple of minutes for all games), the
      full matrix behind `KLUNKI_LIVE_UI_FULL=1`.
- [ ] Browser adapters for the same games (`tool/browser_live/<game>.mjs`,
      `live.mjs --game <id>`), run once by hand per game with the trick/turn
      log attached to the card.
- [ ] Any bug found: root-cause fix plus the failing test kept.

## Hints

- Reveals that time out on their own (like Quartett's grace) need
  observation after every pump; the driver already steps the fake clock in
  250 ms frames for that.
- Semantics labels are the German texts; tap targets for boards may need
  `Semantics(label: …)` already present (Connect Four columns are labelled
  "Spalte N"); check with a node dump (see `browser.mjs` → `nodes()`).
- Ports: run.sh defaults to 8775; never use 8080, 8081, 4749 or 8090.
