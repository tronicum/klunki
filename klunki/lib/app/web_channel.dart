import 'package:flutter/foundation.dart';

// The web build's channel and the app links it may show (KLD-108). All of
// them are build-time defines with empty defaults: only the GitHub Pages job
// in `.github/workflows/build.yml` sets KLUNKI_WEB_CHANNEL; the local
// relay-served web build and the apps don't.

/// `--dart-define=KLUNKI_WEB_CHANNEL=…`: `pages-beta` for the PWA on GitHub
/// Pages, empty otherwise. Tests set it directly.
@visibleForTesting
String appWebChannel = const String.fromEnvironment('KLUNKI_WEB_CHANNEL');

/// The web channel of the GitHub Pages build.
const String pagesBetaChannel = 'pages-beta';

/// Whether this is the Pages web beta: a "Beta" badge in the menu and a line
/// in "Über Klunki".
bool get isPagesBeta => appWebChannel == pagesBetaChannel;

/// `--dart-define=KLUNKI_IOS_BETA_URL=…`: a public iPhone/iPad test link.
/// Empty (the default): no button, only the teaser line.
@visibleForTesting
String appIosBetaUrl = const String.fromEnvironment('KLUNKI_IOS_BETA_URL');

/// `--dart-define=KLUNKI_ANDROID_URL=…`: an Android download link. Empty
/// (the default): no button.
@visibleForTesting
String appAndroidUrl = const String.fromEnvironment('KLUNKI_ANDROID_URL');

/// [appIosBetaUrl] as an https link, or null (empty or not https).
Uri? get iosBetaUri => _httpsLink(appIosBetaUrl);

/// [appAndroidUrl] as an https link, or null (empty or not https).
Uri? get androidAppUri => _httpsLink(appAndroidUrl);

Uri? _httpsLink(String text) {
  final uri = Uri.tryParse(text.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty ? uri : null;
}
