# KLD-097 — App icon

- **ID:** `KLD-097`
- **Title:** A real Klunki app icon instead of the default Flutter icon (concepts, then every platform)
- **Milestone:** release basics (part of KLD-076 "icons")
- **Status:** DONE (step 1: concepts; step 2: **c5-zoom-b-fill** (since 2026-11-04, before: c5-final-d4) applied on iOS, Android and web; the look on real home screens is still to be checked by 🧑)
- **Depends on:** KLD-062 (Spieltisch look)
- **Touched paths:**
  - step 1: `klunki/tool/icon/**`, `docs/tasks/KLD-097-app-icon.md`, `docs/tasks/BOARD.md`
  - step 2: `klunki/tool/icon/**`, `klunki/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (+ `Contents.json` only if a size changes),
    `klunki/android/app/src/main/res/mipmap-*/**`, `klunki/android/app/src/main/res/mipmap-anydpi-v26/**` (new),
    `klunki/android/app/src/main/res/values/ic_launcher_background.xml` (new, if the background is a colour),
    `klunki/web/icons/*.png`, `klunki/web/favicon.png`, `docs/store/*.png` (new)

## Goal

Klunki ("deine Taschen-Spielesammlung") gets its own icon in the Spieltisch
look on iOS, Android (legacy and adaptive) and the web/PWA. The icon is drawn
in code (`klunki/tool/icon/icon_concepts.dart`), so every size is generated
from one source by a script.

## Step 1 — concepts (done)

Four concepts as Flutter painters, rendered to 1024 × 1024 RGB PNGs plus
preview sheets (sizes 180/120/60/40 px, iOS rounded square, Android circle,
light/dark home screen). See `klunki/tool/icon/README.md`.

| id | concept |
|---|---|
| a | "K" made of a card (stem), two chips (upper arm) and a leaning pawn (lower leg) |
| b | Fan of three Quartett cards with a red chip in front |
| c | Stitched leather pocket with a card, a pawn and a chip peeking out |
| d | Four-in-a-Row board whose yellow discs form a "K" |

**The user picked c (the pocket).** Variants c1–c5 followed: a smaller pocket
with more pieces peeking out (card, pawn/knight, chip, Mühle stone, ship,
GoStrategy flag, a "K" letter tile), game pieces as rivets or as the flap
button, and a denim test. See the table in `klunki/tool/icon/README.md`. The
user picks the final variant before step 2 starts.

Later rounds (all in `klunki/tool/icon/README.md`): denim pocket (c5), a
phone with a mini Four-in-a-Row board (c5-p1), the word "Klunki" on a leather
patch (c5-k1, user's request, overrides the "no text" constraint below), a
Quartett card behind the phone (c5-k1-card-b), a lighter patch (c5-cb-c), a
word-game letter tile (c5-cb-tile-1) and a small die behind the red piece.
**Final pick: `c5-final-d4`** (smaller ivory die, 6 pips, turned).

**Follow-up (zoom round):** maintainer feedback on d4: too much margin, the
lettering is unreadable at ~60 pt and in the 30 px header. Zoomed variants
`c5-zoom-a` … `d` (one without lettering) and the comparison sheet
`c5-zoom-compare.png` are in `klunki/tool/icon/README.md`.

**New final pick (2026-11-04): `c5-zoom-b`**: the d4 pocket, bigger (0.95
instead of 0.83), with a wider patch, bigger and bolder "Klunki" lettering and
all pieces kept (~69 % × 86 % of the side). Exported everywhere d4 was: iOS
AppIcon set, Android legacy mipmaps and adaptive foreground (shrunk to 0.625
to fit the 66 dp safe circle; the background layer is the unchanged table),
web icons, maskable icons and favicon, `assets/icon/app_icon.png` (About
screen, menu header), `docs/store/` and the landing page's
`site/assets/{icon-192,favicon}.png`. The zoomed motif no longer fits the 80 %
maskable circle as is, so the export now draws the maskable web icons as the
full table plus the motif shrunk until it fits (0.818 for zoom-b).

**Zoomed to fill (2026-11-04, same day):** the maintainer: "just zoom the
app icon so the unused brown space is used". `c5-zoom-b-fill` keeps the
zoom-b artwork exactly and scales the motif by 1.16 (moved up a little) over
the unchanged full-bleed table: ~80 % × 98 % of the side instead of
69 % × 86 %; the flag pole's knob is cut slightly at the top edge. Applied to
iOS (iPhone, iPad, Spotlight, Settings, 1024), the Android legacy icon, the
web icons and favicon, `assets/icon/app_icon.png`, `docs/store/` and
`site/assets/`. The Android adaptive foreground and the maskable web icons
must stay inside their safe circles: they use the uncropped zoom-b art,
now centred on its smallest enclosing circle, which makes it ~6 % bigger
there (0.662 instead of 0.625; maskable 0.866 instead of 0.818). The menu
header keeps its layout (30 px icon) and shows the new PNG.

## Step 2 — apply the chosen concept everywhere (done)

Done with `klunki/tool/icon/export_icon_test.dart` (opt-in, see the README):
`KLUNKI_ICON_EXPORT=<dir> KLUNKI_ICON_ID=c5-zoom-b-fill flutter test
tool/icon/export_icon_test.dart`, then `cp -R <dir>/{ios,android,web,assets}
klunki/`. `assets/icon/app_icon.png` (384 px) is the copy the About screen
shows (KLD-102).

Step 2b (maintainer feedback): the menu app bar showed the old three-chip
`KlunkiLogo` and its header took a lot of room. It now shows the same PNG
(`KlunkiAppIcon`, 30 px, rounded square; it reads on the cream and the dark
background) next to "Klunki" in a 48 px app bar instead of 56, and "Wähle ein
Spiel" is a slim label like "Mit anderen Geräten spielen" instead of a big
headline; the painter `KlunkiLogo` is gone. On a 375 × 667 phone the first game
tile starts 24 pt higher (78 instead of 102). Screenshot tests decode the
asset images before a shot (`test/support/asset_images.dart`). No other place
drew the old mark: the PWA has no own splash logo, the landing page uses
`Icon-192.png` (its `shot-menu.jpg` is an older menu screenshot).

Matching colours (user-approved): web `theme_color` / meta theme-color
`#C9772B`, `background_color` / page background `#FBF4E8`; iOS
`LaunchScreen.storyboard` background `#FBF4E8`; Android launch and window
background `@color/launch_background` = `#FBF4E8` (`values/colors.xml`) and
`#1F1A16` in dark mode (`values-night/colors.xml`, the walnut table colour, to
avoid a cream flash). The adaptive foreground is the motif without the table, shrunk to
0.78 so every visible pixel is inside the 66 dp safe circle; the background
is the table gradient as PNGs (no colour resource). Store art:
`docs/store/app-icon-1024.png` (= the iOS marketing icon) and
`docs/store/play-store-512.png`. No monochrome (themed) layer and no
`roundIcon` yet.

Generate everything with a script from the painter, **with no new packages**.
`flutter_launcher_icons` would be a new dev dependency, so it needs the
user's OK first. Suggested: extend `render_icons_test.dart` (or add
`render_app_icons_test.dart`, opt-in through an env var like today) so it
paints the chosen concept at each target size directly. Painting each size
gives sharper small icons than downscaling the 1024 master. Write RGB PNGs
(no alpha) where the platform requires it.

### iOS (`klunki/ios/Runner/Assets.xcassets/AppIcon.appiconset/`)
- [x] Replace every PNG listed in `Contents.json` with the same file name and
      pixel size: 20@1/2/3, 29@1/2/3, 40@1/2/3, 60@2/3, 76@1/2, 83.5@2, 1024@1.
- [x] No alpha channel in any file (App Store rejects an alpha 1024). Check
      with `sips -g hasAlpha`.
- [x] Full-bleed square; iOS applies its own corner mask.
- [x] Don't touch `Runner.xcodeproj`, `Info.plist` or `Main.storyboard`.

### Android (`klunki/android/app/src/main/res/`)
- [x] Legacy `mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png`: 48/72/96/144/192 px.
- [x] Adaptive icon (API 26+): `mipmap-anydpi-v26/ic_launcher.xml` with a
      `<background>` and a `<foreground>` (+ `<monochrome>` for themed icons,
      optional: a one-colour silhouette of the motif).
  - background: the table gradient as `ic_launcher_background.png` per
    density, or a plain colour in `values/ic_launcher_background.xml`
    (`#C9772B`-ish, if the gradient doesn't matter at that size).
  - foreground: `mipmap-*/ic_launcher_foreground.png` at 108 dp
    (108/162/216/324/432 px) with a **transparent** background. The motif
    sits in the central 72 dp, key content inside the 66 dp safe circle,
    so it scales to about 61 % of the 108 dp canvas.
- [x] `AndroidManifest.xml` already points at `@mipmap/ic_launcher`; no change
      needed. Add `android:roundIcon` only if a round variant is generated.

### Web / PWA (`klunki/web/`)
- [x] `icons/Icon-192.png`, `icons/Icon-512.png`: full icon.
- [x] `icons/Icon-maskable-192.png`, `icons/Icon-maskable-512.png`: background
      to the edges, motif inside the central 80 % (maskable safe zone).
- [x] `favicon.png`: 32 px (or 48 px). Paint it directly at that size, maybe
      with a simplified motif (fewer details).
- [x] `manifest.json` already lists these files; no change unless names change.
      Check `tool/check_pwa_external_urls.py` and the PWA build still pass.

### Checks
- [ ] Build and look at the icon on the iOS simulator home screen, an Android
      emulator (circle, squircle and themed icon) and the installed PWA.
- [x] `flutter analyze`, `flutter test` green (render tests stay opt-in).
- [x] Short note in `klunki/tool/icon/README.md` on how to regenerate.

## Constraints
- No installs, no new packages without the user's OK.
- No brand imagery or likeness of existing game logos; no game brand names.
- No text in the icon except possibly a single "K" (relaxed by the user: the
  "Klunki" patch is wanted).
