// One relay room = one Durable Object (named by its room code), holding the
// host's and the guest's WebSocket. Port of `_Room` in
// packages/klunki_net/lib/src/relay/relay_server.dart (KLD-114).
//
// It uses the WebSocket Hibernation API (`ctx.acceptWebSocket` and the
// `webSocketMessage` / `webSocketClose` / `webSocketError` handlers): while
// nothing happens (a host waiting for its guest) the object is evicted from
// memory and costs nothing, and the WebSockets stay open. Because of that the
// object keeps NO state in memory: who is host and guest comes from the
// socket tags, everything else from each socket's attachment
// (`{role, code, active, gone}`), which survives hibernation.
//
// KLD-120: the room's host key and, while the host is away (its connection
// dropped without a clean close), the time it went away live in storage, so
// they outlive the host's socket. The host comes back with
// `?resume=CODE&key=KEY` within HOST_GRACE_SECONDS.
//
// KLD-088: a table room (`guests` 2–3 in storage and in every attachment)
// holds several guest sockets, each with its `peer` number (the next one in
// storage); their lines reach the host as `relay.from {peer, line}` and the
// host answers with `relay.to {peer, line}`.

import {
  closeGoingAway,
  closeNoStatus,
  closeNormal,
  closePolicyViolation,
  parseRelayControl,
  relayClosed,
  relayControl,
  relayError,
  relayKick,
  relayFrom,
  relayLeft,
  relayPeer,
  relayPeerField,
  relayRoom,
  relayTo,
} from './protocol.js';

/** Defaults of the Dart relay (`RelayServer.start`). */
export const defaultIdleTimeoutMs = 10 * 60 * 1000;
export const defaultHostGraceMs = 5 * 60 * 1000;
export const defaultMaxLineLength = 256 * 1024;

const OPEN = 1;

function positive(value, fallback) {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function attachment(ws) {
  return ws.deserializeAttachment() ?? {};
}

function mark(ws, fields) {
  ws.serializeAttachment({ ...attachment(ws), ...fields });
}

function send(ws, line) {
  try {
    if (ws.readyState === OPEN) ws.send(line);
  } catch {
    // the socket is going away: nothing to tell it
  }
}

/** 16 random bytes as hex: the room's host key (KLD-120). */
function newKey() {
  return [...crypto.getRandomValues(new Uint8Array(16))].map((b) => b.toString(16).padStart(2, '0')).join('');
}

function sameKey(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function close(ws, code) {
  try {
    ws.close(code, '');
  } catch {
    // already closed
  }
}

export class RelayRoom {
  constructor(ctx, env) {
    this.ctx = ctx;
    this.idleTimeoutMs = positive(env?.IDLE_TIMEOUT_SECONDS, defaultIdleTimeoutMs / 1000) * 1000;
    this.maxLineLength = positive(env?.MAX_LINE_LENGTH, defaultMaxLineLength);
    const grace = Number(env?.HOST_GRACE_SECONDS);
    this.hostGraceMs = Number.isFinite(grace) && grace >= 0 ? grace * 1000 : defaultHostGraceMs;
  }

  /** The current host socket, or null (none, or it is leaving). */
  host() {
    return this.ctx.getWebSockets('host').find((ws) => ws.readyState === OPEN && !attachment(ws).gone) ?? null;
  }

  /** The current guest sockets. */
  guests() {
    return this.ctx.getWebSockets('guest').filter((ws) => ws.readyState === OPEN && !attachment(ws).gone);
  }

  /**
   * Called by the Worker only (Durable Objects have no public URL):
   * header `X-Klunki-Op: create|join|resume`, `X-Klunki-Room: CODE` (resume:
   * also `X-Klunki-Key`). Answers 101 with the client's WebSocket, or 409
   * (create: code in use; join: room full) / 404 (join, resume: no room, or
   * a wrong key) / 423 (join: the host is away, KLD-120) without one; the
   * Worker turns those into the relay's `relay.error` messages.
   */
  async fetch(request) {
    const op = request.headers.get('X-Klunki-Op');
    const code = request.headers.get('X-Klunki-Room') ?? '';
    if (op === 'create') {
      if (this.host() !== null || (await this.ctx.storage.get('key')) !== undefined) {
        return new Response(null, { status: 409 });
      }
      const key = newKey();
      const guests = positive(request.headers.get('X-Klunki-Guests'), 1);
      await this.ctx.storage.put('key', key);
      await this.ctx.storage.put('guests', guests);
      return this.attachHost(code, key, guests);
    }
    if (op === 'resume') {
      const key = await this.ctx.storage.get('key');
      if (!sameKey(request.headers.get('X-Klunki-Key') ?? '', key)) return new Response(null, { status: 404 });
      // A host connection that still looks open is replaced.
      const old = this.host();
      if (old !== null) {
        mark(old, { gone: true });
        send(old, relayControl(relayClosed, { reason: 'replaced by a new host connection' }));
        close(old, closeGoingAway);
      }
      this.dropGuests();
      await this.ctx.storage.delete('away');
      return this.attachHost(code, key, (await this.ctx.storage.get('guests')) ?? 1);
    }
    if (op === 'join') {
      const host = this.host();
      if (host === null) {
        const away = await this.ctx.storage.get('away');
        return new Response(null, { status: away === undefined ? 404 : 423 });
      }
      const guests = attachment(host).guests ?? 1;
      if (this.guests().length >= guests) return new Response(null, { status: 409 });
      const peer = (await this.ctx.storage.get('nextPeer')) ?? 1;
      await this.ctx.storage.put('nextPeer', peer + 1);
      const [client, server] = Object.values(new WebSocketPair());
      this.ctx.acceptWebSocket(server, ['guest']);
      server.serializeAttachment({ role: 'guest', peer, guests });
      this.touch(host);
      send(host, guests > 1 ? relayControl(relayPeer, { [relayPeerField]: peer }) : relayControl(relayPeer));
      return new Response(null, { status: 101, webSocket: client });
    }
    return new Response(null, { status: 400 });
  }

  /** The host's connection, new or coming back (KLD-120); `guests`: the room's size (KLD-088). */
  async attachHost(code, key, guests) {
    const [client, server] = Object.values(new WebSocketPair());
    this.ctx.acceptWebSocket(server, ['host']);
    server.serializeAttachment({ role: 'host', code, active: Date.now(), guests });
    send(server, relayControl(relayRoom, guests > 1 ? { code, key, guests } : { code, key }));
    await this.ctx.storage.setAlarm(Date.now() + this.idleTimeoutMs);
    return new Response(null, { status: 101, webSocket: client });
  }

  // ------------------------------------------------- hibernation handlers

  webSocketMessage(ws, message) {
    const a = attachment(ws);
    if (a.gone) return;
    if (a.role === 'host') this.fromHost(ws, message);
    else if (a.role === 'guest') this.fromGuest(ws, message);
  }

  webSocketClose(ws, code, _reason, _wasClean) {
    // Complete the closing handshake (needed with older compatibility
    // dates; harmless otherwise).
    close(ws, closeNormal);
    return this.gone(ws, 'disconnected', code);
  }

  webSocketError(ws, _error) {
    return this.gone(ws, 'connection failed');
  }

  /**
   * Idle expiry: no forwarded frame for `idleTimeoutMs` closes the room;
   * so does a host that stays away longer than `hostGraceMs` (KLD-120).
   */
  async alarm() {
    const away = await this.ctx.storage.get('away');
    if (away !== undefined) {
      if (Date.now() - away >= this.hostGraceMs) return this.shutDown('host left');
      return this.ctx.storage.setAlarm(away + this.hostGraceMs);
    }
    const host = this.host();
    if (host === null) return this.shutDown('room expired (idle)');
    const active = attachment(host).active ?? 0;
    if (Date.now() - active >= this.idleTimeoutMs) return this.shutDown('room expired (idle)');
    await this.ctx.storage.setAlarm(active + this.idleTimeoutMs);
  }

  // ------------------------------------------------------------ forwarding

  /** Checks one frame (against `limit`, default the line limit); returns the line to forward, or null after refusing. */
  check(ws, frame, limit = this.maxLineLength) {
    if (typeof frame !== 'string') {
      this.violation(ws, 'binary frames are not relayed');
      return null;
    }
    if (frame.length > limit) {
      this.violation(ws, `line too long (max ${this.maxLineLength} characters)`);
      return null;
    }
    return frame;
  }

  fromHost(host, frame) {
    const table = (attachment(host).guests ?? 1) > 1;
    // A table room's lines are wrapped: room for the escaping of `line`.
    const line = this.check(host, frame, table ? 2 * this.maxLineLength + 1024 : this.maxLineLength);
    if (line === null) return;
    this.touch(host);
    const control = parseRelayControl(line);
    if (control === null) {
      // The classic room forwards the line; a table room needs `relay.to`.
      if (!table) for (const guest of this.guests()) send(guest, line);
      return;
    }
    const peer = control[relayPeerField];
    const isPeer = Number.isInteger(peer);
    if (control.t === relayKick && !table) {
      this.dropGuests();
    } else if (control.t === relayKick && isPeer) {
      this.dropGuests(peer);
    } else if (control.t === relayTo && table && isPeer) {
      const inner = control.line;
      if (typeof inner !== 'string' || inner.length > this.maxLineLength) {
        return this.violation(host, `line too long (max ${this.maxLineLength} characters)`);
      }
      for (const guest of this.guests()) if (attachment(guest).peer === peer) send(guest, inner);
    }
    // other control lines from the host are ignored
  }

  fromGuest(ws, frame) {
    const line = this.check(ws, frame);
    if (line === null) return;
    if (parseRelayControl(line) !== null) {
      return this.violation(ws, 'relay control messages are not allowed from a guest');
    }
    const host = this.host();
    if (host === null) return;
    this.touch(host);
    const a = attachment(ws);
    send(host, (a.guests ?? 1) > 1 ? relayControl(relayFrom, { [relayPeerField]: a.peer, line }) : line);
  }

  /** Marks the room active (in the host's attachment: survives hibernation). */
  touch(host) {
    mark(host, { active: Date.now() });
  }

  /**
   * A rule broken by `ws`: `relay.error`, then close. The host breaking a
   * rule closes the room; a guest only loses its own connection.
   */
  violation(ws, message) {
    send(ws, relayControl(relayError, { message }));
    if (attachment(ws).role === 'host') {
      this.shutDown('host broke the relay rules');
    } else {
      this.guestGone(ws, message);
      close(ws, closePolicyViolation);
    }
  }

  /** Drops the guests (only guest `peer` when given); no `relay.left` follows. */
  dropGuests(peer) {
    for (const guest of this.guests()) {
      if (peer !== undefined && attachment(guest).peer !== peer) continue;
      mark(guest, { gone: true });
      close(guest, closeNormal);
    }
  }

  /**
   * A socket's connection ended (closed by the client, or failed). A host
   * that closes cleanly (1000, or no status) leaves; any other end makes it
   * away for `hostGraceMs` (KLD-120): the guest is dropped, the room waits.
   */
  async gone(ws, what, code) {
    const a = attachment(ws);
    if (a.gone) return;
    if (a.role === 'guest') return this.guestGone(ws, `guest ${what}`);
    if (a.role !== 'host') return;
    const left = what === 'disconnected' && (code === closeNormal || code === closeNoStatus);
    if (left || this.hostGraceMs <= 0) {
      return this.shutDown(`host ${what === 'disconnected' ? 'left' : 'connection failed'}`);
    }
    mark(ws, { gone: true });
    this.dropGuests();
    const now = Date.now();
    await this.ctx.storage.put('away', now);
    await this.ctx.storage.setAlarm(now + this.hostGraceMs);
  }

  guestGone(ws, reason) {
    const a = attachment(ws);
    if (a.gone) return;
    mark(ws, { gone: true });
    const host = this.host();
    if (host === null) return;
    send(host, relayControl(relayLeft, (a.guests ?? 1) > 1 ? { [relayPeerField]: a.peer, reason } : { reason }));
  }

  /**
   * Closes the room: everyone still connected gets `relay.closed {reason}`,
   * then the connection is closed. Nothing is left in storage.
   */
  shutDown(reason) {
    const sockets = [...this.ctx.getWebSockets('host'), ...this.ctx.getWebSockets('guest')];
    for (const ws of sockets) {
      if (attachment(ws).gone) continue;
      mark(ws, { gone: true });
      send(ws, relayControl(relayClosed, { reason }));
      close(ws, closeGoingAway);
    }
    return Promise.all([this.ctx.storage.deleteAlarm(), this.ctx.storage.deleteAll()]);
  }
}
