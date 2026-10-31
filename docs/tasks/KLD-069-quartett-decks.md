# KLD-069 — Quartett decks (cars, trains, rockets, planes) and the card gallery

- **ID:** `KLD-069`
- **Title:** Themed Quartett decks of 32 cards, deck picker, view-only card gallery
- **Milestone:** M3 (content)
- **Status:** DONE
- **Depends on:** KLD-024/025 (Quartett screens), KLD-062 (card style), KLD-064 (secrecy)
- **Touched paths:**
  - `packages/klunki_engine/lib/{quartett,quartett_decks,quartett_view,registry}.dart`, `lib/debug/{debug_console,quartett_text}.dart`, `bin/klunki.dart`, `tool/quartett_ties.dart`, `test/quartett_decks_test.dart`
  - `packages/klunki_net/lib/src/{host,guest,cli/cli,secrecy/secrecy}.dart`, `PROTOCOL.md`, `test/{cli,secrecy}_test.dart`
  - `klunki/lib/ui/games/{quartett_card,quartett_pictograms,quartett_deck_picker,quartett_gallery,quartett_trumpf_screen,quartett_sets_screen}.dart`
  - `klunki/lib/ui/{engine_l10n,menu_screen}.dart`, `klunki/lib/ui/shell/screen_registry.dart`, `klunki/lib/game/game_controller.dart`
  - `klunki/lib/ui/pairing/{pairing_screen,relay_host_screen,web_join_screen}.dart`, `klunki/lib/profile/quartett_deck_settings.dart`
  - `klunki/lib/l10n/**` (one grouped `quartett*` block at the end of every ARB), `klunki/assets/fonts/NotoSansSC/**`
  - `klunki/test/ui/games/quartett_decks_test.dart`, `klunki/test/screenshots/screenshots_test.dart`, small updates to existing tests

## Goal

Quartett (Trumpf and Sets) can be played with several themed decks, each a
full classic deck of 32 cards (8 sets A–H × 4, ids `A1`…`H4`) with its own
5–6 stats. The deck is chosen before a hot-seat game and in the network host
setup, travels in the game config, and every card can be browsed offline in a
view-only gallery.

## What was built

### Engine (`packages/klunki_engine`)
- `QuartettDeck` (in `quartett_decks.dart`, part of `quartett.dart`): `id`,
  German engine `name`, `stats`, `setNames`, `cards`; `cardById`, `statById`,
  `cardsOf(set)`, `validate()` (32 cards, ids A1–H4, 8 named sets of 4, 5–6
  unique stats, every stat on every card, values ≥ 0) and `tieRate(stat)`.
  Registry `QuartettDeck.all` / `byId` (null = default `cars`).
- `Card.deck` names the card's deck (card ids repeat across decks).
- `QuartettGame(mode, {seed, handSize, deck})` works with any deck; `stats`,
  `setNames`, `cards`, `cardById`, `statById` are now instance members (they
  were static on the car deck). Trumpf splits 16/16; Sets keeps `handSize: 8`
  plus a 16-card draw pile (unchanged, all decks have 32 cards).
- `GameConfig.deck` (null = cars, so pre-KLD-069 configs keep working);
  `toJson` adds `deck` only when set, `publicJson()` is the config without the
  seed, `copyWith(seed:)`. `GameSpec.usesDeck` marks the Quartett games;
  `configProblem(config)` reports an unknown game or deck; `createGame` throws
  `ArgumentError` for an unknown deck; other games ignore `deck`.
- `QuartettGame.viewJson` carries `deck`; `QuartettView.fromJson` resolves
  the cards in that deck (absent = cars, unknown = `BadViewException`).
- Debug console / text mode: `DebugConsole(gameId, seed, deck)`,
  `new quartett-trumpf trains`, `dart run klunki_engine:klunki quartett-sets --deck rockets`;
  the title shows the deck when it is not cars ("Quartett (Sets) – Raketen").

### Network (`packages/klunki_net`)
- KLD-064 secrecy kept: the seed stays committed and hidden; the deck is public
  config: a redacted `welcome` sends `config.publicJson()` = `{game, deck?}`.
  The guest checks `configProblem`, replays the reveal with the deck
  (`verifyRedactedGame(deck: …)`), and a host that dealt from another deck
  fails the start-view check. Protocol stays v2 (an old guest ignores `deck`
  and would play cars, its verify then fails: mixed versions are not supported).
- CLI: `host <game> --deck trains` (Quartett games only; bad deck → usage,
  exit 64); host and guest print "Quartett (Sets) – Züge".

### App
- **Deck picker** (`quartett_deck_picker.dart`): tapping a Quartett tile in the
  menu opens a bottom sheet "Kartendeck wählen" with one tile per deck (small
  preview card with the deck pictogram, localized name, "32 Karten · 8 Sets à
  4 Karten"), "Karten ansehen" and "Spielen". The same `QuartettDeckChooser`
  shows under the game choice in the native host panel and the PWA relay host
  screen when a Quartett game is selected. The last choice is remembered
  (`QuartettDeckSettings`, shared_preferences key `quartettDeck`).
- **Cards**: `QuartettCard` takes the stats of the card's deck, the set name of
  that deck, and a drawn pictogram (car, high-speed train, rocket, plane;
  `QuartettPictogram` CustomPainter, set-coloured on a white badge) in the
  header; the card back shows the deck's pictogram. No images, no logos.
- **Game title** names the deck: "Quartett (Trumpf) · Züge" (both players in a
  network game see it; on narrow phones the title is ellipsized, the cards
  themselves show the deck).
- **Card gallery** (`quartett_gallery.dart`, "Karten ansehen" under the menu
  grid and in the picker): deck list → one deck with its 8 sets as sections
  (set-colour header, 4 small cards each, 2 columns on phones, 4 from 560 dp)
  → full-size card (`QuartettCard`) in a `PageView` (swipe follows the reading
  direction; previous/next buttons; "↑ höher gewinnt · ↓ niedriger gewinnt"
  legend); app bar menu "Top 5 nach Wert" ranks the deck by a stat (lower-wins
  stats ascending). Read-only, offline. Small cards have one screen-reader
  label ("Karte B3: Shinkansen N700S, Set Shinkansen").
- **l10n**: 54 keys in one block at the end of each ARB (deck names, 24 set
  names, 14 stat labels, picker and gallery texts); de is the template, the
  other six are machine translations under the existing `@@x-review` marker.
  SI units (kW, m, t, kN, km) are not translated; years and counts have no
  unit. Card names (real vehicles) stay untranslated. The Noto Sans SC subset
  was rebuilt for the new zh characters.

## The decks

All four decks: 32 cards, 8 sets of 4. A stat id means the same in every deck
(label, unit, direction), so it needs one translation.

| Deck | Sets A–H | Stats (↑ higher wins, ↓ lower wins) |
|---|---|---|
| `cars` Autos | Supersportwagen, Hypercars, Klassiker, Muscle Cars, Rallye-Legenden, Gran Turismo, Elektro, Kleine Flitzer | Leistung PS ↑, Höchstgeschwindigkeit km/h ↑, Hubraum cm³ ↑, Gewicht kg ↓, 0–100 km/h s ↓ |
| `trains` Züge | ICE, Shinkansen, TGV, Europas Schnelle, Asien & Amerika, E-Loks, Dampf-Legenden, Güter-Riesen | Höchstgeschwindigkeit km/h ↑, Leistung kW ↑, Länge m ↑, Gewicht t ↓, Anfahrzugkraft kN ↑, In Betrieb seit ↑ |
| `rockets` Raketen | Mondraketen, Wiederverwendbar, Europa, USA-Klassiker, Russland, China, Japan & Indien, Kleine Träger | Höhe m ↑, Startschub kN ↑, Nutzlast (LEO) t ↑, Startmasse t ↑, Starts ↑, Erstflug ↓ |
| `planes` Flugzeuge | Großraumjets, Mittelstrecke, Überschall, Propeller-Klassiker, Frachtriesen, Business & Sport, Pioniere, Rekord-Exoten | Höchstgeschwindigkeit km/h ↑, Reichweite km ↑, Länge m ↑, Spannweite m ↑, Startgewicht t ↑, Erstflug ↓ |

Cards (A1–H4 in set order):
- **Trains:** ICE 1, ICE T, ICE 3, ICE 4 · Shinkansen 0, 300, N700S, E5 · TGV Sud-Est, TGV Atlantique, TGV Duplex, TGV V150 · Eurostar e320, AVE S-103, Frecciarossa 1000, Talgo 350 · Fuxing CR400AF, KTX-Sancheon, Shanghai Transrapid, Acela (Avelia Liberty) · Baureihe 103, Baureihe 101, SBB Re 460, Siemens Taurus ES64U4 · Flying Scotsman, Mallard, DR 18 201, Big Boy · SBB Krokodil, EMD SD70ACe, GE AC6000CW, Class 66
- **Rockets:** Saturn V, Saturn IB, SLS Block 1, N1 · Falcon 9, Falcon Heavy, Starship, New Glenn · Ariane 5, Ariane 6 (A64), Vega C, Ariane 4 · Atlas V, Delta IV Heavy, Space Shuttle, Titan IV B · Sojus-U, Proton-M, Angara A5, Energija · Langer Marsch 5, 2F, 3B, 2C · H3, H-IIB, PSLV, LVM3 · Electron, Pegasus XL, Firefly Alpha, Epsilon
- **Planes:** A380-800, 747-8I, 777-300ER, A350-900 · A320neo, 737 MAX 8, A220-300, E195-E2 · Concorde, Tu-144, SR-71, X-15 · DC-3, Ju 52/3m, Super Constellation, Dash 8-400 · An-225, An-124, 747 Dreamlifter, Beluga XL · Cessna 172, Learjet 75, Gulfstream G650, Pilatus PC-12 · Wright Flyer, Blériot XI, Spirit of St. Louis, Junkers F 13 · Solar Impulse 2, Hughes H-4 Hercules, Stratolaunch Roc, Rutan Voyager

## Data caveats (approximate, unverified)

The new decks use **plausible, rounded values from general knowledge, not
checked against sources**; treat every train, rocket and plane value as
approximate. In particular:
- **Trains:** service top speed, except the record/design speeds of TGV V150
  (575), Siemens Taurus (357 record), Shanghai Transrapid (431). Length/mass
  are per unit as commonly built (locomotive only for locos, steam with
  tender). The starting tractive effort of multiple units is an estimate.
  "Anfahrzugkraft" replaces the brief's "Sitzplätze": locomotives have no
  seats (8 cards with 0 would tie constantly).
- **Rockets:** the most common or most powerful configuration (e.g. Atlas V
  5xx, Ariane 5 ECA, LM-3B); payload to LEO is approximate for rockets usually
  quoted to GTO/SSO (H3, Ariane 4, Electron). "Starts" are rough counts as of
  about 2025 (Falcon 9 ≈ 550, Sojus-U 786, Starship 11, New Glenn 2) and go
  stale. "Starts" replaces the brief's "Stufen" (most rockets have 2–3 stages:
  ties in ~40 % of pairs).
- **Planes:** maximum or maximum-cruise speed as commonly quoted; record
  aircraft show their record range (Rutan Voyager 42 212 km, Solar Impulse 2's
  longest leg); Wright Flyer "range" is its first flight (0.3 km).
- **Cars:** unchanged from KLD-024.
- Values are numbers only; the engine never derives anything from them, so a
  correction is a one-line data change (the replay of old games would change,
  which only matters for games in progress during an update).

## Tie rates (Trumpf)

Share of card pairs (of 496) with equal values per stat, from
`dart run packages/klunki_engine/tool/quartett_ties.dart`; the engine test
requires < 3 % per stat for every deck.

| Deck | Ties per stat |
|---|---|
| cars | ps 0.8 %, kmh 2.2 %, ccm 2.2 % (the 5 electric cars at 0), kg 0.2 %, sec0to100 2.4 % |
| trains | kmh 1.8 %, kw 2.0 % (four 8800 kW trainsets), lengthM 0 %, massT 0 %, tractiveKn 0.6 %, inService 1.0 % |
| rockets | heightM 0.6 %, thrustKn 0.2 %, leoT 0 %, launchMassT 0.2 %, flights 1.8 %, firstFlight 0.8 % |
| planes | kmh 0 %, rangeKm 0.8 %, lengthM 0 %, wingspanM 0 %, mtowT 0.2 %, firstFlight 0.2 % |

## How to add a deck

1. Engine: in `quartett_decks.dart` write `QuartettDeck _ships() => QuartettDeck.build(id: 'ships', name: 'Schiffe', stats: […], setNames: {'A': …}, rows: [('A1', 'Name', [v1, v2, …]), …])`
   with 32 rows in stat order; reuse a stat constant when the meaning is the
   same (`_kmh`, `_lengthM`, `_firstFlight`), otherwise use a new id. Add it to
   `QuartettDeck.all`. Note the data caveats in the comment above it.
2. Run `dart test` in `packages/klunki_engine` (validation, tie rate < 3 %,
   full games) and `dart run tool/quartett_ties.dart`.
3. App: add `quartettDeck<Name>`, `quartettSet<Name>A`…`H` and any new
   `quartettStat*` keys to all 7 ARB files (de with descriptions), run
   `flutter gen-l10n`, map them in `engine_l10n.dart`
   (`localizedDeckName`, `localizedSetName`, `localizedStatLabel`); new zh
   characters: `python3 -I tool/update_web_fonts.py subset`.
4. Draw a pictogram in `QuartettPictogram` (100 × 60 box) and give the deck a
   preview colour (`_previewSet` in `quartett_deck_picker.dart`).
5. `flutter test` (the deck tests loop over `QuartettDeck.all`).

## Follow-ups (ideas)
- More decks: **ships** (container ships, liners, sailing ships, submarines),
  **animals** (speed, weight, lifespan, …), **dinosaurs**, **planets/moons**.
- A source check of the train, rocket and plane values (and a "Stand" date for
  the launch counts).
- A deck badge in the network join screen before the game starts (today the
  guest learns the deck when the game screen opens).

## Tests
- Engine: `test/quartett_decks_test.dart` (registry, one meaning per stat id,
  validation, tie rates, 25 random games per deck and mode, views and
  `createGame` with decks, config round trip, unknown decks, debug console).
- Net: `secrecy_test.dart` (every deck × mode over loopback: deck public, seed
  secret, verified; a swapped deck fails), `cli_test.dart` (`--deck`).
- App: `test/ui/games/quartett_decks_test.dart` (picker, remembered choice,
  a card per deck in de/en, gallery list/sets/pager/swipe/Top 5, RTL/zh/tablet
  smoke, relay host deck choice), `pairing_flow_test.dart` (host picks
  rockets, guest plays the rocket deck), screenshots `kld069 *` in
  `test/screenshots`.
