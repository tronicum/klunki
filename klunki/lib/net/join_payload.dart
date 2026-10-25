/// The manual-entry / QR join payload. Pure Dart (no Flutter, no `dart:io`).
///
/// Canonical form (what the QR code encodes):
///
///     klunki://join?h=192.168.1.20&p=4747&v=1&n=Stefans%20iPhone&g=muehle
///
/// `h` host (required), `p` port (default [klunkiDefaultPort]), `v` protocol
/// version (default [klunkiProtocolVersion]), `n` display name and `g` game
/// id (both optional). [JoinPayload.tryParse] also accepts what a person
/// types: `192.168.1.20:4747` or just `192.168.1.20`.
library;

import 'discovery.dart';

/// Default TCP port: the `klunki` terminal CLI's default (`klunki_net`
/// `src/cli/cli.dart`, not exported). Mirrored here because importing
/// `klunki_net` pulls in `dart:io`, which breaks the web build.
const int klunkiDefaultPort = 4747;

/// `klunki_net`'s `protocolVersion`, mirrored for the same reason (a test
/// keeps them in sync).
const int klunkiProtocolVersion = 1;

/// URI scheme and "host" part of the canonical payload.
const String joinScheme = 'klunki';
const String joinAction = 'join';

class JoinPayload {
  /// IPv4 address or host name.
  final String host;
  final int port;
  final int protocol;
  final String? name;
  final String? gameId;

  const JoinPayload({
    required this.host,
    this.port = klunkiDefaultPort,
    this.protocol = klunkiProtocolVersion,
    this.name,
    this.gameId,
  });

  factory JoinPayload.fromHostInfo(KlunkiHostInfo info) => JoinPayload(
        host: info.host,
        port: info.port,
        protocol: info.protocol,
        name: info.name,
        gameId: info.gameId,
      );

  /// As a [KlunkiHostInfo]; without a [name] the display name is `host:port`.
  KlunkiHostInfo toHostInfo() => KlunkiHostInfo(
        name: name ?? '$host:$port',
        host: host,
        port: port,
        protocol: protocol,
        gameId: gameId,
      );

  /// The canonical `klunki://join?...` string.
  String format() => Uri(
        scheme: joinScheme,
        host: joinAction,
        queryParameters: {
          'h': host,
          'p': '$port',
          'v': '$protocol',
          if (name != null && name!.isNotEmpty) 'n': name!,
          if (gameId != null && gameId!.isNotEmpty) 'g': gameId!,
        },
      ).toString();

  /// Short form for showing next to the QR code: `host:port`.
  String get address => '$host:$port';

  @override
  String toString() => format();

  @override
  bool operator ==(Object other) =>
      other is JoinPayload &&
      other.host == host &&
      other.port == port &&
      other.protocol == protocol &&
      other.name == name &&
      other.gameId == gameId;

  @override
  int get hashCode => Object.hash(host, port, protocol, name, gameId);

  /// Parses the canonical URI, `host:port` or `host`. Null for anything else
  /// (bad host, port outside 1..65535, non-numeric version, other schemes).
  static JoinPayload? tryParse(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    if (text.toLowerCase().startsWith('$joinScheme:')) return _parseUri(text);
    if (text.contains('://')) return null;

    final colon = text.lastIndexOf(':');
    final host = colon < 0 ? text : text.substring(0, colon);
    final port = colon < 0 ? klunkiDefaultPort : _parsePort(text.substring(colon + 1));
    if (port == null || !isValidHost(host)) return null;
    return JoinPayload(host: host, port: port);
  }

  static JoinPayload? _parseUri(String text) {
    final Uri uri;
    try {
      uri = Uri.parse(text);
    } on FormatException {
      return null;
    }
    if (uri.scheme != joinScheme || uri.host != joinAction) return null;
    final q = uri.queryParameters;
    final host = q['h'];
    if (host == null || !isValidHost(host)) return null;
    final port = q.containsKey('p') ? _parsePort(q['p']!) : klunkiDefaultPort;
    if (port == null) return null;
    final protocol = q.containsKey('v') ? int.tryParse(q['v']!) : klunkiProtocolVersion;
    if (protocol == null || protocol < 0) return null;
    final name = q['n'];
    final game = q['g'];
    return JoinPayload(
      host: host,
      port: port,
      protocol: protocol,
      name: name == null || name.isEmpty ? null : name,
      gameId: game == null || game.isEmpty ? null : game,
    );
  }

  static int? _parsePort(String s) {
    if (!RegExp(r'^\d{1,5}$').hasMatch(s)) return null;
    final p = int.parse(s);
    return p >= 1 && p <= 65535 ? p : null;
  }

  /// A dotted-quad IPv4 address or a DNS host name (letters, digits, `-`,
  /// dot-separated, at least one letter so `999.1.1.1` is not a "name").
  /// IPv6 literals are not supported.
  static bool isValidHost(String host) {
    if (host.isEmpty || host.length > 253) return false;
    final ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$').firstMatch(host);
    if (ipv4 != null) {
      return [for (var i = 1; i <= 4; i++) int.parse(ipv4.group(i)!)].every((o) => o <= 255);
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(host)) return false;
    final label = RegExp(r'^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$');
    final labels = host.endsWith('.') ? host.substring(0, host.length - 1).split('.') : host.split('.');
    return labels.every(label.hasMatch);
  }
}
