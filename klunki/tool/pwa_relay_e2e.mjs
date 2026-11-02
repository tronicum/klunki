#!/usr/bin/env node
// Browser vs browser through the relay (KLD-057b), end to end in two real
// browsers. Wrapper: tool/pwa_relay_e2e.sh (builds nothing, starts nothing:
// it needs a running `klunki relay --web build/web`).
//
// Drives two headless Firefox instances over WebDriver BiDi (built into
// Firefox: no driver, no npm module; Node >= 22 for the global WebSocket),
// like tool/pwa_i18n_check.mjs. Flutter draws on a canvas, so the script
// turns on Flutter's accessibility tree (the hidden "Enable accessibility"
// placeholder), finds widgets by their semantics labels in the DOM and taps
// their centre with real pointer events. No app test hooks are needed.
//
//   A: Menu → "Mit anderen" on the 4 Gewinnt tile (KLD-105) → Raum starten
//      → reads the room code
//   B: Menu → "Raum beitreten" (KLD-098) → types the code → Raum beitreten
//      (--join link: B opens A's `?room=` link instead and joins by itself)
//   A (Ada, first player) and B (Bea) play Four in a Row (A: column 1 four
//   times, B: column 2) → Ada wins; both must show the result (names, no
//   X / O since KLD-106). Screenshots of every step go to OUT_DIR.
//   --no-relay URL: first checks that a page NOT served by a relay (e.g.
//   `python3 -m http.server`) explains how to start one: Menu → "Raum
//   starten" → choose 4 Gewinnt → Raum starten.
//
// Flutter web exposes no widget keys in the DOM (the app sets no semantics
// identifiers), so the script goes by the German labels; the patterns are
// anchored to whole labels to stay unambiguous.
//
// Usage: node tool/pwa_relay_e2e.mjs --url http://127.0.0.1:8765/ [--out DIR]
//          [--join code|link] [--no-relay http://127.0.0.1:8766/]
//          [--browser PATH] [--width 390 --height 844] [--timeout 30000] [--verbose]
// Exit code: 0 PASS, 1 FAIL, 2 setup problem.

import { spawn } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, existsSync } from 'node:fs';
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

const url = new URL(args.url || 'http://127.0.0.1:8765/');
const outDir = args.out || join(process.cwd(), 'pwa-relay-e2e');
const width = Number(args.width || 390);
const height = Number(args.height || 844);
const stepTimeout = Number(args.timeout || 30000);
const verbose = !!args.verbose;
const joinMode = String(args.join || 'code');
const noRelayUrl = args['no-relay'] ? new URL(args['no-relay']) : null;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (...a) => console.log(...a);

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

// In-page helper: all semantics nodes with a label, their text and centre.
const NODES_JS = `(() => {
  const out = [];
  for (const el of document.querySelectorAll('flt-semantics, input, textarea')) {
    const r = el.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) continue;
    let label = el.getAttribute('aria-label') || '';
    if (!label) {
      // Text nodes directly inside this element (not in child semantics nodes).
      label = [...el.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent).join('').trim();
    }
    if (!label && el.tagName !== 'INPUT' && el.tagName !== 'TEXTAREA') {
      const span = el.querySelector(':scope > span');
      if (span) label = span.textContent.trim();
    }
    out.push({
      tag: el.tagName.toLowerCase(),
      role: el.getAttribute('role') || '',
      label,
      value: el.value ?? '',
      disabled: el.getAttribute('aria-disabled') === 'true',
      x: r.left + r.width / 2,
      y: r.top + r.height / 2,
      w: r.width,
      h: r.height,
    });
  }
  return JSON.stringify(out);
})()`;

class Browser {
  constructor(name, binary, profileRoot) {
    this.name = name;
    this.binary = binary;
    this.profile = mkdtempSync(join(profileRoot, `${name}-`));
    this.shots = [];
  }

  async start() {
    writeFileSync(join(this.profile, 'user.js'), [
      ['browser.shell.checkDefaultBrowser', false],
      ['datareporting.policy.dataSubmissionEnabled', false],
      ['toolkit.telemetry.reportingpolicy.firstRun', false],
      ['app.update.enabled', false],
      ['app.normandy.enabled', false],
      ['network.captive-portal-service.enabled', false],
      ['network.connectivity-service.enabled', false],
      ['browser.safebrowsing.malware.enabled', false],
      ['browser.safebrowsing.phishing.enabled', false],
      ['browser.safebrowsing.update.enabled', false],
      ['extensions.update.enabled', false],
      ['services.settings.server', 'http://127.0.0.1:9/'],
      ['network.proxy.allow_hijacking_localhost', false],
    ].map(([k, v]) => `user_pref(${JSON.stringify(k)}, ${JSON.stringify(v)});`).join('\n') + '\n');
    this.port = 9300 + Math.floor(Math.random() * 600);
    this.proc = spawn(this.binary, ['--headless', '--no-remote', '--profile', this.profile,
      `--remote-debugging-port=${this.port}`, `--window-size=${width},${height}`, 'about:blank'],
    { stdio: ['ignore', 'ignore', 'ignore'] });
    this.bidi = await connectBidi(this.port);
    await this.bidi.send('session.new', { capabilities: {} });
    const tree = await this.bidi.send('browsingContext.getTree', {});
    this.context = tree.contexts[0].context;
    await this.bidi.send('browsingContext.setViewport', { context: this.context, viewport: { width, height } });
    await this.bidi.send('script.addPreloadScript', {
      functionDeclaration: `() => {
        window.__klunkiFirstFrame = false;
        window.addEventListener('flutter-first-frame', () => { window.__klunkiFirstFrame = true; });
      }`,
    });
  }

  async evaluate(expression) {
    const r = await this.bidi.send('script.evaluate', { expression, target: { context: this.context }, awaitPromise: true });
    if (r.type === 'exception') throw new Error(r.exceptionDetails.text);
    return r.result.value;
  }

  async shot(name) {
    const r = await this.bidi.send('browsingContext.captureScreenshot', { context: this.context });
    const file = join(outDir, `${this.name}-${name}.png`);
    writeFileSync(file, Buffer.from(r.data, 'base64'));
    this.shots.push(file);
    return file;
  }

  async load(href) {
    await this.bidi.send('browsingContext.navigate', { context: this.context, url: href, wait: 'complete' });
    await this.until('the first Flutter frame', async () => this.evaluate('window.__klunkiFirstFrame === true'));
    await sleep(1500); // fonts, first layout
    // Flutter web keeps its accessibility tree off until the hidden
    // placeholder is activated (what a screen reader does).
    await this.until('the accessibility tree', async () => this.evaluate(`(() => {
      if (document.querySelector('flt-semantics')) return true;
      const p = document.querySelector('flt-semantics-placeholder');
      if (p) p.click();
      return false;
    })()`));
  }

  async nodes() { return JSON.parse(await this.evaluate(NODES_JS)); }

  async until(what, fn, timeout = stepTimeout) {
    const deadline = Date.now() + timeout;
    let last;
    while (Date.now() < deadline) {
      try {
        last = await fn();
        if (last) return last;
      } catch (e) {
        last = e;
      }
      await sleep(200);
    }
    if (verbose) log(`[${this.name}] nodes:`, JSON.stringify(await this.nodes().catch(() => []), null, 1));
    await this.shot(`timeout-${what.replace(/\W+/g, '-')}`).catch(() => {});
    throw new Error(`${this.name}: timed out waiting for ${what}`);
  }

  /** The first semantics node whose label matches [re] (and [filter]). */
  async find(re, what = String(re), filter = () => true) {
    return this.until(what, async () => (await this.nodes()).find((n) => re.test(n.label) && filter(n)));
  }

  async tapAt(x, y) {
    await this.bidi.send('input.performActions', {
      context: this.context,
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
    await this.bidi.send('input.releaseActions', { context: this.context });
  }

  /** Scrolls (mouse wheel over the page) until [n] is inside the viewport. */
  async scrollIntoView(re, what, filter, n) {
    for (let i = 0; i < 10 && (n.y < 60 || n.y > height - 40); i++) {
      const deltaY = Math.round(n.y - height / 2);
      await this.bidi.send('input.performActions', {
        context: this.context,
        actions: [{
          type: 'wheel', id: 'wheel',
          actions: [{ type: 'scroll', x: Math.round(width / 2), y: Math.round(height / 2), deltaX: 0, deltaY }],
        }],
      });
      await sleep(500);
      n = await this.find(re, what, filter);
    }
    return n;
  }

  async tap(re, what, filter) {
    const n = await this.scrollIntoView(re, what, filter, await this.find(re, what, filter));
    if (verbose) log(`[${this.name}] tap "${n.label}" at ${Math.round(n.x)},${Math.round(n.y)}`);
    await this.tapAt(n.x, n.y);
    await sleep(600);
    return n;
  }

  async type(text) {
    const actions = [];
    for (const ch of text) actions.push({ type: 'keyDown', value: ch }, { type: 'keyUp', value: ch });
    await this.bidi.send('input.performActions', {
      context: this.context, actions: [{ type: 'key', id: 'keyboard', actions }],
    });
    await this.bidi.send('input.releaseActions', { context: this.context });
    await sleep(300);
  }

  async hasText(re) { return (await this.nodes()).some((n) => re.test(n.label)); }

  async close() {
    try { await this.bidi?.send('session.end', {}); } catch (_) { /* ignore */ }
    this.proc?.kill();
  }
}

async function main() {
  const binary = findBrowser();
  if (!binary) {
    console.error('No Firefox found. Install Firefox or pass --browser /path/to/firefox (uses WebDriver BiDi).');
    process.exit(2);
  }
  if (typeof WebSocket === 'undefined') {
    console.error('Node >= 22 is needed (global WebSocket).');
    process.exit(2);
  }
  mkdirSync(outDir, { recursive: true });
  const profileRoot = mkdtempSync(join(tmpdir(), 'klunki-pwa-relay-'));
  const a = new Browser('a-host', binary, profileRoot);
  const b = new Browser('b-guest', binary, profileRoot);
  const result = { url: url.href, ok: false, steps: [] };
  const step = (s) => { result.steps.push(s); log(`- ${s}`); };
  try {
    await Promise.all([a.start(), b.start()]);

    // German UI, names saved (no first-run name dialog).
    for (const [br, name] of [[a, 'Ada'], [b, 'Bea']]) {
      await br.load(url.href);
      await br.evaluate(`localStorage.setItem('flutter.locale', '"de"');
        localStorage.setItem('flutter.playerName', ${JSON.stringify(JSON.stringify(name))}); true`);
      await br.load(url.href);
    }
    step('both browsers loaded the PWA from the relay');

    if (noRelayUrl) {
      // A page from a plain web server: hosting explains how to start a relay.
      await a.load(noRelayUrl.href);
      await a.evaluate(`localStorage.setItem('flutter.locale', '"de"');
        localStorage.setItem('flutter.playerName', '"Ada"'); true`);
      await a.load(noRelayUrl.href);
      await a.tap(/^Raum starten\n/, 'menu: Raum starten');
      await a.find(/^Spiel wählen$/m, 'room setup');
      await a.tap(/^4 Gewinnt$/m, 'choose 4 Gewinnt', (n) => n.y > 100);
      await a.tap(/^Raum starten$/, 'Raum starten button', (n) => n.y > 100);
      await a.find(/Kein Relay erreichbar/, 'the "no relay" message');
      await a.find(/brauchen ein Relay/, 'the hint how to start a relay');
      await sleep(500);
      await a.shot('0-no-relay');
      step(`${noRelayUrl.host} (no relay): "Kein Relay erreichbar" + how to start one`);
      await a.load(url.href);
    }

    // A: "Mit anderen" on the 4 Gewinnt tile → Raum starten (game fixed).
    const tile = await a.find(/^4 Gewinnt\n/, 'menu tile 4 Gewinnt');
    await a.tap(/^Mit anderen$/, '"Mit anderen" on the 4 Gewinnt tile', (n) => n.y > tile.y);
    await a.find(/^Raum starten$/, 'room setup', (n) => n.y > 100);
    await a.shot('1-host-setup');
    await a.tap(/^Raum starten$/, 'Raum starten button', (n) => n.y > 100);
    // Semantics merges the waiting screen's texts into one label: one line of
    // it is the grouped code ("K7Q 2M").
    const codeRe = /^[2-9A-HJKMNP-Z]{3} [2-9A-HJKMNP-Z]{2}$/m;
    const code = (await a.find(codeRe, 'the room code')).label.match(codeRe)[0];
    await sleep(500);
    await a.shot('2-host-waiting');
    step(`A hosts Four in a Row, room code "${code}"`);
    const link = (await a.nodes()).find((n) => /\?room=/.test(n.label))?.label;
    if (link) step(`A shows the join link ${link}`);

    if (joinMode === 'link') {
      // B: opens the link (what scanning the QR code does) and joins by itself.
      if (!link) throw new Error('no ?room= link on the host screen');
      await b.load(link);
      step(`B opens ${link}`);
    } else {
      // B: Raum beitreten → type the code (lower case, no space) → Raum beitreten.
      await b.tap(/^Raum beitreten\n/, 'menu: Raum beitreten');
      await b.find(/^Raumcode eintippen$/m, 'room join section');
      const field = await b.find(/^Raumcode/, 'room code field', (n) => n.tag === 'input' || n.role === 'textbox');
      await b.tapAt(field.x, field.y);
      await sleep(500);
      await b.type(code.toLowerCase().replace(' ', ''));
      await b.shot('3-guest-code');
      await b.tap(/^Raum beitreten$/, 'Raum beitreten button');
      step(`B joins room ${code} by typing it`);
    }

    // Both on the game: the connection bar names the opponent.
    await a.find(/Gegner: Bea/, 'A in the game with Bea');
    await b.find(/Gegner: Ada/, 'B in the game with Ada');
    await sleep(800);
    await a.shot('4-host-game');
    await b.shot('4-guest-game');
    step('both browsers are in the game (connection bar: Du: Ada · Gegner: Bea)');

    // A (first player): column 1 four times; B: column 2 three times.
    for (let i = 0; i < 7; i++) {
      const [mover, other] = i % 2 === 0 ? [a, b] : [b, a];
      const col = i % 2 === 0 ? 1 : 2;
      await mover.find(/Du bist am Zug/, `${mover.name}'s turn (move ${i + 1})`);
      await mover.tap(new RegExp(`^Spalte ${col}$`), `column ${col}`);
      // The move shows up on the other side as its turn (or the end).
      if (i < 6) await other.find(/Du bist am Zug/, `${other.name} sees move ${i + 1}`);
    }
    step('7 moves played across the relay');

    await a.find(/Du gewinnst/, 'A wins');
    await b.find(/Ada gewinnt/, 'B sees Ada win');
    await sleep(800);
    await a.shot('5-host-result');
    await b.shot('5-guest-result');
    step('result: A "Du gewinnst!", B "Ada gewinnt!"');
    result.ok = true;
  } catch (e) {
    result.error = String(e.message || e);
    log(`ERROR: ${result.error}`);
    await a.shot('error').catch(() => {});
    await b.shot('error').catch(() => {});
  } finally {
    await a.close();
    await b.close();
    await sleep(500);
    rmSync(profileRoot, { recursive: true, force: true });
  }
  result.shots = [...a.shots, ...b.shots];
  writeFileSync(join(outDir, 'report.json'), JSON.stringify(result, null, 2));
  for (const s of result.shots) log(`  screenshot: ${s}`);
  log(result.ok ? 'RESULT: PASS' : 'RESULT: FAIL');
  process.exit(result.ok ? 0 : 1);
}

main().catch((e) => {
  console.error(`ERROR: ${e.stack || e}`);
  process.exit(2);
});
