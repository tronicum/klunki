import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:klunki/app/build_info.dart';
import 'package:klunki/app/site_links.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/ltr.dart';
import 'package:klunki/ui/menu_screen.dart' show KlunkiLogo;
import 'package:url_launcher/url_launcher.dart' as launcher;

// "Über Klunki" (KLD-102): version, privacy policy, Impressum, support,
// licences. Reached from the menu footer. App Review (guideline 5.1.1)
// wants the privacy policy inside the app; the Impressum must be easy to
// reach as well.

/// Opens [uri] outside the app (web: a new tab). Returns false on failure.
typedef AboutLinkOpener = Future<bool> Function(Uri uri);

Future<bool> _launch(Uri uri) async {
  try {
    return await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication, webOnlyWindowName: '_blank');
  } catch (_) {
    return false;
  }
}

/// The link opener; tests replace it (and reset it with [resetAboutLinkOpener]).
@visibleForTesting
AboutLinkOpener aboutLinkOpener = _launch;

@visibleForTesting
void resetAboutLinkOpener() => aboutLinkOpener = _launch;

Future<void> _open(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failed = AppLocalizations.of(context).quartettLinkFailed; // generic "link could not be opened"
  final ok = await aboutLinkOpener(uri);
  if (!ok) messenger?.showSnackBar(SnackBar(content: Text(failed)));
}

/// Opens the About screen.
void openAboutScreen(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget link(Key key, IconData icon, String title, Uri uri, {VoidCallback? onTap}) => ListTile(
          key: key,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(bidiLtr(context, uri.toString()), style: TextStyle(color: muted)),
          trailing: Icon(onTap == null ? Icons.open_in_new : Icons.chevron_right, size: 20),
          onTap: onTap ?? () => _open(context, uri),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                const ExcludeSemantics(
                  child: Center(child: SizedBox.square(dimension: 64, child: CustomPaint(painter: KlunkiLogo()))),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.menuVersion(bidiLtr(context, appVersionLine)),
                    key: const Key('about-version'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                link(
                  const Key('about-privacy'),
                  Icons.privacy_tip_outlined,
                  l10n.aboutPrivacy,
                  sitePageUri(SitePage.privacy, lang),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => const PrivacyTextScreen())),
                ),
                link(const Key('about-impressum'), Icons.gavel_outlined, l10n.aboutImpressum,
                    sitePageUri(SitePage.impressum, lang)),
                link(const Key('about-support'), Icons.help_outline, l10n.aboutSupport,
                    sitePageUri(SitePage.support, lang)),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(l10n.aboutLicense, style: theme.textTheme.bodyMedium),
                ),
                link(const Key('about-source'), Icons.code, l10n.aboutSourceCode, Uri.parse(sourceCodeUrl)),
                ListTile(
                  key: const Key('about-licenses'),
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.aboutLicenses),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appTitle,
                    applicationVersion: appVersion,
                    applicationIcon: const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox.square(dimension: 48, child: CustomPaint(painter: KlunkiLogo())),
                    ),
                    applicationLegalese: l10n.aboutLicense,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One block of the stored privacy policy (`assets/legal/privacy.json`,
/// exported from `site/privacy/index.html` by `site/export_privacy_text.py`).
@immutable
class PrivacyBlock {
  /// `h1`, `h2`, `meta` (the date line), `p`, `li` or `address`.
  final String type;
  final String text;
  const PrivacyBlock(this.type, this.text);
}

const String privacyAsset = 'assets/legal/privacy.json';

/// The blocks of [json] (the asset's content) in [languageCode]'s page
/// language ([sitePageLanguage]).
List<PrivacyBlock> parsePrivacyBlocks(String json, String languageCode) {
  final all = jsonDecode(json) as Map<String, dynamic>;
  final list = all[sitePageLanguage(languageCode)] as List<dynamic>;
  return [
    for (final b in list.cast<Map<String, dynamic>>()) PrivacyBlock(b['t'] as String, b['x'] as String),
  ];
}

/// The privacy policy stored in the app, readable offline; the web page is
/// linked at the top and in the app bar.
class PrivacyTextScreen extends StatefulWidget {
  const PrivacyTextScreen({super.key});

  @override
  State<PrivacyTextScreen> createState() => _PrivacyTextScreenState();
}

class _PrivacyTextScreenState extends State<PrivacyTextScreen> {
  Future<String>? _text;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once: a new future on every build would reset the FutureBuilder.
    // Uncached: opened rarely, and a cached future would outlive its zone in tests.
    _text ??= DefaultAssetBundle.of(context).loadString(privacyAsset, cache: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final uri = sitePageUri(SitePage.privacy, lang);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutPrivacy),
        actions: [
          IconButton(
            key: const Key('privacy-open-web'),
            tooltip: l10n.aboutOpenInBrowser,
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _open(context, uri),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _text,
          builder: (context, snap) {
            final data = snap.data;
            final blocks = data == null ? const <PrivacyBlock>[] : parsePrivacyBlocks(data, lang);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  key: const Key('privacy-text'),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.aboutPrivacyOffline, style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            InkWell(
                              key: const Key('privacy-web-link'),
                              onTap: () => _open(context, uri),
                              child: Text(
                                bidiLtr(context, uri.toString()),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // The text is German or English: left-to-right also in ar/fa.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [for (final b in blocks) _PrivacyBlockView(b)],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PrivacyBlockView extends StatelessWidget {
  final PrivacyBlock block;
  const _PrivacyBlockView(this.block);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return switch (block.type) {
      'h1' => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Semantics(header: true, child: Text(block.text, style: t.titleLarge)),
        ),
      'h2' => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Semantics(header: true, child: Text(block.text, style: t.titleMedium)),
        ),
      'meta' => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(block.text, style: t.bodySmall?.copyWith(color: muted)),
        ),
      'li' => Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: t.bodyMedium),
              Expanded(child: Text(block.text, style: t.bodyMedium)),
            ],
          ),
        ),
      _ => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(block.text, style: t.bodyMedium),
        ),
    };
  }
}
