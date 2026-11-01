#!/usr/bin/env python3
"""Export the legal pages as plain text blocks for the app (KLD-102).

Usage (from the repo root, after editing site/privacy/ or site/impressum/):
    python3 -I site/export_legal_text.py            # all pages
    python3 -I site/export_legal_text.py impressum  # just one

For each page in PAGES, reads site/<page>/index.html and writes
klunki/assets/legal/<page>.json: {"de": [...], "en": [...]}, each a list of
blocks {"t": "h1"|"h2"|"meta"|"p"|"li"|"address", "x": "text"}. The app
shows them offline ("Datenschutz" and "Impressum" in "Über Klunki"); the web
pages stay the reference. `{{KEY}}` placeholders are filled from
site/site.json like build_site.py does. A widget test
(klunki/test/ui/about_screen_test.dart) fails when an export no longer
matches its page. Support is not bundled: it stays online only.
The old command `site/export_privacy_text.py` still works (privacy only).
Stdlib only.
"""
import json
import os
import re
import sys
from html.parser import HTMLParser

HERE = os.path.dirname(os.path.abspath(__file__))
PAGES = ('privacy', 'impressum')
BLOCKS = {'h1', 'h2', 'p', 'li', 'address'}


class _Parser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.lang = None  # inside <article lang=...>
        self.out = {}
        self.block = None  # (html tag, kind, [text parts])

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == 'article':
            self.lang = a.get('lang')
            self.out[self.lang] = []
        elif self.lang and tag in BLOCKS and self.block is None:
            kind = 'meta' if tag == 'p' and a.get('class') == 'meta' else tag
            self.block = (tag, kind, [])
        elif self.block and tag == 'br':
            self.block[2].append('\x00')  # <br>: a real line break

    def handle_endtag(self, tag):
        if tag == 'article':
            self.lang = None
        elif self.block and tag == self.block[0]:
            lines = [re.sub(r'\s+', ' ', line).strip() for line in ''.join(self.block[2]).split('\x00')]
            self.out[self.lang].append({'t': self.block[1], 'x': '\n'.join(line for line in lines if line)})
            self.block = None

    def handle_data(self, data):
        if self.block:
            self.block[2].append(data)


def export(page: str, values: dict) -> int:
    src = os.path.join(HERE, page, 'index.html')
    dst = os.path.join(HERE, '..', 'klunki', 'assets', 'legal', f'{page}.json')
    with open(src, encoding='utf-8') as f:
        html = re.sub(r'<!--.*?-->', '', f.read(), flags=re.S)
    html = re.sub(r'\{\{([A-Z_]+)\}\}', lambda m: values.get(m.group(1), m.group(0)), html)
    p = _Parser()
    p.feed(html)
    if set(p.out) != {'de', 'en'} or not all(p.out.values()):
        print(f'error: expected <article lang="de"> and <article lang="en"> in {src}', file=sys.stderr)
        return 1
    if '{{' in json.dumps(p.out):
        print(f'error: a {{{{KEY}}}} placeholder in {src} has no value in site/site.json', file=sys.stderr)
        return 1
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(dst, 'w', encoding='utf-8') as f:
        json.dump(p.out, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print(os.path.relpath(dst))
    return 0


def main(pages=None) -> int:
    pages = list(pages or sys.argv[1:] or PAGES)
    unknown = [p for p in pages if p not in PAGES]
    if unknown:
        print(f'error: unknown page(s) {", ".join(unknown)}; known: {", ".join(PAGES)}', file=sys.stderr)
        return 2
    with open(os.path.join(HERE, 'site.json'), encoding='utf-8') as f:
        values = json.load(f)
    return max(export(page, values) for page in pages)


if __name__ == '__main__':
    sys.exit(main())
