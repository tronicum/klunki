import 'package:klunki_engine/klunki_engine.dart';

import 'events.dart';
import 'names.dart';

/// What this build tells the other side in its `hello` (KLD-085): an
/// informational [build] label and the fingerprint of every game and deck
/// it knows ([allFingerprints]).
///
/// The apps pass their version and build id as [build]; tests pass other
/// [games] to play an older or newer build.
class BuildCompat {
  /// E.g. `1.0.0+2026110201 abc1234` (KLD-116: version, build number,
  /// commit); compared only to tell which side is older when nothing else
  /// does ([compareBuilds]), and shown to people as [versionDisplay].
  final String build;
  final Map<String, GameFingerprint> games;

  BuildCompat({this.build = '', Map<String, GameFingerprint>? games}) : games = games ?? allFingerprints();

  /// This build's fingerprint for [config]; null if it does not know the
  /// game or deck.
  GameFingerprint? of(GameConfig config) => games[compatKey(config)];

  /// `games` of the guest's `hello`.
  Map<String, dynamic> gamesJson() => {for (final e in games.entries) e.key: e.value.toJson()};
}

/// How [theirs] compares to [mine], by the leading `major.minor.patch+build`
/// numbers of the labels (`1.2.0+7 abc` → 1, 2, 0, 7); [PeerAge.unknown]
/// when equal or not parsable.
PeerAge compareBuilds(String mine, String? theirs) {
  final a = _numbers(mine), b = theirs == null ? null : _numbers(theirs);
  if (a == null || b == null) return PeerAge.unknown;
  for (var i = 0; i < 4; i++) {
    if (a[i] != b[i]) return b[i] < a[i] ? PeerAge.older : PeerAge.newer;
  }
  return PeerAge.unknown;
}

List<int>? _numbers(String label) {
  final m = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?').firstMatch(label.trim());
  if (m == null) return null;
  return [for (var i = 1; i <= 4; i++) int.parse(m.group(i) ?? '0')];
}

/// A build label (`1.0.0+2026110201 b8752a9`) the way people see it
/// (KLD-116): `1.0.0 (b8752a9)`, the version and the commit (at most 7
/// characters), `1.0.0 (dev)` for a build without a commit. A label that
/// does not start with a version is returned trimmed; null or blank: null.
String? versionDisplay(String? label) {
  final text = label?.trim() ?? '';
  if (text.isEmpty) return null;
  final m = RegExp(r'^(\d+\.\d+\.\d+)(?:\+\d+)?(?:\s+(\S+))?').firstMatch(text);
  if (m == null) return text;
  final commit = m.group(2);
  return '${m.group(1)} (${commit == null ? 'dev' : commit.length > 7 ? commit.substring(0, 7) : commit})';
}

PeerAge _byNumber(int mine, int theirs) => theirs < mine ? PeerAge.older : PeerAge.newer;

/// Protocol versions differ: [theirs] is the other side's (null: unknown).
VersionMismatch protocolMismatch(int? theirs, {String? peerBuild, String myBuild = ''}) => VersionMismatch(
      Incompatibility.protocol,
      theirs == null || theirs == protocolVersion ? compareBuilds(myBuild, peerBuild) : _byNumber(protocolVersion, theirs),
      'protocol ${theirs ?? '?'} on the other device, $protocolVersion here',
      peerBuild: peerBuild,
    );

/// Compares the fingerprints of the game [key] (see [compatKey]); null if
/// they match. [mine] null: this build does not know the game or deck;
/// [theirs] null: the other side does not.
VersionMismatch? compareFingerprints(String key, GameFingerprint? mine, GameFingerprint? theirs,
    {String? peerBuild, String myBuild = ''}) {
  if (mine != null && mine == theirs) return null;
  final byBuild = compareBuilds(myBuild, peerBuild);
  final (kind, age, detail) = switch ((mine, theirs)) {
    (null, null) => (Incompatibility.content, byBuild, 'neither device knows "$key"'),
    (null, _) => (Incompatibility.content, PeerAge.newer, '"$key" is unknown on this device'),
    (_, null) => (Incompatibility.content, PeerAge.older, '"$key" is unknown on the other device'),
    (final m?, final t?) when m.rules != t.rules =>
      (Incompatibility.rules, _byNumber(m.rules, t.rules), 'rules of "$key": ${t.rules} there, ${m.rules} here'),
    (final m?, final t?) when m.revision != t.revision => (
        Incompatibility.content,
        _byNumber(m.revision, t.revision),
        'data of "$key": revision ${t.revision} there, ${m.revision} here'
      ),
    _ => (Incompatibility.content, byBuild, 'data of "$key" differs'),
  };
  return VersionMismatch(kind, age, detail, peerBuild: peerBuild);
}

/// The fields of an `error` that refuses the handshake for [mismatch]:
/// `message` (from the receiver's point of view), `code`, and this side's
/// `protocol`, `build`, the player [name] (informational, KLD-116) and, if
/// known, the fingerprint of game [key].
Map<String, dynamic> mismatchErrorFields(VersionMismatch mismatch, BuildCompat compat,
        {String? key, GameFingerprint? fingerprint, String? name}) =>
    {
      'message': _flip(mismatch).message,
      'code': mismatch.kind.code,
      'protocol': protocolVersion,
      'build': compat.build,
      if (name != null) 'name': name,
      if (key != null) 'game': key,
      if (fingerprint != null) 'fingerprint': fingerprint.toJson(),
    };

/// [mismatch] as the other side sees it (which side is older is swapped;
/// the details name no side).
VersionMismatch _flip(VersionMismatch m) => VersionMismatch(
    m.kind,
    switch (m.peer) { PeerAge.older => PeerAge.newer, PeerAge.newer => PeerAge.older, PeerAge.unknown => PeerAge.unknown },
    m.kind == Incompatibility.protocol ? 'protocol $protocolVersion on the other device' : 'the game differs between the two devices');

/// The [VersionMismatch] an incoming `error` with a `code` reports, from
/// this side's point of view (it recomputes which side is older from the
/// fields); null for any other error.
VersionMismatch? mismatchFromError(Map<String, dynamic>? error, BuildCompat compat) {
  if (error == null) return null;
  final kind = Incompatibility.fromCode(error['code']);
  if (kind == null) return null;
  final name = error['name'];
  // Untrusted input, cleaned like a typed name (KLD-116: shown in the message).
  final peerName = name is String && sanitizePlayerName(name).isNotEmpty ? sanitizePlayerName(name) : null;
  return _mismatchFromError(kind, error, compat)?.withSides(myBuild: compat.build, peerName: peerName);
}

VersionMismatch? _mismatchFromError(Incompatibility kind, Map<String, dynamic> error, BuildCompat compat) {
  final build = error['build'] is String ? error['build'] as String : null;
  final protocol = error['protocol'];
  if (kind == Incompatibility.protocol || (protocol is int && protocol != protocolVersion)) {
    return protocolMismatch(protocol is int ? protocol : null, peerBuild: build, myBuild: compat.build);
  }
  final key = error['game'];
  final theirs = GameFingerprint.tryParse(error['fingerprint']);
  if (key is String) {
    final m = compareFingerprints(key, compat.games[key], theirs, peerBuild: build, myBuild: compat.build);
    if (m != null) return VersionMismatch(kind, m.peer, m.detail, peerBuild: build);
  }
  return VersionMismatch(kind, compareBuilds(compat.build, build), '${error['message'] ?? ''}', peerBuild: build);
}
