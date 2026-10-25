# Klunki — Architecture

## Guiding principles

1. **Framework-agnostic engine.** All game rules live in pure Dart with
   *zero* Flutter imports. This is the most valuable part and is the thing that
   every UI / transport shares. It must be fully unit-testable without a device.
2. **Transport-agnostic engine.** The engine exposes a pure
   `applyMove(state, move) -> result`. Who produces the move (local hot-seat,
   Wi-Fi peer, or a Bluetooth peer, or an AI) is irrelevant to the engine.
3. **One UI, many surfaces.** The Flutter app renders the engine state. The
   same screens work in hot-seat mode; the only difference is where the next
   move comes from.
4. **Modular, agent-ready.** Each unit is a self-contained file or folder with
   a single job. Tasks in `docs/tasks/` are written so an AI agent or developer
   can execute one without global context.

## Layers

```
┌───────────────────────── UI (Flutter widgets) ─────────────────────────┐
│  connect4_screen.dart   muehle_screen.dart   quartett_screen.dart       │
├────────────────────── Transport layer ────────────────────────────────-┤
│  GameTransport (abstract)                                               │
│   ├─ HotSeatTransport   # move comes from local device / pass-the-phone │
│   ├─ NetworkTransport   # move comes from a Wi-Fi peer via message bus  │
│   └─ (BluetoothTransport — later)                                        │
├────────────────────── Engine (pure Dart, klunki_engine) ──────────────-┤
│  games: Connect4Game, MuehleGame, QuartettGame                          │
│  shared: Player, Move, GameEvent, GameResult                            │
│  ai/: simple heuristics for single-device play                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## The transport contract

```dart
/// A transport delivers validated moves to a game and emits events.
abstract class GameTransport {
  /// The local device's own player id.
  Player get self;
  /// Moves produced by the opponent (or AI in single-device).
  Stream<Move> get moves;
  /// Whether a move is currently accepted (it must be this player's turn
  /// and the move must be legal).
  Future<GameEvent> submitMove(Move move);
  void dispose();
}
```

`HotSeatTransport` produces `moves` locally. `NetworkTransport` receives them
over the air and still runs them through the *same* engine, so rules can never
diverge between players.

## Why PWA is a "target"

Flutter web build compiles to a PWA-compatible web app. We add
`flutter web` + `web_dev.dart` / `platform: web` manifest later. The engine
stays identical; only the UI platform changes.
