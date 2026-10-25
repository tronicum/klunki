# KLD-025 — Quartett (Sets) screen

- **ID:** `KLD-025`
- **Title:** Quartett Sets screen: hand grouped by set, ask for a card, quartets laid down, handover
- **Milestone:** P2 — Hot-seat on one device
- **Status:** TODO
- **Depends on:** KLD-021 (shell, `HandoverCover`, placeholder `QuartettSetsScreen`), KLD-024 (`klunki/lib/ui/games/quartett_card.dart` → `QuartettCardView`)
- **Touched paths:**
  - `klunki/lib/ui/games/quartett_sets_screen.dart`
  - `klunki/test/ui/games/quartett_sets*`
  - `docs/tasks/KLD-025-quartett-sets-screen.md` (status only)

## Goal
Two people on one device can play classic Quartett (ask for cards, collect sets of four) to the end. Each player
sees only their own hand, with a handover between turns.

## Repo context
- Flutter app `klunki/`; engine `package:klunki_engine/klunki_engine.dart` (pure Dart). UI strings in German.
  **Name clash:** the engine's `Card` vs Material's `Card`. Import the engine with `hide Card`, plus
  `import 'package:klunki_engine/quartett.dart' as q;`.
- **Read first:** `klunki/lib/ui/shell/**` (KLD-021), `klunki/lib/game/**` + `klunki/lib/transport/**` (KLD-020), and
  `klunki/lib/ui/games/quartett_card.dart` (KLD-024). Reuse `QuartettCardView` (its `compact` mode is for hands). **Don't edit it.**
  If it lacks something, build a local wrapper and report the gap.
  Expected contract, which may differ slightly (adapt): `GameController` (ChangeNotifier) with `game`, `spec`, `canAct`,
  `Future<GameEvent?> submit(Map move)` (null = rejected), `lastEvent`, `moves`, `needsHandover` + an acknowledge method,
  `newGame()`. `GameScreen(controller:, board:)` provides the status line, result dialog, history, new game and `HandoverCover`.
  Keep `const QuartettSetsScreen({super.key, required this.controller})`.
- Engine API (`packages/klunki_engine/lib/quartett.dart`), with `final g = controller.game as QuartettGame` (mode `sets`;
  the registry creates it with `handSize: 8`, so there's a draw pile):
  - `g.handOf(p)` → `List<Card>` sorted by id; `g.quartetsOf(p)` → laid-down set letters; `g.stockSize`
  - `QuartettGame.setNames` (A–H), `QuartettGame.deck` (32 cards, 8 sets × 4: `A1…H4`), `QuartettGame.cardById(id)`
  - `g.legalMoves` → `{'action': 'ask', 'card': id}` for every card of a set you hold that you don't hold yourself
  - event payload: `{'card': id, 'from': 'a'|'b', 'hit': bool, 'quartet': setLetter?, 'drew': id?}`
  - rules: hit → the card moves over and the **same player asks again**. Miss → the asker draws from the stock (if any)
    and the turn passes. A complete set is laid down automatically. Ends when all 8 sets are down; more quartets wins, 4:4 is a draw.
    A player with an empty hand automatically draws, or is skipped (engine `_startTurn`).
  - `GameSpec.hiddenInformation` is true for `quartett-sets`.

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
- [ ] Own hand, grouped by set (set name header, cards via `QuartettCardView(compact: true)`), showing which cards of each set are still missing.
- [ ] Ask flow: pick a set you hold → pick one of the missing cards (only those in `legalMoves`) → submit `ask`.
      Alternative: tap a "missing" slot directly. Disabled when `!canAct`.
- [ ] Result feedback: "Treffer! O gibt dir B3" (ask again), "Fehlanzeige – du ziehst eine Karte" (shows the drawn card,
      **to the asker only, before the handover**), "Quartett! Klassiker abgelegt".
- [ ] Public info always visible: the opponent's hand **count** (`handOf(other).length`, never the cards), the stock count,
      the laid-down quartets of both players (set names), the score n:m.
- [ ] Handover: when the turn passes (miss), the asker acknowledges the feedback ("Weiter"), then `HandoverCover` shows.
      No card ids or names of either hand are in the widget tree while the cover is up.
- [ ] Widget test `klunki/test/ui/games/quartett_sets_screen_test.dart`, fixed seed:
  - only the active player's cards are in the tree (check a known opponent card id from `g.handOf(other)` → not found);
  - a hit keeps the same player, and a miss leads to the cover;
  - play to the end by always asking the first legal card (loop with a cap), then the result dialog shows.
- [ ] `flutter analyze` and `flutter test` are green.

## Constraints
- Board rules: engine stays pure Dart and unchanged. Never install toolchains, download SDK components, accept
  licenses, sign up for accounts or publish anything without the user's OK. No new pub.dev dependencies.
- Only touch the paths above (not `quartett_card.dart`). Don't commit unless asked.

## Hints / context
- Text reference: `cd packages/klunki_engine && dart run bin/klunki.dart quartett-sets` (`help`, `moves`, `B3`) and
  `dart run bin/klunki.dart demo quartett-sets`. `lib/debug/quartett_text.dart` (`QuartettSetsText`) shows what each player may see.

## Definition of done
```bash
cd klunki
flutter analyze
flutter test test/ui/games/
flutter test
```
All green; manual hot-seat game to the end; card status set to DONE.
