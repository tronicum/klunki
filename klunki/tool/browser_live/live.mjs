#!/usr/bin/env node
// Plays complete games of the Klunki PWA in real headless Firefox (KLD-089):
// hot-seat in one browser, and network (host + guest by room code through a
// relay) in two. Every turn result each browser shows is logged; at the end
// the logs are checked: the game's turn rule holds from trick to trick, the
// result shown after each tap is the tapped pick with the tapped card, the
// hot-seat handover cover names the next player, and in a network game both
// browsers showed the same tricks in the same order.
//
// Players are named on screen (KLD-103/106, no X / O): hot-seat reads the
// two names from the "Wer spielt?" dialog, network uses the names it sets
// (Ada hosts, Bea joins). Internally the first player is 'X', the second 'O'.
//
// Generic part (this file) + one adapter per game (./<game>.mjs, see
// quartett_trumpf.mjs). Adapters for the other games: KLD-090.
//
// Usage: node tool/browser_live/live.mjs --url http://127.0.0.1:8797/
//          [--mode hotseat|network|both] [--deck Autos] [--seed 1]
//          [--out DIR] [--browser PATH] [--width 412 --height 1400]
//          [--max-steps 3000] [--verbose]
// Needs a running `klunki relay --web build/web` at --url (run.sh starts one).
// Exit code: 0 PASS, 1 FAIL, 2 setup problem.

import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { Browser, findFirefox, hostRoom, joinRoom, sleep } from './browser.mjs';
import * as adapter from './quartett_trumpf.mjs';

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

const url = new URL(args.url || 'http://127.0.0.1:8797/');
const mode = String(args.mode || 'both');
const deck = args.deck ? String(args.deck) : 'Autos';
const outDir = args.out || join(process.cwd(), 'browser-live');
const width = Number(args.width || 412);
const height = Number(args.height || 1400);
const maxSteps = Number(args['max-steps'] || 3000);
const verbose = !!args.verbose;

// Seeded RNG (mulberry32) so a run's choices can be repeated.
function rngOf(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rng = rngOf(Number(args.seed || 1));

const started = Date.now();
const lines = [];
const log = (s) => {
  const line = `${((Date.now() - started) / 1000).toFixed(1).padStart(7)} ${s}`;
  lines.push(line);
  console.log(line);
};

/** One browser's view of the game: the tricks it showed, in order. */
class Seen {
  constructor(name, names) {
    this.name = name; this.names = names; this.recs = []; this.keys = []; this.lastKey = null; this.problems = [];
  }
  add(o) {
    if (o.key === this.lastKey) return false;
    this.lastKey = o.key;
    this.recs.push(o.rec);
    this.keys.push(o.key);
    log(`${this.name.padEnd(9)} sees  #${String(this.recs.length - 1).padStart(3)} ${adapter.show(o.rec, this.names)}`
      + `   [${o.status}${o.grace ? `, ${o.grace}` : ''}${o.queued ? `, queued: ${o.queued}` : ''}]`);
    return true;
  }
  clear() { this.lastKey = null; }
  problem(s) { this.problems.push(s); log(`${this.name.padEnd(9)} PROBLEM ${s}`); }
}

/** The rule over a trick list: each picker is the previous winner (or the same after a tie). */
function checkRule(seen) {
  const n = seen.names;
  for (let i = 1; i < seen.recs.length; i++) {
    const want = adapter.nextPicker(seen.recs[i - 1]);
    if (seen.recs[i].picker !== want) {
      seen.problem(`trick ${i}: picked by ${n[seen.recs[i].picker]}, but ${n[want]} should pick after ${adapter.show(seen.recs[i - 1], n)}`);
    }
    if (seen.recs[i].winner === undefined) seen.problem(`trick ${i}: no headline`);
  }
}

async function snapshot(b, names) {
  return adapter.observe(await b.nodes(), width, names);
}

async function playHotSeat(o) {
  const b = new Browser('hotseat', o);
  let seen = new Seen('hot-seat', { X: 'X', O: 'O' });
  try {
    await b.start();
    await b.prepare(url.href, 'Ada');
    await b.tap(new RegExp(`^${adapter.game.label.replace(/[()]/g, '\\$&')}\\n`), 'menu tile');
    await b.tap(new RegExp(`^${deck}\\n`), `deck ${deck}`);
    await b.tap(/^Spielen$/, 'Spielen');
    // KLD-103: "Wer spielt?" with both names prefilled; player 1 starts.
    await b.find(/^Wer spielt\?$/, 'the "Wer spielt?" dialog');
    const fields = (await b.nodes()).filter((n) => n.tag === 'input').sort((x, y) => x.y - y.y);
    const names = { X: fields[0]?.value || 'Anna', O: fields[1]?.value || 'Ben' };
    seen = new Seen('hot-seat', names);
    log(`hot-seat  players ${names.X} (starts) and ${names.O}`);
    const dialog = await b.find(/^Wer spielt\?$/, 'the "Wer spielt?" dialog');
    await b.tap(/^Spielen$/, 'Spielen in "Wer spielt?"', (n) => n.y > dialog.y);
    await b.shot('start');
    const other = (p) => (p === 'X' ? 'O' : 'X');
    let expected = 'X';
    let holder = 'X'; // who holds the device
    let lastTap = null; // {player, stat, card}
    let defendDue = null; // KLD-100: {picker, stat} after a pick that the defender must answer
    let covers = 0, chooses = 0;
    for (let step = 0; step < maxSteps; step++) {
      const s = await snapshot(b, names);
      if (s.kind === 'reveal') {
        if (seen.add(s)) {
          const r = s.rec;
          if (r.picker !== expected) seen.problem(`reveal picker ${names[r.picker]}, expected ${names[expected]}`);
          if (!lastTap || lastTap.stat !== r.stat || lastTap.player !== r.picker || lastTap.card !== r.cards[r.picker]) {
            seen.problem(`reveal ${adapter.show(r, names)} does not match the tap ${JSON.stringify(lastTap)}`);
          }
          expected = adapter.nextPicker(r);
          defendDue = null;
        }
        for (const p of adapter.revealProblems(s, null, names)) seen.problem(p);
        if (s.result) break;
        await b.tapAt(s.cont.x, s.cont.y);
        seen.clear();
        await sleep(250);
      } else if (s.result) {
        break;
      } else if (s.kind === 'cover') {
        const r = s.reason;
        if (r?.kind === 'defend') {
          // KLD-100: the defender (2–3 cards) chooses its card in private.
          if (s.name !== other(expected) || r.picker !== expected) seen.problem(`cover "Ich bin ${names[s.name]}" for ${names[r.picker]}'s pick, ${names[expected]} picks`);
          if (lastTap && r.stat !== lastTap.stat) seen.problem(`cover says ${r.stat}, ${lastTap.stat} was tapped`);
          defendDue = { picker: r.picker, stat: r.stat };
        } else {
          if (s.name !== expected) seen.problem(`handover cover names ${names[s.name]}, ${names[expected]} picks next`);
          if (!r || r.player !== expected) seen.problem(`cover reason ${JSON.stringify(r)}, ${names[expected]} picks next`);
          if (holder === expected) seen.problem(`a cover although ${names[expected]} holds the device`);
        }
        if (s.name === holder) seen.problem(`a cover for ${names[s.name]}, who holds the device`);
        holder = s.name;
        covers++;
        log(`hot-seat  cover "Ich bin ${names[s.name]} – weiter" (${JSON.stringify(r)})`);
        await b.tapAt(s.node.x, s.node.y);
        await sleep(300);
      } else if (s.kind === 'choose') {
        const who = s.defending ? other(expected) : expected;
        if (holder !== who) seen.problem(`${names[who]}'s cards are shown while ${names[holder]} holds the device`);
        if (s.defending && !defendDue) seen.problem(`defender choice "${s.hint}" without the cover`);
        const c = adapter.chooseCard(s, rng);
        chooses++;
        log(`hot-seat  ${names[who]} chooses ${c.label.split('\n').find((l) => /^[A-H][1-4]$/.test(l.trim())) ?? '?'}${s.defending ? ' (defending)' : ''}`);
        await b.tapAt(c.x, c.y);
        await sleep(300);
      } else if (s.kind === 'table') {
        const enabled = s.stats.some((x) => x.enabled);
        if (!enabled) { await sleep(150); continue; } // e.g. waiting for the defender's choice
        if (s.viewer !== expected) seen.problem(`table shows ${names[s.viewer]}'s card, ${names[expected]} picks`);
        if (holder !== expected) seen.problem(`no cover before ${names[expected]}'s card (the device changed hands)`);
        if (!s.status.startsWith(`${names[expected]} ist am Zug`)) seen.problem(`status "${s.status}", ${names[expected]} picks`);
        const c = adapter.choose(s, rng);
        if (!c) { await sleep(150); continue; }
        lastTap = { player: s.viewer, stat: c.stat, card: s.card };
        log(`hot-seat  ${names[s.viewer]} taps ${c.stat} on ${s.card}`);
        await b.tapAt(c.node.x, c.node.y);
        await sleep(250);
      } else {
        await sleep(150);
      }
    }
    await sleep(800);
    await b.shot('end');
    if (chooses) log(`hot-seat  ${chooses} card choice(s) with 3 or fewer cards (KLD-100)`);
    const end = await snapshot(b, names);
    if (!end.result) seen.problem('no result dialog at the end');
    checkRule(seen);
    log(`hot-seat  game over after ${seen.recs.length} tricks, ${covers} cover(s), ${seen.problems.length} problem(s)`);
  } finally {
    await b.close();
  }
  return { seen: [seen], shots: b.shots };
}

async function playNetwork(o) {
  const a = new Browser('host', o);
  const g = new Browser('guest', o);
  // Ada hosts and starts (the first player), Bea joins.
  const names = { X: 'Ada', O: 'Bea' };
  const seenA = new Seen('host Ada', names), seenG = new Seen('guest Bea', names);
  const taps = [];
  try {
    await Promise.all([a.start(), g.start()]);
    await a.prepare(url.href, 'Ada');
    await g.prepare(url.href, 'Bea');
    const code = await hostRoom(a, adapter.game.label, deck);
    log(`host      hosts ${adapter.game.label} (${deck}), room ${code}`);
    await joinRoom(g, code);
    await a.find(/Gegner: Bea/, 'host in the game');
    await g.find(/Gegner: Ada/, 'guest in the game');
    await a.shot('start');
    await g.shot('start');
    const devices = [
      { b: a, seen: seenA, me: 'X', pending: false },
      { b: g, seen: seenG, me: 'O', pending: false },
    ];
    let quiet = 0;
    for (let step = 0; step < maxSteps * 2; step++) {
      const snaps = await Promise.all(devices.map((d) => snapshot(d.b, names)));
      let acted = false;
      for (const [i, d] of devices.entries()) {
        const s = snaps[i];
        if (s.kind === 'reveal') {
          if (d.seen.add(s)) d.pending = false;
          if (s.result) continue;
          for (const p of adapter.revealProblems(s, d.me, names)) d.seen.problem(p);
          if (s.badge) d.badges = (d.badges || 0) + 1;
          // The next picker must tap Weiter; the waiting player sometimes
          // lets the grace run out instead.
          const mine = adapter.nextPicker(s.rec) === d.me;
          if (mine || rng() < 0.5) {
            await d.b.tapAt(s.cont.x, s.cont.y);
            d.seen.clear();
            acted = true;
          }
        } else if (s.kind === 'choose' && !s.result) {
          // KLD-100: 2–3 cards left, choose one (picker or defender).
          if (d.choosing !== s.hint) {
            const c = adapter.chooseCard(s, rng);
            d.choosing = s.hint;
            d.chooses = (d.chooses || 0) + 1;
            log(`${d.seen.name.padEnd(9)} chooses a card${s.defending ? ' (defending)' : ''}`);
            await d.b.tapAt(c.x, c.y);
            acted = true;
          }
        } else if (s.kind === 'table' && !s.result) {
          d.choosing = null;
          if (s.viewer !== d.me) d.seen.problem(`table shows ${names[s.viewer] ?? s.viewer}'s card`);
          const myTurn = s.stats.some((x) => x.enabled);
          if (myTurn && !d.pending) {
            const c = adapter.choose(s, rng);
            taps.push({ player: d.me, stat: c.stat, card: s.card });
            log(`${d.seen.name.padEnd(9)} taps ${c.stat} on ${s.card}`);
            d.pending = true;
            await d.b.tapAt(c.node.x, c.node.y);
            acted = true;
          }
        }
      }
      const settled = snaps.every((s) => s.result && !(s.kind === 'reveal' && (s.grace || s.queued)));
      quiet = settled ? quiet + 1 : 0;
      if (quiet >= 8) break;
      await sleep(acted ? 200 : 150);
    }
    await a.shot('end');
    await g.shot('end');
    for (const d of devices) {
      checkRule(d.seen);
      if (!(await snapshot(d.b, names)).result) d.seen.problem('no result dialog at the end');
    }
    // Both browsers showed the same tricks, in the same order.
    const n = Math.max(seenA.keys.length, seenG.keys.length);
    for (let i = 0; i < n; i++) {
      if (seenA.keys[i] !== seenG.keys[i]) {
        seenG.problem(`trick ${i}: host showed ${seenA.recs[i] ? adapter.show(seenA.recs[i], names) : 'nothing'}, guest ${seenG.recs[i] ? adapter.show(seenG.recs[i], names) : 'nothing'}`);
        break;
      }
    }
    // Every tap became exactly that trick (picker, stat, the tapped card).
    for (let i = 0; i < Math.max(taps.length, seenA.recs.length); i++) {
      const t = taps[i], r = seenA.recs[i];
      if (!t || !r || t.player !== r.picker || t.stat !== r.stat || t.card !== r.cards[r.picker]) {
        seenA.problem(`trick ${i}: tapped ${JSON.stringify(t)}, shown ${r ? adapter.show(r, names) : 'nothing'}`);
        break;
      }
    }
    log(`network   status line followed a queued reveal ${(devices[0].badges || 0) + (devices[1].badges || 0)} time(s)`);
    log(`network   card choices with 3 or fewer cards (KLD-100): host ${devices[0].chooses || 0}, guest ${devices[1].chooses || 0}`);
    log(`network   game over after ${seenA.recs.length} tricks; problems: host ${seenA.problems.length}, guest ${seenG.problems.length}`);
  } finally {
    await a.close();
    await g.close();
  }
  return { seen: [seenA, seenG], shots: [...a.shots, ...g.shots] };
}

async function main() {
  const binary = findFirefox(args.browser);
  if (!binary) {
    console.error('No Firefox found. Install Firefox or pass --browser /path/to/firefox (uses WebDriver BiDi).');
    process.exit(2);
  }
  if (typeof WebSocket === 'undefined') {
    console.error('Node >= 22 is needed (global WebSocket).');
    process.exit(2);
  }
  mkdirSync(outDir, { recursive: true });
  const profileRoot = mkdtempSync(join(tmpdir(), 'klunki-browser-live-'));
  const o = { binary, profileRoot, outDir, width, height, timeout: 30000, verbose };
  const report = { url: url.href, game: adapter.game.id, deck, runs: [] };
  let ok = true;
  try {
    for (const m of mode === 'both' ? ['hotseat', 'network'] : [mode]) {
      log(`== ${m} ${adapter.game.label} (${deck})`);
      let r;
      try {
        r = m === 'hotseat' ? await playHotSeat(o) : await playNetwork(o);
      } catch (e) {
        log(`ERROR (${m}): ${e.message || e}`);
        ok = false;
        report.runs.push({ mode: m, error: String(e.message || e) });
        continue;
      }
      const problems = r.seen.flatMap((s) => s.problems.map((p) => `${s.name}: ${p}`));
      if (problems.length) ok = false;
      report.runs.push({
        mode: m,
        tricks: r.seen.map((s) => ({ device: s.name, tricks: s.recs.map((rec) => adapter.show(rec, s.names)) })),
        problems,
        shots: r.shots,
      });
    }
  } finally {
    await sleep(300);
    rmSync(profileRoot, { recursive: true, force: true });
  }
  writeFileSync(join(outDir, 'report.json'), JSON.stringify(report, null, 2));
  writeFileSync(join(outDir, 'tricks.log'), lines.join('\n') + '\n');
  log(`report: ${join(outDir, 'report.json')}, log: ${join(outDir, 'tricks.log')}`);
  log(ok ? 'RESULT: PASS' : 'RESULT: FAIL');
  process.exit(ok ? 0 : 1);
}

main().catch((e) => {
  console.error(`ERROR: ${e.stack || e}`);
  process.exit(2);
});
