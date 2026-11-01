# KLD-097 — App icon

- **ID:** `KLD-097`
- **Title:** A real Klunki app icon instead of the default Flutter icon (concepts, then every platform)
- **Milestone:** release basics (part of KLD-076 "icons")
- **Status:** IN_PROGRESS (step 1 done: concepts; step 2 waits for the user's pick)
- **Depends on:** KLD-062 (Spieltisch look)
- **Touched paths:**
  - step 1: `klunki/tool/icon/**`, `docs/tasks/KLD-097-app-icon.md`, `docs/tasks/BOARD.md`
  - step 2: `klunki/tool/icon/**`, `klunki/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (+ `Contents.json` only if a size changes),
    `klunki/android/app/src/main/res/mipmap-*/**`, `klunki/android/app/src/main/res/mipmap-anydpi-v26/**` (new),
    `klunki/android/app/src/main/res/values/ic_launcher_background.xml` (new, if the background is a colour),
    `klunki/web/icons/*.png`, `klunki/web/favicon.png`

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

**The user picks one** (or asks for changes) before step 2 starts.

## Step 2 — apply the chosen concept everywhere

Generate everything with a script from the painter, **with no new packages**.
`flutter_launcher_icons` would be a new dev dependency, so it needs the
user's OK first. Suggested: extend `render_icons_test.dart` (or add
`render_app_icons_test.dart`, opt-in through an env var like today) so it
paints the chosen concept at each target size directly. Painting each size
gives sharper small icons than downscaling the 1024 master. Write RGB PNGs
(no alpha) where the platform requires it.

### iOS (`klunki/ios/Runner/Assets.xcassets/AppIcon.appiconset/`)
- [ ] Replace every PNG listed in `Contents.json` with the same file name and
      pixel size: 20@1/2/3, 29@1/2/3, 40@1/2/3, 60@2/3, 76@1/2, 83.5@2, 1024@1.
- [ ] No alpha channel in any file (App Store rejects an alpha 1024). Check
      with `sips -g hasAlpha`.
- [ ] Full-bleed square; iOS applies its own corner mask.
- [ ] Don't touch `Runner.xcodeproj`, `Info.plist` or `Main.storyboard`.

### Android (`klunki/android/app/src/main/res/`)
- [ ] Legacy `mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png`: 48/72/96/144/192 px.
- [ ] Adaptive icon (API 26+): `mipmap-anydpi-v26/ic_launcher.xml` with a
      `<background>` and a `<foreground>` (+ `<monochrome>` for themed icons,
      optional: a one-colour silhouette of the motif).
  - background: the table gradient as `ic_launcher_background.png` per
    density, or a plain colour in `values/ic_launcher_background.xml`
    (`#C9772B`-ish, if the gradient doesn't matter at that size).
  - foreground: `mipmap-*/ic_launcher_foreground.png` at 108 dp
    (108/162/216/324/432 px) with a **transparent** background. The motif
    sits in the central 72 dp, key content inside the 66 dp safe circle,
    so it scales to about 61 % of the 108 dp canvas.
- [ ] `AndroidManifest.xml` already points at `@mipmap/ic_launcher`; no change
      needed. Add `android:roundIcon` only if a round variant is generated.

### Web / PWA (`klunki/web/`)
- [ ] `icons/Icon-192.png`, `icons/Icon-512.png`: full icon.
- [ ] `icons/Icon-maskable-192.png`, `icons/Icon-maskable-512.png`: background
      to the edges, motif inside the central 80 % (maskable safe zone).
- [ ] `favicon.png`: 32 px (or 48 px). Paint it directly at that size, maybe
      with a simplified motif (fewer details).
- [ ] `manifest.json` already lists these files; no change unless names change.
      Check `tool/check_pwa_external_urls.py` and the PWA build still pass.

### Checks
- [ ] Build and look at the icon on the iOS simulator home screen, an Android
      emulator (circle, squircle and themed icon) and the installed PWA.
- [ ] `flutter analyze`, `flutter test` green (render tests stay opt-in).
- [ ] Short note in `klunki/tool/icon/README.md` on how to regenerate.

## Constraints
- No installs, no new packages without the user's OK.
- No brand imagery or likeness of existing game logos; no game brand names.
- No text in the icon except possibly a single "K".
