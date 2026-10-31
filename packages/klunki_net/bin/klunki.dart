import 'dart:io';

import 'package:klunki_net/src/cli/cli.dart';

/// Two terminals play each other over TCP (or WebSocket: `join ws://ip:4748`).
///
///   dart run packages/klunki_net/bin/klunki.dart host connect4 [--port N] [--seed S] [--name NAME]
///   dart run packages/klunki_net/bin/klunki.dart join 192.168.1.20 4747 [--name NAME]
///   dart run packages/klunki_net/bin/klunki.dart relay [--port N] [--web DIR]
///   dart run packages/klunki_net/bin/klunki.dart host connect4 --relay ws://192.168.1.20:4749
///   dart run packages/klunki_net/bin/klunki.dart join --relay ws://192.168.1.20:4749 --room K7Q2M
///
/// From the repo root; inside packages/klunki_net `dart run klunki_net:klunki …`
/// works too. Relative paths (`--web DIR`) resolve against the current directory.
///
/// Run without arguments for the usage text.
Future<void> main(List<String> args) async {
  final code = await runCli(args);
  await stdout.flush();
  // The stdin subscription may keep the VM alive; leave explicitly.
  exit(code);
}
