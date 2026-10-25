# KLD-022 — Connect Four screen

- **ID:** `KLD-022`
- **Title:** 4 Gewinnt screen: tap a column, drop animation, winning-line highlight
- **Milestone:** P2 — Hot-seat on one device
- **Status:** IN_PROGRESS (an agent is working on it, 2026-10-25)
- **Depends on:** KLD-021 (shell + placeholder `Connect4Screen`), which builds on KLD-020 (`GameController`)
- **Touched paths:**
  - `klunki/lib/ui/games/connect4_screen.dart`
  - `klunki/test/ui/games/connect4*`
  - `docs/tasks/KLD-022-connect4-screen.md` (status only)

## Goal
Two people on one device can play 4 Gewinnt to the end. Tap a column and the piece drops in with an animation;
the four winning pieces are highlighted.

## Repo context
- Flutter app `klunki/`; engine `package:klunki_engine/klunki_engine.dart` (pure Dart). UI strings in German.
  If you import the whole engine library, add `hide Card`: the engine's Quartett `Card` clashes with Material's.
- **Read first:** `klunki/lib/ui/shell/**` (KLD-021) and `klunki/lib/game/**` + `klunki/lib/transport/**` (KLD-020).
  Expected contract, which may differ slightly in the real code (adapt to it):
  - `GameController` (ChangeNotifier): `game`, `spec`, `canAct`, `Future<GameEvent?> submit(Map move)`
    (null = rejected), `lastEvent`, `moves`, `needsHandover`, `newGame()`.
  - `GameScreen(controller: …, board: …)` gives you the AppBar, status line, result dialog, history and new game.
    **Don't** reimplement these.
  - The placeholder `class Connect4Screen extends StatelessWidget { const Connect4Screen({super.key, required this.controller}); }`
    must keep its name and constructor (routing depends on it).
- Engine API (`packages/klunki_engine/lib/connect4.dart`), with `final g = controller.game as Connect4Game`:
  - `Connect4Game.cols` = 7, `Connect4Game.rows` = 6
  - `g.toRenderRows()`: `List<List<Player?>>`, **row 0 = top**, `[row][col]`
  - `g.board`: `[col][row]` with **row 0 = bottom** (raw)
  - `g.legalMoves`: `List<int>` of non-full columns (empty when over)
  - move map: `{'col': c}`; `GameEvent.payload` = `{'col', 'row'}` (row from bottom) **only on the winning move**
  - `g.currentPlayer`, `g.result` (`reason: 'four in a row'` / draw), `g.history` entries `{'col','row','player'}`
  - The engine does **not** expose the winning cells. Compute them in the screen: scan from the last move
    (last `history` entry) in the 4 directions for the winner's run of ≥ 4.

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
- [ ] The board renders 7×6 with X (`Player.a`) and O (`Player.b`) as two clearly distinct colors (from the theme), plus empty holes.
- [ ] Tapping anywhere in a column submits `{'col': c}` through `controller.submit` (never `game.applyMove` directly).
      Taps are ignored when `!controller.canAct`, the game is over, or the column isn't in `legalMoves`.
- [ ] The new piece animates falling from the top to its row (≤ 400 ms). The board stays consistent if the user taps fast
      (ignore input during the animation, or queue at most one move).
- [ ] After a win, the four (or more) winning cells are visibly highlighted. The shell shows the result dialog.
- [ ] Column hover/press feedback, and a column-number label 0–6 or 1–7 under or over the board.
- [ ] Widget test `klunki/test/ui/games/connect4_screen_test.dart`: plays a full scripted game by tapping columns
      (e.g. X 0, O 1, X 0, O 1, X 0, O 1, X 0 → X wins vertically). It checks the result dialog text "X gewinnt",
      that the highlight is present on exactly 4 cells (give cells `Key('c4-cell-$row-$col')` and highlighted ones a
      distinguishable key or semantics label), and that tapping a full column does nothing.
- [ ] Draw path: a unit test of the win-cell helper (pure function) for horizontal, vertical, both diagonals.
- [ ] `flutter analyze` and `flutter test` are green.

## Constraints
- Board rules: engine stays pure Dart and unchanged. Never install toolchains, download SDK components, accept
  licenses, sign up for accounts or publish anything without the user's OK. No new pub.dev dependencies.
- Only touch the paths above. Shell/controller gaps go in your report; don't edit 020/021 files.
- No handover in this game (it has no hidden information). Don't commit unless asked.

## Hints / context
- A `LayoutBuilder` + `AspectRatio(7/6)` + `GestureDetector` per column is enough. `CustomPainter` is optional.
- To find the cell that just got filled, compare `history.length` before and after `submit`, or read `history.last`.
- Text-console reference for expected behaviour: `cd packages/klunki_engine && dart run bin/klunki.dart connect4 0 1 0 1 0 1 0`.

## Definition of done
```bash
cd klunki
flutter analyze
flutter test test/ui/games/
flutter test
```
All green; manual check `flutter run -d chrome` (or simulator) plays a game to the end; card status set to DONE.
