# Releasing Klunki

How versions and build numbers work and how a release is made (KLD-116). Short version: bump the
version, write the changelog, tag, let CI build, upload by hand.

## Version and build number

| What | Form | Source | Where it shows up |
|---|---|---|---|
| **Version** | `MAJOR.MINOR.PATCH`, e.g. `1.1.0` | `version:` in `klunki/pubspec.yaml` (`1.1.0+1`), mirrored in `appVersion` in `klunki/lib/app/build_info.dart` (a test keeps both equal) | iOS `CFBundleShortVersionString`, Android `versionName`, the app ("Version 1.1.0 (b8752a9)"), store listings, the tag `v1.1.0` |
| **Build number** | `YYYYMMDDNN`, e.g. `2026110201` | CI: `tool/build_number.sh` → `flutter build … --build-number` (and `--dart-define=KLUNKI_BUILD_NUMBER`); local builds keep the pubspec's `+1` | iOS `CFBundleVersion`, Android `versionCode`, small print on the About screen, the handshake's `build` label |
| **Commit** | 7 hex digits, e.g. `b8752a9` | CI: `--dart-define=KLUNKI_BUILD=${{ github.sha }}`; local builds show `(dev)` | the version line, the handshake's `build` label |

- **Numbering rule (maintainer, 2026-11-02).** **1.1.0** is the first bigger release (the first external
  TestFlight test). **PATCH** (`1.1.1`, `1.1.2`, …) = functional updates: **new games or game variants**.
  Design tweaks and small fixes get **no new version, only a new build number**. **MINOR** and **MAJOR**
  bumps are reserved for bigger milestones the maintainer decides. (`1.0.0` was an earlier internal-only
  TestFlight upload.)
- **Build number** `YYYYMMDDNN`: the commit's committer date in **UTC**, then `NN` = how many commits of
  that UTC day are on the first-parent line up to and including this commit (01..99). Deterministic (the
  same commit always gets the same number: a CI re-run or the tag build of a commit main already built
  gives the same number for the same app) and increasing along `main` (the first merge of a day is `01`,
  the next `02`). More than 99 commits in one day stops the build instead of reusing a number. The
  script needs the full history (`fetch-depth: 0` in `build.yml`) and refuses a shallow clone. Test it with
  `tool/build_number_test.sh` (CI job `tools`).
- **Limits.** Android `versionCode` may be at most 2 100 000 000; the largest number the scheme makes is
  2 099 123 199. Do not build Android with `--split-per-abi`: Flutter adds `1000 × ABI` to the
  versionCode, which would collide with numbers of later days. iOS only needs `CFBundleVersion` to
  increase per version; it does.
- **Only builds of `main` or of a release tag go to a store.** A manual workflow run on another branch
  counts that branch's commits and can repeat a number of `main`.
- iOS takes both numbers from `Info.plist` (`$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)`), Android
  from `flutter.versionName` / `flutter.versionCode` in `android/app/build.gradle.kts`: `--build-name` /
  `--build-number` reach both without project changes.

The app shows `Version 1.1.0 (b8752a9)` in the menu and on the About screen, with
`Build-Nummer 2026110201 · Protokoll 3 · Spieldaten 2699da15` in small print there. Whether two devices can
play together is decided by the protocol version and the game fingerprints (`compat.dart`,
`protocolVersion`, see `packages/klunki_net/PROTOCOL.md`), **never by the app version**. When two
devices refuse each other, the message names both versions ("Anna hat 1.1.0 (b8752a9), Ben hat 1.1.1
(c3d4e5f).") so people see who has to update.

## Making a release

1. **Pick the version.** New games or features since the last tag: raise MINOR (`1.1.0`); fixes only:
   raise PATCH (`1.0.1`).
2. **Bump it** in `klunki/pubspec.yaml` (`version: 1.1.0+1`; leave the `+1`, CI sets the real build
   number) and in `appVersion` in `klunki/lib/app/build_info.dart`. `flutter test test/app/build_info_test.dart`
   checks that both match.
3. **Changelog.** Move the `[Unreleased]` items in `CHANGELOG.md` under a new `## [1.1.0] – <date>`
   heading, in plain words, with a short German "Kurz:" line (it doubles as the store's "What's new" /
   "Was ist neu"); update the compare links at the bottom.
4. **Commit** (`Release 1.1.0`), merge to `main`, and check that CI (`ci.yml`) is green.
5. **Tag** the merge commit on `main` with an annotated tag and push it (maintainer only):
   ```bash
   git tag -a v1.1.0 -m "Klunki 1.1.0"
   git push origin v1.1.0
   ```
   Never move or reuse a pushed tag; a broken release gets the next PATCH.
6. **CI builds** (`build.yml` runs on tags `v*`): the PWA (`klunki-pwa`), the APK (`klunki-android-apk`) and
   the app bundle (`klunki-android-aab`, signed with the upload key when the `KEYSTORE_*` secrets exist),
   all with `--build-number` from `tool/build_number.sh` and the commit. The tag build of a commit has the
   same build number as the `main` build of that commit.
7. **Upload by hand** (maintainer):
   - **Android:** `gh run download <run-id> --name klunki-android-aab` → Play Console → the track
     (internal, closed, open) → new release → upload, release notes from the changelog
     (`docs/PLAYSTORE.md`). Play refuses a versionCode it has seen before.
   - **iOS / TestFlight:** there is no signed iOS build in CI. On the Mac, from the tagged commit:
     ```bash
     git checkout v1.1.0
     cd klunki
     flutter build ipa --release \
       --build-number=$(../tool/build_number.sh) \
       --dart-define=KLUNKI_BUILD=$(git rev-parse HEAD) \
       --dart-define=KLUNKI_BUILD_NUMBER=$(../tool/build_number.sh)
     ```
     then upload `build/ios/ipa/*.ipa` with Transporter (or Xcode Organizer → Distribute App) and add the
     "What to Test" text from the changelog (`docs/APPSTORE.md`). No Xcode project change is needed.
   - **Web:** the Pages site is built from `main` (`pages-build`, when `PAGES_ENABLED` is set); the
     `klunki-pwa` artifact of the tag is the one to serve with `klunki relay --web`.
8. After the release: a new empty `## [Unreleased]` stays at the top of `CHANGELOG.md`.

## Later (pointers only, nothing set up)

A pushed `v*` tag could also:
- create a GitHub Release with the changelog section and attach the PWA zip, the APK and the relay
  binaries (relay packages, KLD-114);
- build and push a relay container image tagged with the version;
- update the download and version information on the website / landing page (KLD-115).

Each of these needs the maintainer's OK first (publishing, accounts, registries).
