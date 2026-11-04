# App icon concepts (KLD-097)

Step 1 of KLD-097: four icon concepts drawn in code, in the "Spieltisch" look
of KLD-062 (colours from `KlunkiPalette.classicLight`, pawn shape from
`lib/ui/games/chess/chess_pieces.dart`). All of them are full-bleed, opaque
squares on a warm amber table, have no text (except the c5-k variants), and keep their key content inside
the central ~66 % so Android circle or squircle masks don't cut it off.

| id | concept | idea |
|---|---|---|
| a | K aus Spielsteinen | A "K": the stem is an upright Quartett card, the upper arm a yellow and a red chip, the lower leg a leaning white pawn |
| b | Kartenfächer mit Chip | A fan of three Quartett cards (blue, green, purple) with a red Four-in-a-Row chip in front |
| c | Tasche mit Spielsteinen | A stitched leather pocket ("Taschen-Spielesammlung") with a card, a pawn and a red chip peeking out |
| d | Vier-Gewinnt-K | A Four-in-a-Row board (4 × 5) whose yellow discs form a "K"; dark empty holes so the letter still reads at 40 px |

The user picked **c**. Variants of c (smaller pocket, more pieces, game
pieces as rivets; the whole group fills about 66 % of the icon):

| id | variant |
|---|---|
| c1 | Brown pocket with yellow chip rivets; card, pawn, red GoStrategy flag and red chip |
| c2 | Pocket with a front flap and a white Mühle stone as its button; card, black knight and a small ship |
| c3 | Slightly tilted pocket with dark Mühle stone rivets, 5 pieces: blue flag, card, pawn, wooden "K" letter tile, red chip |
| c4 | Minimal: three big pieces (card, pawn, red chip), yellow chip rivets |
| c5 | Like c1 in denim blue with orange stitching (contrast test) |

The user then picked **c5** (denim). Final size and phone ideas:

| id | variant |
|---|---|
| c5-final | c5 with a ~12 % bigger pocket, pieces unchanged; the group fills ~69 % |
| c5-p1 | A generic phone (graphite body, plain screen) instead of the card, with a tiny Four-in-a-Row board on its screen |
| c5-p2 | A phone outline stitched on the pocket front in the orange thread; it fades away at small sizes |
| c5-p3 | A phone with a lit blue screen stands behind the pieces in the card's place; pawn, flag and chip pop out in front of it |

The phones are deliberately generic: a rounded rectangle with a screen, no
notch, no buttons, no brand cues.

The user then picked **c5-p1** and asked for the name "Klunki" on the icon,
preferably centred on the pocket. All of these are c5-p1 with the same pieces
and pocket; the word is set in Roboto Bold (`assets/fonts/Roboto`, already in
the app; the render test loads it with a `FontLoader`):

| id | variant |
|---|---|
| c5-k1 | Brown leather jeans patch with its own cream stitching, centred on the pocket, slightly tilted; "Klunki" pressed in, cream letters |
| c5-k2 | "Klunki" embroidered straight on the denim in the yellow thread (satin-stitch stripes, darker thread edge, small shadow) |
| c5-k3 | "Klunki" as a big white print with a thick dark outline, centred |
| c5-k4 | Big yellow letters with a dark outline on a gentle rainbow arch (badge style), centred |
| c5-k5 | A red ribbon banner with folded tails across the lower pocket, white letters; the tails reach past the 66 % circle (inside 80 %) |
| c5-k6 | A ~25 % bigger red flag with "Klunki" on the pennant |

Legibility: all are clear at 1024 and 180 px; k3 and k4 (biggest, highest
contrast) read best at 120 px. At 60 px the word is only a light/dark smudge
on the pocket and at 40 px it is mush in every variant; the pocket, phone and
pieces carry the icon there. k6's pennant text is already small at 180 px.
`c5-k-compare.png` (written by the render test) shows all k variants at 256,
180 and 60 px side by side.

The user then picked **c5-k1** (leather patch, matches the pocket). Patch and
lettering styles, all Roboto (the bundled Noto Sans Math is only a symbol
subset, so script or Fraktur letters are not available without a new font):

| id | variant |
|---|---|
| c5-k1a | Dark chocolate leather, gold-foil Roboto Bold, gold stitching |
| c5-k1b | Light tan leather, classic tonal deboss (letters pressed in, darker brown); weakest contrast, soft at 180 px |
| c5-k1c | Mid leather, white caps "KLUNKI" in Roboto Medium, wide letter spacing |
| c5-k1d | Mid leather, cream Roboto Regular (thin), slightly larger |
| c5-k1e | Red-brown leather, tall condensed gold caps (Roboto Bold squeezed to 78 %), workwear-label look |
| c5-k1f | Mid leather, raised cream Roboto Bold Italic with a dark outline |
| c5-k1-card-a | The Quartett card back in the phone's place (as c5-final), k1a patch |
| c5-k1-card-b | Phone in front, a green Quartett card fanned out behind it to the left, k1a patch |

All patch styles read at 180 px (k1b and k1d least well); at 60 px the patch
is a brown block with a light smudge. `c5-k1-compare.png` shows k1, k1a–f and
both card variants at 256, 180 and 60 px.

The user then picked **c5-k1-card-b** as the base. Patch steps from k1 to
k1b, and a light-wood word-game tile ("K", point value 5, Roboto Bold; no
brand look):

| id | variant |
|---|---|
| c5-cb-a | k1 patch: cream letters pressed into mid-brown leather |
| c5-cb-b | k1b patch: tonal deboss in light tan; softest at 180 px |
| c5-cb-c | In between: lighter leather than k1, cream letters with k1's dark edge; reads at 180 px |
| c5-cb-d | k1b's light tan with deep-brown pressed letters (k1b with more contrast) |
| c5-cb-e | A step lighter than cb-c (tan leather), cream letters |
| c5-cb-tile-1 | cb-c patch; tile rising from the pocket in front of the phone's lower left |
| c5-cb-tile-2 | cb-c patch; tile replaces the red piece |
| c5-cb-tile-3 | cb-c patch; smaller tile between pawn and flag, on the red piece |

`c5-cb-compare.png` shows all of them at 256, 180 and 60 px. The tile's "K"
reads at 180 px; at 60 px it is a light square.

The user then picked **c5-cb-tile-1** and asked for a small die behind the
red piece (for future dice games). The die is drawn before the red piece, so
it is partly hidden:

| id | variant |
|---|---|
| c5-final-d1 | Small white die, 5 pips, flat, turned right |
| c5-final-d2 | Ivory die, 6 pips, with a hint of its top face (one pip) |
| c5-final-d3 | White die, 5 pips, 3D: top face (one pip) and a shaded right face |
| c5-final-d4 | Smaller ivory die, 6 pips, strongly turned, flat |

`c5-final-compare.png` shows c5-cb-tile-1 and d1–d4 at 256, 180 and 60 px.
The pips read at 180 px; at 60 px the die is a small white speck.

Feedback on the applied c5-final-d4: the motif leaves a lot of table around
it (it spans ~59 % × 69 % of the side) and "Klunki" is a blur at home-screen
size. Zoomed variants (step 1 only, not exported):

| id | variant |
|---|---|
| c5-zoom-a | d4 unchanged, only zoomed in (~74 % × 86 %); letters a little bolder (stroke on top of Roboto Bold) |
| c5-zoom-b | Bigger pocket (0.95 instead of 0.83) with a wider patch and bigger, bolder letters; all pieces; ~69 % × 86 % |
| c5-zoom-c | Like b without the green card and the die, a bigger letter tile, the biggest letters; ~68 % × 88 % |
| c5-zoom-d | No patch and no lettering (the name is under the icon anyway): a smaller plain pocket, all pieces, zoomed in furthest; ~79 % × 86 % |

`--plain-name c5-zoom` writes `c5-zoom-compare.png` (one row per icon, d4
first: 1024 px; 180/120/60/30 px plain and in the iOS mask on a light and a
dark home screen; the 66 % / 80 % safe circles; the Android adaptive icon as
the export builds it; a home-screen row and the 30 px menu header), the rows
alone as `c5-zoom-row-<id>.png`, and `c5-zoom-small.png` (all at 120/60/30 px).
The export shrinks the Android foreground until it fits the 66 dp circle, so
a bigger motif gains nothing there (scale 0.78 for d4, ~0.61–0.64 zoomed):
on Android the zoom only helps the legacy icon, and a variant is only bigger
in the adaptive icon if it is more compact (round) rather than just larger.

The pieces are clipped to "above the opening or inside the pocket", so nothing
pokes out beside the pocket below its opening. The preview sheet's first row
ends with a 180 px tile that has the safe-zone guides drawn on it: cyan for
the 66 % circle (Android adaptive) and white for the 80 % circle (PWA
maskable).

Files:

- `icon_concepts.dart`: the painters (`iconConcepts`: id → title, painter).
  Each painter draws on a 1024 grid and scales to any size.
- `icon_png.dart`: shared helpers (Roboto loading, rendering, PNG encoder
  with RGB or RGBA output).
- `export_icon_test.dart`: step 2, exports one concept in every app size
  (see below).
- `render_icons_test.dart`: renders every concept. It lives outside `test/`,
  so the normal `flutter test` run doesn't pick it up, and it is skipped
  unless `KLUNKI_ICON_OUT` is set.

## Rendering

```sh
cd klunki
KLUNKI_ICON_OUT=/tmp/icon-concepts flutter test tool/icon/render_icons_test.dart
sips -g pixelWidth -g pixelHeight -g hasAlpha /tmp/icon-concepts/*.png   # 1024, no alpha
```

The test writes, per concept:

- `concept-<id>-1024.png`: 1024 × 1024, 8-bit RGB with no alpha channel. The
  test has its own small PNG encoder because Flutter's PNG export is always
  RGBA.
- `concept-<id>-preview.png`: 180 / 120 / 60 / 40 px with no mask on grey,
  then with an iOS rounded-square mask and an Android circle mask, on a light
  and a dark home screen.

The render test only writes into `KLUNKI_ICON_OUT`. The app icon in use is
**c5-final-d4**, applied with the export below (KLD-097 step 2).

## Exporting all app sizes (step 2)

```sh
cd klunki
KLUNKI_ICON_EXPORT=/tmp/klunki-icon KLUNKI_ICON_ID=c5-final-d1 \
  flutter test tool/icon/export_icon_test.dart
```

Opt-in like the render test. Every size is drawn straight from the painter
(vector, no downscaling) into a tree that mirrors the app, so after review it
can be copied over `klunki/` (`cp -R /tmp/klunki-icon/{ios,android,web,assets} .`):

- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png`: all 15
  files the existing `Contents.json` names (20–83.5 pt, the 1024 marketing
  icon), RGB without alpha. `Contents.json` stays as it is.
- `android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/`: `ic_launcher.png`
  (48 dp, legacy, opaque), `ic_launcher_foreground.png` (108 dp, transparent)
  and `ic_launcher_background.png` (108 dp, the table), plus
  `mipmap-anydpi-v26/ic_launcher.xml` (adaptive icon). The foreground is the
  motif without the table, shrunk until every visible pixel (shadows too)
  sits inside the 66 dp safe circle; the test prints the factor (0.78 for
  c5-final-d1). The painters draw one layer at a time via `iconLayer`.
- `web/icons/Icon-{192,512}.png`, `Icon-maskable-{192,512}.png` (the motif is
  already inside the 80 % maskable circle) and `web/favicon.png` (32 px; the
  old one is 16 px).
- `store/play-store-512.png`: the Google Play listing icon (not part of the
  app; kept in `docs/store/` with the 1024 marketing PNG).
- `assets/icon/app_icon.png`: 384 px copy for the About screen
  (`KlunkiAppIcon` in `lib/ui/about_screen.dart`). The app shows this PNG
  rather than running the painter, so the painters stay in `tool/` and the
  in-app icon is pixel-identical to the home-screen icon.
- `check/android-adaptive.png`: the adaptive layers unmasked, under a circle
  and a rounded-square mask, with the 66 dp safe circle in cyan.
