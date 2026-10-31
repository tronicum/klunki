# KLD-076: Release basics: icons, launch screens, signing, licences, store metadata, PWA update

- **ID:** `KLD-076`
- **Title:** Release basics: icons, launch screens, signing, licences, store metadata, PWA update
- **Priority:** medium
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** KLD-053, KLD-012, KLD-066 (launch look)
- **Touched paths:** `klunki/ios/Runner/{Assets.xcassets,Info.plist,LaunchScreen.storyboard,*.xcstrings}` (never `project.pbxproj`, `Runner.xcscheme` or `Main.storyboard`), `klunki/android/**`, `klunki/web/**`, `klunki/lib/ui/about_screen.dart`, `klunki/pubspec.yaml`

## Goal
The app can pass store review (REVIEW R1–R5, I6).

## Acceptance criteria
- [ ] A real icon set (adaptive on Android, maskable on the web), branded launch screens, and manifest colours that match the theme.
- [ ] An About screen with the version, a source link and `showLicensePage` (OFL fonts, dependencies).
- [ ] Localized Info.plist permission strings, `CFBundleLocalizations` and `ITSAppUsesNonExemptEncryption=false`.
- [ ] PWA: no automatic `skipWaiting`, a "Neue Version – neu laden" prompt, and an automated finalize step.
- [ ] 🧑 decisions: AGPL vs store distribution, ML Kit (unbundled, or another scanner), the release keystore, the Apple team.

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.
