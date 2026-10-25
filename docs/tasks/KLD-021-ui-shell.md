# KLD-021 — Shared UI shell: GameScreen, HandoverCover, menu routing

- **ID:** `KLD-021`
- **Title:** `GameScreen` frame (status line, hint line, result dialog, move history, undo, new game), `HandoverCover`, menu → game routing with placeholder screens
- **Milestone:** P2 — Hot-seat on one device
- **Status:** DONE (commit `c10573c`)
- **Depends on:** KLD-020 (`GameTransport`, `HotSeatTransport`, `GameController`, game registry)
- **Touched paths:**
  - `klunki/lib/ui/shell/**`
  - `klunki/lib/ui/menu_screen.dart`
  - `klunki/lib/ui/games/*_screen.dart` (placeholders only)
  - `klunki/test/ui/shell/**`
  - `klunki/test/widget_test.dart` (menu expectations; added to the paths by board decision)
  - `docs/tasks/KLD-021-ui-shell.md` (status only)

## Goal
From the menu you can open every game. Each opens a `GameScreen` frame around a placeholder board.
The frame shows whose turn it is, a hint line, a result dialog at the end, the move history, undo (hot-seat) and "new game".
For hidden-information games, the frame covers the board between turns with "Gib das Gerät an O weiter".
KLD-022…026 only replace the placeholder bodies, in parallel.

## Delivered API (the real code — this is the contract for KLD-022…026, 032, 034, 036)
All in `klunki/lib/ui/shell/`. Flutter files import the engine as
`import 'package:klunki_engine/klunki_engine.dart' hide Card;` (the engine's Quartett `Card` clashes with Material's `Card`; see backlog KLD-027).

**`game_screen.dart`**
- `GameScreen({key, required GameController controller, required BoardBuilder boardBuilder, MoveDescriber? describeMove, String? title})`
  - `typedef BoardBuilder = Widget Function(BuildContext context, GameController controller);`
  - `typedef MoveDescriber = String Function(AcceptedMove move);` (history text; default `move.move.toString()`)
  - `title` defaults to `controller.spec.title`.
- `GameScreen.of(context)` → `GameShell` with `controller`, `hint`, and **`setHint(String? text)`** (sets the line under the
  status; `null` hides it; safe to call from `build`, it defers to after the frame). The hint resets on restart.
- Helpers: `String playerMark(Player p)` (`Player.a` = `X`, `Player.b` = `O`), `int newGameSeed()`.
- App bar actions: undo (only when `controller.transport is HotSeatTransport`, enabled by `controller.canUndo`), restart
  ("Neues Spiel?" confirm when a game is running, then `controller.restart(seed: newGameSeed())`), history bottom sheet ("Züge").
- Status line: "X ist am Zug" / "O ist am Zug", at the end "X hat gewonnen" / "Unentschieden".
- Result dialog once per game: headline "X gewinnt!" / "O gewinnt!" / "Unentschieden", content `result.reason`
  (English engine text, see KLD-028), buttons "Menü" (pops the route) and "Nochmal" (restart with a new seed).
- `GameScreen` does not own the controller; whoever creates it disposes it.

**`handover_cover.dart`**
- `HandoverCover({key, required GameController controller, required Widget child})`, used inside `GameScreen` automatically.
- While `controller.needsHandover`: an opaque cover "Gib das Gerät an O weiter" + button "Ich bin O – weiter"
  (calls `controller.acknowledgeHandover()`). The board **stays mounted** (its state survives) but is `Offstage` +
  `ExcludeSemantics` + `TickerMode(enabled: false)`: not painted, not hit-testable, no semantics.
  Note for tests: `find.text(...)` without `skipOffstage: false` does not find offstage widgets.

**`screen_registry.dart`**
- `typedef GameScreenBuilder = Widget Function(GameController controller);`
- `final Map<String, GameScreenBuilder> gameScreens` keyed by `GameSpec.id`
  (`connect4`, `muehle`, `quartett-trumpf`, `quartett-sets`, `schiffe`).
- `Widget buildGameScreen(GameController controller)` (looks up `controller.config.gameId`).
- `Future<void> openGame(BuildContext context, String gameId, {int? seed})`: pushes a `GameSession`, which owns a
  `GameController.hotSeat(GameConfig(gameId, seed: …))` and disposes it on pop. Network games (KLD-034) build their own
  controller and call `buildGameScreen(controller)`.

**`legal_move_board.dart`** (placeholder helper)
- `List<Map<String, dynamic>> legalMovesOf(Game game)` (Connect4's int columns become `{'col': c}`).
- `LegalMoveBoard({key, required GameController controller, label})`: one button per legal move.

**Placeholders** in `klunki/lib/ui/games/`: `Connect4Screen`, `MuehleScreen`, `QuartettTrumpfScreen`, `QuartettSetsScreen`,
`SchiffeScreen`, each `const XScreen({super.key, required this.controller})` returning a `GameScreen` with a `LegalMoveBoard`.
Keep the class names and constructors; replace the body.

**Menu** (`klunki/lib/ui/menu_screen.dart`): one entry per `gameSpecs` item (key `menu-<id>`), tap → `openGame(context, id)`.
The Debug-Konsole button stays (`!kReleaseMode`).

**Stable keys** (use them in tests): `shell-status`, `shell-hint`, `shell-undo`, `shell-restart`, `shell-history`,
`history-sheet`, `result-dialog`, `handover-cover`, `handover-continue`, `menu-<gameId>`, `legal-move-<i>`.

**`GameController` facts used by the shell** (`klunki/lib/game/game_controller.dart`, KLD-020):
`game`, `config`, `spec`, `transport`, `lastEvent`, `List<AcceptedMove> moves`, `canAct`, `canUndo`, `needsHandover`,
`Future<SubmitResult> submit(Map<String, dynamic> move)` (`SubmitResult.isAccepted`, `.event`, `.reason`),
`acknowledgeHandover()`, `bool undo()`, `restart({int? seed})`. There is no `newGame()`.

## Acceptance criteria
- [x] `GameScreen` with app bar (title, undo, restart, history), status line, hint line, result dialog once per game.
- [x] `HandoverCover` hides the board for hidden-information games in hot-seat until O acknowledges.
- [x] Menu lists all `gameSpecs` titles and opens each game; Debug-Konsole button kept.
- [x] Five placeholder screens with the fixed class names, playable end-to-end via `LegalMoveBoard`.
- [x] Routing in one place (`screen_registry.dart`).
- [x] Widget tests in `klunki/test/ui/shell/game_screen_test.dart` (menu, result dialog + "Nochmal"/"Menü", cover for the three
      hidden-information games, no cover for open games, undo, restart confirm, history sheet, hint line);
      `klunki/test/widget_test.dart` updated for the new menu.
- [x] `flutter analyze` and `flutter test` green.

## Constraints
- Engine stays pure Dart. No new pub.dev dependencies. Don't edit KLD-020's files.

## Definition of done
```bash
cd klunki
flutter analyze
flutter test
```
Both green; acceptance criteria ticked; card status DONE.
