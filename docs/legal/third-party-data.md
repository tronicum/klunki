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

Word list details (source URL, commit, date, hashes, filters, word counts): `klunki/assets/wordlists/*/SOURCE.txt`;
the build tool is `klunki/tool/build_word_lists.py`. The English list uses no size above 80 and no Australian-only
data, so only the main ESDB notice applies (not the UKACD or AU notices in the same file). Single words are facts;
we use licensed lists only, never scraped ones (EU database right, see the KLD-094 card).
