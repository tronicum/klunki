// KLD-072: the engine-owned PRNG. The vectors below are the output of the
// C reference of xoshiro128** (Blackman/Vigna) with the seeding described in
// lib/prng.dart; they must never change (every deal and dice roll depends on
// them: a change needs a rules version bump of every game with a seed).
@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:klunki_engine/prng.dart';
import 'package:test/test.dart';

/// First six 32-bit words per seed (C reference, uint32_t arithmetic).
const _words = {
  0: [552252858, 1657986846, 3345064230, 296417636, 2181872584, 1715809803],
  1: [2562523787, 1531140423, 3513259819, 1499315193, 2899830629, 3658717969],
  42: [2543292313, 1043658083, 3359365626, 960763603, 3864948998, 3138929559],
  -1: [1381168876, 2688481711, 1534903908, 2152625949, 389910028, 2136280100],
  2147483647: [3844872641, 4158481377, 4128648606, 2465908490, 804638802, 1007938876],
  4503599627370497: [844444383, 1869929939, 3211784278, 1430316107, 4034541056, 1708349968],
  -9007199254740991: [554564237, 3729006822, 2405965018, 346460437, 466453468, 1485444042],
};

/// Everything a game draws, for one seed, as JSON: the same program runs on
/// the VM here and compiled to JavaScript below.
const _probe = r'''
import 'dart:convert';
import 'package:klunki_engine/prng.dart';

String probe() {
  final out = <String, Object>{};
  for (final seed in [0, 1, 42, -1, 2147483647, 4503599627370497, -9007199254740991, 4503599627370496, 7777777777777]) {
    final r = GameRandom(seed);
    final deck = List.generate(32, (i) => i);
    r.shuffle(deck);
    out['$seed'] = {
      'words': [for (var i = 0; i < 4; i++) r.nextUint32()],
      'dice': [for (var i = 0; i < 12; i++) r.nextInt(6) + 1],
      'big': [r.nextInt(0x100000000), r.nextInt(1000000007), r.nextInt(3)],
      'double': r.nextDouble(),
      'bool': [for (var i = 0; i < 8; i++) r.nextBool()],
      'deck': deck,
    };
  }
  return jsonEncode(out);
}

void main() => print(probe());
''';

void main() {
  test('xoshiro128** core matches the reference vector for state 1, 2, 3, 4', () {
    final r = GameRandom.fromState(1, 2, 3, 4);
    expect([for (var i = 0; i < 6; i++) r.nextUint32()], [11520, 0, 5927040, 70819200, 2031721883, 1637235492]);
  });

  test('seeded words match the C reference (golden)', () {
    for (final MapEntry(key: seed, value: words) in _words.entries) {
      final r = GameRandom(seed);
      expect([for (var i = 0; i < words.length; i++) r.nextUint32()], words, reason: 'seed $seed');
    }
  });

  test('derived draws are pinned (golden)', () {
    final r = GameRandom(2024);
    expect([for (var i = 0; i < 12; i++) r.nextInt(6) + 1], [4, 4, 1, 4, 4, 2, 4, 4, 2, 4, 6, 2]);
    final deck = List.generate(10, (i) => i);
    GameRandom(7).shuffle(deck);
    expect(deck, [7, 4, 1, 9, 5, 6, 3, 0, 8, 2]);
  });

  test('ranges, uniform dice, different seeds differ', () {
    final r = GameRandom(99);
    final counts = List.filled(6, 0);
    for (var i = 0; i < 60000; i++) {
      counts[r.nextInt(6)]++;
      final d = r.nextDouble();
      expect(d >= 0 && d < 1, isTrue);
    }
    for (final c in counts) {
      expect(c, inInclusiveRange(9400, 10600));
    }
    // Two dice in a row (Mäxchen, Baulöwe): all 36 pairs about equally often.
    final pairs = List.filled(36, 0);
    for (var i = 0; i < 72000; i++) {
      pairs[r.nextInt(6) * 6 + r.nextInt(6)]++;
    }
    for (final c in pairs) {
      expect(c, inInclusiveRange(1800, 2200));
    }
    expect(r.nextInt(1), 0);
    expect(() => r.nextInt(0), throwsRangeError);
    expect(() => r.nextInt(0x100000001), throwsRangeError);
    final firsts = {for (var s = 0; s < 1000; s++) GameRandom(s).nextUint32()};
    expect(firsts.length, greaterThan(990), reason: 'the first word depends on the seed');
    expect(GameRandom(1 << 32).nextUint32(), isNot(GameRandom(0).nextUint32()), reason: 'the high half counts');
  });

  test('secureSeed: 53 bits, non-negative, varies', () {
    final seeds = {for (var i = 0; i < 50; i++) secureSeed()};
    expect(seeds.length, greaterThan(45));
    for (final s in seeds) {
      expect(s, inInclusiveRange(0, 9007199254740991));
    }
    expect(seeds.any((s) => s > 0xFFFFFFFF), isTrue, reason: 'wider than 32 bits');
  });

  test('compiled to JavaScript (dart2js), the same numbers as on the VM', () async {
    final node = _which('node');
    if (node == null) {
      markTestSkipped('node not found: the JavaScript comparison needs Node.js');
      return;
    }
    final tmp = await Directory.systemTemp.createTemp('klunki_prng_js');
    addTearDown(() => tmp.delete(recursive: true));
    final entry = File('${tmp.path}/main.dart')..writeAsStringSync(_probe);
    final packages = File('.dart_tool/package_config.json').absolute.path;
    final compile = await Process.run(
        Platform.resolvedExecutable, ['compile', 'js', '--packages=$packages', '-o', '${tmp.path}/out.js', entry.path]);
    expect(compile.exitCode, 0, reason: '${compile.stdout}\n${compile.stderr}');
    final js = await Process.run(node, ['${tmp.path}/out.js']);
    expect(js.exitCode, 0, reason: '${js.stderr}');
    final vm = await Process.run(Platform.resolvedExecutable, ['run', '--packages=$packages', entry.path]);
    expect(vm.exitCode, 0, reason: '${vm.stderr}');
    final vmOut = jsonDecode((vm.stdout as String).trim()) as Map<String, dynamic>;
    final jsOut = jsonDecode((js.stdout as String).trim()) as Map<String, dynamic>;
    expect(jsOut, vmOut);
    expect((vmOut['0'] as Map)['words'], hasLength(4));
  });
}

String? _which(String name) {
  final env = Platform.environment['KLUNKI_NODE'];
  if (env != null && env.isNotEmpty) return env;
  for (final dir in (Platform.environment['PATH'] ?? '').split(Platform.isWindows ? ';' : ':')) {
    final f = File('$dir${Platform.pathSeparator}$name');
    if (f.existsSync()) return f.path;
  }
  return null;
}
