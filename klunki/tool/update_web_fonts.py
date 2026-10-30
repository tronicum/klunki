#!/usr/bin/env python3
"""List or refetch the bundled script fonts (I18N-04b). Manual tool, never run by a build.

Usage (from klunki/):
    python3 -I tool/update_web_fonts.py                 # list (default)
    python3 -I tool/update_web_fonts.py list --family "Noto Sans SC"
    python3 -I tool/update_web_fonts.py fetch --version v2.013

list:  shows the bundled files (size, sha256, TrueType check) and what this
       Flutter version's web font fallback would download from
       fonts.gstatic.com for the given families (default: Noto Sans Arabic,
       plus Roboto, which the engine loads at startup). Run it after a Flutter
       upgrade to see whether the engine's fallback data changed.
fetch: downloads NotoSansArabic-<version>.zip from the official notofonts
       GitHub release into a new temporary directory, checks it, and replaces
       assets/fonts/NotoSansArabic/{Regular,Bold}.ttf and OFL.txt with the
       unhinted static TTFs from it. Review `git diff --stat` and commit.

Klunki bundles the font as a Flutter asset (theme fontFamilyFallback for
ar/fa) instead of redirecting `fontFallbackBaseUrl`: that URL is also used for
Roboto and for every other fallback font (CJK, symbols, emoji), which would
then 404 even online. See docs/tasks/I18N-04-rtl.md.
"""
import argparse
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile

KLUNKI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_DIR = os.path.join(KLUNKI, 'assets', 'fonts', 'NotoSansArabic')
FILES = ['NotoSansArabic-Regular.ttf', 'NotoSansArabic-Bold.ttf']
RELEASE_URL = ('https://github.com/notofonts/arabic/releases/download/'
               'NotoSansArabic-{v}/NotoSansArabic-{v}.zip')
TRUETYPE_MAGIC = (b'\x00\x01\x00\x00', b'OTTO')


def flutter_root():
    flutter = shutil.which('flutter')
    if not flutter:
        sys.exit('error: flutter not on PATH')
    return os.path.dirname(os.path.dirname(os.path.realpath(flutter)))


def engine_dir(root):
    return os.path.join(root, 'bin', 'cache', 'flutter_web_sdk', 'lib', '_engine', 'engine')


def describe(path):
    with open(path, 'rb') as f:
        data = f.read()
    if path.endswith('.txt'):
        check = 'ok' if b'SIL Open Font License' in data else 'NOT THE SIL OFL'
    else:
        check = 'ok' if data[:4] in TRUETYPE_MAGIC else 'NOT A TTF/OTF'
    return f'{len(data):>8} B  sha256 {hashlib.sha256(data).hexdigest()[:16]}  {check}'


def cmd_list(args):
    print(f'Bundled ({os.path.relpath(FONT_DIR, KLUNKI)}):')
    for name in FILES + ['OFL.txt']:
        path = os.path.join(FONT_DIR, name)
        print(f'  {name:<28} ' + (describe(path) if os.path.isfile(path) else 'MISSING'))

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
        roboto = re.search(r"fontFallbackBaseUrl\}(roboto/[^']+)'", f.read())
    if roboto:
        print(f'  Roboto (startup)  {roboto.group(1)}')
    for family in args.family or ['Noto Sans Arabic']:
        pattern = re.compile(r"NotoFont\(\s*'(" + re.escape(family) + r"(?: \d+)?)',\s*'([^']+)'")
        hits = pattern.findall(data)
        if not hits:
            print(f'  {family}: not in the fallback data')
        for name, url in hits:
            print(f'  {name}  {url}')
    return 0


def cmd_fetch(args):
    if not re.fullmatch(r'v\d+\.\d+', args.version):
        sys.exit('error: --version looks like v2.013')
    url = RELEASE_URL.format(v=args.version)
    work = tempfile.mkdtemp(prefix='klunki-fonts-')  # new, empty directory
    zip_path = os.path.join(work, os.path.basename(url))
    print(f'downloading {url}')
    with urllib.request.urlopen(url) as resp, open(zip_path, 'wb') as out:  # noqa: S310 (fixed host)
        shutil.copyfileobj(resp, out)
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
    os.makedirs(FONT_DIR, exist_ok=True)
    for name, blob in extracted.items():
        with open(os.path.join(FONT_DIR, name), 'wb') as f:
            f.write(blob)
    shutil.rmtree(work)
    subprocess.run(['git', 'diff', '--stat', '--', FONT_DIR], cwd=KLUNKI, check=False)
    return cmd_list(argparse.Namespace(family=None))


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = parser.add_subparsers(dest='cmd')
    p_list = sub.add_parser('list', help='show bundled files and the engine fallback URLs')
    p_list.add_argument('--family', action='append',
                        help='fallback family to look up (repeatable), e.g. "Noto Sans SC"')
    p_fetch = sub.add_parser('fetch', help='refetch Noto Sans Arabic from the notofonts release')
    p_fetch.add_argument('--version', required=True, help='release version, e.g. v2.013')
    args = parser.parse_args()
    if args.cmd == 'fetch':
        return cmd_fetch(args)
    if args.cmd is None:
        args.family = None
    return cmd_list(args)


if __name__ == '__main__':
    sys.exit(main())
