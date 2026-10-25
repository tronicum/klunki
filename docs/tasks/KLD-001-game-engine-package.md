# KLD-001 — `klunki_engine` package scaffold

- **Milestone:** M0
- **Status:** TODO
- **Depends on:** none
- **Touched paths:** `packages/klunki_engine/`

## Goal
A pure-Dart Dart package with shared types, zero Flutter dependency, testable offline.

## Acceptance criteria
- [ ] `pubspec.yaml` declares `name: klunki_engine`, SDK `>=3.4.0 <4.0.0`.
- [ ] `lib/game.dart` exports shared `Player`, `Move`, `GameEvent`, `GameResult`, `GameState`, etc.
- [ ] `test/` runs with `dart test` and all tests pass.

## Definition of done
`cd packages/klunki_engine && dart test` reports "All tests passed."
