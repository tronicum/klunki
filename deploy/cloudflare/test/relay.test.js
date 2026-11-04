// Worker-specific behaviour on top of the shared vectors (KLD-114): HTTP
// answers, Origin allow-list, club codes from the CLUB_CODES secret (no room
// lookup before the check, strikes, revocation), code collisions, idle
// expiry by alarm, connection errors.
import assert from 'node:assert/strict';
import { afterEach, describe, test } from 'node:test';

import { flush, makeRelay } from './harness.js';

const { ClubCodes, ClubStrikes, newClubCode, normalizeClubCode } = await import('../src/protocol.js');

const realNow = Date.now;
afterEach(() => {
  Date.now = realNow;
});

describe('HTTP', () => {
  test('other paths: 404; /relay without upgrade: 426', async () => {
    const { relay, env } = makeRelay();
    const other = await relay.fetch(new Request('https://relay.test/'), env);
    assert.equal(other.status, 404);
    const plain = await relay.fetch(new Request('https://relay.test/relay?create'), env);
    assert.equal(plain.status, 426);
    assert.equal(plain.headers.get('Upgrade'), 'websocket');
    assert.equal(env.ROOMS.fetches, 0);
  });

  test('/relay/ works like /relay', async () => {
    const { request } = makeRelay();
    const res = await request('create', {}, '/relay/');
    assert.equal(res.status, 101);
  });
});

describe('Origin allow-list', () => {
  const env = { ALLOWED_ORIGINS: 'https://klunki.example, http://localhost:8080' };

  test('a listed origin and no origin (apps) pass', async () => {
    const { open } = makeRelay(env);
    const h = await open('h', 'create', { Origin: 'https://klunki.example' });
    assert.equal((await h.nextJson()).t, 'relay.room');
    const app = await open('app', 'create');
    assert.equal((await app.nextJson()).t, 'relay.room');
  });

  test('another origin is refused before anything else', async () => {
    const { request, env: e } = makeRelay({ ...env, CLUB_CODES: 'K7QX-M2PA' });
    const res = await request('create&club=K7QX-M2PA', { Origin: 'https://evil.example' });
    assert.equal(res.status, 403);
    assert.equal(e.ROOMS.fetches, 0);
  });

  test('without ALLOWED_ORIGINS every origin passes', async () => {
    const { open } = makeRelay();
    const h = await open('h', 'create', { Origin: 'https://anything.example' });
    assert.equal((await h.nextJson()).t, 'relay.room');
  });
});

describe('club codes', () => {
  const codes = 'K7QX-M2PA  # Familie Müller\nMNPQ-RSTU\n';
  const missing = { t: 'relay.error', error: 'club-missing', message: 'club code required' };
  const wrong = { t: 'relay.error', error: 'club-wrong', message: 'club code not accepted' };

  test('refusals never reach a room object (no room-existence leak)', async () => {
    const { open, env } = makeRelay({ CLUB_CODES: codes });
    const h = await open('h', 'create&club=K7QX-M2PA');
    const { code } = await h.nextJson();
    const before = env.ROOMS.fetches;
    for (const [query, want] of [
      [`join=${code}`, missing],
      ['join=22222', missing],
      [`join=${code}&club=WRONG-CODE`, wrong],
      ['join=22222&club=WRONG-CODE', wrong],
      ['create&club=WRONG-CODE', wrong],
    ]) {
      const c = await open('c', query);
      assert.deepEqual(await c.nextJson(), want, query);
      await c.expectClosed(1008);
    }
    assert.equal(env.ROOMS.fetches, before, 'a refused client must not cause a room lookup');
  });

  test('an empty secret admits nobody; no secret = open relay', async () => {
    const gated = makeRelay({ CLUB_CODES: '' });
    const c = await gated.open('c', 'create&club=K7QX-M2PA');
    assert.deepEqual(await c.nextJson(), wrong);
    const open = makeRelay();
    const h = await open.open('h', 'create');
    assert.equal((await h.nextJson()).t, 'relay.room');
  });

  test('a changed secret revokes for new connections; the running room goes on', async () => {
    const { open, env } = makeRelay({ CLUB_CODES: codes });
    const h = await open('h', 'create&club=MNPQ-RSTU');
    const { code } = await h.nextJson();
    const g = await open('g', `join=${code}&club=MNPQ-RSTU`);
    assert.deepEqual(await h.nextJson(), { t: 'relay.peer' });
    env.CLUB_CODES = 'K7QX-M2PA\n'; // MNPQ-RSTU deleted
    await g.send('{"type":"ping","v":3}');
    assert.equal(await h.next(), '{"type":"ping","v":3}');
    await g.close();
    assert.equal((await h.nextJson()).t, 'relay.left');
    const again = await open('again', `join=${code}&club=MNPQ-RSTU`);
    assert.deepEqual(await again.nextJson(), wrong);
  });

  test('10 wrong codes per address, then even a right one is refused until the window passed', async () => {
    let now = 1_000_000;
    const strikes = new ClubStrikes({ now: () => now });
    const { open } = makeRelay({ CLUB_CODES: codes }, { strikes });
    const ip = { 'CF-Connecting-IP': '203.0.113.7' };
    for (let i = 0; i < 10; i++) {
      const c = await open('c', 'create&club=WRONG-CODE', ip);
      assert.deepEqual(await c.nextJson(), wrong);
    }
    const blocked = await open('b', 'create&club=K7QX-M2PA', ip);
    assert.deepEqual(await blocked.nextJson(), {
      t: 'relay.error',
      error: 'club-wrong',
      message: 'too many wrong club codes, try again later',
    });
    const other = await open('o', 'create&club=K7QX-M2PA', { 'CF-Connecting-IP': '198.51.100.1' });
    assert.equal((await other.nextJson()).t, 'relay.room');
    now += 10 * 60 * 1000 + 1;
    const later = await open('l', 'create&club=K7QX-M2PA', ip);
    assert.equal((await later.nextJson()).t, 'relay.room');
  });

  test('ClubCodes.check: normalised, labels and comments ignored', async () => {
    const c = new ClubCodes('k7qx-m2pa # x\n# MNPQ-RSTU\n');
    assert.equal(await c.check('K7QX M2PA'), true);
    assert.equal(await c.check('k7qxm2pa'), true);
    assert.equal(await c.check('MNPQ-RSTU'), false);
    assert.equal(await c.check('K7QX-M2P'), false);
    assert.equal(await c.check('#'), false);
  });

  test('newClubCode has the shape of `klunki relay-code new`', () => {
    const code = newClubCode();
    assert.match(code, /^[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{4}-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{4}$/);
    assert.equal(normalizeClubCode(code), code.replace('-', ''));
  });
});

describe('rooms', () => {
  test('a drawn code that is in use is drawn again; after 8 collisions: too many rooms', async () => {
    const real = crypto.getRandomValues.bind(crypto);
    crypto.getRandomValues = (a) => a.fill(0); // every code is "22222"
    try {
      const { open } = makeRelay();
      const h = await open('h', 'create');
      assert.deepEqual(await h.nextJson(), { t: 'relay.room', code: '22222', key: '0'.repeat(32) });
      const h2 = await open('h2', 'create');
      assert.deepEqual(await h2.nextJson(), { t: 'relay.error', message: 'too many rooms, try again later' });
      await h2.expectClosed(1008);
      await h.close();
      const h3 = await open('h3', 'create');
      assert.deepEqual(await h3.nextJson(), { t: 'relay.room', code: '22222', key: '0'.repeat(32) }, 'the code is free again');
    } finally {
      crypto.getRandomValues = real;
    }
  });

  test('idle expiry: the alarm closes a room without traffic and spares one with traffic', async () => {
    let now = 5_000_000;
    Date.now = () => now;
    const { open, rooms } = makeRelay();
    const h = await open('h', 'create');
    const { code } = await h.nextJson();
    const g = await open('g', `join=${code}`);
    await h.nextJson(); // relay.peer
    const storage = rooms.objects.get(code).ctx.storage;
    assert.equal(storage.alarmAt, 5_000_000 + 600_000);

    now += 300_000;
    await g.send('{"type":"ping","v":3}');
    await h.next();
    now = 5_000_000 + 600_000;
    rooms.hibernateAll();
    await rooms.runAlarm(code);
    assert.equal(storage.alarmAt, 5_000_000 + 300_000 + 600_000, 'traffic moved the expiry');
    await flush();
    assert.equal(h.ws.received.length, h.cursor, 'nothing sent yet');

    now = storage.alarmAt;
    await rooms.runAlarm(code);
    assert.deepEqual(await h.nextJson(), { t: 'relay.closed', reason: 'room expired (idle)' });
    await h.expectClosed(1001);
    assert.deepEqual(await g.nextJson(), { t: 'relay.closed', reason: 'room expired (idle)' });
    await g.expectClosed(1001);
    assert.equal(storage.alarmAt, null, 'nothing left behind');
  });

  test('IDLE_TIMEOUT_SECONDS and MAX_LINE_LENGTH override the defaults', async () => {
    let now = 1_000;
    Date.now = () => now;
    const { open, rooms } = makeRelay({ IDLE_TIMEOUT_SECONDS: '60', MAX_LINE_LENGTH: '10' });
    const h = await open('h', 'create');
    const { code } = await h.nextJson();
    assert.equal(rooms.objects.get(code).ctx.storage.alarmAt, 61_000);
    const g = await open('g', `join=${code}`);
    await h.nextJson();
    await g.send('x'.repeat(10));
    assert.equal(await h.next(), 'x'.repeat(10));
    await g.send('x'.repeat(11));
    assert.deepEqual(await g.nextJson(), { t: 'relay.error', message: 'line too long (max 10 characters)' });
  });

  test('a failed guest connection: relay.left "guest connection failed"; a failed host is away (KLD-120)', async () => {
    const { open, rooms } = makeRelay();
    const h = await open('h', 'create');
    const { code } = await h.nextJson();
    const g = await open('g', `join=${code}`);
    await h.nextJson();
    const object = rooms.objects.get(code);
    const guestSide = g.ws.other;
    guestSide.readyState = 3;
    await object.call('webSocketError', guestSide, new Error('reset'));
    assert.deepEqual(await h.nextJson(), { t: 'relay.left', reason: 'guest connection failed' });
    const g2 = await open('g2', `join=${code}`);
    await h.nextJson();
    const hostSide = h.ws.other;
    hostSide.readyState = 3;
    await object.call('webSocketError', hostSide, new Error('reset'));
    await g2.expectClosed(1000); // dropped without a message; the room waits for the host
    const g3 = await open('g3', `join=${code}`);
    assert.deepEqual(await g3.nextJson(), {
      t: 'relay.error',
      error: 'host-away',
      message: `the host of room ${code} is away, try again in a moment`,
    });
  });

  test('KLD-120: a host that stays away longer than HOST_GRACE_SECONDS loses the room', async () => {
    let now = 1_000_000;
    Date.now = () => now;
    const { open, rooms } = makeRelay({ HOST_GRACE_SECONDS: '60' });
    const h = await open('h', 'create');
    const { code, key } = await h.nextJson();
    const storage = rooms.objects.get(code).ctx.storage;
    await h.close(4000);
    assert.equal(storage.alarmAt, 1_000_000 + 60_000);
    now += 30_000;
    rooms.hibernateAll();
    const h2 = await open('h2', `resume=${code}&key=${key}`);
    assert.deepEqual(await h2.nextJson(), { t: 'relay.room', code, key }, 'back within the grace period');
    await h2.close(4000);
    now += 60_000;
    await rooms.runAlarm(code);
    assert.equal(storage.alarmAt, null, 'nothing left behind');
    assert.deepEqual([...storage.values.keys()], []);
    const late = await open('late', `resume=${code}&key=${key}`);
    assert.deepEqual(await late.nextJson(), { t: 'relay.error', message: `no room with code ${code}` });
  });

  test('KLD-120: HOST_GRACE_SECONDS=0 closes the room when the host drops, as before', async () => {
    const { open } = makeRelay({ HOST_GRACE_SECONDS: '0' });
    const h = await open('h', 'create');
    const { code } = await h.nextJson();
    const g = await open('g', `join=${code}`);
    await h.nextJson();
    await h.close(4000);
    assert.deepEqual(await g.nextJson(), { t: 'relay.closed', reason: 'host left' });
  });

  test('a host waiting alone leaves: the room and its alarm are gone', async () => {
    const { open, rooms } = makeRelay();
    const h = await open('h', 'create');
    const { code } = await h.nextJson();
    await h.close();
    assert.equal(rooms.objects.get(code).ctx.storage.alarmAt, null);
    const g = await open('g', `join=${code}`);
    assert.deepEqual(await g.nextJson(), { t: 'relay.error', message: `no room with code ${code}` });
  });
});
