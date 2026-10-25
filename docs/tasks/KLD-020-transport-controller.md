# KLD-020 — Typed transport + hot-seat transport + game controller

- **ID:** `KLD-020`
- **Title:** Typed `GameTransport`, `HotSeatTransport` and `GameController` (ChangeNotifier)
- **Milestone:** P2
- **Status:** DONE
- **Depends on:** none (uses the engine registry: `GameConfig`, `GameSpec`, `gameSpecs`, `createGame`, `replay`)
- **Touched paths:**
  - `klunki/lib/transport/**`
  - `klunki/lib/game/**`
  - `klunki/test/transport/**`
  - `klunki/test/game/**`
  - `docs/tasks/KLD-020-transport-controller.md`

## Goal
One app layer that every game screen (KLD-021..026) and every transport
(hot-seat now, `NetworkTransport` in KLD-032) share. A screen only talks to a
`GameController`; the controller only talks to a `GameTransport`; the transport
runs every move through the engine, which stays the single source of truth.

## Design

```
UI screen ──listens──▶ GameController (ChangeNotifier)
                         │ submit / undo / restart / acknowledgeHandover
                         ▼
                      GameTransport ──accepted stream──▶ GameController
                         │  (HotSeatTransport | NetworkTransport later)
                         ▼
                      engine Game.applyMove  (authoritative, local copy)
```

### `GameTransport` (`klunki/lib/transport/game_transport.dart`)
```dart
abstract class GameTransport {
  GameConfig get config;
  Set<Player> get localPlayers;            // hot-seat: {a, b}; network: {self}
  Game get game;                           // read-only view, never call applyMove on it
  List<AcceptedMove> get moves;            // accepted log, index == position
  Stream<AcceptedMove> get accepted;       // every accepted move, any side, in order
  Future<SubmitResult> submit(Map<String, dynamic> move);
  void dispose();
}
class AcceptedMove { int index; Player player; Map<String, dynamic> move; GameEvent event; }
enum RejectReason { notYourTurn, illegal, gameOver, disconnected }
class SubmitResult { AcceptedMove? accepted; RejectReason? reason; bool get isAccepted; GameEvent? get event; }
```
- `config` + `moves` is a full replay (`replay(config, moves.map((m) => m.move))`),
  which is what network sync/reconnect will rely on.
- `moves` was added to the suggested shape so the controller (and reconnect) can
  read the authoritative log instead of rebuilding it from the stream.
- Order of checks in `submit`: disposed → `disconnected`, game over → `gameOver`,
  current player not local → `notYourTurn`, engine returns `null` or throws on a
  malformed move → `illegal`. A rejection never changes state.
- The engine returns `null` both for "game over" and "illegal"; the transport
  disambiguates by checking `isOver` first.

### `HotSeatTransport(GameConfig)` (`klunki/lib/transport/hot_seat_transport.dart`)
- Owns the engine instance from `createGame(config)`; both players local.
- Moves are defensively copied (`Map.unmodifiable`) before applying/logging.
- `accepted` is a **synchronous** broadcast stream: listeners have seen the move
  before the `submit` future completes, so UI state is consistent right away.
- Hot-seat only: `bool get canUndo`, `bool undo()` — rebuilds the game with
  `replay(config, moves minus the last)`. No stream event is emitted for undo.

### `GameController` (`klunki/lib/game/game_controller.dart`)
```dart
class GameController extends ChangeNotifier {
  GameController(GameTransport transport, {GameTransport Function(GameConfig)? transportFactory});
  GameController.hotSeat(GameConfig config);
  GameTransport get transport;
  Game get game;  GameConfig get config;  GameSpec get spec;
  GameEvent? get lastEvent;  List<AcceptedMove> get moves;
  bool get canAct;           // current player local && !game.isOver
  bool get canUndo;          // hot-seat transport with at least one move
  bool get needsHandover;    // hidden-info hot-seat game, turn passed to the other player
  Future<SubmitResult> submit(Map<String, dynamic> move);
  void restart({int? seed}); // fresh transport via factory; same seed unless given
  bool undo();
  void acknowledgeHandover();
}
```
- State changes are driven by the transport's `accepted` stream (local and remote
  moves look the same); `undo`, `restart`, `acknowledgeHandover` notify directly.
- `needsHandover` is set when a `spec.hiddenInformation` game runs with more than
  one local player (hot-seat) and an accepted move (or an undo) leaves a
  *different* player to move while the game is not over. Moves that keep the
  same player to move (e.g. a Schiffe ship placement, a Quartett trick won) do
  not raise it. `restart` clears it (player A always starts).
- `canAct` deliberately ignores `needsHandover`; the KLD-021 cover screen blocks
  input while it is set.
- `restart` disposes the old transport. The default factory is
  `HotSeatTransport.new`; a network controller will pass its own (or not support restart).
- The old `Object`-typed stubs were replaced in place (nothing else imported them).

## Acceptance criteria
- [x] Typed `GameTransport` with accepted stream, `SubmitResult`/`RejectReason`.
- [x] `HotSeatTransport` validates through the engine; rejections leave state unchanged.
- [x] `GameController` with `canAct`, `undo`, `restart({seed})`, `needsHandover`,
      `acknowledgeHandover`, notifies on every change.
- [x] Tests: legal moves for every game in `gameSpecs`, rejection reasons, stream
      order, notifications, canAct, undo, restart with seed, handover only for
      hidden-information games.

## Constraints
- No engine, UI, pubspec or other card changes; no new dependencies.
- No Flutter imports in `klunki_engine` (untouched).

## Definition of done
`cd klunki && flutter analyze && flutter test` and
`cd packages/klunki_engine && dart test` are green.
