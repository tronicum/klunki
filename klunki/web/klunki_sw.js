// Klunki offline service worker (KLD-010).
//
// Registered by index.html as `klunki_sw.js` (scope `./`). Flutter's own
// `flutter_service_worker.js` is a deprecated, self-unregistering cleanup
// worker; web/flutter_bootstrap.js makes sure flutter.js never registers it.
//
// Two modes:
//  * finalized (after `python3 build/web/pwa_finalize.py`, see the KLD-010
//    card): BUILD_HASH/PRECACHE are filled in from the build output. The app
//    shell is precached on install, same-origin GETs are served cache-first,
//    and every new build changes this file's bytes -> the browser installs the
//    new worker, which uses a new cache and deletes the old ones.
//  * dev (placeholders untouched): a small core list is precached, requests go
//    network-first with cache fallback, so an un-finalized build never serves
//    stale code but still works offline after one online visit.
'use strict';

const BUILD_HASH = '__KLUNKI_BUILD_HASH__';
const PRECACHE = [/*__KLUNKI_PRECACHE__*/];

const FINALIZED = !BUILD_HASH.startsWith('__');
const CACHE_PREFIX = 'klunki-';
const CACHE_NAME = CACHE_PREFIX + (FINALIZED ? BUILD_HASH : 'dev');

// Always-needed shell files (used as the precache list in dev mode).
const CORE = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
  'assets/AssetManifest.bin',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
];
// Files that must be cached for the install to count as successful.
const REQUIRED = ['index.html', 'flutter_bootstrap.js', 'flutter.js', 'main.dart.js'];

// Cross-origin hosts Flutter web may load from at runtime (Roboto from
// fonts.gstatic.com; CanvasKit from www.gstatic.com if not loaded locally).
const CACHEABLE_HOSTS = new Set(['fonts.gstatic.com', 'www.gstatic.com']);

// Never cache these (the browser fetches worker scripts itself, debug symbols
// are not needed at runtime).
const NEVER_CACHE = /(?:klunki_sw\.js|flutter_service_worker\.js|\.symbols|pwa_finalize\.py)$/;

const scopeUrl = new URL(self.registration.scope);
const toUrl = (path) => new URL(path, scopeUrl).href;

function isCacheable(url) {
  if (url.protocol !== 'https:' && url.protocol !== 'http:') return false;
  if (NEVER_CACHE.test(url.pathname)) return false;
  if (url.origin === scopeUrl.origin) return url.href.startsWith(scopeUrl.href);
  return CACHEABLE_HOSTS.has(url.hostname);
}

async function cacheUrl(cache, url) {
  // `cache: 'reload'` bypasses the HTTP cache so a new build never precaches
  // stale bytes.
  const response = await fetch(new Request(url, { cache: 'reload' }));
  if (!response.ok && response.type !== 'opaque') {
    throw new Error(`${url}: HTTP ${response.status}`);
  }
  await cache.put(url, response);
}

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    const list = [...new Set((FINALIZED ? CORE.concat(PRECACHE) : CORE).map(toUrl))];
    const results = await Promise.allSettled(list.map((url) => cacheUrl(cache, url)));
    const required = new Set(REQUIRED.map(toUrl));
    results.forEach((result, i) => {
      if (result.status === 'rejected') {
        console.warn('Klunki SW: precache failed', result.reason);
        if (required.has(list[i])) throw result.reason; // abort install
      }
    });
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names
      .filter((name) => name.startsWith(CACHE_PREFIX) && name !== CACHE_NAME)
      .map((name) => caches.delete(name)));
    await self.clients.claim();
  })());
});

async function cacheFirst(request, cacheKey) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(cacheKey);
  if (cached) return cached;
  const response = await fetch(request);
  if (response.ok || response.type === 'opaque') {
    cache.put(cacheKey, response.clone()).catch(() => {});
  }
  return response;
}

async function networkFirst(request, cacheKey) {
  const cache = await caches.open(CACHE_NAME);
  try {
    const response = await fetch(request);
    if (response.ok || response.type === 'opaque') {
      cache.put(cacheKey, response.clone()).catch(() => {});
    }
    return response;
  } catch (e) {
    const cached = await cache.match(cacheKey);
    if (cached) return cached;
    throw e;
  }
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET' || request.headers.has('range')) return;
  const url = new URL(request.url);
  if (!isCacheable(url)) return;

  // Single-page app: every navigation inside the scope gets the app shell.
  const cacheKey = request.mode === 'navigate' ? toUrl('index.html') : request;
  event.respondWith(FINALIZED ? cacheFirst(request, cacheKey) : networkFirst(request, cacheKey));
});

// index.html posts the resource URLs the page loaded before this worker
// controlled it (first visit), so they are available offline as well.
self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type !== 'klunki-warm-cache' || !Array.isArray(data.urls)) return;
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    await Promise.allSettled(data.urls.map(async (raw) => {
      let url;
      try { url = new URL(raw); } catch (_) { return; }
      url.hash = '';
      if (!isCacheable(url)) return;
      const key = url.href === scopeUrl.href ? toUrl('index.html') : url.href;
      if (await cache.match(key)) return;
      await cacheUrl(cache, url.href === scopeUrl.href ? key : url.href);
    }));
  })());
});
