import 'dart:io';

import 'package:klunki_net/src/cli/cli.dart';

/// Two terminals play each other over TCP (or WebSocket: `join ws://ip:4748`).
///
///   dart run klunki_net:klunki host connect4 [--port N] [--seed S] [--name NAME]
///   dart run klunki_net:klunki join 192.168.1.20 4747 [--name NAME]
///   dart run klunki_net:klunki relay [--port N] [--web DIR]
///   dart run klunki_net:klunki host connect4 --relay ws://192.168.1.20:4749
///   dart run klunki_net:klunki join --relay ws://192.168.1.20:4749 --room K7Q2M
///
/// Run without arguments for the usage text.
Future<void> main(List<String> args) async {
  final code = await runCli(args);
  await stdout.flush();
  // The stdin subscription may keep the VM alive; leave explicitly.
  exit(code);
}
