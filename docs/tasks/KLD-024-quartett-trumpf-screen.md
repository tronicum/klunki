# KLD-024 — Quartett (Trumpf) screen + shared card widget

- **ID:** `KLD-024`
- **Title:** Quartett Trumpf screen: top card with stats, tap a stat, trick reveal, pot, handover
- **Milestone:** P2 — Hot-seat on one device
- **Status:** IN_PROGRESS (an agent is working on it, 2026-10-25)
- **Depends on:** KLD-021 (shell, `HandoverCover`, placeholder `QuartettTrumpfScreen`), which builds on KLD-020 (`GameController`)
- **Touched paths:**
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart`
  - `klunki/lib/ui/games/quartett_card.dart` (new; **also used by KLD-025**)
  - `klunki/test/ui/games/quartett_trumpf*`
  - `docs/tasks/KLD-024-quartett-trumpf-screen.md` (status only)

## Goal
Two people on one device can play Quartett Trumpf (Supertrumpf) to the end. The active player sees only
**their own** top card, taps a stat, and both cards are revealed with the winner of the trick. The device is
handed over before the next top card becomes visible.

## Repo context
- Flutter app `klunki/`; engine `package:klunki_engine/klunki_engine.dart` (pure Dart). UI strings in German.
- **Name clash:** the engine's Quartett card class is `Card`, and so is Material's widget. Use
  `import 'package:klunki_engine/klunki_engine.dart' hide Card;` plus `import 'package:klunki_engine/quartett.dart' as q;`
  and refer to `q.Card`, or another clean way.
- **Read first:** `klunki/lib/ui/shell/**` (KLD-021) and `klunki/lib/game/**` + `klunki/lib/transport/**` (KLD-020).
  Expected contract, which may differ slightly (adapt): `GameController` (ChangeNotifier) with `game`, `spec`, `canAct`,
  `Future<GameEvent?> submit(Map move)` (null = rejected), `lastEvent`, `moves`, `needsHandover` + an acknowledge method,
  `newGame()`. `GameScreen(controller:, board:)` provides the status line, result dialog, history, new game and the `HandoverCover`.
  Keep `const QuartettTrumpfScreen({super.key, required this.controller})`.
- Engine API (`packages/klunki_engine/lib/quartett.dart`), with `final g = controller.game as QuartettGame` (mode `trumpf`):
  - `g.topCard(p)` → `Card?` (`id` e.g. `"A1"`, `name`, `set` letter, `stats: Map<String, num>`)
  - `g.stackSize(p)`, `g.potSize` (cards waiting after ties), `g.tricks`, `QuartettGame.maxTricks` (200)
  - `QuartettGame.stats`: 5 × `QuartettStat {id, label, unit, higherWins}` (ps, kmh, ccm, kg ↓, sec0to100 ↓)
  - `QuartettGame.setNames` (A–H → name), `QuartettGame.cardById(id)`, `QuartettGame.statById(id)`
  - move: `{'action': 'pick', 'stat': id}`; `g.legalMoves` = one pick per stat
  - event payload: `{'stat', 'cards': {'a': id, 'b': id}, 'values': {'a': n, 'b': n}, 'trickWinner': 'a'|'b'|null, 'pot': n}`
  - rules: the trick winner picks next; on a **tie** both cards go to the pot and the **same player picks again**.
    You lose when your stack is empty; after 200 tricks the larger stack wins.
  - `GameSpec.hiddenInformation` is true for `quartett-trumpf`.

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
- [ ] `quartett_card.dart`: a reusable `QuartettCardView` showing the card id, name, set name (`setNames[card.set]`) and all 5 stats
      (label, value, unit; "↓ gewinnt" marker for `higherWins == false`). Options: `onStatTap` (null = not tappable),
      `highlightStat`, `faceDown` (shows the card back only), `compact` (smaller, for hands in KLD-025). **No game logic**,
      and it must not depend on `GameController`.
- [ ] Pick view (`canAct`, not covered): your top card face up with tappable stats; the opponent's stack face down with its count;
      your stack count; pot count if > 0; "Stich n / 200".
- [ ] Tapping a stat submits `pick`. Then a **reveal** view shows both cards side by side with the picked stat highlighted, the values,
      and "X gewinnt den Stich" / "Gleichstand – Karten in den Pott". It also shows who picks next, with a "Weiter" button.
- [ ] Hidden info: the opponent's top card never shows outside the reveal. After the reveal, the next pick view only appears
      after a handover cover ("Gib das Gerät an O weiter" / "X ist wieder dran"), **including on ties and when the same player picks again**.
      Reason: the opponent watched the reveal, so the device may be in their hands. If 020's `needsHandover` doesn't cover the
      "same player again" case, do it locally in the screen (show the cover after "Weiter") and mention it in your report.
- [ ] Widget test `klunki/test/ui/games/quartett_trumpf_screen_test.dart`, with a fixed seed so it's deterministic:
  - in the pick view, only the active player's top-card name is in the tree, not the opponent's (`find.text(...)` → none);
  - one full trick: tap stat → reveal shows both names and the winner → "Weiter" → cover visible, no card names in the tree → "Bereit";
  - play to the end by tapping stats in a loop (cap the iterations) and assert the result dialog shows.
- [ ] `flutter analyze` and `flutter test` are green.

## Constraints
- Board rules: engine stays pure Dart and unchanged. Never install toolchains, download SDK components, accept
  licenses, sign up for accounts or publish anything without the user's OK. No new pub.dev dependencies, no image assets
  (cards are text + colors; color per set letter is fine).
- Only touch the paths above. **KLD-025 depends on `QuartettCardView`**: keep its constructor stable and documented.
- Don't commit unless asked.

## Hints / context
- Text reference: `cd packages/klunki_engine && dart run bin/klunki.dart quartett-trumpf` (then `help`, `1`…`5` or stat ids, `auto 5`)
  and `dart run bin/klunki.dart demo quartett-trumpf`. `lib/debug/quartett_text.dart` shows how the console hides the opponent's info.
- Number formatting: `0–100 km/h` values are decimals (e.g. 2.7 s); the others are integers.

## Definition of done
```bash
cd klunki
flutter analyze
flutter test test/ui/games/
flutter test
```
All green; manual hot-seat game to the end; card status set to DONE.
