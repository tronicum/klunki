#!/usr/bin/env python3
"""Build the Wortgewandt word lists (KLD-094 step 4) from the approved sources. Manual tool, never run by a build.

Usage (from klunki/; standard library only, reproducible: same input -> same bytes):
    python3 -I tool/build_word_lists.py de <dir with enz/german-wordlist files: words, COPYING>
    python3 -I tool/build_word_lists.py en <dir with en-wl/wordlist files: scowl-pre.txt, Copyright> [--size 80]
    python3 -I tool/build_word_lists.py check     # counts, samples and sizes of the bundled assets

The sources are downloaded by hand (curl, pinned commit, see assets/wordlists/*/SOURCE.txt) into a fresh
directory and treated as data: this script only reads them, it never runs anything from them.

Output: assets/wordlists/<lang>/words.txt.gz (gzip, mtime 0, UTF-8, one word per line, sorted by code point =
UTF-8 byte order, which the app's binary search relies on) plus LICENSE (copied from the source).
SOURCE.txt is written by hand (URL, commit, date, licence, filters).

Filters (both languages), mirroring the engine's TileSet (packages/klunki_engine/lib/word_tiles.dart):
  * normalize like TileSet.normalize: ß / ẞ -> SS, then upper case;
  * keep words of 2-15 letters that the tile set can spell (TileSet.canSpell): A-Z plus Ä Ö Ü for de, A-Z for en;
    anything else (accents, apostrophes, hyphens, spaces, digits, dots) drops the word.
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
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, 'assets', 'wordlists')

LETTERS = {
    'de': set('ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ'),
    'en': set('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
}
MIN_LEN, MAX_LEN = 2, 15

SAMPLES = {
    'de': ['HÄUSER', 'LIEF', 'GINGEN', 'SCHÖNSTEN', 'STRASSE', 'FÜSSE', 'BÄUME', 'ÄRGERTEN', 'QI', 'XYLOFON'],
    'en': ['HOUSES', 'RAN', 'WENT', 'GOING', 'NICEST', 'COLOR', 'COLOUR', 'AA', 'QI', 'ZA', 'XU', 'QAT', 'ZAX'],
}


def normalize(word):
    return word.replace('ß', 'SS').replace('ẞ', 'SS').upper()


def keep(lang, word):
    w = normalize(word)
    return w if MIN_LEN <= len(w) <= MAX_LEN and set(w) <= LETTERS[lang] else None


def write_list(lang, words, license_src):
    out_dir = os.path.join(ASSETS, lang)
    os.makedirs(out_dir, exist_ok=True)
    data = ''.join(w + '\n' for w in sorted(words)).encode('utf-8')
    buf = io.BytesIO()
    with gzip.GzipFile(filename='', mode='wb', fileobj=buf, compresslevel=9, mtime=0) as gz:
        gz.write(data)
    with open(os.path.join(out_dir, 'words.txt.gz'), 'wb') as f:
        f.write(buf.getvalue())
    with open(license_src, 'rb') as src, open(os.path.join(out_dir, 'LICENSE'), 'wb') as dst:
        dst.write(src.read())
    print(f'{lang}: {len(words)} words, raw {len(data)} bytes, gzip {len(buf.getvalue())} bytes')


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
    write_list('de', words, os.path.join(src, 'COPYING'))


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
    write_list('en', words, os.path.join(src, 'Copyright'))


def check():
    for lang in ('de', 'en'):
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
        lens = {}
        for w in words:
            lens[len(w)] = lens.get(len(w), 0) + 1
        s = set(words)
        print(f'{lang}: {len(words)} words, raw {len(data)} bytes, gzip {gz} bytes')
        print('   by length: ' + ', '.join(f'{k}:{lens[k]}' for k in sorted(lens)))
        print('   samples: ' + ', '.join(f'{w}={"yes" if w in s else "NO"}' for w in SAMPLES[lang]))


def main(argv):
    if len(argv) >= 1 and argv[0] == 'check':
        return check()
    if len(argv) >= 2 and argv[0] == 'de':
        return build_de(argv[1])
    if len(argv) >= 2 and argv[0] == 'en':
        size = int(argv[argv.index('--size') + 1]) if '--size' in argv else 80
        return build_en(argv[1], size)
    print(__doc__)
    sys.exit(2)


if __name__ == '__main__':
    main(sys.argv[1:])
