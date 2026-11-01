#!/usr/bin/env python3
"""Finalize klunki_sw.js after `flutter build web` (KLD-010).

Usage (from klunki/):
    flutter build web --release
    python3 build/web/pwa_finalize.py            # or: python3 web/pwa_finalize.py build/web

Fills in klunki_sw.js in the build directory:
  * __KLUNKI_BUILD_HASH__  -> sha256 (16 hex chars) over all build files, so
    every different build yields a different worker (=> update + new cache).
  * __KLUNKI_PRECACHE__    -> list of app-shell files to precache on install.
CanvasKit/Skwasm engines (~3-7 MB each, only one is used per browser) are not
precached; the page hands the variant it actually loaded to the worker.
Removes its own copy from the build directory afterwards. Deterministic,
stdlib only, idempotent (refuses to run twice on the same output).
"""
import hashlib
import json
import os
import sys

SW = 'klunki_sw.js'
SELF = 'pwa_finalize.py'
# Not part of the app / not needed at runtime.
EXCLUDE_FROM_HASH = {SW, SELF, '.last_build_id'}
EXCLUDE_FROM_PRECACHE = EXCLUDE_FROM_HASH | {
    'flutter_service_worker.js',  # Flutter's deprecated cleanup worker
    'assets/NOTICES',             # 1.3 MB, only for the license page (runtime-cached)
}
# Static pages published next to the app (KLD-096, GitHub Pages): not part of
# the app, the service worker leaves them alone (klunki_sw.js STATIC_PAGES).
STATIC_PAGES = ('privacy/', 'support/', 'impressum/')
# Loaded on demand only (KLD-094: the Wortgewandt word lists, ~1.9 MB gzip):
# not precached; the worker caches them on first use (cache-first fetch).
# Their LICENSE / SOURCE.txt stay precached (the licence page reads them).
ON_DEMAND = ('assets/assets/wordlists/de/words.txt.gz', 'assets/assets/wordlists/en/words.txt.gz')


def main() -> int:
    build_dir = os.path.abspath(
        sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__)))
    sw_path = os.path.join(build_dir, SW)
    if not os.path.isfile(os.path.join(build_dir, 'main.dart.js')) or not os.path.isfile(sw_path):
        print(f'error: {build_dir} is not a Flutter web build containing {SW}', file=sys.stderr)
        return 1

    files = []
    for root, dirs, names in os.walk(build_dir):
        dirs.sort()
        for name in sorted(names):
            rel = os.path.relpath(os.path.join(root, name), build_dir).replace(os.sep, '/')
            files.append(rel)
    files.sort()

    digest = hashlib.sha256()
    for rel in files:
        if rel in EXCLUDE_FROM_HASH:
            continue
        digest.update(rel.encode() + b'\0')
        with open(os.path.join(build_dir, rel), 'rb') as f:
            digest.update(hashlib.sha256(f.read()).digest())
    build_hash = digest.hexdigest()[:16]

    precache = [
        rel for rel in files
        if rel not in EXCLUDE_FROM_PRECACHE
        and not rel.startswith('canvaskit/')
        and rel not in ON_DEMAND
        and not rel.startswith(STATIC_PAGES)
        and not rel.endswith('.symbols')
    ]

    with open(sw_path, encoding='utf-8') as f:
        sw = f.read()
    if "'__KLUNKI_BUILD_HASH__'" not in sw or '/*__KLUNKI_PRECACHE__*/' not in sw:
        print(f'error: {SW} already finalized (or placeholders missing)', file=sys.stderr)
        return 1
    sw = sw.replace("'__KLUNKI_BUILD_HASH__'", json.dumps(build_hash))
    sw = sw.replace('[/*__KLUNKI_PRECACHE__*/]', json.dumps(precache, indent=2))
    with open(sw_path, 'w', encoding='utf-8') as f:
        f.write(sw)

    own_copy = os.path.join(build_dir, SELF)
    if os.path.isfile(own_copy):
        os.remove(own_copy)

    print(f'{SW}: build {build_hash}, {len(precache)} files precached')
    return 0


if __name__ == '__main__':
    sys.exit(main())
