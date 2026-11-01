# App icon concepts (KLD-097)

Step 1 of KLD-097: four icon concepts drawn in code, in the "Spieltisch" look
of KLD-062 (colours from `KlunkiPalette.classicLight`, pawn shape from
`lib/ui/games/chess/chess_pieces.dart`). All of them are full-bleed, opaque
squares on a warm amber table, have no text, and keep their key content inside
the central ~66 % so Android circle or squircle masks don't cut it off.

| id | concept | idea |
|---|---|---|
| a | K aus Spielsteinen | A "K": the stem is an upright Quartett card, the upper arm a yellow and a red chip, the lower leg a leaning white pawn |
| b | Kartenfächer mit Chip | A fan of three Quartett cards (blue, green, purple) with a red Four-in-a-Row chip in front |
| c | Tasche mit Spielsteinen | A stitched leather pocket ("Taschen-Spielesammlung") with a card, a pawn and a red chip peeking out |
| d | Vier-Gewinnt-K | A Four-in-a-Row board (4 × 5) whose yellow discs form a "K"; dark empty holes so the letter still reads at 40 px |

Files:

- `icon_concepts.dart`: the painters (`iconConcepts`: id → title, painter).
  Each painter draws on a 1024 grid and scales to any size.
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

Nothing is installed and no app icon is replaced. Step 2 (all platform sizes)
is described in `docs/tasks/KLD-097-app-icon.md`.
