# KLD-070 — GitHub Actions CI, PWA + Android builds, build guide

- **ID:** `KLD-070`
- **Title:** CI (analyze + test), PWA/Android build artifacts, iOS compile check, moderate lints, the flaky loopback test, `docs/BUILDING.md`
- **Milestone:** infrastructure (folds in the review's "minimal CI + stricter lints + flaky test" card, `docs/REVIEW-2026-10.md` T4/KLD-072)
- **Status:** DONE. **Android CI build unverified until the first run on GitHub** (no Android SDK on the dev Mac). Workflows run only after 🧑 pushes.
- **Depends on:** –
- **Touched paths:**
  - `.github/workflows/ci.yml`, `.github/workflows/build.yml` (new)
  - `klunki/android/app/build.gradle.kts` (release signing with debug fallback)
  - `klunki/tool/check_pwa_external_urls.py` (new)
  - `klunki/analysis_options.yaml`, `packages/klunki_{engine,net}/analysis_options.yaml` (new)
  - lint fixes: `packages/klunki_engine/lib/{connect4,debug/gostrategy_text,debug/schiffe_text}.dart`, `packages/klunki_net/lib/src/guest.dart`, a few tests
  - flaky test: `klunki/test/ui/pairing/pairing_test_utils.dart`, `klunki/test/e2e/{e2e_support,muehle_screens_e2e_test}.dart`, `klunki/test/ui/shell/resign_test.dart`
  - `docs/BUILDING.md` (new), `README.md`, `docs/tasks/BOARD.md`

## Goal
Every push to main and every PR runs analyze + tests of all three Dart projects; pushes to main / `v*` tags build a
PWA and an Android APK as downloadable artifacts; an iOS compile check runs on demand. Self-builders have one guide.
Nothing is deployed.

## What was done

### Workflows
Flutter pinned to **3.47.8** (stable, Dart 3.13.7; = local `flutter --version`; pubspec needs `^3.13.7`). No
`.fvmrc` exists. Actions pinned to commit SHAs, all releases ≥ 2 weeks old on 2026-10-31:

| Action | Tag | SHA | Released |
|---|---|---|---|
| actions/checkout | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` | 2026-07-20 |
| subosito/flutter-action | v2.23.0 | `1a449444c387b1966244ae4d4f8c696479add0b2` | 2026-03-25 |
| actions/setup-java | v6.0.1 | `de7274f081f381c8f8158605e0321c36c376e2e6` | 2026-09-09 |
| actions/upload-artifact | v7.0.2 | `cf430e030ddbb5b0abf93d22962f4752f3646cd9` | 2026-10-07 |
| actions/download-artifact (disabled Pages job) | v8.0.1 | `3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c` | 2026-03-11 |
| actions/upload-pages-artifact (disabled) | v5.0.0 | `fc324d3547104276b827a68afc52ff2a11cc49c9` | 2026-04-10 |
| actions/deploy-pages (disabled) | v5.0.1 | `368f82528645a54fb793d4d04e342629a3f51346` | 2026-09-01 |

- `ci.yml` (push main, pull_request; `permissions: contents: read`; concurrency cancels superseded runs):
  **engine** and **net** (`dart pub get`, `dart analyze --fatal-infos`, `dart test`; `web_compile_test` uses only
  dart2js from the SDK, no Chrome/Node), **app** (`flutter gen-l10n` + `git diff --exit-code lib/l10n`,
  `flutter analyze`, `flutter test`). Flutter SDK and pub cache cached by flutter-action.
- `build.yml` (push main, tags `v*`, `workflow_dispatch`):
  - **pwa:** `flutter build web --release`, `python3 -I build/web/pwa_finalize.py`, then
    `tool/check_pwa_external_urls.py`, upload `klunki/build/web` as `klunki-pwa`.
  - **android:** Temurin 17, the runner's preinstalled Android SDK (licences accepted with its sdkmanager),
    Gradle heap capped at 4 GB through `~/.gradle/gradle.properties` (the template asks for 8 GB; private-repo
    runners have 7 GB RAM), optional keystore from secrets, `flutter build apk --release`, upload
    `app-release.apk` as `klunki-android-apk`.
  - **ios:** only on `workflow_dispatch` (macOS minutes), `flutter build ios --release --no-codesign`, no artifact.
  - **pages:** `if: false`, with a note (publishing needs the owner's OK; https Pages can only use a `wss://` relay).

### External-URL check
A plain `grep jsdelivr|unpkg|gstatic|googleapis` on `build/web` always hits: the engine contains its default
URLs as literals (`www.gstatic.com/flutter-canvaskit` in flutter.js/flutter_bootstrap.js/main.dart.js,
`fonts.gstatic.com/s/` in main.dart.js) even though the app overrides them, and `klunki_sw.js` names the hosts as
cacheable. `check_pwa_external_urls.py` allows exactly those occurrences, verifies the overrides that make them
dead (`canvasKitBaseUrl: "canvaskit/"`, local `canvaskit.wasm`, Roboto bundled, worker finalized) and fails on
anything else. Verified against the current local build (passes). The runtime proof stays `tool/pwa_i18n_check.sh`.

### Android config (never built in this repo, so reasoned, not run)
- Compared with the Flutter 3.47.8 template (`flutter_tools/templates/app/android*.tmpl`): `settings.gradle.kts`,
  `gradle.properties` (`android.newDsl=false`, `android.builtInKotlin=false`) and `app/build.gradle.kts` match it
  (AGP 9.1.0 ≤ max known 9.2, Kotlin 2.4.0 = max known, Gradle 9.3.1 = template default). Flutter's
  `minSdkVersion` is 24 (`mobile_scanner` 7.4.2 needs 23), `compileSdkVersion` 36 (= mobile_scanner,
  bonsoir_android), NDK 28.2.13676358.
- `gradlew` and `gradle-wrapper.jar` are gitignored; `flutter build` injects them from the SDK cache.
- Manifest already has INTERNET, network/Wi-Fi state, multicast, CAMERA (+ `camera` feature optional).
- **No cleartext / network security config needed:** the app uses `dart:io` sockets and `dart:io` WebSocket
  (`klunki_net`), which don't consult Android's `NetworkSecurityPolicy` (the Dart SDK has no
  insecure-connection check anymore; grep of `dart-sdk/lib/{_http,io}` finds none). Browsers' `http://` only
  matters for the PWA.
- **Only change:** release signing. `app/build.gradle.kts` reads `android/key.properties` or the
  `KLUNKI_KEYSTORE_FILE` / `KLUNKI_KEYSTORE_PASSWORD` / `KLUNKI_KEY_ALIAS` / `KLUNKI_KEY_PASSWORD` env vars; if
  any is missing it signs release with the debug key and logs a Gradle warning (this also covers KLD-053's code
  part; the 🧑 keystore steps remain).
- Risks for the first CI run: R8/minify of the ML Kit dependency of mobile_scanner (it ships consumer rules), NDK
  auto-download, AGP 9 + `newDsl=false` deprecation warnings. Fix forward from the first log.

### The flaky loopback test (root cause + fix)
`web_join_screen_test.dart` "loopback: native host … vs the web join over joinWebSocket" (and every other widget
test with real loopback transports) created its transports with a **2 s keepalive timeout**. The sockets and
keepalive timers live in the real zone, but each `tester.pump()` is synchronous: while two side-by-side apps
(1800×1400) are laid out and painted, the isolate can't read pongs. Under full-suite load (one test isolate per
core) a single pump can exceed 2 s of wall time, the transport times out, the connection drops mid-game, and the
next `pumpUntil` fails ("X move in the browser").

Reproduced deterministically by inserting a 2.6 s busy-wait (simulated CPU starvation) after the connection:
fails with the old 2 s timeout, passes with the fix.

Fix: `pairing_test_utils.netTimeout` is 10 s (the library default). No pairing test relies on the timeout firing;
all leave with a `bye`. `e2e_support` gets `widgetNetTimeout` (10 s), used by the widget tests
`muehle_screens_e2e_test.dart` (the earlier "timing flake" in I18N-07-08) and `resign_test.dart`. The
plain-`test` Wi-Fi-cut e2e tests keep the 2 s timeout, because they need a cut to be noticed fast.
`pumpUntil`'s limit is raised from 5 s to 15 s. Its `Stopwatch` *is* real wall time (Dart's Stopwatch isn't
faked by fake-async), so the limit only bounds a hang. No `@Tags(['network'])` / retry step was needed.

### Moderate lints
`strict-casts` in all three projects; `cancel_subscriptions` everywhere; `unawaited_futures` in the two packages.
Fixed what that found: `connect4.dart` `final int col = move['col']` (a malformed move threw a `TypeError`; now
`col is! int` → rejected, with a test), dynamic → int in the GoStrategy/Schiffe debug formatters,
`Iterable<int>.generate` in `guest.dart`, `unawaited(...)` for 4 fire-and-forget `done.catchError` in net tests.

**Follow-up (not done here, to avoid broad refactors while other agents work):** `unawaited_futures` in the app
(17 hits, mostly `pairing_screen.dart`, `room_join.dart`, `web_join_screen.dart`), `discarded_futures`,
`strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `only_throw_errors`
(`socket_channel.dart:19` rethrows arbitrary errors), `close_sinks`, `prefer_final_locals`,
`avoid_catches_without_on_clauses`, `package:lints/recommended.yaml` for the packages (adds a dev dependency).

## Acceptance criteria
- [x] `ci.yml` / `build.yml` as above, YAML parses (Ruby `YAML.load_file`), every action SHA-pinned.
- [x] Android release falls back to debug signing without secrets; secrets documented (BUILDING.md §7).
- [x] No deployment; Pages job disabled.
- [x] Flaky test root-caused and fixed; full `flutter test` green 3× in a row (486 passed, 38 skipped each).
- [x] `dart analyze` + `dart test` green in both packages; `flutter analyze` green.
- [x] `docs/BUILDING.md` written and linked from README.
- [ ] 🧑 Push, then check the first CI + Build runs (especially the Android job).
- [ ] 🧑 Optional: add the keystore secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEYSTORE_KEY_ALIAS`, `KEYSTORE_KEY_PASSWORD`).
