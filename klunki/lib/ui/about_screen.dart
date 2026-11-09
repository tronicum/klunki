import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:klunki/app/build_info.dart';
import 'package:klunki/app/site_links.dart';
import 'package:klunki/app/web_channel.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/help_screen.dart';
import 'package:klunki/ui/ltr.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

// "Über Klunki" (KLD-102): version, privacy policy, Impressum, support,
// licences. Reached from the menu footer. App Review (guideline 5.1.1)
// wants the privacy policy inside the app; the Impressum must be easy to
// reach as well. Both are stored in the app ("local first": readable
// offline and while the web pages are not published); Support is a help
// page and opens in the browser.

/// The app icon (KLD-097, c5-zoom-b-fill) as on the home screen: the bundled
/// 384 px PNG (written by `tool/icon/export_icon_test.dart`) in a rounded
/// square. Decorative; the app name is next to it.
class KlunkiAppIcon extends StatelessWidget {
  const KlunkiAppIcon({super.key, this.size = 112});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.225),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      ),
    ),
  );
}

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

/// Opens [uri] outside the app with [aboutLinkOpener]; a snackbar if that
/// fails. Also used by the "not in the browser yet" sheet (KLD-108).
Future<void> openExternalLink(BuildContext context, Uri uri) => _open(context, uri);

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
                const Center(child: KlunkiAppIcon(key: Key('about-app-icon'))),
                const SizedBox(height: 12),
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  l10n.appSubtitle,
                  key: const Key('about-subtitle'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
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
                // KLD-116: small print to compare two devices in detail
                // (KLD-085): build number, protocol, game data code.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.aboutBuildDetails(bidiLtr(context, appBuildDetails.build),
                        bidiLtr(context, appBuildDetails.protocol), bidiLtr(context, appBuildDetails.games)),
                    key: const Key('about-build-details'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ),
                // KLD-108: the GitHub Pages build says what it can't do.
                if (isPagesBeta)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      l10n.aboutWebBeta,
                      key: const Key('about-web-beta'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 16),
                const Divider(),
                // KLD-113: "So spielt ihr zusammen", stored in the app.
                ListTile(
                  key: const Key('about-help'),
                  leading: const Icon(Icons.groups_outlined),
                  title: Text(l10n.helpTitle),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => openHelpScreen(context),
                ),
                // Stored in the app (chevron); Support opens the web page (open_in_new).
                for (final (key, icon, page) in [
                  (const Key('about-privacy'), Icons.privacy_tip_outlined, LegalPage.privacy),
                  (const Key('about-impressum'), Icons.gavel_outlined, LegalPage.impressum),
                ])
                  link(
                    key,
                    icon,
                    page.title(l10n),
                    sitePageUri(page.site, lang),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => LegalTextScreen(page))),
                  ),
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
                    applicationVersion: appVersionLine,
                    applicationIcon: const Padding(
                      padding: EdgeInsets.all(8),
                      child: KlunkiAppIcon(size: 48),
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

/// The pages stored in the app as text (`assets/legal/<name>.json`, exported
/// from `site/<name>/index.html` by `site/export_legal_text.py`). Support is
/// not one of them: it stays online only.
enum LegalPage {
  privacy(SitePage.privacy),
  impressum(SitePage.impressum);

  /// The web page with the same content (the authoritative version).
  final SitePage site;
  const LegalPage(this.site);

  String get asset => 'assets/legal/$name.json';

  String title(AppLocalizations l10n) => switch (this) {
        LegalPage.privacy => l10n.aboutPrivacy,
        LegalPage.impressum => l10n.aboutImpressum,
      };
}

/// One block of a stored legal text ([LegalPage]).
@immutable
class LegalBlock {
  /// `h1`, `h2`, `meta` (the date line), `p`, `li` or `address`.
  final String type;
  final String text;
  const LegalBlock(this.type, this.text);
}

/// The blocks of [json] (the asset's content) in [languageCode]'s page
/// language ([sitePageLanguage]).
List<LegalBlock> parseLegalBlocks(String json, String languageCode) {
  final all = jsonDecode(json) as Map<String, dynamic>;
  final list = all[sitePageLanguage(languageCode)] as List<dynamic>;
  return [
    for (final b in list.cast<Map<String, dynamic>>()) LegalBlock(b['t'] as String, b['x'] as String),
  ];
}

/// A legal text stored in the app ([page]: privacy policy or Impressum),
/// readable offline; the web page is linked at the top and in the app bar.
/// Keys are prefixed with the page name (`privacy-text`, `impressum-open-web`).
class LegalTextScreen extends StatefulWidget {
  const LegalTextScreen(this.page, {super.key});

  final LegalPage page;

  @override
  State<LegalTextScreen> createState() => _LegalTextScreenState();
}

class _LegalTextScreenState extends State<LegalTextScreen> {
  Future<String>? _text;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once: a new future on every build would reset the FutureBuilder.
    // Uncached: opened rarely, and a cached future would outlive its zone in tests.
    _text ??= DefaultAssetBundle.of(context).loadString(widget.page.asset, cache: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final page = widget.page;
    final uri = sitePageUri(page.site, lang);
    return Scaffold(
      appBar: AppBar(
        title: Text(page.title(l10n)),
        actions: [
          IconButton(
            key: Key('${page.name}-open-web'),
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
            final blocks = data == null ? const <LegalBlock>[] : parseLegalBlocks(data, lang);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  key: Key('${page.name}-text'),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Generic wording ("this copy … the page on the web is authoritative").
                            Text(l10n.aboutPrivacyOffline, style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            InkWell(
                              key: Key('${page.name}-web-link'),
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
                        children: [for (final b in blocks) _LegalBlockView(b)],
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

class _LegalBlockView extends StatelessWidget {
  final LegalBlock block;
  const _LegalBlockView(this.block);

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
