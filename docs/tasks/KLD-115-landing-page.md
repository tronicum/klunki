# KLD-115 – Landing page on GitHub Pages, PWA under play/

- **ID:** `KLD-115`
- **Title:** A homepage at `https://tronicum.github.io/klunki/`: what Klunki is, the games, "Im Browser spielen",
  the app beta (greyed out store entries + "Zugang anfragen"), FAQ, legal links; the PWA moves to `/klunki/play/`
- **Milestone:** M-store
- **Status:** DONE (🧑 maintainer: texts, privacy wording (legal review), screenshots; merging publishes)
- **Number:** KLD-113 and KLD-114 are claimed by parallel branches (in-app help "So spielt ihr zusammen", relay
  packages / server wording), not yet on main; this card took 115.
- **Depends on:** KLD-096 (Pages, static pages), KLD-102 (legal texts in the app), KLD-108 (web channel, store
  URL variables), KLD-113 (in-app help ARB keys, for the FAQ; see below)
- **Touched paths:**
  - `site/index.html`, `site/assets/*` (icon, favicon, 4 screenshots, ~236 KB), `site/root_sw.js`
  - `site/build_site.py` (now assembles the whole site), `site/test_build_site.py`, `site/testdata/help_fixture.json`
  - `site/privacy/index.html` + `klunki/assets/legal/privacy.json` (re-exported): beta access by email
  - `.github/workflows/build.yml` (pages-build), `docs/BUILDING.md` §7.1, `docs/APPSTORE.md` (marketing URL line)

## Goal

The Pages site gets a real start page that "wraps everything up": what Klunki is, screenshots, the 8 games, a
button to the browser version, the apps (closed beta, with a way to ask for access), the FAQ and the legal links.
Merging to `main` publishes it (the `pages-build` / `pages` jobs run on every push to `main` while
`PAGES_ENABLED` is `true`); the maintainer decides when to merge.

## URL decision

Option (a): **landing page at `/klunki/`, PWA at `/klunki/play/`**; `privacy/`, `support/`, `impressum/` stay
where they were. Why: the address people see and the App Store marketing URL (`/klunki/`) explains the project;
the app's `siteBaseUrl` (`https://tronicum.github.io/klunki/`, KLD-102) and the store privacy/support URLs keep
working unchanged; room links made in the browser now say `/klunki/play/?room=…` by themselves (`roomJoinLink`
uses the page URL), no app change needed.

Migration (kept small: so far only the maintainer used the browser version):

- `/klunki/klunki_sw.js` is now a 10-line worker that unregisters itself and reloads its pages (`site/root_sw.js`).
  An old root worker is replaced by it on the next visit (browsers check the worker script on navigation); the
  new app worker at `play/` deletes the old `klunki-*` caches when it activates.
- The landing page's small inline script sends `/klunki/?room=…` and `?join=…` (old QR codes and links) and an
  old home-screen install (`display-mode: standalone`) on to `play/`.
- The `klunki-pwa` artifact for `klunki relay --web` stays a root build: nothing changes on the LAN.

## Content

- **Hero:** "Klassische Spiele für zwei", families and kids, one device or each on their own device on the Wi-Fi;
  chips "Kein Konto · Keine Werbung · Kein Tracking · Spielt auch offline · Freie Software" (checked against
  `site/privacy/`: no account, no ads/analytics/tracking; offline: PWA service worker, hot-seat in the apps);
  buttons "Im Browser spielen (Beta)" → `play/` and "Apps für iPhone, iPad und Android"; note that the browser
  plays on one device (KLD-108).
- **Screenshots:** menu, 4 Gewinnt, Schiffe versenken, Schach from `KLUNKI_SHOTS` (phone, light; the Quartett
  shots show black photo boxes in tests, so none of those), 400 px wide JPEG q55 via `sips`.
- **Games:** the 8 games in menu order with `menuGame*` / `menuDesc*` from `app_de.arb` / `app_en.arb`
  (generated at build time, so renames follow the app).
- **Apps:** App Store and Google Play as greyed-out "Geschlossene Beta" entries; with the repository variables
  `KLUNKI_IOS_BETA_URL` / `KLUNKI_ANDROID_URL` (KLD-108, https only) they become links. No store badge images
  (licensing). **"Zugang zur Beta anfragen":** a form `action="mailto:<CONTACT_EMAIL>" method="get"` with the
  device as `subject` ("Klunki Beta: iPhone/iPad" / "Klunki Beta: Android") and a prefilled `body` with
  "Vorname (freiwillig):" (a GET form to `mailto:` builds the mail without JavaScript), plain `mailto:` links per
  device and the address as text (mailto can fail). Notes "Bitte von Erwachsenen anfragen." and "Wir nutzen
  deine E-Mail-Adresse nur für die Beta-Einladung." with a link to the privacy policy. A real form endpoint (e.g.
  a Cloudflare Worker) could come later; no third-party form services.
- **FAQ:** generated from the in-app help, see below; always followed by a link to `support/`.
- **Footer:** Datenschutz, Impressum, Support, source code, licence (AGPL-3.0).
- **Language:** both articles in the page (`#de`, `#en`), German shown by default, English via `#en`
  (CSS `:has(:target)`) or automatically for a non-German browser language (tiny script; without JS: German,
  the link switches).

## FAQ from the ARB files (dependency on KLD-113)

`build_site.py` takes every ARB key starting with `help` in `app_de.arb` / `app_en.arb`, in file order:
`helpTitle` = section heading, keys ending in `Title` / `Question` / `Q` = a question (`<details><summary>`),
other `help…` keys = the answer to the question before (`\n` = new paragraph, lines starting with `• ` / `- ` = a
list). Keys with ICU placeholders are skipped with a warning. **The help keys are not on main yet** (KLD-113 is
in flight): until then the page shows only "Weitere Fragen und Antworten stehen auf der Hilfe-Seite" (link to
`support/`). The extraction is tested against `site/testdata/help_fixture.json`. When KLD-113 lands, check that
its key naming matches the convention above (adjust `faq_blocks` if not) and look at the page once.

## Privacy

`site/privacy/` (de + en) has a new section "Zugang zur App-Beta per E-Mail" / "App beta access by email":
which data (address, message, optional first name), purpose (sending the invitation via Apple TestFlight / a
Google Play test track; Apple/Google then process the address under their own terms), legal basis Art. 6(1)(b)
GDPR, no sharing otherwise, deletion on request and at the latest when the beta ends, ask as an adult. "Kurz
gesagt", "Kinder" and "Deine Rechte" were adjusted (we now can receive data: emails), date 2 November 2026.
`klunki/assets/legal/privacy.json` re-exported (`site/export_legal_text.py privacy`). **Needs the maintainer's
legal review.**

## Acceptance criteria

- [x] Landing page de + en, inline CSS, no external resources, works without JS, light/dark, phone width,
      accessible (landmarks, alt texts, labels, focus outlines, `aria-disabled` store entries).
- [x] PWA at `/klunki/play/`; old root links `?room=` / `?join=` redirected; old root worker removes itself.
- [x] Store entries greyed out until the variables are set; "Zugang anfragen" via mailto without JS.
- [x] FAQ from the `help` ARB keys when present (fixture-tested), else the support link.
- [x] `build_site.py` refuses pages that load from another host; `check_pwa_external_urls.py` still checks the app.
- [x] `build.yml` pages-build and `docs/BUILDING.md` §7.1 updated.

## Verification (done locally, no network)

- `python3 -I site/test_build_site.py`: 7 tests OK.
- `flutter build web --release --base-href /klunki/play/ --dart-define=KLUNKI_WEB_CHANNEL=pages-beta`,
  `pwa_finalize.py`, `build_site.py OUT --app build/web`, served under `/klunki/` with `python3 -m http.server`.
- curl: `/`, `/play/`, `/privacy/`, `/support/`, `/impressum/`, assets, both `klunki_sw.js` → 200; `play/`
  has `<base href="/klunki/play/">`.
- Headless Firefox (BiDi, the `klunki/tool/browser_live/browser.mjs` driver): landing page desktop 1280 and
  phone 400, light and dark, de and en: the right article shown, no horizontal overflow, no broken images;
  `/klunki/?room=K7Q2M` → `/klunki/play/?room=K7Q2M` opens the join screen with the code filled in; the app at
  `play/` renders and registers its worker with scope `/klunki/play/`; the landing page afterwards is still the
  landing page.
- `flutter test test/ui/about_screen_test.dart test/ui/web_beta_test.dart` (privacy export matches the page).

## Later: preview channels (design only, not built)

- **Stable** from `main`: `/klunki/` (landing) and `/klunki/play/`. **Preview** (from a `preview` branch, or per
  PR) in the same Pages artifact at `/klunki/preview/play/`: one more `flutter build web --base-href
  /klunki/preview/play/ --dart-define=KLUNKI_WEB_CHANNEL=pages-preview` into its own output dir and one more
  `--app preview/play=<dir>` for `build_site.py` (already supported, repeatable). Since a Pages deployment
  replaces the whole site, the job building it needs both sources (e.g. check out `preview` into a second
  directory) or a matrix whose builds are merged before `upload-pages-artifact`.
- **Service workers:** separate scopes per path (`/klunki/play/` vs `/klunki/preview/play/`, the more specific
  scope wins). Caveat: `klunki_sw.js` deletes every `klunki-*` cache but its own on activate, so two app builds on
  one origin would wipe each other's offline caches; the cache name needs the scope in it (e.g.
  `klunki-<hash>@<scope path>`) and the cleanup should only touch its own scope's caches.
- **Badge:** a "Vorschau" badge via `KLUNKI_WEB_CHANNEL` (like `pages-beta`, KLD-108), plus a line in the About
  screen.
- **Compatibility:** the build fingerprints (`compat.dart`) already keep stable and preview from playing together
  when rules or decks differ.
- **Apps:** TestFlight external groups and Play closed tracks can map to stable vs preview later; the landing
  page could then show two sets of store entries.
