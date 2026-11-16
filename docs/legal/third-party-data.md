# Third-party data bundled with the app

What the app ships that is not our own work, and under which licence. The app's licence page
(`showLicensePage`, fed by `LicenseRegistry` in `klunki/lib/app/fonts.dart` and
`klunki/lib/app/third_party_licenses.dart`) shows every text listed here; Flutter adds the packages' own licences.

| Data | Where | Licence | Notice shown |
|---|---|---|---|
| Fonts: Roboto, Noto Sans Arabic, Noto Sans SC (subset), Noto Sans Math (subset) | `klunki/assets/fonts/*` | SIL OFL 1.1 | `OFL.txt` per family |
| zxing-cpp, libzint (native code in the QR scanner; iOS/Android only) | via `flutter_zxing` | Apache-2.0, BSD-3-Clause | `klunki/assets/licenses/*` |
| Quartett card photos | `klunki/assets/quartett/*` | per photo (Wikimedia Commons) | in the card's credits (KLD-082) |
| Word tile game word list, German (KLD-094) | `klunki/assets/wordlists/de/` | CC0-1.0 (enz/german-wordlist) | `LICENSE` (CC0 text) |
| Word tile game word list, English (KLD-094) | `klunki/assets/wordlists/en/` | MIT-like: "Copyright 2000-2026 by Kevin Atkinson", English Speller Database (formerly SCOWL); the notice must appear in all copies and the documentation | `LICENSE` (the project's `Copyright` file) |
| Word tile game word list, French (KLD-132) | `klunki/assets/wordlists/fr/` | MPL-2.0: Grammalecte lexicon 7.7, Olivier R. and the Dicollecte contributors; our filtered, folded list stays under the MPL 2.0, its source form is the published lexicon | `LICENSE` (our note, the lexicon's README, MPL 2.0 text) |
| Word tile game word list, Arabic (KLD-132) | `klunki/assets/wordlists/ar/` | Ayaspell / hunspell-ar (Mohamed Kebdani, Taha Zerrouki), offered under GPL-2.0+ / LGPL-2.1+ / MPL-1.1+; we use the GPL version 3 | `LICENSE` (our note, `COPYING.txt`, `AUTHORS.txt`, GPL 3 text) |
| Word tile game word list, Persian (KLD-132) | `klunki/assets/wordlists/fa/` | Apache-2.0: Lilak, Copyright 2015 Mostafa Sedaghat Joo; modified (expanded, filtered, folded), as our note says | `LICENSE` (our note, Lilak's notice, Apache 2.0 text) |
| Word tile game word list, Spanish (KLD-132) | `klunki/assets/wordlists/es/` | RLA-ES, "Santiago Bosio y otros", offered under GPL-3.0+ / LGPL-3.0+ / MPL-1.1+; we use GPL-3.0-or-later (compatible with the app's AGPL-3.0) | `LICENSE` (our note, the project's `LICENSE.md`, GPL 3 text) |

Word list details (source URL, commit, date, hashes, filters, word counts): `klunki/assets/wordlists/*/SOURCE.txt`;
the build tool is `klunki/tool/build_word_lists.py`. The English list uses no size above 80 and no Australian-only
data, so only the main ESDB notice applies (not the UKACD or AU notices in the same file). Single words are facts;
we use licensed lists only, never scraped ones (EU database right, see the KLD-094 card). KLD-132 (fr, es, ar, fa):
the Hunspell sources are expanded by our own `klunki/tool/hunspell_expand.py`; copyleft data (MPL, GPL) keeps its
licence in the derived list, whose source and build steps are public in this repository.
