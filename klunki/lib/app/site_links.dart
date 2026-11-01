// Links to the static pages published with the PWA on GitHub Pages (KLD-096:
// `site/{privacy,support,impressum}/`, copied into the web build by
// `site/build_site.py`), shown in "Über Klunki" (KLD-102).

/// Where GitHub Pages serves the PWA and the pages: `build.yml` builds with
/// `--base-href /<repo>/` for the `tronicum/klunki` repository. The one place
/// for the base; change it here if the site moves. Always the absolute URL,
/// also in the PWA: a PWA served by a relay in the local network has no
/// static pages next to it.
const String siteBaseUrl = 'https://tronicum.github.io/klunki/';

/// The source code (AGPL: offered to everyone who uses the app).
const String sourceCodeUrl = 'https://github.com/tronicum/klunki';

/// The static pages. [path] is the directory under [siteBaseUrl].
enum SitePage {
  privacy('privacy/'),
  impressum('impressum/'),
  support('support/');

  final String path;
  const SitePage(this.path);
}

/// The language a page is shown in: each page has a German and an English
/// part (`<article id="de">` first, then `id="en"`); German for `de`,
/// English for every other app language.
String sitePageLanguage(String languageCode) => languageCode == 'de' ? 'de' : 'en';

/// [page] in the app language [languageCode]: the page itself for German
/// (its first part), `…#en` otherwise.
Uri sitePageUri(SitePage page, String languageCode) {
  final uri = Uri.parse(siteBaseUrl).resolve(page.path);
  return sitePageLanguage(languageCode) == 'de' ? uri : uri.replace(fragment: 'en');
}
