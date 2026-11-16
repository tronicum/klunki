# KLD-132: Wortgewandt in French, Spanish, Arabic and Persian

- **ID:** `KLD-132`
- **Title:** Word lists and tile sets for fr, es, ar, fa in the word tile game (`wordtiles`)
- **Milestone:** M3
- **Status:** IN_PROGRESS
- **Depends on:** KLD-094 (word tile game, word lists step 4, network step 6), KLD-072 (engine PRNG), KLD-085
  (fingerprint)
- **Touched paths:**
  - `packages/klunki_engine/lib/word_tiles.dart` (tile sets, per-set normalisation, alphabet order, right-to-left
    reading, word list revisions), `packages/klunki_engine/lib/registry.dart` (rules version 7), engine tests,
    `compat_test.dart` goldens
  - `klunki/tool/build_word_lists.py` (+ `klunki/tool/hunspell_expand.py` and its tests)
  - `klunki/assets/wordlists/{fr,es,ar,fa}/{words.txt.gz,LICENSE,SOURCE.txt}`, `klunki/pubspec.yaml`,
    `klunki/web/pwa_finalize.py`
  - `klunki/lib/ui/games/wordtiles/**` (language picker, right-to-left rack and bench),
    `klunki/lib/app/third_party_licenses.dart`, `klunki/lib/l10n/**`
  - `docs/legal/third-party-data.md`, `CHANGELOG.md`, tests and screenshots

## Goal
Wortgewandt can be played in French, Spanish, Arabic and Persian, with a bundled word list ("Wörterbuch prüfen")
and a tile set of our own for each language. The language is chosen per game; it defaults from the app language
(de → Deutsch, en → English, fr → Français, es → Español, ar → العربية, fa → فارسی, zh → English: a letter tile
game does not fit Chinese characters, so there is no zh list). Basis: the maintainer-approved research proposal
"Wortgewandt: Wortlisten für fr, es, ar, fa (und zh)" (2026-11-15).

## Acceptance criteria
- [ ] Engine: per tile set normalisation (fold table), fixed alphabet order (blank picker, bag), a right-to-left flag
      (ar, fa: a word across is read from right to left; down stays top to bottom; the board stays geometrically
      the same). de and en behave exactly as before (same deal from the same seed, same words).
- [ ] One rules version bump for all of it (wordtiles rules 6 → 7), fingerprint goldens updated.
- [ ] Word lists for fr, es, ar, fa built reproducibly by `klunki/tool/build_word_lists.py` (standard library only;
      Hunspell affixes expanded by our own `hunspell_expand.py`, tested against hand-made affix cases), with
      `SOURCE.txt` (URL, version/commit, date, sha256, filters, counts) and `LICENSE`; loaded on demand, not
      precached in the PWA.
- [ ] Tile sets derived from the letter frequencies of each filtered list (the KLD-094 method, no brand's set),
      recomputed and pinned in `word_tiles_test.dart`.
- [ ] Language picker for six languages; the rack and the bench run right to left for ar/fa; hint that words across
      are read from right to left; strings in 7 locales.
- [ ] Licence page in the app and `docs/legal/third-party-data.md` list the four new sources.
- [ ] Live-UI / widget game in each new language (ar and fa including the right-to-left rack); screenshots.

## Decisions
Taken from the proposal; the ones marked *default* were left open there and are decided by its recommendation,
**native-speaker review pending**.

| Topic | Decision |
|---|---|
| fr source | Grammalecte lexicon 7.7 (MPL-2.0), all spelling variants (classic + 1990 reform) |
| es source | RLA-ES `ortografia/palabras/RAE/*.txt` + `afijos/afijos.txt` (GPL-3.0-or-later chosen from GPL/LGPL/MPL) |
| ar source | Ayaspell (hunspell-ar) via LibreOffice dictionaries (GPL-3.0 chosen via "GPL 2.0 or later") |
| fa source | Lilak 3.3 via LibreOffice dictionaries (Apache-2.0) + Lilak lexicon for the offensive/foreign filter |
| zh | no tile set, no list; zh UI defaults to English tiles |
| es: double enclitic pronouns (*cómetelo*) | allowed (*default*) |
| es: Ñ | a tile of its own; no digraph tiles (CH, LL, RR) |
| fr: accents | folded (É → E, Ç → C, Œ → OE …), apostrophe and hyphen words dropped |
| ar: proclitics و ف ب ل ك | dropped; article ال kept (*default*); pronoun suffixes kept |
| ar: folding | vowel marks and tatweel removed, أ إ آ ٱ → ا, ؤ → و, ئ → ي, ى → ي (*default*), ة and ء tiles of their own |
| fa: آ | a tile of its own (*default*) |
| fa: folding | vowel marks, tatweel and ZWNJ removed, ك → ک, ي ى → ی, ة → ه, أ إ ٱ → ا, ؤ → و, ئ → ی (*default*) |
| Release | all four languages with one rules bump (6 → 7) |

## Notes
(filled in as the stages land: list sizes, tile tables, open questions)
