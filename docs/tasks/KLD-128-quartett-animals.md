# KLD-128: Quartett deck "Tiere" (animals)

- **ID:** `KLD-128`
- **Title:** A fifth Quartett deck, "Tiere": 32 animals with sourced values and translated names
- **Milestone:** M3
- **Status:** DONE (photos and the Chinese font subset pending, see "Open")
- **Depends on:** KLD-069 (decks), KLD-069b (more decks), KLD-082/084 (photo pipeline), KLD-085 (fingerprint),
  KLD-092 (hyphenated labels), KLD-110 (number grouping)
- **Touched paths:**
  - `packages/klunki_engine/lib/quartett_decks.dart` (deck `animals`), engine tests, `compat_test.dart` goldens
  - `klunki/lib/ui/engine_l10n.dart` (`localizedCardName`, set / deck / stat / unit names)
  - `klunki/lib/ui/games/{quartett_card,quartett_gallery,quartett_sets_screen,quartett_media,quartett_deck_picker,quartett_pictograms}.dart`
  - `klunki/lib/l10n/**` (45 keys × 7 locales), `klunki/tool/card_media/animals.json`
  - `klunki/test/ui/games/quartett_decks_test.dart`, `klunki/test/l10n/{translations,coverage}_test.dart`,
    `klunki/test/screenshots/quartett_animals_shots_test.dart`

## Goal
A Quartett deck about animals for the families and kids who play Klunki: 32 cards in 8 sets (Raubkatzen, Bären,
Affen, Savanne, Wale & Delfine, Haie, Vögel, Reptilien), 5 stats, every value from a named source and cautious
where the sources disagree. Unlike the vehicle decks the card names are translated into all 7 languages.
Basis: the maintainer-approved proposal "Deck Tiere", revision 2 (2026-11-15), with the maintainer's decisions:

- weight and length are means of both sexes; weight from AnAge;
- stat "Lebenserwartung" (typical lifespan, wild where known, else in human care);
- label "Tragzeit / Brutzeit" with spaces around the slash and soft hyphens;
- cautious, sourced values;
- swaps: Jaguar → Leopard, Großer Hammerhai → Blauhai (revision 2), and **Große Anakonda → Schwarze Mamba**
  (2026-11-15: the mamba has a sourced speed, the anaconda had only one comparison site).

## Acceptance criteria
- [x] Engine deck `animals` (name "Tiere", revision 1), 5 stats, all higher-wins: `weightKg` (new id, kg, 1 decimal;
      the cars' `kg` wins low, so one id = one meaning), `lengthM` (shared), `kmh` (same id/label/unit/direction as
      the vehicle decks, 1 decimal for 0.3 and 22.5 km/h), `lifeYears` (Jahre), `gestationD` (Tage).
- [x] Validation and tie rates pass (< 3 %, > 16 distinct values per stat); compat goldens for
      `quartett-trumpf/animals` and `quartett-sets/animals`; the other decks' fingerprints are unchanged.
- [x] Card names, set names, deck name, stat labels and units ("Jahre", "Tage") in all 7 locales.
      `localizedCardName` (by deck and card id) is used wherever a name is shown: card header, gallery grid,
      Top 5 list, gallery semantics, Sets hand, photo credits list. Vehicle names stay untranslated.
- [x] Display names never reach gameplay: the engine keeps the German name (fingerprint, views and moves use
      card ids and engine data); the German ARB names equal the engine names (test).
- [x] Long names break only at soft hyphens with a visible hyphen (`QuartettCardName` → `HyphenatedLabel`):
      "Wander-/albatros" on a 320 px phone, never "Wande/ralba…".
- [x] Drawn pictogram (an elephant, side view) on every card without a photo; the deck picker gives the fifth deck
      its own preview colour (orange, set D).
- [x] No photos yet: the cards show the pictogram exactly like the decks before KLD-082. The media list is
      prepared in `klunki/tool/card_media/animals.json` (de/en Wikipedia article per animal).
- [x] Screenshots `kld128` (picker, gallery, full card, Trumpf comparison, en and ar cards).

## The cards

Weight, length, speed, lifespan, gestation/incubation (engine order):

| Card | Set | Tier | kg | m | km/h | Jahre | Tage |
|---|---|---|---|---|---|---|---|
| A1 | Raubkatzen | Gepard | 54 | 2.0 | 104 | 9 | 88 |
| A2 | Raubkatzen | Löwe | 175 | 2.7 | 74 | 14 | 109 |
| A3 | Raubkatzen | Tiger | 120 | 3.0 | 56 | 9 | 105 |
| A4 | Raubkatzen | Leopard | 54 | 2.2 | 58 | 15 | 97 |
| B1 | Bären | Eisbär | 475 | 2.1 | 40 | 28 | 245 |
| B2 | Bären | Braunbär | 278 | 2.0 | 48 | 25 | 225 |
| B3 | Bären | Großer Panda | 118 | 1.6 | 32 ⚠ | 13 | 130 |
| B4 | Bären | Malaienbär | 46 | 1.4 | 30 ⚠ | 20 (care) | 95 ⚠ |
| C1 | Affen | Gorilla | 140 | 1.5 | 32 ⚠ | 38 | 256 |
| C2 | Affen | Orang-Utan | 64 | 1.3 | 5 ⚠ | 40 | 249 |
| C3 | Affen | Schimpanse | 45 | 1.5 | 35 ⚠ | 33 | 229 |
| C4 | Affen | Weißhandgibbon | 6.8 | 0.5 | 55 ⚠ | 30 | 217 |
| D1 | Savanne | Afrikanischer Elefant | 4800 | 8.0 | 24 | 65 | 670 |
| D2 | Savanne | Giraffe | 800 | 5.2 | 60 | 13 | 457 |
| D3 | Savanne | Flusspferd | 3750 | 3.6 | 30 | 45 | 234 |
| D4 | Savanne | Breitmaulnashorn | 2175 | 4.2 | 40 | 41 | 515 |
| E1 | Wale & Delfine | Blauwal | 136000 | 26.0 | 48 | 85 | 350 |
| E2 | Wale & Delfine | Grönlandwal | 100000 | 16.0 | 23 | 100 ⚠ | 396 |
| E3 | Wale & Delfine | Orca | 3988 | 7.5 | 56 | 50 | 435 |
| E4 | Wale & Delfine | Großer Tümmler | 200 | 3.1 | 35 | 25 | 365 |
| F1 | Haie | Weißer Hai | 1870 | 4.2 | 24 | 30 | 365 |
| F2 | Haie | Tigerhai | 444 | 3.8 | 32 ⚠ | 27 | 440 |
| F3 | Haie | Blauhai | 113 | 2.5 | 39 ⚠ | 16 | 320 |
| F4 | Haie | Kurzflossen-Mako | 278 | 3.5 | 50 ⚠ | 31 | 500 |
| G1 | Vögel | Strauß | 111 | 2.1 | 70 | 35 ⚠ | 40 |
| G2 | Vögel | Wanderfalke | 0.8 | 0.5 | 290 | 13 | 30 |
| G3 | Vögel | Kaiserpinguin | 30 | 1.2 | 20 | 20 | 65 |
| G4 | Vögel | Wanderalbatros | 7.0 | 1.2 | 135 ⚠ | 35 | 78 |
| H1 | Reptilien | Leistenkrokodil | 200 | 3.6 | 29 | 70 ⚠ | 90 |
| H2 | Reptilien | Komodowaran | 87 | 2.4 | 20 | 30 | 230 |
| H3 | Reptilien | Aldabra-Riesenschildkröte | 117 | 1.1 | 0.3 ⚠ | 100 ⚠ | 240 ⚠ |
| H4 | Reptilien | Schwarze Mamba | 1.0 | 2.5 | 22.5 | 10 (care) | 85 |

⚠ = popular figure only (cautious lower end) or conflicting sources; details in the proposal, section 4.

**Tie rates** (`dart test test/quartett_decks_test.dart`, 496 card pairs): weight 0.60 % (3 pairs: Gepard/Leopard 54,
Braunbär/Mako 278, Tümmler/Krokodil 200), length 1.61 % (8), top speed 2.02 % (10), lifespan 2.22 % (11),
gestation 0.20 % (1: Tümmler/Weißer Hai 365). Distinct values: 29, 24, 23, 23, 31. The mamba swap keeps every
rate: its length 2.5 ties the Blauhai where the anaconda's 3.8 tied the Tigerhai; 22.5 km/h and 10 years are unique.

## Sources

Data rule: weight and gestation from **AnAge** (Human Ageing Genomic Resources,
`https://genomics.senescence.info/species/entry.php?species=<Genus_species>`); lifespan and length from **Animal
Diversity Web** (`https://animaldiversity.org/accounts/<Genus_species>/`), zoo and agency pages (Smithsonian
National Zoo, NOAA, NT Government) or Wikipedia with a primary source. Speed: the highest value a reliable source
gives as measured or as a firm figure; popular figures only as the cautious lower end. Gestation months × 30.4,
rounded to 5 days. All sources are web pages.

| Card | Species | Length | km/h | Lifespan | Other |
|---|---|---|---|---|---|
| A1 | *Acinonyx jubatus* | WP Cheetah: HBL 1.1–1.5 + tail 0.6–0.8 | Sharp 1997, 104 (WP); Wilson et al. 2013 (GPS) 93 | Smithsonian: wild 8–10 | |
| A2 | *Panthera leo* | WP Lion (West 2013) | GPS collars 2018, 74.1 (WP Fastest animals) | ADW: mean wild 14 | |
| A3 | *Panthera tigris* | WP Tiger | Schaller 1967, Thapar 2004: 56 | ADW: 8–10 wild | |
| A4 | *Panthera pardus* | WP Leopard: HBL 0.92–1.83 + tail | Sunquist & Sunquist: over 58 | WP: 12–17 | AnAge 53.75 kg, 97 d |
| B1 | *Ursus maritimus* | ADW / WP | WP: up to 40 | ADW: 25–30 wild | WP (Derocher 2012) 7–9 months |
| B2 | *Ursus arctos* | WP / ADW | Yellowstone 48 (56 anecdotal) | WP: mean 25 | AnAge 103 d + delayed implantation |
| B3 | *Ailuropoda melanoleuca* | WP: 1.2–1.9 | ⚠ popular ~32 | ADW: wild 10–15 | AnAge 97–163 |
| B4 | *Helarctos malayanus* | ADW: 1.2–1.5 | ⚠ popular 30–48 → 30 | WP: care "over 20" | AnAge 95 (WP 95–240) |
| C1 | *Gorilla gorilla* | ADW: ♂ 1.75, ♀ 1.25 standing | ⚠ popular 32–40 | ADW: 35–40 wild | |
| C2 | *Pongo pygmaeus* | WP (Wood 1977) | ⚠ popular 5–8 → 5 | WP (Locke et al. 2011): 35–45 | |
| C3 | *Pan troglodytes* | WP (Braccini 2010): 1.50 | ⚠ popular 35–48 → 35 | WP: Ngogo "nearly 33" | |
| C4 | *Hylobates lar* | ADW: 0.42–0.58 | ⚠ WP up to 55 | ADW: mean 30 wild | |
| D1 | *Loxodonta africana* | de.WP: HBL with trunk 6.0–7.5 + tail | ADW: up to 24 | ADW: 60–70 wild | |
| D2 | *Giraffa camelopardalis* | ADW: 4.7–5.7 | Schaller 1976: 50–60 | ADW: 10–15 wild | |
| D3 | *Hippopotamus amphibius* | ADW: 2.09–5.05 | ADW: up to 30 | ADW table: wild 45 | |
| D4 | *Ceratotherium simum* | ADW: HBL + tail | ADW: up to 40 | ADW: 39–43 wild | |
| E1 | *Balaenoptera musculus* | ADW: ♂ 25, ♀ 27 | ADW: 48 if alarmed | ADW: 80–90 | |
| E2 | *Balaena mysticetus* | WP / ADW: 14–18 | Ford & Reeves 2008, satellite tag 22.7 | ⚠ NOAA "over 200", cautious 100 | |
| E3 | *Orcinus orca* | ADW: ♂ 8, ♀ 7 | Fish & Fisher: 56 | ADW: wild ♀ 63, ♂ 36 | |
| E4 | *Tursiops truncatus* | ADW | Fish & Fisher: 30–35 | ADW: mean wild 25 | |
| F1 | *Carcharodon carcharias* | WP: length at maturity | WP: sprint 24.12 | ADW: ~30 | WP: ~12 months |
| F2 | *Galeocerdo cuvier* | ADW: 3.25–4.25 | ⚠ ADW data field 8.88 m/s | ADW: mean 27 wild | ADW 13–16 months |
| F3 | *Prionace glauca* | WP: ♂ 1.8–2.8, ♀ 2.2–3.3 | ⚠ ReefQuest 39.4 | ADW: 15–16 wild | AnAge 113 kg; ADW 9–12 months |
| F4 | *Isurus oxyrinchus* | ADW: 3.2–3.8 | ⚠ WP Fastest animals 50 | ADW: 29–32 | WP/ADW 15–18 months |
| G1 | *Struthio camelus* | WP: ♂ 2.1–2.75, ♀ 1.75–1.9 | WP (Davies 2002): ~70 | ⚠ zoo sheets 30–40 | WP (Perrins) 35–45 d |
| G2 | *Falco peregrinus* | ADW | ADW: dive over 180 mph = 290 | ADW: mean 13 | |
| G3 | *Aptenodytes forsteri* | ADW: 1.01–1.32 | ADW: up to 20 | WP (Mougin & van Beveren 1979): 19.9 | ADW 65 d |
| G4 | *Diomedea exulans* | ADW: 1.1–1.35 | ⚠ WP (Barwell 2013): 135 | ADW: mean wild 35 | ADW mean 78 d |
| H1 | *Crocodylus porosus* | WP: ♂ 4.0–4.5, ♀ 2.7–3.1 | NT Government: 24–29 bursts | ⚠ WP (Britton et al. 2012): 70+ | ADW 90 d |
| H2 | *Varanus komodoensis* | WP (Guinness): ♂ 2.59, ♀ 2.29 | WP (Burnie & Wilson 2001): 20 | WP (Ciofi 2004): up to 30 | WP 7–8 months |
| H3 | *Aldabrachelys gigantea* | Smithsonian: shell ♂ 1.22, ♀ 0.91 | ⚠ popular 0.3–0.5 | ⚠ Smithsonian "more than 100" | WP (Stearns 2007) ~8 months |
| H4 | *Dendroaspis polylepis* | ADW: average 2.2–2.7 → 2.5 | Spawls, Howell, Drewes & Ashe 2017, *A Field Guide to the Reptiles of East Africa*, 2nd ed.: 22.53 (WP Fastest animals) | ADW: mean of females in care 10.1 (Max Planck Institute for Demographic Research) → 10 | weight see below; AnAge 85 d, ADW 80–90 d |

**Schwarze Mamba (H4), how the values were chosen** (checked 2026-11-15):
- Weight **1.0 kg**: AnAge lists 30,758 g without a source or quality note, about 20 times what every other
  source says, so it is treated as a data error. Wikipedia "Black mamba" cites a measured mean of seven snakes,
  1.03 kg (Branch, Haagner & Shine 1995); National Geographic gives about 1.6 kg. The measured mean is used.
- Length **2.5 m**: ADW, "average length of 2.2 to 2.7 m" (adults 2–3 m).
- Speed **22.5 km/h**: Wikipedia "Fastest animals", 22.53 km/h, citing Spawls et al. 2017 pp. 1201–1202 (the
  proposal's value). ADW and Wikipedia "Black mamba" say "up to 20 km/h".
- Lifespan **10 years** (in care): ADW, average lifespan of females in captivity 10.1 years (MPIDR); nothing is
  known about the wild. AnAge's 26.2 years is a captive maximum, not typical.
- Incubation **85 days**: AnAge 85 days; ADW 80–90 days ("2 to 3 months").

URLs: https://genomics.senescence.info/species/entry.php?species=Dendroaspis_polylepis ·
https://animaldiversity.org/accounts/Dendroaspis_polylepis/ · https://en.wikipedia.org/wiki/Black_mamba ·
https://en.wikipedia.org/wiki/Fastest_animals

## Translations
45 keys per locale: `quartettDeckAnimals`, `quartettSetAnimalsA`–`H`, `quartettAnimalA1`–`H4`,
`quartettStatLifeYears`, `quartettStatGestationD`, `quartettUnitYears`, `quartettUnitDays`. "Gewicht" and "kg"
reuse the car deck's `engineStatKg` / `engineUnitKg`. Animal names are the common names in each language (zh:
猎豹, 狮子, 老虎, 花豹, 北极熊, 棕熊, 大熊猫, 马来熊, 大猩猩, 红毛猩猩, 黑猩猩, 白掌长臂猿, 非洲象, 长颈鹿, 河马, 白犀牛,
蓝鲸, 弓头鲸, 虎鲸, 宽吻海豚, 大白鲨, 鼬鲨, 大青鲨, 尖吻鲭鲨, 鸵鸟, 游隼, 帝企鹅, 漂泊信天翁, 湾鳄, 科莫多巨蜥, 亚达伯拉象龟,
黑曼巴蛇). Machine translation like the rest of the non-German locales; a native-speaker review is still open.
Long names carry soft hyphens (de "Wander­albatros", "Breit­maul­nas­horn", en "Hippo­potamus", fr "Rhino­céros
blanc", es "Hipo­pótamo"); the card breaks only there.

## Decisions in the code
- **Display only.** `localizedCardName(l10n, card)` switches on `card.deck` and `card.id`; the engine card keeps its
  German name, which is part of `deckGameplayData` (fingerprint). A guest and a host in different languages play
  the same deck and see their own names; nothing in the protocol changes.
- **Gallery grid** (`IntrinsicHeight` rows cannot measure `HyphenatedLabel`): plain `Text` with the soft hyphens as
  break chances (no visible hyphen there).
- **Deck picker**: tiles a little flatter (preview 32 px, padding 4) so five decks and "Spielen" fit a 360×640
  phone; the l10n walk scrolls to "Spielen" like a user would.
- **Gallery legend** "höher gewinnt / niedriger gewinnt" may wrap (it overflowed in fr at 320 px).

## Open
- **Photos**: run `python3 -I klunki/tool/fetch_card_media.py animals` (needs the maintainer's OK for the
  download), review licences and credits as in KLD-082/084, add `- assets/quartett/animals/` to `pubspec.yaml` and
  `'animals'` to `_mediaDecks` in `test/ui/games/quartett_media_test.dart`. Until then no Wikipedia links either
  (the generated `quartett_media_data.dart` has no `animals` entry).
- **Chinese font subset**: 60 new characters (listed in the commit / report) need
  `python3 -I tool/update_web_fonts.py subset` (internet); until then `test/l10n/glyph_coverage_test.dart` fails on
  zh and the PWA falls back for these characters.
- Native-speaker review of the animal names (fr, es, zh, ar, fa).

## Screenshots
`KLUNKI_SHOTS=<dir> flutter test test/screenshots/quartett_animals_shots_test.dart` (group `kld128`): deck picker
(de 390×844, fr 360×640), gallery (decks, animal sets in de/en/ar), full cards (D1 in de/en/ar, H3 de, H4 en/ar),
Trumpf table and comparison (de/en/ar phone, de 320×640), Sets hand (de).
