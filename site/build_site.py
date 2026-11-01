#!/usr/bin/env python3
"""Copy the static pages (privacy/, support/, impressum/) into a web build (KLD-096).

Usage (from the repo root, after `flutter build web` + pwa_finalize.py):
    python3 -I site/build_site.py klunki/build/web

Every `{{KEY}}` in the pages is replaced with the value from site/site.json
(the one place for the contact email; change it there). Placeholders inside
HTML comments are left alone. The build fails if a page still has an unknown placeholder outside a comment.
Stdlib only.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PAGES = ('privacy', 'support', 'impressum')
PLACEHOLDER = re.compile(r'\{\{([A-Z_]+)\}\}')
COMMENT = re.compile(r'<!--.*?-->', re.S)


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    out_root = sys.argv[1]
    if not os.path.isfile(os.path.join(out_root, 'index.html')):
        print(f'error: {out_root} is not a web build (no index.html)', file=sys.stderr)
        return 1
    with open(os.path.join(HERE, 'site.json'), encoding='utf-8') as f:
        values = json.load(f)

    errors = []
    for page in PAGES:
        src = os.path.join(HERE, page, 'index.html')
        with open(src, encoding='utf-8') as f:
            html = f.read()

        def fill(m: re.Match) -> str:
            return values.get(m.group(1), m.group(0))

        # Only outside comments: split on comments and fill the other parts.
        parts, pos = [], 0
        for c in COMMENT.finditer(html):
            parts.append(PLACEHOLDER.sub(fill, html[pos:c.start()]))
            parts.append(c.group(0))
            pos = c.end()
        parts.append(PLACEHOLDER.sub(fill, html[pos:]))
        html = ''.join(parts)

        left = PLACEHOLDER.findall(COMMENT.sub('', html))
        if left:
            errors.append(f'{page}/index.html: no value in site/site.json for {sorted(set(left))}')
            continue
        dst_dir = os.path.join(out_root, page)
        os.makedirs(dst_dir, exist_ok=True)
        with open(os.path.join(dst_dir, 'index.html'), 'w', encoding='utf-8') as f:
            f.write(html)
        print(f'{page}/index.html')

    for e in errors:
        print(f'error: {e}', file=sys.stderr)
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
