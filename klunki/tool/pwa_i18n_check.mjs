#!/usr/bin/env node
// PWA i18n smoke check (I18N-06). Wrapper: tool/pwa_i18n_check.sh.
//
// Drives a headless Firefox over WebDriver BiDi (built into Firefox: no
// driver, no npm module; Node >= 22 for the global WebSocket). For every
// locale it seeds the saved language (localStorage `flutter.locale`, plus the
// `?lang=` debug parameter), loads the app, waits for Flutter's first frame
// and takes screenshots of the menu, the language picker and the first game.
//
// All traffic to hosts other than the app server goes through a tiny local
// proxy started by this script, so every external request is seen, including
// the ones the service worker makes (BiDi does not report those).
//
// Usage: node tool/pwa_i18n_check.mjs --url http://localhost:8080/ [--out DIR]
//          [--locales de,en,fr,es,zh-Hans,ar,fa] [--screens menu,picker,game]
//          [--offline] [--warmup] [--browser PATH] [--width 390 --height 844]
//
//   --offline  the proxy refuses every external host ("no internet", the app
//              server stays reachable). Any external request attempt = FAIL.
//   --warmup   with --offline: first one online visit (default locale) so the
//              service worker can cache what it sees, then go offline. This is
//              the "installed PWA, later offline" scenario.
// Without --offline, external requests are allowed and listed (they are what
// an offline user would miss). Exit code: 0 PASS, 1 FAIL, 2 setup problem.

import { spawn } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, existsSync } from 'node:fs';
import { createServer } from 'node:http';
import { connect as netConnect } from 'node:net';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const args = Object.fromEntries((() => {
  const out = [];
  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) out.push([a.slice(2), true]);
    else { out.push([a.slice(2), next]); i++; }
  }
  return out;
})());

const url = new URL(args.url || 'http://localhost:8080/');
const outDir = args.out || join(process.cwd(), 'pwa-i18n-screens');
const locales = String(args.locales || 'de,en,fr,es,zh-Hans,ar,fa').split(',');
const screens = new Set(String(args.screens || 'menu,picker,game').split(','));
const offline = !!args.offline;
const warmup = !!args.warmup;
const width = Number(args.width || 390);
const height = Number(args.height || 844);
const bootTimeoutMs = Number(args['boot-timeout'] || 30000);
const settleMs = Number(args.settle || 2500);

// Browser housekeeping traffic (updates, codecs, remote settings), not the app.
const BROWSER_NOISE = /(^|\.)(mozilla\.(org|net|com)|mozaws\.net|openh264\.org|update\.googleapis\.com|dl\.google\.com|firefox\.com)(:\d+)?$/;
const isNoise = (u) => {
  try { return BROWSER_NOISE.test(new URL(u).host); } catch (_) { return false; }
};

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function findBrowser() {
  if (args.browser) return args.browser;
  if (process.env.KLUNKI_FIREFOX) return process.env.KLUNKI_FIREFOX;
  return [
    '/Applications/Firefox.app/Contents/MacOS/firefox',
    '/Applications/Firefox Nightly.app/Contents/MacOS/firefox',
    '/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox',
    '/usr/bin/firefox',
    '/usr/local/bin/firefox',
    '/snap/bin/firefox',
  ].find((p) => existsSync(p));
}

// Logging forward proxy. Online: tunnels CONNECT / forwards plain HTTP.
// Offline: refuses. Either way every external host:port is recorded.
function startProxy(state) {
  const server = createServer((req, res) => {
    state.log.push(req.url);
    if (state.offline) { res.writeHead(502); res.end('offline (pwa_i18n_check)'); return; }
    const target = new URL(req.url);
    const upstream = netConnect(Number(target.port || 80), target.hostname, () => {
      upstream.write(`${req.method} ${target.pathname}${target.search} HTTP/1.1\r\n`);
      for (let i = 0; i < req.rawHeaders.length; i += 2) {
        upstream.write(`${req.rawHeaders[i]}: ${req.rawHeaders[i + 1]}\r\n`);
      }
      upstream.write('\r\n');
      req.pipe(upstream);
      upstream.pipe(res.socket);
    });
    upstream.on('error', () => res.destroy());
  });
  server.on('connect', (req, socket, head) => {
    state.log.push(`https://${req.url}`);
    if (state.offline) { socket.end('HTTP/1.1 502 Offline\r\n\r\n'); return; }
    const [host, port] = req.url.split(':');
    const upstream = netConnect(Number(port || 443), host, () => {
      state.tunnels.add(socket);
      socket.on('close', () => state.tunnels.delete(socket));
      socket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
      upstream.write(head);
      upstream.pipe(socket);
      socket.pipe(upstream);
    });
    upstream.on('error', () => socket.destroy());
    socket.on('error', () => upstream.destroy());
  });
  return new Promise((resolve) => server.listen(0, '127.0.0.1', () => resolve(server)));
}

class Bidi {
  constructor(ws) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    this.handlers = [];
    ws.addEventListener('message', (ev) => {
      const msg = JSON.parse(typeof ev.data === 'string' ? ev.data : ev.data.toString());
      if (msg.id !== undefined && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.type === 'error') reject(new Error(`${msg.error}: ${msg.message}`));
        else resolve(msg.result);
      } else if (msg.method) {
        for (const h of this.handlers) h(msg.method, msg.params);
      }
    });
  }
  send(method, params = {}) {
    const id = ++this.id;
    this.ws.send(JSON.stringify({ id, method, params }));
    return new Promise((resolve, reject) => this.pending.set(id, { resolve, reject }));
  }
  on(handler) { this.handlers.push(handler); }
}

async function connectBidi(port) {
  const deadline = Date.now() + 30000;
  let lastErr;
  while (Date.now() < deadline) {
    try {
      const ws = new WebSocket(`ws://127.0.0.1:${port}/session`);
      await new Promise((resolve, reject) => {
        ws.addEventListener('open', resolve, { once: true });
        ws.addEventListener('error', reject, { once: true });
      });
      return new Bidi(ws);
    } catch (e) {
      lastErr = e;
      await sleep(300);
    }
  }
  throw new Error(`could not connect to the browser's BiDi port: ${lastErr?.message || lastErr}`);
}

async function main() {
  const browser = findBrowser();
  if (!browser) {
    console.error('No Firefox found. Install Firefox or pass --browser /path/to/firefox (uses WebDriver BiDi).');
    process.exit(2);
  }
  if (typeof WebSocket === 'undefined') {
    console.error('Node >= 22 is needed (global WebSocket).');
    process.exit(2);
  }
  mkdirSync(outDir, { recursive: true });

  const proxyState = { offline: offline && !warmup, log: [], tunnels: new Set() };
  const goOffline = () => {
    proxyState.offline = true;
    // Kept-alive HTTP/2 tunnels would otherwise keep "the internet" reachable.
    for (const s of proxyState.tunnels) s.destroy();
    proxyState.tunnels.clear();
  };
  const proxy = await startProxy(proxyState);
  const proxyPort = proxy.address().port;

  // Fresh profile: no HTTP cache, no service worker, no localStorage from
  // earlier runs. External traffic is forced through the logging proxy.
  const profile = mkdtempSync(join(tmpdir(), 'klunki-pwa-i18n-'));
  writeFileSync(join(profile, 'user.js'), [
    ['browser.shell.checkDefaultBrowser', false],
    ['datareporting.policy.dataSubmissionEnabled', false],
    ['toolkit.telemetry.reportingpolicy.firstRun', false],
    ['app.update.enabled', false],
    ['app.normandy.enabled', false],
    ['network.captive-portal-service.enabled', false],
    ['network.connectivity-service.enabled', false],
    ['browser.safebrowsing.malware.enabled', false],
    ['browser.safebrowsing.phishing.enabled', false],
    ['browser.safebrowsing.downloads.enabled', false],
    ['browser.safebrowsing.update.enabled', false],
    ['extensions.update.enabled', false],
    ['extensions.getAddons.cache.enabled', false],
    ['browser.newtabpage.enabled', false],
    ['browser.region.network.url', ''],
    ['services.settings.server', 'http://127.0.0.1:9/'],
    ['network.proxy.type', 1],
    ['network.proxy.http', '127.0.0.1'],
    ['network.proxy.http_port', proxyPort],
    ['network.proxy.ssl', '127.0.0.1'],
    ['network.proxy.ssl_port', proxyPort],
    ['network.proxy.no_proxies_on', `${url.hostname},localhost,127.0.0.1`],
    ['network.proxy.allow_hijacking_localhost', false],
    ['media.gmp-manager.url', ''],
    ['media.gmp-gmpopenh264.enabled', false],
    ['media.gmp-widevinecdm.enabled', false],
    ['media.gmp-provider.enabled', false],
    ['app.update.url', ''],
    ['browser.ping-centre.telemetry', false],
    ['network.dns.disablePrefetch', true],
    ['network.prefetch-next', false],
  ].map(([k, v]) => `user_pref(${JSON.stringify(k)}, ${JSON.stringify(v)});`).join('\n') + '\n');

  const port = 9300 + Math.floor(Math.random() * 500);
  const proc = spawn(browser, ['--headless', '--no-remote', '--profile', profile,
    `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, 'about:blank'],
  { stdio: ['ignore', 'ignore', 'ignore'] });

  const results = [];
  let bidi;
  try {
    bidi = await connectBidi(port);
    await bidi.send('session.new', { capabilities: {} });
    const tree = await bidi.send('browsingContext.getTree', {});
    const context = tree.contexts[0].context;
    await bidi.send('browsingContext.setViewport', { context, viewport: { width, height } });

    // Mark Flutter's first frame so we know the app booted.
    await bidi.send('script.addPreloadScript', {
      functionDeclaration: `() => {
        window.__klunkiFirstFrame = false;
        window.addEventListener('flutter-first-frame', () => { window.__klunkiFirstFrame = true; });
      }`,
    });

    // Page-level requests (also the ones the service worker answers). The proxy
    // log adds what the worker itself fetches; it only sees one CONNECT per
    // host and connection, so both are combined.
    // url -> 'pending' | 'ok' (answered, e.g. by the service worker cache) | 'failed'
    let pageRequests = new Map();
    bidi.on((method, params) => {
      const u = params?.request?.url;
      if (!u) return;
      if (method === 'network.beforeRequestSent' && !pageRequests.has(u)) pageRequests.set(u, 'pending');
      if (method === 'network.responseCompleted') pageRequests.set(u, params.response.status >= 400 ? 'failed' : 'ok');
      if (method === 'network.fetchError') pageRequests.set(u, 'failed');
    });
    await bidi.send('session.subscribe', {
      events: ['network.beforeRequestSent', 'network.responseCompleted', 'network.fetchError'],
    });

    const evaluate = async (expression) => {
      const r = await bidi.send('script.evaluate', { expression, target: { context }, awaitPromise: true });
      if (r.type === 'exception') throw new Error(r.exceptionDetails.text);
      return r.result.value;
    };
    const shot = async (name) => {
      const r = await bidi.send('browsingContext.captureScreenshot', { context });
      const file = join(outDir, `${name}.png`);
      writeFileSync(file, Buffer.from(r.data, 'base64'));
      return file;
    };
    const tap = async (x, y) => {
      await bidi.send('input.performActions', {
        context,
        actions: [{
          type: 'pointer', id: 'mouse', parameters: { pointerType: 'mouse' },
          actions: [
            { type: 'pointerMove', x: Math.round(x), y: Math.round(y) },
            { type: 'pointerDown', button: 0 },
            { type: 'pause', duration: 60 },
            { type: 'pointerUp', button: 0 },
          ],
        }],
      });
      await bidi.send('input.releaseActions', { context });
    };
    const load = async (href) => {
      await bidi.send('browsingContext.navigate', { context, url: href, wait: 'complete' });
      const deadline = Date.now() + bootTimeoutMs;
      while (Date.now() < deadline) {
        if (await evaluate('window.__klunkiFirstFrame === true').catch(() => false)) {
          await sleep(settleMs); // fallback fonts arrive (or fail) and text re-lays out
          return true;
        }
        await sleep(250);
      }
      return false;
    };

    // First visit: gives us the origin for localStorage, registers the SW.
    const firstBoot = await load(url.href);
    if (warmup) {
      await sleep(10000); // index.html posts klunki-warm-cache ~0.5 s after the first frame
      if (offline) goOffline();
    }

    for (const tag of locales) {
      const res = { locale: tag, booted: false, external: [], cached: [], shots: [] };
      proxyState.log = [];
      pageRequests = new Map();
      await evaluate(`localStorage.setItem('flutter.locale', ${JSON.stringify(JSON.stringify(tag))}); true`)
        .catch(() => {});
      const target = new URL(url.href);
      target.searchParams.set('lang', tag);
      res.booted = await load(target.href);
      if (screens.has('menu')) res.shots.push(await shot(`${tag}-menu`));
      if (res.booted && screens.has('picker')) {
        // The language picker is the globe icon at the end of the app bar
        // (top right in LTR, top left in RTL).
        const rtl = /^(ar|fa|he|ur)\b/.test(tag);
        await tap(rtl ? 20 : width - 20, Number(args['picker-y'] || 28));
        await sleep(settleMs);
        res.shots.push(await shot(`${tag}-picker`));
      }
      if (res.booted && screens.has('game')) {
        await load(target.href);
        // First game tile (Four in a Row).
        await tap(width / 2, Number(args['game-y'] || 343));
        await sleep(settleMs);
        res.shots.push(await shot(`${tag}-game`));
      }
      const isExternal = (u) => {
        try {
          const p = new URL(u);
          return (p.protocol === 'http:' || p.protocol === 'https:') && p.host !== url.host && !isNoise(u);
        } catch (_) { return false; }
      };
      const ext = [...pageRequests].filter(([u]) => isExternal(u));
      // Reached the network (proxy) or failed: an offline user misses these.
      res.external = [...new Set([
        ...ext.filter(([, st]) => st !== 'ok' || !offline).map(([u]) => u),
        ...proxyState.log.filter((u) => !isNoise(u)),
      ])];
      // Answered without network (service worker cache) while offline.
      res.cached = offline ? ext.filter(([, st]) => st === 'ok').map(([u]) => u) : [];
      results.push(res);
    }
    if (!firstBoot && results.length === 0) results.push({ locale: '(first load)', booted: false, external: [], shots: [] });
  } finally {
    try { await bidi?.send('session.end', {}); } catch (_) { /* ignore */ }
    proc.kill();
    proxy.close();
    await sleep(500);
    rmSync(profile, { recursive: true, force: true });
  }

  let failed = false;
  const mode = offline ? (warmup ? 'offline after online warm-up' : 'offline (no internet)') : 'online';
  console.log(`pwa_i18n_check: ${url.href}, ${mode}, ${width}x${height}, screenshots in ${outDir}`);
  for (const r of results) {
    const problems = [];
    if (!r.booted) problems.push('app did not boot (no flutter-first-frame)');
    if (offline && r.external.length) problems.push(`${r.external.length} request(s) to external hosts while offline`);
    if (problems.length) failed = true;
    console.log(`${problems.length ? 'FAIL' : 'PASS'} ${r.locale}${problems.length ? ': ' + problems.join('; ') : ''}`);
    for (const u of r.external) console.log(`     external: ${u}`);
    for (const u of r.cached || []) console.log(`     from SW cache: ${u}`);
    for (const s of r.shots) console.log(`     screenshot: ${s}`);
  }
  writeFileSync(join(outDir, 'report.json'), JSON.stringify({ url: url.href, mode, results }, null, 2));
  console.log(failed ? 'RESULT: FAIL' : 'RESULT: PASS');
  process.exit(failed ? 1 : 0);
}

main().catch((e) => {
  console.error(`ERROR: ${e.stack || e}`);
  process.exit(2);
});
