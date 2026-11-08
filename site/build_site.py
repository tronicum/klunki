#!/usr/bin/env python3
"""Build the GitHub Pages site: landing page, static pages, PWA under play/
(KLD-096, KLD-115).

Usage (from the repo root):
    python3 -I site/build_site.py OUT [--app [SUBPATH=]WEB_BUILD ...]

`--app klunki/build/web` copies the build to OUT/play/; the form
`--app preview/play=DIR` (repeatable) puts another build elsewhere, e.g. a
later preview channel (see docs/tasks/KLD-115-landing-page.md).

Writes into OUT (created if needed):
  index.html             the landing page (site/index.html, filled in below)
  assets/                icon and screenshots for the landing page
  klunki_sw.js           a self-unregistering service worker: the PWA used to
                         live at the site root (KLD-096..113); an old root worker
                         would keep answering the landing page with the app
  privacy/ support/ impressum/   the static pages
  play/                  a copy of --app (a finalized `flutter build web
                         --base-href /<repo>/play/` build), when given;
                         each build's --base-href must match its sub-path

Every `{{KEY}}` in the pages is replaced: CONTACT_EMAIL and the other keys of
site/site.json, plus for the landing page GAMES_DE/EN (titles and
descriptions from the app's ARB files), FAQ_DE/EN (the in-app help, ARB keys
with the prefix `help`, see faq_blocks), STORES_DE/EN (App Store / Google
Play: greyed out "Geschlossene Beta" unless KLUNKI_IOS_BETA_URL /
KLUNKI_ANDROID_URL are set to https links in the environment) and
BETA_MAIL_* (mailto links asking for beta access). Placeholders inside HTML
comments are left alone. The build fails if a page still has an unknown
placeholder outside a comment. Stdlib only.
"""
import html
import json
import os
import re
import shutil
import sys
from urllib.parse import quote

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
ARB_DIR = os.path.join(REPO, 'klunki', 'lib', 'l10n')
PAGES = ('privacy', 'support', 'impressum')
LANGS = ('de', 'en')
PLACEHOLDER = re.compile(r'\{\{([A-Z_]+)\}\}')
COMMENT = re.compile(r'<!--.*?-->', re.S)

# Menu order of packages/klunki_engine/lib/registry.dart: (id, ARB suffix of
# menuGame*/menuDesc*).
GAMES = (
    ('connect4', 'Connect4'),
    ('muehle', 'Muehle'),
    ('quartett-trumpf', 'QuartettTrumpf'),
    ('quartett-sets', 'QuartettSets'),
    ('schiffe', 'Schiffe'),
    ('gostrategy', 'GoStrategy'),
    ('chess', 'Chess'),
    ('wordtiles', 'WordTiles'),
    ('maumau', 'MauMau'),
)

# Texts the build puts into the landing page (not worth ARB keys: the site
# is de + en only, like the other pages).
TEXT = {
    'de': {
        'closed': 'Geschlossene Beta',
        'ios': 'iPhone und iPad',
        'android': 'Android',
        'ios_open': 'Beta testen (TestFlight)',
        'android_open': 'Beta testen (Google Play)',
        'subject_ios': 'Klunki Beta: iPhone/iPad',
        'subject_android': 'Klunki Beta: Android',
        'body': 'Hallo,\n\nich möchte Klunki als Beta ausprobieren.\nVorname (freiwillig): \n',
        'faq_more': 'Weitere Fragen und Antworten stehen auf der <a href="support/#de">Hilfe-Seite</a>.',
    },
    'en': {
        'closed': 'Closed beta',
        'ios': 'iPhone and iPad',
        'android': 'Android',
        'ios_open': 'Try the beta (TestFlight)',
        'android_open': 'Try the beta (Google Play)',
        'subject_ios': 'Klunki Beta: iPhone/iPad',
        'subject_android': 'Klunki Beta: Android',
        'body': 'Hello,\n\nI would like to try the Klunki beta.\nFirst name (optional): \n',
        'faq_more': 'More questions and answers are on the <a href="support/#en">help page</a>.',
    },
}


def load_arb(lang: str, arb_dir: str = None) -> dict:
    with open(os.path.join(arb_dir or ARB_DIR, f'app_{lang}.arb'), encoding='utf-8') as f:
        return json.load(f)  # dicts keep the file order


def esc(s: str) -> str:
    return html.escape(s, quote=True)


def games_html(arb: dict) -> str:
    rows = []
    for gid, suffix in GAMES:
        title, desc = arb[f'menuGame{suffix}'], arb[f'menuDesc{suffix}']
        rows.append(f'      <li data-game="{gid}"><strong>{esc(title)}</strong><span>{esc(desc)}</span></li>')
    return '\n'.join(rows)


# --- FAQ from the in-app help ------------------------------------------------
#
# The in-app help ("So spielt ihr zusammen", KLD-113, parallel branch) stores
# its texts as ARB keys starting with `help`. Their order in app_de.arb is the
# order on the page. Convention read here:
#   help…Title / help…Question / help…Q   -> a question (<h3>)
#   any other help… key                    -> answer text for the question
#                                             before it; "\n" starts a new
#                                             paragraph, lines starting with
#                                             "• " or "- " become a list
#   helpTitle (exactly)                    -> the section heading (otherwise
#                                             "Häufige Fragen" / "FAQ")
# ICU placeholders ({player}) and plurals are not expected in help texts; a
# key with one is skipped with a warning.
HELP_PREFIX = 'help'
QUESTION = re.compile(r'(?:Title|Question|Q)$')


def faq_blocks(arb: dict) -> tuple:
    """(heading or None, [(question, [answer texts])]) from the help keys."""
    heading, items = None, []
    for key, value in arb.items():
        if key.startswith('@') or not key.startswith(HELP_PREFIX) or not isinstance(value, str):
            continue
        if key == 'helpTitle':
            heading = value
            continue
        if '{' in value:
            print(f'warning: {key} has a placeholder, not on the landing page', file=sys.stderr)
            continue
        if QUESTION.search(key):
            items.append((value, []))
        elif items:
            items[-1][1].append(value)
        else:
            items.append((None, [value]))
    return heading, items


def answer_html(text: str) -> str:
    out, bullets = [], []

    def flush():
        if bullets:
            out.append('<ul>' + ''.join(f'<li>{esc(b)}</li>' for b in bullets) + '</ul>')
            bullets.clear()

    for line in text.split('\n'):
        line = line.strip()
        if not line:
            flush()
            continue
        if line.startswith(('• ', '- ')):
            bullets.append(line[2:].strip())
        else:
            flush()
            out.append(f'<p>{esc(line)}</p>')
    flush()
    return '\n'.join(out)


def faq_html(arb: dict, lang: str) -> str:
    """The FAQ section, or only the link to the support page without help keys."""
    heading, items = faq_blocks(arb)
    more = f'<p>{TEXT[lang]["faq_more"]}</p>'
    if not items:
        return more
    title = heading or ('Häufige Fragen' if lang == 'de' else 'Frequently asked questions')
    parts = [f'<h3 class="faq-title">{esc(title)}</h3>']
    for q, answers in items:
        body = '\n'.join(answer_html(a) for a in answers)
        if q is None:
            parts.append(body)
        else:
            parts.append(f'<details><summary>{esc(q)}</summary>\n{body}\n</details>')
    parts.append(more)
    return '\n'.join(parts)


# --- App Store / Google Play ------------------------------------------------

def https_or_empty(url: str) -> str:
    url = (url or '').strip()
    return url if url.startswith('https://') else ''


def mailto(email: str, subject: str, body: str) -> str:
    return f'mailto:{email}?subject={quote(subject)}&body={quote(body)}'


def stores_html(lang: str, ios_url: str, android_url: str) -> str:
    t = TEXT[lang]
    cells = []
    for kind, url in (('ios', ios_url), ('android', android_url)):
        if url:
            cells.append(f'<a class="store open" href="{esc(url)}" rel="noopener">'
                         f'<span class="store-name">{esc(t[kind])}</span>'
                         f'<span class="store-state">{esc(t[kind + "_open"])}</span></a>')
        else:
            cells.append(f'<span class="store closed" aria-disabled="true">'
                         f'<span class="store-name">{esc(t[kind])}</span>'
                         f'<span class="store-state">{esc(t["closed"])}</span></span>')
    return '\n'.join(cells)


def landing_values(values: dict, env: dict, arb_dir: str = None) -> dict:
    out = {}
    email = values['CONTACT_EMAIL']
    ios, android = https_or_empty(env.get('KLUNKI_IOS_BETA_URL')), https_or_empty(env.get('KLUNKI_ANDROID_URL'))
    for lang in LANGS:
        arb = load_arb(lang, arb_dir)
        up = lang.upper()
        out[f'GAMES_{up}'] = games_html(arb)
        out[f'FAQ_{up}'] = faq_html(arb, lang)
        out[f'STORES_{up}'] = stores_html(lang, ios, android)
        t = TEXT[lang]
        out[f'BETA_MAIL_IOS_{up}'] = esc(mailto(email, t['subject_ios'], t['body']))
        out[f'BETA_MAIL_ANDROID_{up}'] = esc(mailto(email, t['subject_android'], t['body']))
        out[f'BETA_BODY_{up}'] = esc(t['body'])
    return out


# --- filling and copying ----------------------------------------------------

def fill(html_text: str, values: dict) -> tuple:
    """(filled html, unknown placeholders outside comments)."""
    def sub(m: re.Match) -> str:
        return values.get(m.group(1), m.group(0))

    parts, pos = [], 0
    for c in COMMENT.finditer(html_text):
        parts.append(PLACEHOLDER.sub(sub, html_text[pos:c.start()]))
        parts.append(c.group(0))
        pos = c.end()
    parts.append(PLACEHOLDER.sub(sub, html_text[pos:]))
    out = ''.join(parts)
    return out, sorted(set(PLACEHOLDER.findall(COMMENT.sub('', out))))


# Pages must not load anything from another host (links to other sites are
# fine: they open only on a click). Checked on every page written.
EXTERNAL_LOAD = re.compile(
    r"""(?:\b(?:src|srcset|poster|data|action)\s*=\s*["']\s*(?:https?:)?//)"""
    r"""|(?:<link\b[^>]*\bhref\s*=\s*["']\s*(?:https?:)?//)"""
    r"""|(?:url\(\s*["']?\s*(?:https?:)?//)"""
    r"""|(?:@import\b)""", re.I)


def external_loads(html_text: str) -> list:
    return [m.group(0) for m in EXTERNAL_LOAD.finditer(COMMENT.sub('', html_text))]


def main(argv=None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    apps = []  # (sub-path in OUT, web build)
    while '--app' in args:
        i = args.index('--app')
        if i + 1 >= len(args):
            print(__doc__, file=sys.stderr)
            return 2
        spec = args[i + 1]
        sub, _, src = spec.rpartition('=') if '=' in spec else ('play', '', spec)
        apps.append((sub.strip('/'), src))
        del args[i:i + 2]
    if len(args) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    out_root = args[0]
    for sub, src in apps:
        if not sub or not os.path.isfile(os.path.join(src, 'main.dart.js')):
            print(f'error: --app {sub}={src}: not a Flutter web build (no main.dart.js) or no sub-path', file=sys.stderr)
            return 1
    if os.path.isfile(os.path.join(out_root, 'main.dart.js')):
        print(f'error: {out_root} is a web build; the app goes to <out>/play/ now (--app)', file=sys.stderr)
        return 1
    with open(os.path.join(HERE, 'site.json'), encoding='utf-8') as f:
        values = json.load(f)
    values.update(landing_values(values, os.environ))

    os.makedirs(out_root, exist_ok=True)
    errors = []
    for page, src in [('', 'index.html')] + [(p, os.path.join(p, 'index.html')) for p in PAGES]:
        with open(os.path.join(HERE, src), encoding='utf-8') as f:
            text, left = fill(f.read(), values)
        if left:
            errors.append(f'{src}: no value for {left}')
            continue
        loads = external_loads(text)
        if loads:
            errors.append(f'{src}: loads from another host: {loads}')
            continue
        dst_dir = os.path.join(out_root, page)
        os.makedirs(dst_dir, exist_ok=True)
        with open(os.path.join(dst_dir, 'index.html'), 'w', encoding='utf-8') as f:
            f.write(text)
        print(os.path.join(page, 'index.html'))

    shutil.copytree(os.path.join(HERE, 'assets'), os.path.join(out_root, 'assets'), dirs_exist_ok=True)
    shutil.copy(os.path.join(HERE, 'root_sw.js'), os.path.join(out_root, 'klunki_sw.js'))
    shutil.copy(os.path.join(HERE, 'assets', 'favicon.png'), os.path.join(out_root, 'favicon.png'))
    print('assets/, klunki_sw.js (unregisters the old root worker), favicon.png')
    for sub, src in apps:
        dst = os.path.join(out_root, sub)
        if os.path.isdir(dst):
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        print(f'{sub}/ (from {src})')

    for e in errors:
        print(f'error: {e}', file=sys.stderr)
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
