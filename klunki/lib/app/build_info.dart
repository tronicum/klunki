import 'package:klunki_engine/klunki_engine.dart' show catalogFingerprint;
import 'package:klunki_net/guest_web.dart' show BuildCompat, protocolVersion, versionDisplay;

// The app's version and build (KLD-085, KLD-116), shown in the menu footer
// and on the About screen and sent to the other device in the network
// handshake (informational: what decides compatibility are the protocol
// version and the game fingerprints, see `klunki_net`'s PROTOCOL.md).
//
// Scheme (KLD-116, docs/RELEASING.md): `MAJOR.MINOR.PATCH+BUILD`. The
// version comes from `pubspec.yaml`; CI sets the build number
// (`YYYYMMDDNN`, `tool/build_number.sh`) with `--build-number` for the
// stores and `--dart-define=KLUNKI_BUILD_NUMBER` for the app itself, and the
// commit with `--dart-define=KLUNKI_BUILD`. Local builds keep the pubspec's
// build number and have no commit.

/// `version:` of `pubspec.yaml`, mirrored (a test keeps them in sync): Dart
/// code cannot read the pubspec without a plugin. Bump both together.
const String appVersion = '1.0.0+1';

/// [appVersion] without the build number: `1.0.0`.
String get appVersionName => appVersion.split('+').first;

/// The commit the app was built from, if the build passed one:
/// `flutter build … --dart-define=KLUNKI_BUILD=$(git rev-parse --short HEAD)`
/// (CI does). Empty for local builds without it.
const String _buildId = String.fromEnvironment('KLUNKI_BUILD');

/// The build number CI passed (`--dart-define=KLUNKI_BUILD_NUMBER`, the
/// same value as `--build-number`); empty for local builds.
const String _buildNumber = String.fromEnvironment('KLUNKI_BUILD_NUMBER');

/// [_buildId], at most 7 characters.
String get appBuildId => shortCommit(_buildId);

/// The build number: CI's [_buildNumber], else the pubspec's (`1`).
String get appBuildNumber =>
    _buildNumber.isNotEmpty ? _buildNumber : (appVersion.contains('+') ? appVersion.split('+').last : '');

/// [commit], at most 7 characters.
String shortCommit(String commit) => commit.length > 7 ? commit.substring(0, 7) : commit;

/// The handshake's build label from its parts: `1.0.0+2026110201 b8752a9`
/// (version, build number, commit; the last two optional).
String buildLabel(String version, {String buildNumber = '', String commit = ''}) {
  final v = buildNumber.isEmpty ? version : '$version+$buildNumber';
  final c = shortCommit(commit);
  return c.isEmpty ? v : '$v $c';
}

/// `1.0.0+2026110201 b8752a9` (or `1.0.0+1` locally): the `build` label of
/// the handshake. Starts with the version, so the other side can tell which
/// build is older.
String get appBuildLabel => buildLabel(appVersionName, buildNumber: appBuildNumber, commit: _buildId);

/// What the app sends and checks in the handshake.
BuildCompat appBuildCompat() => BuildCompat(build: appBuildLabel);

/// The version line people see (KLD-116): `1.0.0 (b8752a9)`, or
/// `1.0.0 (dev)` for a build without a commit. Same text the version
/// mismatch message shows for both devices.
String get appVersionLine => versionDisplay(appBuildLabel)!;

/// The small print under it on the About screen, to compare two devices in
/// detail (KLD-085): build number, protocol, a short code over every game's
/// fingerprint. Equal protocol and code play together.
({String build, String protocol, String games}) get appBuildDetails =>
    (build: appBuildNumber, protocol: '$protocolVersion', games: catalogFingerprint());
