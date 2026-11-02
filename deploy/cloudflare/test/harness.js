// Test harness: a relay Worker with a fake Durable Object namespace, and
// clients that connect through it (KLD-114).
import assert from 'node:assert/strict';

import { CLOSED, FakeNamespace, flush, installGlobals } from './fakes.js';

installGlobals();

const { createRelay } = await import('../src/relay.js');
const { RelayRoom } = await import('../src/room.js');
const { ClubStrikes } = await import('../src/protocol.js');

export { flush };

export class Client {
  constructor(name, ws) {
    this.name = name;
    this.ws = ws;
    this.cursor = 0;
  }

  async next() {
    await flush();
    assert.ok(this.cursor < this.ws.received.length, `${this.name}: expected a message, got none`);
    return this.ws.received[this.cursor++];
  }

  async nextJson() {
    return JSON.parse(await this.next());
  }

  async expectClosed(code) {
    await flush();
    assert.deepEqual(this.ws.received.slice(this.cursor), [], `${this.name}: unread messages`);
    assert.equal(this.ws.readyState, CLOSED, `${this.name}: still open`);
    if (code !== undefined) assert.equal(this.ws.closeCode, code, `${this.name}: close code`);
  }

  async send(data) {
    this.ws.send(data);
    await flush();
  }

  async close() {
    this.ws.close(1000);
    await flush();
  }
}

/** A Worker + namespace; `env` extras: CLUB_CODES, ALLOWED_ORIGINS, … */
export function makeRelay(envExtras = {}, { strikes } = {}) {
  const env = { ...envExtras };
  env.ROOMS = new FakeNamespace(RelayRoom, env);
  const relay = createRelay({ strikes: strikes ?? new ClubStrikes() });

  async function request(query, headers = {}, path = '/relay') {
    const req = new Request(`https://relay.test${path}${query === null ? '' : `?${query}`}`, {
      headers: { Upgrade: 'websocket', ...headers },
    });
    return relay.fetch(req, env);
  }

  async function open(name, query, headers = {}) {
    const res = await request(query, headers);
    assert.equal(res.status, 101, `${name}: expected a WebSocket for ?${query}`);
    await flush();
    return new Client(name, res.webSocket);
  }

  return { env, relay, rooms: env.ROOMS, request, open };
}
