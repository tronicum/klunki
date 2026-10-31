# KLD-084 — Quartett photos and Wikipedia links for planes, trains and cars

- **ID:** `KLD-084`
- **Title:** The KLD-082 media pipeline (Wikipedia links, free-licence Wikimedia Commons photos, credits) applied to the other three Quartett decks
- **Milestone:** M3 (content)
- **Status:** planes ✅ · trains open · cars open (one commit per deck)
- **Depends on:** KLD-082 (pipeline, app UI, credit dialog, "Bildnachweise", PWA check)
- **Touched paths (per deck):**
  - `klunki/tool/card_media/<deck>.json` (chosen Commons files, article titles, author overrides, notes)
  - `klunki/assets/quartett/<deck>/**` (JPEGs + `credits.json`), `klunki/pubspec.yaml` (asset folder)
  - `klunki/lib/ui/games/quartett_media_data.dart` (generated)
  - `klunki/test/ui/games/quartett_media_test.dart` (data tests run per deck)

## Goal

Every Quartett card can show a real photo and link to its Wikipedia article,
as the rocket cards do since KLD-082. Same rules as there: only free
licences (public domain, CC0, CC BY, CC BY-SA, FAL, OGL, Licence Ouverte,
GODL-India; no NC/ND/fair use/GFDL-only), bundled ~480 px JPEGs ≤ 40 KB,
about 1.1 MB per deck, author/licence/source in `credits.json` and in the
app ("ⓘ" on the full card, "Bildnachweise" from the gallery). A card
without an acceptable free photo keeps its drawn pictogram. No app code
changed: the card, gallery and credit screens are generic since KLD-082.

## How (per deck)

1. `klunki/tool/card_media/<deck>.json`: en article per card (de from the
   interlanguage link unless given).
2. `python3 -I klunki/tool/fetch_card_media.py <deck> --candidates` lists
   the free images of the articles; the chosen file is set per card (lead
   images are often another variant, or GFDL-only), so the result is
   reproducible.
3. `python3 -I klunki/tool/fetch_card_media.py <deck>` writes the JPEGs,
   `credits.json` and the Dart data; every JPEG looked at.
4. `- assets/quartett/<deck>/` in `pubspec.yaml`; `_mediaDecks` in
   `quartett_media_test.dart`; `python3 -I klunki/tool/update_web_fonts.py subset`.

## Tests

`klunki/test/ui/games/quartett_media_test.dart`: the data group of KLD-082
now runs for every deck in `_mediaDecks` (complete, allowed credits; JPEGs
≤ 40 KB, no stray files, **deck folder ≤ 1.2 MB**; Wikipedia URLs; generated
Dart = `credits.json`; gallery photos and the "Bildnachweise" button).
New: exactly the collected decks have media data and an asset folder;
"Bildnachweise" lists every photo of every deck.

## Planes

32 of 32 cards have a photo. Licences: CC BY-SA 2.0 9, CC BY-SA 4.0 8,
Public domain 6 (USAF, NASA, the Wright brothers' 1903 photo, SDASM
archives, own-work release), CC BY-SA 3.0 4, CC BY 2.0 2, CC BY 4.0 1
(Japan Air Self-Defense Force), CC BY 3.0 1, FAL 1. Total: 32 JPEGs
920 318 B (largest 39 651 B) + `credits.json` 26 837 B = **947 155 B**.

Choices other than the article's lead image: A3 a 777-300ER (lead: a
777-200), B2 a 737 MAX 8 (lead: a MAX 9), B4 an E195-E2 (lead: an
E190-E2), H1 Solar Impulse 2 (lead: Solar Impulse 1), F1 and F4 (lead
images GFDL-only), G2 (a flying Blériot XI instead of the Swedish
Thulin A licence build). G4 is the flying Junkers F 13 replica HB-RIM.
Author overrides: A3 (Commons gives 航空自衛隊), E3, F1, G3 (cleaned up
names). German articles: B1 → Airbus-A320-Familie, B4 →
Embraer-E-Jet-Familie (no interlanguage link); F2 Learjet 75 has no
German article (English only); A2/E3 link the general de "Boeing 747"
article (no separate one).

| Card | Name | Commons file | Author | Licence | SA | Wikipedia |
|---|---|---|---|---|---|---|
| A1 | Airbus A380-800 | [A6-EDY A380 Emirates 31 jan 2013 jfk (8442269364) (cropped).jpg](https://commons.wikimedia.org/wiki/File:A6-EDY_A380_Emirates_31_jan_2013_jfk_(8442269364)_(cropped).jpg) | Maarten Visser from Capelle aan den IJssel, Nederland | [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0) | yes | [de](https://de.wikipedia.org/wiki/Airbus_A380) · [en](https://en.wikipedia.org/wiki/Airbus_A380) |
| A2 | Boeing 747-8I | [D-ABYT at FRA.jpg](https://commons.wikimedia.org/wiki/File:D-ABYT_at_FRA.jpg) | Juke Schweizer | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Boeing_747) · [en](https://en.wikipedia.org/wiki/Boeing_747-8) |
| A3 | Boeing 777-300ER | [JASDF B777-300ER 80-1111 (1) (cropped).jpg](https://commons.wikimedia.org/wiki/File:JASDF_B777-300ER_80-1111_(1)_(cropped).jpg) | Japan Air Self-Defense Force | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0) | – | [de](https://de.wikipedia.org/wiki/Boeing_777) · [en](https://en.wikipedia.org/wiki/Boeing_777) |
| A4 | Airbus A350-900 | [EGLF - Airbus A350-941 - F-WZNW.jpg](https://commons.wikimedia.org/wiki/File:EGLF_-_Airbus_A350-941_-_F-WZNW.jpg) | Steve Lynes | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0) | – | [de](https://de.wikipedia.org/wiki/Airbus_A350) · [en](https://en.wikipedia.org/wiki/Airbus_A350) |
| B1 | Airbus A320neo | [IndiGo Airbus A320neo F-WWDG (to VT-ITI) (28915135713).jpg](https://commons.wikimedia.org/wiki/File:IndiGo_Airbus_A320neo_F-WWDG_(to_VT-ITI)_(28915135713).jpg) | BriYYZ from Toronto, Canada | [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0) | yes | [de](https://de.wikipedia.org/wiki/Airbus-A320-Familie) · [en](https://en.wikipedia.org/wiki/Airbus_A320neo_family) |
| B2 | Boeing 737 MAX 8 | [N8749Q Southwest Boeing 737 MAX-8.jpg](https://commons.wikimedia.org/wiki/File:N8749Q_Southwest_Boeing_737_MAX-8.jpg) | Tomás Del Coro | [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0) | yes | [de](https://de.wikipedia.org/wiki/Boeing_737) · [en](https://en.wikipedia.org/wiki/Boeing_737_MAX) |
| B3 | Airbus A220-300 | [Airbus A220-300.jpg](https://commons.wikimedia.org/wiki/File:Airbus_A220-300.jpg) | Romain COUPY | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Airbus_A220) · [en](https://en.wikipedia.org/wiki/Airbus_A220) |
| B4 | Embraer E195-E2 | [EC-NHA Embraer 195-E2 Binter arrecife 29-02-20.jpg](https://commons.wikimedia.org/wiki/File:EC-NHA_Embraer_195-E2_Binter_arrecife_29-02-20.jpg) | Rob Hodgkins | [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0) | yes | [de](https://de.wikipedia.org/wiki/Embraer-E-Jet-Familie) · [en](https://en.wikipedia.org/wiki/Embraer_E-Jet_E2_family) |
| C1 | Concorde | [British Airways Concorde G-BOAC 03.jpg](https://commons.wikimedia.org/wiki/File:British_Airways_Concorde_G-BOAC_03.jpg) | Eduard Marmet | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0) | yes | [de](https://de.wikipedia.org/wiki/Concorde) · [en](https://en.wikipedia.org/wiki/Concorde) |
| C2 | Tupolew Tu-144 | [Tupolev TU-144 (6060104119).jpg](https://commons.wikimedia.org/wiki/File:Tupolev_TU-144_(6060104119).jpg) | clipperarctic | [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0) | yes | [de](https://de.wikipedia.org/wiki/Tupolew_Tu-144) · [en](https://en.wikipedia.org/wiki/Tupolev_Tu-144) |
| C3 | Lockheed SR-71 | [Lockheed SR-71 Blackbird.jpg](https://commons.wikimedia.org/wiki/File:Lockheed_SR-71_Blackbird.jpg) | USAF / Judson Brohmer | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Lockheed_SR-71) · [en](https://en.wikipedia.org/wiki/Lockheed_SR-71_Blackbird) |
| C4 | North American X-15 | [X-15 flying.jpg](https://commons.wikimedia.org/wiki/File:X-15_flying.jpg) | U.S. Air Force | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/North_American_X-15) · [en](https://en.wikipedia.org/wiki/North_American_X-15) |
| D1 | Douglas DC-3 | [Douglas DC-3, SE-CFP.jpg](https://commons.wikimedia.org/wiki/File:Douglas_DC-3,_SE-CFP.jpg) | Towpilot | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/) | yes | [de](https://de.wikipedia.org/wiki/Douglas_DC-3) · [en](https://en.wikipedia.org/wiki/Douglas_DC-3) |
| D2 | Junkers Ju 52/3m | [Ju-Air Junkers Ju-52 in flight over Austria.jpg](https://commons.wikimedia.org/wiki/File:Ju-Air_Junkers_Ju-52_in_flight_over_Austria.jpg) | Bernd K | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Junkers_Ju_52%2F3m) · [en](https://en.wikipedia.org/wiki/Junkers_Ju_52) |
| D3 | Lockheed Super Constellation | [Lockheed L1049C CF-TGC TCA LAP 12.09.54 edited-2.jpg](https://commons.wikimedia.org/wiki/File:Lockheed_L1049C_CF-TGC_TCA_LAP_12.09.54_edited-2.jpg) | RuthAS | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0) | – | [de](https://de.wikipedia.org/wiki/Lockheed_Super_Constellation) · [en](https://en.wikipedia.org/wiki/Lockheed_L-1049_Super_Constellation) |
| D4 | De Havilland Dash 8-400 | [Hamburg Airport Widerøe Bombardier DHC-8-402Q LN-WDR (DSC08713).jpg](https://commons.wikimedia.org/wiki/File:Hamburg_Airport_Wider%C3%B8e_Bombardier_DHC-8-402Q_LN-WDR_(DSC08713).jpg) | MarcelX42 | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/De_Havilland_DHC-8) · [en](https://en.wikipedia.org/wiki/De_Havilland_Canada_Dash_8) |
| E1 | Antonow An-225 | [Antonov Design Bureau Antonov An-225 Mriya at Leipzig Halle (EDDP-LEJ).jpg](https://commons.wikimedia.org/wiki/File:Antonov_Design_Bureau_Antonov_An-225_Mriya_at_Leipzig_Halle_(EDDP-LEJ).jpg) | Myroslav Kaplun | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Antonow_An-225) · [en](https://en.wikipedia.org/wiki/Antonov_An-225_Mriya) |
| E2 | Antonow An-124 | [Антонов Ан-124 9773054055093, Москва - Домодедово RP2297.jpg](https://commons.wikimedia.org/wiki/File:%D0%90%D0%BD%D1%82%D0%BE%D0%BD%D0%BE%D0%B2_%D0%90%D0%BD-124_9773054055093,_%D0%9C%D0%BE%D1%81%D0%BA%D0%B2%D0%B0_-_%D0%94%D0%BE%D0%BC%D0%BE%D0%B4%D0%B5%D0%B4%D0%BE%D0%B2%D0%BE_RP2297.jpg) | Alex Beltyukov | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0) | yes | [de](https://de.wikipedia.org/wiki/Antonow_An-124) · [en](https://en.wikipedia.org/wiki/Antonov_An-124_Ruslan) |
| E3 | Boeing 747 Dreamlifter | [Boeing, N780BA, B747-409(LCF) Dreamlifter - PAE (19833251496).jpg](https://commons.wikimedia.org/wiki/File:Boeing,_N780BA,_B747-409(LCF)_Dreamlifter_-_PAE_(19833251496).jpg) | Eric Salard | [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0) | yes | [de](https://de.wikipedia.org/wiki/Boeing_747) · [en](https://en.wikipedia.org/wiki/Boeing_Dreamlifter) |
| E4 | Airbus Beluga XL | [Hamburg-Finkenwerder Airport Airbus Transport International Airbus A330-743L Beluga XL F-GXLH (DSC09365).jpg](https://commons.wikimedia.org/wiki/File:Hamburg-Finkenwerder_Airport_Airbus_Transport_International_Airbus_A330-743L_Beluga_XL_F-GXLH_(DSC09365).jpg) | MarcelX42 | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Airbus_Beluga_XL) · [en](https://en.wikipedia.org/wiki/Airbus_BelugaXL) |
| F1 | Cessna 172 | [Cessna 172S Skyhawk at Bristol Airport (England) 23Aug2014 arp.jpg](https://commons.wikimedia.org/wiki/File:Cessna_172S_Skyhawk_at_Bristol_Airport_(England)_23Aug2014_arp.jpg) | Adrian Pingstone | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Cessna_172) · [en](https://en.wikipedia.org/wiki/Cessna_172) |
| F2 | Learjet 75 | [G-ZNTH Learjet 75 LJ75 c n 45-540 - BZE (46212773245).jpg](https://commons.wikimedia.org/wiki/File:G-ZNTH_Learjet_75_LJ75_c_n_45-540_-_BZE_(46212773245).jpg) | Markus Eigenheer from Genève, Schweiz | [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0) | yes | [en](https://en.wikipedia.org/wiki/Learjet_70%2F75) |
| F3 | Gulfstream G650 | [G-ULFS Gulfstream G650 CVT 05-05-16 (27046023031) (cropped).jpg](https://commons.wikimedia.org/wiki/File:G-ULFS_Gulfstream_G650_CVT_05-05-16_(27046023031)_(cropped).jpg) | Rob Hodgkins | [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0) | yes | [de](https://de.wikipedia.org/wiki/Gulfstream_G650) · [en](https://en.wikipedia.org/wiki/Gulfstream_G650%2FG700%2FG800) |
| F4 | Pilatus PC-12 | [Pilatus PC-12 45 Jetfly LX-JFH (7358281460).jpg](https://commons.wikimedia.org/wiki/File:Pilatus_PC-12_45_Jetfly_LX-JFH_(7358281460).jpg) | Curimedia | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0) | – | [de](https://de.wikipedia.org/wiki/Pilatus_PC-12) · [en](https://en.wikipedia.org/wiki/Pilatus_PC-12) |
| G1 | Wright Flyer | [First flight2.jpg](https://commons.wikimedia.org/wiki/File:First_flight2.jpg) | John T. Daniels | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Wright_Flyer) · [en](https://en.wikipedia.org/wiki/Wright_Flyer) |
| G2 | Blériot XI | [Bleriot XI OTT 2013 D7N9461 004.jpg](https://commons.wikimedia.org/wiki/File:Bleriot_XI_OTT_2013_D7N9461_004.jpg) | Stefan Krause, Germany | [FAL](https://artlibre.org/licence/lal/en) | – | [de](https://de.wikipedia.org/wiki/Bl%C3%A9riot_XI) · [en](https://en.wikipedia.org/wiki/Bl%C3%A9riot_XI) |
| G3 | Spirit of St. Louis | [Spirit Of St Louis2.jpg](https://commons.wikimedia.org/wiki/File:Spirit_Of_St_Louis2.jpg) | Ad Meskens | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0) | yes | [de](https://de.wikipedia.org/wiki/Spirit_of_St._Louis) · [en](https://en.wikipedia.org/wiki/Spirit_of_St._Louis) |
| G4 | Junkers F 13 | [Replica Junkers F13 ‘HB-RIM’ (49789577598).jpg](https://commons.wikimedia.org/wiki/File:Replica_Junkers_F13_%E2%80%98HB-RIM%E2%80%99_(49789577598).jpg) | Alan Wilson from Peterborough, Cambs, UK | [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0) | yes | [de](https://de.wikipedia.org/wiki/Junkers_F_13) · [en](https://en.wikipedia.org/wiki/Junkers_F_13) |
| H1 | Solar Impulse 2 | [Solar Impulse SI2 pilote Bertrand Piccard Payerne November 2014.jpg](https://commons.wikimedia.org/wiki/File:Solar_Impulse_SI2_pilote_Bertrand_Piccard_Payerne_November_2014.jpg) | Milko Vuille | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Solar_Impulse) · [en](https://en.wikipedia.org/wiki/Solar_Impulse) |
| H2 | Hughes H-4 Hercules | [H-4 Hercules 2.jpg](https://commons.wikimedia.org/wiki/File:H-4_Hercules_2.jpg) | SDASM Archives | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Hughes_H-4) · [en](https://en.wikipedia.org/wiki/Hughes_H-4_Hercules) |
| H3 | Stratolaunch Roc | [230113- Stratolaunch Talon Photo Chase-091.jpg](https://commons.wikimedia.org/wiki/File:230113-_Stratolaunch_Talon_Photo_Chase-091.jpg) | Eva Folsom | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Scaled_Composites_Stratolaunch) · [en](https://en.wikipedia.org/wiki/Scaled_Composites_Stratolaunch) |
| H4 | Rutan Voyager | [Voyager aircraft return from non-stop trip around the world (EC87-0029-02).jpg](https://commons.wikimedia.org/wiki/File:Voyager_aircraft_return_from_non-stop_trip_around_the_world_(EC87-0029-02).jpg) | NASA Armstrong Flight Research Center / NASA/Thomas Harrop | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Rutan_Voyager) · [en](https://en.wikipedia.org/wiki/Rutan_Voyager) |
