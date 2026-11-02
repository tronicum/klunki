// Published as <site>/klunki_sw.js (KLD-115). Until KLD-115 the PWA lived at
// the site root and registered its offline worker there; that worker would
// keep answering the landing page with the old app. Browsers check a worker
// script for updates on navigation, find this one, and it removes itself and
// reloads the open pages (the landing page, or the app at play/ with its own
// worker). The new app's worker deletes the old caches when it activates.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await self.registration.unregister();
    const pages = await self.clients.matchAll({ type: 'window' });
    pages.forEach((page) => page.navigate(page.url));
  })());
});
