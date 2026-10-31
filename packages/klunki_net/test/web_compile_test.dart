// The browser guest (the PWA) must build without `dart:io`. No browser test
// runner is used:
//
// 1. The import graph of the web entrypoints, with conditional imports
//    resolved the way a web compiler does (`dart.library.io` false,
//    `dart.library.js_interop` true), must not reach `dart:io` or Flutter.
//    (dart2js alone does not prove it: it accepts `dart:io` imports and only
//    fails at run time.)
// 2. `dart compile js` (dart2js, part of the Dart SDK) compiles a small
//    program that joins over WebSocket.
@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final packages = _PackageConfig.load(File('.dart_tool/package_config.json').absolute);

  for (final entry in ['package:klunki_net/guest_web.dart', 'package:klunki_net/klunki_net.dart']) {
    test('$entry does not reach dart:io or Flutter on the web', () {
      final reached = _webImportGraph(Uri.parse(entry), packages);
      expect(reached, contains(Uri.parse('package:klunki_net/src/channel/platform_web.dart')));
      expect(reached, isNot(contains(Uri.parse('package:klunki_net/src/channel/platform_io.dart'))));
      expect(reached.where((u) => u.toString() == 'dart:io' || u.toString().startsWith('package:flutter/')),
          isEmpty);
    });
  }

  test('the VM graph does reach dart:io (the walker sees conditional imports)', () {
    final reached = _webImportGraph(Uri.parse('package:klunki_net/guest_web.dart'), packages, web: false);
    expect(reached, contains(Uri.parse('dart:io')));
  });

  test('a WebSocket guest program compiles to JavaScript', () async {
    final tmp = await Directory.systemTemp.createTemp('klunki_web_compile');
    addTearDown(() => tmp.delete(recursive: true));
    final entry = File('${tmp.path}/main.dart')..writeAsStringSync('''
import 'package:klunki_net/guest_web.dart';
import 'package:klunki_net/klunki_net.dart' as full;

Future<void> main() async {
  final guest = await KlunkiGuest.connectWebSocket(
      webSocketUri('192.168.1.20', defaultWebSocketPort), name: 'Web');
  guest.events.listen((e) => print(e));
  print(await guest.submit({'col': 3}));
  print(full.KlunkiHost.start); // the full library compiles for the web too
  await guest.close();
}
''');
    final result = await Process.run(Platform.resolvedExecutable,
        ['compile', 'js', '--packages=${packages.file.path}', '-o', '${tmp.path}/out.js', entry.path]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(File('${tmp.path}/out.js').readAsStringSync(), contains('WebSocket'));
  });
}

/// Every library reachable from [root] through imports and exports, with
/// conditional directives resolved for the web ([web]) or the VM.
Set<Uri> _webImportGraph(Uri root, _PackageConfig packages, {bool web = true}) {
  final defines = web
      ? const {'dart.library.io': false, 'dart.library.js_interop': true, 'dart.library.html': true}
      : const {'dart.library.io': true, 'dart.library.js_interop': false, 'dart.library.html': false};
  final seen = <Uri>{};
  final todo = [root];
  final directive = RegExp(r'''^\s*(?:import|export)\s+'([^']+)'((?:\s+if\s*\([^)]*\)\s*'[^']+')*)''',
      multiLine: true);
  final branch = RegExp(r'''if\s*\(\s*([\w.]+)\s*\)\s*'([^']+)'\s*''');
  while (todo.isNotEmpty) {
    final uri = todo.removeLast();
    if (!seen.add(uri) || uri.scheme == 'dart') continue;
    final file = packages.resolve(uri);
    if (file == null) continue; // a package outside this workspace (none expected)
    for (final m in directive.allMatches(file.readAsStringSync())) {
      var target = m.group(1)!;
      for (final b in branch.allMatches(m.group(2)!)) {
        if (defines[b.group(1)] ?? false) {
          target = b.group(2)!;
          break;
        }
      }
      todo.add(uri.resolve(target));
    }
  }
  return seen;
}

class _PackageConfig {
  final File file;
  final Map<String, Directory> _roots;
  _PackageConfig(this.file, this._roots);

  static _PackageConfig load(File file) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final roots = <String, Directory>{};
    for (final p in (json['packages'] as List).cast<Map<String, dynamic>>()) {
      final rootUri = p['rootUri'] as String;
      final root = file.uri.resolve(rootUri.endsWith('/') ? rootUri : '$rootUri/');
      roots[p['name'] as String] = Directory.fromUri(root.resolve(p['packageUri'] as String));
    }
    return _PackageConfig(file, roots);
  }

  File? resolve(Uri uri) {
    if (uri.scheme != 'package') return null;
    final dir = _roots[uri.pathSegments.first];
    if (dir == null) return null;
    return File.fromUri(dir.uri.resolve(uri.pathSegments.skip(1).join('/')));
  }
}
