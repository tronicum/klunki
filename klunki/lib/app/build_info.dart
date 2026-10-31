import 'package:klunki_engine/klunki_engine.dart' show catalogFingerprint;
import 'package:klunki_net/guest_web.dart' show BuildCompat, protocolVersion;

// The app's version and build (KLD-085), shown in the menu footer and sent
// to the other device in the network handshake (informational: what
// decides compatibility are the protocol version and the game
// fingerprints, see `klunki_net`'s PROTOCOL.md).

/// `version:` of `pubspec.yaml`, mirrored (a test keeps them in sync): Dart
/// code cannot read the pubspec without a plugin. Bump both together.
const String appVersion = '1.0.0+1';

/// The commit the app was built from, if the build passed one:
/// `flutter build … --dart-define=KLUNKI_BUILD=$(git rev-parse --short HEAD)`
/// (CI does). Empty for local builds without it.
const String _buildId = String.fromEnvironment('KLUNKI_BUILD');

/// [_buildId], at most 7 characters.
String get appBuildId => _buildId.length > 7 ? _buildId.substring(0, 7) : _buildId;

/// `1.0.0+1 abc1234` (or just the version): the `build` label of the
/// handshake. Starts with the version, so the other side can tell which
/// build is older.
String get appBuildLabel => appBuildId.isEmpty ? appVersion : '$appVersion $appBuildId';

/// What the app sends and checks in the handshake.
BuildCompat appBuildCompat() => BuildCompat(build: appBuildLabel);

/// The line for people to compare two devices by eye:
/// `1.0.0+1 · abc1234 · P3 · ba13a678` (version, build, protocol, game
/// data). Equal lines play together; the last part changes with any
/// game rules or deck data.
String get appVersionLine =>
    [appVersion, if (appBuildId.isNotEmpty) appBuildId, 'P$protocolVersion', catalogFingerprint()].join(' · ');
