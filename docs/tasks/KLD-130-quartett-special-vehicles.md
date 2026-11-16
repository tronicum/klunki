# KLD-130: Quartett deck "Sonderfahrzeuge" (special vehicles)

- **ID:** `KLD-130`
- **Title:** A seventh Quartett deck, "Sonderfahrzeuge": 32 special-purpose vehicles with sourced values
- **Milestone:** M3
- **Status:** DONE (25 of 32 cards with a Commons photo; A1 dropped after the visual check, it showed a
  person instead of the ladder truck; the zh glyphs are in the web font subset)
- **Depends on:** KLD-069 (decks), KLD-082/084 (photo pipeline), KLD-085 (fingerprint), KLD-092 (hyphenated
  labels), KLD-110 (number grouping), KLD-127 (legal notice), KLD-128/129 (picker room, `localizedCardName`)
- **Touched paths:**
  - `packages/klunki_engine/lib/quartett_decks.dart` (deck `special`), engine tests, `compat_test.dart` goldens
  - `klunki/lib/ui/engine_l10n.dart` (deck, set and three card names)
  - `klunki/lib/ui/games/{quartett_deck_picker,quartett_pictograms}.dart`
  - `klunki/lib/l10n/**` (12 keys × 7 locales), `klunki/tool/card_media/special.json`
  - `klunki/test/ui/games/{quartett_decks,quartett_media}_test.dart` (the gallery test scrolls to the seventh deck;
    the Bildnachweise test skips decks without photos), `klunki/test/l10n/translations_test.dart`,
    `klunki/test/screenshots/quartett_special_shots_test.dart`

## Goal
A Quartett deck about special-purpose vehicles: 32 cards in 8 sets chosen by the maintainer (Feuerwehr, Baustelle,
Kräne, Landwirtschaft, Rettung, Flughafen, Stadtreinigung, Schwertransport), no military vehicles. The deck uses
only stats that all 32 vehicles have and that compare fairly, each value with a named source (manufacturer,
press/database, or a marked estimate). Real model names, untranslated like the other vehicle decks.

## Step 1: proposal
The proposal "Deck Sonderfahrzeuge", version 1 (2026-11-15), was handed to the maintainer as a German document
(kept outside the repo, like the KLD-128/129 proposals). Summary:

- **5 stats, all existing ids, so no new stat translations:** `ps` Leistung (↑), `kmh` Höchstgeschwindigkeit (↑),
  `massT` Gewicht (t, 1 decimal, **lower wins** like the trains), `lengthM` Länge (m, 1 decimal), `heightM` Höhe
  (m, **2 decimals**: with 1 decimal the 4 m legal height limit gives 4.0 % ties).
- **Rejected:** Hubraum (electric vehicles), Drehmoment (not published for excavators, cranes, helicopter, ship),
  seats/crew (ties, a remote-controlled tug has none), width (2.55 m legal limit), tank/range, price, a set-specific
  "special" stat.
- **Weak spot:** no fire truck, box ambulance or heavy-haulage tractor has a published top speed; 5 of 32 km/h
  values are estimates (legal limiter, a tender spec, the sister model's figure).

## Step 2: the maintainer's decisions (2026-11-16)
The proposal was approved as written:
- km/h stays, with the 5 estimates marked;
- weight: lighter wins;
- the H135 helicopter and the rescue cruiser stay in "Rettung";
- the eEconic as a chassis (8.53 m / 2.85 m without the refuse body); the Scheuerle SPMT with computed values;
- the BelAZ 75710;
- card names with a translated type word for E1, E2 and E4 ("Rettungswagen Sprinter", "Notarztwagen Kodiaq",
  "Seenotretter Hermann Marwede"); the other 29 cards keep their model names in every language;
- deck id `special`; "Stand 2025/2026" in the deck's doc comment.

## Acceptance criteria
- [x] Engine deck `special` ("Sonderfahrzeuge", revision 1), 5 stats with existing ids: `ps` (cars, motorcycles),
      `kmh` (`_kmh`), `massT` (trains: lower wins; here 1 decimal), `lengthM` (`_lengthM`, 1 decimal), `heightM`
      (rockets; here 2 decimals). Validation passes, tie rate < 3 % and > 16 distinct values per stat; compat
      goldens for `quartett-trumpf/special` and `quartett-sets/special`; the other decks' fingerprints are unchanged.
- [x] Deck name, the 8 set names and the 3 card names with a type word in all 7 locales (12 keys).
- [x] Drawn pictogram (a fire engine with a turntable ladder, side view) on every card without a photo; the
      seventh deck gets the blue preview colour (set F). Seven decks, "Karten ansehen" and "Spielen" fit a 360×640
      phone without scrolling (screenshot `kld130-1-picker-de-360x640`).
- [ ] Photos from Wikimedia Commons (CC BY / CC BY-SA / CC0 / public domain only) via
      `klunki/tool/card_media/special.json`: the file list is ready; the fetch runs in the maintainer's session
      (`python3 -I klunki/tool/fetch_card_media.py special`); then add `special` to `_mediaDecks` in
      `klunki/test/ui/games/quartett_media_test.dart` and check every photo by eye.
- [ ] zh web font subset: 10 new characters (业农医卫场急援环辆防); the two glyph tests fail until
      `python3 -I tool/update_web_fonts.py subset` runs (with the maintainer's OK).
- [x] Card values and sources documented in this card; `CHANGELOG.md` under `[Unreleased]`.
- [x] Screenshots `kld130` (picker, gallery, full cards, Trumpf comparison, Sets hand).

## The cards

Leistung, Höchstgeschwindigkeit, Gewicht (lower wins), Länge, Höhe (engine order). Marks: ᴾ press, dealer or
database value, ˢ estimate or conversion; no mark = manufacturer figure (directly or via a database quoting the
data sheet). kW × 1.36 = PS. Stand 2025/2026.

| Card | Set | Name (de) | PS | km/h | t ↓ | Länge m | Höhe m |
|---|---|---|---|---|---|---|---|
| A1 | Feuerwehr | Magirus M32L-AS | 299 | 100ˢ | 16.0 | 10.2 | 3.30 |
| A2 | Feuerwehr | Magirus M64L | 422 | 90ˢ | 32.0 | 12.0 | 3.92 |
| A3 | Feuerwehr | Rosenbauer RT | 490 | 105ˢ | 18.0ᴾ | 7.6ᴾ | 2.90 |
| A4 | Feuerwehr | Magirus Wolf R1 | 20 | 15 | 0.9 | 1.5 | 1.30 |
| B1 | Baustelle | Caterpillar 320 | 175 | 6ᴾ | 22.6 | 9.5 | 2.96 |
| B2 | Baustelle | JCB 3CX | 75 | 40 | 8.2 | 5.6 | 3.61ᴾ |
| B3 | Baustelle | Caterpillar D11 | 862 | 12 | 106.8 | 10.5 | 4.72 |
| B4 | Baustelle | Volvo A60H | 639 | 55 | 98.8 | 12.2 | 3.85 |
| C1 | Kräne | Liebherr LTM 11200-9.1 | 687 | 75 | 108.0 | 19.9 | 4.00ᴾ |
| C2 | Kräne | Liebherr LTM 1090-4.2 | 449 | 85 | 48.0 | 13.4ᴾ | 4.00ᴾ |
| C3 | Kräne | Tadano GR-1000XL-4 | 284 | 35 | 53.2 | 14.4 | 3.81 |
| C4 | Kräne | Liebherr MK 140 | 544 | 80 | 60.0 | 16.0ᴾ | 4.00ᴾ |
| D1 | Landwirtschaft | Fendt 1052 Vario | 520 | 60 | 18.0 | 6.4 | 3.55 |
| D2 | Landwirtschaft | John Deere 9RX 830 | 842ˢ | 40 | 38.1ᴾ | 8.9ᴾ | 3.77ᴾ |
| D3 | Landwirtschaft | Claas Lexion 8900 | 790 | 40 | 22.4ᴾ | 9.4ᴾ | 4.00ᴾ |
| D4 | Landwirtschaft | Fendt 211 Vario | 114 | 40 | 7.5 | 4.1 | 2.62 |
| E1 | Rettung | Rettungswagen Sprinter | 190 | 130ˢ | 5.0 | 6.5ᴾ | 2.98ᴾ |
| E2 | Rettung | Notarztwagen Kodiaq | 193 | 220 | 2.3 | 4.8 | 1.68 |
| E3 | Rettung | Airbus H135 | 1284 | 255 | 3.0 | 12.3 | 3.90 |
| E4 | Rettung | Seenotretter Hermann Marwede | 9250 | 46 | 404.0 | 46.0 | 17ˢ |
| F1 | Flughafen | Rosenbauer Panther 8×8 | 1450 | 135 | 52.0 | 12.0 | 4.00 |
| F2 | Flughafen | Goldhofer AST-1X | 707 | 32 | 31.0 | 9.5 | 2.21ˢ |
| F3 | Flughafen | e.COBUS 3000 | 218 | 50 | 20.4 | 13.9 | 3.10 |
| F4 | Flughafen | Mototok Twin 7500 | 7 | 4 | 2.1 | 2.6 | 0.32 |
| G1 | Stadtreinigung | Mercedes-Benz eEconic | 544 | 89 | 27.0 | 8.5 | 2.85 |
| G2 | Stadtreinigung | Bucher CityCat 5006 | 160 | 80 | 10.4 | 5.0 | 2.50 |
| G3 | Stadtreinigung | Mercedes-Benz Unimog U 530 | 299 | 90 | 16.5 | 5.3 | 2.92 |
| G4 | Stadtreinigung | Goupil G4 | 14 | 50 | 2.1ᴾ | 3.6ᴾ | 1.89ᴾ |
| H1 | Schwertransport | Volvo FH16 780 | 780 | 90ˢ | 35.0 | 7.4 | 3.79 |
| H2 | Schwertransport | Caterpillar 797F | 4057 | 68 | 623.7 | 15.1 | 7.71 |
| H3 | Schwertransport | BelAZ 75710 | 4660ᴾ | 64ᴾ | 810.0ᴾ | 20.6ᴾ | 8.16ᴾ |
| H4 | Schwertransport | Scheuerle SPMT | 245 | 5ˢ | 715.0ˢ | 16.8 | 1.50 |

**What the values mean.** Gewicht: permissible gross weight for registered vehicles, loaded gross weight for the
dump trucks and the SPMT, operating weight for machines without a load (excavator, dozer, cranes, tug, robot),
maximum take-off weight for the helicopter, displacement for the ship. Länge in driving or transport position
without attachments (combine without header, LTM 11200 without the boom that travels separately). Höhe in driving
position (eEconic: chassis with cab, no refuse body). The five km/h estimates: M32L-AS 100 (tender spec; fire
engines are exempt from the 90 km/h limiter), M64L 90 and FH16 90 (legal limiter of the chassis), Rosenbauer RT 105
(the US sister model RTX, "approx. 105 km/h with full load"), Sprinter ambulance 130 (a placeholder: neither the
body builder nor Mercedes-Benz nor the ADAC give one). E4 height measured on the shipyard's side view (waterline to
mast top, ±2 m). H4: two 6-axle modules with the PPU Z180 drive; 5 km/h loaded; weight 2 × (≈25 t + 334 t payload).
D2: 830 hp rated (913 hp with power boost); weight is the maximum operating weight (33.5 t empty).

**Tie rates** (`dart test test/quartett_decks_test.dart`, 496 card pairs): ps 0.40 %, kmh 2.22 %, massT 0.40 %,
lengthM 0.40 %, heightM 2.02 % (five cards at the 4.00 m legal limit). Distinct values: 30, 25, 30, 30, 28. With one
decimal the height would tie 4.03 %. The margin on kmh and heightM is small: recompute after any change.

**Balance** (share of the stat comparisons won, ties left out; printed by the engine test, which keeps every set
within 40–65 %): Feuerwehr 49 %, Baustelle 44 %, Kräne 58 %, Landwirtschaft 46 %, Rettung 63 %, Flughafen 45 %,
Stadtreinigung 41 %, Schwertransport 55 %. No stat belongs to one card: the rescue cruiser has the most PS and is
the longest but slow and heavy; the H135 is the fastest; the BelAZ the tallest and heaviest; the Wolf R1 the
lightest.

## Sources
| id | Main source | Further |
|---|---|---|
| A1 | https://www.magirusgroup.com/de/serving-heroes/deliveries/detail/delivery/m32l-as-for-schleswig-09-2024/ | km/h: https://lste.brandenburg.de/sixcms/media.php/9/HLF%2010%20mit%20Beladeliste%20Stand%202023.4502534.pdf |
| A2 | https://www.magirusgroup.com/de/serving-heroes/deliveries/detail/delivery/three-m64l-for-london-11-2021/ | – |
| A3 | https://www.eurotransport.de/fahrzeuge/lkw/rosenbauers-loeschfahrzeug-der-zukunft-r-wie-revolutionaer/ | https://www.autoevolution.com/news/rosenbauer-rt-shows-how-an-electric-fire-truck-can-go-electric-164516.html; km/h: https://rosenbaueramerica.com/wp-content/uploads/2023/06/RTX-Demo-spec-1.pdf |
| A4 | https://www.magirusgroup.com/de/en/products/special-vehicles/wolf-r1/ | Magirus press release (15 km/h) |
| B1 | https://www.borusancat.com/en/equipment/new/464/excavators/126532/320 | dealer data sheets (km/h) |
| B2 | https://machinestore.jcb.com/en-GB/machines/backhoe-loader-excavator-loader/3cx-sitemaster | older JCB sheets (length), a rental company (height) |
| B3 | https://www.warrencat.com/new/equipment/dozers/large-dozers/d11-dozer/ (Cat data via a dealer) | – |
| B4 | https://www.volvoce.com/europe/en/products/articulated-haulers/a60h | the brochure PDF |
| C1 | https://www.liebherr.com/en-at/mobile-cranes/ltm-mobile-cranes/ltm-11200-9-1-5923936 | weight, length: https://de.wikipedia.org/wiki/Liebherr_LTM_11200 (Liebherr data sheet); height: Ritchie Specs |
| C2 | https://assets-cdn.liebherr.com/versions/2c96d46e-3f5b-45c0-bcee-d3268afbb303/original (data sheet) | length: fleetfile.com; height: a rental table |
| C3 | https://mediahub.tadano.com/m/64b878bdc2a53b0c/original/doc_tadano_GR-1000XL-4_datasheet_imperial_en.pdf | – |
| C4 | https://www.liebherr.com/en-nl/mobile-cranes/mk-mobile-construction-cranes/mk-140-5-1e-8571765 | length, height: a fan site |
| D1 | https://api.fendt.com/techdata/US/en/1519937 | – |
| D2 | https://www.koneviesti.fi/en/konedata/traktorit/john-deere/john-deere-9rx-710-830 | https://www.topagrar.com/technik/news/fur-1-mio-eur-erster-john-deere-9rx-830-in-europa-20007227.html; tractordata, agriland |
| D3 | Claas (PS, km/h) | https://www.koneviesti.fi/en/konedata/puimurit/claas/claas-lexion-7400-8900-2020; Lectura |
| D4 | https://api.fendt.com/techdata/ZA/en/1152980 | – |
| E1 | https://www.was-vehicles.com/fileadmin/user_upload/WAS/Seiten/WAS_500_Kofferambulanzen/RTW-Sprinter-neue-Vorf%C3%BChrer/Datenbl%C3%A4tter/Datenblatt_zum_WAS_500_Rettungswagen_Mercedes-Sprinter.pdf | dimensions: used-vehicle listings |
| E2 | https://www.adac.de/rund-ums-fahrzeug/autokatalog/marken-modelle/skoda/kodiaq/2generation/344546/ | – |
| E3 | https://airbus.com/en/products-services/helicopters/civil-helicopters/h135/h135-technical-information | – |
| E4 | https://www.seenotretter.de/fileadmin/seenotretter/PDFs/46-Meter-Seenotrettungskreuzer.pdf | height: the shipyard's side view |
| F1 | https://www.rosenbauer.com/en-us/news/deliveries/panther-8x8-auckland~d-8761 | km/h: Rosenbauer brochure |
| F2 | https://www.goldhofer.com/en/towbarless-tractors-ast-1x | the data sheet and dimension drawing |
| F3 | https://assets.new.siemens.com/siemens/assets/api/uuid:52495109232b1176df25668b35daa19243bf8b58/electric-bus-for-airports-en.pdf | – |
| F4 | https://www.mototok.com/hubfs/downloads/Model-Overview.pdf (TWIN 7500 NG Flat) | – |
| G1 | https://www.mercedes-benz-trucks.com/int/en/trucks/eeconic.html | – |
| G2 | https://d3v9db8ug40up8.cloudfront.net/s3fs-public/2020-08/2020-08_citycat-5006_specification_de.pdf | – |
| G3 | https://www.mercedes-benz-trucks.com/int/en/trucks/unimog-implement-carrier.html | – |
| G4 | Goupil data sheet (PS, km/h) | weight and dimensions: a rental company |
| H1 | https://stpi.it.volvo.com/STPIFiles/Volvo/ModelRange/fh84tp6a_che_gerch.pdf | – |
| H2 | https://www.petersoncat.com/sites/default/files/products/documents/1495808649.pdf (AEHQ5884-07) | – |
| H3 | https://en.wikipedia.org/wiki/BelAZ_75710 | Lectura |
| H4 | https://www.tii-group.com/tii-scheuerle/our-solutions/spmt/scheuerle-spmt | km/h empty: an unofficial data sheet |

## Translations
| Key | de | en | fr | es | zh | ar | fa |
|---|---|---|---|---|---|---|---|
| deck | Sonderfahrzeuge | Special vehicles | Véhicules spéciaux | Vehículos especiales | 特种车辆 | مركبات خاصة | خودروهای ویژه |
| A | Feuerwehr | Fire brigade | Pompiers | Bomberos | 消防 | الإطفاء | آتش‌نشانی |
| B | Baustelle | Construction | Chantier | Obras | 工地 | البناء | ساختمانی |
| C | Kräne | Cranes | Grues | Grúas | 起重机 | الرافعات | جرثقیل‌ها |
| D | Landwirtschaft | Farming | Agriculture | Agricultura | 农业 | الزراعة | کشاورزی |
| E | Rettung | Rescue | Secours | Rescate | 救援 | الإنقاذ | امداد |
| F | Flughafen | Airport | Aéroport | Aeropuerto | 机场 | المطار | فرودگاه |
| G | Stadtreinigung | Street cleaning | Propreté urbaine | Limpieza urbana | 环卫 | النظافة | پاکبانی |
| H | Schwertransport | Heavy haulage | Convoi exceptionnel | Transporte pesado | 重型运输 | النقل الثقيل | حمل سنگین |
| E1 | Rettungswagen Sprinter | Ambulance Sprinter | Ambulance Sprinter | Ambulancia Sprinter | 救护车 Sprinter | سيارة إسعاف Sprinter | آمبولانس Sprinter |
| E2 | Notarztwagen Kodiaq | Emergency doctor car Kodiaq | Véhicule médical Kodiaq | Vehículo médico Kodiaq | 急救医生车 Kodiaq | سيارة الطبيب Kodiaq | خودروی پزشک Kodiaq |
| E4 | Seenotretter Hermann Marwede | Lifeboat Hermann Marwede | Canot de sauvetage Hermann Marwede | Bote salvavidas Hermann Marwede | 救生船 Hermann Marwede | قارب النجاة Hermann Marwede | قایق نجات Hermann Marwede |

Machine translations like the other decks; a native-speaker review is open. Soft hyphens in the German card names
("Rettungs-wagen", "Not-arzt-wagen", "Seenot-retter"); set names have none (the set line is cut with "…"). The stat
labels and units exist already (no new keys).

## Decisions in the code
- **Stat ids:** all five exist; label, unit and direction match the other decks (engine test). Only `decimals`
  differs: `massT` 1 (trains 0), `heightM` 2 (rockets 1). Trailing zeros drop like in every deck ("4 m", "3,92 m",
  "48 t"); `fixedDecimals` would show "4,00 m" and "48,0 t" if the maintainer prefers that (format only, no
  fingerprint change).
- **Card names:** the engine name is the German one with the type word; the app translates E1, E2 and E4
  (`localizedCardName`, keys `quartettSpecialE1/E2/E4`); the fingerprint hashes the engine names only.
- **Deck picker:** blue (set F) for the seventh deck. Seven decks still fit 360×640 without scrolling.
- **Pictogram:** one deck pictogram, a fire engine with a turntable ladder (body with lockers, cab with window and
  light bar, the ladder on the roof, three wheels); no per-set pictograms.

## Photos
`klunki/tool/card_media/special.json` pins a Commons file per card where a free photo was found (licence checked on
the file page: CC BY, CC BY-SA, CC0 or public domain only), `""` where none fits. Not fetched yet: the maintainer's
session runs `python3 -I klunki/tool/fetch_card_media.py special`, then `special` goes into `_mediaDecks`
(`klunki/test/ui/games/quartett_media_test.dart`) and every photo is checked by eye. Until then the deck has no
media entry and no "Bildnachweise" button, and every card shows the pictogram.

- **A Commons file pinned (26):** A1, A3, B1–B4, C2, C4, D1–D4, E1, E3, E4, F1, F3, F4, G1–G4, H1–H4.
  - Exact model: A1, A3, B2, B4 (Bauma fair), C2, C4, D1–D4, E1 (Johanniter RTW, WAS body), E3 (ADAC Christoph 46),
    E4, F3 (electric e.Cobus), F4, G1 (with refuse body), G2, G3 (with snow blower), G4, H1, H3, H4 (carrying a ship
    section).
  - Nearest model: B1 (generation not stated), B3 (D11T), F1 (2011 Panther 8×8, previous generation), H2 ("797",
    generation unknown).
- **No photo, `""` (6):** A2 M64L and C3 GR-1000XL (nothing on Commons), C1 (no file names an LTM 11200-9.1), A4
  Wolf R1 (the only photos show a missile-strike scene: not for a children's card), F2 AST-1X (company uploads
  without VRT permission), E2 (no German NEF Kodiaq; the Czech doctor car comes from an organisation account without
  VRT permission).
- **Wikipedia:** most models have no article; the link then goes to the maker (Magirus, Liebherr, Fendt, …) or the
  vehicle type (Backhoe loader, Ambulance, Self-propelled modular transporter). H1: recheck the licence line when
  fetching (the proposal had seen a conflicting NC note on a Popp photo).

## Screenshots
`KLUNKI_SHOTS=<dir> flutter test test/screenshots/quartett_special_shots_test.dart` (group `kld130`): deck picker
(de 390×844; de and fr 360×640), gallery (deck list top and end, special vehicle sets in de/en/ar), full cards (E4
de/fr, E2 en, E1 ar, C1 de, F4 en, A1 de), Trumpf table and comparison on Gewicht (de/en/ar phone) and Höhe (de
320×640), Sets hand (de).

## Open
- Photos (fetch and eye check), the zh font subset.
- Native-speaker review of the set and card names (fr, es, zh, ar, fa).

## Constraints
- No military vehicles; generic wording in texts, manufacturer and model names only on the cards.
- No Flutter in the engine; deterministic; a deck data change after release bumps `QuartettDeck.revision`.
- Stat ids keep one meaning across decks (label, unit, direction); only `decimals` may differ per deck.
