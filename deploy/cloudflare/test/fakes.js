// A small hand-written fake of the parts of the Workers runtime the relay
// uses (KLD-114): WebSocketPair, Response with status 101 + webSocket, and a
// Durable Object namespace with the WebSocket Hibernation API
// (ctx.acceptWebSocket, getWebSockets(tag), attachments, alarms). No
// miniflare, no dependencies.
//
// Worst cases on purpose, so the relay must not rely on runtime details:
// - every message and close is delivered asynchronously, in order, through
//   one queue (`flush()` runs it);
// - a close started by the relay is echoed by the client and then reported
//   to the object's webSocketClose handler as well;
// - `hibernate()` throws the object instance away between events (its
//   sockets, tags, attachments and alarm stay), so state kept in memory
//   would be lost.

export const queue = [];

export async function flush() {
  for (let guard = 0; queue.length > 0; guard++) {
    if (guard > 100000) throw new Error('fake runtime: endless message loop');
    const task = queue.shift();
    await task();
  }
}

const CONNECTING = 0;
const OPEN = 1;
const CLOSED = 3;

class FakeSocket {
  constructor(side) {
    this.side = side; // 'client' | 'server'
    this.readyState = OPEN;
    this.other = null;
    this.received = []; // client side: what the relay sent
    this.closeCode = null; // client side: the relay's close code
    this.closedByUs = false;
    this.owner = null; // server side: the FakeObject that accepted it
    this.tags = [];
    this.accepted = false;
    this._attachment = null;
  }

  accept() {
    this.accepted = true;
  }

  send(data) {
    if (this.readyState !== OPEN) throw new TypeError('WebSocket is not open');
    const other = this.other;
    const copy = typeof data === 'string' ? data : new Uint8Array(data).slice().buffer;
    queue.push(() => other._deliver(copy));
  }

  close(code = 1000, reason = '') {
    if (code === 1005 || code === 1006 || code === 1015) throw new TypeError(`invalid close code ${code}`);
    if (this.readyState === CLOSED) return;
    this.readyState = CLOSED;
    this.closedByUs = true;
    const other = this.other;
    queue.push(() => other._remoteClose(code, reason));
  }

  serializeAttachment(value) {
    this._attachment = structuredClone(value);
  }

  deserializeAttachment() {
    return this._attachment === null ? null : structuredClone(this._attachment);
  }

  async _deliver(data) {
    if (this.side === 'client') {
      if (this.readyState === OPEN) this.received.push(data);
      return;
    }
    if (this.readyState !== OPEN || this.owner === null) return;
    await this.owner.call('webSocketMessage', this, data);
  }

  async _remoteClose(code, reason) {
    if (this.side === 'client') {
      const echo = this.readyState === OPEN;
      this.readyState = CLOSED;
      this.closeCode = code;
      // The client answers the close; the runtime then reports it.
      if (echo) queue.push(() => this.other._closeReported(code, reason));
      return;
    }
    // The client closed: the server side is closing; the handler is told.
    if (this.readyState === OPEN) this.readyState = CLOSED;
    await this._closeReported(code, reason);
  }

  async _closeReported(code, reason) {
    if (this.side !== 'server' || this.owner === null || this._reported) return;
    this._reported = true;
    await this.owner.call('webSocketClose', this, code, reason, true);
  }
}

export class WebSocketPair {
  constructor() {
    const client = new FakeSocket('client');
    const server = new FakeSocket('server');
    client.other = server;
    server.other = client;
    this[0] = client;
    this[1] = server;
  }
}

/** Response that allows status 101 with a `webSocket`, like the runtime. */
export class Response {
  constructor(body = null, init = {}) {
    this.status = init.status ?? 200;
    this.webSocket = init.webSocket ?? null;
    this.headers = new Headers(init.headers ?? {});
    this._body = body;
  }

  async text() {
    return this._body ?? '';
  }
}

class FakeStorage {
  constructor() {
    this.alarmAt = null;
    this.values = new Map();
  }

  async get(key) {
    return this.values.has(key) ? structuredClone(this.values.get(key)) : undefined;
  }

  async put(key, value) {
    this.values.set(key, structuredClone(value));
  }

  async delete(key) {
    return this.values.delete(key);
  }

  async deleteAll() {
    this.values.clear();
  }

  async setAlarm(time) {
    this.alarmAt = Number(time);
  }

  async getAlarm() {
    return this.alarmAt;
  }

  async deleteAlarm() {
    this.alarmAt = null;
  }
}

class FakeState {
  constructor() {
    this.sockets = [];
    this.storage = new FakeStorage();
  }

  acceptWebSocket(ws, tags = []) {
    if (ws.side !== 'server') throw new TypeError('accept the server side');
    ws.tags = [...tags];
    ws.owner = this.owner;
    this.sockets.push(ws);
  }

  getWebSockets(tag) {
    // The runtime drops disconnected sockets from this list.
    return this.sockets.filter((ws) => ws.readyState !== CLOSED && (tag === undefined || ws.tags.includes(tag)));
  }
}

/** One Durable Object: its state lives on, its instance may not. */
class FakeObject {
  constructor(cls, env) {
    this.cls = cls;
    this.env = env;
    this.ctx = new FakeState();
    this.ctx.owner = this;
    this.instance = null;
    this.gate = Promise.resolve();
  }

  get object() {
    this.instance ??= new this.cls(this.ctx, this.env);
    return this.instance;
  }

  /** Runs one event at a time (the runtime's input gate). */
  call(method, ...args) {
    const run = this.gate.then(() => this.object[method](...args));
    this.gate = run.catch(() => {});
    return run;
  }

  hibernate() {
    this.instance = null;
  }
}

export class FakeNamespace {
  constructor(cls, env) {
    this.cls = cls;
    this.env = env;
    this.objects = new Map();
    this.fetches = 0;
  }

  idFromName(name) {
    return { name };
  }

  get(id) {
    return {
      fetch: (input, init) => {
        this.fetches++;
        const request = input instanceof Request ? input : new Request(input, init);
        return this.object(id.name).call('fetch', request);
      },
    };
  }

  object(name) {
    let o = this.objects.get(name);
    if (o === undefined) {
      o = new FakeObject(this.cls, this.env);
      this.objects.set(name, o);
    }
    return o;
  }

  /** Evicts every object instance (what hibernation does). */
  hibernateAll() {
    for (const o of this.objects.values()) o.hibernate();
  }

  /** Fires the alarm of room `name` if it is due at `now`. */
  async runAlarm(name) {
    const o = this.objects.get(name);
    if (o === undefined || o.ctx.storage.alarmAt === null) return false;
    o.ctx.storage.alarmAt = null;
    await o.call('alarm');
    return true;
  }
}

/** Installs the runtime globals the Worker code uses. */
export function installGlobals() {
  globalThis.WebSocketPair = WebSocketPair;
  globalThis.Response = Response;
}

export { CONNECTING, OPEN, CLOSED };
