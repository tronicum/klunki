# KLD-127: "Rechtliche Hinweise" for the Quartett cards

- **ID:** `KLD-127`
- **Title:** Trademark notice for the names on the Quartett cards, linked from the cards, the game and About
- **Milestone:** M3
- **Status:** DONE
- **Depends on:** KLD-069 (decks, gallery), KLD-082 (card photos), KLD-102 (About screen)
- **Touched paths:**
  - `klunki/lib/ui/quartett_legal_screen.dart` (new: page, small link, menu entry)
  - `klunki/lib/ui/games/{quartett_deck_picker,quartett_gallery,quartett_trumpf_screen,quartett_sets_screen}.dart`
  - `klunki/lib/ui/about_screen.dart`, `klunki/lib/l10n/**`
  - `klunki/test/ui/quartett_legal_test.dart`, `klunki/test/screenshots/quartett_legal_shots_test.dart`

## Goal
The Quartett decks name real manufacturers and products, which may be trademarks. A short, plain notice
says so and that Klunki has no connection with them (App Store review). It is generic: valid for every deck
(cars, trains, rockets, planes and later ones), it never names a vehicle type.

German text (maintainer's wording, 2026-11-15):

> Namen von Herstellern und Produkten auf den Karten dienen nur zur Bezeichnung. Sie können Marken ihrer
> jeweiligen Inhaber sein. Klunki steht in keiner Verbindung zu diesen Herstellern und wird nicht von ihnen
> unterstützt.

Two more lines, checked against the code and data, so only what is true:

- "Die Fotos auf den Karten stammen von Wikimedia Commons und stehen unter freien Lizenzen. Wer sie
  aufgenommen hat, steht in den Bildnachweisen." Every card photo is a bundled Commons file under a free
  licence (`quartett_media_data.dart`, `docs/legal/third-party-data.md`). We do **not** say "no manufacturer
  photos": a few Commons files are credited to a maker or operator (e.g. SpaceX, Rocket Lab via NASA,
  Union Pacific), still under free licences.
- "Die kleinen Bilder neben dem Namen und auf der Rückseite der Karten hat Klunki selbst gezeichnet. Es sind
  keine Logos von Herstellern." The pictograms are drawn in code (`quartett_pictograms.dart`, KLD-069).

## Where the link is
- Deck picker (before a hot-seat game): small underlined text link "Rechtliche Hinweise" under
  "Karten ansehen" / "Spielen".
- Card gallery: the same link under the deck list and under the cards of each deck.
- In a Quartett game (Trumpf and Sets, hot-seat and network): "Rechtliche Hinweise" in the "⋮" menu; no link
  on each card.
- "Über Klunki": a "Rechtliche Hinweise · Quartett-Karten" entry between Impressum and Support.
- The page has a "Bildnachweise" button (the photo credits of all decks).

## Acceptance criteria
- [x] Page `QuartettLegalScreen` with the text in all 7 locales (zh wording uses only glyphs already in the
      web font subset; no subset rebuild).
- [x] Links in the deck picker, the gallery (deck list and deck), the game menu of both variants and About.
- [x] Widget tests: every link opens the page, the text is shown, no deck-specific word; ar is RTL
      (`test/ui/quartett_legal_test.dart`).
- [x] Screenshots `KLUNKI_SHOTS=… flutter test test/screenshots/quartett_legal_shots_test.dart` (de: gallery,
      page, picker, game menu, About; ar: gallery, page, About).

## Constraints
- Generic names only; no rules or protocol change (no rules version bump).
