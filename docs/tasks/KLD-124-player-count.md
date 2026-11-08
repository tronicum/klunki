# KLD-124: Player count on the menu tiles and rules pages

- **ID:** `KLD-124`
- **Title:** Player count on the menu tiles and rules pages
- **Milestone:** M5 (polish)
- **Status:** DONE
- **Depends on:** KLD-119 (first game for 2–4), KLD-123 (rules pages)
- **Touched paths:**
  - `klunki/lib/ui/player_count_chip.dart` (new)
  - `klunki/lib/ui/menu_screen.dart`, `klunki/lib/ui/rules/rules_screen.dart`, `klunki/lib/ui/shell/screen_registry.dart`
  - `klunki/lib/l10n/**` (`playerCount`, `playerCountRange`)
  - `klunki/test/ui/player_count_test.dart`, `klunki/test/screenshots/player_count_shots_test.dart`

## Goal
Maintainer decision 2026-11-08: show how many players a game supports, board-game-box style. Every menu
tile and every rules page carries a small chip with a people icon and the count: "2", or "2–4" for
Ausgewürfelt (later "2–6" for the property game). Icon and number only: no play time, no network icon.

## Design
- **Source of truth:** the engine registry. `offeredPlayers(spec)` (next to `seatGames` in
  `screen_registry.dart`) is `GameSpec.minPlayers`–`GameSpec.maxPlayers` for the games the app plays in the seat
  shell (`seatGames`), and exactly `minPlayers` for the others. Wortgewandt has 4 seats in the engine but the
  app offers 2 so far, so its chip says "2"; adding a game to `seatGames` changes its chip by itself.
- **Chip** (`PlayerCountChip`): `Icons.people_alt_outlined` + bold number in a pill (surface colour at 88 %,
  outline-variant border), so it reads on every accent in light and dark. The range uses an en dash; the
  number is laid out LTR, so "2–4" does not become "4–2" in ar/fa.
- **Placement:** top end corner of the tile's illustration (top right, top left in RTL), like the badge on a
  game box: it never competes with the title, the play links or "Regeln". The rules page shows the same chip
  in the same corner of its illustration banner.
- **Screen readers:** the chip's label replaces its text: "2 Spieler" / "2 bis 4 Spieler" (ICU plural in
  de/en/fr/es/ar). On the tile it is merged into the tile's button label, read before the title.

## Acceptance criteria
- [x] Every tile shows the count from the registry (widget test over `appGameSpecs`); Ausgewürfelt "2–4".
- [x] Rules page header shows the same chip for every game with a rules page.
- [x] ar: the range stays "2–4", chip in the top-left corner, Arabic label.
- [x] Text scale 1.3 on a small phone: no overflow.
- [x] 7 locales; no new zh characters (名, 玩, 家, 到 were already in the font subset).
- [x] Screenshots: menu phone light/dark/ar, iPhone SE at 1.3, rules page header (de light, dark, ar):
      `KLUNKI_SHOTS=/tmp/shots flutter test test/screenshots/player_count_shots_test.dart` (into `kld124/`).
