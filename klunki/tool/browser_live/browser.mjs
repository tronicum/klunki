// Generic headless-browser driver for the Klunki PWA (KLD-089).
//
// Drives a real Firefox over WebDriver BiDi (built into Firefox: no driver,
// no npm module; Node >= 22 for the global WebSocket), like
// tool/pwa_relay_e2e.mjs. Flutter draws on a canvas, so the page's
// accessibility tree (the hidden "Enable accessibility" placeholder) is
// switched on and widgets are found by their semantics labels in the DOM;
// taps are real pointer events at a node's centre. No app test hooks.
import { spawn } from 'node:child_process';
import { existsSync, mkdtempSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Firefox: [explicit] path, $KLUNKI_FIREFOX, or a usual install location. */
export function findFirefox(explicit) {
  if (explicit) return explicit;
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
    ws.addEventListener('message', (ev) => {
      const msg = JSON.parse(typeof ev.data === 'string' ? ev.data : ev.data.toString());
      if (msg.id !== undefined && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.type === 'error') reject(new Error(`${msg.error}: ${msg.message}`));
        else resolve(msg.result);
      }
    });
  }
  send(method, params = {}) {
    const id = ++this.id;
    this.ws.send(JSON.stringify({ id, method, params }));
    return new Promise((resolve, reject) => this.pending.set(id, { resolve, reject }));
  }
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

// In-page helper: every visible semantics node with its label, role, state
// and box (page coordinates).
const NODES_JS = `(() => {
  const out = [];
  for (const el of document.querySelectorAll('flt-semantics, input, textarea')) {
    const r = el.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) continue;
    let label = el.getAttribute('aria-label') || '';
    if (!label) {
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
      disabled: el.getAttribute('aria-disabled') === 'true',
      x: r.left + r.width / 2,
      y: r.top + r.height / 2,
      left: r.left, top: r.top, w: r.width, h: r.height,
    });
  }
  return JSON.stringify(out);
})()`;

export class Browser {
  /**
   * @param {string} name   short name for logs and screenshots
   * @param {object} o      {binary, profileRoot, outDir, width, height, timeout, verbose}
   */
  constructor(name, o) {
    this.name = name;
    this.o = o;
    this.profile = mkdtempSync(join(o.profileRoot, `${name}-`));
    this.shots = [];
  }

  async start() {
    const { width, height } = this.o;
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
      // Background tabs/windows must not be throttled: two headless browsers
      // run side by side and both keep their timers.
      ['dom.min_background_timeout_value', 0],
    ].map(([k, v]) => `user_pref(${JSON.stringify(k)}, ${JSON.stringify(v)});`).join('\n') + '\n');
    this.port = 9300 + Math.floor(Math.random() * 600);
    this.proc = spawn(this.o.binary, ['--headless', '--no-remote', '--profile', this.profile,
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
    const file = join(this.o.outDir, `${this.name}-${name}.png`);
    writeFileSync(file, Buffer.from(r.data, 'base64'));
    this.shots.push(file);
    return file;
  }

  /** Loads [href], waits for the first Flutter frame, turns on semantics. */
  async load(href) {
    await this.bidi.send('browsingContext.navigate', { context: this.context, url: href, wait: 'complete' });
    await this.until('the first Flutter frame', async () => this.evaluate('window.__klunkiFirstFrame === true'));
    await sleep(1500); // fonts, first layout
    await this.until('the accessibility tree', async () => this.evaluate(`(() => {
      if (document.querySelector('flt-semantics')) return true;
      const p = document.querySelector('flt-semantics-placeholder');
      if (p) p.click();
      return false;
    })()`));
  }

  /** German UI and a saved player name, then a fresh load. */
  async prepare(href, playerName) {
    await this.load(href);
    await this.evaluate(`localStorage.setItem('flutter.locale', '"de"');
      localStorage.setItem('flutter.playerName', ${JSON.stringify(JSON.stringify(playerName))}); true`);
    await this.load(href);
  }

  async nodes() { return JSON.parse(await this.evaluate(NODES_JS)); }

  async until(what, fn, timeout = this.o.timeout) {
    const deadline = Date.now() + timeout;
    let last;
    while (Date.now() < deadline) {
      try {
        last = await fn();
        if (last) return last;
      } catch (e) {
        last = e;
      }
      await sleep(150);
    }
    if (this.o.verbose) console.log(`[${this.name}] nodes:`, JSON.stringify(await this.nodes().catch(() => []), null, 1));
    await this.shot(`timeout-${what.replace(/\W+/g, '-')}`).catch(() => {});
    throw new Error(`${this.name}: timed out waiting for ${what}`);
  }

  /** The first semantics node whose label matches [re] (and [filter]). */
  async find(re, what = String(re), filter = () => true, timeout) {
    return this.until(what, async () => (await this.nodes()).find((n) => re.test(n.label) && filter(n)), timeout);
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

  /** Taps the node matching [re]; waits [settle] ms afterwards. */
  async tap(re, what, filter, settle = 400) {
    const n = await this.find(re, what, filter);
    if (this.o.verbose) console.log(`[${this.name}] tap "${n.label}" at ${Math.round(n.x)},${Math.round(n.y)}`);
    await this.tapAt(n.x, n.y);
    await sleep(settle);
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

  async close() {
    try { await this.bidi?.send('session.end', {}); } catch (_) { /* ignore */ }
    this.proc?.kill();
  }
}

/** Menu → Über WLAN spielen → Spiel hosten → [gameLabel] (→ deck) → hosts; returns the room code. */
export async function hostRoom(a, gameLabel, deckLabel) {
  await a.tap(/^Über WLAN spielen/, 'menu: Über WLAN spielen');
  await a.tap(/^Spiel hosten$/, 'Spiel hosten button');
  await a.find(/^Spiel wählen$/m, 'host setup');
  await a.tap(new RegExp(`^${gameLabel.replace(/[()]/g, '\\$&')}`), `game ${gameLabel}`);
  if (deckLabel) await a.tap(new RegExp(`^${deckLabel}`), `deck ${deckLabel}`);
  await a.tap(/^Spiel hosten$/, 'start hosting', (n) => n.y > 300);
  const codeRe = /^[2-9A-HJKMNP-Z]{3} [2-9A-HJKMNP-Z]{2}$/m;
  return (await a.find(codeRe, 'the room code')).label.match(codeRe)[0];
}

/** Menu → Über WLAN spielen → types [code] → Raum beitreten. */
export async function joinRoom(b, code) {
  await b.tap(/^Über WLAN spielen/, 'menu: Über WLAN spielen');
  await b.find(/^Mit Raumcode beitreten$/m, 'room join section');
  const field = await b.find(/^Raumcode/, 'room code field');
  await b.tapAt(field.x, field.y);
  await sleep(500);
  await b.type(code.toLowerCase().replace(' ', ''));
  await b.tap(/^Raum beitreten$/, 'Raum beitreten button');
}
