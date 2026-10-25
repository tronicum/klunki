# KLD-010 — PWA hello world (installable, offline-capable web build)

- **ID:** `KLD-010`
- **Milestone:** Platform hello world
- **Status:** DONE
- **Depends on:** none (uses the existing app shell)
- **Touched paths:**
  - `klunki/web/**`
  - `docs/tasks/KLD-010-pwa-hello-world.md`

## Goal
`flutter build web --release` of the existing app yields a real, installable,
offline-capable PWA branded "Klunki" — a de-risked "hello world" for the final
PWA demo.

## Acceptance criteria
- [x] Manifest: name/short_name "Klunki", DE/EN description, theme/background color from the seed color `#4F46E5`, `lang`, `id`, `scope`; existing icons kept.
- [x] `index.html`: title, description, apple-mobile-web-app-title branded.
- [x] Own service worker (`klunki_sw.js`): precache app shell on install, cache-first for same-origin GETs with network fallback, versioned cache name from a build hash, old caches deleted on activate.
- [x] Flutter's deprecated cleanup worker (`flutter_service_worker.js`) cannot replace/unregister ours.
- [x] Verified: build, local serve, curl checks; browser check (automated if possible, else manual steps documented).

## Constraints
- Only `klunki/web/**` and this card. No Dart/pubspec changes, no new packages, no downloads.

## Hints / context
- Flutter 3.47.8: `flutter_service_worker.js` is a cleanup worker that unregisters itself.
- `flutter.js` (`service_worker_loader.js`) registers `flutter_service_worker.js?v=…` at the
  **same scope** whenever `serviceWorkerSettings` is passed *and any registration exists* —
  that would replace our worker and then unregister it. Hence a custom `web/flutter_bootstrap.js`.
- Release builds load CanvasKit from `www.gstatic.com` and Roboto from `fonts.gstatic.com` by default.

## Definition of done
Release build served locally registers `klunki_sw.js`, manifest is valid, app reloads offline.

## PWA

### Files (`klunki/web/`)
- `manifest.json`: branding, `id`/`scope`/`start_url` `./`, `lang: de`, colors `#4F46E5`.
- `index.html`: branding, registers `klunki_sw.js` on `load`, then posts the resource URLs
  the page loaded (CanvasKit variant, Roboto, ...) to the worker for caching (`klunki-warm-cache`).
- `flutter_bootstrap.js`: custom bootstrap (`{{flutter_js}}` + `{{flutter_build_config}}` +
  `_flutter.loader.load({config: {canvasKitBaseUrl: "canvaskit/"}})`). No `serviceWorkerSettings`,
  so flutter.js never registers its cleanup worker over ours; CanvasKit same-origin.
- `klunki_sw.js`: the worker. Finalized mode = precache + cache-first; dev mode (not
  finalized) = network-first with cache fallback, cache `klunki-dev`.
- `pwa_finalize.py`: post-build step (stdlib Python). Injects the build hash (sha256 over the
  build output) and the precache list into `build/web/klunki_sw.js`, then deletes its own copy
  from `build/web`. Refuses to run twice on the same output.

### Build / serve / verify
```sh
cd klunki
flutter build web --release
python3 build/web/pwa_finalize.py      # must run after every build
cd build/web && python3 -m http.server 8765 --bind 127.0.0.1
```
Open `http://127.0.0.1:8765/` (localhost counts as a secure context for service workers) in Chrome:
1. DevTools > Application > Manifest: name "Klunki", icons shown, no errors; install icon in the address bar.
2. Application > Service workers: `klunki_sw.js` is "activated and running"; Cache storage has `klunki-<hash>`.
3. Network > "Offline", reload: the app starts and renders.
4. Rebuild with a change + finalize + reload twice: a new `klunki-<hash>` cache, the old one is gone.

Verified for this card (2026-10-25) in headless Firefox Nightly via WebDriver BiDi (no Chrome
installed): SW `klunki_sw.js` registered and controlling, scope `/`, 22 cache entries
(18 precached + `canvaskit/canvaskit.{js,wasm}` + Roboto + `/`), app renders after an
offline-emulated reload **and** with the HTTP server stopped; a changed build replaced the old
cache. Rebuilding unchanged sources gives the same hash (deterministic).

### Known limits
- Forgetting `pwa_finalize.py` is safe but weaker: dev-mode worker (network-first, core files only).
- First visit: offline works only after the page has fully loaded once online (the CanvasKit
  variant and Roboto are cached by the warm-up message, not precached).
- CanvasKit is large: the browser's variant is 3.5–7 MB wasm (`canvaskit/` in total ~40 MB with
  `.symbols`, but only one `.js`+`.wasm` pair is cached). `--wasm` builds would use skwasm instead;
  not tested here.
- Roboto comes from `fonts.gstatic.com` (cached by the worker); Noto fallback fonts for other
  scripts/emoji are fetched on demand and are only offline if they were seen online.
- Update model: new worker `skipWaiting()`s and deletes the old cache; the running tab keeps
  the old code until the next reload (cache-first => usually reload twice to see a new build).
- iOS Safari: no install prompt (Share > "Zum Home-Bildschirm"), storage may be evicted after
  ~7 days without use, separate storage for the home-screen app vs. Safari tab, CanvasKit WebGL
  performance can be weak on older iPhones. `orientation` is ignored there.
- Must be served over HTTPS (or localhost) for the worker and install prompt.
