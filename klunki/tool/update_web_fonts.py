#!/usr/bin/env python3
"""List, refetch or re-subset the bundled fonts (I18N-04b, I18N-07, I18N-08). Manual tool, never run by a build.

Usage (from klunki/):
    python3 -I tool/update_web_fonts.py                 # list (default)
    python3 -I tool/update_web_fonts.py list --family "Noto Sans SC"
    python3 -I tool/update_web_fonts.py subset          # after ARB strings changed
    python3 -I tool/update_web_fonts.py fetch --version v2.013
    python3 -I tool/update_web_fonts.py fetch-roboto --version v3.016

list:   shows the bundled files (size, sha256, TrueType check) and what this
        Flutter version's web font fallback would download from
        fonts.gstatic.com for the given families (default: Noto Sans Arabic,
        plus Roboto, which the engine loads at startup unless the app bundles
        a family named "Roboto"). Run it after a Flutter upgrade.
subset: rebuilds the two subset fonts from the characters the app shows
        (all ARB values + the language picker's endonyms):
          * assets/fonts/NotoSansSC/   Noto Sans SC 400 + 700: every Han / CJK
            character of all ARB files and endonyms, all characters of the zh
            strings, and printable ASCII (I18N-07).
          * assets/fonts/NotoSansMath/ Noto Sans Math 400: the remaining
            symbols that neither Roboto nor Noto Sans Arabic has, e.g. the
            arrow U+2192 and the French narrow no-break space U+202F (I18N-08).
        The subsets come from the Google Fonts CSS API (`text=` parameter,
        served as TrueType), i.e. Google subsets the google/fonts font for us:
        no fontTools needed, and the full ~10 MB source font never touches
        the repo. Every requested character is checked in the result's cmap.
        The API subsets at most 800 characters per request (with more it
        silently serves the full ~10 MB font), so the sorted characters are
        split into parts of <= 800, one font family per part: NotoSansSC
        (printable ASCII + the first CJK characters), NotoSansSC2, ... The
        tool rewrites the families in pubspec.yaml (between the BEGIN/END
        markers) and the family lists in lib/app/fonts.dart (the web
        fallback chain). A downloaded file over 1 MB is refused (a full
        font, not a subset). fontTools is not needed (no merging).
        Rerun whenever test/l10n/glyph_coverage_test.dart says so.
fetch:  downloads NotoSansArabic-<version>.zip from the official notofonts
        GitHub release into a new temporary directory, checks it, and replaces
        assets/fonts/NotoSansArabic/{Regular,Bold}.ttf and OFL.txt with the
        unhinted static TTFs from it.
fetch-roboto: downloads Roboto_<version>.zip from the official
        googlefonts/roboto-3-classic release and replaces
        assets/fonts/Roboto/Roboto-{Regular,Medium,Bold}.ttf with the
        web-optimized static TTFs (Latin, Greek, Cyrillic) plus OFL.txt.
After fetch/subset: review `git diff --stat`, run `flutter test test/l10n`, commit.

Klunki bundles fonts as Flutter assets (theme fontFamily / fontFamilyFallback)
instead of redirecting `fontFallbackBaseUrl`: that URL is also used for every
other fallback font (emoji in names, rare scripts), which would then 404 even
online. See docs/tasks/I18N-04-rtl.md and docs/tasks/I18N-07-08-offline-fonts.md.
"""
import argparse
import glob
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request
import zipfile

KLUNKI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = os.path.join(KLUNKI, 'assets', 'fonts')
L10N = os.path.join(KLUNKI, 'lib', 'l10n')
FONT_DIR = os.path.join(FONTS, 'NotoSansArabic')
FILES = ['NotoSansArabic-Regular.ttf', 'NotoSansArabic-Bold.ttf']
RELEASE_URL = ('https://github.com/notofonts/arabic/releases/download/'
               'NotoSansArabic-{v}/NotoSansArabic-{v}.zip')
ROBOTO_DIR = os.path.join(FONTS, 'Roboto')
ROBOTO_FILES = ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']
ROBOTO_URL = ('https://github.com/googlefonts/roboto-3-classic/releases/download/'
              '{v}/Roboto_{v}.zip')
ROBOTO_OFL_URL = 'https://raw.githubusercontent.com/googlefonts/roboto-3-classic/{v}/OFL.txt'
CSS_API = 'https://fonts.googleapis.com/css2'
GOOGLE_FONTS_OFL = 'https://raw.githubusercontent.com/google/fonts/main/ofl/{dir}/OFL.txt'
# Family -> (directory, file stem, weights). Weight names follow the static TTF naming.
SUBSETS = {
    'Noto Sans SC': ('NotoSansSC', 'NotoSansSC', {400: 'Regular', 700: 'Bold'}),
    'Noto Sans Math': ('NotoSansMath', 'NotoSansMath', {400: 'Regular'}),
}
TRUETYPE_MAGIC = (b'\x00\x01\x00\x00', b'OTTO')
# The CSS API subsets at most this many characters per request; with more it
# serves the full font (Noto Sans SC: ~10 MB). Measured 2026-11-11.
TEXT_LIMIT = 800
# A subset part is far smaller; a bigger download is a full font: refuse it.
MAX_SUBSET_BYTES = 1_000_000
PUBSPEC = os.path.join(KLUNKI, 'pubspec.yaml')
FONTS_DART = os.path.join(KLUNKI, 'lib', 'app', 'fonts.dart')
# Family -> the Dart list of its part families in lib/app/fonts.dart.
DART_LISTS = {'Noto Sans SC': 'chineseFontFamilies', 'Noto Sans Math': 'symbolFontFamilies'}
# An old user agent makes the CSS API serve TrueType instead of WOFF2
# (CanvasKit's FreeType cannot read WOFF2).
TTF_USER_AGENT = 'Wget/1.0'


# --- characters -----------------------------------------------------------

def is_cjk(c):
    """Han, CJK symbols/punctuation, fullwidth forms: what Noto Sans SC is for."""
    return (0x3400 <= c <= 0x4DBF or 0x4E00 <= c <= 0x9FFF or 0x3000 <= c <= 0x303F
            or 0xFF00 <= c <= 0xFFEF or 0x20000 <= c <= 0x2FFFF)


def needs_glyph(c):
    """Visible characters (controls, zero-width and bidi marks need none)."""
    return c > 0x20 and not (0x200B <= c <= 0x200F) and not (0x2066 <= c <= 0x2069)


def arb_strings(code):
    with open(os.path.join(L10N, f'app_{code}.arb'), encoding='utf-8') as f:
        arb = json.load(f)
    return [v for k, v in arb.items() if not k.startswith('@') and isinstance(v, str)]


def arb_codes():
    return sorted(re.fullmatch(r'app_(\w+)\.arb', os.path.basename(p)).group(1)
                  for p in glob.glob(os.path.join(L10N, 'app_*.arb')))


def endonyms():
    """The language picker's endonyms (shown in every locale)."""
    with open(os.path.join(L10N, 'locale_controller.dart'), encoding='utf-8') as f:
        src = f.read()
    names = re.findall(r"AppLanguage\(.*?,\s*'([^']+)'\)", src)
    if not names:
        sys.exit('error: no AppLanguage endonyms found in locale_controller.dart')
    return names


def card_media_strings():
    """Photo credits shown in every locale (KLD-082): authors and licence
    names from assets/quartett/<deck>/credits.json (e.g. a Japanese author)."""
    out = []
    for p in sorted(glob.glob(os.path.join(KLUNKI, 'assets', 'quartett', '*', 'credits.json'))):
        with open(p, encoding='utf-8') as f:
            for card in json.load(f)['cards'].values():
                img = card.get('image')
                if img:
                    out += [img['author'], img['license']]
    return out


def app_chars():
    """code -> set of code points in that locale's ARB values; '_endonyms'
    and '_card_media' (photo credits) too."""
    out = {code: {ord(ch) for s in arb_strings(code) for ch in s} for code in arb_codes()}
    out['_endonyms'] = {ord(ch) for s in endonyms() for ch in s}
    out['_card_media'] = {ord(ch) for s in card_media_strings() for ch in s}
    return out


# --- fonts ----------------------------------------------------------------

def cmap_code_points(data):
    """Unicode code points mapped by a TrueType/OpenType font (cmap 4 and 12)."""
    u16 = lambda o: struct.unpack_from('>H', data, o)[0]  # noqa: E731
    u32 = lambda o: struct.unpack_from('>I', data, o)[0]  # noqa: E731
    cmap = None
    for i in range(u16(4)):
        rec = 12 + 16 * i
        if data[rec:rec + 4] == b'cmap':
            cmap = u32(rec + 8)
    if cmap is None:
        raise ValueError('no cmap table')
    out = set()
    for i in range(u16(cmap + 2)):
        platform, encoding = u16(cmap + 4 + 8 * i), u16(cmap + 6 + 8 * i)
        if not (platform == 0 or (platform == 3 and encoding in (1, 10))):
            continue
        sub = cmap + u32(cmap + 8 + 8 * i)
        fmt = u16(sub)
        if fmt == 4:
            segs = u16(sub + 6) // 2
            ends = sub + 14
            starts = ends + 2 * segs + 2
            deltas = starts + 2 * segs
            offsets = deltas + 2 * segs
            for s in range(segs):
                end, start = u16(ends + 2 * s), u16(starts + 2 * s)
                delta = struct.unpack_from('>h', data, deltas + 2 * s)[0]
                ro_at = offsets + 2 * s
                ro = u16(ro_at)
                for c in range(start, min(end, 0xFFFE) + 1):
                    if ro == 0:
                        glyph = (c + delta) & 0xFFFF
                    else:
                        g = u16(ro_at + ro + 2 * (c - start))
                        glyph = 0 if g == 0 else (g + delta) & 0xFFFF
                    if glyph:
                        out.add(c)
        elif fmt == 12:
            for g in range(u32(sub + 12)):
                start, end = u32(sub + 16 + 12 * g), u32(sub + 20 + 12 * g)
                out.update(range(start, end + 1))
    return out


def font_cmap(path):
    with open(path, 'rb') as f:
        return cmap_code_points(f.read())


def bundled_coverage(dirs):
    cov = set()
    for d in dirs:
        for p in sorted(glob.glob(os.path.join(FONTS, d, '*.[to]tf'))):
            cov |= font_cmap(p)
    return cov


def fmt_chars(cps):
    return ' '.join(f'{chr(c)}U+{c:04X}' for c in sorted(cps))


def describe(path):
    with open(path, 'rb') as f:
        data = f.read()
    if path.endswith('SOURCE.txt'):
        check = 'subset provenance'
    elif path.endswith('.txt'):
        check = 'ok' if b'SIL Open Font License' in data else 'NOT THE SIL OFL'
    else:
        check = 'ok' if data[:4] in TRUETYPE_MAGIC else 'NOT A TTF/OTF'
        if check == 'ok':
            check += f', {len(cmap_code_points(data))} code points'
    return f'{len(data):>8} B  sha256 {hashlib.sha256(data).hexdigest()[:16]}  {check}'


def download(url, user_agent=None):
    req = urllib.request.Request(url, headers={'User-Agent': user_agent} if user_agent else {})
    with urllib.request.urlopen(req) as resp:  # noqa: S310 (fixed hosts)
        return resp.read()


def write_files(directory, blobs):
    os.makedirs(directory, exist_ok=True)
    for name, blob in blobs.items():
        with open(os.path.join(directory, name), 'wb') as f:
            f.write(blob)


# --- commands -------------------------------------------------------------

def flutter_root():
    flutter = shutil.which('flutter')
    if not flutter:
        sys.exit('error: flutter not on PATH')
    return os.path.dirname(os.path.dirname(os.path.realpath(flutter)))


def engine_dir(root):
    return os.path.join(root, 'bin', 'cache', 'flutter_web_sdk', 'lib', '_engine', 'engine')


def cmd_list(args):
    total = 0
    print(f'Bundled ({os.path.relpath(FONTS, KLUNKI)}):')
    for d in sorted(os.listdir(FONTS)) if os.path.isdir(FONTS) else []:
        for p in sorted(glob.glob(os.path.join(FONTS, d, '*'))):
            total += os.path.getsize(p)
            print(f'  {d + "/" + os.path.basename(p):<42} ' + describe(p))
    print(f'  total {total} B')

    root = flutter_root()
    eng = engine_dir(root)
    data_file = os.path.join(eng, 'font_fallback_data.dart')
    if not os.path.isfile(data_file):
        print(f'\n(no web SDK at {eng}; run `flutter precache --web`)')
        return 0
    with open(data_file, encoding='utf-8') as f:
        data = f.read()
    with open(os.path.join(eng, 'configuration.dart'), encoding='utf-8') as f:
        base = re.search(r"fontFallbackBaseUrl \?\? '([^']+)'", f.read())
    base = base.group(1) if base else '<fontFallbackBaseUrl>'
    print(f'\nFlutter web fallback ({root}), base {base}:')
    with open(os.path.join(eng, 'canvaskit', 'fonts.dart'), encoding='utf-8') as f:
        src = f.read()
    roboto = re.search(r"fontFallbackBaseUrl\}(roboto/[^']+)'", src)
    if roboto:
        skip = "family.name == 'Roboto'" in src
        print(f'  Roboto (startup)  {roboto.group(1)}'
              + ('  [skipped: the app bundles a family "Roboto"]' if skip else ''))
    for family in args.family or ['Noto Sans Arabic']:
        pattern = re.compile(r"NotoFont\(\s*'(" + re.escape(family) + r"(?: \d+)?)',\s*'([^']+)'")
        hits = pattern.findall(data)
        if not hits:
            print(f'  {family}: not in the fallback data')
        for name, url in hits:
            print(f'  {name}  {url}')
    return 0


def subset_texts():
    """(Noto Sans SC code points, Noto Sans Math code points) the app needs."""
    chars = app_chars()
    every = set().union(*chars.values())
    sc = {c for c in every if is_cjk(c)} | set(range(0x21, 0x7F))
    sc |= {c for c in chars.get('zh', set()) if needs_glyph(c)}
    covered = bundled_coverage(['Roboto', 'NotoSansArabic'])
    if not covered:
        sys.exit('error: Roboto / Noto Sans Arabic not bundled yet (run fetch-roboto / fetch first)')
    symbols = {c for c in every if needs_glyph(c) and not is_cjk(c) and c not in covered}
    return sc, symbols


def part_family(stem, index):
    """Family (and file stem) of subset part [index]: NotoSansSC, NotoSansSC2, ..."""
    return stem if index == 0 else f'{stem}{index + 1}'


def split_parts(cps):
    """The sorted code points in parts of at most TEXT_LIMIT. Deterministic;
    printable ASCII sorts first, so it lands in the first part."""
    ordered = sorted(cps)
    return [ordered[i:i + TEXT_LIMIT] for i in range(0, len(ordered), TEXT_LIMIT)] or [[]]


def fetch_part(family, weights, cps):
    """(weight -> TrueType bytes of [family] subset to [cps], first font URL)."""
    if len(cps) > TEXT_LIMIT:
        raise ValueError(f'{len(cps)} characters in one request (limit {TEXT_LIMIT})')
    query = urllib.parse.urlencode({
        'family': f'{family}:wght@' + ';'.join(str(w) for w in sorted(weights)),
        'text': ''.join(chr(c) for c in cps),
    }, safe=':@;')
    css = download(f'{CSS_API}?{query}', TTF_USER_AGENT).decode('utf-8')
    faces = re.findall(r'font-weight:\s*(\d+);\s*src:\s*url\((https://fonts\.gstatic\.com/[^)]+)\)'
                       r"\s*format\('truetype'\)", css)
    got = {int(w): u for w, u in faces}
    if set(got) != set(weights):
        sys.exit(f'error: {family}: expected TrueType weights {sorted(weights)}, CSS API returned:\n{css}')
    out = {}
    for weight in sorted(weights):
        blob = download(got[weight])
        if len(blob) > MAX_SUBSET_BYTES:
            sys.exit(f'error: {family} {weight}: the font service sent {len(blob)} B for {len(cps)} '
                     f'characters ({got[weight]}): a full font, not a subset. Did its per-request '
                     f'limit drop below TEXT_LIMIT = {TEXT_LIMIT}? Lower TEXT_LIMIT and rerun.')
        if blob[:4] not in TRUETYPE_MAGIC:
            sys.exit(f'error: {family} {weight} is not a TrueType font')
        missing = {c for c in cps if not (0x21 <= c <= 0x7E)} - cmap_code_points(blob)
        if missing:
            sys.exit(f'error: {family} {weight} lacks {fmt_chars(missing)}')
        out[weight] = blob
    return out, got[min(weights)]


def fetch_subset(family, cps, work):
    """Downloads the subset parts of [family] into its asset directory and
    returns the part family names (NotoSansSC, NotoSansSC2, ...)."""
    directory, stem, weights = SUBSETS[family]
    parts = split_parts(cps)
    names = [part_family(stem, i) for i in range(len(parts))]
    blobs = {}
    version = None
    for name, part in zip(names, parts):
        fonts, url = fetch_part(family, weights, part)
        version = version or re.search(r'[?&]v=(v\d+)', url)
        for weight, blob in fonts.items():
            file = f'{name}-{weights[weight]}.ttf'
            blobs[file] = blob
            with open(os.path.join(work, file), 'wb') as f:
                f.write(blob)
    ofl = download(GOOGLE_FONTS_OFL.format(dir=stem.lower()))
    if b'SIL Open Font License' not in ofl:
        sys.exit(f'error: {family}: OFL.txt does not contain the SIL OFL')
    blobs['OFL.txt'] = ofl
    text = lambda part: ''.join(chr(c) for c in part)  # noqa: E731
    if len(parts) == 1:
        how, chars = '', f'Characters:\n{text(parts[0])}\n'
    else:
        how = f' in {len(parts)} parts of <= {TEXT_LIMIT} (one font family each, see pubspec.yaml)'
        chars = 'Characters per family:\n' + ''.join(f'{n}: {text(p)}\n' for n, p in zip(names, parts))
    blobs['SOURCE.txt'] = (
        f'{family}, Google Fonts {version.group(1) if version else "?"} (google/fonts, SIL OFL 1.1),\n'
        f'subset by the Google Fonts CSS API (text=) to {len(cps)} code points{how}.\n'
        'Generated by `python3 -I tool/update_web_fonts.py subset`; do not edit by hand.\n'
        + chars).encode('utf-8')
    # Replace the directory content (a weight or a part may have been dropped).
    target = os.path.join(FONTS, directory)
    if os.path.isdir(target):
        shutil.rmtree(target)
    write_files(target, blobs)
    size = sum(len(b) for n, b in blobs.items() if n.endswith('.ttf'))
    print(f'{family}: {len(cps)} code points in {len(parts)} part(s) -> '
          f'{os.path.relpath(target, KLUNKI)} ({size} B of TTF)')
    return names


def pubspec_block(family, names):
    """The pubspec.yaml `fonts:` entries of [family]'s part families."""
    directory, _, weights = SUBSETS[family]
    lines = []
    for name in names:
        lines += [f'    - family: {name}', '      fonts:']
        for weight in sorted(weights):
            lines.append(f'        - asset: assets/fonts/{directory}/{name}-{weights[weight]}.ttf')
            if weight != 400:
                lines.append(f'          weight: {weight}')
    return '\n'.join(lines) + '\n'


def register_families(parts):
    """Writes the part families ({family: [names]}) into pubspec.yaml (between
    its BEGIN/END markers) and into the family lists of lib/app/fonts.dart."""
    with open(PUBSPEC, encoding='utf-8') as f:
        pubspec = f.read()
    with open(FONTS_DART, encoding='utf-8') as f:
        dart = f.read()
    for family, names in parts.items():
        stem = SUBSETS[family][1]
        begin = f'    # BEGIN {stem} (written by tool/update_web_fonts.py subset)\n'
        end = f'    # END {stem}\n'
        if pubspec.count(begin) != 1 or pubspec.count(end) != 1:
            sys.exit(f'error: pubspec.yaml lacks the markers {begin.strip()!r} / {end.strip()!r}')
        head, rest = pubspec.split(begin)
        _, tail = rest.split(end)
        pubspec = head + begin + pubspec_block(family, names) + end + tail
        var = DART_LISTS[family]
        pattern = re.compile(r'const List<String> ' + var + r' = \[[^\]]*\];')
        if len(pattern.findall(dart)) != 1:
            sys.exit(f'error: lib/app/fonts.dart lacks `const List<String> {var} = [...];`')
        listed = ', '.join(f"'{n}'" for n in names)
        dart = pattern.sub(lambda _: f'const List<String> {var} = [{listed}];', dart)
    with open(PUBSPEC, 'w', encoding='utf-8') as f:
        f.write(pubspec)
    with open(FONTS_DART, 'w', encoding='utf-8') as f:
        f.write(dart)


def cmd_subset(args):
    sc, symbols = subset_texts()
    if args.extra_text:
        # Testing only (the parts with > 800 characters): add the characters
        # of this file to the Noto Sans SC set. Never commit such a result.
        with open(args.extra_text, encoding='utf-8') as f:
            sc |= {ord(ch) for ch in f.read() if needs_glyph(ord(ch))}
    work = tempfile.mkdtemp(prefix='klunki-fonts-')  # new, empty directory
    parts = {'Noto Sans SC': fetch_subset('Noto Sans SC', sc, work)}
    if symbols:
        parts['Noto Sans Math'] = fetch_subset('Noto Sans Math', symbols, work)
    else:
        print('Noto Sans Math: nothing outside Roboto / Arabic needed')
    shutil.rmtree(work)
    register_families(parts)
    subprocess.run(['git', 'diff', '--stat', '--', FONTS, PUBSPEC, FONTS_DART], cwd=KLUNKI, check=False)
    return 0


def cmd_fetch(args):
    if not re.fullmatch(r'v\d+\.\d+', args.version):
        sys.exit('error: --version looks like v2.013')
    url = RELEASE_URL.format(v=args.version)
    work = tempfile.mkdtemp(prefix='klunki-fonts-')  # new, empty directory
    zip_path = os.path.join(work, os.path.basename(url))
    print(f'downloading {url}')
    with open(zip_path, 'wb') as out:
        out.write(download(url))
    wanted = {f'NotoSansArabic/unhinted/ttf/{n}': n for n in FILES}
    wanted['OFL.txt'] = 'OFL.txt'
    extracted = {}
    with zipfile.ZipFile(zip_path) as z:
        names = set(z.namelist())
        for member, target in wanted.items():
            if member not in names:
                sys.exit(f'error: {member} not in the release zip')
            extracted[target] = z.read(member)
    for name in FILES:
        if extracted[name][:4] not in TRUETYPE_MAGIC:
            sys.exit(f'error: {name} is not a TrueType font')
    if b'SIL Open Font License' not in extracted['OFL.txt']:
        sys.exit('error: OFL.txt does not contain the SIL OFL')
    write_files(FONT_DIR, extracted)
    shutil.rmtree(work)
    subprocess.run(['git', 'diff', '--stat', '--', FONT_DIR], cwd=KLUNKI, check=False)
    return cmd_list(argparse.Namespace(family=None))


def cmd_fetch_roboto(args):
    if not re.fullmatch(r'v\d+\.\d+', args.version):
        sys.exit('error: --version looks like v3.016')
    url = ROBOTO_URL.format(v=args.version)
    work = tempfile.mkdtemp(prefix='klunki-fonts-')  # new, empty directory
    zip_path = os.path.join(work, os.path.basename(url))
    print(f'downloading {url}')
    with open(zip_path, 'wb') as out:
        out.write(download(url))
    extracted = {}
    with zipfile.ZipFile(zip_path) as z:
        names = set(z.namelist())
        for name in ROBOTO_FILES:
            member = f'web/static/{name}'
            if member not in names:
                sys.exit(f'error: {member} not in the release zip')
            blob = z.read(member)
            if blob[:4] not in TRUETYPE_MAGIC:
                sys.exit(f'error: {name} is not a TrueType font')
            extracted[name] = blob
    ofl = download(ROBOTO_OFL_URL.format(v=args.version))
    if b'SIL Open Font License' not in ofl:
        sys.exit('error: Roboto OFL.txt does not contain the SIL OFL')
    extracted['OFL.txt'] = ofl
    write_files(ROBOTO_DIR, extracted)
    shutil.rmtree(work)
    subprocess.run(['git', 'diff', '--stat', '--', ROBOTO_DIR], cwd=KLUNKI, check=False)
    print('Roboto changed: rerun `subset` (the symbol subset depends on what Roboto lacks).')
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = parser.add_subparsers(dest='cmd')
    p_list = sub.add_parser('list', help='show bundled files and the engine fallback URLs')
    p_list.add_argument('--family', action='append',
                        help='fallback family to look up (repeatable), e.g. "Noto Sans SC"')
    p_subset = sub.add_parser('subset', help='rebuild the Noto Sans SC / Noto Sans Math subsets from the ARB files')
    p_subset.add_argument('--extra-text', metavar='FILE',
                          help='testing only: also subset the characters of FILE into Noto Sans SC')
    p_fetch = sub.add_parser('fetch', help='refetch Noto Sans Arabic from the notofonts release')
    p_fetch.add_argument('--version', required=True, help='release version, e.g. v2.013')
    p_roboto = sub.add_parser('fetch-roboto', help='refetch Roboto from the roboto-3-classic release')
    p_roboto.add_argument('--version', required=True, help='release version, e.g. v3.016')
    args = parser.parse_args()
    if args.cmd == 'fetch':
        return cmd_fetch(args)
    if args.cmd == 'fetch-roboto':
        return cmd_fetch_roboto(args)
    if args.cmd == 'subset':
        return cmd_subset(args)
    if args.cmd is None:
        args.family = None
    return cmd_list(args)


if __name__ == '__main__':
    sys.exit(main())
