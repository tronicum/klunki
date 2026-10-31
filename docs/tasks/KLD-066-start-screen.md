# KLD-066: Start / welcome screen

- **ID:** `KLD-066`
- **Title:** Start screen "Klunki – deine Spielesammlung für die Hosentasche" with wordmark, tagline and intro animation
- **Priority:** medium-low
- **Status:** TODO (stub)
- **Depends on:** KLD-062 (theme, palette, logo)
- **Touched paths:**
  - `klunki/lib/ui/start_screen.dart` (new), `klunki/lib/app/klunki_app.dart` (route), `klunki/lib/l10n/*.arb`
  - later: `klunki/web/index.html` + `manifest.json` (PWA splash colours), Android launch theme,
    iOS `LaunchScreen.storyboard` (never `Main.storyboard`, `project.pbxproj` or `Runner.xcscheme`)

## Goal
A short, friendly welcome before the menu: the Klunki wordmark and logo, the tagline and a playful intro animation,
then the menu (tap anywhere or after ~1.5 s). Later the same look becomes the native launch screen and the PWA splash.

## Ideas
- Pieces from the games fly in and settle into the logo: a red and a yellow disc drop like in 4 Gewinnt, a stone
  slides along a Mühle line, a card flips. Drawn in code (`CustomPainter`), no image assets.
- Tagline under the wordmark; a "Los geht's" button for screen readers and keyboard.
- Show it on cold start only (not when returning from a game); deep links (`?join=`, `?room=`) skip it.
- Optional later: a "Tipp des Tages" line.

## Reuse from KLD-062
- Logo: `KlunkiLogo` in `klunki/lib/ui/menu_screen.dart` (three pieces in red `#D32F2F`, yellow `#FFC107`,
  blue `#1C5DB8`); move it to a shared file when the start screen is built.
- Background: `KlunkiBackground` (paper gradient light, walnut dark) and `KlunkiPalette.of(context)`; follow the
  active `KlunkiPreset` so selectable themes (KLD-063) apply here too.
- Wordmark: the bundled Roboto Bold (no new font without an OFL check and bundling).
- PWA/native splash: background `#FBF4E8` (light) / `#1F1A16` (dark), seed `#C9772B` as theme colour.

## Tagline (l10n, new key e.g. `startTagline`; machine translations marked `@@x-review`)
| | |
|---|---|
| de | Deine Spielesammlung für die Hosentasche |
| en | Your pocket game collection |
| fr | Ta collection de jeux de poche |
| es | Tu colección de juegos de bolsillo |
| zh | 口袋里的游戏合集 (check the Noto Sans SC subset; rerun `tool/update_web_fonts.py subset` only with the user's OK, it downloads) |
| ar | مجموعة ألعابك في جيبك |
| fa | مجموعه بازی‌های جیبی تو |

## Acceptance criteria
- [ ] Start screen shown on cold start, leads to the menu by tap or after a short delay; deep links skip it.
- [ ] Respects reduced motion (`MediaQuery.disableAnimations`): no fly-in, static logo, same content.
- [ ] Light and dark; RTL fine (ar/fa); tagline in all 7 languages; glyph coverage test green.
- [ ] Semantics: logo has a label, the screen is skippable with one action.
- [ ] Widget tests: shown on start, skipped for `?room=`/`?join=`, reduced motion builds without animation.
- [ ] Later step: native launch screen + PWA splash colours match (separate sub-task, 🧑 for device checks).
