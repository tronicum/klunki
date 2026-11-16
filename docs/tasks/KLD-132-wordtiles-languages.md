# KLD-132: Wortgewandt in French, Spanish, Arabic and Persian

- **ID:** `KLD-132`
- **Title:** Word lists and tile sets for fr, es, ar, fa in the word tile game (`wordtiles`)
- **Milestone:** M3
- **Status:** DONE
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
- [x] Engine: per tile set normalisation (fold table), fixed alphabet order (blank picker, bag), a right-to-left flag
      (ar, fa: a word across is read from right to left; down stays top to bottom; the board stays geometrically
      the same). de and en behave exactly as before (same deal from the same seed, same words).
- [x] One rules version bump for all of it (wordtiles rules 6 → 7), fingerprint goldens updated.
- [x] Word lists for fr, es, ar, fa built reproducibly by `klunki/tool/build_word_lists.py` (standard library only;
      Hunspell affixes expanded by our own `hunspell_expand.py`, tested against hand-made affix cases), with
      `SOURCE.txt` (URL, version/commit, date, sha256, filters, counts) and `LICENSE`; loaded on demand, not
      precached in the PWA.
- [x] Tile sets derived from the letter frequencies of each filtered list (the KLD-094 method, no brand's set),
      recomputed and pinned in `word_tiles_test.dart`.
- [x] Language picker for six languages; the rack and the bench run right to left for ar/fa; hint that words across
      are read from right to left; strings in 7 locales.
- [x] Licence page in the app and `docs/legal/third-party-data.md` list the four new sources.
- [x] Live-UI / widget game in each new language (ar and fa including the right-to-left rack); screenshots.

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
| ar: proclitics و ف ب ل ك | dropped; article ال kept (*default*) |
| ar: attached pronouns (كتابه, كتبه) and the future prefix س | dropped (*default*): with them the list has 5 million words (12.5 MB gzip) |
| ar: names | the names section of the Ayaspell dictionary dropped |
| ar: folding | vowel marks and tatweel removed, أ إ آ ٱ → ا, ؤ → و, ئ → ي, ى → ي (*default*), ة and ء tiles of their own |
| fa: آ | a tile of its own (*default*) |
| fa: folding | vowel marks, tatweel and ZWNJ removed, ك → ک, ي ى → ی, ة → ه, أ إ ٱ → ا, ؤ → و, ئ → ی (*default*) |
| fa: possessive and copula clitics (کتابم, خوبم) | dropped (*default*): with them 1.2 million words (3.1 MB gzip) |
| fa: offensive and foreign words | dropped (Lilak lexicon marks); Lilak has no proper-noun class, so some names stay; Hazm (MIT) fetched but not used (no proper-noun tag either) |
| fr: filters | proper nouns (uppercase), sub-dictionary X (rare variants), symbols, abbreviations without a vowel (VS, PT), slurs (note "péj") dropped (*default*) |
| es: filters | `Locuciones.txt` (multi-word phrases) skipped |
| Blanks in the view (ar, fa) | a caseless script cannot mark a blank by a lowercase letter: the view JSON lists the blank squares (`blanks`) |
| Release | all four languages with one rules bump (6 → 7) |

## Notes
Word lists (`SOURCE.txt` in each folder has the hashes, filters and counts by length):

| Lang | Words | gzip | Stems in the source |
|---|---|---|---|
| fr | 406,224 | 966,084 B | Grammalecte lexicon (all flexions listed) |
| es | 563,033 | 1,303,983 B | RLA-ES RAE word files + affixes |
| ar | 827,435 | 2,096,014 B | Ayaspell `ar.dic` + `ar.aff` |
| fa | 402,334 | 1,069,724 B | Lilak `fa-IR.dic` + `fa-IR.aff` |

Tile sets (98 letters + 2 blanks; letter: count/points; counted in each list, words of 2–8 letters):

- **fr** E 14/1, A 11/1, S 8/1, I 8/1, R 8/1, T 6/1, N 5/1, O 5/1, U 4/2, L 4/2, C 4/2, M 3/2, P 2/2, D 2/2,
  G 2/3, B 2/3, F H V Z 1/3, Y Q X J 1/5, K 1/6, W 1/10
- **es** A 15/1, E 11/1, R 8/1, S 8/1, O 7/1, I 6/1, N 5/1, L D C T 4/1, U 3/1, M 3/2, P B 2/2, G V H 1/2,
  F J Z Ñ 1/3, Q Y X 1/4, K 1/6, W 1/8
- **ar** ا 16/1, ي 11/1, ت 10/1, ن 9/1, ل 7/1, م 6/2, و 5/2, ر 4/2, ب 3/3, ف س ع د ق ح 2/3,
  ج ش ك ه ط ص ز خ 1/4, ة ض غ 1/5, ذ ث 1/6, ظ 1/8, ء 1/10
- **fa** ی 14/1, ا 13/1, ن 8/1, ر 7/1, ه 6/1, م 5/2, د ب و ت 4/2, ل 3/2, س 3/3, ک ش 2/3, ز ف گ 1/3,
  خ پ ق ج ع 1/4, ح آ چ ص ط غ 1/5, ض 1/6, ذ ژ ث 1/8, ظ 1/10

Tests: `word_tiles_languages_test.dart` (engine: sets, normalisation, right-to-left reading, view/replay),
`wordtiles_word_lists_test.dart` (every bundled word normalized and spellable, samples in and out),
`wordtiles_screen_test.dart` (ar/fa rack right to left, a word across laid from the right),
`test/e2e/live_ui/wordtiles_languages_live_test.dart` (a whole game per language with its list; every run across
on the final board, read in the set's direction, is a word of the game), screenshots
`--plain-name kld132` in `test/screenshots/wordtiles_languages_shots_test.dart`.

Open (native-speaker review): the *default* decisions above; Arabic two-letter words include odd short verb forms
from the affix expansion; some Persian names remain; the rarity of W and K in Spanish squeezes the point scale (W 8,
not 10). de and en tiles were not recalculated (that would change existing seeds and tests).
