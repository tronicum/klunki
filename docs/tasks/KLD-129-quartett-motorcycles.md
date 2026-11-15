# KLD-129: Quartett deck "Motorräder" (motorcycles)

- **ID:** `KLD-129`
- **Title:** A sixth Quartett deck, "Motorräder": 32 motorcycles with sourced values
- **Milestone:** M3
- **Status:** IN_PROGRESS (deck, texts and pictogram done; photos and the zh glyphs wait for the maintainer's OK)
- **Depends on:** KLD-069 (decks), KLD-082/084 (photo pipeline), KLD-085 (fingerprint), KLD-092 (hyphenated
  labels), KLD-110 (number grouping), KLD-128 (fifth deck, picker room, `localizedCardName`)
- **Touched paths:**
  - `packages/klunki_engine/lib/quartett_decks.dart` (deck `motorcycles`), engine tests, `compat_test.dart` goldens
  - `klunki/lib/ui/engine_l10n.dart` (deck, set, stat and unit names)
  - `klunki/lib/ui/games/{quartett_deck_picker,quartett_pictograms}.dart`
  - `klunki/lib/l10n/**` (14 keys × 7 locales), `klunki/tool/card_media/motorcycles.json`
  - `klunki/test/ui/games/{quartett_decks,quartett_media}_test.dart`, `klunki/test/ui/quartett_legal_test.dart` (scrolls
    to the link below six decks), `klunki/test/l10n/translations_test.dart`,
    `klunki/test/screenshots/quartett_motorcycles_shots_test.dart`

## Goal
A Quartett deck about motorcycles: 32 cards in 8 sets (Supersportler, Naked Bikes, Reiseenduros, Cruiser, Klassiker,
Gelände, Roller, Elektro), 6 stats, every value with a named source (manufacturer, press database or a marked
estimate). Basis: the maintainer-approved proposal "Deck Motorräder", version 3 (2026-11-15), with the maintainer's
decisions:

- no Hubraum (electric bikes would all tie at "–");
- the BMW R 32 shows **9 PS** (8.5 PS rounded; `ps` keeps whole numbers, like the cars);
- "Stand 2025/2026" for prices and values in the deck's doc comment;
- press databases count as sources; the Gelände set has road-legal bikes only (Beta Alp 4.0, Yamaha WR125R);
  Can-Am Pulse instead of the Energica, Kymco AK 575 Premium instead of the AK 550.

Real model names stay untranslated, like the cars; the legal notice of KLD-127 covers the trademarks.

## Acceptance criteria
- [x] Engine deck `motorcycles` (name "Motorräder", revision 1), 6 stats, whole numbers: `ps` (shared with the cars),
      `kmh` (`_kmh`), `nm` (new, Nm), `kg` (shared with the cars: **lower wins**), `rangeKmBike` (new, km; not the
      planes' `rangeKm`, which has one decimal), `valueEur` (new, €).
- [x] Validation and tie rates pass (< 3 %, > 16 distinct values per stat); compat goldens for
      `quartett-trumpf/motorcycles` and `quartett-sets/motorcycles`; the other decks' fingerprints are unchanged.
- [x] Deck name, set names, the labels Drehmoment / Reichweite / Wert and the units Nm / € in all 7 locales.
- [x] Drawn pictogram (a road bike, side view) on every card without a photo; the deck picker gives the sixth deck
      its own preview colour (purple, set B). Six decks and "Spielen" fit a 360×640 phone without scrolling.
- [ ] Photos from Wikimedia Commons, from `klunki/tool/card_media/motorcycles.json` (needs the maintainer's OK).
      Until then the gallery has no "Bildnachweise" for this deck (`quartett_media_test.dart` skips it).
- [ ] zh web font subset: 10 new characters (needs `tool/update_web_fonts.py subset`, internet).
- [x] Screenshots `kld129` (picker, gallery, full cards, Trumpf comparison, Sets hand).

## The cards

Leistung, Höchstgeschwindigkeit, Drehmoment, Gewicht (lower wins), Reichweite, Wert (engine order). Marks:
ᴾ press or database value, ˢ estimate or conversion; no mark = manufacturer figure (directly or via a database
quoting the factory data sheet). Weight ready to ride with a (nearly) full tank. Wert: German list price without
on-road costs where that can be told (model year in brackets), rounded to 100 €; classics: collector value,
rounded to 1000 €.

| Card | Set | Model | PS | km/h | Nm | kg ↓ | km | € |
|---|---|---|---|---|---|---|---|---|
| A1 | Supersportler | Ducati Panigale V4 S | 216 | 299ᴾ | 121 | 199ˢ | 260 | 34.800 (2025) |
| A2 | Supersportler | BMW M 1000 RR | 218 | 314ᴾ | 113 | 194 | 255 | 36.300 (2026) |
| A3 | Supersportler | Suzuki Hayabusa | 190 | 299 | 150 | 264 | 300 | 19.400 (2026) |
| A4 | Supersportler | Kawasaki Ninja H2R | 310 | 400ᴾ | 165 | 216 | 200ˢ | 58.000 (2026) |
| B1 | Naked Bikes | KTM 1390 Super Duke R Evo | 190 | 250ᴾ | 145 | 212 | 295 | 23.000 (2026) |
| B2 | Naked Bikes | Yamaha MT-09 | 119 | 215ᴾ | 93 | 193 | 280 | 11.000 (2026) |
| B3 | Naked Bikes | Triumph Speed Triple 1200 RS | 183 | 245ᴾ | 128 | 199 | 280 | 20.000 (2025) |
| B4 | Naked Bikes | Aprilia Tuono V4 Factory | 180 | 270ᴾ | 121 | 211ᴾ | 250 | 21.000 (2025) |
| C1 | Reiseenduros | BMW R 1300 GS | 145 | 225ᴾ | 149 | 237 | 395 | 19.900 (2026) |
| C2 | Reiseenduros | Honda Africa Twin | 102 | 199 | 112 | 231 | 385 | 16.400 (2026) |
| C3 | Reiseenduros | Ducati Multistrada V4 S | 170 | 240ᴾ | 124 | 246ˢ | 365 | 25.300 (2025) |
| C4 | Reiseenduros | Harley-Davidson Pan America 1250 Special | 152 | 220ᴾ | 125 | 258 | 385 | 20.900 (2026) |
| D1 | Cruiser | Harley-Davidson Fat Boy 117 | 105 | 190ᴾ | 168 | 315 | 345 | 27.700 (2026) |
| D2 | Cruiser | Indian Chief Dark Horse | 88ᴾ | 174ᴾ | 156 | 304 | 280ᴾ | 19.400 (2025) |
| D3 | Cruiser | Triumph Rocket 3 Storm R | 182 | 222ᴾ | 225 | 317 | 275 | 26.200 (2026) |
| D4 | Cruiser | Royal Enfield Super Meteor 650 | 47 | 160ᴾ | 52 | 241 | 365 | 8.100 (incl. on-road) |
| E1 | Klassiker | BMW R 32 (1923) | 9ˢ | 95 | 19ˢ | 122ᴾ | 400ˢ | 150.000ˢ |
| E2 | Klassiker | Honda CB750 Four (1969) | 67 | 200ᴾ | 60ᴾ | 233ᴾ | 260ˢ | 12.000ˢ |
| E3 | Klassiker | Kawasaki Z1 (1972) | 82 | 210ᴾ | 74ᴾ | 246ᴾ | 275ˢ | 18.000ˢ |
| E4 | Klassiker | Vincent Black Shadow (1948) | 56ᴾ | 201ᴾ | 71ˢ | 227ᴾ | 285ˢ | 65.000ˢ |
| F1 | Gelände | Husqvarna 701 Enduro | 79 | 165ˢ | 73 | 162ˢ | 310 | 12.500 (2026) |
| F2 | Gelände | Suzuki DR-Z4S | 38 | 139ᴾ | 37 | 151 | 250 | 9.000 (2026) |
| F3 | Gelände | Beta Alp 4.0 | 35ᴾ | 135 | 28ᴾ | 150ᴾ | 315 | 6.100 (2023/24, incl. on-road) |
| F4 | Gelände | Yamaha WR125R | 15 | 104 | 11 | 138 | 350 | 5.000 (2026, incl. on-road) |
| G1 | Roller | Vespa GTS 310 | 25ᴾ | 127ᴾ | 29ᴾ | 163ᴾ | 265 | 7.300 (2026, incl. on-road) |
| G2 | Roller | Honda Super Cub C125 | 10 | 95 | 10 | 111 | 245 | 4.200 (2025) |
| G3 | Roller | Yamaha TMAX 560 Tech MAX | 48 | 165ᴾ | 55 | 221ᴾ | 315 | 16.100 (2026) |
| G4 | Roller | Kymco AK 575 Premium | 52 | 160ᴾ | 55ᴾ | 238 | 345 | 12.300 (2026) |
| H1 | Elektro | Zero SR/F | 113ˢ | 200 | 190 | 227 | 190 | 23.000ᴾ (2025) |
| H2 | Elektro | Can-Am Pulse | 47 | 129 | 72 | 177 | 130 | 12.900ᴾ (2025/26) |
| H3 | Elektro | LiveWire One | 102ˢ | 177 | 114 | 255 | 155 | 14.800ᴾ (2026) |
| H4 | Elektro | Kawasaki Ninja e-1 | 12 | 99 | 40 | 140 | 70 | 6.600ᴾ (2025, incl. on-road) |

20 makes, at most three cards each (BMW, Kawasaki, Honda, Yamaha three; Ducati, Suzuki, Triumph, Harley-Davidson two).

**Tie rates** (`dart test test/quartett_decks_test.dart`, 496 card pairs): ps 0.60 % (3 pairs), kmh 1.01 % (5),
nm 0.40 % (2), kg 0.60 % (3), rangeKmBike 2.02 % (10), valueEur 0.40 % (2). Distinct values: 29, 27, 30, 29, 23, 30.
`dart run tool/quartett_ties.dart` lists the pairs (e.g. range 280 km: MT-09 / Speed Triple / Chief Dark Horse).

**Balance** (proposal, share of stat comparisons won): Supersportler 70 %, Naked 64 %, Reiseenduros 63 %, Cruiser
50 %, Klassiker 46 %, Gelände 37 %, Roller 31 %, Elektro 36 %. No stat belongs to one card: the H2R wins PS and
km/h but has only 200 km range; the R 32 wins value and range and loses everything else; the Rocket 3 wins torque
and is the heaviest; the Super Cub is the lightest.

## Sources

### Range and value: how they are made
- **Reichweite, petrol bikes:** tank (L) × 100 / consumption (L/100 km), rounded to 5 km. Consumption is the type
  approval figure (WMTC, Euro 5/5+), mostly via a database quoting the factory. Ninja H2R: no type approval, the
  road H2's 8.5 L (bikez.net) instead.
- **Reichweite, electric bikes:** manufacturer figure: Can-Am Pulse 130 (WMTC combined; city 160, 80 km/h constant
  89), Ninja e-1 72 → 70 (WMTC class 1), Zero SR/F 188 → 190 (highway; Zero gives only city and highway),
  LiveWire One 153 → 155 (combined).
- **Reichweite, classics:** consumption from period tests or databases, estimates.
- **Wert:** see the column above; USD → EUR 0.86, GBP → EUR 1.17 for the auction results (approximations).

### Technical data (main source, further sources)
| id | Main source | Further |
|---|---|---|
| A1 | https://www.1000ps.com/de-de/modell/9182/ducati-panigale-v4-s/2025 | https://www.cyclenews.com/2024/07/article/2025-ducati-panigale-v4-and-v4-s-first-look-and-specs |
| A2 | https://www.motorradundreisen.de/motorraddatenbank/bmw/m-1000-rr-11315.html | https://www.motorradonline.de/supersportler/bmw-s-1000-rr-und-m-1000-rr-neu-2025/ |
| A3 | https://www.1000ps.de/modellnews-id-3007810-suzuki-hayabusa-2021-die-299-km-h-legende-ist-zurueck | – |
| A4 | https://www.kawasaki.com.au/en-au/motorcycle/ninja/hypersport/ninja-h2r/2024-ninja-h2r (manufacturer) | 400 km/h: https://www.autorevue.at/autowelt/400-kmh-kawasaki-ninja-h2r |
| B1 | https://www.ktm.com/de-at/models/naked-bike/2025-ktm-1390-superdukerevo/technische-spezifikationen.html (manufacturer) | – |
| B2 | https://www.motorradundreisen.de/motorraeder/yamaha-mt-09-2024/7672/ | – |
| B3 | https://www.1000ps.de/testbericht-id-3012436-die-neue-triumph-speed-triple-1200-rs-2025 | – |
| B4 | https://www.bennetts.co.uk/bikesocial/reviews/bikes/aprilia/tuono-v4-2025-review | https://www.motorradundreisen.de/motorraddatenbank/aprilia/tuono-v4-factory-13683.html |
| C1 | https://www.motorradundreisen.de/motorraddatenbank/bmw/r-1300-gs-11601.html | – |
| C2 | https://www.honda.de/motorcycles/range/adventure/crf1100l-africa-twin/specifications-and-price.html (manufacturer) | – |
| C3 | https://www.motorradundreisen.de/motorraddatenbank/ducati/multistrada-v4-s-11170.html | https://mcnews.com.au/?p=496845 |
| C4 | https://www.harley-davidson.com/eu/en/motorcycles/2025/pan-america-1250-special.html (manufacturer) | – |
| D1 | https://www.harley-davidson.com/eu/en/motorcycles/2025/fat-boy.html (manufacturer) | – |
| D2 | https://www.motofichas.com/marcas/indian/chief-dark-horse | https://www.motorcycle.com/specs/indian/cruiser/2026/chief/dark-horse/detail.html |
| D3 | https://www.triumphmotorcycles.co.uk/motorcycles/rocket-3/rocket-3-storm/specification (manufacturer) | – |
| D4 | https://www.royalenfield.com/content/dam/open-pdf/royal-enfield-super-meteor-650-technical-specifications.pdf (manufacturer) | – |
| E1 | https://www.bmwgroup-classic.com/en/models/bmw-motorcycle-classics/product-description-page.md-569-1.bmw-r-32.html (manufacturer) | https://www.motorradundreisen.de/motorraddatenbank/bmw/r-32-11600.html |
| E2 | https://en.wikipedia.org/wiki/Honda_CB750 | https://global.honda/en/heritage/episodes/1969cb750four.html |
| E3 | https://en.wikipedia.org/wiki/Kawasaki_Z1 | https://magazine.cycleworld.com/article/1973/3/1/kawasaki-900-z-1 (tank) |
| E4 | https://en.wikipedia.org/wiki/Vincent_Black_Shadow | https://www.hagerty.co.uk/articles/the-full-english-vincent-black-shadow/ |
| F1 | https://www.cyclenews.com/2025/09/article/2026-husqvarna-701-enduro-and-701-supermoto-models/ | https://www.1000ps.com/de-at/modell/8408/husqvarna-701-enduro/2026 |
| F2 | https://www.motorcycles.news/motorrad/suzuki-dr-z4s-2025/ | https://www.dirtrider.com/dirt-bikes/suzuki-dr-z4s-technical-information |
| F3 | https://www.betamotor.com/en-be/bikes/alp-4-0/ (manufacturer: weight, tank, consumption) | PS/Nm: https://www.motorradundreisen.de/motorraeder/test-beta-alp-4-0-wander-enduro-china-herz-fahrbericht/9989/; top speed "according to Beta" and 150 kg ready to ride: https://www.1000ps.com/en-gb/amp/articledetail/3011245 |
| F4 | https://www.motorradundreisen.de/motorraddatenbank/yamaha/wr125r-10248.html (factory data MY 2026) | https://www.motorradonline.de/enduro/yamaha-wr125r-2026-125er-enduro-fuer-deutschland/ (2.5 L WMTC) |
| G1 | https://www.motorradundreisen.de/motorraddatenbank/vespa/gts-310-29392.html | – |
| G2 | https://hondanews.eu/at/de/motorcycles/media/pressreleases/570699/honda-super-cub-c125-modelljahr-2026 (manufacturer) | – |
| G3 | https://www.motorradundreisen.de/motorraddatenbank/yamaha/tmax-tech-max-12139.html | https://www.motorradundreisen.de/roller-scooter/yamaha-tmax-tech-max-2025-imu-kurven-abs/8602/ |
| G4 | https://www.kymco.de/roller/250-575ccm/kymco-ak-575i-abs-premium (manufacturer: PS, weight, tank, consumption, price) | top speed: https://www.motorradonline.de/roller/kymco-ak-575i/; Nm: https://www.motorradundreisen.de/motorraddatenbank/kymco/ak-575i-abs-premium-30207.html |
| H1 | https://zeromotorcycles.com/en-gb/model/zero-srf (manufacturer) | – |
| H2 | https://brp-world.com/content/dam/global/emea/can-am-on-road/my25/2-wheel/ONRD-2WV-MY25-PULSE-SPEC-A4-V-HR-ENEMEA.pdf (manufacturer data sheet EMEA) | https://www.adac.de/rund-ums-fahrzeug/zweirad/motorrad-roller/fahrberichte/can-am-pulse-origin/ |
| H3 | https://www.livewire.com/en-gb/livewire-one-electric-motorcycle (manufacturer) | – |
| H4 | https://www.kawasaki.de/de_de/Motorcycles/EV_HEV/ninja_e-1.html (manufacturer) | https://www.motorradundreisen.de/motorraddatenbank/kawasaki/ninja-e-1-11986.html (Nm, 72 km) |

### Range: tank and consumption
| id | Tank / L per 100 km | Source |
|---|---|---|
| A1 | 17 / 6.5 | https://www.motorradundreisen.de/motorraddatenbank/ducati/panigale-v4-s-2024-4765.html |
| A2 | 16.5 / 6.5 WMTC | https://bmw-motorrad.co.uk/en/models/m/m1000rr/technicaldata.html |
| A3 | 20 / 6.7 | https://www.motorradundreisen.de/motorraddatenbank/suzuki/hayabusa-11175.html |
| A4 | 17 / ~8.5ˢ | tank: https://www.motorradundreisen.de/motorraddatenbank/kawasaki/ninja-h2r-11368.html; consumption of the road H2: https://bikez.net/us/motorcycle/57216/Kawasaki_Ninja_H2_2022 |
| B1 | 17.5 / 5.9 | https://www.motorradundreisen.de/motorraddatenbank/ktm/1390-super-duke-r-evo-12051.html |
| B2 | 14 / 5.0 | https://www.motorradundreisen.de/motorraddatenbank/yamaha/mt-09-11118.html |
| B3 | 15.5 / 5.5 | https://www.motorradundreisen.de/motorraddatenbank/triumph/speed-triple-1200-rs-11182.html |
| B4 | 18 / 7.2 | https://www.motorradundreisen.de/motorraddatenbank/aprilia/tuono-v4-factory-13683.html |
| C1 | 19 / 4.8 WMTC | https://www.bmw-motorrad.com.au/en/models/adventure/r1300gs/technicaldata.html |
| C2 | 18.8 / 4.9 | https://www.motorradundreisen.de/motorraddatenbank/honda/crf1100l-africa-twin-11193.html |
| C3 | 22 / 6.0 | https://www.motorradundreisen.de/motorraddatenbank/ducati/multistrada-v4-s-11170.html |
| C4 | 21.2 / 5.5 (EU 134/2014) | https://www.harley-davidson.com/ch/de/motorcycles/2025/pan-america-1250-special.html |
| D1 | 18.9 / 5.5 (EU 134/2014) | https://www.harley-davidson.com/at/de/motorcycles/2025/fat-boy.html |
| D2 | 15.1 / 5.4ᴾ | tank: https://www.indianmotorcycle.de/chief-dark-horse/; consumption: press databases only (1000ps, motoplanete, "estimated WMTC") |
| D3 | 18 / 6.6 | Triumph UK (above) |
| D4 | 15.7 / 4.3 | https://www.motorradundreisen.de/motorraddatenbank/royal-enfield/super-meteor-650-11854.html |
| E1 | 14 / ~3.5 | https://www.motorradundreisen.de/motorraddatenbank/bmw/r-32-11600.html |
| E2 | 18 / ~6.9 (34.3 US mpg, period test) | https://www.motorcycleclassics.com/classic-japanese-motorcycles/honda-cb750-zmmz06jazraw/ |
| E3 | 17.8 / ~6.5 | tank: Cycle World 3/1973 (above); consumption from a user database (weak) |
| E4 | ~16 / ~5.6 ("about 50 mpg", imperial) | Hagerty UK (above) |
| F1 | 13.3 / 4.3 | https://www.1000ps.com/de-at/modell/8408/husqvarna-701-enduro/2026 |
| F2 | 8.7 / 3.5 WMTC | https://www.globalsuzuki.com/motorcycle/smgs/products/digitalbook/2026dr-z4s/pageindices/index11.html |
| F3 | 11.0 / 3.51 | Beta (above; with a CO₂ figure, cycle not named) |
| F4 | 8.1 / 2.3 (factory) | above; motorradonline gives 2.5 L WMTC (→ 325 km) |
| G1 | 8.5 / 3.2 WMTC | above |
| G2 | 3.7 / 1.5 WMTC | https://www.motorradundreisen.de/motorraddatenbank/honda/super-cub-125-11573.html |
| G3 | 15 / 4.8 | above |
| G4 | 14.5 / 4.2 | kymco.de (above, Euro 5+) |

### Value
| id | Price (raw) | Source |
|---|---|---|
| A1 | 34.790 (2025) | https://www.motorradundreisen.de/motorrad-fotos/ducati-panigale-v4s-2025/9602/ |
| A2 | 36.300 (2026) | https://www.motorradonline.de/marken-modelle/bmw/m-1000-rr/technische-daten/ |
| A3 | 19.390 (2026, plus on-road) | https://www.motorradonline.de/supersportler/suzuki-hayabusa-2026-und-special-edition-deutschland/ |
| A4 | 58.000 ex works (2026) | https://www.1000ps.de/modellnews-id-3013018-kawasaki-ninja-h2r-2026-bestellung-jetzt-wieder-moeglich |
| B1 | 22.999 (2026, plus 495) | https://www.ktm.com/de-de/models/naked-bike/2026-ktm-1390-superdukerevo.html (manufacturer) |
| B2 | 10.999 (2026) | https://www.motorradonline.de/marken-modelle/yamaha/mt-09/technische-daten/ |
| B3 | 19.995 (2025, plus on-road) | https://www.motorradundreisen.de/motorraeder/aufgelegt-triumph-ueberarbeitet-speed-triple-rs/8767/ |
| B4 | 20.999 (2025) | https://www.motorradonline.de/supersportler/aprilia-tuono-v4-factory-fahrtest-vereint-leichtigkeit-und-stabilitaet/ |
| C1 | 19.900 (2026) | https://www.motorradonline.de/enduro/bmw-r-1300-gs-neu-fuer-2026-neue-farben-neuer-preis-und-updates/ |
| C2 | 16.449 (2026, plus freight) | https://www.motorradundreisen.de/motorraeder/starten-honda-africa-twin-adventure-sports-saison-2026/10022/ |
| C3 | 25.290 (2025) | https://www.1000ps.com/de-de/bericht/3011851/nya-ducati-multistrada-v4-2025 |
| C4 | 20.900 (2026, "ab … €+") | https://www.harley-davidson.com/de/de/motorcycles/pan-america-1250-special.html (manufacturer) |
| D1 | 27.700 (2026, "ab … €+") | https://www.harley-davidson.com/de/de/motorcycles/fat-boy.html (manufacturer) |
| D2 | 19.390 (2025) | https://www.motorradundreisen.de/motorraddatenbank/indian/chief-dark-horse-11068.html |
| D3 | 26.195 (2026) | https://www.motorradonline.de/chopper-cruiser/triumph-rocket-3-storm-mit-neuem-lack/ |
| D4 | 8.070 (incl. on-road, Astral Black) | https://www.royalenfield.com/de/de/motorcycles/super-meteor-650/ (manufacturer) |
| E1 | 150.000ˢ (Bonhams Paris 2023 143.750 €; Mecum 2026 ≈ 180.000 € / 209.000 $) | https://www.classic.com/veh/1924-bmw-r32-2555-nOlQYwW |
| E2 | 12.000ˢ (die-cast K0; Bonhams 2023 £11.500, Aguttes 13.870 €; early sand-cast K0 ~22.000) | https://www.motorcycleclassics.com/classic-japanese-motorcycles/honda-cb750-zmmz06jazraw/ |
| E3 | 18.000ˢ (Bonhams 2024 £16.675; Mecum 2025 $15.400–19.250) | https://www.classic.com/veh/1973-kawasaki-903cc-z1-z1f17551-nlXVwvn |
| E4 | 65.000ˢ (auctions 2025 £35.000–69.000; Hagerty "excellent" $68.800) | https://www.hagerty.co.uk/articles/the-full-english-vincent-black-shadow/ |
| F1 | 12.499 (2026, plus 495) | https://www.motorradonline.de/motorraeder/jetzt-mit-79-ps-husqvarna-701-supermoto-und-701-enduro-neu-2026/ |
| F2 | 8.999 (2026) | https://www.motorcycles.news/suzuki-deutschland-2026-preise-strategie-modelle/ |
| F3 | 6.140 (MY 2023/24, incl. on-road) | https://www.motorradundreisen.de/motorraddatenbank/beta/alp-4-0-10122.html |
| F4 | 4.999 (2026, incl. on-road) | https://www.motorradundreisen.de/motorraddatenbank/yamaha/wr125r-10248.html |
| G1 | 7.250 (2026, incl. on-road) | https://www.motorradundreisen.de/motorraddatenbank/vespa/gts-310-29392.html |
| G2 | 4.199 (2025) | https://www.motorradundreisen.de/motorraddatenbank/honda/super-cub-125-11573.html |
| G3 | 16.119 (2026) | https://www.motorradundreisen.de/motorraddatenbank/yamaha/tmax-tech-max-12139.html |
| G4 | 12.349 (2026, plus 400 delivery) | https://www.kymco.de/roller/250-575ccm/kymco-ak-575i-abs-premium (manufacturer) |
| H1 | 23.000 (2025) | https://www.motorradundreisen.de/motorraddatenbank/zero/sr-f-12071.html |
| H2 | 12.900 (2025/26, after the price cut 09/2025) | https://www.motorradundreisen.de/szene/can-am-pulse-origin-preissenkung-e-motorraedern/9344/ |
| H3 | 14.790 (after the price cut 03/2026) | https://auto-medienportal.net/artikel/detail/69664 |
| H4 | 6.595 (ADAC, 25.09.2025, incl. on-road) | https://www.adac.de/rund-ums-fahrzeug/zweirad/motorrad-roller/kauf-verkauf/elektromotorraeder/ |

### Estimates and known spread
- **Estimates (ˢ):** Panigale 199 kg (187 kg without fuel + 17 L), Multistrada 246 kg (231 kg + 90 % of 22 L),
  701 Enduro 162 kg (152 kg + tank) and 165 km/h (top speed nowhere published), H2R 200 km (road H2's
  consumption), R 32 9 PS (8.5), 19 Nm (from kW and engine speed, lower bound), 400 km and 150.000 €, CB750 260 km
  and 12.000 €, Z1 275 km and 18.000 €, Black Shadow 71 Nm, 285 km and 65.000 €, Zero 113 PS (83 kW) and
  LiveWire 102 PS (75 kW) converted.
- **Spread (ᴾ):** most top speeds are press values (H2R 400 the unofficial record; R 1300 GS 225 "limited";
  Super Duke "over 250"; Speed Triple 245 from the RR's registration; Multistrada 240 measured in a test).
  Consumption varies by source (Tuono 7.2 / 6.8 / 6.4 L; Hayabusa 6.7 / 6.8; Super Meteor 4.1–4.5; WR125R 2.3
  factory vs. 2.5 WMTC; Indian 5.4 press only; Beta without a named cycle). Prices: Panigale, Multistrada, Speed
  Triple and Tuono 2025 (no 2026 price found); Indian 2025 (2026 maybe ~17.990); Beta 2023/24 (dealers 2026
  5.000–6.140); Zero rounded database value (MY 2027: 20.740); LiveWire 14.790 or 14.890; Ninja e-1 ADAC 6.595
  vs. "ab 9.135" in a database. Conflicting manufacturer figures: LiveWire 100 or 105 hp, Pan America 125 or 128
  Nm, Indian 156 or 162 Nm, R 32 95 or 90 km/h.

## Translations
14 keys per locale: `quartettDeckMotorcycles`, `quartettSetMotorcyclesA`–`H`, `quartettStatNm`,
`quartettStatRangeKmBike`, `quartettStatValueEur`, `quartettUnitNm`, `quartettUnitEur`. Leistung,
Höchstgeschwindigkeit, Gewicht and their units reuse the car deck's keys (`engineStat*`, `engineUnit*`: "hp", "ch", "CV",
"马力", …). `rangeKmBike` has its own label key so a language can use the vehicle word (fr "Autonomie", es
"Autonomía", zh "续航") where the planes say "range" of an aircraft (zh "航程"). Nm and € are written the same in
every locale (SI symbol, currency sign), like kg and km/h; the euro follows the number ("34,800 €" in en too).
Machine translation like the rest of the non-German locales; a native-speaker review is open.

| Key | de | en | fr | es | zh | ar | fa |
|---|---|---|---|---|---|---|---|
| deck | Motorräder | Motorbikes | Motos | Motos | 摩托车 | دراجات نارية | موتورسیکلت‌ها |
| A | Supersportler | Superbikes | Sportives | Superdeportivas | 超级跑车 | دراجات رياضية | اسپرت‌ها |
| B | Naked Bikes | Naked bikes | Roadsters | Naked | 街车 | دراجات الشوارع | خیابانی‌ها |
| C | Reiseenduros | Adventure | Trails | Trail | 探险车 | دراجات المغامرة | ماجراجویی |
| D | Cruiser | Cruisers | Customs | Custom | 巡航车 | دراجات كروزر | کروزرها |
| E | Klassiker | Classics | Classiques | Clásicas | 经典车 | كلاسيكيات | کلاسیک‌ها |
| F | Gelände | Off-road | Tout-terrain | Todoterreno | 越野车 | الطرق الوعرة | آفرود |
| G | Roller | Scooters | Scooters | Escúteres | 踏板车 | سكوترات | اسکوترها |
| H | Elektro | Electric | Électriques | Eléctricas | 电动车 | كهربائية | برقی‌ها |
| nm | Drehmoment | Torque | Couple | Par motor | 扭矩 | عزم الدوران | گشتاور |
| rangeKmBike | Reichweite | Range | Autonomie | Autonomía | 续航 | المدى | برد |
| valueEur | Wert | Value | Valeur | Valor | 价值 | القيمة | ارزش |

Soft hyphens in "Dreh-moment", "Reich-weite", "Auto-nomie", "Auto-nomía" (set names have none: the set line is one
line with "…"). en C is "Adventure", not "Adventure bikes", which was cut to "Adventure b…" on a Trumpf card.

## Decisions in the code
- **Stat ids:** `ps`, `kmh` and `kg` are the cars' stats (same label, unit and direction; one translation per id,
  checked by the engine test). `rangeKmBike` is new because the planes' `rangeKm` has one decimal; `nm` and
  `valueEur` are new.
- **Deck picker:** purple (set B) for the sixth deck. The KLD-128 tiles are flat enough: six decks, "Karten
  ansehen" and "Spielen" fit a 360×640 phone without scrolling (screenshot `kld129-1-picker-de-360x640`).
- **Pictogram:** a road bike, side view (two wheels with hubs, fork, handlebar, tank, seat, engine block,
  headlight) in the 100 × 60 box of the other pictograms.

## Photos (open: needs the maintainer's OK)
`klunki/tool/card_media/motorcycles.json` lists per card the en (and where known de) Wikipedia article and in
`_check` what the photo must show (the exact model, else the nearest generation with a note). No Commons file is
pinned yet: run `python3 -I klunki/tool/fetch_card_media.py motorcycles --candidates` first, pin a `file` where the
lead image shows another model or generation (likely for A2, A4, B1, D1, D2, F2, G2, G4, H1), then run the fetch.
Doubtful on Commons (proposal, section 6): Kymco AK 575, Indian Chief Dark Horse, Husqvarna 701, DR-Z4S, Beta Alp
4.0, WR125R (2026), Can-Am Pulse, Ninja e-1, Rocket 3 Storm R, Super Duke R Evo; a card without a free photo keeps
the pictogram (`"file": ""`). After the fetch: add `motorcycles` to `_mediaDecks` in `quartett_media_test.dart`,
drop the skip in "every deck gallery with photos has a Bildnachweise button", and add
`- assets/quartett/motorcycles/` to `pubspec.yaml`.

## Chinese font (open)
The zh texts need 10 characters missing from the Noto Sans SC subset: 托扭探摩板矩越踏野险. Until
`python3 -I tool/update_web_fonts.py subset` runs (internet), two glyph tests in `test/l10n/glyph_coverage_test.dart`
fail.

## Screenshots
`KLUNKI_SHOTS=<dir> flutter test test/screenshots/quartett_motorcycles_shots_test.dart` (group `kld129`): deck
picker (de 390×844; de and fr 360×640), gallery (decks, motorcycle sets in de/en/ar), full cards (C4 in de/en/ar,
E1 de, A4 en, H1 ar), Trumpf table and comparison on Drehmoment (de/en/ar phone) and on Wert (de 320×640), Sets
hand (de).
