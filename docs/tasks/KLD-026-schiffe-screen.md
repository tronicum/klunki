# KLD-026 — Schiffe versenken screen

- **ID:** `KLD-026`
- **Title:** Schiffe versenken screen: fleet placement (rotate + random), own grid + target grid, tap to fire, handover
- **Milestone:** P2 — Hot-seat on one device
- **Status:** IN_PROGRESS (an agent is working on it, 2026-10-25)
- **Depends on:** KLD-021 (shell, `HandoverCover`, placeholder `SchiffeScreen`), which builds on KLD-020 (`GameController`)
- **Touched paths:**
  - `klunki/lib/ui/games/schiffe_screen.dart`
  - `klunki/test/ui/games/schiffe*`
  - `docs/tasks/KLD-026-schiffe-screen.md` (status only)

## Goal
Two people on one device can place their fleets in secret and then play Battleship to the end. Each player sees
their own ocean plus their shots at the opponent, and never the opponent's ships.

## Repo context
- Flutter app `klunki/`; engine `package:klunki_engine/klunki_engine.dart` (pure Dart; add `hide Card` if you import the whole
  library, since the Quartett `Card` clashes with Material's). UI strings in German.
- **Read first:** `klunki/lib/ui/shell/**` (KLD-021) and `klunki/lib/game/**` + `klunki/lib/transport/**` (KLD-020).
  Expected contract, which may differ slightly (adapt): `GameController` (ChangeNotifier) with `game`, `spec`, `canAct`,
  `Future<GameEvent?> submit(Map move)` (null = rejected), `lastEvent`, `moves`, `needsHandover` + an acknowledge method,
  `newGame()`. `GameScreen(controller:, board:)` provides the status line, result dialog, history, new game and `HandoverCover`.
  Keep `const SchiffeScreen({super.key, required this.controller})`.
- Engine API (`packages/klunki_engine/lib/schiffe.dart`), with `final g = controller.game as SchiffeGame`:
  - `SchiffeGame.size` = 10; `g.fleet` (`[5,4,4,3,3,3,2,2,2,2]`); `SchiffeGame.shipName(length)` (Schlachtschiff, Kreuzer, Zerstörer, U-Boot)
  - `g.phase` → `SchiffePhase.setup | battle` (stays `battle` after the end; use `g.isOver`)
  - setup: A places the whole fleet, then B, then battle starts with A. `g.nextShipIndex(p)` → index into `fleet` or null
  - `g.placements(p)` → `List<ShipPlacement {length,row,col,horizontal,cells}>` (own view only)
  - `g.ownGrid(p)` → `[row][col]` of `SchiffeCell.empty|ship|miss|hit|sunk`; `g.targetGrid(p)` → `[row][col]` of `ShotMark.unknown|miss|hit|sunk`
  - `g.shipsRemaining(p)`; `g.legalMoves` (valid placements of the next ship / unshot cells)
  - moves: `{'action':'place','ship':i,'row':r,'col':c,'dir':'h'|'v'}` (`ShipPlacement.toMove(i)` builds it);
    `{'action':'autoplace','seed':n}` places the **rest** of the fleet; `{'action':'fire','row':r,'col':c}`
  - Ships may not touch, not even diagonally. An illegal placement returns `null`.
  - fire payload `{'row','col','result': 'miss'|'hit'|'sunk', 'ship': length?}`; a hit or sunk gives **another shot** (`extraShotOnHit` default true)
  - `GameSpec.hiddenInformation` is true for `schiffe`.

## Actual API after KLD-020/021 (verified against main @ `c10573c`; overrides the expected contract above)
- `GameScreen(controller:, boardBuilder: (context, controller) => …, describeMove:, title:)`; there is no `board:` parameter.
  Set the hint line with `GameScreen.of(context).setHint('…')` (safe from `build`; `null` hides it).
- `controller.submit(move)` returns `Future<SubmitResult>` (`isAccepted`, `event`, `reason`), not `GameEvent?`.
  `controller.moves` is `List<AcceptedMove>` (`index`, `player`, `move`, `event`). Restart is `controller.restart(seed:)`; there is no `newGame()`.
  Also: `canAct`, `canUndo`, `undo()`, `needsHandover`, `acknowledgeHandover()`, `config`, `transport`.
- Status line text is "X ist am Zug"; result dialog buttons are "Nochmal" / "Menü"; handover button is "Ich bin O – weiter".
  `HandoverCover` keeps the board mounted but `Offstage` (use `skipOffstage: false` only if you need to find offstage widgets).
- Routing: `klunki/lib/ui/shell/screen_registry.dart` (`gameScreens`, `buildGameScreen(controller)`, `openGame(context, id, seed:)`); there is no `screenFor`.
- Stable keys: `shell-status`, `shell-hint`, `shell-undo`, `shell-restart`, `shell-history`, `history-sheet`, `result-dialog`,
  `handover-cover`, `handover-continue`, `menu-<gameId>`. Full list: `docs/tasks/KLD-021-ui-shell.md`.
- Transport interface (`klunki/lib/transport/game_transport.dart`): `config`, `Set<Player> localPlayers`, `game`, `moves`,
  `Stream<AcceptedMove> accepted`, `Future<SubmitResult> submit(move)`, `dispose()`; `RejectReason {notYourTurn, illegal, gameOver, disconnected}`.

## Acceptance criteria
- [ ] **Setup view** (for the current placer): a 10×10 grid with the ships placed so far, a "next ship: Kreuzer (4)" label,
      a rotate toggle (h/v), and a ghost preview on hover/tap that turns red where illegal. Tap → `place`.
      **"Zufällig"** → `autoplace` with a random seed (store the seed in the move, so replays and network sync stay deterministic).
      Optional "Zurücksetzen": you can't undo inside the engine. Leave it out, or make it local-only before the first
      submit, and say which in your report.
- [ ] After A's fleet is complete: handover to B ("Gib das Gerät an O weiter"), B places, then handover to A, then battle.
- [ ] **Battle view** for the current shooter: the target grid (large, tappable unknown cells) and their own grid
      (small: own ships + incoming shots), plus a remaining-ships count for both sides.
      Tap an unknown cell → `fire`. Feedback "Wasser", "Treffer!" or "Versenkt: Kreuzer!".
      On a hit you shoot again (no handover); on a miss you get "Weiter", then the handover.
- [ ] Hidden info: the opponent's `ownGrid`/`placements` are never rendered. While the cover is up neither grid is in the tree.
- [ ] Coordinates labelled A–J (rows) / 1–10 (cols), the same as the console (`"E5"`).
- [ ] Widget test `klunki/test/ui/games/schiffe_screen_test.dart`:
  - both players use "Zufällig", then the battle starts and the handovers happen in the right order;
  - in A's battle view the cells of B's unhit ships show as unknown (check a known B ship cell via `g.placements(Player.b)`);
  - play to the end by tapping the first unknown target cell repeatedly (with covers acknowledged; cap the iterations), then the result dialog shows;
  - a manual placement test: place ship 0 horizontally at A1 by tapping, and an illegal touching placement is rejected.
- [ ] Give cells keys like `Key('schiffe-target-$r-$c')`, `Key('schiffe-own-$r-$c')`, `Key('schiffe-setup-$r-$c')`.
- [ ] `flutter analyze` and `flutter test` are green.

## Constraints
- Board rules: engine stays pure Dart and unchanged. Never install toolchains, download SDK components, accept
  licenses, sign up for accounts or publish anything without the user's OK. No new pub.dev dependencies.
- Only touch the paths above. Don't commit unless asked.
- The layout must fit two grids on a phone in portrait (target grid on top, own grid smaller below) and side by side on a tablet/landscape.

## Hints / context
- Text reference: `cd packages/klunki_engine && dart run bin/klunki.dart schiffe` then `fleet`, `fleet 3`, `E5`, and
  `dart run bin/klunki.dart demo schiffe`. `lib/debug/schiffe_text.dart` renders "own fleet | shots at" side by side.
- Use `Random().nextInt(1 << 31)` for the autoplace seed. The engine is deterministic for a given seed.

## Definition of done
```bash
cd klunki
flutter analyze
flutter test test/ui/games/
flutter test
```
All green; manual hot-seat game to the end; card status set to DONE.
