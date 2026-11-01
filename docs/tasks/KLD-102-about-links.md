# KLD-102 — "Über Klunki": Datenschutz, Impressum and Support inside the app

- **ID:** `KLD-102`
- **Title:** About screen with the privacy policy (also offline), Impressum, support, version and licences
- **Status:** DONE
- **Depends on:** KLD-096 (the pages on GitHub Pages)
- **Touched paths:**
  - `klunki/lib/app/site_links.dart` (new: `siteBaseUrl`, `SitePage`, `sitePageUri`, `sourceCodeUrl`)
  - `klunki/lib/ui/about_screen.dart` (new: `AboutScreen`, `PrivacyTextScreen`, `aboutLinkOpener`)
  - `klunki/lib/ui/menu_screen.dart` (footer button `menu-about`)
  - `klunki/lib/l10n/**` (9 keys `about*`, after `menuVersion`)
  - `klunki/assets/legal/privacy.json` (new), `klunki/pubspec.yaml` (asset entry)
  - `site/export_privacy_text.py` (new)
  - `klunki/test/ui/about_screen_test.dart`, `klunki/test/screenshots/about_shots_test.dart` (new)
  - `docs/tasks/BOARD.md`, `docs/APPSTORE.md`, `docs/tasks/KLD-096-pages-privacy.md` (follow-up ticked)

## Why

App Review guideline 5.1.1 wants the privacy policy reachable inside the app, and the German Impressum
duty wants the provider information easy to find. KLD-096 published the pages; this links them.

## Where the entry sits

A small text button **"Über Klunki"** with an info icon, centred right above the version line at the
bottom of the menu. The games stay the first thing on screen and the app bar keeps its two actions
(name, language: a third icon would crowd small phones and be less obvious than a labelled button).
The bottom of a menu is where people look for legal links.

## The About screen

Logo, "Klunki", the version line from the footer (`appVersionLine`, LTR-isolated), then:

| Entry | Opens |
|---|---|
| Datenschutz | the policy stored in the app (`PrivacyTextScreen`, works offline); there an "Im Browser öffnen" action and the URL link open the web page |
| Impressum | `https://tronicum.github.io/klunki/impressum/` |
| Support | `https://tronicum.github.io/klunki/support/` |
| licence line | "Klunki ist freie Software unter der GNU AGPL 3.0." |
| Quellcode | `https://github.com/tronicum/klunki` (AGPL) |
| Open-Source-Lizenzen | Flutter's `showLicensePage` (includes the fonts, zxing-cpp, libzint registered at startup) |

Each link shows its URL as subtitle, so it can be read (and typed) when opening fails.

## URLs and languages

One constant, `siteBaseUrl = 'https://tronicum.github.io/klunki/'` in `site_links.dart`
(`site/site.json` only has the contact email; the base comes from `build.yml`'s `--base-href /<repo>/`).
Each page has a German and an English part (`<article id="de">` first, then `id="en"`): German app →
the page itself, every other language → `…/#en`. The absolute URL is also used in the PWA: a PWA served
by a relay in the local network has no pages next to it.

## Opening links

`url_launcher` is already a dependency (KLD-082, Quartett Wikipedia links): `launchUrl` with
`LaunchMode.externalApplication` and `webOnlyWindowName: '_blank'` (PWA: new tab). A failure shows the
existing "Der Link konnte nicht geöffnet werden." snack bar. On the Pages PWA the pages are same-origin
under `/klunki/`; the service worker's `isStaticPage` (KLD-096, `klunki/web/klunki_sw.js`) keeps them out
of the cache and never answers them with the app shell. Verified in the source; not re-run in a browser.

## Offline privacy text

`python3 -I site/export_privacy_text.py` (stdlib `html.parser`) turns `site/privacy/index.html` into
`klunki/assets/legal/privacy.json`: per language a list of blocks (`h1`, `meta`, `h2`, `p`, `li`,
`address`), `{{KEY}}` filled from `site/site.json`. The app renders them as plain text (no links inside).
A test compares the words of each `<article>` with the asset and fails with the command to rerun when the
page changes. Languages other than German read the English text, laid out LTR also in ar/fa (the note
above it says it is English and that the web page is authoritative). Impressum and support are not
bundled (contact data, help: online is fine; follow-up if wanted).

## Locales

de, en, fr, es, zh, ar, fa. zh uses only characters already in the Noto Sans SC subset (no font
update). RTL: the About screen mirrors; URLs and the version line are LTR-isolated; the privacy text is
an LTR block (checked in the test and the `ar-*` screenshots).

## Tests

- `test/ui/about_screen_test.dart`: URL derivation (de, `#en` for the rest); the pages and anchors exist
  in `site/`; the menu entry exists, the About screen shows version, links and licence line, and
  Impressum/Support/Quellcode open the right URLs (de and en); Datenschutz opens the stored text,
  the web action and link open the privacy URL; Arabic layout; licence page; asset matches the page.
- `test/screenshots/about_shots_test.dart` (opt-in, `KLUNKI_SHOTS=<dir>`): menu footer, About screen,
  privacy text in de and ar. In the ar shots Arabic letters are boxes: the bundled Arabic fallback is web only
  (KLD-093) and the test runs as a native platform; layout and direction are what the shots check.
