# KLD-072: Unguessable hidden setups: secure seeds and an engine-owned PRNG

- **ID:** `KLD-072`
- **Title:** Unguessable hidden setups: secure seeds and an engine-owned PRNG
- **Priority:** high
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** KLD-065 merged (touches the engine games)
- **Touched paths:** `packages/klunki_engine/lib/{registry,quartett,schiffe,gostrategy}.dart`, new `packages/klunki_engine/lib/prng.dart`, `klunki/lib/ui/shell/game_screen.dart` (`newGameSeed`), `klunki/lib/ui/games/schiffe/schiffe_board.dart`, `packages/klunki_net/lib/src/cli/cli.dart`

## Goal
A modified guest can no longer get the host's hand or fleet by brute-forcing a 31-bit `Random()` seed (REVIEW S2). Deals replay the same on the VM, dart2js and wasm, and across SDK versions (REVIEW C5).

## Acceptance criteria
- [ ] Game rules use an engine-owned deterministic PRNG (e.g. splitmix64, xoshiro or SHA-256 counter mode), never `dart:math` `Random(seed)`. A golden test pins its first outputs.
- [ ] Secret seeds are 128 bits from `Random.secure`, in the CLI too. `GameConfig.seed` gets wider and is a hex string in JSON.
- [ ] Battleship "Zufällig" and GoStrategy "Mischen" send the explicit layout (or a 128-bit seed).
- [ ] A test checks that the same seed gives the same deal on the VM and with `-p chrome`.
- [ ] Optional follow-up, noted in the PROTOCOL threat model: guest entropy for a fair shuffle (commit/reveal).

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.
