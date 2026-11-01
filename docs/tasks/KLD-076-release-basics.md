# KLD-076: Release basics: icons, launch screens, signing, licences, store metadata, PWA update

- **ID:** `KLD-076`
- **Title:** Release basics: icons, launch screens, signing, licences, store metadata, PWA update
- **Priority:** medium
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** KLD-053, KLD-012, KLD-066 (launch look)
- **Touched paths:** `docs/legal/**`, `klunki/ios/Runner/{Assets.xcassets,Info.plist,LaunchScreen.storyboard,*.xcstrings}` (never `project.pbxproj`, `Runner.xcscheme` or `Main.storyboard`), `klunki/android/**`, `klunki/web/**`, `klunki/lib/ui/about_screen.dart`, `klunki/pubspec.yaml`

## Goal
The app can pass store review (REVIEW R1–R5, I6).

## Acceptance criteria
- [ ] A real icon set (adaptive on Android, maskable on the web), branded launch screens, and manifest colours that match the theme.
- [ ] An About screen with the version, a source link and `showLicensePage` (OFL fonts, dependencies).
- [ ] Localized Info.plist permission strings, `CFBundleLocalizations` and `ITSAppUsesNonExemptEncryption=false`.
- [ ] PWA: no automatic `skipWaiting`, a "Neue Version – neu laden" prompt, and an automated finalize step.
- [ ] 🧑 decisions: AGPL vs store distribution (two options drafted 2026-11-01, see "Licence and store distribution" below; the maintainer picks one), ~~ML Kit~~ (gone since KLD-080: `flutter_zxing`), the release keystore, the Apple team.

## Licence and store distribution (2026-11-01, 🧑 open decision)

Not legal advice; a lawyer should check whichever option is chosen.

**Status on 2026-11-01:** the source stays **AGPL-3.0-only**. Apple's App Store/TestFlight
terms (usage rules, FairPlay DRM, the store EULA) and Google Play's terms add restrictions
that AGPL §10 forbids, so a store build needs one of the two routes below. The maintainer
picks one. Until then, `README.md`, `LICENSE` and the in-app licence page stay unchanged.

| | **A. App store exception** (AGPL §7 additional permission) | **B. Dual licensing**: a custom licence for the maintainer's store builds |
|---|---|---|
| Who may publish in stores | Anyone, forks included, as long as the source stays public under the AGPL | Only the copyright holder (the maintainer); forks stay AGPL-only and cannot go into the stores |
| Licence files | Add `LICENSE-EXCEPTION.md` (draft: [`docs/legal/app-store-exception-DRAFT.md`](../legal/app-store-exception-DRAFT.md)) and mention it in the README and the in-app licence page | `LICENSE` stays as it is. Store builds ship under the store's standard EULA or a short custom licence, and the README says so |
| Outside contributions | Every contributor must agree to the exception (consent or DCO-style sign-off that covers it) | Needs a CLA that lets the maintainer relicense contributions |
| Third-party parts | Not covered by the exception; their own licences apply | The store build's licence must still respect them: OFL fonts, CC photos and permissive packages need their notices and must stay redistributable |
| Precedents | Signal (GPLv3 App Store permission), Nextcloud iOS `COPYING.iOS`, Bulwark Mail (AGPL, Discussion #1113, 2026) | Common for open-core and companion apps whose owner controls all copyright |
| Fit for Klunki today | Fits the project's open stance: a fork could also ship. It must also cover the AGPL "Installation Information" paragraphs | Simplest while the maintainer is the only copyright holder, but it is one-sided |

**Copyright holders.** Either route only works if every copyright holder agrees. Today that is the maintainer alone
(the code was written with AI assistance and has no outside contributors). There is no `CONTRIBUTING.md` yet. If outside
contributions are accepted later, add a CLA (for B) or a sign-off line (for A) first. A suggested line for a future
CONTRIBUTING note (A):

> By submitting a contribution you agree that it is licensed under the GNU AGPL-3.0 together with the additional
> permission for app store distribution in `LICENSE-EXCEPTION.md` (sign off your commits with `git commit -s`).

For B, use instead: "…you grant the maintainer the right to also distribute your contribution under other licence terms,
including in app store builds (see the CLA)."

### Third-party inventory (2026-11-01)

The inventory covered `klunki/pubspec.lock`, `packages/klunki_engine/pubspec.lock` and `packages/klunki_net/pubspec.lock`:
125 hosted packages, each checked against its LICENSE file in the pub cache.

- **No GPL, LGPL or AGPL dependency.** 102 are BSD, 14 MIT, 4 Apache-2.0, 3 Apache+BSD (image_picker*) and 1 BSD+MIT (node_preamble, dev only).
  The direct dependencies are bonsoir (MIT), camera (BSD), cupertino_icons (MIT), flutter_zxing (MIT), intl (BSD),
  qr_flutter (BSD), shared_preferences (BSD) and url_launcher (BSD).
- **dbus 0.7.15: MPL-2.0** (file-level copyleft; its text mentions the GNU licences only as "Secondary Licenses").
  It comes in transitively through `bonsoir_linux`, so it is only in Linux desktop builds, not in iOS, Android or web. It does not block the stores.
- **Native code in flutter_zxing:** zxing-cpp (Apache-2.0) and libzint (BSD-3-Clause). Both are on the licence page (KLD-080).
  The proprietary ML Kit is gone since KLD-080.
- **Flutter engine/SDK** (`sky_engine`): BSD plus permissive bundled licences, listed automatically by `showLicensePage`.
- **Fonts:** Roboto, Noto Sans Arabic, Noto Sans SC and Noto Sans Math are all **SIL OFL 1.1**. Bundling them is fine; the licence text is registered (`registerFontLicenses`).
- **Quartett photos** (`klunki/assets/quartett/*/credits.json`, 128 images): 77 copyleft-attribution
  (CC BY-SA 4.0 ×48, 3.0 ×8, 3.0 de ×2, 3.0 igo ×1, 2.5 ×1, 2.0 ×16, plus FAL ×1),
  17 attribution-only (CC BY 4.0 ×6, 3.0 ×1, 2.0 ×10), 2 GODL-India (attribution) and 32 free (Public domain ×28, CC0 ×4).
  - Attribution: every photo needs its author, licence name and link, the source, and a note that it was modified
    (it was resized). The in-app credit line and dialog plus the gallery (KLD-082) already show this; keep them in store builds.
  - ShareAlike: the resized files stay under the same licence (stated in the credit dialog).
  - ⚠️ **Review item, not a confirmed blocker:** CC BY/BY-SA (2.0–4.0) and FAL forbid applying technological
    measures that restrict recipients' rights. Apple encrypts App Store binaries (FairPlay). The usual view is that
    this is acceptable when the same files can be freely obtained elsewhere: they are linked from the app to Wikimedia
    Commons, and the repo copy is public. CC 4.0 §2(a)(4) also allows circumventing such measures. This should be part
    of the legal check. Fallback if needed: use only PD/CC0 photos in iOS builds.
- **Blockers:** none in the dependencies. The only store-distribution blocker is our own AGPL, which option A or B solves.

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.
