# KLD-072: Unguessable hidden setups: secure seeds and an engine-owned PRNG

- **ID:** `KLD-072`
- **Title:** Unguessable hidden setups: secure seeds and an engine-owned PRNG
- **Priority:** high
- **Status:** step 1 DONE ✅ (engine PRNG, 53-bit secure seeds, explicit layouts) · step 2 TODO (128-bit seeds as hex, needs a config/protocol change)
- **Depends on:** KLD-065 merged (touches the engine games)
- **Touched paths:** `packages/klunki_engine/lib/{prng,registry,quartett,schiffe,gostrategy,word_tiles,mau_mau,maexchen,dice_sheet,property}.dart`,
  `packages/klunki_engine/lib/debug/{debug_console,property_text}.dart`, `klunki/lib/ui/shell/game_screen.dart` (`newGameSeed`),
  `packages/klunki_net/lib/src/cli/cli.dart`

## Goal
A modified guest can no longer get the host's hand or fleet by brute-forcing a 31-bit `Random()` seed (REVIEW S2). Deals replay the same on the VM, dart2js and wasm, and across SDK versions (REVIEW C5). Saved games (KLD-079) need the second part: a save must replay the same deal after an SDK update.

## Step 1 (done, 2026-11-14)

**PRNG: xoshiro128\*\*** (Blackman/Vigna; 128-bit state, 32-bit output, period 2^128 − 1) in
`packages/klunki_engine/lib/prng.dart` (`GameRandom`, implements `dart:math` `Random`, so bots and debug helpers keep
their `Random` parameters). Why this one: a well-known, well-tested generator whose arithmetic fits in 32-bit words;
every intermediate value stays below 2^53 and is masked to 32 bits, so the VM (64-bit ints) and JavaScript (doubles)
compute the same numbers without `BigInt` (splitmix64/PCG need 64-bit multiplies, which dart2js cannot do exactly).
Seeding: the seed's low and high 32 bits go through murmur3's `fmix32` (a bijection) into the four state words, so
different seeds never share a state and every output depends on both halves. `nextInt` uses rejection sampling (no
modulo bias), `shuffle` is Fisher–Yates from the end (not `List.shuffle`, whose algorithm belongs to the SDK). The
exact specification is the library doc of `prng.dart`.

- Every game rule draws from `GameRandom`: Quartett deals, Mau-Mau deal and reshuffle, the Wortgewandt tile bag and
  exchanges, Mäxchen and Ausgewürfelt dice (and Ausgewürfelt's random start), Baulöwe dice and card decks, Schiffe
  `autoplace` and GoStrategy `autosetup`. The debug console's `auto` and demos too (reproducible across SDKs).
  `dart:math` `Random` stays only for bots in tests and for UI-only randomness (the drafted random layouts in the
  Schiffe and GoStrategy setup screens, which send the explicit layout, and the Wortgewandt rack shuffle button).
- **Rules versions** (another deal or other dice from the same seed): Quartett Trumpf 2→3, Quartett Sets 1→2,
  Schiffe 1→2, GoStrategy 1→2, Wortgewandt 5→6, Mau-Mau 1→2, Mäxchen 3→4, Ausgewürfelt 1→2, Baulöwe 1→2.
  4 Gewinnt, Mühle and chess (the seed only picks the colours by parity) are unchanged. Old and new builds refuse to
  play these games together; saves from the earlier build show "Kann nicht fortgesetzt werden".
- **Seeds:** `secureSeed()` (engine) gives 53 bits from `Random.secure()`: the widest integer that JSON carries
  exactly to a browser, so `GameConfig.seed` stays an `int` and the protocol is unchanged. The app (`newGameSeed`)
  and the CLI `host` use it. Trying every seed against one's own hand is now 2^53 replays instead of 2^31.
- **Explicit layouts:** the app already sends Schiffe "Zufällig" and GoStrategy "Mischen" as explicit layouts
  (`place` moves / `setup` with the pieces); `autoplace` / `autosetup` with a seed are used by the CLI, the debug
  console and tests only.
- Tests: `packages/klunki_engine/test/prng_test.dart` pins the reference vector of xoshiro128\*\* (state 1, 2, 3, 4),
  the seeded words (checked against a C reference with `uint32_t` arithmetic), dice and a shuffle, checks the
  distribution, and compiles a probe to JavaScript (`dart compile js`) and runs it with Node.js: the same numbers as
  on the VM, also for seeds up to ±2^53 (skipped without `node`; `KLUNKI_NODE` picks one).
- Seeded tests that relied on particular deals were moved to seeds with the same property (Quartett, Wortgewandt
  exchange replay, Mau-Mau and Quartett network secrecy, the Schiffe "swap the fleet" check now picks a fleet that
  answers the shots so far the same way); the Mäxchen 2-seat transcript hash was retaken.

## Step 2 (open)
- `GameConfig.seed` 128 bits as a hex string in JSON (a `GameConfig`/protocol change: `protocolVersion` bump,
  PROTOCOL.md, compat fingerprints) and `GameRandom` seeded from all 128 bits.
- Optional, noted in the PROTOCOL threat model: guest entropy for a fair shuffle (commit/reveal), so the host cannot
  pick a deal either.

## Acceptance criteria
- [x] Game rules use an engine-owned deterministic PRNG, never `dart:math` `Random(seed)`. A golden test pins its first outputs.
- [ ] Secret seeds are 128 bits from `Random.secure`, in the CLI too. `GameConfig.seed` gets wider and is a hex string in JSON.
  (Step 1: 53 bits from `Random.secure` in the app and the CLI, still an int.)
- [x] Battleship "Zufällig" and GoStrategy "Mischen" send the explicit layout.
- [x] A test checks that the same seed gives the same deal on the VM and compiled to JavaScript (dart2js under Node.js
  instead of `-p chrome`: no browser download).
- [ ] Optional follow-up, noted in the PROTOCOL threat model: guest entropy for a fair shuffle (commit/reveal).

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.
