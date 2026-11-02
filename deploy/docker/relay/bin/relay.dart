import 'dart:async';
import 'dart:io';

// ignore: implementation_imports
import 'package:klunki_net/src/cli/cli.dart';

/// Entry point of the Docker image (KLD-114): the `klunki` network CLI
/// (`relay`, `relay-code new`, …, see packages/klunki_net/bin/klunki.dart),
/// plus `healthcheck [PORT]` for the image's HEALTHCHECK, since the runtime
/// image has no shell and no curl.
///
///   klunki relay --port 4749 --codes /data/codes.txt [--web /web]
///   klunki relay-code new --label "Familie Müller"
///   klunki healthcheck [4749]
Future<void> main(List<String> args) async {
  if (args.isNotEmpty && args.first == 'healthcheck') {
    exit(await healthcheck(args.length > 1 ? int.tryParse(args[1]) : null));
  }
  final code = await runCli(args);
  await stdout.flush();
  // The stdin subscription may keep the VM alive; leave explicitly.
  exit(code);
}

/// 0 if a relay answers on `http://127.0.0.1:PORT/relay` (a plain GET gets
/// `426 Upgrade Required`), else 1. Sends no club code and opens no room.
Future<int> healthcheck(int? port) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    final request = await client.getUrl(Uri.parse('http://127.0.0.1:${port ?? 4749}/relay'));
    final response = await request.close().timeout(const Duration(seconds: 3));
    await response.drain<void>();
    return response.statusCode == HttpStatus.upgradeRequired ? 0 : 1;
  } catch (_) {
    return 1;
  } finally {
    client.close(force: true);
  }
}
