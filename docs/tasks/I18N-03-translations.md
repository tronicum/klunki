# I18N-03: translations fr / es / zh / ar / fa

- **ID:** `I18N-03`
- **Title:** Translate all 200 ARB keys into French, Spanish, Simplified Chinese, Arabic and Farsi
- **Status:** DONE (machine-translated, native review pending)
- **Depends on:** I18N-01, I18N-02, I18N-04, I18N-05
- **Touched paths:**
  - `klunki/lib/l10n/app_{fr,es,zh,ar,fa}.arb`, generated `klunki/lib/l10n/app_localizations_{fr,es,zh,ar,fa}.dart`
  - `klunki/test/l10n/translations_test.dart` (new)

## Goal
Every key of the German template (`app_de.arb`) has a real translation in fr, es, zh (zh-Hans),
ar and fa. The English placeholders from I18N-02 are gone.

## Acceptance criteria
- [x] Source text: German; English used for meaning, `@key` descriptions for context.
- [x] `@@x-untranslated` removed from all five files; each has
      `"@@x-review": "machine translation, needs native-speaker review"`.
- [x] Placeholders and ICU plural structures unchanged (`strings_test.dart`).
- [x] Plurals per CLDR:
  - fr, es: `one` / `many` / `other` (`many` = millions, "1 000 000 de cartes"). fr `one` also covers 0 ("0 carte"), which is correct French.
  - ar: `zero` / `one` / `two` / `few` / `many` / `other` (بطاقة واحدة, بطاقتان, 3–10 بطاقات, 11+ بطاقة).
  - zh: `other` only.
  - fa: `=1` (یک) + `other`. CLDR `one` in fa also matches 0, so an explicit `=1` is used for the word "یک".
- [x] Informal address: tu (fr), tú (es), تو (fa); ar uses the usual masculine-singular imperative of app UIs.
- [x] Kept as is: brand "Klunki", player marks X / O, units km/h, kg, s, cm³ (en has "cc"), coordinates, IP examples, debug command `undo`.
      Power units are localized: ch (fr), CV (es), 马力 (zh), حصان (ar), اسب (fa; "اسب بخار" overflowed the stat row at phone width).
- [x] Digits stay Western in ar/fa (I18N-04 decision); no Eastern Arabic digits in the ARB text.
- [x] French typography: narrow no-break space before ! and ?, no-break space before : and inside « ».
- [x] `flutter gen-l10n` without warnings, `flutter analyze` clean, `flutter test` green (237 tests, 35 new).

## Term choices (generic names, no brands)

| Concept | fr | es | zh | ar | fa |
|---|---|---|---|---|---|
| Four in a Row | Quatre en ligne | Cuatro en raya | 四子棋 | أربعة في صف | چهار در یک ردیف |
| Mill | Jeu du moulin | Juego del molino | 九子棋 | الطاحونة | دوز نُه‌مهره |
| "Mill!" (closed a line) | Moulin ! | ¡Molino! | 成三！ | طاحونة! | دوز! |
| Quartett (Trumps) | Quartett (Atouts) | Quartett (Triunfos) | 四张卡（比大小） | الرباعيات (مقارنة) | کوارتت (مقایسه) |
| Quartett (Sets) | Quartett (Familles) | Quartett (Familias) | 四张卡（集套） | الرباعيات (مجموعات) | کوارتت (دسته‌ها) |
| a quartet (set of 4) | famille | familia | 一套 | رباعية | کوارتت |
| card back | QUARTETT | QUARTETT | 四张卡 | رباعيات | کوارتت |
| Go fish / Fehlanzeige | Pioche | Nada | 没有 | لا يوجد | ندارد |
| Sink the Fleet | Bataille navale | Hundir la flota | 海战棋 | معركة السفن | نبرد دریایی |
| ships 5/4/3/2 | Cuirassé / Croiseur / Contre-torpilleur / Sous-marin | Acorazado / Crucero / Destructor / Submarino | 战列舰 / 巡洋舰 / 驱逐舰 / 潜艇 | بارجة / طرّاد / مدمّرة / غوّاصة | ناو جنگی / رزمناو / ناوشکن / زیردریایی |

**Quartett:** fr/es keep the German name "Quartett" as the game's proper name (no common
generic local name for the car-trumps game; "Top Trumps" is a brand). Inside the Sets variant
the set of four is called by the local set-collecting term: fr "famille" (from the
Jeu des 7 familles), es "familia". zh/ar/fa get a readable local name instead of a Latin word:
zh 四张卡 ("four cards"), ar الرباعيات ("the quartets"), fa کوارتت (transliteration, common in Persian).

## Check first (native-speaker review priorities)
1. **fa Mühle name "دوز نُه‌مهره"** and "دوز!" for a closed mill: "دوز" is also tic-tac-toe; check that it reads as Nine Men's Morris.
2. **ar game names** "الطاحونة", "أربعة في صف", "معركة السفن", "الرباعيات" — are these the names people actually use?
3. **zh Quartett names** "四张卡（比大小）/（集套）" and **九子棋** for Mill (alternative: 直棋, 打三棋).
4. **fr "Quatre en ligne"** (avoiding the brand "Puissance 4") and **es "Nada"** for the Go-fish miss (alternative: "¡A pescar!").
5. **Plural forms in ar** (`quartettCards`, `schiffeMoveAutoplace`, zero form "لا بطاقات") and the gender of verbs after a player mark (ar uses masculine: يفوز، يختار).
6. **Quartett set names** (`engineSetA`–`H`), e.g. fr "Petites bombes", es "Pequeños bólidos", zh 小钢炮, ar "صواريخ صغيرة", fa "کوچک‌های تندرو".
7. **Ship names** in fa (ناو جنگی vs رزمناو) and the fr 3-cell ship "Contre-torpilleur" (length in the fleet list).
8. **Pairing / network strings** (host = "Héberger" / "Crear" / 创建 / استضافة / میزبانی).
9. Power unit abbreviations: ch, CV, 马力, حصان, اسب.

## Tests
- `test/l10n/strings_test.dart` (unchanged): every locale has every key with the same placeholders.
- `test/l10n/translations_test.dart` (new, 35 tests):
  - per locale: `@@locale` matches, `@@x-review` present, no `@@x-untranslated`, and no value identical to
    English except placeholder-only values ("{cell} {state}") and a small allowlist:
    Klunki, km/h, 0–100 km/h, kg, s, undo, QUARTETT, Menu, Horizontal, Vertical, "Point {point}, {player}".
  - per locale at 390×844: the menu renders without exceptions, and each of the five games is pumped and
    played to the result dialog without overflow or other exceptions.

## Notes
- Widget tests render with the Ahem test font (all glyphs one square wide), so the overflow check is an
  approximation for CJK/Arabic widths. A visual check on a device per locale is still worth doing.
- The I18N-04 font plan (web, offline zh/ar/fa glyphs) can now measure the real character set from these files.
