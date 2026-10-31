#!/usr/bin/env python3
"""Collect Wikipedia links and free Commons photos for a Quartett deck (KLD-082).

Usage (from the repo root or klunki/; stdlib only):
    python3 -I klunki/tool/fetch_card_media.py rockets              # fetch + write
    python3 -I klunki/tool/fetch_card_media.py rockets --candidates # list free images per card
    python3 -I klunki/tool/fetch_card_media.py rockets --offline    # rebuild from the cache only

Input: klunki/tool/card_media/<deck>.json, checked in:
    {"deck": "rockets", "cards": {"A1": {"name": "Saturn V", "en": "Saturn V",
        "de": null, "file": "File:Apollo 11 Launch - GPN-2000-000630.jpg"}, ...}}
  * en / de: Wikipedia article titles (null de = follow the en article's
    interlanguage link; null en = none). Redirects are resolved to the
    canonical title and each URL is checked for HTTP 200.
  * file: the chosen Commons file (the manual override, so results are
    reproducible); absent = try the en, then the de article's lead image;
    "" = no image on purpose (the card keeps its drawn pictogram).
    Every file's licence is read from Commons (extmetadata) and must be free
    (see licence_ok); a non-free or local (fair-use) file is skipped.
  * optional top-level "maxBytes": cap per photo for this deck (default
    40 KB), to keep a deck of detailed photos at about 1.1 MB.

Output (idempotent; only changed files are rewritten):
  * klunki/assets/quartett/<deck>/<cardId>.jpg  - ~480 px long side, JPEG
    (macOS `sips`; WebP is not writable there), <= 40 KB.
  * klunki/assets/quartett/<deck>/credits.json  - per card: Wikipedia links and
    image credit (file page, author, licence name + URL, modified).
  * klunki/lib/ui/games/quartett_media_data.dart - the same data as Dart
    constants for the app (all decks found in klunki/assets/quartett/*/credits.json).
Originals and API responses are cached outside the repo
($KLUNKI_MEDIA_CACHE, default $TMPDIR/klunki_card_media); the app never
loads anything from Wikimedia at runtime.
"""
import argparse
import hashlib
import html
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

UA = 'KlunkiBuild/0.1 (https://github.com/tronicum/klunki; asset collection)'
COMMONS_API = 'https://commons.wikimedia.org/w/api.php'
MAX_BYTES = 40 * 1024
LONG_SIDE = 480
THROTTLE_S = 1.0

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # klunki/
DEF_DIR = os.path.join(ROOT, 'tool', 'card_media')
ASSET_DIR = os.path.join(ROOT, 'assets', 'quartett')
DART_OUT = os.path.join(ROOT, 'lib', 'ui', 'games', 'quartett_media_data.dart')
CACHE = os.environ.get('KLUNKI_MEDIA_CACHE') or os.path.join(tempfile.gettempdir(), 'klunki_card_media')

_last_request = [0.0]
OFFLINE = [False]


def _get(url, binary=False):
    """GET with the policy User-Agent, throttled, cached on disk."""
    key = hashlib.sha256(url.encode()).hexdigest()[:24]
    path = os.path.join(CACHE, 'http', key + ('.bin' if binary else '.json'))
    if os.path.isfile(path):
        with open(path, 'rb') as f:
            data = f.read()
        return data if binary else json.loads(data)
    if OFFLINE[0]:
        raise RuntimeError('offline and not cached: ' + url)
    wait = THROTTLE_S - (time.time() - _last_request[0])
    if wait > 0:
        time.sleep(wait)
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                data = r.read()
            break
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 3:
                time.sleep(10 * (attempt + 1))
                continue
            raise
    _last_request[0] = time.time()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(data)
    return data if binary else json.loads(data)


def _api(base, **params):
    params.update(format='json', formatversion='2')
    return _get(base + '?' + urllib.parse.urlencode(params))


def _status(url):
    """HTTP status of [url] after redirects (cached as a tiny JSON)."""
    key = 'status-' + hashlib.sha256(url.encode()).hexdigest()[:24]
    path = os.path.join(CACHE, 'http', key + '.json')
    if os.path.isfile(path):
        with open(path) as f:
            return json.load(f)['status']
    if OFFLINE[0]:
        raise RuntimeError('offline and not cached: ' + url)
    time.sleep(THROTTLE_S)
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            status = r.status
    except urllib.error.HTTPError as e:
        status = e.code
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        json.dump({'url': url, 'status': status}, f)
    return status


def article(lang, title):
    """{title, url, image (lead image file name or None), de (langlink)} or None."""
    base = 'https://%s.wikipedia.org/w/api.php' % lang
    r = _api(base, action='query', titles=title, redirects='1', prop='info|pageimages|langlinks',
             inprop='url', piprop='name', lllang='de', lllimit='1')
    pages = r.get('query', {}).get('pages', [])
    if not pages or pages[0].get('missing') or pages[0].get('invalid'):
        return None
    p = pages[0]
    ll = p.get('langlinks') or []
    url = 'https://%s.wikipedia.org/wiki/%s' % (lang, urllib.parse.quote(p['title'].replace(' ', '_'), safe='()_,-.!\'*:'))
    if _status(url) != 200:
        raise RuntimeError('%s does not resolve' % url)
    return {'title': p['title'], 'url': url, 'image': p.get('pageimage'), 'de': ll[0]['title'] if ll else None}


def article_images(lang, title):
    base = 'https://%s.wikipedia.org/w/api.php' % lang
    r = _api(base, action='query', titles=title, redirects='1', prop='images', imlimit='100')
    pages = r.get('query', {}).get('pages', [])
    return [re.sub(r'^[^:]+:', 'File:', i['title']) for i in (pages[0].get('images') or [])] if pages else []


def commons_info(file_title):
    """Commons imageinfo for 'File:…' (None if not on Commons, e.g. a local fair-use file)."""
    if not file_title.startswith('File:'):
        file_title = 'File:' + file_title
    r = _api(COMMONS_API, action='query', titles=file_title, prop='imageinfo', redirects='1',
             iiprop='url|extmetadata|size|mime', iiurlwidth='1280')
    pages = r.get('query', {}).get('pages', [])
    if not pages or pages[0].get('missing') or 'imageinfo' not in pages[0]:
        return None
    info = pages[0]['imageinfo'][0]
    info['title'] = pages[0]['title']
    return info


def commons_infos(file_titles):
    """Batch form of commons_info: {requested title: info or None} (50 per request)."""
    out = {}
    titles = [t if t.startswith('File:') else 'File:' + t for t in file_titles]
    for i in range(0, len(titles), 50):
        chunk = titles[i:i + 50]
        r = _api(COMMONS_API, action='query', titles='|'.join(chunk), prop='imageinfo',
                 iiprop='url|extmetadata|size|mime')
        q = r.get('query', {})
        norm = {n['from']: n['to'] for n in q.get('normalized', [])}
        by = {}
        for p in q.get('pages', []):
            if p.get('missing') or 'imageinfo' not in p:
                continue
            info = p['imageinfo'][0]
            info['title'] = p['title']
            by[p['title']] = info
        for t in chunk:
            out[t] = by.get(norm.get(t, t))
    return out


def _meta(info, key):
    return ((info.get('extmetadata') or {}).get(key) or {}).get('value') or ''


def strip_html(s):
    s = re.sub(r'<[^>]+>', '', s or '')
    return re.sub(r'\s+', ' ', html.unescape(s)).strip()


# Free licences that allow commercial use and modification with attribution
# (or none): public domain, CC0, CC BY / BY-SA (any version, incl. IGO and
# ports), Free Art License, Open Government Licence (UK), Licence Ouverte
# (Etalab, FR), GODL-India; Commons' generic "Attribution" template. GFDL alone is not
# accepted (only as a dual licence, where Commons names the CC option).
_ALLOWED = [
    r'^public domain', r'^pd\b', r'^pd-', r'^cc0', r'^cc[ -]?zero',
    r'^cc by(-sa)? \d(\.\d)?( [a-z]{2,3})?( igo)?$', r'^cc-by(-sa)?-\d',
    r'^fal\b', r'^free art licen[cs]e', r'^ogl\b', r'^open government licen[cs]e',
    r'^attribution$', r'^copyrighted free use$',
    # Government open-data licences (attribution only, commercial use and
    # modification allowed): France (Etalab), India.
    r'^licence ouverte', r'^etalab', r'^godl-india$',
]
_FORBIDDEN = [r'\bnc\b', r'\bnd\b', r'non-?commercial', r'no ?deriv', r'fair use', r'permission', r'^gfdl']


def licence_ok(info):
    """(ok, reason) for a Commons imageinfo."""
    short = strip_html(_meta(info, 'LicenseShortName'))
    s = short.lower()
    if _meta(info, 'NonFree').lower() == 'true':
        return False, 'non-free (%s)' % short
    if not s:
        return False, 'no licence in metadata'
    for pat in _FORBIDDEN:
        if re.search(pat, s):
            return False, 'licence not allowed: %s' % short
    for pat in _ALLOWED:
        if re.search(pat, s):
            return True, short
    return False, 'licence unclear: %s' % short


def licence_url(info):
    url = _meta(info, 'LicenseUrl')
    if url:
        return url.replace('http://', 'https://', 1)
    s = strip_html(_meta(info, 'LicenseShortName')).lower()
    if 'public domain' in s or s.startswith('pd'):
        return 'https://creativecommons.org/publicdomain/mark/1.0/'
    if s.startswith('cc0'):
        return 'https://creativecommons.org/publicdomain/zero/1.0/'
    return ''


def author_of(info):
    """Plain-text author; 'Unknown author' gets the source host from Credit."""
    author = re.sub(r'^(photo )?credit:\s*', '', strip_html(_meta(info, 'Artist')), flags=re.I)
    m = re.match(r'^(.+?)\1+$', author)
    if m:
        author = m.group(1)
    credit = strip_html(_meta(info, 'Credit'))
    if not author or author.lower() in ('unknown author', 'unknown', 'anonymous'):
        host = re.search(r'https?://([^/\s]+)', credit)
        if host:
            return 'Unknown author (%s)' % host.group(1)
        return credit[:120] if credit and len(credit) < 120 else 'Unknown author'
    return author


def credit_of(info, author=None):
    ok, short = licence_ok(info)
    assert ok
    author = author or author_of(info)
    title = info['title']
    return {
        'commonsTitle': title,
        'source': 'https://commons.wikimedia.org/wiki/' + urllib.parse.quote(title.replace(' ', '_'), safe='()_,-.!\'*:'),
        'author': author[:200],
        'license': short,
        'licenseUrl': licence_url(info),
        'shareAlike': 'sa' in re.split(r'[ -]', short.lower()),
        'description': strip_html(_meta(info, 'ImageDescription'))[:300],
    }


def resize(src, dest, max_bytes=MAX_BYTES):
    """~480 px long side JPEG <= max_bytes via sips (no extra tools)."""
    sips = shutil.which('sips')
    if not sips:
        raise RuntimeError('sips not found (macOS); no image converter available')
    # 40 and 32 only for very detailed photos (KLD-084: a few train
    # photos); earlier outputs never reach them, so they stay byte-identical.
    for q in (80, 72, 64, 56, 48, 40, 32):
        tmp = dest + '.tmp.jpg'
        subprocess.run([sips, '-s', 'format', 'jpeg', '-s', 'formatOptions', str(q), '-Z', str(LONG_SIDE),
                        src, '--out', tmp], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if os.path.getsize(tmp) <= max_bytes:
            os.replace(tmp, dest)
            return q
        os.remove(tmp)
    raise RuntimeError('cannot get %s under %d bytes' % (dest, max_bytes))


def _write_if_changed(path, text):
    if os.path.isfile(path):
        with open(path, encoding='utf-8') as f:
            if f.read() == text:
                return False
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
    return True


def candidates(deck_def):
    for cid, c in sorted(deck_def['cards'].items()):
        print('== %s %s' % (cid, c.get('name')))
        seen = set()
        de = c.get('de') or (c.get('en') and (article('en', c['en']) or {}).get('de'))
        for lang, title in (('en', c.get('en')), ('de', de)):
            if not title:
                continue
            files = [f for f in article_images(lang, title)
                     if f not in seen and re.search(r'\.(jpe?g|png|tiff?)$', f, re.I)]
            infos = commons_infos(files)
            for f in files:
                seen.add(f)
                info = infos.get(f if f.startswith('File:') else 'File:' + f)
                if info is None:
                    print('   -- %s: not on Commons' % f)
                    continue
                ok, why = licence_ok(info)
                print('   %s %s [%s] %dx%d' % ('OK' if ok else '--', info['title'], why, info.get('width', 0), info.get('height', 0)))


def build(deck_def):
    deck = deck_def['deck']
    out_dir = os.path.join(ASSET_DIR, deck)
    os.makedirs(out_dir, exist_ok=True)
    # Optional per-deck cap per photo (KLD-084): wide, detailed photos (trains)
    # would otherwise all sit at 40 KB and push the deck past ~1.1 MB.
    max_bytes = int(deck_def.get('maxBytes', MAX_BYTES))
    cards = {}
    for cid, c in sorted(deck_def['cards'].items()):
        en = article('en', c['en']) if c.get('en') else None
        de_title = c.get('de') or (en and en['de'])
        de = article('de', de_title) if de_title else None
        links = {}
        if de:
            links['de'] = de['url']
        if en:
            links['en'] = en['url']
        if c.get('file') is not None:
            tries = [c['file']] if c['file'] else []
        else:
            tries = [x for x in ((en or {}).get('image'), (de or {}).get('image')) if x]
        image = None
        for f in tries:
            info = commons_info(f)
            if info is None:
                print('  %s: %s is not on Commons (local/fair use?), skipped' % (cid, f))
                continue
            ok, why = licence_ok(info)
            if not ok:
                print('  %s: %s: %s, skipped' % (cid, info['title'], why))
                continue
            credit = credit_of(info, c.get('author'))
            src_url = info['url'] if info.get('size', 0) <= 25_000_000 else info.get('thumburl', info['url'])
            ext = os.path.splitext(urllib.parse.urlparse(src_url).path)[1].lower() or '.jpg'
            orig = os.path.join(CACHE, 'originals', deck, cid + ext)
            os.makedirs(os.path.dirname(orig), exist_ok=True)
            data = _get(src_url, binary=True)
            with open(orig, 'wb') as fh:
                fh.write(data)
            name = cid + '.jpg'
            dest = os.path.join(out_dir, name)
            stamp = os.path.join(CACHE, 'stamps', deck, cid + '.txt')
            sig = hashlib.sha256(data).hexdigest() + ' %d' % LONG_SIDE
            if max_bytes != MAX_BYTES:
                sig += ' max%d' % max_bytes
            if not (os.path.isfile(dest) and os.path.isfile(stamp) and open(stamp).read() == sig):
                resize(orig, dest, max_bytes)
                os.makedirs(os.path.dirname(stamp), exist_ok=True)
                with open(stamp, 'w') as fh:
                    fh.write(sig)
            credit.update(file=name, modified='resized (%d px, JPEG)' % LONG_SIDE, bytes=os.path.getsize(dest))
            image = credit
            break
        if image is None:
            stale = os.path.join(out_dir, cid + '.jpg')
            if os.path.isfile(stale):
                os.remove(stale)
        cards[cid] = {'name': c.get('name', ''), 'wikipedia': links, 'image': image,
                      **({'note': c['note']} if c.get('note') else {})}
        print('%s %-22s img=%s de=%s en=%s' % (cid, c.get('name', ''), image['license'] if image else '-',
                                              'y' if 'de' in links else '-', 'y' if 'en' in links else '-'))
    credits = {'deck': deck, 'generatedBy': 'klunki/tool/fetch_card_media.py', 'cards': cards}
    _write_if_changed(os.path.join(out_dir, 'credits.json'), json.dumps(credits, ensure_ascii=False, indent=2) + '\n')
    total = sum(os.path.getsize(os.path.join(out_dir, f)) for f in os.listdir(out_dir))
    n = sum(1 for v in cards.values() if v['image'])
    print('%s: %d/%d cards with an image, %d bytes in %s' % (deck, n, len(cards), total, os.path.relpath(out_dir, ROOT)))


def _dart_str(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', ' ') + "'"


def write_dart():
    decks = {}
    for d in sorted(os.listdir(ASSET_DIR)):
        p = os.path.join(ASSET_DIR, d, 'credits.json')
        if os.path.isfile(p):
            with open(p, encoding='utf-8') as f:
                decks[d] = json.load(f)
    out = ['// GENERATED by klunki/tool/fetch_card_media.py from',
           '// assets/quartett/<deck>/credits.json (KLD-082). Do not edit by hand:',
           '// change klunki/tool/card_media/<deck>.json and run the tool.',
           '',
           "import 'quartett_media.dart';",
           '',
           '/// Wikipedia links and bundled photos per deck id and card id.',
           'const Map<String, Map<String, QuartettCardMedia>> quartettMediaData = {']
    for deck, data in decks.items():
        out.append('  %s: {' % _dart_str(deck))
        for cid, c in data['cards'].items():
            w = c['wikipedia']
            img = c['image']
            parts = []
            if 'de' in w:
                parts.append('wikiDe: %s' % _dart_str(w['de']))
            if 'en' in w:
                parts.append('wikiEn: %s' % _dart_str(w['en']))
            if img:
                parts.append('image: QuartettImageCredit(\n        asset: %s,\n        source: %s,\n'
                             '        author: %s,\n        license: %s,\n        licenseUrl: %s,\n'
                             '        shareAlike: %s,\n      )' % (
                                 _dart_str('assets/quartett/%s/%s' % (deck, img['file'])), _dart_str(img['source']),
                                 _dart_str(img['author']), _dart_str(img['license']), _dart_str(img['licenseUrl']),
                                 'true' if img['shareAlike'] else 'false'))
            out.append('    %s: QuartettCardMedia(' % _dart_str(cid))
            out.extend('      %s,' % x for x in parts)
            out.append('    ),')
        out.append('  },')
    out.append('};')
    if _write_if_changed(DART_OUT, '\n'.join(out) + '\n'):
        print('wrote ' + os.path.relpath(DART_OUT, ROOT))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('deck')
    ap.add_argument('--candidates', action='store_true', help='list free images in the articles, write nothing')
    ap.add_argument('--offline', action='store_true', help='use cached API responses and originals only')
    a = ap.parse_args()
    OFFLINE[0] = a.offline
    with open(os.path.join(DEF_DIR, a.deck + '.json'), encoding='utf-8') as f:
        deck_def = json.load(f)
    if a.candidates:
        candidates(deck_def)
        return 0
    build(deck_def)
    write_dart()
    return 0


if __name__ == '__main__':
    sys.exit(main())
