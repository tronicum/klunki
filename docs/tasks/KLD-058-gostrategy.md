# KLD-058: GoStrategy (hidden-rank capture-the-flag)

- **ID:** `KLD-058a` (engine + text/CLI + network registration, DONE), `KLD-058b` (Flutter UI, DONE)
- **Title:** A new two-player game: the classic hidden-rank capture-the-flag board game, called "GoStrategy" in the app (id `gostrategy`)
- **Milestone:** games
- **Status:** 058a DONE · 058b ✅ DONE
- **Depends on:** none (058a); 058b depends on 058a and the UI shell (KLD-021)
- **Touched paths (058a):**
  - `packages/klunki_engine/lib/gostrategy.dart` (new), `lib/debug/gostrategy_text.dart` (new)
  - `packages/klunki_engine/lib/game.dart` (4 `GameEndReason` codes), `lib/registry.dart` (spec,
    `GameSpec.appReady`, `appGameSpecs`), `lib/klunki_engine.dart`, `lib/debug.dart`, `lib/debug/debug_console.dart`
  - `packages/klunki_engine/test/gostrategy_test.dart` (new), `test/debug_console_test.dart`,
    `test/game_contract_test.dart`, `test/result_code_test.dart`
  - `packages/klunki_net/lib/src/cli/cli.dart` (opponent's setup not narrated), `test/net_test.dart`, `test/cli_test.dart`
  - `klunki/lib/ui/engine_l10n.dart`, `klunki/lib/l10n/*.arb` (+ generated), `klunki/assets/fonts/NotoSansSC/**`
  - `klunki/lib/ui/menu_screen.dart`, `lib/ui/pairing/pairing_screen.dart`, `lib/ui/pairing/relay_host_screen.dart`
    (`appGameSpecs`), `lib/ui/shell/screen_registry.dart` (`GameNotInAppScreen`), app tests
  - `docs/tasks/BOARD.md`, `docs/DEMO.md`, `packages/klunki_net/PROTOCOL.md`

Never use the original brand name of the board game anywhere (code, docs, UI, tests).

## Rules (as implemented)
- **Board:** 10×10, squares `row * 10 + col` (0–99), row 0 at the top. Lakes: the 2×2 blocks in rows 4–5,
  columns 2–3 and 6–7 (`{42, 43, 46, 47, 52, 53, 56, 57}`). No piece may enter a lake.
- **Sides:** player A (X, moves first) has home rows 6–9 (bottom), player B (O) rows 0–3 (top).
- **Army (40 per player):** marshal 10 ×1, general 9 ×1, colonel 8 ×2, major 7 ×3, captain 6 ×4,
  lieutenant 5 ×4, sergeant 4 ×4, miner 3 ×5, scout 2 ×8, spy 1 ×1, bomb ×6, flag ×1.
- **Setup:** A submits a full placement, then B; then A moves. Validation: exactly 40 known ids with the
  counts above. The square is given by the index (player-relative order, see below), so a setup is always
  on the own four home rows and never on a lake.
- **Moving:** one piece, one step orthogonally onto an empty square or onto an enemy (= attack). Bombs and
  the flag never move. A scout moves any number of empty squares in a straight line (no jumping over pieces
  or lakes) and may attack the piece at the end of that line in the same move.
- **Attack:** both pieces are revealed. Higher rank wins and takes the square; equal ranks remove both.
  The spy beats the marshal **only when the spy attacks** (marshal attacking spy: marshal wins). Attacking a
  bomb removes the attacker and the bomb stays, except a **miner**, which removes the bomb and takes its
  square. Attacking the flag wins the game.
- **Revealed / moved:** a piece is *revealed* after any fight it took part in, and a scout is revealed when
  it moves more than one square (that shows it is a scout). Every piece that has moved is marked *moved*
  (public: it is neither a bomb nor the flag).
- **Two-square rule (simple version):** a player may move a piece back and forth between the same two squares
  at most **3 times in a row** (`maxRepeats`). Counted per player over their own consecutive moves: moving
  X→Y, Y→X, X→Y is allowed, the next Y→X is not (it is left out of `legalMoves`/`targetsFrom` and rejected).
  Any other move, or any attack, resets the count.
- **End:**
  - flag captured → attacker wins (`gostrategy.flagCaptured`);
  - the player to move has no legal move (no movable piece, all blocked, or only the forbidden repeat)
    → they lose (`gostrategy.noMoves`); checked after every move, also right after B's setup;
  - neither player can move → draw (`gostrategy.bothBlocked`);
  - `noCaptureLimit` (default **200**) moves of both players in a row without a fight → draw
    (`gostrategy.moveLimit`, params `{moves: 200}`).

## Engine API (for KLD-058b)
`import 'package:klunki_engine/klunki_engine.dart';`

```dart
enum GoStrategyPhase { setup, play }
enum GoPiece { marshal, general, colonel, major, captain, lieutenant, sergeant, miner, scout, spy, bomb, flag }
  // .id (== name, stable string), .rank (10..1, null for bomb/flag), .count, .movable, GoPiece.fromId(id)
enum GoFightOutcome { attackerWins('attacker'), defenderWins('defender'), bothLose('both'), flagCaptured('flag') }

class GoCell {            // one square as a viewer sees it
  Player? owner;          // null = empty or lake
  GoPiece? piece;         // null = empty, or enemy piece not revealed
  bool revealed, moved, lake;
  bool get isEmpty; bool get hidden;   // hidden = enemy piece of unknown kind
}

class GoStrategyGame extends Game {
  GoStrategyGame({int noCaptureLimit = 200});
  GoStrategyGame.position(Map<int, (Player, GoPiece)> pieces, {Player toMove, int noCaptureLimit}); // tests/previews, starts in play
  static const size = 10, squareCount = 100, piecesPerPlayer = 40, maxRepeats = 3, defaultNoCaptureLimit = 200;
  static const Set<int> lakes;               static bool isLake(int sq);
  static int square(int row, int col); static int rowOf(int sq); static int colOf(int sq);
  static final List<GoPiece> army;           // the 40 pieces in rank order
  static int setupSquare(Player p, int i);   // setup index 0–39 → board square
  static List<int> homeSquares(Player p);    // the 40 squares in setup order
  static String? setupError(Object? pieces); static bool isValidSetup(Object? pieces);
  static List<GoPiece> randomSetup(int seed);
  static Map<String, dynamic> setupMove(List<GoPiece> pieces);
  static GoFightOutcome fight(GoPiece attacker, GoPiece defender);

  GoStrategyPhase get phase; Player get currentPlayer; GameResult get result; bool get isOver;
  List<Map<String, dynamic>> get history;
  bool hasSetup(Player p);
  List<GoCell> viewFor(Player viewer);       // what [viewer] may see, index = square — use this in the UI
  List<GoCell> get board;                    // full truth: never show it to a player
  GoCell cellAt(int sq, {Player? viewer});
  List<Map<String, dynamic>> get legalMoves;
  List<int> targetsFrom(int sq);             // legal target squares of the current player's piece on sq
  Map<GoPiece, int> remaining(Player p);     // pieces left per kind (public)
  int get movesSinceCapture;
  Map<String, dynamic>? get lastFight;       // same map as the event's 'fight'
}
```

### Moves (map convention, JSON-safe)
| Move | Meaning |
|---|---|
| `{'action': 'setup', 'pieces': [40 ids]}` | full placement, ids in setup order |
| `{'action': 'autosetup', 'seed': s}` | `randomSetup(s)` (short on the wire, used by the CLI and auto-play) |
| `{'action': 'move', 'from': 63, 'to': 53}` | move or attack, flat squares 0–99 |

**Setup order (player-relative):** index 0–9 is the player's front row from *their own* left to right,
index 30–39 their back row. A: index `i` → square `60 + i`; B: index `i` → square `39 - i` (the same layout
rotated by 180°, as if both sit opposite each other). So `randomSetup` and any saved layout work for both sides.

`legalMoves` in the setup phase lists ten sample `autosetup` moves (seeds 0–9); any valid `setup` is accepted
too. In the play phase it lists every legal `move`.

### Events
- setup: `payload = {'setup': Player}`
- quiet move: `payload = {'from': f, 'to': t}` (+ `'scout': true` when a scout ran more than one square)
- attack: `payload = {'from': f, 'to': t, 'fight': {...}}` with
  `fight = {'attacker': 'scout', 'defender': 'bomb', 'attackerRank': 2, 'defenderRank': null,
  'attackerPlayer': Player.a, 'outcome': 'attacker'|'defender'|'both'|'flag', 'from': f, 'to': t}` —
  everything a reveal animation needs.
- `winner` / `draw` set as usual; `result.code` is one of the four reason codes.

### End reasons
| Code | Enum | Result | Params |
|---|---|---|---|
| `gostrategy.flagCaptured` | `gostrategyFlagCaptured` | mover wins | – |
| `gostrategy.noMoves` | `gostrategyNoMoves` | the player who cannot move loses | – |
| `gostrategy.bothBlocked` | `gostrategyBothBlocked` | draw | – |
| `gostrategy.moveLimit` | `gostrategyMoveLimit` | draw | `moves` |

Localized in `klunki/lib/ui/engine_l10n.dart` (`engineReasonGostrategy*`, all 7 locales; non-de/en are
machine translations under the files' `@@x-review` note).

## Text / CLI
- `GoStrategyText` (`package:klunki_engine/debug.dart`), registered in `DebugConsole.games` and `forGame`.
- Squares like a chess board: files `a`–`j` left to right, ranks `1`–`10` from X's back row (bottom) to O's
  back row (top). Square 60 = `a4` (X's front row), 0 = `a10`.
- Commands: `setup` / `setup <seed>` (random setup), `a4 a5` or `a4-a5` (move/attack).
- Board from the player on turn's view: own pieces `X9`, `XS`, `XB`, `XF`; enemy `O?` until revealed, then `O7`;
  `~` lake, `.` empty. Status: pieces left per side, moves without a capture.
- `autoMove`: random setup; then capture a known flag, attack known weaker pieces, avoid known stronger ones,
  probe unknown pieces with cheap ones, otherwise advance (random tie-break). Only uses the mover's own view.
  Seeded auto games end in a few hundred moves (100 seeds: 47 flag, 41 no moves, 12 move limit).
- `dart run bin/klunki.dart demo gostrategy`, `dart run klunki_net:klunki host gostrategy`.
- The "keep or reshuffle" setup step is not built: undo (`undo` in the console) and `setup <other seed>` does the same.

## Network
- Registered in `gameSpecs` as `GameSpec('gostrategy', 'GoStrategy', …, hiddenInformation: true,
  redaction: const GoStrategyRedaction())` (`appReady` since 058b).
- **Since KLD-064 the host's setup never reaches the guest.** The guest gets `{action: setup}` instead of the
  host's setup move, a commitment to it, and its own `GoStrategyView` (own pieces, owners, revealed kinds) after
  every move; the host reveals the setup at the end and the guest replays the game to check it (see
  `PROTOCOL.md`, "Hidden information", and `docs/tasks/KLD-064-hidden-info-secrecy.md`). The host, as
  referee, still sees the guest's setup. The 058b screen renders only `viewFor(me)` / `targetsFrom` (on the
  guest the `GoStrategyView`) and the public fight payload of each redacted event.

## KLD-058b (UI) ✅
- [x] `klunki/lib/ui/games/gostrategy_screen.dart` (+ `gostrategy/gostrategy_board.dart`, `gostrategy/gostrategy_pieces.dart`),
      entry in `gameScreens`, `menuGameGoStrategy` in `game_titles.dart`, `appReady: true` in `registry.dart`
      (menu, pairing and relay host lists show it now).
- [x] Menu: olive accent (`#4E6B2F` / dark `#3F5726`, AA in `theme_test`), `GoStrategyIllustration` (board patch with
      lake, own tile with star, hidden enemy backs, flag), `menuDescGoStrategy`, eye-off badge (hidden info).
- [x] Setup editor per player: the own 4 rows (front row on top) from `randomSetup(seed*2 + player)`, **Neu mischen**
      (new random seed), swap by tapping two tiles (tap again = deselect), **Fertig** submits `setupMove(list)`;
      piece list with counts + short rules legend. Network: the guest can arrange while the host sets up, "Fertig" waits.
- [x] Board: `viewFor(me)` only (me = local player in network, player to move in hot-seat), drawn turned by 180° for O
      (own army at the bottom), inside `LtrBoard`; cell keys keep the engine squares (`go-cell-<sq>`). Lakes in the
      Schiffe water colours, pieces as rounded tiles in the army colour (X red, O blue: `GoStrategyPalette`) with rank
      (bomb/flag symbol) and the first letter of the localized name; hidden enemies as blank backs, a dot on moved
      hidden enemies, a small eye on own pieces the enemy has seen, last move tinted.
- [x] Tap own piece → `targetsFrom` (green dots, red ring = attack, scouts the whole line), tap target → move.
- [x] Fight reveal from the event payload (`GoFight.fromMove`): card with both pieces, "Angriff von X", outcome
      ("Hauptmann (6) schlägt Leutnant (5)", "Beide fallen", "Mineur (3) entschärft die Bombe", "… läuft auf eine Bombe",
      "Fahne erobert!"); 2.4 s fade/scale, static with reduced motion, tap to skip. Hot-seat: the cover shows the
      same card (public info; new optional `GameScreen.handoverDetail` / `HandoverCover.detail`), and the next
      player sees the animated reveal after taking the device.
- [x] Armies panel (`remaining()`, captured kinds faded, "N von 40 übrig"), move-limit hint in the last 30 moves.
- [x] Piece names, setup/hint/fight/history/semantics strings in 7 locales (one block before `gameNotInApp`;
      fr/es/zh/ar/fa machine translations under `@@x-review`); Noto Sans SC subset rebuilt. de reason text now
      "Fahne erobert" (same word as the piece).
- [x] Tests (below), screenshots (`test/screenshots`: setup, mid-game, cover with fight, fight reveal).

Rendering never reads `board` (only `viewFor(me)` and the fight payload), so it keeps working with redacted
per-player views on the wire (KLD-064). `GameNotInAppScreen` stays for future engine-only games.

Open: no a–j/1–10 labels around the board (the history uses them); no drag-to-swap in the setup; the result dialog
can cover the final "Fahne erobert!" reveal; saved/favourite setups.

## Rule decisions / open questions
- Setup is turn-based (A then B) like Schiffe versenken; B could see nothing of A's setup in the UI anyway.
- Move-limit counts both players' moves; a "fight" (any attack) resets it, also a lost attack.
- Two-square rule is the simple per-player alternation count, not the tournament "chasing" rule.
- Scouts are revealed by long runs; one-step scout moves only mark `moved`.
- Open: should the move limit be configurable in `GameConfig`? Should a timeout/resign move exist (all games)?
- Open: per-player wire views for real secrecy (affects all hidden-information games).

## Tests
- `packages/klunki_engine/test/gostrategy_test.dart` (31 tests): pieces/lakes/home squares, setup validation,
  `randomSetup` (100 seeds), setup flow, a blocked setup losing at once, movement (step, diagonal, lakes,
  immobile bombs/flag, scout lines and scout attack), the whole fight table and every combat rule on the
  board, views and reveal tracking, the two-square rule, no-moves loss, both-blocked draw, move-limit draw,
  determinism/history/replay, 30 seeded auto games, random legal games ending.
- `debug_console_test.dart` (parsing, narration, hidden enemy ranks, auto game), `game_contract_test.dart`,
  `result_code_test.dart` (25 seeded games per id), `registry_test.dart`.
- `klunki_net`: `net_test.dart` (config round trip + host↔guest setup/move/view check; the full random game
  for every spec now includes GoStrategy), `cli_test.dart` (host/guest setups, seed stays private).
- App (058a): `engine_l10n_test` (new codes in all locales).
- App (058b): `test/ui/games/gostrategy_screen_test.dart` (setup shuffle/swap/submit, hot-seat setup hiding, rotation per
  player, LTR in ar, targets + move + moved marker, scout line, animated reveal + cover card, reduced-motion reveal,
  fight texts, panel + move limit, scripted position game to the flag + result dialog, a seeded full game, no
  unrevealed enemy rank on screen over 120 turns), `gostrategy_network_test.dart` (host + guest `NetworkGameSession`
  on loopback: setups, tap move, rotation, private views, fight reveal on both, no cover); GoStrategy added to
  `game_screen_test` (menu), `coverage_test` (all locales, two sizes), `translations_test`, `rtl_test`,
  `screenshots_test`.

## Rank insignia (2026-11-08, step 1: variant sheet)

Maintainer decision: every piece gets a drawn rank insignia (CustomPainter, generic, no assets), the rank
number small in a corner. Marschall crossed batons, General peaked cap (oak leaves only at large sizes),
Oberst/Major/Hauptmann 3/2/1 stars, Leutnant one bar, Feldwebel chevrons, Mineur pickaxe, Späher binoculars,
Spion hat over a domino mask; bomb and flag unchanged. `GoInsignia(piece, color, size)` in
`gostrategy_pieces.dart` is public (rules pages reuse it). Looks: `GoPieceLook` (A shoulder board, B free in
the ink colour, C free with gold stars/bars/chevrons); the app switch `goPieceLook` stays `classic` until the
maintainer chooses. Variant sheet and a board with B:
`KLUNKI_SHOTS=/tmp/insignia flutter test test/screenshots/gostrategy_insignia_shots_test.dart` (group
`kld058-insignia`); paint test `test/ui/games/gostrategy_insignia_test.dart`.

v2 (maintainer feedback: B favourite, A possible): `GoInsigniaLayout` gives the number and the "seen" eye
corners of their own (B/C: a top strip, number left, eye right; A: number top left, eye bottom left beside
the board), so nothing overlaps and every insignia has the same centre. Equal weight: pictures share one
height, stars one size for 1/2/3 (nested triangle), bar and chevrons one stroke. A: every board the same
size and outline, 80 % of the tile height. Shots now end in `-v2`, boards for B and A.

v3 (maintainer chose B; "no border between the white and the background colour"): B with an edge for
comparison, B1 thin black outline, B2 thin dark grey, B3 soft dark halo (`goInsigniaEdge`, width 3 % of the
tile, 0.8–1.5 px, drawn as a dilated or blurred copy below the insignia, bomb and flag included). Free-standing,
the single star and the bar fill their area like a picture. Shots end in `-v3`.

v4 (feedback: insignia too low): looks `badgeBlack` / `badgeGrey` centre the insignia in the whole tile (area
0.2–0.8, equal margins) and show the number (top left) and the "seen" eye (top right) as small rounded badges
in the army colour with a thin border in the edge colour, 0.34 of the tile high, reaching 0.06 over the tile
edge. On the board the overflow stays inside the cell's padding (0.07 of the cell), so neighbours do not clip
it. The batons are drawn at 0.9 of the picture height so their ends keep clear of the badge. Shots end in `-v4`.
