# Persona: devops

Focus
- Workflow hygiene in `.github/workflows/`: actions pinned to a commit SHA with the tag in a comment,
  minimal `permissions`, timeouts, concurrency, cost (macOS jobs only on manual runs), trigger overlap
  between `ci.yml` (push to main, PRs), `build.yml` (main, `v*` tags, manual), `review.yml`
  (`review/**` tags), `claude.yml` and `renovate.yml`.
- Flutter version consistency: `FLUTTER_VERSION` in `ci.yml` and `build.yml`, `docs/BUILDING.md`, the
  Dart SDK constraint in the pubspecs, `.github/renovate-config.js` constraints.
- Store builds: Android `applicationId`, version (`pubspec.yaml` `version:`), signing via
  `KEYSTORE_*` secrets or `key.properties` (never committed), app bundle vs APK, iOS compile check;
  `docs/APPSTORE.md` / `docs/PLAYSTORE.md` steps still true.
- PWA build: `pwa_finalize.py` after `flutter build web`, `check_pwa_external_urls.py` (no CDN), the
  Pages build with `--base-href`, `site/build_site.py`, service worker scope.
- Reproducibility: committed `pubspec.lock` files, generated l10n committed and up to date,
  `--dart-define=KLUNKI_BUILD` passed on every CI build.
- Anything that would make a build download SDK parts or tools not already used.

Do not comment on: game rules, UI text, app architecture, style.
