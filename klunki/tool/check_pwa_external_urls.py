#!/usr/bin/env python3
"""Fail if a finalized PWA build would load anything from a CDN (KLD-070).

Usage (from klunki/, after `flutter build web --release` and pwa_finalize.py):
    python3 -I tool/check_pwa_external_urls.py build/web

The PWA must start offline, so it may not load scripts, fonts or CanvasKit
from jsdelivr, unpkg, gstatic or googleapis. A plain grep is not enough:
the Flutter engine always contains its two *default* URLs as string
literals, even when the app overrides them:

  * https://www.gstatic.com/flutter-canvaskit/...  (flutter.js,
    flutter_bootstrap.js, main.dart.js) - overridden by
    `canvasKitBaseUrl: "canvaskit/"` in web/flutter_bootstrap.js;
  * https://fonts.gstatic.com/s/  (main.dart.js) - the font fallback base,
    never reached because every glyph is in a bundled font
    (lib/app/fonts.dart, test/l10n/glyph_coverage_test.dart);
  * klunki_sw.js names fonts.gstatic.com / www.gstatic.com as cacheable hosts.

So this check allows exactly those occurrences, verifies the overrides that
make them dead code, and fails on anything else (another host, another
file, another path). The runtime proof is tool/pwa_i18n_check.sh (needs
Node and Firefox); this is the static check CI can run cheaply.
"""
import os
import re
import sys

HOSTS = re.compile(r'jsdelivr|unpkg|gstatic|googleapis')
URL = re.compile(r'https?://[A-Za-z0-9.\-]*(?:jsdelivr|unpkg|gstatic|googleapis)[A-Za-z0-9.\-]*[^\s"\'`)]*')

# (file, url prefix) pairs that are known engine defaults (see above).
ALLOWED_URLS = {
    ('flutter.js', 'https://www.gstatic.com/flutter-canvaskit'),
    ('flutter_bootstrap.js', 'https://www.gstatic.com/flutter-canvaskit'),
    ('main.dart.js', 'https://www.gstatic.com/flutter-canvaskit/'),
    ('main.dart.js', 'https://fonts.gstatic.com/s/'),
}
# Files that may mention the hosts without a URL (the service worker's list).
ALLOWED_BARE = {'klunki_sw.js'}

# KLD-082: Quartett cards carry Wikipedia articles, Wikimedia Commons file
# pages and licence pages as *link targets only* ("Auf Wikipedia lesen",
# photo credit): opened in a new tab on a tap, never fetched by the app. The
# card photos are bundled assets. So these hosts may appear only as link
# text in the compiled app (main.dart.js), the bundled credits files and the
# package licence texts (NOTICES cites creativecommons.org),
# and nothing may point at Wikimedia's media server (no hotlinked images).
LINK_HOSTS = re.compile(r'https?://[A-Za-z0-9.\-]*(?:wikipedia\.org|wikimedia\.org|creativecommons\.org)[^\s"\'`)]*')
LINK_TEXT_FILES = re.compile(r'^(main\.dart\.js|assets/NOTICES|assets/assets/quartett/[a-z]+/credits\.json)$')
HOTLINK = re.compile(r'upload\.wikimedia\.org')


def main() -> int:
    build = sys.argv[1] if len(sys.argv) > 1 else 'build/web'
    errors = []

    def need(cond: bool, msg: str) -> None:
        if not cond:
            errors.append(msg)

    # The overrides that make the engine defaults unreachable.
    with open(os.path.join(build, 'flutter_bootstrap.js'), encoding='utf-8') as f:
        need('canvasKitBaseUrl: "canvaskit/"' in f.read(),
             'flutter_bootstrap.js does not load CanvasKit from the app origin (canvasKitBaseUrl)')
    need(os.path.isfile(os.path.join(build, 'canvaskit', 'canvaskit.wasm')), 'canvaskit/canvaskit.wasm is missing')
    with open(os.path.join(build, 'klunki_sw.js'), encoding='utf-8') as f:
        need('__KLUNKI_BUILD_HASH__' not in f.read(), 'klunki_sw.js is not finalized (run pwa_finalize.py)')
    with open(os.path.join(build, 'assets', 'FontManifest.json'), encoding='utf-8') as f:
        need('"Roboto"' in f.read(), 'Roboto is not bundled (CanvasKit would fetch it from fonts.gstatic.com)')
    # KLD-082: the bundled card photos are precached (offline cards).
    photos = os.path.join(build, 'assets', 'assets', 'quartett')
    if os.path.isdir(photos):
        with open(os.path.join(build, 'klunki_sw.js'), encoding='utf-8') as f:
            need('assets/assets/quartett/' in f.read(), 'klunki_sw.js does not precache the Quartett card photos')
    # KLD-094: the Wortgewandt word lists (~1.9 MB) load on demand only; their
    # LICENSE / SOURCE.txt stay precached for the licence page.
    if os.path.isdir(os.path.join(build, 'assets', 'assets', 'wordlists')):
        with open(os.path.join(build, 'klunki_sw.js'), encoding='utf-8') as f:
            sw = f.read()
        need('words.txt.gz' not in sw, 'klunki_sw.js precaches a word list (they load on demand)')
        need('assets/assets/wordlists/de/LICENSE' in sw, 'klunki_sw.js does not precache the word list licences')

    for root, dirs, names in os.walk(build):
        dirs.sort()
        for name in sorted(names):
            path = os.path.join(root, name)
            rel = os.path.relpath(path, build).replace(os.sep, '/')
            with open(path, 'rb') as f:
                text = f.read().decode('utf-8', errors='replace')
            if HOTLINK.search(text):
                errors.append(f'{rel}: hotlinks upload.wikimedia.org (bundle the image instead)')
            if not LINK_TEXT_FILES.match(rel):
                for url in LINK_HOSTS.findall(text):
                    errors.append(f'{rel}: Wikipedia/Wikimedia/licence URL outside the link text: {url}')
                    break
            if not HOSTS.search(text):
                continue
            urls = URL.findall(text)
            for url in urls:
                if not any(rel == fname and url.startswith(prefix) for fname, prefix in ALLOWED_URLS):
                    errors.append(f'{rel}: external URL {url}')
            if not urls and rel not in ALLOWED_BARE:
                for m in HOSTS.finditer(text):
                    snippet = text[max(0, m.start() - 40):m.end() + 40].replace('\n', ' ')
                    errors.append(f'{rel}: mentions {m.group(0)}: …{snippet}…')
                    break

    if errors:
        print('PWA external URL check FAILED:', file=sys.stderr)
        for e in errors:
            print('  ' + e, file=sys.stderr)
        return 1
    print(f'PWA external URL check passed ({build}): only the overridden engine defaults remain.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
