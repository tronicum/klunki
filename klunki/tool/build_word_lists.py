#!/usr/bin/env python3
"""Build the Wortgewandt word lists (KLD-094 step 4) from the approved sources. Manual tool, never run by a build.

Usage (from klunki/; standard library only, reproducible: same input -> same bytes):
    python3 -I tool/build_word_lists.py de <dir with enz/german-wordlist files: words, COPYING>
    python3 -I tool/build_word_lists.py en <dir with en-wl/wordlist files: scowl-pre.txt, Copyright> [--size 80]
    python3 -I tool/build_word_lists.py fr <lexique-grammalecte-fr-v7.7.txt> <MPL-2.0 licence text> <README_lexique.txt>
    python3 -I tool/build_word_lists.py es <extracted rla-es repository>
    python3 -I tool/build_word_lists.py check     # counts, samples and sizes of the bundled assets
    python3 -I tool/build_word_lists.py tiles <lang>   # letter frequencies of a bundled list and the derived tile set
(KLD-132 adds fr, es, ar, fa; the Hunspell affixes are expanded by tool/hunspell_expand.py, tested by
tool/hunspell_expand_test.py.)

The sources are downloaded by hand (curl, pinned commit, see assets/wordlists/*/SOURCE.txt) into a fresh
directory and treated as data: this script only reads them, it never runs anything from them.

Output: assets/wordlists/<lang>/words.txt.gz (gzip, mtime 0, UTF-8, one word per line, sorted by code point =
UTF-8 byte order, which the app's binary search relies on) plus LICENSE (copied from the source).
SOURCE.txt is written by hand (URL, commit, date, licence, filters).

Filters (every language), mirroring the engine's TileSet (packages/klunki_engine/lib/word_tiles.dart):
  * normalize like TileSet.normalize: fold with the set's table (FOLD below: ß -> SS; fr/es accents; Arabic and
    Persian vowel marks, tatweel, hamza seats, ZWNJ), then upper case;
  * keep words of 2-15 letters that the tile set can spell (TileSet.canSpell, LETTERS below);
    anything else (other letters, apostrophes, hyphens, spaces, digits, dots) drops the word.
de: enz/german-wordlist has no names, places or abbreviations by its own rules (README), so nothing else is dropped.
en: ESDB (SCOWL v2) `data/scowl-pre.txt`, parsed here (we do not run the project's make/Python tools):
  * size <= --size (default 80: 80 adds the word-game words such as AA, QI, ZA), counting only the sizes without a
    region or with US / GB / CA (no Australian-only data, so the AU copyright does not apply; no size above 80,
    so the UKACD copyright does not apply);
  * derived-form annotations raise the size like ESDB does (- @ -> 70, ~ -> 80, ! -> 85);
  * spelling variants: A B Z C _ (not D-only = Australian), variant levels up to V (acceptable) and @ (archaic);
    '-' (uncommon, not in standard dictionaries) and 'x' (misspelling) are dropped;
  * dropped: any word with an upper-case letter in the source (proper nouns, abbreviations), POS classes for names
    (person, surname, place, name, demonym, trademark, abbr, upper and their '?' forms), the POS abbr / pre / suf /
    wp / we / x / s (contractions), words without a vowel (A E I O U Y) unless ENABLE lists them (unit symbols such
    as CM, KG, ML come as nouns; HM, SH, BRR, TSK stay), and every group with an offensive-* or vulgar-* usage note.
"""
import gzip
import io
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hunspell_expand as hx  # noqa: E402  (our own module next to this file)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, 'assets', 'wordlists')

LANGS = ('de', 'en', 'fr', 'es', 'ar', 'fa')

LETTERS = {
    'de': set('ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ'),
    'en': set('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
    'fr': set('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
    'es': set('ABCDEFGHIJKLMNOPQRSTUVWXYZÑ'),
    # 28 letters plus taa marbuta and hamza on the line.
    'ar': set('ابتثجحخدذرزسشصضطظعغفقكلمنهوي' + 'ةء'),
    # 32 letters plus alef madda.
    'fa': set('ابپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی' + 'آ'),
}
MIN_LEN, MAX_LEN = 2, 15

# How a word is folded before it is upper-cased, per tile set; MUST equal TileSet.fold in
# packages/klunki_engine/lib/word_tiles.dart (an app test checks every bundled word against TileSet.normalize).
_SHARP_S = {'ß': 'SS', 'ẞ': 'SS'}


def _both_cases(table):
    out = {}
    for k, v in table.items():
        out[k] = v
        out[k.lower()] = v
    return out


_AR_MARKS = {c: '' for c in '\u064b\u064c\u064d\u064e\u064f\u0650\u0651\u0652\u0653\u0654\u0655\u0670\u0640'}
FOLD = {
    'de': _SHARP_S,
    'en': _SHARP_S,
    'fr': _both_cases({'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ç': 'C', 'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E', 'Î': 'I',
                       'Ï': 'I', 'Ô': 'O', 'Ö': 'O', 'Ù': 'U', 'Û': 'U', 'Ü': 'U', 'Ÿ': 'Y', 'Œ': 'OE', 'Æ': 'AE'}),
    'es': _both_cases({'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U'}),
    'ar': {**_AR_MARKS, 'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ؤ': 'و', 'ئ': 'ي', 'ى': 'ي', 'ک': 'ك', 'ی': 'ي'},
    'fa': {**_AR_MARKS, '\u200c': '', 'ك': 'ک', 'ي': 'ی', 'ى': 'ی', 'ة': 'ه', 'ۀ': 'ه', 'أ': 'ا', 'إ': 'ا',
           'ٱ': 'ا', 'ؤ': 'و', 'ئ': 'ی'},
}

SAMPLES = {
    'de': ['HÄUSER', 'LIEF', 'GINGEN', 'SCHÖNSTEN', 'STRASSE', 'FÜSSE', 'BÄUME', 'ÄRGERTEN', 'QI', 'XYLOFON'],
    'en': ['HOUSES', 'RAN', 'WENT', 'GOING', 'NICEST', 'COLOR', 'COLOUR', 'AA', 'QI', 'ZA', 'XU', 'QAT', 'ZAX'],
    'fr': ['MAISON', 'MAISONS', 'ETE', 'ALLIONS', 'IRONT', 'FUMES', 'NOEL', 'COEUR', 'OEUFS', 'CHEVAUX', 'FRAICHE',
           'FRAICHES', 'EVENEMENT', 'EVENEMENTS', 'DEJA', 'GARCON', 'OU', 'KIWI', 'ZOO'],
    'es': ['CASA', 'CASAS', 'NIÑO', 'NIÑOS', 'AÑO', 'CANTABAMOS', 'FUIMOS', 'DAMELO', 'CUENTAMELO', 'COMERTELO',
           'DIGASELO', 'ARBOL', 'ARBOLES', 'CORAZON', 'PINGUINO', 'ESPAÑOL', 'KILO', 'ZORRO'],
    'ar': ['كتاب', 'الكتاب', 'كتابه', 'كتب', 'مدرسة', 'المدرسة', 'مدارس', 'قمر', 'شمس', 'سماء', 'يكتب', 'كتبوا',
           'مسيء', 'سيارة'],
    'fa': ['کتاب', 'کتابها', 'خانه', 'آب', 'آسمان', 'مادر', 'پدر', 'بچه', 'چشم', 'میروم', 'رفتم', 'گل', 'ژاله'],
}
# Words that must not be in a list (proper nouns, abbreviations, clitic chains).
ABSENT = {
    'fr': ['BRUXELLES', 'QUEBEC', 'MARX', 'FRANCE', 'SNCF', 'KM', 'KG', 'ETC', 'QU', 'PEUTON', 'VS', 'PT'],
    'es': ['MADRID', 'ESPAÑA', 'CARLOS', 'KM', 'ONU', 'OTAN', 'UE'],
    'ar': ['وكتاب', 'بالكتاب', 'فكتب', 'لكتاب', 'ككتاب', 'مصر', 'محمد'],
    'fa': ['تهران', 'ایران'],
}


def normalize(word, lang='de'):
    """Like TileSet.normalize in the engine: fold, then upper case."""
    table = FOLD[lang]
    return ''.join(table.get(c, c) for c in word).upper()


def keep(lang, word):
    w = normalize(word, lang)
    return w if MIN_LEN <= len(w) <= MAX_LEN and set(w) <= LETTERS[lang] else None


# A short note above the licence texts of the derived lists (KLD-132): what the list is and which licence applies.
LICENSE_NOTE = {
    'fr': '''Klunki "Wortgewandt" word list (fr), derived from the Grammalecte French lexicon 7.7
("Lexique français, liste des formes fléchies", Olivier R. and the Dicollecte contributors, https://grammalecte.net/).
Changed by Klunki: forms filtered (no proper nouns, symbols, abbreviations), accents folded, upper case
(klunki/tool/build_word_lists.py). The list is distributed under the Mozilla Public License 2.0; the source form is
the lexicon at https://www.grammalecte.net/dic/lexique-grammalecte-fr-v7.7.zip. The lexicon's README and the MPL 2.0
text follow.
''',
    'es': '''Klunki "Wortgewandt" word list (es), derived from RLA-ES (Recursos lingüísticos abiertos del español),
Copyright 2004-2020 Santiago Bosio y otros, https://github.com/sbosio/rla-es (stems of ortografia/palabras/RAE and the
affixes of ortografia/afijos/afijos.txt, expanded and filtered by klunki/tool/build_word_lists.py, accents folded,
upper case). RLA-ES is offered under GPL-3.0-or-later, LGPL-3.0-or-later or MPL-1.1-or-later; Klunki uses it under
the GNU General Public License version 3 or later. The project's licence note and the GPL 3 text follow.
''',
}


def write_list(lang, words, license_texts):
    """Writes words.txt.gz and LICENSE ([license_texts]: the texts, joined by a blank line)."""
    out_dir = os.path.join(ASSETS, lang)
    os.makedirs(out_dir, exist_ok=True)
    data = ''.join(w + '\n' for w in sorted(words)).encode('utf-8')
    buf = io.BytesIO()
    with gzip.GzipFile(filename='', mode='wb', fileobj=buf, compresslevel=9, mtime=0) as gz:
        gz.write(data)
    with open(os.path.join(out_dir, 'words.txt.gz'), 'wb') as f:
        f.write(buf.getvalue())
    with open(os.path.join(out_dir, 'LICENSE'), 'wb') as dst:
        note = [LICENSE_NOTE[lang].encode('utf-8')] if lang in LICENSE_NOTE else []
        dst.write(b'\n\n'.join(t.rstrip(b'\n') for t in note + license_texts) + b'\n')
    print(f'{lang}: {len(words)} words, raw {len(data)} bytes, gzip {len(buf.getvalue())} bytes')


def read_bytes(path):
    with open(path, 'rb') as f:
        return f.read()


def build_de(src):
    words = set()
    total = 0
    with open(os.path.join(src, 'words'), encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            total += 1
            w = keep('de', line)
            if w:
                words.add(w)
    print(f'de: {total} source lines')
    write_list('de', words, [read_bytes(os.path.join(src, 'COPYING'))])


# --- ESDB (SCOWL v2) text format, see the project's README "File Format" ---

BAD_CLASSES = {'person', 'surname', 'place', 'name', 'demonym', 'trademark', 'abbr', 'upper',
               'name?', 'upper?', 'abbr?', 'person?', 'place?'}
BAD_POS = {'abbr', 'pre', 'suf', 'wp', 'we', 'x', 's'}
OK_SPELLINGS = set('ABZC_')
OK_LEVELS = set('.=?v~V@')  # plus '' (non-variant); not '-' (uncommon) or 'x' (invalid)
ANN_SIZE = {'-': 70, '@': 70, '~': 80, '!': 85}
VARIANT_TOKEN = re.compile(r'^([ABZCD_]?)([.=?v~V@x-]?)$')
VOWEL = re.compile(r'[AEIOUY]')
SIZE_TOKEN = re.compile(r'^\d+$')
LEMMA = re.compile(r'^(.*?)(?: <([^>]*)>)?(?: \{[^}]*\})?(?: \(([^)]*)\))?$')


def split_top(s, sep):
    """Splits s at sep outside parentheses."""
    parts, depth, cur, i = [], 0, [], 0
    while i < len(s):
        c = s[i]
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
        if depth == 0 and s.startswith(sep, i):
            parts.append(''.join(cur))
            cur = []
            i += len(sep)
            continue
        cur.append(c)
        i += 1
    parts.append(''.join(cur))
    return parts


def scowl_size(info):
    """Smallest size of the info segment, counting sizes without a region or with US / GB / CA."""
    best = None
    toks = info.split()
    i = 0
    while i < len(toks):
        t = toks[i]
        if SIZE_TOKEN.match(t):
            region = toks[i + 1] if i + 1 < len(toks) and toks[i + 1] in ('US', 'GB', 'CA', 'AU') else None
            if region != 'AU':
                n = int(t)
                best = n if best is None else min(best, n)
        i += 1
    return best


def variant_ok(info):
    """True if any token of a variant info ('A B=', '_~', '~') is an accepted spelling at an accepted level."""
    if info is None:
        return True
    for tok in info.split():
        if tok == '+':
            continue
        m = VARIANT_TOKEN.match(tok)
        if not m:
            return False
        spelling, level = m.groups()
        if (spelling == '' or spelling in OK_SPELLINGS) and (level == '' or level in OK_LEVELS):
            return True
    return False


def is_variant_info(seg):
    toks = seg.split()
    return bool(toks) and all(t == '+' or (VARIANT_TOKEN.match(t) and t) for t in toks)


def strip_ann(word):
    """(word, size floor) without leading group annotation / trailing annotations."""
    floor = 0
    while word and word[-1] in '*-@~!†':
        floor = max(floor, ANN_SIZE.get(word[-1], 0))
        word = word[:-1]
    while word and word[0] in '-@!' and len(word) > 1:
        floor = max(floor, ANN_SIZE.get(word[0], 0))
        word = word[1:]
    return word, floor


def parse_line(line):
    """-> (size, variant_info, lemma, pos, cls, usage, [entries]) or None."""
    hash_at = line.find(' #')
    if hash_at >= 0:
        line = line[:hash_at]
    line = line.rstrip()
    if not line or line.startswith('#'):
        return None
    segs = split_top(line, ': ')
    if len(segs) < 2:
        return None
    size = scowl_size(segs[0])
    rest = segs[1:]
    vinfo = None
    if len(rest) > 1 and is_variant_info(rest[0]):
        vinfo = rest[0]
        rest = rest[1:]
    m = LEMMA.match(rest[0])
    lemma, posinfo, usage = m.group(1), m.group(2) or '', m.group(3) or ''
    pos, _, cls = posinfo.partition('/')
    entries = split_top(': '.join(rest[1:]), ', ') if len(rest) > 1 else []
    return size, vinfo, lemma, pos, cls, usage, entries


def entry_words(entry):
    """(word, size floor) pairs of one derived entry, variant alternatives filtered."""
    entry = entry.strip()
    if entry.startswith('(') and entry.endswith(')'):
        out = []
        for alt in split_top(entry[1:-1], ' | '):
            info, sep, word = alt.rpartition(': ')
            if sep and not variant_ok(info):
                continue
            out.append(strip_ann(word.strip()))
        return out
    return [strip_ann(entry)]


def build_en(src, max_size):
    groups, cur = [], []
    with open(os.path.join(src, 'scowl-pre.txt'), encoding='utf-8') as f:
        for raw in f:
            line = raw.rstrip('\n')
            if not line.strip():
                if cur:
                    groups.append(cur)
                    cur = []
                continue
            if line.startswith('#'):
                continue
            cur.append(line)
    if cur:
        groups.append(cur)
    words = set()
    dropped_usage = 0
    for g in groups:
        parsed = [p for p in (parse_line(l) for l in g) if p]
        if any(re.search(r'offensive|vulgar', p[5]) for p in parsed):
            dropped_usage += 1
            continue
        if any(p[4] in BAD_CLASSES or p[3] in BAD_POS for p in parsed):
            continue
        for (size, vinfo, lemma, pos, cls, usage, entries), line in zip(parsed, [l for l in g if parse_line(l)]):
            if size is None or size > max_size or not variant_ok(vinfo):
                continue
            cands = [] if lemma == '-' else [strip_ann(lemma)]
            for e in entries:
                cands.extend(entry_words(e))
            for word, floor in cands:
                if not word or word == '-' or max(size, floor) > max_size:
                    continue
                if word != word.lower():
                    continue  # proper noun / abbreviation spelling
                w = keep('en', word)
                if w and not VOWEL.search(w) and '[enable]' not in line:
                    continue  # unit symbols such as CM, KG, ML (tagged <n>, from one source only)
                if w:
                    words.add(w)
    print(f'en: {len(groups)} groups, {dropped_usage} dropped as offensive/vulgar, size <= {max_size}')
    write_list('en', words, [read_bytes(os.path.join(src, 'Copyright'))])


# --- French: the Grammalecte lexicon (full forms with tags) ---

# Tags (column "Étiquettes") whose rows are dropped: proper nouns, first names, surnames, titles (M, Dr), Roman
# numerals, punctuation, signs, prefixes / suffixes, odd bits, elided forms (qu, jusqu), parts of fixed phrases
# (a priori, statu quo) and the inverted first person (eussé-je: only before -je).
FR_BAD_TAGS = {'npr', 'prn', 'patr', 'titr', 'nbro', 'ponc', 'sign', 'pfx', 'sfx', 'div', 'err', '1isg'}
# Notes: symbols (km, kg), abbreviations (etc, cf), acronyms, pejorative senses.
FR_BAD_NOTES = {'symb', 'abty', 'sig', 'péj'}
FR_VOWEL = re.compile(r'[aeiouyàâäéèêëîïôöùûüÿœæ]')


def build_fr(lexicon, mpl, readme):
    words, rows, kept_rows = set(), 0, 0
    header = None
    with open(lexicon, encoding='utf-8') as f:
        for raw in f:
            line = raw.rstrip('\n')
            if header is None:
                if line.startswith('id\t'):
                    header = line.split('\t')
                continue
            p = line.split('\t')
            if len(p) < 11:
                continue
            rows += 1
            flexion, tags, notes, subdict = p[2], set(p[4].split()), set(p[7].split()), p[10]
            if flexion != flexion.lower():
                continue  # proper nouns, acronyms, units written with capitals
            if tags & FR_BAD_TAGS or any(t.startswith('loc.') for t in tags):
                continue
            if notes & FR_BAD_NOTES:
                continue
            if 'abr' in notes and not FR_VOWEL.search(flexion):
                continue  # abbreviations without a vowel (vs, pt); radio, auto, pro stay
            if 'X' in subdict.split('/'):
                continue  # sub-dictionary X: doubtful forms (dessication, peuton), not in any spelling variant
            w = keep('fr', flexion)
            if w:
                kept_rows += 1
                words.add(w)
    assert header and header[2] == 'Flexion' and header[4] == 'Étiquettes' and header[10] == 'Sous-dictionnaire'
    print(f'fr: {rows} lexicon rows, {kept_rows} kept')
    write_list('fr', words, [read_bytes(readme), read_bytes(mpl)])


# --- Spanish: RLA-ES stems (RAE words) + affixes ---

ES_SKIP = {'Locuciones.txt'}  # parts of fixed phrases (acerca de, per cápita), not words of their own


def build_es(repo):
    aff_path = os.path.join(repo, 'ortografia', 'afijos', 'afijos.txt')
    with open(aff_path, encoding='utf-8') as f:
        d = hx.parse_aff(f.read())
    rae = os.path.join(repo, 'ortografia', 'palabras', 'RAE')
    files = sorted(n for n in os.listdir(rae) if n.endswith('.txt') and n not in ES_SKIP)
    words, stems, forms = set(), 0, 0
    for name in files:
        with open(os.path.join(rae, name), encoding='utf-8') as f:
            for line in f:
                e = hx.parse_dic_line(d, line)
                if not e:
                    continue
                stem, flags, _ = e
                if stem != stem.lower():
                    continue
                stems += 1
                for form in d.expand(stem, flags):
                    forms += 1
                    w = keep('es', form)
                    if w:
                        words.add(w)
    print(f'es: {len(files)} files ({", ".join(files)}), {stems} stems, {forms} forms')
    lic = os.path.join(repo, 'LICENSE')
    write_list('es', words, [read_bytes(os.path.join(repo, 'LICENSE.md')), read_bytes(os.path.join(lic, 'GPLv3.txt'))])


# --- tile sets (KLD-094 method, KLD-132: frequencies counted in the list itself) ---

def list_words(lang):
    with gzip.open(os.path.join(ASSETS, lang, 'words.txt.gz'), 'rb') as f:
        return f.read().decode('utf-8').split('\n')[:-1]


def letter_frequencies(words, max_len=8):
    """Per cent of each letter in the words of 2..max_len letters (each word once): the lengths actually laid."""
    counts = {}
    total = 0
    for w in words:
        if len(w) > max_len:
            continue
        for c in w:
            counts[c] = counts.get(c, 0) + 1
            total += 1
    return {c: round(100 * n / total, 3) for c, n in counts.items()}


def derive_tiles(f, tiles=98):
    """Counts and points as TileSet's doc and test/word_tiles_test.dart derive them."""
    n = {l: 1 for l in f}
    order = sorted(f)
    for _ in range(len(f), tiles):
        best, best_v = None, -1.0
        for l in order:
            v = math.pow(f[l], 0.9) / (n[l] + 1)
            if v > best_v:
                best, best_v = l, v
        n[best] += 1
    top = sorted(f.values(), reverse=True)[:6]
    ref = sum(top) / 6
    k = 7 / (math.log(ref / min(f.values())) / math.log(2))
    bands = [1, 2, 3, 4, 5, 6, 8, 10]
    p = {l: bands[min(7, math.floor(max(0.0, math.log(ref / v) / math.log(2)) * k))] for l, v in f.items()}
    return n, p


def tiles(lang):
    f = letter_frequencies(list_words(lang))
    missing = LETTERS[lang] - set(f)
    assert not missing, f'letters never used: {missing}'
    n, p = derive_tiles(f)
    by_f = sorted(f, key=lambda l: (-f[l], l))
    print(f'{lang}: frequencies (% of letters in words of 2-8 letters):')
    print('  {' + ', '.join(f"'{l}': {f[l]}" for l in sorted(f)) + '}')
    print('  counts: {' + ', '.join(f"'{l}': {n[l]}" for l in by_f) + '}')
    print('  points: {' + ', '.join(f"'{l}': {p[l]}" for l in by_f) + '}')
    print(f'  {sum(n.values())} letter tiles + 2 blanks')


def check():
    for lang in LANGS:
        path = os.path.join(ASSETS, lang, 'words.txt.gz')
        if not os.path.exists(path):
            print(f'{lang}: missing')
            continue
        gz = os.path.getsize(path)
        with gzip.open(path, 'rb') as f:
            data = f.read()
        words = data.decode('utf-8').split('\n')[:-1]
        assert words == sorted(words), 'not sorted'
        assert len(set(words)) == len(words), 'duplicates'
        assert all(MIN_LEN <= len(w) <= MAX_LEN and set(w) <= LETTERS[lang] for w in words)
        assert all(normalize(w, lang) == w for w in words), 'not normalized'
        lens = {}
        for w in words:
            lens[len(w)] = lens.get(len(w), 0) + 1
        s = set(words)
        print(f'{lang}: {len(words)} words, raw {len(data)} bytes, gzip {gz} bytes')
        print('   by length: ' + ', '.join(f'{k}:{lens[k]}' for k in sorted(lens)))
        print('   samples: ' + ', '.join(f'{w}={"yes" if w in s else "NO"}' for w in SAMPLES[lang]))
        if lang in ABSENT:
            print('   absent: ' + ', '.join(f'{w}={"in (BAD)" if w in s else "no"}' for w in ABSENT[lang]))


def main(argv):
    if len(argv) >= 1 and argv[0] == 'check':
        return check()
    if len(argv) >= 2 and argv[0] == 'tiles':
        return tiles(argv[1])
    if len(argv) >= 2 and argv[0] == 'de':
        return build_de(argv[1])
    if len(argv) >= 2 and argv[0] == 'en':
        size = int(argv[argv.index('--size') + 1]) if '--size' in argv else 80
        return build_en(argv[1], size)
    if len(argv) >= 4 and argv[0] == 'fr':
        return build_fr(argv[1], argv[2], argv[3])
    if len(argv) >= 2 and argv[0] == 'es':
        return build_es(argv[1])
    print(__doc__)
    sys.exit(2)


if __name__ == '__main__':
    main(sys.argv[1:])
