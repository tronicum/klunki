# KLD-130: Quartett deck "Sonderfahrzeuge" (special vehicles)

- **ID:** `KLD-130`
- **Title:** A seventh Quartett deck, "Sonderfahrzeuge": 32 special-purpose vehicles with sourced values
- **Milestone:** M3
- **Status:** TODO (proposal written, waiting for the maintainer's approval of cards and stats)
- **Depends on:** KLD-069 (decks), KLD-082/084 (photo pipeline), KLD-085 (fingerprint), KLD-092 (hyphenated
  labels), KLD-110 (number grouping), KLD-127 (legal notice), KLD-128/129 (picker room, `localizedCardName`)
- **Touched paths (planned):**
  - `packages/klunki_engine/lib/quartett_decks.dart` (new deck), engine tests, `compat_test.dart` goldens
  - `klunki/lib/ui/engine_l10n.dart` (deck and set names)
  - `klunki/lib/ui/games/{quartett_deck_picker,quartett_pictograms}.dart`
  - `klunki/lib/l10n/**` (9 keys × 7 locales, more if card names get a type word), `klunki/tool/card_media/special.json`
  - `klunki/test/ui/games/{quartett_decks,quartett_media}_test.dart`, `klunki/test/ui/quartett_legal_test.dart`,
    `klunki/test/l10n/translations_test.dart`, `klunki/test/screenshots/quartett_special_shots_test.dart`

## Goal
A Quartett deck about special-purpose vehicles: 32 cards in 8 sets chosen by the maintainer (Feuerwehr, Baustelle,
Kräne, Landwirtschaft, Rettung, Flughafen, Stadtreinigung, Schwertransport), no military vehicles. The deck uses
only stats that all 32 vehicles have and that compare fairly, each value with a named source (manufacturer,
press/database, or a marked estimate). Real model names, untranslated like the other vehicle decks.

## Step 1: proposal (this step)
The proposal "Deck Sonderfahrzeuge", version 1 (2026-11-15), was handed to the maintainer as a German document
(kept outside the repo, like the KLD-128/129 proposals). Summary:

- **5 stats, all existing ids, so no new stat translations:** `ps` Leistung (↑), `kmh` Höchstgeschwindigkeit (↑),
  `massT` Gewicht (t, 1 decimal, **lower wins** like the trains), `lengthM` Länge (m, 1 decimal), `heightM` Höhe
  (m, **2 decimals**: with 1 decimal the 4 m legal height limit gives 4.0 % ties).
- **Rejected:** Hubraum (electric vehicles), Drehmoment (not published for excavators, cranes, helicopter, ship),
  seats/crew (ties, a remote-controlled tug has none), width (2.55 m legal limit), tank/range, price, a set-specific
  "special" stat.
- **Weak spot:** no fire truck, box ambulance or heavy-haulage tractor has a published top speed; 5 of 32 km/h
  values are estimates (legal limiter, a tender spec, the sister model's figure). Alternatives are in the proposal
  (drop km/h for "PS je Tonne", or swap those cards).
- **Cards (draft):**
  - Feuerwehr: Magirus M32L-AS, Magirus M64L, Rosenbauer RT, Magirus Wolf R1
  - Baustelle: Caterpillar 320, JCB 3CX, Caterpillar D11, Volvo A60H
  - Kräne: Liebherr LTM 11200-9.1, Liebherr LTM 1090-4.2, Tadano GR-1000XL-4, Liebherr MK 140
  - Landwirtschaft: Fendt 1052 Vario, John Deere 9RX 830, Claas Lexion 8900, Fendt 211 Vario
  - Rettung: RTW on Mercedes-Benz Sprinter, NEF on Škoda Kodiaq, Airbus H135, rescue cruiser Hermann Marwede
  - Flughafen: Rosenbauer Panther 8×8, Goldhofer AST-1X, e.COBUS 3000, Mototok Twin 7500
  - Stadtreinigung: Mercedes-Benz eEconic, Bucher CityCat 5006, Mercedes-Benz Unimog U 530, Goupil G4
  - Schwertransport: Volvo FH16 780, Caterpillar 797F, BelAZ 75710, Scheuerle SPMT
- **Tie rates (draft values, 496 pairs):** ps 0.40 %, kmh 2.22 %, massT 0.40 %, lengthM 0.40 %, heightM 2.02 %. The
  margin on kmh and heightM is small: recompute after every change.
- **Balance (share of comparisons won, weight lower wins):** sets between 41 % (Stadtreinigung) and 63 % (Rettung);
  with "heavier wins" it would be 33–70 %.
- **Commons photos:** 25 yes, 5 unclear, 2 no (M64L, GR-1000XL-4).

Open decisions for the maintainer: km/h with estimates; weight direction; helicopter and ship in "Rettung";
eEconic chassis dimensions; SPMT vs Liebherr T 284; BelAZ 75710; card names with or without a translated type word
(RTW, NEF, Seenotretter); deck id; "Stand 2025/2026" in the doc comment.

## Acceptance criteria (after approval)
- [ ] Engine deck (revision 1) with the approved stats and 32 cards; validation passes, tie rate < 3 % and > 16
      distinct values per stat; compat goldens for `quartett-trumpf/<id>` and `quartett-sets/<id>`; the other
      decks' fingerprints are unchanged.
- [ ] Deck name and the 8 set names in all 7 locales (plus card names if the maintainer wants type words).
- [ ] Drawn pictogram for cards without a photo; a preview colour in the deck picker. Seven decks and "Spielen" fit
      a 360×640 phone without scrolling (screenshot).
- [ ] Photos from Wikimedia Commons (CC BY / CC BY-SA / CC0 / public domain only) via
      `klunki/tool/card_media/special.json`, fetched with the maintainer's OK; every photo checked by eye.
- [ ] zh web font subset updated if new characters are needed (with the maintainer's OK).
- [ ] Card values and sources documented in this card, as in KLD-129; `CHANGELOG.md` under `[Unreleased]`.
- [ ] Screenshots `kld130` (picker, gallery, full cards, Trumpf comparison, Sets hand).

## Constraints
- No military vehicles; generic wording in texts, manufacturer and model names only on the cards.
- No Flutter in the engine; deterministic; a deck data change after release bumps `QuartettDeck.revision`.
- Stat ids keep one meaning across decks (label, unit, direction); only `decimals` may differ per deck.
