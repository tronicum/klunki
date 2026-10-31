# KLD-062: Visual baseline ("Spieltisch" look)

- **ID:** `KLD-062`
- **Title:** Basic visual design beyond "text on white": theme, menu tiles, boards, small motion
- **Priority:** medium
- **Status:** DONE
- **Depends on:** none
- **Touched paths:**
  - `klunki/lib/app/theme.dart` (theme, presets, palette)
  - `klunki/lib/ui/game_visuals.dart`, `klunki/lib/ui/game_illustrations.dart` (new)
  - `klunki/lib/ui/menu_screen.dart`, `klunki/lib/ui/shell/game_screen.dart`
  - `klunki/lib/ui/games/connect4/connect4_board.dart`, `muehle/muehle_board.dart`, `muehle/muehle_painter.dart`,
    `schiffe/schiffe_grid.dart`, `quartett_card.dart`, `quartett_sets_screen.dart`, `quartett_trumpf_screen.dart`
  - `klunki/lib/l10n/*.arb` (9 keys, one block right after `menuGameSchiffe`)
  - `klunki/test/app/theme_test.dart` (new), `klunki/test/screenshots/screenshots_test.dart` (new, skipped by default),
    `klunki/test/widget_test.dart`, `klunki/test/l10n/coverage_test.dart` (scroll a tile into view first)

## Goal
A friendly, warm, family-board-game look ("game table"): soft paper background instead of white, rounded cards, a
colour per game, drawn illustrations in the menu, boards that look like the real thing, light and dark following the
system setting. Everything drawn in code: no image assets, no new fonts, no network fetches (the PWA stays offline).

## What was done

### Theme structure (ready for selectable themes, KLD-063)
- `KlunkiPreset` = id + seed colour + light and dark `KlunkiPalette`. `KlunkiPreset.classic` ("Spieltisch") is the only
  preset; `KlunkiPreset.all` is what a picker would list. `KlunkiTheme.build(preset, brightness)` makes the `ThemeData`
  (`ColorScheme.fromSeed`, bundled fonts via `withAppFonts` as before). `KlunkiTheme.light/dark` = classic.
- `KlunkiPalette` is a `ThemeExtension`: background gradient, card colour, trophy colour, per-game `GameAccent`s
  (`color` for the app bar/tile stripe, `onColor` for its text, `container` for the tile header, `onSurface(b)` for icons on
  cards) and the board materials `Connect4Palette`, `MuehlePalette`, `SchiffePalette`, `QuartettPalette`. Widgets read
  `KlunkiPalette.of(context)`; without the extension (bare `MaterialApp` in tests) it falls back to the classic preset.
  No board colour is hard-coded in a widget any more (`Connect4Colors.of`, `quartettSetColor`, `quartettOutcomeColor`
  now read the palette; the latter two default to the classic light palette when called without one).
- Components: cards radius 16, dialogs 24, buttons 14 with min height 48, chips/inputs 12; app bars without tint.
- Page transitions: fade-forwards (Android/web/desktop), Cupertino (iOS/macOS); with reduced motion
  (`MediaQuery.disableAnimations`) pages appear without transition.

### Palette (classic)
| | Light | Dark |
|---|---|---|
| Seed | `#C9772B` (warm amber) | same |
| Page | `#FBF4E8`, gradient `#FDF8EF` → `#F3E4CB` (cream paper) | `#1F1A16`, gradient `#26201B` → `#17130F` (walnut table) |
| Card | `#FFFCF6` | `#2E2721` |
| Trophy | `#C98A00` | `#FFC233` |

Per-game accents (`color` with white text / tile `container`):

| Game | Light | Dark |
|---|---|---|
| 4 Gewinnt (`connect4`) | `#1C5DB8` / `#D6E4FA` | `#184C96` / `#1E2C44` |
| Mühle (`muehle`) | `#8A5527` / `#F1DEC4` | `#6E4320` / `#3A2C1F` |
| Quartett Trumpf (`quartett-trumpf`) | `#B3261E` / `#F9DAD5` | `#9A2A22` / `#42221F` |
| Quartett Sets (`quartett-sets`) | `#6E3C96` / `#EADCF5` | `#5E3382` / `#33243F` |
| Schiffe (`schiffe`) | `#00707A` / `#CCEDEF` | `#00636B` / `#18363A` |
| Network entry | `#8C4A00` / `#FFE0C2` | `#7A4100` / `#3F2C1A` |
| Unknown game (default) | `#5D5A52` / `#E8E2D6` | `#4F4B44` / `#34302B` |

Boards: 4 Gewinnt blue frame `#1C5DB8`, red `#D32F2F`, yellow `#FFC107`; Mühle wood `#E2BC7E`/`#F0D3A0` with grain
`#9C6A35` and lines `#4E3016`; Schiffe water `#BFE0F2` (dark `#1D4E6E`), grid `#7FB3D3`, ship slate `#55606B`,
hit `#C62828` on `#FFCDD2`, sunk `#8E1B1B`; Quartett set headers A–H (white text AA; D and G darkened slightly for AA).
`test/app/theme_test.dart` checks the contrasts (accent text ≥ 4.5:1, icons/non-text ≥ 3:1) for every preset and brightness.

### Menu
- Header with a drawn logo (three pieces) + "Klunki", headline "Wähle ein Spiel", section labels
  "Zu zweit an einem Gerät" / "Mit zwei Geräten".
- Game tiles in eager rows (2 columns on phones, up to 5 on wide screens, tiles of a row share the height): drawn
  illustration on the accent (`CustomPainter`s in `game_illustrations.dart`: discs in a blue frame, wooden mill board
  with stones, fanned cards with set headers, sea grid with ship, hit and misses), title, one-line description,
  an eye-off badge + "Gerät weitergeben" for hidden-information games, chevron. Keys `menu-<id>` unchanged.
- Network entry as its own card (`menu-network`) with a round Wi-Fi badge and "Spiel hosten oder beitreten".
- The Debug-Konsole is a small text button under everything (still hidden in release).

### Game shell
- App bar in the game's accent colour.
- Paper/table gradient behind the board.
- Status line as a pill with the **player token** (`PlayerToken`: red/yellow disc in 4 Gewinnt, light/dark stone in
  Mühle, accent-coloured X/O disc elsewhere, always with the mark); the pill's tint animates on turn change
  (instant with reduced motion); trophy when won. `shell-status`/`shell-hint` keep their keys and are now
  `liveRegion`s.
- Result dialog with a trophy + winner token (handshake icon for a draw).

### Boards
- 4 Gewinnt: gradient blue frame with a lower edge shadow, recessed holes, shaded discs with a drop shadow; O pieces
  carry an embossed inner ring (not colour-only). The drop animation is skipped with reduced motion.
- Mühle: wood panel with grain and bevel, inlaid points, shaded stones from the palette; the mill highlight is steady
  instead of pulsing with reduced motion.
- Schiffe: water-blue cells with grid lines and a framed grid; slate ships, misses as white splash dots, hits as a red
  cross on light red, sunk as dark red with a white cross.
- Quartett: card face in the card colour, header gradient per set, diamond-lattice card back in warm brown;
  highlighted stat row as before (set colour or win/lose/tie).

### Strings (all 7 ARB files, one block after `menuGameSchiffe`)
`menuDescConnect4`, `menuDescMuehle`, `menuDescQuartettTrumpf`, `menuDescQuartettSets`, `menuDescSchiffe`,
`menuSectionHotSeat`, `menuSectionNetwork`, `menuNetworkSubtitle`, `menuHiddenInfo`. fr/es/zh/ar/fa are machine
translations (files already flagged `@@x-review`). The zh texts were worded with characters already in the bundled
Noto Sans SC subset, so no subset rebuild (no download) was needed.

### Adding a game (e.g. GoStrategy)
1. `gameVisuals` in `klunki/lib/ui/game_visuals.dart`: illustration painter, description getter, optional token colours.
2. An accent per palette in `klunki/lib/app/theme.dart` (a commented example sits in `classicLight.accents`).
3. A `menuDesc<Game>` string. Without 1–2 the game still works: default accent and a die illustration.

## Verification
- `flutter analyze`: no issues. `flutter test`: 441 passed, 34 skipped (the screenshot captures).
- Screenshots: `KLUNKI_SHOTS=<dir> flutter test test/screenshots` renders menu, every game mid-game, the result dialog
  and pairing in light/dark at phone (390×844) and tablet (1180×820) size plus Arabic, with the real bundled fonts.
- PWA: `flutter build web --release` + `pwa_finalize.py`, `tool/pwa_i18n_check.sh <url> <out> offline`: PASS for all
  7 languages, no external requests.

## Follow-ups
- KLD-063 selectable themes (presets + picker in settings, persisted via `shared_preferences`).
- KLD-066 start/welcome screen (reuses `KlunkiLogo` from `menu_screen.dart` and the palette background).
- Pairing, join and relay screens only got the theme (colours, shapes, background colour); a dedicated visual pass
  (illustrated host/join choice, room code card) is open.
- Handover cover could use the game accent and a drawn "pass the device" illustration.
- Rules sheet per game (UX-REVIEW 1.1, second half) and the remaining quick wins (start cover, leave confirmation,
  "Ansehen" in the result dialog, invalid-tap feedback, haptics).
- Mühle panels still use the theme primary for the active border; could use the game accent.
- Last-move highlight exists for 4 Gewinnt only; Mühle/Schiffe could mark the last move too.
