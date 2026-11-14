/// The engine-owned pseudo random number generator (KLD-072).
///
/// Every deal, dice roll, tile bag and random setup comes from [GameRandom],
/// never from `dart:math` `Random(seed)`: the SDK does not promise that
/// `Random(seed)` gives the same numbers on the VM, dart2js and wasm or in
/// the next SDK version, and a deal that changes under a saved game (KLD-079)
/// or between a native host and a browser guest (KLD-064 replay check) breaks
/// the game. [GameRandom] is specified here bit for bit and pinned by a golden
/// test (`test/prng_test.dart`), on the VM and compiled to JavaScript.
///
/// **Algorithm: xoshiro128\*\*** (Blackman and Vigna, 2018; 128-bit state,
/// 32-bit outputs, period 2^128 − 1), seeded by **murmur3's fmix32** finalizer:
///
/// * The seed is split into `lo` = its low 32 bits and `hi` = the next 32 bits
///   (two's complement for negative seeds). With `a = fmix32(lo + 0x9e3779b9)`,
///   `b = fmix32(hi + 0x7f4a7c15)`, `c = fmix32(lo + 0x3c6ef372)` and
///   `d = fmix32(hi + 0xf39cc060)` (sums modulo 2^32) the state is
///   `s0 = b`, `s1 = a ^ d`, `s2 = c ^ b`, `s3 = d ^ c`. fmix32 is a
///   bijection, so `s0` gives back `hi` and then `s1` gives back `lo`:
///   different seeds never share a state, and every output word depends on
///   both halves. An all-zero state (not reachable in practice) becomes
///   `s0 = 1`.
/// * [nextUint32]: `rotl(s1 * 5, 7) * 9`, then the xoshiro128 state step.
/// * [nextInt]`(max)`: rejection sampling, unbiased: draws until a word is
///   below the largest multiple of `max` that fits in 2^32, returns it modulo
///   `max`. `max` is 1 to 2^32.
/// * [nextDouble]: 53 bits, `((a >> 5) * 2^26 + (b >> 6)) / 2^53`.
/// * [nextBool]: the top bit of one word.
/// * [shuffle]: Fisher–Yates from the end, `j = nextInt(i + 1)`
///   (`List.shuffle` is not used: its algorithm belongs to the SDK).
///
/// All arithmetic stays below 2^53 and every result is masked to 32 bits, so
/// the VM (64-bit ints) and JavaScript (doubles) compute the same numbers.
/// Seeds are exact on both for |seed| ≤ 2^53 (the app's seeds are 53 bits,
/// see `newGameSeed`).
///
/// [GameRandom] implements `dart:math` [Random], so bots and debug helpers
/// that take a `Random` accept it too.
library;

import 'dart:math' show Random;

const int _mask32 = 0xFFFFFFFF;
const int _two32 = 0x100000000;

/// Deterministic xoshiro128\*\* generator; see the library documentation.
class GameRandom implements Random {
  int _s0, _s1, _s2, _s3;

  /// A generator for [seed]; the same seed gives the same numbers on every
  /// platform and SDK.
  factory GameRandom(int seed) {
    final lo = seed & _mask32;
    final hi = ((seed - lo) ~/ _two32) & _mask32;
    final a = _fmix32((lo + 0x9e3779b9) & _mask32);
    final b = _fmix32((hi + 0x7f4a7c15) & _mask32);
    final c = _fmix32((lo + 0x3c6ef372) & _mask32);
    final d = _fmix32((hi + 0xf39cc060) & _mask32);
    return GameRandom.fromState(b, a ^ d, c ^ b, d ^ c);
  }

  /// A generator with the raw xoshiro128 state words (32 bits each, not all
  /// zero; an all-zero state becomes `s0 = 1`). For tests against the
  /// reference implementation.
  GameRandom.fromState(int s0, int s1, int s2, int s3)
      : _s0 = s0 & _mask32,
        _s1 = s1 & _mask32,
        _s2 = s2 & _mask32,
        _s3 = s3 & _mask32 {
    if (_s0 == 0 && _s1 == 0 && _s2 == 0 && _s3 == 0) _s0 = 1;
  }

  /// The next 32-bit word, 0 to 2^32 − 1.
  int nextUint32() {
    final result = _mul32(_rotl(_mul32(_s1, 5), 7), 9);
    final t = (_s1 << 9) & _mask32;
    _s2 ^= _s0;
    _s3 ^= _s1;
    _s1 ^= _s2;
    _s0 ^= _s3;
    _s2 ^= t;
    _s3 = _rotl(_s3, 11);
    return result;
  }

  /// A uniform int from 0 (inclusive) to [max] (exclusive), 1 ≤ max ≤ 2^32.
  @override
  int nextInt(int max) {
    if (max < 1 || max > _two32) throw RangeError.range(max, 1, _two32, 'max');
    final limit = _two32 - _two32 % max;
    while (true) {
      final r = nextUint32();
      if (r < limit) return r % max;
    }
  }

  /// A uniform double in [0, 1) with 53 random bits.
  @override
  double nextDouble() {
    final a = nextUint32() >> 5, b = nextUint32() >> 6;
    return (a * 67108864 + b) / 9007199254740992;
  }

  @override
  bool nextBool() => nextUint32() >= 0x80000000;

  /// Shuffles [list] in place (Fisher–Yates from the end).
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final t = list[i];
      list[i] = list[j];
      list[j] = t;
    }
  }
}

/// A fresh game seed: 53 bits from `Random.secure()` (KLD-072), the widest
/// integer that JSON carries exactly to a browser. A guest that sees only
/// its own hand can no longer try every seed (2^31 were a few minutes of
/// work). [random] replaces the secure source in tests.
int secureSeed([Random? random]) {
  final r = random ?? Random.secure();
  return r.nextInt(1 << 21) * _two32 + r.nextInt(_two32);
}

/// `list..shuffleWith(rng)`: [GameRandom.shuffle] in a cascade.
extension GameShuffle<T> on List<T> {
  void shuffleWith(GameRandom rng) => rng.shuffle(this);
}

/// a * b modulo 2^32 for 32-bit a, b; every partial product stays below 2^53.
int _mul32(int a, int b) => ((a & 0xFFFF) * b + ((((a >> 16) * b) & 0xFFFF) << 16)) & _mask32;

int _rotl(int x, int k) => ((x << k) & _mask32) | (x >> (32 - k));

/// murmur3's 32-bit finalizer (a bijection on 32-bit words).
int _fmix32(int h) {
  h ^= h >> 16;
  h = _mul32(h, 0x85ebca6b);
  h ^= h >> 13;
  h = _mul32(h, 0xc2b2ae35);
  h ^= h >> 16;
  return h;
}
