# KLD-032 — `NetworkTransport` on top of `klunki_net`

- **ID:** `KLD-032`
- **Title:** `NetworkTransport`: the app's `GameTransport` over `KlunkiHost` / `KlunkiGuest`
- **Milestone:** P3
- **Status:** DONE
- **Depends on:** KLD-020 (`GameTransport`, `GameController`), KLD-030 (`klunki_net`)
- **Touched paths:**
  - `klunki/pubspec.yaml` (+ `pubspec.lock`): path dependency `klunki_net: path: ../packages/klunki_net`
  - `klunki/lib/transport/network_transport.dart` (new)
  - `klunki/test/transport/network_transport_test.dart` (new)
  - `docs/tasks/KLD-032-network-transport.md`

## Goal
`GameController` runs network games unchanged: one `NetworkTransport` per
device, one local player each. The host's engine stays authoritative (KLD-030).

## API
```dart
enum NetConnectionState { connecting, connected, peerMissing, reconnecting, closed }
enum NetRole { host, guest }

class NetworkTransport implements GameTransport {
  static Future<NetworkTransport> host(GameConfig config,
      {String name = 'Host', int port = 0, Object? address, Duration pingInterval, Duration timeout});
  static Future<NetworkTransport> join(Object host, int port,
      {String name = 'Guest', String? token, Duration pingInterval, Duration timeout});

  NetRole role;  Player me;  Set<Player> localPlayers; // {me}
  Game game; List<AcceptedMove> moves; Stream<AcceptedMove> accepted; // mirror the net session
  Future<SubmitResult> submit(Map<String, dynamic> move);
  void dispose();                 // bye + close (fire and forget)
  Future<void> close();           // same, awaitable

  ValueListenable<NetConnectionState> connection;
  Stream<NetConnectionState> connectionChanges;
  String? peerName;  String? lastDisconnectReason;
  int? port;                      // host
  String? token;                  // guest: rejoin token
  Future<void> reconnect();       // guest only (StateError on the host)
  static RejectReason mapReason(String netReason); // @visibleForTesting
}
```

## Design
- `game` is the net session's engine (`KlunkiHost.game` / `KlunkiGuest.game`), so
  after a guest `Resynced` it is the new replayed instance.
- `klunki_net` does not report `GameEvent`s. The transport keeps a private
  **shadow engine** and gets each move's event from `applyMove`, the same way
  `HotSeatTransport` does. `AcceptedMove.index` is the protocol index.
- `_catchUp()` reads the session's log (not the event payloads) and emits every
  index it has not emitted yet. It runs on construction (snapshot), on every
  `MoveAccepted` / `Resynced`, after an accepted `submit` and after `reconnect()`.
  That makes emission idempotent and in order, exactly once. It also covers
  events the net layer emitted before the transport subscribed, and missed moves
  after a reconnect.
- `accepted` is a sync broadcast stream, like hot-seat: an accepted `submit`
  has been emitted before its future completes. Between a remote move arriving
  and the next microtask, `game` can be one move ahead of `moves`.
- `submit` check order: disposed → `disconnected`, game over → `gameOver`,
  not `me` to move → `notYourTurn`, non-JSON move → `illegal` (so it cannot
  break the guest's socket), then net. Net reasons: `not your turn` / `stale index` /
  `index ahead` → `notYourTurn`, `game is over` → `gameOver`,
  `not connected` / `disconnected` → `disconnected`, everything else
  (`illegal move`, `move is not JSON`) → `illegal`.
- Connection state: the host starts in `connecting` (no guest yet), moves to `connected` on
  `PeerConnected` and to `peerMissing` on `PeerDisconnected` (it keeps listening). The guest starts
  `connected`, goes to `peerMissing` on disconnect (including the host's `bye`), and runs
  `reconnecting` → `connected` during `reconnect()` (back to `peerMissing` if that throws).
  Both end in `closed` after dispose.
- The host may keep playing while the guest is away; the guest catches up on
  reconnect.
- `GameController.restart` is not supported for network games (its default
  factory is hot-seat); the pairing UI should not offer it.
- No interface change: `game_transport.dart`, `hot_seat_transport.dart`,
  `game_controller.dart` untouched.

## Acceptance criteria
- [x] Factories `host` / `join`; `localPlayers == {me}`; mirrored game/moves/accepted.
- [x] Rejection mapping; connection state as `ValueListenable` + `Stream`; peer name.
- [x] Guest `reconnect()`; after `Resynced` the new game instance; missed moves emitted once, in order.
- [x] `dispose` sends `bye`.
- [x] Loopback tests: full Connect Four + Mühle via two `GameController`s (identical end
      states), `canAct` per device, `needsHandover` never set (incl. Quartett), rejections,
      disconnect + reconnect resume, reconnect failure.

## Constraints
- No UI, engine or `klunki_net` changes. No downloads (`flutter pub get --offline`).

## Definition of done
`cd klunki && flutter analyze && flutter test`, `packages/klunki_net` and
`packages/klunki_engine` `dart test` green.
